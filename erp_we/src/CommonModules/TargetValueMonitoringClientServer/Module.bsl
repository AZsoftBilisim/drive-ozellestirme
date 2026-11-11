#Region Public

// Returns standard settings for creating a target monitor
//
// Returns:
//	Structure - Standard settings:
//		* IndicatorGroupingOption - String - "Goal categories", grouping indicators by goal categories
//		* NumberOfIndicatorMonitorColumns - Number - 3 columns, number of columns
//		* ChartSize - Number - large (2), the height is approximately equal to the width
//		* ArbitraryScale - Number - 100 %, the default zoom value
//		* DetailDisplayOption - String - "Show only current value" - only the current value
//		* AutoRefreshPeriod - Number - 15 min. The number of minutes after which the data on the form should be automatically updated.
//
Function ExchangeDefaultSettings() Export
	
	DefaultSettings = New Structure;
	
	// the order of output of indicators
	DefaultSettings.Insert("IndicatorGroupingOption", "ByGoalCategory");
	DefaultSettings.Insert("NumberOfIndicatorMonitorColumns", 3);
	
	// Appearance of indicators
	DefaultSettings.Insert("ChartSize", 1);
	DefaultSettings.Insert("ArbitraryScale", 100);
	DefaultSettings.Insert("DetailDisplayOption", "ShowOnlyCurValue");
	
	// Data refresh
	DefaultSettings.Insert("AutoRefreshPeriod", 15);
	
	// Selecting Indicators
	DefaultSettings.Insert("DisplayIndicatorFilter", False);
	
	Return DefaultSettings;
	
EndFunction

// Returns the names of the enumeration Periodicity in different declensions
//
// Parameters:
//	NumberOfPeriods_ - Number - the number of periods determines the declination
//	Periodicity - a reference to the value of the "Periodicity" enumeration.
//
// Returns:
//  String - the name of the period is in the correct declension.
//
Function PeriodInWords(NumberOfPeriods_, Periodicity) Export
	PeriodInWords = "";
	FormatString = "";
	NumerationItemOptions = "";
	
	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		NumerationItemOptions = NStr("vi = 'ngày';
									|ru = 'день, дня, дней, м';
									|en = 'day, days, days'; fa = 'day, days, days';
									|it = 'giorno, del giorno, dei giorni, m';
									|pl = 'dzień, dnia, dni, m';
									|tr = 'gün, gün, günler'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = 'ngày';
										|ru = 'дня';
										|en = 'Day'; fa = 'روز';
										|it = 'del giorno';
										|pl = 'dnia';
										|tr = 'gün'")) Then
			PeriodInWords = NStr("vi = 'ngày';
								|ru = 'дня';
								|en = 'Day'; fa = 'روز';
								|it = 'del giorno';
								|pl = 'dnia';
								|tr = 'gün'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'ngày';
											|ru = 'дня';
											|en = 'day'; fa = 'روز';
											|it = 'del giorno';
											|pl = 'dnia';
											|tr = 'gün'")) Then
			PeriodInWords = NStr("vi = 'ngày';
								|ru = 'дня';
								|en = 'day'; fa = 'روز';
								|it = 'del giorno';
								|pl = 'dnia';
								|tr = 'gün'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'ngày';
											|ru = 'дней';
											|en = 'days'; fa = 'روز';
											|it = 'di giorni';
											|pl = 'dni';
											|tr = 'günler'")) Then
			PeriodInWords = NStr("vi = 'ngày';
								|ru = 'дней';
								|en = 'days'; fa = 'روز';
								|it = 'di giorni';
								|pl = 'dni';
								|tr = 'günler'");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		NumerationItemOptions = NStr("vi = 'tuần, tuần, tuần, w';
									|ru = 'неделя, недели, недель, ж';
									|en = 'week, weeks, weeks'; fa = 'week, weeks, weeks';
									|it = 'settimana, della settimana, delle settimane, g';
									|pl = 'tydzień, tygodnia, tygodni, ж';
									|tr = 'hafta, haftalar, hafta'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = 'tuần';
										|ru = 'неделя';
										|en = 'week'; fa = 'هفته';
										|it = 'settimana';
										|pl = 'week';
										|tr = 'hafta'")) Then
			PeriodInWords = NStr("vi = 'tuần';
								|ru = 'неделя';
								|en = 'week'; fa = 'هفته';
								|it = 'settimana';
								|pl = 'tydzień';
								|tr = 'hafta'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'tuần';
											|ru = 'недель';
											|en = 'weeks'; fa = 'هفته';
											|it = 'delle settimane';
											|pl = 'weeks';
											|tr = 'hafta'")) Then
			PeriodInWords = NStr("vi = 'tuần';
								|ru = 'недель';
								|en = 'weeks'; fa = 'هفته';
								|it = 'delle settimane';
								|pl = 'tygodni';
								|tr = 'hafta'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'tuần';
											|ru = 'недель';
											|en = 'weeks'; fa = 'هفته';
											|it = 'delle settimane';
											|pl = 'weeks';
											|tr = 'hafta'")) Then
			PeriodInWords = NStr("vi = 'tuần';
								|ru = 'недель';
								|en = 'weeks'; fa = 'هفته';
								|it = 'delle settimane';
								|pl = 'tygodni';
								|tr = 'hafta'");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.TenDays") Then
		NumerationItemOptions = NStr("vi = 'mười ngày, mười ngày, mười ngày, w';
									|ru = 'декада, декады, декад, ж';
									|en = 'ten-day period, ten-day periods, ten-day periods'; fa = 'ten-day period, ten-day periods, ten-day periods';
									|it = 'decade, della decade, delle decadi, g';
									|pl = 'dekada, dekady, dekad, ж';
									|tr = '10 günlük süre, 10 günlük süreler, 10 günlük süre'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = '10 ngày';
										|ru = 'декада';
										|en = 'ten-day period'; fa = 'ten-day period';
										|it = 'decade';
										|pl = 'dekada';
										|tr = '10 günlük süre'")) Then
			PeriodInWords = NStr("vi = '10 ngày';
								|ru = 'декада';
								|en = 'ten-day period'; fa = 'ten-day period';
								|it = 'decade';
								|pl = 'dekada';
								|tr = '10 günlük süre'");
		ElsIf StrFind(PeriodInWords, NStr("vi = '10 ngày';
											|ru = 'декады';
											|en = 'ten-day periods'; fa = 'ten-day periods';
											|it = 'della decade';
											|pl = 'ten-day periods';
											|tr = '10 günlük süreler'")) Then
			PeriodInWords = NStr("vi = '10 ngày';
								|ru = 'декады';
								|en = 'ten-day periods'; fa = 'ten-day periods';
								|it = 'della decade';
								|pl = 'dekady';
								|tr = '10 günlük süreler'");
		ElsIf StrFind(PeriodInWords, NStr("vi = '10 ngày';
											|ru = 'декады';
											|en = 'ten-day periods'; fa = 'ten-day periods';
											|it = 'della decade';
											|pl = 'ten-day periods';
											|tr = '10 günlük süreler'")) Then
			PeriodInWords = NStr("vi = '10 ngày';
								|ru = 'декады';
								|en = 'ten-day periods'; fa = 'ten-day periods';
								|it = 'della decade';
								|pl = 'dekady';
								|tr = '10 günlük süreler'");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Month") Then
		NumerationItemOptions = NStr("vi = 'tháng, tháng, tháng, м';
									|ru = 'месяц, месяца, месяцев, м';
									|en = 'month, months, months'; fa = 'month, months, months';
									|it = 'mese, del mese, dei mesi, m';
									|pl = 'miesiąc, miesiąca, miesięcy, m';
									|tr = 'ay, ay, aylar'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = 'tháng ';
										|ru = 'месяцев';
										|en = 'months'; fa = 'ماه';
										|it = 'di mesi';
										|pl = 'months';
										|tr = 'aylar'")) Then
			PeriodInWords = NStr("vi = 'tháng ';
								|ru = 'месяцев';
								|en = 'months'; fa = 'ماه';
								|it = 'di mesi';
								|pl = 'miesięcy';
								|tr = 'aylar'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'tháng';
											|ru = 'месяца';
											|en = 'month'; fa = 'ماه';
											|it = 'del mese';
											|pl = 'month';
											|tr = 'ay'")) Then
			PeriodInWords = NStr("vi = 'tháng';
								|ru = 'месяца';
								|en = 'month'; fa = 'ماه';
								|it = 'del mese';
								|pl = 'miesiąca';
								|tr = 'ay'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'tháng';
											|ru = 'месяца';
											|en = 'month'; fa = 'ماه';
											|it = 'del mese';
											|pl = 'month';
											|tr = 'ay'")) Then
			PeriodInWords = NStr("vi = 'tháng';
								|ru = 'месяца';
								|en = 'month'; fa = 'ماه';
								|it = 'del mese';
								|pl = 'miesiąca';
								|tr = 'ay'");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Quarter") Then
		NumerationItemOptions = NStr("vi = 'quý, quý, quý, м';
									|ru = 'квартал, квартала, кварталов, м';
									|en = 'quarter, quarter, quarters'; fa = 'quarter, quarter, quarters';
									|it = 'trimestre, del trimestre, dei trimestri, m';
									|pl = 'kwartał, kwartału, kwartałów, м';
									|tr = 'çeyrek, çeyrek, çeyrekler'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = 'quý';
										|ru = 'кварталов';
										|en = 'quarters'; fa = 'quarters';
										|it = 'dei trimestri';
										|pl = 'quarters';
										|tr = 'çeyrekler'")) Then
			PeriodInWords = NStr("vi = 'quý';
								|ru = 'кварталов';
								|en = 'quarters'; fa = 'quarters';
								|it = 'dei trimestri';
								|pl = 'kwartałów';
								|tr = 'çeyrekler'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'quý';
											|ru = 'квартала';
											|en = 'quarter'; fa = 'quarter';
											|it = 'del trimestre';
											|pl = 'quarter';
											|tr = 'çeyrek'")) Then
			PeriodInWords = NStr("vi = 'quý';
								|ru = 'квартала';
								|en = 'quarter'; fa = 'quarter';
								|it = 'del trimestre';
								|pl = 'kwartału';
								|tr = 'çeyrek'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'quý';
											|ru = 'квартала';
											|en = 'quarter'; fa = 'quarter';
											|it = 'del trimestre';
											|pl = 'quarter';
											|tr = 'çeyrek'")) Then
			PeriodInWords = NStr("vi = 'quý';
								|ru = 'квартала';
								|en = 'quarter'; fa = 'quarter';
								|it = 'del trimestre';
								|pl = 'kwartału';
								|tr = 'çeyrek'");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.HalfYear") Then
		NumerationItemOptions = NStr("vi = 'nửa năm';
									|ru = 'полугодие, полугодия, полугодий, с';
									|en = 'half-year, half-years'; fa = 'half-year, half-years';
									|it = 'semestre, del semestre, dei semestri, s';
									|pl = 'półrocze, półrocza, półrocz, с';
									|tr = 'yarıyıl, yarıyıllar, yarıyılların,'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = 'nửa năm';
										|ru = 'полугодие';
										|en = 'half-year'; fa = 'نیم‌سال';
										|it = 'semestre';
										|pl = 'półrocze';
										|tr = 'yarıyıl'")) Then
			PeriodInWords = NStr("vi = 'nửa năm';
								|ru = 'полугодие';
								|en = 'half-year'; fa = 'نیم‌سال';
								|it = 'semestre';
								|pl = 'półrocze';
								|tr = 'yarıyıl'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'nửa năm';
											|ru = 'полугодия';
											|en = 'half-year periods'; fa = 'half-year periods';
											|it = 'del semestre';
											|pl = 'half-year periods';
											|tr = 'yarıyıl'")) Then
			PeriodInWords = NStr("vi = 'nửa năm';
								|ru = 'полугодия';
								|en = 'half-year periods'; fa = 'half-year periods';
								|it = 'del semestre';
								|pl = 'półrocza';
								|tr = 'yarıyıl'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'nửa năm';
											|ru = 'полугодия';
											|en = 'half-year periods'; fa = 'half-year periods';
											|it = 'del semestre';
											|pl = 'half-year periods';
											|tr = 'yarıyıl'")) Then
			PeriodInWords = NStr("vi = 'nửa năm';
								|ru = 'полугодия';
								|en = 'half-year periods'; fa = 'half-year periods';
								|it = 'del semestre';
								|pl = 'półrocza';
								|tr = 'yarıyıl'");
		EndIf;
	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Year") Then
		NumerationItemOptions = NStr("vi = 'năm, năm, năm, м';
									|ru = 'год, года, лет, м';
									|en = 'year, years, years'; fa = 'year, years, years';
									|it = 'anno, dell''anno, degli anni, m';
									|pl = 'rok, roku, lat, м';
									|tr = 'sene, sene, yıl'");
		PeriodInWords = NumberInWords(NumberOfPeriods_, FormatString, NumerationItemOptions);
		
		If StrFind(PeriodInWords, NStr("vi = 'năm';
										|ru = 'года';
										|en = 'year'; fa = 'سال';
										|it = 'dell''anno';
										|pl = 'year';
										|tr = 'sene'")) Then
			PeriodInWords = NStr("vi = 'năm';
								|ru = 'года';
								|en = 'year'; fa = 'سال';
								|it = 'dell''anno';
								|pl = 'lata';
								|tr = 'sene'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'năm';
											|ru = 'года';
											|en = 'year'; fa = 'سال';
											|it = 'dell''anno';
											|pl = 'year';
											|tr = 'sene'")) Then
			PeriodInWords = NStr("vi = 'năm';
								|ru = 'года';
								|en = 'year'; fa = 'سال';
								|it = 'dell''anno';
								|pl = 'lata';
								|tr = 'sene'");
		ElsIf StrFind(PeriodInWords, NStr("vi = 'năm';
											|ru = 'лет';
											|en = 'years'; fa = 'سال';
											|it = 'degli anni';
											|pl = 'years';
											|tr = 'yıl'")) Then
			PeriodInWords = NStr("vi = 'năm';
								|ru = 'лет';
								|en = 'years'; fa = 'سال';
								|it = 'degli anni';
								|pl = 'lat';
								|tr = 'yıl'");
		EndIf;
	EndIf;
	
	Return PeriodInWords;
EndFunction

// Returns the structure of settings for forming the monitor composition
//
// Returns:
//	Structure - an unfilled structure with the required properties:
//		* DynamicParameterAddresses - String - specifies the time settings for displaying analysis options in the target monitor.
//		* SearchType - EnumRef.KindsOfAssociatedIndicatorSearch, String - the dependent variable, impact, connected, everything.
//		* DemoMode - Boolean - indicates whether to display demo data for analysis options.
//		* AnalysisOptionFilter - CatalogRef.AnalysisOptionsOfTargetValues, Array - data selection based on a link to an analysis option.
//		* FilterAreaOfInterest - Number - this parameter is deprecated and left for compatibility.
//		* FilterStatus - String - selection of analysis options based on their status. 
//			Takes the values: "" (without taking into account the state), "Target Reached", "Acceptable State", "Unacceptable State", "State Undefined", "Calculated With Errors".
//		* ControlCycle - EnumRef.Periodicity - selection of analysis options based on the relevant details
//		* ForceUpdateData - Boolean - indicates that the cache is updated earlier than the scheduled time
//		* AnalysisModeOfTheRelated - Boolean - indicates that related metrics are being analyzed
//		* PropertiesOfAnalysisVariant - Structure - Properties:
//			** Ref - CatalogRef.AnalysisOptionsOfTargetValues - analysis option for which data will be obtained
//			** AnalysisPeriod - ValueStorage - contains a Packed standard Period describing the data sampling period
//		* SettingsStructure - See TargetValueMonitoring.GetGoalMonitorSettings
//		* ConsiderDisplayOptions - Boolean - True, preparing data to display as a table, chart, or text.
//
Function InitializingMonitorCompositionParameters() Export
	MonitorCompositionParameters = New Structure;
	MonitorCompositionParameters.Insert("DynamicParameterAddresses",);
	MonitorCompositionParameters.Insert("SearchType",);
	MonitorCompositionParameters.Insert("DemoMode",);
	MonitorCompositionParameters.Insert("AnalysisOptionFilter",);
	MonitorCompositionParameters.Insert("FilterAreaOfInterest",);
	MonitorCompositionParameters.Insert("FilterStatus",);
	MonitorCompositionParameters.Insert("ControlCycle",);
	MonitorCompositionParameters.Insert("ForceUpdateData",);
	MonitorCompositionParameters.Insert("AnalysisModeOfTheRelated",);
	MonitorCompositionParameters.Insert("PropertiesOfAnalysisVariant",);
	MonitorCompositionParameters.Insert("SettingsStructure",);
	MonitorCompositionParameters.Insert("ConsiderDisplayOptions",);
	
	Return MonitorCompositionParameters;
EndFunction

#EndRegion
