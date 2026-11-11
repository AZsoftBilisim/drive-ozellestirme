#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.CompanyStockBalance) 
			And GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CompanyStockBalance.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hàng tồn kho trong doanh nghiệp';
											|ru = 'Остатки товаров организаций';
											|en = 'Company stock balance'; fa = 'مانده موجودی شرکت';
											|it = 'Giacenze delle organizzazioni';
											|pl = 'Pozostałości towarów orgnizacji';
											|tr = 'İş yerlerinin ürün bakiyeleri'");
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CompanyStockBalance);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf