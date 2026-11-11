

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "UseOfCashFlowLimits");
	OptionSettings.LongDesc =
		NStr("vi = 'Chỉ số kế hoạch thực tế về hạn mức chi tiêu tiền mặt';
			|ru = 'План-факт анализ лимитов расходования денежных средств';
			|en = 'Variance analysis of cash flow limits'; fa = 'Variance analysis of cash flow limits';
			|it = 'Analisi obiettivo-reale dei limiti di spesa dei mezzi monetari';
			|pl = 'Plan-fakt analiza limitów wydatkowania środków pieniężnych';
			|tr = 'Veri-plan analiz limiti nakit türleri harcamaları'");
	
EndProcedure

Function PresentationOfReportAnalyticsWithShift(AnalyticsPresentation, GroupingLevel) Export
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1%2';
			|ru = '%1%2';
			|en = '%1%2'; fa = '%1%2';
			|it = '%1%2';
			|pl = '%1%2';
			|tr = '%1%2'"),
		ShiftingReportDimensions(GroupingLevel),
		AnalyticsPresentation);
EndFunction

// Returns a string of empty characters for the grouping level shift.
// The length of the shift depends on the level of grouping.
//
// Parameters:
// 	GroupingLevel - Number - The grouping level of the report.
//
// Returns:
// 	String - A string of empty characters before the representation of the grouping value.
//
Function ShiftingReportDimensions(GroupingLevel)
	Return StringFunctionsClientServer.GenerateCharacterString("  ", GroupingLevel);
EndFunction

#EndRegion

#EndIf