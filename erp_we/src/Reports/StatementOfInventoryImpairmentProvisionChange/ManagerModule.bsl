#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//   ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.StatementOfInventoryImpairmentProvisionChange) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StatementOfInventoryImpairmentProvisionChange.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính lưu chuyển dự phòng giảm giá vật tư';
											|ru = 'Справка-расчет движения резервов под обесценение запасов';
											|en = 'Statement of movement in provisions for inventory impairment'; fa = 'Statement of movement in provisions for inventory impairment';
											|it = 'Calcolo di riferimento dei movimenti delle scorte in deterioramento';
											|pl = 'Zaświadczenie-rozliczenie przepływu rezerw pod utratę wartości zapasów';
											|tr = 'Stokların değer düşüklüğü rezerv hareketlerini hesaplama özeti'");
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatementOfInventoryImpairmentProvisionChange);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Số dư dự phòng được hình thành bằng cách nào tại thời điểm bắt đầu tính?';
									|ru = 'Каким образом сформировался остаток резерва на момент начала расчета?';
									|en = 'How was the provision balance generated at the beginning of the calculation?'; fa = 'How was the provision balance generated at the beginning of the calculation?';
									|it = 'Каким образом сформировался остаток резерва на момент начала расчета?';
									|pl = 'W jaki sposób zostało utworzone saldo rezerwy na moment rozpoczęcia rozliczenia?';
									|tr = 'Hesaplamanın başladığı tarihte karşılık bakiyesi nasıl oluştu?'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf