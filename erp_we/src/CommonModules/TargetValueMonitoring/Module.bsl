///////////////////////////////////////////////////////////////////////////////
// The module contains methods for forming a target indicator monitor
///////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region GoalMonitorSettings

// Returns user settings for the target monitor
//
// Parameters:
//	Dashboard - CatalogRef.PerformanceDashboards - dashboard with MCP settings
//	PrintMode - Boolean - indicates whether the target indicator analysis option is displayed for printing
//
// Returns:
//	Structure - contains user settings:
//		* IndicatorGroupingOption - String - takes values "Okategoriserade" and "Osostoyanii"
//		* DetailDisplayOption - String - takes the values "show only current Value" and " show current value of Detail"
//		* NumberOfIndicatorMonitorColumns - Number - the number of columns on the form.
//		* ChartSize - Number - takes the values 1(small) and 2 (Large)
//		* AutoRefreshPeriod - Number - period in minutes.
//
Function GetGoalMonitorSettings(Dashboard = Undefined, PrintMode = False) Export
	
	DefaultSettings = TargetValueMonitoringClientServer.ExchangeDefaultSettings();
	
	GoalMonitorSettings = New Structure;
	
	If Dashboard = Undefined Then
		Dashboard = Common.CommonSettingsStorageLoad(
			"GoalMonitorSettings", "DefaultDashboard", , , UserName());
		If Not DashboardIsAvailableToUser(Dashboard) Then
			Dashboard = Undefined;
		EndIf;
	EndIf;
	If PrintMode Then
		Dashboard = Undefined;
	EndIf;
	
	If Dashboard <> Undefined Then
		Query = New Query;
		Query.SetParameter("Dashboard", Dashboard);
		Query.Text = 
		"SELECT
		|	PerformanceDashboards.IndicatorGroupingOption AS IndicatorGroupingOption,
		|	PerformanceDashboards.ColumnsCount AS ColumnsCount,
		|	PerformanceDashboards.Scale AS Scale,
		|	PerformanceDashboards.AutoRefreshPeriod AS AutoRefreshPeriod,
		|	PerformanceDashboards.DisplayIndicatorFilter AS DisplayIndicatorFilter,
		|	PerformanceDashboards.AnalysisOptions.(
		|		AnalysisOption AS AnalysisOption,
		|		ViewOption AS ViewOption,
		|		Details_3 AS Details_3,
		|		TableSummary AS TableSummary,
		|		TRUE AS Enabled
		|	) AS AnalysisOptions
		|FROM
		|	Catalog.PerformanceDashboards AS PerformanceDashboards
		|WHERE
		|	PerformanceDashboards.Ref = &Dashboard";
		DashboardSettings = Query.Execute().Select();
		DashboardSettings.Next();
	Else
		DashboardSettings = Undefined;
	EndIf;
	GoalMonitorSettings.Insert("Dashboard", Dashboard);
	
	// the order of output of indicators
	If DashboardSettings = Undefined Then
		IndicatorGroupingOption = DefaultSettings.IndicatorGroupingOption;
	Else 
		IndicatorGroupingOption = DashboardSettings.IndicatorGroupingOption;
	EndIf;
	If IndicatorGroupingOption = "ByImportance" Then
		IndicatorGroupingOption = "ByState";
	EndIf;
	
	If DashboardSettings = Undefined Then
		NumberOfIndicatorMonitorColumns = DefaultSettings.NumberOfIndicatorMonitorColumns;
	Else 
		NumberOfIndicatorMonitorColumns = DashboardSettings.ColumnsCount;
	EndIf;
	
	GoalMonitorSettings.Insert("IndicatorGroupingOption", IndicatorGroupingOption);
	GoalMonitorSettings.Insert("NumberOfIndicatorMonitorColumns", NumberOfIndicatorMonitorColumns);
	GoalMonitorSettings.Insert("AutomaticCalculationOfNumberOfColumns", (NumberOfIndicatorMonitorColumns = 0));
	
	// Appearance of indicators
	If DashboardSettings = Undefined Then
		ChartSize = DefaultSettings.ChartSize;
		ArbitraryScale = DefaultSettings.ArbitraryScale;
	Else 
		Scale = DashboardSettings.Scale;
		If Scale > 200 Then
			ChartSize = 0;
			ArbitraryScale = Scale;
		Else
			ChartSize = Scale/100;
			ArbitraryScale = Scale;
		EndIf;
	EndIf;
	
	DetailDisplayOption = "ShowCurValueAndDetails";
	
	GoalMonitorSettings.Insert("ChartSize", ChartSize);
	GoalMonitorSettings.Insert("ArbitraryScale", ArbitraryScale);
	GoalMonitorSettings.Insert("DetailDisplayOption", DetailDisplayOption);
	
	// Data refresh
	If DashboardSettings = Undefined Then
		AutoRefreshPeriod = DefaultSettings.AutoRefreshPeriod;
	Else 
		AutoRefreshPeriod = DashboardSettings.AutoRefreshPeriod;
	EndIf;
	
	GoalMonitorSettings.Insert("AutoRefreshPeriod", AutoRefreshPeriod);
	
	// Output of indicator selection
	If DashboardSettings = Undefined Then
		DisplayIndicatorFilter = DefaultSettings.DisplayIndicatorFilter;
	Else
		DisplayIndicatorFilter = DashboardSettings.DisplayIndicatorFilter;
	EndIf;
	GoalMonitorSettings.Insert("DisplayIndicatorFilter", DisplayIndicatorFilter);
	
	// Displayed analysis options
	If DashboardSettings = Undefined Then
		AnalysisOptions = Undefined;
	Else
		AnalysisOptions = DashboardSettings.AnalysisOptions.Unload();
	EndIf;
	GoalMonitorSettings.Insert("AnalysisOptionsCustomSettings", New ValueStorage(AnalysisOptions));
	
	GoalMonitorSettings.Insert("PrintMode", PrintMode);
	
	Return GoalMonitorSettings;
	
EndFunction

// The procedure is called from a background task to prepare data for filling 
// in the target monitor.
//
// Parameters:
//	MonitorCompositionParameters - Structure - structure of parameters for data preparation:
//		* SettingsStructure - See TargetValueMonitoring.GetGoalMonitorSettings
//		* FilterStatus - String, ValueList - the values of the selected statuses
//		* ControlCycle - EnumRef.Periodicity - frequency of monitoring the analysis option
//		* ConsiderDisplayOptions - Boolean - consider visual representation in the preparation of these
//		* DemoMode - Boolean - get demo data instead of real data
//  StorageAddress - String - address of the temporary storage with prepared data.
//
Procedure PrepareDataForFilling(MonitorCompositionParameters, StorageAddress) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("GetCompositionOfGoalMonitor");
	
	DataToFill = New Structure;
	
	If MonitorCompositionParameters.Property("AnalysisModeOfTheRelated")
		And MonitorCompositionParameters.AnalysisModeOfTheRelated Then
		DataToFill.Insert("Monitor", GetCompositionOfMonitorInterconnected(MonitorCompositionParameters));
	Else
		DataToFill.Insert("Monitor", GetMonitorComposition(MonitorCompositionParameters));
	EndIf;
	
	PutToTempStorage(DataToFill, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ?(
		DataToFill.Monitor.SetOfDataSources = Undefined, 1,
		DataToFill.Monitor.SetOfDataSources.Count()));

EndProcedure

// The function returns the prepared composition of the target monitor
//
// Parameters:
//	MonitorCompositionParameters - See TargetValueMonitoring.PrepareDataForFilling.MonitorCompositionParameters
//
// Returns:
//	Structure -
Function GetMonitorComposition(MonitorCompositionParameters) Export
	AnalysisOptionFilter			= MonitorCompositionParameters.AnalysisOptionFilter;
	ForceUpdateData		= MonitorCompositionParameters.ForceUpdateData;
	DemoMode			= MonitorCompositionParameters.DemoMode;
	SettingsStructure				= MonitorCompositionParameters.SettingsStructure;
	FilterAreaOfInterest				= MonitorCompositionParameters.FilterAreaOfInterest;
	FilterStatus						= MonitorCompositionParameters.FilterStatus;
	If MonitorCompositionParameters.Property("ControlCycle") Then
		ControlCycle		= MonitorCompositionParameters.ControlCycle;
	Else
		ControlCycle		= Enums.Periodicity.EmptyRef();
	EndIf;
	ConsiderDisplayOptions	= MonitorCompositionParameters.ConsiderDisplayOptions;
	
	ResultingCompositionOfMonitor			= New Structure("SetOfDataSources, StatisticsByLine, IsEmpty",,, True);
	SetOfDataSources				= New ValueTable;
	CurrentUser					= Users.CurrentUser();
	AreasOfAttention						= Enums.InterestAreasOfAnalysisOptions;
	
	CompositionRequest = New Query;
	CompositionRequest.SetParameter("CurrentUser", CurrentUser);
	CompositionRequest.SetParameter("ControlCycle", ControlCycle);
	
	Dashboard = Undefined;
	PrintMode = False;
	SettingsStructure.Property("Dashboard", Dashboard);
	SettingsStructure.Property("PrintMode", PrintMode);
	
	If AnalysisOptionFilter = Undefined Then
		
		If ValueIsFilled(Dashboard) And Not PrintMode Then
			CompositionRequest.SetParameter("Dashboard", Dashboard);
			CompositionRequest.Text = "SELECT
			|	AnalysisOptions.Target,
			|	AnalysisOptions.TargetValue,
			|	AnalysisOptions.AnalysisOption,
			|	AnalysisOptions.ViewOption,
			|	AnalysisOptions.DisplayDetails,
			|	AnalysisOptions.DisplayTableTotal,
			|	AnalysisOptions.StateByCumulativeTotal,
			|	AnalysisOptions.Group,
			|	AnalysisOptions.ShortNameOfTargetValue
			|FROM
			|	(SELECT
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner AS Target,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetValue AS TargetValue,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
			|		CASE
			|			WHEN CustomSettingsForAnalysisOptions.ViewOption IS NULL 
			|				THEN OptionsForAnalyzingAccessibilitySettingsTargets.ViewOption
			|			ELSE CustomSettingsForAnalysisOptions.ViewOption
			|		END AS ViewOption,
			|		CASE
			|			WHEN CustomSettingsForAnalysisOptions.Details_3 IS NULL 
			|				THEN FALSE
			|			ELSE CustomSettingsForAnalysisOptions.Details_3
			|		END AS DisplayDetails,
			|		CASE
			|			WHEN CustomSettingsForAnalysisOptions.TableSummary IS NULL 
			|				THEN FALSE
			|			ELSE CustomSettingsForAnalysisOptions.TableSummary
			|		END AS DisplayTableTotal,
			|		CASE
			|			WHEN OptionsForAnalyzingAccessibilitySettingsTargets.Ref.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
			|				THEN TRUE
			|			ELSE FALSE
			|		END AS StateByCumulativeTotal,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetCategory AS Group,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.ShortNameOfTargetValue AS ShortNameOfTargetValue
			|	FROM
			|		Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
			|			LEFT JOIN Catalog.PerformanceDashboards.AnalysisOptions AS CustomSettingsForAnalysisOptions
			|			ON OptionsForAnalyzingAccessibilitySettingsTargets.Ref = CustomSettingsForAnalysisOptions.AnalysisOption
			|	WHERE
			|		OptionsForAnalyzingAccessibilitySettingsTargets.User = &CurrentUser
			|		AND NOT OptionsForAnalyzingAccessibilitySettingsTargets.Ref.DeletionMark
			|		AND CustomSettingsForAnalysisOptions.Ref = &Dashboard
			|		AND &ConditionPeriodicityOfControl) AS AnalysisOptions
			|
			|ORDER BY
			|	AnalysisOptions.Target.TargetCategory.AttributeOfAdditionalSortingHierarchical  HIERARCHY,
			|	AnalysisOptions.Target.AttributeOfAdditionalSortingHierarchical,
			|	AnalysisOptions.AnalysisOption.AddlOrderingAttribute";
		Else
			CompositionRequest.Text = "SELECT
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner AS Target,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetValue AS TargetValue,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
			|	FALSE AS DisplayDetails,
			|	FALSE AS DisplayTableTotal,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.ViewOption,
			|	CASE
			|		WHEN OptionsForAnalyzingAccessibilitySettingsTargets.Ref.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS StateByCumulativeTotal,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetCategory AS Group,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.ShortNameOfTargetValue AS ShortNameOfTargetValue
			|FROM
			|	Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
			|WHERE
			|	OptionsForAnalyzingAccessibilitySettingsTargets.User = &CurrentUser
			|	AND NOT OptionsForAnalyzingAccessibilitySettingsTargets.Ref.DeletionMark
			|	AND &ConditionPeriodicityOfControl
			|
			|ORDER BY
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetCategory.AttributeOfAdditionalSortingHierarchical HIERARCHY,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.AttributeOfAdditionalSortingHierarchical,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.AddlOrderingAttribute";
		EndIf;
		
	Else
		CompositionRequest.SetParameter("AnalysisOptionFilter", AnalysisOptionFilter);
		
		If ValueIsFilled(Dashboard) And Not PrintMode Then
			CompositionRequest.SetParameter("Dashboard", Dashboard);
			CompositionRequest.Text = "SELECT
			|	AnalysisOptions.Target,
			|	AnalysisOptions.TargetValue,
			|	AnalysisOptions.AnalysisOption,
			|	CASE 
			|		WHEN AnalysisOptions.ViewOption = VALUE(Enum.DisplayOptionsOfAnalysisOptions.EmptyRef)
			|			THEN VALUE(Enum.DisplayOptionsOfAnalysisOptions.Brief1)
			|			ELSE AnalysisOptions.ViewOption
			|	END AS ViewOption,
			|	AnalysisOptions.DisplayDetails,
			|	AnalysisOptions.DisplayTableTotal,
			|	AnalysisOptions.StateByCumulativeTotal,
			|	AnalysisOptions.Group,
			|	AnalysisOptions.ShortNameOfTargetValue
			|FROM
			|	(SELECT
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner AS Target,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetValue AS TargetValue,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
			|		CASE
			|			WHEN CustomSettingsForAnalysisOptions.ViewOption IS NULL 
			|				THEN OptionsForAnalyzingAccessibilitySettingsTargets.ViewOption
			|			ELSE CustomSettingsForAnalysisOptions.ViewOption
			|		END AS ViewOption,
			|		CASE
			|			WHEN CustomSettingsForAnalysisOptions.Details_3 IS NULL 
			|				THEN FALSE
			|			ELSE CustomSettingsForAnalysisOptions.Details_3
			|		END AS DisplayDetails,
			|		CASE
			|			WHEN CustomSettingsForAnalysisOptions.TableSummary IS NULL 
			|				THEN FALSE
			|			ELSE CustomSettingsForAnalysisOptions.TableSummary
			|		END AS DisplayTableTotal,
			|		CASE
			|			WHEN OptionsForAnalyzingAccessibilitySettingsTargets.Ref.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
			|				THEN TRUE
			|			ELSE FALSE
			|		END AS StateByCumulativeTotal,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetCategory AS Group,
			|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.ShortNameOfTargetValue AS ShortNameOfTargetValue
			|	FROM
			|		Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
			|			LEFT JOIN Catalog.PerformanceDashboards.AnalysisOptions AS CustomSettingsForAnalysisOptions
			|			ON OptionsForAnalyzingAccessibilitySettingsTargets.Ref = CustomSettingsForAnalysisOptions.AnalysisOption
			|	WHERE
			|		OptionsForAnalyzingAccessibilitySettingsTargets.User = &CurrentUser
			|		AND NOT OptionsForAnalyzingAccessibilitySettingsTargets.Ref.DeletionMark
			|		AND OptionsForAnalyzingAccessibilitySettingsTargets.Ref IN(&AnalysisOptionFilter)
			|		AND CustomSettingsForAnalysisOptions.Ref = &Dashboard
			|		AND &ConditionPeriodicityOfControl) AS AnalysisOptions
			|
			|ORDER BY
			|	AnalysisOptions.Target.TargetCategory.AttributeOfAdditionalSortingHierarchical HIERARCHY,
			|	AnalysisOptions.Target.AttributeOfAdditionalSortingHierarchical,
			|	AnalysisOptions.AnalysisOption.AddlOrderingAttribute";
		Else
			CompositionRequest.Text = "SELECT
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner AS Target,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetValue AS TargetValue,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
			|	FALSE AS DisplayDetails,
			|	FALSE AS DisplayTableTotal,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.ViewOption,
			|	CASE
			|		WHEN OptionsForAnalyzingAccessibilitySettingsTargets.Ref.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS StateByCumulativeTotal,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetCategory AS Group,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.ShortNameOfTargetValue AS ShortNameOfTargetValue
			|FROM
			|	Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
			|WHERE
			|	OptionsForAnalyzingAccessibilitySettingsTargets.User = &CurrentUser
			|	AND NOT OptionsForAnalyzingAccessibilitySettingsTargets.Ref.DeletionMark
			|	AND OptionsForAnalyzingAccessibilitySettingsTargets.Ref IN(&AnalysisOptionFilter)
			|	AND &ConditionPeriodicityOfControl
			|
			|ORDER BY
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.TargetCategory.AttributeOfAdditionalSortingHierarchical HIERARCHY,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner.AttributeOfAdditionalSortingHierarchical,
			|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.AddlOrderingAttribute";
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ControlCycle) Then
		ExpressionConditionPeriodicityOfControl = "OptionsForAnalyzingAccessibilitySettingsTargets.Ref.ControlCycle = &ControlCycle";
	Else
		ExpressionConditionPeriodicityOfControl = "TRUE";
	EndIf;
	CompositionRequest.Text = StrReplace(CompositionRequest.Text, "&ConditionPeriodicityOfControl", ExpressionConditionPeriodicityOfControl);
	
	CompositionRequestResult = CompositionRequest.Execute();
	
	If Not CompositionRequestResult.IsEmpty() Then
		
		SetOfDataSources = CompositionRequestResult.Unload();
		
		// Let's add data sources, status and trend to the table
		SetOfDataSources.Columns.Add("DataSource");
		SetOfDataSources.Columns.Add("AreaOfInterest");
		SetOfDataSources.Columns.Add("IsEmpty");
		SetOfDataSources.Columns.Add("PaymentsAreIrrelevant");
		SetOfDataSources.Columns.Add("CalculationError");
		SetOfDataSources.Columns.Add("InterestAreaProcedure");
		SetOfDataSources.Columns.Add("Status");
		SetOfDataSources.Columns.Add("Position");
		
		Position = 1;
		For Each Set_Item In SetOfDataSources Do
			AnalysisOption = Set_Item.AnalysisOption;
			
			// We will get the data of the analysis option
			DataSourceOfAnalysisVariant = GetAnalysisVariantDataSource(
				AnalysisOption,
				Set_Item.ViewOption,
				ForceUpdateData,,
				DemoMode);
			Set_Item.DataSource = New ValueStorage(DataSourceOfAnalysisVariant);
			
			Set_Item.IsEmpty = DataSourceOfAnalysisVariant.IsEmpty;
			Set_Item.CalculationError = DataSourceOfAnalysisVariant.CalculationError;
			Set_Item.PaymentsAreIrrelevant = Not DataSourceOfAnalysisVariant.CalculationsAreRelevant;
			// We will get a zone of attention
			FillPropertyValues(Set_Item, DataSourceOfAnalysisVariant.PropertiesOfAnalysisAndTrendZone);
			Set_Item.Position = Position;
			
			Position = Position + 1;
		EndDo;
		
		// We will set the selection according to the state of the indicators
		If FilterStatus = "TheGoalIsAchieved"
			Or FilterStatus = "AcceptableState" 
			Or FilterStatus = "UnacceptableState"
			Or FilterStatus = "StateIsNotDefined"
			Or FilterStatus = "CalculatedWithErrors" Then
			
			PickingByStatuses = New Structure("Status", FilterStatus);
			SetOfDataSources = SetOfDataSources.Copy(PickingByStatuses);
			
		EndIf;
		
		// Let's set the selection by attention zone
		If FilterAreaOfInterest = 1 Then
			
			SelectionOfCritical = New Structure("AreaOfInterest", AreasOfAttention.CriticalState);
			SetOfDataSources = SetOfDataSources.Copy(SelectionOfCritical);
			
		ElsIf FilterAreaOfInterest = 2 Then
			
			SelectionOfImportantOnes = New Structure("AreaOfInterest", AreasOfAttention.Critical);
			SetOfDataSources = SetOfDataSources.Copy(SelectionOfImportantOnes);
			
		ElsIf FilterAreaOfInterest = 3 Then
			
			FilterForInformation = New Structure("AreaOfInterest", AreasOfAttention.ForInformation);
			MonitorElementsToDelete = SetOfDataSources.FindRows(FilterForInformation);
			
			For Each MonitorElementToDelete In MonitorElementsToDelete Do 
				
				SetOfDataSources.Delete(MonitorElementToDelete);
				
			EndDo;
			
			SelectionBasedOnCalculatedDataWithErrors = New Structure("AreaOfInterest", AreasOfAttention.CalculatedWithErrors);
			MonitorElementsToDelete = SetOfDataSources.FindRows(SelectionBasedOnCalculatedDataWithErrors);
			
			For Each MonitorElementToDelete In MonitorElementsToDelete Do 
				
				SetOfDataSources.Delete(MonitorElementToDelete);
				
			EndDo;
			
		ElsIf FilterAreaOfInterest = 4 Then
			
			FilterForInformation = New Structure("AreaOfInterest", AreasOfAttention.ForInformation);
			SetOfDataSources = SetOfDataSources.Copy(FilterForInformation);
			
		ElsIf FilterAreaOfInterest = 5 Then
			
			SelectionBasedOnCalculatedValuesWithError = New Structure("AreaOfInterest", AreasOfAttention.CalculatedWithErrors);
			SetOfDataSources = SetOfDataSources.Copy(SelectionBasedOnCalculatedValuesWithError);
			
		EndIf;
		
		ResultingCompositionOfMonitor.IsEmpty = (SetOfDataSources.Count() = 0);
		
		ResultingCompositionOfMonitor.Insert("SetOfDataSources", SetOfDataSources);
		
		ResultingCompositionOfMonitor.Insert("StatisticsByLine",
			StatisticsOfDataSourcesByState(
				SetOfDataSources,
				ConsiderDisplayOptions));
	Else
		If ThereAreAnalysisOptionsAvailable() Then
			ResultingCompositionOfMonitor.SetOfDataSources = SetOfDataSources;
		EndIf;
	EndIf;
	
	ResultingCompositionOfMonitor.Insert("Parameters", MonitorCompositionParameters);
	
	Return ResultingCompositionOfMonitor;
	
EndFunction

// The function returns a prepared list of related indicators for the monitor
// Parameters:
//	MonitorCompositionParameters - Structure - structure of parameters for data preparation. See TargetValueMonitoring.PrepareDataForFilling.
//
// Returns:
//	See GetInterrelatedAnalysisOptions
//
Function GetCompositionOfMonitorInterconnected(MonitorCompositionParameters) Export
	SearchType						= Enums.KindsOfAssociatedIndicatorSearch[MonitorCompositionParameters.SearchType];
	PropertiesOfAnalysisVariant			= TargetValueMonitoringServerCall.GetPropertiesOfAnalysisVariantById(
		MonitorCompositionParameters.PropertiesOfAnalysisVariant);
	DynamicParameterAddresses	= MonitorCompositionParameters.DynamicParameterAddresses.Get();
	FilterAreaOfInterest				= MonitorCompositionParameters.FilterAreaOfInterest;
	
	ResultingCompositionOfMonitor = GetInterrelatedAnalysisOptions(
		SearchType,
		PropertiesOfAnalysisVariant.Ref,
		FilterAreaOfInterest,
		DynamicParameterAddresses,
		MonitorCompositionParameters.DemoMode);
	
	ResultingCompositionOfMonitor.Insert("Parameters", MonitorCompositionParameters);
		
	Return ResultingCompositionOfMonitor;
	
EndFunction

// Returns the order in which information blocks are output as a structure
//
// Parameters:
//	MonitorContent - Structure - table of links to indicators that should be included in the report
// Returns:
//	Structure - description of the order of output of information blocks.
//
Function OutputStructure(MonitorContent) Export
	OutputStructure = New Structure("OutputOrder", New Array);
	
	SetOfDataSources = MonitorContent.SetOfDataSources;
	Parameters = MonitorContent.Parameters;
	
	DisplayOptionsOfAnalysisOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	If Parameters.AnalysisModeOfTheRelated Then
		// Let's create form elements for the analyzed indicator
		SelectionOfAnalyzed = New Structure("Group", Enums.KindsOfAssociatedIndicatorSearch.EmptyRef());
		AddOutputElement(OutputStructure, "Analyzed", SetOfDataSources.FindRows(SelectionOfAnalyzed));
		
		// Let's create form elements for interrelated indicators
		SelectionOfDependents = New Structure("Group", Enums.KindsOfAssociatedIndicatorSearch.DependentIndicators);
		AddOutputElement(OutputStructure, "DependentItems", SetOfDataSources.FindRows(SelectionOfDependents));
		
		SelectionOfInfluencers = New Structure("Group", Enums.KindsOfAssociatedIndicatorSearch.InfluencingIndicators);
		AddOutputElement(OutputStructure, "Influencers", SetOfDataSources.FindRows(SelectionOfInfluencers));
	Else 
		If Parameters.SettingsStructure.IndicatorGroupingOption = "ByState" Then
			Filter = New Structure("Status, ViewOption", "UnacceptableState", DisplayOptionsOfAnalysisOptions.Brief1);
			AddOutputElement(OutputStructure, "IndicatorsUnacceptableState", SetOfDataSources.FindRows(Filter));
			
			Filter = New Structure("Status, ViewOption", "AcceptableState", DisplayOptionsOfAnalysisOptions.Brief1);
			AddOutputElement(OutputStructure, "IndicatorsAcceptableStateBriefly", SetOfDataSources.FindRows(Filter));
			
			Filter = New Structure("Status, ViewOption", "TheGoalIsAchieved", DisplayOptionsOfAnalysisOptions.Brief1);
			AddOutputElement(OutputStructure, "IndicatorsGoalAchievedBriefly", SetOfDataSources.FindRows(Filter));
			
			Filter = New Structure("Status, ViewOption", "StateIsNotDefined", DisplayOptionsOfAnalysisOptions.Brief1);
			AddOutputElement(OutputStructure, "IndicatorsStateUncertainBrief", SetOfDataSources.FindRows(Filter));
			
			Filter = New Structure("Status, ViewOption", "CalculatedWithErrors", DisplayOptionsOfAnalysisOptions.Brief1);
			AddOutputElement(OutputStructure, "IndicatorsCalculatedWithErrorsBrief", SetOfDataSources.FindRows(Filter));
			
			Filter = New Structure("ViewOption", DisplayOptionsOfAnalysisOptions.Brief1);
			DataSourceSetIsNotConcise = ApplyConditionNotToTable(SetOfDataSources.Copy(), Filter);
			DataSourceSetIsNotConcise.Sort("Position");
			
			Filter = New Structure("Status", "UnacceptableState");
			AddOutputElement(OutputStructure, "IndicatorsUnacceptableStateOfDetail", DataSourceSetIsNotConcise.FindRows(Filter));
			
			Filter = New Structure("Status", "AcceptableState");
			AddOutputElement(OutputStructure, "IndicatorsAcceptableStateOfDetail", DataSourceSetIsNotConcise.FindRows(Filter));
			
			Filter = New Structure("Status", "TheGoalIsAchieved");
			AddOutputElement(OutputStructure, "IndicatorsGoalAchievedInDetail", DataSourceSetIsNotConcise.FindRows(Filter));
			
			Filter = New Structure("Status", "StateIsNotDefined");
			AddOutputElement(OutputStructure, "IndicatorsStateUncertainDetail", DataSourceSetIsNotConcise.FindRows(Filter));
			
			Filter = New Structure("Status", "CalculatedWithErrors");
			AddOutputElement(OutputStructure, "IndicatorsCalculatedWithErrorsDetails", DataSourceSetIsNotConcise.FindRows(Filter));
		ElsIf Parameters.SettingsStructure.IndicatorGroupingOption = "ByGoalCategory" Then
			GoalCategory = SetOfDataSources.Copy(,"Group"); // ValueTable -
			GoalCategory.GroupBy("Group");
			
			For Each GoalCategory_ In GoalCategory Do 
				Filter = New Structure("ViewOption, Group", DisplayOptionsOfAnalysisOptions.Brief1, GoalCategory_.Group);
				TagName = "Indicators" + UniqueIDPerLine(GoalCategory_.Group.UUID())
					+ "Brief1";
				AddOutputElement(OutputStructure, TagName, SetOfDataSources.FindRows(Filter));
			EndDo;
			
			Filter = New Structure("ViewOption", DisplayOptionsOfAnalysisOptions.Brief1);
			DataSourceSetIsNotConcise = ApplyConditionNotToTable(SetOfDataSources.Copy(), Filter);
			DataSourceSetIsNotConcise.Sort("Position");
			
			For Each GoalCategory_ In GoalCategory Do 
				Filter = New Structure("Group", GoalCategory_.Group);
				TagName = "Indicators" + UniqueIDPerLine(GoalCategory_.Group.UUID())
					+ "More";
				AddOutputElement(OutputStructure, TagName, DataSourceSetIsNotConcise.FindRows(Filter));
			EndDo;
		EndIf;
	EndIf;
	
	Return OutputStructure;
EndFunction

#EndRegion

#Region RegulatedCalculationOfDataSourcesOfTargetIndicators

// Calculates data sources that are available to at least one user.
// Called from the routine task "calculation of data sources of variantanalysis".
//
Procedure CalculationOfAnalysisOptionDataSources() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.CalculationOfAnalysisOptionDataSources);
	
	UseTargetValueMonitoring = GetFunctionalOption("UseTargetValueMonitoring");

	If Not UseTargetValueMonitoring Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	// We will get all the configured analysis options taking into account user settings
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref,
	|	Users.IBUserID AS IBUserID
	|FROM
	|	Catalog.Users AS Users";
	UsersTable = Query.Execute().Unload();
	
	TableOfCustomAnalysisOptions = New ValueTable;
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.AnalysisOptionsOfTargetValues"));
	DescriptionOfTypeOfAnalysisVariant = New TypeDescription(TypesArray);
	
	TypesArray.Clear();
	TypesArray.Add(Type("EnumRef.DisplayOptionsOfAnalysisOptions"));
	DescriptionOfDisplayOptionType = New TypeDescription(TypesArray);
	
	TableOfCustomAnalysisOptions.Columns.Add("AnalysisOption", DescriptionOfTypeOfAnalysisVariant);
	TableOfCustomAnalysisOptions.Columns.Add("ViewOption", DescriptionOfDisplayOptionType);
	
	For Each User In UsersTable Do 
		
		InfoBaseUser = InfoBaseUsers.FindByUUID(User.IBUserID);
		If Not InfoBaseUser = Undefined Then
			TableUserName = InfoBaseUser.Name;
			
			StorageOfUserAnalysisOptions = Common.CommonSettingsStorageLoad("GoalMonitorSettings", "AnalysisOptionsCustomSettings",, TableUserName);
			If Not StorageOfUserAnalysisOptions = Undefined Then
				
				UserAnalysisOptions = StorageOfUserAnalysisOptions.Get();
				For Each UserAnalysisOption In UserAnalysisOptions Do 
					NewOptionInTable = TableOfCustomAnalysisOptions.Add();
					NewOptionInTable.AnalysisOption = UserAnalysisOption.AnalysisOption;
					NewOptionInTable.ViewOption = UserAnalysisOption.ViewOption;
				EndDo;
			EndIf;
		EndIf;
		
	EndDo;
	
	TableOfCustomAnalysisOptions.GroupBy("AnalysisOption, ViewOption");
	
	Query.SetParameter("AnalysisOptions", TableOfCustomAnalysisOptions);
	Query.Text =
	"SELECT
		|	CustomSettingsForAnalysisOptions.AnalysisOption,
		|	CustomSettingsForAnalysisOptions.ViewOption
		|INTO CustomSettingsForAnalysisOptions
		|FROM
		|	&AnalysisOptions AS CustomSettingsForAnalysisOptions
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AnalysisOptions.AnalysisOption,
		|	AnalysisOptions.ViewOption
		|FROM
		|	(SELECT
		|		OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
		|		OptionsForAnalyzingAccessibilitySettingsTargets.ViewOption AS ViewOption
		|	FROM
		|		Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
		|	WHERE
		|		(NOT OptionsForAnalyzingAccessibilitySettingsTargets.Ref.DeletionMark)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CustomSettingsForAnalysisOptions.AnalysisOption,
		|		CustomSettingsForAnalysisOptions.ViewOption
		|	FROM
		|		CustomSettingsForAnalysisOptions AS CustomSettingsForAnalysisOptions) AS AnalysisOptions
		|
		|GROUP BY
		|	AnalysisOptions.AnalysisOption,
		|	AnalysisOptions.ViewOption";
	
	QueryResult = Query.Execute();
	
	TableOfAnalysisOptions = QueryResult.Unload();
	For Each CurAnalysis In TableOfAnalysisOptions Do 
		
		GetAnalysisVariantDataSource(CurAnalysis.AnalysisOption, CurAnalysis.ViewOption, True);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region AnalysisOfInterrelatedTargets

// Returns a set of data sources for related analysis options
//
// Parameters:
//	SearchType - EnumRef.KindsOfAssociatedIndicatorSearch - link search method
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - a variant of the analysis for which related data are searched
//	FilterAreaOfInterest - Number - characterizes a status or set of statuses
//	DynamicParameterAddresses - ValueTable - contains analysis options and addresses of their DIN parameters.
//	DemoData - Boolean - Flag for building a report based on demo data.
//
// Returns:
//	Structure - contains a set of data sources and summarized information about the sources of interrelated indicators:
//	 *SetOfDataSources - ValueTable - Table Of Sources:
//	   **AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Analysis option.
//	   **Target - CatalogRef.StructureOfTargets - Goal.
//	   **ObjectiveTarget - String - Target.
//	   **StateByCumulativeTotal - Boolean - flag for calculating the status on an accrual basis.
//	   **ViewOption - EnumRef.DisplayOptionsOfAnalysisOptions - Display option.
//	   **DisplayDetails - Boolean - Flag for displaying details.
//	   **DisplayTableTotal - Boolean - Flag for displaying table totals.
//	   **Position - Number - details for additional ordering of the analysis option.
//	   **NamingOfTarget - String - Short name of the target indicator.
//	   **Group - EnumRef.KindsOfAssociatedIndicatorSearch - group.
//	   **DataSource - See GetAnalysisVariantDataSource
//	   **AreaOfInterest - See ValueAnalysisZone
//	   **IsEmpty - Boolean - 
//	   **PaymentsAreIrrelevant - Boolean - 
//	   **CalculationError - Boolean - 
//	   **InterestAreaProcedure - Undefined, EnumRef.InterestAreasOfAnalysisOptions - 
//	 *StatisticsByLine - See StatisticsOfDataSourcesByAreasOfAttention
//	 *IsEmpty - Boolean - Flag empty part of the monitor.
//
Function GetInterrelatedAnalysisOptions(SearchType, AnalysisOption, FilterAreaOfInterest, DynamicParameterAddresses, DemoData = False) Export
	
	ResultingCompositionOfMonitor = New Structure;
	ResultingCompositionOfMonitor.Insert("IsEmpty", True);
	
	SetOfDataSources = New ValueTable;
	
	TypesOfSearch = Enums.KindsOfAssociatedIndicatorSearch;
	AreasOfAttention = Enums.InterestAreasOfAnalysisOptions;
	
	Query = New Query;
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("AnalysisOption", AnalysisOption);
	Query.Text = QueryTextBasedOnStructureOfAvailableAnalysisOptions();
	
	RequestPackageResult = Query.ExecuteBatch();
	
	If SearchType = TypesOfSearch.InterdependentIndicators
		And (Not RequestPackageResult[1].IsEmpty() Or Not RequestPackageResult[2].IsEmpty()) Then
		
		If Not RequestPackageResult[1].IsEmpty() Then
			SetOfDataSources = RequestPackageResult[1].Unload();
			
		EndIf;
		
		If Not RequestPackageResult[2].IsEmpty() Then
			If SetOfDataSources.Count() = 0 Then
				SetOfDataSources = RequestPackageResult[2].Unload();
				
			Else
				SelectionOfOptions = RequestPackageResult[2].Select();
				
				While SelectionOfOptions.Next() Do 
					NewRow = SetOfDataSources.Add();
					FillPropertyValues(NewRow, SelectionOfOptions);
					
				EndDo;
				
			EndIf;
		EndIf;
		
	ElsIf SearchType = TypesOfSearch.DependentIndicators And Not RequestPackageResult[1].IsEmpty() Then
		If Not RequestPackageResult[1].IsEmpty() Then
			SetOfDataSources = RequestPackageResult[1].Unload();
			
		EndIf;
		
	ElsIf SearchType = TypesOfSearch.InfluencingIndicators And Not RequestPackageResult[2].IsEmpty() Then
		If Not RequestPackageResult[2].IsEmpty() Then
			SetOfDataSources = RequestPackageResult[2].Unload();
			
		EndIf;
		
	EndIf;
	
	If Not RequestPackageResult[3].IsEmpty() Then
		SelectionOfOptions = RequestPackageResult[3].Select();
		
		While SelectionOfOptions.Next() Do 
			NewRow = SetOfDataSources.Add();
			FillPropertyValues(NewRow, SelectionOfOptions);
			
		EndDo;
		
	EndIf;
	
	// Let's add service columns to the table
	SetOfDataSources.Columns.Add("DataSource");
	SetOfDataSources.Columns.Add("AreaOfInterest");
	SetOfDataSources.Columns.Add("IsEmpty");
	SetOfDataSources.Columns.Add("PaymentsAreIrrelevant");
	SetOfDataSources.Columns.Add("CalculationError");
	SetOfDataSources.Columns.Add("InterestAreaProcedure");
	
	For Each Set_Item In SetOfDataSources Do 
		AnalysisOption = Set_Item.AnalysisOption;
		
		// Get the address of the dynamic parameters
		SelectionByAnalysisOption = New Structure("AnalysisOption", AnalysisOption);
		FoundMonitorComponents = DynamicParameterAddresses.FindRows(SelectionByAnalysisOption);
		If FoundMonitorComponents.Count() > 0 Then
			DynamicParameterAddress = FoundMonitorComponents[0].DynamicParameterAddress;
			
			If Not IsBlankString(DynamicParameterAddress) Then
				DynamicParameters = GetFromTempStorage(DynamicParameterAddress);
				
				DataSourceOfAnalysisVariant = GetAnalysisVariantDataSource(AnalysisOption, Set_Item.ViewOption, , DynamicParameters, DemoData);
			Else
				DataSourceOfAnalysisVariant = GetAnalysisVariantDataSource(AnalysisOption, Set_Item.ViewOption, , , DemoData);
				
			EndIf;
		Else
		
			DataSourceOfAnalysisVariant = GetAnalysisVariantDataSource(AnalysisOption, Set_Item.ViewOption, , , DemoData);
			
		EndIf;
		
		// We will get the data of the analysis option
		Set_Item.DataSource = New ValueStorage(DataSourceOfAnalysisVariant);
		
		Set_Item.IsEmpty = DataSourceOfAnalysisVariant.IsEmpty;
		Set_Item.CalculationError = DataSourceOfAnalysisVariant.CalculationError;
		// We will get a zone of attention
		Set_Item.AreaOfInterest = DataSourceOfAnalysisVariant.PropertiesOfAnalysisAndTrendZone.AreaOfInterest;
		Set_Item.InterestAreaProcedure = DataSourceOfAnalysisVariant.PropertiesOfAnalysisAndTrendZone.InterestAreaProcedure;
		
	EndDo;
	
	// Let's set the selection
	If FilterAreaOfInterest = 1 Then
		
		SelectionOfCritical = New Structure("AreaOfInterest", AreasOfAttention.CriticalState);
		SetOfDataSources = SetOfDataSources.Copy(SelectionOfCritical);
		
	ElsIf FilterAreaOfInterest = 2 Then
		
		SelectionOfImportantOnes = New Structure("AreaOfInterest", AreasOfAttention.Critical);
		SetOfDataSources = SetOfDataSources.Copy(SelectionOfImportantOnes);
		
	ElsIf FilterAreaOfInterest = 3 Then
		
		FilterForInformation = New Structure("AreaOfInterest", AreasOfAttention.ForInformation);
		MonitorElementsToDelete = SetOfDataSources.FindRows(FilterForInformation);
		
		For Each MonitorElementToDelete In MonitorElementsToDelete Do 
			
			SetOfDataSources.Delete(MonitorElementToDelete);
			
		EndDo;
		
		SelectionBasedOnCalculatedDataWithErrors = New Structure("AreaOfInterest", AreasOfAttention.CalculatedWithErrors);
		MonitorElementsToDelete = SetOfDataSources.FindRows(SelectionBasedOnCalculatedDataWithErrors);
		
		For Each MonitorElementToDelete In MonitorElementsToDelete Do 
			
			SetOfDataSources.Delete(MonitorElementToDelete);
			
		EndDo;
		
	ElsIf FilterAreaOfInterest = 4 Then
		
		FilterForInformation = New Structure("AreaOfInterest", AreasOfAttention.ForInformation);
		SetOfDataSources = SetOfDataSources.Copy(FilterForInformation);
		
	ElsIf FilterAreaOfInterest = 5 Then
		
		SelectionBasedOnCalculatedDataWithErrors = New Structure("AreaOfInterest", AreasOfAttention.CalculatedWithErrors);
		SetOfDataSources = SetOfDataSources.Copy(SelectionBasedOnCalculatedDataWithErrors);
		
	EndIf;
	
	If Not SetOfDataSources.Count() = 0 Then
		ResultingCompositionOfMonitor.IsEmpty = False;
		
	EndIf;
	
	ResultingCompositionOfMonitor.Insert("SetOfDataSources", SetOfDataSources);
	
	ResultingCompositionOfMonitor.Insert("StatisticsByLine", StatisticsOfDataSourcesByAreasOfAttention(SetOfDataSources, True));
	
	Return ResultingCompositionOfMonitor;
	
EndFunction

// Returns the availability of dependent / influencing analysis options for the current user
// and the passed analysis option.
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - a variant of the analysis for which related data is being searched.
//
// Returns:
//	Structure - contains signs of availability:
//		*ThereAreInfluencersAvailable - Boolean - 
//		*ThereAreDependentsAvailable - Boolean - 
//
Function GetParametersForAvailabilityOfAnalysisOfInterrelated(AnalysisOption) Export
	
	StructureOfAvailableRelationships = New Structure("ThereAreInfluencersAvailable, ThereAreDependentsAvailable", False, False);
	
	Query = New Query;
	Query.SetParameter("User", Users.CurrentUser());
	Query.SetParameter("AnalysisOption", AnalysisOption);
	Query.Text = QueryTextBasedOnStructureOfAvailableAnalysisOptions();
	
	RequestPackageResult = Query.ExecuteBatch();
	
	// There are dependent measurable goals and analysis options available
	StructureOfAvailableRelationships.ThereAreDependentsAvailable = (Not RequestPackageResult[1].IsEmpty());
	
	// There are influencing measurable goals and analysis options available
	StructureOfAvailableRelationships.ThereAreInfluencersAvailable = (Not RequestPackageResult[2].IsEmpty());
	
	Return StructureOfAvailableRelationships;
	
EndFunction

#EndRegion

#Region FormationOfPrintedFormOfVariantOfAnalysisAndSummaryReport

// Fills in a tabular document with information about individual analysis options
//
// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument - table document to fill in
//	MonitorContent - Structure - See PrepareDataForFilling:
//	 *Parameters - Structure -:
//	  **AnalysisModeOfTheRelated - Boolean - 
//	OutputStructure - Structure - description of the order of output of information blocks.
//
Procedure DisplayIndividualIndicators(SpreadsheetDocument, MonitorContent, OutputStructure) Export
	OutputNotation = False;
	
	If TypeOf(MonitorContent) = Type("FormDataCollection") Then
		MonitorContent = MonitorContent.Unload(,"AnalysisOption, DynamicParameterAddress"); // Assignment Tables - 
		TableColumn2 = MonitorContent.Columns.AnalysisOption; // ValueTableColumn - 
		TableColumn2.Name = "Value";
	EndIf;
	
	Parameters = MonitorContent.Parameters;
	
	// Output of indicators
	If Parameters.AnalysisModeOfTheRelated Then
		For Each OutputItem In OutputStructure.OutputOrder Do
			If OutputStructure[OutputItem].Count() > 0 Then
				For Each DataSourceDescription In OutputStructure[OutputItem] Do
					OutputSeparateIndicator(SpreadsheetDocument, DataSourceDescription);
				EndDo;
			EndIf;
		EndDo;
	Else 
		For Each OutputItem In OutputStructure.OutputOrder Do
			If OutputStructure[OutputItem].Count() > 0 Then
				For Each DataSourceDescription In OutputStructure[OutputItem] Do
					OutputSeparateIndicator(SpreadsheetDocument, DataSourceDescription);
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	// Output of symbols
	If OutputNotation And MonitorContent.Count() > 1 Then
		NotationTemplate = Reports.PerformanceDashboard.GetTemplate("TemplateOfIndicatorEFormDesignations");
		AreaOfNotation = NotationTemplate.GetArea("Designations");
		SpreadsheetDocument.Put(AreaOfNotation);
	EndIf;
EndProcedure

// Fills in a tabular document with information for a separate analysis option
//
// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument - table document to fill in
//	DataSourceDescription - Structure - full description of the data source.
//
Procedure OutputSeparateIndicator(SpreadsheetDocument, DataSourceDescription) Export
	SourceWithParameters = DataSourceDescription.DataSource.Get(); // See InitializeDataSource
	
	If Not SourceWithParameters.CalculationError And Not SourceWithParameters.IsEmpty And SourceWithParameters.CalculationsAreRelevant Then
		PrepareSource(SourceWithParameters, DataSourceDescription.AnalysisOption);
	EndIf;
	
	SpreadsheetDocument.StartRowAutoGrouping();
	
	FillInIndicatorReferenceData(SpreadsheetDocument, DataSourceDescription.AnalysisOption, SourceWithParameters);
	FillChartData(SpreadsheetDocument, DataSourceDescription.AnalysisOption, SourceWithParameters);
	
	SpreadsheetDocument.EndRowAutoGrouping();
	
	SpreadsheetDocument.PutHorizontalPageBreak();
EndProcedure

// Sets standard output parameters for a table document
//
// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument - the table document for the settings.
//
Procedure SetOutputParameters(SpreadsheetDocument) Export
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.FitToPage = True;
	
	// Fields
	SpreadsheetDocument.TopMargin = 5;
	SpreadsheetDocument.BottomMargin = 10;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	
	SpreadsheetDocument.HeaderSize = 5;
	SpreadsheetDocument.FooterSize = 5;
	
	// HeaderFooter
	SpreadsheetDocument.Footer.Enabled = True;
	SpreadsheetDocument.Footer.RightText = StrTemplate(NStr("vi = 'Trang [&%1] trong số [&%2]';
															|ru = 'Страница [&%1] из [&%2]';
															|en = 'Page [&%1] of [&%2]'; fa = 'Page [&%1] of [&%2]';
															|it = 'Pagina [&%1] di [&%2]';
															|pl = 'Strona [&%1] z [&%2]';
															|tr = 'Sayfa [&%2]''dan [&%1]'"), "PageNumber", "PagesTotal");
	// Other parameters
	SpreadsheetDocument.Protection = True;
	SpreadsheetDocument.ShowHeaders = False;
	SpreadsheetDocument.ShowGrid = False;
	SpreadsheetDocument.PrintParametersKey = "PrintedFormOfTargetMonitor";
	SpreadsheetDocument.UsedFileName = NStr("vi = 'Màn hình chỉ số mục tiêu';
											|ru = 'Монитор целевых показателей';
											|en = 'Performance dashboard'; fa = 'داشبورد عملکرد';
											|it = 'Monitor degli indici obiettivo';
											|pl = 'Monitor wskaźników celowych';
											|tr = 'Performans paneli'");
EndProcedure

#EndRegion

#Region AggregateFunctionsOfDataLayoutSystem

// Returns the last value from the total array passed from the SKD
//
// Parameters:
//	Data - Array of Arbitrary - array of totals.
//	ExpandArray - Boolean - True if you need to get the first value of the array
//
// Returns:
//	Arbitrary - the last value in the array.
//
Function GetLastArrayValue(Data, ExpandArray = False) Export
	
	ItemCount = Data.Count();
	
	If ItemCount > 0 Then
		Return Data[?(ExpandArray, 0, ItemCount - 1)];
	Else
		Return Null;
	EndIf;
	
EndFunction

#EndRegion

#Region CalculationOfDataSourcesAndValuesOfAnalysisOptions

// Returns the data source for the analysis option
// If the data source in the cache is outdated, the cache is recalculated and updated.
//
// Parameters:
//	AnalysisOption - Structure
//	ViewOption - EnumRef.DisplayOptionsOfAnalysisOptions - brief, chart, table
//	ForceUpdateData - Boolean - indicates that you don't need to check whether the data is up-to-date.
//	DynamicParameters - Undefined -
//						- Structure - contains the applied dins. parameters of the analysis option:
//							*IndicatorCalculationFrequency - EnumRef.Periodicity - frequency of calculation.
//							*AnalysisObject - String - name of the dimension field that will be used as the analysis object.
//	DemoData - Boolean - Flag for building a report based on demo data.
//
// Returns:
//	Structure - the data source of the analysis variant.
//
Function GetAnalysisVariantDataSource(AnalysisOption, ViewOption, ForceUpdateData = False, DynamicParameters = Undefined, DemoData = False) Export
	// Variable initialization
	DataSource = New Structure;
	GettingDataFromInformationSecurity = True;
	
	If DemoData Then
		DataSource = GetDataSourceOfAnalysisVariantFromDemoData(AnalysisOption, ViewOption, DynamicParameters);
	Else
		// Check if the indicator data is outdated
		// If the account period is 0, then the data is always taken from the IB.
		If Not AnalysisOption.CalculationRelevancePeriod = 0 And Not ForceUpdateData And Not AnalysisOption.DeletionMark Then
			// Let's check if there is data in the cache and its relevance
			If PropertiesOfCacheAnalysisVariantData(AnalysisOption, ViewOption).DataIsRelevant Then
				GettingDataFromInformationSecurity = False;
				
				// Getting data from the cache
				DataSource = GetAnalysisVariantDataSourceFromCache(AnalysisOption, ViewOption);
			EndIf;
		EndIf;
		
		// We will get data from the IB
		If GettingDataFromInformationSecurity Then
			DataSource = GetDataSourceOfAnalysisVariantFromInformationBase(AnalysisOption, ViewOption, DynamicParameters);
			
			If Not AnalysisOption.DeletionMark And DynamicParameters = Undefined Then
				WriteAnalysisVariantDataToCache(DataSource, ViewOption);
			EndIf;
		EndIf;
	EndIf;
	
	Return DataSource;
EndFunction

// Returns the data source of the analysis option, based on the demo data.
//
// Parameters:
//	AnalysisOption - Structure - Attributes of The Analysis Option
//	ViewOption - EnumRef.DisplayOptionsOfAnalysisOptions - brief, chart, table
//	DynamicParameters - Undefined -
//						- Structure - contains the applied dins. parameters of the analysis option:
//							*IndicatorCalculationFrequency - EnumRef.Periodicity - frequency of calculation.
//							*AnalysisObject - String - name of the dimension field that will be used as the analysis object.
//	DataTable - Undefined, 
//				  - ValueTable - a table with possible columns:
//					*Period - Date - 
//					*AnalysisObject - Arbitrary - 
//					*IndicatorValue - Number -
//					*TargetValue_ - Number -
//					*MaximumTargetRange - Number -
//					*MinimumTargetRange - Number -
//					*AdjustedPositiveBorderVariance - Number - 
//					*AdjustedNegativeBorderVariance - Number -
//					*PositiveBorderVariance - Number - 
//					*NegativeBorderVariance - Number - 
//					*TheValueOfTheIndexForMore - Number - 
//
// Returns:
//	See InitializeDataSource
Function GetDataSourceOfAnalysisVariantFromDemoData(AnalysisOption, ViewOption, DynamicParameters = Undefined, DataTable = Undefined) Export
	SetPrivilegedMode(True);
	
	#Region InitializingDataSource
	DataSource = InitializeDataSource(AnalysisOption);
	#EndRegion
	
	#Region InitializationOfCalculationParameters
	CalculationParameters = CalculationParameters(AnalysisOption, ViewOption, DynamicParameters);
	DataSource.CalculationParameters = CalculationParameters;
	#EndRegion 
	
	DataSource.ForTable = CalculationParameters.ForTable;
	
	#Region ConfiguringAndControllingDataLayoutScheme
	DataCompositionSchema = DataLayoutDiagramForCalculation(CalculationParameters);
	
	If Not MonitoringCorrectnessOfSettingsAndData("DataCompositionSchema", DataCompositionSchema, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	#EndRegion 
	
	AnalysisPeriod = CalculationParameters.AnalysisPeriod;
	// We get a table with a continuous interval of period values
	PeriodsTable = PeriodsOfGivenPeriodicity(AnalysisPeriod.StartDate,
			AnalysisPeriod.EndDate,
			CalculationParameters.IndicatorCalculationFrequency);
	
	If CalculationParameters.ThereIsComparison Then
		ComparisonPeriod = CalculationParameters.ComparisonPeriod;
		PeriodsTable = AddPeriodsToTable(PeriodsTable,
				ComparisonPeriod.StartDate,
				ComparisonPeriod.EndDate,
				CalculationParameters.IndicatorCalculationFrequency);
	EndIf;
	
	#Region ConfiguringSettingsComposer
	SettingsComposer = ComposerSettingsForCalculation(DataCompositionSchema, CalculationParameters, DynamicParameters);
	#EndRegion 
	
	#Region CachingDataSourceCalculationParameters
	// Fill in the dynamic properties of the analysis option in the data source
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency = CalculationParameters.IndicatorCalculationFrequency;
	
	Target = AnalysisOption.Owner;
	
	If Not DataCompositionSchema.Parameters.Find("SettlementCurrency") = Undefined 
		And DataCompositionSchema.Parameters.Find("SettlementCurrency").Use = DataCompositionParameterUse.Always Then
		
		SettlementCurrency = DataCompositionClientServer.GetParameter(SettingsComposer, "SettlementCurrency");
		DynamicPropertiesOfAnalysisVariant.Dimensions = SettlementCurrency.Value;
	Else 
		DynamicPropertiesOfAnalysisVariant.Dimensions = Common.ObjectAttributeValue(Target, "Dimensions");
	EndIf;
	
	AvailableAnalysisObjects = Catalogs.StructureOfTargets.AvailableAnalysisObjects(Target);
	AvailableAnalysisValues = Catalogs.StructureOfTargets.AvailableAnalysisValues(Target);
	SelectionAvailableFields = SettingsComposer.Settings.SelectionAvailableFields;
	
	If AvailableAnalysisObjects.FindByValue(CalculationParameters.ObjectOfAnalysisField) <> Undefined Then
		AvailableField = SelectionAvailableFields.FindField(CalculationParameters.ObjectOfAnalysisField);
		ObjectOfAnalysisHeader = AvailableField.Title;
	Else
		ObjectOfAnalysisHeader = "";
	EndIf;
	DynamicPropertiesOfAnalysisVariant.AnalysisObject = CalculationParameters.AnalysisObjectFieldName;
	DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation = ObjectOfAnalysisHeader;
	
	If AvailableAnalysisValues.FindByValue(CalculationParameters.ValueAnalysisField) <> Undefined Then
		AvailableField = SelectionAvailableFields.FindField(CalculationParameters.ValueAnalysisField);
		ValueOfAnalysisHeader = AvailableField.Title;
	Else
		ValueOfAnalysisHeader = "";
	EndIf;
	DynamicPropertiesOfAnalysisVariant.AnalysisValue = CalculationParameters.AnalysisValueFieldName;
	DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation = ValueOfAnalysisHeader;
	
	If AvailableAnalysisValues.FindByValue(CalculationParameters.AnalysisValueAdditionalField) <> Undefined Then
		AvailableField = SelectionAvailableFields.FindField(CalculationParameters.AnalysisValueAdditionalField);
		ValueOfAnalysisIsAdditionalHeader = AvailableField.Title;
	Else
		ValueOfAnalysisIsAdditionalHeader = "";
	EndIf;
	DynamicPropertiesOfAnalysisVariant.AnalysisValueAdditional = CalculationParameters.AnalysisValueAdditionalFieldName;
	DynamicPropertiesOfAnalysisVariant.AnalysisValueAdditionalPresentation = ValueOfAnalysisIsAdditionalHeader;
	#EndRegion
	
	#Region GetData
	DataSource.DateOfCalculation = CurrentSessionDate();
	If DataTable <> Undefined Then
		DataSource.Data = DataTable;
	Else
		DataSource.Data = Catalogs.AnalysisOptionsOfTargetValues.DemonstrationDataOfAnalysisOption(AnalysisOption);
	EndIf;
	#EndRegion
	
	#Region SettingServiceColumnHeaders	
	DataSourceColumns = DataSource.Data.Columns;
	
	SearchColumn = DataSourceColumns.Find(DynamicPropertiesOfAnalysisVariant.AnalysisObject);
	If SearchColumn <> Undefined Then
		SearchColumn.Title = DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation;
	EndIf;
	SearchColumn = DataSourceColumns.Find(DynamicPropertiesOfAnalysisVariant.AnalysisValue);
	If SearchColumn <> Undefined Then
		SearchColumn.Title = DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation;
	EndIf;
	SearchColumn = DataSourceColumns.Find(DynamicPropertiesOfAnalysisVariant.AnalysisValueAdditional);
	If SearchColumn <> Undefined Then
		SearchColumn.Title = DynamicPropertiesOfAnalysisVariant.AnalysisValueAdditionalPresentation;
	EndIf;
	
	// Target value
	SearchColumn = DataSourceColumns.Find("TargetValue_");
	If SearchColumn <> Undefined Then
		SearchColumn.Title = NStr("vi = 'Mục tiêu';
									|ru = 'Цель';
									|en = 'Target'; fa = 'هدف';
									|it = 'Obiettivo';
									|pl = 'Target';
									|tr = 'Hedef'");
	EndIf;
	SearchColumn = DataSourceColumns.Find("AdjustedNegativeBorderVariance");
	If SearchColumn <> Undefined Then
		SearchColumn.Title = NStr("vi = 'Giới hạn của độ lệch âm';
									|ru = 'Граница негативных отклонений';
									|en = 'Negative variance border'; fa = 'مرز انحراف منفی';
									|it = 'Limite degli scostamenti negativi';
									|pl = 'Granica odchyleń ujemnych';
									|tr = 'Negatif sapmaların sınırı'");
	EndIf;
	SearchColumn = DataSourceColumns.Find("AdjustedPositiveBorderVariance");
	If SearchColumn <> Undefined Then
		SearchColumn.Title = NStr("vi = 'Giới hạn của độ lệch dương';
									|ru = 'Граница позитивных отклонений';
									|en = 'Positive variance border'; fa = 'مرز انحراف مثبت';
									|it = 'Limite degli scostamenti positivi';
									|pl = 'Granica odchyleń dodatnich';
									|tr = 'Pozitif sapmaların sınırı'");
	EndIf;
	SearchColumn = DataSourceColumns.Find("MaximumTargetRange");
	If SearchColumn <> Undefined Then
		SearchColumn.Title = NStr("vi = 'Phạm vi mục tiêu tối đa';
									|ru = 'Целевой диапазон максимум';
									|en = 'Maximum target range'; fa = 'حداکثر بازه هدف';
									|it = 'Intervallo di obiettivi massimo';
									|pl = 'Zakres docelowy maksimum';
									|tr = 'Hedef aralık maksimum'");
	EndIf;
	SearchColumn = DataSourceColumns.Find("MinimumTargetRange");
	If SearchColumn <> Undefined Then
		SearchColumn.Title = NStr("vi = 'Phạm vi mục tiêu tối thiểu';
									|ru = 'Целевой диапазон минимум';
									|en = 'Minimum target range'; fa = 'حداقل بازه هدف';
									|it = 'Intervallo di obiettivi minimo';
									|pl = 'Zakres docelowy minimum';
									|tr = 'Hedef aralık minimum'");
	EndIf;
	#EndRegion 
	
	#Region PostProcessingAndControlOfCorrectnessOfSettingsAndData
	If Not MonitoringCorrectnessOfSettingsAndData("Data", DataSource.Data, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	
	// Let's add target values to the table
	If CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ChangeTrends
		Or CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.MeasureCurrentValue Then
		TargetValuesForDates = GetTargetValuesForDates(DataSource.Data.UnloadColumn("Period"), AnalysisOption);
		
		If TargetValuesForDates.Count() > 0 Then
			For Each DataString1 In DataSource.Data Do 
				TargetValuesForDate = TargetValuesForDates.Find(DataString1.Period, "Period");
				If TargetValuesForDate <> Undefined Then
					FillPropertyValues(DataString1, TargetValuesForDates.Find(DataString1.Period, "Period"));
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// Let's fix the relevance of the calculation fact
	DataSource.DataIsRelevant = True;
	
	CollapseData(DataSource, CalculationParameters);
	
	If Not MonitoringCorrectnessOfSettingsAndData("SettlementsRelevance", DataSource.Data, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	
	// Let's process a table of values for two types of object analysis
	If CalculationParameters.ThereIsRunningTotal Then 
		CalculateCumulativeTotal(DataSource.Data, CalculationParameters);
	EndIf;
	
	// Let's check that after analyzing and preparing the source, there is still enough data in it.
	If Not MonitoringCorrectnessOfSettingsAndData("Data", DataSource.Data, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	#EndRegion 
	
	#Region CachingSummaryInformationByPeriod
	FillInSummaryInformationAboutDataSource(DataSource, CalculationParameters);
	#EndRegion
	
	#Region AugmentingDataWithForecast
	AddForecastToData(DataSource, CalculationParameters);
	#EndRegion 
	
	#Region CachingAnalysisAndTrendZones
	FillAnalysisZonesAndTrend(DataSource, CalculationParameters);
	#EndRegion 
	
	SetPrivilegedMode(False);
	
	Return DataSource;
EndFunction

#EndRegion

#Region WorkingWithPeriodsAndDates

// Returns a date offset by the specified number of periods
//
// Parameters:
//	Date - Date - the original date
//	Periodicity - EnumRef.Periodicity - period step
//	NumberOfPeriods_ - Number - number of periods to move the original date by
//  WeekDecadeFromDayOne - Boolean - specifies whether
// 		the calculated date will be shifted to the beginning of the week or decade for the periodicity "Week" and "Decade".
//
// Returns:
//	Date - date offset by the specified number of periods.
//
Function OffsetDate_(Date, Periodicity, NumberOfPeriods_, WeekDecadeFromDayOne = True) Export
	
	If Periodicity = Enums.Periodicity.Year Then
		Return AddMonth(Date, 12 * NumberOfPeriods_);
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Return AddMonth(Date, 6 * NumberOfPeriods_);
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Return AddMonth(Date, 3 * NumberOfPeriods_);
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Return AddMonth(Date, NumberOfPeriods_);
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		If WeekDecadeFromDayOne Then
			Return DateWithOffsetForDecade(Date, NumberOfPeriods_);
		Else
			Return Date + 3600 * 24 * 10 * NumberOfPeriods_;
		EndIf;
		
	ElsIf Periodicity = Enums.Periodicity.Week Then
		If WeekDecadeFromDayOne Then
 			Return BegOfWeek(Date + 3600 * 24 * 7 * NumberOfPeriods_);
		Else
			Return Date + 3600 * 24 * 7 * NumberOfPeriods_;
		EndIf;
		
	ElsIf Periodicity = Enums.Periodicity.Day Then
		Return Date  + 3600 * 24 * NumberOfPeriods_;
		
	Else
		Return Date;
		
	EndIf;
	
EndFunction

// Returns a string representation of the period of the analysis option 
// 
// Parameters:
//	DataSource - See InitializeDataSource
//
// Returns:
//	String - string representation of the period of the analysis variant.
// 
Function PresentationOfAnalysisVariantPeriod(Val DataSource) Export
	Var TextPresentationOfPeriod;
	
	AnalysisOption = DataSource.AnalysisOption; // Structure -
	
	If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then
		
		StandardAnalysisPeriod = AnalysisOption.AnalysisPeriod.Get(); // StandardPeriod -
		TextPresentationOfPeriod = String(Format(StandardAnalysisPeriod.EndDate, "DLF=D"));
	ElsIf AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends
		Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
		
		AnalysisPeriod = AnalysisOption.AnalysisPeriod.Get();
		If TypeOf(AnalysisPeriod) = Type("StandardPeriod") Then
			TextPresentationOfPeriod = PresentationOfStandardPeriod(AnalysisPeriod, False);
		Else
			TextPresentationOfPeriod = String(AnalysisPeriod);
		EndIf;
	ElsIf AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
		StandardAnalysisPeriod = AnalysisOption.AnalysisPeriod.Get(); // StandardPeriod - 
		StandardComparisonPeriod = AnalysisOption.ComparisonPeriod.Get(); // StandardPeriod - 
		TextPresentationOfPeriod = String(Format(StandardComparisonPeriod.EndDate, "DLF=D")) + "/"
			+ String(Format(StandardAnalysisPeriod.EndDate, "DLF=D"));
	EndIf;
	
	Return TextPresentationOfPeriod;
EndFunction

// returns a table of values supplemented with non-entered dates 
// for later use as a DCS object.
//
// Parameters:
//  PeriodsTable - ValueTable - Period table:
//    *Period - Date - 
//  BeginOfPeriod 	- Date - Beginning of the period
//  EndOfPeriod	- Date - end of the period
//  Periodicity	- EnumRef.Periodicity - takes the values "DAY, WEEK, DECADE, MONTH, QUARTER, half-YEAR, YEAR".
//
// Returns:
//   ValueTable - a table of values containing a "Period" column and period values:
//    *Period - Date - 
//
Function AddPeriodsToTable(Val PeriodsTable, BeginOfPeriod, EndOfPeriod, Periodicity) Export
	
	DateDiff = TMCommonUse.DateDiff(BeginOfPeriod, EndOfPeriod, Periodicity);
	
	Counter = 0;
	While Counter <= DateDiff Do 
		PeriodToAdd = OffsetDate_(BeginOfPeriod, Periodicity, Counter);
		
		SearchRow = PeriodsTable.Find(PeriodToAdd, "Period");
		If SearchRow = Undefined Then
			NewPeriod = PeriodsTable.Add();
			NewPeriod.Period = PeriodToAdd;
		EndIf;
		
		Counter = Counter + 1;
		
	EndDo;
	
	PeriodsTable.Sort("Period");
	
	Return PeriodsTable;
	
EndFunction

// Returns a table of values for later use as an external source.
//
// Parameters:
//  BeginOfPeriod 	- Date - the beginning of the period.
//  EndOfPeriod	- Date - end of the period.
//  Periodicity	- EnumRef.Periodicity - takes the values "DAY, WEEK, DECADE, MONTH, QUARTER, half-YEAR, YEAR".
//
// Returns:
//   ValueTable	 - a table of values containing the "Period" column and period values.
//
Function PeriodsOfGivenPeriodicity(BeginOfPeriod, EndOfPeriod, Periodicity) Export 
	
	Var PeriodsTable;
	
	PeriodsTable = New ValueTable;
	PeriodsTable.Columns.Add("Period");
	
	NewPeriod = PeriodsTable.Add();
	NewPeriod.Period = BeginOfPeriod;
	
	DateDiff = TMCommonUse.DateDiff(BeginOfPeriod, EndOfPeriod, Periodicity);
	
	Counter = 1;
	While Counter <= DateDiff Do 
		
		NewPeriod = PeriodsTable.Add();
		NewPeriod.Period = OffsetDate_(BeginOfPeriod, Periodicity, Counter);
		
		Counter = Counter + 1;
		
	EndDo;
	
	Return PeriodsTable;
	
EndFunction

// Returns a table of values for later use as an external source.
//
// Parameters:
//  BeginOfPeriod 	- Date - the beginning of the period.
//  EndOfPeriod	- Date - end of the period.
//  Periodicity	- EnumRef.Periodicity - takes the values "DAY, WEEK, DECADE, MONTH, QUARTER, half-YEAR, YEAR".
//
// Returns:
//   ValueTable	 - a table of values containing the column "Data counts" and the values of periods.
//
Function PeriodsWithEndDate(BeginOfPeriod, EndOfPeriod, Periodicity) Export
	
	Var PeriodsTable;
	
	Months = New Map;
	Months.Insert(1, NStr("vi = 'Tháng 1';
							|ru = 'Январь';
							|en = 'January'; fa = 'ژانویه';
							|it = 'Gennaio';
							|pl = 'Styczeń';
							|tr = 'Ocak'"));
	Months.Insert(2, NStr("vi = 'Tháng 2';
							|ru = 'Февраль';
							|en = 'February'; fa = 'فوریه';
							|it = 'Febbraio';
							|pl = 'Luty';
							|tr = 'Şubat'"));
	Months.Insert(3, NStr("vi = 'Tháng 3';
							|ru = 'Март';
							|en = 'March'; fa = 'مارس';
							|it = 'Marzo';
							|pl = 'Marzec';
							|tr = 'Mart'"));
	Months.Insert(4, NStr("vi = 'Tháng 4';
							|ru = 'Апрель';
							|en = 'April'; fa = 'آوریل';
							|it = 'Aprile';
							|pl = 'Kwiecień';
							|tr = 'Nisan'"));
	Months.Insert(5, NStr("vi = 'Tháng 5';
							|ru = 'Май';
							|en = 'May'; fa = 'مه';
							|it = 'Maggio';
							|pl = 'Maj';
							|tr = 'Mayıs'"));
	Months.Insert(6, NStr("vi = 'Tháng 6';
							|ru = 'Июнь';
							|en = 'June'; fa = 'ژوئن';
							|it = 'Giugno';
							|pl = 'Czerwiec';
							|tr = 'Haziran'"));
	Months.Insert(7, NStr("vi = 'Tháng 7';
							|ru = 'Июль';
							|en = 'July'; fa = 'ژوئیه';
							|it = 'Luglio';
							|pl = 'Lipiec';
							|tr = 'Temmuz'"));
	Months.Insert(8, NStr("vi = 'Tháng 8';
							|ru = 'Август';
							|en = 'August'; fa = 'اوت';
							|it = 'Agosto';
							|pl = 'Sierpień';
							|tr = 'Ağustos'"));
	Months.Insert(9, NStr("vi = 'Tháng 9';
							|ru = 'Сентябрь';
							|en = 'September'; fa = 'سپتامبر';
							|it = 'Settembre';
							|pl = 'Wrzesień';
							|tr = 'Eylül'"));
	Months.Insert(10, NStr("vi = 'Tháng 10';
							|ru = 'Октябрь';
							|en = 'October'; fa = 'اکتبر';
							|it = 'Ottobre';
							|pl = 'Październik';
							|tr = 'Ekim'"));
	Months.Insert(11, NStr("vi = 'Tháng 11';
							|ru = 'Ноябрь';
							|en = 'November'; fa = 'نوامبر';
							|it = 'Novembre';
							|pl = 'Listopad';
							|tr = 'Kasım'"));
	Months.Insert(12, NStr("vi = 'Tháng 12';
							|ru = 'Декабрь';
							|en = 'December'; fa = 'دسامبر';
							|it = 'Dicembre';
							|pl = 'Grudzień';
							|tr = 'Aralık'"));
	
	PeriodsTable = New ValueTable;
	PeriodsTable.Columns.Add("DateOfCalculation");
	PeriodsTable.Columns.Add("MonthName");
	PeriodsTable.Columns.Add("Month");
	
	NewPeriod = PeriodsTable.Add();
	NewPeriod.DateOfCalculation = EndOfPeriod(BeginOfPeriod, Periodicity);
	NewPeriod.Month = Month(NewPeriod.DateOfCalculation);
	NewPeriod.MonthName = Months[NewPeriod.Month];
	
	DateDiff = TMCommonUse.DateDiff(BeginOfPeriod, EndOfPeriod, Periodicity);
	
	Counter = 1;
	While Counter <= DateDiff Do
		NewPeriod = PeriodsTable.Add();
		NewPeriod.DateOfCalculation = EndOfPeriod(OffsetDate_(BeginOfPeriod, Periodicity, Counter, False), Periodicity);
		NewPeriod.Month = Month(NewPeriod.DateOfCalculation);
		NewPeriod.MonthName = Months[NewPeriod.Month];
		
		Counter = Counter + 1;
	EndDo;
	
	Return PeriodsTable;
	
EndFunction

// Returns a table of values for later use as an external source.
//
// Parameters:
//	BeginOfPeriod - Date - Beginning of the period
//	EndOfPeriod- Date - end of the period
//	ComparisonPeriodStep- EnumRef.Periodicity - the period in which the segment from the beginning to the end of the period will be selected.
//	NumberOfPeriods- Number - the number of compared periods of the specified periodicity.
//	
// Example: The beginning of the period = the beginning of the year, the end of the period = the Cur date, the step of the periodsreferences = year, the number of periods = 2
//	It will get a set of periods from the beginning of the year to the Cur date for the Cur and last year.
//
// Returns:
//   ValueTable - a table of values containing the columns "Calculation date", "Calculation completion date" and date values:
//    *SettlementStartDate - Date - 
//    *SettlementEndDate - Date - 
//
Function PeriodsComparedToSimilarPeriodsInPast(BeginOfPeriod, EndOfPeriod, ComparisonPeriodStep, NumberOfPeriods) Export
	
	Var PeriodsTable;
	
	PeriodsTable = New ValueTable;
	PeriodsTable.Columns.Add("SettlementStartDate");
	PeriodsTable.Columns.Add("SettlementEndDate");
	For Counter = 0 To NumberOfPeriods - 1 Do
		NewPeriod = PeriodsTable.Add();
		NewPeriod.SettlementStartDate = OffsetDate_(BeginOfPeriod, ComparisonPeriodStep, -Counter, False);
		
		// Checking that the full multiple period is specified
		MinimumPeriodicityOfFullPeriod = MinimumPeriodicityOfFullPeriod(BeginOfPeriod, EndOfPeriod, ComparisonPeriodStep);
		
		If MinimumPeriodicityOfFullPeriod <> Undefined Then
			NewPeriod.SettlementEndDate = EndOfPeriod(OffsetDate_(EndOfPeriod, ComparisonPeriodStep, -Counter, False), MinimumPeriodicityOfFullPeriod);
		Else
			NewPeriod.SettlementEndDate = OffsetDate_(EndOfPeriod, ComparisonPeriodStep, -Counter, False);
		EndIf;
	EndDo;
	
	Return PeriodsTable;
	
EndFunction

#EndRegion

#Region RgbhsvColorConversion

// Returns the color components in the HSV model, for the given RGB components
//
// Parameters:
//	Red - Number - from 0 to 255
//	Green - Number - from 0 to 255
//	B - Number - from 0 to 255
//	Tone - Number - returns a value from 0 to 360 (degrees)
//	Saturation - Number - returns a value from 0 to 100 (%)
//	Brightness - Number - returns a value from 0 to 100 (%).
//
Procedure GetToneSaturationBrightnessByRedGreenBlue(Red, Green, B, Tone, Saturation, Brightness) Export
	
	LedRed = Red/255;
	LedGreen = Green/255;
	LedBlue = B/255;
	
	// Let 's define the brightness
	MaxColors = Max(LedRed, LedGreen, LedBlue);	
	MinColors = Min(LedRed, LedGreen, LedBlue);
	
	Brightness = Round(100 * MaxColors);
	
	// Let 's define saturation
	If MaxColors = 0 Then 
		Saturation = 0;
		
	Else 
		Saturation = Round(100 * (1 - MinColors/MaxColors));
		
	EndIf;
	
	// Let's define the color tone
	If MaxColors = MinColors Then
		Tone = 0;
		
	ElsIf MaxColors = LedRed And LedGreen >= LedBlue Then
		Tone = 60*(LedGreen - LedBlue)/(MaxColors - MinColors);
		
	ElsIf MaxColors = LedRed And LedGreen < LedBlue Then
		Tone = 60*(LedGreen - LedBlue)/(MaxColors - MinColors) + 360;
		
	ElsIf MaxColors = LedGreen Then
		Tone = 60*(LedBlue - LedRed)/(MaxColors - MinColors) + 120;
		
	ElsIf MaxColors = LedBlue Then
		Tone = 60*(LedRed - LedGreen)/(MaxColors - MinColors) + 240;
		
	EndIf;
	
EndProcedure

// Returns color components based on the RGB model, based on the passed Web color.
//
// Parameters:
//	Color - WebColors - the system enumeration.
//	Red - Number - returns a value from 0 to 255.
//	Green - Number - returns a value from 0 to 255.
//	B - Number - returns a value from 0 to 255.
//
Procedure GetRedGreenBlueWebColors(Color, Red, Green, B) Export
	
	ComponentsOfWebColors = TargetValueMonitoringCached.ComponentsOfWebColors();
	WebColorString = ComponentsOfWebColors.Find(Color, "WebColor_");
	
	If Not WebColorString = Undefined Then
		Red = WebColorString.Red;
		Green = WebColorString.Green;
		B   = WebColorString.B;
	Else 
		Red = 0;
		Green = 0;
		B = 0;
	EndIf;
	
EndProcedure

// Returns color components based on the RGB model and the passed HSV components.
//
// Parameters:
//	Tone - Number - from 0 to 360 (degrees).
//	Saturation - Number - from 0 to 100 (%).
//	Brightness - Number - from 0 to 100 (%).
//	Red - Number - returns a value from 0 to 255.
//	Green - Number - returns a value from 0 to 255.
//	B - Number - returns a value from 0 to 255.
//
Procedure GetRedGreenBlueByToneSaturationBrightness(Tone, Saturation, Brightness, Red, Green, B) Export
	
	ReducedSaturation = Saturation/100;
	ReducedLightness = Brightness/100;
	
	Whole60 = Int(Tone/60);
	Balance60 = Tone/60 - Whole60;
	
	pTemp = ReducedLightness * (1 - ReducedSaturation);
	qTemp = ReducedLightness * (1 - Balance60 * ReducedSaturation);
	tTemp = ReducedLightness * (1 - (1 - Balance60) * ReducedSaturation);
	
	If Whole60 = 0 Then
		LedRed = ReducedLightness;
		LedGreen = tTemp;
		LedBlue= pTemp;
		
	ElsIf Whole60 = 1 Then
		LedRed = qTemp;
		LedGreen = ReducedLightness;
		LedBlue= pTemp;
		
	ElsIf Whole60 = 2 Then
		LedRed = pTemp;
		LedGreen = ReducedLightness;
		LedBlue= tTemp;
		
	ElsIf Whole60 = 3 Then
		LedRed = pTemp;
		LedGreen = qTemp;
		LedBlue= ReducedLightness;
		
	ElsIf Whole60 = 4 Then
		LedRed = tTemp;
		LedGreen = pTemp ;
		LedBlue= ReducedLightness;
		
	ElsIf Whole60 = 5 Then
		LedRed = ReducedLightness;
		LedGreen = pTemp;
		LedBlue= qTemp;
		
	EndIf;
	
	Red = Round(255 * LedRed, 0);
	Green = Round(255 * LedGreen, 0);
	B = Round(255 * LedBlue, 0);
	
EndProcedure

// Returns additional color components based on the HSV model, based on the passed HSV components.
//
// Parameters:
//	Tone - Number - from 0 to 360 (degrees).
//	Saturation - Number - from 0 to 100 (%).
//	Brightness - Number - from 0 to 100 (%).
//	NewTone - Number - returns a value from 0 to 360 (degrees).
//	NewSaturation - Number - returns a value from 0 to 100 (%).
//	NewBrightness - Number - returns a value from 0 to 100 (%).
//
Procedure GetAdditionalColorByToneSaturationBrightness(Tone, Saturation, Brightness, NewTone, NewSaturation, NewBrightness) Export
	
	ReducedSaturation = Saturation/100;
	ReducedLightness = Brightness/100;
	
	If Tone >= 180 Then
		NewTone = Tone - 180;
		
	Else
		NewTone = Tone + 180;
		
	EndIf;
	
	NewSaturation = 100 * (ReducedLightness * ReducedSaturation) / (ReducedLightness * (ReducedSaturation - 1) + 1);
	
	NewBrightness = 100 * (ReducedLightness * (ReducedSaturation - 1) + 1);
	
EndProcedure

// Returns additional color components based on the HSV model, based on the passed RGB components.
//
// Parameters:
//	Red - Number - from 0 to 255.
//	Green - Number - from 0 to 255.
//	B - Number - from 0 to 255.
//	NewRed - Number - returns a value from 0 to 255.
//	NewGreen - Number - returns a value from 0 to 255.
//	NewBlue - Number - returns a value from 0 to 255.
//
Procedure GetExtraColorByRedGreenBlue(Red, Green, B, NewRed, NewGreen, NewBlue) Export
	
	Tone = 0;
	Saturation = 0;
	Brightness = 0;
	NewTone = 0;
	NewSaturation = 0;
	NewBrightness = 0;
	
	GetToneSaturationBrightnessByRedGreenBlue(Red, Green, B, Tone, Saturation, Brightness);
	GetAdditionalColorByToneSaturationBrightness(Tone, Saturation, Brightness, NewTone, NewSaturation, NewBrightness);
	GetRedGreenBlueByToneSaturationBrightness(NewTone, NewSaturation, NewBrightness, NewRed, NewGreen, NewBlue);
	
EndProcedure

#EndRegion

#Region EventSubscriptions

// Handler subscribe to event Variancecovariance.
//
// Parameters:
//	Source - CatalogObject.AnalysisOptionsOfTargetValues - Link to the analysis option
//	Cancel - Boolean - indicates that the object was not deleted.
//
Procedure ReportOptionBeforeDeletion(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	ReportVariant = Source.Ref;
	
	Query = New Query;
	Query.Text =
	"SELECT
		|	ReportsToDrillDown.Ref
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues.ReportsToDrillDown AS ReportsToDrillDown
		|WHERE
		|	ReportsToDrillDown.ReportVariant = &ReportVariant";
	Query.SetParameter("ReportVariant", ReportVariant);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		AnalysisOptionObject = Selection.Ref.GetObject(); // CatalogObject.AnalysisOptionsOfTargetValues -
		DeletedDecryptionReports = AnalysisOptionObject.ReportsToDrillDown.FindRows(
			New Structure("ReportVariant", ReportVariant));
		
		For Each String In DeletedDecryptionReports Do 
			AnalysisOptionObject.ReportsToDrillDown.Delete(String);
		EndDo;
		
		AnalysisOptionObject.Write();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InfobaseUpdateHandlers

// The procedure fills in the "goal Categories", "goal structure", and "target analysis Options" directories,
// as well as the "Target values of analysis options" data register using the specified template.
// If the demo metrics were already created earlier, the default settings are restored.
// The procedure is used only when updating the information database, the first launch
// , and can be called from the "Administration" section.
//
Procedure FillInGoalStructureAndAnalysisOptions() Export
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	
	TempFilesDir = FileSystem.CreateTemporaryDirectory("kpitmp");
	
	// Extracting the model file
	ArchiveFullName = TempFilesDir + "ModelData.zip";
	Try
		NameOfTemplateWithLanguageCode = StringFunctionsClientServer.SubstituteParametersToString(
				"TargetMonitoringDemonstrationModel_%1", 
				Common.DefaultLanguageCode());
		
		If Metadata.CommonTemplates.Find(NameOfTemplateWithLanguageCode) = Undefined Then
			Return;
		EndIf;
		
		BinaryData = GetCommonTemplate(NameOfTemplateWithLanguageCode);
		BinaryData.Write(ArchiveFullName);
	Except
		LREvent = NStr("vi = 'Tải xuống mô hình chỉ số mục tiêu';
						|ru = 'Загрузка демонстрационной модели целевых показателей';
						|en = 'Import target value demonstration model'; fa = 'Import target value demonstration model';
						|it = 'Download del modello dimostrativo degli indicatori mirati';
						|pl = 'Pobieranie modelu demonstracyjnego wskaźników celowych';
						|tr = 'Hedef değer demo modelinin yüklenmesi'", Common.DefaultLanguageCode());
		WriteLogEvent(
			LREvent,
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	ZipFileReader = New ZipFileReader(ArchiveFullName);
	ZipFileReader.ExtractAll(TempFilesDir, ZIPRestoreFilePathsMode.Restore);
	
	DeleteFiles(ArchiveFullName);
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(TempFilesDir + "ModelData.xml");
	
	ObjectName = Undefined;
	NewObjectElement = Undefined;
	NewRecordSet_ = Undefined; // InformationRegisterRecordSet -
	SkipRecording = False;
	LinkTextOfCurElement = "";
	While XMLReader.Read() Do  // The supplied model of indicators
		LocalName = XMLReader.LocalName;
		
		If XMLReader.NodeType = XMLNodeType.StartElement
			And (LocalName = "GoalCategory" 
			Or LocalName = "AnalysisOptionsOfTargetValues" 
			Or LocalName = "StructureOfTargets"
			Or LocalName = "AnalysisOptionTargetValues") Then
			
			ObjectName = LocalName;
		ElsIf XMLReader.NodeType = XMLNodeType.StartElement
			And (LocalName = "GoalCategory_" 
			Or LocalName = "AnalysisOption" 
			Or LocalName = "GoalStructureElement")
			And Not ObjectName = "AnalysisOptionTargetValues" Then
			
			NewObjectElement = Catalogs[ObjectName].CreateItem();
		ElsIf XMLReader.NodeType = XMLNodeType.StartElement
			And LocalName = "TargetValueOfAnalysisOption" Then
			
			NewRecordSet_ = InformationRegisters[ObjectName].CreateRecordSet(); // InformationRegisterRecordSet -
			NewObjectElement = NewRecordSet_.Add();
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement
			And (LocalName = "GoalCategory_" 
			Or LocalName = "AnalysisOption" 
			Or LocalName = "GoalStructureElement")
			And Not ObjectName = "AnalysisOptionTargetValues" Then
			
			If NewObjectElement <> Undefined And Not SkipRecording Then
				NewObjectElement.Write();
				NewObjectElement = Undefined;
			ElsIf NewObjectElement <> Undefined And SkipRecording Then
				NewObjectElement = Undefined;
				SkipRecording = False;
			EndIf;
		ElsIf XMLReader.NodeType = XMLNodeType.EndElement
			And LocalName = "TargetValueOfAnalysisOption" Then
			
			If NewObjectElement <> Undefined And Not SkipRecording Then
				NewRecordSet_.Write();
			ElsIf NewObjectElement <> Undefined And SkipRecording Then
				SkipRecording = False;
			EndIf;
		Else
			If NewObjectElement <> Undefined And XMLReader.NodeType = XMLNodeType.StartElement Then
				TagName = LocalName;
			ElsIf NewObjectElement <> Undefined And XMLReader.NodeType = XMLNodeType.Text Then
				If TagName = "Ref" 
					Or TagName = "Parent" Then
					
					UUID = New UUID(XMLReader.Value);
					ObjectElementReference = Catalogs[ObjectName].GetRef(UUID);
					
					If TagName = "Ref" Then
						LinkTextOfCurElement = XMLReader.Value;
						
						// Canceling an entry for analysis options and metrics
						SkipRecording = SkipRecording(LinkTextOfCurElement);
						
						If ObjectIsInDatabase(ObjectName, ObjectElementReference) Then
							NewObjectElement = ObjectElementReference.GetObject();
						Else
							NewObjectElement.SetNewObjectRef(ObjectElementReference);
						EndIf;
					Else
						NewObjectElement[TagName] = ObjectElementReference;
					EndIf;
				ElsIf TagName = "Owner" Then
					UUID = New UUID(XMLReader.Value);
					ObjectElementReference = Catalogs.StructureOfTargets.GetRef(UUID);
					NewObjectElement[TagName] = ObjectElementReference;
				ElsIf TagName = "TargetCategory" Then
					UUID = New UUID(XMLReader.Value);
					ObjectElementReference = Catalogs.GoalCategory.GetRef(UUID);
					NewObjectElement[TagName] = ObjectElementReference;
				ElsIf ObjectName = "AnalysisOptionTargetValues" And TagName = "AnalysisOption" Then
					UUID = New UUID(XMLReader.Value);
					ObjectElementReference = Catalogs.AnalysisOptionsOfTargetValues.GetRef(UUID);
					NewRecordSet_.Filter.AnalysisOption.Set(ObjectElementReference);
					
					SkipRecording = SkipRecording(XMLReader.Value);
					
					NewObjectElement[TagName] = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
				Else
					// Filling in parameters referring to data
					If TagName = "StorageOfDataCompositionUserSettings" 
						And LinkTextOfCurElement = "4838f66e-bcda-11e4-8d8d-e0cb4ed5f4cc" Then // Analysis option "EUR exchange rate"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						DataCompositionClientServer.SetParameter(UserSettings, "ConvertibleCurrency", CurrencyEUR());
						DataCompositionClientServer.SetParameter(UserSettings, "SettlementCurrency", CurrencyRUB());
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And LinkTextOfCurElement = "e859aeb6-bce3-11e4-8d8d-e0cb4ed5f4cc" Then // The "USD Exchange Rate" analysis option
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						DataCompositionClientServer.SetParameter(UserSettings, "ConvertibleCurrency", CurrencyUSD());
						DataCompositionClientServer.SetParameter(UserSettings, "SettlementCurrency", CurrencyRUB());
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And LinkTextOfCurElement = "4838f66b-bcda-11e4-8d8d-e0cb4ed5f4cc" Then // Analysis option "Remaining DS / RUB"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						
						SetSelectionValueById(UserSettings, "40ff4cd7-1c9f-42f1-b57d-4c241d5c2fd5", CurrencyRUB());
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And LinkTextOfCurElement = "4838f66c-bcda-11e4-8d8d-e0cb4ed5f4cc" Then // Analysis option "DS/USD balance"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						
						SetSelectionValueById(UserSettings, "40ff4cd7-1c9f-42f1-b57d-4c241d5c2fd5", CurrencyUSD());
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And LinkTextOfCurElement = "4838f66d-bcda-11e4-8d8d-e0cb4ed5f4cc" Then // Analysis option "Balance of DS / EUR"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						
						SetSelectionValueById(UserSettings, "40ff4cd7-1c9f-42f1-b57d-4c241d5c2fd5", CurrencyEUR());
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And (LinkTextOfCurElement = "49c43ecb-bcea-11e4-8d8d-e0cb4ed5f4cc"         // Analysis option "Execution of the sales plan (week)"
						Or LinkTextOfCurElement = "405ff23a-bd08-11e4-8d8d-e0cb4ed5f4cc") Then // Analysis option "Execution of the sales plan (month)"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						
						DataCompositionClientServer.SetParameter(UserSettings, 
							"Scenario", 
							Planning.GetDefaultScript(Enums.TypesOfPlans.SalesPlan));
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf LinkTextOfCurElement = "4838f663-bcda-11e4-8d8d-e0cb4ed5f4cc" // The structure of the goals "Control of the execution of the sales plan"
						And TagName = "StorageOfDataCompositionSettings" Then
						
						StorageOfDataCompositionSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						DataCompositionSettings = StorageOfDataCompositionSettings.Get();
						
						DataCompositionClientServer.SetParameter(DataCompositionSettings, 
							"Scenario", 
							Planning.GetDefaultScript(Enums.TypesOfPlans.SalesPlan));
						
						NewObjectElement[TagName] = New ValueStorage(DataCompositionSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And (LinkTextOfCurElement = "2d6a8c2a-bcec-11e4-8d8d-e0cb4ed5f4cc"         // Analysis option "Execution of the procurement plan (week)"
						Or LinkTextOfCurElement = "af11cd1c-bd0c-11e4-8d8d-e0cb4ed5f4cc") Then // Analysis option "Execution of the procurement plan (month)"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						
						DataCompositionClientServer.SetParameter(UserSettings, 
							"Scenario", 
							Planning.GetDefaultScript(Enums.TypesOfPlans.PurchasePlan));
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf LinkTextOfCurElement = "4838f664-bcda-11e4-8d8d-e0cb4ed5f4cc" // The structure of the goals "Control of the execution of the procurement plan"
						And TagName = "StorageOfDataCompositionSettings" Then
						
						StorageOfDataCompositionSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						DataCompositionSettings = StorageOfDataCompositionSettings.Get();
						
						DataCompositionClientServer.SetParameter(DataCompositionSettings, 
							"Scenario", 
							Planning.GetDefaultScript(Enums.TypesOfPlans.PurchasePlan));
						
						NewObjectElement[TagName] = New ValueStorage(DataCompositionSettings);
						
					ElsIf TagName = "StorageOfDataCompositionUserSettings" 
						And (LinkTextOfCurElement = "2d6a8c2b-bcec-11e4-8d8d-e0cb4ed5f4cc"         // Analysis option "Execution of the production plan (week)"
						Or LinkTextOfCurElement = "af11cd1d-bd0c-11e4-8d8d-e0cb4ed5f4cc") Then // Analysis option "Execution of the production plan (month)"
						
						StorageOfDataCompositionUserSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						UserSettings = StorageOfDataCompositionUserSettings.Get();
						
						DataCompositionClientServer.SetParameter(UserSettings, 
							"Scenario", 
							Planning.GetDefaultScript(Enums.TypesOfPlans.ProductionPlan));
						
						NewObjectElement[TagName] = New ValueStorage(UserSettings);
						
					ElsIf LinkTextOfCurElement = "4838f665-bcda-11e4-8d8d-e0cb4ed5f4cc" // The structure of the goals "Control of the execution of the production plan"
						And TagName = "StorageOfDataCompositionSettings" Then
						
						StorageOfDataCompositionSettings = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
						DataCompositionSettings = StorageOfDataCompositionSettings.Get();
						
						DataCompositionClientServer.SetParameter(DataCompositionSettings, 
							"Scenario", 
							Planning.GetDefaultScript(Enums.TypesOfPlans.ProductionPlan));
						
						NewObjectElement[TagName] = New ValueStorage(DataCompositionSettings);
						
					ElsIf Not UseMultipleCurrencies
						And (LinkTextOfCurElement = "e859aeb7-bce3-11e4-8d8d-e0cb4ed5f4cc"       // Analysis option "The balance of the DS in the upr. currency (week)"
							Or LinkTextOfCurElement = "3a30c0ea-bd02-11e4-8d8d-e0cb4ed5f4cc") // Analysis option "The balance of the DS in the upr. currency (month)"
						And TagName = "AnalysisObject" Then
						
						NewObjectElement[TagName] = New ValueStorage(New DataCompositionField("StorageLocation"));
					Else
						NewObjectElement[TagName] = XMLValue(TypeOf(NewObjectElement[TagName]), XMLReader.Value);
					EndIf;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	XMLReader.Close();
	
	DeleteFiles(TempFilesDir);
EndProcedure

#EndRegion 

#Region Other

// Returns a completed and configured chart for the metrics monitor.
//
// Parameters:
//	Chart - Chart - source object.
//	AnalysisOption - Structure - Attributes of the analysis option.
//	SourceWithParameters - See InitializeDataSource
//
// Returns:
//	Chart - filled with data and customized chart.
//
Function FillInChartForMonitor(Chart, AnalysisOption, SourceWithParameters) Export
	PrepareSource(SourceWithParameters, AnalysisOption);
	
	DataSourceForChart = SourceWithParameters.Data;
	DynamicPropertiesOfAnalysisVariant = SourceWithParameters.DynamicPropertiesOfAnalysisVariant;
	
	SetChartDataSource(Chart, SourceWithParameters, AnalysisOption);
	SetDefaultChartSettings(Chart, AnalysisOption, SourceWithParameters.PropertiesOfGeneralStatistics);
	
	// Let's set the settings for the points
	If Not DataSourceForChart.Columns.Find("Period") = Undefined Then
		SetChartPointNames(Chart.Points,
				DynamicPropertiesOfAnalysisVariant.AnalysisValue,
				DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency);
	EndIf;
	
	If Not DataSourceForChart.Columns.Find("Flag") = Undefined 
		And AnalysisOption.CalculateForecast 
		And Not SourceWithParameters.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.IsEmpty Then
		// Select all the forecast periods
		SelectionOnBasisOf = New Structure("Flag", True);
		FoundRowsWithPeriods = DataSourceForChart.FindRows(SelectionOnBasisOf);
		PeriodsWithSign = DataSourceForChart.Copy(FoundRowsWithPeriods, "Period");
		SetCustomChartPointSettings(Chart.Points, AnalysisOption, PeriodsWithSign);
		
		// Delete the "Feature" series
		SourceColumns = DataSourceForChart.Columns;
		SourceColumns.Delete(SourceColumns.IndexOf(SourceColumns.Find("Flag")));
		
	EndIf;
	
	SetDefaultChartSeriesSettings(Chart.Series);
	
	If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then
		SetMeasurementChartSettings(Chart, AnalysisOption, SourceWithParameters);
	Else
		SetCustomChartSeriesSettings(Chart.Series, SourceWithParameters);
	EndIf;
	
	Return Chart;
	
EndFunction

// Fills in the table of values for the indicator monitor
//
// Parameters:
//	TableOfMonitorValues - ValueTable - source object
//	IDOfFormElement - String - string ID of the form element that defines uniqueness
//	AnalysisOption - Structure - Attributes of The Analysis Option
//	SourceWithParameters - See InitializeDataSource
//
Procedure FillInTableForMonitor(TableOfMonitorValues, IDOfFormElement, AnalysisOption, SourceWithParameters) Export
	
	PrepareSource(SourceWithParameters, AnalysisOption);
	
	DataSourceData = SourceWithParameters.Data;
	DynamicPropertiesOfAnalysisVariant = SourceWithParameters.DynamicPropertiesOfAnalysisVariant;
	
	SourceColumns = DataSourceData.Columns;
	For Each SourceColumn1 In SourceColumns Do
		If SourceColumn1.Name = DynamicPropertiesOfAnalysisVariant.AnalysisObject Then
			SourceColumn1.Name = "ColumnObjectOfAnalysis"
				+ ?(Not IsBlankString(IDOfFormElement), "__", "") + IDOfFormElement;
		ElsIf SourceColumn1.Name = DynamicPropertiesOfAnalysisVariant.AnalysisValue Then
			SourceColumn1.Name = "ColumnAnalysisValue"
				+ ?(Not IsBlankString(IDOfFormElement), "__", "") + IDOfFormElement;
		EndIf;
	EndDo;
	
	If TypeOf(TableOfMonitorValues) = Type("FormDataCollection") Then
		TableOfMonitorValues.Load(DataSourceData);
	Else
		TableOfMonitorValues = DataSourceData;
	EndIf;
	
	// Format the value according to the data of the indicator
	For Each MonitorValueTableRow In TableOfMonitorValues Do
		ColumnNameValue = "ColumnAnalysisValue" + ?(Not IsBlankString(IDOfFormElement), "__", "") + IDOfFormElement;
		ValueToSet = Round(MonitorValueTableRow[ColumnNameValue], AnalysisOption.FractionalPartCalculationAccuracy);
		
		MonitorValueTableRow[ColumnNameValue] = ValueToSet;
	EndDo;
EndProcedure

// Returns a chart with an error message in the header
// 
// Parameters:
//	DiagramForErrors - Chart - diagram where the error message will be set
//	ErrorText - String - text of the output error.
//
// Returns:
//	Chart - the diagram in which the error message will be set.
// 
Function GetChartForCalculationErrors(DiagramForErrors, ErrorText) Export
	DiagramForErrors.DataSource = Undefined;
	
	// Let's set the header with an error
	DiagramForErrors.TitleArea.Top = 0;
	DiagramForErrors.TitleArea.Left = 0;
	DiagramForErrors.TitleArea.Bottom = 1;
	DiagramForErrors.TitleArea.Right = 1;
	DiagramForErrors.TitleArea.Text = ErrorText;
	DiagramForErrors.TitleArea.TextColor = WebColors.Red;
	
	DiagramForErrors.PlotArea.Top = 0;
	DiagramForErrors.PlotArea.Left = 0;
	DiagramForErrors.PlotArea.Bottom = 0;
	DiagramForErrors.PlotArea.Right = 0;
	
	DiagramForErrors.ShowLegend = False;
	
	Return DiagramForErrors;
EndFunction

// Returns the default currency for filling in the goal structure settings and analysis options.
//
// Returns:
//	CatalogRef.Currencies - the default currency for the settings.
//
Function GetDefaultCurrency() Export
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	
	Return ManagementAccountingCurrency;
	
EndFunction

// Returns the name of the value of the enumeration by reference metadata object.
//
// Parameters:
//  EnumRef - EnumRef - enumeration value.
//
// Returns:
//  String - If not found, then an empty string.
//
Function GetNameOfEnumerationValue(EnumRef) Export
	
	EnumValueName = "";
	
	If Not EnumRef.IsEmpty() Then
		EnumValueName = Common.EnumerationValueName(EnumRef);
	EndIf;
	
	Return EnumValueName;
	
EndFunction

// returns the index of the image that characterizes the State (Status) of the indicator for the list.
//
// Parameters:
//	AnalysisOption - Structure - Attributes of the analysis option.
//
// Returns:
//	Number - index of the image in the collection.
//
Function GetIndexOfStateImageForMetric(AnalysisOption, DataSource) Export
	
	Var IndexOfIndicatorStatus;
	
	IndexOfIndicatorStatus = Undefined;
	
	TypeOfTarget = GetTargetValueView(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
		AnalysisOption);
	TargetTrend = Common.ObjectAttributeValue(AnalysisOption, "Owner.TargetTrend");
	AnalysisArea = ValueAnalysisZone(DataSource,
			TargetTrend,
			TypeOfTarget,
			Common.ObjectAttributeValue(AnalysisOption, "FractionalPartCalculationAccuracy"));
	
	NameOfRegionOfStateMatrix =  "Unstable" + "_" + AnalysisArea.TheActualTrend + "_" + "Zone_"
		+ AnalysisArea.ZoneNumber + "_" + GetNameOfEnumerationValue(TargetTrend);
	
	MatrixOfStates = TargetValueMonitoringCached.GetStateMatrix();
	SectionNameOfStatePicture = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "NameOfStatusImage");
	SectionText_ = SectionNameOfStatePicture.CurrentArea.Parameter;
	
	If SectionText_ = "IconTargetAchieved" Then
		IndexOfIndicatorStatus = 3;
	ElsIf SectionText_ = "IconAcceptableValue" Then
		IndexOfIndicatorStatus = 2;
	ElsIf SectionText_ = "IconStatusIsNotDefined" Then
		IndexOfIndicatorStatus = 1;
	ElsIf SectionText_ = "IconUnacceptableValue" Then
		IndexOfIndicatorStatus = 0;
	EndIf;
	
	Return IndexOfIndicatorStatus;
	
EndFunction

// Returns the index of the image characterizing the trend (nature of changes) of the indicator for the list.
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option.
//
// Returns:
//	Number - index of the image in the collection.
//
Function GetTrendImageIndexForMetric(AnalysisOption, DataSource) Export
	
	Var IndicatorTrendPictureIndex;
	
	IndicatorTrendPictureIndex = Undefined;
	
	TypeOfTarget = GetTargetValueView(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
		AnalysisOption);
	TargetTrend = Common.ObjectAttributeValue(AnalysisOption, "Owner.TargetTrend");
	AnalysisArea = ValueAnalysisZone(DataSource, TargetTrend, TypeOfTarget,
		Common.ObjectAttributeValue(AnalysisOption, "FractionalPartCalculationAccuracy"));
	
	NameOfRegionOfStateMatrix =  "Unstable" + "_" + AnalysisArea.TheActualTrend + "_" + "Zone_"
		+ AnalysisArea.ZoneNumber + "_" + GetNameOfEnumerationValue(TargetTrend);
	
	MatrixOfStates = TargetValueMonitoringCached.GetStateMatrix();
	TrendImageNameSection = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "TrendImageName");
	SectionText_ = TrendImageNameSection.CurrentArea.Parameter;
	
	If SectionText_ = "TrendIconWithoutChanges" Then
		IndicatorTrendPictureIndex = 6;
	ElsIf SectionText_ = "TrendIconDeclineInARange" Then
		IndicatorTrendPictureIndex = 5;
	ElsIf SectionText_ = "TrendIconDeclineIsGettingWorse" Then
		IndicatorTrendPictureIndex = 4;
	ElsIf SectionText_ = "TrendIconDeclineIsImproving" Then
		IndicatorTrendPictureIndex = 3;
	ElsIf SectionText_ = "TrendIconGrowthInARange" Then
		IndicatorTrendPictureIndex = 2;
	ElsIf SectionText_ = "TrendIconGrowthIsGettingWorse" Then
		IndicatorTrendPictureIndex = 1;
	ElsIf SectionText_ = "TrendIconGrowthIsImproving" Then
		IndicatorTrendPictureIndex = 0;
	ElsIf SectionText_ = "PictureOfTrendUndefined" Then
		IndicatorTrendPictureIndex = 7;
	EndIf;
	
	Return IndicatorTrendPictureIndex;
	
EndFunction

// returns an image that describes the State (Status) of the indicator
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option
//	DataSource 	- Value tables with data for the chart.
//
// Returns:
//	Picture		- a picture from the picture library.
//
Function GetStatePictureForMetric(AnalysisOption, DataSource) Export
	
	Var IndicatorStatusImage;
	
	IndicatorStatusImage = New Picture;
	
	TypeOfTarget = GetTargetValueView(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
		AnalysisOption);
	TargetTrend = Common.ObjectAttributeValue(AnalysisOption, "Owner.TargetTrend");
	AnalysisArea = ValueAnalysisZone(DataSource, TargetTrend, TypeOfTarget,
		Common.ObjectAttributeValue(AnalysisOption, "FractionalPartCalculationAccuracy"));
	
	NameOfRegionOfStateMatrix =  "Unstable" + "_" + AnalysisArea.TheActualTrend + "_" + "Zone_"
		+ AnalysisArea.ZoneNumber + "_" + GetNameOfEnumerationValue(TargetTrend);
	
	MatrixOfStates = TargetValueMonitoringCached.GetStateMatrix();
	SectionNameOfStatePicture = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "NameOfStatusImage");
	NameOfStatePicture = SectionNameOfStatePicture.CurrentArea.Parameter;
	
	IndicatorStatusImage = PictureLib[NameOfStatePicture];
	
	Return IndicatorStatusImage;
	
EndFunction

// Returns an image characterizing the trend (nature of changes) of the indicator
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option.
//
// Returns:
//	Number - index of the image from the library.
//
Function GetTrendImageForMetric(AnalysisOption, DataSource) Export
	
	Var IndicatorTrendPicture;
	
	IndicatorTrendPicture = New Picture;
	
	TypeOfTarget = GetTargetValueView(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
		AnalysisOption);
	TargetTrend = Common.ObjectAttributeValue(AnalysisOption, "Owner.TargetTrend");
	AnalysisArea = ValueAnalysisZone(DataSource, TargetTrend, TypeOfTarget,
		Common.ObjectAttributeValue(AnalysisOption, "FractionalPartCalculationAccuracy"));
	
	NameOfRegionOfStateMatrix =  "Unstable" + "_" + AnalysisArea.TheActualTrend + "_" + "Zone_"
		+ AnalysisArea.ZoneNumber + "_" + GetNameOfEnumerationValue(TargetTrend);
	
	MatrixOfStates = TargetValueMonitoringCached.GetStateMatrix();
	TrendImageNameSection = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "TrendImageName");
	TrendImageName = TrendImageNameSection.CurrentArea.Parameter;
	
	IndicatorTrendPicture = PictureLib[TrendImageName];
	
	Return IndicatorTrendPicture;
	
EndFunction

// A utility function is designed to obtain a description of the types of line
// 
// Parameters:
//  StringLength - Number - the number of characters in a string.
//
// Returns:
//	TypeDescription - description of the string type of the specified length.
//
Function GetDescriptionOfStringTypes(StringLength) Export
	Array = New Array; 
	Array.Add(Type("String"));
	StringQualifier = New StringQualifiers(StringLength, AllowedLength.Variable);
	Return New TypeDescription(Array, , StringQualifier);
EndFunction

// A utility function used to get descriptions of Boolean types.
//
// Returns:
//	TypeDescription - description of the Boolean type.
//
Function GetDescriptionOfBooleanTypes() Export
	
	Array = New Array;
	Array.Add(Type("Boolean"));
	Return New TypeDescription(Array);
	
EndFunction // Get a description of the types left() 

// Returns a structure containing all the properties of the analysis variant
//
// Parameters:
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option.
//
// Returns:
//  Structure - the structure of the details and related data of the analysis option.
//
Function GetPropertiesOfAnalysisVariant(AnalysisOption, DataSource) Export
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	
	// Initializing variables
	PropertiesOfAnalysisVariant = New Structure;
	PropertiesOfAnalysisVariant.Insert("Target");
	PropertiesOfAnalysisVariant.Insert("TargetCategory");
	PropertiesOfAnalysisVariant.Insert("TargetValue");
	PropertiesOfAnalysisVariant.Insert("ShortNameOfTargetValue");
	PropertiesOfAnalysisVariant.Insert("LongDesc");
	PropertiesOfAnalysisVariant.Insert("CalculationFormula");
	PropertiesOfAnalysisVariant.Insert("Dimensions");
	PropertiesOfAnalysisVariant.Insert("AnalysisOption");
	PropertiesOfAnalysisVariant.Insert("EmployeeResponsible");
	PropertiesOfAnalysisVariant.Insert("TargetTrend");
	PropertiesOfAnalysisVariant.Insert("TargetValuesRanges");
	PropertiesOfAnalysisVariant.Insert("TheActualTrend");
	PropertiesOfAnalysisVariant.Insert("ActualValue");
	PropertiesOfAnalysisVariant.Insert("ActualState");
	PropertiesOfAnalysisVariant.Insert("AnalysisPeriod");
	PropertiesOfAnalysisVariant.Insert("ComparisonPeriod");
	PropertiesOfAnalysisVariant.Insert("AnalysisType");
	PropertiesOfAnalysisVariant.Insert("IndicatorCalculationFrequency");
	PropertiesOfAnalysisVariant.Insert("AnalysisObject");
	PropertiesOfAnalysisVariant.Insert("AnalysisValue");
	PropertiesOfAnalysisVariant.Insert("ValueMultiplier");
	PropertiesOfAnalysisVariant.Insert("FractionalPartCalculationAccuracy");
	PropertiesOfAnalysisVariant.Insert("ValueCalculationMethod");
	PropertiesOfAnalysisVariant.Insert("CustomFilters");
	PropertiesOfAnalysisVariant.Insert("DateAndTimeOfFormation");
	PropertiesOfAnalysisVariant.Insert("User");
	PropertiesOfAnalysisVariant.Insert("CalculationMethod_2");
	PropertiesOfAnalysisVariant.Insert("Adequacy");
	
	KindsOfVariancesFromTargetValues = Enums.KindsOfVariancesFromTargetValues;
	TargetValueKindsOfAnalysisOptions = Enums.TargetValueKindsOfAnalysisOptions;
	
	// We get the properties of the analysis option and the goal
	RequestingPropertiesForAnalysisOption = New Query;
	RequestingPropertiesForAnalysisOption.SetParameter("AnalysisOption", AnalysisOption);
	RequestingPropertiesForAnalysisOption.Text =
	"SELECT
		|	AnalysisOptionsOfTargetValues.Owner.Ref AS Target,
		|	AnalysisOptionsOfTargetValues.Owner.TargetCategory AS TargetCategory,
		|	AnalysisOptionsOfTargetValues.Owner.TargetValue AS TargetValue,
		|	AnalysisOptionsOfTargetValues.Owner.ShortNameOfTargetValue AS ShortNameOfTargetValue,
		|	AnalysisOptionsOfTargetValues.Owner.LongDesc AS LongDesc,
		|	AnalysisOptionsOfTargetValues.Owner.CalculationFormula AS CalculationFormula,
		|	AnalysisOptionsOfTargetValues.Owner.TargetTrend AS TargetTrend,
		|	AnalysisOptionsOfTargetValues.AnalysisPeriod,
		|	AnalysisOptionsOfTargetValues.ComparisonPeriod,
		|	AnalysisOptionsOfTargetValues.AnalysisType,
		|	AnalysisOptionsOfTargetValues.IndicatorCalculationFrequency,
		|	AnalysisOptionsOfTargetValues.AnalysisObject,
		|	AnalysisOptionsOfTargetValues.AnalysisValue,
		|	AnalysisOptionsOfTargetValues.ValueCalculationMethod,
		|	AnalysisOptionsOfTargetValues.StorageOfDataCompositionUserSettings,
		|	AnalysisOptionsOfTargetValues.EmployeeResponsible,
		|	AnalysisOptionsOfTargetValues.FractionalPartCalculationAccuracy,
		|	AnalysisOptionsOfTargetValues.ValueMultiplier,
		|	AnalysisOptionsOfTargetValues.Ref AS AnalysisOption
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
		|WHERE
		|	AnalysisOptionsOfTargetValues.Ref = &AnalysisOption";
	
	ResultOfRequestForPropertiesOfAnalysisVariant = RequestingPropertiesForAnalysisOption.Execute();
	
	If Not ResultOfRequestForPropertiesOfAnalysisVariant.IsEmpty() Then
		SelectionOfPropertiesOfAnalysisVariant = ResultOfRequestForPropertiesOfAnalysisVariant.Select();
		SelectionOfPropertiesOfAnalysisVariant.Next();
		
		FillPropertyValues(PropertiesOfAnalysisVariant, SelectionOfPropertiesOfAnalysisVariant);
		
		If PropertiesOfAnalysisVariant.EmployeeResponsible.IsEmpty() Then
			PropertiesOfAnalysisVariant.EmployeeResponsible = NStr("vi = 'Chưa xác định người chịu trách nhiệm';
																	|ru = 'Ответственный не определен';
																	|en = 'Responsible person is not determined'; fa = 'Responsible person is not determined';
																	|it = 'Responsabile non definito';
																	|pl = 'Odpowiedzialny nie jest określony';
																	|tr = 'Sorumlu kişi belirlenmedi'");
		EndIf;
		
		PropertiesOfAnalysisVariant.AnalysisPeriod = PresentationOfStandardPeriod(SelectionOfPropertiesOfAnalysisVariant.AnalysisPeriod.Get());
		
		ComparisonPeriod = SelectionOfPropertiesOfAnalysisVariant.ComparisonPeriod.Get();
		If Not ComparisonPeriod = Undefined And PropertiesOfAnalysisVariant.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
			PropertiesOfAnalysisVariant.ComparisonPeriod = PresentationOfStandardPeriod(SelectionOfPropertiesOfAnalysisVariant.ComparisonPeriod.Get());
		Else
			PropertiesOfAnalysisVariant.ComparisonPeriod = Undefined;
		EndIf;
		
		// Fill in the information on user settings
		UserSettings = SelectionOfPropertiesOfAnalysisVariant.StorageOfDataCompositionUserSettings.Get(); // DataCompositionUserSettings - 
		If Not UserSettings = Undefined Then
			CustomSettingsElements = UserSettings.Items;
			
			CustomFilters = "";
			For Each UserSetting In CustomSettingsElements Do
				If (TypeOf(UserSetting) = Type("DataCompositionFilterItem")
						Or TypeOf(UserSetting) = Type("DataCompositionSettingsParameterValue"))
						And UserSetting.Use Then
						
					CustomFilters = NStr("vi = 'Đã cài đặt bộ lọc tự tạo';
										|ru = 'Установлены пользовательские отборы';
										|en = 'Custom filters are set'; fa = 'Custom filters are set';
										|it = 'Selezioni personalizzate impostate';
										|pl = 'Są określone selekcje użytkownika';
										|tr = 'Kullanıcı filtreleri ayarlandı'");
					
					Break;
				EndIf;
			EndDo;
			
			If Not IsBlankString(CustomFilters) Then
				PropertiesOfAnalysisVariant.CustomFilters = CustomFilters;
			Else
				PropertiesOfAnalysisVariant.CustomFilters = Undefined;
			EndIf;
		Else
			PropertiesOfAnalysisVariant.CustomFilters = Undefined;
		EndIf;
		
		PropertiesOfAnalysisVariant.Dimensions = Chars.NBSp + String(DataSource.DynamicPropertiesOfAnalysisVariant.Dimensions);
		PropertiesOfAnalysisVariant.IndicatorCalculationFrequency = DataSource.DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency;
		PropertiesOfAnalysisVariant.AnalysisObject = DataSource.DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation;
		PropertiesOfAnalysisVariant.AnalysisValue = DataSource.DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation;
	EndIf;
	
	// Fill in the information about the actual condition
	PropertiesOfAnalysisVariant.TheActualTrend = DataSource.PropertiesOfAnalysisAndTrendZone.ExplanationOfTheTrend;
	PropertiesOfAnalysisVariant.ActualState = DataSource.PropertiesOfAnalysisAndTrendZone.ExplanationOfTheStatus;
	PropertiesOfAnalysisVariant.ActualValue = GetAbbreviatedPresentationOfNumber(DataSource.PropertiesOfDataByPeriod.LastValue, PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy, PropertiesOfAnalysisVariant.ValueMultiplier);
	
	// Fill in the information on the goals
	DimensionPresentation_ = "";
	If Not IsBlankString(DynamicPropertiesOfAnalysisVariant.Dimensions) And Not DynamicPropertiesOfAnalysisVariant.Dimensions = Undefined Then
		DimensionPresentation_ = Chars.NBSp + DynamicPropertiesOfAnalysisVariant.Dimensions;
	EndIf;
	
	If Not DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = Undefined And Not DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue.IsEmpty() Then
		If DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Absolute Then
			DimensionOfDeviation = Chars.NBSp + DynamicPropertiesOfAnalysisVariant.Dimensions;
		ElsIf DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Relative Then
			DimensionOfDeviation = "%";
		EndIf;
		
		If DataSource.PropertiesOfDataByPeriod.TargetValueKind = TargetValueKindsOfAnalysisOptions.Value Then
			If DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Absolute Then
			
				TargetValueTextTemplate = NStr("vi = '%1%2';
												|ru = '%1%2';
												|en = '%1%2'; fa = '%1%2';
												|it = '%1%2';
												|pl = '%1%2';
												|tr = '%1%2'");
				TargetValueTextTemplate = TargetValueTextTemplate + Chars.LF
					+ NStr("vi = 'với độ lệch dương là %3%4 và độ lệch âm là %5%6';
							|ru = 'с позитивным отклонением %3%4 и негативным отклонением %5%6';
							|en = 'with positive variance %3%4 and negative variance%5%6'; fa = 'with positive variance %3%4 and negative variance%5%6';
							|it = 'сon deviazione positiva %3%4 e con deviazione negativa %5%6';
							|pl = 'z pozytywnym odchyleniem %3%4 i negatywnym odchyleniem %5%6';
							|tr = 'pozitiv %3%4 ve negatif sapma %5%6 ile'");
				TargetValuePresentation = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.TargetValue_,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				PresentationOfPositiveRejection = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.PositiveBorderVariance,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				PresentationOfNegativeRejection = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.NegativeBorderVariance,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				
				PropertiesOfAnalysisVariant.TargetValuesRanges = StringFunctionsClientServer.SubstituteParametersToString(
					TargetValueTextTemplate,
					TargetValuePresentation,
					DimensionPresentation_,
					PresentationOfPositiveRejection,
					DimensionOfDeviation,
					PresentationOfNegativeRejection,
					DimensionOfDeviation);
				
			ElsIf DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Relative Then
				
				TargetValueTextTemplate = NStr("vi = '%1%2';
												|ru = '%1%2';
												|en = '%1%2'; fa = '%1%2';
												|it = '%1%2';
												|pl = '%1%2';
												|tr = '%1%2'");
				TargetValueTextTemplate = TargetValueTextTemplate + Chars.LF
					+ NStr("vi = 'với độ lệch dương là %3%4 và độ lệch âm là %5%6';
							|ru = 'с позитивным отклонением %3%4 и негативным отклонением %5%6';
							|en = 'with positive variance %3%4 and negative variance%5%6'; fa = 'with positive variance %3%4 and negative variance%5%6';
							|it = 'сon deviazione positiva %3%4 e con deviazione negativa %5%6';
							|pl = 'z pozytywnym odchyleniem %3%4 i negatywnym odchyleniem %5%6';
							|tr = 'pozitiv %3%4 ve negatif sapma %5%6 ile'");
				TargetValuePresentation = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.TargetValue_,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				
				PropertiesOfAnalysisVariant.TargetValuesRanges = StringFunctionsClientServer.SubstituteParametersToString(
					TargetValueTextTemplate,
					TargetValuePresentation,
					DimensionPresentation_,
					DataSource.PropertiesOfDataByPeriod.PositiveBorderVariance,
					DimensionOfDeviation,
					DataSource.PropertiesOfDataByPeriod.NegativeBorderVariance,
					DimensionOfDeviation);
				
			EndIf;
		Else 
			If DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Absolute Then
				TargetValueTextTemplate = NStr("vi = '%1 - %2%3';
												|ru = '%1 - %2%3';
												|en = '%1 - %2%3'; fa = '%1 - %2%3';
												|it = '%1 - %2%3';
												|pl = '%1 - %2%3';
												|tr = '%1 - %2%3'");
				TargetValueTextTemplate = TargetValueTextTemplate + Chars.LF
					+ NStr("vi = 'với độ lệch dương là %4%5 và độ lệch âm là %6%7';
							|ru = 'с позитивным отклонением %4%5 и негативным отклонением %6%7';
							|en = 'with positive variance %4%5 and negative variance %6%7'; fa = 'with positive variance %4%5 and negative variance %6%7';
							|it = 'сon deviazione positiva%4%5 e con deviazione negativa %6%7';
							|pl = 'z pozytywnym odchyleniem %4%5 i negatywnym odchyleniem %6%7';
							|tr = 'pozitiv %4%5 ve negatif sapma %6%7 ile'");
				PresentationRangeMinimum = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.MinimumTargetRange,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				PresentationRangeMaximum = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.MaximumTargetRange,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				PresentationOfPositiveRejection = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.PositiveBorderVariance,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				PresentationOfNegativeRejection = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.NegativeBorderVariance,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				
				PropertiesOfAnalysisVariant.TargetValuesRanges = StringFunctionsClientServer.SubstituteParametersToString(
					TargetValueTextTemplate,
					PresentationRangeMinimum,
					PresentationRangeMaximum,
					DimensionPresentation_,
					PresentationOfPositiveRejection,
					DimensionOfDeviation,
					PresentationOfNegativeRejection,
					DimensionOfDeviation);
				
			ElsIf DataSource.PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindsOfVariancesFromTargetValues.Relative Then
				
				TargetValueTextTemplate = NStr("vi = '%1 - %2%3';
												|ru = '%1 - %2%3';
												|en = '%1 - %2%3'; fa = '%1 - %2%3';
												|it = '%1 - %2%3';
												|pl = '%1 - %2%3';
												|tr = '%1 - %2%3'");
				TargetValueTextTemplate = TargetValueTextTemplate + Chars.LF
					+ NStr("vi = 'với độ lệch dương là %4%5 và độ lệch âm là %6%7';
							|ru = 'с позитивным отклонением %4%5 и негативным отклонением %6%7';
							|en = 'with positive variance %4%5 and negative variance %6%7'; fa = 'with positive variance %4%5 and negative variance %6%7';
							|it = 'сon deviazione positiva%4%5 e con deviazione negativa %6%7';
							|pl = 'z pozytywnym odchyleniem %4%5 i negatywnym odchyleniem %6%7';
							|tr = 'pozitiv %4%5 ve negatif sapma %6%7 ile'");
				PresentationRangeMinimum = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.MinimumTargetRange,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				PresentationRangeMaximum = GetAbbreviatedPresentationOfNumber(
					DataSource.PropertiesOfDataByPeriod.MaximumTargetRange,
					PropertiesOfAnalysisVariant.FractionalPartCalculationAccuracy,
					PropertiesOfAnalysisVariant.ValueMultiplier);
				
				PropertiesOfAnalysisVariant.TargetValuesRanges = StringFunctionsClientServer.SubstituteParametersToString(
					TargetValueTextTemplate,
					PresentationRangeMinimum,
					PresentationRangeMaximum,
					DimensionPresentation_,
					DataSource.PropertiesOfDataByPeriod.PositiveBorderVariance,
					DimensionOfDeviation,
					DataSource.PropertiesOfDataByPeriod.NegativeBorderVariance,
					DimensionOfDeviation);
				
			EndIf;
		EndIf;
		
	Else
		DimensionOfDeviation = "";
		PropertiesOfAnalysisVariant.TargetValuesRanges = NStr("vi = 'Chưa đặt mục tiêu';
																|ru = 'Цели не установлены';
																|en = 'Targets are not set'; fa = 'Targets are not set';
																|it = 'Obiettivi non impostati';
																|pl = 'Cele nie są określone';
																|tr = 'Hedefler ayarlanmadı'");
	EndIf;
	
	// Fill in the forecast information
	If Common.ObjectAttributeValue(AnalysisOption, "CalculateForecast") 
		And Not DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend = Undefined
		And Not DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.IsEmpty Then
		
		PropertiesOfAnalysisVariant.CalculationMethod_2	= DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.CalculationMethod_2;
		PropertiesOfAnalysisVariant.Adequacy	= String(Round(100 * DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.Adequacy, 2)) + " " + "%";
	EndIf;

	// Fill in the information about the generated and the date of relevance of the information.
	PropertiesOfAnalysisVariant.DateAndTimeOfFormation = CurrentSessionDate();
	PropertiesOfAnalysisVariant.User = Users.CurrentUser();
	
	Return PropertiesOfAnalysisVariant;
EndFunction

// Returns a representation of a number in the form of thousands, millions
// 
// Parameters:
//	OriginalNumber - Number - the number to be formatted
//	Digits - Number - number of decimal places
//	TypeOfNumberPresentation - EnumRef.NumberPresentationKinds - type of representation of the returned string.
//
// Returns:
//	String - string representation of a number in the form of <formatted number> <Dimension>.
//
Function GetAbbreviatedPresentationOfNumber(OriginalNumber, Digits, TypeOfNumberPresentation) Export 
	
	AbbreviatedPresentationOfNumber = "";
	AbbreviatedPresentationOfOrderOfNumbers = "";
	
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	
	If TypeOfNumberPresentation = NumberPresentationKinds.InThousands Then
		AbbreviatedPresentationOfOrderOfNumbers = NStr("vi = '%1 nghìn';
														|ru = '%1 тыс.';
														|en = '%1 thousand'; fa = '%1 thousand';
														|it = '%1 mila';
														|pl = '%1 tys.';
														|tr = '%1 bin.'");
	ElsIf TypeOfNumberPresentation = NumberPresentationKinds.InMillions Then
		AbbreviatedPresentationOfOrderOfNumbers = NStr("vi = '%1 triệu';
														|ru = '%1 млн.';
														|en = '%1 million'; fa = '%1 million';
														|it = '%1 mln';
														|pl = '%1 mln.';
														|tr = '%1 mln.'");
	Else
		AbbreviatedPresentationOfOrderOfNumbers = NStr("vi = '%1';
														|ru = '%1';
														|en = '%1'; fa = '%1';
														|it = '%1';
														|pl = '%1';
														|tr = '%1'");
	EndIf;
	
	NumberFormatString = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'NFD= %1;NZ=';
			|ru = 'ЧДЦ=%1;ЧН=';
			|en = 'NFD=%1; NZ='; fa = 'NFD=%1; NZ=';
			|it = 'END=%1;NZ=';
			|pl = 'CZDC=%1;CZN=';
			|tr = 'NFD=%1;NZ='"),
		Format(Digits, "NG=0;"));
	AbbreviatedPresentationOfNumber = StringFunctionsClientServer.SubstituteParametersToString(
		AbbreviatedPresentationOfOrderOfNumbers,
		Format(OriginalNumber, NumberFormatString));
	
	Return AbbreviatedPresentationOfNumber;
	
EndFunction

// Returns a string for the thousand, million types
// 
// Parameters:
//	AnalysisOption - Structure - Attributes of the analysis option.
//
// Returns:
//	String - representation of the dimension of a number (empty string, "thousand" or "million").
//
Function GetNumberPresentationString(AnalysisOption) Export
	
	AbbreviatedPresentationOfOrderOfNumbers = "";
	
	TypeOfNumberPresentation = AnalysisOption.ValueMultiplier;
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	
	If TypeOfNumberPresentation = NumberPresentationKinds.InThousands Then
		AbbreviatedPresentationOfOrderOfNumbers = NStr("vi = 'nghìn';
														|ru = 'тыс.';
														|en = 'thous.'; fa = 'thous.';
														|it = 'mill.';
														|pl = 'tys.';
														|tr = 'bin.'");
	ElsIf TypeOfNumberPresentation = NumberPresentationKinds.InMillions Then
		AbbreviatedPresentationOfOrderOfNumbers = NStr("vi = 'triệu';
														|ru = 'млн.';
														|en = 'million'; fa = 'million';
														|it = 'mln';
														|pl = 'mln.';
														|tr = 'mln.'");
	EndIf;
	
	Return AbbreviatedPresentationOfOrderOfNumbers;
	
EndFunction

// Returns the number of data sources broken down by attention zones and display options.
//
// Parameters:
//	SetOfDataSources - ValueTable - the analyzed set
//	ConsiderDisplayOptions - Boolean
//
// Returns:
//	Structure - contains the number of data sources.
//
Function StatisticsOfDataSourcesByAreasOfAttention(SetOfDataSources, ConsiderDisplayOptions = False) Export
	
	DisplayOptionsOfAnalysisOptions = Enums.DisplayOptionsOfAnalysisOptions;
	AreasOfAttention = Enums.InterestAreasOfAnalysisOptions;
	
	If ConsiderDisplayOptions Then
		StatisticsByLine = New Structure;
		StatisticsByLine.Insert("CriticalStateBriefly");
		StatisticsByLine.Insert("CriticalStateDetail");
		StatisticsByLine.Insert("ImportantBriefly");
		StatisticsByLine.Insert("ImportantDetails");
		StatisticsByLine.Insert("NoteBriefly");
		StatisticsByLine.Insert("NoteInDetail");
		StatisticsByLine.Insert("CalculatedWithErrors_Briefly");
		StatisticsByLine.Insert("CalculatedWithErrorsInDetail");
		
		// Let's select a critical condition
		Filter = New Structure("AreaOfInterest, ViewOption", AreasOfAttention.CriticalState, DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.CriticalStateBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		SelectionOfAllShort = New Structure("ViewOption", DisplayOptionsOfAnalysisOptions.Brief1);
		SetOfDataSourcesWithoutConcise = ApplyConditionNotToTable(SetOfDataSources, SelectionOfAllShort);
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.CriticalState);
		StatisticsByLine.CriticalStateDetail = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let 's select the important ones
		Filter = New Structure("AreaOfInterest, ViewOption", AreasOfAttention.Critical, DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.ImportantBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.Critical);
		StatisticsByLine.ImportantDetails = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let's take the indicators into consideration
		Filter = New Structure("AreaOfInterest, ViewOption", AreasOfAttention.ForInformation, DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.NoteBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.ForInformation);
		StatisticsByLine.NoteInDetail = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let's select the indicators calculated with errors
		Filter = New Structure("AreaOfInterest, ViewOption", AreasOfAttention.CalculatedWithErrors, DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.CalculatedWithErrors_Briefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.CalculatedWithErrors);
		StatisticsByLine.CalculatedWithErrorsInDetail = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
	Else
		StatisticsByLine = New Structure;
		StatisticsByLine.Insert("CriticalState");
		StatisticsByLine.Insert("Critical");
		StatisticsByLine.Insert("ForInformation");
		StatisticsByLine.Insert("CalculatedWithErrors");
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.CriticalState);
		StatisticsByLine.CriticalState = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.Critical);
		StatisticsByLine.Critical = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.ForInformation);
		StatisticsByLine.ForInformation = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("AreaOfInterest", AreasOfAttention.CalculatedWithErrors);
		StatisticsByLine.CalculatedWithErrors = SetOfDataSources.FindRows(Filter).Count();
		
	EndIf;
	
	Return StatisticsByLine;
	
EndFunction

// Returns the number of data sources broken down by state and display options.
//
// Parameters:
//	SetOfDataSources - ValueTable - the analyzed set
//	ConsiderDisplayOptions - Boolean
//
// Returns:
//	Structure - contains the number of data sources.
//
Function StatisticsOfDataSourcesByState(SetOfDataSources, ConsiderDisplayOptions = False) Export
	
	DisplayOptionsOfAnalysisOptions = Enums.DisplayOptionsOfAnalysisOptions;
	
	If ConsiderDisplayOptions Then
		StatisticsByLine = New Structure;
		StatisticsByLine.Insert("UnacceptableState_");
		StatisticsByLine.Insert("UnacceptableStateOfMind");
		StatisticsByLine.Insert("AcceptableStateBriefly");
		StatisticsByLine.Insert("AcceptableStateOfDetail");
		StatisticsByLine.Insert("GoalIsAchievedBriefly");
		StatisticsByLine.Insert("GoalAchievedInDetail");
		StatisticsByLine.Insert("StateIsNotDefinedBriefly");
		StatisticsByLine.Insert("StateNotDefinedInDetail");
		StatisticsByLine.Insert("CalculatedWithErrorsBriefly");
		StatisticsByLine.Insert("CalculatedWithErrorsDetails");
		
		// Let's select unacceptable values
		Filter = New Structure("Status, ViewOption", "UnacceptableState", DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.UnacceptableState_ = SetOfDataSources.FindRows(Filter).Count();
		
		SelectionOfAllShort = New Structure("ViewOption", DisplayOptionsOfAnalysisOptions.Brief1);
		SetOfDataSourcesWithoutConcise = ApplyConditionNotToTable(SetOfDataSources, SelectionOfAllShort);
		
		Filter = New Structure("Status", "UnacceptableState");
		StatisticsByLine.UnacceptableStateOfMind = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let's select acceptable values
		Filter = New Structure("Status, ViewOption", "AcceptableState", DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.AcceptableStateBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "AcceptableState");
		StatisticsByLine.AcceptableStateOfDetail = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let's select the indicators that have reached the goal
		Filter = New Structure("Status, ViewOption", "TheGoalIsAchieved", DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.GoalIsAchievedBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "TheGoalIsAchieved");
		StatisticsByLine.GoalAchievedInDetail = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let's select the indicators for which the state is not defined
		Filter = New Structure("Status, ViewOption", "StateIsNotDefined", DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.StateIsNotDefinedBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "StateIsNotDefined");
		StatisticsByLine.StateNotDefinedInDetail = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
		// Let's select the indicators calculated with errors
		Filter = New Structure("Status, ViewOption", "CalculatedWithErrors", DisplayOptionsOfAnalysisOptions.Brief1);
		StatisticsByLine.CalculatedWithErrorsBriefly = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "CalculatedWithErrors");
		StatisticsByLine.CalculatedWithErrorsDetails = SetOfDataSourcesWithoutConcise.FindRows(Filter).Count();
		
	Else
		StatisticsByLine = New Structure;
		StatisticsByLine.Insert("UnacceptableState");
		StatisticsByLine.Insert("AcceptableState");
		StatisticsByLine.Insert("TheGoalIsAchieved");
		StatisticsByLine.Insert("StateIsNotDefined");
		StatisticsByLine.Insert("CalculatedWithErrors");
		
		Filter = New Structure("Status", "UnacceptableState");
		StatisticsByLine.UnacceptableState = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "AcceptableState");
		StatisticsByLine.AcceptableState = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "TheGoalIsAchieved");
		StatisticsByLine.TheGoalIsAchieved = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "StateIsNotDefined");
		StatisticsByLine.StateIsNotDefined = SetOfDataSources.FindRows(Filter).Count();
		
		Filter = New Structure("Status", "CalculatedWithErrors");
		StatisticsByLine.CalculatedWithErrors = SetOfDataSources.FindRows(Filter).Count();
		
	EndIf;
	
	Return StatisticsByLine;
	
EndFunction

// Returns properties of analysis types - available chart types, 
// availability of the analysis object, and whether the analysis type needs formatting.
// 
// Returns:
// 	ValueTable - LongDesc:
// * AnalysisType - EnumRef.IndicatorAnalysisTypes -
// * ChartType - EnumRef.ChartTypesOfIndicators -
// * TheDesignOfAComponentByComponentComparisonIsAvailable - Boolean - 
// * AnalysisObjectIsAvailable - Boolean - 
// * ComparisonPeriodIsAvailable - Boolean - 
// * ForecastingIsAvailable - Boolean - 
// * DisplayPointMarkersAvailable - Boolean - 
// * DisplayAMarkerOfForecastPointsAvailable - Boolean - 
// * DisplayChartCaptionsAvailable - Boolean - 
// * ChartBorderIsAvailable - Boolean - 
// * ChartSmoothingModeAvailable - Boolean - 
Function TypesOfAnalysisAndDiagrams() Export
	
	BooleanTypeDetails = New TypeDescription("Boolean");
	
	MapsTable = New ValueTable;
	MapsTable.Columns.Add("AnalysisType", New TypeDescription("EnumRef.IndicatorAnalysisTypes"));
	MapsTable.Columns.Add("ChartType", New TypeDescription("EnumRef.ChartTypesOfIndicators"));
	MapsTable.Columns.Add("TheDesignOfAComponentByComponentComparisonIsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("AnalysisObjectIsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("ComparisonPeriodIsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("ForecastingIsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("DisplayPointMarkersAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("DisplayAMarkerOfForecastPointsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("DisplayChartCaptionsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("ChartBorderIsAvailable", BooleanTypeDetails);
	MapsTable.Columns.Add("ChartSmoothingModeAvailable", BooleanTypeDetails);
	
	TypesOfComparisons = Enums.IndicatorAnalysisTypes;
	ChartTypes = Enums.ChartTypesOfIndicators;
	
	// Empty Analysis type
	NewComparison = MapsTable.Add();
	
	// Dynamics of changes
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ChangeTrends;
	NewComparison.ChartType = ChartTypes.Line;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = True;
	NewComparison.DisplayPointMarkersAvailable = True;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = True;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = False;
	NewComparison.ChartSmoothingModeAvailable = True;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ChangeTrends;
	NewComparison.ChartType = ChartTypes.Step;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = True;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = False;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ChangeTrends;
	NewComparison.ChartType = ChartTypes.Column;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = True;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = True;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ChangeTrends;
	NewComparison.ChartType = ChartTypes.Column3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = True;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = True;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	// Component-by-component comparison (dynamics)
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.Line;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = True;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = False;
	NewComparison.ChartSmoothingModeAvailable = True;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.StackedLine;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = True;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = True;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.Area;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = True;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.StackedArea;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = True;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.NormalizedArea;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = True;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.Step;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = False;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.Column;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.Column3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.NormalizedColumn;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.NormalizedColumn3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;

	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.StackedColumn;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonTrends;
	NewComparison.ChartType = ChartTypes.StackedColumn3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	// Component-by-component comparison (structure)
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.Column;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.Column3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.NormalizedColumn;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.NormalizedColumn3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;

	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.StackedColumn;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.StackedColumn3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.Bar;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.Bar3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.NormalizedBar;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.NormalizedBar3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.StackedBar;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.StackedBar3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComponentWiseComparisonStructure;
	NewComparison.ChartType = ChartTypes.Pie;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = True;
	NewComparison.AnalysisObjectIsAvailable = True;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	// Current state
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.MeasureCurrentValue;
	NewComparison.ChartType = ChartTypes.Gauge;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = False;
	NewComparison.ForecastingIsAvailable = False;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = False;
	NewComparison.ChartBorderIsAvailable = False;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	// Comparison with the previous period
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComparisonWithPreviousPeriod;
	NewComparison.ChartType = ChartTypes.Column;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = True;
	NewComparison.ForecastingIsAvailable = True;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	NewComparison = MapsTable.Add();
	NewComparison.AnalysisType = TypesOfComparisons.ComparisonWithPreviousPeriod;
	NewComparison.ChartType = ChartTypes.Column3D;
	NewComparison.TheDesignOfAComponentByComponentComparisonIsAvailable = False;
	NewComparison.AnalysisObjectIsAvailable = False;
	NewComparison.ComparisonPeriodIsAvailable = True;
	NewComparison.ForecastingIsAvailable = True;
	NewComparison.DisplayPointMarkersAvailable = False;
	NewComparison.DisplayAMarkerOfForecastPointsAvailable = False;
	NewComparison.DisplayChartCaptionsAvailable = True;
	NewComparison.ChartBorderIsAvailable = True;
	NewComparison.ChartSmoothingModeAvailable = False;
	
	Return MapsTable;
	
EndFunction

// Returns colors that characterize the status and trend of the indicator.
//
// Parameters:
//	AnalysisOption - Structure - Attributes of the analysis option.
//	DataSource - See GetDataSourceOfAnalysisVariantFromDemoData
//
// Returns:
//	Structure - with properties:
//		*StateColor - Color - status color.
//		*TrendColor - Color - color of the trend.
//
Function GetStateAndTrendIndicatorColors(AnalysisOption, DataSource) Export
	StateAndTrendColors = New Structure("StateColor, TrendColor");
	
	TargetTrend = Common.ObjectAttributeValue(AnalysisOption.Owner, "TargetTrend");
	DesignSettings = AnalysisOption.DecorationSettingStorage.Get();
	
	StateColor = New Color;
	
	TargetValueKind = GetTargetValueView(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
			AnalysisOption);
	AnalysisArea = ValueAnalysisZone(DataSource,
			TargetTrend,
			TargetValueKind,
			AnalysisOption.FractionalPartCalculationAccuracy);
	
	NameOfRegionOfStateMatrix =  "Unstable" + "_" + AnalysisArea.TheActualTrend + "_" + "Zone_"
		+ AnalysisArea.ZoneNumber + "_" + GetNameOfEnumerationValue(TargetTrend);
	
	MatrixOfStates = TargetValueMonitoringCached.GetStateMatrix();
	
	// Get the color of the state
	StateColorSection = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "TheColorValueStatus");
	
	ColorName = StateColorSection.CurrentArea.Parameter;
	If ColorName <> "Undefined" Then
		StateColor = DesignSettings.Colors[ColorName];
	Else
		StateColor = New Color(65, 48, 3);
	EndIf;
	StateAndTrendColors.StateColor = StateColor;
	
	// Get the color of the trend
	TrendColorSection = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "TheColorValueTrend");
	
	ColorName = TrendColorSection.CurrentArea.Parameter;
	If ColorName <> "Undefined" Then
		TrendColor = DesignSettings.Colors[ColorName];
	Else
		TrendColor = New Color(65, 48, 3);
	EndIf;
	StateAndTrendColors.TrendColor = TrendColor;
	
	Return StateAndTrendColors;
EndFunction

// Returns a table of values with the selection applied to it
//
// Parameters:
//	ValueTable - ValueTable - table being processed
//	FiltersStructure - Structure - applied selections.
//
// Returns:
//	ValueTable - the processed table.
//
Function ApplyConditionToTable(ValueTable, FiltersStructure) Export
	
	TableOfValuesForProcessing = ValueTable.Copy();
	
	LinesToDelete = FindTableRowsByConditionNot(TableOfValuesForProcessing, FiltersStructure);
	
	For Each RowToDelete In LinesToDelete Do 
		TableOfValuesForProcessing.Delete(RowToDelete);
		
	EndDo;
	
	Return TableOfValuesForProcessing;
	
EndFunction

// Returns a table of values with the selection applied to it by the condition NOT
//
// Parameters:
//	ValueTable - ValueTable - table being processed
//	FiltersStructure - Structure - applied selections.
//
// Returns:
//	ValueTable - the processed table.
//
Function ApplyConditionNotToTable(ValueTable, FiltersStructure) Export
	
	TableOfValuesForProcessing = ValueTable.Copy();
	
	LinesToDelete = TableOfValuesForProcessing.FindRows(FiltersStructure);
	
	For Each RowToDelete In LinesToDelete Do 
		TableOfValuesForProcessing.Delete(RowToDelete);
	EndDo;
	
	Return TableOfValuesForProcessing;
	
EndFunction

// Returns the result of checking the target indicator calculation template
//
// Parameters:
//	DCSTemplate_ - DataCompositionSchema - the calculation template to check.
//
// Returns:
//	Structure - contains a sign of the correctness of the template and a description of the error
//			Layout Correct - Boolean
//			Error description - Array - errors detected.
//
Function CheckDataLayoutScheme(DCSTemplate_) Export
	
	CheckResult = New Structure("CorrectTemplate, ErrorsDescription", True, Undefined);
	
	ErrorsArray = New Array;
	
	// Let's check the fullness of the layout
	If DCSTemplate_ = Undefined Then
		
		ErrorsArray.Add(NStr("vi = 'Mẫu tính toán chỉ số mục tiêu trống.';
							|ru = 'Шаблон расчета целевого показателя не заполнен.';
							|en = 'Target value calculation template is blank.'; fa = 'Target value calculation template is blank.';
							|it = 'Il modello del calcolo dell''indicatore mirato non è compilato.';
							|pl = 'Szablon obliczenia wskaźnika celowego nie jest wypełniony.';
							|tr = 'Hedef değer hesaplama numunesi doldurulmadı.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
	
	// Let's check the availability of the required data sets
	
	If DCSTemplate_.DataSets.Find("PeriodsTable") = Undefined Then
		
		ErrorText = StrTemplate(NStr("vi = 'Khuôn mẫu tính toán chỉ tiêu đích không được chứa tập hợp dữ liệu bắt buộc ""%1"".
			|Cần tùy chỉnh khuôn mẫu tính chỉ tiêu đích theo yêu cầu.';
			|ru = 'Шаблон расчета целевого показателя не содержит обязательного набора данных ""%1"". 
			|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
			|en = 'Target value calculation template must contain a required data set ""%1"".
			|Modify the target value calculation template accordingly.'; fa = 'Target value calculation template must contain a required data set ""%1"".
			|Modify the target value calculation template accordingly.';
			|it = 'Il modello di calcolo dell''indicatore mirato non contiene il set obbligatorio dei dati ""%1"". 
			|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
			|pl = 'Szablon obliczenia wskaźnika celowego nie zawiera obowiązkowego zestawu danych ""%1"". 
			|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
			|tr = 'Hedef değer hesaplama numunesi gerekli ''%1'' veri kümesini içermiyor. 
			|Hedef değer hesaplama numunesini talebe uygun ayarlamak gerekir.'"),
			"PeriodsTable");
		ErrorsArray.Add(ErrorText);
		CheckResult.CorrectTemplate = False;
		
	EndIf;
	
	If DCSTemplate_.DataSets.Find("TargetValuesRanges") = Undefined Then
		
		ErrorText = StrTemplate(NStr("vi = 'Khuôn mẫu tính toán chỉ tiêu đích không được chứa tập hợp dữ liệu bắt buộc ""%1"".
			|Cần tùy chỉnh khuôn mẫu tính chỉ tiêu đích theo yêu cầu.';
			|ru = 'Шаблон расчета целевого показателя не содержит обязательного набора данных ""%1"". 
			|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
			|en = 'Target value calculation template must contain a required data set ""%1"".
			|Modify the target value calculation template accordingly.'; fa = 'Target value calculation template must contain a required data set ""%1"".
			|Modify the target value calculation template accordingly.';
			|it = 'Il modello di calcolo dell''indicatore mirato non contiene il set obbligatorio dei dati ""%1"". 
			|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
			|pl = 'Szablon obliczenia wskaźnika celowego nie zawiera obowiązkowego zestawu danych ""%1"". 
			|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
			|tr = 'Hedef değer hesaplama numunesi gerekli ''%1'' veri kümesini içermiyor. 
			|Hedef değer hesaplama numunesini talebe uygun ayarlamak gerekir.'"),
			"TargetValuesRanges");
		ErrorsArray.Add(ErrorText);
		CheckResult.CorrectTemplate = False;
		
	EndIf;
	
	If DCSTemplate_.DataSets.Find("DataForAnalysis") = Undefined Then
		
		ErrorText = StrTemplate(NStr("vi = 'Khuôn mẫu tính toán chỉ tiêu đích không được chứa tập hợp dữ liệu bắt buộc ""%1"".
			|Cần tùy chỉnh khuôn mẫu tính chỉ tiêu đích theo yêu cầu.';
			|ru = 'Шаблон расчета целевого показателя не содержит обязательного набора данных ""%1"". 
			|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
			|en = 'Target value calculation template must contain a required data set ""%1"".
			|Modify the target value calculation template accordingly.'; fa = 'Target value calculation template must contain a required data set ""%1"".
			|Modify the target value calculation template accordingly.';
			|it = 'Il modello di calcolo dell''indicatore mirato non contiene il set obbligatorio dei dati ""%1"". 
			|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
			|pl = 'Szablon obliczenia wskaźnika celowego nie zawiera obowiązkowego zestawu danych ""%1"". 
			|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
			|tr = 'Hedef değer hesaplama numunesi gerekli ''%1'' veri kümesini içermiyor. 
			|Hedef değer hesaplama numunesini talebe uygun ayarlamak gerekir.'"),
			"DataForAnalysis");
		ErrorsArray.Add(ErrorText);
		CheckResult.CorrectTemplate = False;
		
	EndIf;
	
	// Let's check the correctness of data set connections
	
	TableOfPeriodsIs = False;
	TargetValuesAre = False;
	ThereIsDataForAnalysis = False;
	If DCSTemplate_.DataSetLinks.Count() = 2 Then
		
		For Each LinkingDatasets In DCSTemplate_.DataSetLinks Do 
			
			If StrFind(LinkingDatasets.SourceExpression, "PeriodsTable")
				And StrFind(LinkingDatasets.DestinationExpression, "TargetValuesRanges") Then
				
					TableOfPeriodsIs = True;
					TargetValuesAre = True;
				
			ElsIf StrFind(LinkingDatasets.SourceExpression, "PeriodsTable")
				And StrFind(LinkingDatasets.DestinationExpression, "TargetValuesRanges") Then
				
					TableOfPeriodsIs = True;
					ThereIsDataForAnalysis = True;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If TableOfPeriodsIs And Not TargetValuesAre Or DCSTemplate_.DataSetLinks.Count() < 2 Then
		
		ErrorsArray.Add(NStr("vi = 'Khuôn mẫu tính chỉ tiêu chính không chứa liên kết giữa bảng kỳ và giá trị chỉ tiêu.
										|Cần tùy chỉnh khuôn mẫu tính chỉ tiêu chính theo yêu cầu.';
										|ru = 'Шаблон расчета целевого показателя не содержит связи между таблицей периодов и целевых значений. 
										|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
										|en = 'Target value calculation template does not contain any link between the period table and the target value table.
										|Configure the target indicator calculation template in accordance with the requirements.'; fa = 'Target value calculation template does not contain any link between the period table and the target value table.
										|Configure the target indicator calculation template in accordance with the requirements.';
										|it = 'Il modello di calcolo dell''indicatore mirato non contiene un collegamento tra la tabella dei periodi e dei valori mirati. 
										|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
										|pl = 'Szablon obliczenia wskaźnika celowego nie zawiera połączenia między tabelą okresów a wartościami celowymi. 
										|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
										|tr = 'Hedef değer hesaplama numunesi gerekli veri kümesini içermiyor. 
										|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
	
	If TableOfPeriodsIs And Not ThereIsDataForAnalysis Or DCSTemplate_.DataSetLinks.Count() < 2 Then
		
		ErrorsArray.Add(NStr("vi = 'Khuôn mẫu tính toán mục tiêu của không chứa liên kết giữa bảng các kỳ và dữ liệu để phân tích. 
										|Cần tùy chỉnh khuôn mẫu tính toán mục tiêu của chỉ tiêu tương ứng với yêu cầu.';
										|ru = 'Шаблон расчета целевого показателя не содержит связи между таблицей периодов и данными для анализа. 
										|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
										|en = 'Target value calculation template does not contain any link between the period table and the data for analysis.
										|Configure the target value calculation template in accordance with the requirements.'; fa = 'Target value calculation template does not contain any link between the period table and the data for analysis.
										|Configure the target value calculation template in accordance with the requirements.';
										|it = 'Il modello di calcolo dell''indicatore mirato non contiene un collegamento tra la tabella dei periodi e dei valori mirati. 
										|È necessario impostare il modello di calcolo dell''indicatore mirato dell''indicatore mirato in base alle richieste.';
										|pl = 'Szablon obliczenia wskaźnika celowego nie zawiera połączenia między tabelą okresów a danymi dla analizy. 
										|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
										|tr = 'Hedef değer hesaplama numunesi, dönem tablosu ile analiz verileri arasında bir bağlantı içermez. 
										|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
		
	// Let's check that the settings option is the same
	If DCSTemplate_.SettingVariants.Count() <> 1 Then
		
		ErrorsArray.Add(NStr("vi = 'Khuôn mẫu tính toán chỉ số phải có một phương án tùy chỉnh. 
										|Cần tùy chỉnh khuôn mẫu tính toán chỉ số đích theo yêu cầu.';
										|ru = 'Шаблон расчета целевого показателя должен содержать один вариант настроек. 
										|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
										|en = 'Target value calculation template must contain one settings option. 
										|Configure the target value calculation template in accordance with the requirements.'; fa = 'Target value calculation template must contain one settings option. 
										|Configure the target value calculation template in accordance with the requirements.';
										|it = 'Il modello di calcolo dell''indicatore mirato deve contenere una variante delle impostazioni. 
										|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
										|pl = 'Szablon obliczenia wskaźnika celowego powinien zawierać jeden wariant ustawień. 
										|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
										|tr = 'Hedef değer hesaplama numunesi bir ayar seçeneği içermelidir.
										|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
	
	URLDataCompositionSchema = PutToTempStorage(DCSTemplate_, New UUID());
	NewSourceOfAvailableSettings = New DataCompositionAvailableSettingsSource(URLDataCompositionSchema);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(NewSourceOfAvailableSettings);
		
	// Let's check that the service fields are available
	ServiceResources = Catalogs.StructureOfTargets.ServiceFieldsAnalysisValues();
	ServiceMeasurements = Catalogs.StructureOfTargets.ServiceFieldsOfAnalysisObject();
	
	For Each ServiceResource_ In ServiceResources Do 
		
		ServiceFieldYouAreLookingFor = SettingsComposer.Settings.SelectionAvailableFields.FindField(New DataCompositionField(ServiceResource_));
		If ServiceFieldYouAreLookingFor = Undefined Then
			
			ErrorString = StrTemplate(NStr("vi = 'Khuôn mẫu tính toán chỉ số phải có trường hệ thống %%1. 
				|Cần tùy chỉnh khuôn mẫu tính toán chỉ tiêu chính theo yêu cầu.';
				|ru = 'Шаблон расчета целевого показателя должен содержать служебное поле %%1. 
				|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
				|en = 'Target value calculation template must contain the %%1 internal field.
				|Modify the target value calculation template accordingly.'; fa = 'Target value calculation template must contain the %%1 internal field.
				|Modify the target value calculation template accordingly.';
				|it = 'Il modello di calcolo dell''indicatore mirato deve contenere il campo ausiliario %%1. 
				|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
				|pl = 'Szablon obliczenia wskaźnika celowego powinien zawierać służbowe pole %%1. 
				|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
				|tr = 'Hedef değer hesaplama numunesi, %%1 özel alanını içermelidir. 
				|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"),
				"ServiceResource_");
			StringFunctionsClientServer.SubstituteParametersToString(ErrorString, ServiceResource_);
			ErrorsArray.Add(ErrorString);
			CheckResult.CorrectTemplate = False;
			
		EndIf;
		
	EndDo;
	
	ServiceFieldYouAreLookingFor = SettingsComposer.Settings.SelectionAvailableFields.FindField(New DataCompositionField("Period"));
	If ServiceFieldYouAreLookingFor = Undefined Then
		
		ErrorsArray.Add(NStr("vi = 'Khuôn mẫu tính toán chỉ số phải có trường hệ thống ""Kỳ"". 
										|Cần tùy chỉnh khuôn mẫu tính toán chỉ tiêu chính theo yêu cầu.';
										|ru = 'Шаблон расчета целевого показателя должен содержать служебное поле ""Период"". 
										|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
										|en = 'Target value calculation template must contain the ""Period"" internal field.
										|Configure the target value calculation template in accordance with the requirements.'; fa = 'Target value calculation template must contain the ""Period"" internal field.
										|Configure the target value calculation template in accordance with the requirements.';
										|it = 'Il modello di calcolo dell''indicatore mirato deve contenere il campo ausiliario ""Periodo"". 
										|È necessario impostare il modello di calcolo dell''indicatore mirato in base alle richieste.';
										|pl = 'Szablon obliczenia wskaźnika celowego powinien zawierać służbowe pole ""Период"". 
										|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
										|tr = 'Hedef değer hesaplama numunesi ""Dönem"" özel alanını içermelidir. 
										|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
		
	// Let's check that measurements are available except for service ones
	NumberOfOffDutyMeasurements = 0;
	For Each AvailableSelectionField In SettingsComposer.Settings.SelectionAvailableFields.Items Do 
		
		If Not AvailableSelectionField.Resource
			And Not AvailableSelectionField.Folder
			And Not AvailableSelectionField.Table
			And ServiceMeasurements.Find(String(AvailableSelectionField.Field)) = Undefined Then
			
			NumberOfOffDutyMeasurements = NumberOfOffDutyMeasurements + 1;
			
		EndIf;
	EndDo;
	
	If NumberOfOffDutyMeasurements < 1 Then
		
		ErrorsArray.Add(NStr("vi = 'Khuôn mẫu tính toán chỉ số phải có chiều đo không phải là hệ thống. 
										|Cần tùy chỉnh khuôn mẫu tính toán chỉ số đích theo yêu cầu.';
										|ru = 'Шаблон расчета целевого показателя должен содержать неслужебные измерения. 
										|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
										|en = 'Target value calculation template should contain non-service dimensions. 
										|Set up target value calculation template according to the requirements.'; fa = 'Target value calculation template should contain non-service dimensions. 
										|Set up target value calculation template according to the requirements.';
										|it = 'Il modello di calcolo dell''indicatore mirato deve contenere misure non di servizio.
										|È necessario configurare il modello del calcolo dell''indicatore mirato in base alle richieste.';
										|pl = 'Szablon obliczenia wskaźnika celowego powinien zawierać niesłużbowe pomiary. 
										|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
										|tr = 'Hedef değer hesaplama numunesi, özel olmayan boyutlar içermelidir. 
										|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
		
	NumberOfOffDutyResources = 0;
	For Each AvailableSelectionField In SettingsComposer.Settings.SelectionAvailableFields.Items Do 
		
		If AvailableSelectionField.Resource 
			And Not AvailableSelectionField.Folder 
			And Not AvailableSelectionField.Table 
			And ServiceResources.Find(String(AvailableSelectionField.Field)) = Undefined Then
			
			NumberOfOffDutyResources = NumberOfOffDutyResources + 1;
			
		EndIf;
	EndDo;
	
	If NumberOfOffDutyResources < 1 Then
		
		ErrorsArray.Add(NStr("vi = 'Khuôn mẫu tính toán chỉ số phải có số đo không theo hệ thống. 
										|Cần tùy chỉnh khuôn mẫu tính toán chỉ số cốt yếu theo yêu cầu.';
										|ru = 'Шаблон расчета целевого показателя должен содержать неслужебные ресурсы. 
										|Необходимо настроить шаблон расчета целевого показателя в соответствии с требованиями.';
										|en = 'Target value calculation template should contain non-service resources. 
										|Set up target value calculation template according to the requirements.'; fa = 'Target value calculation template should contain non-service resources. 
										|Set up target value calculation template according to the requirements.';
										|it = 'Il modello di calcolo dell''indicatore mirato deve contenere misure non di servizio.
										|È necessario configurare il modello del calcolo dell''indicatore mirato in base alle richieste.';
										|pl = 'Szablon obliczenia wskaźnika celowego powinien zawierać niesłużbowe zasoby. 
										|Należy ustawić szablon obliczenia wskaźnika celowego zgodnie z wymaganiami.';
										|tr = 'Hedef değer hesaplama numunesi, özel olmayan kaynaklar içermelidir. 
										|Hedef değer hesaplama numunesini taleplere uygun ayarlamak gerekir.'"));
		CheckResult.CorrectTemplate = False;
		
	EndIf;
		
	// Let's write the errors in the result
	
	CheckResult.ErrorsDescription = ErrorsArray;
	
	Return CheckResult;
	
EndFunction

// Returns a string representation of a unique identifier.
// The "-" characters are replaced with "_".
// 
// Parameters:
//	UUID - UUID - the ID that you want to convert to a string.
//
// Returns:
//	String - string representation of a unique identifier.
//
Function UniqueIDPerLine(UUID) Export
	Return StrReplace(String(UUID), "-", "_");
EndFunction

// Returns a unique identifier from the string that was received by the unique identifier function in the String.
// 
// Parameters:
//	String - String - string representation of a unique identifier obtained by the unique identifier function in a String.
//
// Returns:
//	UUID - the ID obtained from the string.
//
Function StringInUniqueIdentifier(String) Export
	Return New UUID(StrReplace(String, "_", "-"));
EndFunction

// Returns a localized representation of the state
// 
// Parameters:
//	State - String - string value of the indicator status.
//
// Returns:
//	String - localized, interface-adapted representation of the state.
// 
Function StatusPresentation(State) Export
	If State = "UnacceptableState" Then
		Presentation = NStr("vi = 'Điều kiện không được chấp nhận';
							|ru = 'Неприемлемое состояние';
							|en = 'Unacceptable state'; fa = 'وضعیت غیرقابل قبول';
							|it = 'Condizione inaccettabile';
							|pl = 'Status niedopuszczalny';
							|tr = 'Kabul edilemez durum'");
	ElsIf State = "AcceptableState" Then
		Presentation = NStr("vi = 'Tình trạng chấp nhận được';
							|ru = 'Приемлемое состояние';
							|en = 'Acceptable state'; fa = 'وضعیت قابل قبول';
							|it = 'Condizione accettabile';
							|pl = 'Warunek dopuszczalny';
							|tr = 'Kabul edilebilir durum'");
	ElsIf State = "TheGoalIsAchieved" Then
		Presentation = NStr("vi = 'Đã đạt mục tiêu';
							|ru = 'Цель достигнута';
							|en = 'Target is achieved'; fa = 'هدف محقق شده است';
							|it = 'Obiettivo raggiunto';
							|pl = 'Cel osiągnięty';
							|tr = 'Hedefe ulaşıldı'");
	ElsIf State = "StateIsNotDefined" Then
		Presentation = NStr("vi = 'Trạng thái không xác định';
							|ru = 'Состояние не определено';
							|en = 'State is not defined'; fa = 'وضعیت تعریف نشده است';
							|it = 'Condizione non definita';
							|pl = 'Stan nie jest zdefiniowany';
							|tr = 'Durum tanımlanamadı'");
	ElsIf State = "CalculatedWithErrors" Then
		Presentation = NStr("vi = 'Đã tính bị lỗi';
							|ru = 'Рассчитано с ошибками';
							|en = 'Calculated with errors'; fa = 'محاسبه‌شده با خطا';
							|it = 'Calcolato con errori';
							|pl = 'Obliczono z błędami';
							|tr = 'Hatalarla hesaplandı'");
	Else
		Presentation = State;
	EndIf;
	
	Return Presentation;
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Forecasting

// The function calculates the forecast based on the passed table of values and supplements it if necessary.
//
// Parameters:
//   DataSource - See InitializeDataSource
//   ForecastCalculationParameters - Structure - with properties:
//    *ColumnX - String - name of the column for X-axis data.
//    *ColumnY - String - name of the column for Y-axis data.
//    *AttributeColumn - String - 
//    *Basis - Structure -:
//       **StartDate - Date - base date of the report.
//       **Period - EnumRef.Periodicity - The period used for the calculation.
//       **NumberOfPeriods - Number - the number of periods between adjacent date values on the X-axis.
//    *AnalysisDepth - Number - the x-axis offset within which the trend is calculated.
//    *Offset - Number - the x-axis offset within which the extrapolated values are calculated.
//    *ToSupplementTable - Boolean - if True, extrapolated values are added to the value table.
//    *Prediction - Boolean - 
//
// Returns:
//   Structure - with properties:
//    *Value - Number - extrapolated value for the x-axis offset, or undefined, if there is an error in the calculation.
//    *Adequacy - Number - value of the deviation coefficient.
//    *CalculationMethod_2 - String, Undefined - contains the name of the calculation method.
//    *IsEmpty - Boolean - 
//
Function GenerateForecastValuesForDataSource(DataSource, ForecastCalculationParameters)
	
	ColumnX = ForecastCalculationParameters.ColumnX;
	ColumnY = ForecastCalculationParameters.ColumnY;
	AttributeColumn = ForecastCalculationParameters.AttributeColumn;
	Basis = ForecastCalculationParameters.Basis;
	AnalysisDepth = ForecastCalculationParameters.AnalysisDepth;
	Offset = ForecastCalculationParameters.Offset;
	ToSupplementTable = ForecastCalculationParameters.ToSupplementTable;
	Prediction = ForecastCalculationParameters.Prediction;
		
	StructureOfNeedForCalculations = New Structure;
	StructureOfNeedForCalculations.Insert("Linear_",			True);
	StructureOfNeedForCalculations.Insert("Logarithmic",	True);
	StructureOfNeedForCalculations.Insert("Quadratic",		True);
	StructureOfNeedForCalculations.Insert("Exponential",	True);
	
	StructureOfForecastResult = New Structure("Value, Adequacy, CalculationMethod_2, IsEmpty");
	
	BasisPosition = 0;
	
	SumFact=0;
	SumLogFact=0;
	SumFactArgument=0;
	SumFactLogArgument=0;
	SumLogFactArgument=0;
	SumFactArgument2=0;
	SumArgument=0;
	SumLogArgument=0;
	SumArgument2=0;
	SumLogArgument2=0;
	SumArgument3=0;
	SumArgument4=0;
	
	ValueTable = DataSource.Data;
	DateAndFactOfValue = DataSource.PropertiesOfDataByPeriod.DateOfLastValue;
	
	If ValueTable.Find(Basis.StartDate, ColumnX) = Undefined Then
		StructureOfForecastResult.Insert("Value",			0);
		StructureOfForecastResult.Insert("Adequacy",		0);
		StructureOfForecastResult.Insert("CalculationMethod_2",	Undefined);
		StructureOfForecastResult.Insert("IsEmpty",			True);
		
		Return StructureOfForecastResult;
	EndIf;
	
	// Always served at a continuous interval
	WorkingTable = ContinuousIntervalTable(ValueTable, Basis, AnalysisDepth, ColumnX, ColumnY, BasisPosition); 
	
	If WorkingTable = Undefined Then
		StructureOfForecastResult.Insert("Value",			0);
		StructureOfForecastResult.Insert("Adequacy",		0);
		StructureOfForecastResult.Insert("CalculationMethod_2",	Undefined);
		StructureOfForecastResult.Insert("IsEmpty",			True);
		
		Return StructureOfForecastResult;
	EndIf;
	
	WorkingTable.Sort("SequenceNumber");
	
	For Each String In WorkingTable Do
		
		LineNumber = String.SequenceNumber;
		
		Real=String.Value;
		
		SumFact=SumFact+Real;
		SumLogFact=SumLogFact+?(Real>0,Log(Real),0);
		SumFactArgument=SumFactArgument+Real*LineNumber;
		SumFactLogArgument=SumFactLogArgument+Real*Log(LineNumber);
		SumLogFactArgument=SumLogFactArgument+?(Real>0,Log(Real),0)*LineNumber;
		SumFactArgument2=SumFactArgument2+Real*Pow(LineNumber,2);
		SumArgument=SumArgument+LineNumber;
		SumLogArgument=SumLogArgument+Log(LineNumber);
		SumArgument2=SumArgument2+Pow(LineNumber,2);
		SumLogArgument2=SumLogArgument2+Pow(Log(LineNumber),2);
		SumArgument3=SumArgument3+Pow(LineNumber,3);
		SumArgument4=SumArgument4+Pow(LineNumber,4);
		
	EndDo; 
	CountFact  = WorkingTable.Count();
	ThatSFact = ?(CountFact>0,SumFact/CountFact,0);
	
	// Kramer formulas for linear approximation
	If StructureOfNeedForCalculations.Linear_ Then
		DeterminantOfLinIsComplete = CountFact*SumArgument2-Pow(SumArgument,2);
		DeterminantOfLin1 = SumFact*SumArgument2-SumArgument*SumFactArgument;
		DeterminantOfLin2 = CountFact*SumFactArgument-SumFact*SumArgument;
		
		If DeterminantOfLinIsComplete=0 Then
			StructureOfNeedForCalculations.Linear_ = False;
		Else
			CoefficientOfLinear1=DeterminantOfLin1/DeterminantOfLinIsComplete;
			CoefficientOfLinear2=DeterminantOfLin2/DeterminantOfLinIsComplete;
		EndIf; 
	EndIf;
	// Kramer's formulas for exponential approximation
	If StructureOfNeedForCalculations.Exponential Then
		DeterminantOfExpressionIsComplete = CountFact*SumArgument2-Pow(SumArgument,2);
		DeterminantExp1 = SumLogFact*SumArgument2-SumArgument*SumLogFactArgument;
		DeterminantExp2 = CountFact*SumLogFactArgument-SumLogFact*SumArgument;
		
		If DeterminantOfExpressionIsComplete=0 Then
			StructureOfNeedForCalculations.Exponential = False;
		Else
			ExponentialFactor1=Exp(DeterminantExp1/DeterminantOfExpressionIsComplete);
			ExponentialFactor2=DeterminantExp2/DeterminantOfExpressionIsComplete;
		EndIf;
	EndIf;
	// Kramer 's formulas for logarithmic approximation
	If StructureOfNeedForCalculations.Logarithmic Then
		DeterminantIsLogical = CountFact*SumLogArgument2-Pow(SumLogArgument,2);
		DeterminantLog1 = SumFact*SumLogArgument2-SumLogArgument*SumFactLogArgument;
		DeterminantLog2 = CountFact*SumFactLogArgument-SumFact*SumLogArgument;
		
		If DeterminantIsLogical=0 Then
			StructureOfNeedForCalculations.Logarithmic = False;
		Else
			LogarithmicCoefficient1=DeterminantLog1/DeterminantIsLogical;
			LogarithmicCoefficient2=DeterminantLog2/DeterminantIsLogical;
		EndIf;
		
	EndIf;
	// Kramer 's formulas for quadratic approximation
	If StructureOfNeedForCalculations.Quadratic Then
		DeterminantOfKVIsComplete =CountFact*SumArgument2*SumArgument4+2*SumArgument*SumArgument2*SumArgument3-
			Pow(SumArgument2,3)-CountFact*Pow(SumArgument3,2)-Pow(SumArgument,2)*SumArgument4;
		DeterminantKV1 = SumFact*SumArgument2*SumArgument4+SumArgument*SumArgument3*SumFactArgument2+SumFactArgument*SumArgument2*SumArgument3-
			Pow(SumArgument2,2)*SumFactArgument2-SumFactArgument*SumArgument*SumArgument4-Pow(SumArgument3,2)*SumFact;
		DeterminantKV2 = CountFact*SumFactArgument*SumArgument4+SumFact*SumArgument3*SumArgument2+SumArgument*SumFactArgument2*SumArgument2-
			Pow(SumArgument2,2)*SumFactArgument-SumFact*SumArgument*SumArgument4-CountFact*SumFactArgument2*SumArgument3;
		DeterminantKV3 = CountFact*SumArgument2*SumFactArgument2+SumArgument*SumFactArgument*SumArgument2+SumArgument*SumArgument3*SumFact-
			Pow(SumArgument2,2)*SumFact-Pow(SumArgument,2)*SumFactArgument2-CountFact*SumArgument3*SumFactArgument;
		
		If DeterminantOfKVIsComplete=0 Then
			StructureOfNeedForCalculations.Quadratic = False;
		Else
			CoefficientOfQuadratic1=DeterminantKV1/DeterminantOfKVIsComplete;
			CoefficientOfQuadratic2=DeterminantKV2/DeterminantOfKVIsComplete;
			CoefficientOfQuadratic3=DeterminantKV3/DeterminantOfKVIsComplete;
		EndIf;
		
	EndIf;
	
	SumOSTLinear = 0;
	SumIsQuadratic = 0;
	SumOSTExponential = 0;
	SumIsLogarithmic = 0;
	SumFull = 0;
	
	For Each String In WorkingTable Do
		
		Real = String.Value;
		LineNumber = String.SequenceNumber;
		
		If StructureOfNeedForCalculations.Linear_ Then
			CalculationByLinear=CoefficientOfLinear1+CoefficientOfLinear2*LineNumber;
			SumOSTLinear=SumOSTLinear+Pow((Real-CalculationByLinear),2);
		EndIf;
		
		If StructureOfNeedForCalculations.Quadratic Then
			CalculationByQuadratic=CoefficientOfQuadratic1+CoefficientOfQuadratic2*LineNumber+CoefficientOfQuadratic3*Pow(LineNumber,2);
			SumIsQuadratic=SumIsQuadratic+Pow((Real-CalculationByQuadratic),2);
		EndIf;
		
		If StructureOfNeedForCalculations.Exponential Then
			CalculationByExponential=ExponentialFactor1*Exp(ExponentialFactor2*LineNumber);
			SumOSTExponential=SumOSTExponential+Pow((Real-CalculationByExponential),2);
		EndIf;
		
		If StructureOfNeedForCalculations.Logarithmic Then
			CalculationByLogarithmic=LogarithmicCoefficient1+LogarithmicCoefficient2*Log(LineNumber);
			SumIsLogarithmic=SumIsLogarithmic+Pow((Real-CalculationByLogarithmic),2);
		EndIf;
		
		SumFull=SumFull+Pow((ThatSFact-Real),2);
		
	EndDo;
	
	MaxRatio = Undefined;
	ValueSelected = Undefined;
	
	If StructureOfNeedForCalculations.Linear_ Then
		CoefficientDetLinear=?(SumFull<>0,1-SumOSTLinear/SumFull,1);
		If MaxRatio = Undefined Then
			ValueSelected = "Linear_";
			MaxRatio = CoefficientDetLinear;
		ElsIf MaxRatio < CoefficientDetLinear Then
			ValueSelected = "Linear_";
			MaxRatio = CoefficientDetLinear;
		EndIf;
	EndIf;
	
	If StructureOfNeedForCalculations.Quadratic Then
		
		CoefficientDetQuadratic=?(SumFull<>0,1-SumIsQuadratic/SumFull,0);
		If MaxRatio = Undefined Then
			ValueSelected = "Quadratic";
			MaxRatio = CoefficientDetQuadratic;
		ElsIf MaxRatio < CoefficientDetQuadratic Then
			ValueSelected = "Quadratic";
			MaxRatio = CoefficientDetQuadratic;
		EndIf;
	EndIf;
	
	If StructureOfNeedForCalculations.Logarithmic Then
		
		CoefficientDetLogarithmic=?(SumFull<>0,1-SumIsLogarithmic/SumFull,0);
		If MaxRatio = Undefined Then
			ValueSelected = "Logarithmic";
			MaxRatio = CoefficientDetLogarithmic;
		ElsIf MaxRatio < CoefficientDetLogarithmic Then
			ValueSelected = "Logarithmic";
			MaxRatio = CoefficientDetLogarithmic;
		EndIf;
	EndIf;
	
	If StructureOfNeedForCalculations.Exponential Then
		
		CoefficientDetExponential=?(SumFull<>0,1-SumOSTExponential/SumFull,0);
		
		If MaxRatio = Undefined Then
			ValueSelected = "Exponential";
			MaxRatio = CoefficientDetExponential;
		ElsIf MaxRatio < CoefficientDetExponential Then
			ValueSelected = "Exponential";
			MaxRatio = CoefficientDetExponential;
		EndIf;
		
	EndIf;
	
	If ValueSelected = Undefined Then
		StructureOfForecastResult.Insert("Value",			0);
		StructureOfForecastResult.Insert("Adequacy",		0);
		StructureOfForecastResult.Insert("CalculationMethod_2",	Undefined);
		StructureOfForecastResult.Insert("IsEmpty",			True);
		
		Return StructureOfForecastResult;
	EndIf;
	
	If ToSupplementTable Then
		TypeDescriptionNumber = Common.TypeDescriptionNumber(31, 3);
		If Prediction Then
			ForecastColumn = ValueTable.Columns.Add("Prediction", TypeDescriptionNumber, "Prediction");
		Else
			TrendColumn = ValueTable.Columns.Add("Trend", TypeDescriptionNumber, "Trend");
		EndIf;
		ValueTable.Columns.Add(AttributeColumn, GetDescriptionOfBooleanTypes(), AttributeColumn);
	EndIf;
	
	BaseValue = StandardBaseValueForCharts();
	
	For Indus = ?(ToSupplementTable, 0, Offset) To Offset Do
		
		Argument = BasisPosition + Indus;
		
		If Not Indus = 0 And ValueSelected = "Linear_" Then
			
			// Linear approximation
			
			PaymentAmount_ = CoefficientOfLinear1+CoefficientOfLinear2*Argument;
			Adequacy = CoefficientDetLinear;
		ElsIf Not Indus = 0 And ValueSelected = "Quadratic" Then
			
			// Quadratic approximation
			
			PaymentAmount_=CoefficientOfQuadratic1+CoefficientOfQuadratic2*Argument+CoefficientOfQuadratic3*Pow(Argument,2); 
			Adequacy = CoefficientDetQuadratic;
			
		ElsIf Not Indus = 0 And ValueSelected = "Exponential" Then
			
			// Exponential approximation
			
			PaymentAmount_=ExponentialFactor1*Exp(ExponentialFactor2*Argument); 
			Adequacy = CoefficientDetExponential;
			
		ElsIf Not Indus = 0 And ValueSelected = "Logarithmic" Then
			
			// Logarithmic approximation
			
			PaymentAmount_=LogarithmicCoefficient1+LogarithmicCoefficient2*Log(Argument);
			Adequacy = CoefficientDetLogarithmic;
			
		EndIf;
		
		If ToSupplementTable Then
			CurDate = OffsetDate_(Basis.StartDate, Basis.Period, Indus * Basis.NumberOfPeriods);
			
			StringWithExistingPeriod = ValueTable.Find(CurDate, ColumnX);
			
			If StringWithExistingPeriod = Undefined Then
				NewRow = ValueTable.Add();
				NewRow[ColumnX] = CurDate;
				NewRow[ColumnY] = BaseValue;
			Else 
				NewRow = StringWithExistingPeriod;
				If CurDate > DateAndFactOfValue Then
					NewRow[ColumnY] = BaseValue;
				EndIf;
			EndIf;
			
			If Prediction Then
				If CurDate = DateAndFactOfValue Then
					NewRow[ForecastColumn.Name] = NewRow[ColumnY];
				Else
					NewRow[ForecastColumn.Name] = PaymentAmount_;
				EndIf;
			Else 
				NewRow[TrendColumn.Name] = PaymentAmount_;
			EndIf;
			
			If AttributeColumn <> Undefined Then
				NewRow[AttributeColumn] = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ToSupplementTable Then 
		
		// Fill in the base value of the "empty" points of trends and forecasts
		FilterNotFlag = New Structure("Flag", False);
		RowsNotAttribute = ValueTable.FindRows(FilterNotFlag);
		For Each StringNotAttribute In RowsNotAttribute Do 
			StringNotAttribute[?(Prediction, ForecastColumn.Name, TrendColumn.Name)] = BaseValue;	
		EndDo;
		
	EndIf;
	
	StructureOfForecastResult.Insert("Value",			PaymentAmount_);
	StructureOfForecastResult.Insert("Adequacy",		Adequacy);
	StructureOfForecastResult.Insert("CalculationMethod_2",	ValueSelected);
	StructureOfForecastResult.Insert("IsEmpty",			False);
		
	Return StructureOfForecastResult;
	
EndFunction

// Creates a table with rows in the specified date increment.
//
// Parameters:
//	ValueTable - ValueTable - the original data.
//	Basis - Structure - Properties:
//		*StartDate - Date - base date of the report.
//		*Period - EnumRef.Periodicity - The period used for the calculation.
//		*NumberOfPeriods - Number - the number of periods between adjacent date values on the X-axis.
//	AnalysisDepth - Number - the x-axis offset within which the trend is calculated.
//	ColumnX - String - name of the column for X-axis data.
//	ColumnY - String - name of the column for Y-axis data.
//	BasisPosition - Number - 
//
// Returns:
//	- ValueTable - if it was possible to process.
//	- Undefined - if there is not enough data to extrapolate.
//
Function ContinuousIntervalTable(Val ValueTable, Basis, AnalysisDepth, ColumnX, ColumnY, BasisPosition)
	
	WorkingTable = New ValueTable;
	
	WorkingTable.Columns.Add("SequenceNumber", Common.TypeDescriptionNumber(5, 0));
	WorkingTable.Columns.Add("Date", TMCommonUse.GetDescriptionOfDateTypes(DateFractions.Date));
	WorkingTable.Columns.Add("Value", Common.TypeDescriptionNumber(31, 3));
	
	LastFilled = Undefined;
	NumberOfDataFilledIn = 0;
	SequenceNumber = 1;
	
	For Indus = 1 To AnalysisDepth Do
		CurDate = OffsetDate_(Basis.StartDate, Basis.Period, (Indus - AnalysisDepth) * Basis.NumberOfPeriods);
		FactString_ = ValueTable.Find(CurDate, ColumnX);
		
		If FactString_ = Undefined Then
			
			If LastFilled <> Undefined Then
				NewRow = WorkingTable.Add();
				NewRow.SequenceNumber = SequenceNumber;
				NewRow.Date = CurDate;
				NewRow.Value = 0;
				SequenceNumber = SequenceNumber + 1;
			EndIf;
			
		Else
		
			NewRow = WorkingTable.Add();
			NewRow.SequenceNumber = SequenceNumber;
			NewRow.Date			= CurDate;
			NewRow.Value		= FactString_[ColumnY];
			NumberOfDataFilledIn = NumberOfDataFilledIn + 1;
			If LastFilled <> Undefined And LastFilled < SequenceNumber - 1 Then
				InitialValue_ = WorkingTable.Find(LastFilled, "SequenceNumber").Value;
				ConValue = NewRow.Value;
				ZoomRatio = (ConValue - InitialValue_) / (SequenceNumber - LastFilled + 1);
				
				For Indus2 = LastFilled + 1 To SequenceNumber - 1 Do
					EmptyPeriod = WorkingTable.Find(Indus2, "SequenceNumber");
					EmptyPeriod.Value = InitialValue_ + ZoomRatio * Indus2;
				EndDo;
				
			EndIf;
			
			LastFilled = SequenceNumber;
			SequenceNumber = SequenceNumber + 1;
			
		EndIf;
		
	EndDo;
	
	If NumberOfDataFilledIn < 2 Then 
		Return Undefined;
	Else
		BasisPosition = SequenceNumber - 1;
		Return WorkingTable;
	EndIf;
EndFunction

#EndRegion

#Region AreasOfAnalysisOfTargetValues

// Returns the data source analysis zone
//
// Parameters:
//	DataSource - See GetDataSourceOfAnalysisVariantFromDemoData
//	Trend - EnumRef.KindsOfTargetValueTrends - Trend.
//	TargetValueKind - EnumRef.TargetValueKindsOfAnalysisOptions - range or value.
//	FractionalPartCalculationAccuracy - Number - an integer that sets the degree of rounding in calculations.
//
// Returns:
//	Structure - contains an indication of the analysis area and the nature of the changes:
//		*ZoneNumber - Number - 
//		*TheActualTrend - String - the nature of changes in the indicator "Growth", "Fall", "no Changes".
//					
//
Function ValueAnalysisZone(DataSource, Trend, TargetValueKind, FractionalPartCalculationAccuracy)
	
	AnalysisArea = New Structure;
	AnalysisArea.Insert("ZoneNumber", 0);
	AnalysisArea.Insert("TheActualTrend", "");
	TypesOfTargetValues = Enums.TargetValueKindsOfAnalysisOptions;
	
	TypesOfTrends = Enums.KindsOfTargetValueTrends;
	LastValue = DataSource.PropertiesOfDataByPeriod.LastValue;
	
	PenultimateValue = DataSource.PropertiesOfDataByPeriod.PenultimateValue;
	AnalysisZoneZoneNumber = 0;
	
	If Not DataSource.CalculationsAreRelevant Then 
		AnalysisZoneZoneNumber = 500;
		
	ElsIf Not DataSource.CalculationError And (TargetValueKind = Undefined Or DataSource.IsEmpty) Then
		AnalysisZoneZoneNumber = 0;
		
	ElsIf DataSource.CalculationError Then 
		AnalysisZoneZoneNumber = 100;
		
	Else 
		// We get the fact analysis zone
		If TargetValueKind = TypesOfTargetValues.Value Then
			TargetValue_ = DataSource.PropertiesOfDataByPeriod.TargetValue_;
			AdjustedPositiveBorderVariance = DataSource.PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance;
			AdjustedNegativeBorderVariance  = DataSource.PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance;
			
			If Trend = TypesOfTrends.ValueMaximization Then
				If LastValue > AdjustedPositiveBorderVariance Then
					AnalysisZoneZoneNumber = 1;
				ElsIf LastValue = AdjustedPositiveBorderVariance Then
					AnalysisZoneZoneNumber = 2;
				ElsIf LastValue < AdjustedPositiveBorderVariance
					And LastValue > TargetValue_ Then
					AnalysisZoneZoneNumber = 3;
				ElsIf LastValue = TargetValue_ Then
					AnalysisZoneZoneNumber = 4;
				ElsIf LastValue < TargetValue_
					And LastValue > AdjustedNegativeBorderVariance Then
					AnalysisZoneZoneNumber = 5;
				ElsIf LastValue = AdjustedNegativeBorderVariance Then
					AnalysisZoneZoneNumber = 6;
				ElsIf LastValue < AdjustedNegativeBorderVariance Then
					AnalysisZoneZoneNumber = 7;
				EndIf;
				
			ElsIf Trend = TypesOfTrends.ValueMinimization Then
				If LastValue > AdjustedNegativeBorderVariance Then
					AnalysisZoneZoneNumber = 1;
				ElsIf LastValue = AdjustedNegativeBorderVariance Then
					AnalysisZoneZoneNumber = 2;
				ElsIf LastValue < AdjustedNegativeBorderVariance
					And LastValue > TargetValue_ Then
					AnalysisZoneZoneNumber = 3;
				ElsIf LastValue = TargetValue_ Then
					AnalysisZoneZoneNumber = 4;
				ElsIf LastValue < TargetValue_
					And LastValue > AdjustedPositiveBorderVariance Then
					AnalysisZoneZoneNumber = 5;
				ElsIf LastValue = AdjustedPositiveBorderVariance Then
					AnalysisZoneZoneNumber = 6;
				ElsIf LastValue < AdjustedPositiveBorderVariance Then
					AnalysisZoneZoneNumber = 7;
				EndIf;
				
			EndIf;
			
		ElsIf TargetValueKind = TypesOfTargetValues.Span Then
			MaximumTargetRange = DataSource.PropertiesOfDataByPeriod.MaximumTargetRange;
			MinimumTargetRange = DataSource.PropertiesOfDataByPeriod.MinimumTargetRange;
			AdjustedPositiveBorderVariance = DataSource.PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance;
			AdjustedNegativeBorderVariance  = DataSource.PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance;
			
			If LastValue > AdjustedPositiveBorderVariance Then
				AnalysisZoneZoneNumber = 1;
			ElsIf LastValue = AdjustedPositiveBorderVariance Then
				AnalysisZoneZoneNumber = 2;
			ElsIf LastValue < AdjustedPositiveBorderVariance
				And LastValue > MaximumTargetRange Then
				AnalysisZoneZoneNumber = 3;
			ElsIf LastValue = MaximumTargetRange Then
				AnalysisZoneZoneNumber = 4;
			ElsIf LastValue < MaximumTargetRange
				And LastValue > MinimumTargetRange Then
				AnalysisZoneZoneNumber = 5;
			ElsIf LastValue = MinimumTargetRange Then
				AnalysisZoneZoneNumber = 6;
			ElsIf LastValue < MinimumTargetRange
				And LastValue > AdjustedNegativeBorderVariance Then
				AnalysisZoneZoneNumber = 7;
			ElsIf LastValue = AdjustedNegativeBorderVariance Then
				AnalysisZoneZoneNumber = 8;
			ElsIf LastValue < AdjustedNegativeBorderVariance Then
				AnalysisZoneZoneNumber = 9;
			EndIf;
			
			If AnalysisZoneZoneNumber > 7
				And (Trend = TypesOfTrends.ValueMaximization Or Trend = TypesOfTrends.ValueMinimization) Then
				AnalysisZoneZoneNumber = 7;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	AnalysisArea.ZoneNumber = AnalysisZoneZoneNumber;
	
	// We will get a real trend
	// If the analysis option is compared with past periods, then the trend is a change compared to the previous period
	// If no comparison is specified, then the trend is the change in the specified period.
	If Not DataSource.IsEmpty And DataSource.CalculationsAreRelevant Then
		If DataSource.Property("ComparisonData_") And Not DataSource.ComparisonData_ = Undefined Then
			ComparisonData_ = DataSource.ComparisonData_; // Structure
			DifferenceBetweenFactValues = Round(LastValue - ComparisonData_.LastActualValue, FractionalPartCalculationAccuracy);
		Else
			DifferenceBetweenFactValues = Round(LastValue - PenultimateValue, FractionalPartCalculationAccuracy);
		EndIf;
		
		If DifferenceBetweenFactValues > 0 Then
			TheActualTrend = "Growth";
		ElsIf DifferenceBetweenFactValues = 0 Then
			TheActualTrend = "Unchanged";
		ElsIf DifferenceBetweenFactValues < 0 Then
			TheActualTrend = "Fall";
		EndIf;
	Else
		TheActualTrend = "Undefined";
	EndIf;
	
	AnalysisArea.TheActualTrend = TheActualTrend;
	
	Return AnalysisArea;
	
EndFunction

#EndRegion

#Region WorkingWithPeriodsAndDates

Function DateWithOffsetForDecade(Val EstimatedDate, Val Offset)
	
	// analyzing
	YearOfStartDate						= Year(EstimatedDate);
	MonthOfStartDate						= Month(EstimatedDate);
	StartDateDay						= Day(EstimatedDate);
	DecadeStartDate					= Int((StartDateDay - 1) / 10) + 1;
	DecadeStartDate					= ?(DecadeStartDate = 4, 3, DecadeStartDate);
	NEDecadeNumber						= YearOfStartDate * 36 + (MonthOfStartDate - 1) * 3 + (DecadeStartDate - 1);
	
	// changing
	NEDecadeNumber						= NEDecadeNumber + Offset;
	
	// synthesize
	YearOfStartDateOfRelPeriod				= Int((NEDecadeNumber)/ 36);
	DecadeYear							= NEDecadeNumber % 36;
	MonthInYearOfStartDateOfRelPeriod		= Int(DecadeYear / 3) + 1;
	DecadePerMonth						= DecadeYear % 3;
	DayInMonthOfStartDateOfRelPeriod		= DecadePerMonth * 10 + 1;
	
	Return Date(YearOfStartDateOfRelPeriod, MonthInYearOfStartDateOfRelPeriod, DayInMonthOfStartDateOfRelPeriod);
	
EndFunction

Procedure ReplacePeriodicityName(Expression, NewPeriodicityName)
	
	// Non-translatable expressions of data layout schema fields in the code language.
	Expression = StrReplace(Expression, """Day""", """" + NewPeriodicityName + """");
	Expression = StrReplace(Expression, """Week""", """" + NewPeriodicityName + """");
	Expression = StrReplace(Expression, """TenDays""", """" + NewPeriodicityName + """");
	Expression = StrReplace(Expression, """Month""", """" + NewPeriodicityName + """");
	Expression = StrReplace(Expression, """Quarter""", """" + NewPeriodicityName + """");
	Expression = StrReplace(Expression, """HalfYear""", """" + NewPeriodicityName + """");
	Expression = StrReplace(Expression, """Year""", """" + NewPeriodicityName + """");
	
EndProcedure

Function CalculationPeriodInMinutes(AnalysisOption)
	
	PeriodInMinutes = 0;
	NumberOfPeriods = AnalysisOption.CalculationRelevancePeriod;
	KindOfCalculationRelevancePeriod = AnalysisOption.KindOfCalculationRelevancePeriod;
	
	KindsOfCalculationRelevancePeriods = Enums.KindsOfCalculationRelevancePeriods;
	
	If KindOfCalculationRelevancePeriod = KindsOfCalculationRelevancePeriods.Day Then
		PeriodInMinutes = NumberOfPeriods * 1440;
	ElsIf KindOfCalculationRelevancePeriod = KindsOfCalculationRelevancePeriods.Hour Then
		PeriodInMinutes = NumberOfPeriods * 60;
	ElsIf KindOfCalculationRelevancePeriod = KindsOfCalculationRelevancePeriods.Minute Then
		PeriodInMinutes = NumberOfPeriods;
	EndIf;
	
	Return PeriodInMinutes;
	
EndFunction

Function BeginOfPeriod(Date, Periodicity)
	
	If Periodicity = Enums.Periodicity.Year Then
		Return BegOfYear(Date);
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Return OffsetDate_(BegOfYear(Date), Periodicity, ?(Month(Date)>6, 1, 0));
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Return BegOfQuarter(Date);
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Return BegOfMonth(Date);
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		Return OffsetDate_(BegOfYear(Date), Periodicity, TMCommonUse.DateDiff(BegOfYear(Date), Date, Periodicity));
		
	ElsIf Periodicity = Enums.Periodicity.Week Then
		Return BegOfWeek(Date);
		
	ElsIf Periodicity = Enums.Periodicity.Day Then
		Return BegOfDay(Date);
		
	EndIf;
	
EndFunction

Function EndOfPeriod(Date, Periodicity)
	
	If Periodicity = Enums.Periodicity.Year Then
		
		Return EndOfYear(Date);
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		
		Return EndOfMonth(AddMonth(BegOfYear(Date), ?(Month(Date) <= 6, 1, 2) * 6 - 1));
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		
		Return EndOfQuarter(Date);
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		
		Return EndOfMonth(Date);
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		
		Return EndOfDay(Date);
		
	ElsIf Periodicity = Enums.Periodicity.Week Then
		
		Return EndOfWeek(Date);
		
	ElsIf Periodicity = Enums.Periodicity.Day Then
		
		Return EndOfDay(Date);
		
	Else 
		Return Date;
	EndIf;
	
EndFunction

Function PresentationOfStandardPeriodVariant(CurVersionOfStandardPeriod)
	
	// For platforms below 8.3.15
	If CurVersionOfStandardPeriod = StandardPeriodVariant.Yesterday Then
		VariantPresentation = NStr("vi = 'Hôm qua';
									|ru = 'Вчера';
									|en = 'Yesterday'; fa = 'دیروز';
									|it = 'Ieri';
									|pl = 'Wczoraj';
									|tr = 'Dün'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.TillEndOfThisYear Then
		VariantPresentation = NStr("vi = 'Cho đến hết năm';
									|ru = 'До конца этого года';
									|en = 'Until the end of the year'; fa = 'Until the end of the year';
									|it = 'Fino alla fine di quest''anno';
									|pl = 'Do końca bieżącego roku';
									|tr = 'Bu yılın sonuna kadar'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.TillEndOfThisQuarter Then
		VariantPresentation = NStr("vi = 'Cho đến hết quý';
									|ru = 'До конца этого квартала';
									|en = 'Until the end of the quarter'; fa = 'Until the end of the quarter';
									|it = 'Fino a questo trimestre';
									|pl = 'Do końca bieżącego kwartału';
									|tr = 'Bu çeyreğin sonuna kadar'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.TillEndOfThisMonth Then
		VariantPresentation = NStr("vi = 'Cho đến hết tháng';
									|ru = 'До конца этого месяца';
									|en = 'Until the end of the month'; fa = 'Until the end of the month';
									|it = 'Fino alla fine di questo mese';
									|pl = 'Do końca bieżącego miesiąca';
									|tr = 'Bu ayın sonuna kadar'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.TillEndOfThisHalfYear Then
		VariantPresentation = NStr("vi = 'Đến cuối nửa năm nay';
									|ru = 'До конца этого полугодия';
									|en = 'Until the end of the half-year'; fa = 'Until the end of the half-year';
									|it = 'Fino alla fine di questi sei mesi';
									|pl = 'Do końca bieżącego półrocza';
									|tr = 'Bu yarıyıl sonuna kadar'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.TillEndOfThisTenDays Then
		VariantPresentation = NStr("vi = 'Cho đến cuối kỳ 10 ngày';
									|ru = 'До конца этой декады';
									|en = 'Until the end of the ten-day period'; fa = 'Until the end of the ten-day period';
									|it = 'Fino alla fine di questa decade';
									|pl = 'Do końca bieżącej dekady';
									|tr = 'Bu on günlük sonuna kadar'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.TillEndOfThisWeek Then
		VariantPresentation = NStr("vi = 'Đến cuối tuần này';
									|ru = 'До конца этой недели';
									|en = 'Until the end of this week'; fa = 'Until the end of this week';
									|it = 'Fino alla fine di questa settimana';
									|pl = 'Do końca bieżącego tygodnia';
									|tr = 'Bu hafta sonuna kadar'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.Tomorrow Then
		VariantPresentation = NStr("vi = 'Ngày mai';
									|ru = 'Завтра';
									|en = 'Tomorrow'; fa = 'Tomorrow';
									|it = 'Domani';
									|pl = 'Jutro';
									|tr = 'Yarın'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.Month Then
		VariantPresentation = NStr("vi = 'Tháng';
									|ru = 'Месяц';
									|en = 'Month'; fa = 'ماه';
									|it = 'Mese';
									|pl = 'Miesiąc';
									|tr = 'Ay'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.Last7Days Then
		VariantPresentation = NStr("vi = '7 ngày qua';
									|ru = 'Последние 7 дней';
									|en = 'Last 7 days'; fa = 'Last 7 days';
									|it = 'Ultimi 7 giorni';
									|pl = 'Ostatnie 7 dni';
									|tr = 'Son 7 gün'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.Custom Then
		VariantPresentation = NStr("vi = 'Kỳ tùy ý';
									|ru = 'Произвольный период';
									|en = 'Arbitrary period'; fa = 'دوره دلخواه';
									|it = 'Periodo libero';
									|pl = 'Okres dowolny';
									|tr = 'Serbest dönem'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastTenDays Then
		VariantPresentation = NStr("vi = 'Mười ngày trước';
									|ru = 'Прошлая декада';
									|en = 'Previous ten-day period'; fa = 'Previous ten-day period';
									|it = 'Decade passata';
									|pl = 'Zeszła dekada';
									|tr = 'Geçen 10 günlük süre'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastTenDaysTillSameDayNumber Then
		VariantPresentation = NStr("vi = 'Mười ngày trước cùng ngày này';
									|ru = 'Прошлая декада до такого же номера дня';
									|en = 'Previous ten-day period until the same day number'; fa = 'Previous ten-day period until the same day number';
									|it = 'Decade passata allo stesso numero del giorno';
									|pl = 'Zeszła dekada do takiego samego numeru dnia';
									|tr = 'Aynı gün numarasına son 10 günlük süre'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastWeek Then
		VariantPresentation = NStr("vi = 'Tuần trước';
									|ru = 'Прошлая неделя';
									|en = 'Last week'; fa = 'هفته گذشته';
									|it = 'Settimana passata';
									|pl = 'Zeszły tydzień';
									|tr = 'Geçen hafta'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastWeekTillSameWeekDay Then
		VariantPresentation = NStr("vi = 'Tuần trước cho đến cùng ngày trong tuần';
									|ru = 'Прошлая неделя до такого же дня недели';
									|en = 'Last week until the same day of the week'; fa = 'Last week until the same day of the week';
									|it = 'Settimana passata allo stesso giorno della settimana';
									|pl = 'Zeszły tydzień do takiego samego dnia tygodnia';
									|tr = 'Geçen haftadan haftanın aynı gününe'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastHalfYear Then
		VariantPresentation = NStr("vi = 'Nửa năm trước';
									|ru = 'Прошлое полугодие';
									|en = 'Last half-year'; fa = 'Last half-year';
									|it = 'Sei mesi passati';
									|pl = 'Zeszłe półrocze';
									|tr = 'Geçen yarıyıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastHalfYearTillSameDate Then
		VariantPresentation = NStr("vi = 'Nửa năm trước đến ngày này';
									|ru = 'Прошлое полугодие до такой же даты';
									|en = 'Last half-year until the same day'; fa = 'Last half-year until the same day';
									|it = 'Sei mesi passati alla stessa data';
									|pl = 'Zeszłe półrocze do takiej samej daty';
									|tr = 'Aynı tarihe kadar geçen yarıyıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastYear Then
		VariantPresentation = NStr("vi = 'Năm trước';
									|ru = 'Прошлый год';
									|en = 'Previous year'; fa = 'Previous year';
									|it = 'Anno scorso';
									|pl = 'Poprzedni rok';
									|tr = 'Geçen yıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastYearTillSameDate Then
		VariantPresentation = NStr("vi = 'Năm trước cho đến cùng ngày';
									|ru = 'Прошлый год до такой же даты';
									|en = 'Last year until the same day'; fa = 'Last year until the same day';
									|it = 'Anno scorso fino alla stessa data';
									|pl = 'Zeszły rok do takiej samej daty';
									|tr = 'Aynı tarihe kadar geçen yıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastQuarter Then
		VariantPresentation = NStr("vi = 'Quý trước';
									|ru = 'Прошлый квартал';
									|en = 'Previous quarter'; fa = 'Previous quarter';
									|it = 'Trimestre scorso';
									|pl = 'Poprzedni kwartał';
									|tr = 'Geçen çeyrek'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastQuarterTillSameDate Then
		VariantPresentation = NStr("vi = 'Quý trước cho đến cùng ngày';
									|ru = 'Прошлый квартал до такой же даты';
									|en = 'Last quarter until the same day'; fa = 'Last quarter until the same day';
									|it = 'Trimestre scorso fino alla stessa data';
									|pl = 'Zeszły kwartał do takiej samej daty';
									|tr = 'Aynı tarihe kadar geçen çeyrek'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastMonth Then
		VariantPresentation = NStr("vi = 'Tháng trước';
									|ru = 'Прошлый месяц';
									|en = 'Previous month'; fa = 'ماه قبل';
									|it = 'Mese scorso';
									|pl = 'Poprzedni miesiąc';
									|tr = 'Geçen ay'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.LastMonthTillSameDate Then
		VariantPresentation = NStr("vi = 'Tháng trước cho đến cùng ngày';
									|ru = 'Прошлый месяц до такой же даты';
									|en = 'Last month until the same day'; fa = 'Last month until the same day';
									|it = 'Mese scorso fino alla stessa data';
									|pl = 'Zeszły miesiąc do takiej samej daty';
									|tr = 'Aynı tarihe kadar geçen ay'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.Today Then
		VariantPresentation = NStr("vi = 'Hôm nay';
									|ru = 'Сегодня';
									|en = 'Today'; fa = 'امروز';
									|it = 'Oggi';
									|pl = 'Dzisiaj';
									|tr = 'Bugün'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextTenDays Then
		VariantPresentation = NStr("vi = 'Mười ngày tiếp theo';
									|ru = 'Следующая декада';
									|en = 'Next ten-day period'; fa = 'Next ten-day period';
									|it = 'Decade successiva';
									|pl = 'Przyszła dekada';
									|tr = 'Sonraki on günlük süre'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextTenDaysTillSameDayNumber Then
		VariantPresentation = NStr("vi = 'Mười ngày tới cùng số ngày';
									|ru = 'Следующая декада до такого же номера дня';
									|en = 'Next ten-day period until the same day number'; fa = 'Next ten-day period until the same day number';
									|it = 'Decde successiva allo stesso numero del giorno';
									|pl = 'Przyszła dekada do takiego samego numeru dnia';
									|tr = 'Aynı gün numarasına kadar sonraki 10 günlük süre'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextWeek Then
		VariantPresentation = NStr("vi = 'Tuần sau';
									|ru = 'Следующая неделя';
									|en = 'Next week'; fa = 'هفته بعد';
									|it = 'Settimana successiva';
									|pl = 'Następny tydzień';
									|tr = 'Sonraki hafta'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextWeekTillSameWeekDay Then
		VariantPresentation = NStr("vi = 'Tuần tới cho đến cùng ngày trong tuần';
									|ru = 'Следующая неделя до такого же дня недели';
									|en = 'Next week until the same day of the week'; fa = 'Next week until the same day of the week';
									|it = 'Settimana successiva allo stesso giorno della settimana';
									|pl = 'Przyszły tydzień do takiego samego dnia tygodnia';
									|tr = 'Aynı hafta gününe kadar sonraki hafta'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextHalfYear Then
		VariantPresentation = NStr("vi = 'Nửa năm sau';
									|ru = 'Следующее полугодие';
									|en = 'Next half-year'; fa = 'Next half-year';
									|it = 'Sei mesi successivi';
									|pl = 'Przyszłe półrocze';
									|tr = 'Sonraki yarıyıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextHalfYearTillSameDate Then
		VariantPresentation = NStr("vi = 'Nửa năm tới cùng ngày';
									|ru = 'Следующее полугодие до такой же даты';
									|en = 'Next half-year until the same day'; fa = 'Next half-year until the same day';
									|it = 'Sei mesi successivi fino alla stessa data';
									|pl = 'Przyszłe półrocze do takiej samej daty';
									|tr = 'Aynı tarihe kadar sonraki yarıyıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.Next7Days Then
		VariantPresentation = NStr("vi = '7 ngày tới';
									|ru = 'Следующие 7 дней';
									|en = 'Next 7 days'; fa = 'Next 7 days';
									|it = '7 giorni successivi';
									|pl = 'Następne 7 dni';
									|tr = 'Sonraki 7 gün'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextYear Then
		VariantPresentation = NStr("vi = 'Năm tiếp theo';
									|ru = 'Следующий год';
									|en = 'Next year'; fa = 'Next year';
									|it = 'Anno successivo';
									|pl = 'Następny rok';
									|tr = 'Sıradaki sene'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextYearTillSameDate Then
		VariantPresentation = NStr("vi = 'Năm sau cho đến ngày này';
									|ru = 'Следующий год до такой же даты';
									|en = 'Next year until the same day'; fa = 'Next year until the same day';
									|it = 'Anno successivo fino alla stessa data';
									|pl = 'Przyszły rok do takiej samej daty';
									|tr = 'Aynı tarihe kadar sonraki yıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextQuarter Then
		VariantPresentation = NStr("vi = 'Quý tiếp theo';
									|ru = 'Следующий квартал';
									|en = 'Next quarter'; fa = 'Next quarter';
									|it = 'Trimestre successivo';
									|pl = 'Następny kwartał';
									|tr = 'Sonraki çeyrek'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextQuarterTillSameDate Then
		VariantPresentation = NStr("vi = 'Quý tiếp theo cùng ngày';
									|ru = 'Следующий квартал до такой же даты';
									|en = 'Next quarter until the same day'; fa = 'Next quarter until the same day';
									|it = 'Trimestre successivo alla stessa data';
									|pl = 'Przyszły kwartał do takiej samej daty';
									|tr = 'Aynı tarihe kadar sonraki çeyrek'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextMonth Then
		VariantPresentation = NStr("vi = 'Tháng tiếp theo';
									|ru = 'Следующий месяц';
									|en = 'Next month'; fa = 'Next month';
									|it = 'Mese successivo';
									|pl = 'Następny miesiąc';
									|tr = 'Gelecek ay'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.NextMonthTillSameDate Then
		VariantPresentation = NStr("vi = 'Tháng sau cho đến cùng ngày';
									|ru = 'Следующий месяц до такой же даты';
									|en = 'Next month until the same day'; fa = 'Next month until the same day';
									|it = 'Mese successivo fino alla stessa data';
									|pl = 'Przyszły miesiąc do takiej samej daty';
									|tr = 'Aynı tarihe kadar sonraki ay'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.FromBeginningOfThisYear Then
		VariantPresentation = NStr("vi = 'Từ đầu năm nay';
									|ru = 'С начала этого года';
									|en = 'Since the beginning of the year'; fa = 'Since the beginning of the year';
									|it = 'Dall''inizio di quest''anno';
									|pl = 'Od początku bieżącego roku';
									|tr = 'Bu yılın başından beri'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.FromBeginningOfThisQuarter Then
		VariantPresentation = NStr("vi = 'Từ đầu quý này';
									|ru = 'С начала этого квартала';
									|en = 'Since the beginning of this quarter'; fa = 'Since the beginning of this quarter';
									|it = 'Dall''inizio di questo trimestre';
									|pl = 'Od początku bieżącego kwartału';
									|tr = 'Bu çeyreğin başından beri'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.FromBeginningOfThisMonth Then
		VariantPresentation = NStr("vi = 'Từ đầu tháng này';
									|ru = 'С начала этого месяца';
									|en = 'Since the beginning of this month'; fa = 'Since the beginning of this month';
									|it = 'Dall''inizio di questo mese';
									|pl = 'Od początku bieżącego miesiąca';
									|tr = 'Bu ayın başından beri'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.FromBeginningOfThisHalfYear Then
		VariantPresentation = NStr("vi = 'Từ đầu năm nay';
									|ru = 'С начала этого полугодия';
									|en = 'Since the beginning of this half-year'; fa = 'Since the beginning of this half-year';
									|it = 'Dall''inizio di questi sei mesi';
									|pl = 'Od początku bieżącego półrocza';
									|tr = 'Bu yarıyılın başından beri'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.FromBeginningOfThisTenDays Then
		VariantPresentation = NStr("vi = 'Từ đầu Mười ngày này';
									|ru = 'С начала этой декады';
									|en = 'Since the beginning of this ten-day period'; fa = 'Since the beginning of this ten-day period';
									|it = 'Dall''inizio di questa decade';
									|pl = 'Od początku bieżącej dekady';
									|tr = 'Bu on günlük sürenin başından beri'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.FromBeginningOfThisWeek Then
		VariantPresentation = NStr("vi = 'Từ đầu tuần này';
									|ru = 'С начала этой недели';
									|en = 'Since the beginning of this week'; fa = 'Since the beginning of this week';
									|it = 'Dall''inizio di questa settimana';
									|pl = 'Od początku bieżącego tygodnia';
									|tr = 'Bu haftanın başından beri'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.ThisTenDays Then
		VariantPresentation = NStr("vi = 'Mười ngày này';
									|ru = 'Эта декада';
									|en = 'This ten-day period'; fa = 'This ten-day period';
									|it = 'Questa decade';
									|pl = 'Bieżąca dekada';
									|tr = 'Bu on günlük süre'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.ThisWeek Then
		VariantPresentation = NStr("vi = 'Tuần này';
									|ru = 'Эта неделя';
									|en = 'This week'; fa = 'این هفته';
									|it = 'Questa settimana';
									|pl = 'Ten tydzień';
									|tr = 'Bu hafta'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.ThisHalfYear Then
		VariantPresentation = NStr("vi = 'Nửa năm nay';
									|ru = 'Это полугодие';
									|en = 'This half-year'; fa = 'This half-year';
									|it = 'Questi sei mesi';
									|pl = 'Bieżące półrocze';
									|tr = 'Bu yarıyıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.ThisYear Then
		VariantPresentation = NStr("vi = 'Năm nay';
									|ru = 'Этот год';
									|en = 'This year'; fa = 'This year';
									|it = 'Quest''anno';
									|pl = 'Bieżący rok';
									|tr = 'Bu yıl'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.ThisQuarter Then
		VariantPresentation = NStr("vi = 'Quý này';
									|ru = 'Этот квартал';
									|en = 'This quarter'; fa = 'This quarter';
									|it = 'Questo trimestre';
									|pl = 'Bieżący kwartał';
									|tr = 'Bu çeyrek'");
	ElsIf CurVersionOfStandardPeriod = StandardPeriodVariant.ThisMonth Then
		VariantPresentation = NStr("vi = 'Tháng này';
									|ru = 'Этот месяц';
									|en = 'This month'; fa = 'این ماه';
									|it = 'Questo mese';
									|pl = 'Ten miesiąc';
									|tr = 'Bu ay'");
	Else
		VariantPresentation = String(VariantPresentation);
	EndIf;
	
	Return VariantPresentation;
EndFunction

Function PresentationOfStandardPeriod(ValueOfStandardPeriod, OutputVariant = True)
	
	PresentationOfStartDate = Format(ValueOfStandardPeriod.StartDate, "DLF=D");
	PresentationOfEndDate = Format(ValueOfStandardPeriod.EndDate, "DLF=D");
	
	If OutputVariant Then
		Template = NStr("vi = '%3 (%1 - %2)';
						|ru = '%3 (%1 - %2)';
						|en = '%3 (%1 - %2)'; fa = '%3 (%1 - %2)';
						|it = '%3 (%1 - %2)';
						|pl = '%3 (%1 - %2)';
						|tr = '%3 (%1 - %2)'");
		VariantPresentation = PresentationOfStandardPeriodVariant(ValueOfStandardPeriod.Variant);
	Else
		Template = NStr("vi = '%1 - %2';
						|ru = '%1 - %2';
						|en = '%1 - %2'; fa = '%1 - %2';
						|it = '%1 - %2';
						|pl = '%1 - %2';
						|tr = '%1 - %2'");
		VariantPresentation = "";
	EndIf;
	PresentationOfStandardPeriod = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		PresentationOfStartDate,
		PresentationOfEndDate,
		VariantPresentation);
	
	Return PresentationOfStandardPeriod;
	
EndFunction

Function ApplyDateFormat(Date, Periodicity)
	
	FormattedDate = "01.01.01";
	
	If Periodicity = Enums.Periodicity.Day Then
		FormatString = StrTemplate(NStr("vi = 'DF=%1';
										|ru = 'ДФ=%1';
										|en = 'DF=%1'; fa = 'DF=%1';
										|it = 'DF=%1';
										|pl = 'DF=%1';
										|tr = 'DF=%1'"), "dd.MM.yy");
		FormattedDate = Format(Date(Date), FormatString);
	ElsIf Periodicity = Enums.Periodicity.Week Then
		FormatString = StrTemplate(NStr("vi = 'DF=%1';
										|ru = 'ДФ=%1';
										|en = 'DF=%1'; fa = 'DF=%1';
										|it = 'DF=%1';
										|pl = 'DF=%1';
										|tr = 'DF=%1'"), "dd.MM.yy");
		FormattedDate = Format(Date(Date), FormatString);
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		FormatString = StrTemplate(NStr("vi = 'DF=%1';
										|ru = 'ДФ=%1';
										|en = 'DF=%1'; fa = 'DF=%1';
										|it = 'DF=%1';
										|pl = 'DF=%1';
										|tr = 'DF=%1'"), "dd.MM.yy");
		FormattedDate = Format(Date(Date), FormatString);
	ElsIf Periodicity = Enums.Periodicity.Month Then
		FormatString = NStr("vi = 'DF=''MMM yyyy''';
							|ru = 'ДФ=''MMM yyyy''';
							|en = 'DF=''MMM yyyy'''; fa = 'DF=''MMM yyyy''';
							|it = 'DF=''MMM yyyy''';
							|pl = 'DF=''MMM yyyy''';
							|tr = 'DF=''MMM yyyy'''");
		FormattedDate = Format(Date(Date), FormatString);
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		FormatString = NStr("vi = 'DF=""%1""""Q""""''';
							|ru = 'ДФ=''%1""""КВ""""''';
							|en = 'DF = ''%1""""Q""""'; fa = 'DF = ''%1""""Q""""';
							|it = 'ДФ=''%1""""КВ""""''';
							|pl = 'DF = ''%1""""Q""""';
							|tr = 'DF=''%1""""ÇY""""'''");
		ParameterIsWrittenInCodeLanguage = "k";
		FormatString = StringFunctionsClientServer.SubstituteParametersToString(
			FormatString, ParameterIsWrittenInCodeLanguage);
		FormattedDate = Format(Date(Date), FormatString);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		FormatString = NStr("vi = 'DF='' %1 """"Q""""''';
							|ru = 'ДФ=''%1 """"КВ""""''';
							|en = 'DF = ''%1 """"Q""""'; fa = 'DF = ''%1 """"Q""""';
							|it = 'DF=''%1 """"КВ""""''';
							|pl = 'DF=''%1 """"КВ""""''';
							|tr = 'DF=''%1 """"ÇY""""'''");
		ParameterIsWrittenInCodeLanguage = "k";
		FormatString = StringFunctionsClientServer.SubstituteParametersToString(
			FormatString, ParameterIsWrittenInCodeLanguage);
		FormattedDate = Format(Date(Date), FormatString);
	ElsIf Periodicity = Enums.Periodicity.Year Then
		FormatString = NStr("vi = 'DF=yyyy';
							|ru = 'ДФ=yyyy';
							|en = 'DF=yyyy'; fa = 'DF=yyyy';
							|it = 'Formato data=yyyy';
							|pl = 'DF=yyyy';
							|tr = 'DF=yyyy'");
		FormattedDate = Format(Date(Date), FormatString);
	EndIf;

	Return FormattedDate;
	
EndFunction

Procedure SetPeriodOfExpressionsOfTotalsFields(CompositionSchema, Periodicity)
	
	SummaryFields = CompositionSchema.TotalFields;
	PeriodicityName = GetNameOfEnumerationValue(Periodicity);
	
	For Each TotalField In SummaryFields Do 
		ReplacePeriodicityName(TotalField.Expression, PeriodicityName);
	EndDo;
	
EndProcedure

Function MinimumPeriodicityOfFullPeriod(BeginOfPeriod, EndOfPeriod, MaximumPeriodicity)
	MinimumPeriodicityOfFullPeriod = Undefined;
	
	Periodicity = Enums.Periodicity;
	MaxPeriodicityName = GetNameOfEnumerationValue(MaximumPeriodicity);
	
	OrderedValues = New Array;
	OrderedValues.Add("Year");
	OrderedValues.Add("HalfYear");
	OrderedValues.Add("Quarter");
	OrderedValues.Add("Month");
	
	Check = False;
	For Each OrderedValue In OrderedValues Do
		If Not Check Then
			Check = OrderedValue = MaxPeriodicityName;
		EndIf;
		If Check 
			And BeginOfPeriod(BeginOfPeriod, Periodicity[OrderedValue]) = BeginOfPeriod
			And EndOfPeriod(BeginOfPeriod, Periodicity[OrderedValue]) = EndOfPeriod Then
			MinimumPeriodicityOfFullPeriod = Periodicity[OrderedValue];
		EndIf;
	EndDo;
	
	Return MinimumPeriodicityOfFullPeriod;
EndFunction

#EndRegion

#Region AnalysisOfInterrelatedTargets

Function QueryTextBasedOnStructureOfAvailableAnalysisOptions()
	
	Text = "SELECT
		|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption,
		|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref.Owner AS Target,
		|	OptionsForAnalyzingAccessibilitySettingsTargets.ViewOption
		|INTO AvailableAnalysisOptions
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
		|WHERE
		|	OptionsForAnalyzingAccessibilitySettingsTargets.User = &User
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailableAnalysisOptions.AnalysisOption AS AnalysisOption,
		|	AvailableAnalysisOptions.Target,
		|	AvailableAnalysisOptions.Target.TargetValue,
		|	CASE
		|		WHEN AvailableAnalysisOptions.AnalysisOption.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StateByCumulativeTotal,
		|	AvailableAnalysisOptions.ViewOption,
		|	FALSE AS DisplayDetails,
		|	FALSE AS DisplayTableTotal,
		|	AvailableAnalysisOptions.AnalysisOption.AddlOrderingAttribute AS Position,
		|	AvailableAnalysisOptions.Target.ShortNameOfTargetValue AS NamingOfTarget,
		|	VALUE(Enum.KindsOfAssociatedIndicatorSearch.DependentIndicators) AS Group
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
		|		LEFT JOIN Catalog.StructureOfTargets AS StructureOfTargets
		|			LEFT JOIN AvailableAnalysisOptions AS AvailableAnalysisOptions
		|			ON StructureOfTargets.Ref = AvailableAnalysisOptions.Target
		|		ON AnalysisOptionsOfTargetValues.Owner.Parent = StructureOfTargets.Ref
		|WHERE
		|	AnalysisOptionsOfTargetValues.Ref = &AnalysisOption
		|	AND StructureOfTargets.MeasurableTarget
		|	AND (NOT AvailableAnalysisOptions.AnalysisOption IS NULL )
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailableAnalysisOptions.AnalysisOption AS AnalysisOption,
		|	AvailableAnalysisOptions.Target,
		|	AvailableAnalysisOptions.Target.TargetValue,
		|	CASE
		|		WHEN AvailableAnalysisOptions.AnalysisOption.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StateByCumulativeTotal,
		|	AvailableAnalysisOptions.ViewOption,
		|	FALSE AS DisplayDetails,
		|	FALSE AS DisplayTableTotal,
		|	AvailableAnalysisOptions.AnalysisOption.AddlOrderingAttribute AS Position,
		|	AvailableAnalysisOptions.Target.ShortNameOfTargetValue AS NamingOfTarget,
		|	VALUE(Enum.KindsOfAssociatedIndicatorSearch.InfluencingIndicators) AS Group
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
		|		LEFT JOIN Catalog.StructureOfTargets AS StructureOfTargets
		|			LEFT JOIN AvailableAnalysisOptions AS AvailableAnalysisOptions
		|			ON StructureOfTargets.Ref = AvailableAnalysisOptions.Target
		|		ON AnalysisOptionsOfTargetValues.Owner = StructureOfTargets.Parent
		|WHERE
		|	AnalysisOptionsOfTargetValues.Ref = &AnalysisOption
		|	AND StructureOfTargets.MeasurableTarget
		|	AND (NOT AvailableAnalysisOptions.AnalysisOption IS NULL )
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AvailableAnalysisOptions.AnalysisOption AS AnalysisOption,
		|	AvailableAnalysisOptions.Target,
		|	AvailableAnalysisOptions.Target.TargetValue,
		|	CASE
		|		WHEN AvailableAnalysisOptions.AnalysisOption.ValueCalculationMethod = VALUE(Enum.CalculationMethodsOfTargetValueAnalysisOptions.CumulativeAmount)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StateByCumulativeTotal,
		|	AvailableAnalysisOptions.ViewOption,
		|	FALSE AS DisplayDetails,
		|	FALSE AS DisplayTableTotal,
		|	AvailableAnalysisOptions.AnalysisOption.AddlOrderingAttribute AS Position,
		|	AvailableAnalysisOptions.Target.ShortNameOfTargetValue AS NamingOfTarget,
		|	VALUE(Enum.KindsOfAssociatedIndicatorSearch.EmptyRef) AS Group
		|FROM
		|	Catalog.AnalysisOptionsOfTargetValues AS AnalysisOptionsOfTargetValues
		|		LEFT JOIN AvailableAnalysisOptions AS AvailableAnalysisOptions
		|		ON AnalysisOptionsOfTargetValues.Ref = AvailableAnalysisOptions.AnalysisOption
		|WHERE
		|	AnalysisOptionsOfTargetValues.Ref = &AnalysisOption
		|	AND (NOT AvailableAnalysisOptions.AnalysisOption IS NULL )";
	
	Return Text;
	
EndFunction

#EndRegion

#Region GeneratingCharts

// Fills in the "Diagram" section of the transmitted table document.
//
// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument - Tabular document to fill in.
//	AnalysisOption - Structure - Attributes of the analysis option.
//	DataSource - See InitializeDataSource
//
Procedure FillChartData(SpreadsheetDocument, AnalysisOption, DataSource)
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	TemplateForPrintedFormOfAnalysisVariant = TargetValueMonitoringCached.TemplateIndicatorPages();
	
	If Not DataSource.CalculationsAreRelevant Or DataSource.CalculationError Or DataSource.IsEmpty Then
		TemplateArea = TemplateForPrintedFormOfAnalysisVariant.GetArea("ResultHeaderCalculationError");
		
		If DataSource.Property("ErrorDescription") Then
			TemplateArea.Parameters.ErrorDescription = DataSource.ErrorDescription;
		EndIf;
	Else
		TemplateArea = TemplateForPrintedFormOfAnalysisVariant.GetArea("ResultHeader_");
	EndIf;
	
	SpreadsheetDocument.Put(TemplateArea, 2, "Result");
	
	If Not DataSource.CalculationError And Not DataSource.IsEmpty And DataSource.CalculationsAreRelevant Then
		TemplateArea = TemplateForPrintedFormOfAnalysisVariant.GetArea("ResultChart");
		
		DerivedArea = SpreadsheetDocument.Put(TemplateArea, 3, "Result");
		
		ChartTemplateArea = TemplateArea.Areas.ChartLayout;
		
		FigureDiagram = SpreadsheetDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Chart);
		FigureDiagram.Line = New Line(SpreadsheetDocumentDrawingLineType.Solid);
		FigureDiagram.LineColor = WebColors.Gainsboro;
		
		IndexOf = SpreadsheetDocument.Drawings.IndexOf(FigureDiagram);
		FigureDiagram.Name = "Chart";
		Chart = FigureDiagram.Object;
		
		SetChartDataSource(Chart, DataSource, AnalysisOption);
		
		SetDefaultChartSettings(Chart, AnalysisOption, DataSource.PropertiesOfGeneralStatistics);
		
		If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends
			Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
			SetChartPointNames(Chart.Points,
					DynamicPropertiesOfAnalysisVariant.AnalysisValue,
					DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency);
		EndIf;
		
		If Not DataSource.Data.Columns.Find("Flag") = Undefined 
			And AnalysisOption.CalculateForecast 
			And DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.IsEmpty Then
			// Select all the forecast periods
			SelectionOnBasisOf = New Structure("Flag", True);
			FoundRowsWithPeriods = DataSource.Data.FindRows(SelectionOnBasisOf);
			PeriodsWithSign = DataSource.Data.Copy(FoundRowsWithPeriods, "Period");
			SetCustomChartPointSettings(Chart.Points, AnalysisOption, PeriodsWithSign);
			
			// Delete the "Feature" series
			SourceColumns = DataSource.Data.Columns;
			SourceColumns.Delete(SourceColumns.IndexOf(SourceColumns.Find("Flag")));
		EndIf;
		
		SetDefaultChartSeriesSettings(Chart.Series);
		
		If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then
			SetMeasurementChartSettings(Chart, AnalysisOption, DataSource);
		Else
			SetCustomChartSeriesSettings(Chart.Series, DataSource);
		EndIf;
		
		Chart.ShowLegend = AnalysisOption.ShowLegend;
		FigureDiagram.Protection = False;
		
		Chart.Transparent = True;
		
		TopOfChart = DerivedArea.Top;
		LeftOfChart = DerivedArea.Left + ChartTemplateArea.Left;
		ChartBottoms = TopOfChart + ChartTemplateArea.Bottom - ChartTemplateArea.Top + 10;
		ChartRight = LeftOfChart + ChartTemplateArea.Right - ChartTemplateArea.Left;
		
		ChartTemplateArea = SpreadsheetDocument.Area(TopOfChart, LeftOfChart, ChartBottoms, ChartRight);
		SpreadsheetDocument.Drawings[IndexOf].Place(ChartTemplateArea);
	EndIf;
EndProcedure

// Sets the names of chart points according to chart data from an external source.
//
// Parameters:
//	ChartPoints - ChartPoints - contains the points of the Chart object.
//	AnalysisValueFieldName - Arbitrary -
//	Periodicity - EnumRef.Periodicity - 
//
Procedure SetChartPointNames(ChartPoints, AnalysisValueFieldName, Periodicity)
	
	For Each ChartPoint In ChartPoints Do
		If ChartPoint.Value = AnalysisValueFieldName Then
			Break;
		EndIf;
		
		ChartPoint.Text = ApplyDateFormat(ChartPoint.Text, Periodicity);
		
	EndDo;
	
EndProcedure

// Sets the data source for the chart.
//
// Parameters:
//	Chart - Chart - contains the chart object to fill In
//	DataSource - See InitializeDataSource
//	AnalysisOption - Structure- Attributes of the analysis option.
//	Minidiagram - Boolean - Flag of the minidiagram.
//
Procedure SetChartDataSource(Chart, DataSource, AnalysisOption, Minidiagram = False)
	DataSourceData = DataSource.Data;
	DataSourceColumns = DataSourceData.Columns;
	
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	
	PropertiesOfGeneralStatistics = DataSource.PropertiesOfGeneralStatistics;
	
	TypesOfAnalysis = Enums.IndicatorAnalysisTypes;
	AnalysisType = AnalysisOption.AnalysisType;
	SeriesInColumns = Not (AnalysisType = TypesOfAnalysis.MeasureCurrentValue)
			And Not (AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure);
	
	ThereIsGradient = ((AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure)
			And AnalysisOption.OnlyColorOfMainBatch
			And AnalysisOption.GradientForComponentWiseComparison);
	BySeriesWeight = False;
	
	If ThereIsGradient Then
		MaximumDataSource = PropertiesOfGeneralStatistics.ByObjectsOfAnalysis.Max;
	EndIf;
	
	If AnalysisType = TypesOfAnalysis.ComponentWiseComparisonTrends
		Or (AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure 
		And DataSource.CalculationParameters.ComponentWiseComparisonMode = 1) Then
		Chart.SeriesInRows = False;
		
		For Each RowOfDataSource In DataSourceData Do
			CurChartPoint = Chart.SetPoint(RowOfDataSource["Period"]);
			CurChartPoint.Text = RowOfDataSource["Period"];
			For Each DataSourceColumn In DataSourceColumns Do
				NameOfDataSourceColumn = DataSourceColumn.Name;
				DataSourceColumnHeader = DataSourceColumn.Title;
				
				If NameOfDataSourceColumn = "Period" Then
					Continue;
				EndIf;
				
				CurChartSeries = Chart.SetSeries(NameOfDataSourceColumn);
				CurChartSeries.Value = NameOfDataSourceColumn;
				CurChartSeries.Text = DataSourceColumnHeader;
				
				CurrentValue = RowOfDataSource[NameOfDataSourceColumn];
				
				If Not DataSourceColumns.Find("Period") = Undefined Then
					FormattedSignatureOfSeriesPoint = ApplyDateFormat(CurChartPoint.Text,
						DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency);
				Else 
					FormattedSignatureOfSeriesPoint = CurChartPoint.Text;
				EndIf;
				
				ToolTipText = CurChartSeries.Text + " / " + String(CurrentValue) + " / " + FormattedSignatureOfSeriesPoint;
				
				Chart.SetValue(CurChartPoint, 
				CurChartSeries, 
				CurrentValue, ,
				ToolTipText);
			EndDo;
		EndDo;
	Else
		For Each RowOfDataSource In DataSourceData Do
			StringValue_ = RowOfDataSource[DynamicPropertiesOfAnalysisVariant.AnalysisValue];
			
			If ThereIsGradient Then
				If Not MaximumDataSource = 0 Then
					SeriesWeight = Round(100 * StringValue_ / MaximumDataSource);
				Else
					SeriesWeight = 0;
				EndIf;
			EndIf;
			
			If SeriesInColumns Then
				If AnalysisType = TypesOfAnalysis.ChangeTrends Then
					CurChartPoint = Chart.SetPoint(RowOfDataSource["Period"]);
					CurChartPoint.Text = RowOfDataSource["Period"];
				ElsIf AnalysisType = TypesOfAnalysis.ComparisonWithPreviousPeriod Then
					CurChartPoint = Chart.SetPoint(RowOfDataSource["ComparisonPeriod"]);
					CurChartPoint.Text = RowOfDataSource["ComparisonPeriod"];
				Else
					CurChartPoint = Chart.SetPoint(
						RowOfDataSource[DynamicPropertiesOfAnalysisVariant.AnalysisObject]);
					CurChartPoint.Text = RowOfDataSource[DynamicPropertiesOfAnalysisVariant.AnalysisObject];
				EndIf;
			Else
				If AnalysisType = TypesOfAnalysis.MeasureCurrentValue Then
					CurChartSeries = Chart.SetSeries(
						RowOfDataSource["Period"]);
				Else
					CurChartSeries = Chart.SetSeries(
						RowOfDataSource[DynamicPropertiesOfAnalysisVariant.AnalysisObject]);
				EndIf;
				
				If AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure And BySeriesWeight Then
					If ThereIsGradient Then
						TextTemplate1 = NStr("vi = '%1 = %2#%3#';
											|ru = '%1 = %2#%3#';
											|en = '%1 = %2#%3#'; fa = '%1 = %2#%3#';
											|it = '%1 = %2#%3#';
											|pl = '%1 = %2#%3#';
											|tr = '%1 = %2#%3#'");
					Else
						TextTemplate1 = NStr("vi = '%1 = %2';
											|ru = '%1 = %2';
											|en = '%1 = %2'; fa = '%1 = %2';
											|it = '%1 = %2';
											|pl = '%1 = %2';
											|tr = '%1 = %2'");
					EndIf;
					TextOfSeries = StringFunctionsClientServer.SubstituteParametersToString(
						TextTemplate1,
						String(RowOfDataSource[DynamicPropertiesOfAnalysisVariant.AnalysisObject]),
						StringValue_,
						SeriesWeight);
				ElsIf AnalysisType = TypesOfAnalysis.MeasureCurrentValue Then
					
					Template1 = NStr("vi = 'DF=%Couples1%; DLF=D';
									|ru = 'ДФ=%Couples1%; ДЛФ=D';
									|en = 'DF=%Couples1%; DLF=D'; fa = 'DF=%Couples1%; DLF=D';
									|it = 'DF=%Couples1%; DLF=D';
									|pl = 'DF=%Couples1%; DLF=D';
									|tr = 'DF=%Couples1%; DLF=D'");
					Template1 = StrReplace(Template1, "%Couples1%", "dd.MM.yy");
					DatePresentation = Format(DataSource.PropertiesOfDataByPeriod.DateOfLastValue, Template1);
					
					TextTemplate1 = NStr("vi = '%1 trên %2 = %3';
										|ru = '%1 на %2 = %3';
										|en = '%1 by %2 = %3'; fa = '%1 by %2 = %3';
										|it = '%1 per %2 = %3';
										|pl = '%1 na %2 = %3';
										|tr = '%1 üzerine %2 = %3'");
					TextOfSeries = StringFunctionsClientServer.SubstituteParametersToString(
						TextTemplate1,
						DataSource.PropertiesOfAnalysisAndTrendZone.ExplanationOfTheStatus,
						DatePresentation,
						StringValue_);
				Else
					TextOfSeries = RowOfDataSource[DynamicPropertiesOfAnalysisVariant.AnalysisObject];
				EndIf;
				
				CurChartSeries.Text = TextOfSeries;
			EndIf;
			
			For Each DataSourceColumn In DataSourceColumns Do
				NameOfDataSourceColumn = DataSourceColumn.Name;
				DataSourceColumnHeader = DataSourceColumn.Title;
				
				If NameOfDataSourceColumn = "Period" 
					Or ?(DynamicPropertiesOfAnalysisVariant.AnalysisObject = Undefined, False, StrFind(NameOfDataSourceColumn, DynamicPropertiesOfAnalysisVariant.AnalysisObject))
					Or NameOfDataSourceColumn = "ComparisonPeriod"
					Or NameOfDataSourceColumn = "Flag" Then
					Continue;
				EndIf;
				
				If SeriesInColumns Then
					CurChartSeries = Chart.SetSeries(NameOfDataSourceColumn);
					CurChartSeries.Value = NameOfDataSourceColumn;
					CurChartSeries.Text = DataSourceColumnHeader;
				Else
					CurChartPoint = Chart.SetPoint(NameOfDataSourceColumn);
					CurChartPoint.Value = NameOfDataSourceColumn;
					CurChartPoint.Text = DataSourceColumnHeader;
				EndIf;
				
				CurrentValue = RowOfDataSource[NameOfDataSourceColumn];
				
				If SeriesInColumns Then
					If Not DataSourceColumns.Find("Period") = Undefined Then
						FormattedSignatureOfSeriesPoint = ApplyDateFormat(CurChartPoint.Text,
							DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency);
					Else 
						FormattedSignatureOfSeriesPoint = CurChartPoint.Text;
					EndIf;
				Else
					If Not DataSourceColumns.Find("Period") = Undefined And Not AnalysisType = TypesOfAnalysis.MeasureCurrentValue Then
						FormattedSignatureOfSeriesPoint = ApplyDateFormat(CurChartSeries.Text, DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency);
					Else 
						FormattedSignatureOfSeriesPoint = CurChartSeries.Text;
					EndIf;
				EndIf;
				
				If AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure Then
					If ThereIsGradient And BySeriesWeight Then
						TextOfSeries = CurChartSeries.Text;
						
						StartOfSeriesWeightMarker = StrFind(TextOfSeries, "#");
						LengthOfSeriesValue = StrLen(TextOfSeries);
						SeriesWeightMarker = Right(TextOfSeries, LengthOfSeriesValue - StartOfSeriesWeightMarker + 1);
						
						ToolTipText = StrReplace(TextOfSeries, SeriesWeightMarker, "");
					Else 
						ToolTipText = CurChartSeries.Text;
					EndIf;
					
					Chart.SetValue(CurChartPoint,
						CurChartSeries,
						CurrentValue,,
						ToolTipText);
					
				ElsIf AnalysisType = TypesOfAnalysis.MeasureCurrentValue Then
					Chart.SetValue(CurChartPoint,
						CurChartSeries,
						CurrentValue,,
						CurChartSeries.Text);
					
				Else
					Chart.SetValue(CurChartPoint,
						CurChartSeries,
						CurrentValue,,
						String(CurrentValue) + " / " + FormattedSignatureOfSeriesPoint);
					
				EndIf;
			EndDo; 
		EndDo;
	EndIf;
EndProcedure

// Sets the default settings for the measurement chart.
// Parameters such as stripes, dimensions, etc.
//
// Parameters:
//	Chart - Chart - contains the Chart object to fill in.
//	AnalysisOption - Structure - Attributes of the analysis option.
//	DataSource - See InitializeDataSource
//
Procedure SetMeasurementChartSettings(Chart, AnalysisOption, DataSource)
	
	// Initializing variables
	ChartBands = Chart.GaugeChartQualityBands;
	
	IndicatorColors = AnalysisOption.DecorationSettingStorage.Get().Colors;
	Include_2Zero = AnalysisOption.Include_2Zero;
	
	FractionalPartCalculationAccuracy = AnalysisOption.FractionalPartCalculationAccuracy;
	
	TargetTrend = Common.ObjectAttributeValue(DataSource.Target, "TargetTrend");
	
	PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
	
	// Control values of the diagram construction
	TargetValue_ = GetValueOfAbbreviatedPresentationOfNumber(
		PropertiesOfDataByPeriod.TargetValue_,
		FractionalPartCalculationAccuracy);
	MinimumTargetRange = GetValueOfAbbreviatedPresentationOfNumber(
		PropertiesOfDataByPeriod.MinimumTargetRange,
		FractionalPartCalculationAccuracy);
	MaximumTargetRange = GetValueOfAbbreviatedPresentationOfNumber(
		PropertiesOfDataByPeriod.MaximumTargetRange,
		FractionalPartCalculationAccuracy);
	
	If TargetTrend = Enums.KindsOfTargetValueTrends.ValueMaximization Then
		MinimumGoalValue = GetValueOfAbbreviatedPresentationOfNumber(
			PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance,
			FractionalPartCalculationAccuracy);
		MaximumGoalValue = GetValueOfAbbreviatedPresentationOfNumber(
			PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance,
			FractionalPartCalculationAccuracy);
	ElsIf TargetTrend = Enums.KindsOfTargetValueTrends.ValueMinimization Then
		MinimumGoalValue = GetValueOfAbbreviatedPresentationOfNumber(
			PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance,
			FractionalPartCalculationAccuracy);
		MaximumGoalValue = GetValueOfAbbreviatedPresentationOfNumber(
			PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance,
			FractionalPartCalculationAccuracy);
	ElsIf TargetTrend = Enums.KindsOfTargetValueTrends.Span Then
		MinimumGoalValue = GetValueOfAbbreviatedPresentationOfNumber(
			PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance,
			FractionalPartCalculationAccuracy);
		MaximumGoalValue = GetValueOfAbbreviatedPresentationOfNumber(
			PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance,
			FractionalPartCalculationAccuracy);
	EndIf;
	
	CurrentValue = GetValueOfAbbreviatedPresentationOfNumber(
		DataSource.PropertiesOfDataByPeriod.LastValue,
		FractionalPartCalculationAccuracy);
	
	MinValue = Min(CurrentValue, MinimumGoalValue);
	MaxValue = Max(CurrentValue, MaximumGoalValue);
	BaseValue = ?(Include_2Zero, 0, MinValue);
	
	// Chart Settings
	Chart.BeginGaugeAngle	= 0;
	Chart.EndGaugeAngle	= 180;
	Chart.GaugeThickness	= 10;
	Chart.GaugeBushThickness	= 10;
	
	Chart.BaseValue			= BaseValue;
	Chart.AutoMinValue	= Include_2Zero;
	Chart.MinValue		= MinValue;
	Chart.AutoMaxValue	= False;
	Chart.MaxValue		= MaxValue;

	// Let's add the chart bars
	If TargetTrend = Enums.KindsOfTargetValueTrends.ValueMaximization Then
		If DataSource.PropertiesOfAnalysisAndTrendZone.AnalysisZoneNumber > 0 Then
			BandIsLessThanMinimum = ChartBands.Add();
			BandIsLessThanMinimum.Begin = BaseValue;
			BandIsLessThanMinimum.End = MinimumGoalValue;
			BandIsLessThanMinimum.BackColor = IndicatorColors["NegativeVariance"];
			ToolTip = NStr("vi = 'Phạm vi giá trị không hợp lệ: Chỉ tiêu <Tối thiểu = %1.';
							|ru = 'Диапазон недопустимых значений: Показатель < Мин. = %1.';
							|en = 'Range of invalid values: Indicator < Min. = %1.'; fa = 'Range of invalid values: Indicator < Min. = %1.';
							|it = 'Intervallo dei valori inaccettabili: Indicatore < Min. = %1.';
							|pl = 'Zakres niedopuszczalnych wartości: Wskaźnik < Min. = %1.';
							|tr = 'Geçersiz değerler aralığı: Gösterge < Min. = %1.'");
			BandIsLessThanMinimum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumGoalValue);
			
			BandIsGreaterThanMinimumLessThanGoal = ChartBands.Add();
			BandIsGreaterThanMinimumLessThanGoal.Begin = MinimumGoalValue;
			BandIsGreaterThanMinimumLessThanGoal.End = TargetValue_;
			BandIsGreaterThanMinimumLessThanGoal.BackColor = IndicatorColors["AcceptableDeviationZone"];
			ToolTip = NStr("vi = 'Phạm vi hợp lệ: Tối thiểu = %1 <Chỉ tiêu <Mục tiêu = %2';
							|ru = 'Диапазон допустимых значений: Мин. = %1 < Показатель < Цель = %2';
							|en = 'Range of valid values: Min. = %1 < Indicator < Target = %2'; fa = 'Range of valid values: Min. = %1 < Indicator < Target = %2';
							|it = 'Intervallo dei valori accettabili: Min. = %1 < Indicatore < Obiettivo = %2';
							|pl = 'Zakres dopuszczalnych wartości: Min. = %1 < Wskaźnik < Cel = %2';
							|tr = 'Mümkün değerler aralığı: Min. = %1 < Metrik < Hedef = %2'"); 
			BandIsGreaterThanMinimumLessThanGoal.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumGoalValue,
				TargetValue_);
			
			BandIsLargerThanTargetLessThanMaximum = ChartBands.Add();
			BandIsLargerThanTargetLessThanMaximum.Begin = TargetValue_;
			BandIsLargerThanTargetLessThanMaximum.End = MaximumGoalValue;
			BandIsLargerThanTargetLessThanMaximum.BackColor = IndicatorColors["TargetValue_"];
			ToolTip = NStr("vi = 'Phạm vi đạt được mục tiêu: Mục tiêu = %1 <Chỉ tiêu <Tối đa = %2';
							|ru = 'Диапазон достижения цели: Цель = %1 < Показатель < Макс. = %2';
							|en = 'Target achievement range: Target = %1 < Indicator < Max. = %2'; fa = 'Target achievement range: Target = %1 < Indicator < Max. = %2';
							|it = 'Intervallo di raggiungimento dell''obiettivo: Obiettivo = %1 < Indicatore < Max. = %2';
							|pl = 'Zakres osiągnięcia celu: Cel = %1 < Wskaźnik < Maks. = %2';
							|tr = 'Hedefe ulaşma aralığı: Hedef = %1 < Gösterge < Maks. = %2'");
			BandIsLargerThanTargetLessThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				TargetValue_,
				MaximumGoalValue);
			
			If MaxValue > MaximumGoalValue Then
				BandIsGreaterThanMaximum = ChartBands.Add();
				BandIsGreaterThanMaximum.Begin = MaximumGoalValue;
				BandIsGreaterThanMaximum.End = MaxValue;
				BandIsGreaterThanMaximum.BackColor = IndicatorColors["PositiveVariance"];
				ToolTip = NStr("vi = 'Phạm vi của các giá trị: Chỉ tiêu> Tối đa. = %1';
								|ru = 'Диапазон значений: Показатель > Макс. = %1';
								|en = 'Range of values: Indicator > Max. = %1'; fa = 'Range of values: Indicator > Max. = %1';
								|it = 'Intervallo dei valori: Indicatore > Max. = %1';
								|pl = 'Zakres wartości: Wskaźnik > Maks. = %1';
								|tr = 'Değer aralığı: Gösterge > Maks. = %1'");
				BandIsGreaterThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
					ToolTip,
					MaximumGoalValue);
			EndIf;
		
			If CurrentValue <= MinimumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["NegativeVariance"];
				Chart.Series[0].Color = IndicatorColors["NegativeVariance"];
				
			ElsIf CurrentValue > MinimumGoalValue And CurrentValue < TargetValue_ Then
				Chart.GaugeBushColor = IndicatorColors["AcceptableDeviationZone"];
				Chart.Series[0].Color = IndicatorColors["AcceptableDeviationZone"];
				
			ElsIf CurrentValue >= TargetValue_ And CurrentValue < MaximumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["TargetValue_"];
				Chart.Series[0].Color = IndicatorColors["TargetValue_"];
				
			ElsIf CurrentValue >= MaximumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["PositiveVariance"];
				Chart.Series[0].Color = IndicatorColors["PositiveVariance"];
				
			EndIf;
		Else
			// One band of actual values
			BandIsLargerThanTargetLessThanMaximum = ChartBands.Add();
			BandIsLargerThanTargetLessThanMaximum.Begin = Chart.MinValue;
			BandIsLargerThanTargetLessThanMaximum.End = Chart.MaxValue;
			BandIsLargerThanTargetLessThanMaximum.ToolTip = NStr("vi = 'Chưa thiết lập mục tiêu. Khoảng giá trị không có giá trị mục tiêu.';
																|ru = 'Цели не установлены. Диапазон без учета целевых значений.';
																|en = 'Targets are not set. The range is without target values.'; fa = 'Targets are not set. The range is without target values.';
																|it = 'Obiettivi non impostati. L''intervallo esclude i valori dell''obiettivo.';
																|pl = 'Cele nie są określone. Zakres bez ewidencji celowych wartości.';
																|tr = 'Hedefler ayarlanmadı. Hedef değerler hariç aralık.'");
			BandIsLargerThanTargetLessThanMaximum.BackColor = IndicatorColors["Value"];
			Chart.GaugeBushColor = IndicatorColors["Value"];
			Chart.Series[0].Color = IndicatorColors["Value"];
			
		EndIf;
	ElsIf TargetTrend = Enums.KindsOfTargetValueTrends.ValueMinimization Then
		If DataSource.PropertiesOfAnalysisAndTrendZone.AnalysisZoneNumber > 0 Then
			BandIsLessThanMinimum = ChartBands.Add();
			BandIsLessThanMinimum.Begin = BaseValue;
			BandIsLessThanMinimum.End = MinimumGoalValue;
			BandIsLessThanMinimum.BackColor = IndicatorColors["PositiveVariance"];
			ToolTip = NStr("vi = 'Phạm vi của các giá trị: Chỉ tiêu<Tối thiểu = %1.';
							|ru = 'Диапазон значений: Показатель < Мин. = %1.';
							|en = 'Range of values: Indicator < Min. = %1.'; fa = 'Range of values: Indicator < Min. = %1.';
							|it = 'Intervallo degli obiettivi: Indicatore < Min. = %1.';
							|pl = 'Zakres wartości: Wskaźnik < Min. = %1.';
							|tr = 'Değer aralığı: Gösterge < Min. = %1.'");
			BandIsLessThanMinimum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumGoalValue);
			
			BandIsGreaterThanMinimumLessThanGoal = ChartBands.Add();
			BandIsGreaterThanMinimumLessThanGoal.Begin = MinimumGoalValue;
			BandIsGreaterThanMinimumLessThanGoal.End = TargetValue_;
			BandIsGreaterThanMinimumLessThanGoal.BackColor = IndicatorColors["TargetValue_"];
			ToolTip = NStr("vi = 'Phạm vi đạt được mục tiêu: Tối thiểu. = %1 <Chỉ tiêu <Mục tiêu = %2';
							|ru = 'Диапазон достижения цели: Мин. = %1 < Показатель < Цель = %2';
							|en = 'Target achievement range: Min. = %1 < Indicator < Target = %2'; fa = 'Target achievement range: Min. = %1 < Indicator < Target = %2';
							|it = 'Intervallo di raggiungimento dell''obiettivo: Min. = %1 < Indicatore < Obiettivo = %2';
							|pl = 'Zakres osiągnięcia celu: Min. = %1 < Wskaźnik < Cel = %2';
							|tr = 'Efe ulaşma aralığı: Min. = %1 < Gösterge < Hedef = %2'"); 
			BandIsGreaterThanMinimumLessThanGoal.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumGoalValue,
				TargetValue_);
			
			BandIsLargerThanTargetLessThanMaximum = ChartBands.Add();
			BandIsLargerThanTargetLessThanMaximum.Begin = TargetValue_;
			BandIsLargerThanTargetLessThanMaximum.End = MaximumGoalValue;
			BandIsLargerThanTargetLessThanMaximum.BackColor = IndicatorColors["AcceptableDeviationZone"];
			ToolTip = NStr("vi = 'Phạm vi hợp lệ: Mục tiêu = %1 <Chỉ tiêu <Tối đa = %2';
							|ru = 'Диапазон допустимых значений: Цель = %1 < Показатель < Макс. = %2';
							|en = 'Range of possible values: Target = %1 < Indicator < Max. = %2'; fa = 'Range of possible values: Target = %1 < Indicator < Max. = %2';
							|it = 'Intervallo dei valori accettabili: Obiettivo = %1 < Indicatore < Max. = %2';
							|pl = 'Zakres dopuszczalnych wartości: Cel = %1 < Wskaźnik < Maks. = %2';
							|tr = 'Mümkün değerler aralığı: Hedef = %1 < Gösterge < Maks. = %2'");
			BandIsLargerThanTargetLessThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				TargetValue_,
				MaximumGoalValue);
			
			If MaxValue > MaximumGoalValue Then
				BandIsGreaterThanMaximum = ChartBands.Add();
				BandIsGreaterThanMaximum.Begin = MaximumGoalValue;
				BandIsGreaterThanMaximum.End = MaxValue;
				BandIsGreaterThanMaximum.BackColor = IndicatorColors["NegativeVariance"];
				ToolTip = NStr("vi = 'Phạm vi giá trị không hợp lệ: Chỉ tiêu> Tối đa. = %1';
								|ru = 'Диапазон недопустимых значений: Показатель > Макс. = %1';
								|en = 'Range of invalid values: Indicator > Max. = %1'; fa = 'Range of invalid values: Indicator > Max. = %1';
								|it = 'Intervallo dei valori inaccettabili: Indicatore > Max. = %1';
								|pl = 'Zakres niedopuszczalnych wartości: Wskaźnik > Maks. = %1';
								|tr = 'Geçersiz değerler aralığı: Gösterge > Maks. = %1'");
				BandIsGreaterThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
					ToolTip,
					MaximumGoalValue);
			EndIf;
			
			If CurrentValue < MinimumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["PositiveVariance"];
				Chart.Series[0].Color = IndicatorColors["PositiveVariance"];
				
			ElsIf CurrentValue > MinimumGoalValue And CurrentValue <= TargetValue_ Then
				Chart.GaugeBushColor = IndicatorColors["TargetValue_"];
				Chart.Series[0].Color = IndicatorColors["TargetValue_"];
				
			ElsIf CurrentValue > TargetValue_ And CurrentValue < MaximumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["AcceptableDeviationZone"];
				Chart.Series[0].Color = IndicatorColors["AcceptableDeviationZone"];
				
			ElsIf CurrentValue >= MaximumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["NegativeVariance"];
				Chart.Series[0].Color = IndicatorColors["NegativeVariance"];
				
			EndIf;
		Else
			// One band of actual values
			BandIsLargerThanTargetLessThanMaximum = ChartBands.Add();
			BandIsLargerThanTargetLessThanMaximum.Begin = Chart.MinValue;
			BandIsLargerThanTargetLessThanMaximum.End = Chart.MaxValue;
			BandIsLargerThanTargetLessThanMaximum.ToolTip = NStr("vi = 'Chưa thiết lập mục tiêu. Khoảng giá trị không có giá trị mục tiêu.';
																|ru = 'Цели не установлены. Диапазон без учета целевых значений.';
																|en = 'Targets are not set. The range is without target values.'; fa = 'Targets are not set. The range is without target values.';
																|it = 'Obiettivi non impostati. L''intervallo esclude i valori dell''obiettivo.';
																|pl = 'Cele nie są określone. Zakres bez ewidencji celowych wartości.';
																|tr = 'Hedefler ayarlanmadı. Hedef değerler hariç aralık.'");
			BandIsLargerThanTargetLessThanMaximum.BackColor = IndicatorColors["Value"];
			Chart.GaugeBushColor = IndicatorColors["Value"];
			Chart.Series[0].Color = IndicatorColors["Value"];
			
		EndIf;
	ElsIf TargetTrend = Enums.KindsOfTargetValueTrends.Span Then
		If DataSource.PropertiesOfAnalysisAndTrendZone.AnalysisZoneNumber > 0 Then
			BandIsLessThanMinimum = ChartBands.Add();
			BandIsLessThanMinimum.Begin = BaseValue;
			BandIsLessThanMinimum.End = MinimumGoalValue;
			BandIsLessThanMinimum.BackColor = IndicatorColors["NegativeVariance"];
			ToolTip = NStr("vi = 'Phạm vi giá trị không hợp lệ: Chỉ tiêu <Tối thiểu = %1.';
							|ru = 'Диапазон недопустимых значений: Показатель < Мин. = %1.';
							|en = 'Range of invalid values: Indicator < Min. = %1.'; fa = 'Range of invalid values: Indicator < Min. = %1.';
							|it = 'Intervallo dei valori inaccettabili: Indicatore < Min. = %1.';
							|pl = 'Zakres niedopuszczalnych wartości: Wskaźnik < Min. = %1.';
							|tr = 'Geçersiz değerler aralığı: Gösterge < Min. = %1.'");
			BandIsLessThanMinimum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumGoalValue);
			
			BandIsGreaterThanMinimumLessThanGoal = ChartBands.Add();
			BandIsGreaterThanMinimumLessThanGoal.Begin = MinimumGoalValue;
			BandIsGreaterThanMinimumLessThanGoal.End = MinimumTargetRange;
			BandIsGreaterThanMinimumLessThanGoal.BackColor = IndicatorColors["AcceptableDeviationZone"];
			ToolTip = NStr("vi = 'Khoảng giá trị hợp lệ: Tối thiểu = %1 < Chỉ tiêu < Mục tiêu (tối thiểu) = %2';
							|ru = 'Диапазон допустимых значений: Мин. = %1 < Показатель < Цель (мин.) = %2';
							|en = 'Range of valid values: Min. = %1 < Indicator < Target (min.) = %2'; fa = 'Range of valid values: Min. = %1 < Indicator < Target (min.) = %2';
							|it = 'Intervallo dei valori accettabili: Min. = %1 < Indicatore < Obiettivo (min.) = %2';
							|pl = 'Zakres dopuszczalnych wartości: Min. = %1 < Wskaźnik < Cel (min.) = %2';
							|tr = 'Mümkün değerler aralığı: Min. = %1 < Gösterge < Hedef (min.) = %2'"); 
			BandIsGreaterThanMinimumLessThanGoal.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumGoalValue,
				MinimumTargetRange);
			
			BandIsLargerThanTargetLessThanMaximum = ChartBands.Add();
			BandIsLargerThanTargetLessThanMaximum.Begin = MinimumTargetRange;
			BandIsLargerThanTargetLessThanMaximum.End = MaximumTargetRange;
			BandIsLargerThanTargetLessThanMaximum.BackColor = IndicatorColors["TargetValue_"];
			ToolTip = NStr("vi = 'Khoảng đạt mục tiêu: Mục tiêu (tối thiểu) = %1 < Chỉ tiêu < Mục tiêu (tối đa) = %2';
							|ru = 'Диапазон достижения цели: Цель (мин.) = %1 < Показатель < Цель (макс.) = %2';
							|en = 'Target achievement range: Target (min.) = %1 < Indicator < Target (max.) = %2'; fa = 'Target achievement range: Target (min.) = %1 < Indicator < Target (max.) = %2';
							|it = 'Intervallo di raggiungimento dell''obiettivo: Obiettivo (min.) = %1 < Indicatore < Obiettivo (max.) = %2';
							|pl = 'Zakres osiągnięcia celu: Cel (min.) = %1 < Wskaźnik < Cel (maks.) = %2';
							|tr = 'Hedefe ulaşma aralığı: Hedef (min.) = %1 < Gösterge < Hedef (maks.) = %2'");
			BandIsLargerThanTargetLessThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MinimumTargetRange,
				MaximumTargetRange);
			
			BandIsGreaterThanMaximum = ChartBands.Add();
			BandIsGreaterThanMaximum.Begin = MaximumTargetRange;
			BandIsGreaterThanMaximum.End = MaximumGoalValue;
			BandIsGreaterThanMaximum.BackColor = IndicatorColors["AcceptableDeviationZone"];
			ToolTip = NStr("vi = 'Khoảng giá trị hợp lệ: Mục tiêu (tối đa) = %1 < Chỉ tiêu < Tối đa = %2';
							|ru = 'Диапазон допустимых значений: Цель (макс.) = %1 < Показатель < Макс. = %2';
							|en = 'Range of valid values: Target (max.) = %1 < Indicator < Max. = %2'; fa = 'Range of valid values: Target (max.) = %1 < Indicator < Max. = %2';
							|it = 'Intervallo dei valori accettabili: Obiettivo (max.) = %1 < Indicatore < Max. = %2';
							|pl = 'Zakres dopuszczalnych wartości: Cel (maks.) = %1 < Wskaźnik < Maks. = %2';
							|tr = 'Mümkün değerler aralığı: Hedef (maks) = %1 < Gösterge < Maks. = %2'"); 
			BandIsGreaterThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MaximumTargetRange,
				MaximumGoalValue);
			
			BandIsGreaterThanMaximum = ChartBands.Add();
			BandIsGreaterThanMaximum.Begin = MaximumGoalValue;
			BandIsGreaterThanMaximum.End = MaxValue;
			BandIsGreaterThanMaximum.BackColor = IndicatorColors["NegativeVariance"];
			ToolTip = NStr("vi = 'Phạm vi của các giá trị: Chỉ tiêu> Tối đa. = %1';
							|ru = 'Диапазон значений: Показатель > Макс. = %1';
							|en = 'Range of values: Indicator > Max. = %1'; fa = 'Range of values: Indicator > Max. = %1';
							|it = 'Intervallo dei valori: Indicatore > Max. = %1';
							|pl = 'Zakres wartości: Wskaźnik > Maks. = %1';
							|tr = 'Değer aralığı: Gösterge > Maks. = %1'");
			BandIsGreaterThanMaximum.ToolTip = StringFunctionsClientServer.SubstituteParametersToString(
				ToolTip,
				MaximumGoalValue);
				
			If CurrentValue < MinimumGoalValue
				Or CurrentValue > MaximumGoalValue Then
				Chart.GaugeBushColor = IndicatorColors["NegativeVariance"];
				Chart.Series[0].Color = IndicatorColors["NegativeVariance"];
				
			ElsIf (CurrentValue >= MinimumGoalValue And CurrentValue < MinimumTargetRange)
				Or (CurrentValue > MaximumTargetRange And CurrentValue <= MaximumGoalValue) Then
				Chart.GaugeBushColor = IndicatorColors["AcceptableDeviationZone"];
				Chart.Series[0].Color = IndicatorColors["AcceptableDeviationZone"];
				
			ElsIf CurrentValue >= MinimumTargetRange And CurrentValue <= MaximumTargetRange Then
				Chart.GaugeBushColor = IndicatorColors["TargetValue_"];
				Chart.Series[0].Color = IndicatorColors["TargetValue_"];
				
			EndIf;
		Else
			// One band of actual values
			BandIsLargerThanTargetLessThanMaximum = ChartBands.Add();
			BandIsLargerThanTargetLessThanMaximum.Begin = MinValue;
			BandIsLargerThanTargetLessThanMaximum.End = MaxValue;
			BandIsLargerThanTargetLessThanMaximum.ToolTip = NStr("vi = 'Chưa thiết lập mục tiêu. Khoảng giá trị không có giá trị mục tiêu.';
																|ru = 'Цели не установлены. Диапазон без учета целевых значений.';
																|en = 'Targets are not set. The range is without target values.'; fa = 'Targets are not set. The range is without target values.';
																|it = 'Obiettivi non impostati. L''intervallo esclude i valori dell''obiettivo.';
																|pl = 'Cele nie są określone. Zakres bez ewidencji celowych wartości.';
																|tr = 'Hedefler ayarlanmadı. Hedef değerler hariç aralık.'");
			BandIsLargerThanTargetLessThanMaximum.BackColor = IndicatorColors["Value"];
			Chart.GaugeBushColor = IndicatorColors["Value"];
			Chart.Series[0].Color = IndicatorColors["Value"];
			
		EndIf;
	EndIf;
EndProcedure

// Sets the default settings for the layout of the chart object.
//
// Parameters:
//	Chart - Chart - contains the Chart object to fill in.
//	AnalysisOption - Structure - Attributes of the analysis option.
//
Procedure SetChartObjectSDefaultSettings(Chart, AnalysisOption, PropertiesOfGeneralStatistics)
	
	Chart.ShowLegend = AnalysisOption.ShowLegend;
	
	ChartTypeName = GetNameOfEnumerationValue(AnalysisOption.ChartType);
	Chart.ChartType = ChartType[ChartTypeName];
	
	If AnalysisOption.ChartSmoothingMode Then
		Chart.SplineMode = ChartSplineMode.SmoothCurve;
	Else
		Chart.SplineMode = ChartSplineMode.None;
	EndIf;
	
	If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		And AnalysisOption.ComponentWiseComparisonMode = 0 Then
		Chart.SeriesInRows = True;
	EndIf;
	
	If Enums.ChartTypesOfIndicators.Histograms().Find(AnalysisOption.ChartType) <> Undefined Then
		Chart.SpaceMode = ChartSpaceMode.Half;
		
		If AnalysisOption.DisplayChartCaptions 
			And Not AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends
			And Not AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends Then
			Chart.LabelType = ChartLabelType.SeriesValue;
			
			If StrFind(ChartTypeName, "Horizontal") > 0 Then
				Chart.LabelLocation = ChartLabelLocation.EdgeAuto;
			EndIf;
		Else
			Chart.LabelType = ChartLabelType.None;
		EndIf;
	ElsIf StrFind(ChartTypeName, "Pie") > 0 Then
		Chart.LabelType = ChartLabelType.SeriesPercent;
	EndIf;
	
	Chart.Outline = AnalysisOption.ChartBorder;
	
	FillPropertyValues(Chart, BasicValueParametersForCharts(AnalysisOption, PropertiesOfGeneralStatistics));
	
	//@skip-warning
	Chart.LabelValueFormat = "NFD=" + AnalysisOption.FractionalPartCalculationAccuracy; //@skip-warning
	Chart.LabelDelimiter = " / ";
EndProcedure

// Sets the default settings for the chart title area.
//
// Parameters:
//	Chart - Chart - contains the Chart object to fill in.
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option.
//
Procedure SetDefaultSettingsOfChartHeaderArea(Chart, AnalysisOption)
	TitleArea = Chart.TitleArea;
	Chart.ShowTitle = False;
	
	TitleArea.Top = 0;
	TitleArea.Bottom = 0;
	TitleArea.Left = 0;
	TitleArea.Right = 0;
EndProcedure

// Sets the default settings for the chart plotting area.
//
// Parameters:
//	Chart - Chart - contains the Chart object to fill in.
//	AnalysisOption - Structure - Attributes of the analysis option.
//
Procedure SetDefaultSettingsOfChartPlottingArea(Chart, AnalysisOption)
	PlotArea = Chart.PlotArea;
	ShowLegend = AnalysisOption.ShowLegend;
	ChartTypeName = GetNameOfEnumerationValue(AnalysisOption.ChartType);
	LabelLocation = PlotArea.PointsScale.ScaleLabelLocation;
	
	If Chart.BaseValue <> 0 Then
		PlotArea.ScaleColor = WebColors.DodgerBlue;
	Else
		PlotArea.ScaleColor = WebColors.Silver;
	EndIf;
	
	If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ChangeTrends
		Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends
		Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
		
		PlotArea.PointsScale.LabelOrientation = ChartLabelsOrientation.Horizontal;;
		
	ElsIf AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then
		
		PlotArea.PointsScale.LabelOrientation = ChartLabelsOrientation.Auto;
		LabelLocation = ChartScaleLabelLocation.None;
		
		If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.MeasureCurrentValue Then
			PlotArea.Font = New Font(,,True);
			PlotArea.ScaleColor = WebColors.White;
		EndIf;
	EndIf;
	If StrFind(ChartTypeName, "Horizontal") > 0 Then
		LabelLocation = ChartScaleLabelLocation.None;
	EndIf;
	
	PlotArea.PointsScale.ScaleLabelLocation = ChartScaleLabelLocation.Auto;
	PlotArea.ValuesScale.GridLinesShowMode = ChartGridLinesShowMode.DontShow;
	PlotArea.PointsScale.ScaleLabelLocation = LabelLocation;
	PlotArea.ValueScaleFormat = "NFD=" + AnalysisOption.FractionalPartCalculationAccuracy;
	
	If ShowLegend Then
		PlotArea.Top = 0;
		PlotArea.Bottom = 0.76;
		PlotArea.Left = 0;
		PlotArea.Right = 1;
	Else 
		PlotArea.Top = 0;
		PlotArea.Bottom = 0.95;
		PlotArea.Left = 0;
		PlotArea.Right = 1;
	EndIf;
EndProcedure

// Sets the default settings for the chart legend area.
//
// Parameters:
//	Chart - Chart - contains the Chart object to fill in.
//	AnalysisOption - Structure - Attributes of the analysis option.
//
Procedure SetDefaultSettingsOfChartLegendArea(Chart, AnalysisOption)
	ShowLegend = AnalysisOption.ShowLegend;
	
	Chart.ShowLegend = ShowLegend;
	
	LegendArea = Chart.LegendArea;
	
	If ShowLegend Then
		LegendArea.Top = 0.82;
		LegendArea.Bottom = 1;
		LegendArea.Left = 0;
		LegendArea.Right = 1;
	Else
		LegendArea.Top = 0;
		LegendArea.Bottom = 0;
		LegendArea.Left = 0;
		LegendArea.Right = 0;
	EndIf;
EndProcedure

// Sets the default settings for all chart areas.
// Calls the appropriate procedures.
//
// Parameters:
//	Chart - Chart - contains the chart object to fill In
//	AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option
//	PropertiesOfGeneralStatistics - Structure - structure containing statistics on the data source:
// 	* ByPeriods - Structure:
// 	** Count - Number - 
// 	** Min - Number - 
// 	** Max - Number -
// 	** AVG - Number -
// 	** Range - Number - 
// 	** StdDeviation - Number - 
// 	** Median - Number - 
// 	* ByObjectsOfAnalysis - Structure:
// 	** Count - Number - 
// 	** Min - Number - 
// 	** Max - Number -
// 	** AVG - Number -
// 	** Range - Number - 
// 	** StdDeviation - Number - 
// 	** Median - Number -
//
Procedure SetDefaultChartSettings(Chart, AnalysisOption, PropertiesOfGeneralStatistics)
	
	SetChartObjectSDefaultSettings(Chart, AnalysisOption, PropertiesOfGeneralStatistics);
	
	SetDefaultSettingsOfChartHeaderArea(Chart, AnalysisOption);
	SetDefaultSettingsOfChartPlottingArea(Chart, AnalysisOption);
	SetDefaultSettingsOfChartLegendArea(Chart, AnalysisOption);
	SetDefaultChartPointSettings(Chart, AnalysisOption);
	
EndProcedure

// Sets the default settings for the chart series design.
//
// Parameters:
//	ChartSeriesCollection - ChartSeriesCollection - contains the series of the Chart object.
//
Procedure SetDefaultChartSeriesSettings(ChartSeriesCollection)
	For Each ChartSeries In ChartSeriesCollection Do
		SeriesID = ChartSeries.Value;
		
		If StrFind(SeriesID, "TargetValue_")
			Or StrFind(SeriesID, "TargetRange") Then
			ChartSeries.Marker = ChartMarkerType.None;
			ChartSeries.Line = New Line(ChartLineType.Solid, 1);
			ChartSeries.Indicator = True;
		ElsIf StrFind(SeriesID, "Given") Then
			ChartSeries.Marker = ChartMarkerType.None;
			ChartSeries.Line = New Line(ChartLineType.Dashed, 1);
			ChartSeries.Indicator = True;
		ElsIf StrFind(SeriesID, "Trend")
			Or StrFind(SeriesID, "Prediction") Then
			ChartSeries.Indicator = True;
		Else
			ChartSeries.Marker = ChartMarkerType.None;
			ChartSeries.Line = New Line(ChartLineType.Solid, 2);
		EndIf;
	EndDo; 
EndProcedure

// Sets the default settings for chart points.
//
// Parameters:
//	Chart - Chart - contains the chart object to fill In
//	AnalysisOption - Structure - Attributes of the analysis option.
//
Procedure SetDefaultChartPointSettings(Chart, AnalysisOption)
	
	ChartPoints = Chart.Points;
	
	If AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
		For Each ChartPoint In ChartPoints Do 
			If StrFind(ChartPoint.Value, "Prediction") Then
				ChartPoint.Color = AnalysisOption.DecorationSettingStorage.Get().Colors["Prediction"];
				ChartPoint.ColorPriority = True;
			ElsIf StrFind(ChartPoint.Value, "Past_") Then
				ChartPoint.Color = WebColors.DarkGray;
				ChartPoint.ColorPriority = True;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Sets the design parameters for the chart series in accordance with the indicator settings.
//
// Parameters:
//	ChartSeriesCollection - ChartSeriesCollection - contains the series of the Chart object.
//	DataSource - See InitializeDataSource
//
Procedure SetCustomChartSeriesSettings(ChartSeriesCollection, DataSource)
	CalculationParameters = DataSource.CalculationParameters;
	
	AnalysisType = CalculationParameters.AnalysisType;
	TypesOfAnalysis = CalculationParameters.TypesOfAnalysis;
	VariantChartType = DataSource.CalculationParameters.ChartType;
	ChartTypes = Enums.ChartTypesOfIndicators;
	AnalysisOption = DataSource.AnalysisOption; // Structure -
	Colors = AnalysisOption.DecorationSettingStorage.Get().Colors;
	AnalysisValueFieldName = CalculationParameters.AnalysisValueFieldName;
	ObjectOfAnalysisMaximum = DataSource.PropertiesOfDataForAnalysisObjects.ObjectOfAnalysisMaximum;
	
	If Not (AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure 
		Or AnalysisType = TypesOfAnalysis.ComponentWiseComparisonTrends) Then
		
		For Each ChartSeries In ChartSeriesCollection Do
			SeriesID = ChartSeries.Value;
			
			If StrFind(SeriesID, "Flag") Then
				Continue;
			EndIf;
			
			// Colors and markers of the series
			If StrFind(SeriesID, "AdjustedPositiveBorderVariance")
				Or StrFind(SeriesID, "AdjustedNegativeBorderVariance") Then
				
				ChartSeries.Color = ChooseColor(Colors, SeriesID);
				
			ElsIf StrFind(SeriesID, "Prediction")
				Or StrFind(SeriesID, "Trend") Then
				
				If AnalysisOption.DisplayAMarkerOfForecastPoints Then
					ChartSeries.Marker = ChartMarkerType.Rhomb;
					ChartSeries.Line = New Line(ChartLineType.Solid, 2);
				Else
					ChartSeries.Marker = ChartMarkerType.None;
					ChartSeries.Line = New Line(ChartLineType.Dashed, 2);
				EndIf;
				ChartSeries.Color = Colors[SeriesID];
				
			ElsIf StrFind(SeriesID, "TargetRange")
				Or StrFind(SeriesID, "TargetValue_") Then
				ChartSeries.Color = Colors["TargetValue_"];
				
			ElsIf StrFind(SeriesID, AnalysisValueFieldName) Then 
				If AnalysisOption.DisplayValuePointMarkers Then
					ChartSeries.Marker = ChartMarkerType.Circle;
				Else
					ChartSeries.Marker = ChartMarkerType.None;
				EndIf;
				ChartSeries.Color = Colors["Value"];
				
			EndIf;
			
		EndDo;
		
	ElsIf AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure 
		Or AnalysisType = TypesOfAnalysis.ComponentWiseComparisonTrends Then
		
		If AnalysisOption.OnlyColorOfMainBatch Then
			MainSeriesColor = Colors["Value"]; // Color -
			NegativeValueColor = Colors["NegativeVariance"];
			NumberOfChartSeries = ChartSeriesCollection.Count();
			
			If VariantChartType = ChartTypes.Bar
				Or VariantChartType = ChartTypes.Bar3D
				Or VariantChartType = ChartTypes.NormalizedBar
				Or VariantChartType = ChartTypes.NormalizedBar3D
				Or VariantChartType = ChartTypes.StackedBar 
				Or VariantChartType = ChartTypes.StackedBar3D Then
				HorizontalDiagram = True;
			Else
				HorizontalDiagram = False;
			EndIf;
			
			OriginalRed = 0;
			OriginalGreen = 0;
			OriginalBlue = 0;
			OriginalTone = 0;
			InitialSaturation = 0;
			InitialLightness = 0;
			MaximumGradations = Min(5, NumberOfChartSeries);
			BySeriesWeight = False;
			
			GetRedGreenBlueWebColors(MainSeriesColor,
					OriginalRed,
					OriginalGreen,
					OriginalBlue);
			GetToneSaturationBrightnessByRedGreenBlue(OriginalRed,
					OriginalGreen,
					OriginalBlue,
					OriginalTone,
					InitialSaturation,
					InitialLightness);
			
			If BySeriesWeight Then 
				If AnalysisOption.GradientForComponentWiseComparison Then
					WeightOfMaximumSeries = 0;
					For Each ChartSeries In ChartSeriesCollection Do
						// By series weight
						TextOfSeries = ChartSeries.Text;
						StartOfSeriesWeightMarker = StrFind(TextOfSeries, "#");
						LengthOfSeriesValue = StrLen(TextOfSeries);
						SeriesWeightMarker = Right(TextOfSeries, LengthOfSeriesValue - StartOfSeriesWeightMarker + 1);
						
						WeightOfMaximumSeries = Max(WeightOfMaximumSeries, Number(StrReplace(SeriesWeightMarker, "#","")));
					EndDo;
				EndIf;
			EndIf;
			
			NumberOfIssuedSeries = 1;
			While NumberOfIssuedSeries <= NumberOfChartSeries Do 
				If HorizontalDiagram Then
					ChartSeries = ChartSeriesCollection[NumberOfChartSeries - NumberOfIssuedSeries];
				Else
					ChartSeries = ChartSeriesCollection[NumberOfIssuedSeries-1];
				EndIf;
				
				If AnalysisOption.GradientForComponentWiseComparison Then
					If BySeriesWeight Then
						// By series weight
						TextOfSeries = ChartSeries.Text;
						StartOfSeriesWeightMarker = StrFind(TextOfSeries, "#");
						LengthOfSeriesValue = StrLen(TextOfSeries);
						SeriesWeightMarker = Right(TextOfSeries, LengthOfSeriesValue - StartOfSeriesWeightMarker + 1);
						
						ChartSeries.Text = StrReplace(TextOfSeries, SeriesWeightMarker, "");
						
						SeriesWeight = Number(StrReplace(SeriesWeightMarker, "#",""));
						
						If WeightOfMaximumSeries = 0 Then
							Continue;
							
						EndIf;
						
						SeriesWeightRatio = SeriesWeight/WeightOfMaximumSeries;
						
						SeriesRed = 0;
						SeriesGreen = 0;
						SeriesBlue = 0;
						
						// By series weight
						If AnalysisOption.HighlightMaximumValueForComponentWiseComparison And SeriesWeight
							= WeightOfMaximumSeries Then
							// If we select the first value of the initial saturation * coefficient of the series
							GetRedGreenBlueByToneSaturationBrightness(OriginalTone,
								100,
								InitialLightness + (100 - InitialLightness) * (1 - SeriesWeightRatio),
								SeriesRed,
								SeriesGreen,
								SeriesBlue);
							GetExtraColorByRedGreenBlue(SeriesRed,
								SeriesGreen,
								SeriesBlue,
								SeriesRed,
								SeriesGreen,
								SeriesBlue);
						Else
							GetRedGreenBlueByToneSaturationBrightness(OriginalTone,
								InitialSaturation * SeriesWeightRatio, InitialLightness
									+ (100 - InitialLightness) * (1 - SeriesWeightRatio),
								SeriesRed,
								SeriesGreen,
								SeriesBlue);
						EndIf;
						
						If SeriesWeight < 0 Then
							ChartSeries.Color = NegativeValueColor;
						Else
							ChartSeries.Color = New Color(SeriesRed, SeriesGreen, SeriesBlue);
						EndIf;
					Else
						// In no more than 5 steps
						If NumberOfIssuedSeries > MaximumGradations Then
							GraduationNumber = Int(NumberOfIssuedSeries % MaximumGradations);
						Else
							GraduationNumber = NumberOfIssuedSeries;
						EndIf;
						// Lighten almost to white
						If MaximumGradations > 1 Then
							NewLightRatio = InitialLightness + (GraduationNumber - 1) * (100 - InitialLightness) / (MaximumGradations - 1);
							If InitialSaturation <> 0 Then
								NewSaturationFactor = 100 - (GraduationNumber - 1) * 20;//(Gradation number - 2) * (Initial saturation - 25) / (Maximum gradation - 1);
							Else
								NewSaturationFactor = InitialSaturation;
							EndIf;
							
							GetRedGreenBlueByToneSaturationBrightness(OriginalTone,
								NewSaturationFactor,
								NewLightRatio, 
								SeriesRed,
								SeriesGreen,
								SeriesBlue);
						Else
							GetRedGreenBlueByToneSaturationBrightness(OriginalTone,
								InitialSaturation, 
								InitialLightness, 
								SeriesRed,
								SeriesGreen,
								SeriesBlue);
						EndIf;
					
						ChartSeries.Color = New Color(SeriesRed, SeriesGreen, SeriesBlue);
					EndIf;
				Else
					ChartSeries.Color = MainSeriesColor;
					
				EndIf;
				
				If BySeriesWeight Then 
					If AnalysisOption.GradientForComponentWiseComparison
						And AnalysisOption.HighlightMaximumValueForComponentWiseComparison And SeriesWeight
						= WeightOfMaximumSeries Then
						// If we select the first value of the initial saturation * coefficient of the series
						GetRedGreenBlueByToneSaturationBrightness(OriginalTone,
							100,
							InitialLightness + (100 - InitialLightness) * (1 - SeriesWeightRatio),
							SeriesRed,
							SeriesGreen,
							SeriesBlue);
						GetExtraColorByRedGreenBlue(SeriesRed,
							SeriesGreen,
							SeriesBlue,
							SeriesRed,
							SeriesGreen,
							SeriesBlue);
					EndIf;
				Else
					If AnalysisOption.GradientForComponentWiseComparison
						And AnalysisOption.HighlightMaximumValueForComponentWiseComparison
						And ChartSeries.Value = ObjectOfAnalysisMaximum Then
						If ChartSeriesCollection.Count() > 1 Then
							OriginalRedMaxSeries = 0;
							OriginalGreenMaxSeries = 0;
							OriginalBlueMaxSeries = 0;
							NewRedMaxSeries = 0;
							NewGreenMaxSeries = 0;
							NewBlueMaxSeries = 0;
							
							If MainSeriesColor.Type = ColorType.Absolute Then
								OriginalRedMaxSeries = MainSeriesColor.R;
								OriginalGreenMaxSeries = MainSeriesColor.G;
								OriginalBlueMaxSeries = MainSeriesColor.B;
							ElsIf MainSeriesColor.Type = ColorType.WebColor Then
								GetRedGreenBlueWebColors(MainSeriesColor,
									OriginalRedMaxSeries,
									OriginalGreenMaxSeries,
									OriginalBlueMaxSeries);
							EndIf;
							
							GetExtraColorByRedGreenBlue(OriginalRedMaxSeries,
								OriginalGreenMaxSeries,
								OriginalBlueMaxSeries,
								NewRedMaxSeries,
								NewGreenMaxSeries,
								NewBlueMaxSeries);
								
							ChartSeries.Color = New Color(NewRedMaxSeries, NewGreenMaxSeries, NewBlueMaxSeries);
						EndIf;
					EndIf;
				EndIf;
				
				NumberOfIssuedSeries = NumberOfIssuedSeries + 1;
			EndDo;
		EndIf;
		
		If AnalysisType = TypesOfAnalysis.ComponentWiseComparisonTrends Then
			For Each ChartSeries In ChartSeriesCollection Do
				If AnalysisOption.DisplayValuePointMarkers Then
					ChartSeries.Marker = ChartMarkerType.Circle;
				Else
					ChartSeries.Marker = ChartMarkerType.None;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
EndProcedure

Function ChooseColor(Colors, SeriesID)
	
	Result = Undefined;
	
	If SeriesID = "AdjustedPositiveBorderVariance" Then
		Result = Colors["PositiveVariance"];
	ElsIf SeriesID = "AdjustedNegativeBorderVariance" Then
		Result = Colors["NegativeVariance"];
	EndIf;
	
	Return Result;
	
EndFunction

// Sets parameters for the layout of chart points in accordance with the indicator settings.
//
// Parameters:
//	ChartPoints - ChartPoints - contains the points of the Chart object.
//	AnalysisOption - Structure - Attributes of the analysis option.
//	PeriodsWithSign - ValueTable - Period table:
//	 *Period - Date - 
//
Procedure SetCustomChartPointSettings(ChartPoints, AnalysisOption, PeriodsWithSign)
	
	IndicatorColors = AnalysisOption.DecorationSettingStorage.Get().Colors;
	
	For Each ChartPoint In ChartPoints Do
		
		PointID = ChartPoint.Value;
		
		// Find the points with "Sign" = True in the data source
		If Not PeriodsWithSign.Find(Date(PointID)) = Undefined Then
			
			ChartPoint.ColorPriority = True;
			ChartPoint.Color = IndicatorColors["Prediction"];
			
		EndIf;
		
	EndDo; 
	
EndProcedure

#EndRegion

#Region FormationOfPrintedFormOfVariantOfAnalysisAndSummaryReport

// Fills in the header of the table document (indicator Name, status, parameters).
//
// Parameters:
//	SpreadsheetDocument - SpreadsheetDocument - Tabular document to fill in.
//	AnalysisOption - Structure - Attributes of the analysis option.
//	DataSource - See InitializeDataSource
//
Procedure FillInIndicatorReferenceData(SpreadsheetDocument, AnalysisOption, DataSource)
	
	TypesOfAnalysis = Enums.IndicatorAnalysisTypes;
	AnalysisType = AnalysisOption.AnalysisType;
	
	PropertiesOfAnalysisVariant = GetPropertiesOfAnalysisVariant(AnalysisOption, DataSource);
	PrintFormTemplate = TargetValueMonitoringCached.TemplateIndicatorPages();
	Separator = TargetValueMonitoringCached.GetSeparatorOfPrintedFormOfAnalysisVariant();
	
	ThereIsComparison = (AnalysisType = TypesOfAnalysis.ComparisonWithPreviousPeriod);
	
	TemplateArea = PrintFormTemplate.GetArea("NameHeader"); // SpreadsheetDocument - 
	FillPropertyValues(TemplateArea.Parameters, PropertiesOfAnalysisVariant); 
	
	SpreadsheetDocument.Put(TemplateArea, 1, "Header");
	SpreadsheetDocument.Put(Separator, 2, "Header");
	
	// Display information about the goal
	TemplateArea = PrintFormTemplate.GetArea("HeaderGoalInformationHeader"); // SpreadsheetDocument - 
	SpreadsheetDocument.Put(TemplateArea, 2, "Header");
	TemplateArea = PrintFormTemplate.GetArea("HeaderGoalInformationContent"); // SpreadsheetDocument - 
	FillPropertyValues(TemplateArea.Parameters, PropertiesOfAnalysisVariant);
	SpreadsheetDocument.Put(TemplateArea, 3, "Header");
	
	// We will display information about the actual State
	TemplateArea = PrintFormTemplate.GetArea("HeaderInformationAboutActualState"); // SpreadsheetDocument - 
	FillPropertyValues(TemplateArea.Parameters, PropertiesOfAnalysisVariant);
	SpreadsheetDocument.Put(TemplateArea, 3, "Header");
	
	// Output information about the analysis parameters
	ParameterTemplateArea = PrintFormTemplate.GetArea("HeaderInformationAboutAnalysisParameters"); // SpreadsheetDocument - 
	FillPropertyValues(ParameterTemplateArea.Parameters, PropertiesOfAnalysisVariant);
	
	If Not ThereIsComparison Then
		ParameterTemplateArea.DeleteArea(ParameterTemplateArea.Areas.ComparisonPeriodHeader, SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	If Not AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure Then
		TemplateArea = ParameterTemplateArea.GetArea("AnalysisObjectHeader"); // SpreadsheetDocument - 
		ParameterTemplateArea.DeleteArea(ParameterTemplateArea.Areas.AnalysisObjectHeader, SpreadsheetDocumentShiftType.Vertical);
	EndIf;
	
	SpreadsheetDocument.Put(ParameterTemplateArea, 3, "Header");
	
	// Output information about the analysis parameters
	If AnalysisOption.CalculateForecast 
		And Not DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend = Undefined
		And Not DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.IsEmpty Then
		TemplateAreaForForecastParameters = PrintFormTemplate.GetArea("InformationAboutForecastParametersHeader"); // SpreadsheetDocument - 
		FillPropertyValues(TemplateAreaForForecastParameters.Parameters, PropertiesOfAnalysisVariant);
		
		SpreadsheetDocument.Put(TemplateAreaForForecastParameters, 3, "Header");
		
	EndIf;

	SpreadsheetDocument.Put(Separator, 3, "Header");
	
	TemplateArea = PrintFormTemplate.GetArea("ResponsibleHeader"); // SpreadsheetDocument - 
	FillPropertyValues(TemplateArea.Parameters, PropertiesOfAnalysisVariant);
	SpreadsheetDocument.Put(TemplateArea, 3, "Header");
	
	TemplateArea = PrintFormTemplate.GetArea("HeaderFormed"); // SpreadsheetDocument - 
	FillPropertyValues(TemplateArea.Parameters, PropertiesOfAnalysisVariant);
	SpreadsheetDocument.Put(TemplateArea, 3, "Header");
EndProcedure

#EndRegion

#Region CalculationOfDataSourcesAndValuesOfAnalysisOptions

Function GetDataSourceOfAnalysisVariantFromInformationBase(AnalysisOption, ViewOption, DynamicParameters = Undefined)
	SetPrivilegedMode(True);
	
	#Region InitializingDataSource
	DataSource = InitializeDataSource(AnalysisOption);
	#EndRegion
	
	#Region InitializationOfCalculationParameters
	CalculationParameters = CalculationParameters(AnalysisOption, ViewOption, DynamicParameters);
	DataSource.CalculationParameters = CalculationParameters;
	#EndRegion 
	
	DataSource.ForTable = CalculationParameters.ForTable;
	
	#Region ConfiguringAndControllingDataLayoutScheme
	DataCompositionSchema = DataLayoutDiagramForCalculation(CalculationParameters);
	
	If Not MonitoringCorrectnessOfSettingsAndData("DataCompositionSchema", DataCompositionSchema, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	#EndRegion 
	
	// We get a table with a continuous interval of period values
	PeriodsTable = PeriodsOfGivenPeriodicity(CalculationParameters.AnalysisPeriod.StartDate,
		CalculationParameters.AnalysisPeriod.EndDate,
		CalculationParameters.IndicatorCalculationFrequency);
	If CalculationParameters.ThereIsComparison Then
		PeriodsTable = AddPeriodsToTable(PeriodsTable,
			CalculationParameters.ComparisonPeriod.StartDate,
			CalculationParameters.ComparisonPeriod.EndDate,
			CalculationParameters.IndicatorCalculationFrequency);
	EndIf;
	
	#Region ConfiguringSettingsComposer
	SettingsComposer = ComposerSettingsForCalculation(DataCompositionSchema, CalculationParameters, DynamicParameters);
	#EndRegion 
	
	#Region ConfiguringAndControllingDataLayoutTemplate
	DataLayoutTemplateSettings = DataLayoutTemplateSettingsForCalculation(DataCompositionSchema, SettingsComposer);
	
	If Not MonitoringCorrectnessOfSettingsAndData("DataLayoutTemplateSettings", DataLayoutTemplateSettings, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	
	DataCompositionTemplate = DataLayoutTemplateSettings.DataCompositionTemplate;
	#EndRegion 
	
	#Region CachingDataSourceCalculationParameters
	// Fill in the dynamic properties of the analysis option in the data source
	DataCompositionSettings = SettingsComposer.GetSettings();
	
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	DynamicPropertiesOfAnalysisVariant.IndicatorCalculationFrequency = CalculationParameters.IndicatorCalculationFrequency;
	
	If Not DataCompositionSchema.Parameters.Find("SettlementCurrency") = Undefined 
		And DataCompositionSchema.Parameters.Find("SettlementCurrency").Use = DataCompositionParameterUse.Always Then
		
		SettlementCurrency = DataCompositionClientServer.GetParameter(SettingsComposer, "SettlementCurrency");
		DynamicPropertiesOfAnalysisVariant.Dimensions = SettlementCurrency.Value;
	Else 
		DynamicPropertiesOfAnalysisVariant.Dimensions = Common.ObjectAttributeValue(AnalysisOption, "Owner.Dimensions");
	EndIf;
	
	DesiredValueOfAnalysis = DataCompositionSettings.SelectionAvailableFields.FindField(CalculationParameters.ValueAnalysisField);
	If Not MonitoringCorrectnessOfSettingsAndData("AnalysisValue", DesiredValueOfAnalysis, DataSource, CalculationParameters) Then
		Return DataSource;
	Else
		DynamicPropertiesOfAnalysisVariant.AnalysisValue = CalculationParameters.AnalysisValueFieldName;
		DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation = DesiredValueOfAnalysis.Title;
	EndIf;
	
	If CalculationParameters.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		Or CalculationParameters.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
		If CalculationParameters.ComponentWiseComparisonMode = 0 Then
			DesiredObjectOfAnalysis = DataCompositionSettings.SelectionAvailableFields.FindField(CalculationParameters.ObjectOfAnalysisField);
			If Not MonitoringCorrectnessOfSettingsAndData("AnalysisObject", DesiredObjectOfAnalysis, DataSource, CalculationParameters) Then
				Return DataSource;
			Else
				DynamicPropertiesOfAnalysisVariant.AnalysisObject = CalculationParameters.AnalysisObjectFieldName;
				DynamicPropertiesOfAnalysisVariant.AnalysisObjectPresentation = DesiredObjectOfAnalysis.Title;
			EndIf;
		EndIf;
		
		If CalculationParameters.ComponentWiseComparisonMode = 1 Then
			DesiredValueOfAnalysisIsAdditional = DataCompositionSettings.SelectionAvailableFields.FindField(CalculationParameters.AnalysisValueAdditionalField);
			If Not MonitoringCorrectnessOfSettingsAndData("AnalysisValueAdditional", DesiredValueOfAnalysisIsAdditional, DataSource, CalculationParameters) Then
				Return DataSource;
			Else
				DynamicPropertiesOfAnalysisVariant.AnalysisValueAdditional = CalculationParameters.AnalysisValueAdditionalFieldName;
				DynamicPropertiesOfAnalysisVariant.AnalysisValueAdditionalPresentation = DesiredValueOfAnalysisIsAdditional.Title;
			EndIf;
		EndIf;
	EndIf;
	#EndRegion
	
	#Region GetData
	DataSource.DateOfCalculation = CurrentSessionDate();
	DataAcquisitionResult = DataAcquisitionResult(DataCompositionTemplate, PeriodsTable);
	
	If Not MonitoringCorrectnessOfSettingsAndData("DataAcquisitionResult", DataAcquisitionResult, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	
	DataSource.Data = DataAcquisitionResult.Data;
	#EndRegion
	
	#Region PostProcessingAndControlOfCorrectnessOfSettingsAndData
	If Not MonitoringCorrectnessOfSettingsAndData("Data", DataSource.Data, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	
	// Let's fix the relevance of the calculation fact
	DataSource.DataIsRelevant = True;
	
	CollapseData(DataSource, CalculationParameters);
	
	If Not MonitoringCorrectnessOfSettingsAndData("SettlementsRelevance", DataSource.Data, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	
	// Let's process a table of values for two types of object analysis
	If CalculationParameters.ThereIsRunningTotal Then 
		CalculateCumulativeTotal(DataSource.Data, CalculationParameters);
	EndIf;
	
	// Let's check that after analyzing and preparing the source, there is still enough data in it.
	If Not MonitoringCorrectnessOfSettingsAndData("Data", DataSource.Data, DataSource, CalculationParameters) Then
		Return DataSource;
	EndIf;
	#EndRegion 
	
	#Region CachingSummaryInformationByPeriod
	FillInSummaryInformationAboutDataSource(DataSource, CalculationParameters);
	#EndRegion
	
	#Region AugmentingDataWithForecast
	AddForecastToData(DataSource, CalculationParameters);
	#EndRegion 
	
	#Region CachingAnalysisAndTrendZones
	FillAnalysisZonesAndTrend(DataSource, CalculationParameters);
	#EndRegion 
	
	SetPrivilegedMode(False);
	
	Return DataSource;
EndFunction

Function KindOfVarianceFromTargetValue(AnalysisOption, TargetValueDate)
	
	KindOfVarianceFromTargetValue = Enums.KindsOfVariancesFromTargetValues.EmptyRef();
	
	Query = New Query;
	Query.SetParameter("AnalysisOption", AnalysisOption.Ref);
	Query.SetParameter("TargetValueDate", TargetValueDate);
	Query.Text =
	"SELECT
	|	TargetValuesOfSliceAnalysisOptions.KindOfVarianceFromTargetValue
	|FROM
	|	InformationRegister.AnalysisOptionTargetValues.SliceLast(&PeriodParameter_, AnalysisOption = &AnalysisOption) AS TargetValuesOfSliceAnalysisOptions";
	
	PeriodParameterExpression = StringFunctionsClientServer.SubstituteParametersToString(
		"ENDOFPERIOD(&TargetValueDate, %1)",
		Upper(GetNameOfEnumerationValue(AnalysisOption.IndicatorCalculationFrequency)));
	Query.Text = StrReplace(Query.Text, "&PeriodParameter_", PeriodParameterExpression);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then 
		Selection = QueryResult.Select();
		Selection.Next();
		
		KindOfVarianceFromTargetValue = Selection.KindOfVarianceFromTargetValue;
		
	EndIf;
	
	Return KindOfVarianceFromTargetValue;
	
EndFunction

Procedure WriteAnalysisVariantDataToCache(DataSource, ViewOption)
	
	RecordSet = InformationRegisters.DataSourcesOfTargetValueAnalysisOptions.CreateRecordSet();
	
	RecordSet.Filter.AnalysisOption.Value = DataSource.AnalysisOption;
	RecordSet.Filter.AnalysisOption.Use = True;
	RecordSet.Filter.ViewOption.Value = ViewOption;
	RecordSet.Filter.ViewOption.Use = True;
	
	NewRecord = RecordSet.Add();
	NewRecord.AnalysisOption = DataSource.AnalysisOption;
	NewRecord.ViewOption = ViewOption;
	NewRecord.DateOfCalculation = DataSource.DateOfCalculation;
	NewRecord.DataSource = New ValueStorage(DataSource);
	
	RecordSet.Write();
	
EndProcedure

Procedure FillInInformationAboutSetGoals(PropertiesOfDataByPeriod, StringWithLatestValues, AnalysisOption)
	
	TargetValueKind = GetTargetValueView(PropertiesOfDataByPeriod.DateOfLastValue, AnalysisOption);
	
	PropertiesOfDataByPeriod.TargetValueKind = TargetValueKind;
	PropertiesOfDataByPeriod.TargetValue_ = StringWithLatestValues.TargetValue_;
	PropertiesOfDataByPeriod.MaximumTargetRange = StringWithLatestValues.MaximumTargetRange;
	PropertiesOfDataByPeriod.MinimumTargetRange = StringWithLatestValues.MinimumTargetRange;
	PropertiesOfDataByPeriod.KindOfVarianceFromTargetValue = KindOfVarianceFromTargetValue(AnalysisOption, PropertiesOfDataByPeriod.DateOfLastValue);
	PropertiesOfDataByPeriod.PositiveBorderVariance = StringWithLatestValues.PositiveBorderVariance;
	PropertiesOfDataByPeriod.NegativeBorderVariance = StringWithLatestValues.NegativeBorderVariance;
	PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance = StringWithLatestValues.AdjustedPositiveBorderVariance;
	PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance = StringWithLatestValues.AdjustedNegativeBorderVariance;
	
EndProcedure


// Template for the report construction data source.
// 
// Parameters:
// 	AnalysisOption - Structure - Option for analyzing the goal.
//
// Returns:
// 	Structure - LongDesc:
// 	* Target - CatalogRef.StructureOfTargets - Goal.
// 	* AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Option for analyzing the goal.
// 	* CalculationParameters - Undefined -
// 	* Data - ValueTable - table with columns:
// 	** Period - Date - 
// 	** ComparisonPeriod - Date - 
// 	** Flag - Boolean - 
// 	* DateOfCalculation - Date -
// 	* DataIsRelevant - Boolean -
// 	* CalculationsAreRelevant - Boolean -
// 	* ForTable - Boolean -
// 	* IsEmpty - Boolean -
// 	* CalculationError - Boolean -
// 	* ErrorDescription - String -
// 	* DynamicPropertiesOfAnalysisVariant - Structure -:
// 	** Filters - Undefined -
// 	** IndicatorCalculationFrequency - Undefined -
// 	** AnalysisValueAdditionalPresentation - String -
// 	** AnalysisValueAdditional - Undefined -
// 	** AnalysisValuePresentation - String -
// 	** AnalysisValue - Undefined -
// 	** AnalysisObjectPresentation - String -
// 	** AnalysisObject - Undefined -
// 	** Dimensions - Undefined -
// 	* PropertiesOfGeneralStatistics - Structure -:
// 	** ByPeriods - Structure -:
// 	*** Count - Number - 
// 	*** Min - Number - 
// 	*** Max - Number -
// 	*** AVG - Number -
// 	*** Range - Number - 
// 	*** StdDeviation - Number - 
// 	*** Median - Number - 
// 	** ByObjectsOfAnalysis - Structure -:
// 	*** Count - Number - 
// 	*** Min - Number - 
// 	*** Max - Number -
// 	*** AVG - Number -
// 	*** Range - Number - 
// 	*** StdDeviation - Number - 
// 	*** Median - Number - 
// 	* PropertiesOfAnalysisAndTrendZone - Structure -:
// 	** TargetValuesRangesPresentation - Undefined -
// 	** InterestAreaProcedure - Undefined -
// 	** AreaOfInterest - Undefined -
// 	** PatternOfChange - Undefined -
// 	** ExplanationOfTheStatus - Undefined -
// 	** Status - Undefined -
// 	** PointsInRealTrend - Undefined -
// 	** ExplanationOfTheTrend - Undefined -
// 	** TheActualTrend - Undefined -
// 	** AnalysisZoneNumber - Undefined -
// 	** TargetTrend - Undefined -
// 	** ChangesAreStable - Undefined -
// 	* PropertiesOfDataForecastByPeriod - Structure -:
// 	** StatisticalParametersOfTrend - Undefined -
// 	** ToSupplementTable - Undefined -
// 	** AnalysisDepth - Undefined -
// 	** Basis - Undefined -
// 	** NumberOfPeriods - Undefined -
// 	** StartDate - Undefined -
// 	** Offset - Undefined -
// 	** Periodicity - Undefined -
// 	* PropertiesOfDataForAnalysisObjects - Structure -:
// 	** MinValue - Undefined -
// 	** MaxValue - Undefined -
// 	** ObjectOfAnalysisMinimum - Undefined -
// 	** ObjectOfAnalysisMaximum - Undefined -
//
Function InitializeDataSource(AnalysisOption) Export
	
	DataSource = New Structure;
	DataSource.Insert("Target", AnalysisOption.Owner);
	DataSource.Insert("AnalysisOption",							AnalysisOption);
	DataSource.Insert("CalculationParameters",							Undefined);
	DataSource.Insert("Data",									New ValueTable);
	DataSource.Insert("DateOfCalculation",								Date(1,1,1)); 
	DataSource.Insert("DataIsRelevant",							False);
	DataSource.Insert("CalculationsAreRelevant",							True);
	DataSource.Insert("ForTable",								False);
	DataSource.Insert("IsEmpty",									False);
	DataSource.Insert("CalculationError",							False);
	DataSource.Insert("ErrorDescription",							"");
	
	DynamicPropertiesOfAnalysisVariant = New Structure;
	DynamicPropertiesOfAnalysisVariant.Insert("Dimensions",										Undefined);
	DynamicPropertiesOfAnalysisVariant.Insert("AnalysisObject",									Undefined);
	DynamicPropertiesOfAnalysisVariant.Insert("AnalysisObjectPresentation",						"");
	DynamicPropertiesOfAnalysisVariant.Insert("AnalysisValue",									Undefined);
	DynamicPropertiesOfAnalysisVariant.Insert("AnalysisValuePresentation",					"");
	DynamicPropertiesOfAnalysisVariant.Insert("AnalysisValueAdditional",					Undefined);
	DynamicPropertiesOfAnalysisVariant.Insert("AnalysisValueAdditionalPresentation",		"");
	DynamicPropertiesOfAnalysisVariant.Insert("IndicatorCalculationFrequency",					Undefined);
	DynamicPropertiesOfAnalysisVariant.Insert("Filters",											Undefined);
	
	DataSource.Insert("DynamicPropertiesOfAnalysisVariant", DynamicPropertiesOfAnalysisVariant);
	
	PropertiesOfDataByPeriod = New Structure;
	PropertiesOfDataByPeriod.Insert("DateOfFirstValue",						Undefined);
	PropertiesOfDataByPeriod.Insert("DateOfPenultimateValue",					Undefined);
	PropertiesOfDataByPeriod.Insert("DateOfLastValue",						Undefined);
	PropertiesOfDataByPeriod.Insert("FirstValue",								Undefined);
	PropertiesOfDataByPeriod.Insert("PenultimateValue",						Undefined);
	PropertiesOfDataByPeriod.Insert("LastValue",							Undefined);
	PropertiesOfDataByPeriod.Insert("Overall",									Undefined);
	PropertiesOfDataByPeriod.Insert("TargetValueKind",						Undefined);
	PropertiesOfDataByPeriod.Insert("TargetValue_",							Undefined);
	PropertiesOfDataByPeriod.Insert("MinimumTargetRange",						Undefined);
	PropertiesOfDataByPeriod.Insert("MaximumTargetRange",					Undefined);
	PropertiesOfDataByPeriod.Insert("KindOfVarianceFromTargetValue",			Undefined);
	PropertiesOfDataByPeriod.Insert("PositiveBorderVariance",				Undefined);
	PropertiesOfDataByPeriod.Insert("NegativeBorderVariance",				Undefined);
	PropertiesOfDataByPeriod.Insert("AdjustedPositiveBorderVariance",	Undefined);
	PropertiesOfDataByPeriod.Insert("AdjustedNegativeBorderVariance",	Undefined);
	
	DataSource.Insert("PropertiesOfDataByPeriod", PropertiesOfDataByPeriod);
	
	PropertiesOfDataForComparisonPeriods = New Structure;
	PropertiesOfDataForComparisonPeriods.Insert("DateOfFirstValue",							Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("DateOfPenultimateValue",					Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("DateOfLastValue",						Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("FirstValue",								Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("PenultimateValue",							Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("LastValue",								Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("Overall",										Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("TargetValueKind",							Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("TargetValue_",								Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("MinimumTargetRange",						Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("MaximumTargetRange",						Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("KindOfVarianceFromTargetValue",				Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("PositiveBorderVariance",					Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("NegativeBorderVariance",					Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("AdjustedPositiveBorderVariance",		Undefined);
	PropertiesOfDataForComparisonPeriods.Insert("AdjustedNegativeBorderVariance",		Undefined);
	
	DataSource.Insert("PropertiesOfDataForComparisonPeriods", PropertiesOfDataForComparisonPeriods);
	
	PropertiesOfDataForAnalysisObjects = New Structure;
	PropertiesOfDataForAnalysisObjects.Insert("ObjectOfAnalysisMaximum",			Undefined);
	PropertiesOfDataForAnalysisObjects.Insert("ObjectOfAnalysisMinimum",			Undefined);
	PropertiesOfDataForAnalysisObjects.Insert("MaxValue",			Undefined);
	PropertiesOfDataForAnalysisObjects.Insert("MinValue",				Undefined);
	
	DataSource.Insert("PropertiesOfDataForAnalysisObjects", PropertiesOfDataForAnalysisObjects);
	
	PropertiesOfDataForecastByPeriod = New Structure;
	PropertiesOfDataForecastByPeriod.Insert("Periodicity",					Undefined);
	PropertiesOfDataForecastByPeriod.Insert("Offset",						Undefined);
	PropertiesOfDataForecastByPeriod.Insert("StartDate",						Undefined);
	PropertiesOfDataForecastByPeriod.Insert("NumberOfPeriods",				Undefined);
	PropertiesOfDataForecastByPeriod.Insert("Basis",							Undefined);
	PropertiesOfDataForecastByPeriod.Insert("AnalysisDepth",					Undefined);
	PropertiesOfDataForecastByPeriod.Insert("ToSupplementTable",				Undefined);
	PropertiesOfDataForecastByPeriod.Insert("StatisticalParametersOfTrend",	Undefined);
	
	DataSource.Insert("PropertiesOfDataForecastByPeriod", PropertiesOfDataForecastByPeriod);
	
	PropertiesOfAnalysisAndTrendZone = New Structure;
	PropertiesOfAnalysisAndTrendZone.Insert("ChangesAreStable",					Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("TargetTrend",							Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("AnalysisZoneNumber",						Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("TheActualTrend",						Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("ExplanationOfTheTrend",						Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("PointsInRealTrend",					Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("Status",								Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("ExplanationOfTheStatus",					Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("PatternOfChange",					Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("AreaOfInterest",							Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("InterestAreaProcedure",					Undefined);
	PropertiesOfAnalysisAndTrendZone.Insert("TargetValuesRangesPresentation",			Undefined);
	
	DataSource.Insert("PropertiesOfAnalysisAndTrendZone", PropertiesOfAnalysisAndTrendZone);
	
	StructureOfStatistics = New Structure;
	StructureOfStatistics.Insert("Count",					0);
	StructureOfStatistics.Insert("Min",						0);
	StructureOfStatistics.Insert("Max",					0);
	StructureOfStatistics.Insert("AVG",						0);
	StructureOfStatistics.Insert("Range",						0);
	StructureOfStatistics.Insert("StdDeviation",		0);
	StructureOfStatistics.Insert("Median",						0);
	
	PropertiesOfGeneralStatistics = New Structure;
	PropertiesOfGeneralStatistics.Insert("ByPeriods", StructureOfStatistics);
	PropertiesOfGeneralStatistics.Insert("ByObjectsOfAnalysis", Common.CopyRecursive(StructureOfStatistics));
	
	DataSource.Insert("PropertiesOfGeneralStatistics", PropertiesOfGeneralStatistics);
	
	Return DataSource;
	
EndFunction

Function DataSourceIsEmptyBasedOnResults(DataSourceData)
	CheckResult = True;
	
	If Not DataSourceData = Undefined Then
		DataSourceColumns = DataSourceData.Columns;
		
		For Each DataSourceColumn In DataSourceColumns Do
			ColumnSummary_ = DataSourceData.Total(DataSourceColumn.Name);
			
			If Not ColumnSummary_ = Undefined And Not ColumnSummary_ = 0 Then
				CheckResult = False;
				Break;
			EndIf;
		EndDo; 
	EndIf;
	
	Return CheckResult;
EndFunction

Function GeneralDataSourceStatistics(DataSource)
	
	DataSourceAnalysis = New DataAnalysis;
	DataSourceAnalysis.AnalysisType = Type("DataAnalysisSummaryStatistics");
	DataSourceAnalysis.DataSource = DataSource;
	ResultDataSourceAnalysis = DataSourceAnalysis.Execute();
	
	Return ResultDataSourceAnalysis;
	
EndFunction

// Changes the composition of the data source columns depending on the purpose of the metric.
//
// Parameters:
//		DataSource - See InitializeDataSource
//		AnalysisOption - Structure - Attributes of the analysis option.
//
Procedure PrepareSource(DataSource, AnalysisOption)
	
	TargetValueKindsOfAnalysisOptions	= Enums.TargetValueKindsOfAnalysisOptions;	
	DataSourceColumns				= DataSource.Data.Columns;
	SourceData						= DataSource.Data;
	DateOfLastValue				= DataSource.PropertiesOfDataByPeriod.DateOfLastValue;
	DynamicPropertiesOfAnalysisVariant = DataSource.DynamicPropertiesOfAnalysisVariant;
	
	TypesOfAnalysis	= Enums.IndicatorAnalysisTypes;
	AnalysisType	= AnalysisOption.AnalysisType;
	
	VariantOfAnalysisFromSource = DataSource.AnalysisOption; // Structure
	
	If DataSource.ForTable Then
		// Remove the columns that are not needed for component-by-component comparison
		ColumnsToDelete_ = New Array;
		For Each DataSourceColumn In DataSourceColumns Do 
			ColumnName = DataSourceColumn.Name;
			If Not ColumnName = DynamicPropertiesOfAnalysisVariant.AnalysisValue 
				And Not ColumnName = DynamicPropertiesOfAnalysisVariant.AnalysisObject Then
				ColumnsToDelete_.Add(ColumnName);
			EndIf;
		EndDo;
		For Each ColumnToDelete In ColumnsToDelete_ Do 
			DataSourceColumns.Delete(ColumnToDelete);
		EndDo;
		
	ElsIf AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure 
		And DataSource.CalculationParameters.ComponentWiseComparisonMode = 0 Then
		// Remove the columns that are not needed for component-by-component comparison
		ColumnsToDelete_ = New Array;
		For Each DataSourceColumn In DataSourceColumns Do 
			ColumnName = DataSourceColumn.Name;
			If Not ColumnName = DynamicPropertiesOfAnalysisVariant.AnalysisValue 
				And Not ColumnName = DynamicPropertiesOfAnalysisVariant.AnalysisObject Then
				ColumnsToDelete_.Add(ColumnName);
			EndIf;
		EndDo;
		For Each ColumnToDelete In ColumnsToDelete_ Do 
			DataSourceColumns.Delete(ColumnToDelete);
		EndDo;
		
	ElsIf AnalysisType = TypesOfAnalysis.ChangeTrends
		Or AnalysisType = TypesOfAnalysis.ComponentWiseComparisonTrends
		Or (AnalysisType = TypesOfAnalysis.ComponentWiseComparisonStructure 
			And DataSource.CalculationParameters.ComponentWiseComparisonMode = 1)Then
		
		TargetValueKind = GetTargetValueView(DateOfLastValue, AnalysisOption);
		
		If TargetValueKind = TargetValueKindsOfAnalysisOptions.Value Then
			ColumnToDelete_ = DataSourceColumns.Find("MaximumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MinimumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
		ElsIf TargetValueKind = TargetValueKindsOfAnalysisOptions.Span Then
			ColumnToDelete_ = DataSourceColumns.Find("TargetValue_");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
		ElsIf TargetValueKind = Undefined Then 
			ColumnToDelete_ = DataSourceColumns.Find("TargetValue_");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MaximumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MinimumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("AdjustedNegativeBorderVariance");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("AdjustedPositiveBorderVariance");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
		EndIf;
		
		ColumnToDelete_ = DataSourceColumns.Find("NegativeBorderVariance");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
		ColumnToDelete_ = DataSourceColumns.Find("PositiveBorderVariance");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
		If AnalysisType = TypesOfAnalysis.ComponentWiseComparisonTrends Then
			If DataSource.CalculationParameters.ComponentWiseComparisonMode = 0 Then
				NewSourceData = New ValueTable;
				NewSourceData.Columns.Add("Period", New TypeDescription("Date"));
				
				// Convert series from rows to columns
				TableWithAnalysisObjects = SourceData.Copy(, DynamicPropertiesOfAnalysisVariant.AnalysisObject + "," + DynamicPropertiesOfAnalysisVariant.AnalysisValue);
				TableWithAnalysisObjects.GroupBy(DynamicPropertiesOfAnalysisVariant.AnalysisObject);
				AnalysisObjects = TableWithAnalysisObjects.UnloadColumn(DynamicPropertiesOfAnalysisVariant.AnalysisObject);
				
				// Let's order the columns by their weight
				TableWithAnalysisObjectsInOrder = SourceData.CopyColumns(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "," + DynamicPropertiesOfAnalysisVariant.AnalysisValue);
				For Each AnalysisObject In AnalysisObjects Do 
					SelectionByObjectOfAnalysis = New Structure(DynamicPropertiesOfAnalysisVariant.AnalysisObject, AnalysisObject);
					FoundRows = SourceData.FindRows(SelectionByObjectOfAnalysis);
					
					TemporaryTableForSubtotal = New ValueTable;
					TemporaryTableForSubtotal = SourceData.Copy(FoundRows, DynamicPropertiesOfAnalysisVariant.AnalysisObject + "," + DynamicPropertiesOfAnalysisVariant.AnalysisValue);
					
					If AnalysisOption.ValueCalculationMethod = Enums.CalculationMethodsOfTargetValueAnalysisOptions.Sum Then
						TemporaryTableForSubtotal.GroupBy(DynamicPropertiesOfAnalysisVariant.AnalysisObject, DynamicPropertiesOfAnalysisVariant.AnalysisValue);
						
						NewRow = TableWithAnalysisObjectsInOrder.Add();
						FillPropertyValues(NewRow, TemporaryTableForSubtotal[0]);
					Else
						NewRow = TableWithAnalysisObjectsInOrder.Add();
						FillPropertyValues(NewRow, TemporaryTableForSubtotal[TemporaryTableForSubtotal.Count()-1]);
					EndIf;
				EndDo;
				TableWithAnalysisObjectsInOrder.GroupBy(DynamicPropertiesOfAnalysisVariant.AnalysisObject);
				AnalysisObjects = TableWithAnalysisObjectsInOrder.UnloadColumn(DynamicPropertiesOfAnalysisVariant.AnalysisObject);
				
				// Let's form a hash of values in case the object of analysis is not of a reference type
				TableWithAnalysisObjectsInOrder.Columns.Add("Hash", Common.StringTypeDetails(32));
				For Each StringObjectOfAnalysis In TableWithAnalysisObjectsInOrder Do 
						// Let's form a unique identifier based on the hash
						DataHashing = New DataHashing(HashFunction.MD5);
						DataHashing.Append(Common.ValueToXMLString(StringObjectOfAnalysis[DynamicPropertiesOfAnalysisVariant.AnalysisObject]));
						StringObjectOfAnalysis.Hash = StrReplace(DataHashing.HashSum, " ", "");
						DataHashing = Undefined;
				EndDo;
				
				// Create columns
				For Each StringObjectOfAnalysis In TableWithAnalysisObjectsInOrder Do 
					ValueOfObjectOfAnalysis = StringObjectOfAnalysis[DynamicPropertiesOfAnalysisVariant.AnalysisObject];
					If Not TypeOf(ValueOfObjectOfAnalysis) = Type("Null")
						And (TypeOf(ValueOfObjectOfAnalysis) = Type("String")
						Or Common.ObjectKindByRef(ValueOfObjectOfAnalysis) = "Enum") Then
						UIDOfObjectOfAnalysis = StringObjectOfAnalysis.Hash;
					ElsIf TypeOf(ValueOfObjectOfAnalysis) = Type("Null") Then
						UIDOfObjectOfAnalysis = "NullValue";
					ElsIf TypeOf(ValueOfObjectOfAnalysis) = Type("Undefined") Then
						UIDOfObjectOfAnalysis = "UndefinedValue";
					ElsIf ValueIsFilled(ValueOfObjectOfAnalysis) Then
						UIDOfObjectOfAnalysis = ValueOfObjectOfAnalysis.UUID();
					ElsIf Not ValueIsFilled(ValueOfObjectOfAnalysis) Then
						UIDOfObjectOfAnalysis = "ValueNotFilledIn";
					EndIf;
					YidOfObjectOfAnalysisNormalized = StrReplace(String(UIDOfObjectOfAnalysis), "-", "_");
					NewSourceData.Columns.Add(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + YidOfObjectOfAnalysisNormalized, ,
						String(ValueOfObjectOfAnalysis));
				EndDo;
					
				// Let's create lines with periods
				TableWithPeriods = SourceData.Copy(, "Period");
				TableWithPeriods.GroupBy("Period");
				TableWithPeriods.Sort("Period ASC");
				
				For Each Period In TableWithPeriods Do  
					NewRow = NewSourceData.Add();
					FillPropertyValues(NewRow, Period);
				EndDo;
				
				// Let's move the numbers from the rows to the columns
				For Each DataString1 In SourceData Do 
					ValueOfObjectOfAnalysis = DataString1[DynamicPropertiesOfAnalysisVariant.AnalysisObject];
					If Not TypeOf(ValueOfObjectOfAnalysis) = Type("Null")
						And (TypeOf(ValueOfObjectOfAnalysis) = Type("String")
						Or Common.ObjectKindByRef(ValueOfObjectOfAnalysis) = "Enum") Then
						SelectionByObjectOfAnalysis = New Structure(DynamicPropertiesOfAnalysisVariant.AnalysisObject, ValueOfObjectOfAnalysis);
						FoundHashes = TableWithAnalysisObjectsInOrder.FindRows(SelectionByObjectOfAnalysis);
						
						UIDOfObjectOfAnalysis = FoundHashes[0].Hash;
					ElsIf TypeOf(ValueOfObjectOfAnalysis) = Type("Null") Then
						UIDOfObjectOfAnalysis = "NullValue";
					ElsIf TypeOf(ValueOfObjectOfAnalysis) = Type("Undefined") Then
						UIDOfObjectOfAnalysis = "UndefinedValue";
					ElsIf ValueIsFilled(ValueOfObjectOfAnalysis) Then
						UIDOfObjectOfAnalysis = ValueOfObjectOfAnalysis.UUID();
					ElsIf Not ValueIsFilled(ValueOfObjectOfAnalysis) Then
						UIDOfObjectOfAnalysis = "ValueNotFilledIn";
					EndIf;
					
					YidOfObjectOfAnalysisNormalized = StrReplace(String(UIDOfObjectOfAnalysis), "-", "_");
					
					PeriodString_ = NewSourceData.Find(DataString1.Period, "Period");
					PeriodString_[DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + YidOfObjectOfAnalysisNormalized] = DataString1[DynamicPropertiesOfAnalysisVariant.AnalysisValue];
				EndDo;
				
				SearchColumn = NewSourceData.Columns.Find(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + "NullValue");
				If SearchColumn <> Undefined
					And NewSourceData.Total(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + "NullValue") = 0 Then 
					NewSourceData.Columns.Delete(NewSourceData.Columns.IndexOf(SearchColumn));
				EndIf;
				SearchColumn = NewSourceData.Columns.Find(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + "UndefinedValue");
				If SearchColumn <> Undefined
					And NewSourceData.Total(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + "UndefinedValue") = 0 Then 
					NewSourceData.Columns.Delete(NewSourceData.Columns.IndexOf(SearchColumn));
				EndIf;
				SearchColumn = NewSourceData.Columns.Find(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + "ValueNotFilledIn");
				If SearchColumn <> Undefined
					And NewSourceData.Total(DynamicPropertiesOfAnalysisVariant.AnalysisObject + "__" + "ValueNotFilledIn") = 0 Then 
					NewSourceData.Columns.Delete(NewSourceData.Columns.IndexOf(SearchColumn));
				EndIf;
				
				SourceData = NewSourceData.Copy();
				
				DataSource.Data = SourceData;
			Else
				ColumnToDelete_ = DataSourceColumns.Find("TargetValue_");
				If Not ColumnToDelete_ = Undefined Then
					DataSourceColumns.Delete(ColumnToDelete_);
				EndIf;
				
				ColumnToDelete_ = DataSourceColumns.Find("AdjustedNegativeBorderVariance");
				If Not ColumnToDelete_ = Undefined Then
					DataSourceColumns.Delete(ColumnToDelete_);
				EndIf;
				
				ColumnToDelete_ = DataSourceColumns.Find("AdjustedPositiveBorderVariance");
				If Not ColumnToDelete_ = Undefined Then
					DataSourceColumns.Delete(ColumnToDelete_);
				EndIf;
			EndIf;
		EndIf;
	ElsIf AnalysisType = TypesOfAnalysis.MeasureCurrentValue Then
		TargetValueKind = GetTargetValueView(DateOfLastValue, AnalysisOption);
		
		If TargetValueKind = TargetValueKindsOfAnalysisOptions.Value Then
			ColumnToDelete_ = DataSourceColumns.Find("MaximumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MinimumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
		ElsIf TargetValueKind = TargetValueKindsOfAnalysisOptions.Span Then
			ColumnToDelete_ = DataSourceColumns.Find("TargetValue_");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MaximumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MinimumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
		Else
			ColumnToDelete_ = DataSourceColumns.Find("MaximumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("MinimumTargetRange");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
			
			ColumnToDelete_ = DataSourceColumns.Find("TargetValue_");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
		EndIf;
		
		ColumnToDelete_ = DataSourceColumns.Find("PositiveBorderVariance");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
		ColumnToDelete_ = DataSourceColumns.Find("NegativeBorderVariance");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
		// For the measurement chart, we will leave only the last actual value
		SelectionByDate_1 = New Structure("Period", BegOfDay(DateOfLastValue));
		RowsArray = SourceData.FindRows(SelectionByDate_1);
		DataSource.Data = SourceData.Copy(RowsArray);
		
		// Let's transfer individual values to the source structure
		DataSourceColumns = DataSource.Data.Columns;
		
		ColumnToDelete_ = DataSourceColumns.Find("AdjustedNegativeBorderVariance");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
		ColumnToDelete_ = DataSourceColumns.Find("AdjustedPositiveBorderVariance");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
		If AnalysisOption.CalculateForecast Then
			ColumnToDelete_ = DataSourceColumns.Find("Prediction");
			If Not ColumnToDelete_ = Undefined Then
				DataSourceColumns.Delete(ColumnToDelete_);
			EndIf;
		EndIf;
		
		ColumnToDelete_ = DataSourceColumns.Find("TargetValue_");
		If Not ColumnToDelete_ = Undefined Then
			DataSourceColumns.Delete(ColumnToDelete_);
		EndIf;
		
	ElsIf AnalysisType = TypesOfAnalysis.ComparisonWithPreviousPeriod Then 
		
		// For comparison with past periods, we will re-fill the data
		// based on the current and previous values.
		DataForComparingPeriods = New ValueTable;
		DataColumns = DataForComparingPeriods.Columns;
		
		ColumnPresentation = NStr("vi = 'Kỳ so sánh';
									|ru = 'Период сравнения';
									|en = 'Comparison period'; fa = 'دوره مقایسه';
									|it = 'Periodo di confronto';
									|pl = 'Okres porównawczy';
									|tr = 'Karşılaştırma dönemi'");
		DataColumns.Add("ComparisonPeriod",, ColumnPresentation);
		
		ColumnPresentation = DynamicPropertiesOfAnalysisVariant.AnalysisValuePresentation;
		DataColumns.Add(DynamicPropertiesOfAnalysisVariant.AnalysisValue,
			Common.TypeDescriptionNumber(31,3),
			ColumnPresentation);
		
		ColumnPresentation = NStr("vi = 'Giá trị mục tiêu';
									|ru = 'Целевое значение';
									|en = 'Target value'; fa = 'مقدار هدف';
									|it = 'Valore obiettivo';
									|pl = 'Wartość docelowa';
									|tr = 'Hedef değer'");
		DataColumns.Add("TargetValue_",
			Common.TypeDescriptionNumber(31,3),
			ColumnPresentation);
		
		ColumnPresentation = NStr("vi = 'Độ lệch dương biên đã nhập';
									|ru = 'Приведенное граничное позитивное отклонение';
									|en = 'Adjusted positive border variance'; fa = 'انحراف مرز مثبت تعدیل‌شده';
									|it = 'Alterazione positiva di confine riportata';
									|pl = 'Zadane graniczne odchylenie dodatnie';
									|tr = 'Verilen sınır pozitif sapması'");
		DataColumns.Add("AdjustedPositiveBorderVariance",
			Common.TypeDescriptionNumber(31,3),
			ColumnPresentation);
		
		ColumnPresentation = NStr("vi = 'Độ lệch âm biên đã nhập';
									|ru = 'Приведенное граничное негативное отклонение';
									|en = 'Adjusted negative border variance'; fa = 'انحراف مرز منفی تعدیل‌شده';
									|it = 'Alterazione negativa di confine riportata';
									|pl = 'Zadane graniczne odchylenie ujemne';
									|tr = 'Verilen sınır negatif sapması'");
		DataColumns.Add("AdjustedNegativeBorderVariance",
			Common.TypeDescriptionNumber(31,3),
			ColumnPresentation);
		
		LastPeriodString = DataForComparingPeriods.Add();
		PresentationOfPastPeriod = PresentationOfStandardPeriod(VariantOfAnalysisFromSource.ComparisonPeriod.Get(), False);
		LastPeriodString.ComparisonPeriod = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trước %1';
				|ru = 'Прошлый %1';
				|en = 'Last %1'; fa = 'Last %1';
				|it = 'Scorso %1';
				|pl = 'Zeszły %1';
				|tr = 'Geçmiş %1'"),
			PresentationOfPastPeriod); 
		LastPeriodString[DynamicPropertiesOfAnalysisVariant.AnalysisValue] = DataSource.PropertiesOfDataForComparisonPeriods.Overall;
		LastPeriodString.TargetValue_ = DataSource.PropertiesOfDataForComparisonPeriods.TargetValue_; 
		LastPeriodString.AdjustedPositiveBorderVariance = DataSource.PropertiesOfDataForComparisonPeriods.AdjustedPositiveBorderVariance; 
		LastPeriodString.AdjustedNegativeBorderVariance = DataSource.PropertiesOfDataForComparisonPeriods.AdjustedNegativeBorderVariance; 
		
		CurPeriodLine = DataForComparingPeriods.Add();
		PresentationOfCurPeriod = PresentationOfStandardPeriod(VariantOfAnalysisFromSource.AnalysisPeriod.Get(), False);
		CurPeriodLine.ComparisonPeriod = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hiện tại %1';
				|ru = 'Текущий %1';
				|en = 'Current %1'; fa = 'Current %1';
				|it = 'Corrente %1';
				|pl = 'Bieżący %1';
				|tr = 'Mevcut %1'"),
			PresentationOfCurPeriod); 
		CurPeriodLine[DynamicPropertiesOfAnalysisVariant.AnalysisValue] = DataSource.PropertiesOfDataByPeriod.Overall;
		CurPeriodLine.TargetValue_ = DataSource.PropertiesOfDataByPeriod.TargetValue_; 
		CurPeriodLine.AdjustedPositiveBorderVariance = DataSource.PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance; 
		CurPeriodLine.AdjustedNegativeBorderVariance = DataSource.PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance; 
		
		If AnalysisOption.CalculateForecast
			And Not DataSource.PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend.IsEmpty Then 
			DateForecast = BegOfDay(OffsetDate_(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
				AnalysisOption.IndicatorCalculationFrequency, 1));
			
			ForecastPeriodLine = DataForComparingPeriods.Add();
			ForecastPeriodLine.ComparisonPeriod = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Dự báo %1';
					|ru = 'Прогноз на %1';
					|en = 'Forecast for %1'; fa = 'Forecast for %1';
					|it = 'Previsione su %1';
					|pl = 'Prognoza na %1';
					|tr = '%1 için tahmin'"),
				Format(DateForecast, "DLF=D;")); 
			ForecastPeriodLine[DynamicPropertiesOfAnalysisVariant.AnalysisValue] = DataSource.Data.Find(DateForecast, "Period").Prediction; 
			ForecastPeriodLine.TargetValue_ = DataSource.PropertiesOfDataByPeriod.TargetValue_; 
			ForecastPeriodLine.AdjustedPositiveBorderVariance = DataSource.PropertiesOfDataByPeriod.AdjustedPositiveBorderVariance; 
			ForecastPeriodLine.AdjustedNegativeBorderVariance = DataSource.PropertiesOfDataByPeriod.AdjustedNegativeBorderVariance; 
			
		EndIf;
		
		DataSource.Data = DataForComparingPeriods;
		
	EndIf;
	
EndProcedure

Function PeriodData_(DataSource, CalculationParameters)
	MultipleValues = (CalculationParameters.ComponentWiseComparisonMode = 1);
	
	ConvolutionFieldNames = "Period, TargetValue_, MaximumTargetRange, MinimumTargetRange, PositiveBorderVariance";
	ConvolutionFieldNames = ConvolutionFieldNames + ", NegativeBorderVariance, AdjustedPositiveBorderVariance, AdjustedNegativeBorderVariance";
		
	PeriodData_ = DataSource.Data.Copy();
	PeriodData_.GroupBy(ConvolutionFieldNames, CalculationParameters.AnalysisValueFieldName);
		
	If MultipleValues Then
		
		AdditionalFieldData = DataSource.Data.Copy(); // ValueTable - 
		AdditionalFieldData.GroupBy(ConvolutionFieldNames, CalculationParameters.AnalysisValueAdditionalFieldName);
		TableColumn2 = AdditionalFieldData.Columns[CalculationParameters.AnalysisValueAdditionalFieldName]; // ValueTableColumn - 
		TableColumn2.Name = CalculationParameters.AnalysisValueFieldName;
		
		// Let's move the data of the additional field to the main column
		For Each DataStringForField In AdditionalFieldData Do 
			NewExtraLine = PeriodData_.Add();
			FillPropertyValues(NewExtraLine, DataStringForField);
		EndDo;
		
	EndIf;
	
	PeriodData_.Sort("Period");
	
	Return PeriodData_;
EndFunction

Function MonitoringCorrectnessOfSettingsAndData(TypeOfObjectToCheck, ObjectToCheck, DataSource, CalculationParameters)
	CheckResult = True;
	
	AnalysisOption = CalculationParameters.AnalysisOption; // CatalogRef.AnalysisOptionsOfTargetValues, CatalogObject.AnalysisOptionsOfTargetValues -
	AnalysisPeriod = CalculationParameters.AnalysisPeriod;
	IndicatorCalculationFrequency = CalculationParameters.IndicatorCalculationFrequency;
		
	If TypeOfObjectToCheck = "DataCompositionSchema"
		And ObjectToCheck = Undefined Then
		DataSource.IsEmpty = True;
		DataSource.CalculationError = True;
		DataSource.ErrorDescription = NStr("vi = 'Chưa xác định khuôn mẫu tính toán';
											|ru = 'Шаблон расчета не определен';
											|en = 'Calculation template is not determined'; fa = 'Calculation template is not determined';
											|it = 'Modello di contabilizzazione non definito';
											|pl = 'Szablon obliczenia nie jest określony';
											|tr = 'Hesaplama numunesi belirlenmedi'");
		
		CheckResult = False;
	EndIf;
	
	If TypeOfObjectToCheck = "DataLayoutTemplateSettings"
		And ObjectToCheck.DataCompositionTemplate = Undefined Then
		
		DataSource.IsEmpty = True;
		DataSource.CalculationError = True;
		DataSource.ErrorDescription = ObjectToCheck.ErrorInformation_;
		
		PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
		PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
		PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate), IndicatorCalculationFrequency, -1);
		PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
		
		// Let's define the analysis zones, status, trend
		PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
		FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
		
		CheckResult = False;
	EndIf;
	
	If TypeOfObjectToCheck = "DataAcquisitionResult"
		And ObjectToCheck.Data = Undefined Then
		
		DataSource.IsEmpty = True;
		DataSource.CalculationError = True;
		DataSource.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Mẫu tính toán không hợp lệ: %1';
				|ru = 'Неверный шаблон расчета: %1';
				|en = 'Incorrect calculation template: %1'; fa = 'Incorrect calculation template: %1';
				|it = 'Modello di contabilizzazione errato: %1';
				|pl = 'Błędny szablon obliczenia: %1';
				|tr = 'Yanlış hesaplama numunesi: %1'"),
			ObjectToCheck.ErrorInformation_);
		
		PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
		PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
		PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate),
				IndicatorCalculationFrequency,
				-1);
		PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
		
		// Let's define the analysis zones, status, trend
		PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
		FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
		
		CheckResult = False;
	EndIf;
	
	If TypeOfObjectToCheck = "Data" Then
		If ObjectToCheck = Undefined Then
			DataSource.IsEmpty = True;
			DataSource.CalculationError = True;
			DataSource.ErrorDescription = NStr("vi = 'Sai khuôn mẫu tính toán';
												|ru = 'Неверный шаблон расчета';
												|en = 'Incorrect calculation template'; fa = 'Incorrect calculation template';
												|it = 'Modello di contabilizzazione errato';
												|pl = 'Błędny szablon obliczenia';
												|tr = 'Yanlış hesaplama numunesi'");
			
			PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
			PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
			PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate),
					IndicatorCalculationFrequency,
					-1);
			PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
			
			// Let's define the analysis zones, status, trend
			PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
			FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
			
			CheckResult = False;
		ElsIf Not ObjectToCheck = Undefined 
			And (DataSourceIsEmptyBasedOnResults(ObjectToCheck) Or ObjectToCheck.Count() = 0) Then 
			
			DataSource.IsEmpty = True;
			DataSource.CalculationError = True;
			DataSource.ErrorDescription = NStr("vi = 'Không đủ dữ liệu để hiển thị. 
				|Hãy kiểm tra tùy chỉnh phương án phân tích.';
				|ru = 'Недостаточно данных для отображения. 
				|Проверьте настройки варианта анализа.';
				|en = 'Insufficient data to display. 
				|Check analysis option settings.'; fa = 'Insufficient data to display. 
				|Check analysis option settings.';
				|it = 'Dati insufficienti per la visualizzazione. 
				|Controllate le impostazioni della variante dell''analisi.';
				|pl = 'Nie wystarcza danych do odzwierciedlenia. 
				|Sprawdź ustawienia wariantu analizy.';
				|tr = 'Görüntülenme için yeterli veri yok. 
				|Analiz seçeneği ayarlarını kontrol et.'");
			
			DataSource.Data = New ValueTable;
			
			PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
			PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
			PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate), IndicatorCalculationFrequency, -1);
			PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
			
			FillInInformationAboutSetGoals(PropertiesOfDataByPeriod,
				TargetValuesOfAnalysisVariant(AnalysisOption, PropertiesOfDataByPeriod.DateOfLastValue),
				AnalysisOption);
			
			// Let's define the analysis zones, status, trend
			PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
			FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
			
			CheckResult = False;
		EndIf;
	EndIf;
	
	// Let's check the relevance of the business data of the calculation.
	// If the calculations are not relevant, for example, the sequences are broken - the calculation stops.
	If TypeOfObjectToCheck = "SettlementsRelevance" Then
		CalculationRelevanceColumn = DataSource.Data.Columns.Find("CalculationsAreRelevant");
		If Not CalculationRelevanceColumn = Undefined Then
			RelevanceSelection = New Structure("CalculationsAreRelevant", True);
			FoundRelevanceLines = DataSource.Data.FindRows(RelevanceSelection);
			
			If FoundRelevanceLines.Count() > 0 Then
				DataSource.CalculationsAreRelevant = True;
				DataSource.Data.Delete(FoundRelevanceLines[0]);
			EndIf;
			
			RelevanceSelection = New Structure("CalculationsAreRelevant", False);
			FoundRowsAreNotRelevant = DataSource.Data.FindRows(RelevanceSelection);
			
			If FoundRowsAreNotRelevant.Count() > 0 Then
				DataSource.CalculationsAreRelevant = False;
				DataSource.Data.Delete(FoundRowsAreNotRelevant[0]);
			EndIf;
			
			If Not DataSource.CalculationsAreRelevant Then
				DataSource.Data = New ValueTable;
				DataSource.CalculationError = True;
				DataSource.ErrorDescription = NStr("vi = 'Dữ liệu không thiết thực';
													|ru = 'Данные не актуальны';
													|en = 'Data is irrelevant'; fa = 'Data is irrelevant';
													|it = 'Dati non attuali';
													|pl = 'Dane nie są aktualne';
													|tr = 'Veriler güncel değil'");
				
				PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
				PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
				PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate),
						IndicatorCalculationFrequency,
						-1);
				PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
				
				FillInInformationAboutSetGoals(PropertiesOfDataByPeriod,
					TargetValuesOfAnalysisVariant(AnalysisOption, PropertiesOfDataByPeriod.DateOfLastValue),
					AnalysisOption);
				
				// Let's define the analysis zones, status, trend
				PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
				FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
				
				CheckResult = False;
			EndIf;
		EndIf;
	EndIf;
	
	If TypeOfObjectToCheck = "AnalysisObject" 
		And ObjectToCheck = Undefined Then
		
		DataSource.IsEmpty = True;
		DataSource.CalculationError = True;
		DataSource.ErrorDescription = NStr("vi = 'Đối tượng phân tích không tìm thấy trong khuôn mẫu tính toán';
											|ru = 'Объект анализа не найден в шаблоне расчета';
											|en = 'Analysis object is not found in the calculation template'; fa = 'Analysis object is not found in the calculation template';
											|it = 'L''oggetto dell''analisi non è trovato nel modello di contabilizzazione';
											|pl = 'Obiekt analizy nie znaleziono w szablonie obliczenia';
											|tr = 'Hesaplama numunesinde analiz nesnesi bulunamadı'");
		
		PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
		PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
		PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate),
				IndicatorCalculationFrequency,
				-1);
		PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
		
		// Let's define the analysis zones, status, trend
		PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
		FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
		
		CheckResult = False;
	EndIf;
	
	If TypeOfObjectToCheck = "AnalysisValue"
		And ObjectToCheck = Undefined Then
		
		DataSource.IsEmpty = True;
		DataSource.CalculationError = True;
		DataSource.ErrorDescription = NStr("vi = 'Giá trị phân tích không tìm thấy trong khuôn mẫu tính toán';
											|ru = 'Значение анализа не найдено в шаблоне расчета';
											|en = 'Analysis value is not found in the calculation template'; fa = 'Analysis value is not found in the calculation template';
											|it = 'Il valore dell''analisi non è trovato nel modello di contabilizzazione';
											|pl = 'Wartość analizy nie znaleziono w szablonie obliczenia';
											|tr = 'Hesaplama numunesinde analiz değeri bulunamadı'");
		
		PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
		PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
		PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate),
				IndicatorCalculationFrequency,
				-1);
		PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
		
		// Let's define the analysis zones, status, trend
		PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
		FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
		
		CheckResult = False;
	EndIf; 
	
	If TypeOfObjectToCheck = "AnalysisValueAdditional"
		And ObjectToCheck = Undefined Then
		
		DataSource.IsEmpty = True;
		DataSource.CalculationError = True;
		DataSource.ErrorDescription = NStr("vi = 'Không tìm thấy giá trị phân tích bổ sung trong mẫu tính toán';
											|ru = 'Дополнительное значение анализа не найдено в шаблоне расчета';
											|en = 'Additional analysis value is not found in the calculation template'; fa = 'Additional analysis value is not found in the calculation template';
											|it = 'Il valore aggiuntivo dell''analisi non è trovato nel modello di contabilizzazione';
											|pl = 'Dodatkowa wartość analizy nie znaleziona w szablonie obliczenia';
											|tr = 'Hesaplama numunesinde ek analiz değeri bulunamadı'");
		
		PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
		PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
		PropertiesOfDataByPeriod.DateOfPenultimateValue = OffsetDate_(BegOfDay(AnalysisPeriod.EndDate),
				IndicatorCalculationFrequency,
				-1);
		PropertiesOfDataByPeriod.DateOfLastValue = BegOfDay(AnalysisPeriod.EndDate);
		
		// Let's define the analysis zones, status, trend
		PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
		FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(AnalysisOption, DataSource));
		
		CheckResult = False;
	EndIf; 
	
	Return CheckResult;
EndFunction

Procedure FillAnalysisZonesAndTrend(DataSource, CalculationParameters)
	PropertiesOfAnalysisAndTrendZone = DataSource.PropertiesOfAnalysisAndTrendZone;
	FillPropertyValues(PropertiesOfAnalysisAndTrendZone, PropertiesOfAnalysisZone(CalculationParameters.AnalysisOption, DataSource));
EndProcedure

Procedure AddForecastToData(DataSource, CalculationParameters)
	AnalysisPeriod = CalculationParameters.AnalysisPeriod;
	IndicatorCalculationFrequency = CalculationParameters.IndicatorCalculationFrequency;
	AnalysisValueFieldName = CalculationParameters.AnalysisValueFieldName;
	ForecastHorizon = CalculationParameters.ForecastHorizon;
	ForecastAnalysisDepth = CalculationParameters.ForecastAnalysisDepth;
	
	If CalculationParameters.AddForecast Then
		// Adding forecast data
		If IndicatorCalculationFrequency = Enums.Periodicity.Year Then
			StartDate = BegOfYear(OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon));
		ElsIf IndicatorCalculationFrequency = Enums.Periodicity.HalfYear Then
			StartDate = OffsetDate_(BegOfQuarter(OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon)), Enums.Periodicity.Quarter, -1);
		ElsIf IndicatorCalculationFrequency = Enums.Periodicity.Quarter Then
			StartDate = BegOfQuarter(OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon));
		ElsIf IndicatorCalculationFrequency = Enums.Periodicity.Month Then
			StartDate = BegOfMonth(OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon));
		ElsIf IndicatorCalculationFrequency = Enums.Periodicity.TenDays Then
			StartDate = OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon);
		ElsIf IndicatorCalculationFrequency = Enums.Periodicity.Week Then
			StartDate = BegOfWeek(OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon));
		ElsIf IndicatorCalculationFrequency = Enums.Periodicity.Day Then
			StartDate = BegOfDay(OffsetDate_(AnalysisPeriod.EndDate, IndicatorCalculationFrequency, -ForecastHorizon));
		EndIf;
		
		StepPeriods = 1;
		Basis = New Structure("StartDate, Period, NumberOfPeriods", StartDate, IndicatorCalculationFrequency, StepPeriods);
		
		ForecastCalculationParameters = New Structure; 
		
		ForecastCalculationParameters.Insert("ColumnX", "Period");
		ForecastCalculationParameters.Insert("ColumnY", AnalysisValueFieldName);
		ForecastCalculationParameters.Insert("AttributeColumn", "Flag");
		ForecastCalculationParameters.Insert("Basis", Basis);
		
		ForecastCalculationParameters.Insert("AnalysisDepth", ForecastAnalysisDepth);
		ForecastCalculationParameters.Insert("Offset", ForecastHorizon);
		ForecastCalculationParameters.Insert("ToSupplementTable", True);
		ForecastCalculationParameters.Insert("Prediction", True);
		
		StatisticalParametersOfTrend = GenerateForecastValuesForDataSource(DataSource, ForecastCalculationParameters);
		
		// Fill in the statistical properties of the forecast data
		PropertiesOfDataForecastByPeriod = DataSource.PropertiesOfDataForecastByPeriod;
		PropertiesOfDataForecastByPeriod.Periodicity = IndicatorCalculationFrequency;
		PropertiesOfDataForecastByPeriod.Offset = ForecastHorizon;
		PropertiesOfDataForecastByPeriod.StartDate = StartDate;
		PropertiesOfDataForecastByPeriod.NumberOfPeriods = StepPeriods;
		PropertiesOfDataForecastByPeriod.Basis = Basis;
		PropertiesOfDataForecastByPeriod.AnalysisDepth = ForecastAnalysisDepth;
		PropertiesOfDataForecastByPeriod.ToSupplementTable = ForecastCalculationParameters.ToSupplementTable;
		PropertiesOfDataForecastByPeriod.StatisticalParametersOfTrend = StatisticalParametersOfTrend;
	EndIf;
EndProcedure

Procedure FillInSummaryInformationAboutDataSource(DataSource, CalculationParameters)
	AnalysisOption = CalculationParameters.AnalysisOption;
	AnalysisPeriod = CalculationParameters.AnalysisPeriod;
	ComparisonPeriod = CalculationParameters.ComparisonPeriod;
	IndicatorCalculationFrequency = CalculationParameters.IndicatorCalculationFrequency;
	AnalysisValueFieldName = CalculationParameters.AnalysisValueFieldName;
	AnalysisObjectFieldName = CalculationParameters.AnalysisObjectFieldName;
	ThereIsComparison = CalculationParameters.ThereIsComparison;
	ForecastHorizon = CalculationParameters.ForecastHorizon;
	
	PeriodData_ = PeriodData_(DataSource, CalculationParameters);
	
	// Fill in the summary information by period
	PropertiesOfDataByPeriod = DataSource.PropertiesOfDataByPeriod;
	PropertiesOfDataByPeriod.DateOfFirstValue = AnalysisPeriod.StartDate;
	NumberOfDataRows = PeriodData_.Count();
	If Not IsBlankString(PeriodData_[NumberOfDataRows - 1 - ForecastHorizon].Period) Then
		PropertiesOfDataByPeriod.DateOfLastValue = PeriodData_[NumberOfDataRows - 1 - ForecastHorizon].Period;
	EndIf;
	If NumberOfDataRows > (1 + ForecastHorizon) And Not IsBlankString(PeriodData_[NumberOfDataRows - 2 - ForecastHorizon].Period) Then
		PropertiesOfDataByPeriod.DateOfPenultimateValue = PeriodData_[NumberOfDataRows - 2 - ForecastHorizon].Period;
	EndIf;
	
	StringWithLatestValues = PeriodData_.Find(PropertiesOfDataByPeriod.DateOfLastValue, "Period");
	PropertiesOfDataByPeriod.FirstValue = PeriodData_[0][AnalysisValueFieldName];
	
	PenultimateValueString = PeriodData_.Find(PropertiesOfDataByPeriod.DateOfPenultimateValue, "Period");
	If Not PenultimateValueString = Undefined Then 
		PropertiesOfDataByPeriod.PenultimateValue = PenultimateValueString[AnalysisValueFieldName];
	Else
		PropertiesOfDataByPeriod.PenultimateValue = StringWithLatestValues[AnalysisValueFieldName];
	EndIf;
	
	PropertiesOfDataByPeriod.LastValue = StringWithLatestValues[AnalysisValueFieldName];
	PropertiesOfDataByPeriod.Overall = PropertiesOfDataByPeriod.LastValue;
	
	// Fill in the information about the target values for the last calculation period
	FillInInformationAboutSetGoals(PropertiesOfDataByPeriod, StringWithLatestValues, AnalysisOption);
	
	// Let's fill in the statistical properties of the data for the comparison periods
	If ThereIsComparison Then
		PropertiesOfDataForComparisonPeriods = DataSource.PropertiesOfDataForComparisonPeriods;
		PropertiesOfDataForComparisonPeriods.DateOfFirstValue = ComparisonPeriod.StartDate;
		PropertiesOfDataForComparisonPeriods.DateOfLastValue = BeginOfPeriod(ComparisonPeriod.EndDate, IndicatorCalculationFrequency);
		PropertiesOfDataForComparisonPeriods.DateOfPenultimateValue = OffsetDate_(PropertiesOfDataForComparisonPeriods.DateOfLastValue, IndicatorCalculationFrequency, -1);
		
		StringWithLatestValues = PeriodData_.Find(PropertiesOfDataForComparisonPeriods.DateOfLastValue, "Period");
		
		PropertiesOfDataForComparisonPeriods.FirstValue = PeriodData_.Find(PropertiesOfDataForComparisonPeriods.DateOfFirstValue, "Period")[AnalysisValueFieldName];
		PropertiesOfDataForComparisonPeriods.LastValue = StringWithLatestValues[AnalysisValueFieldName];
		PropertiesOfDataForComparisonPeriods.Overall = PropertiesOfDataForComparisonPeriods.LastValue;
		
		FillInInformationAboutSetGoals(PropertiesOfDataForComparisonPeriods, StringWithLatestValues, AnalysisOption);
	EndIf;
	
	// Fill in the properties of the general statistics
	PropertiesOfGeneralStatistics = DataSource.PropertiesOfGeneralStatistics;
	GeneralStatisticsByPeriod = GeneralDataSourceStatistics(PeriodData_);
		
	FillPropertyValues(PropertiesOfGeneralStatistics.ByPeriods, GeneralStatisticsByPeriod.ContiguousFields[AnalysisValueFieldName]);
	
	If (CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ComponentWiseComparisonStructure
		Or CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ComponentWiseComparisonTrends)
		And CalculationParameters.ComponentWiseComparisonMode = 0 Then
		
		// Delete the data for the statistics for the period
		If DataSource.Data.Count() > 1 Then
			SelectionForEmptyObjectOfAnalysis = New Structure(AnalysisObjectFieldName, Undefined);
			FoundRows = DataSource.Data.FindRows(SelectionForEmptyObjectOfAnalysis);
			
			For Each FoundRow In FoundRows Do 
				DataSource.Data.Delete(FoundRow);
			EndDo;
			
			SelectionForEmptyObjectOfAnalysis = New Structure(AnalysisObjectFieldName, "");
			FoundRows = DataSource.Data.FindRows(SelectionForEmptyObjectOfAnalysis);
			
			For Each FoundRow In FoundRows Do 
				DataSource.Data.Delete(FoundRow);
			EndDo;
		EndIf;
		
		DataOnAnalysisObjects = DataSource.Data.Copy();
		DataOnAnalysisObjects.Columns.Delete("Period");
		
		// Fill in the statistical properties of the data on the objects of analysis
		IndicatorValueColumn = DataOnAnalysisObjects.Columns[AnalysisValueFieldName];
		FractionDigits = IndicatorValueColumn.ValueType.NumberQualifiers.FractionDigits;
		
		GeneralStatistics = GeneralDataSourceStatistics(DataOnAnalysisObjects);
		
		ContinuousField = GeneralStatistics.ContiguousFields[AnalysisValueFieldName]; // DataAnalysisContiguousFieldInformation -
		MaxValue = Round(ContinuousField.Maximum, FractionDigits);
		StringWithMaximumValue = DataOnAnalysisObjects.Find(MaxValue, AnalysisValueFieldName);
		
		MinValue = Round(ContinuousField.Minimum, FractionDigits);
		StringWithMinimumValue = DataOnAnalysisObjects.Find(MinValue, AnalysisValueFieldName);
		
		PropertiesOfDataForAnalysisObjects = DataSource.PropertiesOfDataForAnalysisObjects;
		If Not StringWithMaximumValue = Undefined Then
			PropertiesOfDataForAnalysisObjects.ObjectOfAnalysisMaximum = StringWithMaximumValue[AnalysisObjectFieldName];
		EndIf;
		If Not StringWithMinimumValue = Undefined Then
			PropertiesOfDataForAnalysisObjects.ObjectOfAnalysisMinimum = StringWithMinimumValue[AnalysisObjectFieldName];
		EndIf;
		PropertiesOfDataForAnalysisObjects.MaxValue = MaxValue;
		PropertiesOfDataForAnalysisObjects.MinValue = MinValue;
		
		FillPropertyValues(PropertiesOfGeneralStatistics.ByObjectsOfAnalysis, ContinuousField);
	EndIf;
EndProcedure

Procedure CollapseData(DataSource, CalculationParameters)
	If CalculationParameters.ViewOption = CalculationParameters.DisplayOptions.Table Then
		DataSource.Data.GroupBy(CalculationParameters.AnalysisObjectFieldName + 
			", Period, TargetValue_, MaximumTargetRange, MinimumTargetRange, PositiveBorderVariance, NegativeBorderVariance, AdjustedPositiveBorderVariance, AdjustedNegativeBorderVariance", 
			CalculationParameters.AnalysisValueFieldName);
	ElsIf CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ComponentWiseComparisonTrends
		Or CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ComponentWiseComparisonStructure Then
		
		If CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ComponentWiseComparisonTrends Then
			SelectionForEmptyPeriods = New Structure("Period", Undefined);
			EmptyPeriodsFound = DataSource.Data.FindRows(SelectionForEmptyPeriods);
			
			For Each StringWithEmptyPeriod In EmptyPeriodsFound Do 
				DataSource.Data.Delete(StringWithEmptyPeriod);
			EndDo;
			
			#Region BypassingCollapseOfPeriodTable
			// Bypassing the "collapse" of the period table in a nested grouping
			If CalculationParameters.ComponentWiseComparisonMode = 0 Then // By Analytics
				SelectionOfAuxiliaryPeriods = New Structure(CalculationParameters.AnalysisObjectFieldName, Undefined);
				FoundAuxiliaryPeriods = DataSource.Data.FindRows(SelectionOfAuxiliaryPeriods);
				
				For Each AuxiliaryPeriodString In FoundAuxiliaryPeriods Do 
					SelectingRowsByPeriod = New Structure("Period", AuxiliaryPeriodString.Period);
					DataFound = DataSource.Data.FindRows(SelectingRowsByPeriod);
					
					For Each DataString1 In DataFound Do 
						FillPropertyValues(DataString1, AuxiliaryPeriodString,
							"Period, 
							|TargetValue_, 
							|MaximumTargetRange, 
							|MinimumTargetRange, 
							|PositiveBorderVariance, 
							|NegativeBorderVariance, 
							|AdjustedPositiveBorderVariance, 
							|AdjustedNegativeBorderVariance");
					EndDo;
				EndDo;
				
				For Each AuxiliaryPeriodString In FoundAuxiliaryPeriods Do 
					DataSource.Data.Delete(AuxiliaryPeriodString);
				EndDo;
			EndIf;
			#EndRegion
		EndIf;
		
		If CalculationParameters.ComponentWiseComparisonMode = 0 Then
			DataSource.Data.GroupBy(CalculationParameters.AnalysisObjectFieldName + 
				", Period, TargetValue_, MaximumTargetRange, MinimumTargetRange, PositiveBorderVariance, NegativeBorderVariance, AdjustedPositiveBorderVariance, AdjustedNegativeBorderVariance", 
				CalculationParameters.AnalysisValueFieldName);
		Else
			DataSource.Data.GroupBy("Period, TargetValue_, MaximumTargetRange, MinimumTargetRange, PositiveBorderVariance, NegativeBorderVariance, AdjustedPositiveBorderVariance, AdjustedNegativeBorderVariance", 
				CalculationParameters.AnalysisValueFieldName + ", " + CalculationParameters.AnalysisValueAdditionalFieldName);
		EndIf;
	Else
		DataSource.Data.GroupBy(
			"Period, TargetValue_, MaximumTargetRange, MinimumTargetRange, PositiveBorderVariance, NegativeBorderVariance, AdjustedPositiveBorderVariance, AdjustedNegativeBorderVariance", 
			CalculationParameters.AnalysisValueFieldName);
	EndIf;
EndProcedure

Function DataAcquisitionResult(DataCompositionTemplate, PeriodsTable)
	DataAcquisitionResult = New Structure("Data, ErrorInformation_");
	Data = Undefined;
	
	ExternalDataSets = New Structure("PeriodsTable", PeriodsTable);
	
	CompositionProcessor = New DataCompositionProcessor;
	Try
		CompositionProcessor.Initialize(DataCompositionTemplate, ExternalDataSets,, True);
	Except
		DataAcquisitionResult.ErrorInformation_ = BriefErrorDescription(ErrorInfo());
		
		Return DataAcquisitionResult;
	EndTry; 
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Try
		Data = OutputProcessor.Output(CompositionProcessor);
	Except
		DataAcquisitionResult.ErrorInformation_ = BriefErrorDescription(ErrorInfo());
		
		Return DataAcquisitionResult;
	EndTry;
	
	DataAcquisitionResult.Data = Data;
	
	Return DataAcquisitionResult;
EndFunction

Function DataLayoutTemplateSettingsForCalculation(DataCompositionSchema, SettingsComposer)
	DataLayoutTemplateSettings = New Structure("DataCompositionTemplate, ErrorInformation_");
	DataCompositionTemplate = Undefined;
	
	DataCompositionSettings = SettingsComposer.GetSettings();
	
	DCTemplateComposer = New DataCompositionTemplateComposer;
	Try
		DataCompositionTemplate = DCTemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings,,, Type("DataCompositionValueCollectionTemplateGenerator")); 
	Except
		DataLayoutTemplateSettings.ErrorInformation_ = BriefErrorDescription(ErrorInfo());
		
		Return DataLayoutTemplateSettings;
	EndTry;
	
	// Let's establish an external connection so that all the data in the period table gets into the result
	DataSetLinks = DataCompositionTemplate.DataSetLinks;
	For Each DataSetCommunication In DataSetLinks Do 
		If DataSetCommunication.SourceDataSet = "PeriodsTable"
			And DataSetCommunication.DestinationDataSet = "DataForAnalysis" Then
			DataSetCommunication.LinkType = DataCompositionDataSetsLinkType.Outer;
		EndIf;
	EndDo;
	
	// Let's check the correctness of the SKD
	ResultOfCheckingDataLayoutScheme = CheckDataLayoutScheme(DataCompositionSchema);
	If Not ResultOfCheckingDataLayoutScheme.CorrectTemplate Then
		DataCompositionTemplate = Undefined;
		
		For Each ErrorDescription In ResultOfCheckingDataLayoutScheme.ErrorsDescription Do 
			DataLayoutTemplateSettings.ErrorInformation_ = String(DataLayoutTemplateSettings.ErrorInformation_) + ErrorDescription + Chars.LF;
		EndDo;
	EndIf;
	
	DataLayoutTemplateSettings.DataCompositionTemplate = DataCompositionTemplate;
	
	Return DataLayoutTemplateSettings;
EndFunction

Function ComposerSettingsForCalculation(DataCompositionSchema, CalculationParameters, DynamicParameters)
	Addresses = CalculationParameters.Addresses;
	
	If Not Addresses.DataCompositionSettings = Undefined Then
		DataCompositionSettings = GetFromTempStorage(Addresses.DataCompositionSettings);
	Else
		DataCompositionSettings = Undefined;
	EndIf;
	
	If Not Addresses.UserSettings = Undefined Then 
		UserSettings = GetFromTempStorage(Addresses.UserSettings);
	Else
		UserSettings = Undefined;
	EndIf;
	
	URLDataCompositionSchema = PutToTempStorage(DataCompositionSchema, New UUID());
	NewSourceOfAvailableSettings = New DataCompositionAvailableSettingsSource(URLDataCompositionSchema);
	
	// Let's restore the user settings of selections
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(NewSourceOfAvailableSettings);
	If Not DataCompositionSettings = Undefined Then
		SettingsComposer.LoadSettings(DataCompositionSettings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	If Not UserSettings = Undefined Then
		SettingsComposer.LoadUserSettings(UserSettings);
	EndIf;
	
	// Let's check that it is possible to apply a cumulative total for the layout
	If Not DataCompositionClientServer.GetParameter(SettingsComposer, "RunningTotal") = Undefined Then
		DataCompositionSchema.Parameters.RunningTotal.Value = CalculationParameters.ThereIsRunningTotal;
	Else 
		CalculationParameters.ThereIsRunningTotal = False;
	EndIf;
	
	// Setting the values of the currency parameters
	SetReportCurrencyParameters(SettingsComposer, True);
	
	ApplyDisplayOptionSettings(SettingsComposer, CalculationParameters, DynamicParameters);
	
	Return SettingsComposer;
EndFunction

// The procedure sets the associated parameters of the report calculation currency
//
// Parameters:
//		SettingsComposer - DataCompositionSettingsComposer - report settings
//		UserSettingsModified - Boolean - required to install a sign of user modification. report settings.
//
Procedure SetReportCurrencyParameters(SettingsComposer, UserSettingsModified)
	ReportDataParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PaymentData");
	If ReportDataParameter <> Undefined Then
		ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
		DefaultBaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	
		CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "SettlementCurrency");
		If CurrencyParameter <> Undefined Then
			If ReportDataParameter.Value = 1
				Or ReportDataParameter.Value = 2 Then
				DataCompositionClientServer.SetParameter(SettingsComposer, "SettlementCurrency", ManagementAccountingCurrency);
			ElsIf ReportDataParameter.Value = 3 Then
				DataCompositionClientServer.SetParameter(SettingsComposer, "SettlementCurrency", DefaultBaseCurrency);
			ElsIf ReportDataParameter.Value = 0 Then
				DataCompositionClientServer.SetParameter(SettingsComposer, "SettlementCurrency", Catalogs.Currencies.EmptyRef());
			EndIf;
				
			UserSettingsModified = True;
		EndIf;
	EndIf;
EndProcedure



// Returns the layout diagram for calculating the target metric.
// 
// Parameters:
// 	CalculationParameters - See CalculationParameters
// Returns:
// 	DataCompositionSchema - scheme of the layout.
Function DataLayoutDiagramForCalculation(CalculationParameters)
	// Obtaining a scheme with verification of its correctness and existence.
	// If the scheme is not defined, the calculation stops.
	AnalysisOption = CalculationParameters.AnalysisOption; // Structure -
	IndicatorCalculationFrequency = CalculationParameters.IndicatorCalculationFrequency; // EnumRef.Periodicity - 
	AnalysisPeriod = CalculationParameters.AnalysisPeriod;
	ComparisonPeriod = CalculationParameters.ComparisonPeriod;
	
	DataCompositionSchema = GetFromTempStorage(CalculationParameters.Addresses.DataCompositionSchema); // DataCompositionSchema -
	
	If Not DataCompositionSchema = Undefined Then
		DataCompositionServer.SetDCSParameter(DataCompositionSchema, "AnalysisOption", AnalysisOption);
		
		// Setting up the parameters of the scheme related to the interval of calculation of values and the period of the indicator.
		BringTotalFieldExpressionsToSpecifiedPrecision(DataCompositionSchema, AnalysisOption.ValueMultiplier,
			AnalysisOption.FractionalPartCalculationAccuracy);
		SetPeriodOfExpressionsOfTotalsFields(DataCompositionSchema, IndicatorCalculationFrequency);
		
		// For indicators where the comparison period is used, we will set its value
		ComparisonPeriodParameter = DataCompositionServer.GetDCSParameter(DataCompositionSchema, "ComparisonPeriod");
		If ComparisonPeriodParameter <> Undefined Then
			DataCompositionServer.SetDCSParameter(DataCompositionSchema,
					"ComparisonPeriod",
					ComparisonPeriod);
			DataCompositionServer.SetDCSParameter(DataCompositionSchema,
					"ComparisonPeriodStartDate",
					ComparisonPeriod.StartDate);
			DataCompositionServer.SetDCSParameter(DataCompositionSchema,
					"ComparisonPeriodEndDate",
					ComparisonPeriod.EndDate);
		EndIf;
		
		If CalculationParameters.AddForecast Then
			AnalysisPeriod.EndDate = OffsetDate_(AnalysisPeriod.EndDate,
					IndicatorCalculationFrequency,
					CalculationParameters.ForecastHorizon);
		EndIf;
		
		DataCompositionServer.SetDCSParameter(DataCompositionSchema,
				"Period",
				AnalysisPeriod);
		DataCompositionServer.SetDCSParameter(DataCompositionSchema,
				"BeginOfPeriod",
				AnalysisPeriod.StartDate);
		DataCompositionServer.SetDCSParameter(DataCompositionSchema,
				"EndOfPeriod",
				AnalysisPeriod.EndDate);
		ParameterValue = ?(ValueIsFilled(ComparisonPeriod.StartDate),
			Min(ComparisonPeriod.StartDate, AnalysisPeriod.StartDate),
			AnalysisPeriod.StartDate);
		DataCompositionServer.SetDCSParameter(DataCompositionSchema,
				"ProvidedPeriodStart",
				ParameterValue);
		
		// Let's establish connections of data sets by period
		If DataCompositionSchema.Parameters.Find("DoNotChangeConnectionAccordingToCalculationDate") = Undefined
			Or (Not DataCompositionSchema.Parameters.Find("DoNotChangeConnectionAccordingToCalculationDate") = Undefined
			And Not DataCompositionSchema.Parameters.Find("DoNotChangeConnectionAccordingToCalculationDate").Value) Then
			DataSetLinks = DataCompositionSchema.DataSetLinks;
			For Each LinkingDatasets In DataSetLinks Do 
				If LinkingDatasets.DestinationDataSet = "DataForAnalysis" Then 
					If StrFind(LinkingDatasets.SourceExpression, "Period") Then
						LinkingDatasets.DestinationExpression =
							FinancialReportingClientServer.PeriodStrings(IndicatorCalculationFrequency).Period;
					EndIf;
				ElsIf LinkingDatasets.DestinationDataSet = "TargetValuesRanges" Then 
					LinkingDatasets.SourceExpression = StrTemplate("ENDOFPERIOD(Period, ""%1"")",
						Upper(GetNameOfEnumerationValue(IndicatorCalculationFrequency)));
				EndIf;
			EndDo;
		ElsIf Not DataCompositionSchema.Parameters.Find("DoNotChangeConnectionAccordingToCalculationDate") = Undefined
			And DataCompositionSchema.Parameters.Find("DoNotChangeConnectionAccordingToCalculationDate").Value Then
			DataSetLinks = DataCompositionSchema.DataSetLinks;
			For Each LinkingDatasets In DataSetLinks Do 
				If StrFind(LinkingDatasets.SourceExpression, "Period") Then
					LinkingDatasets.SourceExpression = StrTemplate("ENDOFPERIOD(Period, ""%1"")",
						Upper(GetNameOfEnumerationValue(IndicatorCalculationFrequency)));
					LinkingDatasets.DestinationExpression = StrTemplate("ENDOFPERIOD(DateOfCalculation, ""%1"")",
						Upper(GetNameOfEnumerationValue(IndicatorCalculationFrequency)));
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Return DataCompositionSchema;
EndFunction


// LongDesc
// 
// Parameters:
// 	AnalysisOption - Structure - Attributes of The Analysis Option
// 	ViewOption - EnumRef.DisplayOptionsOfAnalysisOptions - LongDesc
// 	DynamicParameters - Structure, Arbitrary, Undefined - LongDesc
// Returns:
// 	Structure - LongDesc:
// * AnalysisValueAdditionalFieldName - String, Undefined -
// * AnalysisValueAdditionalField - DataCompositionField, Arbitrary, Undefined -
// * AnalysisValueFieldName - String, Undefined -
// * ValueAnalysisField - DataCompositionField, Arbitrary, Undefined -
// * AnalysisObjectFieldName - String, Undefined -
// * ObjectOfAnalysisField - DataCompositionField, Arbitrary, Undefined -
// * Addresses - Structure -:
// ** DataCompositionSchema - String - Address of the temporary storage of the layout diagram.
// ** DataCompositionSettings - String - Address of the temporary storage for layout settings.
// ** UserSettings - String - Address of the temporary storage of user settings.
// * ForecastAnalysisDepth - Number -
// * ForecastHorizon - Number -
// * AddForecast - Boolean -
// * IndicatorCalculationFrequency - EnumRef.Periodicity -
// * ComponentWiseComparisonMode - Number -
// * ForTable - Boolean -
// * CalculateForecast - Boolean -
// * ThereIsRunningTotal - Boolean -
// * ThereIsComparison - Boolean -
// * ComparisonPeriod - StandardPeriod -
// * AnalysisPeriod - StandardPeriod -
// * CalculationMethods_ - EnumManager.CalculationMethodsOfTargetValueAnalysisOptions -
// * ChartType - EnumRef.ChartTypesOfIndicators -
// * AnalysisType - EnumRef.IndicatorAnalysisTypes -
// * TypesOfAnalysis - EnumManager.IndicatorAnalysisTypes -
// * DisplayOptions - EnumManager.DisplayOptionsOfAnalysisOptions -
Function CalculationParameters(AnalysisOption, ViewOption, DynamicParameters)
	CalculationParameters = New Structure;
	
	CalculationParameters.Insert("AnalysisOption", AnalysisOption);
	
	CalculationParameters.Insert("DisplayOptions", Enums.DisplayOptionsOfAnalysisOptions);
	CalculationParameters.Insert("ViewOption", ViewOption);
	CalculationParameters.Insert("TypesOfAnalysis", Enums.IndicatorAnalysisTypes);
	CalculationParameters.Insert("AnalysisType", AnalysisOption.AnalysisType);
	CalculationParameters.Insert("ChartType", AnalysisOption.ChartType);
	CalculationParameters.Insert("CalculationMethods_", Enums.CalculationMethodsOfTargetValueAnalysisOptions);
	CalculationParameters.Insert("AnalysisPeriod", AnalysisOption.AnalysisPeriod.Get());
	CalculationParameters.Insert("ComparisonPeriod", AnalysisOption.ComparisonPeriod.Get());
	CalculationParameters.Insert("ThereIsComparison", False);
	CalculationParameters.Insert("ThereIsRunningTotal", AnalysisOption.ValueCalculationMethod = CalculationParameters.CalculationMethods_.CumulativeAmount);
	CalculationParameters.Insert("CalculateForecast", False);
	CalculationParameters.Insert("ForTable", False);
	CalculationParameters.Insert("ComponentWiseComparisonMode", AnalysisOption.ComponentWiseComparisonMode);
	
	// We get the periodicity settings
	If Not DynamicParameters = Undefined And DynamicParameters.Property("IndicatorCalculationFrequency") Then
		IndicatorCalculationFrequency = DynamicParameters.IndicatorCalculationFrequency;
	Else
		IndicatorCalculationFrequency = AnalysisOption.IndicatorCalculationFrequency;
	EndIf;
	CalculationParameters.Insert("IndicatorCalculationFrequency", IndicatorCalculationFrequency);
	
	// Let's clarify the calculation settings
	If CalculationParameters.ViewOption = CalculationParameters.DisplayOptions.Chart Then 
		If CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ChangeTrends Then
			CalculationParameters.CalculateForecast = True;
		ElsIf CalculationParameters.AnalysisType = CalculationParameters.TypesOfAnalysis.ComparisonWithPreviousPeriod Then
			CalculationParameters.ThereIsComparison = True;
			CalculationParameters.CalculateForecast = True;
		EndIf;
	ElsIf CalculationParameters.ViewOption = CalculationParameters.DisplayOptions.Table Then 
		CalculationParameters.ForTable = True;
	EndIf;
	
	CalculationParameters.Insert("AddForecast", CalculationParameters.CalculateForecast And AnalysisOption.CalculateForecast);
	CalculationParameters.Insert("ForecastHorizon", ?(CalculationParameters.AddForecast, AnalysisOption.ForecastHorizon, 0));
	CalculationParameters.Insert("ForecastAnalysisDepth", AnalysisOption.ForecastAnalysisDepth);
	CalculationParameters.Insert("Addresses", Catalogs.AnalysisOptionsOfTargetValues.AddressesOfDataLayoutSchemeAndUserSettings(AnalysisOption));
	
	// We will get the settings of the fields of the analysis option
	If Not DynamicParameters = Undefined And DynamicParameters.Property("AnalysisObject") Then
		ObjectOfAnalysisField = New DataCompositionField(DynamicParameters.AnalysisObject);
		AnalysisObjectFieldName = DynamicParameters.AnalysisObject;
	Else
		If TypeOf(AnalysisOption.AnalysisObject) = Type("String") Then
			ObjectOfAnalysisField = New DataCompositionField(AnalysisOption.AnalysisObject);
		ElsIf AnalysisOption.AnalysisObject = Undefined Then
			ObjectOfAnalysisField = Undefined;
		Else
			ObjectOfAnalysisField = AnalysisOption.AnalysisObject.Get();
		EndIf;
		
		If Not ObjectOfAnalysisField = Undefined Then
			AnalysisObjectFieldName = String(ObjectOfAnalysisField);
		Else
			AnalysisObjectFieldName = Undefined;
		EndIf;
	EndIf;
	CalculationParameters.Insert("ObjectOfAnalysisField", ObjectOfAnalysisField);
	CalculationParameters.Insert("AnalysisObjectFieldName", AnalysisObjectFieldName);
	
	If TypeOf(AnalysisOption.AnalysisValue) = Type("String") Then
		ValueAnalysisField = New DataCompositionField(AnalysisOption.AnalysisValue);
	ElsIf AnalysisOption.AnalysisValue = Undefined Then
		ValueAnalysisField = Undefined;
	Else
		ValueAnalysisField = AnalysisOption.AnalysisValue.Get();
	EndIf;
	If Not ValueAnalysisField = Undefined Then
		AnalysisValueFieldName = String(ValueAnalysisField);
	Else
		AnalysisValueFieldName = Undefined;
	EndIf;
	CalculationParameters.Insert("ValueAnalysisField", ValueAnalysisField);
	CalculationParameters.Insert("AnalysisValueFieldName", AnalysisValueFieldName);
	
	If TypeOf(AnalysisOption.AnalysisValueAdditional) = Type("String") Then
		AnalysisValueAdditionalField = New DataCompositionField(AnalysisOption.AnalysisValueAdditional);
	ElsIf AnalysisOption.AnalysisValueAdditional = Undefined Then
		AnalysisValueAdditionalField = Undefined;
	Else
		AnalysisValueAdditionalField = AnalysisOption.AnalysisValueAdditional.Get();
	EndIf;
	If Not AnalysisValueAdditionalField = Undefined Then
		AnalysisValueAdditionalFieldName = String(AnalysisValueAdditionalField);
	Else
		AnalysisValueAdditionalFieldName = Undefined;
	EndIf;
	CalculationParameters.Insert("AnalysisValueAdditionalField", AnalysisValueAdditionalField);
	CalculationParameters.Insert("AnalysisValueAdditionalFieldName", AnalysisValueAdditionalFieldName);
	
	Return CalculationParameters;
EndFunction

Function GetAnalysisVariantDataSourceFromCache(AnalysisOption, ViewOption)
	
	DataSource = Undefined; 
	
	PeriodInMinutes = CalculationPeriodInMinutes(AnalysisOption);
	Query = New Query;
	Query.SetParameter("AnalysisOption", AnalysisOption);
	Query.SetParameter("ViewOption", ViewOption);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("CalculationRelevancePeriod", PeriodInMinutes);
	Query.Text = RequestTextForAnalysisVariantDataInCache();
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		DataSource = Selection.DataSource.Get();
		DataSource.DateOfCalculation = Selection.DateOfCalculation;
		DataSource.DataIsRelevant = Selection.DataIsRelevant;
		
	EndIf;
	
	Return DataSource;
	
EndFunction

Function InterestAreaProcedure(AreaOfInterest)
	
	Query = New Query;
	Query.SetParameter("Ref", AreaOfInterest);
	Query.Text = "SELECT
		|	InterestAreasOfAnalysisOptions.Order AS Order
		|FROM
		|	Enum.InterestAreasOfAnalysisOptions AS InterestAreasOfAnalysisOptions
		|WHERE
		|	InterestAreasOfAnalysisOptions.Ref = &Ref";
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		Return Selection.Order;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure BringTotalFieldExpressionsToSpecifiedPrecision(CompositionSchema, TypeOfNumberPresentation, Digits)
	
	SummaryFields = CompositionSchema.TotalFields;
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	
	DenominatorRequired = False;
	
	If TypeOfNumberPresentation = NumberPresentationKinds.InThousands Then
		Denominator = Format(Pow(10, 3), "NG=0;");
		DenominatorRequired = True;
	ElsIf TypeOfNumberPresentation = NumberPresentationKinds.InMillions Then
		Denominator = Format(Pow(10, 6), "NG=0;");
		DenominatorRequired = True;
	EndIf;
	
	NumberExpressionPattern = "Number(31, %1)";
	NumberExpression = """" + StrTemplate(NumberExpressionPattern, Digits) + """";
	
	If DenominatorRequired Then
		DenominatorAwarePattern = "CAST((%1) / %3, %2)";
	Else
		DenominatorAwarePattern = "CAST((%1), %2)";
	EndIf;
	
	For Each TotalField In SummaryFields Do 
		If TotalField.DataPath = "PositiveBorderVariance"
			Or TotalField.DataPath = "NegativeBorderVariance" Then
			
			PartOfExpression = StrTemplate(DenominatorAwarePattern,
				TotalField.Expression, NumberExpression, Denominator);
			
			TotalField.Expression = StrTemplate(
				"CASE
				|	WHEN KindOfVarianceFromTargetValue = VALUE(Enum.KindsOfVariancesFromTargetValues.Absolute)
				|		THEN %1
				|		ELSE %2
				|END",
				PartOfExpression, TotalField.Expression);
		Else
			TotalField.Expression = StrTemplate(DenominatorAwarePattern,
				TotalField.Expression, NumberExpression, Denominator);
		EndIf;
	EndDo;
	
EndProcedure

Procedure ApplyDisplayOptionSettings(SettingsComposer, CalculationParameters, DynamicParameters = Undefined)
	DisplayOptionsOfAnalysisOptions = Enums.DisplayOptionsOfAnalysisOptions;
	IndicatorAnalysisTypes = Enums.IndicatorAnalysisTypes;
	
	AnalysisOption = CalculationParameters.AnalysisOption; // Structure -
	ViewOption = CalculationParameters.ViewOption;
	
	AnalysisType = AnalysisOption.AnalysisType;
	AnalysisPeriod = CalculationParameters.AnalysisPeriod; // StandardPeriod -
	ComparisonPeriod = CalculationParameters.ComparisonPeriod; // StandardPeriod -
	
	If AnalysisType = IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
		ProvidedPeriodStart = Min(AnalysisPeriod.StartDate, ComparisonPeriod.StartDate);
		QuotedEndOfPeriod = Max(AnalysisPeriod.EndDate, ComparisonPeriod.EndDate);
	Else
		ProvidedPeriodStart = AnalysisPeriod.StartDate;
		QuotedEndOfPeriod = AnalysisPeriod.EndDate;
	EndIf;
	PeriodicityName = GetNameOfEnumerationValue(CalculationParameters.IndicatorCalculationFrequency);
	
	// We will get the settings of the fields of the analysis option
	If Not DynamicParameters = Undefined And DynamicParameters.Property("AnalysisObject") Then
		ObjectOfAnalysisField = New DataCompositionField(DynamicParameters.AnalysisObject);
		AnalysisObjectFieldName = DynamicParameters.AnalysisObject;
	Else
		ObjectOfAnalysisField = CalculationParameters.ObjectOfAnalysisField;
		If Not ObjectOfAnalysisField = Undefined Then
			AnalysisObjectFieldName = String(ObjectOfAnalysisField);
		Else
			AnalysisObjectFieldName = Undefined;
		EndIf;	
	EndIf;
	
	ValueAnalysisField = CalculationParameters.ValueAnalysisField;
		
	SettingsComposer.Settings.Structure.Clear();
	
	PeriodGroupingParameters = New Structure("BeginOfPeriod, EndOfPeriod, GroupType, AdditionType"); 
	PeriodGroupingParameters.Insert("BeginOfPeriod", ProvidedPeriodStart);
	PeriodGroupingParameters.Insert("EndOfPeriod", QuotedEndOfPeriod);
	PeriodGroupingParameters.Insert("AdditionType", DataCompositionPeriodAdditionType[PeriodicityName]);
	
	If ViewOption = DisplayOptionsOfAnalysisOptions.Chart
		Or ViewOption = DisplayOptionsOfAnalysisOptions.Brief1 Then
		If AnalysisType = IndicatorAnalysisTypes.ChangeTrends Then
			DataCompositionClientServer.AddGrouping(SettingsComposer,
			                                                 "Period",,
			                                                 PeriodGroupingParameters);
			
			SetGroupingOrdering(SettingsComposer.Settings, 
				New DataCompositionField("Period"), 
				DataCompositionSortDirection.Asc,
				False, False);
		ElsIf AnalysisType = IndicatorAnalysisTypes.ComponentWiseComparisonTrends Then
			If CalculationParameters.ComponentWiseComparisonMode = 0 Then
				DataCompositionClientServer.AddGrouping(SettingsComposer, AnalysisObjectFieldName);
			EndIf;
			
			DataCompositionClientServer.AddGrouping(SettingsComposer,
			                                                 "Period",,
			                                                 PeriodGroupingParameters);
			
			SetGroupingOrdering(SettingsComposer.Settings, 
				New DataCompositionField("Period"), 
				DataCompositionSortDirection.Asc,
				False, False);
		ElsIf AnalysisType = IndicatorAnalysisTypes.ComponentWiseComparisonStructure Then
			If CalculationParameters.ComponentWiseComparisonMode = 0 Then
				DataCompositionClientServer.AddGrouping(SettingsComposer, AnalysisObjectFieldName);
			EndIf;
			
			DataCompositionClientServer.AddGroupingToStructureRoot(SettingsComposer,
			                                                                 "Period",
			                                                                 PeriodGroupingParameters);
			
			SetGroupingOrdering(SettingsComposer.Settings, 
				New DataCompositionField("Period"), 
				DataCompositionSortDirection.Asc,
				False, False);
		ElsIf AnalysisType = IndicatorAnalysisTypes.MeasureCurrentValue Then
			DataCompositionClientServer.AddGrouping(SettingsComposer,
			                                                 "Period",,
			                                                 PeriodGroupingParameters);
			
			SetGroupingOrdering(SettingsComposer.Settings, 
				New DataCompositionField("Period"), 
				DataCompositionSortDirection.Asc,
				False, False);
		ElsIf AnalysisType = IndicatorAnalysisTypes.ComparisonWithPreviousPeriod Then
			DataCompositionClientServer.AddGrouping(SettingsComposer,
			                                                 "Period",,
			                                                 PeriodGroupingParameters);
			
			SetGroupingOrdering(SettingsComposer.Settings, 
				New DataCompositionField("Period"), 
				DataCompositionSortDirection.Asc,
				False, False);
		EndIf;
	ElsIf ViewOption = DisplayOptionsOfAnalysisOptions.Table Then 
		DataCompositionClientServer.AddGrouping(SettingsComposer, AnalysisObjectFieldName);
		
		DataCompositionClientServer.AddGroupingToStructureRoot(SettingsComposer,
		                                                                 "Period",
		                                                                 PeriodGroupingParameters);
		
		SetGroupingOrdering(SettingsComposer.Settings, 
			New DataCompositionField("Period"), 
			DataCompositionSortDirection.Asc,
			False, False);
	EndIf;
	
	If Not SettingsComposer.Settings.GroupAvailableFields.Items.Find("CalculationsAreRelevant") = Undefined Then
		DataCompositionClientServer.AddGroupingToStructureRoot(SettingsComposer, "CalculationsAreRelevant");
	EndIf;
	
	// Add the selected analysis value and delete the previously added ones
	ServiceFields = Catalogs.StructureOfTargets.ServiceFieldsAnalysisValues();
	FieldsToDelete_ = New Array;
	SelectedFields = SettingsComposer.Settings.Selection.Items;
	For Each SelectedField In SelectedFields Do 
		If ServiceFields.Find(String(SelectedField.Field)) = Undefined Then
			FieldsToDelete_.Add(SelectedField);
		EndIf;
	EndDo;
	For Each FieldToDelete In FieldsToDelete_ Do 
		SelectedFields.Delete(FieldToDelete);
	EndDo;
	DataCompositionClientServer.AddSelectedField(SettingsComposer, ValueAnalysisField);
	If (AnalysisType = IndicatorAnalysisTypes.ComponentWiseComparisonTrends
		Or AnalysisType = IndicatorAnalysisTypes.ComponentWiseComparisonStructure)
		And CalculationParameters.ComponentWiseComparisonMode = 1 Then
		DataCompositionClientServer.AddSelectedField(SettingsComposer, CalculationParameters.AnalysisValueAdditionalField);
	EndIf;
EndProcedure

Function CalculateCumulativeTotal(TableByPeriod, CalculationParameters)
	CalculationColumn = CalculationParameters.AnalysisValueFieldName;
	CalculationColumnOptional = CalculationParameters.AnalysisValueAdditionalFieldName;
	ColumnOfObjectOfAnalysis = CalculationParameters.AnalysisObjectFieldName;
	
	AnalysisPeriod = CalculationParameters.AnalysisPeriod;
	ComparisonPeriod = CalculationParameters.ComparisonPeriod;

	CumulativeResults = New Structure("Overall, TotalAdditional, OverallComparisonResult", 0, 0);
	
	ComparisonPeriodIsSpecified = (Not ComparisonPeriod = Undefined);
	
	If ComparisonPeriodIsSpecified Then
		ComparisonPeriodEndDate = ComparisonPeriod.EndDate;
	EndIf;
	
	PeriodsCoincide = (AnalysisPeriod = ComparisonPeriod);
	
	TemporaryCopyOfTable = TableByPeriod.Copy();
	ThereIsObjectOfAnalysis = TemporaryCopyOfTable.Columns.Find(ColumnOfObjectOfAnalysis) <> Undefined;
	If ThereIsObjectOfAnalysis Then
		TemporaryCopyOfTable.Sort(ColumnOfObjectOfAnalysis + " Asc" + ", " + "Period Asc");
	Else
		TemporaryCopyOfTable.Sort("Period Asc");
	EndIf;
	
	BaseIndex = 0;
	Overall = 0;
	TotalAdditional = 0;
	OverallComparisonResult = 0;
	CountTotal_ = False;
	CountTotalAdditional = Not ThereIsObjectOfAnalysis And CalculationParameters.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends;
	ConsiderTotalResultOfComparison = False;
	PeriodOfPreviousLine = Date("00010101010101");
	For Each TableRow In TemporaryCopyOfTable Do 
		If Not ValueIsFilled(TableRow.Period) Then
			Continue;
		EndIf;
		
		TableRowIndex = TemporaryCopyOfTable.IndexOf(TableRow);
		// Zeroing the total for component-by-component dynamics
		If PeriodOfPreviousLine > TableRow.Period Then
			BaseIndex = TableRowIndex;
		EndIf;
		
		If ComparisonPeriodIsSpecified And TableRow.Period < ComparisonPeriodEndDate Then
			If Not ConsiderTotalResultOfComparison Then
				BaseIndex = TableRowIndex;
				ConsiderTotalResultOfComparison = True;
				CountTotal_ = False;
			EndIf;
		Else
			If Not CountTotal_ Then
				BaseIndex = TableRowIndex;
				ConsiderTotalResultOfComparison = False;
				CountTotal_ = True;
			EndIf;
		EndIf;
			
		If CountTotal_ Then
			Overall = Overall + TableRow[CalculationColumn];
			If CountTotalAdditional Then
				TotalAdditional = TotalAdditional + TableRow[CalculationColumnOptional];
			EndIf;
		EndIf;
		
		If ConsiderTotalResultOfComparison Then
			OverallComparisonResult = OverallComparisonResult + TableRow[CalculationColumn];
		EndIf;
		
		If TableRowIndex > BaseIndex Then
			TableRow[CalculationColumn] = TableRow[CalculationColumn]
				+ TemporaryCopyOfTable[TableRowIndex-1][CalculationColumn];
			If CountTotalAdditional Then
				TableRow[CalculationColumnOptional] = TableRow[CalculationColumnOptional]
					+ TemporaryCopyOfTable[TableRowIndex-1][CalculationColumnOptional];
			EndIf;
		EndIf;
		
		PeriodOfPreviousLine = TableRow.Period;
	EndDo;
	
	// Let's transfer the cumulative total data to the original table with arbitrary sorting.
	For Each TableRow In TableByPeriod Do 
		If ThereIsObjectOfAnalysis Then
			SearchParameters = New Structure;
			SearchParameters.Insert(ColumnOfObjectOfAnalysis, TableRow[ColumnOfObjectOfAnalysis]);
			SearchParameters.Insert("Period", TableRow.Period);
		Else
			SearchParameters = New Structure("Period", TableRow.Period);
		EndIf;
		RequiredRows = TemporaryCopyOfTable.FindRows(SearchParameters);
		If RequiredRows.Count() = 1 Then
			FillPropertyValues(TableRow, RequiredRows[0]);
		EndIf;
	EndDo;
	
	If PeriodsCoincide Then
		CumulativeResults.Overall = OverallComparisonResult;
	Else 
		CumulativeResults.Overall = Overall;
		If CountTotalAdditional Then
			CumulativeResults.TotalAdditional = TotalAdditional;
		EndIf;
	EndIf;
	CumulativeResults.OverallComparisonResult = OverallComparisonResult;
	
	Return CumulativeResults;
EndFunction

Function PropertiesOfCacheAnalysisVariantData(AnalysisOption, ViewOption)
	
	PropertiesOfCacheAnalysisVariantData = New Structure("DateOfCalculation, DataIsRelevant", Date(1,1,1), False); 
	PeriodInMinutes = CalculationPeriodInMinutes(AnalysisOption);
	
	Query = New Query;
	Query.SetParameter("AnalysisOption", AnalysisOption);
	Query.SetParameter("ViewOption", ViewOption);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("CalculationRelevancePeriod", PeriodInMinutes);
	Query.Text = RequestTextForAnalysisVariantDataInCache(True);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		PropertiesOfCacheAnalysisVariantData.DateOfCalculation = Selection.DateOfCalculation;
		PropertiesOfCacheAnalysisVariantData.DataIsRelevant = Selection.DataIsRelevant;
	EndIf;
	
	Return PropertiesOfCacheAnalysisVariantData;
	
EndFunction

// returns the attention zone that characterizes the State (Status) of the indicator
//
// Parameters:
//	AnalysisOption - Structure - Attributes of The Analysis Option
//	DataSource 	- Value tables with data for the chart.
//
// Returns:
//	Structure		- properties of the analysis zone.
//
Function PropertiesOfAnalysisZone(AnalysisOption, DataSource) Export
	
	TargetTrend = Common.ObjectAttributeValue(AnalysisOption.Owner, "TargetTrend");
	
	PropertiesOfAnalysisAndTrendZone = New Structure;
	PropertiesOfAnalysisAndTrendZone.Insert("ChangesAreStable");
	PropertiesOfAnalysisAndTrendZone.Insert("TargetTrend");
	PropertiesOfAnalysisAndTrendZone.Insert("AnalysisZoneNumber");
	PropertiesOfAnalysisAndTrendZone.Insert("TheActualTrend");
	PropertiesOfAnalysisAndTrendZone.Insert("ExplanationOfTheTrend");
	PropertiesOfAnalysisAndTrendZone.Insert("PointsInRealTrend");
	PropertiesOfAnalysisAndTrendZone.Insert("Status");
	PropertiesOfAnalysisAndTrendZone.Insert("ExplanationOfTheStatus");
	PropertiesOfAnalysisAndTrendZone.Insert("PatternOfChange");
	PropertiesOfAnalysisAndTrendZone.Insert("AreaOfInterest");
	PropertiesOfAnalysisAndTrendZone.Insert("InterestAreaProcedure");
	
	MatrixOfStates = TargetValueMonitoringCached.GetStateMatrix();
	TargetValueKind = GetTargetValueView(DataSource.PropertiesOfDataByPeriod.DateOfLastValue,
		AnalysisOption);
	AnalysisArea = ValueAnalysisZone(DataSource,
		TargetTrend,
		TargetValueKind,
		AnalysisOption.FractionalPartCalculationAccuracy);
	NameOfRegionOfStateMatrix = "Unstable" + "_" + AnalysisArea.TheActualTrend + "_" + "Zone" + "_"
		+ AnalysisArea.ZoneNumber + "_" + GetNameOfEnumerationValue(TargetTrend);
	
	ExplanationOfTheStatus = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "ExplanationOfTheStatus").CurrentArea.Parameter;
	ExplanationOfTheTrend  = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "ExplanationOfTheTrend").CurrentArea.Parameter;
	
	PropertiesOfAnalysisAndTrendZone.ChangesAreStable = False;
	PropertiesOfAnalysisAndTrendZone.TargetTrend = TargetTrend;
	PropertiesOfAnalysisAndTrendZone.AnalysisZoneNumber = AnalysisArea.ZoneNumber;
	PropertiesOfAnalysisAndTrendZone.TheActualTrend = AnalysisArea.TheActualTrend;
	PropertiesOfAnalysisAndTrendZone.ExplanationOfTheTrend = TargetValueMonitoringCached.PresentationExplanationOfTrendOfStateMatrix(ExplanationOfTheTrend);
	PropertiesOfAnalysisAndTrendZone.PointsInRealTrend = Undefined;
	PropertiesOfAnalysisAndTrendZone.Status = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "Status").CurrentArea.Parameter;
	PropertiesOfAnalysisAndTrendZone.ExplanationOfTheStatus = TargetValueMonitoringCached.PresentationOfExplanationOfStatusOfStateMatrix(ExplanationOfTheStatus);
	PropertiesOfAnalysisAndTrendZone.PatternOfChange = MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "PatternOfChange").CurrentArea.Parameter;
	PropertiesOfAnalysisAndTrendZone.AreaOfInterest = Enums.InterestAreasOfAnalysisOptions[MatrixOfStates.GetArea(NameOfRegionOfStateMatrix + "|" + "AreaOfInterest").CurrentArea.Parameter];
	PropertiesOfAnalysisAndTrendZone.InterestAreaProcedure = InterestAreaProcedure(PropertiesOfAnalysisAndTrendZone.AreaOfInterest);
	
	Return PropertiesOfAnalysisAndTrendZone;
	
EndFunction

Function RequestTextForAnalysisVariantDataInCache(OnlyProperties = False)
	
	QueryText = "SELECT
		|	MAX(DataSourcesOfTargetValueAnalysisOptions.DateOfCalculation) AS DateOfCalculation,
		|	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption AS AnalysisOption
		|INTO MaximumSettlementDate
		|FROM
		|	InformationRegister.DataSourcesOfTargetValueAnalysisOptions AS DataSourcesOfTargetValueAnalysisOptions
		|WHERE
		|	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption = &AnalysisOption
		|
		|GROUP BY
		|	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataSourcesOfTargetValueAnalysisOptions.DateOfCalculation AS DateOfCalculation,
		|	CASE
		|		WHEN DATEDIFF(DataSourcesOfTargetValueAnalysisOptions.DateOfCalculation, &CurrentDate, MINUTE) <= &CalculationRelevancePeriod
		|				AND DataSourcesOfTargetValueAnalysisOptions.DateOfCalculation >= MaximumSettlementDate.DateOfCalculation
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS DataIsRelevant
		|FROM
		|	InformationRegister.DataSourcesOfTargetValueAnalysisOptions AS DataSourcesOfTargetValueAnalysisOptions
		|		LEFT JOIN MaximumSettlementDate AS MaximumSettlementDate
		|		ON DataSourcesOfTargetValueAnalysisOptions.AnalysisOption = MaximumSettlementDate.AnalysisOption
		|WHERE
		|	DataSourcesOfTargetValueAnalysisOptions.AnalysisOption = &AnalysisOption
		|	AND DataSourcesOfTargetValueAnalysisOptions.ViewOption = &ViewOption";
	
	If Not OnlyProperties Then
		QueryText = RequestSchemes.AddSelectionFieldToQuery(QueryText, "DataSourcesOfTargetValueAnalysisOptions.DataSource", "DataSource");
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure SetGroupingOrdering(GroupingField, OrderField, OrderType, Clear = False, Add = True)
	OrderItems = GroupingField.Order.Items;
	If Clear Then
		OrderItems.Clear();
	EndIf;
	
	If Add Then
		NewElementOfOrder = OrderItems.Add(Type("DataCompositionOrderItem"));
	Else
		NewElementOfOrder = OrderItems.Insert(0, Type("DataCompositionOrderItem"));
	EndIf;
	NewElementOfOrder.Use = True;
	NewElementOfOrder.Field = OrderField;
	NewElementOfOrder.OrderType = OrderType;
EndProcedure

Function TargetValuesOfAnalysisVariant(AnalysisOption, Date)
	
	StructureOfTargets = New Structure;
	StructureOfTargets.Insert("TargetValue_");
	StructureOfTargets.Insert("MinimumTargetRange");
	StructureOfTargets.Insert("MaximumTargetRange");
	StructureOfTargets.Insert("PositiveBorderVariance");
	StructureOfTargets.Insert("NegativeBorderVariance");
	StructureOfTargets.Insert("AdjustedPositiveBorderVariance");
	StructureOfTargets.Insert("AdjustedNegativeBorderVariance");
	
	Query = New Query;
	Query.SetParameter("AnalysisOption", AnalysisOption.Ref);
	Query.SetParameter("Date", Date);
	Query.Text = "SELECT DISTINCT
		|	TargetValuesOfSliceAnalysisOptions.TargetValue_,
		|	TargetValuesOfSliceAnalysisOptions.MinimumTargetRange,
		|	TargetValuesOfSliceAnalysisOptions.MaximumTargetRange,
		|	TargetValuesOfSliceAnalysisOptions.NegativeBorderVariance,
		|	TargetValuesOfSliceAnalysisOptions.PositiveBorderVariance,
		|	TargetValuesOfSliceAnalysisOptions.AdjustedNegativeBorderVariance,
		|	TargetValuesOfSliceAnalysisOptions.AdjustedPositiveBorderVariance
		|FROM
		|	InformationRegister.AnalysisOptionTargetValues.SliceLast(&Date, AnalysisOption = &AnalysisOption) AS TargetValuesOfSliceAnalysisOptions";
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		FillPropertyValues(StructureOfTargets, Selection);
	EndIf;
	
	Return StructureOfTargets;
	
EndFunction

#EndRegion

#Region InfobaseUpdateHandlers

Function SkipRecording(LinkTextOfCurElement)
	SkipRecording = False;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	
	UseSalesPlans = GetFunctionalOption("UseSalesPlans");
	UsePurchasePlanning = GetFunctionalOption("UsePurchasePlanning");
	UseProductionPlanning = False;

	SchedulingIsUsed = UseSalesPlans Or UsePurchasePlanning Or UseProductionPlanning;
	
	UseSalesOrders = GetFunctionalOption("UseSalesOrders");
	UsePurchaseOrders = GetFunctionalOption("UsePurchaseOrders");
	UseProduction21 = False;
	OrdersAreUsed_ = UseSalesOrders Or UsePurchaseOrders Or UseProduction21;
	
	If Not UseMultipleCurrencies
		And (LinkTextOfCurElement =      "4838f66b-bcda-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "4838f66c-bcda-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "4838f66d-bcda-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "4838f666-bcda-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "4838f667-bcda-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "4838f66e-bcda-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "e859aeb6-bce3-11e4-8d8d-e0cb4ed5f4cc") Then
		
		// We do not record indicators of the type "Balance of DS / <Currency>" and exchange rates
		SkipRecording = True;
	EndIf;
	If UseMultipleCurrencies
		And CurrencyEUR().IsEmpty()
		And (LinkTextOfCurElement =      "4838f66e-bcda-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "4838f66d-bcda-11e4-8d8d-e0cb4ed5f4cc") Then
		
		SkipRecording = True;
	EndIf;
	If UseMultipleCurrencies
		And CurrencyUSD().IsEmpty()
		And (LinkTextOfCurElement =      "e859aeb6-bce3-11e4-8d8d-e0cb4ed5f4cc" 
			Or LinkTextOfCurElement = "4838f66c-bcda-11e4-8d8d-e0cb4ed5f4cc") Then
		
		SkipRecording = True;
	EndIf;
	
	If Not SchedulingIsUsed
		And LinkTextOfCurElement = "41b22eaa-bcda-11e4-8d8d-e0cb4ed5f4cc" Then
		
		// We do not record the group of indicators "Execution of plans"
		SkipRecording = True;
	EndIf;
	If Not UseSalesPlans 
		And (LinkTextOfCurElement =      "4838f663-bcda-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "49c43ecb-bcea-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "405ff23a-bd08-11e4-8d8d-e0cb4ed5f4cc"
			) Then
		
		// We do not record sales planning indicators
		SkipRecording = True;
	EndIf;
	If Not UsePurchasePlanning 
		And (LinkTextOfCurElement =      "4838f664-bcda-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "2d6a8c2a-bcec-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "af11cd1c-bd0c-11e4-8d8d-e0cb4ed5f4cc") Then
		
		// We do not record purchase planning indicators
		SkipRecording = True;
	EndIf;
	If Not UseProductionPlanning 
		And (LinkTextOfCurElement =      "4838f665-bcda-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "2d6a8c2b-bcec-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "af11cd1d-bd0c-11e4-8d8d-e0cb4ed5f4cc") Then
		
		// We do not record production planning indicators
		SkipRecording = True;
	EndIf;
	
	If Not OrdersAreUsed_
		And LinkTextOfCurElement = "e859aec0-bce3-11e4-8d8d-e0cb4ed5f4cc" Then
		
		// We do not record the group of indicators "Order fulfillment"
		SkipRecording = True;
	EndIf;
	If Not UseSalesOrders 
		And (LinkTextOfCurElement =      "e859aebe-bce3-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "e859aebf-bce3-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "807b18c8-bcfc-11e4-8d8d-e0cb4ed5f4cc") Then
		
		// We do not record customer order control indicators
		SkipRecording = True;
	EndIf;
	If Not UsePurchaseOrders 
		And (LinkTextOfCurElement =      "e859aec1-bce3-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "e859aec2-bce3-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "807b18c9-bcfc-11e4-8d8d-e0cb4ed5f4cc") Then
		
		// We do not record order control indicators for suppliers
		SkipRecording = True;
	EndIf;
	If Not UseProduction21
		And (LinkTextOfCurElement =      "e859aec3-bce3-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "e859aec4-bce3-11e4-8d8d-e0cb4ed5f4cc"
			Or LinkTextOfCurElement = "807b18ca-bcfc-11e4-8d8d-e0cb4ed5f4cc") Then
		
		// We do not record indicators of control of production orders
		SkipRecording = True;
	EndIf;
	
	Return SkipRecording;
EndFunction


// Sets the selection value based on the user configuration ID.
// 
// Parameters:
// 	UserSettings - DataCompositionUserSettings - 
// 	UserSettingID - String -
// 	Value - Arbitrary -
Procedure SetSelectionValueById(UserSettings, UserSettingID, Value)
	For Each UserSetting In UserSettings.Items Do
		If TypeOf(UserSetting) = Type("DataCompositionFilterItem")
			And UserSetting.UserSettingID = UserSettingID Then
			UserSetting.RightValue = Value;
		EndIf;
	EndDo;
EndProcedure

// Function for checking objects when opening forms and before writing.
// It can be used as a default verification function if
// there is enough logic-blocked objects are registered on the nodes of the information database Update exchange plan.
//
// Parameters:
//  MetadataAndFilter - See InfobaseUpdate.MetadataAndFilterByData.
//
// Returns:
//  Boolean - True if the object is updated and available for modification.
//
Function DataUpdatedForNewApplicationVersion(MetadataAndFilter) Export
	
	Data = MetadataAndFilter.Data;
	
	If GetFunctionalOption("DeferredUpdateCompletedSuccessfully") Then
		If Not Common.IsSubordinateDIBNode() Then
			Return True;
		ElsIf GetFunctionalOption("DeferredMasterNodeUpdateCompleted") Then
			Return True;
		EndIf;
	EndIf;
	
	If MetadataAndFilter = Undefined Then
		MetadataAndFilter = InfobaseUpdate.MetadataAndFilterByData(Data, Undefined);
	EndIf;
	
	If MetadataAndFilter.IsNew Then
		
		CurObjectDataUpdated = True;
		
	Else
		
		CurObjectDataUpdated = Not InfobaseUpdate.HasDataToProcess(Undefined,
			MetadataAndFilter.Metadata, MetadataAndFilter.Filter);
		
	EndIf;
	
	If Not CurObjectDataUpdated Then
		Return CurObjectDataUpdated;
	EndIf;
	
	RelatedObjects = New Array;
	
	RelatedObjectDataUpdated = True;
	
	If MetadataAndFilter.Metadata = Metadata.Catalogs.AnalysisOptionsOfTargetValues Then
		
		LinkedObject = New Structure("Metadata, Filter");
		LinkedObject.Metadata = Metadata.Catalogs.StructureOfTargets;
		If TypeOf(Data) = Type("CatalogObject.AnalysisOptionsOfTargetValues") Then
			LinkedObject.Filter = Data.Owner;
		EndIf;
		RelatedObjects.Add(LinkedObject);
		
	ElsIf MetadataAndFilter.Metadata = Metadata.Reports.PerformanceDashboard Then
		
		LinkedObject = New Structure("Metadata, Filter");
		LinkedObject.Metadata = Metadata.Catalogs.StructureOfTargets;
		RelatedObjects.Add(LinkedObject);
		LinkedObject = New Structure("Metadata, Filter");
		LinkedObject.Metadata = Metadata.Catalogs.AnalysisOptionsOfTargetValues;
		RelatedObjects.Add(LinkedObject);
		
	EndIf;
	
	For Each AssociatedObjectMetadata In RelatedObjects Do
	
		If InfobaseUpdate.HasDataToProcess(
			Undefined, AssociatedObjectMetadata.Metadata, AssociatedObjectMetadata.Filter) Then
			RelatedObjectDataUpdated = False;
			Break;
		EndIf;
	EndDo;
	
	Return CurObjectDataUpdated And RelatedObjectDataUpdated;
	
EndFunction

#EndRegion

#Region Other

Function ThereAreAnalysisOptionsAvailable()
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	OptionsForAnalyzingAccessibilitySettingsTargets.Ref AS AnalysisOption
	|FROM
	|	Catalog.AnalysisOptionsOfTargetValues.AvailabilitySettings AS OptionsForAnalyzingAccessibilitySettingsTargets
	|WHERE
	|	OptionsForAnalyzingAccessibilitySettingsTargets.User = &CurrentUser
	|	AND NOT OptionsForAnalyzingAccessibilitySettingsTargets.Ref.DeletionMark";
	Query.SetParameter("CurrentUser", Users.CurrentUser());
	
	Return Not Query.Execute().IsEmpty();
EndFunction

// Checks that this dashboard is available to the Cur user
// 
// Parameters:
// 	Dashboard - CatalogRef.PerformanceDashboards - MCP dashboard for checking availability.
// Returns:
// 	Boolean - True if the dashboard is accessible to the user
Function DashboardIsAvailableToUser(Dashboard)

	Query = New Query;
	Query.SetParameter("CurrentUser", Users.CurrentUser());
	Query.SetParameter("Dashboard", Dashboard);
	Query.Text = 
	"SELECT
	|	PerformanceDashboards.Ref AS Ref
	|FROM
	|	Catalog.PerformanceDashboards AS PerformanceDashboards
	|WHERE
	|	PerformanceDashboards.Ref = &Dashboard
	|	AND PerformanceDashboards.Author = &CurrentUser
	|	AND PerformanceDashboards.AuthorOnly
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	PerformanceDashboardsDashboardUser.Ref
	|FROM
	|	Catalog.PerformanceDashboards.DashboardUser AS PerformanceDashboardsDashboardUser
	|WHERE
	|	PerformanceDashboardsDashboardUser.Ref = &Dashboard
	|	AND PerformanceDashboardsDashboardUser.User = &CurrentUser";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure AddOutputElement(OutputStructure, TagName, ElementValue)
	OutputStructure.Insert(TagName, ElementValue);
	OutputStructure.OutputOrder.Add(TagName);
EndProcedure

Function FindTableRowsByConditionNot(ValueTable, FiltersStructure)
	
	FoundRows = New Array;
	
	ExcludedRows = ValueTable.FindRows(FiltersStructure);
	
	For Each RowOfTableOfValuesToBeProcessed In ValueTable Do
		If ExcludedRows.Find(RowOfTableOfValuesToBeProcessed) = Undefined Then
			FoundRows.Add(RowOfTableOfValuesToBeProcessed);
		EndIf;
	EndDo;
	
	Return FoundRows;
	
EndFunction

// Returns the base value for plotting charts
Function StandardBaseValueForCharts()
	
	Return 0;
	
EndFunction

// Returns parameters of the base value for plotting charts
// 
// Parameters:
// 	AnalysisOption - Structure - Attributes of the analysis option.
// 	PropertiesOfGeneralStatistics - Structure - structure of statistical parameters of the data source:
// 	* ByObjectsOfAnalysis - Structure -:
// 	** Count - Number - 
// 	** Min - Number - 
// 	** Max - Number - 
// 	** AVG - Number - 
// 	** Range - Number -
// 	** StdDeviation - Number -
// 	** Median - Number -
// 	* ByPeriods - Structure -:
// 	** Count - Number - 
// 	** Min - Number - 
// 	** Max - Number - 
// 	** AVG - Number - 
// 	** Range - Number -
// 	** StdDeviation - Number -
// 	** Median - Number -
// Returns:
// 	Structure - LongDesc:
// 	* AutoMaxValue - Boolean -
// 	* MaxValue - Number -
// 	* AutoMinValue - Boolean -
// 	* MinValue - Number -
// 	* BaseValue - Number -
Function BasicValueParametersForCharts(AnalysisOption, PropertiesOfGeneralStatistics)
	BasicValueParametersForCharts = New Structure;
	BasicValueParametersForCharts.Insert("BaseValue",			StandardBaseValueForCharts());
	BasicValueParametersForCharts.Insert("MinValue",		0);
	BasicValueParametersForCharts.Insert("AutoMinValue",	True);
	BasicValueParametersForCharts.Insert("MaxValue",		0);
	BasicValueParametersForCharts.Insert("AutoMaxValue",	True);
	
	If (AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonStructure
		Or AnalysisOption.AnalysisType = Enums.IndicatorAnalysisTypes.ComponentWiseComparisonTrends)
		And AnalysisOption.ComponentWiseComparisonMode = 0 Then
		StatisticsUsed = PropertiesOfGeneralStatistics.ByObjectsOfAnalysis;
	Else
		StatisticsUsed = PropertiesOfGeneralStatistics.ByPeriods;
	EndIf;
	
	If AnalysisOption.ValueScaleMode = Enums.ChartValueScaleMode.Auto
		And Not AnalysisOption.Include_2Zero Then
		If Not (StatisticsUsed.Max > 0 And StatisticsUsed.Min < 0)
			And Not (StatisticsUsed.Max = 0 And StatisticsUsed.Min = 0)
			And Not StatisticsUsed.Range = 0 Then
			If StatisticsUsed.Min > 0 Then
				OrderOfNearestToZero = Log10(StatisticsUsed.Min);
			ElsIf StatisticsUsed.Min < 0 Then
				OrderOfNearestToZero = Log10(-StatisticsUsed.Max);
			Else
				OrderOfNearestToZero = 0;
			EndIf;
			OrderOfSweep = Log10(StatisticsUsed.Range);
			
			If OrderOfSweep < OrderOfNearestToZero Then
				If StatisticsUsed.Min >= 0 Then
					MinValue = StatisticsUsed.Min - Pow(10, OrderOfSweep - 1);
				Else
					MinValue = StatisticsUsed.Max + Pow(10, OrderOfSweep - 1);
				EndIf;
				
				BasicValueParametersForCharts.Insert("BaseValue", MinValue);
				BasicValueParametersForCharts.Insert("MinValue", MinValue);
				BasicValueParametersForCharts.Insert("AutoMinValue", False);
			EndIf;
		EndIf;
	ElsIf AnalysisOption.ValueScaleMode = Enums.ChartValueScaleMode.ByMinValue Then
		BasicValueParametersForCharts.Insert("BaseValue", StatisticsUsed.Min);
		BasicValueParametersForCharts.Insert("MinValue", StatisticsUsed.Min);
		BasicValueParametersForCharts.Insert("AutoMinValue", False);
	EndIf;
	
	Return BasicValueParametersForCharts;
EndFunction

// Returns the value of a number in the form of thousands, millions
// 
// Parameters:
//	OriginalNumber - Number - the number to be formatted
//	Digits - Number - number of decimal places
//
// Returns:
//	String - Representation of a number.
//
Function GetValueOfAbbreviatedPresentationOfNumber(OriginalNumber, Digits)
	
	MeaningOfAbbreviatedNumberPresentation = "";
	
	MeaningOfAbbreviatedNumberPresentation = StrReplace(Format(OriginalNumber, "NFD=" + Digits + ";NZ="), " ", Chars.NBSp);
	
	Return Number(MeaningOfAbbreviatedNumberPresentation);
	
EndFunction

// Returns the view of the metric's target value for the specified date/
//
// Parameters:
//		UpdateDate - Date - the date on which we want to get the view of the current target value.
//		AnalysisOption - CatalogRef.AnalysisOptionsOfTargetValues - Link to the analysis option.
//
// Returns:
//		- EnumRef.TargetValueKindsOfAnalysisOptions - Type of target value.
//		- Undefined -
//
Function GetTargetValueView(UpdateDate, AnalysisOption)
	TargetValueKind = Undefined;
	
	RequestingTargetValue = New Query;
	RequestingTargetValue.SetParameter("UpdateDate", UpdateDate);
	RequestingTargetValue.SetParameter("AnalysisOption", AnalysisOption.Ref);
	RequestingTargetValue.Text = "SELECT DISTINCT
	|	TargetValuesOfSliceAnalysisOptions.TargetValueKind
	|FROM
	|	InformationRegister.AnalysisOptionTargetValues.SliceLast(&PeriodParameter_, AnalysisOption = &AnalysisOption) AS TargetValuesOfSliceAnalysisOptions";
	
	PeriodBoundaryExpression = StringFunctionsClientServer.SubstituteParametersToString(
		"ENDOFPERIOD(&UpdateDate, %1)",
		Upper(GetNameOfEnumerationValue(AnalysisOption.IndicatorCalculationFrequency)));
	RequestingTargetValue.Text = StrReplace(RequestingTargetValue.Text, "&PeriodParameter_", PeriodBoundaryExpression);
	
	QueryResult = RequestingTargetValue.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		TargetValueKind = Selection.TargetValueKind;
	EndIf;
	
	Return TargetValueKind;
EndFunction


// Returns a table of target values.
// 
// Parameters:
// 	DatesArray - Array of Date - array of dates.
// 	AnalysisOption - Structure - Attributes of the analysis option.
// Returns:
// 	ValueTable - table with columns:
// 	 *Period - Date -
// 	 *TargetValueKind - EnumRef.TargetValueKindsOfAnalysisOptions -
// 	 *KindOfVarianceFromTargetValue - EnumRef.KindsOfVariancesFromTargetValues -
// 	 *TargetValue_ - Number -
// 	 *MinimumTargetRange - Number -
// 	 *MaximumTargetRange - Number -
// 	 *AdjustedNegativeBorderVariance - Number -
// 	 *AdjustedPositiveBorderVariance - Number -
// 	 *NegativeBorderVariance - Number -
// 	 *PositiveBorderVariance - Number -
//
Function GetTargetValuesForDates(DatesArray, AnalysisOption)
	
	NumberPresentationKinds = Enums.NumberPresentationKinds;
	
	DenominatorRequired = False;
	
	If AnalysisOption.ValueMultiplier = NumberPresentationKinds.InThousands Then
		Denominator = Format(Pow(10, 3), "NG=0;");
		DenominatorRequired = True;
	ElsIf AnalysisOption.ValueMultiplier = NumberPresentationKinds.InMillions Then
		Denominator = Format(Pow(10, 6), "NG=0;");
		DenominatorRequired = True;
	EndIf;
	
	Digits = AnalysisOption.FractionalPartCalculationAccuracy;
	
	TargetValueDates = New ValueTable;
	TargetValueDates.Columns.Add("TargetValueDate", Common.DateTypeDetails(DateFractions.Date));
	
	For Counter = 1 To DatesArray.Count() Do 
		TargetValueDates.Add();
	EndDo;
	
	TargetValueDates.LoadColumn(DatesArray, "TargetValueDate");
	
	RequestingTargetValues = New Query;
	RequestingTargetValues.SetParameter("TargetValueDates", TargetValueDates);
	RequestingTargetValues.SetParameter("AnalysisOption", AnalysisOption.Ref);
	Text =
	"SELECT
	|	TargetValueDates.TargetValueDate AS TargetValueDate
	|INTO TargetValueDates
	|FROM
	|	&TargetValueDates AS TargetValueDates
	|INDEX BY
	|	TargetValueDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TargetValueDates.TargetValueDate AS Period,
	|	TargetValuesOfSliceAnalysisOptions.TargetValueKind AS TargetValueKind,
	|	TargetValuesOfSliceAnalysisOptions.KindOfVarianceFromTargetValue AS KindOfVarianceFromTargetValue,
	|	&TargetValueExpression AS TargetValue_,
	|	&ExpressionTargetRangeMinimum AS MinimumTargetRange,
	|	&ExpressionTargetRangeMaximum AS MaximumTargetRange,
	|	&ExpressionReducedBoundaryNegativeDeviation AS AdjustedNegativeBorderVariance,
	|	&ExpressionReducedBoundaryPositiveDeviation AS AdjustedPositiveBorderVariance,
	|	CASE WHEN KindOfVarianceFromTargetValue = VALUE(Enum.KindsOfVariancesFromTargetValues.Absolute)
	|		THEN &ExpressionBoundaryNegativeDeviation
	|		ELSE TargetValuesOfSliceAnalysisOptions.NegativeBorderVariance
	|	END AS NegativeBorderVariance,
	|	CASE WHEN KindOfVarianceFromTargetValue = VALUE(Enum.KindsOfVariancesFromTargetValues.Absolute)
	|		THEN &ExpressionBoundaryPositiveDeviation
	|		ELSE TargetValuesOfSliceAnalysisOptions.PositiveBorderVariance
	|	END AS PositiveBorderVariance
	|FROM
	|	TargetValueDates AS TargetValueDates
	|		LEFT JOIN InformationRegister.AnalysisOptionTargetValues AS TargetValuesOfSliceAnalysisOptions
	|		ON TargetValueDates.TargetValueDate >= TargetValuesOfSliceAnalysisOptions.Period
	|WHERE
	|	TargetValuesOfSliceAnalysisOptions.AnalysisOption = &AnalysisOption";
	
	If DenominatorRequired Then
		ExpressionPattern = "CAST(%1 / %3 AS NUMBER(31, %2))";
	Else
		ExpressionPattern = "CAST(%1 AS NUMBER(31, %2))";
	EndIf;
	TargetValueExpression = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.TargetValue_",
		Digits,
		Denominator);
	ExpressionTargetRangeMinimum = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.MinimumTargetRange",
		Digits,
		Denominator);
	ExpressionTargetRangeMaximum = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.MaximumTargetRange",
		Digits,
		Denominator);
	ExpressionReducedBoundaryNegativeDeviation = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.AdjustedNegativeBorderVariance",
		Digits,
		Denominator);
	ExpressionReducedBoundaryPositiveDeviation = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.AdjustedPositiveBorderVariance",
		Digits,
		Denominator);
	ExpressionBoundaryNegativeDeviation = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.NegativeBorderVariance",
		Digits,
		Denominator);
	ExpressionBoundaryPositiveDeviation = StringFunctionsClientServer.SubstituteParametersToString(
		ExpressionPattern,
		"TargetValuesOfSliceAnalysisOptions.PositiveBorderVariance",
		Digits,
		Denominator);
	Text = StrReplace(Text, "&TargetValueExpression", TargetValueExpression);
	Text = StrReplace(Text, "&ExpressionTargetRangeMinimum", ExpressionTargetRangeMinimum);
	Text = StrReplace(Text, "&ExpressionTargetRangeMaximum", ExpressionTargetRangeMaximum);
	Text = StrReplace(Text, "&ExpressionReducedBoundaryNegativeDeviation", ExpressionReducedBoundaryNegativeDeviation);
	Text = StrReplace(Text, "&ExpressionReducedBoundaryPositiveDeviation", ExpressionReducedBoundaryPositiveDeviation);
	Text = StrReplace(Text, "&ExpressionBoundaryNegativeDeviation", ExpressionBoundaryNegativeDeviation);
	Text = StrReplace(Text, "&ExpressionBoundaryPositiveDeviation", ExpressionBoundaryPositiveDeviation);
	RequestingTargetValues.Text = Text;
	
	QueryResult = RequestingTargetValues.Execute();
	TargetValuesRanges = QueryResult.Unload();
	
	Return TargetValuesRanges;
EndFunction

Function ObjectIsInDatabase(TableName, Ref)
	Query = New Query("SELECT
	|	Table.Ref
	|FROM
	|	&SourceTable2 AS Table
	|WHERE
	|	Table.Ref = &Ref");
	SourceTable2 = StrReplace("Catalog.%1", "%1", TableName);
	Query.Text = StrReplace(Query.Text, "&SourceTable2", SourceTable2);
	Query.SetParameter("Ref", Ref);
	
	
	Return Not Query.Execute().IsEmpty();
EndFunction

Function CurrencyEUR()
	Currency = Catalogs.Currencies.EmptyRef();
	
	Query = New Query("SELECT
	|	Currencies.Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Code = &Code");
	Query.SetParameter("Code", "978");
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		Currency = Selection.Ref;
	EndIf;
	
	Return Currency;
EndFunction

Function CurrencyUSD()
	Currency = Catalogs.Currencies.EmptyRef();
	
	Query = New Query("SELECT
	|	Currencies.Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Code = &Code");
	Query.SetParameter("Code", "840");
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		Currency = Selection.Ref;
	EndIf;
	
	Return Currency;
EndFunction

Function CurrencyRUB()
	Currency = Catalogs.Currencies.EmptyRef();
	
	Query = New Query("SELECT
	|	Currencies.Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.Code = &Code");
	Query.SetParameter("Code", "643");
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		Selection.Next();
		
		Currency = Selection.Ref;
	EndIf;
	
	Return Currency;
EndFunction

#EndRegion

#EndRegion 