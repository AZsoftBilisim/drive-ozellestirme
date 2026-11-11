
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not Parameters.Property("FinancialAccountingGroup") Then
	    MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẩu này';
							|ru = 'Непосредственное открытие этой формы не предусмотрено';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane';
							|tr = 'Bu formun doğrudan açılması sağlanamadı'");
	    Raise MessageText;
	EndIf;
	
	FinancialAccountingGroup = Parameters.FinancialAccountingGroup;
	ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	
	ShowAccountingInvoices();
	
	SetAvailabilityVisibilityOfItemsOnServer();
	
EndProcedure

&AtClient
Procedure OnClose()
	
	Notify("AccountRefinementSettingsChanged");
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	ArrayOfSelectedRows = Items.PostingTemplates.SelectedRows;
	If ArrayOfSelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	If ValueIsFilled(ValueSelected) Then
		FillInAccountingInvoices(ArrayOfSelectedRows, ValueSelected);		
	EndIf;	
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ChartOfAccountsOnChange(Item)
	ShowAccountingInvoices();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure PostingTemplatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.PostingTemplatesPostingTemplate Then
		CurrentData = PostingTemplates.FindByID(RowSelected);
		FormParameters = New Structure("Key", CurrentData.PostingTemplate);
		OpenForm("Catalog.PostingTemplatesForFinancialAccounting.ObjectForm", FormParameters, ThisForm);
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	ArrayOfSelectedRows = Items.PostingTemplates.SelectedRows;
	If ArrayOfSelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("ChartOfAccounts", ChartOfAccounts));
	OpenForm("ChartOfAccounts.International.ChoiceForm", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	RecordAccountingAccounts();
	Close(True);
	
EndProcedure



&AtClient
Procedure Write(Command)
	
	RecordAccountingAccounts();
	Modified = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesRecordType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.RecordType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AccountingMovementKinds.Debit;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.DebitTextColor);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Nợ';
													|ru = 'Дт';
													|en = 'Dr'; fa = 'بد';
													|it = 'Debito';
													|pl = 'Wn';
													|tr = 'Borç'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesRecordType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.RecordType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AccountingMovementKinds.Credit;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.CreditTextColor);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Right);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có';
													|ru = 'Кт';
													|en = 'Cr'; fa = 'بس';
													|it = 'Credito';
													|pl = 'Ma';
													|tr = 'Alacak'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesDefaultAccount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesDefaultAccountDescription.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesPostingTemplate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesRecordType.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesGLAccount.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesGLAccountDescription.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Enabled", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PostingTemplatesGLAccount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PostingTemplates.GLAccount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tài khoản mặc định>';
													|ru = '<Счет по умолчанию>';
													|en = '<Default account>'; fa = '<حساب پیش‌فرض>';
													|it = '<Conto di default>';
													|pl = '<Domyślne konto>';
													|tr = '<Varsayılan hesap>'"));

EndProcedure

&AtServer
Procedure ShowAccountingInvoices()
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		PostingTemplates.GetItems().Clear();
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	RulesForClarifyingInvoices.PostingTemplate AS PostingTemplate,
	|	RulesForClarifyingInvoices.RecordType AS RecordType,
	|	RulesForClarifyingInvoices.GLAccount AS GLAccount
	|INTO BillingRules
	|FROM
	|	InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RulesForClarifyingInvoices
	|WHERE
	|	RulesForClarifyingInvoices.FinancialAccountingGroup = &FinancialAccountingGroup
	|	AND RulesForClarifyingInvoices.PostingTemplate.ChartOfAccounts = &ChartOfAccounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PostingTemplates.Ref AS PostingTemplate,
	|	VALUE(Enum.AccountingMovementKinds.Debit) AS RecordType,
	|	PostingTemplates.DrAccountDefault AS DefaultAccount,
	|	BillingRules.GLAccount AS GLAccount
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|	LEFT JOIN
	|		BillingRules AS BillingRules
	|	ON
	|		(BillingRules.PostingTemplate = PostingTemplates.Ref)
	|		AND (BillingRules.RecordType = VALUE(Enum.AccountingMovementKinds.Debit))
	|WHERE
	|	PostingTemplates.AccountSpecificationSourceTypeDr IN (&AccountSpecificationSourceTypes)
	|	AND PostingTemplates.ChartOfAccounts = &ChartOfAccounts
	|
	|UNION ALL
	|
	|SELECT
	|	PostingTemplates.Ref,
	|	VALUE(Enum.AccountingMovementKinds.Credit),
	|	PostingTemplates.CrAccountDefault,
	|	BillingRules.GLAccount
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|	LEFT JOIN
	|		BillingRules AS BillingRules
	|	ON 
	|		(BillingRules.PostingTemplate = PostingTemplates.Ref)
	|		AND (BillingRules.RecordType = VALUE(Enum.AccountingMovementKinds.Credit))
	|WHERE
	|	PostingTemplates.AccountSpecificationSourceTypeCr IN (&AccountSpecificationSourceTypes)
	|	AND PostingTemplates.ChartOfAccounts = &ChartOfAccounts
	|
	|TOTALS BY
	|	DefaultAccount";
	
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Query.SetParameter("FinancialAccountingGroup", FinancialAccountingGroup);
	Query.SetParameter("AccountSpecificationSourceTypes", FinancialAccountingClientServer.AccountSpecificationSourceTypes(FinancialAccountingGroup));
	
	AccountTree = Query.Execute().Unload(QueryResultIteration.ByGroups);
	ValueToFormAttribute(AccountTree, "PostingTemplates");
	
EndProcedure

&AtServer
Procedure RecordAccountingAccounts()

	RecordSet = InformationRegisters.RulesOfSpecifyingAccountsFinancialAccounting.CreateRecordSet();
	RecordSet.Filter.FinancialAccountingGroup.Set(FinancialAccountingGroup);
	DefaultAccounts = PostingTemplates.GetItems();
	For Each  String In DefaultAccounts Do
		PostingTemplatesByAccount = String.GetItems();
		For Each PostingTemplate In PostingTemplatesByAccount Do
			If ValueIsFilled(PostingTemplate.GLAccount) Then
	 			NewRecord	= RecordSet.Add();
				FillPropertyValues(NewRecord, PostingTemplate);
				NewRecord.FinancialAccountingGroup = FinancialAccountingGroup;
			EndIf;
		EndDo;
	EndDo;
	RecordSet.Write();

EndProcedure

&AtClient
Procedure FillInAccountingInvoices(ArrayOfSelectedRows, GLAccount)

	For Each RowID In ArrayOfSelectedRows Do
		FoundRow = PostingTemplates.FindByID(RowID);
		If ValueIsFilled(FoundRow.PostingTemplate) Then
			FoundRow.GLAccount = GLAccount;
		EndIf;	
	EndDo;

EndProcedure

&AtServer
Procedure SetAvailabilityVisibilityOfItemsOnServer()

	ChangingMFPSettingsIsAvailable = FinancialAccountingOfGeneralPurpose.InternationalAccountingSettingsCanBeChanged();
	
	ItemArray = New Array;
	ItemArray.Add("FormWriteAndClose");
	ItemArray.Add("FormWrite");
	ItemArray.Add("PostingTemplates");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not ChangingMFPSettingsIsAvailable);
	
	ItemArray = New Array;
	ItemArray.Add("PostingTemplatesChangeSelectedItems");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", ChangingMFPSettingsIsAvailable);

EndProcedure

#EndRegion
