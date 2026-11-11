
#Region Variables

&AtClient
Var CachedValues; // used by the mechanism for processing changes in PM details

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);

	UsePartnersAsCounterparties      = GetFunctionalOption("UsePartnersAsCounterparties");
	AgreementIsOld = Object.Terms;
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);

	Items.GoodsIssueMissingInvoices.Visible = AccessRight("Read", Metadata.Documents.CustomerInvoice);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		CalculateRemuneration = True;
		OnReadCreateAtServer();
		If Parameters.Property("Basis")
		 And TypeOf(Parameters.Basis) = Type("Structure")
		 And Parameters.Basis.Property("FillInByTheGoodsForRegistration") Then
			FillInByTheGoodsForRegistration = Parameters.Basis.FillInByTheGoodsForRegistration;
		EndIf;
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
	RemunerationPercentage = Object.RemunerationPercentage;
	CommissionAmount = Object.CommissionAmount;

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	SetPresentationOfFoundationDocument();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	If Not ValueIsFilled(Object.Ref)
	 And FillInByTheGoodsForRegistration Then
		ConsignmentSalesClient.CheckDocumentCompletionByBalances(Object);	
	EndIf;
	

	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)

	If ChoiceSource.FormName = "CommonForm.SelectByGoodsForRegistrationOfConsignorReport" Then
		
		ClearMessages();
		GetProductsFromStorage(ValueSelected);
		
	ElsIf VATAccountingERPClient.FinishedEditingInvoiceIssued(ValueSelected, ChoiceSource) Then
	
		UpdateTextOfInvoiceIssued();
		
	ElsIf VATAccountingERPClient.CompletedProcessingOfInvoicesIssued(ValueSelected, ChoiceSource) Then
		
		If TypeOf(ValueSelected) = Type("Map") And (ValueSelected.Count() > 0) Then 
			FillInBySalesResultServer();
		EndIf;	
		
	ElsIf ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then
		
		GetStockTypesFromStorage(ValueSelected);
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		
	EndIf;
	
	If EventName = "MissingInvoicesIssued" Then
		FillInBySalesResultServer();
	EndIf;
	
	If EventName = "Write_InvoiceIssued"
		And ((Parameter.Property("OwnerForm") And Parameter.OwnerForm = UUID)
			Or Parameter.Property("ListOfGrounds") And Parameter.ListOfGrounds.FindByValue(Object.Ref) <> Undefined) Then
		UpdateTextOfInvoiceIssued();
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter, Source);
	EndIf;
	
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		ContractOnChange(Items[Parameter]);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisForm);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
		
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("WriteParameters", WriteParameters);
	
	If CalculateRemuneration Then
		Cancel = True;
		ConsignmentSalesClient.YouNeedToCalculateReward(
			New CallbackDescription("BeforeRecordingContinuationYouNeedToCalculateReward", ThisObject, AdditionalParameters),
			ThisForm);
	Else
		BeforeRecordingContinuationYouNeedToCalculateReward(False, AdditionalParameters);
	EndIf;

	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		Cancel = True;
	EndIf; 
	 
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
		
EndProcedure

&AtClient
Procedure BeforeRecordingContinuationYouNeedToCalculateReward(YouNeedToCalculateReward, AdditionalParameters) Export
	
	YouNeedToCalculateReward = YouNeedToCalculateReward = True;
	
	BeforeWriteAtClientServer(YouNeedToCalculateReward);
	
	If YouNeedToCalculateReward Then
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
		
EndProcedure

&AtServer
Procedure BeforeWriteAtClientServer(YouNeedToCalculateReward)
	
	If YouNeedToCalculateReward Then
		CalculateServerCommission();
	EndIf;
	
	ARAPAccountingServerCall.FormBeforeRecordingOnClientServer(ThisForm);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ConsignmentReportToVendor", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
		

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "PageGeneral" Then
		ARAPAccountingClient.UpdateHyperlinkTextPaymentSteps(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	Notification = New CallbackDescription("DateOnChangeCompletion", ThisObject);
	EnterprisePricesFillingClient.AskQuestionAboutRecalculatingPriceWhenDateChanges(Object, Notification);
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ClearMessages();
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If ValueIsFilled(Object.Currency) Then
		
		ConsignmentSalesClient.CheckWhetherCurrencyConversionIsNecessaryCommissionReports(
			New CallbackDescription("CurrencyWhenQuestionChangesRecalculateCurrency", ThisObject),
			Object,
			DocumentCurrency);

	Else
		
		DocumentCurrency = Object.Currency;
		
		FillInSubordinatePropertiesForStatistics("Currency");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyWhenQuestionChangesRecalculateCurrency(RecalculateCurrency, AdditionalParameters) Export
	
	CurrencyOnChangeServer(
		Object.Currency,
		RecalculateCurrency);
		
	PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	
	DocumentCurrency = Object.Currency;
	
	FillInSubordinatePropertiesForStatistics("Currency");
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If ValueIsFilled(Object.Partner) Then
		PartnerOnChangeServer();
		If ValueIsFilled(Object.Terms) Then
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("Item", Item);
			QuestionUserBeforeFillingInPricesByAgreement(
				New CallbackDescription("PartnerWhenChangingWhenChangingQuestionFillInPrice",
				                          ThisObject, 
				                          AdditionalParameters));
			Return;
				
		EndIf;
	EndIf;
	
	
EndProcedure

// Parameters:
// 	FillInPrices - Boolean
// 	AdditionalParameters - Structure:
// 		* Item - FormField
&AtClient
Procedure PartnerWhenChangingWhenChangingQuestionFillInPrice(FillInPrices, AdditionalParameters) Export
	
	If FillInPrices Then
		FillThePricesByTermsOfSalesServer();
	EndIf;
	
	PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	
	
EndProcedure

&AtClient
Procedure ContactPersonOnChange(Item)
	
	If Object.ContactPerson.IsEmpty() Then
		Return;
	ElsIf Not Object.Partner.IsEmpty() Then
		Return;
	EndIf;
	
	PartnerChanged_ = False;
	ContactPersonOnChangeServer(PartnerChanged_);
	
	If Not PartnerChanged_ Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.Terms) Then
		
		QuestionUserBeforeFillingInPricesByAgreement(
			New CallbackDescription("ContactPersonWhenChangingWhenChangingQuestionFillInPrice", ThisObject));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ContactPersonWhenChangingWhenChangingQuestionFillInPrice(FillInPrices, AdditionalParameters) Export
	
	If Object.Goods.Total("Price") <> 0 And FillInPrices Then
		FillThePricesByTermsOfSalesServer();
	EndIf;
	
	PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();
	
	
EndProcedure

&AtServerNoContext
Function ParametersForRegisteringInvoicesIssuedServer(Val Object)
	
	Return Documents.ConsignmentReportToVendor.ParametersForRegisteringInvoicesIssued(Object);
	
EndFunction	

&AtClient
Procedure TextOfTheInvoiceIssuedURLProcessing(Item, Var_URL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesIssued(ThisForm, Var_URL,  StandardProcessing, RegistrationParameters);
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	ClearMessages();
	
	VATTaxationOnChangeServer();
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer(CachedValues);
	
EndProcedure

&AtClient
Procedure TermsOnChange(Item)

	QuestionUserBeforeFillingInPricesByAgreement(
		New CallbackDescription("AgreementWhenChangingQuestionFillInPriceCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure AgreementWhenChangingQuestionFillInPriceCompletion(FillInPrices, AdditionalParameters) Export
	
	ClearMessages();
	
	TermsOnChangeServer(
		ValueIsFilled(Object.Terms) And FillInPrices);
	
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StructureOfAdditionalSelection = New Structure;
	OperationArray = New Array();
	OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement"));
	OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery"));
	StructureOfAdditionalSelection.Insert("BusinessOperation", OperationArray);

	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date,
		StructureOfAdditionalSelection);

EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	SalesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ClearMessages();
	ContractOnChangeServer();
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodOnChange(Item)
	
	If Not Object.CommissionFeeCalculationMethod = CommissionFeeCalculationMethod Then
		AdditionalParameters = New Structure("RestoreAttributes", False);
		Notification = New CallbackDescription(
			"MethodOfCalculatingRemunerationWhenChangingItIsNecessaryToCalculateRemunerationCompletion", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(Notification, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfCalculatingRemunerationWhenChangingItIsNecessaryToCalculateRemunerationCompletion(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	ElsIf AdditionalParameters.RestoreAttributes Then
		Object.CommissionFeeCalculationMethod = CommissionFeeCalculationMethod;
	EndIf;
	
	CommissionFeeCalculationMethodOnChangeServer();
	
	If Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		Object.RemunerationPercentage = 0;
		Object.CommissionAmount = 0;
		RemunerationPercentage = 0;
		CommissionAmount = 0;
		Object.OperationService = PredefinedValue("Catalog.Products.EmptyRef");
		Object.VATRateOfRemuneration = PredefinedValue("Catalog.VATRates.EmptyRef");
		Object.PaymentDate = Date(1, 1, 1, 0, 0, 0);
		Object.KeepCommissionFee = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionFeeCalculationMethodStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommissionFeeCalculationMethod = Object.CommissionFeeCalculationMethod;
	
EndProcedure

&AtClient
Procedure RemunerationPercentageOnChange(Item)
	
	If Not Object.RemunerationPercentage = RemunerationPercentage Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RestoreAttributes", False);
		AdditionalParameters.Insert("ClearCommission", False);
		CallbackDescription = New CallbackDescription(
			"PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(CallbackDescription, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionAmountOnChange(Item)

	If Not Object.CommissionAmount = CommissionAmount Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("RestoreAttributes", False);
		AdditionalParameters.Insert("ClearCommission", False);
		CallbackDescription = New CallbackDescription(
			"PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration", ThisObject, AdditionalParameters);
		ConsignmentSalesClient.YouNeedToCalculateReward(CallbackDescription, ThisObject);
	EndIf;

EndProcedure

&AtClient
Procedure PercentageAmountOfRemunerationWhenChangingItIsNecessaryToCalculateEndRemuneration(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		
		CalculateServerCommission();

		CalculationMethodForNotification = ?(
			AdditionalParameters.ClearCommission,
			PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating"),
			Object.CommissionFeeCalculationMethod);
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(CalculationMethodForNotification);

		RemunerationPercentage = Object.RemunerationPercentage;
		CommissionAmount = Object.CommissionAmount;

	ElsIf AdditionalParameters.RestoreAttributes Then

		Object.RemunerationPercentage = RemunerationPercentage;
		Object.CommissionAmount = CommissionAmount;

	EndIf;
	
EndProcedure

&AtClient
Procedure OperationServiceOnChange(Item)
	
	OperationServiceOnChangeServer();
	
EndProcedure

&AtClient
Procedure VATRateOfRemunerationOnChange(Item)
	
	ConsignmentSalesClient.VATRateOfRemunerationOnChange(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure KeepCommissionFeeOnChange(Item)
	
	KeepCommissionFeeOnChangeServer();
		
EndProcedure

&AtServer
Procedure KeepCommissionFeeOnChangeServer()
	
	CalculationMethodNotCalculated = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);

	CommonClientServer.SetFormItemProperty(
		Items,
		"PaymentDate",
		"Enabled",
		Not Object.KeepCommissionFee And Not CalculationMethodNotCalculated);
		
	If Object.KeepCommissionFee Then
		Object.PaymentDate = Date(1,1,1);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "KeepCommissionFee");
	
	FormItemsManagement();

EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	FillInSubordinatePropertiesForStatistics("Manager");
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfSalesDocumentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "OpenDocument" Then
		
		If GetRightToAccessImplementation() Then
			ShowValue(Undefined, Object.DocumentSales);
		EndIf;
		
	ElsIf FormattedStringURL = "SelectDocument" Then
		
		ChoiceFormName = "Document.ConsignmentReportToVendor.Form.SalesDocumentChoiceForm";
		FilterParameters = New Structure();
		FilterParameters.Insert("Contract", Object.Contract);
		FilterParameters.Insert("Terms", Object.Terms);
		OpenForm(ChoiceFormName, FilterParameters, ThisForm,,,,);
		
	EndIf;
	
EndProcedure

&AtServer
Function GetRightToAccessImplementation()
	
	Return AccessRight("Read", Metadata.Documents.CustomerInvoice);
	
EndFunction

&AtClient
Procedure ReportSalesOnChange(Item)
	
	If Not ReportSales Then
		CallbackDescription = New CallbackDescription("WhenSelectingSalesDocumentEnd", ThisObject,
			PredefinedValue("Document.CustomerInvoice.EmptyRef"));
		
		ShowQueryBox(
				CallbackDescription,
				NStr("vi = 'Xóa bảng hàng hóa?';
					|ru = 'Очистить таблицу товаров?';
					|en = 'Do you want to clear the goods table?'; fa = 'Do you want to clear the goods table?';
					|it = 'Cancellare la tabella degli articoli?';
					|pl = 'Wyczyścić tabelę towarów?';
					|tr = 'Mallar tablosu silinsin mi?'"),
				QuestionDialogMode.YesNo);
	Else
		SetPresentationOfFoundationDocument();
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesClearing(Item, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure PresentationOfCodeOfSpecialCircumstancesOpening(Item, StandardProcessing)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, "GoodsPartnerProducts", NStr("vi = 'Người đặt ký gửi';
																									|ru = 'Комитент';
																									|en = 'Consignor'; fa = 'امانت‌گذار';
																									|it = 'Committente';
																									|pl = 'Komitent';
																									|tr = 'Gönderici'"));
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsOnChange(Item)
	
	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;
	
	PartnersProductsClient.SetPackageSelectionParameters(Item.ChoiceParameters, CurrentRow);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInTheItemByThePartnerSItem");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate",   BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
	
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)

	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
		
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)

	ClearMessages();
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);

	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisForm.FormName, "Goods"));
		
	BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	ClearMessages();

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	NumberOfUnitsBeforeRecalculation = CurrentRow.Count;
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	Else
		StructureOfActions.Insert("FillInPurchasePrice", BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
	
	BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	If NumberOfUnitsBeforeRecalculation <> 0 Then
		CurrentRow.SellingPrice = CurrentRow.SellingPrice / NumberOfUnitsBeforeRecalculation * CurrentRow.Count;
		RecalculateSaleAmount(CurrentRow);
	EndIf;
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateSaleAmount(CurrentRow);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)

	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateVATSalesAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount",  BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsSellingPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	RecalculateSaleAmount(CurrentRow);
	CurrentRow.CommissionAmount = 0;
	CalculateRemuneration = True;
	
	
EndProcedure

&AtClient
Procedure GoodsSalesAmountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	CurrentRow.CommissionAmount = 0;
	ConsignmentSalesClient.SaleAmountWhenChanged(
		CurrentRow,
		True); // ThereIsVATSaleAmount
		
	
	CalculateRemuneration = True;
	
EndProcedure

&AtClient
Procedure GoodsCommissionAmountOnChange(Item)
	
	Object.CommissionAmount = Object.Goods.Total("CommissionAmount");
	TotalSalesAmount = Object.Goods.Total("SalesAmount");
	Object.RemunerationPercentage = ?(TotalSalesAmount <> 0, Object.CommissionAmount / TotalSalesAmount * 100, 0);
	ConsignmentSalesClient.CalculateCommissionFeeVAT(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	If Item.CurrentItem = Undefined Then
		Return
	ElsIf Item.CurrentItem.Name = "GoodsPartnerProducts" Then
		
		CurrentData = Items.Goods.CurrentData;
		
		PartnersProductsClient.FillInPartnerProductSelectionList(
			Object.Partner, CurrentData, Items.GoodsPartnerProducts.ChoiceList);
			
		PartnersProductsClient.SetPackageSelectionParameters(
			Items.GoodsPartnerProducts.ChoiceParameters, CurrentData);
		
	EndIf;
EndProcedure

&AtClient
Procedure GoodsTaxInvoiceDateOnChange(Item)
	
	SetAvailabilityOfInvoices(ThisForm);
	
EndProcedure

&AtClient
Procedure GoodsCustomerInvoiceIssuedStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentRow = Items.Goods.CurrentData;
	
	InvoiceSelectionParameters = VATAccountingERPClient.ParametersForSelectingInvoiceToReportToCommittee();
	InvoiceSelectionParameters.Organization = Object.Organization;
	InvoiceSelectionParameters.Date        = CurrentRow.TaxInvoiceDate;
	InvoiceSelectionParameters.Customer  = CurrentRow.Customer;
	InvoiceSelectionParameters.SelectedInvoice_ = CurrentRow.CustomerInvoiceIssued;
	
	VATAccountingERPClient.StartSelectingInvoiceToReportToCommittee(Item, InvoiceSelectionParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure GoodsPartnerProductsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FormItem" , Item);
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfSelectingPartnerProductName", ThisObject, AdditionalParameters);

	PartnersProductsClient.OpenPartnerProductSelectionForm(ThisObject, Object.Partner, CurrentRow, Item.Title, ClosingNotification);

EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateRemuneration = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure SetDateIntervalExecute(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"));

EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.Goods;
	TableData = Object.Goods;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure CalculateCommissionFee(Command)
	
	ConsignmentSalesClient.YouNeedToCalculateReward(
		New CallbackDescription("CalculateRewardItIsNecessaryToCalculateRewardCompletion", ThisObject),
		ThisForm);
	
EndProcedure

&AtClient
Procedure CalculateRewardItIsNecessaryToCalculateRewardCompletion(YouNeedToCalculateReward, AdditionalParameters) Export
	
	If YouNeedToCalculateReward = True Then
		CalculateServerCommission();
		ConsignmentSalesClient.NotifyAboutEndOfCalculationOfRemuneration(Object.CommissionFeeCalculationMethod);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInBySalesResult(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.TabularSection = Object.Goods;
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																|ru = 'Комитент';
																|en = 'Consignor'; fa = 'امانت‌گذار';
																|it = 'Committente';
																|pl = 'Komitent';
																|tr = 'Gönderici'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	If ReportSales Then
		CheckParameters.CheckedAttributes.Insert("DocumentSales", NStr("vi = 'Chứng từ bán hàng';
																		|ru = 'Документ продажи';
																		|en = 'Sales document'; fa = 'سند فروش';
																		|it = 'Documento di vendita';
																		|pl = 'Dokument sprzedaży';
																		|tr = 'Satış belgesi'"));
	EndIf;
	Notification = New CallbackDescription("FillInBySalesResultCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure ShowSupplierProducts(Command)
	
	PartnersProductsClient.ShowThePartnerSNomenclature(Object.Partner, Object.Ref, Items.Goods.CurrentData, NStr("vi = 'Người đặt ký gửi';
																												|ru = 'Комитент';
																												|en = 'Consignor'; fa = 'امانت‌گذار';
																												|it = 'Committente';
																												|pl = 'Komitent';
																												|tr = 'Gönderici'"));
	
EndProcedure

&AtClient
Procedure SelectBySalesResults(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																|ru = 'Комитент';
																|en = 'Consignor'; fa = 'امانت‌گذار';
																|it = 'Committente';
																|pl = 'Komitent';
																|tr = 'Gönderici'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	If ReportSales Then
		CheckParameters.CheckedAttributes.Insert("DocumentSales", NStr("vi = 'Chứng từ bán hàng';
																		|ru = 'Документ продажи';
																		|en = 'Sales document'; fa = 'سند فروش';
																		|it = 'Documento di vendita';
																		|pl = 'Dokument sprzedaży';
																		|tr = 'Satış belgesi'"));
	EndIf;
	Notification = New CallbackDescription("SelectBySalesResultsCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillThePricesByTermsOfSales(Command)

	ClearMessages();
	
	If PartnerPricesFillingClient.ItIsNecessaryToFillInPricesByAgreement(Object, "Goods", NStr("vi = 'Hàng hóa';
																								|ru = 'Товары';
																								|en = 'Goods'; fa = 'کالاها';
																								|it = 'Merci';
																								|pl = 'Wiersze pozycji';
																								|tr = 'Ürünler'")) Then
		
		ErrorText = "";
		PricesCalculated = FillThePricesByTermsOfSalesServer(ErrorText);
		PurchasesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated, ErrorText);
		
	EndIf;

EndProcedure

&AtClient
Procedure IssueMissingInvoices(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																	|ru = 'Организация';
																	|en = 'Company'; fa = 'Company';
																	|it = 'Azienda';
																	|pl = 'Firma';
																	|tr = 'İş yeri'"));
	CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																|ru = 'Комитент';
																|en = 'Consignor'; fa = 'امانت‌گذار';
																|it = 'Committente';
																|pl = 'Komitent';
																|tr = 'Gönderici'"));
	CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																	|ru = 'Валюта';
																	|en = 'Currency'; fa = 'ارز';
																	|it = 'Valuta';
																	|pl = 'Waluta';
																	|tr = 'Para birimi'"));
	Notification = New CallbackDescription("IssueMissingInvoicesCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentSettlement);
	
EndProcedure

&AtClient
Procedure OffsetOfPaymentRemuneration(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentOffsetByRemuneration);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


&AtClient
Procedure FillInVATRate(Command)

	If Object.Goods.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Hàng hóa"" chưa điền dòng nào.';
							|ru = 'В список ""Товары"" не введено ни одной строки.';
							|en = 'No lines entered in the Item list.'; fa = 'No lines entered in the Item list.';
							|it = 'В список ""Товары"" не введено ни одной строки.';
							|pl = 'Do listy ""Wiersze pozycji"" nie wprowadzono żadnego wiersza.';
							|tr = '""Ürünler"" listesine hiçbir satır girilmemiştir.'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;

	ClosingNotification1 = New CallbackDescription("FillInVATRateCompletion", ThisObject);
	FormParameters = New Structure();
	FormParameters.Insert("VATTaxationType", Object.VATTaxation);
	OpenForm("Catalog.VATRates.ChoiceForm", FormParameters,,,,, ClosingNotification1);

EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartnerProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Partner");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn nhà cung cấp>';
													|ru = '<выберите поставщика>';
													|en = '<select vendor>'; fa = '<select vendor>';
													|it = '<selezionare il fornitore>';
													|pl = '<wybierz dostawcę>';
													|tr = '<tedarikçi seçin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Contract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Terms");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Contract");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTaxInvoiceDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.TaxInvoiceDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có hóa đơn GTGT>';
													|ru = '<отсутствует счет-фактура>';
													|en = '<tax invoice is missing>'; fa = '<tax invoice is missing>';
													|it = '<manca la fattura>';
													|pl = '<brakuje faktury>';
													|tr = '<vergi faturası mevcut değil>'"));

	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);

EndProcedure

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateSaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer();
		
		ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage);
		
		UpdateTextOfInvoiceIssued();
		
	EndIf;
		
	CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
		Object.BankAccount, Object.PaymentMethod, Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
	CashServer.CheckOrganizationSSalesRegisterByOwner(Object.Organization, Object.CashAccount, Object.PaymentMethod, Object.LineOfBusiness);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization, Contract");
	
	FillInSubordinatePropertiesForStatistics("Organization");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure CurrencyOnChangeServer(NewCurrency, RecalculateAmounts)
	
	FillInDefaultContract();
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	If RecalculateAmounts Then
		SalesServer.ConvertDocumentAmountToCurrency(Object, DocumentCurrency, Object.Currency);
		CalculateRemuneration = True;
	EndIf;
		
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	ArrayOfChangedProps = New Array;
	ArrayOfChangedProps.Add("Partner");
	
	StructureOfAdditionalSelection = New Structure("SelectedAgreement", Object.Terms);
	
	OperationArray = New Array();
	OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement"));
	OperationArray.Add(PredefinedValue("Enum.BusinessTransactions.AgentServicesDelivery"));
	StructureOfAdditionalSelection.Insert("BusinessTransactions", OperationArray);
	
	PurchaseConditions = PurchasesServer.GetDefaultPurchaseTerms(
		Object.Partner,
		StructureOfAdditionalSelection);
		
	If PurchaseConditions <> Undefined Then
		
		If Object.Terms <> PurchaseConditions.Terms
			And ValueIsFilled(PurchaseConditions.Terms) Then
		
			Object.Terms = PurchaseConditions.Terms;
			TermsOnChangeServer(False);
			
		Else
			Object.Terms = PurchaseConditions.Terms;
			ArrayOfChangedProps.Add("Currency");
			ArrayOfChangedProps.Add("LineOfBusiness");
			ArrayOfChangedProps.Add("Organization");
			ArrayOfChangedProps.Add("Counterparty");
			ArrayOfChangedProps.Add("Contract");
		EndIf;
			
	Else
		Object.Terms = Undefined;
		ArrayOfChangedProps.Add("Terms");
		ArrayOfChangedProps.Add("Contract");
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		Object.Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Object.Partner);
		ArrayOfChangedProps.Add("Counterparty");
	EndIf;
	
	FillInDefaultContract();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ArrayOfChangedProps);
	
	SetAvailabilityAgreements();
	
	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Object.Goods, Object.Partner);
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateTextOfInvoiceIssued();
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Object.Partner, Object.ContactPerson);
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure ContactPersonOnChangeServer(PartnerChanged_)
	
	OwnerOfContactPerson = Common.ObjectAttributeValue(Object.ContactPerson, "Owner");
	If OwnerOfContactPerson <> Object.Partner Then
		Object.Partner = OwnerOfContactPerson;
		PartnerOnChangeServer();
		PartnerChanged_ = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure TermsOnChangeServer(RecalculatePrices_ = True)

	If ValueIsFilled(Object.Terms) Then
		
		CurrentCompany = Object.Organization;
		
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Object.Terms);
		FillPropertyValues(Object, PurchaseConditions, , "ARAPObjectSettings, Organization");
		
		If ValueIsFilled(PurchaseConditions.Organization) Then
			Object.Organization = PurchaseConditions.Organization;
		EndIf;
		
		ConsignmentSalesServer.CalculateRewardAmount(Object);
		CalculateRemuneration = False;
		
		If CurrentCompany <> Object.Organization Then
			Object.BankAccount = Undefined;
			Object.CashAccount = Undefined;
			OrganizationOnChangeServer();
		EndIf;
		
		FillInVATTaxationPurchases();
		VATTaxationOnChangeServer();
		
		DocumentCurrency = Object.Currency;
		If RecalculatePrices_ Then
			ConsignmentSalesServer.FillInSalePrices(Object);
		EndIf;
				
		CalculateFinalIndicatorsOfReportToCommittee(ThisForm);
		FormItemsManagement();
		
		UpdateTextOfInvoiceIssued();
		
	EndIf;
	
	ArrayOfChangedProps = New Array;
	
	ArrayOfChangedProps.Add("Partner");
	ArrayOfChangedProps.Add("Currency");
	ArrayOfChangedProps.Add("LineOfBusiness");
	ArrayOfChangedProps.Add("Organization");
	ArrayOfChangedProps.Add("Counterparty");
	ArrayOfChangedProps.Add("Contract");
	ArrayOfChangedProps.Add("CommissionFeeCalculationMethod");
	ArrayOfChangedProps.Add("KeepCommissionFee");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, ArrayOfChangedProps);
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	SetPresentationOfFoundationDocument();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
	EndIf;
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty, Contract");
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
		Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	Object.BankAccount = GetOrganizationSDefaultBankAccountServer();
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	ResponsiblePersonsServer.FillInManager_(Object);
	FillInSubordinatePropertiesForStatistics("Contract");
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
		
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount"); 
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues); 
		
	CurrentRow = New Structure("VATRate", Catalogs.VATRates.EmptyRef());

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	Object.VATRateOfRemuneration = CurrentRow.VATRate;
	
	ConsignmentSalesServer.CalculateRewardAmount(Object);
	
	AmountVATRemuneration = VATAccountingERPClientServer.CalculateVATAmount(
								CommissionAmount,
								VATAccountingERPClientServer.ValueOfVATRate(Object.VATRateOfRemuneration));
	
	CalculateFinalIndicatorsOfReportToCommittee(ThisForm);
	CalculateRemuneration = True;
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer(CachedValues)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object));
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
	
	Items.GoodsSum.Visible = Not Object.PriceIncludesVAT;
	
EndProcedure

&AtServer
Procedure CommissionFeeCalculationMethodOnChangeServer()
	
	FormItemsManagement();
	CalculateFinalIndicatorsOfReportToCommittee(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "CommissionFeeCalculationMethod");
	UpdateTextOfInvoiceIssued();
	
EndProcedure

&AtServer
Function DateOnChangeServer(RecalculatePrices_2)
	
	If RecalculatePrices_2 Then
		PricesCalculated = FillThePricesByTermsOfSalesServer();
	Else
		PricesCalculated = False;
	EndIf;
	
	FillInVATTaxationPurchases();
	VATTaxationOnChangeServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Date");
	
	Return PricesCalculated;
	
EndFunction

&AtServer
Procedure OperationServiceOnChangeServer()
	
	ConsignmentSalesServer.FillInLBRateOfJointCommissionRemuneration(Object, VATPercentage);
	
EndProcedure

&AtClient
Procedure RecalculateSaleAmount(TableRow)
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateSaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		FillInDefaultContract();
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "LineOfBusiness");
	
EndProcedure

&AtClient
Procedure WhenSelectingSalesDocumentEnd(Response, SelectedSalesDocument) Export
	
	If Response = DialogReturnCode.Yes Then
		Object.DocumentSales = SelectedSalesDocument;
		SetPresentationOfFoundationDocument();
		Object.Goods.Clear();
		CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
		CheckParameters.TabularSection = Object.Goods;
		CheckParameters.CheckedAttributes.Insert("Organization", NStr("vi = 'Doanh nghiệp';
																		|ru = 'Организация';
																		|en = 'Company'; fa = 'Company';
																		|it = 'Azienda';
																		|pl = 'Firma';
																		|tr = 'İş yeri'"));
		CheckParameters.CheckedAttributes.Insert("Partner",     NStr("vi = 'Người đặt ký gửi';
																	|ru = 'Комитент';
																	|en = 'Consignor'; fa = 'امانت‌گذار';
																	|it = 'Committente';
																	|pl = 'Komitent';
																	|tr = 'Gönderici'"));
		CheckParameters.CheckedAttributes.Insert("Currency",      NStr("vi = 'Tiền tệ';
																		|ru = 'Валюта';
																		|en = 'Currency'; fa = 'ارز';
																		|it = 'Valuta';
																		|pl = 'Waluta';
																		|tr = 'Para birimi'"));
		Notification = New CallbackDescription("FillInBySalesResultCompletion", ThisObject);
		ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	ElsIf ValueIsFilled(Object.DocumentSales) And Not ReportSales Then
		ReportSales = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPresentationOfFoundationDocument()
	
	SalesDocumentIsSpecified = False;
	
	If ValueIsFilled(Object.DocumentSales) Then
		
		RightToOpenSale = GetRightToAccessImplementation();
		StatusOfSalesDocumentSEDI = NStr("vi = '(Quản lý chứng từ điện tử: Chưa bắt đầu)';
										|ru = '(ЭДО: Не начат)';
										|en = '(EDI: Not started)'; fa = '(EDI: Not started)';
										|it = '(SDE: Non avviato)';
										|pl = '(EOD: Nie rozpoczęty)';
										|tr = '(EVD: Başlatılmadı)'");
		If RightToOpenSale Then
			DescriptionSalesDocument = New FormattedString(String(Object.DocumentSales),, ,, "OpenDocument");
		Else
			SetPrivilegedMode(True);
			DescriptionSalesDocument = String(Object.DocumentSales);
			SetPrivilegedMode(False);
		EndIf;
			
		PresentationOfSalesDocument = New FormattedString(DescriptionSalesDocument, "  ", StatusOfSalesDocumentSEDI);
		ReportSales = True;
		SalesDocumentIsSpecified = True;
		
	EndIf;
	
	If ValueIsFilled(Object.Terms) Then
		
		SplitReportByDocuments = Common.ObjectAttributeValue(Object.Terms, "SplitReportByDocuments");
		
		If Not AgreementIsOld = Object.Terms
			Or SplitReportByDocuments = False Then
				Object.DocumentSales = Undefined;
				AgreementIsOld = Object.Terms;
				SalesDocumentIsSpecified = False;
		EndIf;
		
		Items.ReportSales.Visible = SplitReportByDocuments;
		
		If Not ValueIsFilled(Object.DocumentSales)
			And SplitReportByDocuments Then
			PresentationOfSalesDocument = New FormattedString(NStr("vi = '<chưa chọn>';
																	|ru = '<не выбран>';
																	|en = '<Not selected>'; fa = '<Not selected>';
																	|it = '<non è selezionato>';
																	|pl = '<nie wybrany>';
																	|tr = '<seçilmedi>'"),, StyleColors.SpecialTextColor,, "SelectDocument");
			SalesDocumentIsSpecified = True;
		ElsIf Not SplitReportByDocuments Then
			Object.DocumentSales = Undefined;
			ReportSales = False;
			SalesDocumentIsSpecified = False;
		EndIf;
		
	Else
		Object.DocumentSales = Undefined;
		Items.ReportSales.Visible = False;
		ReportSales = False;
		SalesDocumentIsSpecified = False;
	EndIf;
	
	If ReportSales Then
		Items.PeriodDateGroup.Visible = False;
		Items.GoodsIssueMissingInvoices.Enabled = False;
		Items.ProductsGroupSalesInformation.Visible = False;
		Object.BeginOfPeriod = Date('00010101');
		Object.EndOfPeriod = Date('00010101');
	Else
		Items.PeriodDateGroup.Visible = True;
		SetAvailabilityOfInvoices(ThisObject);
		Items.ProductsGroupSalesInformation.Visible = True;
	EndIf;
	
	Items.GroupDataOnSalesDocument.Visible = SalesDocumentIsSpecified;
	
EndProcedure


#EndRegion

#Region SelectionAndProcessingOfQuantityVerification

&AtServer
Function PutProductsInStorage(Val Goods, Var_UUID)

	AddressOfPaymentsInTheStorage = PutToTempStorage(
		Goods.Unload(,"Products, Characteristic, TaxInvoiceDate, CustomerInvoiceIssued, Customer, Count"),
		Var_UUID);
		
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	Return InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
		
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisForm);
	
EndProcedure

&AtServer
Procedure GetProductsFromStorage(AddressOfPaymentsInTheStorage)

	Object.Goods.Load(GetFromTempStorage(AddressOfPaymentsInTheStorage));
	
	If ValueIsFilled(Object.Terms) Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price");
		FillParameters.Insert("Date", Object.Date);
		FillParameters.Insert("Currency", Object.Currency);
		FillParameters.Insert("Terms", Object.Terms);
		FillParameters.Insert("VATTaxation", Object.VATTaxation);
		FillParameters.Insert("Organization", Object.Organization);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSaleAmount");
		
		BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
		
		PartnerPricesFillingServer.FillInPrices(
			Object.Goods,
			Undefined, // Array of strings
			FillParameters,
			StructureOfActions);
			
	EndIf;
	
	ConsignmentSalesServer.FillInAmountWithVAT(
		Object.Goods,
		Object.PriceIncludesVAT);

	ConsignmentSalesServer.FillInVATSaleAmount(Object.Goods);
	
	
	CalculateRemuneration = True;
	SetAvailabilityOfInvoices(ThisForm);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	PartnersProductsServer.FillInPartnerProductsByProductsInTable(Object.Goods, Object.Partner);
	
EndProcedure

#EndRegion

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.ConsignmentReportToVendor.FillInNamesOfBusinessTransactionDetails(
		Object.CommissionFeeCalculationMethod,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
    CashServer.SetAvailabilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	SaleIsSubjectToVAT = (Object.VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	Items.GoodsVATRate.Visible = SaleIsSubjectToVAT;
	Items.GoodsVATAmount.Visible = SaleIsSubjectToVAT;
	Items.GoodsAmountSalesVAT.Visible = SaleIsSubjectToVAT;
	
	Items.GoodsSum.Visible = SaleIsSubjectToVAT And Not Object.PriceIncludesVAT;
	
	CalculationMethodNotCalculated = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"PaymentOffsetByRemuneration",
		"Enabled",
		Not Object.KeepCommissionFee And Not CalculationMethodNotCalculated);
		
	CommonClientServer.SetFormItemProperty(
		Items,
		"PaymentDate",
		"Enabled",
		Not Object.KeepCommissionFee And Not CalculationMethodNotCalculated);

	CalculationMethodIsArbitraryAmount = (Object.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.ArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "RemunerationPercentage", "Visible", Not CalculationMethodIsArbitraryAmount);
	CommonClientServer.SetFormItemProperty(Items, "CommissionAmount", "ReadOnly", Not CalculationMethodIsArbitraryAmount);

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfInvoices(Form)
	
	DesignAvailability = False;
	
	For Each LineProducts_ In Form.Object.Goods Do
		If Not ValueIsFilled(LineProducts_.TaxInvoiceDate) Then
			DesignAvailability = True;
			Break;
		EndIf;
	EndDo;
	
	Form.Items.GoodsIssueMissingInvoices.Enabled = DesignAvailability;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UseSimplifiedPaymentScheme = GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing");
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	SetAvailabilityAgreements();
	
	DocumentCurrency = Object.Currency;
	FormItemsManagement();
	SetAvailabilityOfInvoices(ThisForm);
	VATPercentage = PriceManagementSystemClientServer.GetVATRateAsNumber(Object.VATRateOfRemuneration);
	
	UpdateTextOfInvoiceIssued();
	
	CalculateFinalIndicatorsOfReportToCommittee(ThisForm);
	
	StructureCharacteristicsOfProducts = New Structure;
	StructureCharacteristicsOfProducts.Insert("FillInFeatureAttribute",	New Structure("Products", "ItemVariantsAreUsed"));
	StructureCharacteristicsOfProducts.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureCharacteristicsOfProducts);
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
			
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts 
			And UseLinesOfBusiness Then
			
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
		Contract = PurchasesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.ConsignmentProcurement, 
															AddlParameters);
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.Currency;
		Contract = PurchasesServer.GetDefaultContract(Object, 
															Enums.BusinessTransactions.ConsignmentProcurement, 
															AddlParameters);
	EndIf;	
		
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Contract");
		If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
			Object.BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.BankAccount);
	EndIf;
	
EndProcedure

&AtServer
Function FillThePricesByTermsOfSalesServer(ErrorText = "")
	
	If Common.ObjectAttributeValue(Object.Terms, "PriceIncludesVAT") <> Object.PriceIncludesVAT Then
		ErrorText = 
		NStr("vi = 'Các giá trị đã đặt cho trường ""Đơn giá gồm thuế GTGT"" trong chứng từ và thỏa thuận là khác nhau.';
			|ru = 'Установленные значения полей ""Цена включает НДС"" в документе и соглашении разные.';
			|en = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.'; fa = 'Set values of the ""Price includes VAT"" fields in the document and agreement are different.';
			|it = 'I valori impostati dei campi ""Prezzo IVA inclusa"" nel documento e nell''accordo differiscono.';
			|pl = 'Ustawione wartości pól ""Cena brutto"" w dokumencie i umową są różne.';
			|tr = 'Belgedeki ve sözleşmedeki ""KDV dahildir"" alanlarının hesaplanan değerleri farklıdır.'");
		Return False;
	EndIf;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields", "Price");
	FillParameters.Insert("Date", Object.Date);
	FillParameters.Insert("Currency", Object.Currency);
	FillParameters.Insert("Terms", Object.Terms);
	FillParameters.Insert("VATTaxation", Object.VATTaxation);
	FillParameters.Insert("Organization", Object.Organization);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClientServerLocalization.AddActionOfFillingInVATRateForSettingUpAccounting(Object, StructureOfActions);
	
	PricesCalculated = PartnerPricesFillingServer.FillInPrices(
		Object.Goods,
		Undefined, // Array of strings
		FillParameters,
		StructureOfActions);
	
	ConsignmentSalesServer.FillInAmountWithVAT(
		Object.Goods,
		Object.PriceIncludesVAT);
	Return PricesCalculated;
	
EndFunction

&AtClient
Procedure QuestionUserBeforeFillingInPricesByAgreement(CallbackDescription)
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(
		CallbackDescription,
		NStr("vi = 'Điền lại giá theo thỏa thuận?';
			|ru = 'Перезаполнить цены по соглашению?';
			|en = 'Refill prices by terms of sales?'; fa = 'Refill prices by terms of sales?';
			|it = 'Ricompilare i prezzi in base all''accordo?';
			|pl = 'Wypełnić ceny ponownie wg porozumienia?';
			|tr = 'Fiyatlar anlaşmaya göre yeniden doldurulsun mu?'"),
		AnswersOptions);
	
EndProcedure

&AtServer
Procedure FillInBySalesResultServer()
	
	ConsignmentSalesServer.InformationOnGoodsForMakingReportsToCommitteeForPeriod(Object,
																					Object.BeginOfPeriod,
																					Object.EndOfPeriod,
																					False,
																					True,
																					True);
	
		
	ActionsWithString = New Structure;
	ActionsWithString.Insert("FillInArticleAttribute",	New Structure("Products", "SKU"));
	ActionsWithString.Insert("FillInFeatureAttribute",
								New Structure("Products", "ItemVariantsAreUsed"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, ActionsWithString);
	
	CalculateRemuneration = True;
	
	SetAvailabilityOfInvoices(ThisForm);
	
EndProcedure


// This procedure is used in the AutoTest of the sales process.
//
&AtServer
Procedure CalculateServerCommission()
	
	ConsignmentSalesServer.CalculateRewardAmount(Object);
	CalculateRemuneration = False;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateFinalIndicatorsOfReportToCommittee(Form)
	
	DisplayTotalAmountOfVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation);
	
	If DisplayTotalAmountOfVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
	If Form.Object.CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		Form.Items.TotalRemunerationAmount.Visible      = False;
	Else
		Form.Items.TotalRemunerationAmount.Visible      = True;
	EndIf;
	
	TotalPaymentPercentage = 0;
	PreviousDateValue = Date(1, 1, 1);
	Form.LineNumberOfFullPayment = 0;
	For Each CurRow In Form.Object.PaymentScheduleSteps Do
		TotalPaymentPercentage = TotalPaymentPercentage + CurRow.PaymentPercentage;
		CurRow.PercentageIsFilledInIncorrectly = (TotalPaymentPercentage > 100);
		CurRow.DateIsFilledInIncorrectly = (PreviousDateValue > CurRow.PaymentDate);
		PreviousDateValue = CurRow.PaymentDate;
		If TotalPaymentPercentage = 100 Then
			Form.LineNumberOfFullPayment = CurRow.LineNumber;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)

	 Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
       PlacePaymentStepsInTemporaryStorage(Item.Name);
       ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification );
EndProcedure

&AtServer
Procedure PlacePaymentStepsInTemporaryStorage(TagName)
       PaymentStepsServer.PlacePaymentStepsInTemporaryStorage(ThisForm, TagName);
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
	EndIf;
		
EndProcedure

&AtServer
Procedure SetAvailabilityAgreements()
	If ValueIsFilled(Object.Partner) Then
		NumberOfAgreementsWithPostavshik  = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible", NumberOfAgreementsWithPostavshik > 0);
	EndIf; 
EndProcedure

&AtServer
Procedure UpdateTextOfInvoiceIssued()
	
	RegistrationParameters = ParametersForRegisteringInvoicesIssuedServer(Object);
	RegistrationParameters.Insert("DocumentPresentationPostfix", NStr("vi = '(Hoa hồng ký gửi)';
																		|ru = '(Комиссионное вознаграждение)';
																		|en = '(Commission)'; fa = '(Commission)';
																		|it = '(Provvigione)';
																		|pl = '(Wynagrodzenie prowizyjne)';
																		|tr = '(Komisyon ücreti)'"));
	InvoicesIssuedOnBasisOf = VATAccountingERP.InvoicesIssuedOnBasisOf(RegistrationParameters);
	TextOfTheInvoiceIssued =  InvoicesIssuedOnBasisOf.Presentation;
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter, Source)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfSelectingPartnerProductName(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.CurrentRow.PartnerProducts = ValueSelected;
	
	GoodsPartnerProductsOnChange(AdditionalParameters.FormItem);
	
EndProcedure

&AtServer
Function GetOrganizationSDefaultBankAccountServer()
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	Return CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		Object.BankAccount, Object.PaymentMethod);
	
EndFunction

#EndRegion

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	// Subsystem "Properties"
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
EndProcedure

#EndRegion

&AtClient
Procedure DateOnChangeCompletion(QuestionResult, AdditionalParameters) Export 
	
	ClearMessages();
	
	If Not QuestionResult = DialogReturnCode.Cancel Then
		PricesCalculated = DateOnChangeServer(QuestionResult);
	EndIf;
	
	If QuestionResult = True Then
		SalesClient.NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated);
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Goods.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
		CalculateFinalIndicatorsOfReportToCommittee(ThisForm);
		CalculateRemuneration = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInBySalesResultCompletion(Result, AdditionalParameters) Export
	
	FillInBySalesResultServer();
	
EndProcedure

&AtClient
Procedure SelectBySalesResultsCompletion(Result, AdditionalParameters) Export
	
	AddressGoodsInStorage = PutProductsInStorage(
		Object.Goods,
		UUID);
		
	PickingParameters = New Structure;
	PickingParameters.Insert("AddressGoodsInStorage", AddressGoodsInStorage);
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Partner", Object.Partner);
	PickingParameters.Insert("Terms", Object.Terms);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("Contract", Object.Contract);
	PickingParameters.Insert("Currency", Object.Currency);
	PickingParameters.Insert("Date", Object.Date);
	PickingParameters.Insert("VATTaxation", Object.VATTaxation);
	PickingParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	PickingParameters.Insert("EndOfPeriod", Object.EndOfPeriod);
	PickingParameters.Insert("ThisIsASalesReport", True);
	PickingParameters.Insert("DocumentSales", Object.DocumentSales);
	
	OpenForm(
		"CommonForm.SelectByGoodsForRegistrationOfConsignorReport",
		PickingParameters, 
		ThisForm);
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);
	CalculateRemuneration = True;

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("ClearRewardAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Goods, Items.Goods.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);

	CalculateFinalIndicatorsOfReportToCommittee(ThisObject);
	FormItemsManagement();

EndProcedure

&AtClient
Procedure IssueMissingInvoicesCompletion(Result, AdditionalParameters) Export
	
	FormParameters = VATAccountingERPClient.ParametersOfInvoiceFormForReportToCommittee();
	FillPropertyValues(FormParameters, Object);
	FormParameters.AddressOfTableOfSalesOfCommissionGoods = SaleDocuments();
	VATAccountingERPClient.OpenInvoiceFormForReportToCommittee(FormParameters, ThisForm);
	
EndProcedure

&AtServer
Function SaleDocuments()
	SetPrivilegedMode(True);
	Query = New Query("
	|SELECT	
	|	InventoryKinds.Ref AS InventoryOwnerAttribute	
	|	
	|INTO InventoryKinds	
	|FROM	
	|	Catalog.InventoryKinds AS InventoryKinds	
	|WHERE	
	|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)	
	|	AND InventoryKinds.Organization = &Organization	
	|	AND InventoryKinds.GoodsOwner = &Partner	
	|	AND (InventoryKinds.Terms = &Terms	
	|		OR (NOT &SelectByAgreement))	
	|	AND InventoryKinds.Currency = &Currency	
	|;	
	|/////////////////////////////////////////////////////////////////////////////	
	|SELECT
	|	GoodsForRegistration.Recorder AS SaleOfGoodsAndServices,
	|	CustomerInvoice.SalesOrder AS ReferenceOrder,
	|	ISNULL(GoodsShipmentToCustomer.Ref, CustomerInvoice.SalesOrder) AS Shipment
	|
	|INTO DocumentsOfTransferOfOwnership
	|
	|FROM
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration
	|		INNER JOIN InventoryKinds AS InventoryKinds
	|			ON GoodsForRegistration.InventoryOwnerAttribute = InventoryKinds.InventoryOwnerAttribute
	|
	|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
	|			ON GoodsForRegistration.Recorder = CustomerInvoice.Ref
	|			AND CustomerInvoice.Posted
	|
	|		LEFT JOIN Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|		ON CustomerInvoice.SalesOrder = GoodsShipmentToCustomer.SalesOrder
	|			AND GoodsShipmentToCustomer.Posted
	|WHERE
	|	GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND GoodsForRegistration.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|		AND GoodsForRegistration.Count > 0
	|		AND GoodsForRegistration.Active
	|
	|INDEX BY
	|	Shipment
	|;
	|/////////////////////////////////////////////////////////////////////////////	
	|SELECT DISTINCT	
	|	GoodsForRegistration.DocumentSalesOfGoodsAndServices AS Ref,	
	|	GoodsForRegistration.DocumentSalesOfGoodsAndServices.Date AS Date,	
	|	GoodsForRegistration.DocumentSalesOfGoodsAndServices.DocumentAmount AS Sum,	
	|	GoodsForRegistration.DocumentSalesOfGoodsAndServices.Currency AS Currency,	
	|	
	|	CASE WHEN GoodsForRegistration.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoiceIntercompany THEN	
	|		VALUE(Catalog.Partners.OurEnterprise)	
	|	ELSE	
	|		GoodsForRegistration.DocumentSalesOfGoodsAndServices.Partner	
	|	END AS Partner,	
	|	
	|	CASE WHEN GoodsForRegistration.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoiceIntercompany THEN	
	|		GoodsForRegistration.DocumentSalesOfGoodsAndServices.CompanyRecipient	
	|	ELSE	
	|		GoodsForRegistration.DocumentSalesOfGoodsAndServices.Counterparty	
	|	END AS Counterparty	
	|	
	|FROM	
	|	AccumulationRegister.GoodsToBeRegisteredInReportsToConsignor AS GoodsForRegistration	
	|		
	|	INNER JOIN	
	|		InventoryKinds AS InventoryKinds	
	|	ON	
	|		GoodsForRegistration.InventoryOwnerAttribute = InventoryKinds.InventoryOwnerAttribute	
	|		
	|WHERE	
	|	GoodsForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod	
	|	AND GoodsForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)	
	|	AND GoodsForRegistration.Count > 0	
	|	AND GoodsForRegistration.DocumentSalesOfGoodsAndServices <> UNDEFINED	
	|	AND (NOT GoodsForRegistration.DocumentSalesOfGoodsAndServices REFS Document.RetailSalesReport)	
	|	AND (NOT GoodsForRegistration.DocumentSalesOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|	AND GoodsForRegistration.Active	
	|	
	|UNION ALL
	|
	|SELECT DISTINCT
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices AS Ref,
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices.Date AS Date,
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices.DocumentAmount AS Sum,
	|	ServicesForRegistration.DocumentSalesOfGoodsAndServices.Currency AS Currency,
	|	CASE
	|		WHEN ServicesForRegistration.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoiceIntercompany
	|			THEN VALUE(Catalog.Partners.OurEnterprise)
	|		ELSE ServicesForRegistration.DocumentSalesOfGoodsAndServices.Partner
	|	END AS Partner,
	|	CASE
	|		WHEN ServicesForRegistration.DocumentSalesOfGoodsAndServices REFS Document.CustomerInvoiceIntercompany
	|			THEN ServicesForRegistration.DocumentSalesOfGoodsAndServices.CompanyRecipient
	|		ELSE ServicesForRegistration.DocumentSalesOfGoodsAndServices.Counterparty
	|	END AS Counterparty
	|FROM
	|	AccumulationRegister.ServicesForRegistrationOfReportsToPrincipal AS ServicesForRegistration
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON ServicesForRegistration.ItemsLocationAttributes = DimensionKeys.Ref
	|WHERE
	|	ServicesForRegistration.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND ServicesForRegistration.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND ServicesForRegistration.Organization = &Organization
	|	AND DimensionKeys.Partner = &Partner
	|	AND (ServicesForRegistration.Terms = &Terms
	|			OR NOT &SelectByAgreement)
	|	AND ServicesForRegistration.Currency = &Currency
	|	AND ServicesForRegistration.Count > 0
	|	AND ServicesForRegistration.DocumentSalesOfGoodsAndServices <> UNDEFINED
	|	AND NOT ServicesForRegistration.DocumentSalesOfGoodsAndServices REFS Document.RetailSalesReport
	|	AND NOT ServicesForRegistration.DocumentSalesOfGoodsAndServices.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|	AND ServicesForRegistration.Active
	|	
	|UNION ALL
	|	
	|SELECT DISTINCT
	|	GoodsShipmentToCustomer.Ref AS Ref,
	|	GoodsShipmentToCustomer.Date AS Date,
	|	GoodsShipmentToCustomer.DocumentAmount AS Sum,
	|	GoodsShipmentToCustomer.Currency AS Currency,
	|	GoodsShipmentToCustomer.Partner AS Partner,
	|	GoodsShipmentToCustomer.Counterparty AS Counterparty
	|FROM
	|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentToCustomer.Posted
	|	AND GoodsShipmentToCustomer.Ref IN
	|			(SELECT
	|				Shipment AS Shipment
	|			FROM
	|				DocumentsOfTransferOfOwnership AS DocumentsOfTransferOfOwnership)
	|	
	|ORDER BY	
	|	GoodsForRegistration.DocumentSalesOfGoodsAndServices.Date	
	|");
	Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", EndOfDay(	?(ValueIsFilled(Object.EndOfPeriod), 
														Object.EndOfPeriod, 
														CurrentSessionDate()) ));
	Query.SetParameter("Currency", Object.Currency);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Partner", Object.Partner);
	Query.SetParameter("Terms", Object.Terms);
	Query.SetParameter("SelectByAgreement", ValueIsFilled(Object.Terms));
	
	Return PutToTempStorage( Query.Execute().Unload(), ThisForm.UUID );
	
EndFunction

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation, Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues); 
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	PaymentStepsServer.LoadPaymentStagesFromTemporaryStorage(ThisForm);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure


&AtClient
Procedure GoodsCustomerInvoiceIssuedOnChange(Item) 
	
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
