
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	OnReadCreateAtServer();

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	SaveDCSSettingsForAnalysis(CurrentObject);
	
	CurrentObject.AnalysisPeriod = New ValueStorage(AnalysisPeriod);
	
	CurrentObject.ComparisonPeriod = New ValueStorage(ComparisonPeriod);
	
	CurrentObject.DecorationSettingStorage = DecorationSettingStorage;

	CurrentObject.DemoDataStorage = DemoDataStorage;
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Items.ComparisonPeriod.AutoMarkIncomplete
		And Not ValueIsFilled(ComparisonPeriod) Then
		MessageText = NStr("vi = 'Chưa điền trường ""Kỳ so sánh""';
							|ru = 'Поле ""Период сравнения"" не заполнено';
							|en = '""Comparison period"" is required'; fa = '""Comparison period"" is required';
							|it = 'Il campo ""Periodo di comparazione"" non è compilato';
							|pl = 'Nie wypełniono pola ""Период сравнения""';
							|tr = '""Karşılaştırma dönemi"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(
			MessageText,, "ComparisonPeriod",, Cancel);
	EndIf;
	
	If Items.AnalysisObject.AutoMarkIncomplete
		And AnalysisObject = Undefined Then
		MessageText = NStr("vi = 'Chưa điền trường ""Đối tượng phân tích""';
							|ru = 'Поле ""Объект анализа"" не заполнено';
							|en = '""Analysis object"" is required'; fa = '""Analysis object"" is required';
							|it = 'Il campo ""Oggetto di analisi"" non è compilato';
							|pl = 'Nie wypełniono pola ""Объект анализа""';
							|tr = '""Analiz nesnesi"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(
			MessageText,, "AnalysisObject",, Cancel);
	EndIf;
	
	If Items.AnalysisValue.AutoMarkIncomplete
		And AnalysisValue = Undefined Then
		MessageText = NStr("vi = 'Chưa điền trường ""Giá trị""';
							|ru = 'Поле ""Значение"" не заполнено';
							|en = '""Value"" is required'; fa = '""Value"" is required';
							|it = 'Il campo ""Valore"" non è compilato';
							|pl = 'Nie wypełniono pola ""Значение""';
							|tr = '""Değer"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(
			MessageText,, "AnalysisValue",, Cancel);
		EndIf;
		
	If Items.AnalysisValueAdditional.AutoMarkIncomplete
		And AnalysisValueAdditional = Undefined Then
		MessageText = NStr("vi = 'Chưa điền trường ""Giá trị bổ sung""';
							|ru = 'Поле ""Доп. значение"" не заполнено';
							|en = '""Additional value"" is required'; fa = '""Additional value"" is required';
							|it = 'Il campo ""Valore aggiuntivo"" non è compilato';
							|pl = 'Nie wypełniono pola ""Доп. значение""';
							|tr = '""Ek değer"" alanı doldurulmadı'");
		CommonClientServer.MessageToUser(
			MessageText,, "AnalysisValueAdditional",, Cancel);
	EndIf;
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
Procedure ForecastAnalysisDepthOnChange(Item)
	SetLabelsToPeriodFields(Object, Items);
EndProcedure

&AtClient
Procedure ForecastHorizonOnChange(Item)
	SetLabelsToPeriodFields(Object, Items);
EndProcedure

&AtClient
Procedure AnalysisValueOnChange(Item)
	If AnalysisValue = AnalysisValueAdditional Then
		AnalysisValueAdditional = Undefined;
	EndIf;
	FillInAnalysisValueSelectionList();
	
	SetAvailabilityOfFillingByTemplate();
EndProcedure

&AtClient
Procedure ComponentWiseComparisonModeOnChange(Item)
	If Object.ComponentWiseComparisonMode = 0 Then
		AnalysisValueAdditional = Undefined;
	Else
		AnalysisObject = Undefined;
	EndIf;
	
	SetVisibilityAvailabilityOfComparisonItems(Object, Items, True);
EndProcedure

&AtClient
Procedure ValueCalculationMethodOnChange(Item)
	SetAvailabilityOfFillingByTemplate();
EndProcedure

&AtClient
Procedure AnalysisObjectOnChange(Item)
	SetAvailabilityOfFillingByTemplate();
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	FilterByUser = New Structure("User", Object.EmployeeResponsible);
	
	If Not Object.EmployeeResponsible.IsEmpty() Then
		If Object.AvailabilitySettings.FindRows(FilterByUser).Count() = 0 Then
			QuestionRow = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đặt phương án phân tích đối với %1 là chính?';
					|ru = 'Сделать доступным вариант анализа для %1?';
					|en = 'Make analysis option available for %1?'; fa = 'Make analysis option available for %1?';
					|it = 'Rendere disponibile la variante dell''analisi per%1?';
					|pl = 'Udostępnić wariant analizy dla %1?';
					|tr = '%1 için analiz seçeneğini erişilebilir yap?'"),
				Object.EmployeeResponsible); 
			
			CallbackDescription = New CallbackDescription("EmployeeResponsibleOnChangeCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QuestionRow, QuestionDialogMode.YesNo);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure EmployeeResponsibleOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	Response = QuestionResult; 
	
	If Response = DialogReturnCode.Yes Then
		NewAccessibilitySetting = Object.AvailabilitySettings.Add();
		NewAccessibilitySetting.User = Object.EmployeeResponsible;
		NewAccessibilitySetting.ViewOption = Object.DisplayOptionDefault;
	EndIf;
	
	SetLabelsForAccessibilitySettingsAndReports(Object, Items);
EndProcedure

&AtClient
Procedure IndicatorCalculationFrequencyOnChange(Item)
	SetLabelsToPeriodFields(Object, Items);
EndProcedure

&AtClient
Procedure CalculateForecastOnChange(Item)
	SetAvailabilityOfFormPredictionElements(Items, Object.CalculateForecast);
EndProcedure

&AtClient
Procedure AnalysisTypeOnChange(Item)
	SetListToSelectChartTypes(MappingOfComparisonTypesAndChartTypes,
			Items.ChartType.ChoiceList,
			Object.AnalysisType);
	
	SetVisibilityAccessibilityOfFormElements(MappingOfComparisonTypesAndChartTypes,
			Object,
			Items,
			ThisForm);
	
	Object.ChartType = Items.ChartType.ChoiceList[0].Value;
	
	SetAvailabilityOfFillingByTemplate();
EndProcedure

&AtClient
Procedure FractionalPartCalculationAccuracyOnChange(Item)
	SetInscriptionOfDecimalPlaces(Object.FractionalPartCalculationAccuracy, Items);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInANameFromTemplate(Command)
	SettingsItems = SettingsComposer.UserSettings.Items;
	
	StringForSelections = "";
	If HasUserSettings(SettingsItems, False) Then
		StringForSelections = NStr("vi = 'Đã đặt bộ lọc';
									|ru = 'Установлены отборы';
									|en = 'Filters enabled'; fa = 'Filters enabled';
									|it = 'Selezioni impostate';
									|pl = 'Ustawiono filtr';
									|tr = 'Ayarlanan filtreler'");
	EndIf;
	
	SelectionByTypeOfComparison = New Structure("AnalysisType", Object.AnalysisType);
	TheParametersOfThe = MappingOfComparisonTypesAndChartTypes.FindRows(SelectionByTypeOfComparison);
	AnalysisObjectIsAvailable =  TheParametersOfThe[0].AnalysisObjectIsAvailable;
	
	CalculationCurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings,
		"SettlementCurrency");
	
	If CalculationCurrencyParameter = Undefined Then
		Description = String(Items.AnalysisValue.EditText);
	Else
		Description = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (%2)';
				|ru = '%1 (%2)';
				|en = '%1 (%2)'; fa = '%1 (%2)';
				|it = '%1 (%2)';
				|pl = '%1 (%2)';
				|tr = '%1 (%2)'"),
			String(Items.AnalysisValue.EditText),
			CalculationCurrencyParameter.Value);
	EndIf;
	If AnalysisObjectIsAvailable Then
		Description = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 cho %2';
				|ru = '%1 по %2';
				|en = '%1 for %2'; fa = '%1 for %2';
				|it = '%1 fino a %2';
				|pl = '%1 do %2';
				|tr = '%2 göre %1'"),
			Description,
			String(Items.AnalysisObject.EditText));
	EndIf;
	If Not IsBlankString(StringForSelections) Then
		Description = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1, %2, %3';
				|ru = '%1, %2, %3';
				|en = '%1, %2, %3'; fa = '%1, %2, %3';
				|it = '%1, %2, %3';
				|pl = '%1, %2, %3';
				|tr = '%1, %2, %3'"),
			Description,
			String(Object.ValueCalculationMethod),
			StringForSelections);
	Else
		Description = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1, %2';
				|ru = '%1, %2';
				|en = '%1, %2'; fa = '%1, %2';
				|it = '%1, %2';
				|pl = '%1, %2';
				|tr = '%1, %2'"),
			Description,
			String(Object.ValueCalculationMethod));
	EndIf;
	Object.Description = Description;
EndProcedure

&AtClient
Procedure SetUpAvailability(Command)
	FormParameters = New Structure;
	FormParameters.Insert("Users", Object.AvailabilitySettings);
	FormParameters.Insert("DisplayOptionDefault", Object.DisplayOptionDefault);
	
	CallbackDescription = New CallbackDescription("SetUpAvailabilityCompletion", ThisObject);
	OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.AvailabilitySetting",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SetUpAvailabilityCompletion(Result, AdditionalParameters) Export
	If Not Result = Undefined Then
		FillInAccessibilitySettings(Result);
		
		SetLabelsForAccessibilitySettingsAndReports(Object, Items);
		
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure FiltersSet(Command)
	// Open the Data Layout Schema Settings Editor
	Addresses = AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage();
	CustomSettingsAddress = PutToTempStorage(SettingsComposer.UserSettings, UUID);
	
	FormParameters = New Structure("AddressesOfDataCompositionSchema, CustomSettingsAddress", Addresses, CustomSettingsAddress);
	CallbackDescription = New CallbackDescription("FiltersSetCompletion", ThisObject);
	OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.AdvancedFilter",
		FormParameters,,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure FiltersSetCompletion(Result, AdditionalParameters) Export
	CustomSettingsAddress = Result;
	
	If Not CustomSettingsAddress = Undefined Then
		SettingsComposer.LoadUserSettings(GetFromTempStorage(CustomSettingsAddress));
	EndIf;
	
	SetLabelsForSelectionAndOrderingSettings(SettingsComposer, Items);
EndProcedure

&AtClient
Procedure CustomizeReports(Command)
	FormParameters  = New Structure("ReportsOptions", Object.ReportsToDrillDown);
	
	OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.SetUpReportsToDrillDown",
		FormParameters,,,,, 
		New CallbackDescription("CustomizeReportsCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure CustomizeReportsCompletion(Result, AdditionalParameters) Export
	If Not Result = Undefined Then
		FillInReportSettingsForDecryption(Result);
		
		SetLabelsForAccessibilitySettingsAndReports(Object, Items);
		
		Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure SetAppearance(Command)
	
	DecorationSettingStructure = New Structure;
	DecorationSettingStructure.Insert("TheDesignOfAComponentByComponentComparisonIsAvailable");
	DecorationSettingStructure.Insert("ForecastingIsAvailable");
	DecorationSettingStructure.Insert("DisplayPointMarkersAvailable");
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPointsAvailable");
	DecorationSettingStructure.Insert("DisplayChartCaptionsAvailable");
	DecorationSettingStructure.Insert("ChartBorderIsAvailable");
	DecorationSettingStructure.Insert("ChartSmoothingModeAvailable");
	
	DecorationSettingStructure.Insert("DecorationSettingStorage", 
		DecorationSettingStorage);
	DecorationSettingStructure.Insert("OnlyColorOfMainBatch", 
		Object.OnlyColorOfMainBatch);
	DecorationSettingStructure.Insert("GradientForComponentWiseComparison", 
		Object.GradientForComponentWiseComparison);
	DecorationSettingStructure.Insert("HighlightMaximumValueForComponentWiseComparison", 
		Object.HighlightMaximumValueForComponentWiseComparison);
	DecorationSettingStructure.Insert("DisplayValuePointMarkers", 
		Object.DisplayValuePointMarkers);
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPoints", 
		Object.DisplayAMarkerOfForecastPoints);
	DecorationSettingStructure.Insert("ShowLegend", 
		Object.ShowLegend);
	DecorationSettingStructure.Insert("DisplayChartCaptions", 
		Object.DisplayChartCaptions);
	DecorationSettingStructure.Insert("ChartBorder", 
		Object.ChartBorder);
	DecorationSettingStructure.Insert("ChartSmoothingMode", 
		Object.ChartSmoothingMode);
	DecorationSettingStructure.Insert("ValueScaleMode", 
		Object.ValueScaleMode);
	DecorationSettingStructure.Insert("Include_2Zero", 
		Object.Include_2Zero);
		
	FillPropertyValues(DecorationSettingStructure, 
		SettingsByTypeOfAnalysisAndChart(Object, MappingOfComparisonTypesAndChartTypes));
	
	FormParameters = New Structure("DecorationSettingStructure", DecorationSettingStructure);
	
	OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.AppearanceSetting",
		FormParameters,,,,,
		New CallbackDescription("SetAppearanceCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure SetAppearanceCompletion(Result, AdditionalParameters) Export
	If Not Result = Undefined Then
		FillPropertyValues(Object, Result);
		
		DecorationSettingStorage = Result.DecorationSettingStorage;
	EndIf;
EndProcedure

&AtClient
Procedure SpecifyDemoData(Command)
	If Modified Then
		ShowMessageBox(, NStr("vi = 'Trước khi tùy chỉnh dữ liệu minh họa, cần ghi lại tùy chọn phân tích.';
								|ru = 'Перед настройкой демо-данных необходимо записать вариант анализа.';
								|en = 'You need to save the analysis option before demo data setting.'; fa = 'You need to save the analysis option before demo data setting.';
								|it = 'Перед настройкой демо-данных необходимо записать вариант анализа.';
								|pl = 'You need to save the analysis option before demo data setting.';
								|tr = 'Demo verileri ayarlamadan önce analiz seçeneğinin kaydedilmesi gerekmektedir.'"));
		Return;
	EndIf;
	If CheckFilling() Then
		StructureOfDemoDataSettings = StructureOfDemoDataSettings();
		
		If StructureOfDemoDataSettings.SettingsRequiringAnUpdate.UpdateRequired Then
			CallbackDescription = New CallbackDescription("ShowQueryBoxCompletion", ThisObject, StructureOfDemoDataSettings);
			QueryText = NStr("vi = 'Từ thời điểm lưu lại dữ liệu minh họa, các tùy chỉnh đã thay đổi.
				| Tiếp tục sẽ làm mất dữu liệu minh họa?';
				|ru = 'С момента сохранения демонстрационных данных настройки изменились.
				| Продолжить с потерей демонстрационных данных?';
				|en = 'Settings were changed since demo data has been saved. 
				|Lose demo data and continue?'; fa = 'Settings were changed since demo data has been saved. 
				|Lose demo data and continue?';
				|it = 'Dal momento del salvataggio dei dati d''esempio alcune impostazioni sono state modificate.
				|Continuare con la perdita dei dati d''esempio?';
				|pl = 'Od chwili zapisu danych demonstracyjnych ustawienia uległy zmianie.
				| Kontynuować z utratą danych demonstracyjnych?';
				|tr = 'Demo verileri kaydedildikten sonra ayarlar değişmiştir.
				| Demo verilerinin kaybolmasıyla devam edilsin mi?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		Else
			FormParameters = New Structure("StructureOfDemoDataSettings", StructureOfDemoDataSettings);
			CallbackDescription = New CallbackDescription("SpecifyDemoDataCompletion", ThisObject);
			OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.DemoDataSettings",
				FormParameters,,,,, 
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
	EndIf;
EndProcedure

&AtClient 
Procedure ShowQueryBoxCompletion(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.No Then
		Return;
	Else
		FormParameters = New Structure("StructureOfDemoDataSettings", AdditionalParameters);
		
		OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.DemoDataSettings",
			FormParameters,,,,, 
			New CallbackDescription("SpecifyDemoDataCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
EndProcedure

&AtServer 
Function StructureOfDemoDataSettings()
	AvailableChartTypes = New ValueList;
	SetListToSelectChartTypes(MappingOfComparisonTypesAndChartTypes,
		AvailableChartTypes, Object.AnalysisType);
	AvailableAnalysisObjects = Catalogs.StructureOfTargets.AvailableAnalysisObjects(Object.Owner);
	AvailableAnalysisValues = Catalogs.StructureOfTargets.AvailableAnalysisValues(Object.Owner);
	SelectionAvailableFields = SettingsComposer.Settings.SelectionAvailableFields;
	GroupAvailableFields = SettingsComposer.Settings.GroupAvailableFields;
	
	AnalysisValueCDField = New DataCompositionField(AnalysisValue);
	If AvailableAnalysisValues.FindByValue(AnalysisValueCDField) <> Undefined Then
		AvailableField = SelectionAvailableFields.FindField(AnalysisValueCDField);
		ValueOfAnalysisHeader = AvailableField.Title;
	Else
		ValueOfAnalysisHeader = "";
	EndIf;
	AnalysisValueAdditionalCDField = New DataCompositionField(AnalysisValueAdditional);
	If AvailableAnalysisValues.FindByValue(AnalysisValueAdditionalCDField) <> Undefined Then
		AvailableField = SelectionAvailableFields.FindField(AnalysisValueAdditionalCDField);
		ValueOfAnalysisIsAdditionalHeader = AvailableField.Title;
	Else
		ValueOfAnalysisIsAdditionalHeader = "";
	EndIf;
	ObjectOfAnalysisCDField = New DataCompositionField(AnalysisObject);
	If AvailableAnalysisObjects.FindByValue(ObjectOfAnalysisCDField) <> Undefined Then
		AvailableField = GroupAvailableFields.FindField(ObjectOfAnalysisCDField);
		ObjectOfAnalysisHeader = AvailableField.Title;
		AnalysisObjectValueType = AvailableField.ValueType;
	Else
		ObjectOfAnalysisHeader = "";
	EndIf;
	
	StructureOfDemoDataSettings = New Structure;
	
	StructureOfDemoDataSettings.Insert("DecorationSettingStructure");
	StructureOfDemoDataSettings.Insert("SettingsRequiringAnUpdate");
	
	StructureOfDemoDataSettings.Insert("AnalysisOption", 
		Object.Ref);
	StructureOfDemoDataSettings.Insert("AnalysisValue", 
		AnalysisValue);
	StructureOfDemoDataSettings.Insert("AnalysisValueTypeDescription", 
		Common.TypeDescriptionNumber(15, Object.FractionalPartCalculationAccuracy));
	StructureOfDemoDataSettings.Insert("ValueOfAnalysisHeader", 
		ValueOfAnalysisHeader);
	StructureOfDemoDataSettings.Insert("AnalysisValueAdditional", 
		AnalysisValueAdditional);
	StructureOfDemoDataSettings.Insert("AnalysisValueAdditionalTypeDescription", 
		Common.TypeDescriptionNumber(15, Object.FractionalPartCalculationAccuracy));
	StructureOfDemoDataSettings.Insert("ValueOfAnalysisIsAdditionalHeader", 
		ValueOfAnalysisIsAdditionalHeader);
	StructureOfDemoDataSettings.Insert("AnalysisObject", 
		AnalysisObject);
	StructureOfDemoDataSettings.Insert("ObjectOfAnalysisTypeDescription", 
		AnalysisObjectValueType);
	StructureOfDemoDataSettings.Insert("ObjectOfAnalysisHeader", 
		ObjectOfAnalysisHeader);
	StructureOfDemoDataSettings.Insert("ComponentWiseComparisonMode", 
		Object.ComponentWiseComparisonMode);
	StructureOfDemoDataSettings.Insert("ChartType", 
		Object.ChartType);
	StructureOfDemoDataSettings.Insert("AvailableChartTypes", 
		AvailableChartTypes.UnloadValues());
	StructureOfDemoDataSettings.Insert("DemoDataStorage", 
		DemoDataStorage);
	StructureOfDemoDataSettings.Insert("StorageOfDataCompositionUserSettings", 
		StorageOfDataCompositionUserSettings);
		
	DecorationSettingStructure = New Structure;
	DecorationSettingStructure.Insert("TheDesignOfAComponentByComponentComparisonIsAvailable");
	DecorationSettingStructure.Insert("ForecastingIsAvailable");
	DecorationSettingStructure.Insert("DisplayPointMarkersAvailable");
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPointsAvailable");
	DecorationSettingStructure.Insert("DisplayChartCaptionsAvailable");
	DecorationSettingStructure.Insert("ChartBorderIsAvailable");
	DecorationSettingStructure.Insert("ChartSmoothingModeAvailable");
	
	DecorationSettingStructure.Insert("DecorationSettingStorage", DecorationSettingStorage); 
	DecorationSettingStructure.Insert("OnlyColorOfMainBatch", Object.OnlyColorOfMainBatch);
	DecorationSettingStructure.Insert("GradientForComponentWiseComparison", Object.GradientForComponentWiseComparison);
	DecorationSettingStructure.Insert("HighlightMaximumValueForComponentWiseComparison", 
		Object.HighlightMaximumValueForComponentWiseComparison);
	DecorationSettingStructure.Insert("DisplayValuePointMarkers", Object.DisplayValuePointMarkers);
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPoints", Object.DisplayAMarkerOfForecastPoints);
	DecorationSettingStructure.Insert("ShowLegend", Object.ShowLegend);
	DecorationSettingStructure.Insert("DisplayChartCaptions", Object.DisplayChartCaptions);
	DecorationSettingStructure.Insert("ChartBorder", Object.ChartBorder);
	DecorationSettingStructure.Insert("ChartSmoothingMode", Object.ChartSmoothingMode);
	DecorationSettingStructure.Insert("ValueScaleMode", Object.ValueScaleMode);
	DecorationSettingStructure.Insert("Include_2Zero", Object.Include_2Zero);
		
	FillPropertyValues(DecorationSettingStructure, 
		SettingsByTypeOfAnalysisAndChart(Object, MappingOfComparisonTypesAndChartTypes));
	
	StructureOfDemoDataSettings.Insert("DecorationSettingStructure", DecorationSettingStructure);
		
	SettingsRequiringAnUpdate = New Structure;
	SettingsRequiringAnUpdate.Insert("UpdateRequired", False);
	SettingsRequiringAnUpdate.Insert("AnalysisType", Object.AnalysisType);
	SettingsRequiringAnUpdate.Insert("AnalysisPeriod", AnalysisPeriod);
	SettingsRequiringAnUpdate.Insert("ComparisonPeriod", ComparisonPeriod);
	SettingsRequiringAnUpdate.Insert("IndicatorCalculationFrequency", Object.IndicatorCalculationFrequency);
	SettingsRequiringAnUpdate.Insert("ComponentWiseComparisonMode", Object.ComponentWiseComparisonMode);
	SettingsRequiringAnUpdate.Insert("ValueMultiplier", Object.ValueMultiplier);
	SettingsRequiringAnUpdate.Insert("FractionalPartCalculationAccuracy", Object.FractionalPartCalculationAccuracy);
	SettingsRequiringAnUpdate.Insert("AnalysisObject", AnalysisObject);
	SettingsRequiringAnUpdate.Insert("AnalysisValue", AnalysisValue);
	SettingsRequiringAnUpdate.Insert("AnalysisValueAdditional", AnalysisValueAdditional);
		
	TimeDemoDataStorage = DemoDataStorage; // ValueStorage
	DemoDataStorageValue = TimeDemoDataStorage.Get();
	If DemoDataStorageValue <> Undefined Then
		DemoDataStorageValue.Settings.Insert("UpdateRequired", False);
		UpdateRequired = Not Common.DataMatch(DemoDataStorageValue.Settings, 
			SettingsRequiringAnUpdate);
		SettingsRequiringAnUpdate.Insert("UpdateRequired", UpdateRequired);
	EndIf;
		
	StructureOfDemoDataSettings.Insert("SettingsRequiringAnUpdate", SettingsRequiringAnUpdate);
	
	Return StructureOfDemoDataSettings;
EndFunction

&AtClient
Procedure SpecifyDemoDataCompletion(Result, AdditionalParameters) Export
	If Not Result = Undefined Then
		FillPropertyValues(Object, Result);
		FillPropertyValues(Object, Result.DecorationSettingStructure);
		
		Modified = Result.Modified;
		DecorationSettingStorage = Result.DecorationSettingStructure.DecorationSettingStorage;
		DemoDataStorage = Result.DemoDataStorage;
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
EndProcedure
// End MenuReports

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient 
Procedure SetAvailabilityOfFillingByTemplate()
	SelectionByTypeOfComparison = New Structure("AnalysisType", Object.AnalysisType);
	TheParametersOfThe = MappingOfComparisonTypesAndChartTypes.FindRows(SelectionByTypeOfComparison);
	
	If ValueIsFilled(Object.AnalysisType)
		And ValueIsFilled(AnalysisValue)
		And Not Items.AnalysisValue.ChoiceList.FindByValue(AnalysisValue) = Undefined
		And ValueIsFilled(Object.ValueCalculationMethod) Then
		
		If TheParametersOfThe[0].AnalysisObjectIsAvailable Then
			If Not AnalysisObject = Undefined
				And Not Items.AnalysisObject.ChoiceList.FindByValue(AnalysisObject) = Undefined Then
				Items.FillInANameFromTemplate.Enabled = True;
				
			Else
				Items.FillInANameFromTemplate.Enabled = False;
			EndIf;
		Else 
			Items.FillInANameFromTemplate.Enabled = True;
		EndIf;
	Else
		Items.FillInANameFromTemplate.Enabled = False;
	EndIf;
EndProcedure

&AtClientAtServerNoContext 
Procedure SetAvailabilityOfFormPredictionElements(Items, CalculateForecast)
	Items.ForecastAnalysisDepth.Enabled = CalculateForecast;
	Items.ForecastHorizon.Enabled = CalculateForecast;
EndProcedure

&AtClientAtServerNoContext 
Procedure SetVisibilityAccessibilityOfFormElements(ComparisonTypesAndChartTypes, Object, Items, ThisForm)
	SettingsByTypeOfAnalysis = SettingsByTypeOfAnalysis(Object, ThisForm.MappingOfComparisonTypesAndChartTypes);
	
	Items.ComparisonPeriod.Visible = SettingsByTypeOfAnalysis.ComparisonPeriodIsAvailable;
	Items.ComparisonPeriod.AutoMarkIncomplete = SettingsByTypeOfAnalysis.ComparisonPeriodIsAvailable;
	
	Items.ForecastingGroup.Enabled = SettingsByTypeOfAnalysis.ForecastingIsAvailable;
	
	Items.ForecastAnalysisDepth.Enabled = Object.CalculateForecast;
	Items.ForecastHorizon.Enabled = Object.CalculateForecast;
	
	Items.ValueCalculationMethod.Enabled = ThisForm.CumulativeTotalIsAvailable;
	
	Items.GroupComponentByComponentComparisonMode.Visible = SettingsByTypeOfAnalysis.AnalysisObjectIsAvailable;
	Items.ComponentWiseComparisonMode.Visible = ThisForm.AnalysisValueAdditionalSelectionIsAvailable;
	Items.AnalysisObject.AutoMarkIncomplete = SettingsByTypeOfAnalysis.AnalysisObjectIsAvailable;
	Items.AnalysisValueAdditional.AutoMarkIncomplete = SettingsByTypeOfAnalysis.AnalysisObjectIsAvailable;
	
	SetVisibilityAvailabilityOfComparisonItems(Object, Items, SettingsByTypeOfAnalysis.AnalysisObjectIsAvailable);
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailabilityOfComparisonItems(Val Object, Val Items, AnalysisObjectIsAvailable)
	If Object.ComponentWiseComparisonMode = 0 Then
		Items.AnalysisObject.Visible = True;
		Items.AnalysisValueAdditional.Visible = False;
		Items.AnalysisObject.AutoMarkIncomplete = AnalysisObjectIsAvailable;
		Items.AnalysisValueAdditional.AutoMarkIncomplete = False;
	Else
		Items.AnalysisObject.Visible = False;
		Items.AnalysisValueAdditional.Visible = True;
		Items.AnalysisObject.AutoMarkIncomplete = False;
		Items.AnalysisValueAdditional.AutoMarkIncomplete = AnalysisObjectIsAvailable;
	EndIf;
EndProcedure

&AtClientAtServerNoContext 
Procedure SetInscriptionOfDecimalPlaces(DigitsAfterDecimal, Items)
	TitlePart = TMCommonUseClientServer.DeclensionOfWord(
		DigitsAfterDecimal,
		NStr("vi = 'dấu hiệu, dấu hiệu, dấu hiệu, m';
			|ru = 'знак, знака, знаков, м';
			|en = 'character, characters'; fa = 'character, characters';
			|it = 'знак, знака, знаков, м';
			|pl = 'character, characters';
			|tr = 'işaret, işaret, işaretler, m'"));
	Items.TheInscriptionOfDecimalPlaces.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 sau dấu phẩy';
			|ru = '%1 после запятой';
			|en = '%1 after decimal point'; fa = '%1 after decimal point';
			|it = '%1 dopo la virgola';
			|pl = '%1 po przecinku';
			|tr = '%1 virgülden sonra'"),
		TitlePart);
EndProcedure

&AtClientAtServerNoContext 
Procedure SetLabelsToPeriodFields(Object, Items)
	Items.TheInscriptionDepthAnalysisOfTheForecast.Title = TargetValueMonitoringClientServer.PeriodInWords(Object.ForecastAnalysisDepth, Object.IndicatorCalculationFrequency);
	Items.TheInscriptionTheForecastHorizon.Title = TargetValueMonitoringClientServer.PeriodInWords(Object.ForecastHorizon, Object.IndicatorCalculationFrequency);
EndProcedure

&AtClientAtServerNoContext 
Procedure SetLabelsForAccessibilitySettingsAndReports(Object, Items)
	If Object.AvailabilitySettings.Count() = 0 Then
		Items.SetUpAvailability.Title = NStr("vi = 'tùy chỉnh tính khả dụng';
											|ru = 'настроить доступность';
											|en = 'set up availability'; fa = 'set up availability';
											|it = 'configurare l''accessibilità';
											|pl = 'ustaw dostępność';
											|tr = 'mevcutluğu ayarla'");
	Else
		Items.SetUpAvailability.Title = NStr("vi = 'thay đổi tính khả dụng';
											|ru = 'изменить доступность';
											|en = 'change availability'; fa = 'change availability';
											|it = 'modificare l''accessibilità';
											|pl = 'zmień dostępność';
											|tr = 'mevcutluğu değiştir'");
	EndIf;
	
	If Object.ReportsToDrillDown.Count() = 0 Then
		Items.CustomizeReports.Title = NStr("vi = 'tùy chỉnh báo cáo';
											|ru = 'настроить отчеты';
											|en = 'set up reports'; fa = 'set up reports';
											|it = 'impostare i report';
											|pl = 'ustaw raporty';
											|tr = 'raporları ayarla'");
	Else
		Items.CustomizeReports.Title = NStr("vi = 'thay đổi báo cáo';
											|ru = 'изменить отчеты';
											|en = 'change reports'; fa = 'change reports';
											|it = 'modificare i report';
											|pl = 'zmień raporty';
											|tr = 'raporları değiştir'");
	EndIf;
EndProcedure

&AtClientAtServerNoContext 
Procedure SetLabelsForSelectionAndOrderingSettings(SettingsComposer, Items)
	SettingsItems = SettingsComposer.UserSettings.Items;
	
	If HasUserSettings(SettingsItems) Then
		Items.ToConfigureTheSelectionsAndOrdering.Title = NStr("vi = 'xem / thay đổi';
																|ru = 'посмотреть / изменить';
																|en = 'view / change'; fa = 'view / change';
																|it = 'visualizzare / modificare';
																|pl = 'zobacz / zmień';
																|tr = 'görüntüle / değiştir'");
	Else
		Items.ToConfigureTheSelectionsAndOrdering.Title = NStr("vi = 'thiết lập';
																|ru = 'настроить';
																|en = 'customize'; fa = 'customize';
																|it = 'impostare';
																|pl = 'customize';
																|tr = 'ayarla'");
	EndIf;
EndProcedure

&AtClientAtServerNoContext 
Procedure SetListToSelectChartTypes(ComparisonTypesAndChartTypes, ChoiceList, AnalysisType)
	ChoiceList.Clear();
	
	SelectionByTypeOfComparison = New Structure("AnalysisType", AnalysisType);
	ChartTypesFound = ComparisonTypesAndChartTypes.FindRows(SelectionByTypeOfComparison);
	
	For Each CurFoundChartType In ChartTypesFound Do 
		ChoiceList.Add(CurFoundChartType.ChartType);
	EndDo;
EndProcedure

#EndRegion

#Region Other

&AtServer 
Function AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage()
	Return Catalogs.StructureOfTargets.AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage(Object.Owner);
EndFunction

&AtServer 
Procedure RestoreDCSSettingsForAnalysis()
	AnalysisOptionObject = FormAttributeToValue("Object");
	AvailableAnalysisObjects = Catalogs.StructureOfTargets.AvailableAnalysisObjects(Object.Owner);
	AvailableAnalysisValues = Catalogs.StructureOfTargets.AvailableAnalysisValues(Object.Owner);
	
	If Parameters.Property("CopyingValue") And Not Parameters.CopyingValue.IsEmpty() Then
		StorageOfDataCompositionUserSettings = Parameters.CopyingValue.StorageOfDataCompositionUserSettings;
		AnalysisObject = Parameters.CopyingValue.AnalysisObject.Get();
		AnalysisValue = Parameters.CopyingValue.AnalysisValue.Get();
		AnalysisValueAdditional = Parameters.CopyingValue.AnalysisValueAdditional.Get();
	Else	
		StorageOfDataCompositionUserSettings = AnalysisOptionObject.StorageOfDataCompositionUserSettings;
		If AnalysisObject = Undefined Then
			AnalysisObjectSaved = AnalysisOptionObject.AnalysisObject.Get();
			If AvailableAnalysisObjects.FindByValue(AnalysisObjectSaved) <> Undefined Then
				AnalysisObject = AnalysisObjectSaved;
			Else
				AnalysisOptionObject.AnalysisObject = New ValueStorage(Undefined);
			EndIf;
		EndIf;
		If AnalysisValue = Undefined Then
			AnalysisValueSaved = AnalysisOptionObject.AnalysisValue.Get();
			If AvailableAnalysisValues.FindByValue(AnalysisValueSaved) <> Undefined Then
				AnalysisValue = AnalysisValueSaved;
			Else
				AnalysisOptionObject.AnalysisValue = New ValueStorage(Undefined);
			EndIf;
		EndIf;
		If AnalysisValueAdditional = Undefined Then
			AnalysisValueAdditionalStored = AnalysisOptionObject.AnalysisValueAdditional.Get();
			If AvailableAnalysisValues.FindByValue(AnalysisValueAdditionalStored) <> Undefined Then
				AnalysisValueAdditional = AnalysisValueAdditionalStored;
			Else
				AnalysisOptionObject.AnalysisValueAdditional = New ValueStorage(Undefined);
			EndIf;
		EndIf;
	EndIf;
	AnalysisObject   = String(AnalysisObject);
	AnalysisValue = String(AnalysisValue);
	AnalysisValueAdditional = String(AnalysisValueAdditional);
	
	Addresses = AddressesOfDataLayoutSchemeAndSettingsInTemporaryStorage();
	
	If Not Addresses.DataCompositionSchema = Undefined Then
		Schema = GetFromTempStorage(Addresses.DataCompositionSchema);
		StorageOfDataCompositionSchema = New ValueStorage(Schema);
		
		If Not Addresses.DataCompositionSettings = Undefined Then
			DataCompositionSettings = GetFromTempStorage(Addresses.DataCompositionSettings);
			
			StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);
		Else
			StorageOfDataCompositionSettings = New ValueStorage(Schema.DefaultSettings);
		EndIf;
	EndIf;
	
	If Not Schema.Parameters.Find("RunningTotal") = Undefined Then
		CumulativeTotalIsAvailable = True;
	EndIf;
EndProcedure

&AtServer 
Procedure RestoreAnalysisPeriod()
	AnalysisOptionObject = FormAttributeToValue("Object");
	
	If Parameters.Property("CopyingValue") And Not Parameters.CopyingValue.IsEmpty() Then
		AnalysisPeriod = Parameters.CopyingValue.AnalysisPeriod.Get();
	Else
		AnalysisPeriod = AnalysisOptionObject.AnalysisPeriod.Get();
	EndIf;
EndProcedure

&AtServer 
Procedure RestoreComparisonPeriodServer()
	AnalysisOptionObject = FormAttributeToValue("Object");
	
	If Parameters.Property("CopyingValue") And Not Parameters.CopyingValue.IsEmpty() Then
		ComparisonPeriod = Parameters.CopyingValue.ComparisonPeriod.Get();
	Else
		ComparisonPeriod = AnalysisOptionObject.ComparisonPeriod.Get();
	EndIf;
EndProcedure

&AtClientAtServerNoContext 
Function HasUserSettings(CustomSettingsElements, ConsiderParameters = True)
	ThereIsUse = False;
	
	For Each SettingsItem In CustomSettingsElements Do 
		If TypeOf(SettingsItem) = Type("DataCompositionSettingsParameterValue") 
			And Not ConsiderParameters Then
			Continue;
		EndIf;
		
		If SettingsItem.Use Then
			ThereIsUse = True;
			Break;
		EndIf;
	EndDo;
	
	Return ThereIsUse;
EndFunction

&AtServer 
Procedure InitializeFormData()
	InitializeSettingsComposer();
	
	FillInListOfSelectedAnalysisObjects();
	
	FillInAnalysisValueSelectionList();
	
	If Object.DisplayOptionDefault.IsEmpty() Then
		Object.DisplayOptionDefault = Enums.DisplayOptionsOfAnalysisOptions.Chart;
		Modified = True;
	EndIf;
EndProcedure

&AtServer 
Procedure InitializeSettingsComposer()
	
	TimeDataLayoutSchemaStorage = StorageOfDataCompositionSchema; // ValueStorage
	DCSAnalysisOptions = TimeDataLayoutSchemaStorage.Get();
	
	DCSAddress = PutToTempStorage(DCSAnalysisOptions, New UUID());
	AvailableSettingsSource = New DataCompositionAvailableSettingsSource(DCSAddress);
	
	SettingsComposer.Initialize(AvailableSettingsSource);
	StorageOfTimeDataLayoutSettings = StorageOfDataCompositionSettings; // ValueStorage
	
	If Not StorageOfDataCompositionSettings = Undefined And Not StorageOfTimeDataLayoutSettings.Get() = Undefined Then
		SettingsComposer.LoadSettings(StorageOfTimeDataLayoutSettings.Get());
	Else
		SettingsComposer.LoadSettings(DCSAnalysisOptions.DefaultSettings);
	EndIf;
	
	StorageOfUserSettingsForLayoutOfTimeData = StorageOfDataCompositionUserSettings; // ValueStorage
	
	If Not StorageOfUserSettingsForLayoutOfTimeData.Get() = Undefined Then
		SettingsComposer.LoadUserSettings(StorageOfUserSettingsForLayoutOfTimeData.Get());
	EndIf;
	
	// Fill in the required currency calculation parameter for the SKD where it is and is not filled in
	CalculationCurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings, "SettlementCurrency");
	If Not CalculationCurrencyParameter = Undefined
	   And CalculationCurrencyParameter.Value = Catalogs.Currencies.EmptyRef() Then
		DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings,
			"SettlementCurrency",
			TargetValueMonitoring.GetDefaultCurrency(),
			True);
	EndIf;
EndProcedure


// Returns the availability table.
// 
// Parameters:
// 	AvailabilityTableStorage - ValueStorage - 
// Returns:
// 	ValueTable - with a column:
// 	 *Enabled - Boolean - availability flag.
&AtServer
Function AvailabilityTableFromValueStore(AvailabilityTableStorage)
	AvailabilityTable = AvailabilityTableStorage.Get();
	Return AvailabilityTable;
EndFunction

&AtServer 
Procedure FillInAccessibilitySettings(AddressOfAccessibilitySettings)
	AvailabilityTableStorage = GetFromTempStorage(AddressOfAccessibilitySettings);
	
	If Not AvailabilityTableStorage = Undefined Then
		AvailabilityTable = AvailabilityTableFromValueStore(AvailabilityTableStorage);
		
		AvailabilitySettings = Object.AvailabilitySettings;
		AvailabilitySettings.Clear();
		For Each AvailabilityLine In AvailabilityTable Do 
			If Not AvailabilityLine.Enabled Then
				Continue;
			EndIf;
			NewRow = AvailabilitySettings.Add();
			NewRow.User = AvailabilityLine.User;
			NewRow.ViewOption = AvailabilityLine.ViewOption;
		EndDo;
	EndIf;
EndProcedure

// Returns a table of records.
// 
// Parameters:
// 	ReportTableStorage - ValueStorage - 
// Returns:
// 	ValueTable - with a column:
// 	 *Enabled - Boolean - availability flag.
&AtServer
Function ReportTableFromValueStore(ReportTableStorage)
	ReportsTable = ReportTableStorage.Get();
	Return ReportsTable;
EndFunction

&AtServer 
Procedure FillInReportSettingsForDecryption(AddressOfReportSettings)
	ReportTableStorage = GetFromTempStorage(AddressOfReportSettings);
	
	If Not ReportTableStorage = Undefined Then
		ReportsTable = ReportTableFromValueStore(ReportTableStorage);
		
		ReportsToDrillDown = Object.ReportsToDrillDown;
		ReportsToDrillDown.Clear();
		For Each RowReport In ReportsTable Do 
			If Not RowReport.Enabled Then
				Continue;
			EndIf;
			NewRow = ReportsToDrillDown.Add();
			NewRow.ReportVariant = RowReport.ReportVariant;
		EndDo;
	EndIf;
EndProcedure

&AtServer 
Procedure FillInObjectAndDefaultAnalysisValue()
	AvailableAnalysisObjects = Catalogs.StructureOfTargets.AvailableAnalysisObjects(Object.Owner);
	AvailableAnalysisValues = Catalogs.StructureOfTargets.AvailableAnalysisValues(Object.Owner);
	
	AnalysisObject = AvailableAnalysisObjects[0].Value;
	AnalysisValue = AvailableAnalysisValues[0].Value;
EndProcedure

&AtServer 
Procedure FillInAnalysisValueSelectionList()
	AvailableFields = Catalogs.StructureOfTargets.AvailableAnalysisValues(Object.Owner);
	
	Items.AnalysisValue.ChoiceList.Clear();
	For Each AvailableField In AvailableFields Do 
		Items.AnalysisValue.ChoiceList.Add(String(AvailableField.Value), AvailableField.Presentation);
	EndDo;
	
	Items.AnalysisValueAdditional.ChoiceList.Clear();
	For Each AvailableField In AvailableFields Do
		If String(AvailableField.Value) = AnalysisValue Then
			Continue;
		EndIf;
		Items.AnalysisValueAdditional.ChoiceList.Add(String(AvailableField.Value), AvailableField.Presentation);
	EndDo;
EndProcedure

&AtServer 
Procedure FillInListOfSelectedAnalysisObjects()
	AvailableFields = Catalogs.StructureOfTargets.AvailableAnalysisObjects(Object.Owner);
	
	Items.AnalysisObject.ChoiceList.Clear();
	
	For Each AvailableField In AvailableFields Do 
		Items.AnalysisObject.ChoiceList.Add(String(AvailableField.Value), AvailableField.Presentation);
	EndDo;
EndProcedure

&AtServer 
Procedure OnReadCreateAtServer()
	If Not ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Parameters.CopyingValue) Then
			DecorationSettingStorage = Parameters.CopyingValue.DecorationSettingStorage;
			DemoDataStorage = Parameters.CopyingValue.DemoDataStorage;
			StorageOfDataCompositionUserSettings = Parameters.CopyingValue.StorageOfDataCompositionUserSettings;
		Else
			SetDefaultDesignSettings();
			
			FillInObjectAndDefaultAnalysisValue();
			
			DemoDataStorage = New ValueStorage(Undefined);
		EndIf;
	Else
		AnalysisOptionObject = FormAttributeToValue("Object");
		DecorationSettingStorage = AnalysisOptionObject.DecorationSettingStorage;
		DemoDataStorage = AnalysisOptionObject.DemoDataStorage;
	EndIf;
	
	
	ValueToFormData(TargetValueMonitoring.TypesOfAnalysisAndDiagrams(), MappingOfComparisonTypesAndChartTypes);
	
	SetListToSelectChartTypes(MappingOfComparisonTypesAndChartTypes,
			Items.ChartType.ChoiceList,
			Object.AnalysisType);
	
	SetLabelsToPeriodFields(Object, Items);
	
	SetInscriptionOfDecimalPlaces(Object.FractionalPartCalculationAccuracy, Items);
	
	RestoreAnalysisPeriod();
	
	RestoreComparisonPeriodServer();

	RestoreDCSSettingsForAnalysis();
	
	InitializeFormData();
	
	SetLabelsForSelectionAndOrderingSettings(SettingsComposer, Items);
	
	SetLabelsForAccessibilitySettingsAndReports(Object, Items);
	
	AnalysisObjectSelectionIsAvailable = Catalogs.StructureOfTargets.AvailableAnalysisObjects(Object.Owner).Count() > 0;
	AnalysisValueAdditionalSelectionIsAvailable =
		Catalogs.StructureOfTargets.AvailableAnalysisValues(Object.Owner).Count() > 1;
	
	SetVisibilityAccessibilityOfFormElements(MappingOfComparisonTypesAndChartTypes, Object, Items, ThisForm);
	
	SetAvailabilityOfFillingByTemplateServer();
EndProcedure

&AtServer 
Procedure SaveDCSSettingsForAnalysis(CurrentObject)
	If ValueIsFilled(AnalysisObject) Then
		CurrentObject.AnalysisObject = New ValueStorage(New DataCompositionField(AnalysisObject));
	EndIf;
	If ValueIsFilled(AnalysisValue) Then
		CurrentObject.AnalysisValue = New ValueStorage(New DataCompositionField(AnalysisValue));
	EndIf;
	If ValueIsFilled(AnalysisValueAdditional) Then
		CurrentObject.AnalysisValueAdditional = New ValueStorage(New DataCompositionField(AnalysisValueAdditional));
	EndIf;
	CurrentObject.StorageOfDataCompositionUserSettings = New ValueStorage(SettingsComposer.UserSettings);
EndProcedure

&AtServer 
Procedure SetDefaultDesignSettings()
	DecorationSettingStructure = Catalogs.AnalysisOptionsOfTargetValues.DefaultDesignSettings();
	
	If Not Parameters.CopyingValue.IsEmpty() Then
		DecorationSettingStorage = Parameters.CopyingValue.DecorationSettingStorage;
	Else
		DecorationSettingStorage = DecorationSettingStructure.DecorationSettingStorage;
		FillPropertyValues(Object, DecorationSettingStructure);
	EndIf;
EndProcedure

&AtServer 
Procedure SetAvailabilityOfFillingByTemplateServer()
	SelectionByTypeOfComparison = New Structure("AnalysisType", Object.AnalysisType);
	TheParametersOfThe = MappingOfComparisonTypesAndChartTypes.FindRows(SelectionByTypeOfComparison);
	
	If ValueIsFilled(Object.AnalysisType) 
		And ValueIsFilled(AnalysisValue)
		And ValueIsFilled(Object.ValueCalculationMethod) Then
		
		If TheParametersOfThe[0].AnalysisObjectIsAvailable Then
			If Not AnalysisObject = Undefined Then
				Items.FillInANameFromTemplate.Enabled = True;
			Else
				Items.FillInANameFromTemplate.Enabled = False;
			EndIf;
		Else 
			Items.FillInANameFromTemplate.Enabled = True;
		EndIf;
		
		Items.FillInANameFromTemplate.Enabled = True;
	Else
		Items.FillInANameFromTemplate.Enabled = False;
	EndIf;
EndProcedure

&AtClientAtServerNoContext 
Function SettingsByTypeOfAnalysisAndChart(AnalysisOption, MappingOfComparisonTypesAndChartTypes)
	DecorationSettingStructure = New Structure;
	DecorationSettingStructure.Insert("AnalysisType");
	DecorationSettingStructure.Insert("ChartType");
	DecorationSettingStructure.Insert("ComparisonPeriodIsAvailable");
	DecorationSettingStructure.Insert("AnalysisObjectIsAvailable");
	DecorationSettingStructure.Insert("TheDesignOfAComponentByComponentComparisonIsAvailable");
	DecorationSettingStructure.Insert("ForecastingIsAvailable");
	DecorationSettingStructure.Insert("DisplayPointMarkersAvailable");
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPointsAvailable");
	DecorationSettingStructure.Insert("DisplayChartCaptionsAvailable");
	DecorationSettingStructure.Insert("ChartBorderIsAvailable");
	DecorationSettingStructure.Insert("ChartSmoothingModeAvailable"); 

	SelectionByTypeOfAnalysisAndDiagram = New Structure;
	SelectionByTypeOfAnalysisAndDiagram.Insert("AnalysisType", AnalysisOption.AnalysisType);
	SelectionByTypeOfAnalysisAndDiagram.Insert("ChartType", AnalysisOption.ChartType);
	FoundSettings = MappingOfComparisonTypesAndChartTypes.FindRows(SelectionByTypeOfAnalysisAndDiagram);
	FillPropertyValues(DecorationSettingStructure, FoundSettings[0]);
	
	Return DecorationSettingStructure;
EndFunction

&AtClientAtServerNoContext 
Function SettingsByTypeOfAnalysis(AnalysisOption, MappingOfComparisonTypesAndChartTypes)
	DecorationSettingStructure  = New Structure;
	DecorationSettingStructure.Insert("AnalysisType");
	DecorationSettingStructure.Insert("ChartType");
	DecorationSettingStructure.Insert("ComparisonPeriodIsAvailable");
	DecorationSettingStructure.Insert("AnalysisObjectIsAvailable");
	DecorationSettingStructure.Insert("TheDesignOfAComponentByComponentComparisonIsAvailable");
	DecorationSettingStructure.Insert("ForecastingIsAvailable");
	DecorationSettingStructure.Insert("DisplayPointMarkersAvailable");
	DecorationSettingStructure.Insert("DisplayAMarkerOfForecastPointsAvailable");
	DecorationSettingStructure.Insert("DisplayChartCaptionsAvailable");
	DecorationSettingStructure.Insert("ChartBorderIsAvailable");
	DecorationSettingStructure.Insert("ChartSmoothingModeAvailable");
	
	SelectionByTypeOfAnalysis = New Structure("AnalysisType", AnalysisOption.AnalysisType);
	FoundSettings = MappingOfComparisonTypesAndChartTypes.FindRows(SelectionByTypeOfAnalysis);
	FillPropertyValues(DecorationSettingStructure, FoundSettings[0]);
	
	Return DecorationSettingStructure;
EndFunction

// MenuReports

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

#EndRegion
