//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.IncidentStatistics);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thực hiện sự cố theo người chịu trách nhiệm.
		|Có bao nhiêu sự cố cho mỗi nhân viên? 
		|Số lượng sự cố đã giải quyết đúng hạn và quá hạn?';
		|ru = 'Анализ исполнения инцидентов по ответственному.
		|Какое количество инцидентов на сотруднике? 
		|Количество решенных инцидентов в срок и просроченных?';
		|en = 'Analyze the incident execution by the responsible person. 
		|Verify how many incidents the employee has.
		|Track how many incidents have been solved on time. Check how many incidents are overdue.'; fa = 'Analyze the incident execution by the responsible person. 
		|Verify how many incidents the employee has.
		|Track how many incidents have been solved on time. Check how many incidents are overdue.';
		|it = 'Анализ исполнения инцидентов по ответственному.
		|Какое количество инцидентов на сотруднике? 
		|Количество решенных инцидентов в срок и просроченных?';
		|pl = 'Analiza rozwiązania incydentów według osoby odpowiedzialnej.
		|Jaka ilość incydentów jest na pracowniku? 
		|Ilość rozwiązanych incydentów w terminie i przeterminowanych?';
		|tr = 'Olayların sorumlular tarafından yürütülmesi analizi.
		|Çalışan başına kaç olay var?
		|Vadesinde ve gecikmiş olarak çözülen olay sayısı?'");
	OptionDetails.FunctionalOptions.Add("UseIncidents");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	DescriptionOfReport.DefaultVisibility = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GeneralIncidentStatistics");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích sự phân bổ giao tiếp của người sử dụng theo dạng sự cố về mặt số lượng và tỷ lệ phần trăm.';
									|ru = 'Анализ распределения обращений пользователей по видам инцидентов в количественном и процентном отношении.';
									|en = 'Analyze the user support ticket allocation by incident kinds in terms of quantity and percentage.'; fa = 'Analyze the user support ticket allocation by incident kinds in terms of quantity and percentage.';
									|it = 'Анализ распределения обращений пользователей по видам инцидентов в количественном и процентном отношении.';
									|pl = 'Analiza podziału zgłoszeń użytkowników według rodzajów incydentów w ujęciu ilościowym i procentowym.';
									|tr = 'Kullanıcı başvurularının olay türlerine göre dağılımının nicel ve yüzde cinsinden analizi.'");
	OptionDetails.Location.Insert(ReportsOptionsClientServer.HomePageID());
	DescriptionOfReport.DefaultVisibility = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
