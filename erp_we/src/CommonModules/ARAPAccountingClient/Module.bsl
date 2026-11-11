
#Region Public

#Region CommonProgrammingInterface

//notifies about the completion of payment milestones and changes to the AR/AP object,
//notifies about changes in the invoice for the order form of order lists.
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 
Procedure FormAfterRecording(Form) Export
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	If AugmentedMechanismParameters.NotifyAboutCompletionOfStages Then
		PaymentStepsClient.NotifyEndOfFillingInStagesOfPaymentSchedule();
	EndIf;
	If AugmentedMechanismParameters.NotifyAboutChangesToPaymentObject Then
		NotifyChanged(AugmentedMechanismParameters.ModifiedCalculationObject);
	EndIf;
	OrderList = New Array;
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		If ParametersStructure.ThisIsSalePurchase Then
			TS = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSData);
			If ValueIsFilled(TS) And ValueIsFilled(ParametersStructure.PropsNameTSOrder) Then
				For Each TSRow In TS Do
					OrderList.Add(TSRow[ParametersStructure.PropsNameTSOrder]);
				EndDo;
				Cnt = 0;
				While Cnt < OrderList.Count() Do
					If Not ValueIsFilled(OrderList[Cnt]) Then
						OrderList.Delete(Cnt);
					Else
						Cnt= Cnt + 1;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndDo;
	OrderList = CommonClientServer.CollapseArray(OrderList);
	If OrderList.Count() = 1 Then
		NotifyChanged(OrderList[0]);
	ElsIf OrderList.Count() > 1 Then 
		NotifyChanged(TypeOf(OrderList[0]));
	EndIf;
EndProcedure

//Notifies you about the choice when creating a AR/AP object
//
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 
Procedure FormWhenClosing(Form)Export
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		ChoiceStructure = New Structure;
		ChoiceStructure.Insert("ARAPObject",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObject));
		ChoiceStructure.Insert("ARAPObjectSettings",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings));
		ChoiceStructure.Insert("Contract",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract));
		ChoiceStructure.Insert("Object",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref));
		ChoiceStructure.Insert("ARAPCurrency",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency));
		ChoiceStructure.Insert("Counterparty",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty));
		ChoiceStructure.Insert("Partner",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Partner));
		ChoiceStructure.Insert("Date",
			TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date));
		Form.NotifyChoice(ChoiceStructure);
		Break;
	EndDo;
EndProcedure

#EndRegion

#Region ScheduledPaymentSchedule

// Opens the form for editing payment rules.
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	Item - FormField - A hyperlink to open the payment rules form that is associated with a specific set of parameters.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	Notification - CallbackDescription - Description of the form notification to be executed after the configuration is complete.
//
Procedure LabelPaymentStagesClick(Form, Item, StandardProcessing, Notification = Undefined) Export
	
	Try
		Form.LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	SystemSettings_ = MechanismParameters.SystemSettings_;
	StandardProcessing = False;
	ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, Item.Name);
	
	If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
		ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure, "PaymentDate");
	EndIf;
	
	ARAPObjectSettings = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
	ThisIsOrder        = ParametersStructure.ThisIsOrder;
	
	OpeningParameters = New Structure();
	OpeningParameters.Insert("ReadOnly",                          Form.ReadOnly Or ParametersStructure.PaymentStagesViewOnly);
	
	If ValueIsFilled(ParametersStructure.AmountOfDepositForContainerForm) Then
		AmountOfCollateralPackaging = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.AmountOfDepositForContainerForm);
	Else
		AmountOfCollateralPackaging = 0;
	EndIf;
	
	OpeningParameters.Insert("DepositAmountUnderTheDocument",                  AmountOfCollateralPackaging);
	AmountTotal = ARAPAccountingClientServer.AmountToPay(Form, ParametersStructure);
	OpeningParameters.Insert("PaymentAmountAgainstTheDocument",                  AmountTotal - AmountOfCollateralPackaging);
	
	If (ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")
		Or ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice"))
		And ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		AmountOfPaymentDecryption = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentDecryption).Total("AmountARAP");
		OpeningParameters.Insert("MandatoryPrepaymentAmount", AmountOfPaymentDecryption);
	Else
		OpeningParameters.Insert("MandatoryPrepaymentAmount", 0);
	EndIf;
	
	OpeningParameters.Insert("PackageDepositIsRequired",                    AmountOfCollateralPackaging <> 0);
	
	PaymentSteps = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps);
	ThereIsSumOfDeviationOfDimensionalGoods = SystemSettings_.UseAllowableDeviationOfMeasuringGoodsShipmentReceiving
										And PaymentSteps <> Undefined
										And PaymentSteps.Count() > 0
										And CommonClientServer.HasAttributeOrObjectProperty(PaymentSteps[0],"MeasuringGoodsVarianceAmount");
	If ThereIsSumOfDeviationOfDimensionalGoods Then
		MeasuringGoodsVarianceAmount = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps).Total("MeasuringGoodsVarianceAmount");
	Else
		MeasuringGoodsVarianceAmount = 0;
	EndIf;
	OpeningParameters.Insert("DocumentVarianceAmount",                 MeasuringGoodsVarianceAmount);
	
	//form details
	OpeningParameters.Insert("UUID",                 Form.UUID);
	OpeningParameters.Insert("Key",                                    Form.Object.Ref);
	OpeningParameters.Insert("AttributeSelectionParameters",               ParametersStructure.AttributeSelectionParameters);
	
	//details of the object
	OpeningParameters.Insert("Partner",                                 TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Partner));
	OpeningParameters.Insert("Terms",                              TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Terms));
	OpeningParameters.Insert("Contract",                                 TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract));
	OpeningParameters.Insert("Date",                                    TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date));
	OpeningParameters.Insert("Currency",                                  TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency));
	OpeningParameters.Insert("PaymentSchedule",                            TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentSchedule));
	OpeningParameters.Insert("PaymentMethod",                             TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentMethod));
	OpeningParameters.Insert("CashAccount",                                   TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CashAccount));
	OpeningParameters.Insert("BankAccount",                          TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CompanyBankAccount));
	OpeningParameters.Insert("Organization",                             TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization));
	OpeningParameters.Insert("PaymentID",                    TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentID));
	If ParametersStructure.DocumentOfSettlementsWithSuppliers
		And ValueIsFilled(ParametersStructure.PaymentID) Then
		OpeningParameters.Insert("ItIsAllowedToChangeUIP", True);
	EndIf;

	OpeningParameters.Insert("ARAPObjectSettings",                         ARAPObjectSettings);
	OpeningParameters.Insert("LineOfBusiness",                 TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.LineOfBusiness));
	OpeningParameters.Insert("ForeignCurrencyTransaction",                           TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ForeignCurrencyTransaction));
	OpeningParameters.Insert("PaymentDate",                             TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentDate));
	
	DataPathSettlementCurrency = ?(ParametersStructure.ARAPCurrency = "", ParametersStructure.DocumentCurrency, ParametersStructure.ARAPCurrency);
	OpeningParameters.Insert("ARAPCurrency",                    TMCommonUseClientServer.DataAlongWay(Form, DataPathSettlementCurrency));
	
	OpeningParameters.Insert("Counterparty",                              TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty));
	OpeningParameters.Insert("CounterpartyBankAccount",               TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CounterpartyBankAccount));
	OpeningParameters.Insert("TSP",                                     TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.TSP));
	
	//Settings
	InvoiceForOrders = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders,, False);
	OpeningParameters.Insert("InvoiceForOrders",                      InvoiceForOrders);
	
	OpeningParameters.Insert("ThisIsOrder",                                ThisIsOrder);
	OpeningParameters.Insert("FieldNameOrder",                            ParametersStructure.PropsNameTSOrder);
	OpeningParameters.Insert("OrderAsAProformaInvoice",                            ParametersStructure.OrderAsAProformaInvoice);
	
	If ThisIsOrder Then
		OpeningParameters.Insert("ApprovalDate",                    TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ApprovalDate));
		OpeningParameters.Insert("OrderDate",                          OpeningParameters.Date);
	EndIf;
	
	If ParametersStructure.CustomerSettlementDocument
		And ParametersStructure.ThisIsSalePurchase Then
		OpeningParameters.Insert("DateOfShipment",                        OpeningParameters.Date);
		OpeningParameters.Insert("MultipleShippingDates",                False);
	ElsIf StrOccurrenceCount(ParametersStructure.DateOfShipment, ".") > 1 Then
		OpeningParameters.Insert("DateOfShipment",                        Date(1,1,1));
		OpeningParameters.Insert("MultipleShippingDates",                True);
	Else
		OpeningParameters.Insert("DateOfShipment",                        TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DateOfShipment));
		OpeningParameters.Insert("MultipleShippingDates",                False);
	EndIf;
	
	If ParametersStructure.DocumentOfSettlementsWithSuppliers Then
		OpeningParameters.Insert(
			"DisableFillingInForPreviousOrders",
			TypeOf(Form.Object.Ref) <> Type("DocumentRef.SubcontractOrder2_5") And
			TypeOf(Form.Object.Ref) <> Type("DocumentRef.PurchaseOrder"));
	EndIf;
	
	OpeningParameters.Insert("Calendar",                               TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Calendar));
	OpeningParameters.Insert("DeadlineOfTransferOfTitleToGoods",          TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DeadlineOfTransferOfTitleToGoods));
	OpeningParameters.Insert("DateOfTransferOfTitleToGoods",          TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DateOfTransferOfTitleToGoods));
	
	OpeningParameters.Insert("SelfServiceMode",                   TMCommonUseClientServer.AnExternalUserIsAuthorized());
	OpeningParameters.Insert("AddressInTempStorage",               ParametersStructure.AddressStagesOfPayment);
	OpeningParameters.Insert("AddressOfOrderAmounts",                      ARAPAccountingServerCall.PlaceOrderAmountsInTemporaryStorage(Form.Object, ParametersStructure));
	OpeningParameters.Insert("ExecutionScheduleIsSpecified",                   ParametersStructure.ExecutionScheduleIsSpecified);
	OpeningParameters.Insert("ContractSchedule",                ParametersStructure.ContractSchedule);
	OpeningParameters.Insert("SpecialStageHeadersForTheReturn", TypeOf(Form.Object.Ref) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	OpeningParameters.Insert("NoPrepaymentControl",                   ParametersStructure.NoPrepaymentControl);
	OpeningParameters.Insert("ThereIsDateOfTransferOfOwnership",      ParametersStructure.ThereIsDateOfTransferOfOwnership);
	OpeningParameters.Insert("ThereAreManualChangesToPaymentSchedule",         ParametersStructure.ThereAreManualChangesToPaymentSchedule);
	OpeningParameters.Insert("DoNotSpecifyPaymentSources",              ParametersStructure.DoNotSpecifyPaymentSources);
	OpeningParameters.Insert("ThisIsTransferOfOwnership2_5",         ParametersStructure.ThisIsTransferOfOwnership2_5);
	
	If  TypeOf(Form.Object.Ref) = Type("DocumentRef.SaleAdjustment")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.PurchaseAdjustment") Then
		OpeningParameters.Insert("AvailablePaymentTerms", CommonClientServer.ValueInArray(OpeningParameters.ARAPObjectSettings));
		OpeningParameters.Insert("ThisIsAdjustment", True);
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.ConsignmentReportFromCustomer")
			And ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CommissionAgentSAgreement)) Then
		ListOfOrders_ = New ValueList;
		ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
		ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByOrders"), NStr("vi = 'Theo bảng kê của người nhận ký gửi/bán hàng thông qua người nhận ký gửi';
																					|ru = 'По отчетам комиссионера/реализациям через комиссионера';
																					|en = 'By consignment issue notifications/sales via consignee'; fa = 'By consignment issue notifications/sales via consignee';
																					|it = 'Per report di commissionario/vendite tramite commissionario';
																					|pl = 'Według raportów komisanta/sprzedaży przez komisanta';
																					|tr = 'Komisyon acentesi raporları / komisyon acentesi aracılığıyla gerçekleşen satışlar'"));
		OpeningParameters.Insert("AvailablePaymentTerms", ListOfOrders_);
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.CustomerInvoice")
			And ValueIsFilled(TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CommissionAgentSAgreement)) Then
		ListOfOrders_ = New ValueList;
		If ParametersStructure.ConductARAPAccountingThroughEndCustomers Then
			ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
		Else
			ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
			ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"), NStr("vi = 'Ứng trước theo hợp đồng, công nợ theo hóa đơn (chỉ giao hàng)';
																														|ru = 'Аванс по договорам, долг по накладным (только реализация)';
																														|en = 'Invoice for debt, Contract for prepayment (sales only)'; fa = 'Invoice for debt, Contract for prepayment (sales only)';
																														|it = 'Anticipo da accordi, debito su fatture (solo vendita)';
																														|pl = 'Zaliczka z tytułu kontraktów, dług z tytułu faktur (tylko sprzedaż)';
																														|tr = 'Sözleşme avansı, irsaliye borcu (sadece satışlar)'"));
			ListOfOrders_.Add(PredefinedValue("Enum.ARAPObjectSettings.ByOrders"), NStr("vi = 'Theo bảng kê của người nhận ký gửi/bán hàng thông qua người nhận ký gửi';
																						|ru = 'По отчетам комиссионера/реализациям через комиссионера';
																						|en = 'By consignment issue notifications/sales via consignee'; fa = 'By consignment issue notifications/sales via consignee';
																						|it = 'Per report di commissionario/vendite tramite commissionario';
																						|pl = 'Według raportów komisanta/sprzedaży przez komisanta';
																						|tr = 'Komisyon acentesi raporları / komisyon acentesi aracılığıyla gerçekleşen satışlar'"));
		EndIf;
		OpeningParameters.Insert("AvailablePaymentTerms", ListOfOrders_);
	
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.IntercompanyGoodsReturn")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.CustomerInvoiceIntercompany")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.CommissionReportIntercompany")
		Or TypeOf(Form.Object.Ref) = Type("DocumentRef.CommissionWriteOffReportIntercompany") Then
		
		If Form.Object.ARAPAccountingViaSeparateCounterparty Then
			
			OpeningParameters.Insert(
				"AvailablePaymentTerms",
				CommonClientServer.ValueInArray(OpeningParameters.ARAPObjectSettings));
			
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("ParametersStructure", ParametersStructure);
	AdditionalParameters.Insert("NotificationAfterCompletion", Notification);
	AdditionalParameters.Insert("MechanismParameters", MechanismParameters);
	
	ClosingNotification1 = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject, AdditionalParameters);
	
	If ParametersStructure.CustomerSettlementDocument Then
		OpenForm("CommonForm.CustomerPaymentRules", 
			OpeningParameters,
			Form,,,,
			ClosingNotification1,
			FormWindowOpeningMode.LockOwnerWindow);
	Else
		OpenForm("CommonForm.StepsOfPaymentsToVendor", 
			OpeningParameters,
			Form,,,,
			ClosingNotification1,
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

// Service handler for closing the payment rules form.
Procedure LabelPaymentStagesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationAfterCompletion);
		EndIf;
		Return;
	EndIf;
	
	Form               = AdditionalParameters.Form;
	ParametersStructure = AdditionalParameters.ParametersStructure;
	MechanismParameters  = AdditionalParameters.MechanismParameters;
	
	PaymentSteps    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps); // FormDataCollection
	DocumentAmount = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmountForm);
	PaymentDate    = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.PaymentDate);
	
	//Details of the caps
	FieldArray = New Array();
	FieldArray.Add("CashAccount");
	FieldArray.Add("CompanyBankAccount");
	FieldArray.Add("ForeignCurrencyTransaction");
	FieldArray.Add("PaymentMethod");
	FieldArray.Add("ARAPObjectSettings");
	FieldArray.Add("PaymentDate");
	FieldArray.Add("PaymentSchedule");
	If ClosingResult.Property("PaymentID") Then
		FieldArray.Add("PaymentID");
	EndIf;
	OldValuesOfChangedProps = AssignNewValues(Form, ParametersStructure, ClosingResult, FieldArray);
	ParametersStructure.ThereAreManualChangesToPaymentSchedule = ClosingResult.ThereAreManualChangesToPaymentSchedule;
	
	//Payment stages or payment date
	If PaymentSteps <> Undefined Then
		If ClosingResult.Property("AddressInTempStorage") Then
			ParametersStructure.AddressStagesOfPayment = ClosingResult.AddressInTempStorage;
		ElsIf ClosingResult.Property("PaymentDate") Then
			NwRw = PaymentSteps.Add();
			NwRw.PaymentDate    = ClosingResult.PaymentDate;
			NwRw.PaymentAmount   = DocumentAmount;
			NwRw.PaymentPercentage = 100;
		EndIf;
		TSName = Right(ParametersStructure.PathToTSDataPaymentSteps, StrLen(ParametersStructure.PathToTSDataPaymentSteps) - Find(ParametersStructure.PathToTSDataPaymentSteps,"."));
		OldValuesOfChangedProps.Insert(TSName, Undefined);
	Else
		PaymentDetailsPaymentDate = PaymentDate;
		PaymentDetailsPaymentDate.Data[PaymentDetailsPaymentDate.Name] = ClosingResult.PaymentDate;
	EndIf;
	
	//Standard Return to Form
	ProcessingResults = New Structure();
	ProcessingResults.Insert("OldValuesOfChangedProps", OldValuesOfChangedProps);
	
	ARAPAccountingClientServer.SetVisibilityOfPaymentOffset(Form, ParametersStructure);
	
	Form.Modified = True;
	
	TMCommonUseClient.SaveEngineDataToFormCache(Form, "ARAPAccounting", MechanismParameters);
	
	If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
		RunCallback(AdditionalParameters.NotificationAfterCompletion, ProcessingResults);
	EndIf;
	
EndProcedure

// Service procedure that fills in the hyperlink text of the payment rules 
// 
// Parameters:
//	Form       - ClientApplicationForm - Agreement specified in the document:
//	 * Items - FormItems - elements of the calling form
//	ParametersStructure - See ARAPAccountingServer.MechanismParameters
//	SystemSettings_  - Structure - System settings from advanced settings, if already received.
//
Procedure UpdateHyperlinkTextPaymentSteps(Form, ParametersStructure = Undefined, SystemSettings_ = Undefined) Export
	
	If ParametersStructure <> Undefined And SystemSettings_ <> Undefined Then
		ParametersArray = New Array;
		ParametersArray.Add(ParametersStructure);
	Else
		AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersArray = AugmentedMechanismParameters.ParametersArray; // Array of See ARAPAccountingServer.MechanismParameters
		SystemSettings_ = AugmentedMechanismParameters.SystemSettings_;
	EndIf;
	
	For Each ParametersStructure In ParametersArray Do
		
		If Not ValueIsFilled(ParametersStructure.PaymentStepsText) Then
			Continue;
		EndIf;
		
		If Not ParametersStructure.ChangesPaymentPlan And Not ParametersStructure.OrderAsAProformaInvoice Then
			Form.Items[ParametersStructure.FormItems.InscriptionStages].Visible = False;
		Else
			Form.Items[ParametersStructure.FormItems.InscriptionStages].Visible = True;
		EndIf;
		
		If Not ValueIsFilled(ParametersStructure.PathToTSDataPaymentSteps) Then
			ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure, "PaymentDate");
		EndIf;
		
		Template = ARAPAccountingClientServer.FormattedStringOfPaymentStages(Form, ParametersStructure, SystemSettings_);
		FormattedString = StringFunctionsClient.FormattedString(Template);
		
		Attribute = TMCommonUseClientServer.DataForAssignment(Form, ParametersStructure.PaymentStepsText);
		Attribute.Data[Attribute.Name] = FormattedString;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region OffsetOfPaymentDecryptionOfPayment

// Opens the form for selecting payment objects in the table part of the payment Description of payment documents.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	TagName - String - Name of the element that the selection is triggered by clicking on.
// 	Notification - CallbackDescription - Description of the form notification to be performed after closing the transcript editing form.
// 	AdditionalFilters - Map of KeyAndValue:
// 		Key - the name of the details of the Calculation Objects directory, 
// 		The value is the right selection value.
//
Procedure AddToPaymentDecryption(Form, TagName, Notification = Undefined, AdditionalFilters = Undefined) Export 
	
	Try
		Form.LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, TagName);
	
	PartnerOtherRelations = ParametersStructure.PartnerOtherRelations;
	SelectAccountsReceivable = ParametersStructure.SelectAccountsReceivable;
	SelectOnlyUnconditionalDebt = ParametersStructure.SelectOnlyUnconditionalDebt;
	
	Counterparty           = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty);
	Ref               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
	Organization          = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
	Currency               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency);
	DocumentAmount       = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmount);
	Date                 = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date);
	PaymentID = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentID);
	PaymentType_          = ParametersStructure.PaymentType_;
	PaymentByRequests      = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentByRequests, , False);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ObjectRef",                          Ref);
	OpeningParameters.Insert("AddressOfPaymentsInTheStorage",               ParametersStructure.AddressPaymentDecryption);
	OpeningParameters.Insert("Organization",                           Organization);
	OpeningParameters.Insert("Counterparty",                            Counterparty);
	OpeningParameters.Insert("DocumentCurrency",                       Currency);
	OpeningParameters.Insert("DocumentAmount",                        DocumentAmount);
	OpeningParameters.Insert("DocumentDate",                         Date);
	OpeningParameters.Insert("PaymentType_",                           PaymentType_);
	OpeningParameters.Insert("PaymentID",                  PaymentID);
	OpeningParameters.Insert("PartnerOtherRelations",                PartnerOtherRelations);
	OpeningParameters.Insert("RecordBranches",                      ParametersStructure.RecordBranches);
	OpeningParameters.Insert("FillInVATInDecryption",              True);
	OpeningParameters.Insert("SelectAccountsReceivable",        SelectAccountsReceivable);
	OpeningParameters.Insert("SelectOnlyUnconditionalDebt",  SelectOnlyUnconditionalDebt);
	OpeningParameters.Insert("SelectionOfPaymentByRequest",                PaymentByRequests);
	OpeningParameters.Insert("AdditionalFilters",                  AdditionalFilters);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("ParametersStructure", ParametersStructure);
	AdditionalParameters.Insert("NotificationAfterCompletion", Notification);
	AdditionalParameters.Insert("MechanismParameters", MechanismParameters);
	
	ClosingNotification1 = New CallbackDescription("AddToPaymentDecryptionCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Catalog.ARAPObjects.Form.ARAPObjectSelection",
		OpeningParameters, 
		Form,,,,
		ClosingNotification1,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Service handler for closing the payment rules form.
Procedure AddToPaymentDecryptionCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationAfterCompletion);
		EndIf;
		Return;
	EndIf;
	
	Form               = AdditionalParameters.Form;
	ParametersStructure = AdditionalParameters.ParametersStructure;
	MechanismParameters  = AdditionalParameters.MechanismParameters;
	
	//Payment stages or payment date
	If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		If ClosingResult.Property("AddressOfPaymentsInTheStorage") Then
			ParametersStructure.AddressPaymentDecryption = ClosingResult.AddressOfPaymentsInTheStorage;
		EndIf;
	EndIf;
	
	//Standard Return to Form
	ProcessingResults = New Structure();
	ProcessingResults.Insert("Executed", True);
	
	Form.Modified = True;
	
	TMCommonUseClient.SaveEngineDataToFormCache(Form, "ARAPAccounting", MechanismParameters);
	
	If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
		RunCallback(AdditionalParameters.NotificationAfterCompletion, ProcessingResults);
	EndIf;
	
EndProcedure

// Opens the form for selecting the calculation object based on the passed selections and settings.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	Item - FormField - Field where the payment object or payment basis is selected.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	SelectingThePaymentBasis - Boolean - True if the payment Basis is selected, False if the payment object is selected.
// 	CurrentValue - CatalogRef, DocumentRef - A reference is specified to the Cur Current payment Object or Cur Basis of Payment for initial Positioning. the Reference is provided to the AR/AP Object.
// 	AdditionalFilters - Map of KeyAndValue, Undefined - additional selection according to the Objects of the Calculations. AR/AP Object.
//
Procedure ARAPObjectStartChoice(Form, Item, StandardProcessing, SelectingThePaymentBasis = False, CurrentValue = Undefined, AdditionalFilters = Undefined) Export
	
	StandardProcessing = False;
	
	Try
		Form.LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersStructure = MechanismParameters.ParametersArray[0]; // See ARAPAccountingServer.MechanismParameters
	
	Ref = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	RowID = Undefined;
	If FormTable <> Undefined Then 
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Counterparty                = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty, RowID);
	Organization               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization, RowID);
	
	Currency                    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency);
	PaymentType_               = ParametersStructure.PaymentType_;
	PaymentsAsPer275FZ            = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PaymentsAsPer275FZ, , False);
	SelectAccountsReceivable = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.SelectAccountsReceivable);
	
	If ValueIsFilled(ParametersStructure.FormItems.ARAPDetails) Then
		PaymentDecryptionElement = Form.Items[ParametersStructure.FormItems.ARAPDetails];
		Sum = PaymentDecryptionElement.CurrentData.Sum;
	Else
		Sum = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmount);
	EndIf;
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", PaymentType_);
	FilterValues.Insert("Organization", Organization);
	If ValueIsFilled(Counterparty) Then
		FilterValues.Insert("Counterparty",  Counterparty);
	EndIf;
	FilterValues.Insert("PaymentsAsPer275FZ" , PaymentsAsPer275FZ);
	
	If TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		FilterValues.Insert("Partner", PredefinedValue("Catalog.Partners.OurEnterprise"));
	ElsIf Not ValueIsFilled(Counterparty) Then
		Partner = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Partner, RowID);
		If TypeOf(Partner) = Type("CatalogRef.Partners") Then
			FilterValues.Insert("Partner", Partner);
		EndIf;
	EndIf;
	
	If AdditionalFilters <> Undefined Then
		FilterValues.Insert("AdditionalFilters", AdditionalFilters);
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("RecordBranches", ParametersStructure.RecordBranches);
	SelectionSettings_.Insert("SelectingThePaymentBasis", SelectingThePaymentBasis);
	SelectionSettings_.Insert("EditableDocument", Ref);
	SelectionSettings_.Insert("Currency", Currency);
	SelectionSettings_.Insert("Sum", Sum);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("ReturnStructure", True);
	SelectionSettings_.Insert("SelectAccountsReceivable", SelectAccountsReceivable);
	If CurrentValue <> Undefined Then
		SelectionSettings_.Insert("CurrentValue", CurrentValue);
	EndIf;
	
	OpenForm("Catalog.ARAPObjects.Form.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

// Opens the form for editing the payment transcript of the refund document.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	Item - FormField - Hyperlink for editing the payment transcript.
// 	Notification - CallbackDescription - Description of the form notification to be performed after closing the transcript editing form.
//
Procedure ARAPAccountingOnReturnOfGoods(Form, Item, Notification = Undefined ) Export
	
	Try
		Form.LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	MechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, Item.Name);
	
	Currency               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency);
	Date                 = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date);
	Counterparty           = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty);
	Organization          = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
	Partner              = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Partner);
	Posted             = TMCommonUseClientServer.DataAlongWay(Form, "Object.Posted");
	If ValueIsFilled(ParametersStructure.DocumentAmountForm) Then
		DocumentAmountForm  = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmountForm);
	Else
		TS = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSData);
		DocumentAmountForm = TS.Total(ParametersStructure.PropsNameTSAmountWithVAT);
	EndIf;
	Ref               = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
	TheseAreSettlementsWithCustomers = ParametersStructure.CustomerSettlementDocument;
	PartnerOtherRelations = ParametersStructure.PartnerOtherRelations;
	SelectOnlyUnconditionalDebt = ParametersStructure.SelectOnlyUnconditionalDebt;
	
	OpenStructure = New Structure;
	OpenStructure.Insert("Currency", Currency);
	OpenStructure.Insert("Date", Date);
	OpenStructure.Insert("Counterparty", Counterparty);
	OpenStructure.Insert("Organization", Organization);
	OpenStructure.Insert("Partner", Partner);
	OpenStructure.Insert("Posted", Posted);
	OpenStructure.Insert("GoodsAmount", DocumentAmountForm);
	OpenStructure.Insert("CalledFormID", Form.UUID);
	OpenStructure.Insert("Document", Ref);
	OpenStructure.Insert("TheseAreSettlementsWithCustomers", TheseAreSettlementsWithCustomers);
	OpenStructure.Insert("AddressOfPaymentsInTheStorage", ParametersStructure.AddressPaymentDecryption);
	OpenStructure.Insert("ReadOnly", Form.ReadOnly);
	OpenStructure.Insert("Object", Form.Object);
	OpenStructure.Insert("SelectOnlyUnconditionalDebt", SelectOnlyUnconditionalDebt);
	OpenStructure.Insert("PartnerOtherRelations", PartnerOtherRelations);
	OpenStructure.Insert("CallerName", Item.Name);
	
	OpenForm("CommonForm.ARAPAccountingOnReturnOfGoods",
		OpenStructure, 
		Form,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Opens the Payment Offset Assistant form
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	Item - FormItems - Element for defining a set of parameters from an array of parameters.
//
Procedure PaymentSettlement(Form, Item = Undefined) Export
	
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("Item", Item);
	
	Handler = New CallbackDescription("PaymentSettlementCompletion", ThisObject, AdditionalParameters);
	
	If Form.Modified
		Or Not ValueIsFilled(Form.Object.Ref) Then
		QueryText = NStr("vi = 'Dữ liệu đã được sửa đổi.
			|Chỉ có thể khấu trừ thanh toán sau khi ghi lại dữ liệu.
			|Dữ liệu sẽ được ghi lại.';
			|ru = 'Данные модифицированы.
			|Зачет оплат доступен только после записи данных.
			|Данные будут записаны.';
			|en = 'The data is modified.
			|Offset of payments is available only after data recording.
			|The data will be recorded.'; fa = 'The data is modified.
			|Offset of payments is available only after data recording.
			|The data will be recorded.';
			|it = 'I dati sono stati modificati.
			|Sarà possibile computare il pagamento dopo aver salvato i dati.
			| I dati verranno salvati.';
			|pl = 'Modyfikowane dane.
			|Uznanie płatności jest dostępne tylko po zapisywaniu danych.
			|Dane zostaną zapisane.';
			|tr = 'Veriler yenilendi.
			|Ödeme mahsubu yalnızca veriler kaydedildikten sonra kullanılabilir.
			|Veriler kaydedilecektir.'");
		ShowQueryBox(Handler, QueryText, QuestionDialogMode.OKCancel);
	Else
		RunCallback(Handler, DialogReturnCode.Ignore);
	EndIf;
	
EndProcedure

// Service handler for auto selection of Settlement objects and Payment Grounds
//
//  Parameters:
// 	Form - ClientApplicationForm - the form of the document.
// 	Item - FormItems - Element for defining a set of parameters from an array of parameters.
// 	Text - String - Text to search by line.
// 	ChoiceData - ValueList - Found data.
// 	StandardProcessing - Boolean
// 	ThisIsWhip - Boolean - Indicates that a Unique Payment Identifier is being searched for.
// 	ThisIsASettlementObject - Boolean - Indicates that the calculation object is being searched.
//
Procedure ObjectOfCalculationsBasisOfPaymentAutoSelection(Form, Item, Text, ChoiceData, StandardProcessing, ThisIsWhip = False, ThisIsASettlementObject = False) Export
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
		ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, Item.Name);
		
		FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
		RowID = Undefined;
		If FormTable <> Undefined Then 
			RowID = FormTable.CurrentRow;
		EndIf;
		
		Ref                         = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
		SelectAccountsReceivable = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.SelectAccountsReceivable);
		Counterparty                     = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Counterparty, RowID);
		Organization                    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization, RowID);
		PaymentType_                    = ParametersStructure.PaymentType_;
		
		SelectionSettings = ARAPAccountingClientServer.SelectionDataSelectionStructure();
		SelectionSettings.EditableDocument          = Ref;
		SelectionSettings.SelectAccountsReceivable = SelectAccountsReceivable; 
		SelectionSettings.RecordBranches               = True; 
		SelectionSettings.Counterparty                     = Counterparty;
		SelectionSettings.Organization                    = Organization;
		SelectionSettings.PaymentType_                    = PaymentType_;
		SelectionSettings.Text                          = Text;
		
		ARAPAccountingServerCall.ObjectOfCalculationsBasisOfPaymentProcessingOfReceiptOfSelectionData(
			ChoiceData, 
			SelectionSettings, 
			ThisIsWhip, 
			ThisIsASettlementObject);
		
	EndIf;
	
EndProcedure

// An alert processing call is needed.
// 
// Parameters:
//  Form - ClientApplicationForm - Document or directory form
//  EventName - String - Event name
//  Parameter - Arbitrary - Parameter
// 
// Returns:
//  Boolean - Need an alert processing call
Function NeedAlertProcessingCall(Form, EventName, Parameter) Export
	
	Return EventName = "PaymentCredited" And Form.Object.Ref = Parameter
		Or EventName = "Write_PaymentCardTransaction"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_ARAPSettlement"
		Or EventName = "Write_DebtCancellation"
		Or EventName = "Write_ExpenseReport"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_CashVoucher";
	
EndFunction

#EndRegion

#Region DocumentCurrencyExchangeRate

// Opens the form for editing the document's currency and settlement rates.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form of the configuration object.
// 	Item - FormDecoration - A hyperlink to open the payment rules form that is associated with a specific set of parameters.
// 	StandardProcessing - Boolean - indicates standard event handling.
// 	Notification - CallbackDescription - Description of the notification to be performed after the configuration is complete.
//
Procedure CurrencyAndExchangeRateOfDocument(Form, Item, StandardProcessing, Notification = Undefined) Export
	
	Try
		Form.LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	StandardProcessing = False;
	
	MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	SystemSettings_  = MechanismParameters.SystemSettings_;
	ParametersStructure = MechanismParameters.ParametersArray[0]; //The course is always one per document.
	
	If ValueIsFilled(ParametersStructure.PathToTSData) Then
		TS = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSData);
	EndIf;
	
	If ValueIsFilled(ParametersStructure.DocumentAmountForm) Then
		DocumentAmount = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmountForm);
	ElsIf ValueIsFilled(ParametersStructure.PathToTSData) Then
		DocumentAmount = TS.Total(ParametersStructure.PropsNameTSAmountWithVAT);
	Else
		DocumentAmount = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmount,,0);
	EndIf;
	
	OpeningParameters = New Structure();
	OpeningParameters.Insert("DocumentCurrency",      TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency));
	// For payments, the currency of mutual settlements in the tabular part is the decryption of the payment
	TabularSection = TMCommonUseClientServer.DataAlongWay(Form,
		ParametersStructure.PathToTSDataPaymentDecryption);
	If TabularSection <> Undefined And ParametersStructure.IsItPaymentOrOtherDocument And ParametersStructure.DocumentCurrencyViewOnly
		And ParametersStructure.MutualSettlementsCurrencyViewOnly And TabularSection.Count() > 0 Then
		RowID = TabularSection[0].GetID();
		OpeningParameters.Insert("ARAPCurrency", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency, RowID));
		OpeningParameters.Insert("ContractRateOption", TMCommonUseClientServer.DataAlongWay(Form, "Object.ARAPDetails.ContractRateOption", RowID));
		OpeningParameters.Insert("Contract", TMCommonUseClientServer.DataAlongWay(Form, "Object.ARAPDetails.Contract", RowID));
	Else
		OpeningParameters.Insert("ARAPCurrency", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPCurrency));
		OpeningParameters.Insert("ContractRateOption", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ContractRateOption));
		OpeningParameters.Insert("Contract",                      TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract));
	EndIf;
	If ValueIsFilled(ParametersStructure.PathToTSData) Then
		OpeningParameters.Insert("AmountARAP", TS.Total("AmountARAP"));
	Else
		OpeningParameters.Insert("AmountARAP",  TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.AmountARAP));
	EndIf;
	OpeningParameters.Insert("DocumentAmount",               DocumentAmount);
	OpeningParameters.Insert("CourseNumerator",                TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CourseNumerator));
	OpeningParameters.Insert("CourseDenominator",              TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.CourseDenominator));
	OpeningParameters.Insert("DocumentDate",                TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date));
	OpeningParameters.Insert("Organization",                  TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization));
	OpeningParameters.Insert("DocumentExchangeRateDate",     TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentExchangeRateDate));
	OpeningParameters.Insert("ThereIsDateOfDocumentSCurrencyExchangeRate", ValueIsFilled(ParametersStructure.DocumentExchangeRateDate));
	
	OpeningParameters.Insert("ThisIsASalesDocument",                 ParametersStructure.CustomerSettlementDocument);
	OpeningParameters.Insert("ThisIsAPurchaseDocument",                 ParametersStructure.DocumentOfSettlementsWithSuppliers);
	OpeningParameters.Insert("ReadOnly",                     Form.ReadOnly 
	                                                                 Or ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly
	                                                                 Or ParametersStructure.DocumentCurrencyViewOnly 
	                                                                 	And ParametersStructure.MutualSettlementsCurrencyViewOnly
	                                                                 	And OpeningParameters.DocumentCurrency = OpeningParameters.ARAPCurrency);
	OpeningParameters.Insert("DocumentCurrencyViewOnly",      ParametersStructure.DocumentCurrencyViewOnly);
	OpeningParameters.Insert("DocumentAmountViewOnly",       ParametersStructure.DocumentAmountViewOnly);
	OpeningParameters.Insert("MutualSettlementsCurrencyViewOnly", ParametersStructure.MutualSettlementsCurrencyViewOnly);
	OpeningParameters.Insert("DonTShowCalculations",                ParametersStructure.DonTShowCalculations);
	OpeningParameters.Insert("DoNotRecalculateTheAmountOfTheDocument",      ParametersStructure.DoNotRecalculateTheAmountOfTheDocument);
	
	//the currency of the document is only transferred to the form, because there is a server call
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("ParametersStructure", ParametersStructure);
	AdditionalParameters.Insert("SystemSettings_", SystemSettings_);
	AdditionalParameters.Insert("NotificationAfterCompletion", Notification);
	
	ClosingNotification1 = New CallbackDescription("CurrencyAndExchangeRateOfDocumentCompletion", ThisObject, AdditionalParameters);
	
	OpenForm("CommonForm.DocumentCurrencyExchangeRate", OpeningParameters, Form,,,, ClosingNotification1);
	
EndProcedure

// Handler for finishing editing the document's exchange rate and currencies.
// 
Procedure CurrencyAndExchangeRateOfDocumentCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Or ClosingResult = DialogReturnCode.Cancel Then 
		If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationAfterCompletion);
		EndIf;
		Return;
	EndIf;
	
	Form               = AdditionalParameters.Form;
	ParametersStructure = AdditionalParameters.ParametersStructure;
	
	FieldArray = New Array();
	FieldArray.Add("DocumentCurrency");
	FieldArray.Add("ARAPCurrency");
	FieldArray.Add("AmountARAP");
	FieldArray.Add("CourseNumerator");
	FieldArray.Add("CourseDenominator");
	FieldArray.Add("DocumentExchangeRateDate");
	If ClosingResult.RecalculateDocumentAmounts Then
		FieldArray.Add("DocumentAmount");
	EndIf;
	
	ClosingResult.Insert("DocumentCurrency",ClosingResult.Currency);
	
	OldValuesOfChangedProps = AssignNewValues(Form, ParametersStructure, ClosingResult, FieldArray);
	
	If OldValuesOfChangedProps.Count() > 0 Then
		Form.Modified = True;
	EndIf;
	
	// For payments, you need to process the tabular part of the payment decryption
	TabularSection = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentDecryption);
	If TabularSection <> Undefined
		And ParametersStructure.IsItPaymentOrOtherDocument
		And ParametersStructure.DocumentCurrencyViewOnly
		And ParametersStructure.MutualSettlementsCurrencyViewOnly Then
		
		If OldValuesOfChangedProps.Property("ExchangeRateNumeratorOfMutualSettlements") Then
			For Each DecryptionString In TabularSection Do
				DecryptionString.ExchangeRateNumeratorOfMutualSettlements = ClosingResult.CourseNumerator;
			EndDo;
		EndIf;
		
		If OldValuesOfChangedProps.Property("TheExchangeRateIsTheDenominatorOfMutualSettlements") Then
			For Each DecryptionString In TabularSection Do
				DecryptionString.TheExchangeRateIsTheDenominatorOfMutualSettlements = ClosingResult.CourseDenominator;
			EndDo;
		EndIf;
		
		If (OldValuesOfChangedProps.Property("ExchangeRateNumeratorOfMutualSettlements")
			Or OldValuesOfChangedProps.Property("TheExchangeRateIsTheDenominatorOfMutualSettlements"))
			And OldValuesOfChangedProps.Property("DocumentAmount") Then
			For Each DecryptionString In TabularSection Do
				CashClientServer.CalculateAmountInDecryptionLine(DecryptionString, ClosingResult.Currency, Form.CurrencyOfComplianceAccounting);
			EndDo;
		EndIf;
		
		If OldValuesOfChangedProps.Property("DocumentAmount") Then
			FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Form.Object, ClosingResult.DocumentAmount, False);
		EndIf;
		
		If OldValuesOfChangedProps.Property("DocumentAmount")
			And Not OldValuesOfChangedProps.Property("AmountARAP") Then
			
			For Each TSRow In TabularSection Do
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TSRow, ClosingResult.Currency, Form.CurrencyOfComplianceAccounting);
			EndDo;
		EndIf;
		
		If OldValuesOfChangedProps.Property("AmountARAP")
			Or TabularSection.Total("AmountARAP") <> ClosingResult.AmountARAP Then
			
			If TabularSection.Count() = 1 Then
				TabularSection[0].AmountARAP = ClosingResult.AmountARAP;
			Else
				For Each TSRow In TabularSection Do
					CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
						TSRow, ClosingResult.Currency, Form.CurrencyOfComplianceAccounting);
				EndDo;
				
				If TabularSection.Total("AmountARAP") <> ClosingResult.AmountARAP Then
					
					AmountOfDifference = TabularSection.Total("AmountARAP") - ClosingResult.AmountARAP;
					LineNumber = TabularSection.Count() - 1;
					
					While LineNumber >= 0 Do
						DecryptionString = TabularSection[LineNumber];
						If DecryptionString.AmountARAP = AmountOfDifference Then
							TabularSection.Delete(LineNumber);
							Break;
						ElsIf DecryptionString.AmountARAP > AmountOfDifference Then
							DecryptionString.AmountARAP = DecryptionString.AmountARAP - AmountOfDifference;
							If DecryptionString.ARAPCurrency = ClosingResult.Currency Then
								DecryptionString.Sum = DecryptionString.AmountARAP;
							EndIf;
							Break;
						ElsIf DecryptionString.AmountARAP < AmountOfDifference Then
							AmountOfDifference = AmountOfDifference - DecryptionString.AmountARAP;
							TabularSection.Delete(LineNumber);
						EndIf;
						LineNumber = LineNumber - 1;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	ProcessingResults = New Structure();
	ProcessingResults.Insert("OldValuesOfChangedProps", OldValuesOfChangedProps);
	ProcessingResults.Insert("RecalculateDocumentAmounts", ClosingResult.RecalculateDocumentAmounts);
	ProcessingResults.Insert("DocumentAmount", ClosingResult.DocumentAmount);
	
	If AdditionalParameters.NotificationAfterCompletion <> Undefined Then
		RunCallback(AdditionalParameters.NotificationAfterCompletion, ProcessingResults);
	EndIf;
	
EndProcedure

#EndRegion

#Region DebtLimits

// Opens the report form about the reasons for the shipment restriction.
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	Item - FormField - The hyperlink that opens the report.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure DebtLimitsClick(Form, Item, StandardProcessing) Export
	
	StandardProcessing = False;
	
	MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	SystemSettings_  = MechanismParameters.SystemSettings_;
	ParametersStructure = MechanismParameters.ParametersArray[0]; //The course is always one per document.
	
	ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure,
		"Date, DocumentCurrency, Contract, DocumentAmount, Organization");
	
	Date                    = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Date);
	Contract                 = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract);
	DocumentCurrency         = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentCurrency);
	DocumentAmount          = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.DocumentAmount);
	Organization             = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
		
	PathToSettlementCurrency = ?(ParametersStructure.ARAPCurrency="", ParametersStructure.DocumentCurrency, ParametersStructure.ARAPCurrency);
	ARAPCurrency    = TMCommonUseClientServer.DataAlongWay(Form, PathToSettlementCurrency);
	
	PathToSumOfMutualSettlements = ?(ParametersStructure.AmountARAP="", ParametersStructure.DocumentAmount, ParametersStructure.AmountARAP);
	AmountARAP     = TMCommonUseClientServer.DataAlongWay(Form, PathToSumOfMutualSettlements);
	
	PurposeOfUse = Form.Object.Ref;
	
	DataOnSaleAmount = New Structure();
	DataOnSaleAmount.Insert("Date", Date); 
	DataOnSaleAmount.Insert("Currency", DocumentCurrency);
	DataOnSaleAmount.Insert("ARAPCurrency", ARAPCurrency);
	DataOnSaleAmount.Insert("DocumentAmount", DocumentAmount);
	DataOnSaleAmount.Insert("Organization", Organization);
	
	If DocumentCurrency = ARAPCurrency Then
		DataOnSaleAmount.Insert("AmountARAP", DocumentAmount);
	Else //PathToTSData
		DataOnSaleAmount.Insert("AmountARAP", AmountARAP);
	EndIf;
	
	SalesClient.OpenShipmentBanDecryptionReport(Contract, DataOnSaleAmount, PurposeOfUse, SystemSettings_.NewOnlineARAPAccounting);
	
EndProcedure

#EndRegion

#Region StateOfCalculations

// Opens the form of the report Card calculations.
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 	Item - FormField - The hyperlink that opens the report.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure CalculationsClick(Form, Item, StandardProcessing) Export
	
	StandardProcessing = False;
	
	MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	ParametersStructure = MechanismParameters.ParametersArray[0]; //The course is always one per document.
	
	ARAPAccountingClientServer.CheckRequiredParameters(ParametersStructure,
		"Date, DocumentCurrency, Contract, DocumentAmount");
	
	If MechanismParameters.SystemSettings_.NewOnlineARAPAccounting Then
		ReportParameter_ = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
	Else
		If ParametersStructure.IsCatalog
			And TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings)
				= PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice") 
			Or (ParametersStructure.ThisIsOrder 
				And TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings)
					= PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")) Then
			ReportParameter_ = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
		Else
			ReportParameter_ = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObject);
		EndIf;
		If TypeOf(ReportParameter_) = Type("Array") Then
			ReportParameter_ = CommonClientServer.CollapseArray(ReportParameter_);
			If ReportParameter_.Count() = 1 Then
				 ReportParameter_ = ReportParameter_[0];
			EndIf;
		EndIf;
	EndIf;
	
	If ParametersStructure.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting") Then
		ReportsTMClientOverridable.OpenCustomerSettlementCardReport("CardOfSettlementsWithClientsOnDocumentsContext", ReportParameter_);
	Else
		ReportsTMClientOverridable.OpenPaymentCardWithSuppliersReport("PaymentCardWithSuppliersAccordingToDocumentsContext", ReportParameter_);
	EndIf;
	
EndProcedure

#EndRegion

#Region MultipleShippingDates

// When editing the tabular part of the order, it determines that the shipment dates have changed 
// and it is necessary to call the settlement work with forms.Request formsreferences.
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
// 
// Returns:
//  Boolean - Detected a change in shipment dates
Function ThereIsChangeInShippingDates(Form) Export
	
	ThereIsChangeInShippingDates = False;
	
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		ShippingDates = ARAPAccountingClientServer.ArrayOfShipmentDates(Form, ParametersStructure);
		If Not CommonClientServer.ValueListsAreEqual(ParametersStructure.ShippingDates, ShippingDates, True) Then
			ThereIsChangeInShippingDates = True;
		EndIf;
	EndDo;
	
	Return ThereIsChangeInShippingDates;
	
EndFunction

// Caches the current order shipment dates in the mechanism parameters
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
Procedure SaveShipmentDatesInParameters(Form) Export
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		ParametersStructure.ShippingDates = ARAPAccountingClientServer.ArrayOfShipmentDates(Form, ParametersStructure);
	EndDo;
EndProcedure

// Resets the flag that prompts the question about resetting the schedule ON changes in shipment dates
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document/directory.
Procedure QuestionAboutResettingScheduleONChangesInShippingDatesHasBeenAsked(Form) Export
	AugmentedMechanismParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	For Each ParametersStructure In AugmentedMechanismParameters.ParametersArray Do
		ParametersStructure.SeveralShippingDatesHaveChanged = False;
	EndDo;
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function AssignNewValues(Object, ParametersStructure, StructureOfNewValues, FieldArray) 
	
	OldValuesOfChangedProps = New Structure;
	
	For Each Field In FieldArray Do
		
		If StrOccurrenceCount(ParametersStructure[Field],".") > 1 Then
			Continue;
		EndIf;
		
		Attribute = TMCommonUseClientServer.DataForAssignment(Object, ParametersStructure[Field]);
		If Attribute <> Undefined And Attribute.Data[Attribute.Name] <> StructureOfNewValues[Field] Then
			OldValuesOfChangedProps.Insert(Attribute.Name, Attribute.Data[Attribute.Name]);
			Attribute.Data[Attribute.Name] = StructureOfNewValues[Field];
		EndIf;
	EndDo;
	
	Return OldValuesOfChangedProps;
	
EndFunction

// Parameters:
// 	Response - DialogReturnCode -
// 	AdditionalParameters - Structure - :
// 	 * Form - ManagedFormExtensionForObjects
// 	 * Item - FormField - The element that caused the payment offset.
Procedure PaymentSettlementCompletion(Response, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	Item = AdditionalParameters.Item;
	Cancel = False;
	
	If Response = DialogReturnCode.OK Then
		ClearMessages();
		Cancel = Not Form.Write();
	EndIf;
	
	If Response = DialogReturnCode.Cancel Or Cancel Then
		Return;
	EndIf;
	
	MechanismParameters  = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ARAPAccounting");
	If Item = Undefined Then
		ParametersStructure = MechanismParameters.ParametersArray[0]; // See ARAPAccountingServer.MechanismParameters
	Else
		ParametersStructure = ARAPAccountingClientServer.StructureOfParametersByElementName(MechanismParameters.ParametersArray, Item.Name);
	EndIf;
	
	If TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings) = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice")
		And ValueIsFilled(ParametersStructure.PathToTSData)
		And ValueIsFilled(ParametersStructure.PropsNameTSOrder)
		And TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.InvoiceForOrders,,False)
		And ParametersStructure.ThisIsSalePurchase Then
		
		PathSubstrings = StrSplit(ParametersStructure.PathToTSData,".");
		PathToTestObjects = PathSubstrings[PathSubstrings.Count()-1] + "." + ParametersStructure.PropsNameTSOrder;
		
	ElsIf TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings) = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice")
		And ParametersStructure.ThisIsSalePurchase Then
		PathSubstrings = StrSplit(ParametersStructure.Contract,".");
		PathToTestObjects = "." + PathSubstrings[PathSubstrings.Count()-1];
	Else
		PathToTestObjects = "";
	EndIf;
	
	FormParameters = New Structure("ARAPObject, Organization, PaymentType_, PathToTestObjects");
	If ValueIsFilled(ParametersStructure.PathToTSDataPaymentDecryption) Then
		FormParameters.Insert("NameTchrashifrovkaPayment", StrSplit(ParametersStructure.PathToTSDataPaymentDecryption,".")[1]);
	EndIf;
	
	If Not CommonClientServer.HasAttributeOrObjectProperty(Form.Object, "Posted")
		Or Not Form.Object.Posted Then
		FormParameters.Insert("AddressPaymentDecryption", ParametersStructure.AddressPaymentDecryption);
	EndIf;
	
	FormParameters.Insert("Document", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref));
	FormParameters.Insert("DocumentPartner", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Partner));
	
	ARAPObject = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObject);
	If TypeOf(ARAPObject) = Type("Array") Then
		CommonClientServer.DeleteAllValueOccurrencesFromArray(ARAPObject, PredefinedValue("Catalog.ARAPObjects.EmptyRef"));
		ARAPObject = CommonClientServer.CollapseArray(ARAPObject);
		If ARAPObject.Count() = 1 Then
			ARAPObject = ARAPObject[0];
		Else
			ARAPObject = Undefined;
		EndIf;
	EndIf;
	
	If ValueIsFilled(ARAPObject) Then
		FormParameters.ARAPObject = ARAPObject;
	Else
		ARAPObjectSettings = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings);
		If ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts") Then
			FormParameters.ARAPObject = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Contract);
		Else
			FormParameters.ARAPObject = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Ref);
		EndIf;
		FormParameters.Organization = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.Organization);
		FormParameters.PaymentType_ = ParametersStructure.PaymentType_;
	EndIf;
	FormParameters.PathToTestObjects = PathToTestObjects;
	FormParameters.Insert("ARAPObjectSettings", TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings));
	
	If ParametersStructure.ThisIsOrder
		And TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.ARAPObjectSettings) = PredefinedValue("Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice") Then
		PaymentSteps = TMCommonUseClientServer.DataAlongWay(Form, ParametersStructure.PathToTSDataPaymentSteps);
		PaymentOptionAdvancePayment = ?(ParametersStructure.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
		                       PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment"),
		                       PredefinedValue("Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt"));
		AdvancePaymentLines = PaymentSteps.FindRows(New Structure("PaymentOption", PaymentOptionAdvancePayment));
		CommonClientServer.SupplementArray(
			AdvancePaymentLines,
			PaymentSteps.FindRows(New Structure("CalculateFrom", PredefinedValue("Enum.PaymentDateCalculationOptions.BeforeShipmentDate"))),
			True);
		AmountToPay = 0;
		For Each StageString_ In AdvancePaymentLines Do
			AmountToPay = AmountToPay + StageString_.PaymentAmount + StageString_.PackageDepositValue;
		EndDo;
		FormParameters.Insert("AmountToPay", AmountToPay);
	EndIf;
	
	OpenForm("DataProcessor.ARAPSettlementsWizard.Form", FormParameters);
	
EndProcedure

Procedure TranscriptOfPaymentCourseOptionOfContractClick(CurrentData, StandardProcessing) Export 
	StandardProcessing = False;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	If CurrentData.ContractRateOption = PredefinedValue("Enum.ContractRateOptions.SpecifiedInContract") Then
		Contract = GeneralPurposeTMServerCall.ObjectAttributeValue(CurrentData.ARAPObject, "Contract");
		OpeningParameters = New Structure("Filter", New Structure("Contract", Contract));
		OpenForm("InformationRegister.ARAPAccountingExchangeRatesForContracts.Form.ByContractListForm", OpeningParameters);
	ElsIf CurrentData.ContractRateOption = PredefinedValue("Enum.ContractRateOptions.FixedAsOfShipmentDate") Then
		OpeningParameters = New Structure("Key", CurrentData.ARAPObject);
		OpenForm("Catalog.ARAPObjects.ObjectForm", OpeningParameters);
	EndIf;
EndProcedure

#EndRegion

