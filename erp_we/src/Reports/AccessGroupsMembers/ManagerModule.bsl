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
	 Or Not AccessRight("View", Metadata.Reports.AccessGroupsMembers)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.AccessGroups.Form.ListForm" Then
		Presentation = NStr("vi = 'Người tham gia nhóm truy cập';
							|ru = 'Участники группы доступа';
							|en = 'Access group membership'; fa = 'عضویت در گروه دسترسی';
							|it = 'Участники группы доступа';
							|pl = 'Access group membership';
							|tr = 'Erişim grubu üyesi'");
		
	ElsIf Parameters.FormName = "Catalog.AccessGroups.Form.ItemForm" Then
		Presentation = NStr("vi = 'Người tham gia nhóm truy cập';
							|ru = 'Участники группы доступа';
							|en = 'Access group membership'; fa = 'عضویت در گروه دسترسی';
							|it = 'Участники группы доступа';
							|pl = 'Access group membership';
							|tr = 'Erişim grubu üyesi'");
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.AccessGroupsMembers";
	Command.VariantKey = "Main";
	Command.Importance = "Ordinary";
	
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
			|ru = 'Выводит сведения о вхождении пользователей в группы доступа.';
			|en = 'Displays users'' membership in access groups.'; fa = 'Displays users'' membership in access groups.';
			|it = 'Выводит сведения о вхождении пользователей в группы доступа.';
			|pl = 'Displays users'' membership in access groups.';
			|tr = 'Kullanıcıların erişim gruplarındaki üyeliğine ilişkin bilgileri görüntüler.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf