#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//  Undefined, ValueTableRow - Add a report command
//  
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.AccountSpecificationErrorsFinancialAccounting) 
			And GetFunctionalOption("UseFinancialAccounting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.AccountSpecificationErrorsFinancialAccounting.FullName();
		ReportCommand.Presentation = NStr("vi = 'Lỗi thanh toán';
											|ru = 'Ошибки уточнения счетов';
											|en = 'Account specification errors'; fa = 'خطاهای تعیین حساب';
											|it = 'Errori di correzione dei conti';
											|pl = 'Błędy uściślenia rachunków';
											|tr = 'Hesap iyileştirme hataları'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountSpecificationErrorsFinancialAccounting);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf