///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
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
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = False;
	OptionSettings.LongDesc = NStr("vi = 'Tìm kiếm chỗ sử dụng đối tượng ứng dụng.';
									|ru = 'Поиск мест использования объектов приложения.';
									|en = 'Search for occurrences.'; fa = 'Search for occurrences.';
									|it = 'Ricerca dei luoghi di utilizzo degli oggetti dell''applicazione.';
									|pl = 'Wyszukaj miejsc korzystania z obiektów aplikacji.';
									|tr = 'Uygulama nesnelerinin kullanım yerlerini arayın.'");
EndProcedure

// To be called from ReportsOptionsOverridable.BeforeAddReportCommands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//   ValueTableRow, Undefined - an added command or Undefined if there are no rights to view the report.
//
Function AddUsageInstanceCommand(ReportsCommands) Export
	If Not AccessRight("View", Metadata.Reports.SearchForReferences) Then
		Return Undefined;
	EndIf;
	Command = ReportsCommands.Add();
	Command.Presentation      = NStr("vi = 'Nơi sử dụng';
									|ru = 'Места использования';
									|en = 'Occurrences'; fa = 'موارد یافت‌شده';
									|it = 'Luoghi di utilizzo';
									|pl = 'Miejsca wykorzystywania';
									|tr = 'Kullanım yerleri'");
	Command.MultipleChoice = True;
	Command.Importance           = "SeeAlso";
	Command.FormParameterName  = "Filter.RefSet";
	Command.VariantKey       = "Main";
	Command.Manager           = "Report.SearchForReferences";
	Command.Shortcut    = New Shortcut(Key.G, True, False, True); // Alt+Shift+G
	Command.OnlyInAllActions = True;
	Return Command;
EndFunction

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf