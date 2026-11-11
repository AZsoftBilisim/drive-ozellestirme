#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//     ValueTableRow
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.CheckBudgetItemLinks) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CheckBudgetItemLinks.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm tra cài đặt liên kết';
											|ru = 'Проверить настройку связей';
											|en = 'Check link configuration'; fa = 'Check link configuration';
											|it = 'Controlla l''impostazione dei collegamenti';
											|pl = 'Sprawdź ustawienia komunikacyjne';
											|tr = 'Bağlantı ayarlarını kontrol et'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "CheckingRelationshipsOfBudgetIndicator";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CheckBudgetItemLinks);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra sự phù hợp giữa tùy chỉnh các dạng LCTT liên quan với quy tắc nhận dữ liệu thực tế của các chỉ tiêu ngân sách.';
									|ru = 'Проверка соответствия настройки связанных статей правилам получения фактических данных показателей бюджетов.';
									|en = 'Verify consistency between budget item settings and rules used to retrieve actual data.'; fa = 'Verify consistency between budget item settings and rules used to retrieve actual data.';
									|it = 'Проверка соответствия настройки связанных статей правилам получения фактических данных показателей бюджетов.';
									|pl = 'Weryfikacja zgodności ustawienia powiązanych pozycji regułom otrzymania faktycznych danych wskaźników budżetów.';
									|tr = 'İlgili kalemlerin ayarlarının bütçe kalemlerinin gerçek verilerini elde etme kurallarına uygun olup olmadığının kontrol edilmesi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CheckBudgetItemLinks");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra sự phù hợp giữa tùy chỉnh các dạng LCTT liên quan với quy tắc nhận dữ liệu thực tế của các chỉ tiêu ngân sách.';
									|ru = 'Проверка соответствия настройки связанных статей правилам получения фактических данных показателей бюджетов.';
									|en = 'Verify consistency between budget item settings and rules used to retrieve actual data.'; fa = 'Verify consistency between budget item settings and rules used to retrieve actual data.';
									|it = 'Проверка соответствия настройки связанных статей правилам получения фактических данных показателей бюджетов.';
									|pl = 'Weryfikacja zgodności ustawienia powiązanych pozycji regułom otrzymania faktycznych danych wskaźników budżetów.';
									|tr = 'İlgili kalemlerin ayarlarının bütçe kalemlerinin gerçek verilerini elde etme kurallarına uygun olup olmadığının kontrol edilmesi.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CheckingRelationshipsOfBudgetIndicator");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf