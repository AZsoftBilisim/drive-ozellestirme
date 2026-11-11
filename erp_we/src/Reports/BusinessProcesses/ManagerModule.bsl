///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ReportsOptions

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ReportSettings.LongDesc = NStr("vi = 'Danh sách và thống kê tổng hợp theo tất cả quy trình nghiệp vụ.';
									|ru = 'Список и сводная статистика по всем бизнес-процессам.';
									|en = 'Business process list and summary.'; fa = 'Business process list and summary.';
									|it = 'Elenco e statistiche riassuntive per tutti i processi aziendali.';
									|pl = 'Lista i statystyki podsumowujące dla wszystkich procesów biznesowych.';
									|tr = 'İş süreçleri listesi ve özeti.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "BusinessProcessesList");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách quy trình nghiệp vụ của dạng cụ thể trong kỳ đã chỉ ra.';
									|ru = 'Список бизнес-процессов определенных видов за указанный интервал.';
									|en = 'Business processes of certain types for the specified period.'; fa = 'Business processes of certain types for the specified period.';
									|it = 'Elenco di processi aziendali di determinati tipi per un intervallo specificato.';
									|pl = 'Lista procesów biznesowych niektórych typów dla określonego przedziału.';
									|tr = 'Belirtilen dönem için belirli iş süreci türleri.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "StatisticsByKinds");
	OptionSettings.LongDesc = NStr("vi = 'Biểu mẫu tổng hợp theo số lượng quy trình nghiệp vụ đã hoàn thiện và quy trình nghiệp vụ đang hoạt động.';
									|ru = 'Сводная диаграмма по количеству активных и завершенных бизнес-процессов.';
									|en = 'Pivot chart of all active and completed business processes.'; fa = 'Pivot chart of all active and completed business processes.';
									|it = 'Grafico riassuntivo del numero di processi aziendali attivi e completati.';
									|pl = 'Diagram podsumowujący liczbę aktywnych i zakończonych procesów biznesowych.';
									|tr = 'Tüm devam eden ve tamamlanmış iş süreçlerinin özet grafiği.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf