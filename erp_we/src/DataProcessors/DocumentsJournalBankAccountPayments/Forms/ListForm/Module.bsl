
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// DynamicListsSettings
	InitiateDynamicListSettings();
	// End DynamicListsSettings
	
	ListOfDocumentsAutoUpdateMode = True;
	
	If TypeOf(Parameters.QuickFilterStructure) = Type("Structure") Then
		QuickFilterStructure = New Structure;
		QuickFilterStructure.Insert("Organization",             Catalogs.Companies.EmptyRef());
		QuickFilterStructure.Insert("BankAccountSelection",     Catalogs.CompaniesBankAccounts.EmptyRef());
		QuickFilterStructure.Insert("CounterpartyPresentation", "");
		FillPropertyValues(QuickFilterStructure, Parameters.QuickFilterStructure);
	
		Organization             = QuickFilterStructure.Organization;
		BankAccountSelection     = QuickFilterStructure.BankAccountSelection;
		CounterpartyPresentation = QuickFilterStructure.CounterpartyPresentation;
		
		If ValueIsFilled(Organization) Then
			OrganizationOnChangeServer(False);
		EndIf;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	If Parameters.Property("FormAssignmentKey") And Not IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = Parameters.FormAssignmentKey;
	Else
		PurposeUseKey = "BankAccountPayments";
	EndIf;
	
	If PurposeUseKey = "BankAccountPayments" Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	URL = "e1cib/app/DataProcessor.DocumentsJournalBankAccountPayments";
	
	SetPrivilegedMode(True);
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForReceiptsFromBankForAcquiring();
	SetPrivilegedMode(False);
	
	InitializeBankingDetails();
	CompleteDocumentCreationCommands();
	
	ListOfPayment.Parameters.SetParameterValue("BeginOfPeriod", BeginOfPeriod);
	ListOfPayment.Parameters.SetParameterValue("EndOfPeriod",
		?(ValueIsFilled(EndOfPeriod), EndOfDay(EndOfPeriod), EndOfDay(Date(3999, 12, 31))));
	
	SetVisibility1();
	
	If ThereIsAccessToAdmission() Then
		ToRegisterReference.Add("ToReceive");
	EndIf;
	
	If ThereIsAccessToPayment() Then
		ToRegisterReference.Add("ForPaymentByTransfer");
	EndIf;
	
	If ThereIsAccessToCashDeposit() Then
		ToRegisterReference.Add("CreditingDS");
	EndIf;
	
	UpdateHyperlinksToLayout();
	
	SetDynamicListSelection();
	SaveWorkingValuesOfFormFields(True);
	
	DocumentTypes = New Array();
	DocumentTypes.Add("Document.BankAccountReceiptNote");
	DocumentTypes.Add("Document.BankAccountIssue");
	DocumentTypes.Add("Document.CashAccountReceiptNote");
	DocumentTypes.Add("Document.CashVoucher");
	
	ConfigureDocumentManagementButtons(DocumentTypes);
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListOfPayment,
		DocumentTypes);
	
	DocumentTypesUsed = New Array;
	DocumentTypesUsed.Add(Type("DocumentRef.BankAccountReceiptNote"));
	DocumentTypesUsed.Add(Type("DocumentRef.BankAccountIssue"));
	DocumentTypesUsed.Add(Type("DocumentRef.CashAccountReceiptNote"));
	DocumentTypesUsed.Add(Type("DocumentRef.CashVoucher"));
	
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListOfPayment,
		DocumentTypes);
	
	Items.UploadAStatement.Visible = AccessRight("Use", Metadata.DataProcessors.EDIWithBanks);
	Items.ToUploadToTheBank.Visible = AccessRight("Use", Metadata.DataProcessors.EDIWithBanks);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListOfPaymentCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ReglGroupVerification);
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing, AdditionalParameters);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	BeginOfPeriod             = Settings.Get("BeginOfPeriod");
	EndOfPeriod              = Settings.Get("EndOfPeriod");
	
	BankAccountSelection       = Settings.Get("BankAccountSelection");
	ProcessedByBankFilter      = Settings.Get("ProcessedByBankFilter");
	
	ListOfDocumentsAutoUpdateMode = True;
	
	ListAutoUpdateMode = Settings.Get("ListOfDocumentsAutoUpdateMode");
	
	If Not ListAutoUpdateMode = Undefined Then
		ListOfDocumentsAutoUpdateMode = ListAutoUpdateMode;
	EndIf;
	
	
	UpdateHyperlinksToLayout();
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(
				New CallbackDescription("NotificationProcessingCompletion", ThisObject, New Structure("EventName", EventName)),
				EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
			Return;
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "UpdateLogOfDocumentsNonCashPayments" Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListOfPayment", Parameter);
		// End DynamicListsSettings
		
	EndIf;	
	
	HandlingFragmentAlerts(EventName, Parameter);
	
EndProcedure

&AtClient
Procedure NotificationProcessingCompletion(Result, AdditionalParameters) Export
	
	EventName = AdditionalParameters.EventName;
	
	HandlingFragmentAlerts(EventName);
	
EndProcedure

&AtClient
Procedure HandlingFragmentAlerts(Val EventName, Parameter = Undefined)
	
	NamesOfUpdateEvents = New Array;
	NamesOfUpdateEvents.Add("Write_BankAccountIssue");
	NamesOfUpdateEvents.Add("Write_CashVoucher");
	NamesOfUpdateEvents.Add("Write_BankAccountReceiptNote");
	NamesOfUpdateEvents.Add("Write_CashAccountReceiptNote");
	NamesOfUpdateEvents.Add("Write_PaymentCardTransaction");
	NamesOfUpdateEvents.Add("Write_PaymentRequest");
	NamesOfUpdateEvents.Add("Write_CashTransferReferenceOrder");
	NamesOfUpdateEvents.Add("Upload_ExchangeWithBanks");
	NamesOfUpdateEvents.Add("Write_DocumentPayments");
	
	NamesOfPaymentListUpdateEvents = New Array;
	NamesOfPaymentListUpdateEvents.Add("Write_BankAccountIssue");
	NamesOfPaymentListUpdateEvents.Add("Write_CashVoucher");
	NamesOfPaymentListUpdateEvents.Add("Write_BankAccountReceiptNote");
	NamesOfPaymentListUpdateEvents.Add("Write_CashAccountReceiptNote");
	NamesOfPaymentListUpdateEvents.Add("Conducting_Storno");
	NamesOfPaymentListUpdateEvents.Add("Write_ReversingEntry");
	NamesOfPaymentListUpdateEvents.Add("Write_DocumentPayments");
	
	If NamesOfUpdateEvents.Find(EventName) <> Undefined Then
		UpdateTotals();
	EndIf;
	
	If NamesOfPaymentListUpdateEvents.Find(EventName) <> Undefined Then
		
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("ListOfPayment", Parameter);
		// End DynamicListsSettings
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer(ChangeFilter = True)
	
	If Not GetFunctionalOption("UseMultipleBankAccounts") Then
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		BankAccountSelection = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
	EndIf;
	
	If ChangeFilter Then
		SetDynamicListSelection();
		UpdateHyperlinksToLayout();
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountSelectionOnChange(Item)
	
	BankAccountSelectionOnChangeServer();
	
EndProcedure

&AtServer
Procedure BankAccountSelectionOnChangeServer()
	
	SetDynamicListSelection();
	UpdateHyperlinksToLayout();
	
EndProcedure

&AtClient
Procedure CounterpartySelection_OnChange(Item)
	
	CounterpartySelection_OnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartySelection_OnChangeServer()
	
	UpdateHyperlinksToLayout();
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure CounterpartySelection_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text)
		And (StrLen(Text) = 10 Or StrLen(Text) = 12)
		And StringFunctionsClientServer.OnlyNumbersInString(Text) Then
		
		ContractorsByTin = ContractorsByTin(Text);
		If ContractorsByTin.Count() Then
			ChoiceData = New ValueList;
			ChoiceData.LoadValues(ContractorsByTin);
			StandardProcessing = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ContractorsByTin(TIN)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Description
	|FROM
	|	Catalog.Counterparties
	|WHERE
	|	TIN = &TIN
	|UNION ALL
	|SELECT
	|	Description
	|FROM
	|	Catalog.Companies
	|WHERE
	|	TIN = &TIN
	|UNION ALL
	|SELECT
	|	Description
	|FROM
	|	Catalog.Persons
	|WHERE
	|	TIN = &TIN
	|";
	
	Query.SetParameter("TIN", TIN);
	
	Return Query.Execute().Unload().UnloadColumn("Description");
	
EndFunction

&AtServer
Procedure ListOfPaymentOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListOfPayment");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfPayment

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If BeginOfPeriod > EndOfPeriod And ValueIsFilled(EndOfPeriod) Then
		BeginOfPeriod = EndOfPeriod;
	EndIf;
	
	PeriodForChangesOnServer();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If EndOfPeriod < BeginOfPeriod And ValueIsFilled(EndOfPeriod) Then
		EndOfPeriod = BeginOfPeriod;
	EndIf;
	
	PeriodForChangesOnServer();
	
EndProcedure

&AtServer
Procedure PeriodForChangesOnServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure SelectPeriod(Command)
	
	Notification = New CallbackDescription(
		"SelectPeriodCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		ThisObject,
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"),
		Notification);
		
EndProcedure

&AtClient
Procedure SelectPeriodCompletion(Period, AdditionalParameters) Export
	
	If Period <> Undefined Then
		PeriodForChangesOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessedByBankFilterOnChange(Item)
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure ListOfPaymentSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.ListOfPayment);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.ListOfPayment);
	
EndProcedure

&AtClient
Procedure ListOfPaymentOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure ListOfPaymentBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		
		PostfixOfTheCommand = PostfixOfBusinessTransactionCommand(PredefinedValue("Enum.BusinessTransactions.PaymentToVendor"));
		
		If PostfixOfTheCommand <> Undefined Then
			CreateCharge(Commands["CreateCharge" + PostfixOfTheCommand]);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfPaymentBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListOfPaymentBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region BankFeeds

&AtClient
Procedure UploadingBankFeeds(Command)

	//++ WE
	OpenForm("DataProcessor.EDIWithBanksBankFeeds.Form.ExportPaymentDocuments",
		New Structure("BankAccount", BankAccountSelection),);
	//-- WE

	Return;
	
EndProcedure

&AtClient
Procedure LoadingBankFeeds(Command)
	
	//++ WE
	OpenForm("DataProcessor.EDIWithBanksBankFeeds.Form.ImportTransactions",
		New Structure("BankAccount", BankAccountSelection),
		Items.ListOfPayment);
	//-- WE
	
	Return;
	
EndProcedure

&AtClient
Procedure SyncBankFeeds(Command)

	//++ WE
	ExchangeWithBankFeedsServiceClient.SyncBankFeeds(ThisObject, BeginOfPeriod, EndOfPeriod);
	//-- WE
	
	Return;
	
EndProcedure

#EndRegion

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	NameOfFormToSubmit = "";
	
	If FormattedStringURL = "ToReceive" Then
		NameOfFormToSubmit = "DataProcessor.DocumentsJournalBankAccountPayments.Form.ToReceive";
	ElsIf FormattedStringURL = "AmountDue" Then
		If UsePaymentRequests Then
			NameOfFormToSubmit = "DataProcessor.DocumentsJournalBankAccountPayments.Form.PaymentRequests";
		Else
			NameOfFormToSubmit = "DataProcessor.DocumentsJournalBankAccountPayments.Form.OrdersPendingPayment";
		EndIf;
	ElsIf FormattedStringURL = "CreditingDS" Then
		NameOfFormToSubmit = "Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.Form.DocumentListForm";
	EndIf;
	
	If ValueIsFilled(NameOfFormToSubmit) Then
		
		StandardProcessing = False;
		
		FormParameters = New Structure;
		QuickFilterStructure = New Structure;
		QuickFilterStructure.Insert("Organization", Organization);
		QuickFilterStructure.Insert("BankAccountSelection", BankAccountSelection);
		QuickFilterStructure.Insert("CounterpartyPresentation", CounterpartyPresentation);
		FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
		
		OpenForm(NameOfFormToSubmit, FormParameters, ThisObject, True);
	EndIf;
	
EndProcedure

#Region CreatingDocuments

// Executes the document creation command
//
// Parameters:
//    Command - FormCommand - form command
&AtClient
Procedure CreateReceipt(Command)
	
	NameOfBusinessTransaction = Right(Command.Name, StrLen(Command.Name) - StrLen("CreateReceipt"));
	
	StructureFilter = New Structure;
	StructureFilter.Insert("BusinessOperation", FormSettings.BusinessTransactionsIncomeOperations[NameOfBusinessTransaction]);
	StructureFilter.Insert("BankAccount", BankAccountSelection);
	StructureFilter.Insert("Organization", Organization);
	StructureFilter.Insert("Currency", AccountCurrency);
	
	If StructureFilter.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashDepositToBankAccount") Then
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.CashVoucher.ObjectForm", ParametersStructure1, ThisForm);
	Else
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.BankAccountReceiptNote.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

// Executes the document creation command
//
// Parameters:
//    Command - FormCommand - form command
&AtClient
Procedure CreateCharge(Command)
	
	NameOfBusinessTransaction = Right(Command.Name, StrLen(Command.Name) - StrLen("CreateCharge"));
	
	StructureFilter = New Structure;
	StructureFilter.Insert("BusinessOperation", FormSettings.BusinessTransactionsWriteOffOperations[NameOfBusinessTransaction]);
	StructureFilter.Insert("BankAccount", BankAccountSelection);
	StructureFilter.Insert("Organization", Organization);
	StructureFilter.Insert("Currency", AccountCurrency);
	
	If StructureFilter.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromBank") Then
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.CashAccountReceiptNote.ObjectForm", ParametersStructure1, ThisForm);
	Else
		ParametersStructure1 = New Structure("Basis", StructureFilter);
		OpenForm("Document.BankAccountIssue.ObjectForm", ParametersStructure1, ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure ListPost(Command)
	
	ParametersOfUpdate = OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListOfPayment");
	TMCommonUseClient.PostDocuments(Items.ListOfPayment, Title, ParametersOfUpdate);
	
	If ParametersOfUpdate.UpdateList Then
		Notify("Write_DocumentPayments");
	EndIf;
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	ParametersOfUpdate = OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "ListOfPayment");
	TMCommonUseClient.UndoPosting(Items.ListOfPayment, Title, ParametersOfUpdate);
	
	If ParametersOfUpdate.UpdateList Then
		Notify("Write_DocumentPayments");
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	// DynamicListsSettings
	ListName = "ListOfPayment";
	UpdateList = OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments(ThisObject, ListName);
	// End DynamicListsSettings
	
	If UpdateList Then
		CallbackOnCompletion = CashClient.NotificationToListOfNonCashPaymentsAfterChangingDeletionMark(
			Items.ListOfPayment);
	Else
		CallbackOnCompletion = Undefined;
	EndIf;
	
	TMCommonUseClient.SetDeletionMark(Items.ListOfPayment, Title, CallbackOnCompletion,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, ListName));
	
EndProcedure

&AtClient
Procedure SetUpABankTransaction(Command)

	Item = Items.ListOfPayment;	
	Rows = Item.SelectedRows;
	References = CheckGetLinksHighlightedInList(Item, Rows);
	If References.Count() = 0 Then
		Return;
	EndIf;
	
	NumberOfDocks = References.Count();
	For Indus = 1 To NumberOfDocks Do
		If TypeOf(References[NumberOfDocks - Indus]) = Type("DocumentRef.CashAccountReceiptNote")
			Or TypeOf(References[NumberOfDocks - Indus]) = Type("DocumentRef.CashVoucher") Then
			References.Delete(NumberOfDocks - Indus);
		EndIf;
	EndDo;
	
	ClearMessages();
	
	If References.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
								|ru = 'Команда не может быть выполнена для указанного объекта!';
								|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
								|it = 'Il comando non può essere eseguito per oggetto indicato!';
								|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
								|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	WhenInstallingBank = New CallbackDescription("WhenInstallingBank", ThisForm, References);
	ShowInputDate(WhenInstallingBank, CurrentDate(), NStr("vi = 'Hãy chỉ ra ngày thực hiện bởi ngân hàng';
															|ru = 'Укажите дату проведения банком';
															|en = 'Specify a date of processing by bank'; fa = 'Specify a date of processing by bank';
															|it = 'Indicate la data della registrazione dalla banca';
															|pl = 'Wprowadź datę zatwierdzenia przez bank';
															|tr = 'Banka ile kayıt tarihini belirt'"), DateFractions.Date);
	
EndProcedure

&AtClient
Procedure WhenInstallingBank(BankPostingDate, DocumentsArray) Export
	
	If BankPostingDate <> Undefined Then
		
		ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
			DocumentsArray,
			"ProcessedByBank",
			New Structure("BankPostingDate", BankPostingDate));
		
		// DynamicListsSettings
		UpdateDocumentListDataWithTimeMeasurement("ListOfPayment", True);
		// End DynamicListsSettings
		
		UpdateTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExportToBank(Command)
	
	OpenForm("DataProcessor.EDIWithBanks.Form.ExportToBank",
		New Structure("BankAccount", BankAccountSelection),
		Items.ListOfPayment);
	
EndProcedure

&AtClient
Procedure ImportStatement(Command)
	
	OpenForm("DataProcessor.EDIWithBanks.Form.ImportStatement",
		New Structure("BankAccount", BankAccountSelection),
		Items.ListOfPayment);
	
EndProcedure

&AtClient
Procedure DailyReport(Command)
	
	FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen, ReportOptionsCommandsVisibility");
	FormParameters.GenerateOnOpen = True;
	FormParameters.ReportOptionsCommandsVisibility = True;
	
	FormParameters.PurposeUseKey = "DailyReport";
	
	Filter = New Structure;
	If ValueIsFilled(BeginOfPeriod) Then
		Filter.Insert("ReportPeriod", New StandardPeriod(BeginOfPeriod, EndOfPeriod));
	EndIf;
	If ValueIsFilled(BankAccountSelection) Then
		Filter.Insert("BankAccount", BankAccountSelection);
		Filter.Insert("Currency", AccountCurrency);
		FormParameters.VariantKey = "StatementByDayOneAccount";
	Else
		
		If ValueIsFilled(Organization) Then
			Filter.Insert("Organization", Organization);
		EndIf;
		
		FormParameters.VariantKey = "DailyReport";
		
	EndIf;
	FormParameters.Filter = Filter;
	
	OpenForm("Report.BankStatementReconciliation.Form", FormParameters, ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	ClearMessages();
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.ListOfPayment);

EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.ListOfPayment, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListOfPayment);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.ListOfPayment);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure DownloadPaymentsFromYandexCheckout(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure MailsToBank(Command)
	
	Return;
	
EndProcedure

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("ListOfPayment");
	// End DynamicListsSettings
	
	UpdateTotals();
	
EndProcedure

#EndRegion

#Region Private

//++ WE
&AtClient
Procedure ClosingPaymentConfirmationFormInSaltEdge(Result, AdditionalParameters) Export
	
	ExchangeWithBankFeedsServiceClient.CheckStatusOfPaymentsAfterSending(ThisObject, AdditionalParameters);	
	
	Notify("UpdateLogOfDocumentsNonCashPayments",, ThisObject);
	
EndProcedure	
//-- WE

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
EndProcedure

&AtServer
Procedure InitializeBankingDetails()
	
	UsePayroll                   = Constants.UsePayroll.Get();
	UsePaymentRequests  = GetFunctionalOption("UsePaymentRequests");
	MultipleCurrentAccounts                         = GetFunctionalOption("UseMultipleBankAccounts");
	
	If Not MultipleCurrentAccounts Then
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		BankAccountSelection = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
	EndIf;
	
	If Not ValueIsFilled(BeginOfPeriod)
		Or Not ValueIsFilled(EndOfPeriod) Then
		BeginOfPeriod = BegOfDay(CurrentSessionDate());
		EndOfPeriod = EndOfDay(CurrentSessionDate());
	EndIf;
	
	If Not ValueIsFilled(ProcessedByBankFilter) Then
		ProcessedByBankFilter = "AllPayments_";
	EndIf;
	
	ListOfPayment.Parameters.SetParameterValue("IDOfTheObjectReceiptOfNonCashDS",
		Common.MetadataObjectID("Document.BankAccountReceiptNote"));
	ListOfPayment.Parameters.SetParameterValue("TheObjectIDOfTheNonCashWriteOffOfDS",
		Common.MetadataObjectID("Document.BankAccountIssue"));
	ListOfPayment.Parameters.SetParameterValue("IDOfThePKOObject",
		Common.MetadataObjectID("Document.CashAccountReceiptNote"));
	ListOfPayment.Parameters.SetParameterValue("IDOfTheRKOObject",
		Common.MetadataObjectID("Document.CashVoucher"));
		
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	VisibilityOfElements = New Map;
	
	ItemArray = New Array;
	ItemArray.Add("ListOfPaymentCurrency");
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleCurrencies"));
	
	ItemArray = New Array;
	ItemArray.Add("BankAccountSelection");
	VisibilityOfElements.Insert(ItemArray, MultipleCurrentAccounts);
	
	ItemArray = New Array;
	ItemArray.Add("CompanyFilter");
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleCompanies"));
	
	// BankFeeds
	BankFeedsIsAvailable = GetFunctionalOption("UseBankFeedsExchange");	
	ItemArray = New Array;
	ItemArray.Add("LoadingBankFeeds");
	ItemArray.Add("UploadingBankFeeds");
	ItemArray.Add("SyncBankFeeds");
	VisibilityOfElements.Insert(ItemArray, BankFeedsIsAvailable);
	// the end of BankFeeds
	
	For Each MapItem In VisibilityOfElements Do
		For Each TagName In MapItem.Key Do
			Items[TagName].Visible = MapItem.Value;
		EndDo;
	EndDo;
	
	ThereIsAccessToChange = AccessRight("Update", Metadata.Documents.BankAccountReceiptNote)
		And AccessRight("Update", Metadata.Documents.BankAccountIssue);
	Items.ListCopy.Visible =
		AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote)
		And AccessRight("Insert", Metadata.Documents.BankAccountIssue);
	Items.ListChange.Visible = ThereIsAccessToChange;
	Items.ListSetDeletionMark.Visible =
		AccessRight("InteractiveSetDeletionMark", Metadata.Documents.BankAccountReceiptNote)
		And AccessRight("InteractiveSetDeletionMark", Metadata.Documents.BankAccountIssue);
	Items.ListOfPaymentsToHold.Visible =
		AccessRight("Posting", Metadata.Documents.BankAccountReceiptNote)
		And AccessRight("Posting", Metadata.Documents.BankAccountIssue);
	Items.ListOfPaymentsTheAbolitionOfThe.Visible =
		AccessRight("UndoPosting", Metadata.Documents.BankAccountReceiptNote)
		And AccessRight("UndoPosting", Metadata.Documents.BankAccountIssue);
	Items.ListOfEventsHeldByTheBank.Visible = ThereIsAccessToChange;
	
EndProcedure

&AtServer
Procedure CompleteDocumentCreationCommands()
	
	UsePaymentByCards                 = GetFunctionalOption("UsePaymentByCards");
	UseCustomerInvoiceIntercompany       = GetFunctionalOption("UseCustomerInvoiceIntercompany");
	UseMultipleAccounts                         = GetFunctionalOption("UseMultipleBankAccounts");
	UseLoansDeposits                         = GetFunctionalOption("UseLoanAndDepositContracts");
	UseMultipleCurrencies                          = GetFunctionalOption("UseMultipleCurrencies");
	UseSeparateDivisions               = GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	VNAManagementIsUsed                           = NonCurrentAssets.VNAManagementIsUsed();
	UseEmployeeLoans                        = Not GetFunctionalOption("TradeManagement");
	
	BusinessTransactionsByFO = New Map;
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment,              UsePaymentByCards);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashReceiptFromOtherCompany,  UseCustomerInvoiceIntercompany);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices,              UseSeparateDivisions);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashReceiptFromAnotherAccount,        UseMultipleAccounts);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashReceiptFromLoansRepayment,           UseLoansDeposits);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashReceiptUnderDeposits,          UseLoansDeposits);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty,     UseLoansDeposits);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CurrencyConversion,                              UseMultipleCurrencies And UseMultipleAccounts);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.RefundFromAnotherCompany,      UseCustomerInvoiceIntercompany);
	
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashPaymentToAnotherCompany,        UseCustomerInvoiceIntercompany);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices,              UseSeparateDivisions);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.PaymentToLessor,                             VNAManagementIsUsed);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.RefundFromLessor,           VNAManagementIsUsed);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.TransferCashToAnotherAccount,        UseMultipleAccounts);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived,                               UseLoansDeposits);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.TransferToDeposits,                         UseLoansDeposits);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashIssueAsLoanToCounterparty,                                   UseLoansDeposits);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.CashIssueAsLoanToEmployee,                          UseEmployeeLoans);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.LoanRepaymentByEmployee,                      UseEmployeeLoans);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.RefundToAnotherCompany,       UseCustomerInvoiceIntercompany);
	BusinessTransactionsByFO.Insert(Enums.BusinessTransactions.RefundAcquiringPayment,                  UsePaymentByCards);
	
	
	FormSettings = New Structure;
	
	// Inpayment
	BusinessTransactionsIncomeOperations = New Map;
	
	GroupsOfOperations = New Array;
	
	Operations = New ValueList;
	
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.CashReceiptFromCustomer);
		Operations.Add(Enums.BusinessTransactions.CashRecieptByAcquiringTransactionsPayment, NStr("vi = 'Nhận tiền theo thẻ thanh toán';
																									|ru = 'Поступление оплаты по эквайрингу';
																									|en = 'Acquiring payment'; fa = 'پرداخت پذیرندگی';
																									|it = 'Pervenimento del pagamento  per acquiring';
																									|pl = 'Wpływ płatności przez centrum autoryzacyjne';
																									|tr = 'PoS ödemesi'") );
		Operations.Add(Enums.BusinessTransactions.CashReceiptFromOtherCompany, NStr("vi = 'Thu tiền từ một doanh nghiệp khác';
																					|ru = 'Поступление от другой организации';
																					|en = 'Payment from another company'; fa = 'پرداخت از شرکت دیگر';
																					|it = 'Versamento da un''altra azienda';
																					|pl = 'Wpływ od innej firmy';
																					|tr = 'Başka bir iş yerinden ödeme'"));
		Operations.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices, NStr("vi = 'Chuyển tiền giữa doanh nghiệp và chi nhánh';
																										|ru = 'Передача между организацией и филиалом';
																										|en = 'Transfer between the company and its branch office'; fa = 'انتقال بین شرکت و شعبه آن';
																										|it = 'Trasferimento tra organizzazione e filiale';
																										|pl = 'Transfer między organizacją i filią';
																										|tr = 'İş yerleri ve şubeler arasında transfer'"));
	EndIf;
	
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Payment");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.CashReceiptFromAnotherAccount, NStr("vi = 'Thu từ tài khoản khác';
																						|ru = 'Поступление с другого счета';
																						|en = 'Transfer from another account'; fa = 'انتقال از حساب دیگر';
																						|it = 'Entrata da altro conto';
																						|pl = 'Wpływ z innego konta';
																						|tr = 'Diğer hesaptan ödeme'"));
	EndIf;
	If AccessRight("Update", Metadata.Documents.CashVoucher) Then
		Operations.Add(Enums.BusinessTransactions.CashDepositToBankAccount, NStr("vi = 'Nộp tiền mặt vào ngân hàng';
																				|ru = 'Сдача наличных в банк';
																				|en = 'Pass cash to bank'; fa = 'تحویل وجه نقد به بانک';
																				|it = 'Consegna contanti in banca';
																				|pl = 'Oddanie gotówki do banku';
																				|tr = 'Nakdin bankaya transferi'"));
	EndIf;
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.CashReceiptFromCashRegisterToBankAccount, NStr("vi = 'Chuyển tiền đến ngân hàng';
																								|ru = 'Инкассация в банк';
																								|en = 'Cash deposit to bank'; fa = 'واریز وجه نقد به بانک';
																								|it = 'Incasso in banca';
																								|pl = 'Gromadzenie w banku';
																								|tr = 'bankaya nakit yatırma'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Move");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.CashReceiptFromLoansRepayment, NStr("vi = 'Thu tiền theo tín dụng và các khoản vay nhận được';
																						|ru = 'Поступление по кредитам и займам полученным';
																						|en = 'Loan repayment'; fa = 'بازپرداخت وام';
																						|it = 'Entrata relativa a crediti e prestiti ottenuti';
																						|pl = 'Wpływ z tytułu otrzymanych kredytów i pożyczek';
																						|tr = 'Alınan kredi ve borçlara ilişkin girişler'"));
		Operations.Add(Enums.BusinessTransactions.CashReceiptUnderDeposits, NStr("vi = 'Thu tiền gửi (deposit)';
																				|ru = 'Поступление по депозитам';
																				|en = 'Deposit interest'; fa = 'سود سپرده';
																				|it = 'Entrata relativa a depositi';
																				|pl = 'Napływ wg depozytów';
																				|tr = 'Mevduatlara göre girişi'"));
		Operations.Add(Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty, NStr("vi = 'Đối tác trả khoản vay';
																									|ru = 'Погашение займа контрагентом';
																									|en = 'Loan repayment by counterparty'; fa = 'بازپرداخت وام توسط طرف حساب';
																									|it = 'Rimborso del prestito dal controparte';
																									|pl = 'Spłata pożyczki kontrahentem';
																									|tr = 'Cari hesap borcunun geri ödenmesi'"));
		Operations.Add(Enums.BusinessTransactions.LoanRepaymentByEmployee, NStr("vi = 'Nhân viên trả khoản vay';
																				|ru = 'Погашение займа сотрудником';
																				|en = 'Loan repayment by employee'; fa = 'بازپرداخت وام توسط کارمند';
																				|it = 'Rimborso del prestito dal dipendente';
																				|pl = 'Spłata pożyczki pracownikiem';
																				|tr = 'Çalışan borcunun geri ödenmesi'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "CreditsDeposits");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.CurrencyConversion);
		Operations.Add(Enums.BusinessTransactions.OtherCashReceipt, NStr("vi = 'Thu khác';
																		|ru = 'Прочее поступление';
																		|en = 'Other payment'; fa = 'سایر پرداخت‌ها';
																		|it = 'Altri versamenti';
																		|pl = 'Inny napływ';
																		|tr = 'Diğer girişler'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Other");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.RefundFromVendor);
		Operations.Add(Enums.BusinessTransactions.CashReturnByAdvanceHolder, NStr("vi = 'Nhận tiền hoàn lại từ người tạm ứng';
																					|ru = 'Возврат от подотчетника';
																					|en = 'Return from advance holder'; fa = 'برگشت از تنخواه‌گردان';
																					|it = 'Restituzione dal responsabile';
																					|pl = 'Zwrot od osoby rozliczającej się za wydatki';
																					|tr = 'Avans sahibinden iade'"));
		Operations.Add(Enums.BusinessTransactions.RefundFromAnotherCompany, NStr("vi = 'Hoàn tiền từ một doanh nghiệp khác';
																				|ru = 'Возврат от другой организации';
																				|en = 'Other company refund'; fa = 'بازپرداخت شرکت دیگر';
																				|it = 'Restituzione da un'' altra azienda';
																				|pl = 'Zwrot od innej firmy';
																				|tr = 'Diğer iş yerinden iade'"));
		Operations.Add(Enums.BusinessTransactions.RefundFromLessor, NStr("vi = 'Hoàn trả tiền lương chưa áp dụng vào tài khoản cá nhân';
																		|ru = 'Возврат от арендодателя';
																		|en = 'Lessor refund'; fa = 'بازپرداخت موجر';
																		|it = 'Reso da parte del locatore';
																		|pl = 'Zwrot od wynajemcy';
																		|tr = 'Kiracıdan iade'"));
		Operations.Add(Enums.BusinessTransactions.ReturnOfPayrollPaymentByPayrollCardProgram, NStr("vi = 'Trả lại các khoản thanh toán không được liệt kê theo danh sách';
																									|ru = 'Возврат неперечисленных по реестру платежей';
																									|en = 'Refund of payments not listed in payment list'; fa = 'بازپرداخت پرداخت‌های غیرفهرست‌شده در لیست پرداخت';
																									|it = 'Возврат неперечисленных по реестру платежей';
																									|pl = 'Refund of payments not listed in payment list';
																									|tr = 'Kayıtta listelenmeyen ödemelerin iadesi'"));
		Operations.Add(Enums.BusinessTransactions.TaxRefund);
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Returns");
	GroupsOfOperations.Add(GroupOfOperations);
	
	For Each GroupOfOperations In GroupsOfOperations Do
		
		CommandGroup = Items.Insert(
			"CreateReceiptGroup" + GroupOfOperations.GroupName, Type("FormGroup"), Items.CreateReceiptList);
		CommandGroup.Type = FormGroupType.ButtonGroup;
		
		For Each Operation In GroupOfOperations.Operations Do
			
			OperationEnabled = True;
			UsingXO = BusinessTransactionsByFO.Get(Operation.Value);
			If UsingXO <> Undefined Then
				OperationEnabled = UsingXO;
			EndIf;
			
			If OperationEnabled Then
				NameOfBusinessTransaction = Common.EnumerationValueName(Operation.Value);
				BusinessTransactionsIncomeOperations.Insert(NameOfBusinessTransaction, Operation.Value);
				
				CommandName = StrTemplate("CreateReceipt%1", NameOfBusinessTransaction);
				
				CreateDocumentCommand = Commands.Add(CommandName);
				CreateDocumentCommand.Action = "CreateReceipt";
				CreateDocumentCommand.Title = ?(ValueIsFilled(Operation.Presentation), Operation.Presentation, String(Operation.Value));
				AddBusinessTransactionToTableOfCreatedCommands(Operation.Value, NameOfBusinessTransaction);
				
				CreateDocumentElement = Items.Insert("CreateReceipt" + NameOfBusinessTransaction, Type("FormButton"), CommandGroup);
				CreateDocumentElement.CommandName = CreateDocumentCommand.Name;
			EndIf;
		EndDo;
	EndDo;
	
	FormSettings.Insert("BusinessTransactionsIncomeOperations", BusinessTransactionsIncomeOperations);
	
	// WriteOff
	BusinessTransactionsWriteOffOperations = New Map;
	
	GroupsOfOperations = New Array;
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		Operations.Add(Enums.BusinessTransactions.PaymentToVendor);
		Operations.Add(Enums.BusinessTransactions.IssueCashToAdvanceHolder, NStr("vi = 'Chi tạm ứng';
																				|ru = 'Выдача подотчетнику';
																				|en = 'Payment to advance holder'; fa = 'پرداخت به تنخواه‌گردان';
																				|it = 'Rilasciare alla persona responsabile';
																				|pl = 'Wydanie osobie rozliczającej';
																				|tr = 'Avans sahibine transfer'"));
		Operations.Add(Enums.BusinessTransactions.TransferOfTaxesAndContributions);
		Operations.Add(Enums.BusinessTransactions.CashPaymentToAnotherCompany, NStr("vi = 'Thanh toán cho doanh nghiệp khác';
																					|ru = 'Оплата другой организации';
																					|en = 'Intercompany payment'; fa = 'پرداخت درون‌گروهی';
																					|it = 'Pagamento ad un''altra azienda';
																					|pl = 'Płatność innej firmy';
																					|tr = 'Başka iş yeri ödemesi'"));
		Operations.Add(Enums.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices, NStr("vi = 'Chuyển tiền giữa doanh nghiệp và chi nhánh';
																										|ru = 'Передача между организацией и филиалом';
																										|en = 'Transfer between the company and its branch office'; fa = 'انتقال بین شرکت و شعبه آن';
																										|it = 'Trasferimento tra organizzazione e filiale';
																										|pl = 'Transfer między organizacją i filią';
																										|tr = 'İş yerleri ve şubeler arasında transfer'"));
		Operations.Add(Enums.BusinessTransactions.SalaryPaymentToBankAccounts);
		Operations.Add(Enums.BusinessTransactions.PaymentToLessor, NStr("vi = 'Thanh toán cho người cho thuê';
																		|ru = 'Оплата арендодателю';
																		|en = 'Payment to lessor'; fa = 'پرداخت به موجر';
																		|it = 'Pagamento al locatore';
																		|pl = 'Płatność do wynajemcy';
																		|tr = 'Kiracıya ödeme'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Payment");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		Operations.Add(Enums.BusinessTransactions.TransferCashToAnotherAccount, NStr("vi = 'Chuyển sang tài khoản khác';
																					|ru = 'Перечисление на другой счет';
																					|en = 'Cash transfer to other account'; fa = 'انتقال وجه به حساب دیگر';
																					|it = 'Trasferimento su un altro conto';
																					|pl = 'Przelej na inny rachunek';
																					|tr = 'Başka bir hesaba aktarma'"));
	EndIf;
	If AccessRight("Update", Metadata.Documents.CashAccountReceiptNote) Then
		Operations.Add(Enums.BusinessTransactions.CashReceiptFromBank, NStr("vi = 'Nhận tiền mặt từ ngân hàng';
																			|ru = 'Поступление наличных из банка';
																			|en = 'Cash receipt from bank'; fa = 'دریافت وجه نقد از بانک';
																			|it = 'Versamento dei contanti dalla banca';
																			|pl = 'Wpłata gotówki z banku';
																			|tr = 'Bankadan nakit mahsubu'"));
	EndIf;
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		Operations.Add(Enums.BusinessTransactions.WithdrawalFromBankAccount, NStr("vi = 'Chuyển tiền từ ngân hàng';
																					|ru = 'Инкассация из банка';
																					|en = 'Cash withdrawal from bank'; fa = 'برداشت وجه نقد از بانک';
																					|it = 'Incasso dalla banca';
																					|pl = 'Inkasacja z banku';
																					|tr = 'Bankadan nakit çekimi'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Move");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		Operations.Add(Enums.BusinessTransactions.PaymentOnLoansAndBorrowingsReceived);
		Operations.Add(Enums.BusinessTransactions.TransferToDeposits);
		Operations.Add(Enums.BusinessTransactions.CashIssueAsLoanToCounterparty, NStr("vi = 'Chi cho đối tác vay';
																						|ru = 'Выдача займа контрагенту';
																						|en = 'Loan to counterparty'; fa = 'وام به طرف حساب';
																						|it = 'Emissione del prestito alla controparte';
																						|pl = 'Wydanie pożyczki kontrahentowi';
																						|tr = 'Cari hesaba kredi'"));
		Operations.Add(Enums.BusinessTransactions.CashIssueAsLoanToEmployee, NStr("vi = 'Chi cho nhân viên vay';
																					|ru = 'Выдача займа сотруднику';
																					|en = 'Loan to employee'; fa = 'وام به کارمند';
																					|it = 'Emissione del prestito al dipendente';
																					|pl = 'Wydanie pożyczki pracownikowi';
																					|tr = 'Çalışana kredi'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "CreditsDeposits");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		Operations.Add(Enums.BusinessTransactions.CurrencyConversion);
		Operations.Add(Enums.BusinessTransactions.OtherCashIssue, NStr("vi = 'Chi khác';
																		|ru = 'Прочий расход';
																		|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
																		|it = 'Altre spese';
																		|pl = 'Inny wydatek';
																		|tr = 'Diğer giderler'"));
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Other");
	GroupsOfOperations.Add(GroupOfOperations);
	
	Operations = New ValueList;
	If AccessRight("Insert", Metadata.Documents.BankAccountIssue) Then
		Operations.Add(Enums.BusinessTransactions.RefundToCustomer);
		Operations.Add(Enums.BusinessTransactions.RefundToAnotherCompany, NStr("vi = 'Hoàn lại cho doanh nghiệp khác';
																				|ru = 'Возврат другой организации';
																				|en = 'Refund to another company'; fa = 'بازپرداخت به شرکت دیگر';
																				|it = 'La restituzione ad un''altra organizzazione';
																				|pl = 'Zwrot innej firmy';
																				|tr = 'Başka bir iş yeri iadesi'"));
		Operations.Add(Enums.BusinessTransactions.RefundAcquiringPayment);
	EndIf;
	GroupOfOperations = New Structure("Operations, GroupName", Operations, "Returns");
	GroupsOfOperations.Add(GroupOfOperations);
	
	For Each GroupOfOperations In GroupsOfOperations Do
		
		CommandGroup = Items.Insert("CreateWriteOffGroup" + GroupOfOperations.GroupName, Type("FormGroup"), Items.CreateWriteOffList);
		CommandGroup.Type = FormGroupType.ButtonGroup;
		
		For Each Operation In GroupOfOperations.Operations Do
			
			OperationEnabled = True;
			UsingXO = BusinessTransactionsByFO.Get(Operation.Value);
			If UsingXO <> Undefined Then
				OperationEnabled = UsingXO;
			EndIf;
			
			If OperationEnabled Then
				NameOfBusinessTransaction = Common.EnumerationValueName(Operation.Value);
				BusinessTransactionsWriteOffOperations.Insert(NameOfBusinessTransaction, Operation.Value);
				
				CreateDocumentCommand = Commands.Add("CreateCharge" + NameOfBusinessTransaction);
				CreateDocumentCommand.Action = "CreateCharge";
				CreateDocumentCommand.Title = ?(ValueIsFilled(Operation.Presentation), Operation.Presentation, String(Operation.Value));
				
				AddBusinessTransactionToTableOfCreatedCommands(Operation.Value, NameOfBusinessTransaction);
				
				CreateDocumentElement = Items.Insert("CreateCharge" + NameOfBusinessTransaction, Type("FormButton"), CommandGroup);
				CreateDocumentElement.CommandName = CreateDocumentCommand.Name;
			EndIf;
		EndDo;
	EndDo;
	
	FormSettings.Insert("BusinessTransactionsWriteOffOperations", BusinessTransactionsWriteOffOperations);
	
EndProcedure

&AtServer
Procedure AddBusinessTransactionToTableOfCreatedCommands(Operation, OperationName)
	
	NewRow = NamesOfBusinessOperationsCreationCommands.Add();
	NewRow.BusinessOperation = Operation;
	NewRow.PostfixOfTheCommand       = OperationName;
	
EndProcedure

&AtServer
Procedure SetDynamicListSelection()
	
	If ValueIsFilled(BankAccountSelection) Then
		
		AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccountSelection);
		Organization = AccountAttributes.Organization;
		If AccountAttributes.IsFolder Then
			LabelText = StrTemplate(NStr("vi = 'Tài khoản ngân hàng của thư mục ""%1"" theo doanh nghiệp %2';
										|ru = 'Банковские счета каталога ""%1"" по организации %2';
										|en = 'Bank accounts of the ""%1"" directory by the %2 entity'; fa = 'Bank accounts of the ""%1"" directory by the %2 entity';
										|it = 'Conti bancari della directory ""%1"" per l''azienda %2';
										|pl = 'Rachunki bankowe katalogu ""%1"" według firmy %2';
										|tr = '%2 iş yerine göre ""%1"" klasörünün banka hesapları'"),
										BankAccountSelection, AccountAttributes.Organization);
			Items.LabelBankAccount.Title = LabelText;
		Else
			AccountCurrency = AccountAttributes.Currency;
			Items.LabelBankAccount.Title =
				StrTemplate(NStr("vi = 'Tài khoản ngân hàng %1, %2';
								|ru = 'Банковский счет %1, %2';
								|en = 'Bank account %1, %2'; fa = 'Bank account %1, %2';
								|it = 'Conto corrente %1, %2';
								|pl = 'Rachunek bankowy %1, %2';
								|tr = 'Banka hesabı %1, %2'"), String(AccountCurrency), TrimAll(BankAccountSelection));
		EndIf;
		
		If ValueIsFilled(Organization) Then
			ChoiceParameterLinks = New Array;
			ChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Owner", "Organization"));
			Items.BankAccountSelection.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
		Else
			Items.BankAccountSelection.ChoiceParameterLinks = New FixedArray(New Array);
		EndIf;
	ElsIf ValueIsFilled(Organization) Then
		
		BankAccountSelection = Undefined;
		AccountCurrency         = Undefined;
		Items.LabelBankAccount.Title = NStr("vi = '<Chưa chỉ ra tài khoản ngân hàng>';
											|ru = '<Банковский счет не задан>';
											|en = '<Bank account is not set>'; fa = '<Bank account is not set>';
											|it = '<Conto corrente non impostato>';
											|pl = '<Rachunek bankowy nie jest określony>';
											|tr = '<Banka hesabı ayarlanmadı>'");
		
		ChoiceParameterLinks = New Array;
		ChoiceParameterLinks.Add(New ChoiceParameterLink("Filter.Owner", "Organization"));
		Items.BankAccountSelection.ChoiceParameterLinks = New FixedArray(ChoiceParameterLinks);
	Else
		
		Organization = Undefined;
		AccountCurrency = Undefined;
		Items.LabelBankAccount.Title = NStr("vi = '<Chưa chỉ ra tài khoản ngân hàng>';
											|ru = '<Банковский счет не задан>';
											|en = '<Bank account is not set>'; fa = '<Bank account is not set>';
											|it = '<Conto corrente non impostato>';
											|pl = '<Rachunek bankowy nie jest określony>';
											|tr = '<Banka hesabı ayarlanmadı>'");
		Items.BankAccountSelection.ChoiceParameterLinks = New FixedArray(New Array);
	EndIf;
	
	If Not ValueIsFilled(BeginOfPeriod) And Not ValueIsFilled(EndOfPeriod) Then
		Items.TheInscriptionTheStatementPeriod.Title = NStr("vi = 'Trong kỳ <không giới hạn>';
															|ru = 'За период <без ограничения>';
															|en = 'For period <without restriction>'; fa = 'For period <without restriction>';
															|it = 'Per il periodo <senza restrizioni>';
															|pl = 'Za okres <bez ograniczeń>';
															|tr = '<sınırsız> dönem içinde'")
	Else
		Items.TheInscriptionTheStatementPeriod.Title =
			StrTemplate(NStr("vi = 'Trong kỳ từ %1 đến %2';
							|ru = 'За период с %1 по %2';
							|en = 'For the period from %1 to %2'; fa = 'For the period from %1 to %2';
							|it = 'Per il periodo dal %1 al %2';
							|pl = 'Na okres od %1 do %2';
							|tr = '%1 tarihinden %2 kadar olan dönem içerisinde'"),
				?(ValueIsFilled(BeginOfPeriod), Format(BeginOfPeriod, "DLF=D"), NStr("vi = '<không giới hạn>';
																					|ru = '<без ограничения>';
																					|en = '<without restrictions>'; fa = '<without restrictions>';
																					|it = '<senza restrizioni>';
																					|pl = '<bez ograniczeń>';
																					|tr = '<sınırsız>'")),
				?(ValueIsFilled(EndOfPeriod), Format(EndOfPeriod, "DLF=D"), NStr("vi = '<không giới hạn>';
																				|ru = '<без ограничения>';
																				|en = '<without restrictions>'; fa = '<without restrictions>';
																				|it = '<senza restrizioni>';
																				|pl = '<bez ograniczeń>';
																				|tr = '<sınırsız>'")));
	EndIf;
	
	// General selections
	CompaniesList = DataProcessors.DocumentsJournalBankAccountPayments.RelatedOrganizations(Organization);
	
	AccountList = New ValueList;
	AccountList.Add(BankAccountSelection);
	AccountList.Add(Catalogs.CompaniesBankAccounts.EmptyRef());
	AccountList.Add(Undefined);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfPayment,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(Organization));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListOfPayment,
		"BankAccount",
		BankAccountSelection,
		DataCompositionComparisonType.InHierarchy,,
		ValueIsFilled(BankAccountSelection));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListOfPayment,
		"Currency",
		AccountCurrency,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(AccountCurrency));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListOfPayment,
		"CounterpartyPresentation",
		CounterpartyPresentation,
		DataCompositionComparisonType.Contains,,
		ValueIsFilled(CounterpartyPresentation));
	
	ListOfPayment.Parameters.SetParameterValue("BeginOfPeriod", BeginOfPeriod);
	ListOfPayment.Parameters.SetParameterValue("EndOfPeriod", ?(ValueIsFilled(EndOfPeriod), EndOfDay(EndOfPeriod), EndOfDay(Date(3999, 12, 31))));
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfPayment,
		"ProcessedByBank",
		?(ProcessedByBankFilter = "Posted", True, False),
		DataCompositionComparisonType.Equal,,
		ProcessedByBankFilter <> "AllPayments_");
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "ListOfPayment");
	// End DynamicListsSettings
	
	UpdateTotals();
	
	SaveWorkingValuesOfFormFields();
	
EndProcedure

&AtClient
Function CheckGetLinksHighlightedInList(Item, Rows)
	
	If TypeOf(Rows) = Type("Array") Then
		RowsSelected = Rows;
	Else
		RowsSelected = New Array;
		RowsSelected.Add(Rows);
	EndIf;
	
	ReferencesArrray = New Array;
	
	For Iterator_SSLy = 0 To RowsSelected.Count() - 1 Do
		If TypeOf(RowsSelected[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
			ReferencesArrray.Add(Item.RowData(RowsSelected[Iterator_SSLy]).Ref);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Procedure UpdateTotals()
	
	UpdateCashBalances();
	UpdateBalancesAndRevs();
	
EndProcedure

&AtServer
Procedure UpdateCashBalances()
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	BankAccountCash.SumBalance        AS Current_Balance,
	|	BankAccountCash.ToWriteOffBalance    AS ToWriteOffEverything
	|FROM
	|	AccumulationRegister.BankAccountCash.Balance(, BankAccount IN HIERARCHY (&BankAccount)) AS BankAccountCash
	|";
	
	If ValueIsFilled(BankAccountSelection) Or Not ValueIsFilled(Organization) Then
		Query.SetParameter("BankAccount", BankAccountSelection);
	Else
		Query.Text = StrReplace(Query.Text, "BankAccount IN HIERARCHY (&BankAccount)", "Organization = &Organization");
		Query.SetParameter("Organization", Organization);
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Current_Balance = Selection.Current_Balance;
		ToWriteOffEverything = Selection.ToWriteOffEverything;
	Else
		Current_Balance = 0;
		ToWriteOffEverything = 0;
	EndIf;
	
	AvailableInTotal = Current_Balance - ToWriteOffEverything;
	
EndProcedure

&AtServer
Procedure UpdateBalancesAndRevs()
	
	OpeningBalance = 0;
	Inpayment = 0;
	WriteOff = 0;
	ClosingBalance = 0;
	
	If ValueIsFilled(EndOfPeriod) And BeginOfPeriod > EndOfPeriod Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	BankAccountCash.SumOpeningBalance AS OpeningBalance,
	|	BankAccountCash.SumReceipt AS Inpayment,
	|	BankAccountCash.SumExpense AS WriteOff,
	|	BankAccountCash.SumClosingBalance AS ClosingBalance
	|FROM
	|	AccumulationRegister.BankAccountCash.BalanceAndTurnovers(&BeginOfPeriod, &EndOfPeriod,,, BankAccount IN HIERARCHY (&BankAccount)) AS BankAccountCash
	|";
	
	Query.SetParameter("BeginOfPeriod", BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",
		?(ValueIsFilled(EndOfPeriod), New Boundary(EndOfDay(EndOfPeriod), BoundaryType.Including), EndOfPeriod));
	
	If ValueIsFilled(BankAccountSelection) Or Not ValueIsFilled(Organization) Then
		Query.SetParameter("BankAccount", BankAccountSelection);
	Else
		Query.Text = StrReplace(Query.Text, "BankAccount IN HIERARCHY (&BankAccount)", "Organization = &Organization");
		Query.SetParameter("Organization", Organization);
	EndIf;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		OpeningBalance = Selection.OpeningBalance;
		Inpayment = Selection.Inpayment;
		WriteOff = Selection.WriteOff;
		ClosingBalance = Selection.ClosingBalance;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateHyperlinksToLayout()
	
	ListItem = ToRegisterReference.FindByValue("ToReceive");
	If ListItem <> Undefined Then
		ListItem.Presentation = HyperlinkToAdmission(QuantityToBeReceived());
	EndIf;
	
	ListItem = ToRegisterReference.FindByValue("ForPaymentByTransfer");
	If ListItem <> Undefined Then
		ListItem.Presentation = HyperlinkToPaymentTransfer(AmountToBePaidByTransfer());
	EndIf;
	
	ListItem = ToRegisterReference.FindByValue("CreditingDS");
	
	If ListItem <> Undefined Then
		ListItem.Presentation = New FormattedString(
				NStr("vi = 'Ghi có vào tài khoản cá nhân';
					|ru = 'Зачисление на лицевые счета';
					|en = 'Deposit into personal accounts'; fa = 'واریز به حساب‌های شخصی';
					|it = 'Accredito su conti personali';
					|pl = 'Zaliczenie na konta osobiste';
					|tr = 'Kişisel hesaplara kayıt'"), , StyleColors.HyperlinkColor, , "CreditingDS");
	EndIf;
	
	CreateHyperlinksToDesign();
	
EndProcedure

&AtServer
Procedure CreateHyperlinksToDesign()
	
	RowsArray = New Array;
	For Each ListItem In ToRegisterReference Do
		RowsArray.Add(ListItem.Presentation);
		RowsArray.Add("    ");
	EndDo;
	
	ToRegister = New FormattedString(RowsArray);
	Items.ToRegister.Visible = ValueIsFilled(ToRegister);
	
EndProcedure

&AtServer
Function QuantityToBeReceived()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	SUM(LinesForPayment.Count) AS Count
	|FROM
	|(SELECT TOP 1001
	|	1 AS Count
	|FROM
	|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
	|WHERE
	|	ScheduleOfPayments.ReceiptIssue = VALUE(Enum.CashFlowTypes.Inpayment)
	|	AND ScheduleOfPayments.PlanningArea IN (
	|		VALUE(Enum.PaymentPlanningAreas.CustomersARAPAccounting),
	|		VALUE(Enum.PaymentPlanningAreas.ReturnsFromVendors),
	|		VALUE(Enum.PaymentPlanningAreas.CashInTransit),
	|		VALUE(Enum.PaymentPlanningAreas.LoansOrBorrowingsReceived),
	|		VALUE(Enum.PaymentPlanningAreas.IssuedBorrowings),
	|		VALUE(Enum.PaymentPlanningAreas.Deposits)
	|		)
	|	AND ScheduleOfPayments.PaymentMethod IN (
	|		VALUE(Enum.PaymentForms.BankAccountPayment),
	|		VALUE(Enum.PaymentForms.EmptyRef))
	|	AND (ScheduleOfPayments.Organization IN (&CompanyFilter)
	|		OR &OrganizationSelectionNotSpecified)
	|	AND (ScheduleOfPayments.BankAccountCashAccount IN (&BankAccountSelection)
	|		OR &BankAccountSelectionIsNotSet)
	|	AND (ScheduleOfPayments.PayerBeneficiary.Description LIKE &CounterpartySelection_
	|		OR &CounterpartySelectionNotSpecified)
	|) AS LinesForPayment
	|";
	
	CompaniesList = DataProcessors.DocumentsJournalBankAccountPayments.RelatedOrganizations(Organization);
	
	AccountList = New ValueList;
	
	ListOfAccountsByAccount = Catalogs.CompaniesBankAccounts.CatalogBankAccounts(BankAccountSelection);
	
	If ListOfAccountsByAccount.Count() <> 0 Then
		AccountList.LoadValues(ListOfAccountsByAccount);
	EndIf;
	
	AccountList.Add(BankAccountSelection);
	AccountList.Add(Catalogs.CompaniesBankAccounts.EmptyRef());
	AccountList.Add(Undefined);
	
	Query.SetParameter("CompanyFilter",           CompaniesList);
	Query.SetParameter("OrganizationSelectionNotSpecified",    Not ValueIsFilled(Organization));
	Query.SetParameter("BankAccountSelection",        AccountList);
	Query.SetParameter("BankAccountSelectionIsNotSet", Not ValueIsFilled(BankAccountSelection));
	Query.SetParameter("CounterpartySelection_",            CounterpartyPresentation + "%");
	Query.SetParameter("CounterpartySelectionNotSpecified",     Not ValueIsFilled(CounterpartyPresentation));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	Selection.Next();
	
	If ValueIsFilled(Selection.Count) Then
		Return Selection.Count;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Function AmountToBePaidByTransfer()
	
	Query = New Query;
	
	If UsePaymentRequests Then
		Query.Text = "
		|SELECT
		|	SUM(LinesForPayment.Count) AS Count
		|FROM
		|(SELECT TOP 1001
		|	1 AS Count
		|FROM
		|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
		|	
		|	LEFT JOIN Document.PaymentRequest AS Request
		|	ON Request.Ref = ScheduleOfPayments.PaymentObject
		|
		|	LEFT JOIN Document.ApplicationForBusinessTrip AS ApplicationForBusinessTrip
		|	ON ApplicationForBusinessTrip.Ref = ScheduleOfPayments.PaymentObject
		|	
		|	LEFT JOIN Document.CashTransferReferenceOrder AS ReferenceOrder
		|	ON ReferenceOrder.Ref = ScheduleOfPayments.PaymentObject
		|	
		|	
		|WHERE
		|	ScheduleOfPayments.ReceiptIssue = VALUE(Enum.CashFlowTypes.WriteOff)
		|	AND ScheduleOfPayments.PlanningArea IN (
		|		VALUE(Enum.PaymentPlanningAreas.CashPaymentRequests),
		|		VALUE(Enum.PaymentPlanningAreas.ReferencesForCashTransfer))
		|	AND (Request.Status = VALUE(Enum.StatusesOfPaymentRequests.AmountDue)
		|		OR ReferenceOrder.Status = VALUE(Enum.CashTransferOrderStatuses.AmountDue)
		|		OR ApplicationForBusinessTrip.Status = VALUE(Enum.EmployeeApplicationStatuses.AgreedUpon)
		|		)
		|	AND (ReferenceOrder.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
		|		VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
		|		VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount))
		|		OR ReferenceOrder.Ref IS NULL)
		|	AND ScheduleOfPayments.PaymentMethod IN (
		|		VALUE(Enum.PaymentForms.BankAccountPayment),
		|		VALUE(Enum.PaymentForms.EmptyRef))
		|	AND (ScheduleOfPayments.Organization IN (&CompanyFilter)
		|		OR &OrganizationSelectionNotSpecified)
		|	AND (ScheduleOfPayments.BankAccountCashAccount IN (&BankAccountSelection)
		|		OR &BankAccountSelectionIsNotSet)
		|	AND (ScheduleOfPayments.PayerBeneficiary.Description LIKE &CounterpartySelection_
		|		OR &CounterpartySelectionNotSpecified)
		|) AS LinesForPayment
		|";
	Else
		Query.Text = "
		|SELECT
		|	SUM(LinesForPayment.Count) AS Count
		|FROM
		|(SELECT TOP 1001
		|	1 AS Count
		|FROM
		|	InformationRegister.ScheduleOfPayments AS ScheduleOfPayments
		|	
		|WHERE
		|	ScheduleOfPayments.ReceiptIssue = VALUE(Enum.CashFlowTypes.WriteOff)
		|	AND ScheduleOfPayments.PlanningArea IN (
		|		VALUE(Enum.PaymentPlanningAreas.VendorsARAPAccounting),
		|		VALUE(Enum.PaymentPlanningAreas.ReturnsToCustomers),
		|		VALUE(Enum.PaymentPlanningAreas.CashInTransit),
		|		VALUE(Enum.PaymentPlanningAreas.LoansOrBorrowingsReceived),
		|		VALUE(Enum.PaymentPlanningAreas.Deposits),
		|		VALUE(Enum.PaymentPlanningAreas.IssuedBorrowings),
		|		VALUE(Enum.PaymentPlanningAreas.Lease))
		|	AND ScheduleOfPayments.PaymentMethod IN (
		|		VALUE(Enum.PaymentForms.BankAccountPayment),
		|		VALUE(Enum.PaymentForms.EmptyRef))
		|	AND (ScheduleOfPayments.Organization IN (&CompanyFilter)
		|		OR &OrganizationSelectionNotSpecified)
		|	AND (ScheduleOfPayments.BankAccountCashAccount IN (&BankAccountSelection)
		|		OR &BankAccountSelectionIsNotSet)
		|	AND (ScheduleOfPayments.PayerBeneficiary.Description LIKE &CounterpartySelection_
		|		OR &CounterpartySelectionNotSpecified)
		|) AS LinesForPayment
		|";
	EndIf;
	
	CompaniesList = DataProcessors.DocumentsJournalBankAccountPayments.RelatedOrganizations(Organization);
	
	AccountList = New ValueList;
	
	ListOfAccountsByAccount = Catalogs.CompaniesBankAccounts.CatalogBankAccounts(BankAccountSelection);
	
	If ListOfAccountsByAccount.Count() <> 0 Then
		AccountList.LoadValues(ListOfAccountsByAccount);
	EndIf;
	
	AccountList.Add(BankAccountSelection);
	AccountList.Add(Catalogs.CompaniesBankAccounts.EmptyRef());
	AccountList.Add(Undefined);
	
	Query.SetParameter("CompanyFilter",           CompaniesList);
	Query.SetParameter("OrganizationSelectionNotSpecified",    Not ValueIsFilled(Organization));
	Query.SetParameter("BankAccountSelection",        AccountList);
	Query.SetParameter("BankAccountSelectionIsNotSet", Not ValueIsFilled(BankAccountSelection));
	Query.SetParameter("CounterpartySelection_",            CounterpartyPresentation + "%");
	Query.SetParameter("CounterpartySelectionNotSpecified",     Not ValueIsFilled(CounterpartyPresentation));
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	Selection.Next();
	
	If ValueIsFilled(Selection.Count) Then
		Return Selection.Count;
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Function HyperlinkToAdmission(QuantityToBeReceived)
	
	HyperlinkText = StrTemplate(NStr("vi = 'Cần thu tiền (%1)';
									|ru = 'К поступлению (%1)';
									|en = 'Receivables (%1)'; fa = 'Receivables (%1)';
									|it = 'In arrivo (%1)';
									|pl = 'Do wpłynięcia (%1)';
									|tr = 'Giriş için (%1)'"),
		?(QuantityToBeReceived > 1000, String(QuantityToBeReceived)+"+" , QuantityToBeReceived));
	Return New FormattedString(HyperlinkText,,
		?(QuantityToBeReceived > 0, StyleColors.HyperlinkColor, StyleColors.EmptyTableField),, "ToReceive");
	
EndFunction

&AtServer
Function HyperlinkToPaymentTransfer(AmountToBePaidByTransfer)
	
	HyperlinkText = StrTemplate(NStr("vi = 'Thanh toán / chuyển khoản (%1)';
									|ru = 'К оплате / переводу (%1)';
									|en = 'To pay / transfer (%1)'; fa = 'To pay / transfer (%1)';
									|it = 'Da pagare/trasferimento (%1)';
									|pl = 'Do zapłaty / przelewu (%1)';
									|tr = 'Ödenecek / transfer edilecek (%1)'"),
		?(AmountToBePaidByTransfer > 1000, String(AmountToBePaidByTransfer)+"+", AmountToBePaidByTransfer));
	Return New FormattedString(HyperlinkText,,
		?(AmountToBePaidByTransfer > 0, StyleColors.HyperlinkColor, StyleColors.EmptyTableField),, "AmountDue");
	
EndFunction

&AtClient
Function PostfixOfBusinessTransactionCommand(BusinessOperation)
	
	SearchParameters = New Structure;
	SearchParameters.Insert("BusinessOperation",BusinessOperation);
	
	FoundRows = NamesOfBusinessOperationsCreationCommands.FindRows(SearchParameters);
	
	If FoundRows.Count() > 0 Then
		Return FoundRows[0].PostfixOfTheCommand;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.BankAccountReceiptNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.BankAccountIssue.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Val Notification, Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Ref = ReferencesArrray[0];
		Items.ListOfPayment.CurrentRow = Ref;
		ShowValue(New CallbackDescription("ProcessBarcodesCompletion", ThisObject, New Structure("Data, Notification", Data, Notification)), Ref);
		Return;
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
	ProcessBarcodesFragment(Notification);
	
EndProcedure

&AtClient
Procedure ProcessBarcodesCompletion(AdditionalParameters) Export
	
	Data = AdditionalParameters.Data;
	Notification = AdditionalParameters.Notification;
	
	ProcessBarcodesFragment(Notification);
	
EndProcedure

&AtClient
Procedure ProcessBarcodesFragment(Val Notification)
	
	RunCallback(Notification);
	
EndProcedure

#EndRegion

&AtServer
Function ThereIsAccessToAdmission()
	
	Return AccessRight("Read", Metadata.InformationRegisters.ScheduleOfPayments);
	
EndFunction

&AtServer
Function ThereIsAccessToPayment()

	If UsePaymentRequests Then
		Return AccessRight("Read", Metadata.Catalogs.PaymentPriorities)
				And AccessRight("Read", Metadata.InformationRegisters.ScheduleOfPayments)
				And AccessRight("Read", Metadata.Documents.PaymentRequest)
				And AccessRight("Read", Metadata.Documents.ApplicationForBusinessTrip)
				And AccessRight("Read", Metadata.Documents.CashTransferReferenceOrder);
	Else
		Return AccessRight("Read", Metadata.InformationRegisters.ScheduleOfPayments);
	EndIf;

EndFunction

&AtServer
Function ThereIsAccessToCashDeposit()

	Return AccessRight("Read", Metadata.Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount);

EndFunction

&AtServer
Procedure SaveWorkingValuesOfFormFields(SaveUndefined = False)
	
	Common.CommonSettingsStorageSave("CurrentCompany", "", ?(SaveUndefined, Undefined, Organization));
	Common.CommonSettingsStorageSave("CurrentBankAccount", "", ?(SaveUndefined, Undefined, BankAccountSelection));
	
EndProcedure

&AtServer
Procedure ConfigureDocumentManagementButtons(DocumentTypes)
	
	AccessRightUpdate = False;
	
	For Each TypeName In DocumentTypes Do
		If AccessRight("Update", TMCommonUse.ObjectMetadataByFullName(TypeName)) Then
			AccessRightUpdate = True;
			Break;
		EndIf;
	EndDo;
	
	DocumentManagementButtons = New Array;
	DocumentManagementButtons.Add("ListCopy");
	DocumentManagementButtons.Add("PaymentListCopyContextMenu");
	DocumentManagementButtons.Add("ListChange");
	DocumentManagementButtons.Add("ListOfPaymentContextMenuChange");
	DocumentManagementButtons.Add("ListOfPaymentsToHold");
	DocumentManagementButtons.Add("PaymentListContextMenuHold");
	DocumentManagementButtons.Add("ListOfPaymentsTheAbolitionOfThe");
	DocumentManagementButtons.Add("PaymentListContextMenuCancelPayment");
	DocumentManagementButtons.Add("ListSetDeletionMark");
	DocumentManagementButtons.Add("PaymentListContextMenuSetDeleteMark");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		DocumentManagementButtons,
		"Visible",
		AccessRightUpdate);

EndProcedure

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "ListOfPayment";
	ListParameterStructure.PlacementGroupSettings = Items.Header;
	ListParameterStructure.AttributeNameAutoUpdateMode = "ListOfDocumentsAutoUpdateMode";
	ListParameterStructure.NameOfListUpdateCommands = Commands.DocumentsListRefresh.Name;
	DocumentListParameters.Add(ListParameterStructure);
	
	OperationsWithDocumentJournals.InitiateDynamicListSettings(ThisObject, DocumentListParameters);

EndProcedure

&AtClient
Procedure DisplayingGroupOfUserSelectionsAndSettings(ListName)
	
	LongTermUpdate = OperationsWithDocumentJournalsClient.TimeToUpdateListExceedsAllowedTime(ThisObject,
		ListName);
		
	If LongTermUpdate Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	Else
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", False);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", New DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", New Structure);
	EndIf;

	OperationsWithDocumentJournalsClient.DocumentsDisplayGroupOfUserSelectionsAndSettings(ThisObject, ListName);
	
EndProcedure

&AtServer
Function GetPerformingDataCompositionSettings(ListName)
	
	TagName = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject, ListName,
		"NameOfListItem");
	ListFormElement = Items[TagName];
	DataCompositionSettings = ListFormElement.GetPerformingDataCompositionSettings();

	ReturnStructure = New Structure;
	ReturnStructure.Insert("DataCompositionSettings", DataCompositionSettings);

	ListOfCompositeTypeFields = OperationsWithDocumentJournals.ValueOfDocumentListSettings(ThisObject,
		ListName, "ListOfCompositeTypeFields");

	StructureOfUserSettings = OperationsWithDocumentJournals.CheckUserSettingsOfDynamicList(
		DataCompositionSettings, ListOfCompositeTypeFields);

	ReturnStructure.Insert("StructureOfUserSettings", StructureOfUserSettings);
	
	Return ReturnStructure;
	
EndFunction

&AtClient
Procedure SetParametersForUpdatingDocumentLists(DataIsOutdated, UpdatingDuration = Undefined)
	
	SettingName = "ListOfDocumentsCacheSettings";
	ListName = "";
	For Each SettingUpListOfDocuments In ThisObject[SettingName] Do
		ListName = SettingUpListOfDocuments.Key;
		OperationsWithDocumentJournalsClient.SetParametersForUpdatingDocumentList(ThisObject, ListName, DataIsOutdated,
			UpdatingDuration);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateDocumentListDataWithTimeMeasurement(ListName, ConsiderAutoUpdateParameter = False)

	If Not ConsiderAutoUpdateParameter Then

		TheListNeedsToBeUpdated = True;

	Else

		TheListNeedsToBeUpdated = OperationsWithDocumentJournalsClient.SettingValueForAutoUpdatingListOfDocuments(
			ThisObject, ListName);

		If Not TheListNeedsToBeUpdated Then
			OperationsWithDocumentJournalsClient.SetFlagForDisplayingIrrelevantDataInList(ThisObject, ListName);
		EndIf;

	EndIf;

	If TheListNeedsToBeUpdated Then

		OperationsWithDocumentJournalsClient.UpdateDocumentListDataWithTimeMeasurement(ThisObject, ListName);
		DisplayingGroupOfUserSelectionsAndSettings(ListName);

	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfDocumentsEventNotificationProcessing(ListName, Parameter = Undefined)
	
	OperationsWithDocumentJournalsClient.UpdateListOfDocumentsEventNotificationProcessing(ThisObject, ListName, Parameter);
	DisplayingGroupOfUserSelectionsAndSettings(ListName);

EndProcedure

// Processing the form element event.
// 
// Parameters:
//  Item - FormField
//@skip-check module-unused-method
&AtClient
Procedure ListOfDocumentsFormElementEventHandling(Item)

	ActionForList = OperationsWithDocumentJournalsClient.NameOfListOfDocumentsByNameOfFormElement(ThisObject, Item.Name);
	
	If ActionForList.ListName = "" Then
		Return;
	EndIf;
	
	ListName = ActionForList.ListName;
	Action = ActionForList.Action;
	
	If Action = "Filters" Or Action = "Order" Or Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataLayoutSettingsHaveBeenChecked", True);
		DataCompositionSettingStructure = GetPerformingDataCompositionSettings(ListName);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"DataCompositionSettings", DataCompositionSettingStructure.DataCompositionSettings);
		OperationsWithDocumentJournalsClient.SetValueOfDocumentListSettings(ThisObject, ListName,
			"StructureOfUserSettings", DataCompositionSettingStructure.StructureOfUserSettings);
	EndIf;
	
	If Action = "Filters" Then
		OperationsWithDocumentJournalsClient.FixCustomSelectionsInDocumentList(ThisObject, ListName);
	ElsIf Action = "Order" Then
		OperationsWithDocumentJournalsClient.FixSortingSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "ConditionalAppearance" Then
		OperationsWithDocumentJournalsClient.FixConditionalAppearanceSettingsInDocumentList(ThisObject, ListName);
	ElsIf Action = "RefreshEnabled" Then
		UpdateDocumentListDataWithTimeMeasurement(ListName);
	ElsIf Action = "SpeedingUpListUpdates" Then
		OperationsWithDocumentJournalsClient.SaveSettingProductiveListUpdateMode(ThisObject, ListName);
	EndIf;
	
EndProcedure

#EndRegion

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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
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
