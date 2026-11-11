#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetValuesOfFormAttributes();
	ManagingFormElementsDuringCreation();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DisabledConfigurationRulesAreHidden = Common.FormDataSettingsStorageLoad(
		"Catalog.ActualDataQueryRulesByBudgetFlowItems.ListForm",
		"DisabledConfigurationRulesAreHidden",
		False);
	
	FormControl(ThisObject);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure HideRulesForDisabledSettings(Command)
	
	HideDisabledConfigurationRulesAtServer();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetValuesOfFormAttributes()
	
	SettingUpRulesForAssetLiabilityItems = GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems");
	
EndProcedure

&AtServer
Procedure ManagingFormElementsDuringCreation()
	
	Items.FormHideRulesForDisabledSettings.Visible =
		Catalogs.ActualDataQueryRulesByBudgetFlowItems.ThereAreDisabledRulesForGettingFact();
	
EndProcedure

&AtServer
Procedure HideDisabledConfigurationRulesAtServer()
	
	DisabledConfigurationRulesAreHidden = Not DisabledConfigurationRulesAreHidden;
	
	Common.FormDataSettingsStorageSave(
		"Catalog.ActualDataQueryRulesByBudgetFlowItems.ListForm",
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
	FormControl(ThisObject);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"DisabledConfigurationRulesAreHidden",
		DisabledConfigurationRulesAreHidden);
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	If Form.DisabledConfigurationRulesAreHidden Then
		Form.Items.FormHideRulesForDisabledSettings.Title =
			NStr("vi = 'Hiển thị quy tắc bị tắt';
				|ru = 'Показать отключенные правила';
				|en = 'Show disabled rules'; fa = 'Show disabled rules';
				|it = 'Show disabled rules';
				|pl = 'Show disabled rules';
				|tr = 'Devre dışı bırakılan kuralları göster'");
	Else
		Form.Items.FormHideRulesForDisabledSettings.Title =
			NStr("vi = 'Ẩn quy tắc bị tắt';
				|ru = 'Скрыть отключенные правила';
				|en = 'Hide disabled rules'; fa = 'پنهان کردن قواعد غیرفعال';
				|it = 'Hide disabled rules';
				|pl = 'Hide disabled rules';
				|tr = 'Devre dışı bırakılan kuralları gizle'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance() 
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FinancialAccountingChartOfAccounts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.FinancialAccounting;
	
	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Text", "");
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FinancialAccountingChartOfAccounts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.FinancialAccountingChartOfAccounts");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.RuleType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ThisIsItemOfAssetsLiabilities");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpRulesForAssetLiabilityItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.DataSourceSection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.RuleType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ThisIsSettingUpBusinessOfOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SettingUpRulesForAssetLiabilityItems");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.GrayTextColor1);
	
	//
	
EndProcedure

#EndRegion