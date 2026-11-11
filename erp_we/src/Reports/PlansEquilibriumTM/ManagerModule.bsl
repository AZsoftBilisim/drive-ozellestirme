#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//  ValueTableRow, Undefined - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
Function AddBalancedPlansTeam(ReportsCommands) Export
	If AccessRight("View", Metadata.Reports.PlansEquilibriumERP) 
			And (    GetFunctionalOption("UseSalesPlans")
			   Or GetFunctionalOption("UseProductionPlanning")
			   Or GetFunctionalOption("UseAssemblyDisassemblyPlanning")
			   Or GetFunctionalOption("UsePlanningOfInventoryConsumption")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PlansEquilibriumERP.FullName();
		ReportCommand.Presentation = NStr("vi = 'Tính cân đối của kế hoạch';
											|ru = 'Сбалансированность планов';
											|en = 'Plan balance'; fa = 'مانده برنامه';
											|it = 'Equilibrio dei piani';
											|pl = 'Zrównoważenie planów';
											|tr = 'Planların dengelenmesi'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey =                "BalanceOfPlans";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	If AccessRight("View", Metadata.Reports.PlansEquilibriumTM) 
			And (    GetFunctionalOption("UseSalesPlans")
			   Or GetFunctionalOption("UseAssemblyDisassemblyPlanning")
			   Or GetFunctionalOption("UsePlanningOfInventoryConsumption")) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PlansEquilibriumTM.FullName();
		ReportCommand.Presentation = NStr("vi = 'Tính cân đối của kế hoạch';
											|ru = 'Сбалансированность планов';
											|en = 'Plan balance'; fa = 'مانده برنامه';
											|it = 'Equilibrio dei piani';
											|pl = 'Zrównoważenie planów';
											|tr = 'Planların dengelenmesi'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey =                "BalanceOfPlans";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.PlansEquilibriumTM);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = False;
	OptionDetails.LongDesc = NStr("vi = 'Kế hoạch nhu cầu có khả thi so với kế hoạch đảm bảo hay không?';
									|ru = 'Выполнимы ли планы потребностей за счет планов обеспечения?';
									|en = 'Track if demand plans can be fulfilled by means of supply plans.'; fa = 'Track if demand plans can be fulfilled by means of supply plans.';
									|it = 'Выполнимы ли планы потребностей за счет планов обеспечения?';
									|pl = 'Czy są wykonalne plany zapotrzebowania kosztem planów  zaspokojenia?';
									|tr = 'Tedarik planları ile talep planları yürütülebilir mi?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "PlanBalanceForThePeriod");
	OptionDetails.Enabled = False;
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
	OptionDetails.Enabled = False;
	OptionDetails.LongDesc = NStr("vi = 'Sai lệch giữa kịch bản chính so với các kịch bản bổ sung là gì?';
									|ru = 'Каковы отклонения основного сценария относительно дополнительных сценариев?';
									|en = 'What are the deviations of the main scenario relative to the secondary scenarios?'; fa = 'What are the deviations of the main scenario relative to the secondary scenarios?';
									|it = 'Каковы отклонения основного сценария относительно дополнительных сценариев?';
									|pl = 'Jakie są odchylenia podstawowego scenariusza w stosunku do dodatkowych scenariuszy?';
									|tr = 'Ana senaryonun ek senaryolara göre farkları nelerdir?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ComparisonOfScenariosForPeriod");
	OptionDetails.Enabled = False;
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
	OptionDetails.Enabled = False;
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
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf