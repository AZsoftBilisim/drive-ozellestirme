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
	ReportSettings.LongDesc = NStr("vi = 'Danh sách và thống kê tổng hợp theo việc thực hiện nhiệm vụ.';
									|ru = 'Список и сводная статистика по выполнению заданий.';
									|en = 'Jobs and job execution summary.'; fa = 'Jobs and job execution summary.';
									|it = 'Elenco e statistiche riassuntive sull''esecuzione delle attività.';
									|pl = 'Lista i podsumowanie statystyczne dot. realizacji zadań.';
									|tr = 'Görevler ve görev tamamlama özeti.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "JobsList");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách tất cả nhiệm vụ trong kỳ đã chỉ ra.';
									|ru = 'Список всех заданий за указанный период.';
									|en = 'All jobs for the specified period.'; fa = 'All jobs for the specified period.';
									|it = 'Elenco di tutte le attività per il periodo specificato.';
									|pl = 'Lista wszystkich zadań dla określonego okresu.';
									|tr = 'Belirtilen dönem için tüm görevler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "JobsStatistics");
	OptionSettings.LongDesc = NStr("vi = 'Biểu đồ tổng hợp theo tất cả nhiệm vụ đã thực hiện, nhiệm vụ đã hủy bỏ và nhiệm vụ đang hoạt động.';
									|ru = 'Сводная диаграмма по всем выполненным, отмененным заданиям и заданиям в работе.';
									|en = 'Pivot chart of all tasks that are completed, canceled, or in progress.'; fa = 'Pivot chart of all tasks that are completed, canceled, or in progress.';
									|it = 'Diagramma di riepilogo per tutte le attività completate e annullate e le attività nel lavoro.';
									|pl = 'Diagram podsumowujący dla wszystkich zakończonych, anulowanych zadań i zadań w toku.';
									|tr = 'Tamamlanmış, iptal edilmiş ve devam eden tüm görevlerin özet grafiği.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "CheckExecutionCyclesStatistics");
	OptionSettings.LongDesc = NStr("vi = 'Top 10 tác giả về số lượng kiểm tra lại nhiệm vụ trung bình.';
									|ru = 'Топ 10 авторов по среднему количеству перепроверок заданий.';
									|en = 'Top 10 authors by average time of job counterchecks.'; fa = 'Top 10 authors by average time of job counterchecks.';
									|it = '10 principali autori per il numero medio di controlli incrociati sul lavoro.';
									|pl = 'Top 10 autorów dot. średniej liczby ponownych sprawdzeń zadań.';
									|tr = 'Ortalama tekrar kontrol etmeye göre en iyi 10 yazar.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DurationStatistics");
	OptionSettings.LongDesc = NStr("vi = 'Top 10 tác giả về thời lượng thực hiện nhiệm vụ trung bình.';
									|ru = 'Топ 10 авторов по средней длительности выполнения заданий.';
									|en = 'Top 10 authors by average time of job completion.'; fa = 'Top 10 authors by average time of job completion.';
									|it = '10 principali autori per il velocità media di realizzazione dei compiti.';
									|pl = 'Top 10 autorów dot. średniego czasu trwania zadań.';
									|tr = 'Ortalama görev tamamlama süresine göre en iyi 10 yazar.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf