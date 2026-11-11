#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var PageNumbering; // Number - 
Var CurrentVersionOfClientApplicationInterface; // ClientApplicationInterfaceVariant -

#EndRegion

#Region Internal

Function SettingsStructure(Var_SettingsComposer) Export
	SettingsStructure = New Structure;
	SettingsStructure.Insert("IndicatorGroupingOption", "");
	SettingsStructure.Insert("NumberOfIndicatorMonitorColumns", 0);
	SettingsStructure.Insert("SelectedAnalysisOptions");
	SettingsStructure.Insert("SelectedAnalysisOptionsAdvanced");
	SettingsStructure.Insert("ControlCycle", Enums.Periodicity.EmptyRef());
	SettingsStructure.Insert("FilterStatus", "");
		
	UserSettings = Var_SettingsComposer.UserSettings;
		
	Settings = UserSettings.Items;
	For Each Setting In Settings Do
		SettingName = String(Setting.Parameter);
		
		SettingsStructure[SettingName] = Setting.Value;
	EndDo;
	
	If UserSettings.AdditionalProperties.Property("SelectedAnalysisOptionsAdvanced") Then
		ValueTable = TMCommonUse.ArrayToValueTable(UserSettings.AdditionalProperties.SelectedAnalysisOptionsAdvanced);
	Else
		ValueTable = New ValueTable;
		
		TypeDetails = New TypeDescription("CatalogRef.AnalysisOptionsOfTargetValues");
		ValueTable.Columns.Add("AnalysisOption", TypeDetails);
		
		TypeDetails = New TypeDescription("EnumRef.DisplayOptionsOfAnalysisOptions");
		ValueTable.Columns.Add("ViewOption", TypeDetails);
		
		TypeDetails = New TypeDescription("Boolean");
		ValueTable.Columns.Add("Details_3", TypeDetails);
		ValueTable.Columns.Add("Enabled", TypeDetails);
		ValueTable.Columns.Add("TableSummary", TypeDetails);
		
		TypeDetails = New TypeDescription("EnumRef.IndicatorAnalysisTypes");
		ValueTable.Columns.Add("AnalysisType", TypeDetails);
		
		ParameterSelectionOfAnalysisOptions = DataCompositionClientServer.GetParameter(Var_SettingsComposer.FixedSettings, "AnalysisOptionFilter");
		If ParameterSelectionOfAnalysisOptions <> Undefined 
			And ParameterSelectionOfAnalysisOptions.Use Then
			AnalysisOptionFilter = ParameterSelectionOfAnalysisOptions.Value;
		Else
			AnalysisOptionFilter = Undefined;
		EndIf; 
		
		// Provided that the selection of analysis options is a single value
		NewRow = ValueTable.Add();
		NewRow.AnalysisOption = AnalysisOptionFilter;
		NewRow.Enabled = True;
	EndIf;
	
	SettingsStructure.SelectedAnalysisOptionsAdvanced = ValueTable;
	
	Return SettingsStructure;
EndFunction

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	ReportIsBlank = False;
	
	// Receiving the configuration
	Settings = SettingsStructure(SettingsComposer);
	
	// Getting data sources
	MonitorCompositionParameters = TargetValueMonitoringClientServer.InitializingMonitorCompositionParameters();
	
	MonitorCompositionParameters.AnalysisModeOfTheRelated  = False;
	
	ParameterSelectionOfAnalysisOptions = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "AnalysisOptionFilter");
	If ParameterSelectionOfAnalysisOptions <> Undefined
		And ParameterSelectionOfAnalysisOptions.Use Then
		MonitorCompositionParameters.AnalysisOptionFilter = ParameterSelectionOfAnalysisOptions.Value;
	Else
		MonitorCompositionParameters.AnalysisOptionFilter = Undefined;
	EndIf;
	
	MonitorCompositionParameters.ForceUpdateData  = False;
	
	Dashboard = Undefined;
	SettingsComposer.UserSettings.AdditionalProperties.Property("Dashboard", Dashboard);
	SettingsStructure = TargetValueMonitoring.GetGoalMonitorSettings(Dashboard, PrintMode);
	SettingsStructure.AnalysisOptionsCustomSettings = New ValueStorage(Settings.SelectedAnalysisOptionsAdvanced);
	SettingsStructure.Insert("IndicatorGroupingOption", Settings.IndicatorGroupingOption);
	SettingsStructure.Insert("NumberOfIndicatorMonitorColumns", Settings.NumberOfIndicatorMonitorColumns);
	MonitorCompositionParameters.SettingsStructure = SettingsStructure ;
	
	MonitorCompositionParameters.FilterStatus  = Settings.FilterStatus;
	MonitorCompositionParameters.ControlCycle = Settings.ControlCycle;
	MonitorCompositionParameters.ConsiderDisplayOptions = True;
	MonitorCompositionParameters.DemoMode = DataCompositionClientServer.GetParameter(
		SettingsComposer.FixedSettings, "DemoMode").Value;
	
	TargetValueMonitoring.GetMonitorComposition(MonitorCompositionParameters);
	
	// Formation of a filtered composition of indicators
	StorageAddress = PutToTempStorage(Undefined, New UUID);
	
	// In the file mode of operation, we perform the operation directly (synchronously).
	TargetValueMonitoring.PrepareDataForFilling(MonitorCompositionParameters, StorageAddress);
		
	// Output of data sources to a tabular document
	Result = GetFromTempStorage(StorageAddress);
	If TypeOf(Result) = Type("Structure")
		And Result.Property("Monitor") Then
		MonitorContent = CompositionOfMonitorFromResultOfDataPreparation(Result, MonitorCompositionParameters);
		
		GenerateReport(ResultDocument, MonitorContent, ReportIsBlank);
	EndIf;
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
EndProcedure

#EndRegion

#Region Private

// Returns the composition of the monitor.
// 
// Parameters:
// 	ResultOfDataPreparation - Structure - 
// 	 * Monitor-Structure - 
// 	MonitorCompositionParameters - See TargetValueMonitoringClientServer.InitializingMonitorCompositionParameters
// Returns:
// 	Structure - with the property:
// 	 *Parameters - See TargetValueMonitoringClientServer.InitializingMonitorCompositionParameters
Function CompositionOfMonitorFromResultOfDataPreparation(ResultOfDataPreparation, MonitorCompositionParameters)
	MonitorContent = ResultOfDataPreparation.Monitor;
	MonitorContent.Insert("Parameters", MonitorCompositionParameters);
	Return MonitorContent;
EndFunction

#Region OutputOfPrintedFormElements

Procedure OutputIndentation(ResultDocument, Template)
	Area = Template.GetArea("IndentLine");
	ResultDocument.Put(Area);
EndProcedure

Procedure PrintTitle_1(ResultDocument, Template)
	Area = Template.GetArea("Title");
	
	AreaProperties = New Structure("Title", NStr("vi = 'Màn hình chỉ số mục tiêu';
												|ru = 'Монитор целевых показателей';
												|en = 'Performance dashboard'; fa = 'داشبورد عملکرد';
												|it = 'Monitor degli indici obiettivo';
												|pl = 'Monitor wskaźników celowych';
												|tr = 'Performans paneli'"));
	FillPropertyValues(Area.Parameters, AreaProperties); 
	
	OutputIndentation(ResultDocument, Template);
	ResultDocument.Put(Area);
	OutputIndentation(ResultDocument, Template);
EndProcedure


// Outputs report parameters to a table document.
// 
// Parameters:
// 	ResultDocument - SpreadsheetDocument - tables document the results.
// 	Template - SpreadsheetDocument - layout.
// 	MonitorContent - See CompositionOfMonitorFromResultOfDataPreparation
//
Procedure Output_Parameters(ResultDocument, Template, MonitorContent)
	Area = Template.GetArea("Parameters");
	Parameters = MonitorContent.Parameters;
	
	ControlCycle = "";
	State = "";
	
	If Parameters.ControlCycle = Enums.Periodicity.Day Then
		ControlCycle = NStr("vi = 'Hàng tháng';
							|ru = 'Ежемесячные';
							|en = 'Monthly'; fa = 'ماهانه';
							|it = 'Mensili';
							|pl = 'Comiesięczne';
							|tr = 'Aylıklar'");
	ElsIf Parameters.ControlCycle = Enums.Periodicity.Week Then
		ControlCycle = NStr("vi = 'Hàng tuần';
							|ru = 'Еженедельные';
							|en = 'Weekly'; fa = 'هفتگی';
							|it = 'Settimanali';
							|pl = 'Cotygodniowe';
							|tr = 'Haftalıklar'");
	ElsIf Parameters.ControlCycle = Enums.Periodicity.TenDays Then
		ControlCycle = NStr("vi = 'Theo mười ngày một';
							|ru = 'Подекадные';
							|en = 'Occurring every ten days'; fa = 'هر ده روز';
							|it = 'Ogni decade';
							|pl = 'Co dekadę';
							|tr = 'On günlükler'");
	ElsIf Parameters.ControlCycle = Enums.Periodicity.Month Then
		ControlCycle = NStr("vi = 'Hàng tháng';
							|ru = 'Ежемесячные';
							|en = 'Monthly'; fa = 'ماهانه';
							|it = 'Mensili';
							|pl = 'Comiesięczne';
							|tr = 'Aylıklar'");
	ElsIf Parameters.ControlCycle = Enums.Periodicity.Quarter Then
		ControlCycle = NStr("vi = 'Hàng quý';
							|ru = 'Ежеквартальные';
							|en = 'Quarterly'; fa = 'فصلی';
							|it = 'Trimestrali';
							|pl = 'Co kwartał';
							|tr = 'Üç aylıklar'");
	ElsIf Parameters.ControlCycle = Enums.Periodicity.HalfYear Then
		ControlCycle = NStr("vi = 'Nửa năm';
							|ru = 'Полугодичные';
							|en = 'Semi-annual'; fa = 'شش‌ماهه';
							|it = 'Semestrale';
							|pl = 'Półroczne';
							|tr = 'Altı aylık dönemler'");
	ElsIf Parameters.ControlCycle = Enums.Periodicity.Year Then
		ControlCycle = NStr("vi = 'Hàng năm';
							|ru = 'Ежегодные';
							|en = 'Annual'; fa = 'سالانه';
							|it = 'Annuali';
							|pl = 'Coroczne';
							|tr = 'Yıllıklar'");
	EndIf;
	
	If Parameters.FilterStatus = "CalculatedWithErrors" Then
		State = NStr("vi = 'có lỗi trong tính toán';
					|ru = 'есть ошибки в расчете';
					|en = 'there are calculation errors'; fa = 'there are calculation errors';
					|it = 'Ci sono degli errori nel calcolo';
					|pl = 'w obliczeniach występują błędy';
					|tr = 'hesaplamada hatalar mevcut'");
	ElsIf Not Parameters.FilterStatus = "CalculatedWithErrors" 
		And ValueIsFilled(Parameters.FilterStatus) Then
		State = Lower(TargetValueMonitoring.StatusPresentation(Parameters.FilterStatus));
	EndIf;
	
	If ValueIsFilled(ControlCycle) Or ValueIsFilled(State) Then
		If ValueIsFilled(ControlCycle) And ValueIsFilled(State) Then
			StringParameterValues = NStr("vi = '%1 chỉ số với %2';
										|ru = '%1 показатели, у которых %2';
										|en = '%1 indicators which %2'; fa = '%1 indicators which %2';
										|it = '%1 indicatori ai quali %2';
										|pl = '%1 wskaźniki, u których %2';
										|tr = '%2 olan %1 göstergeler'");
		ElsIf Not ValueIsFilled(ControlCycle) And ValueIsFilled(State) Then
			StringParameterValues = NStr("vi = 'Chỉ tiêu, %2 số liệu';
										|ru = 'Показатели, у которых %2';
										|en = 'Indicators with %2'; fa = 'Indicators with %2';
										|it = 'Indicatori ai quali%2';
										|pl = 'Wskaźniki, u których %2';
										|tr = '%2 olan göstergeler'");
		ElsIf ValueIsFilled(ControlCycle) And Not ValueIsFilled(State) Then
			StringParameterValues = NStr("vi = '%1 chỉ số';
										|ru = '%1 показатели';
										|en = '%1 indicators'; fa = '%1 indicators';
										|it = '%1 Indicatori';
										|pl = '%1 wskaźniki';
										|tr = '%1 göstergeler'");
		EndIf;
		
		StringParameterValues = StringFunctionsClientServer.SubstituteParametersToString(StringParameterValues, ControlCycle, State);
		
		AreaProperties = New Structure("ParameterValues_2", StringParameterValues);
		FillPropertyValues(Area.Parameters, AreaProperties); 

		ResultDocument.Put(Area);
	EndIf;
EndProcedure

Procedure PrintFormationDateAndTime(ResultDocument, Template)
	Area = Template.GetArea("DateAndTimeOfFormation");
	
	AreaProperties = New Structure("HeaderGenerated, DateAndTimeOfFormation", 
		NStr("vi = 'Đã lập báo cáo';
			|ru = 'Сформирован';
			|en = 'Generated'; fa = 'ایجادشده';
			|it = 'Generato';
			|pl = 'Wygenerowany';
			|tr = 'Oluşturuldu'")+ ":",
		CurrentSessionDate());
	FillPropertyValues(Area.Parameters, AreaProperties); 

	ResultDocument.Put(Area);
EndProcedure

Procedure PrintGroupTitle(ResultDocument, Template, GroupPresentation, Color = Undefined)
	Area = Template.GetArea("GroupTitle");
	
	If Color <> Undefined Then
		Area.Area("R1C2").TextColor = Color;
	EndIf;
	
	AreaProperties = New Structure("GroupTitle", GroupPresentation);
	FillPropertyValues(Area.Parameters, AreaProperties); 

	OutputIndentation(ResultDocument, Template);
	ResultDocument.Put(Area);
	ResultDocument.StartRowGroup();
	OutputIndentation(ResultDocument, Template);
EndProcedure


// Displays monitor elements in a tabular document.
// 
// Parameters:
// 	ResultDocument - SpreadsheetDocument - tables document the results.
// 	Template - SpreadsheetDocument - layout.
// 	MonitorContent - See CompositionOfMonitorFromResultOfDataPreparation
// 	OutputStructure - See TargetValueMonitoring.OutputStructure
Procedure DisplayMonitorElements(ResultDocument, Template, MonitorContent, OutputStructure)
	// Output of the header and parameters
	PrintTitle_1(ResultDocument, Template);
	Output_Parameters(ResultDocument, Template, MonitorContent);
	PrintFormationDateAndTime(ResultDocument, Template);
	
	// Output of indicators
	Parameters = MonitorContent.Parameters;
	SettingsStructure = Parameters.SettingsStructure;
	
	If Parameters.AnalysisModeOfTheRelated Then
		For Each OutputItem In OutputStructure.OutputOrder Do
			If OutputStructure[OutputItem].Count() > 0 Then
				IndicatorGroup_ = OutputItem;
				
				PrintGroupTitle(ResultDocument, Template, IndicatorGroup_);
				OutputGroupElements(ResultDocument, Template, OutputStructure[OutputItem], SettingsStructure.NumberOfIndicatorMonitorColumns);
				
				ResultDocument.EndRowGroup();
			EndIf;
		EndDo;
	Else 
		If SettingsStructure.IndicatorGroupingOption = "ByState" Then
			For Each OutputItem In OutputStructure.OutputOrder Do
				State = StrReplace(StrReplace(StrReplace(OutputItem, "Indicators", ""), "Brief1", ""), "More", "");
				If OutputStructure[OutputItem].Count() > 0 Then
					IndicatorGroup_ = TargetValueMonitoring.StatusPresentation(State);
					
					PrintGroupTitle(ResultDocument, Template, IndicatorGroup_, StateColor(State));
					OutputGroupElements(ResultDocument, Template, OutputStructure[OutputItem], SettingsStructure.NumberOfIndicatorMonitorColumns);
					
					ResultDocument.EndRowGroup();
				EndIf;
			EndDo;
		ElsIf SettingsStructure.IndicatorGroupingOption = "ByGoalCategory" Then
			For Each OutputItem In OutputStructure.OutputOrder Do
				Id = StrReplace(StrReplace(StrReplace(OutputItem, "Indicators", ""), "Brief1", ""), "More", "");
				GoalCategoryID = TargetValueMonitoring.StringInUniqueIdentifier(Id);
				TargetCategory = Catalogs.GoalCategory.GetRef(GoalCategoryID);
				If OutputStructure[OutputItem].Count() > 0 Then
					IndicatorGroup_ = TargetCategory;
					
					PrintGroupTitle(ResultDocument, Template, IndicatorGroup_);
					OutputGroupElements(ResultDocument, Template, OutputStructure[OutputItem], SettingsStructure.NumberOfIndicatorMonitorColumns);
					
					ResultDocument.EndRowGroup();
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	OutputIndentation(ResultDocument, Template);
EndProcedure

Procedure OutputGroupElements(ResultDocument, Template, CollectionOfAnalysisOptions, NumberOfIndicatorMonitorColumns)
	CounterOfLineElements = 1;
	LineCounter = 1;
	RowsCount = Int(CollectionOfAnalysisOptions.Count()/NumberOfIndicatorMonitorColumns) 
		+ Min(CollectionOfAnalysisOptions.Count()% NumberOfIndicatorMonitorColumns, 1);
	
	For Each MonitorElement In CollectionOfAnalysisOptions Do 
		AnalysisOption = MonitorElement.AnalysisOption;
		DataSourceStorage = MonitorElement.DataSource; // ValueStorage
		DataSource = DataSourceStorage.Get();
		ViewOption = MonitorElement.ViewOption;
		DisplayTableTotal = MonitorElement.DisplayTableTotal;
		DisplayDetails = MonitorElement.DisplayDetails;
		
		// Let's fill the element with content according to the template
		OutputMetricElements(ResultDocument,
				Template,
				AnalysisOption,
				DataSource,
				ViewOption,
				DisplayTableTotal,
				DisplayDetails);
		
		CounterOfLineElements = CounterOfLineElements + 1;
		If CounterOfLineElements > NumberOfIndicatorMonitorColumns Then 
			CounterOfLineElements = 1;
			LineCounter = LineCounter + 1;
			
			// No indentation is required for the last line
			If LineCounter <= RowsCount Then
				OutputIndentation(ResultDocument, Template);
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Procedure OutputMetricElements(ResultDocument, Template, AnalysisOption, DataSource, ViewOption, DisplayTableTotal, DisplayDetails)
	If ViewOption = Enums.DisplayOptionsOfAnalysisOptions.Chart Then
		OutputDiagram(ResultDocument, Template, AnalysisOption, DataSource);
	ElsIf ViewOption = Enums.DisplayOptionsOfAnalysisOptions.Brief1 Then
		OutputBriefly(ResultDocument, Template, AnalysisOption, DataSource, DisplayDetails);
	ElsIf ViewOption = Enums.DisplayOptionsOfAnalysisOptions.Table Then
		OutputTable_(ResultDocument, Template, AnalysisOption, DataSource, DisplayTableTotal);
	EndIf;
EndProcedure

Procedure OutputDiagram(ResultDocument, Template, AnalysisOption, DataSource)
	TemporaryDocument = New SpreadsheetDocument;
	
	DisplayIndicatorTitle(TemporaryDocument, Template, DataSource);
	OutputContentIndicatorChart(TemporaryDocument, Template, DataSource);
	PrintPageNumber(TemporaryDocument, Template, DataSource);
	
	ResultDocument.Join(TemporaryDocument);
EndProcedure

Procedure OutputTable_(ResultDocument, Template, AnalysisOption, DataSource, DisplayTableTotal)
	TemporaryDocument = New SpreadsheetDocument;
	
	DisplayIndicatorTitle(TemporaryDocument, Template, DataSource);
	OutputContentIndicatorTable(TemporaryDocument, Template, DataSource, DisplayTableTotal);
	PrintPageNumber(TemporaryDocument, Template, DataSource);
	
	ResultDocument.Join(TemporaryDocument);
EndProcedure

Procedure OutputBriefly(ResultDocument, Template, AnalysisOption, DataSource, DisplayDetails)
	TemporaryDocument = New SpreadsheetDocument;
	
	DisplayIndicatorTitle(TemporaryDocument, Template, DataSource);
	DisplayContentOfIndicatorBriefly(TemporaryDocument, Template, DataSource, DisplayDetails);
	PrintPageNumber(TemporaryDocument, Template, DataSource);
	
	ResultDocument.Join(TemporaryDocument);
EndProcedure

Procedure DisplayIndicatorTitle(ResultDocument, Template, DataSource)
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	AnalysisOption = DataSource.AnalysisOption; // CatalogRef.AnalysisOptionsOfTargetValues -
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	Separator = " / ";
	
	Area = Template.GetArea("IndicatorHeaderLine|Indentation");
	ResultDocument.Put(Area);
	
	// Status marker output
	If DataSource.PropertiesOfAnalysisAndTrendZone.Status = "UnacceptableState"
		Or DataSource.PropertiesOfAnalysisAndTrendZone.Status = "AcceptableState"
		Or DataSource.PropertiesOfAnalysisAndTrendZone.Status = "TheGoalIsAchieved" Then
		
		Marker = "●";
		MarkerSuffix = "";
		
		Area = Template.GetArea("IndicatorHeaderLine|StateMarkerColumn");
	
		StateAndTrendColors = TargetValueMonitoring.GetStateAndTrendIndicatorColors(AnalysisOption, DataSource);
		Area.CurrentArea.TextColor = StateAndTrendColors.StateColor;
	
		AreaProperties = New Structure("Marker", Marker);
		FillPropertyValues(Area.Parameters, AreaProperties); 
		ResultDocument.Join(Area);
	Else
		Marker = "";
		MarkerSuffix = "WithoutMarker";
	EndIf;
	
	AttributesOfAnalysisOption = Common.ObjectAttributesValues(AnalysisOption, "Description, ValueMultiplier");
	// Output of the indicator name
	If MarkerSuffix = "WithoutMarker" Then
		Area = Template.GetArea("IndicatorHeaderWithoutMarkerLine|IndicatorHeaderWithoutMarkerColumn");
	Else
		Area = Template.GetArea("IndicatorHeaderLine|IndicatorHeadingColumn");
	EndIf;	
	
	AreaProperties = New Structure("IndicatorTitle", AttributesOfAnalysisOption.Description);
	FillPropertyValues(Area.Parameters, AreaProperties); 
	ResultDocument.Join(Area);
	
	// Output of indicator properties
	If MarkerSuffix = "WithoutMarker" Then
		Area = Template.GetArea("IndicatorHeaderWithoutMarkerLine|PropertiesOfIndicatorColumn");
	Else
		Area = Template.GetArea("IndicatorHeaderLine|PropertiesOfIndicatorColumn");
	EndIf;
	IndicatorProperties = "";
	
	If Not AttributesOfAnalysisOption.ValueMultiplier = NumberPresentationKinds.Unchanged Then
		Repetition = TargetValueMonitoring.GetNumberPresentationString(AnalysisOption);
	Else
		Repetition = "";
	EndIf;
	If Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions) Then
		Dimensions = String(DynamicPropertiesOfAnalysisVariant.Dimensions);
	Else
		Dimensions = "";
	EndIf;
	TextPresentationOfPeriod = TargetValueMonitoring.PresentationOfAnalysisVariantPeriod(DataSource);
	
	If ValueIsFilled(Repetition) Then
		IndicatorProperties = IndicatorProperties + Repetition;
	EndIf;
	If ValueIsFilled(Dimensions) Then
		IndicatorProperties = IndicatorProperties + ?(ValueIsFilled(IndicatorProperties), Separator, "") + Dimensions;
	EndIf;
	If ValueIsFilled(TextPresentationOfPeriod) Then
		IndicatorProperties = IndicatorProperties + ?(ValueIsFilled(IndicatorProperties), Separator, "") + TextPresentationOfPeriod;
	EndIf;
	
	AreaProperties = New Structure("IndicatorProperties", IndicatorProperties);
	FillPropertyValues(Area.Parameters, AreaProperties); 
	ResultDocument.Join(Area);
EndProcedure

Procedure DisplayContentOfIndicatorBriefly(ResultDocument, Template, DataSource, DisplayDetails)
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	AnalysisOption = DataSource.AnalysisOption;
	
	EmptyDataSource = DataSource.IsEmpty;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	CalculationError = DataSource.CalculationError;
	ValueMultiplier = AnalysisOption.ValueMultiplier;
	FractionalPartCalculationAccuracy = AnalysisOption.FractionalPartCalculationAccuracy;
	
	Area = Template.GetArea("IndicatorShortString|Indentation");
	ResultDocument.Put(Area);
	
	AreaProperties = New Structure("
		|Value, 
		|Dimensions, 
		|TrendMarker, 
		|Rel_Change, 
		|AbsIsm,
		|ErrorDescription");
		
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		// Status marker output
		Area = Template.GetArea("IndicatorShortString|FactorColumn");
		
		// Filling in the value area
		LastValue = Round(DataSource.PropertiesOfDataByPeriod.LastValue, FractionalPartCalculationAccuracy);
		DisplayedValue_ = LastValue;
		
		Dimensionality = TrimAll(String(DynamicPropertiesOfAnalysisVariant.Dimensions));
		
		If ValueIsFilled(Dimensionality) Then
			DimensionString_ = " " + Dimensionality;
		Else
			DimensionString_ = "";
		EndIf;
		AreaProperties.Value = TrimAll(TargetValueMonitoring.GetAbbreviatedPresentationOfNumber(
				DisplayedValue_, 
				FractionalPartCalculationAccuracy, 
				ValueMultiplier));
				
		AreaProperties.Dimensions = DimensionString_;
		
		// Filling in the details area
		If DisplayDetails Then
			If Not EmptyDataSource And Not PaymentsAreIrrelevant Then
				LastTargetValue = Round(DataSource.PropertiesOfDataByPeriod.TargetValue_, FractionalPartCalculationAccuracy);
				PenultimateValue = Round(DataSource.PropertiesOfDataByPeriod.PenultimateValue, FractionalPartCalculationAccuracy);
			Else
				LastTargetValue = 0;
				PenultimateValue = 0;
			EndIf;
			
			If Not PenultimateValue = 0 Then
				RelativeUpdate = Round(100 * (LastValue - PenultimateValue)/PenultimateValue, FractionalPartCalculationAccuracy);
				
				If RelativeUpdate > 0 Then
					TrendMarker = "▲";
				ElsIf RelativeUpdate = 0 Then
					TrendMarker = "";
				ElsIf RelativeUpdate < 0 Then
					TrendMarker = "▼";
				EndIf;
			EndIf;
			
			AbsoluteUpdate = LastValue - PenultimateValue;
			
			If AbsoluteUpdate > 0 Then
				TrendMarker = "▲";
			ElsIf AbsoluteUpdate = 0 Then
				TrendMarker = "";
			ElsIf AbsoluteUpdate < 0 Then
				TrendMarker = "▼";
			EndIf;
			
			AreaProperties.TrendMarker = TrendMarker;
			AreaProperties.Rel_Change = RelativeUpdate;
			AreaProperties.AbsIsm = TargetValueMonitoring.GetAbbreviatedPresentationOfNumber(AbsoluteUpdate, FractionalPartCalculationAccuracy, ValueMultiplier);
		EndIf;
	Else 
		// Status marker output
		Area = Template.GetArea("IndicatorShortStringError|FactorColumn");
		
		If DataSource.Property("ErrorDescription") Then
			AreaProperties.ErrorDescription = DataSource.ErrorDescription;
		EndIf;
	EndIf;
	
	FillPropertyValues(Area.Parameters, AreaProperties); 
	DerivedArea = ResultDocument.Join(Area);
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		StateAndTrendColors = TargetValueMonitoring.GetStateAndTrendIndicatorColors(AnalysisOption, DataSource);
		DerivedArea.TextColor = StateAndTrendColors.StateColor;
	EndIf;
EndProcedure

Procedure OutputContentIndicatorTable(ResultDocument, Template, DataSource, DisplayTableTotal)
	EmptyDataSource = DataSource.IsEmpty;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	CalculationError = DataSource.CalculationError;
	
	AnalysisOption = DataSource.AnalysisOption;
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		ValueTable = New ValueTable;
		TargetValueMonitoring.FillInTableForMonitor(ValueTable, "", AnalysisOption, DataSource);
		
		IndentArea = Template.GetArea("IndicatorTableHeader|Indentation");
		ResultDocument.Put(IndentArea);
	
		// The output of the table header
		Area = Template.GetArea("IndicatorTableHeader|FactorColumn");
		
		AreaProperties = New Structure("TitleObjectOfAnalysis, TitleValue, Separator, Dimensions");
		AreaProperties.Insert("TitleObjectOfAnalysis", DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation);
		AreaProperties.Insert("TitleValue", DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation);
		AreaProperties.Insert("Separator", ?(ValueIsFilled(DynamicPropertiesOfAnalysisVariant.Dimensions), ",", ""));
		AreaProperties.Insert("Dimensions", DynamicPropertiesOfAnalysisVariant.Dimensions);
			
		FillPropertyValues(Area.Parameters, AreaProperties); 
		ResultDocument.Join(Area);
		
		// Output of the table body
		Area = Template.GetArea("IndicatorTableTableRow|FactorColumn");
		
		StringOutputLimit = 12;
		RowsCount = ValueTable.Count();
		LimitExceeded = (RowsCount > StringOutputLimit);
		
		NumberOfOutputLines = 0;
		MeaningOfRest = 0;
		For Each TableRow In ValueTable Do
			If NumberOfOutputLines < 10 Then
				ResultDocument.Put(IndentArea);
				
				AreaProperties = New Structure("AnalysisObject, AnalysisValue", TableRow.ColumnObjectOfAnalysis, TableRow.ColumnAnalysisValue);
					
				FillPropertyValues(Area.Parameters, AreaProperties); 
				ResultDocument.Join(Area);
				
				NumberOfOutputLines = NumberOfOutputLines + 1; 
			Else
				MeaningOfRest = MeaningOfRest + TableRow.ColumnAnalysisValue;
			EndIf;
		EndDo;
		
		Area = Template.GetArea("IndicatorTableTableRowIndentation|FactorColumn");
		If RowsCount < StringOutputLimit Then
			NumberOfDummyRows = StringOutputLimit - RowsCount;
			While NumberOfDummyRows > 0 Do 
				ResultDocument.Put(IndentArea);
				ResultDocument.Join(Area);
				
				NumberOfDummyRows = NumberOfDummyRows - 1;
			EndDo;
		EndIf;
			 
		If LimitExceeded Then
			Area = Template.GetArea("IndicatorTableRowTableMore|FactorColumn");
			
			TitleOthers = NStr("vi = 'Phần còn lại';
								|ru = 'Остальные';
								|en = 'Other'; fa = 'سایر';
								|it = 'Restanti';
								|pl = 'Pozostałe';
								|tr = 'Geri kalanlar'");
			RowsOverLimit = RowsCount - StringOutputLimit;
			
			AreaProperties = New Structure("TitleOthers, RowsOverLimit, MeaningOfRest", 
				TitleOthers, RowsOverLimit, MeaningOfRest);
				
			FillPropertyValues(Area.Parameters, AreaProperties); 
			
			ResultDocument.Put(IndentArea);
			ResultDocument.Join(Area);
		EndIf;
		
		// Output of the table basement
		If DisplayTableTotal Then
			Area = Template.GetArea("IndicatorTableBasement|FactorColumn");
			
			TitleTotal = NStr("vi = 'Tổng số';
								|ru = 'Итого';
								|en = 'Total'; fa = 'جمع کل';
								|it = 'Totale';
								|pl = 'Łącznie';
								|tr = 'Toplam'");
			TotalValue_ = ValueTable.Total("ColumnAnalysisValue");
			
			AreaProperties = New Structure("TitleTotal, TotalValue_", 
				TitleTotal, TotalValue_);
				
			FillPropertyValues(Area.Parameters, AreaProperties); 
			
			ResultDocument.Put(IndentArea);
			ResultDocument.Join(Area);
		EndIf;
	Else
		// Output an error message (using a diagram)
		OutputContentIndicatorChart(ResultDocument, Template, DataSource);
	EndIf;
EndProcedure

Procedure OutputContentIndicatorChart(ResultDocument, Template, DataSource)
	AnalysisOption = DataSource.AnalysisOption;
	
	EmptyDataSource = DataSource.IsEmpty;
	PaymentsAreIrrelevant = Not DataSource.CalculationsAreRelevant;
	CalculationError = DataSource.CalculationError;
	
	Area = Template.GetArea("IndicatorChartRow|Indentation");
	ResultDocument.Put(Area);
	
	// Chart Output
	Area = Template.GetArea("IndicatorChartRow|FactorColumn");
	DerivedArea = ResultDocument.Join(Area);
	
	FigureDiagram = ResultDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Chart);
	FigureDiagram.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid);
	FigureDiagram.LineColor = WebColors.Gainsboro;
	
	Chart = FigureDiagram.Object;
	
	If Not EmptyDataSource And Not PaymentsAreIrrelevant And Not CalculationError Then
		TargetValueMonitoring.FillInChartForMonitor(Chart, AnalysisOption, DataSource);
	Else
		TargetValueMonitoring.GetChartForCalculationErrors(Chart, DataSource.ErrorDescription);
	EndIf;
	
	// Clarifying chart properties in a tabular document
	Chart.Transparent = True;
	
	IndexOf = ResultDocument.Drawings.IndexOf(FigureDiagram);
	
	ChartTemplateArea = ResultDocument.Area(DerivedArea.Top, DerivedArea.Left, DerivedArea.Bottom, DerivedArea.Right);
	ResultDocument.Drawings[IndexOf].Place(ChartTemplateArea);
EndProcedure

Procedure PrintPageNumber(ResultDocument, Template, DataSource)
	Area = Template.GetArea("StringPage|Indentation");
	ResultDocument.Put(Area);
	
	Area = Template.GetArea("StringPage|FactorColumn");
	AreaProperties = New Structure("PageNumber", "PageNumber_" + PageNumbering);
	FillPropertyValues(Area.Parameters, AreaProperties); 
	ResultDocument.Join(Area);
	
	PageNumbering = PageNumbering + 1;
EndProcedure

Procedure DisplayMessageNoMetricsAvailable(ResultDocument, Template, Output)
	If Output Then
		If AccessRight("Update", Metadata.Catalogs.AnalysisOptionsOfTargetValues) Then
			Area = Template.GetArea("NoIndicatorsAvailableRightToChange");
		Else
			Area = Template.GetArea("NoMetricsAvailable");
		EndIf;
		ResultDocument.Put(Area);
	EndIf;
EndProcedure

Procedure DisplayMessageEmptySelectionResult(ResultDocument, Template, Output)
	If Output Then
		Area  = Template.GetArea("EmptyFilterResult");
		ResultDocument.Put(Area);
	EndIf;
EndProcedure

#EndRegion 

#Region Other


// Generates a report
// 
// Parameters:
// 	ResultDocument - SpreadsheetDocument - LongDesc
// 	MonitorContent - See CompositionOfMonitorFromResultOfDataPreparation
// 	ReportIsBlank - Boolean - flag for an empty report.
Procedure GenerateReport(ResultDocument, MonitorContent, ReportIsBlank)
	// Initializing output parameters
	SummaryPageTemplate = GetTemplate("SummaryPageTemplate"); 
	
	MonitorContentIsNotDefined = (MonitorContent.SetOfDataSources = Undefined
		Or TypeOf(MonitorContent.SetOfDataSources) = Type("ValueTable") 
			And MonitorContent.SetOfDataSources.Count() = 0);
	MonitorContentEmptyByFilter = (MonitorContent.IsEmpty And Not MonitorContentIsNotDefined);
	
	If MonitorContentIsNotDefined Or MonitorContentEmptyByFilter Then
		ReportIsBlank = True;
	EndIf;
	
	// Output of service information
	DisplayMessageNoMetricsAvailable(ResultDocument, SummaryPageTemplate, MonitorContentIsNotDefined);
	DisplayMessageEmptySelectionResult(ResultDocument, SummaryPageTemplate, MonitorContentEmptyByFilter);
	
	SummaryPageWasDisplayed = False;
	If Not MonitorContentIsNotDefined And Not MonitorContentEmptyByFilter Then
		If MonitorContent.Parameters.DemoMode Then
			TemplateArea = SummaryPageTemplate.GetArea("DemoMode");
			ResultDocument.Put(TemplateArea);
		EndIf;
	
		OutputStructure = TargetValueMonitoring.OutputStructure(MonitorContent);
		
		If MonitorContent.Parameters.AnalysisOptionFilter = Undefined Then 
			// Output of the summary page of indicators
			DisplayMonitorElements(ResultDocument, SummaryPageTemplate, MonitorContent, OutputStructure);
			
			// Adjusting page numbers
			// Print output parameters - for page counting.
			TargetValueMonitoring.SetOutputParameters(ResultDocument);
			FillInPageNumbers(ResultDocument, OutputStructure, ResultDocument.PageCount());
			
			SummaryPageWasDisplayed = True;
		EndIf;
		
		// Output of individual indicator pages
		If SummaryPageWasDisplayed Then
			ResultDocument.PutHorizontalPageBreak();
			
			StartOfNewStringFormat = ResultDocument.TableHeight + 1;
			
			TargetValueMonitoring.DisplayIndividualIndicators(ResultDocument, MonitorContent, OutputStructure);
			
			AreaToProcess = ResultDocument.Area(StartOfNewStringFormat, , ResultDocument.TableHeight + 1, );
			AreaToProcess.CreateFormatOfRows();
			
			DocumentTemp = New SpreadsheetDocument;
			DocumentTemp.InsertArea(AreaToProcess);
			
			OverallWidth = Max(150, MonitorContent.Parameters.SettingsStructure.NumberOfIndicatorMonitorColumns * 58);
			For Counter = 1 To DocumentTemp.TableWidth Do 
				If Counter = 1 Then
					Width = 0;
				Else
					Width = OverallWidth / (DocumentTemp.TableWidth - 1);
				EndIf;
				
				ResultDocument.Area(StartOfNewStringFormat, Counter).ColumnWidth = Round(Width, 2);
			EndDo;
		Else
			TargetValueMonitoring.DisplayIndividualIndicators(ResultDocument, MonitorContent, OutputStructure);
		EndIf;
	EndIf;
	
	// Print Output parameters - Header and footer parameters
	TargetValueMonitoring.SetOutputParameters(ResultDocument);
EndProcedure

Procedure FillInPageNumbers(ResultDocument, OutputStructure, Move)
	NumberOfIndicators = 0;
	For Each OutputItem In OutputStructure.OutputOrder Do 
		NumberOfIndicators = NumberOfIndicators + OutputStructure[OutputItem].Count();
	EndDo;
	
	For PageNumber = 1 To NumberOfIndicators Do 
		SearchText_1 = "PageNumber_" + PageNumber;
		SearchArea_ = ResultDocument.FindText(SearchText_1);
		SearchArea_.Text = StrReplace(SearchArea_.Text, SearchText_1, PageNumber + Move);
	EndDo;
EndProcedure

Function StateColor(State)
	If State = "UnacceptableState" 
		Or State = "CalculatedWithErrors" Then
		Return WebColors.FireBrick;
	ElsIf State = "AcceptableState" Then
		Return WebColors.DarkOrange;
	ElsIf State = "TheGoalIsAchieved" Then
		Return WebColors.Seagreen;
	Else
		If CurrentVersionOfClientApplicationInterface = ClientApplicationInterfaceVariant.Version8_2 Then
			Return StyleColors.ReportsOptionsGroupColor82;
		Else // Taxi.
			Return StyleColors.ReportsOptionsGroupColor;
		EndIf;
	EndIf;
EndFunction

#EndRegion 

#EndRegion

#Region Initialize

#Region InitializingLocalVariables

CurrentVersionOfClientApplicationInterface = ClientApplication.CurrentInterfaceVariant();
PageNumbering = 1;

#EndRegion

#EndRegion 

#EndIf

#EndIf

