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
	ReportSettings.LongDesc = NStr("vi = 'Danh sách nhiệm vụ đã thực hiện có vi phạm thời hạn, theo người thực hiện.';
									|ru = 'Список задач, выполненных с нарушением сроков, по исполнителям.';
									|en = 'Tasks completed with delay by assignee.'; fa = 'Tasks completed with delay by assignee.';
									|it = 'L''elenco delle attività eseguite in violazione dei termini, da parte degli esecutori.';
									|pl = 'Lista zadań, wykonywanych z naruszeniem terminów, wg wykonawców.';
									|tr = 'Gecikmeli tamamlanan görevler, atanana göre.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TasksCompletedWithDeadlineViolation");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách nhiệm vụ đã thực hiện có vi phạm thời hạn, theo người thực hiện.';
									|ru = 'Список задач, выполненных с нарушением сроков, по исполнителям.';
									|en = 'Tasks completed with delay by assignee.'; fa = 'Tasks completed with delay by assignee.';
									|it = 'L''elenco delle attività eseguite in violazione dei termini, da parte degli esecutori.';
									|pl = 'Lista zadań, wykonywanych z naruszeniem terminów, wg wykonawców.';
									|tr = 'Gecikmeli tamamlanan görevler, atanana göre.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf