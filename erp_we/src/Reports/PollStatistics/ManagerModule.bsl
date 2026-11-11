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
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, True);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "");
	OptionSettings.LongDesc = 
		NStr("vi = 'Thông tin về những người trả lời đã điền vào các bảng câu hỏi khảo sát, 
		|số câu trả lời cho các câu hỏi, số lượng các phương án trả lời này.';
		|ru = 'Информация о респондентах, заполнивших анкеты по опросу,
		|количестве ответов на вопросы, количестве данных вариантов ответов.';
		|en = 'Information about the survey respondents,
		|and response statistics.'; fa = 'Information about the survey respondents,
		|and response statistics.';
		|it = 'Informazioni sugli intervistati che hanno compilato il questionario per il sondaggio, 
		|sul numero di risposte alle domande, sul numero di risposte date.';
		|pl = 'Informacje o respondentach, którzy wypełnili ankiety w sondażu,
		|ilości odpowiedzi na pytania, ilości danych wariantów odpowiedzi.';
		|tr = 'Anket soru formlarını dolduran katılımcılar,
		|sorulara verilen cevap sayısı, verilen cevap seçeneği sayısı hakkında bilgiler.'");
	OptionSettings.SearchSettings.FieldDescriptions = 
		NStr("vi = 'Người trả lời
		|Thăm dò ý kiến
		|Câu hỏi
		|Câu trả lời';
		|ru = 'Респондент
		|Опрос
		|Вопрос
		|Ответ';
		|en = 'Respondent
		|Survey
		|Question
		|Response'; fa = 'Respondent
		|Survey
		|Question
		|Response';
		|it = 'Intervistato
		|Sondaggio
		|Domanda
		|Risposta';
		|pl = 'Respondent
		|Survey
		|Question
		|Response';
		|tr = 'Yanıtlayan
		|Anket
		|Soru
		|Cevap'");
	OptionSettings.SearchSettings.FilterParameterDescriptions = 
		NStr("vi = 'Thăm dò ý kiến
		|Dạng báo cáo';
		|ru = 'Опрос
		|Вид отчета';
		|en = 'Survey
		|Report kind'; fa = 'Survey
		|Report kind';
		|it = 'Sondaggio
		|Tipo di report';
		|pl = 'Ankieta
		|Widok raportu';
		|tr = 'Anket
		|Rapor türü'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf