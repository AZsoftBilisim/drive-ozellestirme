//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PerformanceOfBudgetProcessTasks);
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích kỷ luật điều hành của quá trình ngân sách.';
									|ru = 'Анализ исполнительской дисциплины бюджетного процесса.';
									|en = 'Analysis of budget process performance discipline.'; fa = 'Analysis of budget process performance discipline.';
									|it = 'Анализ исполнительской дисциплины бюджетного процесса.';
									|pl = 'Analiza dycyplina wykonawczej procesu budżetowego.';
									|tr = 'Bütçe sürecinin yürütme disiplininin analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AllTasks");
	OptionDetails.LongDesc = NStr("vi = 'Đã thực hiện hoặc không có nhiệm vụ lập ngân sách?
		|Những nhiệm vụ nào quá hạn, ai đã quá hạn và quá hạn bao nhiêu ngày?';
		|ru = 'Выполнены или нет задачи бюджетирования?
		|Какие просрочены, кем и на сколько дней?';
		|en = 'Check whether budgeting tasks are completed.
		|Track overdue tasks by owner and days past due.'; fa = 'Check whether budgeting tasks are completed.
		|Track overdue tasks by owner and days past due.';
		|it = 'Выполнены или нет задачи бюджетирования?
		|Какие просрочены, кем и на сколько дней?';
		|pl = 'Czy są wykonane zadania budżetowania? 
		|Jakie zadania są zaległe, przez kogo i na ile dni?';
		|tr = 'Bütçeleme görevleri tamamlandı mı, tamamlanmadı mı?
		|Hangilerinin vadesi kim tarafından ve kaç gün gecikti?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TaskExecutionStatistics");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu nhiệm vụ lập ngân sách đã thực hiện và chưa được thực hiện?
		|Và trong các bước lập ngân sách nào?';
		|ru = 'Сколько бюджетных задач выполнено и не выполнено исполнителями?
		|В рамках каких бюджетных шагов?';
		|en = 'Review completion of budget tasks by assignees.
		|Identify the completion steps for completed tasks.'; fa = 'Review completion of budget tasks by assignees.
		|Identify the completion steps for completed tasks.';
		|it = 'Сколько бюджетных задач выполнено и не выполнено исполнителями?
		|В рамках каких бюджетных шагов?';
		|pl = 'Ile zadań budżetowych wykonano i nie wykonano przez wykonawców? 
		|W ramach jakich kroków budżetowych?';
		|tr = 'Atananlar tarafından tamamlanan ve tamamlanmayan kaç bütçe görevi var?
		|Hangi bütçe adımları çerçevesinde tamamlanıp tamamlanmadığını kontrol edin'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ConnectedTasks");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CurrentTasks");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CurTasksDecryption");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
