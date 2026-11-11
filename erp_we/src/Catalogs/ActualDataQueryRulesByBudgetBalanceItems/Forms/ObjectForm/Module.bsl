#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	BudgetIndicatorPresentation = String(Object.BudgetBalanceItem);
	
	SetSignOfUsingItemOfAssetsLiabilities();
	
	If ValueIsFilled(Object.Ref) Then
		CheckIfRuleMatchesSettings();
	Else
		If ValueIsFilled(Parameters.CopyingValue) Then
			StorageSettingsComposer = Common.ObjectAttributeValue(Parameters.CopyingValue, "SettingsComposer");
			SettingsComposer.LoadSettings(StorageSettingsComposer.Get());
		EndIf;
		BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.Settings);
		AddressOfDataCompositionSettings = PutToTempStorage(SettingsComposer.GetSettings(), UUID);
		CompositionSchemaIsValid = CorrectDataLayoutScheme();
	EndIf;
	
	FillInTypesOfAnalytics();
	FillInAnalyticsSettings();
	
	If Not BudgetingServer.InternationalAccountingIsUsed()
		Or Not AccessRight("Read", Object.FinancialAccountingChartOfAccounts.Metadata())
		 Then
		Sections = Items.DataSourceSection.ChoiceList;
		SectionInternationalAccounting = Sections.FindByValue(Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
		If SectionInternationalAccounting <> Undefined Then
			Sections.Delete(SectionInternationalAccounting);
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseLocal") Then
		Sections = Items.DataSourceSection.ChoiceList;
		LocalAccountingSection = Sections.FindByValue(Enums.SectionsOfBudgetingDataSources.LocalAccounting);
		If LocalAccountingSection <> Undefined Then
			Sections.Delete(LocalAccountingSection);
		EndIf;
	EndIf;
	
	If Parameters.Property("IndicatorType", IndicatorType) Then
		ParameterRelationships = New ChoiceParameterLink("Filter.IndicatorType", "IndicatorType");
		ArrayOfLinks = CommonClientServer.ValueInArray(ParameterRelationships);
		Items.BudgetBalanceItem.ChoiceParameterLinks = New FixedArray(ArrayOfLinks);
	Else
		IndicatorType = Common.ObjectAttributeValue(Object.BudgetBalanceItem, "IndicatorType")
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetConditionalAppearance();
	SetAvailabilityOfDataSourceSchema();
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	SavedSettingsComposer = CurrentObject.SettingsComposer.Get();
	BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SavedSettingsComposer);
	AddressOfDataCompositionSettings = PutToTempStorage(SettingsComposer.GetSettings(), UUID);
	CompositionSchemaIsValid = CorrectDataLayoutScheme();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto() Then
		Cancel = True;
		Return;
	EndIf;

	If IndicatorType <> Enums.BudgetBalanceItemType.SpecialPurpose Then
		CurrentObject.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	EndIf;
	
	CurrentObject.SettingsComposer = New ValueStorage(SettingsComposer.GetSettings());
	CurrentObject.FilterPresentation = String(SettingsComposer.Settings.Filter);
	If CurrentObject.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		CurrentObject.DataSourceScheme = New ValueStorage(DataCompositionSchema);
	EndIf;
	
	BudgetingServer.PutAnalyticsFillingSettingsInRule(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BudgetingServer.ProcessingVerificationOfAnalyticsFillingSettings(DimensionPopulationSettings, Cancel, Object.AdvancedModeOfDimensionFillSetting);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyWritingNew(Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataSourceOnChange(Item)
	
	ClearMessages();
	WhenSourceChangesServer();
	
EndProcedure

&AtClient
Procedure DataSourceSectionOnChange(Item)
	
	ClearMessages();
	WhenChangingSourceSectionServer();
	
EndProcedure

&AtClient
Procedure BudgetBalanceItemOnChange(Item)
	
	OnChangesInBudgetIndicatorServer();
	
EndProcedure

&AtClient
Procedure FinancialAccountingChartOfAccountsOnChange(Item)
	
	ClearMessages();
	InternationalAccountingChartOfAccountsWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDimensionPopulationSettings

&AtClient
Procedure AnalyticsFillInSettingsAnalyticsFillInExpressionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	BlankElementField = Undefined;
	If Not ResultOfCheckingWhetherAnalyticsCanBeSelected(BlankElementField) Then
		ClearMessages();
		If BlankElementField = Items.SetUpDataReceiptScheme.Name Then
			MessageText = NStr("vi = 'Sơ đồ thu thập dữ liệu được điền không chính xác';
								|ru = 'Некорректно заполнена схема получения данных';
								|en = 'The data receipt scheme is incorrectly filled'; fa = 'The data receipt scheme is incorrectly filled';
								|it = 'Lo schema ricezione dati non è compilato correttamente';
								|pl = 'Niepoprawnie wypełniono schemat otrzymania danych';
								|tr = 'Veri toplama şeması yanlış doldurulmuş'");
			CommonClient.MessageToUser(MessageText,,,
			                                            "Object");
		Else
			MessageText = NStr("vi = 'Tất cả các chi tiết của nguồn dữ liệu không được chỉ định, không thể chọn phân tích';
								|ru = 'Не указаны все реквизиты источника данных, выбор аналитики невозможен';
								|en = 'All details of the data source are not specified, dimension cannot be selected'; fa = 'All details of the data source are not specified, dimension cannot be selected';
								|it = 'Non sono stati indicati tutti i requisiti della fonte dei dati, impossibile selezionare l''analitica';
								|pl = 'Nie podano wszystkich atrybutów źródła danych, wybór analityki jest niemożliwy';
								|tr = 'Tüm veri kaynak öznitelikleri belirtilmemiş, boyut seçimi yapılamaz'");
			CommonClient.MessageToUser(MessageText,,
			                                            BlankElementField,
			                                            "Object");
		EndIf;
		Return;
	EndIf;
	CurrentData = Items.DimensionPopulationSettings.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("DimensionKind",               CurrentData.DimensionKind);
	FormParameters.Insert("AddressOfDataCompositionSchema", AddressOfDataCompositionSchema);
	FormParameters.Insert("DataSourceSection",      Object.DataSourceSection);
	FormParameters.Insert("CurrentExpression",           CurrentData.DimensionPopulationExpression);
	
	OpenForm("CommonForm.SelectDimensionFillingField", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure AnalyticsFillInSettingsAnalyticsFillInExpressionChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.DimensionPopulationSettings.CurrentData;
	CurrentData.DimensionPopulationExpression = ValueSelected;
	
	ExpressionFillingAnalyticsSelectionProcessingServer(CurrentData.GetID());
	Modified = True;
	Items.DimensionPopulationSettings.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure AnalyticsFillInSettingsAnalyticsFillInExpressionClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure DimensionPopulationSettingsOnActivateRow(Item)
	
	FormSelectionParameters = New Array;
	
	CurrentData = Items.DimensionPopulationSettings.CurrentData;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.AdditionalProperty) Then
		NewChoiceParameter = New ChoiceParameter("Filter.Owner", CurrentData.AdditionalProperty);
		FormSelectionParameters.Add(NewChoiceParameter);
	EndIf;
	
	Items.DimensionPopulationSettingsDimensionValue.ChoiceParameters = New FixedArray(FormSelectionParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetUpDataReceiptScheme(Command)
	
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Cài đặt lược đồ dữ liệu tùy chỉnh';
													|ru = 'Настройки схемы получения произвольных данных';
													|en = 'Settings of arbitrary data receipt scheme'; fa = 'Settings of arbitrary data receipt scheme';
													|it = 'Impostazioni per la ricezione di dati arbitrari';
													|pl = 'Ustawienia schematu pobierania dowolnych danych';
													|tr = 'Yapay veri toplanma şeması ayarları'");
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfDataCompositionSchema",            AddressOfDataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings",         AddressOfDataCompositionSettings);
	FormParameters.Insert("Title",                             HeaderOfDataLayoutSchemaConfigurationForm);
	FormParameters.Insert("UUID",               UUID);
	FormParameters.Insert("DoNotConfigureConditionalFormatting",       True);
	FormParameters.Insert("DonTAdjustTheOrder",                  True);
	FormParameters.Insert("DoNotConfigureSelection",                    True);
	FormParameters.Insert("DoNotConfigureTheSelection",                    True);
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", False);
	FormParameters.Insert("ProcedureForPlacingTheSettingsInTheDataCompositionSchema", "BudgetingServer.PutSettingsInActualDataAcquisitionScheme");
	FormParameters.Insert("ProcedureForValidatingDataCompositionSchema", "BudgetingServer.CheckingCorrectnessOfSchemeForObtainingActualData");
	FormParameters.Insert("ProcedureForInitializingCompositionSettings", "BudgetingServer.RefillingSettingsWhenChangingLayoutScheme");
	
	CallbackDescription = New CallbackDescription("ChangeDataLayoutScheme", ThisObject);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema", 
		FormParameters, ThisObject, , , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DisableAdvancedSetupModeOfDimensionPopulation(Command)
	
	DisableAdvancedSetupModeOfDimensionPopulationServer();
	
EndProcedure

&AtClient
Procedure EnableAdvancedSetupModeOfDimensionPopulation(Command)
	
	EnableAdvancedConfigurationModeForFillingInAnalyticsServer();
	
EndProcedure

&AtClient
Procedure FillInTheAnalyticsSettingsForTheDataSource(Command)
	
	ClearMessages();
	FillInTheAnalyticsSettingsForTheDataSourceServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Function ResultOfCheckingWhetherAnalyticsCanBeSelected(BlankElementField)
	
	YouCanSelectFillExpression = True;
	If Not ValueIsFilled(Object.BudgetBalanceItem) Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.BudgetBalanceItem.Name;
	ElsIf Not ValueIsFilled(Object.DataSourceSection) Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.DataSourceSection.Name;
	ElsIf Not ValueIsFilled(Object.DataSource) Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.DataSource.Name;
	ElsIf Not ValueIsFilled(Object.DataSource) Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.DataSource.Name;
	ElsIf Object.DataSourceSection =
		PredefinedValue("Enum.SectionsOfBudgetingDataSources.CustomQuery")
		And Not CompositionSchemaIsValid Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.SetUpDataReceiptScheme.Name;
	EndIf;
	
	Return YouCanSelectFillExpression;
	
EndFunction

&AtServer
Function CorrectDataLayoutScheme()
	CompositionSchemaIsValid = False;
	If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
	 Or Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting
	 Or Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting Then
		// The layout scheme is set by the layout from metadata.
	ElsIf Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		CompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		If Not CompositionSchema = Undefined Then
			SelectionAvailableFields = SettingsComposer.Settings.Selection.SelectionAvailableFields;
			For Each AvailableSelectionField In SelectionAvailableFields.Items Do
				If AvailableSelectionField.Folder Then
					Continue; // System fields
				EndIf;
				CompositionSchemaIsValid = True;
			EndDo;
		EndIf;
	EndIf;
	
	Return CompositionSchemaIsValid;
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	BudgetingServer.SetConditionalSettingsForFillingInAnalytics(ConditionalAppearance, "DimensionPopulationSettings");
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfDataSourceSchema()
	
	If Not UserRightsCached.EditArbitraryBudgetingDataSources() Then
		Items.SetUpDataReceiptScheme.Enabled = False;
		Items.SetUpDataReceiptScheme.Title = NStr("vi = 'Không đủ quyền để tùy chỉnh sơ đồ nhận dữ liệu';
													|ru = 'Недостаточно прав для настройки схемы получения данных';
													|en = 'Insufficient rights to set up the data receipt scheme'; fa = 'Insufficient rights to set up the data receipt scheme';
													|it = 'Недостаточно прав для настройки схемы получения данных';
													|pl = 'Insufficient rights to set up the data receipt scheme';
													|tr = 'Veri alma şemasını ayarlamak için yetersiz yetki'");
		Items.SetUpDataReceiptScheme.TextColor = StyleColors.DeniedAccessRightColor;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTypesOfAnalytics()
	
	DimensionKinds = BudgetingServer.DimensionKinds(Object);
	
	FillPropertyValues(ThisObject, DimensionKinds);
	
EndProcedure

&AtClient
Procedure ChangeDataLayoutScheme(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		SettingsComposer.LoadSettings(GetFromTempStorage(Result));
		ChangedDataLayoutSchemeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnChangesInBudgetIndicatorServer()
	
	ArbitraryDataSection = Enums.SectionsOfBudgetingDataSources.CustomQuery;
	LineIndicatorOfBudgets = String(Object.BudgetBalanceItem);
	If Object.DataSourceSection = ArbitraryDataSection 
		And (Object.DataSource = BudgetIndicatorPresentation Or Object.DataSource = "") Then
		Object.DataSource = LineIndicatorOfBudgets;
	EndIf;
	BudgetIndicatorPresentation = LineIndicatorOfBudgets;
	IndicatorType = Common.ObjectAttributeValue(Object.BudgetBalanceItem, "IndicatorType");
	
	FillInTypesOfAnalytics();
	FillInAnalyticsSettings();
	
EndProcedure

&AtServer
Procedure WhenSourceChangesServer()
	
	SetSignOfUsingItemOfAssetsLiabilities();
	CustomizeFormElements();
	
	If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery 
		And Object.DataSource = "" Then
		Object.DataSource = BudgetIndicatorPresentation;
	EndIf;
	
	If Items.TransactionAmountSource.ChoiceList.FindByValue(Object.TransactionAmountSource) = Undefined Then
		Object.TransactionAmountSource = PredefinedValue("Enum.IndicatorsOfAnalyticalRegisters.EmptyRef");
	EndIf;
	
	GetDataLayoutDiagram();
	BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.GetSettings());
	AddressOfDataCompositionSettings = PutToTempStorage(SettingsComposer.GetSettings(), UUID);
	If Not EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto() Then
		BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, True);
	EndIf;
	CompositionSchemaIsValid = CorrectDataLayoutScheme();
	
EndProcedure

&AtServer
Procedure WhenChangingSourceSectionServer()
	
	Section = Object.DataSourceSection; 
	
	OperationalAccountingRule = (Section = Enums.SectionsOfBudgetingDataSources.OperationalAccounting);
	LocalAccountingRule = (Section = Enums.SectionsOfBudgetingDataSources.LocalAccounting);
	InternationalAccountingRule = (Section = Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
	
	If Not OperationalAccountingRule Then
		Object.TransactionAmountSource = Undefined;
	ElsIf Not LocalAccountingRule And Not InternationalAccountingRule Then 
		Object.TotalType = Undefined;
	EndIf;
	
	WhenSourceChangesServer();
	
EndProcedure

&AtServer
Procedure InternationalAccountingChartOfAccountsWhenChangedOnServer()
	
	WhenSourceChangesServer();
	
EndProcedure

&AtServer
Procedure CheckIfRuleMatchesSettings()
	
	RuleDoesnTMatchSettings = False;
	WarningText = "";
	
	If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And ValueIsFilled(Object.DataSource) Then
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			If Not DataSourcesServer.ThisIsItemOfAssetsLiabilities(Object.DataSource) Then
				RuleDoesnTMatchSettings = True;
				WarningText = NStr("vi = 'Quy tắc có cài đặt theo dạng của bảng cân đối kế toán quản trị bị tắt sử dụng. Hãy sử dụng quy tắc có cài đặt theo dạng tài sản và nguồn vốn.';
									|ru = 'Правила с настройками по статьям управленческого баланса отключены. Используйте правила с настройками по статьям активов и пассивов.';
									|en = 'Rules with settings by balance sheet statement items are disabled. Use rules with settings by asset and liability items.'; fa = 'Rules with settings by balance sheet statement items are disabled. Use rules with settings by asset and liability items.';
									|it = 'Rules with settings by balance sheet statement items are disabled. Use rules with settings by asset and liability items.';
									|pl = 'Rules with settings by balance sheet statement items are disabled. Use rules with settings by asset and liability items.';
									|tr = 'Yönetim bilançosu kalemlerine göre ayarlanmış kurallar devre dışı. Varlık ve yükümlülük kalemlerine göre ayarlanmış kuralları kullanın.'");
			EndIf;
		ElsIf Not DataSourcesServer.ThisIsItemOfManagementBalanceSheet(Object.DataSource) Then
			RuleDoesnTMatchSettings = True;
			WarningText = NStr("vi = 'Quy tắc có cài đặt theo dạng tài sản và nguồn vốn bị tắt sử dụng. Hãy sử dụng quy tắc có cài đặt theo dạng của bảng cân đối kế toán quản trị.';
								|ru = 'Правила с настройками по статьям активов и пассивов отключены. Используйте правила с настройками по статьям управленческого баланса.';
								|en = 'Rules with settings by asset and liability items are disabled. Use rules with settings by balance sheet statement items.'; fa = 'Rules with settings by asset and liability items are disabled. Use rules with settings by balance sheet statement items.';
								|it = 'Rules with settings by asset and liability items are disabled. Use rules with settings by balance sheet statement items.';
								|pl = 'Rules with settings by asset and liability items are disabled. Use rules with settings by balance sheet statement items.';
								|tr = 'Varlık ve yükümlülük kalemlerine göre ayarlanmış kurallar devre dışı. Yönetim bilançosu kalemlerine göre ayarlanmış kuralları kullanın.'");
		EndIf;
	EndIf;
	
	If RuleDoesnTMatchSettings Then
		ReadOnly = True;
		Items.GroupWarningRuleDisabled.Visible = True;
		Items.WarningMessageDisabledRule.Title = WarningText;
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	OperationalAccountingRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting);
	LocalAccountingRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting);
	InternationalAccountingRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
	ArbitraryDataRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery);
	
	Items.DataSource.Visible = ValueIsFilled(Object.DataSourceSection);
	Items.FinancialAccountingChartOfAccounts.Visible = False;
	Items.FinancialAccountingChartOfAccounts.Visible = InternationalAccountingRule
		And GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting");
	Items.TotalType.Visible = LocalAccountingRule Or InternationalAccountingRule;
	
	DescriptionOfSourceTypes = New TypeDescription(Undefined);
	SourceHeader = NStr("vi = 'Nguồn dữ liệu';
						|ru = 'Источник данных';
						|en = 'Data source'; fa = 'منبع داده';
						|it = 'Origine dei dati';
						|pl = 'Źródło danych';
						|tr = 'Veri kaynağı'");
	SourceSelectionOptions = New Array();
	
	If OperationalAccountingRule Then
		DescriptionOfSourceTypes = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
		SourceHeader = NStr("vi = 'Mục tài sản /nguồn vốn';
							|ru = 'Статья активов/пассивов';
							|en = 'Asset/liability item'; fa = 'قلم دارایی/بدهی';
							|it = 'Voce attività/passività';
							|pl = 'Pozycja aktywów/pasywów';
							|tr = 'Varlık/yükümlülük kalemi'");
		If RuleOnItemOfAssetsLiabilities Then
			ArticlesKinds = New Array();
			ArticlesKinds.Add(Enums.AssetAndLiabilityItemKinds.AssetBalanceSheetName);
			ArticlesKinds.Add(Enums.AssetAndLiabilityItemKinds.Liabilities);
			ArticlesKinds.Add(Enums.AssetAndLiabilityItemKinds.AssetLiability);
			SourceSelectionOptions.Add(New ChoiceParameter("FinancialAccountingObjects", True));
			SourceSelectionOptions.Add(New ChoiceParameter("FinancialAccounting_Settings",
				ActualBudgetingDataByAssetAndLiabilityItems.FinancialAccountingSettingsForBudgeting()));
			SourceSelectionOptions.Add(New ChoiceParameter("ThereIsDataSource", True));
			SourceSelectionOptions.Add(New ChoiceParameter("Filter.Kind", New FixedArray(ArticlesKinds)));
		EndIf;
	ElsIf LocalAccountingRule Then
		TypesArray = New Array;
		TypesArray.Add(LocalAccntingClientServer.TypeChartOfAccounts());
		DescriptionOfSourceTypes = New TypeDescription(TypesArray);
		SourceHeader = NStr("vi = 'Tài khoản kế toán';
							|ru = 'Счет учета';
							|en = 'Ledger account'; fa = 'حساب دفتر کل';
							|it = 'Conto di bilancio';
							|pl = 'Rachunek ewidencji';
							|tr = 'Defterikebir hesabı'");
	ElsIf InternationalAccountingRule Then
		TypesArray = New Array;
		TypesArray.Add(FinancialAccountingClientServer.TypeChartOfAccounts());
		DescriptionOfSourceTypes = New TypeDescription(TypesArray);
		SourceHeader = NStr("vi = 'Tài khoản kế toán';
							|ru = 'Счет учета';
							|en = 'Ledger account'; fa = 'حساب دفتر کل';
							|it = 'Conto di bilancio';
							|pl = 'Rachunek ewidencji';
							|tr = 'Defterikebir hesabı'");
	ElsIf ArbitraryDataRule Then
		DescriptionOfSourceTypes = New TypeDescription("String", , , , New StringQualifiers(200));
		If TypeOf(Object.DataSource) <> Type("String") Then
			Object.DataSource = String(Object.BudgetBalanceItem);
		EndIf;
	EndIf;
	
	Object.DataSource = DescriptionOfSourceTypes.AdjustValue(Object.DataSource);
	Items.DataSource.ChoiceParameters = New FixedArray(SourceSelectionOptions);
	Items.DataSource.Title = SourceHeader;
	
	If OperationalAccountingRule Or LocalAccountingRule Or InternationalAccountingRule Then
		Items.DataSource.ToolTipRepresentation = ToolTipRepresentation.None;
	Else
		Items.DataSource.ToolTipRepresentation = ToolTipRepresentation.Button;
		Items.DataSource.ExtendedTooltip.Title = CustomDataSourceHint();
	EndIf;
	If InternationalAccountingRule Then
		If Not ValueIsFilled(Object.FinancialAccountingChartOfAccounts)
			And Not GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
			Object.FinancialAccountingChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.International;
		EndIf;
		If ValueIsFilled(Object.DataSource) Then
			ChartOfAccountsAccounts = Common.ObjectAttributeValue(Object.DataSource, "ChartOfAccounts");
			If ChartOfAccountsAccounts <> Object.FinancialAccountingChartOfAccounts Then
				Object.DataSource = DescriptionOfSourceTypes.AdjustValue(Undefined);
			EndIf;
		EndIf;
		ArrayOfParameterRelationships = New Array();
		PVConnection = New ChoiceParameterLink("Filter.ChartOfAccounts", "Object.FinancialAccountingChartOfAccounts", LinkedValueChangeMode.DontChange);
		ArrayOfParameterRelationships.Add(PVConnection);
		Items.DataSource.ChoiceParameterLinks = New FixedArray(ArrayOfParameterRelationships);
	EndIf;
	Items.TransactionAmountSource.Visible = OperationalAccountingRule And RuleOnItemOfAssetsLiabilities;
	Items.SetUpDataReceiptScheme.Visible = ArbitraryDataRule;
	
	FillInSelectionListSourceOfTransactionAmount(OperationalAccountingRule, Object.DataSource);
	
	Items.EnableAdvancedConfigurationModeForFillingInAnalytics.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	Items.GroupSetUpDimensionPopulationExplanation.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	
	Items.DisableAdvancedSetupModeOfDimensionPopulation.Visible = Object.AdvancedModeOfDimensionFillSetting;
	Items.DimensionPopulationSettings.Visible = Object.AdvancedModeOfDimensionFillSetting;
	
	Items.GroupUnselectedSource.Visible = Not ValueIsFilled(Object.DataSourceSection);
	
	Items.RuleType.Visible = IndicatorType = Enums.BudgetBalanceItemType.SpecialPurpose;
	
EndProcedure

&AtServer
Procedure ChangedDataLayoutSchemeServer()
	
	Modified = True;
	
	BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.GetSettings()); 
	AddressOfDataCompositionSettings = PutToTempStorage(SettingsComposer.GetSettings(), UUID);
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object, True);
	CompositionSchemaIsValid = CorrectDataLayoutScheme();
	
EndProcedure

&AtServer
Procedure GetDataLayoutDiagram()
	
	RecordManager = FormAttributeToValue("Object");
	DataCompositionSchema = DataSourcesServer.DataLayoutRules(RecordManager,,, True);
	
	BudgetingServer.SetFieldPropertiesForRuleSettings(DataCompositionSchema, Object);
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
EndProcedure

&AtServer
Procedure FillInSelectionListSourceOfTransactionAmount(OperationalAccountingRule, DataSource)
	
	Items.TransactionAmountSource.ChoiceList.Clear();
	
	If Not OperationalAccountingRule
	 Or Not ValueIsFilled(DataSource)
	 Or Not RuleOnItemOfAssetsLiabilities Then
		Return;
	EndIf;
	
	Indicators = ChartsOfCharacteristicTypes.AssetLiabilityItems.IndicatorsOfArticleOfAssetsLiabilities(DataSource);
	
	For Each KeyAndValue In Indicators Do
		Items.TransactionAmountSource.ChoiceList.Add(KeyAndValue.Key);
	EndDo;
	
	If Items.TransactionAmountSource.ChoiceList.Count() = 1 Then
		Object.TransactionAmountSource = Items.TransactionAmountSource.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAnalyticsSettings()
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	DimensionKinds = New Structure;
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		DimensionKinds.Insert("DimensionKind" + DimensionNumber, ThisObject["DimensionKind" + DimensionNumber]);
	EndDo;
	BudgetingServer.FillInSettingsForFillingInAnalyticsByRule(ThisObject, Object, DimensionKinds);
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure EnableAdvancedConfigurationModeForFillingInAnalyticsServer(Val AnalyticsFillInExpressions = Undefined)
	
	Object.AdvancedModeOfDimensionFillSetting = True;
	FillInAnalyticsSettings();
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject, "DimensionPopulationSettings", AnalyticsFillInExpressions);
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure DisableAdvancedSetupModeOfDimensionPopulationServer()
	
	Object.AdvancedModeOfDimensionFillSetting = False;
	FillInAnalyticsSettings();
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure FillInTheAnalyticsSettingsForTheDataSourceServer()
	
	BudgetingServer.SetSettingsForFillingInAnalyticsAutomatically(ThisObject, "DimensionPopulationSettings");
	
EndProcedure

&AtServer
Procedure ExpressionFillingAnalyticsSelectionProcessingServer(RowID) 
	
	BudgetingServer.CheckAnalyticsFillExpressionAfterSelection(ThisObject, RowID, "DimensionPopulationSettings");
	
EndProcedure

&AtServer
Function EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto()
	
	Result = False;
	If Not Object.AdvancedModeOfDimensionFillSetting Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		DimensionKinds = DimensionPopulationSettings.Unload(, "DimensionNumber, DimensionKind");
		AnalyticsFillInExpressions = BudgetingServer.ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds);
		SearchParameters = New Structure("Ambiguous_", True);
		FoundRows = AnalyticsFillInExpressions.FindRows(SearchParameters);
		If FoundRows.Count() Then
			EnableAdvancedConfigurationModeForFillingInAnalyticsServer(AnalyticsFillInExpressions);
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

&AtServer
Procedure SetSignOfUsingItemOfAssetsLiabilities()
	
	RuleOnItemOfAssetsLiabilities = Catalogs.ActualDataQueryRulesByBudgetBalanceItems.RuleOnItemOfAssetsLiabilities(Object);
	
EndProcedure

&AtServer 
Function CustomDataSourceHint()
	SourceHint = NStr("vi = 'Trong truy vấn sơ đồ dàn dựng dữ liệu, cần thêm trường chọn và điều kiện dạng:
		|""%1"" AS %2.';
		|ru = 'В запросе схемы компоновки данных следует добавить поле выборки и условие вида:
		|""%1"" КАК %2.';
		|en = 'In request for data composition schema, add a selection field and a condition:
		|""%1"" AS %2.'; fa = 'In request for data composition schema, add a selection field and a condition:
		|""%1"" AS %2.';
		|it = 'Nella richiesta dello schema di composizione dati è necessario aggiungere un campo di selezione e una condizione del tipo:
		|""%1"" AS %2.';
		|pl = 'Do żądania schematu układu danych należy dodać pole wyboru i warunek rodzaju:
		|""%1"" AS %2.';
		|tr = 'Veri Oluşturma Sistemi talebinde veri kümesi alanına ve tür şartlarına şunların eklenmesi gerekir:
		|""%1"", %2 GİBİ.'");
	SourceHint = StrTemplate(SourceHint, 
		?(ValueIsFilled(Object.DataSource), Object.DataSource, BudgetIndicatorPresentation), "DataSource");
	
	Return SourceHint; 
EndFunction

#EndRegion