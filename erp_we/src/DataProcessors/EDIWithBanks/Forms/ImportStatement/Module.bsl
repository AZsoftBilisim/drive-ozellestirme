
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // refund upon receipt of the form for analysis
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	
	FillInInvoiceTable();
	
	TableOfBackgroundTasks = BackgroundTasksInProgressForUploadingStatement();
	
	For Each Account In Object.BankAccounts Do
		FillInBackgroundTaskDetails(TableOfBackgroundTasks, Account);
	EndDo;
	
	If Parameters.Property("BankAccount")
		And ValueIsFilled(Parameters.BankAccount) Then
		SelectedBankAccount = Parameters.BankAccount;
	ElsIf Not Parameters.Property("BankAccount") Then
		
		SavedList = 
			Common.CommonSettingsStorageLoad("DataProcessor.EDIWithBanks.Form.ImportStatement", "ListOfSelectedAccounts");
		
		If SavedList <> Undefined Then
			Object.AccountList = SavedList
		EndIf;
		
	EndIf;
	
	ImportedDocuments.Parameters.SetParameterValue("IDOfTheObjectReceiptOfNonCashDS",
		Common.MetadataObjectID("Document.BankAccountReceiptNote"));
	ImportedDocuments.Parameters.SetParameterValue("TheObjectIDOfTheNonCashWriteOffOfDS",
		Common.MetadataObjectID("Document.BankAccountIssue"));
		
	JournalName = "ImportedDocuments";
	
	MultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	
	Query = New Query("
		|SELECT
		|	Ref
		|FROM
		|	Catalog.DocumentRegistryKeys
		|WHERE
		|	Key = VALUE(Catalog.Counterparties.EmptyRef)
		|	OR Key = VALUE(Catalog.Companies.EmptyRef)
		|	OR Key = VALUE(Catalog.Persons.EmptyRef)
		|");
	EmptyRegistryKeys.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
	SetDynamicListSelection();
	SetVisibility1();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonClientServer.IsWebClient() Then
		AttachIdleHandler("Attachable_AttachFileSystemExtension", 0.1, True);
	Else
		AbilityToSelectFiles = True;
	EndIf;
	
	FillInInvoiceTreeByDisplayMode(True);
	ReadStatementData_();
	
	If ValueIsFilled(SelectedBankAccount) Then
		SelectSelectedInvoice(BankAccounts.GetItems());
	EndIf;
	
	SetVisibilityByInvoiceDisplayMode(ThisObject);
	AttachIdleHandler("CheckParallelLoadingOfStatement", 10, False);
	
EndProcedure

&AtClient
Procedure Attachable_AttachFileSystemExtension() Export
	
	CallbackDescription = New CallbackDescription("AttachFileSystemExtensionCompletion", ThisObject);
	CommonClient.ShowFileSystemExtensionInstallationQuestion(CallbackDescription);
	
EndProcedure

&AtClient
Procedure AttachFileSystemExtensionCompletion(FileExtensionEnabled, AdditionalParameters) Export
	
	AbilityToSelectFiles = FileExtensionEnabled;
	
	If AbilityToSelectFiles
		And AdditionalParameters <> Undefined Then
		InitializeFileDirectory(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_BankAccountIssue"
		Or EventName = "Write_BankAccountReceiptNote" Then
		Items.ImportedDocuments.Refresh();
	EndIf;
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	DetachIdleHandler("CheckParallelLoadingOfStatement");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompanyFilterOnChange(Item)

	UpdateListOfBankAccounts();

EndProcedure

&AtClient
Procedure CurrencySelection_3OnChange(Item)

	UpdateListOfBankAccounts();

EndProcedure

&AtClient
Procedure AccountNumberSelectionOnChange(Item)

	UpdateListOfBankAccounts();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBankAccounts

&AtClient
Procedure BankAccountsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.BankAccounts.CurrentData;
	
	If CurrentData.Level <> 0 Then
		Return;
	EndIf;
	
	If Field.Name = "BankAccountsGroup" Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Ref);
		
	ElsIf Field.Name = "BankAccountsConfigureExchange" Then
		
			If CurrentData.Downloading Then
				StandardProcessing = False;
			EndIf;
		
	ElsIf Field.Name = "BankAccountsThereIsBackgroundTask"
		And CurrentData.ThereIsBackgroundTask Then
		
		StandardProcessing = False;
		WarningText = StrTemplate(
			NStr("vi = 'Đang tải bản sao kê trong nền.
						|Người khởi xướng: %1
						|Kỳ kết nhập: %2';
						|ru = 'Выполняется фоновая загрузка выписки.
						|Инициатор: %1
						|Период загрузки: %2';
						|en = 'Importing the statement in the background.
						|Initiator: %1
						|Import period: %2'; fa = 'Importing the statement in the background.
						|Initiator: %1
						|Import period: %2';
						|it = 'Выполняется фоновая загрузка выписки.
						|Инициатор: %1
						|Период загрузки: %2';
						|pl = 'Importing the statement in the background.
						|Initiator: %1
						|Import period: %2';
						|tr = 'Ekstrenin arka planda yüklenmesi gerçekleştirildi.
						|Başlatıcı:%1
						|Yükleme dönemi: %2'"),
			CurrentData.AuthorOfBackgroundTask,
			CurrentData.BackgroundTaskLoadingPeriod);
		ShowMessageBox(, WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsCheckOnChange(Item)
	
	TreeRow = Items.BankAccounts.CurrentData;
	
	If TreeRow = Undefined Then
		Return;
	EndIf;
	
	TreeRow.Imported = False;
	
	If InvoiceViewingMode = 1 Then
		
		SetTagForSubordinateLines(TreeRow.GetItems(), TreeRow.Check);
		SetTagForParentLine(TreeRow);
		
	EndIf;
	
	FillInListOfMarkedAccounts();
	
EndProcedure

&AtClient
Procedure BankAccountsImportPeriodOnChange(Item)
	
	CurrentData = Items.BankAccounts.CurrentData;
	
	CurrentData.ImportStartDate = CurrentData.ImportPeriod.StartDate;
	CurrentData.ImportEndDate = CurrentData.ImportPeriod.EndDate;
	
EndProcedure

&AtClient
Procedure BankAccountsConfigureExchangeStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If AbilityToSelectFiles Then
		SelectingDownloadSource();
	Else
		AttachIdleHandler("Attachable_EnableFileWorkExtensionAndSelectFile", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsConfigureExchangeOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.BankAccounts.CurrentData;
	If ValueIsFilled(CurrentData.ConfigureExchange) Then
		FinancesClient.OpenFileForViewing(
			"BankAccounts",
			CurrentData.ConfigureExchange, CurrentData.Encoding, NStr("vi = 'Tệp';
																		|ru = 'Файл';
																		|en = 'File'; fa = 'فایل';
																		|it = 'Файл';
																		|pl = 'File';
																		|tr = 'Dosya'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsConfigureExchangeClearing(Item, StandardProcessing)
	
	CurrentData = Items.BankAccounts.CurrentData;
	DeleteBankAccountFiles(CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "UploadedDocumentsPage" Then
		If Object.AccountList.Count() = 1 Then
			If BankAccountSelection <> Object.AccountList[0].Value Then
				BankAccountSelection = Object.AccountList[0].Value;
			EndIf;
			SetDynamicListSelection();
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersImportedDocuments

&AtClient
Procedure BankAccountSelectionOnChange(Item)
	
	BankAccountSelectionOnChangeServer();
	
EndProcedure

&AtServer
Procedure BankAccountSelectionOnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure LastStatementOnlyOnChange(Item)
	
	ClearMessages();
	LastStatementOnlyOnChangeServer();
	
EndProcedure

&AtServer
Procedure LastStatementOnlyOnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure OnlyErroneousPaymentsOnChange(Item)
	
	ClearMessages();
	OnlyErroneousPaymentsOnChangeServer();
	
EndProcedure

&AtServer
Procedure OnlyErroneousPaymentsOnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure ImportedDocumentsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.Counterparties") Then
		
		CurrentData = Items[JournalName].CurrentData;
		
		SelectingCounterpartyOnServer(
			CurrentData.NameOfCounterparty,
			ValueSelected,
			CurrentData.StatementData,
			CurrentData.BankAccount,
			CurrentData["Ref"]);
	EndIf;
	
EndProcedure

&AtServer
Procedure SelectingCounterpartyOnServer(NameOfCounterparty, Counterparty, StatementData, BankAccount, DocumentRef)
	
	If Not IsBlankString(StatementData) Then
		
		DocumentData = ParseDocumentExtractData(StatementData, BankAccount);
		
		If DocumentData = Undefined Then
			Return;
		EndIf;
		
		DocumentData.Insert("Counterparty", Counterparty);
		
		SubstituteCounterpartyOnServer(DocumentRef, NameOfCounterparty, Counterparty, DocumentData, BankAccount)
		
	Else
		
		DocumentObject = DocumentRef.GetObject();
		DocumentObject.Counterparty = Counterparty;
		DocumentObject.AdditionalProperties.Insert("EDIWithBanks", True);
		DocumentObject.CheckFilling();
		If DocumentObject.AdditionalProperties.Property("FillingErrors") Then
			DocumentObject.ImportErrors = TrimAll(DocumentObject.AdditionalProperties.FillingErrors);
		EndIf;
		
		DocumentObject.Write();
		
		FormTable = Items[JournalName]; // FormTable
		FormTable.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure TextDirectBankHorizontallyURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure ImportedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ImportedDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ImportedDocumentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ImportedDocumentsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.SetDeletionMark(Item, Title)
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkAccounts(Command)
	
	ClearMessages();
	SetTagForSubordinateLines(BankAccounts.GetItems(), True);
	FillInListOfMarkedAccounts();
	
EndProcedure

&AtClient
Procedure ClearAccounts(Command)
	
	ClearMessages();
	Object.AccountList.Clear();
	
	SetTagForSubordinateLines(BankAccounts.GetItems(), False);
	
EndProcedure

&AtClient
Procedure UpdateTheListOfAccounts(Command)
	
	UpdateListOfBankAccounts(True);
	
EndProcedure

&AtServer
Procedure UpdateListOfAccountsOnServer(UpdateList)
	
	FillInInvoiceTable();
	
	// The marked accounts keep the mark
	ArrayOfFoundAccounts = New Array;
	For Each Account In Object.BankAccounts Do
		ListCount_ = Object.AccountList.FindByValue(Account.Ref);
		If ListCount_ <> Undefined Then
			Account.Check = True;
			ArrayOfFoundAccounts.Add(ListCount_);
		EndIf;
	EndDo;
	
	ArrayOfAccountsNotFound = New Array;
	For Each Account In Object.AccountList Do
		If ArrayOfFoundAccounts.Find(Account) = Undefined Then
			ArrayOfAccountsNotFound.Add(Account);
		EndIf;
	EndDo;
	
	For Each Account In ArrayOfAccountsNotFound Do
		Object.AccountList.Delete(Account);
	EndDo;
	
	SetVisibility1();
	
	FillInInvoiceTreeByDisplayMode(UpdateList);
	
EndProcedure

&AtClient
Procedure AccountViewModeTree(Command)
	
	ChangeViewingMode(1);
	
EndProcedure

&AtClient
Procedure AccountViewModeList(Command)
	
	ChangeViewingMode(0);
	
EndProcedure

&AtClient
Procedure SelectFile(Command)
	
	ClearMessages();
	CurrentData = Items.BankAccounts.CurrentData;
	If CurrentData <> Undefined Then
		
		If AbilityToSelectFiles Then
			ChoosingExchangeFileWithBank(CurrentData, "Load");
		Else
			AttachIdleHandler("Attachable_EnableFileWorkExtensionAndSelectFile", 0.1, True);
		EndIf;
	Else
		CommonClientServer.MessageToUser(
			NStr("vi = 'Để chọn tệp, cần chọn dòng có tài khoản ngân hàng.
				|Nếu danh sách tài khoản ngân hàng trống, hãy chắc chắn rằng, trên thẻ tài khoản ngân hàng đã bật trao đổi với ngân hàng.';
				|ru = 'Для выбора файла должна быть выделена строка с банковским счетом.
				|Если список банковских счетов пуст, убедитесь, что в карточке банковского счета включен обмен с банком.';
				|en = 'To select a file, a line with the bank account must be selected.
				|If the bank account list is empty, make sure that EDI is enabled in the bank account card.'; fa = 'To select a file, a line with the bank account must be selected.
				|If the bank account list is empty, make sure that EDI is enabled in the bank account card.';
				|it = 'Для выбора файла должна быть выделена строка с банковским счетом.
				|Если список банковских счетов пуст, убедитесь, что в карточке банковского счета включен обмен с банком.';
				|pl = 'Aby wybrać plik, należy zaznaczyć wiersz z rachunkiem bankowym.
				|Jeśli lista rachunków bankowych jest pusta, upewnij się, że na rachunku bankowym włączona jest wymiana z bankiem.';
				|tr = 'Dosya seçmek için banka hesabı satırı seçilmelidir.
				|Banka hesapları listesi boşsa, banka hesabı kartında bankayla EDI etkinleştirildiğinden emin ol.'"),,
			"Items.BankAccountsRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenFile(Command)
	
	ClearMessages();
	CurrentData = Items.BankAccounts.CurrentData;
	If CurrentData <> Undefined Then
		If Not CurrentData.DirectExchange And ValueIsFilled(CurrentData.ConfigureExchange) Then
			
			Encoding = CurrentData.Encoding;
			
			If Not CurrentData.ImportFromDirectory
				And CurrentData.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
			
				SelectedFile = New File(CurrentData.ConfigureExchange);
				
				If SelectedFile.Extension = ".xml" Then
					Encoding = "UTF-8";
				EndIf;
			
			EndIf;
			
			FinancesClient.OpenFileForViewing(
				"BankAccounts",
				CurrentData.ConfigureExchange, Encoding, NStr("vi = 'Tập tin sao kê';
																|ru = 'Файл выписки';
																|en = 'Statement file'; fa = 'Statement file';
																|it = 'Файл выписки';
																|pl = 'Plik wyciągu';
																|tr = 'Ekstre dosyası'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDocuments(Command)
	
	ClearMessages();
	
	If FilesAreBeingProcessed Then
		Return;
	EndIf;
	
	FilesAreBeingProcessed = True;
	HasErrors = False;
	
	UploadDocumentsFromTree(BankAccounts.GetItems(), HasErrors);
	
	If HasErrors Then
		
		FilesAreBeingProcessed = False;
		Return;
		
	EndIf;
	
	PerformVerificationBeforeUploadingDocuments();
	
EndProcedure


&AtServer
Procedure UploadToServer_1()
	
	FillInListOfMarkedAccounts();
	
	Common.CommonSettingsStorageSave("DataProcessor.EDIWithBanks.Form.ImportStatement", "ListOfSelectedAccounts", Object.AccountList);
	
	ToDelete_ = New Array;
	
	For Each FileString In Object.Files Do
		
		If TypeOf(FileString.Statement_) = Type("Structure")
			And Not CashClientServer.ThereIsInvoiceInStatementFile(FileString.BankAccount, FileString.Statement_.StatementData) Then
			ToDelete_.Add(FileString);
		EndIf;
		
	EndDo;
	
	For Each ArrayRow In ToDelete_ Do
		Object.Files.Delete(ArrayRow);
	EndDo;
	
	SaveStatementToTemporaryStorage(BankAccounts.GetItems());
	
	FillInInvoiceTableByTree();
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.ImportPayments(UUID);
	ValueToFormAttribute(DataProcessor, "Object");
	
EndProcedure

&AtClient
Procedure CreateCounterparty(Command)
	
	ClearMessages();
	CurrentData = Items[JournalName].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	BankAccount = CurrentData.BankAccount;
	Counterparty     = CurrentData.Counterparty;
	NameOfCounterparty = CurrentData.NameOfCounterparty;
	StatementData  = CurrentData.StatementData;
	
	If EmptyRegistryKeys.FindByValue(Counterparty) = Undefined
		And ValueIsFilled(Counterparty) Then
		
		MessageText = StrTemplate(
			NStr("vi = ' Trong chứng từ %1 đã xác định đối tác %2 . Có thể thay đổi đối tác trong biểu mẫu chứng từ.';
				|ru = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|en = 'Counterparty %2 is already specified in document %1. You can change it in the document form.'; fa = 'Counterparty %2 is already specified in document %1. You can change it in the document form.';
				|it = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|pl = 'W dokumencie %1 jest już ustalony kontrahent %2. Można go zmienić w formie dokumentu.';
				|tr = '%2 cari hesabı zaten %1 belgesinde tanımlandı. Belge şeklinde değiştirilebilir.'"),
				CurrentData["Ref"],
				CurrentData.Counterparty);
		
		CommonClientServer.MessageToUser(
			MessageText,
			CurrentData["Ref"],,
			Items.ImportedDocumentsCounterparty.Name);
		
	ElsIf IsBlankString(NameOfCounterparty) Then
		
		MessageText = NStr("vi = 'Tên của đối tác là không rõ, tự động tạo là không thể.';
							|ru = 'Неизвестно наименование контрагента, автоматическое создание невозможно.';
							|en = 'Counterparty name is unknown. Cannot create it automatically.'; fa = 'Counterparty name is unknown. Cannot create it automatically.';
							|it = 'Неизвестно наименование контрагента, автоматическое создание невозможно.';
							|pl = 'Nazwa kontrahenta jest nieznana, automatyczne tworzenie jest niemożliwe.';
							|tr = 'Cari hesabın tanımı belirsiz, otomatik oluşturma imkansız.'");
		
		CommonClientServer.MessageToUser(
			MessageText,
			CurrentData["Ref"],,
			Items.ImportedDocumentsCounterparty.Name);
		
	Else
		
		If Not ValueIsFilled(StatementData) Then
			MessageText = NStr("vi = 'Không thể tạo tự động đối tác.
			|Hãy tạo thủ công đối tác và chèn vào chứng từ.';
			|ru = 'Не удалось создать контрагента автоматически.
			|Создайте контрагента вручную и подставьте в документ.';
			|en = 'Cannot create counterparty automatically.
			|Create a counterparty manually and insert it to the document.'; fa = 'Cannot create counterparty automatically.
			|Create a counterparty manually and insert it to the document.';
			|it = 'Не удалось создать контрагента автоматически.
			|Создайте контрагента вручную и подставьте в документ.';
			|pl = 'Nie można było automatycznie utworzyć kontrahenta.
			|Utwórz kontrahenta ręcznie i zastąp go w dokumencie.';
			|tr = 'Otomatik olarak cari hesap oluşturulamadı.
			|Manuel olarak cari hesap oluştur ve onu belgeye ekle.'");
			CommonClientServer.MessageToUser(
				MessageText,
				CurrentData["Ref"],,
				Items.ImportedDocumentsCounterparty.Name);
			Return;
		EndIf;
		
		DocumentData = ParseDocumentExtractData(StatementData, BankAccount);
		
		If DocumentData = Undefined Then
			Return;
		EndIf;
		
		CounterpartyFound = FindCounterparty(NameOfCounterparty, DocumentData);
		If CounterpartyFound <> Undefined Then
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã tìm thấy đối tác hiện tại - %1.
				|
				|Đặt đối tác vào chứng từ hoặc tạo đối tác mới?';
				|ru = 'Найден существующий контрагент - %1.
				|
				|Подставить его в документы, или создать нового?';
				|en = 'Existing counterparty is found - %1
				|
				|Substitute it to the documents or create a new one?'; fa = 'Existing counterparty is found - %1
				|
				|Substitute it to the documents or create a new one?';
				|it = 'Найден существующий контрагент - %1.
				|
				|Подставить его в документы, или создать нового?';
				|pl = 'Znaleziono istniejącego kontrahenta - %1.
				|
				|Dodać go do dokumentów czy utworzyć nowego?';
				|tr = 'Mevcut cari hesap bulundu - %1.
				|
				|Belgelere ekle veya yeni bir cari hesap oluştur?'"),
				CounterpartyFound);
				
			CounterpartySearchParameters = New Structure;
			CounterpartySearchParameters.Insert("CounterpartyFound",  CounterpartyFound);
			CounterpartySearchParameters.Insert("NameOfCounterparty",       NameOfCounterparty);
			CounterpartySearchParameters.Insert("DocumentData",      DocumentData);
			CounterpartySearchParameters.Insert("BankAccount",       BankAccount);
			CounterpartySearchParameters.Insert("Document",             CurrentData["Ref"]);
			
			CallbackDescription = New CallbackDescription(
				"SearchAndCompletion",
				ThisObject,
				CounterpartySearchParameters);
				
			ActionsOptions = New ValueList;
			ActionsOptions.Add("Found3", NStr("vi = 'Đặt thay thế';
												|ru = 'Подставить найденного';
												|en = 'Substitute found'; fa = 'Substitute found';
												|it = 'Подставить найденного';
												|pl = 'Dodaj znalezionego';
												|tr = 'Bulunanı ekle'"));
			ActionsOptions.Add("New", NStr("vi = 'Tạo mới';
											|ru = 'Создать нового';
											|en = 'Create new'; fa = 'ایجاد جدید';
											|it = 'Создать нового';
											|pl = 'Utwórz nowy';
											|tr = 'Yenisini oluştur'"));
			ActionsOptions.Add("Cancel", NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Отмена';
												|pl = 'Cancel';
												|tr = 'İptal'"));
			
			ShowQueryBox(CallbackDescription, QueryText, ActionsOptions);
		Else
			
			CreateCounterpartyOnServer(NameOfCounterparty, DocumentData, BankAccount);
		EndIf;
	EndIf
	
EndProcedure

&AtClient
Procedure SearchAndCompletion(QuestionResult, QuestionParameters) Export
	
	If QuestionResult = "Found3" Then
		
		SubstituteCounterpartyOnServer(
			QuestionParameters.Document,
			QuestionParameters.NameOfCounterparty,
			QuestionParameters.CounterpartyFound,
			QuestionParameters.DocumentData,
			QuestionParameters.BankAccount);
		
	ElsIf QuestionResult = "New" Then
		
		CreateCounterpartyOnServer(
			QuestionParameters.NameOfCounterparty,
			QuestionParameters.DocumentData,
			QuestionParameters.BankAccount);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectCounterparty(Command)
	
	ClearMessages();
	CurrentData = Items[JournalName].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Counterparty    = CurrentData.Counterparty;
	StatementData = CurrentData.StatementData;
	
	If EmptyRegistryKeys.FindByValue(Counterparty) = Undefined
		And ValueIsFilled(Counterparty) Then
		
		MessageText = StrTemplate(
			NStr("vi = ' Trong chứng từ %1 đã xác định đối tác %2 . Có thể thay đổi đối tác trong biểu mẫu chứng từ.';
				|ru = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|en = 'Counterparty %2 is already specified in document %1. You can change it in the document form.'; fa = 'Counterparty %2 is already specified in document %1. You can change it in the document form.';
				|it = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|pl = 'W dokumencie %1 jest już ustalony kontrahent %2. Można go zmienić w formie dokumentu.';
				|tr = '%2 cari hesabı zaten %1 belgesinde tanımlandı. Belge şeklinde değiştirilebilir.'"),
				CurrentData["Ref"],
				CurrentData.Counterparty);
		
		CommonClientServer.MessageToUser(
			MessageText,
			CurrentData["Ref"],,
			Items.ImportedDocumentsCounterparty.Name);
	Else
		
		OpenForm("Catalog.Counterparties.ChoiceForm",, Items[JournalName]);
	EndIf;
	
EndProcedure

&AtClient
Procedure OutputReport(Command)
	
	ClearMessages();
	
	IndexesOfSelectedRows = New ValueList;
	
	DetachIdleHandler("OutputReportCompletion");
	
	For Each SelectedRow In Items.BankAccounts.SelectedRows Do
		
		RowData = Items.BankAccounts.RowData(SelectedRow);
		IndexesOfSelectedRows.Add(SelectedRow);
		
		ReadBankAccountFiles(RowData);
		
	EndDo;
	
	AttachIdleHandler("OutputReportCompletion", 0.1, True);
	
EndProcedure

&AtServer
Function DisplayReportOnServer(RowIndexes)
	
	Object.DocumentsToImport.Clear();
	IndexesOfTableRows = New Array;
	
	FillInInvoiceTableByTree();
	
	For Each RowIndex In RowIndexes Do
		
		Account = BankAccounts.FindByID(RowIndex.Value);
		
		Filter = New Structure("Ref", Account.Ref);
		AccountWasFound = Object.BankAccounts.FindRows(Filter);
		
		If AccountWasFound.Count() <> 0 Then
			IndexesOfTableRows.Add(Object.BankAccounts.IndexOf(AccountWasFound[0]));
		EndIf;
		
		ListOfFiles = ListOfBankAccountFiles(Account.Ref, Object.Files);
		
		If ListOfFiles.Count() = 0 Then
			Continue;
		EndIf;
		
		AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(Account.Ref);
		
		For Each File In ListOfFiles Do
		
			If File.Statement_ = Undefined
				Or File.Statement_.StatementData = Undefined
				Or Not File.Statement_.StatementData.StatementDocuments.Count() Then
				Continue;
			EndIf;
			
			DocumentLinesToUpload = New Array;
			
			If Not CashClientServer.ThereIsInvoiceInStatementFile(AccountAttributes.AccountNumber, File.Statement_.StatementData)
				And Not Account.DirectExchange Then
				Continue;
			EndIf;
			
			For Each DocumentExtracts In File.Statement_.StatementData.StatementDocuments Do
				
				If DocumentExtracts.PayerAccount <> TrimAll(AccountAttributes.AccountNumber)
					And DocumentExtracts.BeneficiaryAccount <> TrimAll(AccountAttributes.AccountNumber) Then
					Continue;
				EndIf;
				
				If DocumentExtracts.PayerPersonalAccount <> Undefined
					And DocumentExtracts.PayerPersonalAccount <> AccountAttributes.PersonalAccountNumber
					And DocumentExtracts.PayeePersonalAccount <> Undefined
					And DocumentExtracts.PayeePersonalAccount <> AccountAttributes.PersonalAccountNumber Then
					Continue;
				EndIf;
				
				If DocumentExtracts.AnalyticalSectionCode <> Undefined
					And DocumentExtracts.AnalyticalSectionCode <> AccountAttributes.PersonalAccountSection Then
					Continue;
				EndIf;
				
				VariousAccounts = DocumentExtracts.PayerAccount <> DocumentExtracts.BeneficiaryAccount;
				
				PaymentToRecipientSOrganization = 
					DocumentExtracts.PayerAccount = AccountAttributes.AccountNumber
					And VariousAccounts
					And ValueIsFilled(DocumentExtracts.BeneficiaryAccount)
					And CashClientServer.ThereIsInvoiceInStatementFile(DocumentExtracts.BeneficiaryAccount, File.Statement_.StatementData)
					And Not ValueIsFilled(DocumentExtracts.DepartureDate)
					And ValueIsFilled(DocumentExtracts.ArrivalDate_);
			
				PaymentToPayerSOrganization =
					DocumentExtracts.BeneficiaryAccount = AccountAttributes.AccountNumber
					And VariousAccounts
					And ValueIsFilled(DocumentExtracts.PayerAccount)
					And CashClientServer.ThereIsInvoiceInStatementFile(DocumentExtracts.PayerAccount, File.Statement_.StatementData)
					And ValueIsFilled(DocumentExtracts.DepartureDate)
					And Not ValueIsFilled(DocumentExtracts.ArrivalDate_);
				
				If PaymentToRecipientSOrganization
					Or PaymentToPayerSOrganization Then
					Continue;
				EndIf;
				
				Outgoing = (DocumentExtracts.PayerAccount = TrimAll(AccountAttributes.AccountNumber));
				
				DocumentToDownload = Object.DocumentsToImport.Add();
				FillPropertyValues(DocumentToDownload, DocumentExtracts);
				DocumentLinesToUpload.Add(DocumentToDownload);
				
				If Not ValueIsFilled(DocumentToDownload.DocDate) Then
					DocumentToDownload.DocDate = CashClientServer.GetDateFromString(DocumentExtracts.Date);
					If Not ValueIsFilled(DocumentToDownload.DocDate) Then
						DocumentToDownload.DocDate = CashClientServer.GetDateFromString(
							?(Outgoing, DocumentExtracts.DepartureDate, DocumentExtracts.ArrivalDate_));
					EndIf;
				EndIf;
				
				Sum = StringFunctionsClientServer.StringToNumber(DocumentToDownload.Sum);
				If Sum <> Undefined Then
					If Sum < 0 Then
						Sum = - Sum;
					EndIf;
					DocumentToDownload.DocumentAmount = Sum;
					If Outgoing Then
						DocumentToDownload.AmountCredited   = Sum;
					Else
						DocumentToDownload.ReceivedAmount = Sum;
					EndIf;
				EndIf;
				
				DocumentToDownload.PaymentPurposes = DocumentExtracts.PaymentPurposes;
				If Not ValueIsFilled(DocumentToDownload.PaymentPurposes) Then
					DocumentToDownload.PaymentPurposes = DocumentExtracts.PaymentPurposes1;
					For Indus = 2 To 6 Do
						If Not ValueIsFilled(DocumentExtracts["PaymentPurposes" + Indus]) Then
							Break;
						EndIf;
						DocumentToDownload.PaymentPurposes =
							DocumentExtracts.PaymentPurposes + Chars.LF + DocumentExtracts["PaymentPurposes" + Indus];
					EndDo;
				EndIf;
			EndDo;
			
			File.DocumentStorageAddress = PutToTempStorage(Object.DocumentsToImport.Unload(DocumentLinesToUpload));
			
		EndDo;
		
	EndDo;
	
	DataProcessor = FormAttributeToValue("Object");
	Return DataProcessor.PrintingDownloadReport(IndexesOfTableRows);
	
EndFunction

&AtClient
Procedure Post(Command)
	
	ClearMessages();
	TMCommonUseClient.PostDocuments(Items.ImportedDocuments, Title);
	Notify("Write_DocumentPayments", , Items.ImportedDocuments);
	
EndProcedure

&AtClient
Procedure UndoPosting(Command)
	
	ClearMessages();
	TMCommonUseClient.UndoPosting(Items.ImportedDocuments, Title);
	Notify("Write_DocumentPayments", , Items.ImportedDocuments);
	
EndProcedure

&AtClient
Procedure SetClearDeletionMark(Command)
	
	CallbackOnCompletion = CashClient.NotificationToListOfNonCashPaymentsAfterChangingDeletionMark(
		Items.ImportedDocuments);
	TMCommonUseClient.SetDeletionMark(Items.ImportedDocuments, Title, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure OpenDownloadSettings(Command)

	FormParameters = New Structure;
	FormParameters.Insert("Object", Object);
	
	ClosingNotification1 = New CallbackDescription("SaveDownloadSettings", ThisObject);
	OpenForm(
		"DataProcessor.EDIWithBanks.Form.ImportSettings",
		FormParameters,
		ThisObject, , , ,
		ClosingNotification1,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	
	// The account data is being loaded
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountsImportPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BankAccounts.Downloading");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tick");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Kết nhập';
													|ru = 'Загружается';
													|en = 'Importing'; fa = 'در حال ورود اطلاعات';
													|it = 'Загружается';
													|pl = 'Importing';
													|tr = 'İçe aktarılıyor'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountsImportPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BankAccounts.Downloading");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tick");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đang tải.';
													|ru = 'Загружается.';
													|en = 'Importing.'; fa = 'Importing.';
													|it = 'Загружается.';
													|pl = 'Importing.';
													|tr = 'İçe aktarılıyor.'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountsImportPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BankAccounts.Downloading");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tick");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 2;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đang tải ..';
													|ru = 'Загружается..';
													|en = 'Importing...'; fa = 'Importing...';
													|it = 'Загружается..';
													|pl = 'Importing...';
													|tr = 'İçe aktarılıyor..'"));
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountsImportPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BankAccounts.Downloading");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Tick");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 3;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đang tải ...';
													|ru = 'Загружается...';
													|en = 'Importing ...'; fa = 'Importing ...';
													|it = 'Загружается...';
													|pl = 'Importing ...';
													|tr = 'İçe aktarılıyor...'"));
	
	// Account statement uploaded
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BankAccountsImportPeriod.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BankAccounts.Imported");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ngày kết nhập';
													|ru = 'Загружен';
													|en = 'Imported'; fa = 'واردشده';
													|it = 'Загружен';
													|pl = 'Imported';
													|tr = 'Yüklendi'"));
	
	// Conditional design of the dynamic list of "Uploaded documents"
	ListOfConditionalAppearance = ImportedDocuments.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	// Counterparty not found
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Không tìm thấy đối tác';
							|ru = 'Не найден контрагент';
							|en = 'Counterparty is not found'; fa = 'Counterparty is not found';
							|it = 'Не найден контрагент';
							|pl = 'Nie znaleziono kontrahenta';
							|tr = 'Cari hesap bulunamadı'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("NameOfCounterparty");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);
	
	// Found a counterparty
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Tìm thấy đối tác';
							|ru = 'Найден контрагент';
							|en = 'Counterparty is found'; fa = 'طرف حساب یافت شد';
							|it = 'Найден контрагент';
							|pl = 'Znaleziono kontrahenta';
							|tr = 'Cari hesap bulundu'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("NameOfCounterparty");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	// There are loading errors
	Item = ListOfConditionalAppearance.Items.Add();
	Item.Presentation = NStr("vi = 'Có lỗi tải';
							|ru = 'Есть ошибки загрузки';
							|en = 'There are import errors'; fa = 'There are import errors';
							|it = 'Есть ошибки загрузки';
							|pl = 'Występują błędy pobierania';
							|tr = 'İçe aktarma hatası mevcut'");
	
	Item.Fields.Items.Add().Field = New DataCompositionField("NameOfCounterparty");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Counterparty");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.ImportedDocumentsOrganization.Visible = MultipleCompanies;
	SetDisplayOfTheseFiles();
	SetVisibilityByInvoiceDisplayMode(ThisObject);
	
EndProcedure

&AtServer
Procedure SetDisplayOfTheseFiles()

	ThereAreExtractData = StatementTitle.LineCount() <> 0;
	ThereIsDataOfTransfer = HeaderTransfer.LineCount() <> 0;
	
	Items.GroupStatementData.Visible = ThereAreExtractData
											Or (Not ThereAreExtractData
											And Not ThereIsDataOfTransfer);
	Items.GroupConfirmationOfEnrollment.Visible = ThereIsDataOfTransfer;
	
	If ThereAreExtractData
		And ThereIsDataOfTransfer Then
		Items.FileDataPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.FileDataPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityByInvoiceDisplayMode(Form)

	Form.Items.AccountViewModeTree.Visible =
		Form.InvoiceViewingMode = 0
		And Form.MultipleCompanies;
	Form.Items.AccountViewModeList.Visible =
		Form.InvoiceViewingMode = 1
		And Form.MultipleCompanies;

EndProcedure

&AtServer
Procedure FillInInvoiceTable()
	
	FilterParameters = SelectingListOfAccounts();
	
	DataProcessor = FormAttributeToValue("Object");
	DataProcessor.FillInDownloadInvoiceTable(FilterParameters);
	ValueToFormAttribute(DataProcessor, "Object");
	
EndProcedure

&AtClient
Procedure ReadStatementData_()
	
	Object.Files.Clear();
	ReadDataFromTreeExtracts(BankAccounts.GetItems());
	
EndProcedure

&AtClient
Procedure ReadStatementData(Account)
	
	If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
		Read1CClientBankExchangeStatementData(Account);
	Else
		ReadStatementDataByFormat(Account);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadStatementDataByFormat(Account)
	
	Account.ImportStartDate = '00010101';
	Account.ImportEndDate = '00010101';
	
	MessageText = "";
	
	ListOfFiles = AccountFilesInDirectory(Account);
	
	For Each FileName In ListOfFiles Do
	
		CurrentFile = New File(FileName);
		NewRow = InformationAboutExtractFileByFormat(ThisObject, Account, CurrentFile);
		
		If NewRow.Statement_.MessageText <> "" Then
			Continue;
		EndIf;
		
		If TypeOf(NewRow.Statement_) = Type("Structure")
			And Not CashClientServer.ThereIsInvoiceInStatementFile(Account, NewRow.Statement_.StatementData) Then
			Continue;
		EndIf;
		
		Account.ImportStartDate = ?(Account.ImportStartDate = '00010101',
									NewRow.ImportStartDate,
									Min(Account.ImportStartDate, NewRow.ImportStartDate));
		Account.ImportEndDate = Max(Account.ImportEndDate, NewRow.ImportEndDate);
		
	EndDo;
	
	Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
	
EndProcedure

&AtServerNoContext
Function ReadStatementDataByFormatOnServer(Val ExchangeFormat, Val BinaryData, Val Encoding)
	
	Return DataProcessors.EDIWithBanks.ReadExtractDataFromFile(BinaryData, ExchangeFormat, Encoding);

EndFunction

&AtClient
Procedure Read1CClientBankExchangeStatementData(Account)
	
	Account.ImportStartDate = '00010101';
	Account.ImportEndDate = '00010101';
	
	MessageText = "";
	FirstIteration = True;
	
	ListOfFiles = AccountFilesInDirectory(Account);
	
	For Each FileName In ListOfFiles Do
	
		CurrentFile = New File(FileName);
		
		If CurrentFile.Extension = ".txt" Then
			NewRow = InformationAboutFileAccordingToExchangeFormat1CClientBankExchange(
				ThisObject, Account, FileName, CurrentFile, MessageText, False);
		
		
		Else
			Continue;
		EndIf;
		
		If TypeOf(NewRow.Statement_) = Type("Structure")
			And Not CashClientServer.ThereIsInvoiceInStatementFile(Account, NewRow.Statement_.StatementData) Then
			Continue;
		EndIf;
		
		If FirstIteration Then
			
			Account.ImportStartDate = NewRow.ImportStartDate;
			FirstIteration = False;
			
		Else
			Account.ImportStartDate = Min(Account.ImportStartDate, NewRow.ImportStartDate);
		EndIf;
		
		Account.ImportEndDate = Max(Account.ImportEndDate, NewRow.ImportEndDate);
	
	EndDo;
	
	Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
	
EndProcedure

&AtClient
Procedure PrintStatementTitle()
	
	MessageText = "";
	CurrentData = Items.BankAccounts.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.DirectExchange Then
		MessageText = NStr("vi = '<Trao đổi trực tiếp được chọn. Dữ liệu sẽ được yêu cầu khi tải xuống thanh toán.>';
							|ru = '<Выбран прямой обмен. Данные будут запрошены при загрузке платежей.>';
							|en = '<Direct exchange is selected. Data will be requested while importing payments.>'; fa = '<Direct exchange is selected. Data will be requested while importing payments.>';
							|it = '<Выбран прямой обмен. Данные будут запрошены при загрузке платежей.>';
							|pl = '<Wybrana bezpośrednia wymiana. Dane będą pobierane przy wczytywaniu płatności>';
							|tr = '<Doğrudan değişim seçildi. Ödemeler yüklenirken veriler istenecektir.>'");
		
	ElsIf Not ValueIsFilled(CurrentData.ConfigureExchange) Then
		MessageText = NStr("vi = '<Chưa chỉ định tệp/thư mục sao kê và/hoặc ghi có tiền.>';
							|ru = '<Не указан файл/каталог выписки и/или зачисления ДС.>';
							|en = '<File/directory of the cash statement or deposit is not specified.>'; fa = '<File/directory of the cash statement or deposit is not specified.>';
							|it = '<Не указан файл/каталог выписки и/или зачисления ДС.>';
							|pl = '<Nie podano pliku/katalogu wyciągu i/lub zaliczenia środków pieniężnych.>';
							|tr = '<Ekstrenin dosyası/klasörü ve/veya Nakit transferi belirtilmedi.>'");
		
	Else
		
		DeleteBankAccountFiles(CurrentData.Ref);
		
		#If Not WebClient Then
		ReadStatementData(CurrentData); // the file is re-read in case it has changed
		PrintAccountStatementHeaders(CurrentData, MessageText)
		#EndIf
	EndIf;
	
	If MessageText <> "" Then
		StatementTitle.Clear();
		StatementTitle.AddLine(MessageText);
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformVerificationBeforeUploadingDocuments()

	AllFilesAreRead = FilesAreRead(BankAccounts.GetItems());
	
	If Not AllFilesAreRead Then
		AttachIdleHandler("PerformVerificationBeforeUploadingDocuments", 0.1, True);
	Else
		
		ArrayOfAccounts_ = New Array;
	
		GetInvoicesWithBanOnChangesInUploadedPeriod(ArrayOfAccounts_);
		
		If ArrayOfAccounts_.Count() <> 0 Then
			
			If ArrayOfAccounts_.Count() = 1 Then
				MessageText = StrTemplate(NStr("vi = 'Đã thiết lập cấm thay đổi dữ liệu trong kỳ kết nhập theo tài khoản
					|%1';
					|ru = 'Установлен запрет изменения данных в загружаемом периоде по счету
					|%1';
					|en = 'Period-end closing is set in the import period for the account:
					|%1'; fa = 'Period-end closing is set in the import period for the account:
					|%1';
					|it = 'Установлен запрет изменения данных в загружаемом периоде по счету
					|%1';
					|pl = 'Period-end closing is set in the import period for the account:
					|%1';
					|tr = '
					|%1 hesabında yüklenen dönemde veri değiştirme yasağı ayarlandı'"), StrConcat(ArrayOfAccounts_, Chars.LF));
			Else
				MessageText = StrTemplate(NStr("vi = 'Đã thiết lập cấm thay đổi dữ liệu trong kỳ kết nhập theo các tài khoản
					|%1';
					|ru = 'Установлен запрет изменения данных в загружаемом периоде по счетам
					|%1';
					|en = 'Period-end closing is set in the import period for the accounts:
					|%1'; fa = 'Period-end closing is set in the import period for the accounts:
					|%1';
					|it = 'Установлен запрет изменения данных в загружаемом периоде по счетам
					|%1';
					|pl = 'Period-end closing is set in the import period for the accounts:
					|%1';
					|tr = '
					|%1 hesabında yüklenen dönemde veri değiştirme yasağı ayarlandı'"), StrConcat(ArrayOfAccounts_, Chars.LF));
			EndIf;
			
			QueryText = StrTemplate(NStr("vi = '%1.
					|Sẽ không kết nhập các thanh toán trong kỳ đóng.
					|Tiếp tục kết nhập?';
					|ru = '%1.
					|Платежи в закрытом периоде не будут загружены.
					|Продолжить загрузку?';
					|en = '%1.
					|Payments in the closed period will not be imported.
					|Continue import?'; fa = '%1.
					|Payments in the closed period will not be imported.
					|Continue import?';
					|it = '%1.
					|Платежи в закрытом периоде не будут загружены.
					|Продолжить загрузку?';
					|pl = '%1.
					|Payments in the closed period will not be imported.
					|Continue import?';
					|tr = '%1.
					|Kapalı dönemdeki ödemeler yüklenmeyecektir. 
					|Yüklemeye devam edilsin mi?'"), MessageText);
			CallbackOnCompletion = New CallbackDescription("CheckingBeforeUploadingDocumentsEnd", ThisObject);
			ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.OKCancel);
			
		Else
			UploadDocumentsAfterVerification();
		EndIf;
	
	EndIf;

EndProcedure

&AtServer
Procedure GetInvoicesWithBanOnChangesInUploadedPeriod(AccountList)

	TableToCheck = EDIWithBanksServer.EmptyInvoiceTableToCheckIfEditingIsProhibited();
	
	Filter = New Structure("Level", 0);
	ListOfBankAccounts = ListOfSelectedBankAccounts(Filter);
	
	For Each Account In ListOfBankAccounts Do
		
		If Not Account.Check Or Account.Downloading Then
			Continue;
		EndIf;
		
		NewRow = TableToCheck.Add();
		NewRow.Date = Account.ImportStartDate;
		NewRow.Object = Account.Ref;
		
	EndDo;
	
	AccountList = EDIWithBanksServer.FillInListOfInvoicesWithBanOnChangesInUploadedPeriod(TableToCheck);

EndProcedure

&AtClient
Procedure UploadDocumentsAfterVerification()

	UploadToServer_1(); // Downloading from files
	
	FillInInvoiceLoadingPeriod(BankAccounts.GetItems());
	
	Tick = 0;
	AttachIdleHandler("HandleUploadCompletion", 1, True);

EndProcedure

&AtClient
Procedure CheckingBeforeUploadingDocumentsEnd(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.OK Then
		UploadDocumentsAfterVerification();
	Else
		FilesAreBeingProcessed = False;
	EndIf;

EndProcedure

&AtClient
Procedure HandleUploadCompletion()
	
	ThereAreCompletedDownloads = False;
	ThereAreOutstandingTasks = False;
	
	CheckDownloadProgress(BankAccounts.GetItems(), ThereAreCompletedDownloads, ThereAreOutstandingTasks);
	
	FilesAreBeingProcessed = False;
	
	If ThereAreOutstandingTasks Then
		Tick = Tick + 1;
		If Tick > 3 Then
			Tick = 0;
		EndIf;
	EndIf;
	
	If ThereAreCompletedDownloads Then
		CompleteDownload();
	EndIf;
	
	If ThereAreOutstandingTasks Then
		AttachIdleHandler("HandleUploadCompletion", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteDownload()
	
	UploadedInvoices = New Array;
	UploadedPayments = New Array;
	FillInUploadResults(BankAccounts.GetItems(), UploadedInvoices, UploadedPayments);
	
	Accounts = "";
	For Each Account In UploadedInvoices Do
		Accounts = Accounts + String(Account["Ref"]) + "
		|";
		Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
	EndDo;
	
	CompleteDownloadOnServer(UploadedPayments);
	
	If ValueIsFilled(Accounts) Then
		
		ShowUserNotification(,, StrTemplate(
			NStr("vi = 'Đã hoàn tất tải theo các tài  khoản
			|%1';
			|ru = 'Загрузка по счетам
			|%1 завершена';
			|en = 'Import for the ""%1"" accounts
			|is completed'; fa = 'Import for the ""%1"" accounts
			|is completed';
			|it = 'Import for the ""%1"" accounts
			|is completed';
			|pl = 'Import for the ""%1"" accounts
			|is completed';
			|tr = '%1 muhasebesine göre
			|indirme tamamlandı.'"),
			Accounts)
		);
		Notify("Upload_ExchangeWithBanks");
	EndIf;
	
EndProcedure

&AtServer
Procedure CompleteDownloadOnServer(UploadedPayments)
	
	TableOfAccounts = DataProcessors.EDIWithBanks.TableOfAccounts(SelectingListOfAccounts(), True);
	FillInLastUploadPeriod(TableOfAccounts, BankAccounts.GetItems());
	DisplayMessagesForUploadedPayments(UploadedPayments);
	
EndProcedure

&AtServerNoContext
Function JobCompleted(JobID, Account, FileName)
	
	Result = TimeConsumingOperations.JobCompleted(JobID, True);
	
	If Result.Status = "Error" Then
		DataProcessors.EDIWithBanks.OutputFileUploadError(Account, FileName, Result.ErrorInfo);
	EndIf;
	
	Return Result.Status <> "Running";
	
EndFunction

&AtClient
Function ExtractFileHeader(Account, StatementData)
	
	If Account = Undefined Then
		Return "";
	EndIf;
	
	TitleText = "";
	
	StatementHeaderData  = "";
	ListOfStatementAccounts     = "";
	CurrentAccountsStatements   = "";
	
	If TypeOf(StatementData) = Type("Structure") Then
		
		If StatementData.Property("AccountList", ListOfStatementAccounts) Then
			
			If ListOfStatementAccounts.Find(Account.AccountNumber) = Undefined Then
				TitleText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '<Tệp không hỗ trợ dữ liệu theo tài khoản ngân hàng %1 với số %2>';
						|ru = '<Файл не содержит данных по банковскому счету %1 с номером %2>';
						|en = '<The file does not contain data on the bank account %1 with number %2>'; fa = '<The file does not contain data on the bank account %1 with number %2>';
						|it = '<Файл не содержит данных по банковскому счету %1 с номером %2>';
						|pl = '<Plik nie zawiera danych dotyczących rachunku bankowego %1 z numerem %2>';
						|tr = '<Dosya, %2numaralı banka hesabı %1 için veri içermiyor>'"),
					String(Account.Ref),
					Account.AccountNumber);
				Return TitleText;
			EndIf;
		Else
			Return NStr("vi = '<Tệp không chứa thông tin về các tài khoản thanh toán>';
						|ru = '<Файл не содержит сведений о расчетных счетах>';
						|en = '<The file does not contain information on current accounts>'; fa = '<The file does not contain information on current accounts>';
						|it = '<Файл не содержит сведений о расчетных счетах>';
						|pl = '<Plik nie zawiera danych o rachunkach rozliczeniowych>';
						|tr = '<Dosya, cari işlem hesapları hakkında bilgi içermiyor>'");
		EndIf;
		
		If StatementData.Property("Title", StatementHeaderData) Then
			TitleText = "
			|" + NStr("vi = 'Người gửi';
						|ru = 'Отправитель';
						|en = 'Sender'; fa = 'فرستنده';
						|it = 'Отправитель';
						|pl = 'Nadawca';
						|tr = 'Gönderen'") + "              " + StatementHeaderData["Sender"] + "
			|" + NStr("vi = 'Ngày tạo';
						|ru = 'Дата создания';
						|en = 'Date created'; fa = 'تاریخ ایجاد';
						|it = 'Дата создания';
						|pl = 'Data utworzenia';
						|tr = 'Oluşturma tarihi'") + "            " + StatementHeaderData["CreationDate"] + " " + StatementHeaderData["CreationTime"] + "
			|" + NStr("vi = 'Đầu kỳ';
						|ru = 'Начало периода';
						|en = 'Period start'; fa = 'شروع دوره';
						|it = 'Начало периода';
						|pl = 'Początek okresu';
						|tr = 'Dönem başı'") + "           " + StatementHeaderData["StartDate"] + "
			|" + NStr("vi = 'Cuối kỳ';
						|ru = 'Окончание периода';
						|en = 'Period end'; fa = 'پایان دوره';
						|it = 'Окончание периода';
						|pl = 'Koniec okresu';
						|tr = 'Dönem sonu'") + "        " + StatementHeaderData["EndDate"] + "
			|";
		EndIf;
		
		If StatementData.Property("SettlementAccounts", CurrentAccountsStatements) Then
			For Each SettlementAccount In CurrentAccountsStatements Do
				If SettlementAccount.CreateAccount_1 = Account.AccountNumber
					Then
					TitleText = TitleText + "
					|" + NStr("vi = 'Tài khoản thanh toán';
								|ru = 'Расчетный счет';
								|en = 'Current account'; fa = 'حساب جاری';
								|it = 'Расчетный счет';
								|pl = 'Rachunek rozliczeniowy';
								|tr = 'Cari işlemler hesabı'") + "           " + SettlementAccount.CreateAccount_1 + "
					|" + NStr("vi = 'Số dư đầu';
								|ru = 'Начальный остаток';
								|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
								|it = 'Начальный остаток';
								|pl = 'Saldo początkowe';
								|tr = 'Açılış bakiyesi'") + "        " + SettlementAccount.OpeningBalance + "
					|" + NStr("vi = 'Đã thu';
								|ru = 'Поступило';
								|en = 'Received'; fa = 'دریافت‌شده';
								|it = 'Поступило';
								|pl = 'Wpłynęło';
								|tr = 'Alınan'") + "                " + SettlementAccount.TotalReceived_ + "
					|" + NStr("vi = 'Đã chi';
								|ru = 'Списано';
								|en = 'Written off'; fa = 'اسقاط‌شده';
								|it = 'Списано';
								|pl = 'Wyksięgowano';
								|tr = 'Kayıttan düşüldü'") + "                  " + SettlementAccount.TotalDebited + "
					|" + NStr("vi = 'Số dư cuối';
								|ru = 'Конечный остаток';
								|en = 'Closing balance'; fa = 'مانده پایان دوره';
								|it = 'Конечный остаток';
								|pl = 'Saldo końcowe';
								|tr = 'Kapanış bakiyesi'") + "         " + SettlementAccount.ClosingBalance + "%RemainderPeriod_
					|";
					
					RemainderPeriod_ = "";
					If Not IsBlankString(SettlementAccount.StartDate) And Not IsBlankString(SettlementAccount.EndDate) Then
						If SettlementAccount.StartDate = SettlementAccount.EndDate Then
							RemainderPeriod_ = "
					|" + NStr("vi = 'Trong ngày';
								|ru = 'За день';
								|en = 'Per day'; fa = 'روزانه';
								|it = 'За день';
								|pl = 'Za dzień';
								|tr = 'Günlük'") + "                  " + SettlementAccount.StartDate;
						Else
							RemainderPeriod_ = "
					|" + NStr("vi = 'Trong kỳ';
								|ru = 'За период';
								|en = 'Period'; fa = 'دوره';
								|it = 'За период';
								|pl = 'Za okres';
								|tr = 'Dönem içerisinde'") + "                " + SettlementAccount.StartDate + " - " + SettlementAccount.EndDate;
						EndIf;
					EndIf;
					
					TitleText = StrReplace(TitleText, "%RemainderPeriod_", RemainderPeriod_);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return TitleText;
	
EndFunction


&AtServer
Procedure SetDynamicListSelection()
	
	AccountList = New ValueList;
	
	ListOfAccountsByAccount = Catalogs.CompaniesBankAccounts.CatalogBankAccounts(BankAccountSelection);
	
	If ListOfAccountsByAccount.Count() <> 0 Then
		AccountList.LoadValues(ListOfAccountsByAccount);
	EndIf;
	
	AccountList.Add(BankAccountSelection);
	AccountList.Add(Catalogs.CompaniesBankAccounts.EmptyRef());
	AccountList.Add(Undefined);
	
	CommonClientServer.SetDynamicListFilterItem(
		ImportedDocuments,
		"BankAccount",
		AccountList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(BankAccountSelection));
	
	ToLimitTheSpecifiedTimePeriod = (LastStatementOnly = 0);
	
	ImportedDocuments.Parameters.SetParameterValue("ToLimitTheSpecifiedTimePeriod", ToLimitTheSpecifiedTimePeriod);
	
	CommonClientServer.SetDynamicListFilterItem(
		ImportedDocuments,
		"ImportErrors",,
		DataCompositionComparisonType.Filled,,
		OnlyErroneousPayments = 1);
	
	CommonClientServer.SetDynamicListFilterItem(
		ImportedDocuments,
		"Posted",
		False,
		DataCompositionComparisonType.Equal,,
		OnlyErroneousPayments = 2);
	
EndProcedure

&AtServer
Procedure CreateCounterpartyOnServer(NameOfCounterparty, DocumentData, BankAccount)
	
	StatementDocuments = Object.DocumentsToImport.Unload();
	StatementDocuments.Add();
	FillPropertyValues(StatementDocuments[0], DocumentData);
	
	DocumentLine = StatementDocuments[0];
	DocumentLine.NameOfCounterparty = NameOfCounterparty;
	
	NewCounterparty = EDIWithBanksServer.CreateCounterparty(StatementDocuments, DocumentLine);
	NewAccount_ = EDIWithBanksServer.CreateCounterpartySBankAccount(StatementDocuments, DocumentLine, NewCounterparty);
	
	If Not ValueIsFilled(NewCounterparty) Then
		Return;
	EndIf;
	
	SubstituteCounterpartyInDocuments(NameOfCounterparty, NewCounterparty, NewAccount_, DocumentLine.Partner);
	
	FormTable = Items[JournalName]; // FormTable
	FormTable.Refresh();
	
EndProcedure

&AtServer
Procedure SubstituteCounterpartyOnServer(DocumentRef, NameOfCounterparty, CounterpartyFound, DocumentData, BankAccount)
	
	StatementDocuments = Object.DocumentsToImport.Unload();
	StatementDocuments.Add();
	FillPropertyValues(StatementDocuments[0], DocumentData);
	
	AccountOfCounterparty = FindCounterpartyAccount(CounterpartyFound, StatementDocuments);
	
	If AccountOfCounterparty = Undefined Then
		
		If StatementDocuments[0].Outgoing Then
			NameOfAccountColumn = "BENEFICIARYACCOUNT";
		Else
			NameOfAccountColumn = "PAYERACCOUNT";
		EndIf;
		
		If ThereAreDuplicatesOfCounterpartySAccountNumber(CounterpartyFound, StatementDocuments[0][NameOfAccountColumn]) Then
			
			MessageText = StrTemplate(
				NStr("vi = 'Đã tìm thấy nhiều hơn một tài khoản ngân hàng của đối tác %1 với số %2. Hãy điền dữ liệu thủ công trong biểu mẫu chứng từ.';
					|ru = 'Найдено более одного банковского счета контрагента %1 с номером %2. Заполните данные вручную в форме документа.';
					|en = 'More than one bank account with number %2 of the %1 counterparty was found. Fill in the data manually in the document form.'; fa = 'More than one bank account with number %2 of the %1 counterparty was found. Fill in the data manually in the document form.';
					|it = 'Найдено более одного банковского счета контрагента %1 с номером %2. Заполните данные вручную в форме документа.';
					|pl = 'More than one bank account with number %2 of the %1 counterparty was found. Fill in the data manually in the document form.';
					|tr = '%1 karşı tarafının %2 numaralı birden fazla banka hesabı bulundu. Verileri belge formunda manuel olarak doldurun.'"),
				CounterpartyFound,
				StatementDocuments[0][NameOfAccountColumn]);
				
			Common.MessageToUser(MessageText, DocumentRef, , Items.ImportedDocumentsCounterparty.Name);
			AccountOfCounterparty = Catalogs.CounterpartyBankAccounts.EmptyRef();
			
		Else
			AccountOfCounterparty =
				EDIWithBanksServer.CreateCounterpartySBankAccount(StatementDocuments, StatementDocuments[0], CounterpartyFound);
		EndIf;
		
	EndIf;
	
	Partner = CashServer.GetCounterpartyPartner(CounterpartyFound);
	
	SubstituteCounterpartyInDocuments(NameOfCounterparty, CounterpartyFound, AccountOfCounterparty, Partner);
	
	FormTable = Items[JournalName]; // FormTable
	FormTable.Refresh();
	
EndProcedure

&AtServer
Function FindCounterparty(NameOfCounterparty, DocumentData)
	
	StatementDocuments = Object.DocumentsToImport.Unload();
	StatementDocuments.Add();
	FillPropertyValues(StatementDocuments[0], DocumentData);
	
	DocumentLine = StatementDocuments[0];
	DocumentLine.NameOfCounterparty = NameOfCounterparty;
	
	SearchInn = ?(DocumentLine.Outgoing, DocumentLine.BeneficiaryTIN, DocumentLine.PayerTIN);
	DocumentLine.CheckTIN = ValueIsFilled(SearchInn)
									And SearchInn <> "000000000000"
									And SearchInn <> "0000000000";
	SearchCheckpoint = ?(DocumentLine.Outgoing, DocumentLine.BeneficiaryCRTR, DocumentLine.KPPPayer);
	DocumentLine.CheckCRTR = (ValueIsFilled(SearchCheckpoint) And SearchCheckpoint <> "0");
	
	EDIWithBanksServer.ListOfCounterparties(StatementDocuments, StatementDocuments);
	
	Counterparty = StatementDocuments[0].Counterparty;
	If ValueIsFilled(Counterparty) Then
		Return Counterparty;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function FindCounterpartyAccount(Counterparty, StatementDocuments)
	
	DocumentLine = StatementDocuments[0];
	DocumentLine["LineNumber"] = 0;
	DocumentLine.Counterparty = Counterparty;
	
	EDIWithBanksServer.ListOfCounterparties(StatementDocuments, StatementDocuments);
	
	AccountOfCounterparty = StatementDocuments[0].AccountOfCounterparty;
	If ValueIsFilled(AccountOfCounterparty) Then
		Return AccountOfCounterparty;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function ParseDocumentExtractData(StatementData, BankAccount)
	
	DocumentData = Undefined;
	
	AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
	AccountNumber = AccountAttributes.AccountNumber;
	
	DocumentRows = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StatementData, Chars.LF);
	StatementDataStructure = CashClientServer.Parse1CClientBankExchangeStatementFile(
		DocumentRows, True);
	
	If StatementDataStructure = Undefined
		And Not StatementDataStructure.StatementDocuments.Count() Then
		Return Undefined;
	EndIf;
	
	DocumentData = StatementDataStructure.StatementDocuments[0];
	DocumentData.Insert("Outgoing", (DocumentData.PayerAccount = AccountNumber));
	DocumentData.Insert("BankAccount", BankAccount);
	DocumentData.Insert("Currency", AccountAttributes.Currency);
	DocumentData.Insert("LineNumber", 0);
	
	
	Return DocumentData;
	
EndFunction

&AtServer
Procedure SubstituteCounterpartyInDocuments(NameOfCounterparty, CounterpartyRef, AccountLink_, PartnerLink)
	
	Query = New Query;
	Query.Text = "SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.StatementData AS StatementData,
	|	DocumentData.BankAccount AS BankAccount
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|WHERE
	|	DocumentData.NameOfCounterparty = &NameOfCounterparty
	|	AND DocumentData.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.StatementData,
	|	DocumentData.BankAccount
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|WHERE
	|	DocumentData.NameOfCounterparty = &NameOfCounterparty
	|	AND DocumentData.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)";
	
	Query.SetParameter("NameOfCounterparty", NameOfCounterparty);
	
	Selection = Query.Execute().Select();
	
	If Not ValueIsFilled(AccountLink_) Then
		AccountLink_ = Catalogs.CounterpartyBankAccounts.EmptyRef();
	EndIf;
	
	AccountNumber = Common.ObjectAttributeValue(AccountLink_, "AccountNumber");
	
	While Selection.Next() Do
		
		DocumentData = ParseDocumentExtractData(Selection.StatementData, Selection.BankAccount);
		
		If DocumentData <> Undefined Then
			
			AccountOfCounterparty = ?(DocumentData.Outgoing, DocumentData.BeneficiaryAccount, DocumentData.PayerAccount);
			
			If AccountOfCounterparty <> AccountNumber
				And AccountNumber <> Undefined Then
				Continue;
			EndIf;
			
		EndIf;
		
		DocumentObject = Selection.Ref.GetObject();
		DocumentObject.Counterparty = CounterpartyRef;
		DocumentObject.CounterpartyBankAccount = AccountLink_;
		
		DocumentObject.Counterparty = CounterpartyRef;
		
		For Each TSRow In DocumentObject.ARAPDetails Do
			TSRow.Partner = PartnerLink;
		EndDo;
		
		DocumentObject.AdditionalProperties.Insert("EDIWithBanks", True);
		DocumentObject.CheckFilling();
		If DocumentObject.AdditionalProperties.Property("FillingErrors") Then
			DocumentObject.ImportErrors = TrimAll(DocumentObject.AdditionalProperties.FillingErrors);
		EndIf;
		
		DocumentObject.Write();
	EndDo;
	
EndProcedure


// Displays information about the read confirmation files for crediting funds
//
// Parameters:
//  InvoiceData - FormDataCollectionItem - the row of the tabular part "Bank accounts"
//  ListOfFiles - Array - read bank account files 
//
&AtClient
Procedure GenerateFileHeaders(InvoiceData, ListOfFiles)

	StatementTitle.Clear();
	HeaderTransfer.Clear();
	
	For Each CurrentFileData In ListOfFiles Do
	
		StatementDetails = CurrentFileData.Statement_;
		
		If CurrentFileData.CreditingConfirmationFile Then
		
			If HeaderTransfer.LineCount() <> 0 Then
				HeaderTransfer.AddLine(Chars.LF);
			EndIf;
			
			If ListOfFiles.Count() > 1 Then
				HeaderTransfer.AddLine(CurrentFileData.FileName);
			EndIf;
			
			If StatementDetails.StatementData <> Undefined Then
				MessageText = TitleOfEnrollmentFile(InvoiceData, StatementDetails.StatementData);
			Else
				MessageText = StatementDetails.MessageText;
			EndIf;
			
			HeaderTransfer.AddLine(MessageText);
		
		Else
		
			If StatementTitle.LineCount() <> 0 Then
				StatementTitle.AddLine(Chars.LF);
			EndIf;
			
			If ListOfFiles.Count() > 1 Then
				StatementTitle.AddLine(CurrentFileData.FileName);
			EndIf;
			
			If StatementDetails.StatementData <> Undefined Then
				MessageText = ExtractFileHeader(InvoiceData, StatementDetails.StatementData);
			Else
				MessageText = StatementDetails.MessageText;
			EndIf;
			
			StatementTitle.AddLine(MessageText);
		
		EndIf;
	
	EndDo;

EndProcedure

// Returns a text with basic information about the DS enrollment file.
// 
// Parameters:
//  Account - FormDataCollectionItem - the selected line in the list of bank accounts.
//  FileData - Structure - basic information about the file that was read when it was selected:
//   * SettlementAccounts - Array of Structure- list of current accounts by file, See CashClientServer.CurrentAccountData_.
//   * AccountList - Array of String - list of bank accounts.
//   * Title - Structure - information about uploaded data:
//   ** CreationDate2 - Date - the date of formation of the file on the enrollment of the DS.
//   ** RegistryNumber - String - the number of the register about the enrollment of the DS.
//   ** RegistryDate - Date - the date of formation of the register on the enrollment of the DS.
//   ** ContractNumber - String - the number of the contract with the bank.
//   ** ContractDate_ - Date - date of the agreement with the bank.
// 
// Returns:
//  String - information about the enrollment file
&AtClient
Function TitleOfEnrollmentFile(Account, FileData)
	
	If Account = Undefined Then
		Return "";
	EndIf;
	
	TitleText = "";
	
	If FileData.SettlementAccounts.Count() = 0 Then
		Return NStr("vi = '<Tệp không chứa thông tin về tài khoản thanh toán>';
					|ru = '<Файл не содержит сведений о расчетном счете>';
					|en = '<File does not contain current account details>'; fa = '<File does not contain current account details>';
					|it = '<Файл не содержит сведений о расчетном счете>';
					|pl = '<Plik nie zawiera danych o rachunku rozliczeniowym>';
					|tr = '<Dosya, cari işlemler hesabı hakkında bilgi içermiyor>'");
	EndIf;
	
	If FileData.AccountList.Find(Account.AccountNumber) = Undefined Then
		
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '<Tệp không chứa dữ liệu về tài khoản ngân hàng %1 với số %2>';
				|ru = '<Файл не содержит данных по банковскому счету %1 с номером %2>';
				|en = '<The file does not contain data on the bank account %1 with number %2>'; fa = '<The file does not contain data on the bank account %1 with number %2>';
				|it = '<Файл не содержит данных по банковскому счету %1 с номером %2>';
				|pl = '<Plik nie zawiera danych dotyczących rachunku bankowego %1 z numerem %2>';
				|tr = '<Dosya, %2numaralı banka hesabı %1 için veri içermiyor>'"),
			String(Account.Ref),
			Account.AccountNumber);
		Return TitleText;
		
	EndIf;
			
	FileTitle = FileData.Title;
	SettlementAccount = FileData.SettlementAccounts[0];
	
	If SettlementAccount.CreateAccount_1 = Account.AccountNumber Then
		TitleText = StrTemplate(
			"" + NStr("vi = 'Ngày lập %1';
						|ru = 'Дата формирования %1';
						|en = '%1 creation date'; fa = '%1 creation date';
						|it = 'Дата формирования %1';
						|pl = 'Data utworzenia %1';
						|tr = 'Tarih oluşturma %1'") + "
			|" + NStr("vi = 'Tài khoản thanh toán    %2';
						|ru = 'Расчетный счет    %2';
						|en = 'Current account    %2'; fa = 'Current account    %2';
						|it = 'Расчетный счет    %2';
						|pl = 'Rachunek rozliczeniowy %2';
						|tr = 'Cari işlemler hesabı    %2'") + "
			|" + NStr("vi = 'Sổ đăng ký            số %3 ngày %4';
						|ru = 'Реестр            № %3 от %4';
						|en = 'Registry            # %3 from %4'; fa = 'Registry            # %3 from %4';
						|it = 'Реестр            № %3 от %4';
						|pl = 'Rejestr            nr %3 z dn. %4';
						|tr = 'Sicil            № %3''dan %4'") + "
			|" + NStr("vi = 'Hợp đồng           số %5 ngày %6';
						|ru = 'Договор           № %5 от %6';
						|en = 'Contract           # %5 from %6'; fa = 'Contract           # %5 from %6';
						|it = 'Договор           № %5 от %6';
						|pl = 'Umowa           nr %5 z dn. %6';
						|tr = 'Sözleşme            № %5''dan %6'"),
			Format(FileTitle.CreationDate2, "DLF=D"),
			SettlementAccount.CreateAccount_1,
			FileTitle.RegistryNumber,
			Format(FileTitle.RegistryDate, "DLF=D"),
			FileTitle.ContractNumber,
			Format(FileTitle.ContractDate_, "DLF=D"));
	EndIf;
	
	Return TitleText;
	
EndFunction

&AtClient
Procedure OutputReportCompletion()

	If IndexesOfSelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	AllFilesAreRead = True;
	
	For Each CurrentIndex In IndexesOfSelectedRows Do
		
		Account = BankAccounts.FindByID(CurrentIndex.Value);
		
		If Not Account.Imported And TypeOf(Account.ConfigureExchange) = Type("String") Then
			
			If Not Account.FilesAreRead Then
				AllFilesAreRead = False;
				Break;
			EndIf;
			
		EndIf;
	
	EndDo;
	
	If AllFilesAreRead Then
		
		DownloadReportTable = Undefined;
		
		DownloadReportTable = DisplayReportOnServer(IndexesOfSelectedRows);
		
		If DownloadReportTable <> Undefined Then
			DownloadReportTable.ReadOnly = True;
			DownloadReportTable.Show(NStr("vi = 'Báo cáo tải lên thanh toán';
											|ru = 'Отчет о загрузке платежей';
											|en = 'Payment import report'; fa = 'Payment import report';
											|it = 'Отчет о загрузке платежей';
											|pl = 'Raport wczytywania płatności';
											|tr = 'Ödeme içe aktarma raporu'"));
		EndIf;
		
	Else
		AttachIdleHandler("OutputReportCompletion", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure SaveDownloadSettings(Result, AdditionalParameters) Export

	If TypeOf(Result) = Type("Structure") Then
		FillPropertyValues(Object, Result);
	EndIf;

EndProcedure

&AtClient
Procedure UpdateListOfBankAccounts(UpdateList = False)

	LoadingIsInProgress_ = LoadingIsInProgress(BankAccounts.GetItems())
		Or FilesAreBeingProcessed;
	
	If Not LoadingIsInProgress_ Then
		UpdateListOfAccountsOnServer(UpdateList);
		ReadStatementData_();
	EndIf;

EndProcedure

&AtClient
Function LoadingIsInProgress(TreeItems, LoadingIsInProgress_ = False)

	// If there are accounts that are being uploaded, we do not give them an update
	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			If Account.Downloading Then
				LoadingIsInProgress_ = True;
			EndIf;
		
		Else
			LoadingIsInProgress_ = LoadingIsInProgress(Account.GetItems(), LoadingIsInProgress_);
		EndIf;
		
		If LoadingIsInProgress_ Then
			Break;
		EndIf;
		
	EndDo;
	
	Return LoadingIsInProgress_;

EndFunction

&AtServer
Function SelectingListOfAccounts()

	Filter = New Structure;
	
	If ValueIsFilled(CompanyFilter) Then
		Filter.Insert("Owner", CompanyFilter);
	EndIf;
	
	If ValueIsFilled(CurrencySelection_3) Then
		Filter.Insert("CashCurrency", CurrencySelection_3);
	EndIf;
	
	If ValueIsFilled(AccountNumberSelection) Then
		Filter.Insert("AccountNumber", AccountNumberSelection);
	EndIf;
	
	Return Filter;

EndFunction

&AtClient
Procedure ChangeViewingMode(Mode)

	LoadingIsInProgress_ = LoadingIsInProgress(BankAccounts.GetItems())
		Or FilesAreBeingProcessed;
	
	If Not LoadingIsInProgress_ Then
		
		InvoiceViewingMode = Mode;
		FillInInvoiceTreeByDisplayMode();
		ReadStatementData_();
		
		SetVisibilityByInvoiceDisplayMode(ThisObject);
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInInvoiceTreeByDisplayMode(UpdateList = False)

	If UpdateList Then
		
		BankAccounts.GetItems().Clear();
		AccountTree = FormAttributeToValue("BankAccounts");
		
	Else
		
		Filter = New Structure;
		Filter.Insert("Level", 0);
		FoundRows = ListOfSelectedBankAccounts(Filter);
		
		CurrentTree = FormAttributeToValue("BankAccounts");
		Table = ConvertTreeToTable(CurrentTree, FoundRows);
		
		For Each LineOfATabularSection In Object.BankAccounts Do
			
			TableRow = Table.Find(LineOfATabularSection.Ref, "Ref");
			
			If TableRow <> Undefined Then
				FillPropertyValues(LineOfATabularSection, TableRow);
			EndIf;
			
		EndDo;
		
		BankAccounts.GetItems().Clear();
		AccountTree = FormAttributeToValue("BankAccounts");
		
	EndIf;
	
	If InvoiceViewingMode = 0 Then
		
		For Each TableRow In Object.BankAccounts Do
			AddZeroLevelOfTree(TableRow, AccountTree);
		EndDo;
		
		ValueToFormAttribute(AccountTree, "BankAccounts");
		
	Else
		
		BankAccountsTable = Object.BankAccounts.Unload();
		Companies = BankAccountsTable.Copy(, "Organization, Check");
		Companies.GroupBy("Organization", "Check");
		
		For Each OrganizationString In Companies Do
			
			TreeRow = AccountTree.Rows.Add();
			FillPropertyValues(TreeRow, OrganizationString);
			TreeRow.Group = OrganizationString.Organization;
			TreeRow.Level = 1;
			
			Filter = New Structure("Organization", OrganizationString.Organization);
			OrganizationAccounts = BankAccountsTable.FindRows(Filter);
			
			For Each ArrayRow In OrganizationAccounts Do
				AddZeroLevelOfTree(ArrayRow, TreeRow);
			EndDo;
			
		EndDo;
		
		ValueToFormAttribute(AccountTree, "BankAccounts");
		
	EndIf;

EndProcedure

&AtServer
Procedure AddZeroLevelOfTree(TableRow, AccountTree)

	TreeRow = AccountTree.Rows.Add();
	FillPropertyValues(TreeRow, TableRow);
	TreeRow.Group = TableRow.Ref;
	TreeRow.Level = 0;
	
	If Object.AccountList.FindByValue(TreeRow.Ref) <> Undefined Then
		
		TreeRow.Check = True;
		
		If InvoiceViewingMode = 1 Then
			AccountTree.Check = True;
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure SetTagForSubordinateLines(TreeItems, Value)

	For Each TreeItem In TreeItems Do
		
		If Not TreeItem.Downloading Then
			TreeItem.Check = Value;
		EndIf;
		
		SetTagForSubordinateLines(TreeItem.GetItems(), Value);
		
	EndDo;

EndProcedure

&AtClient
Procedure SetTagForParentLine(TreeRow)

	TreeNode = TreeRow.GetParent();
	
	If TreeNode <> Undefined Then
		
		ThereIsMark = False;
		
		For Each Branch1 In TreeNode.GetItems() Do
			If Branch1.Check Then
				ThereIsMark = True;
				Break;
			EndIf;
		EndDo;
		
		TreeNode.Check = ThereIsMark;
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInListOfMarkedAccounts()

	Filter = New Structure("Check, Level", True, 0);
	MarkedLines = ListOfSelectedBankAccounts(Filter);
	
	Object.AccountList.Clear();
	
	For Each ArrayRow In MarkedLines Do
		Object.AccountList.Add(ArrayRow.Ref);
	EndDo;

EndProcedure

&AtClient
Procedure ReadDataFromTreeExtracts(TreeItems)

	For Each Account In TreeItems Do
		
		If Account.Level <> 0 Then
			ReadDataFromTreeExtracts(Account.GetItems())
		Else
			
			#If Not WebClient Then
			If Not Account.DirectExchange And ValueIsFilled(Account.ConfigureExchange) Then
				ReadStatementData(Account);
			Else
				Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
			EndIf;
			#Else
				Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
			#EndIf
		
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure SelectSelectedInvoice(TreeItems)

	For Each TreeRow In TreeItems Do
		
		If TreeRow.Level = 0 Then
			
			If TreeRow.Ref = SelectedBankAccount Then
				
				Items.BankAccounts.CurrentRow = TreeRow.GetID();
				TreeRow.Check = True;
				
				Object.AccountList.Add(TreeRow["Ref"]);
				
				If InvoiceViewingMode = 1 Then
					SetTagForParentLine(TreeRow);
				EndIf;
				
				MessageText = "";
				
				If ValueIsFilled(TreeRow.ConfigureExchange) Then
					
					If TreeRow.DirectExchange Then
						MessageText = NStr("vi = '<Trao đổi trực tiếp được chọn. Dữ liệu sẽ được yêu cầu khi tải xuống thanh toán.>';
											|ru = '<Выбран прямой обмен. Данные будут запрошены при загрузке платежей.>';
											|en = '<Direct exchange is selected. Data will be requested while importing payments.>'; fa = '<Direct exchange is selected. Data will be requested while importing payments.>';
											|it = '<Выбран прямой обмен. Данные будут запрошены при загрузке платежей.>';
											|pl = '<Wybrana bezpośrednia wymiana. Dane będą pobierane przy wczytywaniu płatności>';
											|tr = '<Doğrudan değişim seçildi. Ödemeler yüklenirken veriler istenecektir.>'");
					Else
						
						#If Not WebClient Then
						PrintAccountStatementHeaders(TreeRow, MessageText);
						#EndIf
						
					EndIf;
					
				Else
					MessageText = NStr("vi = '<Chưa chỉ định tệp/thư mục sao kê và/hoặc ghi có tiền.>';
										|ru = '<Не указан файл/каталог выписки и/или зачисления ДС.>';
										|en = '<File/directory of the cash statement/deposit is not specified.>'; fa = '<File/directory of the cash statement/deposit is not specified.>';
										|it = '<Не указан файл/каталог выписки и/или зачисления ДС.>';
										|pl = '<Nie podano pliku/katalogu wyciągu i/lub zaliczenia środków pieniężnych.>';
										|tr = '<Ekstrenin dosyası/klasörü ve/veya Nakit transferi belirtilmedi.>'");
				EndIf;
				
				If MessageText <> "" Then
					StatementTitle.Clear();
					StatementTitle.AddLine(MessageText);
				EndIf;
				
				Return;
				
			EndIf;
			
		Else
			SelectSelectedInvoice(TreeRow.GetItems())
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure UploadDocumentsFromTree(TreeItems, Errors)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			If Not Account.Check Or Account.Downloading Then
				Continue;
			EndIf;
			
			UploadInvoiceDocuments(Account, Errors);
		
		Else
			UploadDocumentsFromTree(Account.GetItems(), Errors)
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure UploadInvoiceDocuments(Account, HasErrors)

	MessageText = "";
	DeleteBankAccountFiles(Account.Ref);
	Account.FilesAreRead = False;
	
		If ValueIsFilled(Account.ConfigureExchange) Then
			#If Not WebClient Then
			ReadStatementData(Account);
			Account.FilesAreRead = True;
			#Else
			ReadStatementDataInteractiveMode(Account);
			#EndIf
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với tài khoản ngân hàng %1, chưa chọn tệp sao kê trong cài đặt trao đổi. Chọn một tập tin.';
					|ru = 'Для банковского счета %1 не выбран файл выписки в настройке обмена. Выберите файл.';
					|en = 'Statement file is not selected for bank account %1 in the exchange setting. Select a file.'; fa = 'Statement file is not selected for bank account %1 in the exchange setting. Select a file.';
					|it = 'Для банковского счета %1 не выбран файл выписки в настройке обмена. Выберите файл.';
					|pl = 'W przypadku rachunku bankowego %1 w ustawieniach wymiany nie wybrano pliku wyciągu. Wybierz plik.';
					|tr = '%1 banka hesabında değişim ayarlarında ekstre dosyası seçilmedi. Dosya seç.'"), Account.Ref);
		EndIf;
	
	If ValueIsFilled(MessageText) Then
		CommonClient.MessageToUser(
			MessageText,, Items.BankAccountsConfigureExchange.Name, , HasErrors);
	EndIf;

EndProcedure

&AtServer
Procedure SaveStatementToTemporaryStorage(TreeItems)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			BankAccountFiles = ListOfBankAccountFiles(Account.Ref, Object.Files);
		
			If Account.Check And Not Account.Downloading And Not Account.DirectExchange And BankAccountFiles.Count() <> 0 Then
				If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
					
					For Each Data In BankAccountFiles Do
						
						If Data.FileStorageAddress = "" Then
							Data.FileStorageAddress = PutToTempStorage(
								Data.Statement_.StatementLines, UUID);
						EndIf;
						
					EndDo;
					
				EndIf;
			EndIf;
			
		Else
			SaveStatementToTemporaryStorage(Account.GetItems())
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure FillInInvoiceTableByTree()

	Filter = New Structure("Level", 0);
	ListOfTreeRows = ListOfSelectedBankAccounts(Filter);
	
	Object.BankAccounts.Clear();
	
	For Each TreeRow In ListOfTreeRows Do
		
		NewRow = Object.BankAccounts.Add();
		FillPropertyValues(NewRow, TreeRow);
		
	EndDo;

EndProcedure

&AtClient
Function FilesAreRead(TreeItems, AllFilesAreRead = True)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			If Not Account.Check Or Account.Downloading Then
				Continue;
			EndIf;
			
			If Not Account.FilesAreRead Then
				AllFilesAreRead = False;
			EndIf;
		
		Else
			AllFilesAreRead = FilesAreRead(Account.GetItems(), AllFilesAreRead)
		EndIf;
		
		If Not AllFilesAreRead Then
			Break;
		EndIf;
	
	EndDo;
	
	Return AllFilesAreRead;

EndFunction

&AtServer
Function ListOfSelectedBankAccounts(Filter)

	TreeOfBankAccounts = FormAttributeToValue("BankAccounts");
	
	Return TreeOfBankAccounts.Rows.FindRows(Filter, True);

EndFunction

&AtClient
Procedure FillInInvoiceLoadingPeriod(TreeItems)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			If Not Account.Downloading Then
				Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
			EndIf;
			
		Else
			FillInInvoiceLoadingPeriod(Account.GetItems())
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure CheckDownloadProgress(TreeItems, ThereAreCompletedDownloads, ThereAreOutstandingTasks)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			Filter = New Structure("Ref", Account.Ref);
			AccountWasFound = Object.BankAccounts.FindRows(Filter);
			
			If AccountWasFound.Count() <> 0 Then
				Account.Imported = AccountWasFound[0].Imported;
				Account.Downloading = AccountWasFound[0].Downloading;
				Account.Check = AccountWasFound[0].Check;
			Else
				Continue;
			EndIf;
			
			If Account.Downloading Then
				
				AccountFiles = ListOfBankAccountFiles(Account.Ref, Object.Files);
				
				For Each File In AccountFiles Do
				
					If ValueIsFilled(File.ImportID) Then
					
						If JobCompleted(File.ImportID, File.BankAccount, File.FileName) Then
							File.SaveFile = True;
						Else
							ThereAreOutstandingTasks = True;
						EndIf;
					
					EndIf;
				
				EndDo;
				
				Filter = New Structure("BankAccount, SaveFile", Account.Ref, False);
				NotTasks_Completed = Object.Files.FindRows(Filter);
				
				If NotTasks_Completed.Count() = 0 Then
					
					Account.Downloading = False;
					Account.Check = False;
					AccountWasFound[0].Downloading = Account.Downloading;
					AccountWasFound[0].Check = Account.Check;
					ThereAreCompletedDownloads = True;
					
					SetTagForParentLine(Account);
					
				EndIf;
				
			EndIf;
		
			Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
			
		Else
			CheckDownloadProgress(Account.GetItems(), ThereAreCompletedDownloads, ThereAreOutstandingTasks);
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure FillInUploadResults(TreeItems, UploadedInvoices, UploadedPayments)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			Filter = New Structure("BankAccount, SaveFile", Account.Ref, True);
			UploadedFiles = Object.Files.FindRows(Filter);
			
			Filter = New Structure("BankAccount, SaveFile", Account.Ref, False);
			NotUploadedFiles = Object.Files.FindRows(Filter);
		
			If UploadedFiles.Count() <> 0
				And NotUploadedFiles.Count() = 0 Then
				
				UploadedInvoices.Add(Account);
				
				For Each File In UploadedFiles Do
					
					File.SaveFile = False;
					
					FileParameters = GeneralInformationAboutUploadedFile();
					FileParameters.CreditingConfirmationFile = File.CreditingConfirmationFile;
					FileParameters.DocumentStorageAddress = File.DocumentStorageAddress;
					UploadedPayments.Add(FileParameters);
					
				EndDo;
				
				Account.Imported = True;
				
				Filter = New Structure("Ref", Account.Ref);
				AccountWasFound = Object.BankAccounts.FindRows(Filter);
				
				If AccountWasFound.Count() <> 0 Then
					AccountWasFound[0].Imported = True;
				EndIf;
				
			EndIf;
			
		Else
			FillInUploadResults(Account.GetItems(), UploadedInvoices, UploadedPayments);
		EndIf;
		
	EndDo;

EndProcedure

&AtClient
Procedure PrintAccountStatementHeaders(InvoiceData, MessageText)

	BankAccountFiles = ListOfBankAccountFiles(InvoiceData.Ref, Object.Files);
	
	If BankAccountFiles.Count() <> 0 Then
		
		GenerateFileHeaders(InvoiceData, BankAccountFiles);
		SetDisplayOfTheseFiles();
		
	Else
		InvoiceData.ImportStartDate = '00010101';
		InvoiceData.ImportEndDate = '00010101';
		
		If Not InvoiceData.DirectExchange Then
			MessageText = NStr("vi = '<Không thể đọc (các) tệp sao kê/ghi có tiền. Hãy chắc chắn (các) tệp là đúng.>';
								|ru = '<Не удалось прочитать файл(ы) выписки/зачисления ДС. Проверьте корректность файла(ов).>';
								|en = '<Cannot read the cash statement/deposit file(s). Make sure the file(s) is correct.>'; fa = '<Cannot read the cash statement/deposit file(s). Make sure the file(s) is correct.>';
								|it = '<Не удалось прочитать файл(ы) выписки/зачисления ДС. Проверьте корректность файла(ов).>';
								|pl = '<Nie udało się odczytać pliku/ów wyciągu/zaliczenia środków pieniężnych. Sprawdź poprawność pliku/ów.>';
								|tr = '<Nakit ekstresi/transfer dosyaları okunamadı. Dosya(lar)ın doğru olup olmadığını kontrol et.>'");
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInLastUploadPeriod(TableOfAccounts, TreeItems)

	For Each Account In TreeItems Do
		
		If Account.Level = 0 Then
			
			TableRow = TableOfAccounts.Find(Account.Ref, "Ref");
			If TableRow <> Undefined Then
				Account.LastStatement = Format(TableRow.LastImportStartDate, "DLF=D")
					+ " - "
					+ Format(TableRow.EndDateOfLastUpload, "DLF=D");
			EndIf;
			
		Else
			FillInLastUploadPeriod(TableOfAccounts, Account.GetItems());
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Function ThereAreDuplicatesOfCounterpartySAccountNumber(Counterparty, AccountNumber)

	Result = False;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	COUNT(1) AS NumberOfAccounts
	|FROM
	|	Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|WHERE
	|	NOT CounterpartyBankAccounts.DeletionMark
	|	AND NOT CounterpartyBankAccounts.Closed
	|	AND CounterpartyBankAccounts.Owner = &Owner
	|	AND CounterpartyBankAccounts.AccountNumber = &AccountNumber
	|";
	
	Query.SetParameter("Owner", Counterparty);
	Query.SetParameter("AccountNumber", AccountNumber);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Result = Selection.NumberOfAccounts > 1;
	EndDo;
	
	Return Result;

EndFunction

&AtServer
Procedure DisplayMessagesForUploadedPayments(UploadedPayments)

	Enrollment = New Array; // Array of DocumentRef.BankConfirmationAboutCashReceiptOnEmployeeAccount
	
	For Each CurrentFile In UploadedPayments Do
		
		Payments_2 = GetFromTempStorage(CurrentFile.DocumentStorageAddress);
		
		If Not ValueIsFilled(Payments_2) Then
			Continue;
		EndIf;
		
		If CurrentFile.CreditingConfirmationFile Then
			Enrollment.Add(Payments_2);
		Else
			
			For Each CurrentPayment In Payments_2 Do
				
				If CurrentPayment.ImportErrors <> "" Then
					
					If ValueIsFilled(CurrentPayment.Document) Then
						MessageText = TextOfDocumentUploadError(CurrentPayment.Document, CurrentPayment.ImportErrors);
					Else
						MessageText = CurrentPayment.ImportErrors;
					EndIf;
					
					Common.MessageToUser(MessageText);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If Enrollment.Count() > 0 Then
		
		ErrorsInEnrollmentDocuments = Common.ObjectsAttributeValue(Enrollment, "ImportErrors");
		
		For Each DocumentError In ErrorsInEnrollmentDocuments Do
			
			If DocumentError.Value <> "" Then
				MessageText = TextOfDocumentUploadError(DocumentError.Key, DocumentError.Value);
				Common.MessageToUser(MessageText);
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

&AtServer
Function TextOfDocumentUploadError(Document, Error)

	Return StrTemplate(NStr("vi = '%1:
							|%2%3';
							|ru = '%1:
							|%2%3';
							|en = '%1:
							|%2%3'; fa = '%1:
							|%2%3';
							|it = '%1:
							|%2%3';
							|pl = '%1:
							|%2%3';
							|tr = '%1:
							|%2%3'"), Document, Chars.Tab, Error);

EndFunction

#Region CheckingBackgroundJobs

&AtClient
Procedure CheckParallelLoadingOfStatement()

	UpdateAvailabilityOfBackgroundTasks();

EndProcedure

&AtServer
Procedure UpdateAvailabilityOfBackgroundTasks()
	
	TableOfBackgroundTasks = BackgroundTasksInProgressForUploadingStatement();
	UpdatePresenceOfBackgroundTasksInTree(TableOfBackgroundTasks, BankAccounts.GetItems());
	
EndProcedure

&AtServer
Procedure UpdatePresenceOfBackgroundTasksInTree(TableOfBackgroundTasks, TreeItems)

	For Each Account In TreeItems Do
		
		If Account.Level <> 0 Then
			UpdatePresenceOfBackgroundTasksInTree(TableOfBackgroundTasks, Account.GetItems())
		Else
			FillInBackgroundTaskDetails(TableOfBackgroundTasks, Account);
		EndIf;
		
	EndDo;

EndProcedure

&AtServer
Procedure FillInBackgroundTaskDetails(TableOfBackgroundTasks, InvoiceData)

	FilterByAccount = New Structure("Account", InvoiceData.Ref);
	ListOfTasksByAccount = TableOfBackgroundTasks.FindRows(FilterByAccount);
	
	If ListOfTasksByAccount.Count() <> 0 Then
		
		ThereAreNoTasks = True;
		
		For Each BackgroundJobLine In ListOfTasksByAccount Do
			
			FilterFiles_ = New Structure;
			FilterFiles_.Insert("BankAccount", InvoiceData.Ref);
			FilterFiles_.Insert("ImportID", New UUID(BackgroundJobLine.UUID));
			FilesData = Object.Files.FindRows(FilterFiles_);
			
			BackgroundJob = BackgroundJobs.FindByUUID(
				New UUID(BackgroundJobLine.UUID));
			
			If BackgroundJob <> Undefined
				And BackgroundJob.State = BackgroundJobState.Active
				And FilesData.Count() = 0 Then
				
				InvoiceData.ThereIsBackgroundTask = True;
				InvoiceData.AuthorOfBackgroundTask = BackgroundJobLine.Author;
				InvoiceData.BackgroundTaskLoadingPeriod =
					New StandardPeriod(BackgroundJobLine.ImportStartDate, BackgroundJobLine.ImportEndDate);
				ThereAreNoTasks = False;
				
			EndIf;
			
		EndDo;
		
		If ThereAreNoTasks Then
			ClearBackgroundJobDetails(InvoiceData);
		EndIf;
		
	ElsIf InvoiceData.ThereIsBackgroundTask Then
		ClearBackgroundJobDetails(InvoiceData);
	EndIf;

EndProcedure

&AtServer
Function BackgroundTasksInProgressForUploadingStatement()

	Table = New ValueTable;
	Table.Columns.Add("Key");
	Table.Columns.Add("Description");
	Table.Columns.Add("UUID");
	Table.Columns.Add("Account");
	Table.Columns.Add("Author");
	Table.Columns.Add("ImportStartDate");
	Table.Columns.Add("ImportEndDate");
	
	Filter = New Structure;
	Filter.Insert("Description", NStr("vi = 'Tải xuống sao kê ngân hàng';
										|ru = 'Загрузка выписки банка';
										|en = 'Bank statement import'; fa = 'Bank statement import';
										|it = 'Загрузка выписки банка';
										|pl = 'Pobierz wyciąg bankowy';
										|tr = 'Banka ekstresini yükleme'"));
	Filter.Insert("State", BackgroundJobState.Active);
	ListOfBackgroundTasks = BackgroundJobs.GetBackgroundJobs(Filter);
	
	For Each Job In ListOfBackgroundTasks Do
		
		NewRow = Table.Add();
		FillPropertyValues(NewRow, Job);
		PartsOfName = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Job.Key, "_");
		NewRow.Account = Catalogs.CompaniesBankAccounts.GetRef(New UUID(PartsOfName[1]));
		NewRow.Author = Catalogs.Users.GetRef(New UUID(PartsOfName[2]));
		NewRow.ImportStartDate = PartsOfName[3];
		NewRow.ImportEndDate = PartsOfName[4];
		
	EndDo;
	
	Return Table;

EndFunction

&AtServer
Procedure ClearBackgroundJobDetails(Account)

	Account.ThereIsBackgroundTask = False;
	Account.AuthorOfBackgroundTask = "";
	Account.BackgroundTaskLoadingPeriod = New StandardPeriod();

EndProcedure

&AtServer
Function ConvertTreeToTable(ValueTree, TreeRows)

	Table = New ValueTable;
	
	For Each TreeColumn In ValueTree.Columns Do
		Table.Columns.Add(TreeColumn.Name, TreeColumn.ValueType);
	EndDo;
	
	For Each TreeRow In TreeRows Do
		
		NewRow = Table.Add();
		FillPropertyValues(NewRow, TreeRow);
		
	EndDo;
	
	Return Table;

EndFunction

#EndRegion

#Region FilesOperations

&AtClient
Procedure Attachable_EnableFileWorkExtensionAndSelectFile()
	
	MessageText = NStr("vi = 'Để chọn một tệp, Cần cài đặt phần mở rộng tệp.';
						|ru = 'Для выбора файла необходимо установить расширение работы с файлами.';
						|en = 'To select a file, install 1C:Enterprise Extension.'; fa = 'To select a file, install 1C:Enterprise Extension.';
						|it = 'Для выбора файла необходимо установить расширение работы с файлами.';
						|pl = 'Aby wybrać plik, musisz zainstalować rozszerzenie obsługi plików.';
						|tr = 'Dosya seçimi için dosya yönetimi uzantısını yükle'");
	
	CallbackDescription = New CallbackDescription("SelectFileCompletion", ThisObject);
	CommonClient.ShowFileSystemExtensionInstallationQuestion(CallbackDescription, MessageText, False);
	
EndProcedure

&AtClient
Procedure SelectFileCompletion(Result, AdditionalParameters) Export
	
	AbilityToSelectFiles = Result;
	
	If AbilityToSelectFiles Then
		SelectingDownloadSource();
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadStatementDataInteractiveMode(Account)
	
	Account.FilesAreRead = False;
	ProcedureName = "ReadHeadersOfBankAccountFiles";
	
	PerformProcedureAfterCheckingAccountFiles(Account, ProcedureName);
	
EndProcedure

&AtClient
Procedure PerformProcedureAfterCheckingAccountFiles(Account, ProcedureName)

	ProcedureParameters = InitializeFileVerificationParameters();
	ProcedureParameters.Insert("Account", Account);
	ProcedureParameters.Insert("ProcedureName", ProcedureName);
	
	If AbilityToSelectFiles Then
		InitializeFileDirectory(ProcedureParameters);
	Else
		InstallFileExtension(ProcedureParameters);
	EndIf;

EndProcedure

&AtClient
Function InitializeFileVerificationParameters()

	Data = New Structure;
	Data.Insert("Account", Undefined);
	Data.Insert("ProcedureName", "");
	Data.Insert("File", Undefined);
	Data.Insert("FilesDetails", Undefined);
	
	Return Data; 

EndFunction

&AtClient
Procedure InstallFileExtension(NotificationParameters)
	
	MessageText = NStr("vi = 'Để tải xuống tệp tuyên bố, cần cài đặt phần mở rộng tệp.';
						|ru = 'Для загрузки файлов выписки необходимо установить расширение работы с файлами.';
						|en = 'To import statement files, install 1C:Enterprise Extension.'; fa = 'To import statement files, install 1C:Enterprise Extension.';
						|it = 'Для загрузки файлов выписки необходимо установить расширение работы с файлами.';
						|pl = 'Aby przesłać pliki wyciągów, musisz zainstalować rozszerzenie pliku.';
						|tr = 'Ekstre dosyalarını indirmek için, dosyalarla çalışmak için uzantının yüklenmesi gerekir.'");
	
	CallbackDescription = New CallbackDescription("AttachFileSystemExtensionCompletion", ThisObject, NotificationParameters);
	FileSystemClient.AttachFileOperationsExtension(CallbackDescription, MessageText, False);
	
EndProcedure

&AtClient
Procedure InitializeFileDirectory(ParametersStructure)
	
	CallbackDescription = New CallbackDescription("CheckExistenceOfDirectoryFile", ThisObject, ParametersStructure);
	
	File = New File();
	File.BeginInitialization(CallbackDescription, ParametersStructure.Account.ConfigureExchange);
	
EndProcedure

&AtClient
Procedure CheckExistenceOfDirectoryFile(ObjectFile, AdditionalParameters) Export
	
	AdditionalParameters.Insert("File", ObjectFile);
	CallbackDescription = New CallbackDescription("CheckOutThisDirectory",
		ThisObject, AdditionalParameters);
	ObjectFile.BeginCheckingExistence(CallbackDescription);
	
EndProcedure

&AtClient
Procedure CheckOutThisDirectory(Exists, AdditionalParameters) Export
	
	If Exists Then
		File = AdditionalParameters.File;
		CallbackDescription = New CallbackDescription("CheckOutThisDirectoryCompletion", ThisObject, AdditionalParameters);
		File.BeginCheckingIsDirectory(CallbackDescription);
	Else
		MessageText = StrTemplate(NStr("vi = 'Không thể tìm thấy ""%1"".
			|Hãy kiểm tra sự tồn tại của tệp và thư mục.
			|Nếu tệp hoặc thư mục nằm trong mạng, hãy kiểm tra xem, đã kết nối chúng đến mạng hay chưa.';
			|ru = 'Не удалось найти ""%1"".
			|Проверьте, что файл или каталог существует.
			|Если файл или каталог находится в сети, проверьте, подключены ли вы к сети.';
			|en = 'Cannot find ""%1"".
			|Make sure the file or directory exists.
			|If the file or directory is online, check your Internet connection.'; fa = 'Cannot find ""%1"".
			|Make sure the file or directory exists.
			|If the file or directory is online, check your Internet connection.';
			|it = 'Не удалось найти ""%1"".
			|Проверьте, что файл или каталог существует.
			|Если файл или каталог находится в сети, проверьте, подключены ли вы к сети.';
			|pl = 'Cannot find ""%1"".
			|Make sure the file or directory exists.
			|If the file or directory is online, check your Internet connection.';
			|tr = '""%1"" bulunamadı.
			|Dosyanın veya dizinin var olup olmadığını kontrol edin.
			|Dosya veya dizin ağ üzerinde ise ağa bağlı olup olmadığınızı kontrol edin.'"), AdditionalParameters.File.FullName);
		CommonClient.MessageToUser(MessageText);
		AdditionalParameters.Account.FilesAreRead = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckOutThisDirectoryCompletion(IsDirectory, AdditionalParameters) Export
	
	If IsDirectory Then
		GetListOfFilesInFolder(AdditionalParameters);
	Else
		
		ListOfFiles = New Array;
		ListOfFiles.Add(AdditionalParameters.Account.ConfigureExchange);
		
		PutFilesInTempStorage(ListOfFiles, AdditionalParameters);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure GetListOfFilesInFolder(ParametersStructure)

	ProcedureAfterCompletion = New CallbackDescription("AfterGettingListOfFilesInDirectory", ThisObject, ParametersStructure);
	BeginFindingFiles(ProcedureAfterCompletion, ParametersStructure.Account.ConfigureExchange, "*");

EndProcedure

&AtClient
Procedure AfterGettingListOfFilesInDirectory(FilesFound, AdditionalParameters) Export

	FileNamesArray = New Array;
	Account = AdditionalParameters.Account;
	
	If FilesFound.Count() = 0 Then
		
		If Not Account.ImportFromDirectory
			And ValueIsFilled(Account.ConfigureExchange) Then
			FileNamesArray.Add(Account.ConfigureExchange);
		EndIf;
		
	Else
		
		Extension = New Array;
		
		If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
			
			Extension.Add(".txt");
			
		ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
			Extension.Add(".xml");
		EndIf;
			
		For Each File In FilesFound Do
		
			If Extension.Find(File.Extension) <> Undefined Then
				FileNamesArray.Add(File.FullName);
			EndIf;
		
		EndDo;
		
	EndIf;
	
	If FileNamesArray.Count() = 0 Then
		Return;
	EndIf;
	
	PutFilesInTempStorage(FileNamesArray, AdditionalParameters);

EndProcedure

&AtClient
Procedure PutFilesInTempStorage(ListFileNames, AdditionalParameters)

	Files = New Array;

	For Each FileName In ListFileNames Do
		
		FileObject1 = New File(FileName);
		Files.Add(New TransferableFileDescription(FileObject1.FullName));
		
	EndDo;
	
	PlacingFilesCompletion = New CallbackDescription("PutFilesInTempStorageCompletion",
		ThisObject, AdditionalParameters);
	BeginPuttingFiles(PlacingFilesCompletion, Files,, False, UUID);

EndProcedure

&AtClient
Procedure PutFilesInTempStorageCompletion(PlacedFiles, AdditionalParameters) Export
	
	If PlacedFiles <> Undefined And PlacedFiles.Count() > 0 Then
		
		FilesDetails = New Array;
		
		For Each FileDetails In PlacedFiles Do
		
			FileAddress = FileDetails.Location;
			
			If FileAddress = Undefined Then
				Continue;
			EndIf;
			
			FilesDetails.Add(FileDetails);
		
		EndDo;
		
		If FilesDetails.Count() <> 0
			And AdditionalParameters.ProcedureName <> "" Then
		
			AdditionalParameters.Insert("FilesDetails", FilesDetails);
			Callback = New CallbackDescription(AdditionalParameters.ProcedureName, ThisObject, AdditionalParameters);
			RunCallback(Callback);
		
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadHeadersOfBankAccountFiles(Result, AdditionalParameters) Export
	
	Account = AdditionalParameters.Account;
	
	ParseBankAccountFiles(
		AdditionalParameters.Account.GetID(),
		AdditionalParameters.FilesDetails,
		False);
	Account.FilesAreRead = True;
	
EndProcedure

&AtClient
Procedure ChoosingExchangeFileWithBank(CurrentData, Mode, DialogMode = Undefined)

	If DialogMode = Undefined Then
		DialogMode = FileDialogMode.Open;
	EndIf;
	
	If CurrentData.DirectExchange Then
		FileName = "";
	Else
		FileName = CurrentData.ConfigureExchange;
	EndIf;
	
	FileDialog = New FileDialog(DialogMode);
	
	If CurrentData = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
		FileDialog.Filter = NStr("vi = 'Tệp văn bản (*.txt)|*.txt';
								|ru = 'Текстовый файл (*.txt)|*.txt';
								|en = 'Text file (*.txt)|*.txt'; fa = 'Text file (*.txt)|*.txt';
								|it = 'Текстовый файл (*.txt)|*.txt';
								|pl = 'Plik tekstowy (*.txt)|*.txt';
								|tr = 'Metin dosyası (*.txt)|*.txt'");
		FileDialog.DefaultExt = "txt";
		FileDialog.FullFileName = ?(IsBlankString(FileName), 
											?(Mode = "Upload0", "1c_to_kl.txt", "kl_to_1c.txt"), FileName);
	ElsIf CurrentData = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
		FileDialog.Filter = NStr("vi = 'Tệp XML (*.xml)|*.xml';
								|ru = 'XML файл (*.xml)|*.xml';
								|en = 'XML file (*.xml)|*.xml'; fa = 'XML file (*.xml)|*.xml';
								|it = 'XML файл (*.xml)|*.xml';
								|pl = 'Plik XML (*.xml)|*.xml';
								|tr = 'XML dosya (*.xml)|*.xml'");
		FileDialog.DefaultExt = "xml";
		FileDialog.FullFileName = ?(IsBlankString(FileName), 
											?(Mode = "Upload0", "pain.xml", "camp.xml"), FileName);
	ElsIf CurrentData = PredefinedValue("Enum.ExchangeFormatWithBank.FederalTreasuryOfTheRussianFederation") Then
		FileDialog.Filter = NStr("vi = 'Tệp nén zip (*.zip)|*.zip';
								|ru = 'Zip-архив (*.zip)|*.zip';
								|en = 'ZIP archive (*.zip)|*.zip'; fa = 'ZIP archive (*.zip)|*.zip';
								|it = 'Zip-архив (*.zip)|*.zip';
								|pl = 'Archiwum zip (*.zip)|*.zip';
								|tr = 'Zip-arşiv (*.zip)|*.zip'");
		FileDialog.DefaultExt = "zip";
	EndIf;
	FileDialog.Title = StrTemplate(NStr("vi = 'Hãy chọn %1 để %2 dữ liệu từ client bank';
										|ru = 'Выберите %1 для %2 данных из клиента банка';
										|en = 'Select %1 for %2 data from client bank'; fa = 'Select %1 for %2 data from client bank';
										|it = 'Выберите %1 для %2 данных из клиента банка';
										|pl = 'Wybierz %1 dla %2 danych z klienta banku';
										|tr = 'Banka istemcisinden %2 veri için %1''i seç'"),
		?(DialogMode = FileDialogMode.Open, NStr("vi = 'tệp';
												|ru = 'файл';
												|en = 'file'; fa = 'file';
												|it = 'файл';
												|pl = 'file';
												|tr = 'dosya'"), "directory"),
		?(Mode = "Upload0", NStr("vi = 'kết xuất';
								|ru = 'выгрузки';
								|en = 'exports'; fa = 'خروجی‌ها';
								|it = 'выгрузки';
								|pl = 'import';
								|tr = 'dışa aktarmalar'"), NStr("vi = 'kết nhập';
														|ru = 'загрузки';
														|en = 'imports'; fa = 'ورودی‌ها';
														|it = 'загрузки';
														|pl = 'eksport';
														|tr = 'içe aktarmalar'")));
	FileDialog.Preview = False;
	FileDialog.FilterIndex = 0;
	FileDialog.CheckFileExistence = False;
	
	CallbackDescription = New CallbackDescription(
		"SelectingFileCompletion",
		ThisObject,
		New Structure("Mode, CurrentData", Mode, CurrentData));
	
	FileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SelectingFileCompletion(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles <> Undefined Then
		AdditionalParameters.CurrentData.ConfigureExchange = SelectedFiles[0];
		AdditionalParameters.CurrentData.FileStorageAddress = "";
		AdditionalParameters.CurrentData.DirectExchange = False;
		AdditionalParameters.CurrentData.Check = True;
		AdditionalParameters.CurrentData.Imported = False;
		
		FillInListOfMarkedAccounts();
		
		SetTagForParentLine(AdditionalParameters.CurrentData);
		
		PrintStatementTitle();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ReadClientBankStatementFile(FileName, Encoding, MessageText = "")
	
	FileLines = New Array;
	
	#If Not WebClient Then
	
		StatementFile = New File(FileName);
		
		FileEncoding = ?(Encoding = "DOS", "cp866", "windows-1251");
		
		Try
			ReaderStream = New TextReader(FileName, FileEncoding,,, False);
			
		Except
			
			MessageText = NStr("vi = '<Không thể đọc tệp sao kê. Hãy chắc chắn rằng tập tin là chính xác.>';
								|ru = '<Не удалось прочитать файл выписки. Убедитесь в корректности файла.>';
								|en = '<Failed to read the statement file. Make sure the file is correct.>'; fa = '<Failed to read the statement file. Make sure the file is correct.>';
								|it = '<Не удалось прочитать файл выписки. Убедитесь в корректности файла.>';
								|pl = '<Nie można odczytać pliku instrukcji. Upewnij się, że plik jest poprawny.>';
								|tr = '<Ekstre dosyası okunamıyor. Dosyanın doğru olduğundan emin ol.>'");
			Return Undefined;
		EndTry;
		
		CurrentRow = ReaderStream.ReadLine();
		If CurrentRow = Undefined Then
			MessageText = NStr("vi = '<Tệp sao kê không chứa dữ liệu.>';
								|ru = '<Файл выписки не содержит данных.>';
								|en = '<The statement file does not contain data.>'; fa = '<The statement file does not contain data.>';
								|it = '<Файл выписки не содержит данных.>';
								|pl = '<Plik instrukcji nie zawiera danych.>';
								|tr = '<Ekstre dosyası veri içermiyor.>'");
			Return Undefined;
		Else
			If Left(Upper(TrimAll(CurrentRow)), 20) <> "1CCLIENTBANKEXCHANGE" Then
				MessageText =
					NStr("vi = '<Tệp sao kê không phải là tệp trao đổi, hoặc đã chỉ ra sai mã hóa trong tùy chỉnh trao đổi tài khoản ngân hàng.>';
						|ru = '<Файл выписки не является файлом обмена, или неверно указана кодировка в настройках обмена банковского счета.>';
						|en = '<The statement file is not an exchange file, or the encoding in the bank account exchange settings is specified incorrectly.>'; fa = '<The statement file is not an exchange file, or the encoding in the bank account exchange settings is specified incorrectly.>';
						|it = '<Файл выписки не является файлом обмена, или неверно указана кодировка в настройках обмена банковского счета.>';
						|pl = '<Plik wyciągu nie jest plikiem wymiany, lub niepoprawnie jest podane kodowanie w ustawieniach wymiany rachunku bankowego.>';
						|tr = '<Ekstre dosyası bir değişim dosyası değil veya banka hesabı değişim ayarlarında kodlama yanlış belirtilmiş.>'");
				Return Undefined;
			EndIf;
		EndIf;
		
		While CurrentRow <> Undefined Do
			FileLines.Add(TrimAll(CurrentRow));
			CurrentRow = ReaderStream.ReadLine();
		EndDo;
	
	#EndIf
	
	Return FileLines;
	
EndFunction

&AtClient
Procedure SelectingDownloadSource()

	CallbackDescriptionOnClose = New CallbackDescription("SelectingDownloadSourceCompletion", ThisObject);
	
	TableRow = Items.BankAccounts.CurrentData;
	
	ChoiceDialog = New ValueList;
	ChoiceDialog.Add(FileDialogMode.Open, "File");
	ChoiceDialog.Add(FileDialogMode.ChooseDirectory, "Directory");
	
	ShowChooseFromList(CallbackDescriptionOnClose, ChoiceDialog, CurrentItem);

EndProcedure

&AtClient
Procedure SelectingDownloadSourceCompletion(SelectedElement, AdditionalParameters) Export

	If SelectedElement <> Undefined Then
		
		CurrentData = Items.BankAccounts.CurrentData;
		CurrentData.ImportFromDirectory = ?(SelectedElement.Value = FileDialogMode.ChooseDirectory, True, False);
		ChoosingExchangeFileWithBank(CurrentData, "Load", SelectedElement.Value);
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext 
Function AccountFilesInDirectory(Account)

	FileNamesArray = New Array;
	
	If Account.ImportFromDirectory Then
		
		Masks = New Array;
		
		If Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ClientBankExchange1c") Then
			
			Masks.Add("*.txt");
			
		ElsIf Account.ExchangeFormat = PredefinedValue("Enum.ExchangeFormatWithBank.ISO20022") Then
			Masks.Add("*.xml");
		
		
		EndIf;
		
		For Each Mask In Masks Do
			
			ListOfFiles = FindFiles(Account.ConfigureExchange, Mask, False);
			
			For Each File In ListOfFiles Do
				FileNamesArray.Add(File.FullName);
			EndDo;
			
		EndDo;
		
	Else
		FileNamesArray.Add(Account.ConfigureExchange);
	EndIf;
	
	Return FileNamesArray;

EndFunction


// Returns a list of links to the rows of the "Files" tabular part of the bank account
//
// Parameters:
//  Account - CatalogRef.CompaniesBankAccounts - Organization's Bank account
//  Files - FormDataCollection - data of the "Files" tabular part
//
// Returns:
//   Array - list of table part rows
//
&AtClientAtServerNoContext
Function ListOfBankAccountFiles(Account, Files)

	FilterParameters = New Structure("BankAccount", Account);
	
	Return Files.FindRows(FilterParameters);

EndFunction

// Deletes rows from the "Files" tabular part of the bank account
//
// Parameters:
//  Account - CatalogRef.CompaniesBankAccounts - Organization's Bank account
//
&AtClient
Procedure DeleteBankAccountFiles(Account)

	FilesArray = ListOfBankAccountFiles(Account, Object.Files);
	
	For Each ArrayRow In FilesArray Do
		Object.Files.Delete(ArrayRow);
	EndDo;

EndProcedure

// Returns a new filled line of the table part of Files according to the data of the readable file according to the 1C ClientBankExchange exchange format.
// 
// Parameters:
//  Form - ClientApplicationForm - file upload form.
//  Account - FormDataCollectionItem - the row of the tabular part of the Bank account.
//  FileName - String - the full path to the downloaded file.
//  CurrentFile - File - the file being uploaded.
//  MessageText - String - text containing error messages when reading the file for download.
//  ReadDocuments - Boolean - a sign that determines whether the file is fully read, including information on documents.
// 
// Returns:
//  FormDataCollectionItem - file information added to the Files tabular section.
//  
&AtClientAtServerNoContext
Function InformationAboutFileAccordingToExchangeFormat1CClientBankExchange(Form, Account, FileName, CurrentFile, MessageText, ReadDocuments = True)

	StatementLines = ReadClientBankStatementFile(FileName, Account.Encoding, MessageText);
		
	Files = Form.Object.Files; // FormDataCollection
	NewRow = Files.Add();
	NewRow.FileName = CurrentFile.Name;
	NewRow.BankAccount = Account.Ref;
	
	If StatementLines <> Undefined
		And Not ErrorFillingInByBank(StatementLines, MessageText) Then
		
		StatementData = CashClientServer.Parse1CClientBankExchangeStatementFile(StatementLines, ReadDocuments);
		
		NewRow.Statement_ = New Structure;
		NewRow.Statement_.Insert("StatementData", StatementData);
		NewRow.Statement_.Insert("StatementLines", StatementLines);
		NewRow.Statement_.Insert("MessageText", "");
		
		If StatementData <> Undefined
			And TypeOf(StatementData) = Type("Structure")
			And StatementData.Property("Title") Then
	
			If StatementData.Title <> Undefined Then
				NewRow.ImportStartDate = CashClientServer.GetDateFromString(StatementData.Title.StartDate);
				NewRow.ImportEndDate = CashClientServer.GetDateFromString(StatementData.Title.EndDate);
			EndIf;
			
		EndIf;
		
	Else
		NewRow.Statement_ = New Structure;
		NewRow.Statement_.Insert("StatementData", Undefined);
		NewRow.Statement_.Insert("StatementLines", Undefined);
		NewRow.Statement_.Insert("MessageText", MessageText);
	EndIf;
	
	Return NewRow;

EndFunction


&AtClientAtServerNoContext
Function InformationAboutExtractFileByFormat(Form, Account, CurrentFile, BinaryData = Undefined)

	NewRow = Form.Object.Files.Add();
	NewRow.FileName = CurrentFile.Name;
	NewRow.BankAccount = Account.Ref;
	
	If BinaryData = Undefined Then
		
		Try
			BinaryData = New BinaryData(CurrentFile.FullName);
		Except
			
			MessageText = NStr("vi = '<Không thể đọc tệp sao kê/ghi có tiền. Hãy chắc chắn tệp là đúng.>';
								|ru = '<Не удалось прочитать файл выписки/зачисления ДС. Убедитесь в корректности файла.>';
								|en = '<Cannot read the cash statement/deposit file. Make sure the file is correct.>'; fa = '<Cannot read the cash statement/deposit file. Make sure the file is correct.>';
								|it = '<Не удалось прочитать файл выписки/зачисления ДС. Убедитесь в корректности файла.>';
								|pl = '<Nie można odczytać pliku wyciągu/zaliczenia środków pieniężnych. Upewnij się, że plik jest poprawny.>';
								|tr = '<Nakit ekstre/transfer dosyası okunamadı. Dosyanın doğru olduğundan emin ol.>'");
			NewRow.Statement_ = New Structure;
			NewRow.Statement_.Insert("StatementData", Undefined);
			NewRow.Statement_.Insert("MessageText", MessageText);
			NewRow.FileStorageAddress = PutToTempStorage(Undefined, Form.UUID);
			
			Return NewRow;
			
		EndTry;
		
		NewRow.FileStorageAddress = PutToTempStorage(BinaryData, Form.UUID);
		
	EndIf;
	
	StatementData = ReadStatementDataByFormatOnServer(Account.ExchangeFormat, BinaryData, Account.Encoding);
	
	NewRow.Statement_ = New Structure;
	NewRow.Statement_.Insert("StatementData", StatementData);
	NewRow.Statement_.Insert("StatementLines", Undefined);
	NewRow.Statement_.Insert("MessageText", "");
	NewRow.CreditingConfirmationFile = StatementData.Title.Property("RegistryNumber");
	
	If ValueIsFilled(StatementData.SettlementAccounts) Then
		NewRow.ImportStartDate = StatementData.SettlementAccounts[0].StartDate;
		NewRow.ImportEndDate = StatementData.SettlementAccounts[0].EndDate;
	EndIf;
	
	Return NewRow;

EndFunction

// Reads files to be downloaded using the organization's bank account data.
// 
// Parameters:
//  Account - FormDataCollectionItem - details of the organization's bank account.
//
&AtClient
Procedure ReadBankAccountFiles(Account)
	
	If Not Account.Imported And TypeOf(Account.ConfigureExchange) = Type("String") Then
			
		ListOfFiles = ListOfBankAccountFiles(Account.Ref, Object.Files);
		
		For Each LineOfATabularSection In ListOfFiles Do
			Object.Files.Delete(LineOfATabularSection);
		EndDo;
		
		Account.FilesAreRead = False;
		PerformProcedureAfterCheckingAccountFiles(Account, "ReadBankAccountFilesCompletion");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadBankAccountFilesCompletion(Result, AdditionalParameters) Export

	ParseBankAccountFiles(
		AdditionalParameters.Account.GetID(),
		AdditionalParameters.FilesDetails);

EndProcedure

&AtServer
Procedure ParseBankAccountFiles(RowID, FilesDetails, ReadDocuments = True)

	Account = BankAccounts.FindByID(RowID);
	
	For Each CurrentDetails In FilesDetails Do
	
		BinaryData = GetFromTempStorage(CurrentDetails.Location); // BinaryData
	
		MessageText = "";
		
		If Account.ExchangeFormat = Enums.ExchangeFormatWithBank.ClientBankExchange1c Then
		
			FileName = GetTempFileName();
			BinaryData.Write(FileName);
			
			CurrentFile = New File(CurrentDetails.FullName);
			
			If CurrentFile.Extension = ".txt" Then
				
				NewRow = InformationAboutFileAccordingToExchangeFormat1CClientBankExchange(
					ThisObject, Account, FileName, CurrentDetails, MessageText, ReadDocuments);

				NewRow.FileStorageAddress = PutToTempStorage(
					NewRow.Statement_.StatementLines, UUID);
				
			
			EndIf;
			
			Try
				DeleteFiles(FileName);
			Except
				Event = NStr("vi = 'Kết nhập bản sao kê ngân hàng.';
							|ru = 'Загрузка банковской выписки.';
							|en = 'Importing bank statement.'; fa = 'Importing bank statement.';
							|it = 'Загрузка банковской выписки.';
							|pl = 'Pobieranie wyciągu bankowego.';
							|tr = 'Banka ekstresi içe aktarma.'", Common.DefaultLanguageCode())
					+ "." + NStr("vi = 'Xóa tệp tạm thời';
								|ru = 'Удаление временного файла';
								|en = 'Delete temporary file'; fa = 'Delete temporary file';
								|it = 'Удаление временного файла';
								|pl = 'Usuwanie pliku tymczasowego';
								|tr = 'Geçici dosyayı silme'", Common.DefaultLanguageCode());
				WriteLogEvent(Event,
					EventLogLevel.Error,,,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		
		Else
			
			CurrentFile = New File(CurrentDetails.FullName);
			
			NewRow = InformationAboutExtractFileByFormat(ThisObject, Account, CurrentFile, BinaryData);
			NewRow.FileStorageAddress = CurrentDetails.Location;
		
		EndIf;
		
		Account.ImportStartDate = ?(Account.ImportStartDate = '00010101',
									NewRow.ImportStartDate,
									Min(Account.ImportStartDate, NewRow.ImportStartDate));
		Account.ImportEndDate = Max(Account.ImportEndDate, NewRow.ImportEndDate);
	
	EndDo;
	
	Account.ImportPeriod = New StandardPeriod(Account.ImportStartDate, Account.ImportEndDate);
	Account.FilesAreRead = True;

EndProcedure

&AtClientAtServerNoContext
Function ErrorFillingInByBank(StatementLines, MessageText)

	DocumentSection = False;
	PayerInvoiceTagWasFound = False;
	RecipientTagFoundAccount = False;
	
	CurrentAccountSection = False;
	OpeningBalanceTagWasFound = False;
	ClosingBalanceTagWasFound = False;
	
	For Each StatementRow In StatementLines Do
		
		If CurrentAccountSection Then
			
			If StrFind(Upper(StatementRow), "OPENINGBALANCE=") <> 0 Then
				OpeningBalanceTagWasFound = True;
			EndIf;
			
			If StrFind(Upper(StatementRow), "CLOSINGBALANCE=") <> 0 Then
				ClosingBalanceTagWasFound = True;
			EndIf;
			
			If StrFind(Upper(StatementRow), "KONTSACCOUNT") <> 0 Then
				
				CurrentAccountSection = False;
				
				If Not OpeningBalanceTagWasFound
					And ClosingBalanceTagWasFound Then
					MessageText = ?(MessageText <> "", MessageText + Chars.LF, "") 
						+ TextAboutAbsenceOfMandatoryTag("OpeningBalance");
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If StrFind(Upper(StatementRow), "SECTIONACCOUNT") <> 0 Then
			CurrentAccountSection = True;
		EndIf;
		
		If DocumentSection Then
			
			If StrFind(Upper(StatementRow), "PAYERACCOUNT=") <> 0 Then
				PayerInvoiceTagWasFound = True;
			EndIf;
			
			If StrFind(Upper(StatementRow), "BENEFICIARYACCOUNT=") <> 0 Then
				RecipientTagFoundAccount = True;
			EndIf;
			
			If StrFind(Upper(StatementRow), "DOCUMENTEND") <> 0 Then
			
				DocumentSection = False;
				
				If Not PayerInvoiceTagWasFound Then
					MessageText = ?(MessageText <> "", MessageText + Chars.LF, "") 
						+ TextAboutAbsenceOfMandatoryTag("PayerAccount");
				EndIf;
				
				If Not RecipientTagFoundAccount Then
					MessageText = ?(MessageText <> "", MessageText + Chars.LF, "")
						+ TextAboutAbsenceOfMandatoryTag("BeneficiaryAccount");
				EndIf;
				
				If Not PayerInvoiceTagWasFound
					Or Not RecipientTagFoundAccount Then
					Return True;
				EndIf;
			
			EndIf;
			
		EndIf;
		
		If StrFind(Upper(StatementRow), "SECTIONDOCUMENT=") <> 0 Then
			DocumentSection = True;
		EndIf;
		
	EndDo;
	
	Return False;

EndFunction

&AtClientAtServerNoContext
Function TextAboutAbsenceOfMandatoryTag(NameTag)

	Return StrTemplate(NStr("vi = '<Không có mục tin bắt buộc %1>';
							|ru = '<Отсутствует обязательный реквизит %1>';
							|en = '<The %1 required attribute is missing>'; fa = '<The %1 required attribute is missing>';
							|it = '<Отсутствует обязательный реквизит %1>';
							|pl = '<The %1 required attribute is missing>';
							|tr = '<%1 zorunlu özniteliği eksik>'"), NameTag);

EndFunction

&AtClient
Function GeneralInformationAboutUploadedFile()

	FileParameters = New Structure;
	FileParameters.Insert("CreditingConfirmationFile", False);
	FileParameters.Insert("DocumentStorageAddress", Undefined);
	
	Return FileParameters;

EndFunction

#EndRegion

#EndRegion
