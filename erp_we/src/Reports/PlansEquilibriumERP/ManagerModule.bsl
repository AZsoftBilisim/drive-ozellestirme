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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlansEquilibriumERP);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Có thể thực hiện kế hoạch nhu cầu dựa trên kế hoạch đảm bảo không?';
									|ru = 'Выполнимы ли планы потребностей за счет планов обеспечения?';
									|en = 'Track if demand plans can be fulfilled by means of supply plans.'; fa = 'Track if demand plans can be fulfilled by means of supply plans.';
									|it = 'Выполнимы ли планы потребностей за счет планов обеспечения?';
									|pl = 'Czy są wykonalne plany zapotrzebowania kosztem planów  zaspokojenia?';
									|tr = 'Tedarik planları ile talep planları yürütülebilir mi?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlanBalanceForThePeriod");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra tính chính xác của các kế hoạch đã lập. 
		|Kế hoạch nhu cầu có khả thi so với kế hoạch đảm bảo hay không?';
		|ru = 'Проверка корректности составленных планов. 
		|Выполнимы ли планы потребностей за счет планов обеспечения?';
		|en = 'Check plan consistency for the selected period. 
		|Evaluate whether available resources and supply plans can cover demand.'; fa = 'Check plan consistency for the selected period. 
		|Evaluate whether available resources and supply plans can cover demand.';
		|it = 'Проверка корректности составленных планов. 
		|Выполнимы ли планы потребностей за счет планов обеспечения?';
		|pl = 'Weryfikacja poprawności sporządzonych planów. 
		|Czy są wykonalne plany zapotrzebowania kosztem planów zaspokojenia?';
		|tr = 'Planların doğruluğunun kontrolü. 
		|Tedarik planları ile talep planları yürütülebilir mi?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlanBalanceByPeriods");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm tra tính chính xác của các kế hoạch đã lập. 
		|Kế hoạch nhu cầu có khả thi so với kế hoạch đảm bảo hay không?';
		|ru = 'Проверка корректности составленных планов. 
		|Выполнимы ли планы потребностей за счет планов обеспечения?';
		|en = 'Check plan consistency for the selected period. 
		|Evaluate whether available resources and supply plans can cover demand.'; fa = 'Check plan consistency for the selected period. 
		|Evaluate whether available resources and supply plans can cover demand.';
		|it = 'Проверка корректности составленных планов. 
		|Выполнимы ли планы потребностей за счет планов обеспечения?';
		|pl = 'Weryfikacja poprawności sporządzonych planów. 
		|Czy są wykonalne plany zapotrzebowania kosztem planów zaspokojenia?';
		|tr = 'Planların doğruluğunun kontrolü. 
		|Tedarik planları ile talep planları yürütülebilir mi?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfScenariosForPeriod");
	OptionDetails.LongDesc = NStr("vi = 'So sánh nhiều kịch bản với nhau.
		|Kịch bản chính có khác biệt gì so với các kịch bản bổ sung?';
		|ru = 'Сравнение нескольких сценариев между собой. 
		|Каковы отклонения основного сценария относительно дополнительных сценариев?';
		|en = 'Compare several scenarios.
		|Check if there are any deviations of the main scenario from the secondary scenarios.'; fa = 'Compare several scenarios.
		|Check if there are any deviations of the main scenario from the secondary scenarios.';
		|it = 'Сравнение нескольких сценариев между собой. 
		|Каковы отклонения основного сценария относительно дополнительных сценариев?';
		|pl = 'Porównanie kilku scenariuszy między sobą. 
		|Jakie są odchylenia podstawowego scenariusza w stosunku do dodatkowych scenariuszy?';
		|tr = 'Birden fazla senaryonun birbiriyle karşılaştırılması. 
		|Ana senaryonun ek senaryolara göre farkları nelerdir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfScenariosByPeriod");
	OptionDetails.LongDesc = NStr("vi = 'So sánh nhiều kịch bản với nhau.
		|Kịch bản chính có khác biệt gì so với các kịch bản bổ sung?';
		|ru = 'Сравнение нескольких сценариев между собой. 
		|Каковы отклонения основного сценария относительно дополнительных сценариев?';
		|en = 'Compare several scenarios.
		|Check if there are any deviations of the main scenario from the secondary scenarios.'; fa = 'Compare several scenarios.
		|Check if there are any deviations of the main scenario from the secondary scenarios.';
		|it = 'Сравнение нескольких сценариев между собой. 
		|Каковы отклонения основного сценария относительно дополнительных сценариев?';
		|pl = 'Porównanie kilku scenariuszy między sobą. 
		|Jakie są odchylenia podstawowego scenariusza w stosunku do dodatkowych scenariuszy?';
		|tr = 'Birden fazla senaryonun birbiriyle karşılaştırılması. 
		|Ana senaryonun ek senaryolara göre farkları nelerdir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
