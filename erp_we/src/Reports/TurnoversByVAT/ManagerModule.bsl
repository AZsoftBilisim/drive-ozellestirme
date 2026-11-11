//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TurnoversByVAT);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc =
		NStr("vi = 'Phát sinh theo thuế GTGT đầu ra và đầu vào trong kỳ.';
			|ru = 'Обороты по входящему и исходящему НДС за период.';
			|en = 'Input and output VAT turnovers for the period.'; fa = 'Input and output VAT turnovers for the period.';
			|it = 'Обороты по входящему и исходящему НДС за период.';
			|pl = 'Obroty wg wchodzącego i wychodzącego VAT za okres.';
			|tr = 'Dönem için giriş ve çıkış KDV ciroları.'");
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
