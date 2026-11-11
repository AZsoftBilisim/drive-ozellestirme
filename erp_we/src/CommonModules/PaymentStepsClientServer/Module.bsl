
////////////////////////////////////////////////////////////////////////////////
// The "Payment Stages Clientserver" module contains procedures and functions for 
// forming a representation of payment stages,
// working with a table of payment stages that do not require a server call.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region PresentationOfPaymentStages

// Returns a view of payment terms for agreements
// that include the payment form and payment stages.
//
// Parameters:
// 		Form - ClientApplicationForm - the form from which the function is called.
//
// Returns:
// 		String - presentation of payment terms.
//
Function InscriptionStagesPaymentForAgreements(Form) Export
	
	Object = Form.Object;
	
	PaymentMethod            = Object.PaymentMethod;
	PaymentScheduleSteps     = Object.PaymentScheduleSteps;
	NumberOfPaymentStages = PaymentScheduleSteps.Count();
	
	Appearance = LabelDesignParametersPaymentStages();
	
	RowsArray = New Array;
	RowsArray.Add(PresentationOfPaymentFormForAgreements(PaymentMethod));
	
	TextOfPaymentStages = "";
	If NumberOfPaymentStages = 0 Then
		
		RowsArray.Add(" ");
		RowsArray.Add(New FormattedString(NStr("vi = 'chưa chỉ ra các công đoạn';
												|ru = 'этапы не указаны';
												|en = 'milestones are not set'; fa = 'milestones are not set';
												|it = 'Fasi non indicate';
												|pl = 'etapy nie są wskazane';
												|tr = 'aşamalar belirtilmedi'"), , Appearance.ColorWarning));
		
	ElsIf NumberOfPaymentStages <= 2 Then
		
		RowsArray.Add(" ");
		For Cnt=1 To NumberOfPaymentStages Do
			PaymentLine_ = PaymentScheduleSteps[Cnt-1];
			If PaymentLine_.CalculateFrom = PredefinedValue("Enum.PaymentDateCalculationOptions.Formula") Then
				TextOfPaymentStages = String(PaymentLine_.Formula);
			Else
				TextOfPaymentStages = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1% %2 ngày %3';
						|ru = '%1% %2 дн %3';
						|en = '%1% %2 days %3'; fa = '%1% %2 days %3';
						|it = '%1% %2 gg %3';
						|pl = '%1% %2 dn. %3';
						|tr = '%1% %2 gün %3'"),
					PaymentLine_.PaymentPercentage, 
					PaymentLine_.Move,
					PaymentLine_.CalculateFrom);
			EndIf;
			RowsArray.Add(TextOfPaymentStages);
			RowsArray.Add(", ");
		EndDo;
		RowsArray.Delete(RowsArray.Count()-1);
		
	Else
		
		StageText = TMCommonUseClientServer.DeclensionOfWord(
			NumberOfPaymentStages,
			NStr("vi = 'giai đoạn, giai đoạn, giai đoạn, m';
				|ru = 'этапы, этапа, этапов, м';
				|en = 'stage, stages'; fa = 'stage, stages';
				|it = 'этапы, этапа, этапов, м';
				|pl = 'stage, stages';
				|tr = 'aşama, aşama, aşamalar, m'"));
			
		RowsArray.Add(" ");
		RowsArray.Add(NStr("vi = 'trong';
							|ru = 'в';
							|en = 'in'; fa = 'در';
							|it = 'il';
							|pl = 'in';
							|tr = 'içinde'") +" " + Format(NumberOfPaymentStages, "NZ=0") +" " + StageText);
		
	EndIf;
	
	LabelText = New FormattedString(RowsArray);
	Return LabelText;
	
EndFunction

// The order of the postponement options.
// 
// Returns:
// 	Map of KeyAndValue - Contains the order in which the reference options are displayed, where:
// 		* Key - EnumRef.PaymentDateCalculationOptions - full name of the register.
// 		* Value - Number - query text.
Function OrderOfReferenceOptions() Export
	
	Map = New Map();
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.EmptyRef"),0);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.FromOrderDate"),1);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.FromApprovalDate"),2);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate"),3);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.FromShipmentDate"),4);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods"),5);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.FromDateOfReceipt"),6);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.FixedDate"),7);
	Map.Insert(PredefinedValue("Enum.PaymentDateCalculationOptions.Formula"),8);
	
	Return Map;
	
EndFunction

#EndRegion

#Region FillingInAndDistributingPaymentStages

// Distributes the amount by payment stages
//
// Parameters:
// ScheduleStages
// 		PaymentScheduleSteps -ValueTable - table of payment stages where you need to distribute the amount
// 		AmountToDistributePayment - Number - the amount of payments to be distributed by stages
// 		AmountForDistributionOfCollateral - Number - Optional, the amount of the Deposit for the container to be distributed in stages
// 		AmountForDistributionOfSettlements - Number - Optional, the amount of mutual settlements of the document to be distributed by stages.
// 		AmountForDistributionOfMutualSettlementsByContainer - Number - Optional, the amount of mutual settlements for the document container, which must be distributed by stages.
//
Procedure DistributeAmountByStagesOfPaymentSchedule(PaymentScheduleSteps, Val AmountToDistributePayment, 
	Val AmountForDistributionOfCollateral = 0, Val AmountForDistributionOfSettlements = 0, Val AmountForDistributionOfMutualSettlementsByContainer = 0) Export
	
	DistributedPaymentAmount               = 0;
	DistributedAmountOfCollateral               = 0;
	DistributedAmountOfSettlements       = 0;
	DistributedAmountOfMutualSettlementsOnContainer = 0;
	CurrenciesDoNotMatch                         = AmountToDistributePayment = AmountForDistributionOfSettlements;
	CurrentStep                             = 0;
	PaymentPercentage                          = 0;
	PackageDepositPercentage                     = 0;
	ThereAreExtraStages                         = False;
	NumberOfStages                        = PaymentScheduleSteps.Count();
	
	ThereIsPackage = NumberOfStages > 0 And CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0],"PackageDepositValue");
	
	DistributeOnlyAmountOfMutualPayments = AmountToDistributePayment = PaymentScheduleSteps.Total("PaymentAmount")
		And (Not ThereIsPackage Or AmountForDistributionOfCollateral = PaymentScheduleSteps.Total("PackageDepositValue"));
		
	For Each PaymentScheduleStage In PaymentScheduleSteps Do
		
		Data_Stage = New Structure();
		Data_Stage.Insert("PaymentPercentage", 0);
		Data_Stage.Insert("PaymentAmount", 0);
		Data_Stage.Insert("AmountARAP", 0);
		Data_Stage.Insert("PackageDepositPercentage", 0);
		Data_Stage.Insert("PackageDepositValue", 0);
		Data_Stage.Insert("AmountARAPByPackage", 0);
		
		FillPropertyValues(Data_Stage, PaymentScheduleStage);
		
		CurrentStep = CurrentStep + 1;
		
		// If the amount of payments for all stages is less than one hundred percent or 
		// the percentages of the current stage are equal to 0
		// , we will add the missing percentages.
		
		PercentagesOfCurStageAreZero = (Data_Stage.PaymentPercentage = 0 And Data_Stage.PackageDepositPercentage = 0);
		
		If (CurrentStep = NumberOfStages
			And PaymentScheduleSteps.Total("PaymentPercentage") < 100)
			Or PercentagesOfCurStageAreZero Then
			
			Data_Stage.PaymentPercentage = 100 - PaymentPercentage;
			
		EndIf;
		If (CurrentStep = NumberOfStages And PackageDepositPercentage + Data_Stage.PackageDepositPercentage < 100)
			Or PercentagesOfCurStageAreZero Then
			
			Data_Stage.PackageDepositPercentage = 100 - PackageDepositPercentage;
			
		EndIf;
		
		// If the total payment percentage is more than 100% by the current stage 
		// , we will reduce the percentage of the current payment and remove the "extra" stages.
		
		PercentageOfPaymentWithCurStage = PaymentPercentage + Data_Stage.PaymentPercentage;
		PercentageOfCollateralForContainerWithCurStage = PackageDepositPercentage + Data_Stage.PackageDepositPercentage;
		
		If PercentageOfPaymentWithCurStage > 100 Then
			Data_Stage.PaymentPercentage = 100 - PaymentPercentage;
		EndIf;
		If PercentageOfCollateralForContainerWithCurStage > 100 Then
			Data_Stage.PackageDepositPercentage = 100 - PackageDepositPercentage;
		EndIf;
		
		If Not DistributeOnlyAmountOfMutualPayments Then
			PaymentAmountByStage_1       = Round(AmountToDistributePayment * Data_Stage.PaymentPercentage / 100,
			                                2,
			                                RoundMode.Round15as20);
			
			Data_Stage.PaymentAmount  = ?(CurrentStep = NumberOfStages,
			                              AmountToDistributePayment - DistributedPaymentAmount,
			                              PaymentAmountByStage_1);
			
			DistributedPaymentAmount = DistributedPaymentAmount + Data_Stage.PaymentAmount;
			PaymentPercentage            = PaymentPercentage + Data_Stage.PaymentPercentage;
			
			DepositAmountByStage            = Round(AmountForDistributionOfCollateral * Data_Stage.PackageDepositPercentage / 100,
			                                    2,
			                                    RoundMode.Round15as20);
			
			Data_Stage.PackageDepositValue = ?(CurrentStep = NumberOfStages,
			                                  AmountForDistributionOfCollateral - DistributedAmountOfCollateral,
			                                  DepositAmountByStage);
			
			DistributedAmountOfCollateral     = DistributedAmountOfCollateral + Data_Stage.PackageDepositValue;
			PackageDepositPercentage           = PackageDepositPercentage + Data_Stage.PackageDepositPercentage;
		EndIf;
		
		If AmountForDistributionOfSettlements <> 0 Then
			If CurrenciesDoNotMatch Then
				Data_Stage.AmountARAP = Data_Stage.PaymentAmount;
			Else
				AmountOfSettlementsByStage = Round(AmountForDistributionOfSettlements * Data_Stage.PaymentPercentage / 100, 2, RoundMode.Round15as20);
				
				Data_Stage.AmountARAP  = ?(CurrentStep = NumberOfStages,
										AmountForDistributionOfSettlements - DistributedAmountOfSettlements,
										AmountOfSettlementsByStage);
				DistributedAmountOfSettlements = DistributedAmountOfSettlements + Data_Stage.AmountARAP;
			EndIf;
		Else
			Data_Stage.AmountARAP = 0;
		EndIf;
		
		If AmountForDistributionOfMutualSettlementsByContainer <> 0 Then
			If CurrenciesDoNotMatch Then
				Data_Stage.AmountARAPByPackage = Data_Stage.PackageDepositValue;
			Else
				AmountOfMutualSettlementsOnContainerByStage = Round(AmountForDistributionOfMutualSettlementsByContainer * Data_Stage.PackageDepositPercentage / 100, 2, RoundMode.Round15as20);
				
				Data_Stage.AmountARAPByPackage  = ?(CurrentStep = NumberOfStages,
										AmountForDistributionOfMutualSettlementsByContainer - DistributedAmountOfMutualSettlementsOnContainer,
										AmountOfMutualSettlementsOnContainerByStage);
				DistributedAmountOfMutualSettlementsOnContainer = DistributedAmountOfMutualSettlementsOnContainer + Data_Stage.AmountARAPByPackage;
			EndIf;
		Else
			Data_Stage.AmountARAPByPackage = 0;
		EndIf;
		
		// If the payment percentage is exceeded at the current stage and the stage is not the last 
		// one, it is necessary to delete the extra stages.
		
		If CurrentStep <> NumberOfStages
			And AmountToDistributePayment = 0
			And AmountForDistributionOfCollateral = 0 Then
			ThereAreExtraStages = True;
			Break;
		EndIf;
		
		FillPropertyValues(PaymentScheduleStage, Data_Stage);
		
	EndDo;
	
	// We will remove unnecessary stages of the payment schedule.
	If ThereAreExtraStages Then
		
		For Counter = CurrentStep To NumberOfStages-1 Do
			PaymentScheduleSteps.Delete(CurrentStep);
		EndDo;
		
	EndIf;
	
	TMCommonUseClientServer.FillInCollectionPropertyValues(PaymentScheduleSteps, 0, "MeasuringGoodsVarianceAmount");
	
EndProcedure

// Returns the structure of parameters for calculating the payment date or shift.
// 
// Returns:
//  Structure - Payment Date Calculation Parameters:
// * CalculateFrom                                         - EnumRef.PaymentDateCalculationOptions - A variant of the line count.
// * Move                                                  - Number - Line shift.
// * PaymentDate                                            - Date - The payment date of the line.
// * OrderDate                                             - Date - Order date, if any.
// * ApprovalDate                                       - Date - The date of approval of the order, if any.
// * DateOfShipment                                           - Date - The date the line was shipped.
// * DateOfReceipt                                        - Date - Date of receipt of the goods, if any.
// * DeadlineOfTransferOfTitleToGoods                         - Number - The term of transfer of ownership from the agreement
// * Calendar - CatalogRef.BusinessCalendars - Calendar for accounting only working days.
// * DateOfTransferOfTitleToGoods                         - Date - Date of transfer of ownership of the document.
// * Formula - CatalogRef.FormulasForCalculatingPaymentDate   - The formula for calculating the payment date
//
Function PaymentDateCalculationParameters() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("CalculateFrom",                 PredefinedValue("Enum.PaymentDateCalculationOptions.EmptyRef"));
	ParametersStructure.Insert("Move",                          0);
	ParametersStructure.Insert("PaymentDate",                    Date(1,1,1));
	ParametersStructure.Insert("OrderDate",                     Date(1,1,1));
	ParametersStructure.Insert("ApprovalDate",               Date(1,1,1));
	ParametersStructure.Insert("DateOfShipment",                   Date(1,1,1));
	ParametersStructure.Insert("DateOfReceipt",                Date(1,1,1));
	ParametersStructure.Insert("DeadlineOfTransferOfTitleToGoods", 0);
	ParametersStructure.Insert("Calendar",                      PredefinedValue("Catalog.BusinessCalendars.EmptyRef"));
	ParametersStructure.Insert("DateOfTransferOfTitleToGoods", Date(1,1,1));
	ParametersStructure.Insert("Formula",                        PredefinedValue("Catalog.FormulasForCalculatingPaymentDate.EmptyRef"));
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns an informative view of the payment form for agreements
//
// Parameters:
// 		PaymentMethod - EnumRef.PaymentForms - form of payment. for which you need to get a view.
//
// Returns:
// 		String - presentation of the payment form.
//
Function PresentationOfPaymentFormForAgreements(PaymentMethod)
	
	Presentation = "";
	
	If Not ValueIsFilled(PaymentMethod) Then
		Presentation = NStr("vi = 'Thanh toán bất kỳ:';
							|ru = 'Оплата любым способом:';
							|en = 'Any payment method:'; fa = 'Any payment method:';
							|it = 'Il pagamento in qualsiasi modalità:';
							|pl = 'Płatność w dowolny sposób:';
							|tr = 'Herhangi bir ödeme yöntemi ile:'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.PaymentCard") Then
		Presentation = NStr("vi = 'Thanh toán bằng thẻ:';
							|ru = 'Оплата платежной картой:';
							|en = 'Payment by payment card:'; fa = 'Payment by payment card:';
							|it = 'Pagamento con la carta di pagamento:';
							|pl = 'Płatność kartą płatniczą:';
							|tr = 'Ödeme kartı ile ödeme:'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.SettlementOfARAP") Then
		Presentation = NStr("vi = 'Đối trừ:';
							|ru = 'Взаимозачет:';
							|en = 'Offset:'; fa = 'Offset:';
							|it = 'Compensazione:';
							|pl = 'Rozliczenie wzajemne:';
							|tr = 'Uzlaşma:'");
	ElsIf PaymentMethod = PredefinedValue("Enum.PaymentForms.InstantPayments") Then
		Presentation = NStr("ru = 'Оплата через СБП:';
							|vi = 'Payment via FPS:';
							|en = 'Payment via FPS:'; fa = 'Payment via FPS:';
							|it = 'Payment via FPS:';
							|pl = 'Payment via FPS:';
							|tr = 'SBP aracılığıyla ödeme:'");
	Else
		Presentation = NStr("vi = '%PaymentMethod% thanh toán:';
							|ru = '%PaymentMethod% оплата:';
							|en = '%PaymentMethod% payment:'; fa = '%PaymentMethod% payment:';
							|it = '%PaymentMethod% pagamento:';
							|pl = '%PaymentMethod% płatność:';
							|tr = '%PaymentMethod% ödeme:'");
		Presentation = StrReplace(Presentation, "%PaymentMethod%", PaymentMethod);
	EndIf;
	
	Return Presentation;
	
EndFunction

Function LabelDesignParametersPaymentStages()
	
	ParametersStructure = New Structure();
	ParametersStructure.Insert("ColorWarning", WebColors.FireBrick);
	ParametersStructure.Insert("ColorSelection", New Color(22, 39, 121));
	ParametersStructure.Insert("DateFormat", "DLF=D");
	ParametersStructure.Insert("ShareFormat", "ND=3; NFD=; NZ=0");
	
	Return ParametersStructure;
	
EndFunction

// Sort the stage table.
// 
// Parameters:
//  PaymentScheduleSteps - ValueTable,FormDataCollection - The stages of payment schedule
Procedure SortStageTable(PaymentScheduleSteps) Export
	
	If PaymentScheduleSteps.Count() = 0 Then
		Return;
	EndIf;
	
	OrderOfReferenceOptions = OrderOfReferenceOptions();
	
	If CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0],"PaymentOptionNumber") Then
		
		For Each PaymentStage In PaymentScheduleSteps Do
			If PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision")
				Or PaymentStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation") Then
				PaymentStage.PaymentOptionNumber = 1;
			ElsIf PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment")
				Or PaymentStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt") Then
				PaymentStage.PaymentOptionNumber = 2;
			ElsIf PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment")
				Or PaymentStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment") Then
				PaymentStage.PaymentOptionNumber = 3;
			Else
				PaymentStage.PaymentOptionNumber = 4;
			EndIf;
			
			PaymentStage.NumberOfCalculateFrom = OrderOfReferenceOptions[PaymentStage.CalculateFrom];
			
		EndDo;
		
		ThereIsOverOrder = CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0],"ExceedingOrder");
		PaymentScheduleSteps.Sort("PaymentOptionNumber, PaymentDate, NumberOfCalculateFrom"+?(ThereIsOverOrder,",ExceedingOrder",""));
		
	Else
		
		If TypeOf(PaymentScheduleSteps) = Type("ValueTable") Then
			StagesOfPaymentScheduleNew = PaymentScheduleSteps.Copy();
		Else
			StagesOfPaymentScheduleNew = PaymentScheduleSteps.Unload();
		EndIf;
		
		If StagesOfPaymentScheduleNew.Columns.Find("PaymentOptionNumber") = Undefined Then
			StagesOfPaymentScheduleNew.Columns.Add("PaymentOptionNumber");
		EndIf;
		
		If StagesOfPaymentScheduleNew.Columns.Find("NumberOfCalculateFrom") = Undefined Then
			StagesOfPaymentScheduleNew.Columns.Add("NumberOfCalculateFrom");
		EndIf;
		
		For Each PaymentStage In StagesOfPaymentScheduleNew Do
			If PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision")
				Or PaymentStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation") Then
				PaymentStage.PaymentOptionNumber = 1;
			ElsIf PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment")
				Or PaymentStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt") Then
				PaymentStage.PaymentOptionNumber = 2;
			ElsIf PaymentStage.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment")
				Or PaymentStage.PaymentOption = PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment") Then
				PaymentStage.PaymentOptionNumber = 3;
			Else
				PaymentStage.PaymentOptionNumber = 4;
			EndIf;
			
			PaymentStage.NumberOfCalculateFrom = OrderOfReferenceOptions[PaymentStage.CalculateFrom];
		EndDo;
		
		ThereIsOverOrder = StagesOfPaymentScheduleNew.Columns.Find("ExceedingOrder") <> Undefined ;
		StagesOfPaymentScheduleNew.Sort("PaymentOptionNumber, PaymentDate, NumberOfCalculateFrom"+?(ThereIsOverOrder,",ExceedingOrder",""));
		
		PaymentScheduleSteps.Clear();
		For Each Page1 In StagesOfPaymentScheduleNew Do
			FillPropertyValues(PaymentScheduleSteps.Add(),Page1);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion
