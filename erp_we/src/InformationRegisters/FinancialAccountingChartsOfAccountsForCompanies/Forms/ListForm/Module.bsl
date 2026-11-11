
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Filter.Property("PostingGenerationSetting") Then
		Items.PostingGenerationSetting.Visible = False;
	EndIf;
	If Parameters.Filter.Property("Organization") Then
		Items.Organization.Visible = False;
	EndIf;
	
	ChartOfAccounts = Parameters.ChartOfAccounts;
	If Parameters.Filter.Property("ChartOfAccounts") And ValueIsFilled(Parameters.Filter.ChartOfAccounts) Then
		ChartOfAccounts = Parameters.Filter.ChartOfAccounts;
		Parameters.Filter.Delete("ChartOfAccounts");
		Items.ChartOfAccountsSelection.Visible = False;
		Items.ChartOfAccounts.Visible = False;
	EndIf;
	If Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.DefaultChartOfAccounts();
	EndIf;
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts, , , ValueIsFilled(ChartOfAccounts));
	
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	Notify("ClosedListForms_PlansOfAccountsForInternationalAccountingOfOrganizations", , ThisObject);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ChartOfAccountsSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ChartOfAccounts", ChartOfAccounts, , , ValueIsFilled(ChartOfAccounts));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();
	
	FormField = Items.PostingGenerationSetting; // FormField - 
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormField.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.PostingGenerationSetting");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.FinancialAccountingPostingGenerationSetting.EmptyRef();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không sử dụng ';
													|ru = 'Не используется';
													|en = 'Not used'; fa = 'استفاده نمی‌شود';
													|it = 'Non viene utilizzato';
													|pl = 'Nie używane';
													|tr = 'Kullanılmaz'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#EndRegion
