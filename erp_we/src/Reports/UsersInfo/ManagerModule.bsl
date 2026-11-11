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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersAndExternalUsersInfo");
	OptionSettings.LongDesc = 
		NStr("vi = 'Hiển thị thông tin chi tiết về tất cả người sử dụng,
		|bao gồm tùy chỉnh đăng nhập (nếu được chỉ định).';
		|ru = 'Выводит подробные сведения о всех пользователях,
		|включая настройки для входа (если указаны).';
		|en = 'Detailed information about all users,
		|including their login settings (if specified).'; fa = 'Detailed information about all users,
		|including their login settings (if specified).';
		|it = 'Visualizza informazioni dettagliate su tutti gli utenti,
		| incluse le impostazioni di accesso (se specificato).';
		|pl = 'Wyświetla szczegółowe informacje o wszystkich użytkownikach,
		|w tym włącznie ustawienia do logowania (jeśli są podane).';
		|tr = 'Oturum açma ayarları (belirtilmişse) 
		|dahil olmak üzere tüm kullanıcılar hakkında ayrıntılı bilgi görüntüler.'");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "UsersInfo");
	OptionSettings.LongDesc = 
		NStr("vi = 'Hiển thị thông tin chi tiết về người sử dụng,
		|bao gồm tùy chỉnh đăng nhập (nếu được chỉ định).';
		|ru = 'Выводит подробные сведения о пользователях,
		|включая настройки для входа (если указаны).';
		|en = 'Detailed information about users,
		|including their login settings (if specified).'; fa = 'Detailed information about users,
		|including their login settings (if specified).';
		|it = 'Visualizza informazioni dettagliate sugli utenti,
		| incluse le impostazioni di accesso (se specificato).';
		|pl = 'Wyświetla szczegółowe informacje o użytkownikach,
		|w tym włącznie ustawienia do logowania (jeśli są podane).';
		|tr = 'Oturum açma ayarları (belirtilmişse) 
		|dahil olmak üzere tüm kullanıcılar hakkında ayrıntılı bilgi görüntüler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ExternalUsersInfo");
	OptionSettings.LongDesc = 
		NStr("vi = 'Hiển thị thông tin chi tiết về người sử dụng bên ngoài,
		|bao gồm tùy chỉnh đăng nhập (nếu được chỉ định).';
		|ru = 'Выводит подробные сведения о внешних пользователях,
		|включая настройки для входа (если указаны).';
		|en = 'Detailed information about external users,
		|including their login settings (if specified).'; fa = 'Detailed information about external users,
		|including their login settings (if specified).';
		|it = 'Visualizza informazioni dettagliate sugli utenti esterni,
		| incluse le impostazioni di accesso (se specificato).';
		|pl = 'Wyświetla szczegółowe informacje o zewnętrznych użytkownikach,
		|w tym włącznie ustawienia do logowania (jeśli są podane).';
		|tr = 'Oturum açma ayarları (belirtilmişse) 
		|dahil olmak üzere tüm kullanıcılar hakkında ayrıntılı bilgi görüntüler.'");
	OptionSettings.FunctionalOptions.Add("UseExternalUsers");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Not Parameters.Property("VariantKey") Then
		StandardProcessing = False;
		Parameters.Insert("VariantKey", "UsersAndExternalUsersInfo");
		SelectedForm = "Report.UsersInfo.Form";
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
