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
	 Or Not AccessRight("View", Metadata.Reports.UsersByDepartments)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion()
	 Or Not Users.IsDepartmentUsed() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm" Then
		Presentation = NStr("vi = 'Người sử dụng theo bộ phận';
							|ru = 'Пользователи по подразделениям';
							|en = 'Users by department'; fa = 'کاربران بر اساس دپارتمان';
							|it = 'Пользователи по подразделениям';
							|pl = 'Users by department';
							|tr = 'Departmana göre kullanıcılar'");
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.UsersByDepartments";
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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = Users.IsDepartmentUsed();
	OptionSettings.LongDesc =
		NStr("vi = 'Hiển thị thông tin về đưa người sử dụng vào bộ phận.';
			|ru = 'Выводит сведения о вхождении пользователей в подразделения.';
			|en = 'Displays users'' membership in departments.'; fa = 'Displays users'' membership in departments.';
			|it = 'Выводит сведения о вхождении пользователей в подразделения.';
			|pl = 'Displays users'' membership in departments.';
			|tr = 'Departmanlara ait kullanıcılar hakkındaki bilgileri görüntüler.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf