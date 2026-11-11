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

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Not Common.SubsystemExists("StandardSubsystems.AccessManagement")
	 Or Not AccessRight("View", Metadata.Reports.AccessGroupsAllowedValuesChange)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	If ModuleAccessManagementInternal.IsRecordLevelRestrictionDisabled() Then
		Return;
	EndIf;
	
	ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
	
	If Parameters.FormName <> ParametersForReports.AccessGroupsListFormFullName
	   And Parameters.FormName <> ParametersForReports.AccessGroupsItemFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesListFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesItemFormFullName Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("vi = 'Thay đổi giá trị được phép của nhóm truy cập';
								|ru = 'Изменение разрешенных значений групп доступа';
								|en = 'Change allowed access group values'; fa = 'تغییر مقادیر مجاز گروه دسترسی';
								|it = 'Изменение разрешенных значений групп доступа';
								|pl = 'Change allowed access group values';
								|tr = 'Erişim grubu üyelerini düzenle'");
	Command.Manager = "Report.AccessGroupsAllowedValuesChange";
	Command.VariantKey = "Main";
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	EndIf;
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ReportSettings.DefineFormSettings = True;
	ReportSettings.GroupByReport = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = ModuleAccessManagementInternal <> Undefined
		And Not ModuleAccessManagementInternal.IsRecordLevelRestrictionDisabled();
	OptionSettings.LongDesc =
		NStr("vi = 'Hiển thị thay đổi giá trị được phép của nhóm truy cập có thay đổi nhóm giá trị trong kỳ chỉ định theo sự kiện của nhật ký sự kiện.';
			|ru = 'Выводит изменения разрешенных значений групп доступа с учетом изменения групп значений за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and displays the changes in allowed access group values considering value group changes for the given time period.'; fa = 'Reads the event log and displays the changes in allowed access group values considering value group changes for the given time period.';
			|it = 'Выводит изменения разрешенных значений групп доступа с учетом изменения групп значений за указанный период по событиям журнала регистрации.';
			|pl = 'Reads the event log and displays the changes in allowed access group values considering value group changes for the given time period.';
			|tr = 'Günlük olaylarına dayalı olarak belirli bir süre için kullanıcı gruplarında yapılan değişiklikleri dikkate alarak erişim grubu üyelerindeki değişiklikleri görüntüler.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
