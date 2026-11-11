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
	
	ReportSettings.DefineFormSettings = True;
	ReportSettings.Enabled = False;
	
	FirstOption = FirstOption();
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, FirstOption.Name);
	OptionSettings.Enabled  = True;
	OptionSettings.LongDesc = FirstOption.LongDesc;
	
	SecondOption = SecondOption();
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, SecondOption.Name);
	OptionSettings.Enabled  = True;
	OptionSettings.LongDesc = SecondOption.LongDesc;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType <> "Form" Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	SelectedForm = "ReportForm";
	
EndProcedure

#EndRegion

#Region Private

// Called from the report form.
Procedure SetOption(Form, Variant) Export
	
	FirstOption = FirstOption();
	SecondOption = SecondOption();
	
	CustomizeForm(Form, FirstOption, SecondOption, Variant);
	
EndProcedure

// Calls the SetOption procedure.
Procedure CustomizeForm(Form, FirstOption, SecondOption, Variant) Export
	
	Items = Form.Items;
	
	If Variant = 0 Then
		Form.Parameters.GenerateOnOpen = True;
		Items.FormFirstOption.Title = FirstOption.Title;
		Items.FormSecondOption.Title = SecondOption.Title;
	Else
		FullReportName = "Report." + StrSplit(Form.FormName, ".", False)[1];
		
		// Saving the current user settings.
		Common.SystemSettingsStorageSave(
			FullReportName + "/" + Form.CurrentVariantKey + "/CurrentUserSettings",
			"",
			Form.Report.SettingsComposer.UserSettings);
	EndIf;
	
	If Variant = 0 Then
		If Form.CurrentVariantKey = FirstOption.Name Then
			Variant = 1;
		ElsIf Form.CurrentVariantKey = SecondOption.Name Then
			Variant = 2;
		EndIf;
	EndIf;
	
	If Variant = 0 Then
		Variant = 1;
	EndIf;
	
	If Variant = 1 Then
		Items.FormFirstOption.Check = True;
		Items.FormSecondOption.Check = False;
		Form.Title = FirstOption.Title;
		CurrentVariantKey = FirstOption.Name;
	Else
		Items.FormFirstOption.Check = False;
		Items.FormSecondOption.Check = True;
		Form.Title = SecondOption.Title;
		CurrentVariantKey = SecondOption.Name;
	EndIf;
	
	// Importing a new option.
	Form.SetCurrentVariant(CurrentVariantKey);
	
	// Re-generate the report.
	Form.ComposeResult(ResultCompositionMode.Auto);
	
EndProcedure

Function FirstOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections And Not Properties.AllSectionsWithoutObjects Then
		VariantName = "PeriodClosingDatesByUsers";
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		VariantName = "PeriodClosingDatesByUsersWithoutObjects";
	Else
		VariantName = "PeriodClosingDatesByUsersWithoutSections";
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name", VariantName);
	
	OptionProperties.Insert("Title",
		NStr("vi = 'Ngày cấm thay đổi dữ liệu theo người sử dụng';
			|ru = 'Даты запрета изменения данных по пользователям';
			|en = 'Period-end closing dates by users'; fa = 'Period-end closing dates by users';
			|it = 'Date di divieto della modifica dei dati per utenti';
			|pl = 'Daty zakazu zmiany danych wg użytkowników';
			|tr = 'Kullanıcılara göre dönem sonu kapanış tarihleri'"));
	
	OptionProperties.Insert("LongDesc",
		NStr("vi = 'Hiển thị ngày cấm thay đổi mà được gom nhóm theo người sử dụng.';
			|ru = 'Выводит даты запрета изменения, сгруппированные по пользователям.';
			|en = 'Displays period-end closing dates grouped by users.'; fa = 'Displays period-end closing dates grouped by users.';
			|it = 'Visualizza le date di divieto del download raggruppate per utenti.';
			|pl = 'Wyświetla daty zakazu zmian, pogrupowane wg użytkowników.';
			|tr = 'Kullanıcılara göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'"));
	
	Return OptionProperties;
	
EndFunction

Function SecondOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections And Not Properties.AllSectionsWithoutObjects Then
		VariantName = "PeriodClosingDatesBySectionsObjectsForUsers";
		Title = NStr("vi = 'Ngày cấm thay đổi dữ liệu theo các phân hệ và đối tượng';
					|ru = 'Даты запрета изменения данных по разделам и объектам';
					|en = 'Period-end closing dates by sections and objects'; fa = 'Period-end closing dates by sections and objects';
					|it = 'Date di divieto della modifica dei dati per sezioni e oggetti';
					|pl = 'Daty zakazu zmiany danych wg działów i obiektów';
					|tr = 'Bölümlere ve nesnelere göre veri değişikliği için son tarih'");
		OptionDetails =
			NStr("vi = 'Hiển thị ngày cấm thay đổi được gom nhóm theo các phân hệ có đối tượng.';
				|ru = 'Выводит даты запрета изменения, сгруппированные по разделам с объектами.';
				|en = 'Displays period-end closing dates grouped by sections with objects.'; fa = 'Displays period-end closing dates grouped by sections with objects.';
				|it = 'Visualizza le date di divieto delle modifiche raggruppate per sezioni con oggetti.';
				|pl = 'Wyświetla daty zakazu zmian, pogrupowane wg sekcji z obiektami.';
				|tr = 'Nesnelerle bölümlere göre gruplandırılmış değişiklik yasaklama tarihleri gösterir.'");
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		VariantName = "PeriodClosingDatesBySectionsForUsers";
		Title = NStr("vi = 'Ngày cấm thay đổi dữ liệu theo các phân hệ';
					|ru = 'Даты запрета изменения данных по разделам';
					|en = 'Period-end closing dates by sections'; fa = 'Period-end closing dates by sections';
					|it = 'Date di divieto della modifica dei dati per sezioni';
					|pl = 'Daty zakazu zmiany danych wg działów';
					|tr = 'Bölümlere göre veri değişikliği için son tarih'");
		OptionDetails =
			NStr("vi = 'Hiển thị ngày cấm thay đổi được gom nhóm theo các phân hệ.';
				|ru = 'Выводит даты запрета изменения, сгруппированные по разделам.';
				|en = 'Displays period-end closing dates grouped by sections.'; fa = 'Displays period-end closing dates grouped by sections.';
				|it = 'Visualizza le date di divieto delle modifiche raggruppate per sezioni.';
				|pl = 'Wyświetla daty zakazu zmian, pogrupowane wg sekcji.';
				|tr = 'Bölümlere göre gruplandırılmış değişiklik yasaklama tarihleri gösterir.'");
	Else
		VariantName = "PeriodClosingDatesByObjectsForUsers";
		Title = NStr("vi = 'Ngày cấm thay đổi dữ liệu theo đối tượng';
					|ru = 'Даты запрета изменения данных по объектам';
					|en = 'Period-end closing dates by objects'; fa = 'Period-end closing dates by objects';
					|it = 'Date di divieto della modifica dei dati per oggetti';
					|pl = 'Daty zakazu zmian danych wg obiektów';
					|tr = 'Nesnelere göre veri değişikliği için son tarih'");
		OptionDetails =
			NStr("vi = 'Hiển thị ngày cấm thay đổi mà được gom nhóm theo các đối tượng.';
				|ru = 'Выводит даты запрета изменения, сгруппированные по объектам.';
				|en = 'Displays period-end closing dates grouped by objects.'; fa = 'Displays period-end closing dates grouped by objects.';
				|it = 'Visualizza le date di divieto delle modifiche raggruppate per oggetti.';
				|pl = 'Wyświetla daty zakazu zmian, pogrupowane wg obiektów.';
				|tr = 'Nesnelere göre gruplandırılmış değişiklik yasaklama tarihleri gösterir.'");
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name",       VariantName);
	OptionProperties.Insert("Title", Title);
	OptionProperties.Insert("LongDesc",  OptionDetails);
	
	Return OptionProperties;
	
EndFunction

#EndRegion

#EndIf
