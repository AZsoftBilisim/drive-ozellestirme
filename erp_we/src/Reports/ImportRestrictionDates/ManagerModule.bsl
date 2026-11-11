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
	
	Reports.PeriodClosingDates.CustomizeForm(Form, FirstOption, SecondOption, Variant);
	
EndProcedure

Function FirstOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections And Not Properties.AllSectionsWithoutObjects Then
		VariantName = "ImportRestrictionDatesByInfobases";
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		VariantName = "ImportRestrictionDatesByInfobasesWithoutObjects";
	Else
		VariantName = "ImportRestrictionDatesByInfobasesWithoutSections";
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name", VariantName);
	
	OptionProperties.Insert("Title",
		NStr("vi = 'Ngày cấm kết nhập dữ liệu theo cơ sở thông tin';
			|ru = 'Даты запрета загрузки данных по информационным базам';
			|en = 'Data import restriction dates by infobases'; fa = 'Data import restriction dates by infobases';
			|it = 'Data di divieto del download dei dati per i database informatici';
			|pl = 'Daty zakazu pobierania danych wg baz informacyjnych';
			|tr = 'Verilerin infobase''den içe aktarılmasına kapatıldığı tarih'"));
	
	OptionProperties.Insert("LongDesc",
		NStr("vi = 'Hiển thị ngày cấm kết nhập đối với đối tượng mà được gom nhóm theo cơ sở thông tin.';
			|ru = 'Выводит даты запрета загрузки для объектов, сгруппированные по информационным базам.';
			|en = 'Displays data import restriction dates for objects grouped by infobases.'; fa = 'Displays data import restriction dates for objects grouped by infobases.';
			|it = 'Visualizza le date di divieto del download per gli oggetti raggruppati per database.';
			|pl = 'Wyświetla daty zakazu pobierania obiektów, pogrupowanych wg baz informacyjnych.';
			|tr = 'Infobase''lere göre gruplandırılmış nesneler için içe aktarma tarihleri gösterir.'"));
	
	Return OptionProperties;
	
EndFunction

Function SecondOption()
	
	Try
		Properties = PeriodClosingDatesInternal.SectionsProperties();
	Except
		Properties = New Structure("ShowSections, AllSectionsWithoutObjects", False, True);
	EndTry;
	
	If Properties.ShowSections And Not Properties.AllSectionsWithoutObjects Then
		VariantName = "ImportRestrictionDatesBySectionsObjectsForInfobases";
		Title = NStr("vi = 'Ngày cấm kết nhập dữ liệu theo các phân hệ và đối tượng';
					|ru = 'Даты запрета загрузки данных по разделам и объектам';
					|en = 'Data import restriction dates by sections and objects'; fa = 'Data import restriction dates by sections and objects';
					|it = 'Data di divieto del download dei dati per sezioni e oggetti';
					|pl = 'Daty zakazu pobierania danych wg działów i obiektów';
					|tr = 'Bölümlere ve nesnelere göre veri yüklenmesi için son tarih'");
		OptionDetails =
			NStr("vi = 'Hiển thị ngày cấm kết nhập được gom nhóm theo các phân hệ có đối tượng.';
				|ru = 'Выводит даты запрета загрузки, сгруппированные по разделам с объектами.';
				|en = 'Displays data import restriction dates grouped by sections with objects.'; fa = 'Displays data import restriction dates grouped by sections with objects.';
				|it = 'Visualizza le date di divieto del download raggruppate per sezioni con oggetti.';
				|pl = 'Wyświetla daty zakazu pobierania, pogrupowane wg sekcji z obiektami.';
				|tr = 'Nesnelerle bölümlere göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'");
		
	ElsIf Properties.AllSectionsWithoutObjects Then
		VariantName = "ImportRestrictionDatesBySectionsForInfobases";
		Title = NStr("vi = 'Ngày cấm kết nhập dữ liệu theo các phân hệ';
					|ru = 'Даты запрета загрузки данных по разделам';
					|en = 'Data import restriction dates by sections'; fa = 'Data import restriction dates by sections';
					|it = 'Data di divieto del download dei dati per sezioni';
					|pl = 'Daty zakazu pobierania danych wg działów';
					|tr = 'Bölümlere göre veri yüklenmesi için son tarih'");
		OptionDetails =
			NStr("vi = 'Hiển thị ngày cấm kết nhập được gom nhóm theo các phân hệ.';
				|ru = 'Выводит даты запрета загрузки, сгруппированные по разделам.';
				|en = 'Displays data import restriction dates grouped by sections.'; fa = 'Displays data import restriction dates grouped by sections.';
				|it = 'Visualizza le date di divieto del download raggruppate per sezioni.';
				|pl = 'Wyświetla daty zakazu pobierania, pogrupowane wg sekcji.';
				|tr = 'Bölümlere göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'");
	Else
		VariantName = "ImportRestrictionDatesByObjectsForInfobases";
		Title = NStr("vi = 'Ngày cấm kết nhập dữ liệu theo các đối tượng';
					|ru = 'Даты запрета загрузки данных по объектам';
					|en = 'Data import restriction dates by objects'; fa = 'Data import restriction dates by objects';
					|it = 'Data di divieto del download dei dati per oggetti';
					|pl = 'Daty zakazu pobierania danych wg obiektów';
					|tr = 'Nesnelere göre veri yüklenmesi için son tarih'");
		OptionDetails =
			NStr("vi = 'Hiển thị ngày cấm kết nhập mà được gom nhóm theo đối tượng.';
				|ru = 'Выводит даты запрета загрузки, сгруппированные по объектам.';
				|en = 'Displays data import restriction dates grouped by objects.'; fa = 'Displays data import restriction dates grouped by objects.';
				|it = 'Visualizza le date di divieto del download raggruppate per oggetti.';
				|pl = 'Wyświetla daty zakazu pobierania, pogrupowane wg obiektów.';
				|tr = 'Nesnelere göre gruplandırılmış içe aktarma yasaklama tarihleri gösterir.'");
	EndIf;
	
	OptionProperties = New Structure;
	OptionProperties.Insert("Name",       VariantName);
	OptionProperties.Insert("Title", Title);
	OptionProperties.Insert("LongDesc",  OptionDetails);
	
	Return OptionProperties;
	
EndFunction

#EndRegion

#EndIf
