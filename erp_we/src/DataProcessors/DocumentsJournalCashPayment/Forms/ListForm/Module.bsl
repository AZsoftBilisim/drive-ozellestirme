
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
	
	If Parameters.Property("FormAssignmentKey") And Not IsBlankString(Parameters.FormAssignmentKey) Then
		PurposeUseKey = Parameters.FormAssignmentKey;
	Else
		PurposeUseKey = "CashPaymentJournal";
	EndIf;
	
	If PurposeUseKey = "CashPaymentJournal" Then
		SettingsKey = "";
	Else
		SettingsKey = PurposeUseKey;
	EndIf;
	URL = "e1cib/app/DataProcessor.DocumentsJournalCashPayment";
	
	SetPrivilegedMode(True);
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForReceiptsFromBankForAcquiring();
	SetPrivilegedMode(False);
	
	InitializeBankingDetails();
	SetVisibility1();
	SetListConstants();
	
	SetPaymentLogParameters();
	SetPaymentLogSelection();
	
	SetSelectionForReceiptForPayment("ToReceive");
	SetSelectionForReceiptForPayment("AmountDue");
	
	UpgradeBasementOnServer();
	
	DocumentTypes = New Array();
	DocumentTypes.Add("Document.BankAccountReceiptNote");
	DocumentTypes.Add("Document.BankAccountIssue");
	DocumentTypes.Add("Document.CashAccountReceiptNote");
	DocumentTypes.Add("Document.CashVoucher");
	DocumentTypes.Add("Document.PaymentCardTransaction");
	DocumentTypes.Add("Document.BankReportOnAcquiringTransactions");
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.CashPaymentJournal, DocumentTypes);
	
	DocumentTypesUsed = DocumentTypesUsed();
	
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.PaymentJournalCommands;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ToReceive.Date", Items.ToReceiveDate.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "AmountDue.Date", Items.AmountDueDate.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CashPaymentJournal.Date", Items.CashPaymentJournalDate.Name);
	
	SaveWorkingValuesOfFormFields(True);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	If EventName = "Write_BankAccountIssue"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Upload_ExchangeWithBanks" Then
		
		UpgradeBasementOnServer();
		
		If Items.Pages.CurrentPage = Items.PageForPayment Then
			Items.AmountDue.Refresh();
		EndIf;
		
	ElsIf EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashAccountReceiptNote"
		Or EventName = "Write_PaymentCardTransaction"
		Or EventName = "Upload_ExchangeWithBanks" Then
		
		UpgradeBasementOnServer();
		
		If Items.Pages.CurrentPage = Items.PageToReceive Then
			Items.ToReceive.Refresh();
			SetVisibilityOfReceiptByAcquiring();
		EndIf;
		
	ElsIf EventName = "Write_CompaniesBankAccounts"
		Or EventName = "Write_CashAccounts" Then
		
		ResubmitListOfBankAccountCashRegisters();
	EndIf;
	
	NamesOfPaymentListUpdateEvents = New Array;
	NamesOfPaymentListUpdateEvents.Add("Write_BankAccountIssue");
	NamesOfPaymentListUpdateEvents.Add("Write_CashVoucher");
	NamesOfPaymentListUpdateEvents.Add("Write_BankAccountReceiptNote");
	NamesOfPaymentListUpdateEvents.Add("Write_CashAccountReceiptNote");
	NamesOfPaymentListUpdateEvents.Add("Write_PaymentCardTransaction");
	NamesOfPaymentListUpdateEvents.Add("Write_CashDepositWithdrawalDiscrepancies");
	NamesOfPaymentListUpdateEvents.Add("Write_BankReportOnAcquiringTransactions");
	NamesOfPaymentListUpdateEvents.Add("Conducting_Storno");
	NamesOfPaymentListUpdateEvents.Add("Write_ReversingEntry");
	
	If NamesOfPaymentListUpdateEvents.Find(EventName) <> Undefined
		And Items.Pages.CurrentPage = Items.PaymentLogPage Then
		// DynamicListsSettings
		UpdateListOfDocumentsEventNotificationProcessing("CashPaymentJournal", Parameter);
		// End DynamicListsSettings
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetFlagForAutoUpdatingListOfDocumentsWhenUploadingDataFromSettings(ThisObject,
		"CashPaymentJournal", Settings);
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	// DynamicListsSettings
	SetParametersForUpdatingDocumentLists(False, 0);
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	If CompanySavedValue <> Organization Then
		
		OrganizingChangesWhenChangesAreMadeOnServer();
		
		FillInPresentationOfListOfCashRegistersOfBankAccounts();
		CompanySavedValue = Organization;
	EndIf;
	
EndProcedure

&AtServer
Procedure OrganizingChangesWhenChangesAreMadeOnServer()
	
	ListOfCashAccountsBankAccounts = ListOfCashAccountsBankAccounts(Organization);
	
	SetDynamicListSelection();
	SetPaymentLogSelection();
	
	UpgradeBasementOnServer();
	
	SaveWorkingValuesOfFormFields();
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	PerformanceMonitorClient.StartTimeMeasurement(,
		"DataProcessor.DocumentsJournalCashPayment.Form.ListForm.OnCurrentPageChange." + CurrentPage.Name);
	
	If CurrentPage = Items.PaymentLogPage Then
		// DynamicListsSettings
		UpdateDocumentListDataWithTimeMeasurement("CashPaymentJournal");
		// End DynamicListsSettings
		
	ElsIf CurrentPage = Items.PageToReceive Then
		Items.ToReceive.Refresh();
		
	ElsIf CurrentPage = Items.PageForPayment Then
		Items.AmountDue.Refresh();
		
	EndIf;
	
EndProcedure

#Region EventHandlersForPaymentListItems

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ValueIsFilled(BeginOfPeriod)
		And ValueIsFilled(EndOfPeriod)
		And BeginOfPeriod > EndOfPeriod Then
		BeginOfPeriod = EndOfPeriod;
	EndIf;
	SetPaymentLogParameters();
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ValueIsFilled(BeginOfPeriod)
		And ValueIsFilled(EndOfPeriod)
		And EndOfPeriod < BeginOfPeriod Then
		EndOfPeriod = BeginOfPeriod;
	EndIf;
	SetPaymentLogParameters();
	
EndProcedure

&AtClient
Procedure PaymentsSelectAPeriod(Command)
	
	Notification = New CallbackDescription("PaymentsSelectAPeriodCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(
		ThisForm, New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"), Notification);
	
EndProcedure

&AtClient
Procedure PaymentsSelectAPeriodCompletion(SelectionResult, AddlParameters) Export
	
	If SelectionResult = Undefined Then
		Return;
	EndIf;
	
	SetPaymentLogParameters();
	
EndProcedure

&AtClient
Procedure TheDocumentTypeSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("DataProcessor.DocumentsJournalCashPayment.Form.FormOfSelectionFromList",
		New Structure("List, Title, Mode", ListDocumentTypes, NStr("vi = 'Lọc theo kiểu chứng từ';
																	|ru = 'Отбор по типу документов';
																	|en = 'Filter by document type'; fa = 'فیلتر بر اساس نوع سند';
																	|it = 'Selezione per tipi di documenti';
																	|pl = 'Filtr według rodzaju dokumentów';
																	|tr = 'Belgelerin türüne göre filtre'"), 0),
		Item);
	
EndProcedure

&AtClient
Procedure TheDocumentTypeSelectionClearing(Item, StandardProcessing)
	
	ListDocumentTypes.FillChecks(False);
	
	CommonClientServer.SetDynamicListFilterItem(
		CashPaymentJournal,
		"Type",
		ListDocumentTypes,
		DataCompositionComparisonType.InList,,
		False);
		
	CommonClientServer.SetDynamicListFilterItem(
		CashPaymentJournal,
		"PaymentDocumentType",,
		DataCompositionComparisonType.InList,,
		False);
		
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
		
EndProcedure

&AtClient
Procedure TheDocumentTypeSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		StandardProcessing = False;
		ListDocumentTypes = ValueSelected;
		
		ListDocumentTypesPresentation = "";
		For Each ListItem In ListDocumentTypes Do
			If ListItem.Check Then
				ListDocumentTypesPresentation = ListDocumentTypesPresentation +
					?(ValueIsFilled(ListDocumentTypesPresentation), ", ", "") + ListItem.Presentation;
			EndIf;
		EndDo;
		
		DocumentTypeSelectionChangeOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentTypeSelectionChangeOnServer()
	
	TypeReceiptOfNonCashCash = Type("DocumentRef.BankAccountReceiptNote");
	TypeWriteOffOfNonCashCashTransfers = Type("DocumentRef.BankAccountIssue");
	
	ListOfSelectedDocumentTypes = New ValueList;
	
	ArrayOfSelectedPaymentDocumentTypes = New Array;
	For Each ListItem In ListDocumentTypes Do
		If ListItem.Check Then
			If TypeOf(ListItem.Value) = Type("Type") Then
				
				ListOfSelectedDocumentTypes.Add(ListItem.Value);
				
			ElsIf TypeOf(ListItem.Value) = Type("EnumRef.TypesOfPaymentDocuments") Then
				
				ArrayOfSelectedPaymentDocumentTypes.Add(ListItem.Value);
				If TypesOfPaymentReceiptDocument.FindByValue(ListItem.Presentation) <> Undefined
					And ListOfSelectedDocumentTypes.FindByValue(TypeReceiptOfNonCashCash) = Undefined Then
					ListOfSelectedDocumentTypes.Add(TypeReceiptOfNonCashCash);
				ElsIf TypesOfADebitPaymentDocument.FindByValue(ListItem.Presentation) <> Undefined
					And ListOfSelectedDocumentTypes.FindByValue(TypeWriteOffOfNonCashCashTransfers) = Undefined Then
					ListOfSelectedDocumentTypes.Add(TypeWriteOffOfNonCashCashTransfers);
				EndIf;
				
			EndIf;
		EndIf;
	EndDo;
	ArrayOfSelectedPaymentDocumentTypes.Add(Undefined);
	
	CommonClientServer.SetDynamicListFilterItem(
		CashPaymentJournal,
		"Type",
		ListOfSelectedDocumentTypes,
		DataCompositionComparisonType.InList,,
		ListOfSelectedDocumentTypes.Count() > 0);
		
	CommonClientServer.SetDynamicListFilterItem(
		CashPaymentJournal,
		"PaymentDocumentType",
		ArrayOfSelectedPaymentDocumentTypes,
		DataCompositionComparisonType.InList,,
		ArrayOfSelectedPaymentDocumentTypes.Count() > 0);
		
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
		
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure ListChange(Command)
	
	TMCommonUseClient.ChangeElement(Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure CashRegisterBankAccountSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenForm("DataProcessor.DocumentsJournalCashPayment.Form.FormOfSelectionFromList",
		New Structure("List, Title, Mode", ListOfCashAccountsBankAccounts, NStr("vi = 'Quỹ tiền mặt, Tài khoản ngân hàng';
																				|ru = 'Кассы, Банковские счета';
																				|en = 'Cash accounts, bank accounts'; fa = 'Cash accounts, bank accounts';
																				|it = 'Casse, conti bancari';
																				|pl = 'Kasy, konta bankowe';
																				|tr = 'Kasalar, Banka hesapları'"), 1),
		Item);
	
EndProcedure

&AtClient
Procedure CashRegisterBankAccountSelectionClearing(Item, StandardProcessing)
	
	ListOfCashAccountsBankAccounts.FillChecks(False);
	
	CommonClientServer.SetDynamicListFilterItem(
		CashPaymentJournal,
		"BankAccountCashAccount",
		ListOfCashAccountsBankAccounts,
		DataCompositionComparisonType.InList,,
		False);
	
	// DynamicListsSettings
	OperationsWithDocumentJournalsClient.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
	
EndProcedure

&AtClient
Procedure CashRegisterBankAccountSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		StandardProcessing = False;
		ListOfCashAccountsBankAccounts = ValueSelected;
		FillInPresentationOfListOfCashRegistersOfBankAccounts();
		CheckoutBankAccountSelectionChangeOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckoutBankAccountSelectionChangeOnServer()
	
	SetPaymentLogSelection();
	
EndProcedure

#EndRegion

#Region EventHandlersForListItemsToBeReceived

&AtClient
Procedure ToReceiveSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	Ref = Item.CurrentData.Ref;
	If ValueIsFilled(Ref) Then
		ShowValue(, Ref);
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOfReceiptSelectionOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateToBeReceivedSelectionWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DateToBeReceivedSelectionWhenChangedOnServer()
	
	SetSelectionForReceiptForPayment("ToReceive");
	UpdateToReceipt();
	
EndProcedure

&AtClient
Procedure ListOfOperationsToBeReceivedSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		New Structure("TransactionList, Title", TransactionListReceipts, NStr("vi = 'Căn cứ để thanh toán';
																				|ru = 'Основания платежа';
																				|en = 'Payment base objects'; fa = 'موضوعات مبنای پرداخت';
																				|it = 'Motivazioni del pagamento';
																				|pl = 'Podstawy płatności';
																				|tr = 'Ödeme gerekçesi'")), Item);
	
EndProcedure

&AtClient
Procedure ListOfOperationsToBeReceivedSelectionClearing(Item, StandardProcessing)
	
	TransactionListReceipts.FillChecks(False);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure ListOfOperationsToBeReceivedSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
		
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		TransactionListReceipts = ValueSelected;
		
	ElsIf TypeOf(ValueSelected) = Type("EnumRef.PaymentPlanningAreas") Then
		
		For Each ListItem In TransactionListReceipts Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	TransactionListReceiptsPresentation = TransactionListPresentation(TransactionListReceipts);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure PaymentMethodToReceiveFilterOnChange(Item)
	
	ListOfPaymentForms = New ValueList;
	
	If ValueIsFilled(PaymentMethodToReceiveFilter) Then
		ListOfPaymentForms.Add(PaymentMethodToReceiveFilter);
		ListOfPaymentForms.Add(PredefinedValue("Enum.PaymentForms.EmptyRef"));
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ToReceive,
		"PaymentMethod",
		ListOfPaymentForms,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(PaymentMethodToReceiveFilter));
	
EndProcedure

#EndRegion

#Region EventHandlersForListItemsPayable

&AtClient
Procedure AmountDueSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ShowValue(, Items.AmountDue.CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure DateToBePaidSelectionOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	PaymentDueDateSelectionWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure PaymentDueDateSelectionWhenChangedOnServer()
	
	SetSelectionForReceiptForPayment("AmountDue");
	ReadyForPayment();
	
EndProcedure

&AtClient
Procedure ListOfTransactionsToBePaidSelectionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("Enum.BusinessTransactions.Form.SelectionFormOfTransaction",
		New Structure("TransactionList, Title", TransactionListPayments, NStr("vi = 'Căn cứ để thanh toán';
																				|ru = 'Основания платежа';
																				|en = 'Payment base objects'; fa = 'موضوعات مبنای پرداخت';
																				|it = 'Motivazioni del pagamento';
																				|pl = 'Podstawy płatności';
																				|tr = 'Ödeme gerekçesi'")), Item);

EndProcedure

&AtClient
Procedure ListOfTransactionsToBePaidSelectionClearing(Item, StandardProcessing)
	
	TransactionListPayments.FillChecks(False);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure ListOfTransactionsToBePaidSelectionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
		
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		TransactionListPayments = ValueSelected;
		
	ElsIf TypeOf(ValueSelected) = Type("EnumRef.PaymentPlanningAreas") Then
		
		For Each ListItem In TransactionListPayments Do
			ListItem.Check = (ListItem.Value = ValueSelected);
		EndDo;
	EndIf;
	
	TransactionListPaymentsPresentation = TransactionListPresentation(TransactionListPayments);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure PaymentMethodForPaymentFilterOnChange(Item)
	
	ListOfPaymentForms = New ValueList;
	
	If ValueIsFilled(PaymentMethodForPaymentFilter) Then
		ListOfPaymentForms.Add(PaymentMethodForPaymentFilter);
		ListOfPaymentForms.Add(PredefinedValue("Enum.PaymentForms.EmptyRef"));
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		AmountDue,
		"PaymentMethod",
		ListOfPaymentForms,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(PaymentMethodForPaymentFilter));
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlersForPaymentLogItems

&AtClient
Procedure CashPaymentJournalOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
	If Item.CurrentData <> Undefined Then
		DocumentType = Item.CurrentData.Type;
		Items.ProcessedByBank.Enabled =
			(DocumentType = Type("DocumentRef.BankAccountReceiptNote")
				Or DocumentType = Type("DocumentRef.BankAccountIssue"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CashPaymentJournalSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

&AtClient
Procedure CashPaymentJournalBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		CreatePaymentFromBankAccount(PredefinedValue("Enum.BusinessTransactions.PaymentToVendor"));
	EndIf;
	
EndProcedure

&AtClient
Procedure CashPaymentJournalBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure CashPaymentJournalBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title);
	
EndProcedure

&AtServer
Procedure CashPaymentJournalOnUpdateUserSettingSetAtServer(Item, StandardProcessing)
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersToReceive

&AtClient
Procedure ToReceiveOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetVisibilityOfReceiptByAcquiring();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region PaymentListCommandHandlers

&AtClient
Procedure CreateAReceiptFromAClientInCash(Command)
	CreateCashReceiptOrder(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer"));
EndProcedure

&AtClient
Procedure CreateAReceiptFromAClientByBankTransfer(Command)
	CreateInpayment(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer"));
EndProcedure

&AtClient
Procedure CreateAReceiptFromACustomerPaymentCard(Command)
	CreateAcquiringOperation(PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer"))
EndProcedure

&AtClient
Procedure CreateAPaymentToTheSupplierInCash_3(Command)
	CreateSpendingCashOrder(PredefinedValue("Enum.BusinessTransactions.PaymentToVendor"));
EndProcedure

&AtClient
Procedure CreateAPaymentToTheSupplierByBankTransfer(Command)
	CreatePaymentFromBankAccount(PredefinedValue("Enum.BusinessTransactions.PaymentToVendor"));
EndProcedure

&AtClient
Procedure CreateCashReceiptStatement(Command)
	CreateCashReceiptOrder();
EndProcedure

&AtClient
Procedure CreateCashVoucher(Command)
	CreateSpendingCashOrder();
EndProcedure

&AtClient
Procedure CreateIncomingPaymentOrder(Command)
	CreateInpayment(, PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentOrder"));
EndProcedure

&AtClient
Procedure CreateOutgoingPaymentOrder(Command)
	CreatePaymentFromBankAccount(, PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentOrder"));
EndProcedure

&AtClient
Procedure CreateRefundToCustomerAcquiring(Command)
	CreateAcquiringOperation(PredefinedValue("Enum.BusinessTransactions.RefundToCustomer"))
EndProcedure

&AtClient
Procedure CreateBankAcquiringReport(Command)
	OpenForm("Document.BankReportOnAcquiringTransactions.ObjectForm", , Items.CashPaymentJournal);
EndProcedure

&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.CashPaymentJournal, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "CashPaymentJournal"));
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.CashPaymentJournal, Title,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "CashPaymentJournal"));
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.CashPaymentJournal, Title, Undefined,
		OperationsWithDocumentJournalsClient.ParametersForUpdatingDocumentList(ThisObject, "CashPaymentJournal"));
	
EndProcedure

&AtClient
Procedure ExportToBank(Command)
	
	OpenForm("DataProcessor.EDIWithBanks.Form.ExportToBank",, Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure ImportStatement(Command)
	
	OpenForm("DataProcessor.EDIWithBanks.Form.ImportStatement",, Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure ProcessedByBank(Command)
	
	ClearMessages();
	
	Rows = Items.CashPaymentJournal.SelectedRows;
	References = CheckGetLinksHighlightedInList(Rows, Items.CashPaymentJournal);
	
	DocumentsForHolding = DeleteExtraDocuments(References);
	If DocumentsForHolding.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	
	WhenInstallingBank = New CallbackDescription("WhenInstallingBank", ThisForm, DocumentsForHolding);
	ShowInputDate(WhenInstallingBank, CurrentDate(), NStr("vi = 'Hãy chỉ ra ngày thực hiện bởi ngân hàng';
															|ru = 'Укажите дату проведения банком';
															|en = 'Specify a date of processing by bank'; fa = 'Specify a date of processing by bank';
															|it = 'Indicate la data della registrazione dalla banca';
															|pl = 'Wprowadź datę zatwierdzenia przez bank';
															|tr = 'Banka ile kayıt tarihini belirt'"), DateFractions.Date);
	
EndProcedure

&AtServer
Function DeleteExtraDocuments(DocumentsArray)
	
	DocumentsForHolding = New Array;
	
	ArrayOfDocumentTypes_ = New Array;
	ArrayOfDocumentTypes_.Add(Type("DocumentRef.BankAccountReceiptNote"));
	ArrayOfDocumentTypes_.Add(Type("DocumentRef.BankAccountIssue"));
	
	For Each DocumentRef In DocumentsArray Do
		If ArrayOfDocumentTypes_.Find(TypeOf(DocumentRef)) <> Undefined Then
			DocumentsForHolding.Add(DocumentRef);
		EndIf;
	EndDo;
	
	Return DocumentsForHolding;
	
EndFunction

&AtClient
Procedure WhenInstallingBank(BankPostingDate, DocumentsArray) Export
	
	If BankPostingDate <> Undefined Then
		
		ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
			DocumentsArray,
			"ProcessedByBank",
			New Structure("BankPostingDate", BankPostingDate));
		
		// DynamicListsSettings
		UpdateDocumentListDataWithTimeMeasurement("CashPaymentJournal", True);
		// End DynamicListsSettings
		UpgradeBasementOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTheBalanceAndCashFlowReport(Command)
	
	FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen");
	
	Filter = New Structure;
	
	ReportPeriod = New StandardPeriod;
	ReportPeriod.Variant = StandardPeriodVariant.ThisMonth;
	Filter.Insert("ReportPeriod", ReportPeriod);
	
	CashTypes = New ValueList;
	CashTypes.Add(PredefinedValue("Enum.CashTypes.BankAccountPayments_"));
	CashTypes.Add(PredefinedValue("Enum.CashTypes.CashPayment"));
	Filter.Insert("CashType", CashTypes);
	
	If ValueIsFilled(Organization) Then
		Filter.Insert("Organization", Organization);
	EndIf;
	
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("PurposeUseKey", "CashPaymentJournal");
	FormParameters.Insert("VariantKey", "CashStatement");
	FormParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.CashStatement.Form", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenCashControlReport(Command)
	
	FormParameters = New Structure("Filter, PurposeUseKey, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	
	Filter = New Structure;
	If ValueIsFilled(Organization) Then
		Filter.Insert("Organization", Organization);
	EndIf;
	FormParameters.Insert("Filter", Filter);
	
	FormParameters.PurposeUseKey = "CashTransactionControl";
	FormParameters.VariantKey = "CashTransactionControl";
	
	OpenForm("Report.CashTransactionControl.Form", FormParameters, ThisForm);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	ClearMessages();
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.CashPaymentJournal);

EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.CashPaymentJournal, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.CashPaymentJournal);
EndProcedure
// End StandardSubsystems.AttachableCommands


#EndRegion

#Region CommandHandlersForPayment

&AtClient
Procedure PayForDocumentInCash(Command)
	
	CashClient.PayChartLines(Items.AmountDue, "CashVoucher");
	
EndProcedure

&AtClient
Procedure PayForDocumentViaElectronicTransfer(Command)
	
	CashClient.PayChartLines(Items.AmountDue, "BankAccountIssue");
	
EndProcedure

&AtClient
Procedure AcceptPaymentInCash(Command)
	
	CashClient.PayChartLines(Items.ToReceive, "CashAccountReceiptNote");
	
EndProcedure

&AtClient
Procedure AcceptPaymentViaElectronicTransfer(Command)
	
	CashClient.PayChartLines(Items.ToReceive, "BankAccountReceiptNote");
	
EndProcedure

&AtClient
Procedure ReceiveAcquiringPayment(Command)
	
	If Items.ToReceive.SelectedRows.Count() = 1 Then
		CashClient.PayChartLines(Items.ToReceive, "PaymentCardTransaction");
	EndIf;
	
EndProcedure

#EndRegion

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command, ThisForm, Items.CashPaymentJournal);
	
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
Procedure CreateOutgoingBankOrder(Command)
	CreatePaymentFromBankAccount(, PredefinedValue("Enum.TypesOfPaymentDocuments.BankPaymentOrder"));
EndProcedure

&AtClient
Procedure CreateIncomingCollectionOrder(Command)
	CreateInpayment(, PredefinedValue("Enum.TypesOfPaymentDocuments.CollectionOrder_2"));
EndProcedure

&AtClient
Procedure CreateIncomingDemandForPayment(Command)
	CreateInpayment(, PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentDemand"));
EndProcedure

&AtClient
Procedure CreateIncomingPaymentWarrant(Command)
	CreateInpayment(, PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentWarrant"));
EndProcedure

&AtClient
Procedure CreateOutgoingCollectionOrder(Command)
	CreatePaymentFromBankAccount(, PredefinedValue("Enum.TypesOfPaymentDocuments.CollectionOrder_2"));
EndProcedure

&AtClient
Procedure CreateOutgoingDemandForPayment(Command)
	CreatePaymentFromBankAccount(, PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentDemand"));
EndProcedure

&AtClient
Procedure CreateOutgoingPaymentWarrant(Command)
	CreatePaymentFromBankAccount(, PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentWarrant"));
EndProcedure

&AtClient
Procedure DocumentsListRefresh(Command)
	
	// DynamicListsSettings
	UpdateDocumentListDataWithTimeMeasurement("CashPaymentJournal");
	// End DynamicListsSettings
	
EndProcedure

#EndRegion

#Region Private

#Region Initialize

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ToReceivePaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ToReceive.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AmountDuePaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AmountDue.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
EndProcedure

&AtServer
Procedure InitializeBankingDetails()
	
	Currency = Constants.ManagementAccountingCurrency.Get();
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	
	
	ListDocumentTypes            = ListDocumentTypes();
	ListOfCashAccountsBankAccounts      = ListOfCashAccountsBankAccounts(Organization);
	InitializeListOfPaymentOperations();
	InitializeListOfReceiptOperations();
	FillInPaymentDocumentTypes();
	FillInTypesOfDebitedPaymentDocument();
	
	CashPaymentJournal.Parameters.SetParameterValue("IDOfTheObjectReceiptOfNonCashDS",
		Common.MetadataObjectID("Document.BankAccountReceiptNote"));
	CashPaymentJournal.Parameters.SetParameterValue("TheObjectIDOfTheNonCashWriteOffOfDS",
		Common.MetadataObjectID("Document.BankAccountIssue"));
	CashPaymentJournal.Parameters.SetParameterValue("IDOfThePKOObject",
		Common.MetadataObjectID("Document.CashAccountReceiptNote"));
	CashPaymentJournal.Parameters.SetParameterValue("IDOfTheRKOObject",
		Common.MetadataObjectID("Document.CashVoucher"));
	CashPaymentJournal.Parameters.SetParameterValue("TheObjectIDOfTheReportOnOperationsOfTheAcquiring",
		Common.MetadataObjectID("Document.BankReportOnAcquiringTransactions"));
	CashPaymentJournal.Parameters.SetParameterValue("TheObjectIDTheTransactionWithTheCreditCard",
		Common.MetadataObjectID("Document.PaymentCardTransaction"));
	CashPaymentJournal.Parameters.SetParameterValue("AnObjectIDIsAReflectionOfTheDiscrepanciesInCashCollection",
		Common.MetadataObjectID("Document.CashDepositWithdrawalDiscrepancies"));
	
	DateOfFuturePayments = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextMonth);
	DateForReceipt = DateOfFuturePayments.Date;
	DateForPayment = DateOfFuturePayments.Date;
	
	UnavailableOfOperationsForAcquiring = ListOfUnavailableAcquiringOfOperations();
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	VisibilityOfElements = New Map;
	
	ItemArray = New Array;
	ItemArray.Add("CompanyFilter");
	ItemArray.Add("ToReceiveOrganization");
	ItemArray.Add("AmountDueOrganization");
	
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleCompanies"));
	
	ItemArray = New Array;
	ItemArray.Add("ToReceiveCreateAReceiptDocumentBasedOnPaymentCard");
	ItemArray.Add("CreateAReceiptFromACustomerPaymentCard");
	ItemArray.Add("CreateAReceiptFromACustomerPaymentCardOther");
	ItemArray.Add("CreateRefundToCustomerAcquiring");
	ItemArray.Add("CreateBankAcquiringReport");
	
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UsePaymentByCards"));
	
	ItemArray = New Array;
	ItemArray.Add("CashPaymentJournalCurrency");
	ItemArray.Add("ToReceiveCurrency");
	ItemArray.Add("AmountDueCurrency");
	
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleCurrencies"));
	
	ItemArray = New Array;
	ItemArray.Add("CreateAReceiptFromACustomerInCash");
	ItemArray.Add("ToReceiveCreateAReceiptDocumentBasedOnCash");
	ItemArray.Add("CreateCashReceiptStatement");
	
	VisibilityOfElements.Insert(ItemArray, AccessRight("Insert", Metadata.Documents.CashAccountReceiptNote));
	
	ItemArray = New Array;
	ItemArray.Add("CreateAPaymentToTheSupplierInCash");
	ItemArray.Add("ToPayCreateAPaymentDocumentBasedOnCash");
	ItemArray.Add("CreateCashVoucher");
	
	VisibilityOfElements.Insert(ItemArray, AccessRight("Insert", Metadata.Documents.CashVoucher));
	
	ItemArray = New Array;
	ItemArray.Add("CreateAReceiptFromACustomerPaymentCard");
	ItemArray.Add("CreateAReceiptFromACustomerPaymentCardOther");
	ItemArray.Add("CreateRefundToCustomerAcquiring");
	
	VisibilityOfElements.Insert(ItemArray, AccessRight("Insert", Metadata.Documents.PaymentCardTransaction)
		And GetFunctionalOption("UsePaymentByCards"));
		
	For Each MapItem In VisibilityOfElements Do
		For Each TagName In MapItem.Key Do
			Items[TagName].Visible = MapItem.Value;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region ListManagement_

&AtServer
Function ArrayOfDynamicLists()
	
	ArrayOfLists = New Array;
	ArrayOfLists.Add(CashPaymentJournal);
	ArrayOfLists.Add(ToReceive);
	ArrayOfLists.Add(AmountDue);
	
	Return ArrayOfLists;
	
EndFunction

&AtServer
Procedure SetDynamicListSelection()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	For Each DynamicList In ArrayOfDynamicLists() Do
		
		CommonClientServer.SetDynamicListFilterItem(
			DynamicList,
			"Organization",
			CompaniesList,
			DataCompositionComparisonType.InList,,
			ValueIsFilled(Organization));
	EndDo;
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
	
	PlanningAreas = New Array;
	For Each ListItem In TransactionListReceipts Do
		If ListItem.Check Then
			PlanningAreas.Add(ListItem.Value);
		EndIf;
	EndDo;
	CommonClientServer.SetDynamicListFilterItem(
		ToReceive,
		"PlanningArea",
		PlanningAreas,
		DataCompositionComparisonType.InList,,
		PlanningAreas.Count());
		
	PlanningAreas = New Array;
	For Each ListItem In TransactionListPayments Do
		If ListItem.Check Then
			PlanningAreas.Add(ListItem.Value);
		EndIf;
	EndDo;
	CommonClientServer.SetDynamicListFilterItem(
		AmountDue,
		"PlanningArea",
		PlanningAreas,
		DataCompositionComparisonType.InList,,
		PlanningAreas.Count());
	
EndProcedure

&AtServer
Procedure SetListConstants()
	
	CashPaymentJournal.Parameters.SetParameterValue("BankAcquiringReport", NStr("vi = 'Báo cáo của ngân hàng theo dịch vụ thẻ thanh toán';
																				|ru = 'Отчет банка по эквайрингу';
																				|en = 'Merchant statement'; fa = 'صورتحساب پذیرنده';
																				|it = 'Report della banca sull''acquiring';
																				|pl = 'Raport banku z acquiringu';
																				|tr = 'İşyeri ekstresi'"));
	
EndProcedure

&AtServer
Procedure SetPaymentLogParameters()
	
	CashPaymentJournal.Parameters.SetParameterValue("BeginOfPeriod", BeginOfPeriod);
	CashPaymentJournal.Parameters.SetParameterValue("EndOfPeriod", ?(ValueIsFilled(EndOfPeriod), EndOfDay(EndOfPeriod), EndOfDay(Date(3999, 12, 31))));
	
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetPaymentLogSelection()
	
	FilterList = New ValueList;
	For Each ListItem In ListOfCashAccountsBankAccounts Do
		If ListItem.Check Then
			FilterList.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(CashPaymentJournal,
																			"BankAccountCashAccount",
																			FilterList,
																			DataCompositionComparisonType.InHierarchy,
																			,
																			ValueIsFilled(FilterList));
																			
	// DynamicListsSettings
	OperationsWithDocumentJournals.SetVisibilityOfDefaultUpdateSettingsGroup(ThisObject, "CashPaymentJournal");
	// End DynamicListsSettings
	
EndProcedure

&AtServer
Procedure SetSelectionForReceiptForPayment(ListName)
	
	DateParameter = Date('39990101');
	If ListName = "ToReceive" Then
		DateParameter = DateForReceipt;
	ElsIf ListName = "AmountDue" Then
		DateParameter = DateForPayment;
	EndIf;
	
	Log = ThisForm[ListName]; // DynamicList
	Boundary = ?(ValueIsFilled(DateParameter), EndOfDay(DateParameter), Date('39990101'));
	Log.Parameters.SetParameterValue("PaymentDate", Boundary);
	
EndProcedure

&AtServer
Procedure UpdateToReceipt()
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	CustomersARAPAccounting.Currency AS Currency,
	|	CustomersARAPAccounting.AmountDueBalance AS AmountToBeReceived
	|	
	|INTO AmountsDue
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(&PaymentDate, ARAPObject.Object <> UNDEFINED) AS CustomersARAPAccounting
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	CustomersARAPAccounting.AmountDueBalance > 0
	|	AND (DimensionKeys.Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	VendorsARAPAccounting.Currency,
	|	VendorsARAPAccounting.AmountDueBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(&PaymentDate, ARAPObject.Object REFS Document.ReturnOfGoodsToVendor) AS VendorsARAPAccounting
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionKeys
	|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeys.DimensionKey
	|WHERE
	|	VendorsARAPAccounting.AmountDueBalance > 0
	|	AND (DimensionKeys.Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.Currency,
	|	Cash.SumBalance
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(&PaymentDate,
	|		(Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))) AS Cash
	|WHERE
	|	Cash.SumBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	Cash.Currency,
	|	Cash.SumBalance
	|FROM
	|	AccumulationRegister.CashInTransit.Balance(&PaymentDate,
	|		(Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|		AND CashTransferKind IN (
	|				VALUE(Enum.CashTransferKinds.CashCollectionFromBank_),
	|				VALUE(Enum.CashTransferKinds.TransferToAnotherCashAccount),
	|				VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring),
	|				VALUE(Enum.CashTransferKinds.CashDepositToBank),
	|				VALUE(Enum.CashTransferKinds.CashTransferToOtherAccount))
	|		) AS Cash
	|WHERE
	|	Cash.SumBalance > 0
	|;
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT ALLOWED
	|	SUM(AmountsDue.AmountToBeReceived
	|	* (ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1))
	|	* (ISNULL(ReportCurrencyRate.CourseDenominator, 1) / ISNULL(ReportCurrencyRate.CourseNumerator, 1))) AS AmountToBeReceived
	|FROM
	|	AmountsDue AS AmountsDue
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|	ON
	|		CurrencyExchangeRate.Currency = AmountsDue.Currency
	|
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS ReportCurrencyRate
	|	ON
	|		TRUE
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("PaymentDate",
		New Boundary(?(ValueIsFilled(DateForReceipt), EndOfDay(DateForReceipt), DateForReceipt), BoundaryType.Including));
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		AmountToBeReceived = Selection.AmountToBeReceived;
	Else
		AmountToBeReceived = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadyForPayment()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners
	|INTO DimensionKeysOfAccountingByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|WHERE
	|	RegisterAccountingAnalyticsForPartners.Organization = &Organization
	|	OR &Organization = VALUE(Catalog.Companies.EmptyRef)
	|INDEX BY
	|	AccountingDimensionByPartners
	|;
	|
	|SELECT ALLOWED
	|	SUM(-VendorsARAPAccounting.AmountDueBalance
	|	* (ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1))
	|	* (ISNULL(ReportCurrencyRate.CourseDenominator, 1) / ISNULL(ReportCurrencyRate.CourseNumerator, 1))) AS AmountToPay
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(&PaymentDate,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					AccountingDimensionByPartners
	|				FROM
	|					DimensionKeysOfAccountingByPartners)
	|			AND ARAPObject.Object <> UNDEFINED) AS VendorsARAPAccounting
	|		LEFT JOIN
	|			InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|		ON
	|			CurrencyExchangeRate.Currency = VendorsARAPAccounting.Currency
	|		LEFT JOIN
	|			InformationRegister.RelativeExchangeRates.SliceLast(, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS ReportCurrencyRate
	|		ON
	|			TRUE
	|WHERE
	|	VendorsARAPAccounting.AmountDueBalance < 0
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("PaymentDate",
		New Boundary(?(ValueIsFilled(DateForPayment), EndOfDay(DateForPayment), DateForPayment), BoundaryType.Including));
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		AmountToPay = Selection.AmountToPay;
	Else
		AmountToPay = 0;
	EndIf;
	
	ExpectedAmount = AmountTotal - AmountToPay;
	
EndProcedure

&AtServer
Procedure UpdateCashBalances()
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	ISNULL(SUM(BankAccountCash.ToWriteOffBalance
	|	* (ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1))
	|	* (ISNULL(ReportCurrencyRate.CourseDenominator, 1) / ISNULL(ReportCurrencyRate.CourseNumerator, 1))), 0) AS AmountToBeDebited_
	|FROM
	|	AccumulationRegister.BankAccountCash.Balance(,
	|		(Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))) AS BankAccountCash
	|
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(, BaseCurrency = &BaseCurrency) AS CurrencyExchangeRate
	|	ON
	|		CurrencyExchangeRate.Currency = BankAccountCash.BankAccount.CashCurrency
	|
	|	LEFT JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS ReportCurrencyRate
	|	ON
	|		TRUE
	|;
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT ALLOWED
	|	CashAccountBalance.SumManBalance        AS AmountInCash
	|FROM
	|	AccumulationRegister.CashAccountBalance.Balance(,
	|		(Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))) AS CashAccountBalance
	|;
	|/////////////////////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT ALLOWED
	|	BankAccountCash.SumManBalance     AS AmountOnAccounts
	|FROM
	|	AccumulationRegister.BankAccountCash.Balance(,
	|		(Organization = &Organization OR &Organization = VALUE(Catalog.Companies.EmptyRef))) AS BankAccountCash
	|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));

	
	Result = Query.ExecuteBatch();
	
	Selection = Result[1].Select();
	Selection.Next();
	AmountAvailableCashAccountBalance = Selection.AmountInCash;
	
	Selection = Result[2].Select();
	Selection.Next();
	AmountAvailableAccountBalance = Selection.AmountOnAccounts;
	
	AmountTotal = AmountAvailableAccountBalance + AmountAvailableCashAccountBalance;
	
	Selection = Result[0].Select();
	If Selection.Next() Then
		AmountAvailableAccountBalance = AmountAvailableAccountBalance + Selection.AmountToBeDebited_;
		AmountTotal = AmountTotal + Selection.AmountToBeDebited_;
	EndIf;
	
	ExpectedAmount = AmountTotal - AmountToPay;
	
EndProcedure

&AtServer
Procedure UpgradeBasementOnServer()
	
	UpdateCashBalances();
	ReadyForPayment();
	UpdateToReceipt();
	
EndProcedure

#EndRegion

#Region CreatingDocuments

&AtClient
Procedure CreateCashReceiptOrder(BusinessOperation = Undefined)

	FillingData = New Structure;
	FillingData.Insert("BusinessOperation", BusinessOperation);
	If ValueIsFilled(Organization) Then
		FillingData.Insert("Organization", Organization);
	EndIf;
	
	CheckoutArray = ArrayOfSelectedBankAccountCashRegisters(ListOfCashAccountsBankAccounts, "CashAccount");
	If CheckoutArray.Count() = 1 Then
		FillingData.Insert("CashAccount", CheckoutArray[0]);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", FillingData);
	
	OpenForm("Document.CashAccountReceiptNote.ObjectForm", ParametersStructure1, Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure CreateSpendingCashOrder(BusinessOperation = Undefined)

	FillingData = New Structure;
	FillingData.Insert("BusinessOperation", BusinessOperation);
	If ValueIsFilled(Organization) Then
		FillingData.Insert("Organization", Organization);
	EndIf;
	
	CheckoutArray = ArrayOfSelectedBankAccountCashRegisters(ListOfCashAccountsBankAccounts, "CashAccount");
	If CheckoutArray.Count() = 1 Then
		FillingData.Insert("CashAccount", CheckoutArray[0]);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", FillingData);
	
	OpenForm("Document.CashVoucher.ObjectForm", ParametersStructure1, Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure CreateInpayment(BusinessOperation = Undefined, PaymentDocumentType = Undefined)

	If Not ValueIsFilled(PaymentDocumentType) Then
		PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentOrder");
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("BusinessOperation", BusinessOperation);
	FillingData.Insert("PaymentDocumentType", PaymentDocumentType);
	If ValueIsFilled(Organization) Then
		FillingData.Insert("Organization", Organization);
	EndIf;
	
	ArrayOfBankAccounts = ArrayOfSelectedBankAccountCashRegisters(ListOfCashAccountsBankAccounts, "BankAccount");
	If ArrayOfBankAccounts.Count() = 1 Then
		FillingData.Insert("BankAccount", ArrayOfBankAccounts[0]);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", FillingData);
	
	OpenForm("Document.BankAccountReceiptNote.ObjectForm", ParametersStructure1, Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure CreatePaymentFromBankAccount(BusinessOperation = Undefined, PaymentDocumentType = Undefined)

	If Not ValueIsFilled(PaymentDocumentType) Then
		PaymentDocumentType = PredefinedValue("Enum.TypesOfPaymentDocuments.PaymentOrder");
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("BusinessOperation", BusinessOperation);
	FillingData.Insert("PaymentDocumentType", PaymentDocumentType);
	If ValueIsFilled(Organization) Then
		FillingData.Insert("Organization", Organization);
	EndIf;
	
	ArrayOfBankAccounts = ArrayOfSelectedBankAccountCashRegisters(ListOfCashAccountsBankAccounts, "BankAccount");
	If ArrayOfBankAccounts.Count() = 1 Then
		FillingData.Insert("BankAccount", ArrayOfBankAccounts[0]);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", FillingData);
	
	OpenForm("Document.BankAccountIssue.ObjectForm", ParametersStructure1, Items.CashPaymentJournal);
	
EndProcedure

&AtClient
Procedure CreateAcquiringOperation(BusinessOperation = Undefined)
	
	FillingData = New Structure;
	FillingData.Insert("BusinessOperation", BusinessOperation);
	If ValueIsFilled(Organization) Then
		FillingData.Insert("Organization", Organization);
	EndIf;
	
	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("Basis", FillingData);
	
	OpenForm("Document.PaymentCardTransaction.ObjectForm", ParametersStructure1, Items.CashPaymentJournal);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure FillInPresentationOfListOfCashRegistersOfBankAccounts()
	
	ListOfCashAccountsBankAccountsPresentation = "";
	For Each ListItem In ListOfCashAccountsBankAccounts Do
		If ListItem.Check Then
			ListOfCashAccountsBankAccountsPresentation = ListOfCashAccountsBankAccountsPresentation +
				?(ValueIsFilled(ListOfCashAccountsBankAccountsPresentation), ", ", "") + ListItem.Value;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ListDocumentTypes()
	
	List = New ValueList;
	
	List.Add(Type("DocumentRef.CashAccountReceiptNote"),                NStr("vi = 'Phiếu thu 01-TT';
																			|ru = 'Приходный кассовый ордер';
																			|en = 'Incoming payment — Cash account'; fa = 'دریافت — صندوق';
																			|it = 'Reversale di incasso';
																			|pl = 'Asygnata kasowa przychodowa';
																			|tr = 'Gelen ödeme - kasa hesabı'"));
	List.Add(Type("DocumentRef.CashVoucher"),                NStr("vi = 'Phiếu chi';
																	|ru = 'Расходный кассовый ордер';
																	|en = 'Outgoing payment — Cash account'; fa = 'پرداخت خروجی — صندوق';
																	|it = 'Mandato di pagamento';
																	|pl = 'Asygnata kasowa rozchodowa';
																	|tr = 'Giden ödeme - kasa hesabı'"));
	
	List.Add(Enums.TypesOfPaymentDocuments.PaymentOrder,     NStr("vi = 'Ủy nhiệm chi đầu vào';
																	|ru = 'Платежное поручение входящее';
																	|en = 'Incoming payment order'; fa = 'دستور پرداخت ورودی';
																	|it = 'Ordine di bonifico in entrata';
																	|pl = 'Zamówienie płatnicze przychodzące';
																	|tr = 'Gelen ödeme emri'"));
	List.Add(Enums.TypesOfPaymentDocuments.PaymentOrder,     NStr("vi = 'Ủy nhiệm chi đầu ra';
																	|ru = 'Платежное поручение исходящее';
																	|en = 'Outgoing payment order'; fa = 'دستور پرداخت خروجی';
																	|it = 'Ordine di bonifico in uscita';
																	|pl = 'Zamówienie płatnicze wychodzące';
																	|tr = 'Giden ödeme emri'"));

	If GetFunctionalOption("UsePaymentByCards") Then
		List.Add(Type("DocumentRef.PaymentCardTransaction"),              NStr("vi = 'Giao dịch theo thẻ thanh toán';
																				|ru = 'Эквайринговая операция';
																				|en = 'Acquiring transaction'; fa = 'معامله پذیرندگی';
																				|it = 'Operazione acquisizione';
																				|pl = 'Operacja acquiringu';
																				|tr = 'PoS işlemi'"));
		List.Add(Type("DocumentRef.BankReportOnAcquiringTransactions"),       NStr("vi = 'Báo cáo của ngân hàng theo dịch vụ thẻ thanh toán';
																					|ru = 'Отчет банка по эквайрингу';
																					|en = 'Merchant statement'; fa = 'صورتحساب پذیرنده';
																					|it = 'Report della banca sull''acquiring';
																					|pl = 'Raport banku z acquiringu';
																					|tr = 'İşyeri ekstresi'"));
	EndIf;
	
	List.Add(Type("DocumentRef.CashDepositWithdrawalDiscrepancies"),
		NStr("vi = 'Phản ánh chênh lệch khi chuyển tiền nội bộ';
			|ru = 'Отражение расхождений при инкассации ДС';
			|en = 'Cash deposit/withdrawal discrepancies'; fa = 'مغایرت‌های واریز/برداشت وجه نقد';
			|it = 'Rilevazione delle discrepanze all''incasso del denaro';
			|pl = 'Odzwierciedlenie odchylenia podczas inkasacji środków pieniężnych';
			|tr = 'Nakit yatırma sırasında tutarsızlıkların yansıtılması'"));
	
	Return List;
	
EndFunction

&AtServer
Function FillInPaymentDocumentTypes()
	
	TypesOfPaymentReceiptDocument.Clear();
	TypesOfPaymentReceiptDocument.Add(NStr("vi = 'Ủy nhiệm chi đầu vào';
											|ru = 'Платежное поручение входящее';
											|en = 'Incoming payment order'; fa = 'دستور پرداخت ورودی';
											|it = 'Ordine di bonifico in entrata';
											|pl = 'Zamówienie płatnicze przychodzące';
											|tr = 'Gelen ödeme emri'"));
	
EndFunction

&AtServer
Function FillInTypesOfDebitedPaymentDocument()
	
	TypesOfADebitPaymentDocument.Clear();
	TypesOfADebitPaymentDocument.Add(NStr("vi = 'Ủy nhiệm chi đầu ra';
											|ru = 'Платежное поручение исходящее';
											|en = 'Outgoing payment order'; fa = 'دستور پرداخت خروجی';
											|it = 'Ordine di bonifico in uscita';
											|pl = 'Zamówienie płatnicze wychodzące';
											|tr = 'Giden ödeme emri'"));
	
EndFunction

&AtServerNoContext
Function ListOfCashAccountsBankAccounts(Organization)
	
	List = New ValueList;
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED DISTINCT
	|	CheckoutBankAccounts.Ref AS Ref
	|FROM
	|(SELECT
	|	CashAccounts.Ref AS Ref
	|FROM
	|	Catalog.CashAccounts AS CashAccounts
	|WHERE
	|	NOT CashAccounts.DeletionMark
	|	AND (CashAccounts.Owner = &Organization
	|		OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|	
	|UNION ALL
	|	
	|SELECT
	|	CompaniesBankAccounts.Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|WHERE
	|	NOT CompaniesBankAccounts.DeletionMark
	|	AND (CompaniesBankAccounts.Owner = &Organization
	|		OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|) AS CheckoutBankAccounts
	|";
	
	Query.SetParameter("Organization", Organization);
	
	Result = Query.Execute();
	If Not Result.IsEmpty() Then
		List.LoadValues(Result.Unload().UnloadColumn("Ref"));
	EndIf;
	
	Return List;
	
EndFunction

&AtServer
Procedure InitializeListOfReceiptOperations()
	
	TransactionListReceipts.Clear();
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.CustomersARAPAccounting);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.ReturnsFromVendors);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.CashInTransit);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.LoansOrBorrowingsReceived);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.Deposits);
	TransactionListReceipts.Add(Enums.PaymentPlanningAreas.IssuedBorrowings);
	
	Items.ListOfOperationsToBeReceivedSelection.ChoiceList.Clear();
	For Each Operation In TransactionListReceipts Do
		Items.ListOfOperationsToBeReceivedSelection.ChoiceList.Add(Operation.Value, Operation.Presentation);
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeListOfPaymentOperations()
	
	TransactionListPayments.Clear();
	TransactionListPayments.Add(Enums.PaymentPlanningAreas.VendorsARAPAccounting);
	TransactionListPayments.Add(Enums.PaymentPlanningAreas.ReturnsToCustomers);
	TransactionListPayments.Add(Enums.PaymentPlanningAreas.LoansOrBorrowingsReceived);
	TransactionListPayments.Add(Enums.PaymentPlanningAreas.Deposits);
	TransactionListPayments.Add(Enums.PaymentPlanningAreas.IssuedBorrowings);
	TransactionListPayments.Add(Enums.PaymentPlanningAreas.Lease);
	
	Items.ListOfTransactionsToBePaidSelection.ChoiceList.Clear();
	For Each Operation In TransactionListPayments Do
		Items.ListOfTransactionsToBePaidSelection.ChoiceList.Add(Operation.Value, Operation.Presentation);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function TransactionListPresentation(TransactionList)
	
	TransactionListPresentation = "";
	For Each ListItem In TransactionList Do
		If ListItem.Check Then
			TransactionListPresentation = TransactionListPresentation
				+ ?(ValueIsFilled(TransactionListPresentation), ", ", "")
				+ ?(ValueIsFilled(ListItem.Presentation), ListItem.Presentation, ListItem.Value);
		EndIf;
	EndDo;
	
	Return TransactionListPresentation;
	
EndFunction

&AtServer
Procedure SaveWorkingValuesOfFormFields(SaveUndefined = False)
	
	Common.CommonSettingsStorageSave("CurrentCompany", "", ?(SaveUndefined, Undefined, Organization));
	
	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
	Common.CommonSettingsStorageSave("CurrentBankAccount", "", ?(SaveUndefined, Undefined, BankAccount));
	
	CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Organization);
	Common.CommonSettingsStorageSave("CurrentCashAccount", "", ?(SaveUndefined, Undefined, CashAccount));
	
EndProcedure

&AtServerNoContext
Function ArrayOfSelectedBankAccountCashRegisters(ListOfCashAccountsBankAccounts, BankAccountCashAccount)
	
	ArrayOfSelectedBankAccountCashRegisters = New Array;
	
	FIlter_ByType = "";
	If BankAccountCashAccount = "BankAccount" Then
		FIlter_ByType = Type("CatalogRef.CompaniesBankAccounts");
	ElsIf BankAccountCashAccount = "CashAccount" Then
		FIlter_ByType = Type("CatalogRef.CashAccounts");
	EndIf;
	
	For Each ListItem In ListOfCashAccountsBankAccounts Do
		If ListItem.Check And FIlter_ByType = TypeOf(ListItem.Value) Then
			ArrayOfSelectedBankAccountCashRegisters.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	Return ArrayOfSelectedBankAccountCashRegisters;
	
EndFunction

&AtServer
Procedure ResubmitListOfBankAccountCashRegisters()
	
	UpdatedList = ListOfCashAccountsBankAccounts(Organization);
	For Each ListItem In ListOfCashAccountsBankAccounts Do
		Item = UpdatedList.FindByValue(ListItem.Value);
		If Item <> Undefined Then
			Item.Check = ListItem.Check;
		EndIf;
	EndDo;
	
	ListOfCashAccountsBankAccounts = UpdatedList;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfReceiptByAcquiring()

	SelectedRows = Items.ToReceive.SelectedRows;
	
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	RowsArray = New Array;
	
	For Each RowSelected In SelectedRows Do
		
		If TypeOf(RowSelected) <> Type("DynamicListGroupRow") Then
			RowsArray.Add(RowSelected);
		EndIf;
		
	EndDo;
	
	If RowsArray.Count() = 0 Then
		CashRecieptByAcquiringTransactions = False;
	Else
		
		CashRecieptByAcquiringTransactions = True;
		
		For Each LineToReceive In RowsArray Do
			
			DataOfSelectedRow = Items.ToReceive.RowData(LineToReceive);
			
			If DataOfSelectedRow = Undefined Then
				
				CashRecieptByAcquiringTransactions = False;
				Break;
				
			EndIf;
			
			If UnavailableOfOperationsForAcquiring.FindByValue(DataOfSelectedRow.BusinessOperation) <> Undefined Then
				CashRecieptByAcquiringTransactions = False;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Items.ToReceiveCreateAReceiptDocumentBasedOnPaymentCard.Visible = CashRecieptByAcquiringTransactions;

EndProcedure

&AtServer
Function ListOfUnavailableAcquiringOfOperations()

	Operations = New ValueList;
	Operations.Add(Enums.BusinessTransactions.GoodsSaleToAnotherCompany);
	Operations.Add(Enums.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty);
	Operations.Add(Enums.BusinessTransactions.CashReceiptUnderDeposits);
	Operations.Add(Enums.BusinessTransactions.CashReceiptFromLoansRepayment);
	
	Return Operations;

EndFunction

#EndRegion

#Region DynamicListsSettings

&AtServer
Procedure InitiateDynamicListSettings()
	
	DocumentListParameters = New Array;
	
	ListParameterStructure = OperationsWithDocumentJournals.StructureOfFormationOfGroupOfUserSettingsForDynamicListOnForm();
	ListParameterStructure.ListName = "CashPaymentJournal";
	ListParameterStructure.PlacementGroupSettings = Items.PaymentJournalFilter;
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

&AtClient
Function CheckGetLinksHighlightedInList(Rows, DynamicList)
	
	If TypeOf(Rows) = Type("Array") Then
		RowsSelected = Rows;
	Else
		RowsSelected = New Array;
		RowsSelected.Add(Rows);
	EndIf;
	
	ReferencesArrray = New Array;
	
	For Iterator_SSLy = 0 To RowsSelected.Count() - 1 Do
		If TypeOf(RowsSelected[Iterator_SSLy]) <> Type("DynamicListGroupRow") Then
			RowData = DynamicList.RowData(RowsSelected[Iterator_SSLy]);
			ReferencesArrray.Add(RowData.Ref);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServerNoContext
Function DocumentTypesUsed()

	DocumentTypesUsed = New Array;
	DocumentTypesUsed.Add(Type("DocumentRef.BankAccountReceiptNote"));
	DocumentTypesUsed.Add(Type("DocumentRef.BankAccountIssue"));
	DocumentTypesUsed.Add(Type("DocumentRef.CashAccountReceiptNote"));
	DocumentTypesUsed.Add(Type("DocumentRef.CashVoucher"));
	DocumentTypesUsed.Add(Type("DocumentRef.PaymentCardTransaction"));
	DocumentTypesUsed.Add(Type("DocumentRef.BankReportOnAcquiringTransactions"));
	DocumentTypesUsed.Add(Type("DocumentRef.CashDepositWithdrawalDiscrepancies"));

	Return DocumentTypesUsed;
	
EndFunction

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
	ElsIf Item.Name = "sh_ShamsiInput_F_DateForReceipt" Then
		DateOfReceiptSelectionOnChange(Items.DateOfReceiptSelection);
	ElsIf Item.Name = "sh_ShamsiInput_F_DateForPayment" Then
		DateToBePaidSelectionOnChange(Items.DateToBePaidSelection);
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
