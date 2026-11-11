
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TheAccountPlansSelectedInTheReport.LoadValues(Parameters.SelectedAccountPlans);
	If Parameters.Property("AccountPlansUsed") Then
		AccountPlansUsedInTheReport.LoadValues(Parameters.AccountPlansUsed);
	EndIf;
	
	CreateFormDetails();
	CreateFormElements_();
	
	For Each TableRow In ApplicableAccountPlans Do
		If TheAccountPlansSelectedInTheReport.FindByValue(TableRow.Ref) <> Undefined Then
			ThisObject[TableRow.AttributeName] = True;
		EndIf;
	EndDo;
	
	SetItemsAvailability();
	
	If AccountPlansUsedInTheReport.Count() = 1 Then
		
		Items.DecorationUsedInTheAccountPlansReport.Title =
			StrTemplate(NStr("vi = 'Trong báo cáo có sử dụng các chỉ tiêu của hệ thống tài khoản %1';
							|ru = 'В отчете используются показатели плана счетов %1';
							|en = 'The report uses key indicators from the chart of accounts %1'; fa = 'The report uses key indicators from the chart of accounts %1';
							|it = 'Nel report sono utilizzati indicatori del piano dei conti %1';
							|pl = 'W raporcie są używane wskaźniki planu kont %1';
							|tr = 'Raporda hesap planı göstergeleri kullanılıyor%1'"),
			          AccountPlansUsedInTheReport[0].Value);
		Items.GroupOfAccountPlansUsedInTheReport.Visible = True;
		
	ElsIf AccountPlansUsedInTheReport.Count() > 1 Then
		
		LineOfAccountPlans = StrConcat(AccountPlansUsedInTheReport.UnloadValues(), ",");
		
		Items.DecorationUsedInTheAccountPlansReport.Title =
			StrTemplate(NStr("vi = 'Trong báo cáo có sử dụng các chỉ tiêu của hệ thống tài khoản %1';
							|ru = 'В отчете используются показатели планов счетов %1';
							|en = 'The report uses key indicators from the charts of accounts %1'; fa = 'The report uses key indicators from the charts of accounts %1';
							|it = 'Nel report sono utilizzati indicatori dei piani dei conti %1';
							|pl = 'W raporcie są używane wskaźniki planów kont %1';
							|tr = 'Raporda hesap planları göstergeleri kullanılıyor%1'"), LineOfAccountPlans);
		Items.GroupOfAccountPlansUsedInTheReport.Visible = True;
	Else
		
		Items.GroupOfAccountPlansUsedInTheReport.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Result = New Array;
	For Each TableRow In ApplicableAccountPlans Do
		If ThisObject[TableRow.AttributeName] Then
			Result.Add(TableRow.Ref);
		EndIf;
	EndDo;
	
	NotifyChoice(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CreateFormDetails()
	
	AttributesToBeAdded = New Array();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	FinancialAccountingChartsOfAccounts.Ref AS Ref,
	|	FinancialAccountingChartsOfAccounts.Description AS Description,
	|	FinancialAccountingChartsOfAccounts.AccountingInFunctionalCurrency AS AccountingInFunctionalCurrency,
	|	FinancialAccountingChartsOfAccounts.PresentationCurrency AS PresentationCurrency
	|FROM
	|	Catalog.FinancialAccountingChartsOfAccounts AS FinancialAccountingChartsOfAccounts
	|WHERE
	|	NOT FinancialAccountingChartsOfAccounts.DeletionMark
	|		OR FinancialAccountingChartsOfAccounts.Ref IN (&TheAccountPlansSelectedInTheReport)";
	Query.SetParameter("TheAccountPlansSelectedInTheReport", TheAccountPlansSelectedInTheReport);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		AttributeName = "ChartOfAccounts" + StrReplace(String(New UUID()), "-", "");
		
		NewTableRow = ApplicableAccountPlans.Add();
		FillPropertyValues(NewTableRow, Selection);
		NewTableRow.AttributeName = AttributeName;
		
		NewAttribute = New FormAttribute(AttributeName, New TypeDescription("Boolean") , "", Selection.Description);
		AttributesToBeAdded.Add(NewAttribute);
		
	EndDo;
	
	LocalAccountingSettings = LocalAccntingServer.AccountingSettings();
	If LocalAccountingSettings.UseLocal Then
		
		TypeChartOfAccountsLocal = LocalAccntingClientServer.TypeChartOfAccounts();
		LocalChartOfAccountsName = LocalAccntingClientServer.ChartOfAccountsName();
		
		AttributeName = "ChartOfAccounts" + StrReplace(String(New UUID()), "-", "");
		PropsHeader = ChartsOfAccounts[LocalChartOfAccountsName].PresentationInFinancialStatements();
		
		NewTableRow = ApplicableAccountPlans.Add();
		NewTableRow.Ref = Common.MetadataObjectID(TypeChartOfAccountsLocal);
		NewTableRow.AttributeName = AttributeName;
		NewTableRow.Description = PropsHeader;
		NewTableRow.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal;
		If LocalAccountingSettings.AdditionallyManagementAccountingIsConducted Then
			NewTableRow.CurrencyOfManagementAccountingOnTheChartOfAccounts = Constants.ManagementAccountingCurrency.Get();
		EndIf;
		If LocalAccountingSettings.AdditionallyAccountingIsCarriedOutInCurrencyOfFinancialStatements Then
			NewTableRow.FinancialReportingCurrency = LocalAccountingSettings.FinReportingCurrency;
		EndIf;
		
		NewAttribute = New FormAttribute(AttributeName, New TypeDescription("Boolean") , "", PropsHeader);
		AttributesToBeAdded.Add(NewAttribute);
		
	EndIf;
	
	ThisObject.ChangeAttributes(AttributesToBeAdded);
	
EndProcedure

&AtServer
Procedure CreateFormElements_()
	
	For Each TableRow In ApplicableAccountPlans Do
		
		NewItem = ThisObject.Items.Add(
							TableRow.AttributeName,
							Type("FormField"),
							Items.ChartsOfAccountsGroup);
		NewItem.Type = FormFieldType.CheckBoxField;
		NewItem.DataPath = TableRow.AttributeName;
		NewItem.TitleLocation = FormItemTitleLocation.Right;
		
		ArrayOfCurrencyInformation = New Array;
		If TableRow.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
			ArrayOfCurrencyInformation.Add(NStr("vi = 'Tiền tệ chức năng: tiền tệ kế toán pháp quy của doanh nghiệp';
												|ru = 'Функциональная валюта: валюта регл. учета организации';
												|en = 'Functional currency: company local accounting currency'; fa = 'Functional currency: company local accounting currency';
												|it = 'Valuta funzionale: valuta della contabilità regolatoria dell''azienda';
												|pl = 'Waluta funkcjonalna: waluta ewidencji reglamentowanej firmy';
												|tr = 'Fonksiyonel para birimi: iş yerinin yerel hesap para birimi'"));
		Else
			ArrayOfCurrencyInformation.Add(StrTemplate(NStr("vi = 'Tiền tệ chức năng: %1';
															|ru = 'Функциональная валюта: %1';
															|en = 'Functional currency: %1'; fa = 'Functional currency: %1';
															|it = 'Valuta funzionale: %1';
															|pl = 'Waluta funkcjonalna: %1';
															|tr = 'Fonksiyonel para birimi: %1'"), SettingsValueCached.ManagementAccountingCurrency()));
		EndIf;
		
		If ValueIsFilled(TableRow.PresentationCurrency) Then
			ArrayOfCurrencyInformation.Add(StrTemplate(NStr("vi = 'Tiền tệ trình bày: %1';
															|ru = 'Валюта представления: %1';
															|en = 'Presentation currency: %1'; fa = 'Presentation currency: %1';
															|it = 'Valuta di presentazione: %1';
															|pl = 'Waluta prezentacji: %1';
															|tr = 'Sunum para birimi: %1'"), TableRow.PresentationCurrency));
		EndIf;
		
		If ValueIsFilled(TableRow.CurrencyOfManagementAccountingOnTheChartOfAccounts) Then
			ArrayOfCurrencyInformation.Add(StrTemplate(NStr("vi = 'Tiền tệ kế toán quản trị: %1';
															|ru = 'Валюта  упр. учета: %1';
															|en = 'Management accounting currency: %1'; fa = 'Management accounting currency: %1';
															|it = 'Valuta della contabilità di gestione: %1';
															|pl = 'Waluta ewidencji zarządczej: %1';
															|tr = 'Yönetim hesap para birimi: %1'"), TableRow.CurrencyOfManagementAccountingOnTheChartOfAccounts));
		EndIf;
		
		If ValueIsFilled(TableRow.FinancialReportingCurrency) Then
			ArrayOfCurrencyInformation.Add(StrTemplate(NStr("vi = 'Tiền tệ trong báo cáo tài chính: %1';
															|ru = 'Валюта фин. отчетности: %1';
															|en = 'Financial reporting currency: %1'; fa = 'Financial reporting currency: %1';
															|it = 'Valuta della rendicontazione finanziaria: %1';
															|pl = 'Waluta rachunkowości finansowej: %1';
															|tr = 'Finansal raporlama para birimi: %1'"), TableRow.FinancialReportingCurrency));
		EndIf;
		
		NewItem.ToolTip = StrConcat(ArrayOfCurrencyInformation, ",");
		NewItem.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetItemsAvailability()
	
	For Each TableRow In ApplicableAccountPlans Do
		
		FormField = Items[TableRow.AttributeName]; // FormField - 
		
		FlagAvailability_ = True;
		
		If AccountPlansUsedInTheReport.FindByValue(TableRow.Ref) <> Undefined Then
			FlagAvailability_ = False;
		EndIf;
		
		FormField.Enabled = FlagAvailability_;
		
	EndDo;
	
EndProcedure

#EndRegion