
////////////////////////////////////////////////////////////////////////////////
// The "Stages of Payment Server" module contains procedures and functions for 
// working with the mechanism of payment stages,
// primarily filling in the payment stages of various objects.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

//Performs filling/cleaning/redistribution of the phases of the schedule of payments
//
// Parameters:
// 	Object - DocumentObject, CatalogObject, ClientApplicationForm - The object being processed.
// 	AugmentedMechanismParameters - See ARAPAccountingServer.AugmentedMechanismParameters
// 	TableOfStagesOfPaymentSchedule - ValueTable - Unloading the tabular part of the payment stagesgraphicoply
// 
Procedure CheckAndFillInPaymentScheduleStages(Object, Val AugmentedMechanismParameters = Undefined, TableOfStagesOfPaymentSchedule = Undefined) Export
	
	If TypeOf(Object) <> Type("ClientApplicationForm") And AugmentedMechanismParameters = Undefined Then
		ObjectManager = Common.ObjectManagerByRef(Object.Ref);
		MechanismParameters = ObjectManager.SettlementParameters_(Object);
		AugmentedMechanismParameters = ARAPAccountingServer.AugmentedMechanismParameters(Object, MechanismParameters);
	EndIf;
	
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Object, "ARAPAccounting");
	EndIf;
	
	SystemSettings_ = AugmentedMechanismParameters.SystemSettings_;
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) And Not ValueIsFilled(ParametersStructure.PaymentDate) Then
			Continue;
		EndIf;
		
		ChangesPaymentPlan            = ParametersStructure.ChangesPaymentPlan Or ParametersStructure.OrderAsAProformaInvoice;
		ExecutionScheduleIsSpecified         = ParametersStructure.ExecutionScheduleIsSpecified;
		ContractSchedule      = ParametersStructure.ContractSchedule;
		ThisIsSalePurchase             = ParametersStructure.ThisIsSalePurchase;
		ThisIsOrder                      = ParametersStructure.ThisIsOrder;
		
		ARAPObjectSettings           = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
		Terms                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Terms);
		If SystemSettings_.UsePaymentSchedules Then
			PaymentSchedule          = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PaymentSchedule);
		Else
			PaymentSchedule          = Catalogs.PaymentSchedules.EmptyRef();
		EndIf;
		InvoiceForOrders        = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.InvoiceForOrders, , False);
		OrderingCaps = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.OrderBase);
		OrderingCaps = ?(OrderingCaps = Undefined, Documents.SalesOrder.EmptyRef(),OrderingCaps);
	
		DocumentDate             = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
		DateOfShipment              = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfShipment);
		ApprovalDate          = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ApprovalDate);
		If ThisIsOrder Then
			OrderDate            = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
		Else
			OrderDate = Date(1,1,1);
		EndIf;
		DateOfTransferOfTitleToGoods = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfTransferOfTitleToGoods);
		Calendar                      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Calendar);
		
		If Not ValueIsFilled(DocumentDate) Then
			DocumentDate = CurrentSessionDate();
		EndIf;
		
		AgreementScheduleIsFilledIn = PaymentStepsServerCall.AgreementScheduleIsFilledIn(Terms);
		
		//If the source of the sums is the tabular part, then first we get the table and count the totals on it.
		If ParametersStructure.SourceOfAmountsTabularPart Then
			If TypeOf(Object) = Type("ClientApplicationForm") Then
				OrderAmounts                 = ARAPAccountingServer.TableOfOrderAmounts(Object.Object,ParametersStructure);
			Else
				OrderAmounts                 = ARAPAccountingServer.TableOfOrderAmounts(Object,ParametersStructure);
			EndIf;
			If TypeOf(Object) = Type("ClientApplicationForm") Then
				DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object.Object, ParametersStructure, OrderAmounts);
			Else
				DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure, OrderAmounts);
			EndIf;
		Else
			//Otherwise, we first count the amounts from the header, and then create a table for calculating the stages.
			If TypeOf(Object) = Type("ClientApplicationForm") Then
				DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object.Object, ParametersStructure);
			Else
				DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure);
			EndIf;
			
			OrderAmounts = New ValueTable;
			OrderAmounts.Columns.Add("OrderDocument", New TypeDescription(OrderTypes()));
			OrderAmounts.Columns.Add("ExceedingOrder", New TypeDescription("Boolean"));
			OrderAmounts.Columns.Add("Date", Common.DateTypeDetails(DateFractions.Date));
			OrderAmounts.Columns.Add("ApprovalDate", Common.DateTypeDetails(DateFractions.Date));
			OrderAmounts.Columns.Add("DateOfShipment", Common.DateTypeDetails(DateFractions.Date));
			OrderAmounts.Columns.Add("PaymentAmount", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
			OrderAmounts.Columns.Add("PackageDepositValue", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
			OrderAmounts.Columns.Add("AmountARAP", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
			OrderAmounts.Columns.Add("AmountARAPByPackage", Metadata.DefinedTypes.MonetaryAmountNonNegative.Type);
			
			NwRw = OrderAmounts.Add();
			NwRw.OrderDocument = OrderingCaps;
			NwRw.Date = DocumentDate;
			NwRw.ApprovalDate = ApprovalDate;
			NwRw.DateOfShipment = DateOfShipment;
			NwRw.PaymentAmount = DocumentAmounts.DocumentAmount;
			NwRw.PackageDepositValue = DocumentAmounts.PackageDepositValue;
			NwRw.AmountARAP = DocumentAmounts.AmountARAP;
			NwRw.AmountARAPByPackage = DocumentAmounts.AmountARAPByPackage;
			
		EndIf;
		
		//One payment date
		If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			If ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PaymentDate)) Then
				Continue;
			EndIf;
			
			PaymentScheduleSteps = New ValueTable;
			
			PaymentScheduleSteps.Columns.Add("OrderDocument",  New TypeDescription(OrderTypes()));
			PaymentScheduleSteps.Columns.Add("ExceedingOrder");
			PaymentScheduleSteps.Columns.Add("PaymentOption");
			PaymentScheduleSteps.Columns.Add("PaymentDate", Common.DateTypeDetails(DateFractions.Date));
			PaymentScheduleSteps.Columns.Add("Move", Common.TypeDescriptionNumber(10));
			PaymentScheduleSteps.Columns.Add("PaymentAmount", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
			PaymentScheduleSteps.Columns.Add("PackageDepositValue", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
			PaymentScheduleSteps.Columns.Add("AmountARAP", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
			PaymentScheduleSteps.Columns.Add("AmountARAPByPackage", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
			PaymentScheduleSteps.Columns.Add("MeasuringGoodsVarianceAmount", Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type);
			PaymentScheduleSteps.Columns.Add("PaymentPercentage", Common.TypeDescriptionNumber(5,2));
			PaymentScheduleSteps.Columns.Add("PackageDepositPercentage", Common.TypeDescriptionNumber(5,2));
			PaymentScheduleSteps.Columns.Add("CalculateFrom");
			PaymentScheduleSteps.Columns.Add("Formula");
			
		Else
			//table of payment stages
			If TableOfStagesOfPaymentSchedule = Undefined Then
				StagesOfPaymentDetails = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.PathToTSDataPaymentSteps);
				PaymentScheduleSteps = StagesOfPaymentDetails.Data[StagesOfPaymentDetails.Name];
			Else
				PaymentScheduleSteps = TableOfStagesOfPaymentSchedule;
			EndIf;
		EndIf;
		
		//If there should be no schedule.
		If Not ChangesPaymentPlan
			Or (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments") And ThisIsOrder And Not ThisIsSalePurchase)
			Or (ExecutionScheduleIsSpecified And ThisIsOrder
					And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
						Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"))) Then
			PaymentScheduleSteps.Clear();
			Continue;
		EndIf;
		
		// Checking changes in the amount of invoices for orders by orders and the Over-order attribute
		If InvoiceForOrders 
			And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
			And Not ExecutionScheduleIsSpecified 
			And PaymentScheduleSteps.Count() > 0 Then
			
			ClearStagesOfPaymentScheduleONChangingCompositionOfOrder(Object, ParametersStructure, PaymentScheduleSteps);
			
		EndIf;
		
		//Deviations of measured goods
		ThereAreDeviationsOfDimensionalGoods = False;
		If PaymentScheduleSteps.Count() > 0 Then
			ThereAreDeviationsOfDimensionalGoods = CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0],"MeasuringGoodsVarianceAmount");
		EndIf;
		
		AmountOfPaymentStages       = PaymentScheduleSteps.Total("PaymentAmount");
		If PaymentScheduleSteps.Count() > 0 And CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0], "PackageDepositValue") Then
			AmountOfCollateralByStages     = PaymentScheduleSteps.Total("PackageDepositValue");
		Else
			AmountOfCollateralByStages = 0;
		EndIf;
		
		If ThisIsSalePurchase 
			And PaymentScheduleSteps.Count() > 0 
			And CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0], "AmountARAP")Then
			AmountOfMutualSettlementsStages = PaymentScheduleSteps.Total("AmountARAP");
		Else
			AmountOfMutualSettlementsStages = 0;
		EndIf;
		
		If ThisIsSalePurchase And ValueIsFilled(ParametersStructure.AmountARAPByPackage) Then
			AmountOfMutualSettlementsByContainerStages = PaymentScheduleSteps.Total("AmountARAPByPackage");
		Else
			AmountOfMutualSettlementsByContainerStages = 0;
		EndIf;
		
		If ThereAreDeviationsOfDimensionalGoods Then
			AmountOfDeviationByStages = PaymentScheduleSteps.Total("MeasuringGoodsVarianceAmount");
		Else
			AmountOfDeviationByStages = 0;
		EndIf;
		
		AmountOfPaymentDeviation = ?(AmountOfPaymentStages+AmountOfCollateralByStages = 0,0,
									Round(AmountOfDeviationByStages * AmountOfPaymentStages /(AmountOfPaymentStages+AmountOfCollateralByStages),2));
		
		NumberOfStages = PaymentScheduleSteps.Count();
		
		If DocumentAmounts.AmountOfDocumentWithoutCollateral = 0 And DocumentAmounts.PackageDepositValue = 0 And NumberOfStages > 0 Then
			PaymentScheduleSteps.Clear();
		ElsIf DocumentAmounts.AmountOfDocumentWithoutCollateral - AmountOfPaymentDeviation <> AmountOfPaymentStages
			Or DocumentAmounts.PackageDepositValue-(AmountOfDeviationByStages - AmountOfPaymentDeviation) <> AmountOfCollateralByStages 
			Or DocumentAmounts.AmountOfSettlementsWithoutCollateral <> AmountOfMutualSettlementsStages 
			Or DocumentAmounts.AmountARAPByPackage <> AmountOfMutualSettlementsByContainerStages Then
			
			//FillType
			If NumberOfStages = 0 Then
				
				//Invoice for orders
				If Not ThisIsOrder 
					And InvoiceForOrders And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
					And Not (ExecutionScheduleIsSpecified And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
													Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)) Then
					
					FillParameters = PaymentStepsServer.ParametersForFillingPaymentStagesForOrders();
					FillParameters.DateOfShipment                   = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
					FillParameters.DateOfTransferOfTitleToGoods = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfTransferOfTitleToGoods);
					FillParameters.ThereIsDateOfTransferOfOwnership = ParametersStructure.ThereIsDateOfTransferOfOwnership;
					FillParameters.TabularSection                 = OrderAmounts;
					FillParameters.ARAPObjectSettings                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
					FillParameters.TheseAreSettlementsWithCustomers           = ParametersStructure.CustomerSettlementDocument;
					FillParameters.Calendar                      = Calendar;
					FillParameters.ThisIsTransferOfOwnership2_5 = ParametersStructure.ThisIsTransferOfOwnership2_5;
					
					PaymentStepsServer.FillInPaymentStagesOfDocumentForOrders(PaymentScheduleSteps, FillParameters);
					
				//Order or invoice not for orders
				Else
					
					FillParameters = PaymentStepsServer.ParametersForFillingInPaymentStages();
					FillParameters.TheseAreSettlementsWithCustomers   = ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
					FillParameters.InvoiceForOrders     = InvoiceForOrders;
					FillParameters.ThisIsOrder               = ParametersStructure.ThisIsOrder;
					FillParameters.NoPrepaymentControl  = ParametersStructure.NoPrepaymentControl;
					FillParameters.ARAPObjectSettings        = ARAPObjectSettings;
					FillParameters.OrderDate             = OrderDate;
					FillParameters.ApprovalDate       = ApprovalDate;
					If StrOccurrenceCount(ParametersStructure.DateOfShipment, ".") > 1
						Or ParametersStructure.ThisIsTransferOfOwnership2_5 Then
						FillParameters.TabularSection = OrderAmounts;
					Else
						FillParameters.DateOfShipment = DateOfShipment;
					EndIf;
					FillParameters.AgreementScheduleIsFilledIn       = AgreementScheduleIsFilledIn;
					FillParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
					FillParameters.ThereIsDateOfTransferOfOwnership = ParametersStructure.ThereIsDateOfTransferOfOwnership;
					FillParameters.Terms                     = Terms;
					FillParameters.ContractSchedule       = ContractSchedule;
					FillParameters.PaymentSchedule                   = PaymentSchedule;
					FillParameters.PayAmount                    = DocumentAmounts.AmountOfDocumentWithoutCollateral;
					FillParameters.PackageDepositValue              = DocumentAmounts.PackageDepositValue;
					FillParameters.AmountARAP            = DocumentAmounts.AmountOfSettlementsWithoutCollateral;
					FillParameters.AmountARAPByPackage      = DocumentAmounts.AmountARAPByPackage;
					FillParameters.ThisIsTransferOfOwnership2_5 = ParametersStructure.ThisIsTransferOfOwnership2_5;
					
					PaymentStepsServer.FillInPaymentStages(
							PaymentScheduleSteps,
							FillParameters);
							
				EndIf;
			//Redistribution of amounts
			Else
					
				If InvoiceForOrders 
					And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
					//The order is like an invoice - you do not need to distribute anything, because the order did not make movements
					And Not (ParametersStructure.CustomerSettlementDocument And ParametersStructure.OrderAsAProformaInvoice) 
					And Not ExecutionScheduleIsSpecified Then
					
					StagesOfPaymentDetails            = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.PathToTSDataPaymentSteps);
					If Not ValueIsFilled(StagesOfPaymentDetails.Name) Then
						Continue;
					Else
						PaymentScheduleSteps = StagesOfPaymentDetails.Data[StagesOfPaymentDetails.Name];
					EndIf;
					
					Terms = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Terms);
					
					DistributionParameters = PaymentStepsServer.ParametersForFillingPaymentStagesForOrders();
					DistributionParameters.TabularSection                 = OrderAmounts;
					DistributionParameters.ARAPObjectSettings                = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
					DistributionParameters.TheseAreSettlementsWithCustomers           = ParametersStructure.CustomerSettlementDocument;
					DistributionParameters.DateOfShipment                   = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
					DistributionParameters.DateOfTransferOfTitleToGoods = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfTransferOfTitleToGoods);
					DistributionParameters.Calendar                      = Calendar;
					
					PaymentStepsServer.DistributeAmountsOfDocumentPaymentStagesByOrders(PaymentScheduleSteps, DistributionParameters);
					
				Else
					
					PaymentStepsClientServer.DistributeAmountByStagesOfPaymentSchedule(
						PaymentScheduleSteps,
						DocumentAmounts.AmountOfDocumentWithoutCollateral,
						DocumentAmounts.PackageDepositValue,
						DocumentAmounts.AmountOfSettlementsWithoutCollateral,
						DocumentAmounts.AmountARAPByPackage);
					
				EndIf;
				
			EndIf;
			
			PaymentStepsServer.FillInInterestOnAmounts(PaymentScheduleSteps);
			
		EndIf;
		
		If TableOfStagesOfPaymentSchedule = Undefined Then
			AugmentedMechanismParameters.NotifyAboutCompletionOfStages = True;
			If Not TypeOf(Object) = Type("ClientApplicationForm") Then
				Object.AdditionalProperties.Insert("NotifyAboutCompletionOfStages", True);
			EndIf;
		EndIf;
			
		//One payment date
		If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			SimplifiedData = PaymentStepsServer.SimplifiedModeData(PaymentScheduleSteps,DateOfShipment,False,Calendar);
			Attribute = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.PaymentDate);
			
			If Not ValueIsFilled(Attribute.Data[Attribute.Name]) Then
				Attribute.Data[Attribute.Name] = SimplifiedData.DateCredit;
			EndIf;
		EndIf;
		
	EndDo;
	
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		ARAPAccountingFormWork.UpdateHyperlinkTextPaymentSteps(Object);
	EndIf;
	
EndProcedure

Procedure CheckCompletionOfPaymentScheduleStages(Object, Cancel, Val AugmentedMechanismParameters = Undefined) Export
	
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Object, "ARAPAccounting");
	EndIf;
	
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		
		ExecutionScheduleIsSpecified     = ParametersStructure.ExecutionScheduleIsSpecified;
		ARAPObjectSettings           = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPObjectSettings);
		PaymentDate               = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PaymentDate);
		Date                      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
		ARAPCurrency      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ARAPCurrency);
		StagesOfPaymentDetails       = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure.PathToTSDataPaymentSteps);
		
		If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) And Not ValueIsFilled(ParametersStructure.PaymentDate) 
			Or Not ParametersStructure.ChangesPaymentPlan And Not ParametersStructure.OrderAsAProformaInvoice
			Or ParametersStructure.ThisIsOrder And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByARAPDocuments")
												Or ExecutionScheduleIsSpecified And (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts")
																			Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")))
			 Then
			Continue;
		EndIf;
		
		DocumentAmounts = ARAPAccountingInternal.DocumentAmounts(Object, ParametersStructure);
		
		If ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			
			PaymentScheduleSteps = StagesOfPaymentDetails.Data[StagesOfPaymentDetails.Name];
			
			StructureOfVerificationParameters = PaymentStepsServer.ParametersForCheckingWhetherStagesAreFilledInCorrectly();
			StructureOfVerificationParameters.Date                   = Date;
			StructureOfVerificationParameters.Currency                 = ARAPCurrency;
			StructureOfVerificationParameters.ThisIsOrder               = ParametersStructure.ThisIsOrder;
			StructureOfVerificationParameters.InvoiceSourceOfGraph = TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.ThisIsSalePurchase)
																			And Not TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.InvoiceForOrders,,False)
																			And Not ParametersStructure.ExecutionScheduleIsSpecified;
			StructureOfVerificationParameters.PaymentStepsText     = ParametersStructure.PaymentStepsText;
			StructureOfVerificationParameters.PaymentAmountAgainstTheDocument = DocumentAmounts.AmountOfDocumentWithoutCollateral;
			StructureOfVerificationParameters.DepositAmountUnderTheDocument = DocumentAmounts.PackageDepositValue;
			
			PaymentStepsServer.CheckCorrectnessOfPaymentScheduleStages(
					PaymentScheduleSteps,
					Cancel,
					StructureOfVerificationParameters,
					False,
					True);
			
		ElsIf ValueIsFilled(ParametersStructure.PaymentDate)
			And TypeOf(TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.Ref)) <> Type("DocumentRef.SaleAdjustment")
			And TypeOf(TMCommonUseClientServer.DataAlongWay(Object,ParametersStructure.Ref)) <> Type("DocumentRef.PurchaseAdjustment") Then
			
			// We do not perform verification if payment is not required
			If ValueIsFilled(ParametersStructure.PathToTSData) Then
				TabularSection = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData);
				PaymentIsNotRequired = True;
				For Each TableRow In TabularSection Do
					If TableRow[ParametersStructure.PropsNameTSAmountWithVAT] > 0 Then
						PaymentIsNotRequired = False;
						Break;
					EndIf;
				EndDo;
			Else
				PaymentIsNotRequired = DocumentAmounts.DocumentAmount <= 0;
			EndIf;
			
			If Not PaymentIsNotRequired Then
				PaymentStepsServer.CheckIfPaymentDateIsCorrect(PaymentDate, Date, Cancel);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#Region CompletingPaymentStagesForOrders

// Returns a structure with parameters for filling in payment stages for orders.
// 
// Returns:
//  Structure - Parameters For Filling In Payment Stages:
// * DateOfShipment                    - Date - The date of the current invoice (if one).
// * Calendar                       - CatalogRef.BusinessCalendars - Calendar, if payment is made only on business days of the calendar.
// * DateOfTransferOfTitleToGoods  - Date - Date of transfer of ownership.
// * ThereIsDateOfTransferOfOwnership - Boolean - The date of transfer of ownership is in the document.
// * TabularSection                  - See Documents.CustomerInvoice.OrderAmounts
// * ARAPObjectSettings                 - EnumRef.ARAPObjectSettings - The procedure for calculating the document.
// * TheseAreSettlementsWithCustomers            - Boolean, Undefined - It is true if these are settlements with customers.
// * ThisIsTransferOfOwnership2_5 - Boolean - Sign of transfer of ownership 2.5.
//
Function ParametersForFillingPaymentStagesForOrders() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DateOfShipment",                      Date(1,1,1));
	ParametersStructure.Insert("Calendar",                         Catalogs.BusinessCalendars.EmptyRef());
	ParametersStructure.Insert("DateOfTransferOfTitleToGoods",    Date(1,1,1));
	ParametersStructure.Insert("ThereIsDateOfTransferOfOwnership",False);
	ParametersStructure.Insert("TabularSection",                    New ValueTable);
	ParametersStructure.Insert("ARAPObjectSettings",                   Enums.ARAPObjectSettings.EmptyRef());
	ParametersStructure.Insert("TheseAreSettlementsWithCustomers",              Undefined);
	ParametersStructure.Insert("ThisIsTransferOfOwnership2_5",   False);
	
	Return ParametersStructure;
	
EndFunction

// Fills in the PM stages of the payment graph according to the transmitted parameter structure.
// 
// Parameters:
//  PaymentScheduleSteps - ValueTable - A table of stages to fill in.
//  Parameters - See ParametersForFillingPaymentStagesForOrders
//
Procedure FillInPaymentStagesOfDocumentForOrders(PaymentScheduleSteps, Parameters) Export
	
	DateOfShipment = ?(Parameters.DateOfShipment = Date(1,1,1), BegOfDay(CurrentSessionDate()), Parameters.DateOfShipment);
	
	QueryText = "
	|SELECT 
	|	GoodsTable.OrderDocument AS OrderDocument,
	|	GoodsTable.ExceedingOrder AS ExceedingOrder,
	|	GoodsTable.PaymentAmount AS PaymentAmount,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	GoodsTable.PackageDepositValue AS PackageDepositValue,
	|	GoodsTable.AmountARAPByPackage AS AmountARAPByPackage
	|INTO TTDocumentData_
	|FROM &GoodsTable AS GoodsTable
	|;
	|
	|SELECT
	|	DocumentData.OrderDocument                    AS OrderDocument,
	|	DocumentData.OrderDocument.Date               AS OrderDate,
	|	DocumentData.OrderDocument.ApprovalDate   AS ApprovalDate,
	|	CASE WHEN &TheseAreSettlementsWithCustomers AND &ThisIsOrderAsInvoice
	|		THEN FALSE
	|		ELSE DocumentData.ExceedingOrder
	|	END                                    AS ExceedingOrder,
	|	SUM(DocumentData.PaymentAmount)      AS PaymentAmount,
	|	CASE WHEN SUM(DocumentData.AmountARAP) = 0 
	|		THEN SUM(DocumentData.PaymentAmount) 
	|		ELSE SUM(DocumentData.AmountARAP)
	|	END                                    AS AmountARAP,
	|	SUM(DocumentData.PackageDepositValue) AS PackageDepositValue,
	|	CASE WHEN SUM(DocumentData.AmountARAPByPackage) = 0 
	|		THEN SUM(DocumentData.PackageDepositValue) 
	|		ELSE SUM(DocumentData.AmountARAPByPackage)
	|	END                                    AS AmountARAPByPackage
	|FROM
	|	TTDocumentData_ AS DocumentData
	|GROUP BY
	|	DocumentData.OrderDocument,
	|	DocumentData.ExceedingOrder,
	|	CASE WHEN &TheseAreSettlementsWithCustomers AND &ThisIsOrderAsInvoice
	|		THEN FALSE
	|		ELSE DocumentData.ExceedingOrder
	|	END
	|;";
	
	QueryText = QueryText + "
	|SELECT
	|	Orders.OrderDocument AS OrderDocument,
	|	Orders.Move AS Move,
	|	Orders.PaymentOption AS PaymentOption,
	|	Orders.CalculateFrom AS CalculateFrom,
	|	Orders.Formula AS Formula,
	|	Orders.PaymentDate AS PaymentDate,
	|	SUM(Orders.PaymentAmount) AS PaymentAmount,
	|	SUM(Orders.PackageDepositValue) AS PackageDepositValue,
	|	CAST(SUM(Orders.PaymentPercentage) AS NUMBER(13,10)) AS PaymentPercentage,
	|	CAST(SUM(Orders.PackageDepositPercentage) AS NUMBER(13,10)) AS PackageDepositPercentage,
	|	Orders.Calendar AS Calendar
	|FROM ("; //@Query-part-1
	
	If ARAPAccountingClientServer.IsTabularSection(PaymentScheduleSteps) Then
		TypesList = PaymentScheduleSteps.Columns.OrderDocument.ValueType.Types();
	Else
		ValueTable = PaymentScheduleSteps.Unload(); //ValueTable
		TypesList = ValueTable.Columns.OrderDocument.ValueType.Types();
	EndIf;
	
	For Each Type In TypesList Do
		
		QueryText = QueryText + "
		|SELECT
		|	Orders.Ref AS OrderDocument,
		|	Orders.Move AS Move,
		|	Orders.PaymentOption AS PaymentOption,
		|	Orders.CalculateFrom AS CalculateFrom,
		|	Orders.Formula AS Formula,
		|	CASE WHEN Orders.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.FixedDate)
		|		THEN Orders.PaymentDate
		|		ELSE DATETIME(1,1,1)
		|	END AS PaymentDate,
		|	Orders.PaymentAmount AS PaymentAmount,
		|	Orders.PackageDepositValue AS PackageDepositValue,
		|	Orders.PaymentPercentage AS PaymentPercentage,
		|	Orders.PackageDepositPercentage AS PackageDepositPercentage,
		|	&Calendar AS Calendar
		|FROM
		|	&PaymentScheduleSteps AS Orders
		|WHERE
		|	Orders.Ref IN (&OrderList)
		|";
		
		QueryText = StrReplace(QueryText, "&PaymentScheduleSteps", Metadata.FindByType(Type).FullName()+".PaymentScheduleSteps");
		If Parameters.TheseAreSettlementsWithCustomers 
			And Metadata.FindByType(Type).Attributes.Find("PaymentSchedule") <> Undefined Then
			QueryText = StrReplace(QueryText, "&Calendar", "Orders.Ref.PaymentSchedule.Calendar");
		Else
			QueryText = StrReplace(QueryText, "&Calendar", "VALUE(Catalog.BusinessCalendars.EmptyRef)");
		EndIf;
		
		If Type <> TypesList[TypesList.Count()-1] Then
			
			QueryText = QueryText + "
			|UNION ALL
			|"
			
		EndIf;
		
	EndDo;
	
	QueryText = QueryText + ") AS Orders
	|
	|GROUP BY
	|	OrderDocument,
	|	PaymentDate,
	|	Formula,
	|	Move,
	|	PaymentOption,
	|	CalculateFrom,
	|	Calendar
	|";
	
	If Parameters.TabularSection.Count() > 0
		And (TypeOf(Parameters.TabularSection[0].OrderDocument) = Type("DocumentRef.SalesOrder")
		Or TypeOf(Parameters.TabularSection[0].OrderDocument) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")) Then
		QueryText = StrReplace(QueryText, "&ThisIsOrderAsInvoice", "DocumentData.OrderDocument.ThisIsOrderAsInvoice");
	Else
		// for all other types of documents, advanced order features are used
		QueryText = StrReplace(QueryText, "&ThisIsOrderAsInvoice", "FALSE");
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = QueryText;
	Query.SetParameter("GoodsTable", Parameters.TabularSection);
	Query.SetParameter("OrderList", Parameters.TabularSection.UnloadColumn("OrderDocument"));
	Query.SetParameter("TheseAreSettlementsWithCustomers", Parameters.TheseAreSettlementsWithCustomers);
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	Orders           = Results[1].Unload();
	StageLines_     = Results[2].Unload();
	StageLines_.Indexes.Add("OrderDocument");
	
	PaymentScheduleSteps.Clear();
	
	If Not ARAPAccountingClientServer.IsTabularSection(PaymentScheduleSteps) Then
		OrderStages = PaymentScheduleSteps.Unload();
		StagesOfPaymentScheduleNew = PaymentScheduleSteps.Unload();
	Else
		OrderStages = PaymentScheduleSteps.Copy();
		StagesOfPaymentScheduleNew = PaymentScheduleSteps.Copy();
	EndIf;
	
	For Each OrderLine In Orders Do
		
		// The percentage rounded to two decimal places is stored in the order Attribute. We calculate the percentages with an accuracy of 10 digits
		OrderSchedule = StageLines_.Copy(New Structure("OrderDocument",OrderLine.OrderDocument));
		PaymentAmountArray = OrderSchedule.UnloadColumn("PaymentAmount");
		ArrayOfDepositValueForContainer = OrderSchedule.UnloadColumn("PackageDepositValue");
		ArrayOfPaymentPercentages = TMCommonUseClientServer.DistributeProportionally(100, PaymentAmountArray, 10);
		ArrayOfPercentagesOfDepositForContainer = TMCommonUseClientServer.DistributeProportionally(100, ArrayOfDepositValueForContainer, 10);
		For IndexOf = 0 To OrderSchedule.Count() - 1 Do
			OrderSchedule[IndexOf].PaymentPercentage = ?(ArrayOfPaymentPercentages = Undefined, 0, ArrayOfPaymentPercentages[IndexOf]);
			OrderSchedule[IndexOf].PackageDepositPercentage = ?(ArrayOfPercentagesOfDepositForContainer = Undefined, 0,  ArrayOfPercentagesOfDepositForContainer[IndexOf]);
		EndDo;
		
		FillParameters = ParametersForFillingInPaymentStages();
		
		If Parameters.ThisIsTransferOfOwnership2_5 Then
			Filter = New Structure;
			Filter.Insert("OrderDocument", OrderLine.OrderDocument);
			Filter.Insert("ExceedingOrder", OrderLine.ExceedingOrder);
			OrderShipmentDates = Parameters.TabularSection.Copy(Filter, "DateOfShipment, PaymentAmount, PackageDepositValue");
			If OrderShipmentDates.Count() > 0 Then
				FillParameters.TabularSection = OrderShipmentDates;
			Else
				FillParameters.DateOfShipment = DateOfShipment;
			EndIf;
		Else
			FillParameters.DateOfShipment = DateOfShipment;
		EndIf;
		
		FillParameters.OrderDate = OrderLine.OrderDate;
		FillParameters.ApprovalDate = OrderLine.ApprovalDate;
		FillParameters.DateOfTransferOfTitleToGoods = Parameters.DateOfTransferOfTitleToGoods;
		FillParameters.ThereIsDateOfTransferOfOwnership = Parameters.ThereIsDateOfTransferOfOwnership;
		FillParameters.PackageDepositValue = OrderLine.PackageDepositValue;
		FillParameters.PayAmount = OrderLine.PaymentAmount;
		FillParameters.Calendar = Parameters.Calendar;
		FillParameters.ScheduleTemplate = OrderSchedule;
		FillParameters.InvoiceForOrders = True;
		FillParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders;
		FillParameters.ThisIsOrder = False;
		FillParameters.TheseAreSettlementsWithCustomers = Parameters.TheseAreSettlementsWithCustomers;
		
		FillInPaymentStagesOfDocumentUsingTemplate(OrderStages, FillParameters);
		
		AmountOfSettlementsForDistribution = OrderLine.AmountARAP;
		AmountOfMutualSettlementsOnContainersForDistribution = OrderLine.AmountARAPByPackage;
		
		For Each Page1 In OrderStages Do
			NwRw = StagesOfPaymentScheduleNew.Add();
			FillPropertyValues(NwRw, Page1);
			NwRw.OrderDocument = OrderLine.OrderDocument;
			NwRw.ExceedingOrder = OrderLine.ExceedingOrder;
			
			If Page1 = OrderStages[OrderStages.Count()-1] Then
				NwRw.AmountARAP = AmountOfSettlementsForDistribution;
				NwRw.AmountARAPByPackage = AmountOfMutualSettlementsOnContainersForDistribution;
			Else
				If OrderLine.PaymentAmount > 0 Then
					NwRw.AmountARAP = OrderLine.AmountARAP * NwRw.PaymentAmount / OrderLine.PaymentAmount;
				EndIf;
				If OrderLine.PackageDepositValue > 0 Then
					NwRw.AmountARAPByPackage = OrderLine.AmountARAPByPackage * NwRw.PackageDepositValue / OrderLine.PackageDepositValue;
				EndIf;
			EndIf;
			
			AmountOfSettlementsForDistribution = AmountOfSettlementsForDistribution - NwRw.AmountARAP;
			AmountOfMutualSettlementsOnContainersForDistribution = AmountOfMutualSettlementsOnContainersForDistribution - NwRw.AmountARAPByPackage;
			
		EndDo;
		
		OrderStages.Clear();
		
	EndDo;
	
	MeasurementColumns = "OrderDocument,ExceedingOrder,PaymentOption,PaymentDate,Move,CalculateFrom,Formula";
	ResourceColumns = "PaymentAmount,PaymentPercentage,PackageDepositValue,PackageDepositPercentage,AmountARAP,AmountARAPByPackage";
	
	StagesOfPaymentScheduleNew.GroupBy(MeasurementColumns,ResourceColumns);
	
	FillInInterestOnAmounts(StagesOfPaymentScheduleNew);
	PaymentStepsClientServer.SortStageTable(StagesOfPaymentScheduleNew);
	
	For Each Page1 In StagesOfPaymentScheduleNew Do
		FillPropertyValues(PaymentScheduleSteps.Add(),Page1);
	EndDo;
	
EndProcedure

// Distributes the amount of the document on the interest graph
// 
// Parameters:
//  PaymentScheduleSteps -ValueTable - Stages of the payment schedule.
//  Parameters - See ParametersForFillingPaymentStagesForOrders
//
Procedure DistributeAmountsOfDocumentPaymentStagesByOrders(PaymentScheduleSteps, Parameters) Export
	
	Query   = New Query;
	Manager = New TempTablesManager;
	Query.TempTablesManager = Manager;
	
	Amounts = Parameters.TabularSection;
	
	If ARAPAccountingClientServer.IsTabularSection(PaymentScheduleSteps) Then
		ThereIsPackage = PaymentScheduleSteps.Columns.Find("PackageDepositValue") <> Undefined;
	Else
		ValueTable = PaymentScheduleSteps.Unload(); //ValueTable
		ThereIsPackage = ValueTable.Columns.Find("PackageDepositValue") <> Undefined;
	EndIf;
	
	For Each SumString In Amounts Do
		
		GraphLines = PaymentScheduleSteps.FindRows(New Structure("OrderDocument, ExceedingOrder", SumString.OrderDocument, SumString.ExceedingOrder));
		
		PaymentAmount              = SumString.PaymentAmount;
		AmountARAP       = SumString.AmountARAP;
		PackageDepositValue         = SumString.PackageDepositValue;
		AmountARAPByPackage = SumString.AmountARAPByPackage;
		
		CurrenciesDoNotMatch = PaymentAmount = AmountARAP;
		
		AmountOfInterestPayment = 0;
		AmountOfCollateralInterest = 0;
		For Each PlotLine In GraphLines Do
			AmountOfInterestPayment = AmountOfInterestPayment + PlotLine.PaymentPercentage;
			If ThereIsPackage Then
				AmountOfCollateralInterest = AmountOfCollateralInterest + PlotLine.PackageDepositPercentage;
			EndIf;
		EndDo;
		
		For Each PlotLine In GraphLines Do
			
			IsLastRow = PlotLine = GraphLines[GraphLines.Count()-1];
			
			If PaymentAmount <> 0 And AmountOfInterestPayment <> 0 Then
				If IsLastRow Then
					PlotLine.PaymentAmount = PaymentAmount;
				Else
					PlotLine.PaymentAmount = PlotLine.PaymentPercentage / AmountOfInterestPayment * SumString.PaymentAmount;
				EndIf;
				PaymentAmount = PaymentAmount - PlotLine.PaymentAmount;
			Else
				PlotLine.PaymentAmount = 0;
			EndIf;
			
			If AmountARAP <> 0 Then
				If CurrenciesDoNotMatch Then
					PlotLine.AmountARAP = PlotLine.PaymentAmount;
				ElsIf IsLastRow Then
					PlotLine.AmountARAP = AmountARAP;
				Else
					PlotLine.AmountARAP = PlotLine.PaymentAmount / SumString.PaymentAmount * SumString.AmountARAP;
				EndIf;
				AmountARAP = AmountARAP - PlotLine.AmountARAP;
			Else
				PlotLine.AmountARAP = 0;
			EndIf;
			
			If PackageDepositValue <> 0 And AmountOfCollateralInterest <> 0 Then
				If IsLastRow Then
					PlotLine.PackageDepositValue = PackageDepositValue;
				Else
					PlotLine.PackageDepositValue = PlotLine.PackageDepositPercentage / AmountOfCollateralInterest * SumString.PackageDepositValue;
				EndIf;
				PackageDepositValue = PackageDepositValue - PlotLine.PackageDepositValue;
			ElsIf ThereIsPackage Then
				PlotLine.PackageDepositValue = 0;
			EndIf;
			
			If AmountARAPByPackage <> 0 Then
				If CurrenciesDoNotMatch Then
					PlotLine.AmountARAPByPackage = PlotLine.PackageDepositValue;
				ElsIf IsLastRow Then
					PlotLine.AmountARAPByPackage = AmountARAPByPackage;
				Else
					PlotLine.AmountARAPByPackage = PlotLine.PackageDepositValue / SumString.PackageDepositValue * SumString.AmountARAPByPackage;
				EndIf;
				AmountARAPByPackage = AmountARAPByPackage - PlotLine.AmountARAPByPackage;
			ElsIf ThereIsPackage Then
				PlotLine.AmountARAPByPackage = 0;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region CompletingPaymentStages

// Returns a structure with parameters for filling in payment stages by agreement, payment schedule, or by default.
// 
// Returns:
//  Structure - Parameters For Filling In Payment Stages:
// * OrderDate                     - Date - Order date, if any.
// * ApprovalDate               - Date - Order date, if any.
// * DateOfShipment                   - Date - The total date of shipment or a table of values with the columns "Date of shipment","Sum of payment" and "Sum of inventory".
// * TabularSection                 - See Documents.CustomerInvoice.OrderAmounts
// * DateOfTransferOfTitleToGoods - Date - Date of transfer of ownership.
// * DeadlineOfTransferOfTitleToGoods - Number - The term of transfer of ownership from the agreement.
// * PayAmount                    - Number - The total amount to be paid, excluding the deposit.
// * PackageDepositValue              - Number - The amount of the deposit for the container.
// * AmountARAP            - Number - The total amount of settlements.
// * AmountARAPByPackage      - Number - The amount of mutual settlements by container.
// 
// * AgreementScheduleIsFilledIn       - Boolean - The payment schedule is completed in the agreement.
// * Terms                     - CatalogRef.TermsOfSale, CatalogRef.TermsOfPurchaseFromVendors - An agreement, if any.
// * ContractSchedule       - DocumentRef.ContractSchedule - Schedule of the Contract, if any.
// * PaymentSchedule                   - CatalogRef.PaymentSchedules - A graph from the document, if any.
// 
// * ARAPObjectSettings                - EnumRef.ARAPObjectSettings - The procedure for calculating the document.
// * TheseAreSettlementsWithCustomers           - Boolean, Undefined - It is true if these are settlements with customers.
// * ThisIsOrder                       - Boolean, Undefined - True if it is an order.
// * NoPrepaymentControl          - Boolean, Undefined - True if you don't need to check the prepayment is full.
// * InvoiceForOrders             - Boolean, Undefined - True if it is an invoice for orders.
// 
// * ScheduleTemplate                  - Undefined,ValueTable:
// 		** PaymentOption                - EnumRef.CustomerPaymentControlOptions - Control option.
// 
// * Calendar                      - CatalogRef.BusinessCalendars - Calendar, if payment is made only on business days of the calendar.
// * ThisIsTransferOfOwnership2_5 - Boolean - Indication of shipment without transfer of ownership 2.5.
//
Function ParametersForFillingInPaymentStages() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("OrderDate",                        Date(1,1,1));
	ParametersStructure.Insert("ApprovalDate",                  Date(1,1,1));
	ParametersStructure.Insert("DateOfShipment",                      Date(1,1,1));
	ParametersStructure.Insert("DateOfReceipt",                   Date(1,1,1));
	ParametersStructure.Insert("TabularSection",                    Undefined);
	ParametersStructure.Insert("DateOfTransferOfTitleToGoods",    Date(1,1,1));
	ParametersStructure.Insert("ThereIsDateOfTransferOfOwnership", False);
	ParametersStructure.Insert("DeadlineOfTransferOfTitleToGoods",    0);
	ParametersStructure.Insert("PayAmount",                       0);
	ParametersStructure.Insert("PackageDepositValue",                 0);
	ParametersStructure.Insert("AmountARAP",               0);
	ParametersStructure.Insert("AmountARAPByPackage",         0);
	
	ParametersStructure.Insert("AgreementScheduleIsFilledIn",          False);
	ParametersStructure.Insert("Terms",                        Catalogs.TermsOfSale.EmptyRef());
	ParametersStructure.Insert("ContractSchedule",          Documents.ContractSchedule.EmptyRef());
	ParametersStructure.Insert("PaymentSchedule",                      Catalogs.PaymentSchedules.EmptyRef());
	
	ParametersStructure.Insert("ARAPObjectSettings",                   Enums.ARAPObjectSettings.EmptyRef());
	ParametersStructure.Insert("TheseAreSettlementsWithCustomers",              Undefined);
	ParametersStructure.Insert("ThisIsOrder",                          Undefined);
	ParametersStructure.Insert("NoPrepaymentControl",             False);
	ParametersStructure.Insert("InvoiceForOrders",                Undefined);
	
	ParametersStructure.Insert("ScheduleTemplate",                     Undefined);
	ParametersStructure.Insert("Calendar",                         Catalogs.BusinessCalendars.EmptyRef());
	ParametersStructure.Insert("ThisIsTransferOfOwnership2_5",   False);
	
	Return ParametersStructure;
	
EndFunction

// Fills in the stages of the payment schedule or distributes the amount already filled in in the sales documents.
//
// Parameters:
// 		PaymentScheduleSteps - ValueTable - table of payment stages.
// 		FillParameters - See ParametersForFillingInPaymentStages
//
Procedure FillInPaymentStages(PaymentScheduleSteps, FillParameters) Export
	
	If ValueIsFilled(FillParameters.ContractSchedule) 
		And Not FillParameters.ThisIsOrder Then
		FillInPaymentStagesAccordingToExecutionSchedule(PaymentScheduleSteps, FillParameters);
	ElsIf ValueIsFilled(FillParameters.PaymentSchedule) And GetFunctionalOption("UsePaymentSchedules") Then
		FillInPaymentStagesAccordingToPaymentSchedule(PaymentScheduleSteps, FillParameters);
	ElsIf FillParameters.AgreementScheduleIsFilledIn Then
		FillInPaymentStagesByAgreement(PaymentScheduleSteps, FillParameters);
	ElsIf PaymentScheduleSteps.Count() > 0 Then
		PaymentStepsClientServer.DistributeAmountByStagesOfPaymentSchedule(
			PaymentScheduleSteps,
			FillParameters.PayAmount,
			FillParameters.PackageDepositValue,
			FillParameters.AmountARAP,
			FillParameters.AmountARAPByPackage);
	ElsIf ValueIsFilled(FillParameters.TabularSection) Then
		FillInPaymentMilestonesAccordingToShipmentTable(PaymentScheduleSteps, FillParameters);
	Else
		NwRw = PaymentScheduleSteps.Add();
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "PaymentOption") Then
			If FillParameters.TheseAreSettlementsWithCustomers Then
				NwRw.PaymentOption = Enums.CustomerPaymentControlOptions.CreditPlanned;
			Else
				NwRw.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt;
			EndIf;
		EndIf;
		
		If ValueIsFilled(FillParameters.OrderDate) Then
			NwRw.PaymentDate  = FillParameters.OrderDate;
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "CalculateFrom") Then
				NwRw.CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate;
			EndIf;
		Else
			NwRw.PaymentDate  = FillParameters.DateOfShipment;
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "CalculateFrom") Then
				If FillParameters.ThisIsTransferOfOwnership2_5 Then
					NwRw.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods;
					NwRw.PaymentDate = FillParameters.DateOfTransferOfTitleToGoods;
				Else
					NwRw.CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate;
				EndIf;
				If CommonClientServer.HasAttributeOrObjectProperty(NwRw,"DateOfShipment") Then
					NwRw.DateOfShipment = FillParameters.DateOfShipment;
				EndIf;
			EndIf;
		EndIf;
		
		NwRw.PaymentAmount = FillParameters.PayAmount;
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "PackageDepositValue") Then
			NwRw.PackageDepositValue     = FillParameters.PackageDepositValue;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "AmountARAP") Then
			NwRw.AmountARAP = FillParameters.AmountARAP;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "AmountARAPByPackage") Then
			NwRw.AmountARAPByPackage = FillParameters.AmountARAPByPackage;
		EndIf;
		
	EndIf;
	
	FillInInterestOnAmounts(PaymentScheduleSteps);
	
EndProcedure

// Fills in the stages of the payment schedule in the document according to the contract execution schedule.
//
// Parameters:
// 		PaymentScheduleSteps - ValueTable - table of payment stages.
// 		FillParameters - See ParametersForFillingInPaymentStages
//
Procedure FillInPaymentStagesAccordingToExecutionSchedule(PaymentScheduleSteps, FillParameters) Export
	Query = New Query(
	"SELECT
	|	StagesOfTSPaymentSchedule.PaymentOption      AS PaymentOption,
	|	StagesOfTSPaymentSchedule.Move              AS Move,
	|	StagesOfTSPaymentSchedule.CalculateFrom     AS CalculateFrom,
	|	StagesOfTSPaymentSchedule.Formula            AS Formula,
	|	CASE
	|		WHEN CounterpartyContracts.OptionOfDeterminingExecutionScheduleInContract
	|				= VALUE(Enum.OptionsForDeterminingExecutionScheduleInContract.RegularPayments)
	|		THEN 100
	|		ELSE SUM(StagesOfTSPaymentSchedule.PaymentPercentage)
	|	END AS PaymentPercentage,
	|	0                                       AS PackageDepositPercentage,
	|	UNDEFINED                            AS PaymentMethod,
	|	CounterpartyContracts.Date 				AS ContractDate_,
	|	CASE WHEN StagesOfTSPaymentSchedule.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.FixedDate)
	|		THEN StagesOfTSPaymentSchedule.PaymentDate
	|		ELSE DATETIME(1,1,1)
	|	END                                   AS PaymentDate,
	|	ContractScheduleHeader.Calendar AS Calendar
	|FROM
	|	Document.ContractSchedule AS ContractScheduleHeader
	|		INNER JOIN
	|			Document.ContractSchedule.PaymentScheduleSteps AS StagesOfTSPaymentSchedule
	|		ON
	|			ContractScheduleHeader.Ref = StagesOfTSPaymentSchedule.Ref
	|		INNER JOIN
	|			Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON
	|			CounterpartyContracts.Ref = ContractScheduleHeader.Contract
	|WHERE
	|	ContractScheduleHeader.Ref = &ContractSchedule
	|GROUP BY
	|	StagesOfTSPaymentSchedule.PaymentOption,
	|	StagesOfTSPaymentSchedule.Move,
	|	StagesOfTSPaymentSchedule.CalculateFrom,
	|	StagesOfTSPaymentSchedule.Formula,
	|	CASE WHEN StagesOfTSPaymentSchedule.CalculateFrom = VALUE(Enum.PaymentDateCalculationOptions.FixedDate)
	|		THEN StagesOfTSPaymentSchedule.PaymentDate
	|		ELSE DATETIME(1,1,1)
	|	END,
	|	ContractScheduleHeader.Calendar,
	|	CounterpartyContracts.Date,
	|	CounterpartyContracts.OptionOfDeterminingExecutionScheduleInContract");
	
	Query.SetParameter("ContractSchedule", FillParameters.ContractSchedule);
	
	QueryResult = Query.Execute();
	Upload0         = QueryResult.Unload();
	
	If FillParameters.PayAmount = 0 Or Upload0.Count() = 0 Then
		Return;
	EndIf;
	
	FillParameters.Insert("ScheduleTemplate",Upload0);
	FillParameters.Insert("Calendar",Upload0[0].Calendar);
	FillParameters.Insert("OrderDate",Upload0[0].ContractDate_);
	
	FillInPaymentStagesOfDocumentUsingTemplate(PaymentScheduleSteps, FillParameters);
EndProcedure

// Fills in the stages of the payment schedule in the document according to the schedule specified in the agreement.
//
// Parameters:
// 		PaymentScheduleSteps - ValueTable - table of payment stages.
// 		FillParameters - See ParametersForFillingInPaymentStages
//
Procedure FillInPaymentStagesByAgreement(PaymentScheduleSteps, FillParameters) Export
	
	If TypeOf(FillParameters.Terms) = Type("CatalogRef.TermsOfSale") Then
		If GetFunctionalOption("UsePaymentSchedules") Then
			Query = New Query(
			"SELECT
			|	PaymentSchedulesStages.LineNumber AS LineNumber,
			|	PaymentSchedulesStages.PaymentOption AS PaymentOption,
			|	PaymentSchedulesStages.Move AS Move,
			|	PaymentSchedulesStages.CalculateFrom AS CalculateFrom,
			|	PaymentSchedulesStages.Formula AS Formula,
			|	PaymentSchedulesStages.PaymentPercentage AS PaymentPercentage,
			|	PaymentSchedulesStages.PackageDepositPercentage AS PackageDepositPercentage,
			|	PaymentSchedulesStages.Ref.PaymentMethod AS PaymentMethod,
			|	PaymentSchedulesStages.Ref.Calendar AS Calendar,
			|	TermsOfSale.DeadlineOfTransferOfTitleToGoods AS DeadlineOfTransferOfTitleToGoods
			|FROM
			|	Catalog.TermsOfSale AS TermsOfSale
			|		INNER JOIN Catalog.PaymentSchedules.Stages AS PaymentSchedulesStages
			|		ON TermsOfSale.PaymentSchedule = PaymentSchedulesStages.Ref
			|WHERE
			|	TermsOfSale.Ref = &Terms
			|
			|ORDER BY
			|	LineNumber");
		Else
			Query = New Query(
			"SELECT
			|	TermsOfSalePaymentScheduleSteps.LineNumber AS LineNumber,
			|	TermsOfSalePaymentScheduleSteps.PaymentOption AS PaymentOption,
			|	TermsOfSalePaymentScheduleSteps.Formula AS Formula,
			|	TermsOfSalePaymentScheduleSteps.Move AS Move,
			|	TermsOfSalePaymentScheduleSteps.CalculateFrom AS CalculateFrom,
			|	TermsOfSalePaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
			|	TermsOfSalePaymentScheduleSteps.PackageDepositPercentage AS PackageDepositPercentage,
			|	TermsOfSalePaymentScheduleSteps.Ref.PaymentMethod AS PaymentMethod,
			|	TermsOfSalePaymentScheduleSteps.Ref.Calendar AS Calendar,
			|	TermsOfSalePaymentScheduleSteps.Ref.DeadlineOfTransferOfTitleToGoods AS DeadlineOfTransferOfTitleToGoods
			|FROM
			|	Catalog.TermsOfSale.PaymentScheduleSteps AS TermsOfSalePaymentScheduleSteps
			|WHERE
			|	TermsOfSalePaymentScheduleSteps.Ref = &Terms
			|ORDER BY
			|	LineNumber");
			FillParameters.TheseAreSettlementsWithCustomers = True;
		EndIf;
	Else
		Query = New Query(
		"SELECT
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.LineNumber AS LineNumber,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.PaymentOption AS PaymentOption,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Move AS Move,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.CalculateFrom AS CalculateFrom,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Formula AS Formula,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.PaymentPercentage AS PaymentPercentage,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.PackageDepositPercentage AS PackageDepositPercentage,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Ref.PaymentMethod AS PaymentMethod,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Ref.Calendar AS Calendar,
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Ref.DeadlineOfTransferOfTitleToGoods AS DeadlineOfTransferOfTitleToGoods
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors.PaymentScheduleSteps AS TermsOfPurchaseFromVendorsPaymentScheduleSteps
		|WHERE
		|	TermsOfPurchaseFromVendorsPaymentScheduleSteps.Ref = &Terms
		|ORDER BY
		|	LineNumber");
		FillParameters.TheseAreSettlementsWithCustomers = False;
	EndIf;
	
	Query.SetParameter("Terms", FillParameters.Terms);
	
	QueryResult = Query.Execute();
	Upload0         = QueryResult.Unload();
	
	If (FillParameters.PayAmount = 0 And FillParameters.PackageDepositValue = 0) Or Upload0.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	FillParameters.Insert("DeadlineOfTransferOfTitleToGoods",Upload0[0].DeadlineOfTransferOfTitleToGoods);
	FillParameters.Insert("ScheduleTemplate",Upload0);
	FillParameters.Insert("Calendar",Upload0[0].Calendar);
	
	FillInPaymentStagesOfDocumentUsingTemplate(PaymentScheduleSteps, FillParameters);
	
EndProcedure

// Fills in the stages of the payment schedule in the document according to the payment schedule specified in the agreement.
//
// Parameters:
// 		PaymentScheduleSteps - ValueTable - table of payment stages.
// 		FillParameters - See ParametersForFillingInPaymentStages
//
Procedure FillInPaymentStagesAccordingToPaymentSchedule(PaymentScheduleSteps, FillParameters) Export
	
	Query = New Query("
		|SELECT
		|	PaymentSchedulesStages.LineNumber         AS LineNumber,
		|	PaymentSchedulesStages.PaymentOption       AS PaymentOption,
		|	PaymentSchedulesStages.CalculateFrom      AS CalculateFrom,
		|	PaymentSchedulesStages.Formula             AS Formula,
		|	PaymentSchedulesStages.Move               AS Move,
		|	PaymentSchedulesStages.PaymentPercentage      AS PaymentPercentage,
		|	PaymentSchedulesStages.PackageDepositPercentage AS PackageDepositPercentage,
		|	PaymentSchedulesStages.Ref.Calendar    AS Calendar,
		|	PaymentSchedulesStages.Ref.PaymentMethod  AS PaymentMethod
		|FROM
		|	Catalog.PaymentSchedules.Stages AS PaymentSchedulesStages
		|WHERE
		|	PaymentSchedulesStages.Ref = &PaymentSchedule
		|ORDER BY
		|	LineNumber ASC
		|");
		
	Query.SetParameter("PaymentSchedule",FillParameters.PaymentSchedule);
	
	QueryResult = Query.Execute();
	Upload0         = QueryResult.Unload();
	
	If (FillParameters.PayAmount = 0 And FillParameters.PackageDepositValue = 0) Or Upload0.Count() = 0 Then
		
		PaymentScheduleSteps.Clear();
		Return;
		
	EndIf;
	
	FillParameters.Insert("ScheduleTemplate",                  Upload0);
	FillParameters.Insert("Calendar",                      Upload0[0].Calendar);
	
	FillInPaymentStagesOfDocumentUsingTemplate(PaymentScheduleSteps, FillParameters);
	
EndProcedure

// Fills in the stages of the payment schedule in the document according to the transmitted shipment table.
//
// Parameters:
// 		PaymentScheduleSteps - ValueTable - table of payment stages.
// 		FillParameters - See ParametersForFillingInPaymentStages
//
Procedure FillInPaymentMilestonesAccordingToShipmentTable(PaymentScheduleSteps, FillParameters) Export
	
	For Each ShipmentLine In FillParameters.TabularSection Do
		NwRw = PaymentScheduleSteps.Add();
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "PaymentOption") Then
			If FillParameters.TheseAreSettlementsWithCustomers Then
				NwRw.PaymentOption = Enums.CustomerPaymentControlOptions.CreditPlanned;
			Else
				NwRw.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt;
			EndIf;
		EndIf;
		
		If ValueIsFilled(FillParameters.OrderDate) Then
			NwRw.PaymentDate = FillParameters.OrderDate;
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "CalculateFrom") Then
				NwRw.CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate;
			EndIf;
		Else
			NwRw.PaymentDate = ?(ValueIsFilled(ShipmentLine.DateOfShipment),ShipmentLine.DateOfShipment,FillParameters.DateOfShipment);
			If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "CalculateFrom") Then
				If FillParameters.ThisIsTransferOfOwnership2_5 Then
					NwRw.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods;
					NwRw.PaymentDate = FillParameters.DateOfTransferOfTitleToGoods;
				Else
					NwRw.CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate;
				EndIf;
			EndIf;
		EndIf;
		
		NwRw.PaymentAmount = ShipmentLine.PaymentAmount;
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "PackageDepositValue") Then
			NwRw.PackageDepositValue     = ShipmentLine.PackageDepositValue;
		EndIf;
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw,"DateOfShipment") Then
			NwRw.DateOfShipment = ShipmentLine.DateOfShipment;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "AmountARAP") Then
			NwRw.AmountARAP = ShipmentLine.AmountARAP;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(NwRw, "AmountARAPByPackage") Then
			NwRw.AmountARAPByPackage = ShipmentLine.AmountARAPByPackage;
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the stages of the payment schedule in the document according to the transmitted template.
//
// Parameters:
// 		PaymentScheduleSteps - ValueTable - table of payment stages.
// 		FillParameters - See ParametersForFillingInPaymentStages
//
Procedure FillInPaymentStagesOfDocumentUsingTemplate(PaymentScheduleSteps, FillParameters) Export
	
	DistributedPaymentAmount = 0;
	DistributedAmountOfCollateral = 0;
	CurrentStep               = 0;
	
	ScheduleTemplate             = FillParameters.ScheduleTemplate;
	Calendar                 = FillParameters.Calendar;
	AmountOfPaymentToBeDistributed = FillParameters.PayAmount;
	AmountOfCollateralForDistribution = FillParameters.PackageDepositValue;
	
	OrderDate                     = FillParameters.OrderDate;
	ApprovalDate               = FillParameters.ApprovalDate;
	DeadlineOfTransferOfTitleToGoods = FillParameters.DeadlineOfTransferOfTitleToGoods;
	
	ThereIsPackage = CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps.Add(),"PackageDepositValue");
	ThereIsSumOfMutualSettlements = CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps.Add(),"AmountARAP");
	PaymentScheduleSteps.Clear();
	
	If ARAPAccountingClientServer.IsTabularSection(PaymentScheduleSteps) Then
		NewStagesOfPaymentSchedule = PaymentScheduleSteps.Copy();
	Else
		NewStagesOfPaymentSchedule = PaymentScheduleSteps.Unload();
	EndIf;
	
	// There is no "Loading date" column in the invoices
	If NewStagesOfPaymentSchedule.Columns.Find("DateOfShipment") = Undefined Then
		NewStagesOfPaymentSchedule.Columns.Add("DateOfShipment");
	EndIf;
	
	If FillParameters.TabularSection <> Undefined Then
		ShipmentTable = FillParameters.TabularSection;
	Else
		ShipmentTable = New ValueTable();
		ShipmentTable.Columns.Add("DateOfShipment");
		ShipmentTable.Columns.Add("DateOfReceipt");
		ShipmentTable.Columns.Add("PaymentAmount");
		ShipmentTable.Columns.Add("PackageDepositValue");
		NwRw = ShipmentTable.Add();
		NwRw.DateOfShipment = FillParameters.DateOfShipment;
		NwRw.DateOfReceipt = FillParameters.DateOfReceipt;
		NwRw.PaymentAmount = FillParameters.PayAmount;
		NwRw.PackageDepositValue = FillParameters.PackageDepositValue;
	EndIf;
	
	If ShipmentTable.Columns.Find("DateOfReceipt") = Undefined Then
		ShipmentTable.Columns.Add("DateOfReceipt",Common.DateTypeDetails(DateFractions.Date))
	EndIf;
	ShipmentTable.GroupBy("DateOfShipment,DateOfReceipt","PaymentAmount,PackageDepositValue");
	
	If Not ValueIsFilled(ApprovalDate) Then
		ApprovalDate = OrderDate;
	EndIf;
	
	NumberOfStages = ScheduleTemplate.Count();
	
	// Let's define the last non-tax stage
	LastNonTaxStage = NumberOfStages;
	While LastNonTaxStage <> 0 And ScheduleTemplate[LastNonTaxStage-1].PaymentPercentage = 0 Do
		LastNonTaxStage = LastNonTaxStage - 1;
	EndDo;
	
	// Let's define the last collateral stage
	LastPledgeStage = NumberOfStages;
	While LastPledgeStage <> 0 And ScheduleTemplate[LastPledgeStage-1].PackageDepositPercentage = 0 Do
		LastPledgeStage = LastPledgeStage - 1;
	EndDo;
	
	// If the invoice is entered for the entire amount of the order, then the amounts in the stages should be taken from the order.
	CopyPaymentAmount = False;
	CopyDepositAmountForContainer = False;
	If NumberOfStages > 0 And CommonClientServer.HasAttributeOrObjectProperty(ScheduleTemplate[0],"PaymentAmount") Then
		If ScheduleTemplate.Total("PaymentAmount") = AmountOfPaymentToBeDistributed Then
			CopyPaymentAmount = True;
		EndIf;
		If ScheduleTemplate.Total("PackageDepositValue") = AmountOfCollateralForDistribution Then
			CopyDepositAmountForContainer = True;
		EndIf;
	EndIf;
	
	ThisIsInvoiceWithoutSchedule = Not FillParameters.ThisIsOrder 
				And (Not FillParameters.InvoiceForOrders Or FillParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments)
				And (Not ValueIsFilled(FillParameters.ContractSchedule) Or FillParameters.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments);
	
	// We will fill in the stages according to the payment schedule
	For Each Stage In ScheduleTemplate Do
		
		CurrentStep                     = CurrentStep + 1;
		
		If Not (AmountOfPaymentToBeDistributed <> 0 And Stage.PaymentPercentage <> 0
					Or AmountOfCollateralForDistribution <> 0 And Stage.PackageDepositPercentage <> 0) Then
			Continue;
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(Stage, "Calendar") Then
			Calendar = Stage.Calendar;
		EndIf;
		
		// Reduction of the waybill reference option without an order to "before the date of shipment" or "from the date of shipment".
		If ThisIsInvoiceWithoutSchedule Then
			If (Stage.CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate 
				Or Stage.CalculateFrom = Enums.PaymentDateCalculationOptions.FromApprovalDate) Then
		
				If Stage.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment
					Or Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
					Or Stage.PaymentOption = Enums.CustomerPaymentControlOptions.CreditPlanned
					Or Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt Then
					Stage.CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate;
					Stage.Move          = 0;
				Else
					Stage.CalculateFrom = Enums.PaymentDateCalculationOptions.BeforeShipmentDate;
					Stage.Move          = 0;
				EndIf;
			EndIf;
			
			If Stage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision Then
				Stage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment;
			EndIf;
			
			If Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation Then
				Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt;
			EndIf;
		EndIf;
		
		If Not PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(Stage.CalculateFrom, Stage.Formula) Then
			PaymentScheduleStage                = NewStagesOfPaymentSchedule.Add();
			PaymentScheduleStage.PaymentOption  = Stage.PaymentOption;
			PaymentScheduleStage.CalculateFrom = Stage.CalculateFrom;
			PaymentScheduleStage.Formula        = Stage.Formula;
			PaymentScheduleStage.Move          = Stage.Move;
			PaymentScheduleStage.CalculateFrom = Stage.CalculateFrom;
			
			ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
			ParametersStructure.CalculateFrom                 = PaymentScheduleStage.CalculateFrom;
			ParametersStructure.Move                          = PaymentScheduleStage.Move;
			ParametersStructure.PaymentDate                    = ?(CommonClientServer.HasAttributeOrObjectProperty(Stage,"PaymentDate"),
																	Stage.PaymentDate,
																	Date(1,1,1));
			ParametersStructure.OrderDate                     = OrderDate;
			ParametersStructure.ApprovalDate               = ApprovalDate;
			ParametersStructure.DateOfShipment                   = Date(1,1,1);
			ParametersStructure.DateOfTransferOfTitleToGoods = Date(1,1,1);
			ParametersStructure.DeadlineOfTransferOfTitleToGoods = 0;
			ParametersStructure.Calendar                      = Calendar;
			ParametersStructure.Formula                        = PaymentScheduleStage.Formula;
			
			If ValueIsFilled(Calendar)  Then
				PaymentScheduleStage.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersStructure);
			Else
				PaymentScheduleStage.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersStructure);
			EndIf;
			
			If CopyPaymentAmount Then 
				PaymentStageAmount                      = Stage.PaymentAmount;
			Else
				PaymentStageAmount                      = PaymentStageAmount(Stage, AmountOfPaymentToBeDistributed);
			EndIf;
			PaymentScheduleStage.PaymentAmount        = ?(CurrentStep = LastNonTaxStage, AmountOfPaymentToBeDistributed - DistributedPaymentAmount, PaymentStageAmount);
			PaymentScheduleStage.PaymentPercentage      = ?(PaymentStageAmount <> 0, Stage.PaymentPercentage, 0);
			DistributedPaymentAmount             = DistributedPaymentAmount + PaymentScheduleStage.PaymentAmount;
			
			If ThereIsPackage Then
				
				If CopyDepositAmountForContainer Then
					DepositStageAmount                      = Stage.PackageDepositValue;
				Else
					DepositStageAmount                      = PaymentStageAmount(Stage, AmountOfCollateralForDistribution, True);
				EndIf;
				
				PaymentScheduleStage.PackageDepositValue   = ?(CurrentStep = LastPledgeStage, AmountOfCollateralForDistribution - DistributedAmountOfCollateral, DepositStageAmount);
				PaymentScheduleStage.PackageDepositPercentage = ?(Stage.PackageDepositPercentage > 0,Stage.PackageDepositPercentage, 
					?(AmountOfCollateralForDistribution<>0 And PaymentScheduleStage.PackageDepositValue <> 0,
					(Round(PaymentScheduleStage.PackageDepositValue/AmountOfCollateralForDistribution,2,RoundMode.Round15as20))*100,
					0));
				DistributedAmountOfCollateral             = DistributedAmountOfCollateral + PaymentScheduleStage.PackageDepositValue;
			EndIf;
		Else
			
			If CopyPaymentAmount Then
				AmountOfPaymentStageToBeDistributed = Stage.PaymentAmount;
			ElsIf CurrentStep = LastNonTaxStage Then
				AmountOfPaymentStageToBeDistributed = AmountOfPaymentToBeDistributed - DistributedPaymentAmount;
			Else
				AmountOfPaymentStageToBeDistributed = PaymentStageAmount(Stage, AmountOfPaymentToBeDistributed)
			EndIf;
			
			If CopyDepositAmountForContainer Then
				AmountOfCollateralAvailableForDistribution = Stage.PackageDepositValue;
			ElsIf CurrentStep = LastPledgeStage Then
				AmountOfCollateralAvailableForDistribution = AmountOfCollateralForDistribution - DistributedAmountOfCollateral;
			Else
				AmountOfCollateralAvailableForDistribution = PaymentStageAmount(Stage, AmountOfCollateralForDistribution, True);
			EndIf;
			
			DistributedStagePaymentAmount = 0;
			DistributedAmountOfStageDeposit = 0;
			For Each ShipmentDateString In ShipmentTable Do
				
				ParametersStructure = PaymentStepsClientServer.PaymentDateCalculationParameters();
				If Stage.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods
					And Not FillParameters.ThereIsDateOfTransferOfOwnership
					Or Not ValueIsFilled(Stage.CalculateFrom) Then
					ParametersStructure.CalculateFrom                 = Enums.PaymentDateCalculationOptions.FromShipmentDate;
				Else
					ParametersStructure.CalculateFrom                 = Stage.CalculateFrom;
				EndIf;
				ParametersStructure.Move                          = Stage.Move;
				ParametersStructure.OrderDate                     = OrderDate;
				ParametersStructure.ApprovalDate               = ApprovalDate;
				ParametersStructure.DateOfShipment                   = ShipmentDateString.DateOfShipment;
				ParametersStructure.DateOfReceipt                = ShipmentDateString.DateOfReceipt;
				ParametersStructure.DateOfTransferOfTitleToGoods = FillParameters.DateOfTransferOfTitleToGoods;
				ParametersStructure.DeadlineOfTransferOfTitleToGoods = DeadlineOfTransferOfTitleToGoods;
				ParametersStructure.Calendar                      = Calendar;
				ParametersStructure.Formula                        = Stage.Formula;
				
				If ValueIsFilled(Calendar)  Then
					PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersStructure);
				Else
					PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersStructure);
				EndIf;
				
				// For control options before shipment, the payment date cannot be longer than the shipment date
				If (Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation
						Or Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt
						Or Stage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision
						Or Stage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
					And ValueIsFilled(ShipmentDateString.DateOfShipment)
					And PaymentDate > ShipmentDateString.DateOfShipment Then
					PaymentDate = ShipmentDateString.DateOfShipment;
				EndIf;
				
				PaymentScheduleStage               = NewStagesOfPaymentSchedule.Add();
				PaymentScheduleStage.PaymentOption = Stage.PaymentOption;
				PaymentScheduleStage.Move         = Stage.Move;
				PaymentScheduleStage.CalculateFrom = ParametersStructure.CalculateFrom;
				PaymentScheduleStage.Formula       = ParametersStructure.Formula;
				PaymentScheduleStage.PaymentDate   = PaymentDate;
				PaymentScheduleStage.DateOfShipment  = ShipmentDateString.DateOfShipment;
				
				PaymentScheduleStage.PaymentAmount        = ?(ShipmentDateString = ShipmentTable[ShipmentTable.Count()-1] Or AmountOfPaymentStageToBeDistributed = 0,
															AmountOfPaymentStageToBeDistributed - DistributedStagePaymentAmount,
															AmountOfPaymentStageToBeDistributed * (ShipmentDateString.PaymentAmount/AmountOfPaymentToBeDistributed));
				DistributedStagePaymentAmount         = DistributedStagePaymentAmount + PaymentScheduleStage.PaymentAmount;
				DistributedPaymentAmount              = DistributedPaymentAmount + PaymentScheduleStage.PaymentAmount;
				
				If ThereIsPackage Then
					PaymentScheduleStage.PackageDepositValue   = ?(ShipmentDateString = ShipmentTable[ShipmentTable.Count()-1] Or AmountOfCollateralAvailableForDistribution = 0,
															AmountOfCollateralAvailableForDistribution-DistributedAmountOfStageDeposit,
															AmountOfCollateralAvailableForDistribution * (ShipmentDateString.PackageDepositValue/AmountOfCollateralForDistribution));
					DistributedAmountOfStageDeposit        = DistributedAmountOfStageDeposit + PaymentScheduleStage.PackageDepositValue;
					DistributedAmountOfCollateral             = DistributedAmountOfCollateral + PaymentScheduleStage.PackageDepositValue;
				EndIf;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	If ThereIsSumOfMutualSettlements Then
		
		LastNonTaxStage = 0;
		LastPledgeStage = 0;
		For Each Page1 In NewStagesOfPaymentSchedule Do
			If Page1.PaymentAmount <> 0 Then
				LastNonTaxStage = Page1;
			EndIf;
			If ThereIsPackage And Page1.PackageDepositValue <> 0 Then
				LastPledgeStage = Page1;
			EndIf;
		EndDo;
		
		AmountOfSettlementsForDistribution = FillParameters.AmountARAP;
		AmountOfMutualSettlementsOnContainersForDistribution = FillParameters.AmountARAPByPackage;
		For Each Page1 In NewStagesOfPaymentSchedule Do
			
			If Page1 <> LastNonTaxStage And FillParameters.PayAmount <> 0 Then
				Page1.AmountARAP = Page1.PaymentAmount/FillParameters.PayAmount * FillParameters.AmountARAP
			Else
				Page1.AmountARAP = AmountOfSettlementsForDistribution;
			EndIf;
			AmountOfSettlementsForDistribution = AmountOfSettlementsForDistribution - Page1.AmountARAP;
			
			If ThereIsPackage Then
				If Page1 <> LastPledgeStage And FillParameters.PackageDepositValue <> 0 Then
					Page1.AmountARAPByPackage = Page1.PackageDepositValue/FillParameters.PackageDepositValue * FillParameters.AmountARAPByPackage
				Else
					Page1.AmountARAPByPackage = AmountOfMutualSettlementsOnContainersForDistribution;
				EndIf;
				AmountOfMutualSettlementsOnContainersForDistribution = AmountOfMutualSettlementsOnContainersForDistribution - Page1.AmountARAPByPackage;
			EndIf;
		EndDo;
		
	EndIf;
	
	MeasurementColumns = "PaymentOption, PaymentDate, Move, CalculateFrom, Formula, DateOfShipment";
	ResourceColumns = "PaymentAmount,PaymentPercentage"
	 + ?(ThereIsPackage,",PackageDepositValue,PackageDepositPercentage","")
	 + ?(ThereIsSumOfMutualSettlements,",AmountARAP","")
	 + ?(ThereIsSumOfMutualSettlements And ThereIsPackage,",AmountARAPByPackage","");
	NewStagesOfPaymentSchedule.GroupBy(MeasurementColumns, ResourceColumns);
	
	PaymentStepsClientServer.SortStageTable(NewStagesOfPaymentSchedule);
	FillInInterestOnAmounts(NewStagesOfPaymentSchedule);
	
	For Each Page1 In NewStagesOfPaymentSchedule Do
		FillPropertyValues(PaymentScheduleSteps.Add(),Page1);
	EndDo;
	
	If FillParameters.TheseAreSettlementsWithCustomers And GetFunctionalOption("UseSimplifiedPaymentSchemeInSales")
		Or Not FillParameters.TheseAreSettlementsWithCustomers And GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing") Then
		ConvertStageTableToSimplifiedModeData(PaymentScheduleSteps, 
			FillParameters.DateOfShipment, 
			Not FillParameters.NoPrepaymentControl, 
			FillParameters.Calendar);
	EndIf;
	
EndProcedure

// Parameters for checking the correctness of filling in the stages.
// 
// Returns:
//  Structure - Parameters For Checking Whether Stages Are Filled In Correctly:
// * Date                             - Date - document date.
// * Currency                           - CatalogRef.Currencies - Payment currency.
// * ThisIsOrder                         - Boolean,Undefined - This is an order.
// * InvoiceSourceOfGraph         - Boolean,Undefined - This is an invoice based on an order.
// * PaymentStepsText               - String - The path to the details of the form "Inscription of this payment", if any.
// * PaymentAmountAgainstTheDocument           - Number - the amount of the document in which you want to verify
// * DepositAmountUnderTheDocument           - Number - the amount of the Deposit for the document to be checked
//
Function ParametersForCheckingWhetherStagesAreFilledInCorrectly() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Date", Date(1,1,1));
	ParametersStructure.Insert("Currency", Catalogs.Currencies.EmptyRef());
	ParametersStructure.Insert("ThisIsOrder", Undefined);
	ParametersStructure.Insert("InvoiceSourceOfGraph", Undefined);
	ParametersStructure.Insert("PaymentStepsText",  "");
	ParametersStructure.Insert("PaymentAmountAgainstTheDocument", 0);
	ParametersStructure.Insert("DepositAmountUnderTheDocument", 0);
	
	Return ParametersStructure;
	
EndFunction

// Checks the correctness of filling in the stages of the payment schedule in the document
//
// Parameters:
// PaymentScheduleSteps               - ValueTable - Table of payment stages for verification.
// Cancel                            - Boolean - Flag for refusing to write a document
// ParametersStructure              - See ParametersForCheckingWhetherStagesAreFilledInCorrectly
// SimplifiedDialogMode           - Boolean - flag indicating the use of a simple dialog for entering payment stages.
// BindMessagesToHyperlink - Boolean - a flag indicating that the verification takes place on the form and the messages should be linked to the inscription of the schedule of payment stages.
//
Procedure CheckCorrectnessOfPaymentScheduleStages(Val PaymentScheduleSteps,
	                                               Cancel,
	                                               ParametersStructure,
	                                               SimplifiedDialogMode = True,
	                                               BindMessagesToHyperlink = False) Export
	
	If ValueIsFilled(ParametersStructure.Date) Then
		DocumentDate = BegOfDay(ParametersStructure.Date);
	EndIf;
	
	Total_PaymentAmount = Round(ParametersStructure.PaymentAmountAgainstTheDocument, 2);
	TotalDepositAmount = Round(ParametersStructure.DepositAmountUnderTheDocument, 2);
	
	If BindMessagesToHyperlink And ValueIsFilled(ParametersStructure.PaymentStepsText) Then
		PaymentStepsText = StrReplace(ParametersStructure.PaymentStepsText,"Form.","");
	Else
		PaymentStepsText = "";
	EndIf;
	
	UserMessages = New Map;
	
	If PaymentScheduleSteps.Count() = 0 Then
		
		If Total_PaymentAmount <> 0 Or TotalDepositAmount <> 0 Then
			
			If SimplifiedDialogMode Then
				ErrorText = NStr("vi = 'Cần điền ít nhất một trong các giai đoạn thanh toán';
								|ru = 'Необходимо заполнить хотя бы один из этапов оплаты';
								|en = 'Fill in at least one payment milestone'; fa = 'Fill in at least one payment milestone';
								|it = 'Compilare almeno una delle fasi di pagamento';
								|pl = 'Konieczne jest wypełnienie chociażby jednego z etapów płatności';
								|tr = 'Ödeme aşamalarında en az biri doldurulmalıdır'");
				ErrorField  = "PercentageOfPaymentCredit";
			Else
				ErrorText = NStr("vi = 'Cần điền các giai đoạn của lịch thanh toán';
								|ru = 'Необходимо заполнить этапы графика оплаты';
								|en = 'Payment milestones required'; fa = 'Payment milestones required';
								|it = 'È necessario compilare le fasi del programma di pagamento';
								|pl = 'Należy wypełnić etapy harmonogramu płatności';
								|tr = 'Ödeme planı aşamalarını doldurmanız gerekmektedir'");
				ErrorField  = "PaymentScheduleSteps";
			EndIf;
			
			If BindMessagesToHyperlink Then
				ErrorField = PaymentStepsText;
			EndIf;
			
			Cancel = True;
			UserMessages.Insert(ErrorText, ErrorField);
			
		EndIf;
		
	Else
		
		RecordPaymentOption = CommonClientServer.HasAttributeOrObjectProperty(PaymentScheduleSteps[0],"PaymentOption");
		
		TotalPaymentPercentage_ = 0;
		TotalPercentageOfCollateralPerContainer = 0;
		TotalPaymentAmount_ = 0;
		TotalAmountOfDepositPerContainer = 0;
		TotalAmountOfDeviation = 0;
		For CurIndex__ = 0 To PaymentScheduleSteps.Count()-1 Do
			
			Data_Stage = New Structure();
			Data_Stage.Insert("LineNumber",                  0);
			Data_Stage.Insert("PaymentOption",     Undefined);
			Data_Stage.Insert("PaymentDate",         '00010101');
			Data_Stage.Insert("PaymentPercentage",               0);
			Data_Stage.Insert("PackageDepositPercentage",          0);
			Data_Stage.Insert("PaymentAmount",                 0);
			Data_Stage.Insert("PackageDepositValue",            0);
			Data_Stage.Insert("MeasuringGoodsVarianceAmount", 0);
			Data_Stage.Insert("CalculateFrom",    Undefined);
			Data_Stage.Insert("Formula",           Undefined);
			Data_Stage.Insert("DateOfShipment",         '00010101');
			
			FillPropertyValues(Data_Stage, PaymentScheduleSteps[CurIndex__]);
			TotalPaymentPercentage_ = TotalPaymentPercentage_ + Data_Stage.PaymentPercentage;
			TotalPercentageOfCollateralPerContainer = TotalPercentageOfCollateralPerContainer + Data_Stage.PackageDepositPercentage;
			TotalPaymentAmount_ = TotalPaymentAmount_ + Data_Stage.PaymentAmount;
			TotalAmountOfDepositPerContainer = TotalAmountOfDepositPerContainer + Data_Stage.PackageDepositValue;
			TotalAmountOfDeviation = TotalAmountOfDeviation + Data_Stage.MeasuringGoodsVarianceAmount;
			
			ErrorAddress = NStr("vi = 'tại dòng %LineNumber% trong danh sách ""Giai đoạn lịch thanh toán""';
								|ru = 'в строке %LineNumber% списка ""Этапы графика оплаты""';
								|en = 'Line #%LineNumber%, tab Payment milestones'; fa = 'Line #%LineNumber%, tab Payment milestones';
								|it = 'nella riga %LineNumber% dell''elenco ""Fasi del programma di pagamento""';
								|pl = 'w wierszu %LineNumber% listy ""Этапы графика оплаты""';
								|tr = '""ödeme planı aşamaları"" listenin %LineNumber% satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", Data_Stage.LineNumber);
			
			// All details of the payment stage must be filled in
			
			If Not ValueIsFilled(Data_Stage.PaymentOption) And RecordPaymentOption Then
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Phương án thanh toán""';
								|ru = 'Не заполнена колонка ""Вариант оплаты""';
								|en = 'Payment terms required'; fa = 'Payment terms required';
								|it = 'Non è stata compilata la colonna ""Opzione di pagamento""';
								|pl = 'Nie wypełniono pola  ""Вариант оплаты""';
								|tr = '""Ödeme seçeneği"" sütunu doldurulmadı'");
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "PaymentOption");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText + " " + ErrorAddress, ErrorField);
				
			EndIf;
			
			If Not ValueIsFilled(Data_Stage.CalculateFrom) And RecordPaymentOption Then
				
				If SimplifiedDialogMode Then
					If Data_Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
						Or Data_Stage.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment Then
						ErrorText = NStr("vi = 'Chưa điền ""Phương án đếm ngược"" theo khoản trả sau';
										|ru = 'Не заполнен ""Вариант отсчета"" по постоплате';
										|en = '""Calculate from"" is not filled in for the postpayment'; fa = '""Calculate from"" is not filled in for the postpayment';
										|it = '""Variante di calcolo"" non compilata per il pagamento successivo';
										|pl = 'Nie jest wypełniona ""Wariant odliczenia"" z tytułu płatności po wykonaniu usługi';
										|tr = 'Faturalı için ""Geri sayım seçeneği"" doldurulmadı'");
						ErrorField  = "ReferenceOptionIsNotControlled";
					Else
						ErrorText = NStr("vi = 'Chưa điền ""Phương án đếm ngược"" cho khoản trả trước';
										|ru = 'Не заполнен ""Вариант отсчета"" по предоплате';
										|en = '""Calculate from"" is not filled in for the prepayment'; fa = '""Calculate from"" is not filled in for the prepayment';
										|it = '""Variante di calcolo"" non compilata per il pagamento anticipato';
										|pl = 'Nie jest wypełniona ""Wariant odliczenia"" z tytułu przedpłaty';
										|tr = 'Ön ödeme için ""Geri sayım seçeneği"" doldurulmadı'");
						ErrorField  = "ReferenceControlledOption";
					EndIf;
				Else
					ErrorText = NStr("vi = 'Chưa điền cột ""Phương án đếm ngược""';
									|ru = 'Не заполнена колонка ""Вариант отсчета""';
									|en = 'The ""Calculate from"" column is not filled in'; fa = 'The ""Calculate from"" column is not filled in';
									|it = 'Non è stata compilata la colonna ""Variante di calcolo""';
									|pl = 'Nie wypełniono kolumny ""Wariant odliczenia""';
									|tr = '""Referans seçeneği"" sütunu boş'");
					
					If BindMessagesToHyperlink Then
						ErrorField = PaymentStepsText;
					Else
						ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "CalculateFrom");
					EndIf;
					
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText + " " + ErrorAddress, ErrorField);
				
			EndIf;
			
			If Data_Stage.CalculateFrom = Enums.PaymentDateCalculationOptions.Formula
				And Not ValueIsFilled(Data_Stage.Formula) Then
				
				ErrorText = NStr("ru = 'Не заполнена колонка ""Формула""';
								|vi = 'The ""Formula"" column is not filled in';
								|en = 'The ""Formula"" column is not filled in'; fa = 'The ""Formula"" column is not filled in';
								|it = 'The ""Formula"" column is not filled in';
								|pl = 'The ""Formula"" column is not filled in';
								|tr = '""Formül"" sütunu doldurulmadı'");
					
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "CalculateFrom");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
			
			If Not ValueIsFilled(Data_Stage.PaymentDate) Then
				
				If SimplifiedDialogMode Then
					If Data_Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
						Or Data_Stage.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment Then
						ErrorText = NStr("vi = 'Chưa điền ""Ngày thanh toán"" theo khoản trả sau';
										|ru = 'Не заполнена ""Дата платежа"" по постоплате';
										|en = '""Payment date"" is not filled in for the postpayment'; fa = '""Payment date"" is not filled in for the postpayment';
										|it = '""Data di pagamento"" non compilata per pagamento successivo';
										|pl = 'Nie jest wypełniona ""Data płatności"" z tytułu płatności po wykonaniu płatności';
										|tr = 'Faturalı ""Ödeme tarihi"" doldurulmadı'");
						ErrorField  = "DateCredit";
					Else
						ErrorText = NStr("vi = 'Chưa điền ""Ngày thanh toán"" theo khoản trả trước';
										|ru = 'Не заполнена ""Дата платежа"" по предоплате';
										|en = '""Payment date"" is not filled in for prepayment'; fa = '""Payment date"" is not filled in for prepayment';
										|it = '""Data di pagamento"" per prepagamento non compilata';
										|pl = 'Nie jest wypełniona ""Data płatności"" z tytułu przedpłaty';
										|tr = 'Ön ödeme için ""Ödeme tarihi"" doldurulmadı'");
						ErrorField  = "DatePrepayment";
					EndIf;
				Else
					ErrorText = NStr("vi = 'Chưa điền cột ""Ngày thanh toán""';
									|ru = 'Не заполнена колонка ""Дата платежа""';
									|en = 'Column ""Payment date"" is not filled in'; fa = 'Column ""Payment date"" is not filled in';
									|it = 'Colonna ""Data del pagamento"" non compilata';
									|pl = 'Nie wypełniono kolumny ""Data płatności""';
									|tr = '""Ödeme tarihi"" sütunu doldurulmadı'");
					ErrorField  = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "PaymentDate");
				EndIf;
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
			
			If Not ValueIsFilled(Data_Stage.PaymentPercentage)
				And Not ValueIsFilled(Data_Stage.PackageDepositPercentage)
				And TotalDepositAmount + Total_PaymentAmount > 0
				And ((Data_Stage.PaymentAmount + Data_Stage.PackageDepositValue) / (TotalDepositAmount+Total_PaymentAmount) >= 0.0001
					Or Data_Stage.PaymentAmount + Data_Stage.PackageDepositValue = 0) Then
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Phần trăm thanh toán""';
								|ru = 'Не заполнена колонка ""Процент платежа""';
								|en = 'Payment percentage required'; fa = 'Payment percentage required';
								|it = 'La colonna ""Percentuale di pagamento"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Процент платежа""';
								|tr = '""Ödeme yüzdesi"" sütunu boş'");
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "PaymentPercentage");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText + " " + ErrorAddress, ErrorField);
				
			EndIf;
			
			If Not ValueIsFilled(Data_Stage.PaymentAmount)
				And ValueIsFilled(Data_Stage.PaymentPercentage)
				And Total_PaymentAmount <> 0 Then
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Số tiền thanh toán""';
								|ru = 'Не заполнена колонка ""Сумма платежа""';
								|en = 'Column ""Payment amount"" is not filled in'; fa = 'Column ""Payment amount"" is not filled in';
								|it = 'Colonna ""Importo del pagamento"" non compilata';
								|pl = 'Nie wypełniono kolumny ""Сумма платежа""';
								|tr = '""Ödeme tutarı"" sütunu doldurulmadı'");
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "PaymentAmount");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText + " " + ErrorAddress, ErrorField);
				
			EndIf;
				
			If Not ValueIsFilled(Data_Stage.PackageDepositValue)
				And ValueIsFilled(Data_Stage.PackageDepositPercentage) 
				And TotalDepositAmount > 0 Then
				
				ErrorText = NStr("vi = 'Chưa điền cột ""Số tiền ký cược bao bì""';
								|ru = 'Не заполнена колонка ""Сумма залога за тару""';
								|en = 'Column ""Packaging deposit value"" is not filled in'; fa = 'Column ""Packaging deposit value"" is not filled in';
								|it = 'Colonna ""Importo della cauzione per l''imballaggio"" non compilata';
								|pl = 'Nie wypełniono kolumny ""Сумма залога за тару""';
								|tr = '""Ambalaj depozito tutarı"" sütunu doldurulmadı'");
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "PackageDepositValue");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText + " " + ErrorAddress, ErrorField);
				
			EndIf;
			
			// The date of payment in pm stages of the payment graph must be at least the date of the document
			If ValueIsFilled(Data_Stage.PaymentDate) 
				And ValueIsFilled(ParametersStructure.Date) 
				And Data_Stage.PaymentDate < DocumentDate
				And (ParametersStructure.ThisIsOrder
					Or ParametersStructure.InvoiceSourceOfGraph) Then
				
				If SimplifiedDialogMode Then
					If Data_Stage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
						Or Data_Stage.PaymentOption = Enums.CustomerPaymentControlOptions.CreditAfterShipment Then
						ErrorField = "DateCredit";
					Else
						ErrorField = "DatePrepayment";
					EndIf;
				Else
					ErrorField = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "PaymentDate");
				EndIf;
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				EndIf;
				
				ErrorText = NStr("vi = 'Ngày thanh toán không được nhỏ hơn ngày chứng từ %DocumentDate%';
								|ru = 'Дата платежа должна быть не меньше даты документа %DocumentDate%';
								|en = 'Payment date must be not earlier than document date %DocumentDate%'; fa = 'Payment date must be not earlier than document date %DocumentDate%';
								|it = 'La data del pagamento deve essere non precedente alla data del documento %DocumentDate%';
								|pl = 'Data płatności powinna być nie mniejsza od daty dokumentu %DocumentDate%';
								|tr = 'Ödeme tarihi belgenin tarihinden az olmamalıdır  %DocumentDate%'");
				ErrorText = StrReplace(ErrorText,"%DocumentDate%", Format(ParametersStructure.Date, "DLF=DD"));
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
			
		EndDo;
		
		// The percentage of payments in the PM stages of the payment graph should be 100%
		
		If PaymentScheduleSteps.Count() > 0 Then
			
			If TotalPaymentPercentage_ <> 100 And Total_PaymentAmount - TotalDepositAmount > 0 Then
				
				ErrorText = NStr("vi = 'Phần trăm thanh toán theo tất cả các giai đoạn ""%PercentageByStage%%"" phải bằng ""100%""';
								|ru = 'Процент платежей по всем этапам ""%PercentageByStage%%"" должен равняться ""100%""';
								|en = 'Payment percent at all stages ""%PercentageByStage%%"" should be equal to ""100%""'; fa = 'Payment percent at all stages ""%PercentageByStage%%"" should be equal to ""100%""';
								|it = 'La percentuale di pagamento per tutte le fasi ""%PercentageByStage%%"" deve essere uguale al ""100%""';
								|pl = 'Procent płatności wg wszystkich etapów ""%PercentageByStage%%"" powinien być równy ""100%""';
								|tr = 'Tüm aşamalar için ödemelerin yüzdesi ""%PercentageByStage%%"" ""100%""e eşit olmalıdır'");
				ErrorText = StrReplace(ErrorText, "%PercentageByStage%", TotalPaymentPercentage_);
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = ?(SimplifiedDialogMode, "PercentageOfPaymentCredit", "PaymentScheduleSteps[0].PaymentPercentage");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
				
			If TotalAmountOfDepositPerContainer + TotalAmountOfDeviation -(Total_PaymentAmount - TotalPaymentAmount_) 
				<> TotalDepositAmount And TotalDepositAmount <> 0 Then
				
				ErrorText = NStr("vi = 'Phần trăm ký cược bao bì theo tất cả các giai đoạn ""%PercentageByStage%%"" phải bằng ""100%""';
								|ru = 'Процент залога за тару по всем этапам ""%PercentageByStage%%"" должен равняться ""100%""';
								|en = 'Percent of the packaging deposit for all steps ""%PercentageByStage%%"" should be equal to ""100%""'; fa = 'Percent of the packaging deposit for all steps ""%PercentageByStage%%"" should be equal to ""100%""';
								|it = 'La percentuale della cauzione per l''imballaggio per tutte le fasi ""%PercentageByStage%%"" deve essere uguale al ""100%""';
								|pl = 'Procent kaucji za tarę wg wszystkich etapów ""%PercentageByStage%%"" powinien być równy ""100%""';
								|tr = 'Tüm aşamalar için depozito yüzdesi ""%PercentageByStage%%"" ""100%""e eşit olmalıdır'");
				ErrorText = StrReplace(ErrorText, "%PercentageByStage%", TotalPercentageOfCollateralPerContainer);
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				Else
					ErrorField = ?(SimplifiedDialogMode, "ThePercentageOfTheDepositForTheContainerLoan", "PaymentScheduleSteps[0].PackageDepositPercentage");
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
			
		EndIf;
		
		// The amount of payments in the pm stages of the payment graph must be equal to the amount of the order, taking into account the canceled items.
		
		If PaymentScheduleSteps.Count() > 0 Then
			
			If Total_PaymentAmount <> 0 And TotalPaymentAmount_ + TotalAmountOfDeviation <> Total_PaymentAmount Then
				
				ErrorText = NStr("vi = 'Số tiền thanh toán theo tất cả các giai đoạn ""%AmountByStages% %Currency%"" không được khác với số tiền trong chứng từ ""%AmountTotal% %Currency%""';
								|ru = 'Сумма платежей по всем этапам ""%AmountByStages% %Currency%"" не должна отличаться от суммы документа ""%AmountTotal% %Currency%""';
								|en = 'Payment amount of all steps ""%AmountByStages% %Currency%"" should not differ from the document amount ""%AmountTotal% %Currency%""'; fa = 'Payment amount of all steps ""%AmountByStages% %Currency%"" should not differ from the document amount ""%AmountTotal% %Currency%""';
								|it = 'L''importo dei pagamenti per tutte le fasi  ""%AmountByStages% %Currency%"" non deve differire dall''importo del documento ""%AmountTotal% %Currency%""';
								|pl = 'Wartość płatności wg wszystkich etapów ""%AmountByStages% %Currency%"" nie powinna różnić się od kwoty dokumentu "" %AmountTotal%%Currency%""';
								|tr = 'Tüm aşamalar için ödemelerin toplamı ""%AmountByStages% %Currency%"" belgenin toplamından farklı olmamalıdır ""%AmountTotal% %Currency%""'");
				ErrorText = StrReplace(ErrorText, "%AmountByStages%", TotalPaymentAmount_);
				ErrorText = StrReplace(ErrorText, "%AmountTotal%",    Total_PaymentAmount - TotalDepositAmount);
				ErrorText = StrReplace(ErrorText, "%Currency%",        ParametersStructure.Currency);
				
				If SimplifiedDialogMode Then
					If PaymentScheduleSteps[0].PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt Then
						ErrorField = "PaymentAmountPrepayment";
					Else
						ErrorField = "PaymentAmountCredit";
					EndIf;
				Else
					ErrorField = "PaymentScheduleSteps[0].PaymentAmount";
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
			
			If TotalDepositAmount <> 0 And TotalAmountOfDepositPerContainer <> TotalDepositAmount Then
				
				ErrorText = NStr("vi = 'Số tiền ký cược bao bì theo tất cả các giai đoạn ""%AmountByStages% %Currency%"" không được khác với số tiền ký cược theo chứng từ ""%AmountTotal% %Currency%""';
								|ru = 'Сумма залога за тару по всем этапам ""%AmountByStages% %Currency%"" не должна отличаться от суммы залога по документу ""%AmountTotal% %Currency%""';
								|en = 'Packaging deposit value by all steps ""%AmountByStages% %Currency%"" should not differ from a deposit value against document ""%AmountTotal% %Currency%""'; fa = 'Packaging deposit value by all steps ""%AmountByStages% %Currency%"" should not differ from a deposit value against document ""%AmountTotal% %Currency%""';
								|it = 'L''importo della cauzione per l''imballaggio per tutte le fasi""%AmountByStages% %Currency%"" non deve differire dall''importo della garanzia per il documento ""%AmountTotal% %Currency%""';
								|pl = 'Wartość kaucji za tarę wg wszystkich etapów ""%AmountByStages% %Currency%"" nie powinna różnić się od kwoty kaucji wg dokumentu ""%AmountTotal% %Currency%""';
								|tr = 'Tüm aşamalar için depozito tutarı ""%AmountByStages% %Currency%"", belge için ambalaj depozito tutarından farklı olmamalıdır ""%AmountTotal%%Currency%""'");
				ErrorText = StrReplace(ErrorText, "%AmountByStages%", TotalAmountOfDepositPerContainer);
				ErrorText = StrReplace(ErrorText, "%AmountTotal%",    TotalDepositAmount);
				ErrorText = StrReplace(ErrorText, "%Currency%",        ParametersStructure.Currency);
				
				If SimplifiedDialogMode Then
					If PaymentScheduleSteps[0].PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt Then
						ErrorField = "DepositAmountForPackagingPrepayment";
					Else
						ErrorField = "TheAmountOfTheDepositForTheContainerLoan";
					EndIf;
				Else
					ErrorField = "PaymentScheduleSteps[0].PackageDepositValue";
				EndIf;
				
				If BindMessagesToHyperlink Then
					ErrorField = PaymentStepsText;
				EndIf;
				
				Cancel = True;
				UserMessages.Insert(ErrorText, ErrorField);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	For Each MapItem In UserMessages Do
		
		Common.MessageToUser(
			MapItem.Key,,
			MapItem.Value);
		
	EndDo;
	
EndProcedure

// Simplified mode data.
// 
// Parameters:
//  PaymentSteps - ValueTable - Payment milestones:
// * DateOfShipment - Date
//  DateOfShipment - Date - date of shipment
//  ThereIsPrepayment - Boolean - There is a prepayment
//  Calendar - CatalogRef.BusinessCalendars - Calendar
// 
// Returns:
//  Structure - Simplified Mode Data:
// * PaymentAmountCredit - Number - 
// * PercentageOfPaymentCredit - Number - 
// * TheAmountOfTheDepositForTheContainerLoan - Number - 
// * ThePercentageOfTheDepositForTheContainerLoan - Number - 
// * DateCredit - Date - 
// * CreditReferenceOption - EnumRef.PaymentDateCalculationOptions
// * CreditControlOption - EnumRef.CustomerPaymentControlOptions,EnumRef.OptionsForControllingPaymentToSupplier
// * ShiftCredit - Number - 
// * AmountOfSettlementsCredit - Number - 
// * AmountOfSettlementsOnContainerCredit - Number - 
// * DateOfShipmentCredit - Date - 
// * PaymentAmountPrepayment - Number - 
// * PaymentPercentagePrepayment - Number - 
// * DepositAmountForPackagingPrepayment - Number - 
// * PercentageOfTheDepositForTheContainerPrepayment - Number - 
// * DatePrepayment - Date - 
// * CountdownOptionPrepayment - EnumRef.PaymentDateCalculationOptions
// * ControlOptionPrepayment - EnumRef.CustomerPaymentControlOptions,EnumRef.OptionsForControllingPaymentToSupplier
// * ShiftPrepayment - Number - 
// * AmountOfSettlementsPrepayment - Number - 
// * AmountOfSettlementsOnContainersPrepayment - Number - 
// * DateOfShipmentPrepayment - Date - 
// * MeasuringGoodsVarianceAmount - Number - 
Function SimplifiedModeData(PaymentSteps, DateOfShipment, ThereIsPrepayment, Calendar) Export
	
	ThereIsPackage = PaymentSteps.Count() > 0 
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"PackageDepositValue");
	ThereIsSumOfMutualSettlements = PaymentSteps.Count() > 0
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"AmountARAP");
	ThereAreShippingDates = PaymentSteps.Count() > 0 
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"DateOfShipment");
	ThereIsSumOfDeviationOfDimensionalGoods = PaymentSteps.Count() > 0 
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"MeasuringGoodsVarianceAmount");
		
	Result = New Structure();
	Result.Insert("PaymentAmountCredit",0);
	Result.Insert("PercentageOfPaymentCredit",0);
	Result.Insert("TheAmountOfTheDepositForTheContainerLoan",0);
	Result.Insert("ThePercentageOfTheDepositForTheContainerLoan",0);
	Result.Insert("DateCredit",Date(1,1,1));
	Result.Insert("CreditReferenceOption",Enums.PaymentDateCalculationOptions.EmptyRef());
	Result.Insert("CreditControlOption",Enums.CustomerPaymentControlOptions.EmptyRef());
	Result.Insert("ShiftCredit",0);
	Result.Insert("AmountOfSettlementsCredit",0);
	Result.Insert("AmountOfSettlementsOnContainerCredit",0);
	Result.Insert("DateOfShipmentCredit",Date(1,1,1));
	
	Result.Insert("PaymentAmountPrepayment",0);
	Result.Insert("PaymentPercentagePrepayment",0);
	Result.Insert("DepositAmountForPackagingPrepayment",0);
	Result.Insert("PercentageOfTheDepositForTheContainerPrepayment",0);
	Result.Insert("DatePrepayment",Date(1,1,1));
	Result.Insert("CountdownOptionPrepayment",Enums.PaymentDateCalculationOptions.EmptyRef());
	Result.Insert("ControlOptionPrepayment",Enums.CustomerPaymentControlOptions.EmptyRef());
	Result.Insert("ShiftPrepayment",0);
	Result.Insert("AmountOfSettlementsPrepayment",0);
	Result.Insert("AmountOfSettlementsOnContainersPrepayment",0);
	Result.Insert("DateOfShipmentPrepayment",Date(1,1,1));
	
	Result.Insert("MeasuringGoodsVarianceAmount",0);
	
	If PaymentSteps.Count() = 0 Then
		Return Result;
	EndIf;
	
	For Each CurRow In PaymentSteps Do
		
		If CurRow.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditAfterShipment
			And CurRow.PaymentOption <> Enums.CustomerPaymentControlOptions.CreditPlanned
			And CurRow.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt
			And CurRow.PaymentOption <> Enums.OptionsForControllingPaymentToSupplier.CreditAfterShipment
			And ThereIsPrepayment Then //the advance and prepayment are summed up in the total amount
			Result.PaymentAmountPrepayment = Result.PaymentAmountPrepayment + CurRow.PaymentAmount;
			Result.PaymentPercentagePrepayment = Result.PaymentPercentagePrepayment + CurRow.PaymentPercentage;
			
			If ThereIsPackage Then
				Result.DepositAmountForPackagingPrepayment   = Result.DepositAmountForPackagingPrepayment + CurRow.PackageDepositValue;
				Result.PercentageOfTheDepositForTheContainerPrepayment = Result.PercentageOfTheDepositForTheContainerPrepayment + CurRow.PackageDepositPercentage;
			EndIf;
			
			If ThereIsSumOfMutualSettlements Then
				Result.AmountOfSettlementsPrepayment = Result.AmountOfSettlementsPrepayment + CurRow.AmountARAP;
				If ThereIsPackage Then
					Result.AmountOfSettlementsOnContainersPrepayment = Result.AmountOfSettlementsOnContainersPrepayment + CurRow.AmountARAPByPackage;
				EndIf;
			EndIf;
			
			If Result.DatePrepayment <= CurRow.PaymentDate Then
				Result.DatePrepayment = Max(Result.DatePrepayment, CurRow.PaymentDate);
				Result.ShiftPrepayment = CurRow.Move;
				If ThereAreShippingDates Then
					Result.DateOfShipmentPrepayment = Max(Result.DateOfShipmentPrepayment, CurRow.DateOfShipment);
				EndIf;
				If CurRow.CalculateFrom <> Enums.PaymentDateCalculationOptions.Formula Then
					Result.CountdownOptionPrepayment = CurRow.CalculateFrom;
				EndIf;
				Result.ControlOptionPrepayment = CurRow.PaymentOption;
			EndIf;
		Else
			Result.PaymentAmountCredit   = Result.PaymentAmountCredit + CurRow.PaymentAmount;
			Result.PercentageOfPaymentCredit = Result.PercentageOfPaymentCredit + CurRow.PaymentPercentage;
			If ThereIsPackage Then
				Result.TheAmountOfTheDepositForTheContainerLoan   = Result.TheAmountOfTheDepositForTheContainerLoan + CurRow.PackageDepositValue;
				Result.ThePercentageOfTheDepositForTheContainerLoan = Result.ThePercentageOfTheDepositForTheContainerLoan + CurRow.PackageDepositPercentage;
			EndIf;
			
			If ThereIsSumOfMutualSettlements Then
				Result.AmountOfSettlementsCredit = Result.AmountOfSettlementsCredit + CurRow.AmountARAP;
				If ThereIsPackage Then
					Result.AmountOfSettlementsOnContainerCredit = Result.AmountOfSettlementsOnContainerCredit + CurRow.AmountARAPByPackage;
				EndIf;
			EndIf;
			
			If Result.DateCredit <= CurRow.PaymentDate Then
				Result.DateCredit = Max(Result.DateCredit, CurRow.PaymentDate);
				Result.ShiftCredit = CurRow.Move;
				If ThereAreShippingDates Then
					Result.DateOfShipmentCredit = Max(Result.DateOfShipmentCredit, CurRow.DateOfShipment);
				EndIf;
				If CurRow.CalculateFrom <> Enums.PaymentDateCalculationOptions.Formula Then
					Result.CreditReferenceOption = CurRow.CalculateFrom;
				EndIf;
				Result.CreditControlOption= CurRow.PaymentOption;
			EndIf;
		EndIf;
		
		If ThereIsSumOfDeviationOfDimensionalGoods Then
			Result.MeasuringGoodsVarianceAmount = Result.MeasuringGoodsVarianceAmount + CurRow.MeasuringGoodsVarianceAmount;
		EndIf;
		
	EndDo;
	
	If ThereIsPrepayment And Not ValueIsFilled(Result.CountdownOptionPrepayment) Then
		Result.CountdownOptionPrepayment = Enums.PaymentDateCalculationOptions.BeforeShipmentDate;
		
		PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
		PaymentDateCalculationParameters.DateOfShipment = DateOfShipment;
		PaymentDateCalculationParameters.CalculateFrom = Result.CountdownOptionPrepayment;
		PaymentDateCalculationParameters.PaymentDate = Result.DatePrepayment;
		If ValueIsFilled(Calendar) Then
			Result.ShiftPrepayment = PaymentStepsServerCall.CalendarShift(PaymentDateCalculationParameters);
		Else
			Result.ShiftPrepayment = PaymentStepsServerCall.ShiftWithoutCalendar(PaymentDateCalculationParameters);
		EndIf;
		If Result.ShiftPrepayment < 0 Then
			Result.ShiftPrepayment = 0;
			PaymentDateCalculationParameters.Move = 0;
			If ValueIsFilled(Calendar) Then
				Result.DatePrepayment = PaymentStepsServerCall.PaymentDateByCalendar(PaymentDateCalculationParameters);
			Else
				Result.DatePrepayment = PaymentStepsServerCall.PaymentDateWithoutCalendar(PaymentDateCalculationParameters);
			EndIf;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Result.CreditReferenceOption) 
		Or Not ThereIsPrepayment And Result.CreditReferenceOption <> Enums.PaymentDateCalculationOptions.FromShipmentDate Then
		Result.CreditReferenceOption = Enums.PaymentDateCalculationOptions.FromShipmentDate;
		
		PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
		PaymentDateCalculationParameters.DateOfShipment = DateOfShipment;
		PaymentDateCalculationParameters.CalculateFrom = Result.CreditReferenceOption;
		PaymentDateCalculationParameters.PaymentDate = Result.DateCredit;
		If ValueIsFilled(Calendar) Then
			Result.ShiftCredit = PaymentStepsServerCall.CalendarShift(PaymentDateCalculationParameters);
		Else
			Result.ShiftCredit = PaymentStepsServerCall.ShiftWithoutCalendar(PaymentDateCalculationParameters);
		EndIf;
		If Result.ShiftCredit < 0 Then
			Result.ShiftCredit = 0;
			PaymentDateCalculationParameters.Move = 0;
			If ValueIsFilled(Calendar) Then
				Result.DateCredit = PaymentStepsServerCall.PaymentDateByCalendar(PaymentDateCalculationParameters);
			Else
				Result.DateCredit = PaymentStepsServerCall.PaymentDateWithoutCalendar(PaymentDateCalculationParameters);
			EndIf;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CommonMethods

// Returns a structure with parameters for selecting payment details to send to external forms.
//
// Parameters:
// 		MetadataObject - MetadataObject - the metadata object for which you want to define parameters.
//
// Returns:
// 		Structure:
// 			* Key - String - The name of the payment details.
// 			* Value - FixedArray of Structure - Selection parameters, where:
// 				** PaymentMethod - FixedArray of ChoiceParameter
// 				** CashAccount - FixedArray of ChoiceParameter
// 				** BankAccount - FixedArray of ChoiceParameter
// 				** PaymentSchedule - FixedArray of ChoiceParameter
//
Function ParametersForSelectingPaymentDetails(MetadataObject) Export
	
	ObjectAttributes = MetadataObject.Attributes;
	AttributeSelectionParameters = New Structure;
	
	If Common.HasObjectAttribute("PaymentMethod", MetadataObject) Then
		AttributeSelectionParameters.Insert("PaymentMethod", ObjectAttributes.PaymentMethod.ChoiceParameters);
	EndIf;
	
	If Common.HasObjectAttribute("CashAccount", MetadataObject) Then
		AttributeSelectionParameters.Insert("CashAccount", ObjectAttributes.CashAccount.ChoiceParameters);
	EndIf;
	
	If Common.HasObjectAttribute("BankAccount", MetadataObject) Then
		AttributeSelectionParameters.Insert("BankAccount", ObjectAttributes.BankAccount.ChoiceParameters);
	ElsIf Common.HasObjectAttribute("CompanyBankAccount", MetadataObject) Then
		AttributeSelectionParameters.Insert("BankAccount", ObjectAttributes.CompanyBankAccount.ChoiceParameters);
	EndIf;
	
	If Common.HasObjectAttribute("PaymentSchedule", MetadataObject) Then
		AttributeSelectionParameters.Insert("PaymentSchedule", ObjectAttributes.PaymentSchedule.ChoiceParameters);
	EndIf;
	
	Return AttributeSelectionParameters;
	
EndFunction

//Returns the minimum date of the unpaid stage of the contract execution schedule.
//
// Parameters:
//
// 		ContractSchedule - DocumentRef.ContractSchedule - the schedule of the contract.
// 		Date - Date - document date.
// 		PaymentType_ - EnumRef.PartnersARAPAccountingTypes - determines in which register to look for the date of the unpaid stage.
//
// Returns:
// 		Date - The minimum date of the unpaid stage of the schedule, if all are paid - an empty date.
Function DateOfFirstUnpaidStageOfSchedule(ContractSchedule, Date, PaymentType_) Export
	
	If GetFunctionalOption("NewOnlineARAPAccounting") And ValueIsFilled(ContractSchedule) Then
		
		Query = New Query;
		If PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			Query.Text = "
			|SELECT
			|	ISNULL(MIN(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate), DATETIME(1,1,1)) AS PlannedRepaymentDate
			|FROM
			|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(,
			|		DocumentPlan = &DocumentPlan) AS CustomersARAPAccountingCashFlowPlanBalance";
		Else
			Query.Text = "
			|	SELECT
			|		ISNULL(MIN(VendorsARAPAccountingCashFlowPlan.PlannedRepaymentDate), DATETIME(1,1,1)) AS PlannedRepaymentDate
			|	FROM
			|		AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(,
			|			DocumentPlan = &DocumentPlan) AS VendorsARAPAccountingCashFlowPlan";
		EndIf;
		Query.SetParameter("DocumentPlan", ContractSchedule);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Return Selection.PlannedRepaymentDate;
		Else
			Return Date;
		EndIf;
	Else
		Return Date;
	EndIf;
	
EndFunction

// The procedure checks whether the payment date is filled in and correct in the document.
//
// Parameters:
//		PaymentDate - Date - payment date of the document being checked
//		DocumentDate - Date - date of the document being checked 
//		Cancel - Boolean - Indicates that you don't want to continue working.
//
Procedure CheckIfPaymentDateIsCorrect(PaymentDate, DocumentDate, Cancel) Export
	
	If Not ValueIsFilled(PaymentDate) Then
		
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Ngày thanh toán""';
				|ru = 'Поле ""Дата платежа"" не заполнено';
				|en = '""Payment date"" is required'; fa = '""Payment date"" is required';
				|it = 'Il campo ""Data del pagamento"" non è compilato';
				|pl = 'Pole ""Data płatności"" nie jest wypełnione';
				|tr = '""Ödeme tarihi"" alanı doldurulmadı'"),
			,
			"PaymentDate",
			"Object",
			Cancel);
		
	ElsIf PaymentDate < BegOfDay(DocumentDate) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ngày thanh toán không được nhỏ hơn ngày chứng từ %1';
				|ru = 'Дата платежа должна быть не меньше даты документа %1';
				|en = 'Payment date must be not less than the %1 document date'; fa = 'Payment date must be not less than the %1 document date';
				|it = 'La data del pagamento non deve essere precedente alla data del documento %1';
				|pl = 'Data płatności powinna być nie mniejsza od daty dokumentu %1';
				|tr = 'Ödeme tarihi belgenin tarihinden az olmamalıdır %1 '"),
			Format(DocumentDate, "DLF=DD"));
		Common.MessageToUser(
			ErrorText,
			,
			"PaymentDate",
			"Object",
			Cancel);
		
	EndIf;
	
EndProcedure

// The procedure fills in percentages for already calculated amounts in the table of payment schedule stages.
// 
// Parameters:
// 	PaymentScheduleSteps - ValueTable,FormDataCollection - stages where you need to fill in the percentages.
//
Procedure FillInInterestOnAmounts(PaymentScheduleSteps) Export
	
	If ARAPAccountingClientServer.IsTabularSection(PaymentScheduleSteps) Then
		ThereIsPackage = PaymentScheduleSteps.Columns.Find("PackageDepositValue") <> Undefined;
	Else
		ThereIsPackage = PaymentScheduleSteps.Unload().Columns.Find("PackageDepositValue") <> Undefined;
	EndIf;
	
	PaymentsAmounts = New Array;
	AmountsOfCollateralPayments = New Array;
	
	// If there are both positive and negative amounts in the payment stages, interest cannot be calculated in the distribution of the sum disproportionately to the coefficients
	// Percentages are calculated relative to the amount modulo
	AmountOfPaymentsByModule = 0;
	AmountOfDepositModulo = 0;
	For Each StageString_ In PaymentScheduleSteps Do 
		SumModule = ?(StageString_.PaymentAmount > 0, StageString_.PaymentAmount, -StageString_.PaymentAmount);
		PaymentsAmounts.Add(SumModule);
		AmountOfPaymentsByModule = AmountOfPaymentsByModule + SumModule;
		If ThereIsPackage Then
			SumModule = ?(StageString_.PackageDepositValue > 0, StageString_.PackageDepositValue, -StageString_.PackageDepositValue);
			AmountsOfCollateralPayments.Add(SumModule);
			AmountOfDepositModulo = AmountOfDepositModulo + SumModule;
		EndIf;
	EndDo;
	
	InterestPayments = CommonClientServer.DistributeAmountInProportionToCoefficients(100, PaymentsAmounts);
	InterestPaymentsOnCollateral = CommonClientServer.DistributeAmountInProportionToCoefficients(?(ThereIsPackage,100,0), AmountsOfCollateralPayments);
	
	IndexOf = 0;
	While IndexOf < PaymentScheduleSteps.Count() Do
		
		If InterestPayments <> Undefined Then
			PaymentScheduleSteps[IndexOf].PaymentPercentage = InterestPayments[IndexOf];
		Else
			PaymentScheduleSteps[IndexOf].PaymentPercentage = 0;
		EndIf;
		If ThereIsPackage Then
			If InterestPaymentsOnCollateral <> Undefined Then
				PaymentScheduleSteps[IndexOf].PackageDepositPercentage = InterestPaymentsOnCollateral[IndexOf];
			Else
				PaymentScheduleSteps[IndexOf].PackageDepositPercentage = 0;
			EndIf;
		EndIf;
		
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

// The procedure distributes the amount of rejection of measured goods by stages of the payment schedule.
Procedure DistributeAmountOfDeviationByStagesOfPaymentSchedule(PaymentScheduleSteps, Val SumOfDeviationToDistribution) Export
	
	DistributedRejectionAmount = 0;
	CurrentStep                   = 0;
	NumberOfStages              = PaymentScheduleSteps.Count();
	SumOfDeviationToDistribution = SumOfDeviationToDistribution + PaymentScheduleSteps.Total("MeasuringGoodsVarianceAmount");
	
	If SumOfDeviationToDistribution = 0 Then
		Return;
	EndIf;
	
	Total_PaymentAmount              = PaymentScheduleSteps.Total("PaymentAmount")+PaymentScheduleSteps.Total("PackageDepositValue");
	
	For Each PaymentScheduleStage In PaymentScheduleSteps Do
		
		CurrentStep = CurrentStep + 1;
		
		CoefficientOfTotal    = (PaymentScheduleStage.PaymentAmount + PaymentScheduleStage.PackageDepositValue)/Total_PaymentAmount;
		AmountOfDeviationByStage = Round(SumOfDeviationToDistribution * CoefficientOfTotal, 2, RoundMode.Round15as20);
		
		PaymentScheduleStage.MeasuringGoodsVarianceAmount  = ?(CurrentStep = NumberOfStages,
		                                                    SumOfDeviationToDistribution - DistributedRejectionAmount,
		                                                    AmountOfDeviationByStage);
		
		CoefficientFromLine = PaymentScheduleStage.MeasuringGoodsVarianceAmount
		                      / (PaymentScheduleStage.PaymentAmount+PaymentScheduleStage.PackageDepositValue);
		
		PartOfPaymentAmount   = Round(PaymentScheduleStage.PaymentAmount * CoefficientFromLine,2);
		PaymentScheduleStage.PaymentAmount      = PaymentScheduleStage.PaymentAmount - PartOfPaymentAmount;
		
		PaymentScheduleStage.PackageDepositValue = PaymentScheduleStage.PackageDepositValue
		                                      - (PaymentScheduleStage.MeasuringGoodsVarianceAmount - PartOfPaymentAmount);
		
		DistributedRejectionAmount = DistributedRejectionAmount + PaymentScheduleStage.MeasuringGoodsVarianceAmount;
		
	EndDo;
	
EndProcedure

// Moves the payment dates of the payment milestones according to changes in the original dates
// 
// Parameters:
//  Object - DocumentObject, CatalogObject, ClientApplicationForm - processed object
//  ParametersStructure - See ARAPAccountingServer.MechanismParameters
//  ArrayOfBankingDetailsUsed- Array of String - Attribute Names
// 
// Returns:
//  Boolean - true if there are changes in the payment milestones
Function RecalculatePaymentDatesPaymentMilestones(Object, ParametersStructure, ArrayOfBankingDetailsUsed) Export
	
	ChangedPaymentMilestones = False;
	
	ScheduleStages = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSDataPaymentSteps);
	
	If ParametersStructure.ThisIsOrder Then
		
		ShippingDates = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfShipment);
		DatesOfReceipt = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfReceipt);
		// Determines whether the order actually has several shipping dates, and not just the Ship One date flag is unchecked
		If TypeOf(ShippingDates) = Type("Array") Then
			TabularSection = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PathToTSData);
			MultipleShippingDates = VariousDates(TabularSection, ParametersStructure.DateOfShipment).ShippingDates.Count() > 1;
		Else
			MultipleShippingDates = False;
		EndIf;
		
		If (ArrayOfBankingDetailsUsed.Find("DateOfShipment") <> Undefined Or  ArrayOfBankingDetailsUsed.Find("DateOfReceipt") <> Undefined) 
			And ArrayOfBankingDetailsUsed.Find("ShipInOneDay") = Undefined
			And MultipleShippingDates Then 
			ParametersStructure.SeveralShippingDatesHaveChanged = True;
		Else
			
			ApprovalDate = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.ApprovalDate);
			OrderDate = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
			If TypeOf(ShippingDates) = Type("Array") And ShippingDates.Count() > 0 Then
				DateOfShipment = ShippingDates[0];
			ElsIf TypeOf(ShippingDates) = Type("Date") Then
				DateOfShipment = ShippingDates;
			Else
				DateOfShipment = Date(1,1,1);
			EndIf;
			
			If TypeOf(DatesOfReceipt) = Type("Array") And DatesOfReceipt.Count() > 0 Then
				DateOfReceipt = DatesOfReceipt[0];
			ElsIf TypeOf(DatesOfReceipt) = Type("Date") Then
				DateOfReceipt = DatesOfReceipt;
			Else
				DateOfReceipt = Date(1,1,1);
			EndIf;
			
			For Each StageString_ In ScheduleStages Do
				If StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.FromApprovalDate 
						And ArrayOfBankingDetailsUsed.Find("ApprovalDate") <> Undefined
					Or StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.FromOrderDate 
						And ArrayOfBankingDetailsUsed.Find("Date") <> Undefined 
					Or PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(StageString_.CalculateFrom, StageString_.Formula)
						And (ArrayOfBankingDetailsUsed.Find("DateOfShipment") <> Undefined Or ArrayOfBankingDetailsUsed.Find("DateOfReceipt") <> Undefined)
					Or StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.Formula Then
					
					PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
					PaymentDateCalculationParameters.CalculateFrom                 = StageString_.CalculateFrom;
					PaymentDateCalculationParameters.Move                          = StageString_.Move;
					PaymentDateCalculationParameters.OrderDate                     = OrderDate;
					PaymentDateCalculationParameters.ApprovalDate               = ApprovalDate;
					PaymentDateCalculationParameters.DateOfShipment                   = DateOfShipment;
					PaymentDateCalculationParameters.DateOfReceipt                = DateOfReceipt;
					PaymentDateCalculationParameters.DateOfTransferOfTitleToGoods = Date(1,1,1);
					PaymentDateCalculationParameters.DeadlineOfTransferOfTitleToGoods = ParametersStructure.DeadlineOfTransferOfTitleToGoods;
					PaymentDateCalculationParameters.Calendar                      = ParametersStructure.Calendar;
					PaymentDateCalculationParameters.Formula                        = StageString_.Formula;
					
					ChangedPaymentMilestones = True;
					If ValueIsFilled(ParametersStructure.Calendar)  Then
						StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(PaymentDateCalculationParameters);
					Else
						StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(PaymentDateCalculationParameters);
					EndIf;
				EndIf;
			EndDo; 
			
		EndIf;
	ElsIf ParametersStructure.ThisIsSalePurchase Then
		
		DateOfShipment = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.Date);
		If ValueIsFilled(ParametersStructure.DateOfTransferOfTitleToGoods) Then
			DateOfTransferOfTitleToGoods = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.DateOfTransferOfTitleToGoods);
		Else
			DateOfTransferOfTitleToGoods = Date(1,1,1);
		EndIf;
		
		RecalculateStagesFromDateOfTransferOfOwnership = 
			ParametersStructure.ThisIsTransferOfOwnership2_5
				And ArrayOfBankingDetailsUsed.Find("Date") <> Undefined
			Or ArrayOfBankingDetailsUsed.Find("DateOfTransferOfTitleToGoods") <> Undefined;
		
		RecalculateStagesFromShipmentDates = Not ParametersStructure.ThisIsTransferOfOwnership2_5
			And (ArrayOfBankingDetailsUsed.Find("Date") <> Undefined
				Or ArrayOfBankingDetailsUsed.Find("DateOfShipment") <> Undefined);
			
		For Each StageString_ In ScheduleStages Do
			If RecalculateStagesFromDateOfTransferOfOwnership
				And StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods
			Or RecalculateStagesFromShipmentDates
				And (StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.FromShipmentDate 
					Or StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.BeforeShipmentDate
					Or StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfReceipt)
			Or StageString_.CalculateFrom = Enums.PaymentDateCalculationOptions.Formula Then
				PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
				PaymentDateCalculationParameters.CalculateFrom                 = StageString_.CalculateFrom;
				PaymentDateCalculationParameters.Move                          = StageString_.Move;
				PaymentDateCalculationParameters.OrderDate                     = Date(1,1,1);
				PaymentDateCalculationParameters.ApprovalDate               = Date(1,1,1);
				PaymentDateCalculationParameters.DateOfShipment                   = DateOfShipment;
				PaymentDateCalculationParameters.DateOfReceipt                = DateOfShipment;
				PaymentDateCalculationParameters.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
				PaymentDateCalculationParameters.DeadlineOfTransferOfTitleToGoods = ParametersStructure.DeadlineOfTransferOfTitleToGoods;
				PaymentDateCalculationParameters.Calendar                      = ParametersStructure.Calendar;
				PaymentDateCalculationParameters.Formula                        = StageString_.Formula;
				
				ChangedPaymentMilestones = True;
				If ValueIsFilled(ParametersStructure.Calendar)  Then
					StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(PaymentDateCalculationParameters);
				Else
					StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(PaymentDateCalculationParameters);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	If ChangedPaymentMilestones Then
		CollapsePaymentScheduleStages(ScheduleStages);
	EndIf;
	
	Return ChangedPaymentMilestones;
	
EndFunction

// if possible, the procedure will recalculate the payment milestones of the customer's order after filling out the collateral.
// 
// Parameters:
//  Object - DocumentObject.SalesOrder, DocumentObject.MaterialProviderOrder2_5 - order in which the shipping dates have changed
Procedure AfterFillingOutCollateral(Object) Export
	
	ChangedPaymentMilestones = False;
	
	ScheduleStages = Object.PaymentScheduleSteps;
	
	ApprovalDate = Object.ApprovalDate;
	OrderDate = Object.Date;
	If TypeOf(Object.Ref) = Type("DocumentRef.SalesOrder") Then
		ShippingDates = Object.Goods.UnloadColumn("DateOfShipment");
	Else
		ShippingDates = Object.ManufacturedProduct.UnloadColumn("DateOfShipment");
	EndIf;
	ShippingDates = CommonClientServer.CollapseArray(ShippingDates);
	If ShippingDates.Count() = 1 Then
		DateOfShipment = ShippingDates[0];
	Else
		// multiple shipping dates - do not clear or move the current payment schedule
		Return;
	EndIf;
	
	AgreementParameters = New Structure("Calendar, DeadlineOfTransferOfTitleToGoods");
	If TypeOf(Object.Ref) = Type("DocumentRef.SalesOrder") And ValueIsFilled(Object.Terms) Then
		DetailsOfAgreement = Common.ObjectAttributesValues(Object.Terms, "Calendar, DeadlineOfTransferOfTitleToGoods");
		FillPropertyValues(AgreementParameters, DetailsOfAgreement);
	Else
		AgreementParameters.Calendar = Catalogs.BusinessCalendars.EmptyRef();
		AgreementParameters.DeadlineOfTransferOfTitleToGoods = 0;
	EndIf;
	
	For Each StageString_ In ScheduleStages Do
		If PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(StageString_.CalculateFrom,StageString_.Formula) Then
			PaymentDateCalculationParameters = PaymentStepsClientServer.PaymentDateCalculationParameters();
			PaymentDateCalculationParameters.CalculateFrom                 = StageString_.CalculateFrom;
			PaymentDateCalculationParameters.Formula                        = StageString_.Formula;
			PaymentDateCalculationParameters.Move                          = StageString_.Move;
			PaymentDateCalculationParameters.OrderDate                     = OrderDate;
			PaymentDateCalculationParameters.ApprovalDate               = ApprovalDate;
			PaymentDateCalculationParameters.DateOfShipment                   = DateOfShipment;
			PaymentDateCalculationParameters.DateOfTransferOfTitleToGoods = Date(1,1,1);
			PaymentDateCalculationParameters.DeadlineOfTransferOfTitleToGoods = AgreementParameters.DeadlineOfTransferOfTitleToGoods;
			PaymentDateCalculationParameters.Calendar                      = AgreementParameters.Calendar;
			ChangedPaymentMilestones = True;
			If ValueIsFilled(AgreementParameters.Calendar)  Then
				StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(PaymentDateCalculationParameters);
			Else
				StageString_.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(PaymentDateCalculationParameters);
			EndIf;
		EndIf;
	EndDo;
	
	If ChangedPaymentMilestones Then
		CollapsePaymentScheduleStages(ScheduleStages);
		Object.AdditionalProperties.Insert("NotifyAboutCompletionOfStages", True);
	EndIf;
	
EndProcedure

// A tree of operands for formulas for calculating the payment date. It is used on the form of Catalogs of formulas and when calculating these formulas.
// 
// Returns:
//  ValueTree - The Operand Tree For The Formula:
// * Id - String - 
// * Presentation - String - 
// * TreeItemType - String - 
// * OperandSelectionAllowed - Boolean - 
// * IncludedInID - Boolean - 
// * ValueType - TypeDescription - 
// * ExpandToAttributes - Boolean - 
// * Value - Number - 
// * ContainsValue - Boolean - 
// * DeletionMark - Boolean - 
Function OperandTreeForFormula() Export
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "Move";
	RootRowOfTree.Presentation = NStr("ru = 'Срок (дн)';
										|vi = 'Period (days)';
										|en = 'Period (days)'; fa = 'دوره (روز)';
										|it = 'Termine (giorni)';
										|pl = 'Termin (dni)';
										|tr = 'Süre (gün)'");
	RootRowOfTree.ValueType = Common.TypeDescriptionNumber(3,0);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "OrderDate";
	RootRowOfTree.Presentation = NStr("ru = 'Дата заказа/договора';
										|vi = 'Order/contract date';
										|en = 'Order/contract date'; fa = 'Order/contract date';
										|it = 'Order/contract date';
										|pl = 'Order/contract date';
										|tr = 'Sipariş/Sözleşme tarihi'");
	RootRowOfTree.ValueType = Common.DateTypeDetails(DateFractions.Date);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "ApprovalDate";
	RootRowOfTree.Presentation = NStr("ru = 'Дата согласования';
										|vi = 'Approval date';
										|en = 'Approval date'; fa = 'تاریخ تأیید';
										|it = 'Data dell''accordo';
										|pl = 'Data uzgodnienia';
										|tr = 'Anlaşma tarihi'");
	RootRowOfTree.ValueType = Common.DateTypeDetails(DateFractions.Date);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "DateOfShipment";
	RootRowOfTree.Presentation = NStr("vi = 'Ngày giao hàng';
										|ru = 'Дата отгрузки';
										|en = 'Shipment date'; fa = 'تاریخ ارسال';
										|it = 'Data di spedizione';
										|pl = 'Data wysyłki';
										|tr = 'Sevkiyat tarihi'");
	RootRowOfTree.ValueType = Common.DateTypeDetails(DateFractions.Date);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "DateOfReceipt";
	RootRowOfTree.Presentation = NStr("vi = 'Ngày tiếp nhận';
										|ru = 'Дата поступления';
										|en = 'Date of receipt'; fa = 'تاریخ دریافت';
										|it = 'Data di ricezione';
										|pl = 'Data przyjęcia';
										|tr = 'Giriş tarihi'");
	RootRowOfTree.ValueType = Common.DateTypeDetails(DateFractions.Date);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "DeadlineOfTransferOfTitleToGoods";
	RootRowOfTree.Presentation = NStr("ru = 'Срок перехода права собственности';
										|vi = 'Deadline of transfer of title to goods';
										|en = 'Deadline of transfer of title to goods'; fa = 'مهلت انتقال مالکیت کالا';
										|it = 'Periodo di trasferimento diritti di proprietà';
										|pl = 'Termin przejścia prawa własności';
										|tr = 'Mülkiyet hakkı devir süresi'");
	RootRowOfTree.ValueType = Common.TypeDescriptionNumber(3,0);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	RootRowOfTree = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	RootRowOfTree.Id = "DateOfTransferOfTitleToGoods";
	RootRowOfTree.Presentation = NStr("ru = 'Дата перехода права собственности';
										|vi = 'Date of transfer of title to goods';
										|en = 'Date of transfer of title to goods'; fa = 'تاریخ انتقال مالکیت کالا';
										|it = 'Data di transizione del diritto di proprietà';
										|pl = 'Data przejścia prawa własności';
										|tr = 'Mülkiyet hakkının devir tarihi'");
	RootRowOfTree.ValueType = Common.DateTypeDetails(DateFractions.Date);
	RootRowOfTree.OperandSelectionAllowed = True;
	RootRowOfTree.IncludedInID = True;
	RootRowOfTree.ExpandToAttributes = False;
	
	Return OperandsTree;
	
EndFunction

// Returns various completed shipment dates from the table part by non-canceled lines.
// 
// Parameters:
//  TabularSection - FormDataCollection,ValueTable - Table part
//  PathToShipmentDateField - String - The path to the date of shipment in the document
// 
// Returns:
//  Structure - Various Dates:
// * ShippingDates - Array of Date - Different shipping dates - shipping dates from the tabular part of the document.
// * DatesOfReceipt - Array of Date - Different dates of receipt - dates of receipt from the tabular part of the document.
// * OrderDates - Array of Date - Various order dates - order dates from the tabular part of the document.
// * ApprovalDates - Array of Date - Various approval dates - the dates of approval of orders from the tabular part of the document.
Function VariousDates(TabularSection, PathToShipmentDateField = "") Export
	
	ShippingDates = New Array;
	DatesOfReceipt = New Array;
	OrderDates = New Array;
	ApprovalDates = New Array;
	
	If TabularSection.Count() > 0 Then
		If ValueIsFilled(PathToShipmentDateField) Then
			SubstringsArray = StrSplit(PathToShipmentDateField,".");
			FieldNameShipmentDate = SubstringsArray[SubstringsArray.UBound()];
		Else
			FieldNameShipmentDate = "DateOfShipment";
		EndIf;
		
		IsCanceled = CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "Canceled");
		ThereIsShippingDate = CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "DateOfShipment");
		ThereIsDateOfReceipt = CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "DateOfReceipt");
		ThereIsOrderDate = CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "OrderDate");
		ThereIsDateOfApproval = CommonClientServer.HasAttributeOrObjectProperty(TabularSection[0], "ApprovalDate");
		
		For Each Page1 In TabularSection Do
			If ThereIsShippingDate And ValueIsFilled(Page1[FieldNameShipmentDate]) And (Not IsCanceled Or Not Page1.Canceled) Then
				ShippingDates.Add(Page1[FieldNameShipmentDate]);
			EndIf;
			If ThereIsDateOfReceipt And ValueIsFilled(Page1.DateOfReceipt) And (Not IsCanceled Or Not Page1.Canceled) Then
				DatesOfReceipt.Add(Page1.DateOfReceipt);
			EndIf;
			If ThereIsOrderDate And ValueIsFilled(Page1.OrderDate) Then
				OrderDates.Add(Page1.OrderDate);
			EndIf;
			If ThereIsDateOfApproval And ValueIsFilled(Page1.ApprovalDate) Then
				ApprovalDates.Add(Page1.ApprovalDate);
			EndIf;
		EndDo;
		ShippingDates = CommonClientServer.CollapseArray(ShippingDates);
		DatesOfReceipt = CommonClientServer.CollapseArray(DatesOfReceipt);
		OrderDates = CommonClientServer.CollapseArray(OrderDates);
		ApprovalDates = CommonClientServer.CollapseArray(ApprovalDates);
	EndIf;
	
	Return New Structure("ShippingDates,DatesOfReceipt,OrderDates,ApprovalDates",ShippingDates,DatesOfReceipt,OrderDates,ApprovalDates);
EndFunction

Procedure PlacePaymentStepsInTemporaryStorage(Form, TagName) Export
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, TagName);
	
	PaymentSteps = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps);
	ValueTable = PaymentSteps.Unload();
	
	If ValueTable.Columns.Find("PaymentOption") = Undefined Then
		If ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			ValueTable.Columns.Add("PaymentOption", New TypeDescription("EnumRef.CustomerPaymentControlOptions"));
			ValueTable.FillValues(Enums.CustomerPaymentControlOptions.CreditPlanned, "PaymentOption");
		Else
			ValueTable.Columns.Add("PaymentOption", New TypeDescription("EnumRef.OptionsForControllingPaymentToSupplier"));
			ValueTable.FillValues(Enums.OptionsForControllingPaymentToSupplier.CreditAfterReceipt, "PaymentOption");
		EndIf;
	EndIf;
	
	ParametersStructure.AddressStagesOfPayment = PutToTempStorage(ValueTable, New UUID());
	
	TMCommonUse.SaveEngineDataToFormCache(Form, "ARAPAccounting", MechanismParameters);
	
EndProcedure

Procedure LoadPaymentStagesFromTemporaryStorage(Form) Export
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersArray = MechanismParameters.ParametersArray;
	For Each ParametersStructure In ParametersArray Do
		If ValueIsFilled(ParametersStructure.AddressStagesOfPayment) Then
			
			PaymentSteps = TMCommonUseClientServer.DataAlongWay(Form,ParametersStructure.PathToTSDataPaymentSteps);
			NewPaymentStages = GetFromTempStorage(ParametersStructure.AddressStagesOfPayment);
			OldPaymentMilestones = PaymentSteps.Unload();
			
			If NewPaymentStages <> Undefined Then 
				
				RequiredReFilling = True;
				If ParametersStructure.ThisIsOrder Then
					If ARAPAccountingInternal.TablesAreEqual(OldPaymentMilestones, NewPaymentStages) Then
						RequiredReFilling = False
					Else
						ParametersStructure.SeveralShippingDatesHaveChanged = False;
					EndIf;
				EndIf;
				If RequiredReFilling Then
					PaymentSteps.Clear();
					For Each CurRow In NewPaymentStages Do
						NewRow = PaymentSteps.Add();
						FillPropertyValues(NewRow, CurRow);
					EndDo;
					DeleteFromTempStorage(ParametersStructure.AddressStagesOfPayment);
					ParametersStructure.AddressStagesOfPayment = ""; 
				EndIf;
			EndIf;
			
			ARAPAccountingFormWork.UpdateHyperlinkTextPaymentSteps(Form, ParametersStructure, MechanismParameters.SystemSettings_);
			
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure ConvertStageTableToSimplifiedModeData(PaymentSteps, DateOfShipment, ThereIsPrepayment, Calendar)
	
	SimplifiedData = SimplifiedModeData(PaymentSteps, DateOfShipment, ThereIsPrepayment, Calendar);
	
	ThereIsPackage = PaymentSteps.Count() > 0 
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"PackageDepositValue");
	ThereIsSumOfMutualSettlements = PaymentSteps.Count() > 0
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"AmountARAP");
	ThereAreShippingDates = PaymentSteps.Count() > 0 
		And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"DateOfShipment");
	
	PaymentSteps.Clear();
	
	If SimplifiedData.PaymentAmountPrepayment + SimplifiedData.DepositAmountForPackagingPrepayment <> 0 Then
		NwRw = PaymentSteps.Add();
		NwRw.PaymentAmount      = SimplifiedData.PaymentAmountPrepayment;
		NwRw.PaymentPercentage    = SimplifiedData.PaymentPercentagePrepayment;
		NwRw.PaymentDate       = SimplifiedData.DatePrepayment;
		If ThereAreShippingDates Then
			NwRw.DateOfShipment      = SimplifiedData.DateOfShipmentPrepayment;
		EndIf;
		NwRw.CalculateFrom    = SimplifiedData.CountdownOptionPrepayment;
		NwRw.PaymentOption     = SimplifiedData.ControlOptionPrepayment;
		NwRw.Move             = SimplifiedData.ShiftPrepayment;
		If ThereIsPackage Then
			NwRw.PackageDepositValue   = SimplifiedData.DepositAmountForPackagingPrepayment;
			NwRw.PackageDepositPercentage = SimplifiedData.PercentageOfTheDepositForTheContainerPrepayment;
		EndIf;
		If ThereIsSumOfMutualSettlements Then
			NwRw.AmountARAP = SimplifiedData.AmountOfSettlementsPrepayment;
			If ThereIsPackage Then
				NwRw.AmountARAPByPackage = SimplifiedData.AmountOfSettlementsOnContainersPrepayment;
			EndIf;
		EndIf;
	EndIf;
	
	If SimplifiedData.PaymentAmountCredit + SimplifiedData.TheAmountOfTheDepositForTheContainerLoan <> 0 Then
		NwRw = PaymentSteps.Add();
		NwRw.PaymentAmount      = SimplifiedData.PaymentAmountCredit;
		NwRw.PaymentPercentage    = SimplifiedData.PercentageOfPaymentCredit;
		NwRw.PaymentDate       = SimplifiedData.DateCredit;
		If ThereAreShippingDates Then
			NwRw.DateOfShipment      = SimplifiedData.DateOfShipmentCredit;
		EndIf;
		NwRw.CalculateFrom    = SimplifiedData.CreditReferenceOption;
		NwRw.PaymentOption     = SimplifiedData.CreditControlOption;
		NwRw.Move             = SimplifiedData.ShiftCredit;
		If ThereIsPackage Then
			NwRw.PackageDepositValue   = SimplifiedData.TheAmountOfTheDepositForTheContainerLoan;
			NwRw.PackageDepositPercentage = SimplifiedData.ThePercentageOfTheDepositForTheContainerLoan;
		EndIf;
		If ThereIsSumOfMutualSettlements Then
			NwRw.AmountARAP = SimplifiedData.AmountOfSettlementsCredit;
			If ThereIsPackage Then
				NwRw.AmountARAPByPackage = SimplifiedData.AmountOfSettlementsOnContainerCredit;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

// collapses the matching stages of the payment schedule
//
// Parameters:
//  PaymentScheduleSteps	 - 	FormDataCollection, TabularSection - Table Of Stages Of The Payment Schedule
//
Procedure CollapsePaymentScheduleStages(PaymentScheduleSteps)
	
	TableStagesOfPaymentSchedule = PaymentScheduleSteps.Unload();
	ColumnsArray1 = New Array;
	For Each Column In TableStagesOfPaymentSchedule.Columns Do
		ColumnsArray1.Add(Column.Name);
	EndDo;
	
	ArrayOfDimensions_ = New Array;
	ArrayOfDimensions_.Add("PaymentOption");
	ArrayOfDimensions_.Add("CalculateFrom");
	ArrayOfDimensions_.Add("Formula");
	ArrayOfDimensions_.Add("PaymentDate");
	ArrayOfDimensions_.Add("Move");
	ArrayOfDimensions_.Add("OrderDocument");
	ArrayOfDimensions_.Add("ARAPObject");
	ArrayOfDimensions_.Add("ExceedingOrder");
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add("PaymentAmount");
	ArrayOfResources.Add("PaymentPercentage");
	ArrayOfResources.Add("PackageDepositValue");
	ArrayOfResources.Add("PackageDepositPercentage");
	ArrayOfResources.Add("MeasuringGoodsVarianceAmount");
	ArrayOfResources.Add("AmountARAP");
	ArrayOfResources.Add("AmountARAPByPackage");
	
	ArrayOfDimensions_ = TMCommonUseClientServer.IntersectionOfArrays(ArrayOfDimensions_, ColumnsArray1);
	ArrayOfResources = TMCommonUseClientServer.IntersectionOfArrays(ArrayOfResources, ColumnsArray1);
	MeasurementColumns = StrConcat(ArrayOfDimensions_, ",");
	ResourceColumns = StrConcat(ArrayOfResources, ",");
	
	TableStagesOfPaymentSchedule.GroupBy(MeasurementColumns,ResourceColumns);
	
	PaymentStepsServer.FillInInterestOnAmounts(TableStagesOfPaymentSchedule);
	PaymentStepsClientServer.SortStageTable(TableStagesOfPaymentSchedule);
	
	PaymentScheduleSteps.Clear();
	For Each Page1 In TableStagesOfPaymentSchedule Do
		FillPropertyValues(PaymentScheduleSteps.Add(),Page1);
	EndDo;

EndProcedure

Function PaymentStageAmount(PaymentStage, PayAmount, ThisIsDepositForPackage = False)
	
	If PaymentStage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeProvision
		Or PaymentStage.PaymentOption = Enums.CustomerPaymentControlOptions.PrepaymentBeforeShipment
		Or PaymentStage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation
		Or PaymentStage.PaymentOption = Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt Then
		Return TMCommonUseClientServer.RoundFloor(
			PayAmount 
				* ?(ThisIsDepositForPackage, PaymentStage.PackageDepositPercentage, PaymentStage.PaymentPercentage) / 100,
			2);
	Else
		Return Round(
			PayAmount 
				* ?(ThisIsDepositForPackage, PaymentStage.PackageDepositPercentage, PaymentStage.PaymentPercentage) / 100, 
			2,
			RoundMode.Round15as20);
	EndIf;
	
EndFunction

Procedure ClearStagesOfPaymentScheduleONChangingCompositionOfOrder(Object,ParametersStructure, PaymentScheduleSteps)
	
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		OrderAmounts = ARAPAccountingServer.TableOfOrderAmounts(Object.Object, ParametersStructure);
	Else
		OrderAmounts = ARAPAccountingServer.TableOfOrderAmounts(Object, ParametersStructure);
	EndIf;
	PackageDepositIsRequired      = TMCommonUseClientServer.DataAlongWay(Object, ParametersStructure.PackageDepositIsRequired,,False);
	TotalingColumns = New Array;
	TotalingColumns.Add("PaymentAmount");
	If PackageDepositIsRequired Then
		TotalingColumns.Add("PackageDepositValue");
	EndIf;
	If ParametersStructure.CustomerSettlementDocument
		And Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
		MeasurementColumns = "OrderDocument";
	Else
		MeasurementColumns = "OrderDocument, ExceedingOrder";
	EndIf;
	
	For Each PlotLine In PaymentScheduleSteps Do
		NewRow = OrderAmounts.Add();
		FillPropertyValues(NewRow, PlotLine);
		NewRow.PaymentAmount        = - NewRow.PaymentAmount;
		If PackageDepositIsRequired Then
			NewRow.PackageDepositValue         = - NewRow.PackageDepositValue;
		EndIf;
	EndDo;
	
	OrderAmounts.GroupBy(MeasurementColumns, StrConcat(TotalingColumns, ","));
	For Each SumString In OrderAmounts Do
		If SumString.PaymentAmount <> 0
			Or PackageDepositIsRequired
				And SumString.PackageDepositValue <> 0 Then
			PaymentScheduleSteps.Clear();
			Break;
		EndIf;
		If PaymentScheduleSteps.Count() = 0 Then
			Break;
		EndIf;
	EndDo;
EndProcedure

Function OrderTypes()
	Types = New Array;
	Types.Add(Type("DocumentRef.SalesOrder"));
	Types.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	Types.Add(Type("DocumentRef.PurchaseOrder"));
	
	Types.Add(Type("DocumentRef.SubcontractOrder2_5"));
	Types.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	Return Types;
EndFunction

#EndRegion
