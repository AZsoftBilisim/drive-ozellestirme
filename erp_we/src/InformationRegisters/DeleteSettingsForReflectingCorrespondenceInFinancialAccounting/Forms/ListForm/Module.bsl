#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("SourceRecordKey") Then
		Items.List.CurrentRow = Parameters.SourceRecordKey;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IncreaseTheOrderOfApplyingTheSetting(Command)
	
	If Items.List.CurrentRow <> Undefined Then
		IncreaseTheOrderOfApplyingTheSettingServer();
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure ReduceTheOrderInWhichTheSettingIsApplied(Command)
	
	If Items.List.CurrentRow <> Undefined Then
		ReduceTheOrderInWhichTheSettingIsAppliedServer();
		Items.List.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplySubsequentSettings.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ApplySubsequentSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không áp dụng';
													|ru = 'Не применять';
													|en = 'Do not apply'; fa = 'عدم اعمال';
													|it = 'Не применять';
													|pl = 'Nie stosować';
													|tr = 'Uygulanmasın'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ApplySubsequentSettings.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ApplySubsequentSettings");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Áp dụng';
													|ru = 'Применять';
													|en = 'Apply'; fa = 'اعمال';
													|it = 'Применять';
													|pl = 'Zastosuj';
													|tr = 'Uygula'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GLAccountDr.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GLAccountCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ItIsNotReflectedInTheAccounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không phản ánh>';
													|ru = '<не отражается>';
													|en = '<not recorded>'; fa = '<not recorded>';
													|it = '<не отражается>';
													|pl = '<nie wyświetla się>';
													|tr = '<yansıtılmıyor>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GLAccountDr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.LedgerAccountIsDeterminedByAccountingObjectSetupDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<не изменен>';
													|en = '<not changed>'; fa = '<not changed>';
													|it = '<не изменен>';
													|pl = '<nie zmieniony>';
													|tr = '<değiştirilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GLAccountCr.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.LedgerAccountIsDeterminedByAccountingObjectSetupCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thay đổi>';
													|ru = '<не изменен>';
													|en = '<not changed>'; fa = '<not changed>';
													|it = '<не изменен>';
													|pl = '<nie zmieniony>';
													|tr = '<değiştirilmedi>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

&AtServer
Procedure IncreaseTheOrderOfApplyingTheSettingServer()
	NewRecordKey = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ChangeOrderInWhichSettingsAreApplied(
		Items.List.CurrentRow, 1);
	Items.List.Refresh();
	Items.List.CurrentRow = NewRecordKey;
EndProcedure

&AtServer
Procedure ReduceTheOrderInWhichTheSettingIsAppliedServer()
	NewRecordKey = InformationRegisters.DeleteSettingsForReflectingCorrespondenceInFinancialAccounting.ChangeOrderInWhichSettingsAreApplied(
		Items.List.CurrentRow, -1);
	Items.List.Refresh();
	Items.List.CurrentRow = NewRecordKey;
EndProcedure


#EndRegion