#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Initializing the context
	FillPropertyValues(ThisForm, Parameters.StructureOfDemoDataSettings);
	StructureOfDemoDataSettings = Parameters.StructureOfDemoDataSettings;
	
	Items.ChartType.ChoiceList.LoadValues(Parameters.StructureOfDemoDataSettings.AvailableChartTypes);
	ChartType = StructureOfDemoDataSettings.ChartType;
	
	Items.IndicatorName.TitleLocation = FormItemTitleLocation.None;
	
	DecorationSettingStorage = DecorationSettingStructure.DecorationSettingStorage;
	NumberOfAnalysisObjects = Max(3, NumberOfAnalysisObjects);
	DemoDataStorage = Parameters.StructureOfDemoDataSettings.DemoDataStorage; // ValueStorage
	
	If DemoDataStorage = Undefined Then
		DemonstrationData = Undefined;
	Else
		DemonstrationData = DemoDataStorage.Get();
	EndIf;
	If DemonstrationData = Undefined Then
		// Demo data has not been entered yet
		InitializeRequiredData();
	ElsIf TypeOf(DemonstrationData) = Type("Structure") Then
		// Demo data was entered earlier
		DataStorage = DemonstrationData.Data; // ValueStorage
		If DataStorage.Get().Count() = 0 Then
			InitializeRequiredData();
		Else
			If Not StructureOfDemoDataSettings.SettingsRequiringAnUpdate.UpdateRequired Then
				If DemonstrationData.Property("NumberOfAnalysisObjects") Then
					NumberOfAnalysisObjects = DemonstrationData.NumberOfAnalysisObjects;
				EndIf;
				
				ValueToFormData(DataStorage.Get(), Data);
				
				UpdateChart();
			Else
				InitializeRequiredData();
			EndIf;
		EndIf;
	EndIf;
	
	ObjectOfAnalysisTypeDescription = Parameters.StructureOfDemoDataSettings.ObjectOfAnalysisTypeDescription;
	If ObjectOfAnalysisTypeDescription <> Undefined Then
		Items.DataAnalysisObject.TypeRestriction = ObjectOfAnalysisTypeDescription;
	EndIf;
	Items.DataAnalysisObject.Title = Parameters.StructureOfDemoDataSettings.ObjectOfAnalysisHeader;
	Items.DataIndicatorValue.TypeRestriction = Parameters.StructureOfDemoDataSettings.AnalysisValueTypeDescription;
	Items.DataIndicatorValue.Title = Parameters.StructureOfDemoDataSettings.ValueOfAnalysisHeader;
	Items.DataTheValueOfTheIndexForMore.TypeRestriction = Parameters.StructureOfDemoDataSettings.AnalysisValueAdditionalTypeDescription;
	Items.DataTheValueOfTheIndexForMore.Title = Parameters.StructureOfDemoDataSettings.ValueOfAnalysisIsAdditionalHeader;
	For Each DataString1 In Data Do 
		DataString1.AnalysisObject = Items.DataAnalysisObject.AvailableTypes.AdjustValue(DataString1.AnalysisObject);
		DataString1.IndicatorValue = Items.DataIndicatorValue.AvailableTypes.AdjustValue(DataString1.IndicatorValue);
		DataString1.TheValueOfTheIndexForMore = Items.DataTheValueOfTheIndexForMore.AvailableTypes.AdjustValue(DataString1.TheValueOfTheIndexForMore);
	EndDo;
	
	SetVisibilityAccessibilityOfFormElements();
	SetScaleOfFormElements();
	SetConditionalAppearance();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChartTypeOnChange(Item)
	Modified = True;
	
	UpdateChart();
EndProcedure

&AtClient
Procedure NumberOfAnalysisObjectsOnChange(Item)
	InitializeRequiredData();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersData

&AtClient
Procedure DataAnalysisObjectOnChange(Item)
	CurrentData = Items.Data.CurrentData;
	CurrentRow = Items.Data.CurrentRow;
	
	ResultingIndex = Data.IndexOf(Data.FindByID(CurrentRow)) + NumberOfAnalysisObjects;
	While ResultingIndex < Data.Count() Do 
		DataString1 = Data.Get(ResultingIndex);
		DataString1.AnalysisObject = CurrentData.AnalysisObject;
		
		ResultingIndex = ResultingIndex + NumberOfAnalysisObjects;
	EndDo;
EndProcedure

&AtClient
Procedure DataOnEditEnd(Item, NewRow, CancelEdit)
	UpdateChart();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAppearance(Command)
	FormParameters = New Structure("DecorationSettingStructure", DecorationSettingStructure);
	
	OpenForm("Catalog.AnalysisOptionsOfTargetValues.Form.AppearanceSetting", FormParameters,,,,, 
		New CallbackDescription("SetAppearanceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure FillInByInfobaseData(Command)
	Modified = True;
	
	FillingResult = FillInAccordingToInformationSecurityDataOnServer();
	If Not FillingResult.DataFilledIn Then
		WarningText = NStr("vi = 'Lỗi điền';
							|ru = 'Ошибка заполнения';
							|en = 'Filling error'; fa = 'خطای تکمیل';
							|it = 'Errore di compilazione';
							|pl = 'Błąd wypełnienia';
							|tr = 'Doldurma hatası'");
		ShowMessageBox(, FillingResult.ErrorDescription,,WarningText);
	EndIf;
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	Close(EditResult());
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetAppearanceCompletion(Result, AdditionalParameters) Export
	If Not Result = Undefined Then
		FillPropertyValues(DecorationSettingStructure, Result);
		
		DecorationSettingStorage = Result.DecorationSettingStorage;
		DecorationSettingStructure.Insert("DecorationSettingStorage", DecorationSettingStorage);
		
		Modified = True;
	EndIf;
	
	UpdateChart();
EndProcedure

&AtServer 
Function FillInAccordingToInformationSecurityDataOnServer()
	FillingResult = New Structure("ErrorDescription, DataFilledIn");
	
	DataSource = TargetValueMonitoring.GetAnalysisVariantDataSource(AnalysisOption, 
		Enums.DisplayOptionsOfAnalysisOptions.Chart,
		True);
		
	If Not DataSource.CalculationError Then
		PreparedData = DataSource.Data; // ValueTable - 
		TableColumn2 = PreparedData.Columns[String(StructureOfDemoDataSettings.AnalysisValue)]; // ValueTableColumn -
		TableColumn2.Name = "IndicatorValue";
		AnalysisType = Common.ObjectAttributeValue(AnalysisOption, "AnalysisType");
		If AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
			Or AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
			If StructureOfDemoDataSettings.ComponentWiseComparisonMode = 0 Then
				TableColumn2 = PreparedData.Columns[String(StructureOfDemoDataSettings.AnalysisObject)]; // ValueTableColumn -
				TableColumn2.Name = "AnalysisObject";
		Else
			TableColumn2 = PreparedData.Columns[String(StructureOfDemoDataSettings.AnalysisValueAdditional)]; // ValueTableColumn -
				TableColumn2.Name = "TheValueOfTheIndexForMore";
			EndIf;
		EndIf;
		If PreparedData.Columns.Find("Period") = Undefined Then
			PeriodsTable = PeriodsTable();
			PreparedData.Columns.Add("Period");
			PreparedData.FillValues(PeriodsTable[PeriodsTable.Count()-1].Period, "Period");
		EndIf;
		If PreparedData.Columns.Find("AnalysisObject") = Undefined Then
			PreparedData.Columns.Add("AnalysisObject");
		EndIf;
		If PreparedData.Columns.Find("TheValueOfTheIndexForMore") = Undefined Then
			PreparedData.Columns.Add("TheValueOfTheIndexForMore");
		EndIf;
		If AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
			PreparedData.Sort("Period Asc, AnalysisObject Asc");
		EndIf;

		ValueToFormData(PreparedData, Data);
		
		UpdateChart();
	EndIf;
	
	FillingResult.DataFilledIn = Not DataSource.CalculationError;
	FillingResult.ErrorDescription = DataSource.ErrorDescription;
	
	Return FillingResult;
EndFunction


&AtServer
Function EditResult()
	SettingsAndData = New Structure("Settings, Data");
	SettingsAndData.Insert("Settings", SettingsRequiringAnUpdate);
	SettingsAndData.Insert("Data", New ValueStorage(FormAttributeToValue("Data")));
	
	DemoDataStorage = New ValueStorage(SettingsAndData); 
	
	Result = New Structure;
	Result.Insert("Modified", Modified);
	Result.Insert("ChartType", ChartType);
	Result.Insert("NumberOfAnalysisObjects", NumberOfAnalysisObjects);
	Result.Insert("DecorationSettingStructure", DecorationSettingStructure);
	Result.Insert("DemoDataStorage", DemoDataStorage);
		
	Return Result;
EndFunction

// Returns the structure of the analysis option settings.
// 
// Parameters:
// 	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Analysis option.
// Returns:
// 	Structure - LongDesc:
// * Include_2Zero - Boolean -
// * ValueScaleMode - EnumRef.ChartValueScaleMode -
// * StorageOfDataCompositionUserSettings - ValueStorage - 
// * DecorationSettingStorage - ValueStorage -
// * OnlyColorOfMainBatch - Boolean -
// * ChartSmoothingMode - Boolean -
// * ShowLegend - Boolean -
// * ChartBorder - Boolean -
// * GradientForComponentWiseComparison - Boolean -
// * HighlightMaximumValueForComponentWiseComparison - Boolean -
// * DisplayChartCaptions - Boolean -
// * DisplayAMarkerOfForecastPoints - Boolean -
// * DisplayValuePointMarkers - Boolean -
// * ValueMultiplier - EnumRef.NumberPresentationKinds -
// * FractionalPartCalculationAccuracy - Number -
// * ComponentWiseComparisonMode - Number -
// * AnalysisValueAdditional - ValueStorage -
// * AnalysisObject - ValueStorage -
// * AnalysisValue - ValueStorage -
// * ForecastHorizon - Number -
// * ForecastAnalysisDepth - Number -
// * CalculateForecast - Boolean -
// * Owner - ChartOfCharacteristicTypesRefChartOfCharacteristicTypesName, ChartOfAccountsRefChartOfAccountsName, ChartOfCalculationTypesRefChartOfCalculationTypesName, ExchangePlanRefExchangePlanName, Undefined, CatalogRef.AnalysisOptionsOfTargetValues -
// * ValueCalculationMethod - EnumRef.CalculationMethodsOfTargetValueAnalysisOptions -
// * IndicatorCalculationFrequency - EnumRef.Periodicity -
// * ComparisonPeriod - ValueStorage -
// * AnalysisPeriod - ValueStorage -
// * AnalysisType - EnumRef.IndicatorAnalysisTypes -
// * Ref - CatalogRef.AnalysisOptionsOfTargetValues -
&AtServer
Function IndicatorParameters(AnalysisOption)
	IndicatorParameters = Common.ObjectAttributesValues(AnalysisOption, "AnalysisType, AnalysisPeriod, ComparisonPeriod, IndicatorCalculationFrequency,
																					 |ValueCalculationMethod, Owner, CalculateForecast, ForecastAnalysisDepth, ForecastHorizon, AnalysisValue, AnalysisObject,
																					 |AnalysisValueAdditional, ComponentWiseComparisonMode, FractionalPartCalculationAccuracy, ValueMultiplier, ValueScaleMode");
	IndicatorParameters.Insert("Ref", AnalysisOption);
	IndicatorParameters.Insert("ChartType", ChartType);
	
	IndicatorParameters.Insert("DisplayValuePointMarkers", False);
	IndicatorParameters.Insert("DisplayAMarkerOfForecastPoints", False);
	IndicatorParameters.Insert("DisplayChartCaptions", False);
	IndicatorParameters.Insert("HighlightMaximumValueForComponentWiseComparison", False);
	IndicatorParameters.Insert("GradientForComponentWiseComparison", False);
	IndicatorParameters.Insert("ChartBorder", False);
	IndicatorParameters.Insert("ShowLegend", False);
	IndicatorParameters.Insert("ChartSmoothingMode", False);
	IndicatorParameters.Insert("OnlyColorOfMainBatch", False);
	IndicatorParameters.Insert("DecorationSettingStorage", Undefined);
	IndicatorParameters.Insert("StorageOfDataCompositionUserSettings", StorageOfDataCompositionUserSettings);
	
	IndicatorParameters.Insert("Include_2Zero", False);
	
	FillPropertyValues(IndicatorParameters, DecorationSettingStructure);
	
	Return IndicatorParameters;
EndFunction

&AtServer 
Function PeriodsTable()
	// We will get the data
	ThereIsComparison = False;
	IndicatorCalculationFrequency = SettingsRequiringAnUpdate.IndicatorCalculationFrequency;
	AnalysisPeriod = SettingsRequiringAnUpdate.AnalysisPeriod; // StandardPeriod - 
	ComparisonPeriod = SettingsRequiringAnUpdate.ComparisonPeriod; // StandardPeriod - 
	
	If SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
		ThereIsComparison = True;
	EndIf;
	
	PeriodsTable = TargetValueMonitoring.PeriodsOfGivenPeriodicity(AnalysisPeriod.StartDate, AnalysisPeriod.EndDate, IndicatorCalculationFrequency);
	If ThereIsComparison Then
		PeriodsTable = TargetValueMonitoring.AddPeriodsToTable(PeriodsTable, ComparisonPeriod.StartDate, ComparisonPeriod.EndDate, IndicatorCalculationFrequency);
	EndIf;
	
	Return PeriodsTable;
EndFunction

&AtServer
Function SourceOfDemoData(AnalysisOption) Export
	PreparedData = FormAttributeToValue("Data");
	
	PreparedData.Columns.IndicatorValue.Title = StructureOfDemoDataSettings.ValueOfAnalysisHeader;
	PreparedData.Columns.IndicatorValue.Name = StructureOfDemoDataSettings.AnalysisValue;
	
	DataOfAnalysisVariant = Common.ObjectAttributesValues(AnalysisOption, "AnalysisType, ComponentWiseComparisonMode");
	
	If DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		Or DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
		If DataOfAnalysisVariant.ComponentWiseComparisonMode = 0 Then
			PreparedData.Columns.AnalysisObject.Title = StructureOfDemoDataSettings.ObjectOfAnalysisHeader;
			PreparedData.Columns.AnalysisObject.Name = StructureOfDemoDataSettings.AnalysisObject;
			
			PreparedData.Columns.Delete(PreparedData.Columns.Find("TheValueOfTheIndexForMore"))
		Else
			PreparedData.Columns.TheValueOfTheIndexForMore.Title = StructureOfDemoDataSettings.ValueOfAnalysisIsAdditionalHeader;
			PreparedData.Columns.TheValueOfTheIndexForMore.Name = StructureOfDemoDataSettings.AnalysisValueAdditional;
			
			PreparedData.Columns.Delete(PreparedData.Columns.Find("AnalysisObject"))
		EndIf;
	EndIf;
	If DataOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure Then
		If DataOfAnalysisVariant.ComponentWiseComparisonMode = 0 Then
			LastDate = PreparedData[0].Period;
			PreparedData.FillValues(Undefined, "Period");
			
			SummaryOfTable = PreparedData.Total(String(StructureOfDemoDataSettings.AnalysisValue));
			NewRow = PreparedData.Add();
			NewRow.Period = LastDate;
			NewRow[String(StructureOfDemoDataSettings.AnalysisValue)] = SummaryOfTable;
			If DataOfAnalysisVariant.ComponentWiseComparisonMode = 1 Then
				ResultOfTableIsAdditional = PreparedData.Total(String(StructureOfDemoDataSettings.AnalysisValueAdditional));
				NewRow[String(StructureOfDemoDataSettings.AnalysisValueAdditional)] = ResultOfTableIsAdditional;
			EndIf;
		Else
		EndIf;
	EndIf;
	
	IndicatorParameters = IndicatorParameters(AnalysisOption);
	FillPropertyValues(IndicatorParameters, StructureOfDemoDataSettings, "AnalysisObject, AnalysisValue, AnalysisValueAdditional");
	
	DataSource = TargetValueMonitoring.GetDataSourceOfAnalysisVariantFromDemoData(IndicatorParameters, Enums.DisplayOptionsOfAnalysisOptions.Chart, , PreparedData);
	
	Return DataSource;
EndFunction

&AtServer 
Procedure InitializeRequiredData()
	PeriodsTable = New ValueTable;
	
	PeriodsTable = PeriodsTable();
	
	Data.Clear();
	If SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends
		Or SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then 
		For Each PeriodTableRow In PeriodsTable Do 
			NewDataLine = Data.Add();
			NewDataLine.Period = PeriodTableRow.Period;
		EndDo;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure Then
		If SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 0 Then
			For Counter = 1 To NumberOfAnalysisObjects Do 
				NewDataLine = Data.Add();
				NewDataLine.Period = PeriodsTable[PeriodsTable.Count()-1].Period;
			EndDo;
		Else
			For Each PeriodTableRow In PeriodsTable Do 
				NewDataLine = Data.Add();
				NewDataLine.Period = PeriodTableRow.Period;
			EndDo;
		EndIf;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
		If SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 0 Then
			For Each PeriodTableRow In PeriodsTable Do 
				For Counter = 1 To NumberOfAnalysisObjects Do 
					NewDataLine = Data.Add();
					NewDataLine.Period = PeriodTableRow.Period;
				EndDo;
			EndDo;
		Else
			For Each PeriodTableRow In PeriodsTable Do 
				NewDataLine = Data.Add();
				NewDataLine.Period = PeriodTableRow.Period;
			EndDo;
		EndIf;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then 
		For Each PeriodTableRow In PeriodsTable Do 
			NewDataLine = Data.Add();
			NewDataLine.Period = PeriodTableRow.Period;
		EndDo;
	EndIf;
EndProcedure

&AtServer 
Procedure UpdateChart()
	DataSource = SourceOfDemoData(AnalysisOption);
	
	If DataSource.Data.Count() > 0 Then
		Chart.Clear();
		
		IndicatorParameters = IndicatorParameters(AnalysisOption);
	
		SetNameOfIndicator(IndicatorParameters, DataSource);
		Chart = TargetValueMonitoring.FillInChartForMonitor(Chart, AnalysisOption, DataSource);
	EndIf;
EndProcedure

&AtServer
Function BasicTextScale()
	Return 100;
EndFunction

&AtServer
Function FontOfIndicatorHeaderIsImportant()
	Return New Font(,, True,,,, BasicTextScale());
EndFunction


// LongDesc
// 
// Parameters:
// 	IndicatorParameters - See IndicatorParameters
// 	DataSource - See TargetValueMonitoring.GetDataSourceOfAnalysisVariantFromDemoData
&AtServer 
Procedure SetNameOfIndicator(IndicatorParameters, DataSource)
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	ValueMultiplier = IndicatorParameters.ValueMultiplier;
	
	StateAndTrendColors = TargetValueMonitoring.GetStateAndTrendIndicatorColors(IndicatorParameters, DataSource);

	TrafficLightMarker = New FormattedString("●" + Chars.NBSp, FontOfIndicatorHeaderIsImportant(), StateAndTrendColors.StateColor);
	LineSplitter = " ";
	
	NameOfAnalysisOption = New FormattedString(Common.ObjectAttributeValue(
		IndicatorParameters.Ref, "Description"), FontOfIndicatorHeaderIsImportant());
	
	ArrayOfNameStrings = New Array;
	If DataSource.PropertiesOfAnalysisAndTrendZone.Status = "UnacceptableState"
		Or DataSource.PropertiesOfAnalysisAndTrendZone.Status = "AcceptableState"
		Or DataSource.PropertiesOfAnalysisAndTrendZone.Status = "TheGoalIsAchieved" Then
		
		ArrayOfNameStrings.Add(TrafficLightMarker);
	EndIf;
	ArrayOfNameStrings.Add(NameOfAnalysisOption);
	If Not ValueMultiplier = NumberPresentationKinds.Unchanged 
		And ValueIsFilled(ValueMultiplier) Then
		ArrayOfNameStrings.Add(LineSplitter);
		MultiplicityParameters = New Structure("ValueMultiplier", ValueMultiplier);
		StringOfMultiplicityParameters = New FormattedString(
			TargetValueMonitoring.GetNumberPresentationString(MultiplicityParameters));
		ArrayOfNameStrings.Add(StringOfMultiplicityParameters);
	EndIf;
	
	TextPresentationOfPeriod = TargetValueMonitoring.PresentationOfAnalysisVariantPeriod(DataSource);
	If Not TextPresentationOfPeriod = Undefined Then
		ArrayOfNameStrings.Add(LineSplitter);
		PeriodPresentationString = New FormattedString(
			TextPresentationOfPeriod);
		ArrayOfNameStrings.Add(PeriodPresentationString);
	EndIf;
	
	IndicatorName = New FormattedString(ArrayOfNameStrings);
EndProcedure

&AtServer 
Procedure SetVisibilityAccessibilityOfFormElements()
	If SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends Then
		Items.DataPeriod.Visible = True;
		Items.DataAnalysisObject.Visible = False;
		Items.NumberOfAnalysisObjects.Visible = False;
		Items.DataTheValueOfTheIndexForMore.Visible = False;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
		Items.DataPeriod.Visible = True;
		Items.DataAnalysisObject.Visible = SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 0;
		Items.NumberOfAnalysisObjects.Visible = SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 0;
		Items.DataTheValueOfTheIndexForMore.Visible = SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 1;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure Then
		Items.DataPeriod.Visible = False;
		Items.DataAnalysisObject.Visible = SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 0;
		Items.NumberOfAnalysisObjects.Visible = SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 0;
		Items.DataTheValueOfTheIndexForMore.Visible = SettingsRequiringAnUpdate.ComponentWiseComparisonMode = 1;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
		Items.DataPeriod.Visible = True;
		Items.DataAnalysisObject.Visible = False;
		Items.NumberOfAnalysisObjects.Visible = False;
		Items.DataTheValueOfTheIndexForMore.Visible = False;
	ElsIf SettingsRequiringAnUpdate.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then
		Items.DataPeriod.Visible = True;
		Items.DataAnalysisObject.Visible = False;
		Items.NumberOfAnalysisObjects.Visible = False;
		Items.DataTheValueOfTheIndexForMore.Visible = False;
	EndIf;
EndProcedure

&AtServer 
Procedure SetScaleOfFormElements()
	ClientSettings = New ClientSettings;
	
	TaxiInterface = (ClientSettings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Taxi);
	ScaleCompact = (ClientSettings.ClientApplicationFormScaleVariant = ClientApplicationFormScaleVariant.Compact);
	
	If Not TaxiInterface Or ScaleCompact Then
		Items.ChartType.Width = 39;
	Else
		Items.ChartType.Width = 35;
	EndIf;
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();

	ColorOfBlankData = StyleColors.EmptyTableField;
	TextOfBlankData = NStr("vi = '<Giá trị = 0>';
							|ru = '<Значение = 0>';
							|en = '<Value = 0>'; fa = '<Value = 0>';
							|it = '<Valore = 0>';
							|pl = '<Wartość = 0>';
							|tr = '<Değer = 0>'");

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DataIndicatorValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Data.IndicatorValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", ColorOfBlankData);
	Item.Appearance.SetParameterValue("Text", TextOfBlankData);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DataTheValueOfTheIndexForMore.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Data.TheValueOfTheIndexForMore");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("TextColor", ColorOfBlankData);
	Item.Appearance.SetParameterValue("Text", TextOfBlankData);
EndProcedure

#EndRegion