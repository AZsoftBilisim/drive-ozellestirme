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
	 Or Not AccessRight("View", Metadata.Reports.EditAccessGroupMembers)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
	ParametersForReports = ModuleAccessManagementInternal.ParametersForReports();
	
	If Parameters.FormName <> "Catalog.Users.Form.ListForm"
	   And Parameters.FormName <> "Catalog.Users.Form.ItemForm"
	   And Parameters.FormName <> "Catalog.ExternalUsers.Form.ListForm"
	   And Parameters.FormName <> "Catalog.ExternalUsers.Form.ItemForm"
	   And Parameters.FormName <> ParametersForReports.AccessGroupsListFormFullName
	   And Parameters.FormName <> ParametersForReports.AccessGroupsItemFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesListFormFullName
	   And Parameters.FormName <> ParametersForReports.ProfilesItemFormFullName Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = NStr("vi = 'Thêm và thay đổi người sử dụng và nhóm truy cập';
								|ru = 'Изменение участников групп доступа';
								|en = 'Edit access groups'; fa = 'ویرایش گروه‌های دسترسی';
								|it = 'Изменение участников групп доступа';
								|pl = 'Zmiana uczestników grup dostępu';
								|tr = 'Erişim grupları üyelerini düzenle'");
	Command.Manager = "Report.EditAccessGroupMembers";
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
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ReportSettings.DefineFormSettings = True;
	ReportSettings.GroupByReport = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = Common.SubsystemExists("StandardSubsystems.AccessManagement");
	OptionSettings.LongDesc =
		NStr("vi = 'Hiển thị những thay đổi của người tham gia nhóm truy cập có tính đến thay đổi nhóm người sử dụng trong kỳ chỉ định theo các sự kiện của nhật ký sự kiện.';
			|ru = 'Выводит изменения участников групп доступа с учетом изменения групп пользователей за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and displays the changes in user group membership for the given time period.'; fa = 'Reads the event log and displays the changes in user group membership for the given time period.';
			|it = 'Выводит изменения участников групп доступа с учетом изменения групп пользователей за указанный период по событиям журнала регистрации.';
			|pl = 'Reads the event log and displays the changes in user group membership for the given time period.';
			|tr = 'Günlük olaylarına dayalı olarak belirli bir süre için kullanıcı gruplarında yapılan değişiklikleri dikkate alarak erişim grubu üyelerindeki değişiklikleri görüntüler.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
