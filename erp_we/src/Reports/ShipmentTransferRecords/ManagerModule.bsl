#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 	- Undefined - If there are no rights to view the report.
//
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ShipmentTransferRecords) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ShipmentTransferRecords.FullName();
		ReportCommand.Presentation = NStr("ru = 'Документы отгрузки';
											|vi = 'Shipping documents';
											|en = 'Shipping documents'; fa = 'اسناد حمل';
											|it = 'Documenti della spedizione';
											|pl = 'Dokumenty wysyłki';
											|tr = 'Sevkiyat belgeleri'");
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ShipmentTransferRecords");
		ReportCommand.VariantKey = "Main";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ShipmentTransferRecords);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Chứng từ biến động theo lệnh';
									|ru = 'Документы движения по распоряжениям';
									|en = 'Transfer records by references'; fa = 'Transfer records by references';
									|it = 'Transfer records by references';
									|pl = 'Transfer records by references';
									|tr = 'Siparişlere dair kayıt tablosu belgeleri'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf