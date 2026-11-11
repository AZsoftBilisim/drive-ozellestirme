#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CheckResult = GetFromTempStorage(Parameters.AddressValidationResult);
	
	BusinessTransactionsWithoutRecordingRules.Load(CheckResult.BusinessTransactionsWithoutRecordingRules);
	AccountsWithoutRecordingRules.Load(CheckResult.AccountsWithoutRecordingRules);
	AccountingObjectsThatRequireConfiguration.Load(CheckResult.AccountingObjectsThatRequireConfiguration);
	
	Organization = Parameters.Organization;
	Document = Parameters.Document;
	ChartOfAccounts = Parameters.ChartOfAccounts;
	
	SetFormItemsVisibility();
	
EndProcedure



#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure BusinessTransactionsWithoutRecordingRulesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = BusinessTransactionsWithoutRecordingRules.FindByID(RowSelected);
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.PostingGenerationSetting = CurrentData.PostingGenerationSetting;
	FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(
		FormParameters, ThisObject, CurrentData.BusinessOperation);
	
EndProcedure

&AtClient
Procedure AccountsWithoutRecordingRulesSelection(Item, RowSelected, Field, StandardProcessing)
	
	SetUpInvoiceMatching(RowSelected);
	
EndProcedure

&AtClient
Procedure AccountingObjectsThatRequireConfigurationSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = AccountingObjectsThatRequireConfiguration.FindByID(RowSelected);
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = CurrentData.ChartOfAccounts;
	FormParameters.PostingGenerationSetting = CurrentData.PostingGenerationSetting;
	FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(
		FormParameters, ThisObject, CurrentData.AccountingObject, CurrentData.SettingObject1);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpATransactionTemplate(Command)
	
	CurrentData = Items.BusinessTransactionsWithoutRecordingRules.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = CurrentData.ChartOfAccounts;
	FormParameters.PostingGenerationSetting = CurrentData.PostingGenerationSetting;
	FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(
		FormParameters, ThisObject, CurrentData.BusinessOperation);
	
EndProcedure

&AtClient
Procedure SetUpInvoiceMatching(Command)
	
	CurrentData = Items.AccountsWithoutRecordingRules.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = CurrentData.ChartOfAccounts;
	FormParameters.PostingGenerationSetting = CurrentData.PostingGenerationSetting;
	
	FinancialAccountingUponLocalAccountingClient.OpenAccountsAndTurnoverMatchingSettings(
		FormParameters, ThisForm, CurrentData.Account);
	
EndProcedure

&AtClient
Procedure ConfigureInvoicesForAccountingObjects(Command)

	CurrentData = Items.AccountingObjectsThatRequireConfiguration.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.Organization = Organization;
	FormParameters.ChartOfAccounts = CurrentData.ChartOfAccounts;
	FormParameters.PostingGenerationSetting = CurrentData.PostingGenerationSetting;
	FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(
		FormParameters, ThisObject, CurrentData.AccountingObject, CurrentData.SettingObject1);
		
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	CheckServerRulesSettings();
	
EndProcedure

&AtClient
Procedure RecordTheDocumentInInternationalAccounting(Command)
	
	CloseParameter = New Structure;
	CloseParameter.Insert("RecordTheDocumentInInternationalAccounting", True);
	Close(CloseParameter);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountingObjectsThatRequireConfigurationSettingObject1.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("AccountingObjectsThatRequireConfiguration.SettingObject1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa chỉ ra>';
													|ru = '<Не указан>';
													|en = '<Not specified>'; fa = '<مشخص نشده>';
													|it = '<non specificato>';
													|pl = '<Nie określono>';
													|tr = '<Belirtilmedi>'"));
	
	//
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.PageBusinessTransactionWithoutTheRulesOfReflection.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khuôn mẫu bút toán (%1)';
				|ru = 'Шаблоны проводок (%1)';
				|en = 'Posting templates (%1)'; fa = 'Posting templates (%1)';
				|it = 'Moduli di registrazione voci (%1)';
				|pl = 'Szablony dekretowania (%1)';
				|tr = 'Kayıt şablonu (%1)'"), 
			BusinessTransactionsWithoutRecordingRules.Count());
	
	Items.InvoicePageWithoutReflectionRules.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tài khoản kế toán quốc tế tương ứng (%1)';
				|ru = 'Соответствующие счета международного учета (%1)';
				|en = 'Corresponding financial accounting accounts (%1)'; fa = 'Corresponding financial accounting accounts (%1)';
				|it = 'Conti corrispondenti della contabilità internazionale%1)';
				|pl = 'Odpowiednie rachunki międzynarodowej rachunkowości (%1)';
				|tr = 'İlgili uluslararası muhasebe hesapları (%1)'"), 
			AccountsWithoutRecordingRules.Count());
	
	Items.AccountingObjectsPage.Title =
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối tượng hạch toán (%1)';
				|ru = 'Объекты учета (%1)';
				|en = 'Accounting objects (%1)'; fa = 'Accounting objects (%1)';
				|it = 'Oggetti di contabilità (%1)';
				|pl = 'Obiekty ewidencji (%1)';
				|tr = 'Muhasebe nesnesi (%1)'"), 
			AccountingObjectsThatRequireConfiguration.Count());
			
	Items.PageBusinessTransactionWithoutTheRulesOfReflection.Visible = BusinessTransactionsWithoutRecordingRules.Count() > 0;
	Items.InvoicePageWithoutReflectionRules.Visible = AccountsWithoutRecordingRules.Count() > 0;
	Items.AccountingObjectsPage.Visible = AccountingObjectsThatRequireConfiguration.Count() > 0;
	Items.PageAllReflectionRulesAreConfigured.Visible = 
		(BusinessTransactionsWithoutRecordingRules.Count() = 0)
		And (AccountsWithoutRecordingRules.Count() = 0)
		And (AccountingObjectsThatRequireConfiguration.Count() = 0);
	
	VisiblePages = New Array;
	For Each Page In Items.Pages.ChildItems Do
		If Page.Visible Then
			VisiblePages.Add(Page);
		EndIf;
	EndDo;
	
	Items.Pages.PagesRepresentation = 
		?(VisiblePages.Count() = 1, FormPagesRepresentation.None, FormPagesRepresentation.TabsOnTop);
	
	Items.RecordTheDocumentInInternationalAccounting.Visible = ValueIsFilled(Document);
	
EndProcedure

&AtServer
Procedure CheckServerRulesSettings()
	
	CheckParameters = DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCheckingReflectionRules();
	If ValueIsFilled(ChartOfAccounts) Then
		CheckParameters.ChartOfAccounts = ChartOfAccounts;
	EndIf;
	If ValueIsFilled(Organization) Then
		CheckParameters.Organization = Organization;
	EndIf;
	If ValueIsFilled(Document) Then
		CheckParameters.Document = Document;
	EndIf;
	CheckResult = DataProcessors.DocumentPostingInFinancialAccounting.CheckAccountingRulesSettings(CheckParameters);
	
	BusinessTransactionsWithoutRecordingRules.Load(CheckResult.BusinessTransactionsWithoutRecordingRules);
	AccountsWithoutRecordingRules.Load(CheckResult.AccountsWithoutRecordingRules);
	AccountingObjectsThatRequireConfiguration.Load(CheckResult.AccountingObjectsThatRequireConfiguration);
	
	SetFormItemsVisibility();
	
EndProcedure

#EndRegion