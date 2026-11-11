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
	
	If Not Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	If Not AccessRight("View", Metadata.Reports.RolesRights)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	CommandRoles = ReportsCommands.Add();
	CommandRoles.MultipleChoice = True;
	CommandRoles.Manager = "Report.RolesRights";
	CommandRoles.VariantKey = "RolesRights";
	
	If StrStartsWith(Parameters.FormName, "Catalog.AccessGroupProfiles") Then
		CommandProfiles = ReportsCommands.Add();
		CommandProfiles.MultipleChoice = True;
		CommandProfiles.Manager = "Report.RolesRights";
		CommandProfiles.VariantKey = "RightsOfRoleAndProfilesToMetadataObjects";
		
		If Parameters.FormName = "Catalog.AccessGroupProfiles.Form.ItemForm" Then
			CommandRoles.Presentation    = NStr("vi = 'Quyền vai trò của hồ sơ';
												|ru = 'Права ролей профиля';
												|en = 'Rights of profile roles'; fa = 'Rights of profile roles';
												|it = 'Regole dei ruoli del profilo';
												|pl = 'Prawa ról profilu';
												|tr = 'Profil rol yetkileri'");
			CommandProfiles.Presentation = NStr("vi = 'Quyền của hồ sơ';
												|ru = 'Права профиля';
												|en = 'Rights of profile'; fa = 'Rights of profile';
												|it = 'Regole dei ruoli';
												|pl = 'Prawa profilu';
												|tr = 'Profil yetkileri'");
		Else
			CommandRoles.Presentation    = NStr("vi = 'Quyền vai trò của hồ sơ';
												|ru = 'Права ролей профилей';
												|en = 'Rights of profiles roles'; fa = 'Rights of profiles roles';
												|it = 'Regole dei ruoli dei profili';
												|pl = 'Prawa ról profili';
												|tr = 'Profillerin rol yetkileri'");
			CommandProfiles.Presentation = NStr("vi = 'Quyền của hồ sơ';
												|ru = 'Права профилей';
												|en = 'Rights of profiles'; fa = 'Rights of profiles';
												|it = 'Regole dei profili';
												|pl = 'Prawa profili';
												|tr = 'Profillerin yetkileri'");
		EndIf;
	Else
		CommandRoles.Presentation = NStr("vi = 'Quyền của vai trò và hồ sơ';
										|ru = 'Права ролей и профилей';
										|en = 'Rights of profiles and roles'; fa = 'Rights of profiles and roles';
										|it = 'Regole dei ruoli e dei profili';
										|pl = 'Prawa ról i profili';
										|tr = 'Rol ve profillerin yetkileri'");
		CommandRoles.OnlyInAllActions = True;
		CommandRoles.Importance = "SeeAlso";
		CommandRoles.VariantKey = "RightsOfRolesAndProfilesToMetadataObject";
	EndIf;
	
EndProcedure

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	Else
		Return;
	EndIf;
	
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "RolesRights");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị quyền của vai trò đối với đối tượng metadata.';
									|ru = 'Показывает права ролей на объекты метаданных.';
									|en = 'Shows role rights that apply to metadata objects.'; fa = 'Shows role rights that apply to metadata objects.';
									|it = 'Mostrare le regole dei ruoli agli oggetti di metadati.';
									|pl = 'Pokazuje prawa ról na obiekty metadanych.';
									|tr = 'Meta veri nesneleri için rol yetkilerini gösterir.'");
	OptionSettings.DefaultVisibility = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "RightsOfRoleAndProfilesToMetadataObjects");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị quyền của một vai trò và hồ sơ đối với các đối tượng metadata khác nhau.';
									|ru = 'Показывает права одной роли и профилей на разные объекты метаданных.';
									|en = 'Shows rights of one role and profiles to different metadata objects.'; fa = 'Shows rights of one role and profiles to different metadata objects.';
									|it = 'Shows rights of one role and profiles to different metadata objects.';
									|pl = 'Shows rights of one role and profiles to different metadata objects.';
									|tr = 'Farklı meta veri nesneleri için bir rolün ve profilin yetkilerini gösterir.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "RightsOfRolesAndProfilesToMetadataObject");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị quyền của các vai trò và hồ sơ khác nhau đối với một đối tượng metadata.';
									|ru = 'Показывает права разных ролей и профилей на один объект метаданных.';
									|en = 'Shows rights of different roles and profiles to the same metadata object.'; fa = 'Shows rights of different roles and profiles to the same metadata object.';
									|it = 'Shows rights of different roles and profiles to the same metadata object.';
									|pl = 'Shows rights of different roles and profiles to the same metadata object.';
									|tr = 'Bir meta veri nesnesi için farklı rollerin ve profillerin yetkilerini gösterir.'");
	OptionSettings.Enabled = False;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "DetailedRolesRightsToMetadataObject");
	OptionSettings.LongDesc = NStr("vi = 'Hiển thị quyền chi tiết của các vai trò khác nhau đối với một đối tượng metadata.';
									|ru = 'Показывает подробные права разных ролей на один объект метаданных.';
									|en = 'Shows detailed rights of different roles to the same metadata object.'; fa = 'Shows detailed rights of different roles to the same metadata object.';
									|it = 'Shows detailed rights of different roles to the same metadata object.';
									|pl = 'Shows detailed rights of different roles to the same metadata object.';
									|tr = 'Bir meta veri nesnesi için farklı rollerin ayrıntılı yetkilerini gösterir.'");
	OptionSettings.Enabled = False;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
