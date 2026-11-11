   
#Region FormEventHandlers
   
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Organization = Parameters.Organization;
	ResultOfResponseFromServiceToListOfAccounts = Parameters.ResultOfResponseFromService;
	Result = GetFromTempStorage(ResultOfResponseFromServiceToListOfAccounts.ResultAddress);
	Bank = Result.FillParameters.Bank;;
	Organization = Result.FillParameters.Organization;
	Service = Result.FillParameters.Service;
	
	For Each CurCurrentRowInvoiceTableFromService In Result.TableOfAccounts Do
		
		NewRow = TableOfAccounts.Add();
		NewRow.Account = CurCurrentRowInvoiceTableFromService.Account;
		NewRow.InvoiceId = CurCurrentRowInvoiceTableFromService.InvoiceId;
		NewRow.CreationDate = CurCurrentRowInvoiceTableFromService.CreationDate;
		NewRow.Currency = CurCurrentRowInvoiceTableFromService.Currency;
		NewRow.NameOfAnAccount = CurCurrentRowInvoiceTableFromService.NameOfAnAccount;
		NewRow.Balance = Number(CurCurrentRowInvoiceTableFromService.Balance);
		
	EndDo;

	FindAccountsInProgram();
	
    ItemCondition= ConditionalAppearance.Items.Add();
    ItemCondition.Use = True;
    ItemCondition.Appearance.SetParameterValue("ReadOnly",  True);

	FilterGroup =  ItemCondition.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
    ElementSelection                = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
    ElementSelection.LeftValue  = New DataCompositionField("TableOfAccounts.AlreadyAddedTo1C");
    ElementSelection.RightValue = True; 
    ElementSelection.ComparisonType   = DataCompositionComparisonType.Equal;
    ElementSelection.Use  = True;
    
    ElementSelection                = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
    ElementSelection.LeftValue  = New DataCompositionField("TableOfAccounts.ConnectedToService");
    ElementSelection.RightValue = True; 
    ElementSelection.ComparisonType   = DataCompositionComparisonType.Equal;
    ElementSelection.Use  = True;

	FormattedField      = ItemCondition.Fields.Items.Add();
    FormattedField.Field = New DataCompositionField("TableOfAccounts");	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure AddBankAccount(Bank, Account, TheCurrencyCodeIsAlphabetic, InvoiceId)
	
	Currency = FindCurrency(TheCurrencyCodeIsAlphabetic);
	
	FoundObject = FindBankAccount(Account, Currency, Organization);
	
	If FoundObject.IsEmpty() Then  
		SettlementAccount = Catalogs.CompaniesBankAccounts.CreateItem();
	Else
		SettlementAccount = FoundObject.GetObject();
		Try
			SettlementAccount.Lock();
		Except
			MessageText = StrTemplate(NStr("vi = 'Không thể thay đổi tài khoản hạch toán: %1';
											|ru = 'Не удалось изменить расчетный счет: %1';
											|en = 'Cannot edit the current account: %1'; fa = 'Cannot edit the current account: %1';
											|it = 'Не удалось изменить расчетный счет: %1';
											|pl = 'Cannot edit the current account: %1';
											|tr = 'Cari hesap değiştirilemedi: %1'"), SettlementAccount);
			Common.MessageToUser(MessageText);
			Return;
		EndTry;	
		
	EndIf;	
		
	SettlementAccount.Owner = Organization;
	SettlementAccount.Bank = Bank; 
	SettlementAccount.AccountNumber = Account;
	SettlementAccount.ThisIsAnIBAN = True;
	SettlementAccount.CashCurrency = Currency;  
	SettlementAccount.AccountType = Enums.BankAccountTypes.Estimated_;
	SettlementAccount.BankEDIEnabled = True;
	SettlementAccount.UseBankFeedsBankExchange = True; 
	SettlementAccount.BankFeedsAccountID = InvoiceId;
		
	If CashClientServer.CorrectIBANLength(SettlementAccount.AccountNumber) Then
		SettlementAccount.ThisIsAnIBAN = True; 
	EndIf;
		
	If SettlementAccount.DeletionMark Then
		
		SettlementAccount.DeletionMark = False;
		
	EndIf;	
		
	SettlementAccount.Description = GenerateAutoNameOfCurrentAccount(SettlementAccount);
	SettlementAccount.MonthDisplayOption = Enums.OptionsOfMonthDisplayingInDocumentDate.ByNumber;
	SettlementAccount.Write();
	
EndProcedure	

&AtClient
Procedure OK(Command)
	
	ListOfAddedAccounts = New ValueList;
	AccountsAddedButNotConnectedAreMarked = False;
	
	For Each TableRow In TableOfAccounts Do  
		
		If TableRow.Check Then
			If TableRow.AlreadyAddedTo1C And Not TableRow.ConnectedToService
				And Not TableRow.SkipAdding Then
					
				QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Tài khoản ngân hàng ""%1"" đã tồn tại trong danh mục, nhưng chưa được kết nối đến dịch vụ.
					|Kết nối?';
					|ru = 'Банковский счет ""%1"" существует в справочнике, но не подключен к сервису.
					|Подключить?';
					|en = 'The ""%1"" bank account exists in the catalog, but is not connected to the service.
					|Connect the account?'; fa = 'The ""%1"" bank account exists in the catalog, but is not connected to the service.
					|Connect the account?';
					|it = 'Банковский счет ""%1"" существует в справочнике, но не подключен к сервису.
					|Подключить?';
					|pl = 'The ""%1"" bank account exists in the catalog, but is not connected to the service.
					|Connect the account?';
					|tr = 'Dizinde “%1” banka hesabı var, ancak hizmete bağlı değil.
					| Bağlansın mı?'"),
					TableRow.Account);
					
					AdditionalParameters = New Structure("Account,Currency,InvoiceId", 
											TableRow.Account, TableRow.Currency, TableRow.InvoiceId);
					CallbackDescription = New CallbackDescription("ConnectingToServiceOfExistingAccountEnd", 
																					ThisObject, AdditionalParameters);
					ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

					AccountsAddedButNotConnectedAreMarked = True;
					
					Break;
			EndIf;
			
		EndIf;	
		
	EndDo;	                   
	
	If Not AccountsAddedButNotConnectedAreMarked Then
		For Each TableRow In TableOfAccounts Do  
		
			If TableRow.Check 
				And Not TableRow.ConnectedToService Then
			
				AddBankAccount(Bank, TableRow.Account, TableRow.Currency, TableRow.InvoiceId);
				ListOfAddedAccounts.Add(TableRow.Account);
			
			EndIf;	
		
		EndDo;	

		Notify("UpdateListOfBankAccounts");
	
		Close(New Structure("ListOfAddedAccounts", ListOfAddedAccounts));

	EndIf;	
	
EndProcedure

&AtClient
Procedure ConnectingToServiceOfExistingAccountEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Account = AdditionalParameters.Account;
		Currency = AdditionalParameters.Currency;  
		InvoiceId = AdditionalParameters.InvoiceId;
		
		ConnectAccount(Bank, Account, Currency, InvoiceId);
		
	EndIf;

	FoundRows  = TableOfAccounts.FindRows(
		New Structure("InvoiceId", AdditionalParameters.InvoiceId));
		
	FoundRows[0].SkipAdding = True;
	
	OK("");
	
EndProcedure

&AtServer
Procedure ConnectAccount(Bank, Account, TheCurrencyCodeIsAlphabetic, InvoiceId)
	
	Currency = FindCurrency(TheCurrencyCodeIsAlphabetic);
	
	FoundObject = FindBankAccount(Account, Currency, Organization);
	
	SettlementAccount = FoundObject.GetObject();
	
	Try
			SettlementAccount.Lock();
		Except
			MessageText = StrTemplate(NStr("vi = 'Không thể thay đổi tài khoản hạch toán: %1';
											|ru = 'Не удалось изменить расчетный счет: %1';
											|en = 'Cannot edit the current account: %1'; fa = 'Cannot edit the current account: %1';
											|it = 'Не удалось изменить расчетный счет: %1';
											|pl = 'Cannot edit the current account: %1';
											|tr = 'Cari hesap değiştirilemedi: %1'"), SettlementAccount);
			Common.MessageToUser(MessageText);
			Return;
	EndTry;	
		
	SettlementAccount.BankFeedsAccountID = InvoiceId;
		
	SettlementAccount.Write();
	
EndProcedure	

&AtClient
Procedure MarkAccounts(Command)
	
	For Each Account In TableOfAccounts Do
		If Not Account.ConnectedToService Then
			Account.Check = True;
		EndIf;	
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAccounts(Command)
	
	For Each Account In TableOfAccounts Do 
		If Not Account.ConnectedToService Then
			Account.Check = False;
		EndIf;	
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function FindBankAccount(AccountNumber, Currency, Organization)
	
	Query = New Query();                               
	Query.SetParameter("AccountNumber", AccountNumber);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("Organization", Organization); 
	
	Query.Text = 
	"SELECT
	|	CompaniesBankAccounts.Ref AS Ref
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|WHERE
	|	CompaniesBankAccounts.AccountNumber = &AccountNumber
	|	AND CompaniesBankAccounts.CashCurrency = &Currency
	|	AND CompaniesBankAccounts.Owner = &Organization";
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		Return Result.Ref;
	EndIf;	
	
	Return Catalogs.CompaniesBankAccounts.EmptyRef();
	
EndFunction

&AtServerNoContext
Function FindCurrency(TheCurrencyCodeIsAlphabetic)
	
 	FoundCurrency = Catalogs.Currencies.FindByDescription(TheCurrencyCodeIsAlphabetic);	

 	If FoundCurrency <> Undefined
		And ValueIsFilled(FoundCurrency) Then
		
			Return FoundCurrency;
 	EndIf;	 
	
	NewCurrency = AddNewCurrency(TheCurrencyCodeIsAlphabetic);
	
 	If NewCurrency <> Undefined
		And ValueIsFilled(NewCurrency) Then
		
			Return NewCurrency;
 	EndIf;	 
	
 	Return Catalogs.Currencies.EmptyRef();
EndFunction

&AtServerNoContext
Function AddNewCurrency(CurrencyCodeIsAlphabeticForSearching)
	
	SpreadsheetDocument = DataProcessors.InternationalCurrencyClassifier.GetTemplate("InternationalCurrencyClassifier");
	LinkToNewCurrency = Catalogs.Currencies.EmptyRef();
	
	For CntRow = 2 To SpreadsheetDocument.TableHeight Do

		DigitalCurrencyCode = SpreadsheetDocument.Area(CntRow, 1).Text;
		TheCurrencyCodeIsAlphabetic = SpreadsheetDocument.Area(CntRow, 2).Text;
		Description = SpreadsheetDocument.Area(CntRow, 3).Text;
		AmountInWordsParameters = SpreadsheetDocument.Area(CntRow, 5).Text;
		Downloading = TextInBoolean(SpreadsheetDocument.Area(CntRow, 6).Text);
		
		If CurrencyCodeIsAlphabeticForSearching = TheCurrencyCodeIsAlphabetic Then
			
			BeginTransaction();
			Try
			
				NewItem = Catalogs.Currencies.CreateItem();
				NewItem.Code                       = DigitalCurrencyCode;
				NewItem.Description              = TheCurrencyCodeIsAlphabetic;
				NewItem.DescriptionFull        = Description;
				If Downloading Then
					NewItem.RateSource = Enums.RateSources.DownloadFromInternet;
				Else
					NewItem.RateSource = Enums.RateSources.ManualInput;
				EndIf;
				NewItem.AmountInWordsParameters = AmountInWordsParameters;
				NewItem.Write();
			
				ProcessingOfExchangeRatesTM.CheckCorrectnessOfRelativeRateOn01_01_1980(NewItem.Ref);

				LinkToNewCurrency = NewItem.Ref;
				
				CommitTransaction();
				
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
		EndIf;	 
		
		If ValueIsFilled(LinkToNewCurrency) Then
			Break;
		EndIf;	
		
	EndDo;
	
	Return LinkToNewCurrency;
	
EndFunction

&AtServerNoContext
Function TextInBoolean(StringValue)
	
	If IsBlankString(StringValue) Or StringValue = Undefined Then
		Return False;
	EndIf;
	
	Return TrimAll(StringValue) = "true";
	
EndFunction

&AtServer
Procedure  FindAccountsInProgram()
	
	ArrayOfAccountNumbers = New Array;
	
	For Each CurRowTableOfAccounts In TableOfAccounts Do
		
		ArrayOfAccountNumbers.Add(CurRowTableOfAccounts.Account);
	
	EndDo;

	Query = New Query();
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Bank", Bank);
	Query.SetParameter("ListOfAccountNumbers", ArrayOfAccountNumbers);
	
	Query.Text = 
	"SELECT
	|	CompaniesBankAccounts.Ref AS BankAccount,
	|	CompaniesBankAccounts.Owner AS Organization,
	|	CompaniesBankAccounts.Bank AS Bank,
	|	CompaniesBankAccounts.AccountNumber AS Account,
	|	Currencies.Description AS Currency,
	|	ConnectionsToBankFeedsBanks.ServiceSettings AS ServiceSettings,
	|	CompaniesBankAccounts.BankFeedsAccountID AS BankFeedsAccountID
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		LEFT JOIN Catalog.Currencies AS Currencies
	|		ON CompaniesBankAccounts.CashCurrency = Currencies.Ref
	|		LEFT JOIN InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		ON CompaniesBankAccounts.Bank = ConnectionsToBankFeedsBanks.Bank
	|			AND CompaniesBankAccounts.Owner = ConnectionsToBankFeedsBanks.Organization
	|WHERE
	|	CompaniesBankAccounts.Bank = &Bank
	|	AND CompaniesBankAccounts.Owner = &Organization
	|	AND CompaniesBankAccounts.AccountNumber IN(&ListOfAccountNumbers)
	|	AND NOT CompaniesBankAccounts.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	CompaniesBankAccounts.Ref,
	|	CompaniesBankAccounts.Owner,
	|	CompaniesBankAccounts.Bank,
	|	CompaniesBankAccounts.AccountNumber,
	|	Currencies.Description,
	|	ConnectionsToBankFeedsBanks.ServiceSettings,
	|	CompaniesBankAccounts.BankFeedsAccountID
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		LEFT JOIN Catalog.Currencies AS Currencies
	|		ON CompaniesBankAccounts.CashCurrency = Currencies.Ref
	|		LEFT JOIN InformationRegister.ConnectionsToBankFeedsBanks AS ConnectionsToBankFeedsBanks
	|		ON CompaniesBankAccounts.Ref = ConnectionsToBankFeedsBanks.Bank
	|			AND CompaniesBankAccounts.Owner = ConnectionsToBankFeedsBanks.Organization
	|WHERE
	|	CompaniesBankAccounts.Owner = &Organization
	|	AND CompaniesBankAccounts.AccountNumber IN(&ListOfAccountNumbers)
	|	AND CompaniesBankAccounts.ManualBankDetailsChange
	|	AND NOT CompaniesBankAccounts.DeletionMark";	
	
	TableOfAccountsInProgram = Query.Execute().Unload();
	
	If TableOfAccountsInProgram.Count() > 0 Then
		
		InvoiceFilter = New Structure("Organization,Account,Currency");
		InvoiceFilter.Organization = Organization;
		
		For Each CurRowTableOfAccounts In TableOfAccounts Do
			
			FillPropertyValues(InvoiceFilter, CurRowTableOfAccounts);
			
			FoundRows = TableOfAccountsInProgram.FindRows(InvoiceFilter);
			
			If FoundRows.Count() > 0 Then
				
				CurRowTableOfAccounts.AlreadyAddedTo1C = True;
				
				CurRowTableOfAccounts.ConnectedToService = ValueIsFilled(FoundRows[0].ServiceSettings) 
																And ValueIsFilled(FoundRows[0].BankFeedsAccountID);
																
				CurRowTableOfAccounts.Check = CurRowTableOfAccounts.ConnectedToService;
				
			EndIf;	
			
		EndDo;
		
	EndIf;	
		
EndProcedure	

&AtServer 
Function GenerateAutoNameOfCurrentAccount(SettlementAccount)
	
	If SettlementAccount.ManualBankDetailsChange Then
		NameString_ = Right(TrimAll(SettlementAccount.AccountNumber), 4) 
		+ ?(ValueIsFilled(SettlementAccount.BankDescription), " In " + String(SettlementAccount.BankDescription), "")
		+ ", " + TrimAll(SettlementAccount.Owner);
		NameString_ = Left(NameString_, 150);
		
	Else	
		
		NameString_ = Right(TrimAll(SettlementAccount.AccountNumber), 4) 
		+ ?(ValueIsFilled(SettlementAccount.Bank), " In " + String(SettlementAccount.Bank), "")
		+ ", " + TrimAll(SettlementAccount.Owner);
		NameString_ = Left(NameString_, 150);
		
	EndIf;
	
	Return NameString_;

EndFunction

#EndRegion