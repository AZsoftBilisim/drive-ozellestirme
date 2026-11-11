#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	ValueTableRow, Undefined - the generated command to output to the submenu.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.NonFinancialItemValues) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.NonFinancialItemValues.FullName();
		ReportCommand.Presentation = NStr("vi = 'Giá trị chỉ tiêu';
											|ru = 'Значения показателя';
											|en = 'Indicator value'; fa = 'مقدار شاخص';
											|it = 'Valori dell''indice';
											|pl = 'Wartości wskaźnika';
											|tr = 'Gösterge değeri'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "NonFinancialIndicatorValues";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.NonFinancialItemValues);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "NonFinancialItemValues");
	OptionDetails.LongDesc = NStr("vi = 'Xem xét giá trị các chỉ số phi tài chính theo kỳ.';
									|ru = 'Обзор значений нефинансовых показателей по периодам.';
									|en = 'View non-financial item values by periods.'; fa = 'View non-financial item values by periods.';
									|it = 'Обзор значений нефинансовых показателей по периодам.';
									|pl = 'Przegląd wartości wskaźników niefinansowych według okresów.';
									|tr = 'Dönemlere göre finansal olmayan öğe değerlerinin gözden geçirilmesi.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "NonFinancialIndicatorValues");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Details");
	
EndProcedure

#EndRegion

#EndRegion
	
#Region Private

Function PresentationOfPeriodByNumber(Period, PeriodNumber, Periodicity) Export
	
	Result = "";
	
	If Periodicity = Enums.Periodicity.Day Then
		Result = Format(Period, NStr("vi = 'ДФ=''дд ММММ''';
									|ru = 'ДФ=''dd MMMM''';
									|en = 'DF=''MMMM dd'''; fa = 'DF=''MMMM dd''';
									|it = 'ДФ=''дд ММММ''';
									|pl = 'DF=''dd MMMM''';
									|tr = 'DF=''dd MMMM'''"));
	ElsIf Periodicity = Enums.Periodicity.Week Then
		Template = NStr("vi = '%1 tuần';
						|ru = '%1 неделя';
						|en = '%1 week'; fa = '%1 week';
						|it = '%1 settimana';
						|pl = '%1 tydzień';
						|tr = '%1 hafta'");
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			Template, PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		Template = NStr("vi = '%1 mười ngày';
						|ru = '%1 декада';
						|en = 'ten-day period %1'; fa = 'ten-day period %1';
						|it = '%1 decade';
						|pl = '%1 dekada';
						|tr = '%1 on gün'");
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			Template, PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Result = Format(Period, NStr("vi = 'ДФ=''ММММ''';
									|ru = 'ДФ=''MMMM''';
									|en = 'DF=''MMMM'''; fa = 'DF=''MMMM''';
									|it = 'ДФ=''ММММ''';
									|pl = 'DF=''MMMM''';
									|tr = 'DF=''MMMM'''"));
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Template = NStr("vi = '%1 quý';
						|ru = '%1 квартал';
						|en = 'quarter %1'; fa = 'quarter %1';
						|it = '%1 trimestre';
						|pl = '%1 kwartał';
						|tr = '%1 çeyrek'");
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			Template, PeriodNumber);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Template = NStr("vi = '%1 nửa năm';
						|ru = '%1 полугодие';
						|en = 'half-year %1'; fa = 'half-year %1';
						|it = '%1 mezzo anno';
						|pl = '%1 półrocze';
						|tr = '%1 yarıyıl'");
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			Template, PeriodNumber);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the values of a non-financial indicator in a period, taking into account its type
//
// Parameters:
// 	TableOfIndicatorValues - ValueTable -  Non-financial indicator values for grouping
// 	UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure - Unit of measurement for a quantitative non-financial indicator
// 	NonFinancialItem - CatalogRef.NonFinancialItemsOfBudgets - Non-financial indicator.
// 	IndicatorKind - EnumRef.NonFinancialItemKinds - Type of non-financial indicator
// 	ByPeriods - Boolean - A sign that values are entered for the sub-periods
// 	ByCompanies - Boolean - Indicates that values are entered by organization
// 	ByBusinessUnits - Boolean - Indicates that values are entered by division
// 	NumberOfAnalysts - Number - Number of Analytics used for the financial indicator
// 	SetAValueForEachPeriod - Boolean - Indicates that you need to set a value for each period
// 	Period - Date - The current period of the report
// 	ReportFrequency - EnumRef.Periodicity - Frequency of report creation
// 	PeriodicityOfIndicator - EnumRef.Periodicity - Frequency of the indicator
// 	Group - String - Grouping for which the value of a non-financial indicator is returned
// 	DetailsMode - Boolean - Indicates that the report is running in decryption mode
// 	Cache - Map - Cache used when the function is running.
// 
// Returns:
// 	String - Representation of non-financial indicator values for the report period.
//
Function Attachable_MetricValueForGrouping(
		TableOfIndicatorValues,
		UnitOfMeasure,
		NonFinancialItem,
		IndicatorKind,
		ByPeriods,
		ByCompanies,
		ByBusinessUnits,
		NumberOfAnalysts,
		SetAValueForEachPeriod,
		Period,
		ReportFrequency,
		PeriodicityOfIndicator,
		Group,
		DetailsMode,
		Cache) Export
		
	Result = "";
	
	If Not ValueIsFilled(NonFinancialItem) Then
		Return Result;
	EndIf;
	
	MetricSettings = New Structure;
	MetricSettings.Insert("ByCompanies",     ByCompanies);
	MetricSettings.Insert("ByBusinessUnits",   ByBusinessUnits);
	MetricSettings.Insert("NumberOfAnalysts", NumberOfAnalysts);
	MetricSettings.Insert("DetailsMode",   DetailsMode);
	MetricSettings.Insert("TotalNumberOfDimensions", 0);
	
	TheOrderOfTheGroups = GetOrderOfDimensions(MetricSettings, Group);
	
	MetricSettings.Insert("TheOrderOfTheGroups", TheOrderOfTheGroups);
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	Groups = New Map;
	AddGrouping(Groups, MetricSettings, "NonFinancialItem");
	AddGrouping(Groups, MetricSettings, "Organization");
	AddGrouping(Groups, MetricSettings, "Department");
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		AddGrouping(Groups, MetricSettings, "Dimension" + DimensionNumber);
	EndDo;
	AddGrouping(Groups, MetricSettings, "Scenario");
	AddGrouping(Groups, MetricSettings, "Recorder");
	
	If Not Group = "Period" Then
		GroupingProperties = Groups.Get(Group);
		If Not GroupingProperties.Used
		 Or GroupingProperties.DimensionNumber_ <> MetricSettings.TotalNumberOfDimensions Then
			Return Result;
		EndIf;
	EndIf;
	
	EmptyTable = True;
	For Each TableRow In TableOfIndicatorValues Do
		If ValueIsFilled(TableRow.Value) Then
			EmptyTable = False;
			Break;
		EndIf;
	EndDo;
	
	If EmptyTable Then
		Return Result;
	EndIf;
	
	If TableOfIndicatorValues.Count() = 1
		And (ReportFrequency = PeriodicityOfIndicator 
			Or Not SetAValueForEachPeriod) Then
		String = TableOfIndicatorValues[0];
		Result = PresentationOfMetricValueByType(String.Value, IndicatorKind, String.Currency, UnitOfMeasure);
		Return Result;
	EndIf;
	
	PeriodEnding = WorkingWithClientServerPeriods.AddInterval(Period, ReportFrequency, 1, Cache) - 1;
	ArrayOfResultSubstrings = New Array;
	For Each String In TableOfIndicatorValues Do
		If ByPeriods Then
			If String.InstallationPeriod < Period Or String.InstallationPeriod > PeriodEnding Then
				Continue;
			EndIf;
			PeriodPresentation = Reports.NonFinancialItemValues.PresentationOfPeriodByNumber(String.InstallationPeriod, String.SubperiodNumber, PeriodicityOfIndicator);
		ElsIf SetAValueForEachPeriod Then
			PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(String.InstallationPeriod, PeriodicityOfIndicator);
		Else
			PeriodPresentation = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(String.InstallationPeriod, ReportFrequency);
		EndIf;
		
		ValuePresentation = PresentationOfMetricValueByType(
			String.Value, IndicatorKind, String.Currency, UnitOfMeasure, "-");
			
		ArrayOfResultSubstrings.Add(PeriodPresentation + ": " + ValuePresentation);
		
	EndDo;
	
	Result = StrConcat(
		ArrayOfResultSubstrings, 
		"
		|");
	
	Return Result;
	
EndFunction

Function GetOrderOfDimensions(MetricSettings, Group)
	
	TheOrderOfTheGroups = New Array;
	
	TheOrderOfTheGroups.Add("NonFinancialItem");
	If MetricSettings.ByCompanies Then
		TheOrderOfTheGroups.Add("Organization");
	EndIf;
	If MetricSettings.ByBusinessUnits Then
		TheOrderOfTheGroups.Add("Department");
	EndIf;
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		If DimensionNumber <= MetricSettings.NumberOfAnalysts Then
			NameOfAnalytics = "Dimension" + DimensionNumber;
			TheOrderOfTheGroups.Add(NameOfAnalytics);
		EndIf;
	EndDo;
	
	If MetricSettings.DetailsMode Then
		If Group = "Scenario" Then
			TheOrderOfTheGroups.Add("Scenario"); // The scenario in the column with the Period
		EndIf;
		If Group = "Recorder" Then
			TheOrderOfTheGroups.Add("Recorder");
		EndIf;
		
		If Group = "Organization"
			And Not MetricSettings.ByCompanies Then
			
			ThereAreGroupingsDeeperThanCur = MetricSettings.ByBusinessUnits
					Or MetricSettings.NumberOfAnalysts > 0;
			
			If Not ThereAreGroupingsDeeperThanCur Then
				TheOrderOfTheGroups.Add("Organization");
			EndIf;
		EndIf;
		If Group = "Department"
		   And Not MetricSettings.ByBusinessUnits Then
			
			ThereAreGroupingsDeeperThanCur = MetricSettings.NumberOfAnalysts > 0;
			
			If Not ThereAreGroupingsDeeperThanCur Then
				TheOrderOfTheGroups.Add("Department");
			EndIf;
		EndIf;
		
	EndIf;
		
	Return TheOrderOfTheGroups;
	
EndFunction

Procedure AddGrouping(Groups, MetricSettings, Group)
	
	TheOrderOfTheGroups = MetricSettings.TheOrderOfTheGroups;
	
	GroupingIndex = TheOrderOfTheGroups.Find(Group);
	
	If GroupingIndex <> Undefined Then
		GroupingProperties = New Structure("Used, DimensionNumber_", True, GroupingIndex + 1);
	Else
		GroupingProperties = New Structure("Used, DimensionNumber_", False, 0);
	EndIf;
	
	Groups.Insert(Group, GroupingProperties);
	If GroupingProperties.Used Then
		MetricSettings.TotalNumberOfDimensions = MetricSettings.TotalNumberOfDimensions + 1;
	EndIf;
	
EndProcedure

Function PresentationOfMetricValueByType(Value, IndicatorKind, Currency, UnitOfMeasure, BlankPresentation = "")
	
	If Not ValueIsFilled(Value) Then
		Return BlankPresentation;
	EndIf;
	
	If IndicatorKind = Enums.NonFinancialItemKinds.Cash_ Then
		Return Format(String(Value), "NFD=2") + " " + String(Currency);
	ElsIf IndicatorKind = Enums.NonFinancialItemKinds.Quantitative Then
		Return Format(String(Value), "ND=15; NFD=3") + " " + String(UnitOfMeasure);
	Else
		Return String(Value);
	EndIf;
	
EndFunction

#EndRegion

#EndIf