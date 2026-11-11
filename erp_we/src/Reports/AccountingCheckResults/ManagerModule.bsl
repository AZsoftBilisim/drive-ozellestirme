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
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettingsMain = ReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettingsMain.LongDesc = NStr("vi = 'Hiển thị kết quả kiểm tra kế toán.';
										|ru = 'Выводит результаты проверок учета.';
										|en = 'Displays the data integrity check results.'; fa = 'Displays the data integrity check results.';
										|it = 'Visualizzare i risultati delle verifiche di contabilità.';
										|pl = 'Wyświetla wyniki sprawdzeń ewidencji.';
										|tr = 'Muhasebe denetimlerinin sonuçlarını gösterir.'");
	OptionSettingsMain.SearchSettings.Keywords = NStr("vi = 'Báo cáo về các vấn đề của đối tượng';
														|ru = 'Отчет о проблемах объекта';
														|en = 'Report on object issues'; fa = 'Report on object issues';
														|it = 'Report sui problemi dell''oggetto';
														|pl = 'Raport o problemach obiektu';
														|tr = 'Nesne problemleri raporu'");
	
EndProcedure

// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	
	ReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.AccountingCheckResults);
	ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountingCheckResults).Enabled = False;
	
EndProcedure

// See ReportsOptionsOverridable.BeforeAddReportCommands
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not AccessRight("View", Metadata.Reports.AccountingCheckResults) Then
		Return;
	EndIf;
	
	If Not StrStartsWith(Parameters.FormName, Metadata.Catalogs.AccountingCheckRules.FullName()) Then
		Return;
	EndIf;
	
	Command                   = ReportsCommands.Add();
	Command.Presentation     = NStr("vi = 'Kết quả kiểm tra kế toán';
									|ru = 'Результаты проверки учета';
									|en = 'Data integrity check results'; fa = 'نتایج بررسی یکپارچگی داده';
									|it = 'Risultati di verifica di contabilità';
									|pl = 'Wyniki sprawdzenia ewidencji';
									|tr = 'Muhasebe denetim sonucu'");
	Command.FormParameterName = "";
	Command.Importance          = "SeeAlso";
	Command.VariantKey      = "Main";
	Command.Manager          = "Report.AccountingCheckResults";
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
