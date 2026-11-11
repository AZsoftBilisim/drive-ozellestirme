#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  ValueTableRow, Undefined - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ProductRangeState) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ProductRangeState.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái danh điểm mặt hàng';
											|ru = 'Состояние ассортимента';
											|en = 'Product range state'; fa = 'وضعیت دامنه محصول';
											|it = 'Stato dell''assortimento';
											|pl = 'Stan asortymentu';
											|tr = 'Ürün gamı durumu'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "ProductRangeState");
		
		ReportCommand.VariantKey = "BasicContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductRangeState);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf