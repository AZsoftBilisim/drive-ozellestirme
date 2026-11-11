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
	 Or Not AccessRight("View", Metadata.Reports.UserAccountsChanges)
	 Or StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return;
	EndIf;
	
	Presentation = Undefined;
	
	If Parameters.FormName = "Catalog.Users.Form.ListForm"
	 Or Parameters.FormName = "Catalog.ExternalUsers.Form.ListForm" Then
		
		Presentation = NStr("vi = 'Thay đổi tài khoản của người sử dụng';
							|ru = 'Изменение учетных записей пользователей';
							|en = 'User accounts change history'; fa = 'User accounts change history';
							|it = 'Изменение учетных записей пользователей';
							|pl = 'User accounts change history';
							|tr = 'Kullanıcı hesaplarını değiştirme'");
		
	ElsIf Parameters.FormName = "Catalog.Users.Form.ItemForm"
	      Or Parameters.FormName = "Catalog.ExternalUsers.Form.ItemForm" Then
		
		Presentation = NStr("vi = 'Thay đổi tài khoản của người sử dụng';
							|ru = 'Изменение учетной записи пользователя';
							|en = 'User account change history'; fa = 'سابقه تغییر حساب کاربری';
							|it = 'Изменение учетной записи пользователя';
							|pl = 'User account change history';
							|tr = 'Kullanıcı hesabını değiştirme'");
	EndIf;
	
	If Presentation = Undefined Then
		Return;
	EndIf;
	
	Command = ReportsCommands.Add();
	Command.Presentation = Presentation;
	Command.Manager = "Report.UserAccountsChanges";
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
	OptionSettings.LongDesc = 
		NStr("vi = 'Hiển thị thay đổi thuộc tính của người sử dụng cơ sở thông tin trong kỳ cụ thể theo các sự kiện của nhật ký sự kiện.';
			|ru = 'Выводит изменения свойств пользователей информационной базы за указанный период по событиям журнала регистрации.';
			|en = 'Reads the event log and shows you the changes in the properties of infobase users for the given time period.'; fa = 'Reads the event log and shows you the changes in the properties of infobase users for the given time period.';
			|it = 'Выводит изменения свойств пользователей информационной базы за указанный период по событиям журнала регистрации.';
			|pl = 'Reads the event log and shows you the changes in the properties of infobase users for the given time period.';
			|tr = 'Günlük olaylarına göre belirli bir süre için bilgi tabanı kullanıcılarının özelliklerindeki değişiklikleri görüntüler.'");
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf
