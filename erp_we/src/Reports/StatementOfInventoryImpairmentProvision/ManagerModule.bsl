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
	
	If AccessRight("View", Metadata.Reports.StatementOfInventoryImpairmentProvision) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StatementOfInventoryImpairmentProvision.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính dự phòng giảm giá vật tư';
											|ru = 'Справка-расчет резервов под обесценение запасов';
											|en = 'Statement of provisions for inventory impairment'; fa = 'صورت ذخایر کاهش ارزش موجودی';
											|it = 'Calcolo di riferimento delle scorte in deterioramento';
											|pl = 'Zaświadczenie-rozliczenie rezerw pod utratę wartości zapasów';
											|tr = 'Stokların değer düşüklüğü rezervlerini hesaplama özeti'");
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatementOfInventoryImpairmentProvision);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Việc tính toán lập/phục hồi dự phòng trong kỳ đã chọn được thực hiện bằng cách nào?';
									|ru = 'Каким образом был произведен расчет формирования/восстановления резерва в выбранном периоде?';
									|en = 'How was the provision generation/recovery calculated in the selected period?'; fa = 'How was the provision generation/recovery calculated in the selected period?';
									|it = 'Каким образом был произведен расчет формирования/восстановления резерва в выбранном периоде?';
									|pl = 'W jaki sposób zostało wykonane obliczenie tworzenia/przywrócenia rezerwy w wybranym okresie?';
									|tr = 'Seçilen dönemde karşılık oluşumu / geri yüklemenin hesaplanması nasıldı?'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf