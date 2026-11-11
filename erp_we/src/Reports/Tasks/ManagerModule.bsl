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
	ReportSettings.LongDesc = NStr("vi = 'Danh sách và thống kê tổng hợp theo nhiệm vụ.';
									|ru = 'Список и сводная статистика по задачам.';
									|en = 'Task list and summary.'; fa = 'Task list and summary.';
									|it = 'Elenco e statistiche riassuntive sulle attività.';
									|pl = 'Lista i podsumowanie statystyczne dot. zadań.';
									|tr = 'Görev listesi ve özet.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "CurrentTasks");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách tất cả nhiệm vụ đang làm việc đến thời hạn đã đặt.';
									|ru = 'Список всех задач в работе к заданному сроку.';
									|en = 'All tasks in progress by the specified due date.'; fa = 'All tasks in progress by the specified due date.';
									|it = 'Un elenco di tutte le attività nel lavoro ad una determinata data.';
									|pl = 'Lista wszystkich zadań w pracy do określonej daty.';
									|tr = 'Belirtilen bitiş tarihine kadar devam eden tüm görevler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "PerformerDisciplineSummary");
	OptionSettings.LongDesc = NStr("vi = 'Tổng hợp theo số lượng nhiệm vụ đang thực hiện quá hạn và đúng hạn của người thực hiện.';
									|ru = 'Сводка по количеству выполненных в срок и просроченных задачах у исполнителей.';
									|en = 'Overdue tasks and tasks completed on schedule summary by assignee.'; fa = 'Overdue tasks and tasks completed on schedule summary by assignee.';
									|it = 'Riepilogo del numero di attività completate e attività scadute degli esecutori.';
									|pl = 'Podsumowanie dla liczby wykonanych zadań i zaległych zadań u wykonawców.';
									|tr = 'Vadesi geçmiş görevler ve vaktinde tamamlanmış görevlerin atanana göre özeti'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf