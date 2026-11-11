#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// For the "report Options" subsystem when working in the service model.
// Returns:
//  Array of Structure - Contains an array of structures with properties:
//     * ReportVariant - Structure - Version of the report:
//        ** Name             - String - name of the report variant.
//        ** Presentation   - String - presentation of a report variant.
//
Function SettingVariants() Export
	
	Result = New Array;
	
	Variant = New Structure;
	Variant.Insert("Name",           "TurnoverBalanceReport");
	Variant.Insert("Presentation", NStr("vi = 'Báo cáo quay vòng của các khoản mục ngân sách';
										|ru = 'Оборотная ведомость по статьям бюджетов';
										|en = 'Turnover balance report of budget flow items'; fa = 'گزارش مانده گردش اقلام جریان بودجه';
										|it = 'Bilancio fatturato secondo le voci dei budget';
										|pl = 'Zestawienie obrotowe dla pozycji budżetowych';
										|tr = 'Bütçe kalemlerine göre mizan'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "TurnoverBalanceReportOfABudgetItem");
	Variant.Insert("Presentation", NStr("vi = 'Sổ chi tiết ngân sách theo mục';
										|ru = 'Оборотная ведомость по статье бюджетов';
										|en = 'Turnover balance report of a budget flow item'; fa = 'گزارش مانده گردش یک قلم جریان بودجه';
										|it = 'Bilancio fatturato secondo la voce dei budget';
										|pl = 'Zestawienie obrotowe dla pozycji budżetowej';
										|tr = 'Bütçe kalemine göre mizan'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "Details");
	Variant.Insert("Presentation", NStr("vi = 'Báo cáo quay vòng của các khoản mục ngân sách';
										|ru = 'Оборотная ведомость по статьям бюджетов';
										|en = 'Turnover balance report of budget flow items'; fa = 'گزارش مانده گردش اقلام جریان بودجه';
										|it = 'Bilancio fatturato secondo le voci dei budget';
										|pl = 'Zestawienie obrotowe dla pozycji budżetowych';
										|tr = 'Bütçe kalemlerine göre mizan'"));
	Result.Add(Variant);
	
	Return Result;
	
EndFunction

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
//     ValueTableRow
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.BudgetingTurnoverBalanceReport) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.BudgetingTurnoverBalanceReport.FullName();
		ReportCommand.Presentation = NStr("vi = 'Sổ chi tiết';
											|ru = 'Оборотная ведомость';
											|en = 'Turnover balance report'; fa = 'گزارش گردش و مانده';
											|it = 'Bilancio fatturato';
											|pl = 'Lista obrotów';
											|tr = 'Mizan'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "TurnoverBalanceReportOfABudgetItem";
		
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
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BudgetingTurnoverBalanceReport);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'So sánh số liệu theo kịch bản và số liệu thực tế trong kỳ.';
									|ru = 'Сравнение запланированных в рамках сценариев сумм с фактическим исполнением за период.';
									|en = 'Compare amounts planned within scenarios with actual execution over the period.'; fa = 'Compare amounts planned within scenarios with actual execution over the period.';
									|it = 'Сравнение запланированных в рамках сценариев сумм с фактическим исполнением за период.';
									|pl = 'Porównanie zaplanowanych w ramach scenariuszy wartości z faktycznym wykonaniem za okres.';
									|tr = 'Senaryolar kapsamında planlanan tutarların dönem içinde gerçekleşen yürütme ile karşılaştırılması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TurnoverBalanceReport");
	OptionDetails.LongDesc = NStr("vi = 'So sánh số liệu theo kịch bản và số liệu thực tế trong kỳ.';
									|ru = 'Сравнение запланированных в рамках сценариев сумм с фактическим исполнением за период.';
									|en = 'Compare amounts planned within scenarios with actual execution over the period.'; fa = 'Compare amounts planned within scenarios with actual execution over the period.';
									|it = 'Сравнение запланированных в рамках сценариев сумм с фактическим исполнением за период.';
									|pl = 'Porównanie zaplanowanych w ramach scenariuszy wartości z faktycznym wykonaniem za okres.';
									|tr = 'Senaryolar kapsamında planlanan tutarların dönem içinde gerçekleşen yürütme ile karşılaştırılması.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "TurnoverBalanceReportOfABudgetItem");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "Details");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf