#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ProcessPassedParameters();
	SetValuesOfFormAttributes();
	ManagingFormElementsDuringCreation();
	
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

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RulesTypeOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	OpeningParameters = New Structure;
	If Copy Then
		OpeningParameters.Insert("CopyingValue", Items.List.CurrentData.Ref);
	Else
		OpeningParameters.Insert("FillingValues", New Structure("BudgetFlowItem, RuleType", BudgetFlowItem, RulesType));
	EndIf;
	OpenForm("Catalog.ActualDataQueryRulesByBudgetFlowItems.Form.ObjectForm", OpeningParameters, ThisObject,,,,,
																		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	ActualDataQueryRulesByBudgetFlowItems.Ref AS Ref,
		|	ActualDataQueryRulesByBudgetFlowItems.SettingsComposer AS SettingsComposer
		|FROM
		|	Catalog.ActualDataQueryRulesByBudgetFlowItems AS ActualDataQueryRulesByBudgetFlowItems
		|WHERE
		|	ActualDataQueryRulesByBudgetFlowItems.Ref IN(&Rules)";
	
	Query.SetParameter("Rules", Rows.GetKeys());
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	CustomizingByRule = New Map();
	While SelectionDetailRecords.Next() Do
		SettingsStorage = SelectionDetailRecords.SettingsComposer; // ValueStorage
		CustomizingByRule.Insert(SelectionDetailRecords.Ref, SettingsStorage.Get());
	EndDo;
	
	MessageTemplate = NStr("vi = 'Lỗi khi đọc tùy chỉnh theo quy tắc %1';
							|ru = 'Ошибка при чтении настроек по правилу %1';
							|en = 'An error occurred when reading settings by the rule %1'; fa = 'An error occurred when reading settings by the rule %1';
							|it = 'Errore durante la lettura delle impostazioni della regola %1';
							|pl = 'Błąd podczas wczytywania ustawień według reguły %1';
							|tr = 'Ayarların %1 kuralına göre okunmasında hata meydana geldi'");
	
	ReceiptOfFactByCorrespondenceOfRegisters = GetFunctionalOption("SettingUpRulesForObtainingFactsFromCorrespondingRegisters");
	
	For Each String In Rows Do
		If String.Value.Data.DataSourceSection <> Enums.SectionsOfBudgetingDataSources.OperationalAccounting Then
			CorrespondencesTable = Undefined;
		ElsIf ReceiptOfFactByCorrespondenceOfRegisters
			And DataSourcesServer.ThisIsSettingUpBusinessOfOperation(String.Value.Data.DataSource) Then
			CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(String.Value.Data.DataSource);
		Else
			CorrespondencesTable = Undefined;
		EndIf;
		DCSByRule = DataSourcesServer.DataLayoutRules(String.Key, , , , CorrespondencesTable);
		If DCSByRule <> Undefined Then
			Try
				SettingsComposer = New DataCompositionSettingsComposer;
				SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DCSByRule));

				AdditionalSelection = CustomizingByRule.Get(String.Key);
				If AdditionalSelection <> Undefined Then
					SettingsComposer.LoadSettings(AdditionalSelection);
					String.Value.Data.FilterPresentation = String(SettingsComposer.Settings.Filter);
				EndIf;
			Except
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TrimAll(
					String.Key));
				Common.MessageToUser(MessageText, String.Key);
			EndTry;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure HideRulesForDisabledSettings(Command)
	
	HideDisabledConfigurationRulesAtServer();
	
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
Procedure ProcessPassedParameters()
	
	BudgetFlowItem = Parameters.BudgetFlowItem;
	
	CommonClientServer.SetDynamicListFilterItem(List, "BudgetFlowItem", BudgetFlowItem);
	
EndProcedure

&AtServer
Procedure SetValuesOfFormAttributes()
	
	RulesType = Enums.ActualBudgetingDataQueryRuleType.ActualData;
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
	
	If Not ValueIsFilled(Form.RulesType) Then
		CommonClientServer.DeleteDynamicListFilterGroupItems(Form.List, "RuleType");
	Else
		ListOfRuleTypes_ = New ValueList;
		ListOfRuleTypes_.Add(Form.RulesType);
		ListOfRuleTypes_.Add(PredefinedValue(
			"Enum.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData"));
		
		CommonClientServer.SetDynamicListFilterItem(Form.List,
			"RuleType", ListOfRuleTypes_, DataCompositionComparisonType.InList, True);
	EndIf;
	
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
