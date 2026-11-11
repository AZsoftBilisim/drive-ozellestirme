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

// See ReportsOptionsOverridable.BeforeAddReportCommands.
Procedure BeforeAddReportCommands(ReportsCommands, Parameters, StandardProcessing) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Not AccessRight("View", Metadata.Reports.UserGroupsMembers)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm" Then
		Presentation = NStr("vi = 'Người tham gia của nhóm người sử dụng';
							|ru = 'Участники групп пользователей';
							|en = 'User group membership'; fa = 'عضویت در گروه کاربری';
							|it = 'Участники групп пользователей';
							|pl = 'User group membership';
							|tr = 'Kullanıcı grubu üeyeleri'");
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm" Then
		Presentation = NStr("vi = 'Người tham gia của nhóm người sử dụng';
							|ru = 'Участники групп пользователей';
							|en = 'User group membership'; fa = 'عضویت در گروه کاربری';
							|it = 'Участники групп пользователей';
							|pl = 'User group membership';
							|tr = 'Kullanıcı grubu üeyeleri'");
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.UserGroupsMembers";
	Command.VariantKey = "Main";
	Command.Importance = "Ordinary";
	Command.FunctionalOptions = "UseUserGroups";

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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.LongDesc =
		NStr("vi = 'Hiển thị thông tin về đưa người sử dụng vào nhóm truy cập.';
			|ru = 'Выводит сведения о вхождении пользователей в группы пользователей.';
			|en = 'Displays users'' membership in user groups.'; fa = 'Displays users'' membership in user groups.';
			|it = 'Выводит сведения о вхождении пользователей в группы пользователей.';
			|pl = 'Displays users'' membership in user groups.';
			|tr = 'Kullanıcı gruplarındaki kullanıcıların üyeliğine ilişkin bilgileri görüntüler.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf