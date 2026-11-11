
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BankAccountSelection = Parameters.BankAccount;

	FillInInitialValues(BankAccountSelection);
	
	ImportedDocuments.Parameters.SetParameterValue("IDOfTheObjectReceiptOfNonCashDS",
		Common.MetadataObjectID("Document.BankAccountReceiptNote"));
	ImportedDocuments.Parameters.SetParameterValue("TheObjectIDOfTheNonCashWriteOffOfDS",
		Common.MetadataObjectID("Document.BankAccountIssue"));
		
	JournalName = "ImportedDocuments";
	
	Object.CreateCounterparties = True;
	Object.PostDocuments = True;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region EventHandlersForLoadedDocumentElements

&AtClient
Procedure ImportedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
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

&AtClient
Procedure ImportedDocumentsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If TypeOf(ValueSelected) = Type("CatalogRef.Counterparties") Then
		
		ArrayOfSelectedRows = Items[JournalName].SelectedRows;
		
		For Each SelectedRow In ArrayOfSelectedRows Do 

			CurrentData = Items[JournalName].RowData(SelectedRow);
		
			SelectingCounterpartyOnServer(
				CurrentData.NameOfCounterparty,
				ValueSelected,
				CurrentData.StatementData,
				CurrentData.BankAccount,
				CurrentData["Ref"]);
				
		EndDo;		
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportedDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure BankAccountsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MarkAccounts(Command)
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		Account.Check = True;
		Object.AccountList.Add(Account.Ref);
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAccounts(Command)
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		Account.Check = False;
	EndDo;
	
EndProcedure

&AtClient
Procedure UpdateTheListOfAccounts(Command)
	
	FillOutBankAccounts();
	
EndProcedure

&AtClient
Procedure Post(Command)
	
	TMCommonUseClient.PostDocuments(Items.ImportedDocuments, Title);
	Notify("Write_DocumentPayments", , Items.ImportedDocuments);
	
EndProcedure

&AtClient
Procedure CreateCounterparty(Command)
	
	CurrentData = Items[JournalName].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Counterparty     = CurrentData.Counterparty;
	NameOfCounterparty = CurrentData.NameOfCounterparty;
	StatementData  = CurrentData.StatementData;
	
	If EmptyRegistryKeys.FindByValue(Counterparty) = Undefined
		And ValueIsFilled(Counterparty) Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Trong chứng từ %1 đã xác định đối tác %2 . Có thể thay đổi đối tác trong biểu mẫu chứng từ.';
				|ru = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|en = 'Counterparty %2 is already specified in document %1. You can change it in the document form.'; fa = 'Counterparty %2 is already specified in document %1. You can change it in the document form.';
				|it = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|pl = 'W dokumencie %1 jest już ustalony kontrahent %2. Można go zmienić w formie dokumentu.';
				|tr = '%2 cari hesabı zaten %1 belgesinde tanımlandı. Belge şeklinde değiştirilebilir.'"),
				CurrentData["Ref"],
				CurrentData.Counterparty);
		
		CommonClient.MessageToUser(
			MessageText,
			CurrentData["Ref"],,
			Items.ImportedDocumentsCounterparty.Name);
		
	ElsIf IsBlankString(NameOfCounterparty) Then
		
		MessageText = NStr("vi = 'Chưa xác định tên đối tác, không thể tự động tạo.';
							|ru = 'Неизвестно наименование контрагента, автоматическое создание невозможно.';
							|en = 'Counterparty name is unknown. Cannot create it automatically.'; fa = 'Counterparty name is unknown. Cannot create it automatically.';
							|it = 'Неизвестно наименование контрагента, автоматическое создание невозможно.';
							|pl = 'Nazwa kontrahenta jest nieznana, automatyczne tworzenie jest niemożliwe.';
							|tr = 'Cari hesabın tanımı belirsiz, otomatik oluşturma mümkün değil.'");
		
		CommonClient.MessageToUser(
			MessageText,
			CurrentData["Ref"],,
			Items.ImportedDocumentsCounterparty.Name);
		
	Else
		
		If Not ValueIsFilled(StatementData) Then
			MessageText = NStr("vi = 'Không thể tự động tạo đối tác.
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
			|Manuel olarak cari hesap oluşturun ve belgeye ekleyin.'");
			CommonClient.MessageToUser(
				MessageText,
				CurrentData["Ref"],,
				Items.ImportedDocumentsCounterparty.Name);
			Return;
		EndIf;
		
	EndIf
	
EndProcedure

&AtClient
Procedure SelectCounterparty(Command)
	
	CurrentData = Items[JournalName].CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Counterparty    = CurrentData.Counterparty;
	
	If EmptyRegistryKeys.FindByValue(Counterparty) = Undefined
		And ValueIsFilled(Counterparty) Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Trong chứng từ %1 đã xác định đối tác %2 . Có thể thay đổi đối tác trong biểu mẫu chứng từ.';
				|ru = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|en = 'Counterparty %2 is already specified in document %1. You can change it in the document form.'; fa = 'Counterparty %2 is already specified in document %1. You can change it in the document form.';
				|it = 'В документе %1 уже задан контрагент %2. Его можно изменить в форме документа.';
				|pl = 'W dokumencie %1 jest już ustalony kontrahent %2. Można go zmienić w formie dokumentu.';
				|tr = '%2 cari hesabı zaten %1 belgesinde tanımlandı. Belge şeklinde değiştirilebilir.'"),
				CurrentData["Ref"],
				CurrentData.Counterparty);
		
		CommonClient.MessageToUser(
			MessageText,
			CurrentData["Ref"],,
			Items.ImportedDocumentsCounterparty.Name);
	Else
		
		OpenForm("Catalog.Counterparties.ChoiceForm",, Items[JournalName]);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDocuments(Command)
	
	Object.DocumentsToImport.Clear();
	
	ImportParameters = New Structure();
	ImportParameters.Insert("BankAccountAddress", BankAccountsToDownload());
	ImportParameters.Insert("StartDate", BegOfDay(Object.StartDate));
	ImportParameters.Insert("EndDate", EndOfDay(Object.EndDate));
	ImportParameters.Insert("CreateCounterparties", Object.CreateCounterparties);
	ImportParameters.Insert("PostDocuments", Object.PostDocuments);
	ImportParameters.Insert("StartDate", BegOfDay(Object.StartDate));
	ImportParameters.Insert("DownloadIsPerformedWhenSyncing", False);
	ImportParameters.Insert("CounterpartyFillingModeByQRPayment", 0);
	ImportParameters.Insert("ArticlesOfCashFlowOfOperations", Undefined);

	ExchangeWithBankFeedsServiceClient.DownloadTransactions(ImportParameters, ThisObject);	
	
EndProcedure

&AtClient
Procedure BankAccountSelectionOnChange(Item)
	
	BankAccountSelectionOnChangeServer();
	
EndProcedure

&AtServer
Procedure BankAccountSelectionOnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInInitialValues(BankAccount)
	
	CurrentDate = CurrentSessionDate(); 
	
	Object.StartDate = BegOfDay(EndOfDay(CurrentDate) - 2*60*60*24);
	Object.EndDate = EndOfDay(CurrentDate);

	FillOutBankAccounts();	
	
	If ValueIsFilled(BankAccount)
		And ValueIsFilled(BankAccount) Then
		
		TableRows = Object.BankAccounts.FindRows(New Structure("Ref", BankAccount));
		If TableRows.Count() Then
			TableRows[0].Check = True;
			Object.AccountList.Add(TableRows[0]["Ref"]);
		EndIf;
	EndIf;
	
	SetDynamicListSelection();
	
EndProcedure

&AtServer
Procedure FillOutBankAccounts()

	Query = New Query();
	Query.Text = 
	"SELECT
	|	ConnectionsToBankFeedsBanks.Organization AS Organization,
	|	ConnectionsToBankFeedsBanks.Bank AS Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	CompaniesBankAccounts.Ref AS Ref,
	|	CompaniesBankAccounts.AccountNumber AS AccountNumber,
	|	CompaniesBankAccounts.Ref AS BankAccount
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Bank
	|		AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	ConnectionsToBankFeedsBanks.Organization,
	|	ConnectionsToBankFeedsBanks.Bank,
	|	ConnectionsToBankFeedsBanks.ServiceSettings,
	|	CompaniesBankAccounts.Ref,
	|	CompaniesBankAccounts.AccountNumber,
	|	CompaniesBankAccounts.Ref
	|FROM
	|	InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		LEFT JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		ON ConnectionsToBankFeedsBanks.Bank = CompaniesBankAccounts.Ref
	|		AND ConnectionsToBankFeedsBanks.Organization = CompaniesBankAccounts.Owner
	|WHERE
	|	CompaniesBankAccounts.BankFeedsAccountID <> """"";
	
	ConnectedBankAccounts = Query.Execute().Unload();
	
	Object.BankAccounts.Load(ConnectedBankAccounts);
	
EndProcedure	

&AtServer
Function BankAccountsToDownload()
	
	TableOfMarkedAccounts = Object.BankAccounts.Unload(New Structure("Check", True));	
	
	Return PutToTempStorage(TableOfMarkedAccounts);
	
EndFunction	

&AtServer
Procedure SelectingCounterpartyOnServer(NameOfCounterparty, Counterparty, StatementData, BankAccount, DocumentRef)
	
	If Not IsBlankString(StatementData) Then
		
		DocumentData = New ValueTable();
		
		If DocumentData = Undefined Then
			Return;
		EndIf;
		
		DocumentData.Insert("Counterparty", Counterparty);
		
		SubstituteCounterpartyOnServer(NameOfCounterparty, Counterparty, DocumentData, BankAccount)
		
	Else
		
		DocumentObject = DocumentRef.GetObject();
		
		Try
			DocumentObject.Lock();
		Except
			MessageText = StrTemplate(NStr("vi = 'Không thể thay đổi chứng từ: %1';
											|ru = 'Не удалось изменить документ: %1';
											|en = 'Cannot change the document: %1'; fa = 'Cannot change the document: %1';
											|it = 'Не удалось изменить документ: %1';
											|pl = 'Cannot change the document: %1';
											|tr = 'Belge değiştirilemedi: %1'"), DocumentObject);
			Common.MessageToUser(MessageText);
			Return;
		EndTry;
		
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

&AtServer
Procedure SubstituteCounterpartyOnServer(NameOfCounterparty, CounterpartyFound, DocumentData, BankAccount)
	
	StatementDocuments = Object.DocumentsToImport.Unload();
	StatementDocuments.Add();
	FillPropertyValues(StatementDocuments[0], DocumentData);
	
	AccountOfCounterparty = FindCounterpartyAccount(CounterpartyFound, StatementDocuments);
	
	If AccountOfCounterparty = Undefined Then
		AccountOfCounterparty =
			EDIWithBanksServer.CreateCounterpartySBankAccount(StatementDocuments, StatementDocuments[0], 
																							CounterpartyFound);
	EndIf;
	
	Partner = CashServer.GetCounterpartyPartner(CounterpartyFound);
	
	SubstituteCounterpartyInDocuments(NameOfCounterparty, CounterpartyFound, AccountOfCounterparty, Partner);
	
	FormTable = Items[JournalName]; // FormTable
	FormTable.Refresh();
	
EndProcedure

&AtServer
Procedure SubstituteCounterpartyInDocuments(NameOfCounterparty, CounterpartyRef, AccountLink_, PartnerLink)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentData.Ref AS Ref
	|
	|FROM
	|	Document.BankAccountReceiptNote AS DocumentData
	|
	|WHERE
	|	DocumentData.NameOfCounterparty = &NameOfCounterparty
	|	AND DocumentData.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|	
	|UNION ALL
	|	
	|SELECT
	|	DocumentData.Ref AS Ref
	|
	|FROM
	|	Document.BankAccountIssue AS DocumentData
	|
	|WHERE
	|	DocumentData.NameOfCounterparty = &NameOfCounterparty
	|	AND DocumentData.Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|";
	
	Query.SetParameter("NameOfCounterparty", NameOfCounterparty);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		DocumentObject = Selection.Ref.GetObject();
		
		Try
			DocumentObject.Lock();
		Except
			MessageText = StrTemplate(NStr("vi = 'Không thể thay đổi chứng từ: %1';
											|ru = 'Не удалось изменить документ: %1';
											|en = 'Cannot change the document: %1'; fa = 'Cannot change the document: %1';
											|it = 'Не удалось изменить документ: %1';
											|pl = 'Cannot change the document: %1';
											|tr = 'Belge değiştirilemedi: %1'"), DocumentObject);
			Common.MessageToUser(MessageText);
			Return;
		EndTry;
		
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

&AtClient
Procedure OnlyErroneousPaymentsOnChange(Item)
	
	OnlyErroneousPaymentsOnChangeServer();

EndProcedure

&AtServer
Procedure OnlyErroneousPaymentsOnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure BankAccountsCheckOnChange(Item)
	
	Object.AccountList.Clear();
	For Each Account In Object.BankAccounts Do
		If Account.Check Then
			Account.Imported = False;
			Object.AccountList.Add(Account.Ref);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage.Name = "UploadedDocumentsPage" Then
		If Object.AccountList.Count() = 1 Then
			If BankAccountSelection <> Object.AccountList[0].Value Then
				BankAccountSelection = Object.AccountList[0].Value;
				SetDynamicListSelection();
			EndIf;
		EndIf;
	EndIf;
	
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
