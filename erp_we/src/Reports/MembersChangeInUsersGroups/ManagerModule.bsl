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
	 Or Not AccessRight("View", Metadata.Reports.MembersChangeInUsersGroups)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm" Then
		Presentation = NStr("vi = 'Thay đổi người tham gia nhóm người sử dụng';
							|ru = 'Изменение участников групп пользователей';
							|en = 'Changes in user group membership'; fa = 'تغییرات عضویت در گروه کاربری';
							|it = 'Изменение участников групп пользователей';
							|pl = 'Changes in user group membership';
							|tr = 'Erişim grubu üyelerini düzenle'");
		VariantKey = "MembersChangeInUsersGroups";
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm" Then
		Presentation = NStr("vi = 'Thay đổi tham gia trong nhóm người sử dụng';
							|ru = 'Изменение участия в группах пользователей';
							|en = 'Change in user group membership'; fa = 'Change in user group membership';
							|it = 'Изменение участия в группах пользователей';
							|pl = 'Change in user group membership';
							|tr = 'Kullanıcı Grubu Üyeliğini Değiştir'");
		VariantKey = "MembersChangeInUsersGroups";
		
	ElsIf Parameters.FormName = "Catalog.ExternalUsers.Form.ListForm" Then
		Presentation = NStr("vi = 'Thay đổi người sử dụng nhóm người sử dụng ngoài';
							|ru = 'Изменение участников групп внешних пользователей';
							|en = 'Changes in external user group membership'; fa = 'Changes in external user group membership';
							|it = 'Изменение участников групп внешних пользователей';
							|pl = 'Changes in external user group membership';
							|tr = 'Harici kullanıcı gruplarının üyelerini değiştirme'");
		VariantKey = "MembersChangeInExternalUsersGroups";
		
	ElsIf Parameters.FormName = "Catalog.ExternalUsers.Form.ItemForm" Then
		Presentation = NStr("vi = 'Thay đổi tham gia trong nhóm người sử dụng ngoài';
							|ru = 'Изменение участия в группах внешних пользователей';
							|en = 'Change in external user group membership'; fa = 'Change in external user group membership';
							|it = 'Изменение участия в группах внешних пользователей';
							|pl = 'Change in external user group membership';
							|tr = 'Harici Kullanıcı Grubu Üyeliğini Değiştirme'");
		VariantKey = "MembersChangeInExternalUsersGroups";
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.MembersChangeInUsersGroups";
	Command.VariantKey = VariantKey;
	Command.OnlyInAllActions = True;
	Command.Importance = "SeeAlso";
	
	If VariantKey = "MembersChangeInExternalUsersGroups" Then
		Command.FunctionalOptions = "UseExternalUsers";
	EndIf;
	
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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "MembersChangeInUsersGroups");
	OptionSettings.LongDesc =
		NStr("vi = 'Hiển thị thay đổi thành phần nhóm người sử dụng có tính đến phân nhánh trong kỳ cụ thể theo các sự kiện của nhật ký sự kiện.';
			|ru = 'Выводит изменения состава групп пользователей с учетом иерархии за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and shows you the changes in the membership of user groups for the given time period considering the group hierarchy.'; fa = 'Reads the event log and shows you the changes in the membership of user groups for the given time period considering the group hierarchy.';
			|it = 'Выводит изменения состава групп пользователей с учетом иерархии за указанный период по событиям журнала регистрации.';
			|pl = 'Reads the event log and shows you the changes in the membership of user groups for the given time period considering the group hierarchy.';
			|tr = 'Günlük olaylarına dayalı olarak belirli bir süre için kullanıcı gruplarında yapılan değişiklikleri dikkate alarak erişim grubu üyelerindeki değişiklikleri görüntüler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "MembersChangeInExternalUsersGroups");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
	OptionSettings.LongDesc =
		NStr("vi = 'Hiển thị thay đổi thành phần nhóm người sử dụng ngoài có tính đến phân nhánh trong kỳ cụ thể theo các sự kiện của nhật ký sự kiện.';
			|ru = 'Выводит изменения состава групп внешних пользователей с учетом иерархии за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and shows you the changes in the membership of external user groups for the given time period considering the group hierarchy.'; fa = 'Reads the event log and shows you the changes in the membership of external user groups for the given time period considering the group hierarchy.';
			|it = 'Выводит изменения состава групп внешних пользователей с учетом иерархии за указанный период по событиям журнала регистрации.';
			|pl = 'Reads the event log and shows you the changes in the membership of external user groups for the given time period considering the group hierarchy.';
			|tr = 'Günlük olaylarına dayalı olarak belirli bir süre için kullanıcı gruplarında yapılan değişiklikleri dikkate alarak erişim grubu üyelerindeki değişiklikleri görüntüler.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
