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
	ReportSettings.LongDesc = NStr("vi = 'Phân tích các nhiệm vụ bị treo mà chưa thực hiện, bởi vì trong đó chưa ấn định người thực hiện.';
									|ru = 'Анализ зависших задач, которые не могут быть выполнены, так как у них не назначены исполнители.';
									|en = 'Unassigned tasks analysis (tasks not assigned to any users).'; fa = 'Unassigned tasks analysis (tasks not assigned to any users).';
									|it = 'Analisi delle attività bloccate che non possono essere eseguite, perché non non sono state loro assegnati degli esecutori.';
									|pl = 'Analiza zawieszonych zadań, których nie można wykonać, ponieważ nie przeznaczono wykonawców.';
									|tr = 'Atanmayan görevler analizi (hiçbir kullanıcın atanmadığı görevler).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksSummary");
	OptionSettings.LongDesc = NStr("vi = 'Tổng hợp theo số lượng nhiệm vụ bị treo đã ấn định cho vai trò mà chưa xác định bất kỳ người thực hiện nào.';
									|ru = 'Сводка по количеству зависших задач, назначенных на роли, для которых не задано ни одного исполнителя.';
									|en = 'Unassigned tasks summary (tasks assigned to blank roles).'; fa = 'Unassigned tasks summary (tasks assigned to blank roles).';
									|it = 'Riepilogo del numero di obiettivi bloccati assegnati ai ruoli per i quali non è stato assegnato alcun esecutore.';
									|pl = 'Podsumowanie dot. liczby zawieszonych zadań, przeznaczonych do ról, dla których nie określono wykonawcy.';
									|tr = 'Atanmayan görevler toplamı (boş rollere atanan görevler).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksByPerformers");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách nhiệm vụ đang treo được ấn định cho vai trò mà chưa xác định bất kỳ người thực hiện nào.';
									|ru = 'Список зависших задач, назначенных на роли, для которых не задано ни одного исполнителя.';
									|en = 'Unassigned tasks (tasks assigned to blank roles).'; fa = 'Unassigned tasks (tasks assigned to blank roles).';
									|it = 'Elenco delle attività bloccate assegnate ai ruoli per i quali non è specificato alcun esecutore.';
									|pl = 'Lista zawieszonych zadań, przeznaczonych do ról, dla których nie określono wykonawcy.';
									|tr = 'Atanmayan görevler (boş rollere atanan görevler).'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UnassignedTasksByAddressingObjects");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách nhiệm vụ đang treo theo đối tượng đánh địa chỉ.';
									|ru = 'Список зависших задач по объектам адресации.';
									|en = 'Unassigned tasks by business objects.'; fa = 'Unassigned tasks by business objects.';
									|it = 'Elenco delle attività bloccate per gli oggetti dell''indirizzamento.';
									|pl = 'Lista zawieszonych zadań wg adresowanych obiektów.';
									|tr = 'Gönderim hedefine göre atanmamış görevler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "OverdueTasks");
	OptionSettings.LongDesc = NStr("vi = 'Không thể thực hiện danh sách nhiệm vụ bị treo và quá hạn, bởi vì trong đó chưa ấn định người thực hiện.';
									|ru = 'Список просроченных и зависших задач, которые не могут быть выполнены, так как у них не назначены исполнители.';
									|en = 'Unassigned and overdue tasks (tasks not assigned to any users).'; fa = 'Unassigned and overdue tasks (tasks not assigned to any users).';
									|it = 'Elenco delle attività bloccate che non possono essere eseguite, perché non non sono state loro assegnati degli esecutori.';
									|pl = 'Lista przeterminowanych i zawieszonych zadań, których nie można wykonać, ponieważ nie przeznaczono wykonawców.';
									|tr = 'Atanmayan ve vadesi geçmiş görevler (hiçbir kullanıcının atanmadığı görevler).'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf