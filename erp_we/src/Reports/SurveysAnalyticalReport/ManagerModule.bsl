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
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewAnswersSimpleQuestions");
	OptionSettings.LongDesc = NStr("vi = 'Thông tin về cách người được hỏi trả lời các câu hỏi đơn giản.';
									|ru = 'Информация о том, как отвечали респонденты на простые вопросы.';
									|en = 'Information about how respondents answered basic questions.'; fa = 'Information about how respondents answered basic questions.';
									|it = 'Informazioni su come gli intervistati rispondevano alle domande semplici.';
									|pl = 'Informacja o tym, jak respondenci odpowiadali na proste pytania.';
									|tr = 'Yanıtlayanların basit soruları nasıl yanıtladıklarına ilişkin bilgiler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsFlatView");
	OptionSettings.LongDesc = 
		NStr("vi = 'Thông tin về cách người trả lời trả lời các câu hỏi dạng bảng.
		|Được hiển thị dưới dạng danh sách với các nhóm.';
		|ru = 'Информация о том, как отвечали респонденты на табличные вопросы.
		|Выводится в виде списка с группировками.';
		|en = 'Information about replies the respondents gave to question charts.
		|Displayed as a list with grouping.'; fa = 'Information about replies the respondents gave to question charts.
		|Displayed as a list with grouping.';
		|it = 'Informazioni su come gli intervistati rispondevano alle domane tabulari.
		|Viene visualizzato come un elenco con raggruppamenti.';
		|pl = 'Informacja o tym, jak respondenci odpowiadali na pytania tabelaryczne.
		|Wyświetlana jest jako lista z grupowaniami.';
		|tr = 'Yanıtlayanların tablo sorgularını nasıl yanıtladıklarına ilişkin bilgiler.
		|Gruplama içeren bir liste halinde görüntülenir.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "ViewTableQuestionsTableView");
	OptionSettings.LongDesc = 
		NStr("vi = 'Thông tin về cách người trả lời trả lời các câu hỏi dạng bảng.
		|Mỗi câu trả lời của người trả lời được trình bày dưới dạng một bảng.';
		|ru = 'Информация о том, как  отвечали респонденты на табличные вопросы.
		|Каждый ответ респондента представлен в виде таблицы.';
		|en = 'Information about replies the respondents gave to question charts.
		|Each reply is displayed as a table.'; fa = 'Information about replies the respondents gave to question charts.
		|Each reply is displayed as a table.';
		|it = 'Informazioni su come gli intervistati rispondevano alle domane tabulari.
		|Ogni risposta viene rappresentata come una tabella.';
		|pl = 'Informacja o tym, jak respondenci odpowiadali na pytania tabelaryczne.
		|Każda odpowiedź respondenta przedstawiona w postaci tabeli.';
		|tr = 'Yanıtlayanların tablo sorgularını nasıl yanıtladıklarına ilişkin bilgiler.
		|Her yanıtlayan yanıtı bir tablo halinde görüntülenir.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCount");
	OptionSettings.LongDesc = NStr("vi = 'Thông tin về việc, đã có bao nhiêu lần đưa ra phương án phản hồi cho câu hỏi đơn giản.';
									|ru = 'Информация о том, сколько раз был дан вариант ответа на простой вопрос.';
									|en = 'Information on how many times the response option was given to a basic question.'; fa = 'Information on how many times the response option was given to a basic question.';
									|it = 'Informazioni su quante volte è stata data una opzione di risposta alla domanda semplice.';
									|pl = 'Informacja o tym, ile razy wariant odpowiedzi został udzielony na proste pytanie.';
									|tr = 'Basit bir soruya bir yanıt seçeneğinin kaç kez verildiğine ilişkin bilgiler.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAggregatedIndicators");
	OptionSettings.LongDesc = 
		NStr("vi = 'Thông tin về câu trả lời trung bình, tối thiểu, tối đa cho một câu hỏi đơn giản
		|yêu cầu câu trả lời bằng số.';
		|ru = 'Информация о среднем, минимальном, максимальном ответе на простой вопрос,
		|который требует числового ответа.';
		|en = 'Information on average, minimum, and maximum reply to a basic question
		|that requires a numeric value.'; fa = 'Information on average, minimum, and maximum reply to a basic question
		|that requires a numeric value.';
		|it = 'Informazioni sulla risposta media, minima e massima alla domanda semplice
		|che richiede una risposta numerica.';
		|pl = 'Informacje o średniej, minimalnej, maksymalnej odpowiedzi na proste pytanie,
		|które wymaga odpowiedzi numerycznej.';
		|tr = 'Sayısal bir cevap gerektiren basit bir sorunun
		| ortalama, minimum, maksimum cevabı hakkında bilgi.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAnswerCount");
	OptionSettings.LongDesc = 
		NStr("vi = 'Thông tin về số lần tùy chọn câu trả lời được cung cấp cho các câu hỏi dạng bảng,
		|yêu cầu giá trị số.';
		|ru = 'Информация о том, сколько раз был дан варианта ответа для табличных вопросов,
		|который требует указания числового значения.';
		|en = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.'; fa = 'Information on how many times the response option which requires a numeric value 
		|was given for the table questions.';
		|it = 'Informazioni su quante volte è stata data un''opzione di risposta alle domande tabulari
		|che richiede l''indicazione del valore numerico.';
		|pl = 'Informacje o tym, ile razy został dany wariant odpowiedzi na pytania tabelaryczne,
		|który wymaga podania wartości liczbowej.';
		|tr = 'Sayısal değer gerektiren tablo sorguları için 
		|yanıt seçeneğinin kaç kez verildiği bilgisi.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParameters");
	OptionSettings.LongDesc = 
		NStr("vi = 'Thông tin về câu trả lời trung bình, tối thiểu, tối đa trong ô của câu hỏi của bảng,
		|yêu cầu giá trị số.';
		|ru = 'Информация о среднем, минимальном, максимальном ответе в ячейке табличного вопроса,
		|который требует указания числового значения.';
		|en = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.'; fa = 'Information on average, minimum, and maximum response in the cell of a table question 
		|that requires a numeric value.';
		|it = 'Informazioni sulla risposta media, minima e massima nella cella della domanda tabulare
		|che richiede l''indicazione del valore numerico.';
		|pl = 'Informacja o średniej, minimalnej i maksymalnej odpowiedzi w komórce pytania tabelarycznego,
		|który wymaga podania wartości liczbowej.';
		|tr = 'Sayısal bir değer gerektiren bir tablo sorgusunun hücresindeki
		|ortalama, minimum, maksimum yanıt hakkında bilgi.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "SimpleQuestionsAnswerCountComparisonBySurveys");
	OptionSettings.LongDesc = 
		NStr("vi = 'Phân tích so sánh số lượng các phương án trả lời đã cho
		|với các câu hỏi đơn giản trong các cuộc thăm dò ý kiến ​​khác nhau.';
		|ru = 'Сравнительный анализ количества данных вариантов ответов 
		|на простые вопросы в разных опросах.';
		|en = 'Comparative analysis of the responses
		|to basic questions in surveys.'; fa = 'Comparative analysis of the responses
		|to basic questions in surveys.';
		|it = 'Analisi comparativa del numero delle opzioni di risposte date 
		|alle domande semplici nei sondaggi diversi.';
		|pl = 'Analiza porównawcza ilości danych wariantów odpowiedzi 
		|na proste pytania w różnych ankietach.';
		|tr = 'Farklı anketlerde basit sorulara
		|verilen cevapların karşılaştırmalı analizi.'");
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "TableQuestionsAggregatedParametersComparisonBySurveys");
	OptionSettings.LongDesc = 
		NStr("vi = 'Phân tích so sánh các chỉ số tổng hợp về câu trả lời trong các ô
		|của các câu hỏi dạng bảng của các cuộc khảo sát khác nhau.';
		|ru = 'Сравнительный анализ агрегируемых показателей ответов в ячейках
		|табличных вопросов разных опросов.';
		|en = 'Comparative analysis of the aggregated responses
		|to matrix questions in surveys.'; fa = 'Comparative analysis of the aggregated responses
		|to matrix questions in surveys.';
		|it = 'Analisi comparativa degli indici aggregati delle risposte nelle celle
		|delle domande tabulari nei sondaggi diversi.';
		|pl = 'Analiza porównawcza agregowanych wskaźników odpowiedzi w komórkach
		| tabelarycznych pytań różnych ankiet.';
		|tr = 'Farklı anketlerden tablo sorgularının
		|hücrelerindeki toplu yanıt oranlarının karşılaştırmalı analizi.'");
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#EndIf