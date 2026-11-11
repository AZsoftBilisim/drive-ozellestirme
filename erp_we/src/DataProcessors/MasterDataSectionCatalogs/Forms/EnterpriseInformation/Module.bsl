
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ManagingElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region GeneralCatalogues

&AtClient
Procedure ToOpenTheCashRegisterKKM(Command)
	
	OpenForm("Catalog.CashRegisters.ObjectForm", New Structure("Key", CashRegister()));
	
EndProcedure

&AtClient
Procedure OpenAWarehouse(Command)
	
	OpenForm("Catalog.Warehouses.ObjectForm", New Structure("Key", Warehouse()));
	
EndProcedure

&AtClient
Procedure OpenAnOrganization(Command)
	
	OpenForm("Catalog.Companies.ObjectForm", New Structure("Key", Organization()));
	
EndProcedure

&AtClient
Procedure OpenTheBankAccountProperty(Command)
		
	OpenForm("Catalog.CompaniesBankAccounts.ObjectForm",
		New Structure("Key", GetOrganizationSFirstBankAccountOnServer()),
		ThisForm);

EndProcedure

&AtClient
Procedure OpenPropertyCashAccount(Command)
	
	OpenForm("Catalog.CashAccounts.ObjectForm",
		New Structure("Key", GetFirstCheckoutOnServer()),
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenACurrency(Command)
	
	ManagementAccountingCurrency = Currency();
	If Not ValueIsFilled(ManagementAccountingCurrency) Then
		Raise NStr("vi = 'Để tiếp tục, cần điền hằng ""Tiền tệ kế toán quản trị"".
		|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Tập đoàn"" - ""Tiền tệ"".';
		|ru = 'Для продолжения необходимо заполнить константу ""Валюта управленческого учета"".
		|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
		|en = 'To continue, fill in the ""Management accounting currency"" constant.
		| To set it up, go to ""Master data and settings"" — ""Enterprise"" — ""Currencies"".'; fa = 'To continue, fill in the ""Management accounting currency"" constant.
		| To set it up, go to ""Master data and settings"" — ""Enterprise"" — ""Currencies"".';
		|it = 'Per continuare è necessario compilare la costante ""Valuta della contabilità di gestione"".
		|Per l''impostazione è necessario passare alla sezione ""Informazioni di riferimento e amministrazione""-""Impresa""-""Valute"".';
		|pl = 'Aby kontynuować należy wypełnić stałą ""Waluta ewidencji zarządczej"".
		|W celu ustawienia należy przejść do rozdziału ""Ustawienia""- -""Przedsiębiorstwo""-""Waluty"".';
		|tr = 'Devam etmek için ""Yönetim muhasebesi para birimi"" sabitinin doldurulması gerekir.
		|Ayarlamak için ""Master veri ve yönetim"" - ""İşletme"" - ""Para Birimleri"" bölümüne git.'");
	EndIf;
	
	OpenForm("Catalog.Currencies.ObjectForm", New Structure("Key", ManagementAccountingCurrency));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()

	// Functional options
	UseMultipleCompanies     = GetFunctionalOption("UseMultipleCompanies");
	UseMultipleCurrencies           = GetFunctionalOption("UseMultipleCurrencies");
	UseSeveralWarehouses         = GetFunctionalOption("UseSeveralWarehouses");
	UseSeveralCashRegisters         = GetFunctionalOption("UseSeveralCashRegisters");
	UseMultipleCashAccounts            = GetFunctionalOption("UseMultipleCashAccounts");
	UseMultipleBankAccounts = GetFunctionalOption("UseMultipleBankAccounts");
	UseRetailSales         = GetFunctionalOption("UseRetailSales");

	// Read right
	OrganizationAccessRights = AccessRight("View", Metadata.Catalogs.Companies);
	CurrencyAccessRights      = AccessRight("View", Metadata.Catalogs.Currencies);
	RightOfAccessWarehouses      = AccessRight("View", Metadata.Catalogs.Warehouses);
	CashRegisterAccessRights    = AccessRight("View", Metadata.Catalogs.CashRegisters);
	
	//Bank Account
	Items.GroupOfSettingsBankAccounts.Visible = Not UseMultipleBankAccounts;
	Items.GroupOfSettingsCash.Visible           = Not UseMultipleCashAccounts;
	
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"CompanyInformation", "Visible", Not UseMultipleCompanies And OrganizationAccessRights);
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"CurrenciesGroup", "Visible", Not UseMultipleCurrencies And CurrencyAccessRights);
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"WarehouseAccountingSetupGroup", "Visible", Not UseSeveralWarehouses And RightOfAccessWarehouses);
	TMCommonUseClientServer.SetFormItemProperty(Items,
		"GroupSettingUpACashRegisterKKM", "Visible", Not UseSeveralCashRegisters And CashRegisterAccessRights And UseRetailSales);
	
	ThereIsDataToDisplay = Items.GroupOfOrganizations_3.Visible
		Or Items.GroupOfSettingsBankAccounts.Visible
		Or Items.GroupOfSettingsCash.Visible
		Or Items.CurrenciesGroup.Visible
		Or Items.WarehouseAccountingSetupGroup.Visible
		Or Items.GroupSettingUpACashRegisterKKM.Visible;
		
	If ThereIsDataToDisplay Then
		Items.GroupTheNecessarySettingsAreNotSet.Visible = False;
	EndIf;
	
EndProcedure

#Region Other

&AtServerNoContext
Function Warehouse()
	Return Catalogs.Warehouses.DefaultWarehouse();
EndFunction

&AtServerNoContext
Function Currency()
	Return IncomeAndExpensesServer.GetCurrencyOfManagementAccounting();
EndFunction

&AtServerNoContext
Function Organization()
	Return Catalogs.Companies.GetDefaultOrganization();
EndFunction

&AtServerNoContext
Function CashRegister()
	Return Catalogs.CashRegisters.CashRegisterByDefault();
EndFunction

&AtServerNoContext
Function GetFirstCheckoutOnServer()
	
	Return SettingsValueCached.GetOrganizationSDefaultSalesRegister()
	
EndFunction // Get the first instance of the Server()

&AtServerNoContext
Function GetOrganizationSFirstBankAccountOnServer()

	Return CashServer.GetOrganizationSDefaultBankAccount();

EndFunction // Get the first Bank account of the organization in the Server()

#EndRegion

#EndRegion
