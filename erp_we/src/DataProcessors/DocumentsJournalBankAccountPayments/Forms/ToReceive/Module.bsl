
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
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
	
	SetVisibility1();
	InitializeBankingDetails();
	SetDynamicListSelection();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SaveWorkingValuesOfFormFields(True);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(
		ThisObject, "OrdersPendingGoodsReceipt.Date", Items.OrdersPendingGoodsReceiptDate.Name);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DateForReceipt          = Settings.Get("DateForReceipt");
	
	TransactionList            = Settings.Get("TransactionListReceipts");
	If TransactionList <> Undefined Then
		For Each Operation In TransactionList Do
			If Operation.Check Then
				ListOperation_ = TransactionListReceipts.FindByValue(Operation.Value);
				If ListOperation_ <> Undefined Then
					ListOperation_.Check = True;
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	TransactionListReceiptsPresentation = TransactionListPresentation(TransactionListReceipts);
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	NamesOfEventsUpdatingListForReceipt = New Array;
	NamesOfEventsUpdatingListForReceipt.Add("Write_BankAccountReceiptNote");
	NamesOfEventsUpdatingListForReceipt.Add("Write_CashAccountReceiptNote");
	NamesOfEventsUpdatingListForReceipt.Add("Write_PaymentCardTransaction");
	NamesOfEventsUpdatingListForReceipt.Add("Write_CashVoucher");
	NamesOfEventsUpdatingListForReceipt.Add("Write_BankAccountIssue");
	
	If NamesOfEventsUpdatingListForReceipt.Find(EventName) <> Undefined Then
		UpdateTotals();
		Items.OrdersPendingGoodsReceipt.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
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
	EndIf;
	
EndProcedure

&AtClient
Procedure BankAccountSelectionOnChange(Item)
	
	BankAccountSelectionOnChangeServer();
	
EndProcedure

&AtServer
Procedure BankAccountSelectionOnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure CounterpartySelection_OnChange(Item)
	
	CounterpartySelection_OnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartySelection_OnChangeServer()
	
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure DateForReceiptOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateToBeReceivedWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DateToBeReceivedWhenChangedOnServer()
	
	SetDynamicListSelection();
	
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
Procedure AuxiliarySelectionList(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	Ref = Item.CurrentData.Ref;
	If ValueIsFilled(Ref) Then
		ShowValue(, Ref);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateReceiptByReference(Command)
	
	CashClient.PayChartLines(Items.OrdersPendingGoodsReceipt, "BankAccountReceiptNote");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.OrdersPendingGoodsReceiptPaymentDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OrdersPendingGoodsReceipt.PaymentDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Less;
	ItemFilter.RightValue = BegOfDay(CurrentSessionDate());
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	VisibilityOfElements = New Map;
	
	ItemArray = New Array;
	ItemArray.Add("OrdersPendingGoodsReceiptCurrency");
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleCurrencies"));
	
	ItemArray = New Array;
	ItemArray.Add("BankAccountSelection");
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleBankAccounts"));
	
	ItemArray = New Array;
	ItemArray.Add("CompanyFilter");
	VisibilityOfElements.Insert(ItemArray, GetFunctionalOption("UseMultipleCompanies"));
	
	For Each MapItem In VisibilityOfElements Do
		For Each TagName In MapItem.Key Do
			Items[TagName].Visible = MapItem.Value;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeBankingDetails()
	
	If Not GetFunctionalOption("UseMultipleBankAccounts") Then
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
		BankAccountSelection = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
	EndIf;
	
	FiltersDetails = New Map;
	FiltersDetails.Insert("Organization", Type("CatalogRef.Companies"));
	AccessManagement.SetDynamicListFilters(OrdersPendingGoodsReceipt, FiltersDetails);
	
	InitializeListOfReceiptOperations();
	
EndProcedure

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
Procedure SetDynamicListSelection()
	
	AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccountSelection);
	
	If ValueIsFilled(BankAccountSelection) Then
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
			Items.LabelBankAccount.Title =
				StrTemplate(NStr("vi = 'Tài khoản ngân hàng %1, %2';
								|ru = 'Банковский счет %1, %2';
								|en = 'Bank account %1, %2'; fa = 'Bank account %1, %2';
								|it = 'Conto corrente %1, %2';
								|pl = 'Rachunek bankowy %1, %2';
								|tr = 'Banka hesabı %1, %2'"), String(AccountAttributes.Currency), TrimAll(BankAccountSelection));
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
		Items.LabelBankAccount.Title = NStr("vi = '<Chưa chỉ ra tài khoản ngân hàng>';
											|ru = '<Банковский счет не задан>';
											|en = '<Bank account is not set>'; fa = '<Bank account is not set>';
											|it = '<Conto corrente non impostato>';
											|pl = '<Rachunek bankowy nie jest określony>';
											|tr = '<Banka hesabı ayarlanmadı>'");
		Items.BankAccountSelection.ChoiceParameterLinks = New FixedArray(New Array);
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
	
	CommonClientServer.SetDynamicListFilterItem(
		OrdersPendingGoodsReceipt,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(Organization));
		
	CommonClientServer.SetDynamicListFilterItem(
		OrdersPendingGoodsReceipt,
		"BankAccount",
		AccountList,
		DataCompositionComparisonType.InList,,
		ValueIsFilled(BankAccountSelection));
		
	CommonClientServer.SetDynamicListFilterItem(
		OrdersPendingGoodsReceipt,
		"CounterpartyPresentation",
		CounterpartyPresentation,
		DataCompositionComparisonType.Contains,,
		ValueIsFilled(CounterpartyPresentation));
		
	Boundary = ?(ValueIsFilled(DateForReceipt), EndOfDay(DateForReceipt), Date('39990101'));
	OrdersPendingGoodsReceipt.Parameters.SetParameterValue("PaymentDate", Boundary);
	
	PlanningAreas = New Array;
	For Each ListItem In TransactionListReceipts Do
		If ListItem.Check Then
			PlanningAreas.Add(ListItem.Value);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListFilterItem(
		OrdersPendingGoodsReceipt,
		"PlanningArea",
		PlanningAreas,
		DataCompositionComparisonType.InList,,
		PlanningAreas.Count());
		
	UpdateTotals();
	
	SaveWorkingValuesOfFormFields();
	
EndProcedure

&AtServer
Procedure UpdateTotals()
	
	UpdateCashBalances();
	UpdateToReceipt();
	
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
Procedure UpdateToReceipt()
	
	If Not ValueIsFilled(BankAccountSelection) Then
		ToReceiveTotal = 0;
		Return;
	EndIf;
	
	DCS = Items.OrdersPendingGoodsReceipt.GetPerformingDataCompositionScheme();
	Settings = Items.OrdersPendingGoodsReceipt.GetPerformingDataCompositionSettings();
	Settings.Structure.Clear();
	
	DetailedRecords = Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField")).Field = New DataCompositionField("AmountToPay");
	TotalField = FinancialReportingServer.NewResource(DCS, "AmountToPay");
	
	DCSResult = FinancialReportingServer.UploadDCSResults(DCS, Settings);
	ToReceiveTotal = DCSResult[0].AmountToPay;
	
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
	
	Common.CommonSettingsStorageSave("CurrentBankAccount", "", ?(SaveUndefined, Undefined, BankAccountSelection));
	
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
	If Item.Name = "sh_ShamsiInput_F_DateForReceipt" Then
		DateForReceiptOnChange(Items.DateForReceipt);
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
