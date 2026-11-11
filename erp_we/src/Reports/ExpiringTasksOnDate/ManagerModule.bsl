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
	ReportSettings.LongDesc = NStr("vi = 'Danh sách nhiệm vụ cần thực hiện trước ngày chỉ định.';
									|ru = 'Список задач, которые должны быть выполнены к указанной дате.';
									|en = 'Tasks that must be completed by the specified due date.'; fa = 'Tasks that must be completed by the specified due date.';
									|it = 'Elenco delle attività che devono essere completate entro la data specificata.';
									|pl = 'Lista zadań, które należy wykonać do określonej daty.';
									|tr = 'Belirtilen bitiş tarihine kadar tamamlanması gereken görevler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ExpiringTasksOnDate");
	OptionSettings.LongDesc = NStr("vi = 'Danh sách nhiệm vụ mà cần thực hiện trước ngày chỉ định.';
									|ru = 'Список задач, которые должны быть выполнены к указанной дате.';
									|en = 'Tasks that must be completed by the specified due date.'; fa = 'Tasks that must be completed by the specified due date.';
									|it = 'Elenco delle attività che devono essere completate entro la data specificata.';
									|pl = 'Lista zadań, które należy wykonać do określonej daty.';
									|tr = 'Belirtilen bitiş tarihine kadar tamamlanması gereken görevler.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf