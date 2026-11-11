#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

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
	
	DocumentCorrection.OnCreateAtServer(ThisObject, Items.LineCorrection);
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.DocumentGroup_2.BackColor = New Color();
	EndIf;

	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	SetHeadingIncomeExpenseItem();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"BaseGroup_",
		"Visible",
		ValueIsFilled(Object.DocumentBasis));
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Contract = Object.Contract;
	
	ChangeDisplayOfTotals(ThisObject);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	If Object.BusinessOperation <> Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		For Each Command In Commands Do
			If Command.Title = NStr("vi = 'Giấy thanh toán tiền tạm ứng';
									|ru = 'Авансовый отчет';
									|en = 'Expense report'; fa = 'گزارش هزینه';
									|it = 'Nota spese';
									|pl = 'Raport zaliczkowy';
									|tr = 'Gider raporu'") Then
				PrintAdvanceReportButton = Items.PrintSubmenu.ChildItems.Find(Command.Name);
				If PrintAdvanceReportButton <> Undefined Then
					PrintAdvanceReportButton.Visible = False;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	
	If GetFunctionalOption("TradeManagement") Then
		Items.GenerateStatement.Visible = False;
	Else
	
	
	EndIf;
	SetupParameters = Documents.VendorInvoiceServicesAndAssets.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	AccountingForTraceableGoodsLocalization.EstablishVisibilityOfRNPTQuantity(
		ThisObject,
		Date(1, 1, 1),
		"ExpensesGroupQuantityAccordingToRNPT",
		True);
	
	AccountingForTraceableGoodsLocalization.SetTitleNumberOfCCD(Items, 
		Items.ExpensesCCDNumber.Name, True);
	
	// Standard subsystems.Accounting of the originals of the first documents
	SourceDocumentsOriginalsRecording.OnCreateAtServerDocumentForm(ThisObject);
	// The end of the standard subsystem.Accounting of the originals of the first documents
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject, "ExpensesFillInVATRate");

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
	OnReadCreateAtServer();
	SetupParameters = Documents.VendorInvoiceServicesAndAssets.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(Object.BusinessOperation);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	Return; // WE have an empty handler
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.BusinessStructure.Form.ChoiceForm" Then
		
		SelectedRows = Items.Expenses.SelectedRows;
		
		For Each String In SelectedRows Do
			RowData = Object.Expenses.FindByID(String);
			RowData.Department = ValueSelected;
		EndDo;
		
	ElsIf ChoiceSource.FormName = "CommonForm.AttributesForExpenseReportPrinting" Then
		
		If ValueSelected <> Undefined Then
			FillPropertyValues(Object, ValueSelected);
		EndIf;
		
	EndIf;
	
	If VATAccountingERPClient.FinishedEditingInvoiceReceived(ValueSelected, ChoiceSource) Then
		UpdateInvoiceText();
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
		
	Notify("Write_VendorInvoiceServicesAndAssets", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	ARAPAccountingClient.FormAfterRecording(ThisObject);
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	SetAvailabilityOfItemsByStatusServer();
	
	UpdateInvoiceText();
	
	
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisObject, CurrentObject.AdditionalProperties);
	
	VendorInvoiceServicesAndAssetsLocalization.FillInRNPTIsBeingRecordedAttribute(Object.Expenses);
	
	UnlockFormDataForEdit();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If ARAPAccountingClient.NeedAlertProcessingCall(ThisForm, EventName, Parameter) Then
		PaymentCreditedServer(EventName, Parameter);
	EndIf;
	
	If EventName = "UpdateInformationSecurityDocumentAfterFillingItOut"  And Parameter.Find(Object.Ref) <> Undefined Then
		ThisForm.Read();
	ElsIf EventName = "UpdateIBDocumentAfterFillingItOutFromFile"  And Parameter.Find(Object.Ref) <> Undefined Then
		OnReadCreateAtServer();
	EndIf;
	
	If EventName = "Write_TermsOfPurchaseFromVendors" Then
		
		SetAvailabilityAgreements();
		
	EndIf;
	
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.SourceDocumentsOriginalsRecording	
	SourceDocumentsOriginalsRecordingClient.NotificationHandlerDocumentForm(EventName,ThisObject);
	// End StandardSubsystems.SourceDocumentsOriginalsRecording
	
	If EventName = "WhenChangingAgreement"
		And Source = ThisObject Then
		Modified = True;
		If ValueIsFilled(Object.Ref) Then
			Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Items[Parameter]);
		Else
			ContractOnChange(Items[Parameter]);
		EndIf;
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
EndProcedure

&AtClient
Procedure NewWriteProcessing(NewObject, Source, StandardProcessing)
	
	If PurchasesClient.ThisIsIndicationOfCCDNumber(Source) Then
		ParametersForSpecifyingCCDNumber = PurchasesClient.ParametersForSpecifyingCCDNumber();
		ParametersForSpecifyingCCDNumber.TSName = "Expenses";
		
		PurchasesClient.ProcessIndicationOfCCDNumber(ThisObject, NewObject, ParametersForSpecifyingCCDNumber);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	Return; // WE have an empty handler
	
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
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "MainGroup3" Then
		ARAPAccountingClientServer.UpdateHyperlinkText(ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	WhenChangingDateServer();
	
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	If AdjustmentModeFromPreviousDate And Not ValueIsFilled(Object.ActualTransactionDate) Then
		Object.ActualTransactionDate = Object.Date;
	ElsIf Not AdjustmentModeFromPreviousDate Then
		Object.ActualTransactionDate = Date(1,1,1);
	EndIf;
	
	Items.ActualTransactionDate.Enabled = AdjustmentModeFromPreviousDate;
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	WhenOrganizationChangesServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	WhenChangingCounterpartyServer();
	
	
EndProcedure

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StructureOfAdditionalSelection = New Structure;
	StructureOfAdditionalSelection.Insert("BusinessOperation", Object.BusinessOperation);
	
	PurchasesClient.StartSelectingSupplierAgreement(
		Item,
		StandardProcessing,
		Object.Partner,
		Object.Terms,
		Object.Date,
		StructureOfAdditionalSelection);

EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	If Not ValueIsFilled(Object.Partner) Then
		Return;
	EndIf; 
	
	WhenChangingPartnerServer();
	If ValueIsFilled(Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInDefaultPurchaseConditions();
	EndIf;
	

EndProcedure

&AtClient
Procedure TermsOnChange(Item)
	
	WhenChangingAgreementAtServer();
	
	If ValueIsFilled (Object.Terms) Then
		PurchasesClient.NotifyEndOfFillingInTermsOfPurchase();
	EndIf;
	
	If ValueIsFilled(Object.Currency)
		And ValueIsFilled(DocumentCurrency)
		And DocumentCurrency <> Object.Currency 
		And Object.Expenses.Total("Price") <> 0 Then
		
		MessageText = NStr("vi = 'Tính lại số tiền trong chứng từ theo nguyên tệ ""%Currency%""?';
							|ru = 'Пересчитать суммы в документе в валюту ""%Currency%""?';
							|en = 'Convert amounts in the document in %Currency%?'; fa = 'Convert amounts in the document in %Currency%?';
							|it = 'Ricalcolare gli importi del documento in valuta ""%Currency%""?';
							|pl = 'Przeliczyć kwoty w dokumencie na walutę ""%Currency%""?';
							|tr = 'Belgedeki tutarlar ""%Currency%"" para birimine göre yeniden hesaplansın mı?'");
		MessageText = StrReplace(MessageText, "%Currency%", Object.Currency);
		
		UserAnswer = Undefined;

		
		ShowQueryBox(New CallbackDescription("TermsOnChangeCompletion", ThisObject), MessageText,QuestionDialogMode.YesNo);
        Return;
		
	EndIf;
	
	AgreementWhenChangingFragment();
EndProcedure

&AtClient
Procedure TermsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    UserAnswer = QuestionResult;
    
    If UserAnswer = DialogReturnCode.Yes Then
        
        WhenChangingCurrencyServer(Object.Currency);
        PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
        
    EndIf;
    
    
    AgreementWhenChangingFragment();

EndProcedure

&AtClient
Procedure AgreementWhenChangingFragment()
    
    DocumentCurrency = Object.Currency;

EndProcedure

&AtClient
Procedure ContractCreating(Item, StandardProcessing)
	
	PurchasesClient.OpenContractCreationForm(ThisObject, Item, "Object.Contract", Object.Partner, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	WhenChangingAgreementServer();
	
EndProcedure

&AtClient
Procedure VATTaxationOnChange(Item)
	
	WhenChangingVATTaxationServer();
	ChangeDisplayOfTotals(ThisForm);
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	PriceIncludesVATOnChangeServer();
	
EndProcedure

&AtClient
Procedure InvoiceTextReceivedURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceived(Object);
	VATAccountingERPClient.ProcessingNavigationLinkInvoicesReceived(
		ThisForm,
		FormattedStringURL,
		StandardProcessing,
		RegistrationParameters);
	
EndProcedure

&AtClient
Procedure AttributesForExpenseReportPrintingClick(Item)
	
	PrintData = New Structure;
	PrintData.Insert("AdvancePurpose",             Object.AdvancePurpose);
	PrintData.Insert("DocumentsCount",         Object.DocumentsCount);
	PrintData.Insert("SheetQuantity",             Object.SheetQuantity);
	PrintData.Insert("Director",                 Object.Director);
	PrintData.Insert("ChiefAccountant",             Object.ChiefAccountant);
	
	PrintData.Insert("Date",                         Object.Date);
	PrintData.Insert("Organization",                  Object.Organization);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("PrintData", PrintData);
	
	OpenForm("CommonForm.AttributesForExpenseReportPrinting", ParametersStructure, ThisForm,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	SetVisibilityOfElementsByOperationServer();
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	SetupParameters = Documents.VendorInvoiceServicesAndAssets.AccountingAccountSettings_(Object.BusinessOperation);
	GLAccountSettingsServer.WhenChangingSettings(ThisForm, SetupParameters);
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)
	
	LineOfBusinessOnChangeServer();
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelCurrenciesClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelCurrenciesClickCompletion(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult = Undefined Then 
		Return;
	EndIf;
	
	If TypeOf(ClosingResult) = Type("Structure") Then
		
		ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
		If ChangedBankingDetails.Count() > 0 Then
			LabelCurrenciesClickCompletionServer(ClosingResult);
			If ChangedBankingDetails.Property("Currency") Then
				PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LabelCurrenciesClickCompletionServer(ClosingResult)
	
	ChangedBankingDetails = ClosingResult.OldValuesOfChangedProps;
	
	If ClosingResult.RecalculateDocumentAmounts Then
		DocumentAmountOnChangeServer(ClosingResult.DocumentAmount);
	EndIf;
	If ChangedBankingDetails.Property("Currency") Then
		DocumentCurrency = Object.Currency;
	EndIf;
	
	If ChangedBankingDetails.Property("ARAPCurrency") Then
		FillInDefaultContract();
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("LabelPaymentStagesClickCompletion", ThisObject);
	ARAPAccountingClient.LabelPaymentStagesClick(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure LabelPaymentStagesClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		ChangedBankingDetails = Result.OldValuesOfChangedProps;
		ReflectChangesToPaymentRules(ChangedBankingDetails);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler
	
EndProcedure

&AtClient
Procedure PurchaseForActivityClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_OriginalStateDecorationClick()

	// StandardSubsystems.SourceDocumentsOriginalsRecording
	SourceDocumentsOriginalsRecordingClient.OpenStateSelectionMenu(ThisObject,Items.OriginalStateDecoration);
	//End StandardSubsystems.SourceDocumentsOriginalsRecording

EndProcedure

&AtClient
Procedure OperationWithSelfEmployedPersonOnChange(Item)
	
	OperationWithSelfEmployedWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure StatusOfSelfEmployedReceiptClick(Item, StandardProcessing)

	StandardProcessing = False;
	CashClientLocalization.BeforeUploadingSelfEmployedPersonSReceiptToDocument(ThisObject);

EndProcedure

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

#EndRegion

#Region FormTableItemsEventHandlersExpenses

&AtClient
Procedure ExpensesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.Expenses.CurrentData;	
	If NewRow And Not Copy Then
		CurrentData.Department = Object.Department;
		CurrentData.LineOfBusiness = Object.LineOfBusiness;
		WhenAddingExpenseLine(ThisObject, CurrentData);
	//Setting up accounting accounts 
	ElsIf NewRow And Copy Then
		GLAccountSettingsClient.WhenCopyingString(ThisObject, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesCountOnChange(Item)
	
	CurrentData = Items.Expenses.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count",          ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("Price",                CurrentData.Price);
	CurrentRow.Insert("Sum",               CurrentData.Sum);
	CurrentRow.Insert("VATRate",           CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",            CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",           CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP", CurrentData.AmountARAP);
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisForm);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	
EndProcedure

&AtClient
Procedure ExpensesPriceOnChange(Item)
	
	CurrentData = Items.Expenses.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count",          ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("Price",                CurrentData.Price);
	CurrentRow.Insert("Sum",               CurrentData.Sum);
	CurrentRow.Insert("VATRate",           CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",            CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",           CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP", CurrentData.AmountARAP);
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	
EndProcedure

&AtClient
Procedure ExpensesSumOnChange(Item)
	
	CurrentData = Items.Expenses.CurrentData;
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Count",          ?(CurrentData.Count <> 0, CurrentData.Count, 1));
	CurrentRow.Insert("Price",                CurrentData.Price);
	CurrentRow.Insert("Sum",               CurrentData.Sum);
	CurrentRow.Insert("VATRate",           CurrentData.VATRate);
	CurrentRow.Insert("VATAmount",            CurrentData.VATAmount);
	CurrentRow.Insert("AmountIncludingVAT",           CurrentData.AmountIncludingVAT);
	CurrentRow.Insert("AmountARAP", CurrentData.AmountARAP);
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", New Structure("QuantityName", "Count"));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	FillPropertyValues(CurrentData, CurrentRow, , "Count");
	
EndProcedure

&AtClient
Procedure ExpensesAmountARAPOnChange(Item)
	CurrentData = Items.Expenses.CurrentData;
	If CurrentData <> Undefined Then
		CurrentData.AmountVATARAP = 0;
	EndIf;
EndProcedure

&AtClient
Procedure ExpensesVATRateOnChange(Item)
	
	CurrentRow = Items.Expenses.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ExpensesVATAmountOnChange(Item)
	
	CurrentRow = Items.Expenses.CurrentData;
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure ExpensesExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpensesCCDNumberOnChange(Item)
	
	FillInTraceabilityAttributesInExpenseLine();
	
EndProcedure

&AtClient
Procedure ExpensesCCDNumberCreating(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.Expenses.CurrentData;
	
	AdditionalParameters = PurchasesClient.AdditionalParametersForCreatingCCDNumber();
	FillPropertyValues(AdditionalParameters, Object);
	FillPropertyValues(AdditionalParameters, ThisObject);
	
	AdditionalParameters.FieldNameQuantity = "Count";
	
	CreationParameters = PurchasesClient.ParametersForCreatingCCDNumber(CurrentData,
															Item.EditText,
															AdditionalParameters);
	
	FormParameters = New Structure("CreationParameters", CreationParameters);
	
	OpenForm("Catalog.CCDNumbers.Form.ItemForm",
				FormParameters,
				ThisObject,
				UUID);
	
EndProcedure

&AtClient
Procedure ExpensesSelection(Item, RowSelected, Field, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Field, StandardProcessing);
	Return;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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
Procedure SplitRow(Command)
	
	FormTable  = Items.Expenses;
	TableData = Object.Expenses;
	
	StringSplittingParameters = ProcessingOfTabularFormsClient.StringSplittingParameters();
	StringSplittingParameters.FieldNameQuantity = "Count";
	StringSplittingParameters.Title = NStr("vi = 'Hãy nhập số lượng trong dòng mới';
											|ru = 'Введите количество в новой строке';
											|en = 'Enter quantity in a new line'; fa = 'Enter quantity in a new line';
											|it = 'Inserire la quantità nella nuova riga';
											|pl = 'Wprowadź ilość w nowym wierszu';
											|tr = 'Miktarı yeni bir satıra girin'");
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification, StringSplittingParameters);
	
EndProcedure

&AtClient
Procedure SetAnExpenseItem(Command)
	
	IncomeAndExpensesClient.FillInArticleAndAnalyticsInSelectedLines(
		ThisObject, Items.ExpensesExpenseItem, Items.Expenses.SelectedRows);
	
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
Procedure CalculationsClick(Item, StandardProcessing)
	
	ARAPAccountingClient.CalculationsClick(ThisForm, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DistributeToReceipts(Command)
	
	AddressRowsToDistribution = PlaceSelectedRowsInStorage_(Items.Expenses.SelectedRows);
	If AddressRowsToDistribution = Undefined Then
		ClearMessages();
		CommonClientServer.MessageToUser(NStr("vi = 'Không có dòng để phân bổ cho các chứng từ mua lại.';
												|ru = 'Отсутствуют строки к распределению на документы приобретения.';
												|en = 'Lines to allocate among purchase documents are missing.'; fa = 'Lines to allocate among purchase documents are missing.';
												|it = 'Mancano le righe per la distribuzione sui documenti di acquisto.';
												|pl = 'Brak wierszy do podziału na dokumenty zakupu.';
												|tr = 'Satın alma belgelerine tahsis için herhangi bir satır bulunmamaktadır.'"));
	Else
		Handler = New CallbackDescription("DistributeToReceiptsCompletion", ThisObject);
		Mode = FormWindowOpeningMode.LockOwnerWindow;
		
		FormParameters = New Structure;
		FormParameters.Insert("Ref",       Object.Ref);
		FormParameters.Insert("Currency",       Object.Currency);
		FormParameters.Insert("TableOfRows", AddressRowsToDistribution);
		OpenForm("CommonForm.CostAllocationToGoodsReceipts", FormParameters,,,,, Handler, Mode);
	EndIf;

EndProcedure

&AtClient
Procedure DistributeToReceiptsCompletion(ClosingResult, Var_Parameters) Export
	If ClosingResult <> Undefined Then
		TransferResultToTab(ClosingResult);
		Modified = True;
	EndIf;
EndProcedure

// StandardSubsystems.AttachableCommands
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
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure FillInTheDepartment(Command)
	
	SelectedRows = Items.Expenses.SelectedRows;
	
	If Object.Expenses.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Chi phí"" chưa điền dòng nào.';
								|ru = 'В список ""Расходы"" не введено ни одной строки.';
								|en = 'No lines entered in the ""Expenses"" list.'; fa = 'No lines entered in the ""Expenses"" list.';
								|it = 'Nell''elenco ""Spese"" non è stata immessa alcuna riga.';
								|pl = 'Do listy ""Wydatki"" nie wprowadzono ani jednego wiersza.';
								|tr = '""Giderler"" listesine hiçbir satır girilmemiştir.'"));
		Return;
	ElsIf SelectedRows.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Trong danh sách ""Chi phí"" chưa chọn dòng nào.';
								|ru = 'В списке ""Расходы"" не выбрано ни одной строки.';
								|en = 'No lines are selected in the ""Expenses"" list.'; fa = 'No lines are selected in the ""Expenses"" list.';
								|it = 'Nell''elenco ""Spese"" non è stata selezionata alcuna riga.';
								|pl = 'W liście ""Wydatki"" nie wybrano ani jednego wiersza.';
								|tr = '""Giderler"" listesinde hiçbir satır seçilmemiştir.'"));
		Return;
	EndIf;
	
	FormParameters = New Structure("Department", Object.Department);
	
	OpenForm("Catalog.BusinessStructure.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure PaymentSettlement(Command)
	
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.PaymentSettlement(ThisForm, Items.PaymentSettlement);
	
EndProcedure

&AtClient
Procedure FillInVATRate(Command)

	If Object.Expenses.Count() = 0 Then
		WarningText = NStr("vi = 'Trong danh sách ""Chi phí"" chưa điền dòng nào.';
							|ru = 'В список ""Расходы"" не введено ни одной строки.';
							|en = 'No lines entered in the ""Expenses"" list.'; fa = 'No lines entered in the ""Expenses"" list.';
							|it = 'В список ""Расходы"" не введено ни одной строки.';
							|pl = 'Do listy ""Wydatki"" nie wprowadzono ani jednego wiersza.';
							|tr = '""Giderler"" listesine hiçbir satır girilmemiştir.'");
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
Procedure WhenChangingKeyDetailsStatusOfEDO()
	
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	VATAccountingERP.EstablishConditionalAppearanceOfVATAmountsForTaxationOfPurchases(ThisObject,
		"ExpensesVATRate",
		"ExpensesVATAmount",
		"ExpensesAmountIncludingVAT");
	
	//
	EnterprisePricesFillingServer.SetConditionalAppearancePriceIncludesVAT(ThisObject, "ExpensesAmountIncludingVAT");
	
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
	ItemField.Field = New DataCompositionField(Items.ExpensesAmountARAP.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Currency");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPCurrency");
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	//
	VendorInvoiceServicesAndAssetsLocalization.SetConditionalDesignOfDocumentForm(ThisObject);
	
	//
	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisObject);
	
EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure WhenChangingPartnerServer()
	
	AttributesArray = New Array;
	
	DocumentPurchases = FormAttributeToValue("Object");
	DocumentPurchases.FillInDefaultPurchaseConditions();
	ResponsiblePersonsServer.FillInManager_(DocumentPurchases);
	ValueToFormAttribute(DocumentPurchases, "Object");
	
	OriginalViewOfCounterparty = CounterpartyLegEntInd;
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	FillInSubordinatePropertiesForStatistics("Counterparty");
	WhenChangingAgreementServer();
	
	UpdatePurchaseForActivity();
	
	FillInVATTaxationPurchases();
	WhenChangingVATTaxationServer();
	
	IncomeAndExpensesServer.UpdateServiceDetails(ThisObject);
	
	SetAvailabilityAgreements();
	
	AttributesArray.Add("Partner");
	AttributesArray.Add("Currency");
	AttributesArray.Add("ARAPCurrency");
	AttributesArray.Add("Contract");
	AttributesArray.Add("LineOfBusiness");
	AttributesArray.Add("Counterparty");
	AttributesArray.Add("Organization");
	AttributesArray.Add("Terms");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	DocumentCurrency = Object.Currency;
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateInvoiceText();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	ChangeDisplayOfTotals(ThisForm);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	If OriginalViewOfCounterparty <> CounterpartyLegEntInd Then
		
		CashServerLocalization.FillInAttributeForPurchasingFromSelfEmployedPerson(ThisObject);
		OperationWithSelfEmployedWhenChangingOnServer();
		
	EndIf;
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);

EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer()
	
	AttributesArray = New Array;
	AttributesArray.Add("Terms");
	
	If ValueIsFilled(Object.Terms) Then
		
		DocumentPurchases = FormAttributeToValue("Object");
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(DocumentPurchases.Terms, True, True);
		DocumentPurchases.FillInTermsOfPurchase(PurchaseConditions);
		ValueToFormAttribute(DocumentPurchases, "Object");
		UpdatePurchaseForActivity();
		
		DocumentCurrency = Object.Currency;
		
		AttributesArray.Add("Partner");
		AttributesArray.Add("Currency");
		AttributesArray.Add("ARAPCurrency");
		AttributesArray.Add("Contract");
		AttributesArray.Add("LineOfBusiness");
		AttributesArray.Add("Counterparty");
		AttributesArray.Add("Organization");
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	UpdateInvoiceText();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;

	ChangeDisplayOfTotals(ThisForm);
	ResponsiblePersonsServer.FillInManager_(Object);
	
EndProcedure

&AtServer
Procedure WhenChangingCounterpartyServer()
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Counterparty) Then
		FillInDefaultContract();
		If Not Catalogs.CounterpartyBankAccounts.VerifyBankAccountHolder(
			Object.CounterpartyBankAccount, Object.Counterparty) Then
			ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
			Object.CounterpartyBankAccount =
				CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
		EndIf;
		FillInSubordinatePropertiesForStatistics("Counterparty");
	EndIf;
	
	FillInVATTaxationPurchases();
	WhenChangingVATTaxationServer();
	
	ChangeDisplayOfTotals(ThisForm);
	UpdatePurchaseForActivity();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	
	WhenChangingKeyDetailsStatusOfEDO();
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	
	OriginalViewOfCounterparty = CounterpartyLegEntInd;
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	If OriginalViewOfCounterparty <> CounterpartyLegEntInd Then
		
		CashServerLocalization.FillInAttributeForPurchasingFromSelfEmployedPerson(ThisObject);
		OperationWithSelfEmployedWhenChangingOnServer();
		
	EndIf;
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenOrganizationChangesServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible, Object.Contract);
	
	If ValueIsFilled(Object.Organization) Then
		
		FillInDefaultContract();
		
		If UseLinesOfBusiness Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
	
		CashServer.CheckFillInOrganizationSBankAccountByOwner(Object.Organization,
			Object.CompanyBankAccount, , Object.LineOfBusiness, Object.ForeignCurrencyTransaction);
		
		FillInSubordinatePropertiesForStatistics("Organization");
		
		UpdateInvoiceText();
			
		UpdatePurchaseForActivity();
		
	EndIf;
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Organization");
	DocumentCurrency = Object.Currency;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementServer()
	
	OperationWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
	ForeignCurrencyTransaction = Object.ForeignCurrencyTransaction;
	
	If Contract <> Object.Contract Then
		ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
		Contract = Object.Contract;
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Contract");
	
	If Object.ForeignCurrencyTransaction <> ForeignCurrencyTransaction Then
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount,
		Object.CounterpartyBankAccount);
	
	If Not ValueIsFilled(Object.CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
		ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = LocalAccountingCurrency;
		Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
			ParametersOfAccount);
	EndIf;
	
	FillInSubordinatePropertiesForStatistics("Contract");
	
	FillInVATTaxationPurchases();
	WhenChangingVATTaxationServer();
	
	ChangeDisplayOfTotals(ThisForm);
	UpdatePurchaseForActivity();
	
	If UseLinesOfBusiness Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
	WhenChangingKeyDetailsStatusOfEDO();
	
	ResponsiblePersonsServer.FillInManager_(Object);
	
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer(DocumentAmount)
	
	RecalculationParameters = PriceManagementSystem.ParametersForRecalculationOfTableAmountsONChangeOfExchangeRate(Object.PriceIncludesVAT, DocumentAmount, "Count");
	RecalculationParameters.RecalculateAutomaticDiscounts = False;
	RecalculationParameters.RecalculateManualDiscounts         = False;
	
	PriceManagementSystem.RecalculateTableAmountsONChangeOfExchangeRate(
		Object.Expenses,
		RecalculationParameters);
	
	For Each CurRow In Object.Expenses Do
		
		If CurRow.Count = 0 Then
			CurRow.Price = CurRow.Sum;
		EndIf;
		
		CurRow.AmountARAP = 0;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure WhenChangingCurrencyServer(NewCurrency)

	OldCurrency                = DocumentCurrency;
	DocumentDate               = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	CourseStructures = ARAPAccountingServer.ExchangeRatesForTranslation(ThisForm, OldCurrency, NewCurrency, LocalAccountingCurrency, DocumentDate);
	StructureOfOldCurrencyRates = CourseStructures.StructureOfOldCurrencyRates;
	StructureOfNewCurrencyRates  = CourseStructures.StructureOfNewCurrencyRates;
	
	PriceManagementSystem.ConvertTabularAmountsToCurrency(
		Object.Expenses,
		Object.PriceIncludesVAT,
		OldCurrency,
		NewCurrency,
		StructureOfOldCurrencyRates,
		StructureOfNewCurrencyRates,
		False,
		False,
		"Count");
		
	
	For Each CurRow In Object.Expenses Do
		
		If CurRow.Count = 0 Then
			CurRow.Price = CurRow.Sum;
		EndIf;
		
		CurRow.AmountARAP = 0;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure WhenChangingVATTaxationServer()
	
	VATAccountingLocalization.SetPriceIncludesVATOnVATTaxation(Object.PriceIncludesVAT, Object.VATTaxation);
	VATAccountingLocalization.SetAvailabilityPriceIncludesVATOnVATTaxation(Items.PriceIncludesVAT, Object.VATTaxation);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Expenses, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Object.Expenses,
		CachedValues);
	
	UpdateInvoiceText();

	VATAccountingERP.SetVisibilityOfCommandAndFillInVATRate(ThisObject, "ExpensesFillInVATRate");

EndProcedure

&AtServer
Procedure PriceIncludesVATOnChangeServer()
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Object.Expenses, StructureOfActions, CachedValues);
	
EndProcedure

&AtServer
Procedure WhenChangingDateServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject,"Date");
	
	UpdatePurchaseForActivity();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure LineOfBusinessOnChangeServer()
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		FillInDefaultContract();
		
	EndIf;
	UpdatePurchaseForActivity();
	
EndProcedure

&AtServer
Procedure OperationWithSelfEmployedWhenChangingOnServer()

	If ValueIsFilled(Object.Organization) Then
		FillInDefaultContract();
	EndIf;
	
	CashServerLocalization.OperationWithSelfEmployedPersonOnChange(ThisObject);
	WhenChangingVATTaxationServer();

EndProcedure

#EndRegion

#Region Other

&AtClientAtServerNoContext
Function FieldsForRecalculatingAmountOfNDSInTSLine(Form)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Form.Object);
	
	Return StructureOfRecalculationOfAmount;
	
EndFunction

&AtServer
Procedure OnReadCreateAtServer()
	
	UseDebitNotes = GetFunctionalOption("UseDebitNotes");
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date(1, 1, 1));
	
	ContractBusinessTransaction = GetBusinessTransaction(Object.BusinessOperation);
	SetVisibilityOfElementsByOperationServer();
	SetAvailabilityAgreements();
	SetAvailabilityOfItemsByStatusServer();
	
	DocumentCurrency = Object.Currency;
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CounterpartyLegEntInd = Common.ObjectAttributeValue(Object.Counterparty, "LegalEntityIndividual");
	
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
		
	PurchasesServer.SetContractAvailability(Object, Items.Contract.Enabled, Items.Contract.Visible);
	
	UpdateInvoiceText();
	
	UpdatePurchaseForActivity(False);
	PurchasesServer.FillInSelectionListNameOfIncomingDocument(ThisObject, Object.Counterparty);
	VATAccountingLocalization.SetAvailabilityPriceIncludesVATOnVATTaxation(Items.PriceIncludesVAT, Object.VATTaxation);
	
	VendorInvoiceServicesAndAssetsLocalization.FillInRNPTIsBeingRecordedAttribute(Object.Expenses);
	
	OperationWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
	CashServerLocalization.ConfigureElementsOfOperationsWithSelfEmployed(ThisObject);
	CashServerLocalization.SetStatusOfUploadingReceipts(ThisObject);
	
	SetCCDNumberSelectionParameters();
	
	SetCorrectionModeFromLastDate();
	
EndProcedure

&AtClientAtServerNoContext
Function GetBusinessTransaction(BusinessOperation)
	
	ContractBusinessTransaction = BusinessOperation;
	
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
	EndIf;
	
	Return ContractBusinessTransaction;
	
EndFunction

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenQuantityChanges(StructureOfActions, Form)
	
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(Form);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount", "Count");
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
EndProcedure

&AtServer
Procedure FillInDefaultContract()
	
	UseSalesCommission = GetFunctionalOption("UseSalesCommission");
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.ARAPCurrency;
		AddlParameters.Taxation = Object.VATTaxation;
		AddlParameters.LineOfBusiness = Object.LineOfBusiness;
		AddlParameters.ConsignmentSales25 = UseSalesCommission;
		AddlParameters.ContractWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
		Contract = PurchasesServer.GetDefaultContract(Object, 
															Object.BusinessOperation, 
															AddlParameters);
	Else
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.ARAPCurrency;
		AddlParameters.Taxation = Object.VATTaxation;
		AddlParameters.ConsignmentSales25 = UseSalesCommission;
		AddlParameters.ContractWithSelfEmployedPerson = Object.OperationWithSelfEmployedPerson;
		Contract = PurchasesServer.GetDefaultContract(Object, 
															Object.BusinessOperation, 
															AddlParameters);
	EndIf;

	If Object.Contract <> Contract Then
		Object.Contract = Contract;
		ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm,"Contract");
	
		WhenChangingAgreementServer();
		FillInVATTaxationPurchases();
		WhenChangingVATTaxationServer();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeDisplayOfTotals(Form)
	
	PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Form.Object.VATTaxation);
	If PurchaseIsSubjectToVAT Then
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
	Else
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure SetAvailabilityAgreements()
	If ValueIsFilled(Object.Partner) Then
		FilterParameters = New Structure("BusinessTransactions", Enums.BusinessTransactions.PurchaseFromSupplier);
		NumberOfSupplierAgreements  = PurchasesServerCall.GetNumberOfAgreementsWithSupplier(Object.Partner, FilterParameters);
		TMCommonUseClientServer.SetFormItemProperty(Items, "Terms", "Visible", NumberOfSupplierAgreements > 0);
	EndIf; 
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity(Fill = True)
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATActivityType(Object);
	If Fill Then
		VATAccountingERP.FillInTypeOfActivityVAT(
			Object.PurchaseForActivity, 
			FillParameters,
			VATAccountingCachedParameterValues);
	EndIf;
	VATAccountingERP.FillInActivitySelectionList(
		Items.PurchaseForActivity,
		Object.PurchaseForActivity,
		FillParameters, 
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Function PlaceSelectedRowsInStorage_(Val SelectedRows)
	
	TableOfRows = New ValueTable;
	TableOfRows.Columns.Add("DocumentRowNumber", New TypeDescription("Number", New NumberQualifiers(3,0)));
	TableOfRows.Columns.Add("Content", New TypeDescription("String", New StringQualifiers(1000)));
	TableOfRows.Columns.Add("DimensionOfExpenses", Documents.AllRefsType());
	TableOfRows.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
	TableOfRows.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
	TableOfRows.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
	TableOfRows.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	TableOfRows.Columns.Add("ExpenseItem", ChartsOfCharacteristicTypes.AllRefsType());
	
	For Each CurRow In SelectedRows Do
		TableRow = Object.Expenses.FindByID(CurRow);
		If TableRow = Undefined 
			Or TypeOf(TableRow.DimensionOfExpenses) <> Type("DocumentRef.VendorInvoice")
		Then
			Continue;
		EndIf;
		NewRow = TableOfRows.Add();
		FillPropertyValues(NewRow, TableRow);
		NewRow.DocumentRowNumber = TableRow.LineNumber;
	EndDo;
	
	If TableOfRows.Count() = 0 Then
		AddressInTempStorage =  Undefined;
	Else
		AddressInTempStorage = PutToTempStorage(TableOfRows, UUID);
	EndIf;
	Return AddressInTempStorage;
	
EndFunction

&AtServerNoContext
Function GoodsAreTraceable(CCDNumber)
	
	Return VendorInvoiceServicesAndAssetsLocalization.GoodsAreTraceable(CCDNumber);
	
EndFunction

&AtServer
Procedure TransferResultToTab(ClosingResult)
	
	ForDeletion = New Array();
	AllocationResult = GetFromTempStorage(ClosingResult.AddressInTempStorage);
	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	RowsToProcess = New Array;
	
	For Each TableRow In AllocationResult Do
		RowsArray = Object.Expenses.FindRows(New Structure("LineNumber",TableRow.DocumentRowNumber));
		If RowsArray.Count() <> 1 Then
			LineToFillIn = Object.Expenses.Add();
			WhenAddingExpenseLine(ThisObject, LineToFillIn);
		Else
			LineToFillIn = RowsArray[0];
		EndIf;
		FillPropertyValues(LineToFillIn, TableRow,,"Content");
		If TrimAll(LineToFillIn.Content) = "" Then
			LineToFillIn.Content = TableRow.Content;
		EndIf;
	
		If LineToFillIn.Count <> 0 Then
			StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", New Structure("QuantityName", "Count"));
		Else
			StructureOfActions.Delete("RecalculatePriceDiscountForAmountInPurchases");
			LineToFillIn.Price = LineToFillIn.Sum;
		EndIf;
		RowsToProcess.Add(LineToFillIn);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Expenses);
	
	ForDeletion = GetFromTempStorage(ClosingResult.LinesToDelete);
	For Each RowToDelete In ForDeletion Do
		Object.Expenses.Delete(RowToDelete.DocumentRowNumber - 1);
	EndDo;
		
EndProcedure

&AtServer
Procedure ReflectChangesToPaymentRules(ChangedBankingDetails)
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, ChangedBankingDetails, True);
	
EndProcedure

&AtServer
Procedure SetCorrectionModeFromLastDate()
	
	AdjustmentModeFromPreviousDate = ValueIsFilled(Object.ActualTransactionDate);
	Items.ActualTransactionDate.Enabled = AdjustmentModeFromPreviousDate;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsByOperationServer()
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.VendorInvoiceServicesAndAssets.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation,
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
		
	CashServer.SetVisibilityOfElementsByArray(
		Items,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	Items.AttributesForExpenseReportPrinting.Visible = (Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
EndProcedure

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
	Return; // WE have an empty handler
	
EndProcedure

#EndRegion

&AtClient
Procedure ExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	TableRow = Items.Expenses.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.Expenses.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenQuantityChanges(StructureOfActions, ThisForm);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpensesAssetsLiabilitiesDimensionOnChange(Item)
	IncomeAndExpensesClientServer.AssetsLiabilitiesDimensionOnChange(ThisObject, Item);
EndProcedure

&AtClientAtServerNoContext
Procedure WhenAddingExpenseLine(Form, String)
	
	VATTaxation = Form.Object.VATTaxation;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(Form, String, "Object.Expenses");
	If VATTaxation <> PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT") Then
		String.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetHeadingIncomeExpenseItem()
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		Items.ExpensesExpenseItem.Title = NStr("vi = 'Dạng chi phí';
												|ru = 'Статья расходов';
												|en = 'Expense item'; fa = 'قلم هزینه';
												|it = 'Voce di spese';
												|pl = 'Rodzaj kosztu';
												|tr = 'Gider kalemi'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateInvoiceText()
	
	RegistrationParameters = ParametersForRegisteringInvoicesReceived(Object);
	InvoicesReceivedOnBasisOf = VATAccountingERP.InvoicesReceivedOnBasisOf(RegistrationParameters);
	
	InvoiceTextReceived = InvoicesReceivedOnBasisOf.Presentation;
	
EndProcedure

&AtClientAtServerNoContext
Function ParametersForRegisteringInvoicesReceived(Object)
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtServer
Procedure PaymentCreditedServer(EventName, Parameter)
	
	ARAPAccountingFormWork.NotificationProcessing(ThisForm, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm);
EndProcedure

&AtServer
Procedure FillInVATTaxationPurchases()
	
	FillParameters = Documents.VendorInvoiceServicesAndAssets.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInVATTaxationPurchases(Object.VATTaxation, FillParameters, VATAccountingCachedParameterValues);
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

#Region ControlOfInconsistentChanges

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	ItemArray.Add("Date");
	
	// Header Controls
	ItemArray.Add("Partner");
	ItemArray.Add("Terms");
	ItemArray.Add("Contract");
	
	ItemArray.Add("PriceIncludesVAT");
	ItemArray.Add("Organization");
	ItemArray.Add("Counterparty");
	ItemArray.Add("VATTaxation");
	ItemArray.Add("PaymentMethod");
	ItemArray.Add("ARAPObjectSettings");
	
	ItemArray.Add("BusinessOperation");
	ItemArray.Add("Department");
	ItemArray.Add("PurchaseForActivity");
	
	ItemArray.Add("Expenses");
	
	ItemArray.Add("ExpensesSetAnExpenseItem");
	ItemArray.Add("ExpensesFillInTheDepartment");
	ItemArray.Add("ExpensesDistributeToReceipts");

	ItemArray.Add("ExpensesSplitRow");
	ItemArray.Add("ExpensesFillInVATRate");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtServerNoContext
Procedure CheckForAdjustmentsAndInvoices(Ref, ThereAreAdjustingEntries, ThereAreInvoices_1)
	
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
	
EndProcedure

&AtServerNoContext
Function HaveRightToAddAdjustments()
	
	Return AccessRight("Insert", Metadata.Documents.PurchaseAdjustment);
	
EndFunction

&AtClient
Function PerformChecksBeforeChangingStatus()
	
	Var ThereAreInvoices_1;
	
	PropsCanBeChanged = False;
	
	AdditionalParameters = New Structure;
	Notification = New CallbackDescription(
			"QuestionResultCompletion", ThisObject, AdditionalParameters);
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined
		Or StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected Then
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	ClearMessages();
	
	CheckForAdjustmentsAndInvoices(Object.Ref, ThereAreAdjustingEntries, ThereAreInvoices_1);
	
	If Not HaveRightToAddAdjustments() And (ThereAreAdjustingEntries Or ThereAreInvoices_1) And UseDebitNotes Then
		
		If ThereAreAdjustingEntries Then
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã nhập điều chỉnh mua hàng.
				|Không đủ quyền để tạo điều chỉnh tiếp nhận.';
				|ru = 'На основании документа введена корректировка приобретения.
				|Недостаточно прав для создания корректировки поступления.';
				|en = 'Purchase adjustment is generated from base document.
				|Insufficient rights to create the purchase adjustment.'; fa = 'Purchase adjustment is generated from base document.
				|Insufficient rights to create the purchase adjustment.';
				|it = 'Sulla base del documento è stato immessa una rettifica di acquisizione.
				|Non ci sono diritti sufficienti per creare la rettifica di arrivo.';
				|pl = 'Na podstawie tego dokumentu wprowadzono korektę zakupu. 
				| Brak wystarczających uprawnień do korekty wpływu.';
				|tr = 'Belge temelinde bir satın alma düzeltmesi girilmiştir. 
				|Bir gelir düzeltmesi oluşturmak için yeterli hak verilmemiştir.'");
		Else
			MessageText = NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT.
				|Không đủ quyền để tạo điều chỉnh tiếp nhận.';
				|ru = 'На основании документа зарегистрирован счет-фактура.
				|Недостаточно прав для создания корректировки поступления.';
				|en = 'Based on the document the tax invoice was registered.
				|Insufficient rights to adjust the receipt.'; fa = 'Based on the document the tax invoice was registered.
				|Insufficient rights to adjust the receipt.';
				|it = 'Sulla base del documento è stata registrata una fattura.
				|Non ci sono diritti sufficienti per creare la rettifica di arrivo.';
				|pl = 'Na podstawie dokumentu zarejestrowano fakturę.
				|Niewystarczające uprawnienia do wykonania korekty wpływu.';
				|tr = 'Temel belgeye bir fatura kaydedilmiştir. 
				|Bir makbuz düzeltmesi oluşturmak için yetersiz haklar.'");
		EndIf;
		
		CommonClientServer.MessageToUser(MessageText);
		
	ElsIf ThereAreAdjustingEntries And UseDebitNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzenleme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ, đã nhập điều chỉnh mua sắm.
				|Cấm thay đổi chứng từ gốc.';
				|ru = 'На основании документа введена корректировка приобретения.
				|Изменение исходного документа запрещено.';
				|en = 'Purchase adjustment is generated from base document.
				|Editing the original document is not allowed.'; fa = 'Purchase adjustment is generated from base document.
				|Editing the original document is not allowed.';
				|it = 'Sulla base del documento è stato inserita una rettifica di acquisto.
				|La modifica del documento originale è vietata.';
				|pl = 'Na podstawie dokumentu jest wprowadzono korektę zakupu.
				|Zmiana dokumentu źródłowego jest zabroniona.';
				|tr = 'Temel belgeye bir satın alma düzeltmesi girilmiştir.
				| Orijinal belge değiştirilemez.'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
		
	ElsIf ThereAreInvoices_1 And UseDebitNotes Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add("EnterTheAdjustment", NStr("vi = 'Nhập điều chỉnh';
													|ru = 'Ввести корректировку';
													|en = 'Enter the adjustment'; fa = 'Enter the adjustment';
													|it = 'Inserire rettifica';
													|pl = 'Wprowadź korektę';
													|tr = 'Bir düzenleme yapın'"));
		ButtonsList.Add("UndoChanges", NStr("vi = 'Hủy bỏ';
											|ru = 'Отмена';
											|en = 'Cancel'; fa = 'انصراف';
											|it = 'Annulla';
											|pl = 'Cancel';
											|tr = 'İptal'"));
		
		ShowQueryBox(
			Notification,
			NStr("vi = 'Trên cơ sở chứng từ đã ghi nhận hóa đơn GTGT. Nhập điều chỉnh tiếp nhận
				|để xuất hóa đơn GTGT đã chỉnh sửa?';
				|ru = 'На основании документа зарегистрирован счет-фактура. Ввести корректировку поступления
				|для выставления исправленных счетов-фактур?';
				|en = 'Based on the document the tax invoice was registered.
				|Adjust the receipt to issue corrected tax invoices?'; fa = 'Based on the document the tax invoice was registered.
				|Adjust the receipt to issue corrected tax invoices?';
				|it = 'Sulla base del documento è stata registrata una fattura. Effettuare una rettifica di arrivo
				|per l''emissione delle fatture corrette?';
				|pl = 'Na podstawie dokumentu zarejestrowano fakturę. Dokonać korekty rachunku wpływu
				|w celu wystawienia skorygowanych faktur?';
				|tr = 'Belge temelinde bir fatura kaydedilmiştir. Değiştirilmiş faturaları düzenlemek için 
				|bir gelir düzeltmesi girilsin mi?'"),
			ButtonsList,
			,
			"EnterTheAdjustment");
			
	Else
		
		RunCallback(Notification, "ChangeAttribute");
		PropsCanBeChanged = True;
		
	EndIf;
	
	Return PropsCanBeChanged;
	
EndFunction

&AtClient
Procedure QuestionResultCompletion(ResponseCode, AdditionalParameters) Export
	
	If ResponseCode = "EnterTheAdjustment" Then // "Enter an adjustment"
		OpenForm("Document.PurchaseAdjustment.ObjectForm", New Structure("Basis", Object.Ref));
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInVATRateCompletion(VATRate, AdditionalParameters) Export

	If VATRate = Undefined Then
		Return;
	EndIf;

	FillInVATRateOnServer(VATRate, CachedValues);

	ChangeDisplayOfTotals(ThisObject);

EndProcedure

&AtServer
Procedure FillInVATRateOnServer(VATRate, CachedValues)

	StructureOfRecalculationOfAmount = FieldsForRecalculatingAmountOfNDSInTSLine(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");

	SelectedRows = ProcessingOfTabularFormsClientServer.CollectionItems(
		Object.Expenses, Items.Expenses.SelectedRows);
	
	For Each LineOfATabularSection In SelectedRows Do
		LineOfATabularSection.VATRate = VATRate;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		SelectedRows,
		StructureOfActions,
		Object.Expenses,
		CachedValues);

	UpdateInvoiceText();

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If Not PerformChecksBeforeChangingStatus() Then
		TMCommonUseClient.ReturnPreviousPropsValue(ThisForm, Item);
		Return;
	Else
		TMCommonUseClient.SaveAttributeValue(ThisForm, Item);
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_Clicking_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Click.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandlePushEvent(Item);
	EndIf;
	
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If Not PerformChecksBeforeChangingStatus() Then
		Return;
	EndIf;
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(StructureOfActionsControlOfNonAgreedChanges.AttributesValues[Item.Name], Item.CurrentData);
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;

EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	If Item.Name = "Date" Then
		DateOnChange(Item);
	ElsIf Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Terms" Then
		TermsOnChange(Item);
	ElsIf Item.Name = "Contract" Then
		ContractOnChange(Item);
	ElsIf Item.Name = "PriceIncludesVAT" Then
		PriceIncludesVATOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "VATTaxation" Then
		VATTaxationOnChange(Item);
	ElsIf Item.Name = "BusinessOperation" Then
		BusinessOperationOnChange(Item);
	ElsIf Item.Name = "ExpensesCount" Then
		ExpensesCountOnChange(Item);
	ElsIf Item.Name = "ExpensesPrice" Then
		ExpensesPriceOnChange(Item);
	ElsIf Item.Name = "ExpensesSum" Then
		ExpensesSumOnChange(Item);
	ElsIf Item.Name = "ExpensesAmountARAP" Then
		ExpensesAmountARAPOnChange(Item);
	ElsIf Item.Name = "ExpensesVATRate" Then
		ExpensesVATRateOnChange(Item);
	ElsIf Item.Name = "ExpensesVATAmount" Then
		ExpensesVATAmountOnChange(Item);
	ElsIf Item.Name = "ExpensesExpenseItem" Then
		ExpensesExpenseItemOnChange(Item);
	ElsIf Item.Name = "ExpensesCCDNumber" Then
		FillInTraceabilityAttributesInExpenseLine();
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisObject, Item);
	EndIf;
EndProcedure

// Parameters:
//	Command - FormCommand - 
&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	If Command.Name = "SplitRow" Then
		SplitRow(Command);
	ElsIf Command.Name = "SetAnExpenseItem" Then
		SetAnExpenseItem(Command);
	ElsIf Command.Name = "FillInTheDepartment" Then
		FillInTheDepartment(Command);
	ElsIf Command.Name = "DistributeToReceipts" Then
		DistributeToReceipts(Command);
	ElsIf Command.Name = "FillInVATRate" Then
		FillInVATRate(Command);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	EndIf;
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandlePushEvent(Item)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

// Parameters:
//	Item - FormGroup, FormTable, FormField, FormButton - FormItem
&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure GenerateStatement(Command)
	
	Filter = New Structure;
	Filter.Insert("Organization", Object.Organization);
	ReportPeriod = New StandardPeriod();
	ReportPeriod.StartDate = BegOfDay(Object.Date);
	ReportPeriod.EndDate = EndOfDay(Object.Date);
	Filter.Insert("Period", ReportPeriod);
	FormParameters = New Structure("Filter, GenerateOnOpen, VariantKey", Filter, True, "Main");
	AccountingForTraceableGoodsClientLocalization.GenerateStatement(FormParameters);
	
EndProcedure

&AtClient
Procedure FillInTraceabilityAttributesInExpenseLine()
	
	CurrentData = Items.Expenses.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.AccountingForTheRNPTIsMaintained = GoodsAreTraceable(CurrentData.CCDNumber);
	
EndProcedure

#EndRegion

&AtClient
Procedure AfterUploadingSelfEmployedReceipt(CashRegisterReceiptData, AdditionalParameters) Export

	AfterUploadingSelfEmployedReceiptOnServer(CashRegisterReceiptData);
	FilesOperationsClient.NotificationProcessing(ThisObject, "Write_File");

EndProcedure

&AtServer
Procedure AfterUploadingSelfEmployedReceiptOnServer(Receipt)

	CashServerLocalization.SetStatusOfUploadingReceipts(ThisObject);

EndProcedure

&AtServer
Procedure SetCCDNumberSelectionParameters()
	
	ArrayOfCCDNumberParameters = New Array;
	
	ArrayOfCCDTypes = New ValueList;
	ArrayOfCCDTypes.Add(Enums.CCDNumberTypes.ProductBatchIDNumber);
	ArrayOfCCDTypes.Add(Enums.CCDNumberTypes.KitRNPT);
	
	ArrayOfCCDNumberParameters.Add(
		New ChoiceParameter(
			"ListOfCCDTypes",
			ArrayOfCCDTypes));
				
	Items.ExpensesCCDNumber.ChoiceParameters = New FixedArray(ArrayOfCCDNumberParameters);
	
EndProcedure

&AtServer
Procedure FillInSubordinatePropertiesForStatistics(ParentPropsName)
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(Object, ParentPropsName);
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
