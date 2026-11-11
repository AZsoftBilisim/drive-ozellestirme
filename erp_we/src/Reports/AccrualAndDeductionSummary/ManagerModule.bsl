#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Configures the options for the report "Analysis of Accruals and HR deductions".
//
// Parameters:
//   Settings - Structure - Report Options Settings
//   ReportSettings - Structure - report settings
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ReportsOptions.OptionDetails(Settings, ReportSettings, "SummaryOfAccrualsAndDeductions");
	OptionSettings.LongDesc =
		NStr("ru = 'Свод начислений и удержаний';
			|vi = 'Accrual and deduction summary';
			|en = 'Accrual and deduction summary'; fa = 'خلاصه محاسبات و کسورات';
			|it = 'Accrual and deduction summary';
			|pl = 'Accrual and deduction summary';
			|tr = 'Tahakkuk ve kesinti özeti'");
		
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf