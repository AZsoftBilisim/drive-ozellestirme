
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency     = Constants.ManagementAccountingCurrency.Get();
	SeveralAccountsAreUsed    = GetFunctionalOption("UseMultipleBankAccounts");
	SeveralCashAccountsAreUsed      = GetFunctionalOption("UseMultipleCashAccounts");
	MultipleCashRegistersAreUsed   = GetFunctionalOption("UseSeveralCashRegisters");
	
	UpdateListOfBusinessOperations();
	
	If Not AbilityToOpenDocumentFromInstalledFO(Object.BusinessOperation) Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Author = Users.CurrentUser();
	EndIf;
	
	SetTitleOfThisForm();
	FillInDocumentParameters();
	SetVisibility1();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCashInBankAccounts")
		And Not SeveralAccountsAreUsed Then
		
		If Not ValueIsFilled(SingleAccount) Then
			
			Cancel = True;
			
			DetailErrorDescription =
				NStr("vi = 'Trong cơ sở thông tin có sử dụng một tài khoản ngân hàng,
				|nhưng chưa tùy chỉnh thuộc tính của nó trong phân hệ ""Ngân quỹ"" - ""Tùy chỉnh và danh mục"" - ""Tùy chỉnh tài khoản ngân hàng"".';
				|ru = 'В информационной базе используется один банковский счет,
				|но его свойства не настроены разделе ""Казначейство"" - ""Настройки и справочники"" - ""Настройка банковского счета"".';
				|en = 'One bank account is used in the infobase,
				|but its properties are not set up in the ""Treasury"" - ""Settings and catalogs"" - ""Set up bank account"" section.'; fa = 'One bank account is used in the infobase,
				|but its properties are not set up in the ""Treasury"" - ""Settings and catalogs"" - ""Set up bank account"" section.';
				|it = 'Nel database informatico viene utilizzato un conto bancario,
				|ma le sue proprietà non sono configurate nella sezione ""Tesoreria"" - ""Impostazioni e directory"" - ""Impostazione del conto bancario"".';
				|pl = 'W bazie informacyjnej jest używany jeden rachunek bankowy,
				|lecz jego właściwości nie są ustawione w rozdziale ""Казначейство"" - ""Настройки и справочники"" - ""Настройка банковского счета"".';
				|tr = 'Infobase''de banka hesabı kullanılmaktadır,
				|ancak onun özellikleri ""Hazine"" - ""Ayarlar ve kataloglar"" - ""Banka hesabı ayarları"" bölümünde ayarlanmadı.'");
			
			Raise DetailErrorDescription;
			
		EndIf;
		
		Object.BankAccounts.Clear();
		
		NewRow = Object.BankAccounts.Add();
		
		NewRow.BankAccount = SingleAccount;
		NewRow.Sum          = AccountBalance;
		
		OnChangeAttributeServer(
			NewRow.Sum, 
			NewRow.SumCompl,
			NewRow.SumMan,
			NewRow.BankAccount);
			
	EndIf;
	
	If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCashInHand")
		And Not SeveralCashAccountsAreUsed Then
		
		If Not ValueIsFilled(SingleCashAccount) Then
			
			Cancel = True;
			
			DetailErrorDescription =
				NStr("vi = 'Trong cơ sở thông tin có sử dụng một quỹ tiền mặt,
				|nhưng chưa tùy chỉnh thuộc tính của quỹ trong phân hệ ""Danh mục"" - ""Tùy chỉnh và danh mục"" - ""Tùy chỉnh quỹ tiền mặt"".';
				|ru = 'В информационной базе используется одна касса,
				|но ее свойства не настроены в разделе ""Нормативно-справочная информация"" - ""Настройки и справочники"" - ""Настройка кассы"".';
				|en = 'One cash account is used in the infobase,
				|but its properties are not set in the ""Master data"" - ""Settings and catalogs"" - ""Cash account settings"" section.'; fa = 'One cash account is used in the infobase,
				|but its properties are not set in the ""Master data"" - ""Settings and catalogs"" - ""Cash account settings"" section.';
				|it = 'Nel database informatico viene utilizzata una cassa,
				|ma le sue proprietà non sono configurate nella sezione ""Informazioni di riferimento normativo"" - ""Configurazioni e riferimenti"" - ""Configurazione della cassa"".';
				|pl = 'W bazie informacyjnej jest używana jedna kasa,
				|lecz jej właściwości nie są ustawione w rozdziale ""Нормативно-справочная информация"" - ""Настройки и справочники"" - ""Настройка кассы"".';
				|tr = 'Infobase''de bir yazar kasa kullanılmaktadır,
				|ancak özellikleri ""Master Veri"" - ""Ayarlar ve kataloglar"" - ""Yazar kasa ayarları"" bölümünde ayarlanmadı.'");
			
			Raise DetailErrorDescription;
			
		EndIf;
		
		Object.CashAccounts.Clear();
		
		NewRow = Object.CashAccounts.Add();
		
		NewRow.CashAccount = SingleCashAccount;
		NewRow.Sum = CashAccountBalance;
		
		OnChangeAttributeServer(
			NewRow.Sum,
			NewRow.SumCompl,
			NewRow.SumMan,
			NewRow.CashAccount);
			
	EndIf;
		
	If (Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters")
		Or Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.OBEntryCashInRetailCashRegister"))
		And Not MultipleCashRegistersAreUsed Then
		
		If Not ValueIsFilled(SingleCashRegister) Then
			
			Cancel = True;
			
			DetailErrorDescription =
				NStr("vi = 'Trong cơ sở thông tin có sử dụng một quầy thu ngân,
				|nhưng chưa tùy chỉnh thuộc tính của quầy trong phân hệ ""Danh mục"" - ""Tùy chỉnh và danh mục"" - ""Tùy chỉnh quầy thu ngân"".';
				|ru = 'В информационной базе используется одна касса ККМ,
				|но ее свойства не настроены в разделе ""Нормативно-справочная информация"" - ""Настройки и справочники"" - ""Настройка кассы ККМ"".';
				|en = 'One cash register is used in the infobase,
				|but its properties are not set in the ""Master data"" - ""Settings and catalogs"" - ""Cash register settings"" section.'; fa = 'One cash register is used in the infobase,
				|but its properties are not set in the ""Master data"" - ""Settings and catalogs"" - ""Cash register settings"" section.';
				|it = 'Nel database informatico viene utilizzata una cassa KKM (Macchinari di Registrazione e Controllo),
				|ma le sue proprietà non sono configurate nella sezione ""Informazioni di riferimento normativo"" - ""Configurazioni e riferimenti"" - ""Configurazione della cassa KKM (Macchinari di Registrazione e Controllo)"".';
				|pl = 'W bazie informacyjnej jest używana jedna kasa,
				|lecz jej właściwości nie są ustawione w rozdziale ""Нормативно-справочная информация"" - ""Настройки и справочники"" - ""Настройка кассы ККМ"".';
				|tr = 'Infobase''de bir yazar kasa kullanılmaktadır,
				|ancak onun özellikleri ""Master Veri"" - ""Ayarlar ve kataloglar"" - ""Yazar kasa ayarları"" bölümünde ayarlanmadı.'");
			
			Raise DetailErrorDescription;
			
		EndIf;
		
		Object.CashRegisters.Clear();
		
		NewRow = Object.CashRegisters.Add();
		
		NewRow.CashRegister = SingleCashRegister;
		NewRow.Sum    = CashAccountBalance;
		
		OnChangeAttributeServer(
			NewRow.Sum,
			NewRow.SumCompl,
			NewRow.SumMan,
			NewRow.CashRegister);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation",  Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	DocumentCorrectionClient.AfterWrite(Object);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetTitleOfThisForm();
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	OrganizationWhenChangedOnServer();
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBankAccounts

&AtClient
Procedure BankAccountsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow And Not SeveralAccountsAreUsed Then
		Item.CurrentData.BankAccount = SingleAccount;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountsBankAccountOnChange(Item)
	
	TableRow = Items.BankAccounts.CurrentData;
	
	OnChangeAttributeServer(
		TableRow.Sum, 
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.BankAccount);
	
EndProcedure

&AtClient
Procedure BankAccountsSumOnChange(Item)
	
	TableRow = Items.BankAccounts.CurrentData;
	
	OnChangeAttributeServer(
		TableRow.Sum, 
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.BankAccount);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashAccounts

&AtClient
Procedure CashAccountsOnEditEnd(Item, NewRow, CancelEdit)
	
	If NewRow And Not SeveralCashAccountsAreUsed Then
		Item.CurrentData.CashAccount = SingleCashAccount;
	EndIf;
	
EndProcedure

&AtClient
Procedure CashAccountsCashAccountOnChange(Item)
	
	TableRow = Items.CashAccounts.CurrentData;
	
	OnChangeAttributeServer(
		TableRow.Sum, 
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.CashAccount);
	
EndProcedure

&AtClient
Procedure CashAccountsSumOnChange(Item)
	
	TableRow = Items.CashAccounts.CurrentData;
	
	OnChangeAttributeServer(
		TableRow.Sum, 
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.CashAccount);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashRegisters

&AtClient
Procedure CashRegistersCashRegisterOnChange(Item)
	
	TableRow = Items.CashRegisters.CurrentData;
	
	OnChangeAttributeServer(
		TableRow.Sum, 
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.CashRegister);
	
EndProcedure

&AtClient
Procedure CashRegistersSumOnChange(Item)
	
	TableRow = Items.CashRegisters.CurrentData;
	
	OnChangeAttributeServer(
		TableRow.Sum, 
		TableRow.SumCompl,
		TableRow.SumMan,
		TableRow.CashRegister);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure

&AtClient
Procedure FillInByBalance(Command)
	If Object.BankAccounts.Count() > 0
		Or Object.CashAccounts.Count() > 0 Then
		AlertQuestionFillInByBalances = New CallbackDescription("AlertHandlerIssueFillInByBalances", ThisObject);
		QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại của phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'При заполнении текущие данные табличной части будут очищены. Продолжить?';
						|en = 'Current table data will be cleared. Continue?'; fa = 'Current table data will be cleared. Continue?';
						|it = 'I dati correnti della parte tabulare verranno cancellati durante la compilazione. Continuare?';
						|pl = 'Przy wypełnieniu bieżące dane części tabelarycznej będą oczyszczone. Kontynuować?';
						|tr = 'Tablo bölümünün mevcut verileri tamamlandığında silinecektir. Devam edilsin mi?'");
		ShowQueryBox(AlertQuestionFillInByBalances, QueryText, QuestionDialogMode.YesNo,,,  NStr("vi = 'Nhập số dư kế toán theo hoạt động';
																								|ru = 'Ввод остатков регл. учета по данным оперативного';
																								|en = 'Enter local accounting balance according to real-time accounting data'; fa = 'Enter local accounting balance according to real-time accounting data';
																								|it = 'Immissione delle rimanenze della contabilità regolamentare in base ai dati di contabilità operativa';
																								|pl = 'Wprowadzenie ostatków ewidencji reglamentowanej według danych operacyjnej';
																								|tr = 'Operasyonel verilere dayalı olarak yerel muhasebe bakiyelerinin girilmesi'"));
	Else
		FillByBalancesOnServer();
	EndIf;
	Return;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetTitleOfThisForm()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
		
EndProcedure

&AtServer
Procedure FillInDocumentParameters()
	
	If Not ValueIsFilled(Object.Ref) 
		And Not GetFunctionalOption("UseMultipleCompanies")
		And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = SettingsValueCached.GetDefaultOrganization();
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts 
		And Not SeveralAccountsAreUsed Then
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
		SingleAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
		If ValueIsFilled(SingleAccount) Then
			Currency = Common.ObjectAttributeValue(SingleAccount, "CashCurrency");
		Else
			Currency = Catalogs.Currencies.EmptyRef();
		EndIf;
		
		If Object.BankAccounts.Count() > 0 Then
			AccountBalance = Object.BankAccounts[0].Sum;
		EndIf;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand
		And Not SeveralCashAccountsAreUsed Then
		
		SingleCashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister();
		
		If ValueIsFilled(SingleCashAccount) Then
			CashAccountCurrency = Common.ObjectAttributeValue(SingleCashAccount, "CashCurrency");
		Else
			CashAccountCurrency = Catalogs.Currencies.EmptyRef();
		EndIf;
		
		If Object.CashAccounts.Count() > 0 Then
			CashAccountBalance = Object.CashAccounts[0].Sum;
		EndIf;
		
	ElsIf (Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInRetailCashRegister)
		And Not MultipleCashRegistersAreUsed Then
		
		SingleCashRegister = Catalogs.CashRegisters.CashRegisterByDefault();
		
		If ValueIsFilled(SingleCashRegister) Then
			CurrencyOfCashRegister = Common.ObjectAttributeValue(SingleCashRegister, "CashCurrency");
		Else
			CurrencyOfCashRegister = Catalogs.Currencies.EmptyRef();
		EndIf;
		
		If Object.CashRegisters.Count() > 0 Then
			CashAccountBalance = Object.CashRegisters[0].Sum;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangeAttributeServer(Sum, SumCompl, SumMan, Attribute)
	
	DocumentDate = Object.Date;
	OperationName   = Object.BusinessOperation;
	
	If OperationName = Enums.BusinessTransactions.OBEntryCashInHand Then
		Currency = Catalogs.CashAccounts.GetCheckoutDetails(Attribute).Currency;
	ElsIf OperationName = Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters
		Or OperationName = Enums.BusinessTransactions.OBEntryCashInRetailCashRegister Then
		Currency = Catalogs.CashRegisters.CashRegisterDetails(Attribute).Currency;
	ElsIf OperationName = Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		Currency = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(Attribute).Currency;
	EndIf;
	
	If Currency = LocalAccountingCurrency Then
		SumCompl = Sum;
	Else
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency, LocalAccountingCurrency, DocumentDate);
		SumCompl = Round(Sum * ConversionFactor_, 2, 1);
	EndIf;
	
	If Currency = ManagementAccountingCurrency Then
		SumMan = Sum;
	Else
		ConversionFactor_ = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency, ManagementAccountingCurrency, DocumentDate);
		SumMan = Round(Sum * ConversionFactor_, 2, 1);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	Items.GroupEnterBalanceBy.Visible  = GetFunctionalOption("UseLocal");
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		
		Items.GroupBankAccounts.Visible = SeveralAccountsAreUsed;
		Items.GroupOneAccount.Visible        = Not SeveralAccountsAreUsed;
		Items.GroupOneCheckout.Visible       = False;
		Items.GroupCash.Visible           = False;
		Items.GroupCashRegisters.Visible        = False;
		
		Items.BankAccountsFillInByBalance.Visible = 
			Not Object.RecordInOperationalAccounting And (Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA) And Not Object.Patch;
		
		Items.BankAccountsSumCompl.Visible = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting;
		Items.BankAccountsSumMan.Visible  = Object.RecordInOperationalAccounting Or Object.RecordInMA;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand Then
		
		Items.GroupOneCheckout.Visible       = Not SeveralCashAccountsAreUsed;
		Items.GroupCash.Visible           = SeveralCashAccountsAreUsed;
		Items.GroupBankAccounts.Visible = False;
		Items.GroupOneAccount.Visible        = False;
		Items.GroupCashRegisters.Visible        = False;
		
		Items.CashAccountsFillInByBalance.Visible = Not Object.RecordInOperationalAccounting And (Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA);
		Items.CashAccountsSumCompl.Visible           = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting;
		Items.CashAccountsSumMan.Visible            = Object.RecordInOperationalAccounting Or Object.RecordInMA;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInRetailCashRegister
		Or Object.BusinessOperation = Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters Then
		
		Items.GroupOneCheckout.Visible          = Not MultipleCashRegistersAreUsed;
		Items.GroupCashRegisters.Visible           = MultipleCashRegistersAreUsed;
		Items.GroupBankAccounts.Visible    = False;
		Items.GroupOneAccount.Visible           = False;
		Items.GroupCash.Visible              = False;
		Items.CashAccountsFillInByBalance.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Function AbilityToOpenDocumentFromInstalledFO(BusinessOperation)
	
	Result = False;	
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts  Then
		
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount();
		
		If Not ValueIsFilled(BankAccount) Then
		
			Query = New Query("SELECT ALLOWED TOP 2
				|	CompaniesBankAccounts.Ref
				|FROM
				|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
				|WHERE
				|	NOT CompaniesBankAccounts.DeletionMark
				|");
			
			If Query.Execute().Select().Count() = 2
				And Not SeveralAccountsAreUsed Then
				Raise  NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Trong cơ sở thông tin đã nhập nhiều tài khoản ngân hàng của doanh nghiệp,
				|nhưng đồng thời chưa bật tùy chọn ""Sử dụng nhiều tài khoản ngân hàng"". Hãy bật tùy chọn chức năng ""Sử dụng nhiều tài khoản ngân hàng"".';
				|ru = 'Не удалось заполнить поле ""Банковский счет"". В информационной базе введено несколько банковских счетов организаций,
				|но при этом, не включена функциональная опция ""Использовать несколько банковских счетов"". Включите функциональную опцию ""Использовать несколько банковских счетов"".';
				|en = 'Failed to fill in the ""Bank account"" field. Several bank accounts of companies have been entered in the infobase, 
				|but the functional option ""Use multiple bank accounts"" has not been enabled. Enable the ""Use multiple bank accounts"" functional option.'; fa = 'Failed to fill in the ""Bank account"" field. Several bank accounts of companies have been entered in the infobase, 
				|but the functional option ""Use multiple bank accounts"" has not been enabled. Enable the ""Use multiple bank accounts"" functional option.';
				|it = 'Non è stato possibile compilare il campo ""Conto bancario"". Nell''infobase sono stati inseriti alcuni conti bancari delle aziende,
				| ma con questo è abilitata l''opzione funzionale ""Utilizzare alcuni conti bancari"".Abilitare l''opzione funzionale ""Utilizzare alcuni conti bancari""';
				|pl = 'Nie udało się wypełnić pola ""Банковский счет"". W bazie informacyjnej wprowadzono kilka rachunków bankowych firm,
				|ale przy tym, nie włączono opcji funkcjonalnej ""Использовать несколько банковских счетов"". Włącz opcję funkcjonalną ""Использовать несколько банковских счетов"".';
				|tr = '""Banka hesabı"" alanı doldurulamadı. İş yerlerinin birden fazla banka hesabı infobase''e girildi,
				|ancak ""Birden fazla banka hesabı kullan"" fonksiyonel seçeneği etkinleştirilmemiştir. ""Birden fazla banka hesabı kullan"" fonksiyonel seçeneğini aç.'");
			ElsIf Query.Execute().Select().Count()  = 0 Then
				Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Có thể, trong cơ sở thông tin chưa nhập bất kỳ tài khoản ngân hàng nào của doanh nghiệp.';
							|ru = 'Не удалось заполнить поле ""Банковский счет"". Возможно, в информационной базе не введено ни одного банковского счета организации.';
							|en = 'Cannot fill in field ""Bank account"". Possibly no bank accounts of the company are entered into the infobase.'; fa = 'Cannot fill in field ""Bank account"". Possibly no bank accounts of the company are entered into the infobase.';
							|it = 'Non è stato possibile compilare il campo ""Conto bancario"". Probabilmente nel database informatico non è stato immesso nessun conto bancario della società.';
							|pl = 'Nie udało się wypełnić pola ""Konto bankowe"". Możliwe, że do bazy informacyjnej nie wprowadzono ani jednego rachunku bankowego firmy!';
							|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e iş yerine ait bir banka hesabı girilmemiş olabilir!'");
			EndIf;
			
		EndIf;
		
		Result = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand Then
		
		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister();
		
		If Not ValueIsFilled(CashAccount) Then
			
			Query = New Query("SELECT ALLOWED TOP 2
				|	CashAccounts.Ref
				|FROM
				|	Catalog.CashAccounts AS CashAccounts
				|WHERE
				|	NOT CashAccounts.DeletionMark");
			
			If Query.Execute().Select().Count() = 2
				And Not SeveralCashAccountsAreUsed Then
				Raise NStr("vi = 'Không thể điền trường ""Quỹ tiền mặt"". Trong cơ sở thông tin đã nhập nhiều quỹ tiền mặt, 
				|nhưng đồng thời chưa bật tùy chọn ""Sử dụng nhiều quỹ tiền mặt"". Hãy bật tùy chọn chức năng ""Sử dụng nhiều quỹ tiền mặt"".';
				|ru = 'Не удалось заполнить поле ""Касса"". В информационной базе введено несколько касс, но при этом, 
				|не включена функциональная опция ""Использовать несколько касс"". Включите функциональную опцию ""Использовать несколько касс"".';
				|en = 'Cannot fill in the ""Cash account"" field. Several cash accounts have been entered in the infobase, but at the same time, 
				|the functional option ""Use multiple cash accounts"" is not enabled. Enable the ""Use multiple cash accounts"" functional option.'; fa = 'Cannot fill in the ""Cash account"" field. Several cash accounts have been entered in the infobase, but at the same time, 
				|the functional option ""Use multiple cash accounts"" is not enabled. Enable the ""Use multiple cash accounts"" functional option.';
				|it = 'Non è stato possibile compilare il campo ""Cassa"".Nel database informativo è stato immesso alcune casse, ma con questo
				|non è stata abilitata l''opzione funzionale ""Utilizzare alcune casse"" Abilitare l''opzione funzionale ""Utilizzare alcune casse"".';
				|pl = 'Nie udało się wypełnić pola ""Касса"". W bazie informacyjnej wprowadzono kilka kas, ale przy tym, 
				|nie włączono opcji funkcjonalnej ""Использовать несколько касс"". Włącz opcję funkcjonalną ""Использовать несколько касс"".';
				|tr = '""Kasa"" alanı doldurulamadı. Infobase''e birden fazla kasa girildi, 
				|ancak ""Birden fazla kasa kullan"" seçeneği etkin değil. ""Birden fazla kasa kullan"" fonksiyonel seçeneğini aç.'");
			ElsIf Query.Execute().Select().Count()  = 0 Then
				Raise NStr("vi = 'Không thể điền vào trường ""Quỹ tiền mặt"". Có lẽ, chưa nhập bất kỳ quỹ tiền mặt nào trong cơ sở thông tin.';
							|ru = 'Не удалось заполнить поле ""Касса"". Возможно, в информационной базе не введено ни одной кассы.';
							|en = 'Cannot fill in field ""Cash account"". Possibly there are no cash accounts entered into the infobase.'; fa = 'Cannot fill in field ""Cash account"". Possibly there are no cash accounts entered into the infobase.';
							|it = 'Non è stato possibile compilare il campo ""Cassa"". Probabilmente nel database informatico non è stata immessa alcuna cassa.';
							|pl = 'Nie udało się wypełnić pola ""Касса"". Możliwe, w bazie informacyjnej nie wprowadzono ani jednej kasy!';
							|tr = '""Kasa"" alanı doldurulamadı. Infobase''e herhangi bir kasa girilmemiş olabilir.'");
			EndIf;
			
		EndIf;
		
		Result = True;
		
	ElsIf (BusinessOperation = Enums.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters
		Or BusinessOperation = Enums.BusinessTransactions.OBEntryCashInRetailCashRegister) Then
		
		CashRegister = Catalogs.CashRegisters.CashRegisterByDefault();
		
		If Not ValueIsFilled(CashRegister) Then
			
			Query = New Query("SELECT ALLOWED TOP 2
				|	CashRegisters.Ref AS CashRegister
				|FROM
				|	Catalog.CashRegisters AS CashRegisters
				|WHERE
				|	NOT CashRegisters.DeletionMark");
			
			If Query.Execute().Select().Count() = 2 
				And Not MultipleCashRegistersAreUsed Then
				Raise NStr("vi = 'Không thể điền trường ""Quầy thu ngân"". Trong cơ sở thông tin đã nhập nhiều quầy thu ngân,
				|Hãy bật tùy chọn ""Sử dụng nhiều quầy thu ngân""';
				|ru = 'Не удалось заполнить поле ""Касса ККМ"". В информационной базе введено несколько касс ККМ,
				|Включите функциональную опцию ""Использовать несколько касс ККМ""';
				|en = 'Cannot fill in the ""Cash register"" field. There are several cash registers entered into the infobase.
				|Enable the ""Use several cash registers"" functional option.'; fa = 'Cannot fill in the ""Cash register"" field. There are several cash registers entered into the infobase.
				|Enable the ""Use several cash registers"" functional option.';
				|it = 'Non è stato possibile compilare il campo ""Cassa KKM (Macchinari di Registrazione e Controllo)"". Nel database informatico sono immesse più casse KKM,
				|Abilitare l''impostazione funzionale ""Utilizzare più casse KKM""';
				|pl = 'Nie udało się wypełnić pola ""Касса ККМ"". W bazie informacyjnej wprowadzono kilka kass,
				|Włącz opcję funkcjonalną  ""Использовать несколько касс ККМ""';
				|tr = '""Yazar kasa"" alanı doldurulamadı. Infobase''e girilmiş birden fazla yazar kasa var,
				|""Birden fazla yazar kasa kullan"" fonksiyon seçeneğini aç'");
			ElsIf Query.Execute().Select().Count()  = 0 Then
				Raise NStr("vi = 'Không thể điền trường ""Quầy thu ngân"". Có thể, trong cơ sở thông tin chưa nhập bất kỳ một quầy thu ngân nào';
							|ru = 'Не удалось заполнить поле ""Касса ККМ"". Возможно, в информационной базе не введено ни одной кассы ККМ';
							|en = 'Cannot fill in field ""Cash register"". Possibly, there are no cash registers entered into the infobase.'; fa = 'Cannot fill in field ""Cash register"". Possibly, there are no cash registers entered into the infobase.';
							|it = 'Non è stato possibile compilare il campo ""Cassa KKM (Macchinari di Registrazione e Controllo)"". Probabilmente nel database informatico non è stata immessa alcuna cassa KKM';
							|pl = 'Nie udało się wypełnić pola ""Касса ККМ"". Możliwe, w bazie informacyjnej nie wprowadzono ani jednej kasy';
							|tr = '""Yazar kasa"" alanı doldurulamadı. Muhtemelen, infobase''e girilmiş herhangi bir yazar kasa yok'");
			EndIf;
			
		EndIf;
		
		Result = True;
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure UpdateListOfBusinessOperations()
	
	FilterParameters = OBEntryServer.InitializeSelectionParametersForAvailableBusinessOperations();
	FilterParameters.BalanceInputDocument = Common.MetadataObjectID(
		Metadata.Documents.OBEntryCash);
	
	AvailableBusinessTransactions = OBEntryServer.AvailableBusinessTransactions(FilterParameters);
	Items.BusinessOperation.ChoiceList.LoadValues(AvailableBusinessTransactions);
	
EndProcedure

&AtServer
Procedure FillByBalancesOnServer()
	
	If Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		TabPart = FormAttributeToValue("Object.BankAccounts");
		TabPart.Clear();
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand Then
		TabPart = FormAttributeToValue("Object.CashAccounts");
		TabPart.Clear();
	Else
		Return;
	EndIf;
	
	Balance = Documents.OBEntryCash.BalancesByTypeOfOperation(Object.Date, Object.BusinessOperation, Object.Organization);
	
	For Each Var_28_Balance In Balance Do
		Page1 = TabPart.Add();
		FillPropertyValues(Page1, Var_28_Balance);
	EndDo;
	
EndProcedure

&AtClient
Procedure AlertHandlerIssueFillInByBalances(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillByBalancesOnServer();
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
