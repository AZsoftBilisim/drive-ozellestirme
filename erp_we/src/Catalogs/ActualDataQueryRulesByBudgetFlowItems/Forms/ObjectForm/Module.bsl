#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	BudgetItemPresentation = String(Object.BudgetFlowItem);
	
	SetFlagForUsingCorrespondenceTable();
	SetSignOfUsingItemOfAssetsLiabilities();
	SetLimitRegisterUsageFlag();
	
	If ValueIsFilled(Object.Ref) Then
		CheckIfRuleMatchesSettings();
	Else
		SetFlagForIntermediateCacheStorage();
		If ValueIsFilled(Parameters.CopyingValue) Then
			StorageSettingsComposer = Common.ObjectAttributeValue(Parameters.CopyingValue, "SettingsComposer");
			SettingsComposer.LoadSettings(StorageSettingsComposer.Get());
		EndIf;
		If ValueIsFilled(Object.DataSourceSection) Then
			GetDataLayoutDiagram();
		EndIf;
		BudgetingServer.InitializeRuleSettingsComposer(Object, ThisObject, SettingsComposer.Settings);
		AddressOfDataCompositionSettings = PutToTempStorage(SettingsComposer.GetSettings(), UUID);
		CompositionSchemaIsValid = CorrectDataLayoutScheme();
	EndIf;
	
	FillInTypesOfAnalytics();
	FillInAnalyticsSettings();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	SetConditionalAppearance();
	SetAvailabilityOfDataSourceSchema();
	CustomizeFormElements();
	DeleteInaccessibleSectionsOfDataSources();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CurrentObject.TurnoverByExpenseDimension Then
		TypeOfTurnoverByAnalytics = 1;
	EndIf;
	
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

	CurrentObject.SettingsComposer = New ValueStorage(SettingsComposer.GetSettings());
	CurrentObject.FilterPresentation = String(SettingsComposer.Settings.Filter);
	If CurrentObject.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		If DataCompositionSchema = Undefined Then
			Common.MessageToUser(NStr("vi = 'Chưa thiết lập sơ đồ dàn dựng dữ liệu.';
										|ru = 'Не установлена схема компоновки данных.';
										|en = 'The data composition schema is not set.'; fa = 'The data composition schema is not set.';
										|it = 'Не установлена схема компоновки данных.';
										|pl = 'The data composition schema is not set.';
										|tr = 'Veri oluşturma şeması ayarlanmadı.'"), , , , Cancel);
			Return;
		EndIf;
		CurrentObject.DataSourceScheme = New ValueStorage(DataCompositionSchema);
	EndIf;
		
	BudgetingServer.PutAnalyticsFillingSettingsInRule(ThisObject, CurrentObject);
	
	If Object.RuleType <> Enums.ActualBudgetingDataQueryRuleType.ActualData Then
		CurrentObject.CachingOfRuleResults = 
			(AccordingToCorrespondenceTable Or UnderItemOfAssetsLiabilities) And Not ByRegisterOfLimits;
	EndIf;
		
	If Not Object.Ref.IsEmpty() Then
		ComparisonAttributes = Common.ObjectAttributesValues(Object.Ref, "CachingOfRuleResults, ValidFrom, ValidTo");
		ChangedCachingFlag = ComparisonAttributes.CachingOfRuleResults <> Object.CachingOfRuleResults;
	Else
		ChangedCachingFlag = Object.CachingOfRuleResults;
	EndIf;
	
	ItIsRequiredToRegisterDocuments = ChangedCachingFlag Or Object.CachingOfRuleResults And Not IgnoreChangeInValidityPeriod;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If ItIsRequiredToRegisterDocuments Then
		StartDocumentRegistrationForReflection(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BudgetingServer.ProcessingVerificationOfAnalyticsFillingSettings(DimensionPopulationSettings, Cancel, Object.AdvancedModeOfDimensionFillSetting);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If IgnoreChangeInValidityPeriod
		And Not NotExecuteCheck1BeforeWrite Then
		Cancel = True;
		CallbackDescription = New CallbackDescription("IgnoreChangeInValidityPeriodCompletion", ThisObject);
		QueryText = NStr("vi = 'Đã thay đổi kỳ hiệu lực của quy tắc. Thực hiện phản ánh lại chứng từ trong lập ngân sách theo quy tắc?';
						|ru = 'Изменен период действия правила. Выполнить переотражение документов в бюджетировании по правилу?';
						|en = 'The rule validity period is changed. Do you want to re-record documents in budgeting according to the rule?'; fa = 'The rule validity period is changed. Do you want to re-record documents in budgeting according to the rule?';
						|it = 'Изменен период действия правила. Выполнить переотражение документов в бюджетировании по правилу?';
						|pl = 'The rule validity period is changed. Do you want to re-record documents in budgeting according to the rule?';
						|tr = 'Kuralın geçerlilik dönemi değiştirildi. Bütçelemede belgeler kurala göre yeniden yansıtılsın mı?'");
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("RecordedRuleForObtainingFactUnderBudgetItem");
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
Procedure DataSourceTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text)
		And Object.DataSourceSection = PredefinedValue("Enum.SectionsOfBudgetingDataSources.OperationalAccounting")
		And Not UnderItemOfAssetsLiabilities Then
		StandardProcessing = False;
		DataSourceProcessingOfSelectionDataAcquisition(ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtClient
Procedure DataSourceAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text)
		And Object.DataSourceSection = PredefinedValue("Enum.SectionsOfBudgetingDataSources.OperationalAccounting")
		And Not UnderItemOfAssetsLiabilities Then
		StandardProcessing = False;
		DataSourceProcessingOfSelectionDataAcquisition(ChoiceData, Text);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure DataSourceProcessingOfSelectionDataAcquisition(ChoiceData, Text)
	
	ChoiceData = New ValueList;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Ref
	|FROM
	|	Catalog.BusinessTransactionsSettings
	|WHERE
	|	UseInBudgeting
	|	AND Description LIKE &SearchString
	|";
	
	Query.SetParameter("SearchString", "%" + Text + "%");
	
	ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

&AtClient
Procedure StoreAnIntermediateCacheOnChange(Item)
	
	WhenSourceChangesServer();
	
	NotExecuteCheck1BeforeWrite = False;
	If Not Object.CachingOfRuleResults Then
		IgnoreChangeInValidityPeriod = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure DataSourceSectionOnChange(Item)
	
	ClearMessages();
	WhenChangingSourceSectionServer();
	
EndProcedure

&AtClient
Procedure FinancialAccountingChartOfAccountsOnChange(Item)
	
	ClearMessages();
	InternationalAccountingChartOfAccountsWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CorDataSourceOnChange(Item)
	
	WhenSourceChangesServer();
	
EndProcedure

&AtClient
Procedure TurnoverByAnalyticsWhenChangesOccur(Item)
	
	If TypeOfTurnoverByAnalytics = 0 Then
		Object.TurnoverByExpenseDimension = False;
	Else
		Object.TurnoverByExpenseDimension = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetFlowItemOnChange(Item)
	
	WhenChangingBudgetItemServer();
	
EndProcedure

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

&AtClient
Procedure RuleTypeOnChange(Item)
	
	TypeOfRuleWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ValidFromOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ValueIsFilled(Object.Ref) Then
		IgnoreChangeInValidityPeriod = True;
		NotExecuteCheck1BeforeWrite = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ValidToOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	If ValueIsFilled(Object.Ref) Then
		IgnoreChangeInValidityPeriod = True;
		NotExecuteCheck1BeforeWrite = False;
	EndIf;
	
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
	
	ClearMessages();
	DisableAdvancedSetupModeOfDimensionPopulationServer();
	
EndProcedure

&AtClient
Procedure EnableAdvancedSetupModeOfDimensionPopulation(Command)
	
	ClearMessages();
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

&AtClient
Procedure ReflectDocumentsByRule(Command)
	
	ClearMessages();
	
	StartDocumentRegistrationForReflection(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ResultOfCheckingWhetherAnalyticsCanBeSelected(BlankElementField)
	
	YouCanSelectFillExpression = True;
	If Not ValueIsFilled(Object.BudgetFlowItem) Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.BudgetFlowItem.Name;
	ElsIf Not ValueIsFilled(Object.DataSourceSection) Then
		YouCanSelectFillExpression = False;
		BlankElementField = Items.DataSourceSection.Name;
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

&AtClient
Procedure ChangeDataLayoutScheme(Result, Var_Parameters) Export
	
	If ValueIsFilled(Result) Then
		SettingsComposer.LoadSettings(GetFromTempStorage(Result));
		ChangedDataLayoutSchemeServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure IgnoreChangeInValidityPeriodCompletion(Result, Var_Parameters) Export
	
	NotExecuteCheck1BeforeWrite = True;
	
	If Result = DialogReturnCode.Yes Then
		IgnoreChangeInValidityPeriod = False;
	EndIf;
	
	Write();
	
EndProcedure

&AtServer
Procedure FillInTypesOfAnalytics()
	
	DimensionKinds = BudgetingServer.DimensionKinds(Object);
	
	FillPropertyValues(ThisObject, DimensionKinds);
	
EndProcedure

&AtServer
Procedure CheckIfRuleMatchesSettings()
	
	RuleDoesnTMatchSettings = False;
	WarningText = "";
	
	If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting
		And ValueIsFilled(Object.DataSource) Then
		If GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems") Then
			If Object.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData
			And Not DataSourcesServer.ThisIsItemOfAssetsLiabilities(Object.DataSource) Then
				RuleDoesnTMatchSettings = True;
				WarningText = NStr("vi = 'Quy tắc có cài đặt theo giao dịch kinh tế bị tắt sử dụng. Hãy sử dụng quy tắc có cài đặt theo dạng tài sản và nguồn vốn.';
									|ru = 'Правила с настройками по хозяйственным операциям отключены. Используйте правила с настройками по статьям активов и пассивов.';
									|en = 'Rules with settings by business transactions are disabled. Use rules with settings by asset and liability items.'; fa = 'Rules with settings by business transactions are disabled. Use rules with settings by asset and liability items.';
									|it = 'Rules with settings by business transactions are disabled. Use rules with settings by asset and liability items.';
									|pl = 'Rules with settings by business transactions are disabled. Use rules with settings by asset and liability items.';
									|tr = 'Ticari işlemlere göre ayarlanan kurallar devre dışı bırakıldı. Varlık ve yükümlülük kalemlerine göre ayarlanan kuralları kullanın.'");
			EndIf;
		ElsIf Not DataSourcesServer.ThisIsSettingUpBusinessOfOperation(Object.DataSource) Then
			RuleDoesnTMatchSettings = True;
			WarningText = NStr("vi = 'Quy tắc có cài đặt theo dạng tài sản và nguồn vốn bị tắt sử dụng. Hãy sử dụng quy tắc có cài đặt theo giao dịch kinh tế.';
								|ru = 'Правила с настройками по статьям активов и пассивов отключены. Используйте правила с настройками по хозяйственным операциям.';
								|en = 'Rules with settings by asset and liability items are disabled. Use rules with settings by business transactions.'; fa = 'Rules with settings by asset and liability items are disabled. Use rules with settings by business transactions.';
								|it = 'Rules with settings by asset and liability items are disabled. Use rules with settings by business transactions.';
								|pl = 'Rules with settings by asset and liability items are disabled. Use rules with settings by business transactions.';
								|tr = 'Varlık ve yükümlülük kalemlerine göre ayarlanan kurallar devre dışı bırakıldı. Ticari işlemlere göre ayarlanan kuralları kullanın.'");
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
	
	If LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed() Then
		Items.RuleType.ListChoiceMode = True;
		Items.RuleType.ChoiceList.Clear();
		Items.RuleType.ChoiceList.Add(Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment);
		Items.RuleType.ChoiceList.Add(Enums.ActualBudgetingDataQueryRuleType.ActualData);
	EndIf;
	
	Items.DataSourceSection.ChoiceList.Clear();
	Items.DataSourceSection.ChoiceList.Add(Enums.SectionsOfBudgetingDataSources.OperationalAccounting);
	Items.DataSourceSection.ChoiceList.Add(Enums.SectionsOfBudgetingDataSources.LocalAccounting);
	Items.DataSourceSection.ChoiceList.Add(Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
	Items.DataSourceSection.ChoiceList.Add(Enums.SectionsOfBudgetingDataSources.CustomQuery);
	DeleteInaccessibleSectionsOfDataSources(ByRegisterOfLimits);
	
	LocalAccountingRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.LocalAccounting);
	InternationalAccountingRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
	OperationalAccountingRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.OperationalAccounting);
	ArbitraryDataRule = 
		(Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery);
	
	DescriptionOfSourceTypes = New TypeDescription(Undefined);
	SourceHeader = NStr("vi = 'Nguồn dữ liệu';
						|ru = 'Источник данных';
						|en = 'Data source'; fa = 'منبع داده';
						|it = 'Origine dei dati';
						|pl = 'Źródło danych';
						|tr = 'Veri kaynağı'");
	SourceCodeHeader = NStr("vi = 'Nguồn đối ứng';
							|ru = 'Кор. источник';
							|en = 'Cor. source'; fa = 'منبع مقابل';
							|it = 'Cor. source';
							|pl = 'Cor. source';
							|tr = 'İlgili kaynak'");
	SourceInputHint = NStr("vi = '<bất kỳ>';
							|ru = '<любой>';
							|en = '<any>'; fa = '<هر>';
							|it = '<any>';
							|pl = '<any>';
							|tr = '<herhangi>'");
	SourceSelectionOptions = New Array();
	ParametersForSelectingCorSource = New Array();
	
	If OperationalAccountingRule Then
		If UnderItemOfAssetsLiabilities Then
			DescriptionOfSourceTypes = New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
			SourceHeader = NStr("vi = 'Dạng tài sản/nguồn vốn';
								|ru = 'Статья активов/пассивов';
								|en = 'Asset/liability item'; fa = 'قلم دارایی/بدهی';
								|it = 'Voce attività/passività';
								|pl = 'Pozycja aktywów/pasywów';
								|tr = 'Varlık/yükümlülük kalemi'");
			SourceCodeHeader = NStr("vi = 'Dạng đối ứng';
									|ru = 'Кор. статья';
									|en = 'Cor. item'; fa = 'قلم مقابل';
									|it = 'Voce corr.';
									|pl = 'Kor. artykuł';
									|tr = 'Muhabir kalem'");
			SourceSelectionOptions.Add(New ChoiceParameter("FinancialAccountingObjects", True));
			SourceSelectionOptions.Add(New ChoiceParameter("FinancialAccounting_Settings",
				ActualBudgetingDataByAssetAndLiabilityItems.FinancialAccountingSettingsForBudgeting()));
			SourceSelectionOptions.Add(New ChoiceParameter("ThereIsDataSource", True));
			ParametersForSelectingCorSource.Add(New ChoiceParameter("FinancialAccountingObjects", True));
			ParametersForSelectingCorSource.Add(New ChoiceParameter("FinancialAccounting_Settings",
				ActualBudgetingDataByAssetAndLiabilityItems.FinancialAccountingSettingsForBudgeting()));
		Else
			DescriptionOfSourceTypes = New TypeDescription("CatalogRef.BusinessTransactionsSettings");
			SourceHeader = NStr("vi = 'Giao dịch kinh tế';
								|ru = 'Хозяйственная операция';
								|en = 'Business transaction'; fa = 'عملیات تجاری';
								|it = 'Operazione economica';
								|pl = 'Operacja gospodarcza';
								|tr = 'Ticari işlem'");
			SourceSelectionOptions.Add(New ChoiceParameter("Filter.UseInBudgeting", True));
		EndIf;
		SourceInputHint = NStr("vi = '<bất kỳ>';
								|ru = '<любой>';
								|en = '<any>'; fa = '<هر>';
								|it = '<any>';
								|pl = '<any>';
								|tr = '<herhangi>'");
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
		SourceCodeHeader = NStr("vi = 'Tài khoản đối ứng';
								|ru = 'Кор. счет учета';
								|en = 'Cor. ledger account'; fa = 'حساب دفتر کل مقابل';
								|it = 'Conto corrispondente della contabilità';
								|pl = 'Kor. konto księgowe';
								|tr = 'Muhabir defterikebir hesabı'");
		SourceInputHint = NStr("vi = '<bất kỳ>';
								|ru = '<любой>';
								|en = '<any>'; fa = '<هر>';
								|it = '<any>';
								|pl = '<any>';
								|tr = '<herhangi>'");
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
		SourceCodeHeader = NStr("vi = 'Tài khoản đối ứng';
								|ru = 'Кор. счет учета';
								|en = 'Cor. ledger account'; fa = 'حساب دفتر کل مقابل';
								|it = 'Conto corrispondente della contabilità';
								|pl = 'Kor. konto księgowe';
								|tr = 'Muhabir defterikebir hesabı'");
		SourceInputHint = NStr("vi = '<bất kỳ>';
								|ru = '<любой>';
								|en = '<any>'; fa = '<هر>';
								|it = '<any>';
								|pl = '<any>';
								|tr = '<herhangi>'");
	ElsIf ArbitraryDataRule Then
		DescriptionOfSourceTypes = New TypeDescription("String", , , , New StringQualifiers(200));
		If TypeOf(Object.DataSource) <> Type("String") 
			Or Not ValueIsFilled(Object.DataSource) Then
			Object.DataSource = String(Object.BudgetFlowItem);
		EndIf;
	EndIf;
	
	Object.DataSource = DescriptionOfSourceTypes.AdjustValue(Object.DataSource);
	Object.CorDataSource = DescriptionOfSourceTypes.AdjustValue(Object.CorDataSource);
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
		If ValueIsFilled(Object.CorDataSource) Then
			ChartOfAccountsAccounts = Common.ObjectAttributeValue(Object.CorDataSource, "ChartOfAccounts");
			If ChartOfAccountsAccounts <> Object.FinancialAccountingChartOfAccounts Then
				Object.CorDataSource = DescriptionOfSourceTypes.AdjustValue(Undefined);
			EndIf;
		EndIf;
		
		ArrayOfParameterRelationships = New Array();
		PVConnection = New ChoiceParameterLink("Filter.ChartOfAccounts", "Object.FinancialAccountingChartOfAccounts", LinkedValueChangeMode.DontChange);
		ArrayOfParameterRelationships.Add(PVConnection);
		Items.DataSource.ChoiceParameterLinks = New FixedArray(ArrayOfParameterRelationships);
		Items.CorDataSource.ChoiceParameterLinks = New FixedArray(ArrayOfParameterRelationships);
	EndIf;
	Items.DataSource.Title = SourceHeader;
	Items.DataSource.ChoiceParameters = New FixedArray(SourceSelectionOptions);
	
	Items.CorDataSource.Title = SourceCodeHeader;
	Items.CorDataSource.InputHint = SourceInputHint;
	Items.CorDataSource.ChoiceParameters = New FixedArray(ParametersForSelectingCorSource);
	
	If OperationalAccountingRule Or LocalAccountingRule Or InternationalAccountingRule Then
		Items.DataSource.ToolTipRepresentation = ToolTipRepresentation.None;
	Else
		Items.DataSource.ToolTipRepresentation = ToolTipRepresentation.Button;
		Items.DataSource.ExtendedTooltip.Title = CustomDataSourceHint();
	EndIf;
	
	TransactionsWithCorrespondence = False;
	If InternationalAccountingRule And ValueIsFilled(Object.FinancialAccountingChartOfAccounts)Then
		OptionForGeneratingTransactions = Common.ObjectAttributeValue(
			Object.FinancialAccountingChartOfAccounts, "OptionForGeneratingTransactions");
		TransactionsWithCorrespondence =
			OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence;
	EndIf;
	Items.CorDataSource.Visible = LocalAccountingRule
		Or (InternationalAccountingRule And TransactionsWithCorrespondence)
		Or (OperationalAccountingRule And UnderItemOfAssetsLiabilities);
	
	Items.TotalType.Visible = LocalAccountingRule Or InternationalAccountingRule
		Or (OperationalAccountingRule And UnderItemOfAssetsLiabilities);
	
	Items.DataSource.Visible = ValueIsFilled(Object.DataSourceSection);
	
	Items.FinancialAccountingChartOfAccounts.Visible = False;
	Items.FinancialAccountingChartOfAccounts.Visible = InternationalAccountingRule
		And GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting");
	If LocalAccountingRule Or InternationalAccountingRule Then
		Items.TotalType.ChoiceList.Clear();
		Items.TotalType.ChoiceList.Add(Enums.TypesOfTotals.Turnover);
		If Object.CorDataSource <> Object.DataSource Then
			Items.TotalType.ChoiceList.Add(Enums.TypesOfTotals.TurnoverDr);
			Items.TotalType.ChoiceList.Add(Enums.TypesOfTotals.TurnoverCr);
		Else
			Object.TotalType = Enums.TypesOfTotals.Turnover;
		EndIf;
	EndIf;
	
	Items.TransactionAmountSource.Visible = OperationalAccountingRule;
	Items.TransactionAmountSource.Enabled = Not ByRegisterOfLimits;
	Items.SetUpDataReceiptScheme.Visible = ArbitraryDataRule;
	
	FillInSelectionListSourceOfTransactionAmount(OperationalAccountingRule, Object.DataSource);
	
	Items.TypeOfTurnoverByAnalytics.Visible = 
		SelectTypeOfTurnoverBasedOnAnalytics(OperationalAccountingRule, Object.DataSource);
		
	Items.DecorationIndentationCorDataSource.Visible = 
		ValueIsFilled(Object.DataSourceSection) And 
		Object.DataSourceSection <> Enums.SectionsOfBudgetingDataSources.CustomQuery;
		
	Items.EnableAdvancedConfigurationModeForFillingInAnalytics.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	Items.GroupSetUpDimensionPopulationExplanation.Visible = Not Object.AdvancedModeOfDimensionFillSetting;
	
	Items.DisableAdvancedSetupModeOfDimensionPopulation.Visible = Object.AdvancedModeOfDimensionFillSetting;
	Items.DimensionPopulationSettings.Visible = Object.AdvancedModeOfDimensionFillSetting;
	
	Items.GroupUnselectedSource.Visible = Not ValueIsFilled(Object.DataSourceSection);
	
	VisibilityOfIntermediateCacheStorage = ValueIsFilled(Object.DataSourceSection)
		And Object.RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData
		Or (AccordingToCorrespondenceTable Or UnderItemOfAssetsLiabilities) And Not ByRegisterOfLimits;
	
	Items.StoreAnIntermediateCache.Visible = VisibilityOfIntermediateCacheStorage;
	Items.GroupStoringTheResultOfExecutingTheRuleExplanation.Visible = VisibilityOfIntermediateCacheStorage;
	Items.ValidFrom.Visible = VisibilityOfIntermediateCacheStorage;
	Items.ValidTo.Visible = VisibilityOfIntermediateCacheStorage;
	
	Items.StoreAnIntermediateCache.Enabled = Not (AccordingToCorrespondenceTable Or UnderItemOfAssetsLiabilities);
	Items.ValidFrom.Enabled = Object.CachingOfRuleResults;
	Items.ValidTo.Enabled = Object.CachingOfRuleResults;
	Items.ReflectDocumentsByRule.Visible = Object.CachingOfRuleResults And ValueIsFilled(Object.Ref);
	
EndProcedure

&AtServer
Procedure DeleteInaccessibleSectionsOfDataSources(ForciblyDelete = False)

	If Not BudgetingServer.InternationalAccountingIsUsed() Or ForciblyDelete
		Or Not AccessRight("Read", Object.FinancialAccountingChartOfAccounts.Metadata())
		 Then
		Sections = Items.DataSourceSection.ChoiceList;
		SectionInternationalAccounting = Sections.FindByValue(Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
		If SectionInternationalAccounting <> Undefined Then
			Sections.Delete(SectionInternationalAccounting);
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseLocal") Or ForciblyDelete Then
		Sections = Items.DataSourceSection.ChoiceList;
		LocalAccountingSection = Sections.FindByValue(Enums.SectionsOfBudgetingDataSources.LocalAccounting);
		If LocalAccountingSection <> Undefined Then
			Sections.Delete(LocalAccountingSection);
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure WhenChangingBudgetItemServer()
	
	ArbitraryDataSection = Enums.SectionsOfBudgetingDataSources.CustomQuery;
	LineItemBudgets = String(Object.BudgetFlowItem);
	If Object.DataSourceSection = ArbitraryDataSection 
		And (Object.DataSource = BudgetItemPresentation Or Object.DataSource = "") Then
		Object.DataSource = LineItemBudgets;
	EndIf;
	BudgetItemPresentation = LineItemBudgets;
	
	FillInTypesOfAnalytics();
	FillInAnalyticsSettings();
	
EndProcedure

&AtServer
Procedure WhenSourceChangesServer()
	
	SetFlagForUsingCorrespondenceTable();
	SetSignOfUsingItemOfAssetsLiabilities();
	SetFlagForIntermediateCacheStorage();
	
	CustomizeFormElements();
	
	If ValueIsFilled(Object.DataSourceSection) Then
		If Object.DataSourceSection = Enums.SectionsOfBudgetingDataSources.CustomQuery
			And Object.DataSource = "" Then
			Object.DataSource = BudgetItemPresentation;
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
	Else
		CompositionSchemaIsValid = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingSourceSectionServer()
	
	Section = Object.DataSourceSection; 
	
	OperationalAccountingRule = (Section = Enums.SectionsOfBudgetingDataSources.OperationalAccounting);
	LocalAccountingRule = (Section = Enums.SectionsOfBudgetingDataSources.LocalAccounting);
	InternationalAccountingRule = (Section = Enums.SectionsOfBudgetingDataSources.FinancialAccounting);
	
	Object.DataSource = Undefined;
	Object.CorDataSource = Undefined;
	
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
Procedure GetDataLayoutDiagram()
	
	RecordManager = FormAttributeToValue("Object");
	CorrespondencesTable = Undefined;
	If AccordingToCorrespondenceTable Then
		CorrespondencesTable = DataSourcesServer.TableOfCorrespondenceRegisters(RecordManager.DataSource);
	EndIf;
	DataCompositionSchema = DataSourcesServer.DataLayoutRules(RecordManager,,, True, CorrespondencesTable);
	
	BudgetingServer.SetFieldPropertiesForRuleSettings(DataCompositionSchema, Object); 
	AddressOfDataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
EndProcedure

&AtServer
Procedure FillInSelectionListSourceOfTransactionAmount(OperationalAccountingRule, DataSource)
	
	Items.TransactionAmountSource.ChoiceList.Clear();
	
	If Not OperationalAccountingRule Or Not ValueIsFilled(DataSource) Then
		Return;
	EndIf;
	
	If ByRegisterOfLimits Then
		
		Indicators = CommonClientServer.ValueInArray(Enums.IndicatorsOfAnalyticalRegisters.AmountToBePaid);
		Items.TransactionAmountSource.ChoiceList.LoadValues(Indicators);
		
	ElsIf AccordingToCorrespondenceTable Then
		
		Indicators = TMCommonUseClientServer.ConvertMatchOrStructureToArray(
			DataSourcesCached.AmountIndicatorsByDataSource(DataSource, True), True);
		Items.TransactionAmountSource.ChoiceList.LoadValues(Indicators);
		
	ElsIf UnderItemOfAssetsLiabilities Then
		
		Indicators = ChartsOfCharacteristicTypes.AssetLiabilityItems.IndicatorsOfArticleOfAssetsLiabilities(DataSource);
		For Each KeyAndValue In Indicators Do
			Items.TransactionAmountSource.ChoiceList.Add(KeyAndValue.Key);
		EndDo;
		
	Else
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	OperationIndicators.Factor AS Factor,
		|	PRESENTATION(OperationIndicators.Factor) AS Presentation
		|FROM
		|	Catalog.BusinessTransactionsSettings.RegisterIndicators AS OperationIndicators
		|WHERE
		|	OperationIndicators.Ref = &Operation
		|	AND OperationIndicators.Use = TRUE";
		Query.SetParameter("Operation", Object.DataSource);
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			Items.TransactionAmountSource.ChoiceList.Add(Selection.Factor, Selection.Presentation);
		EndDo;
		
	EndIf;
	
	If Items.TransactionAmountSource.ChoiceList.Count() = 1 Then
		Object.TransactionAmountSource = Items.TransactionAmountSource.ChoiceList[0].Value;
	EndIf;
	
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
Function SelectTypeOfTurnoverBasedOnAnalytics(OperationalAccountingRule, DataSource)
	
	Result = False;
	
	If Not OperationalAccountingRule Or Not ValueIsFilled(DataSource) Then
		Return Result;
	EndIf;
	
	SourceRegisterName_ = Common.ObjectAttributeValue(Object.DataSource, "DataSource");
	Result = (SourceRegisterName_ = "RecordsProductsProducts");
	
	Return Result;
	
EndFunction

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
	If EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(False) Then
		Object.AdvancedModeOfDimensionFillSetting = True;
		Common.MessageToUser(NStr("vi = 'Có đối tượng phân tích khoản mục mà cần tùy chỉnh điền thủ công';
									|ru = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
									|en = 'There are item dimensions that require manual population setup'; fa = 'There are item dimensions that require manual population setup';
									|it = 'Имеются аналитики статьи, требующие ручной настройки заполнения';
									|pl = 'There are item dimensions that require manual population setup';
									|tr = 'Doldurmanın manuel olarak ayarlanmasını gerektiren kalem boyutları mevcuttur'"));
	Else
		FillInAnalyticsSettings();
		CustomizeFormElements();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAnalyticsSettings()
	
	DimensionKinds = New Structure;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		DimensionKinds.Insert("DimensionKind" + DimensionNumber, ThisObject["DimensionKind" + DimensionNumber]);
	EndDo;
	BudgetingServer.FillInSettingsForFillingInAnalyticsByRule(ThisObject, Object, DimensionKinds);
	BudgetingServer.CheckAvailabilityOfAnalyticsFields(ThisObject, Object);
	
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
Procedure StartDocumentRegistrationForReflection(ReflectByRule)

	Catalogs.ActualDataQueryRulesByBudgetFlowItems.StartDocumentRegistrationForBackgroundReflection(Object.Ref, Object.ValidFrom, Object.ValidTo, ComparisonAttributes, ReflectByRule);

EndProcedure

&AtServer
Procedure SetFlagForIntermediateCacheStorage()
	
	If AccordingToCorrespondenceTable Or UnderItemOfAssetsLiabilities Then
		Object.CachingOfRuleResults = Not ByRegisterOfLimits;
	ElsIf Object.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment Then
		Object.CachingOfRuleResults = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFlagForUsingCorrespondenceTable()
	
	AccordingToCorrespondenceTable = Catalogs.ActualDataQueryRulesByBudgetFlowItems.RuleOnCorrespondenceTable(Object);
	
EndProcedure

&AtServer
Procedure SetSignOfUsingItemOfAssetsLiabilities()
	
	UnderItemOfAssetsLiabilities = Catalogs.ActualDataQueryRulesByBudgetFlowItems.RuleOnItemOfAssetsLiabilities(Object);
	
EndProcedure

&AtServer
Procedure SetLimitRegisterUsageFlag()
	
	ByRegisterOfLimits = (Object.RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment)
		And LimitsByBudgetingDataServer.RegisterOfBudgetingLimitsIsUsed();
	
EndProcedure

&AtServer
Procedure TypeOfRuleWhenChangingOnServer()
	
	Section = Object.DataSourceSection;
	RuleType = Object.RuleType;
	
	OperationalAccountingRule = Section = Enums.SectionsOfBudgetingDataSources.OperationalAccounting;
	RuleGettingFact = RuleType = Enums.ActualBudgetingDataQueryRuleType.ActualData;
	RuleBudgetExecution = RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillment
		Or RuleType = Enums.ActualBudgetingDataQueryRuleType.BudgetFulfillmentAndActualData;
	
	SetLimitRegisterUsageFlag();
	
	If OperationalAccountingRule Then
		If ValueIsFilled(Object.DataSource) Then
			SourceArticleAssetsLiabilities = DataSourcesServer.ThisIsItemOfAssetsLiabilities(Object.DataSource);
			If (RuleBudgetExecution And SourceArticleAssetsLiabilities)
			 Or (RuleGettingFact And Not SourceArticleAssetsLiabilities
				And GetFunctionalOption("SetUpRulesForObtainingActualDataByAssetAndLiabilityItems")) Then
				Object.DataSource = Undefined;
				Object.CorDataSource = Undefined;
				Object.TransactionAmountSource = Undefined;
				Object.TotalType = Undefined;
			EndIf;
		EndIf;
		
		WhenSourceChangesServer();
	Else
		SetFlagForIntermediateCacheStorage();
		CustomizeFormElements();
	EndIf;
	
EndProcedure

&AtServer
Function EnableAdvancedSettingsForFillingInAnalyticsInCaseOfErrorsInAuto(ChangeSettings = True)
	
	Result = False;
	If Not Object.AdvancedModeOfDimensionFillSetting Then
		DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
		DimensionKinds = DimensionPopulationSettings.Unload(, "DimensionNumber, DimensionKind");
		AnalyticsFillInExpressions = BudgetingServer.ExpressionsForFillingInAnalyticsAccordingToDataLayoutScheme(DataCompositionSchema, DimensionKinds);
		SearchParameters = New Structure("Ambiguous_", True);
		FoundRows = AnalyticsFillInExpressions.FindRows(SearchParameters);
		If FoundRows.Count() Then
			If ChangeSettings Then
				EnableAdvancedConfigurationModeForFillingInAnalyticsServer(AnalyticsFillInExpressions);
			EndIf;
			Result = True;
		EndIf;
	EndIf;
	
	Return Result;

EndFunction

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
		?(ValueIsFilled(Object.DataSource), Object.DataSource, BudgetItemPresentation), "DataSource");
	
	Return SourceHint; 
EndFunction

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
	If Item.Name = "sh_ShamsiInput_ValidFrom" Then
		ValidFromOnChange(Items.ValidFrom);
	ElsIf Item.Name = "sh_ShamsiInput_ValidTo" Then
		ValidToOnChange(Items.ValidTo);
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
