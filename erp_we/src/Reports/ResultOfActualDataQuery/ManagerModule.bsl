#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// For the "report Options" subsystem when working in the service model.
// Returns:
//  Array of Structure - Contains an array of structures with properties:
//     * ReportVariant - Structure - Version of the report.
//        Name - String - Name of the report variant.
//        View - Row - View of the report variant.
//
Function SettingVariants() Export
	
	Result = New Array;
	
	Variant = New Structure;
	Variant.Insert("Name",           "RuleOperationResultByBudgetItem");
	Variant.Insert("Presentation", NStr("vi = 'Kết quả hoạt động của quy tắc theo khoản mục ngân sách';
										|ru = 'Результат работы правил по статье бюджетов';
										|en = 'Rule operation result by budget flow item'; fa = 'نتیجه عملیات قاعده بر اساس قلم جریان بودجه';
										|it = 'Il risultato del lavoro delle regole in termini di budget';
										|pl = 'Wynik działania zasad dotyczących pozycji budżetowych';
										|tr = 'Bütçe kalemine göre kural işlemi sonucu'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "RuleOperationResultByBudgetIndicator");
	Variant.Insert("Presentation", NStr("vi = 'Kết quả hoạt động của các quy tắc theo chỉ tiêu ngân sách';
										|ru = 'Результат работы правил по показателю бюджетов';
										|en = 'Rule operation result by budget balance item'; fa = 'نتیجه عملیات قاعده بر اساس قلم مانده بودجه';
										|it = 'Il risultato del lavoro delle regole in termini di budget';
										|pl = 'Wynik działania zasad dotyczących pozycji budżetowych';
										|tr = 'Bütçe kalemine göre kural işlemi sonucu'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "RuleOperationResultByBudgetItems");
	Variant.Insert("Presentation", NStr("vi = 'Kết quả hoạt động của quy tắc theo khoản mục ngân sách';
										|ru = 'Результат работы правил по статьям бюджетов';
										|en = 'Rule operation result by budget flow items'; fa = 'نتیجه عملیات قاعده بر اساس اقلام جریان بودجه';
										|it = 'Il risultato del lavoro delle regole in termini di budget';
										|pl = 'Wynik działania zasad dotyczących pozycji budżetowych';
										|tr = 'Bütçe kalemlerine göre kural işlemi sonucu'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "RuleOperationResultByBudgetIndicators");
	Variant.Insert("Presentation", NStr("vi = 'Kết quả hoạt động của các quy tắc về chỉ tiêu ngân sách';
										|ru = 'Результат работы правил по показателям бюджетов';
										|en = 'Rule operation result by budget balance items'; fa = 'نتیجه عملیات قاعده بر اساس اقلام مانده بودجه';
										|it = 'Il risultato del lavoro delle regole in termini di budget';
										|pl = 'Wynik działania zasad dotyczących pozycji budżetowych';
										|tr = 'Bütçe dengesi kalemlerine göre kural işlemi sonucu'"));
	Result.Add(Variant);
	
	Variant = New Structure;
	Variant.Insert("Name",           "RuleOperationResultByBudgetItemsAndIndicators");
	Variant.Insert("Presentation", NStr("vi = 'Kết quả hoạt động của quy tắc theo khoản mục và chỉ tiêu ngân sách';
										|ru = 'Результат работы правил по статьям и показателям бюджетов';
										|en = 'Rule operation result by budget flow items and budget balance items'; fa = 'نتیجه عملیات قاعده بر اساس اقلام جریان بودجه و اقلام مانده بودجه';
										|it = 'Il risultato del lavoro delle regole in termini di budget';
										|pl = 'Wynik działania zasad dotyczących pozycji i wskaźników budżetowych';
										|tr = 'Bütçe kalemleri ve bütçe dengesi kalemlerine göre kural işlemi sonucu'"));
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
Function AddBudgetItemReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultOfActualDataQuery) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultOfActualDataQuery.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thực hiện quy tắc';
											|ru = 'Результат работы правил';
											|en = 'Rule operation result'; fa = 'نتیجه عملیات قاعده';
											|it = 'Risultato delle regole';
											|pl = 'Rezultat działania reguł';
											|tr = 'Kural işlemi sonucu'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ByBudgetItem");
		ReportCommand.VariantKey = "RuleOperationResultByBudgetItem";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//     ValueTableRow
//
Function AddReportCommandForBudgetItems(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultOfActualDataQuery) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultOfActualDataQuery.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thực hiện quy tắc';
											|ru = 'Результат работы правил';
											|en = 'Rule operation result'; fa = 'نتیجه عملیات قاعده';
											|it = 'Результат работы правил';
											|pl = 'Rezultat działania reguł';
											|tr = 'Kural işlemi sonucu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ByBudgetItems");
		ReportCommand.VariantKey = "RuleOperationResultByBudgetItems";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//     ValueTableRow
//
Function AddBudgetIndicatorReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultOfActualDataQuery) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultOfActualDataQuery.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thực hiện quy tắc';
											|ru = 'Результат работы правил';
											|en = 'Rule operation result'; fa = 'نتیجه عملیات قاعده';
											|it = 'Risultato delle regole';
											|pl = 'Rezultat działania reguł';
											|tr = 'Kural çalışma sonucu'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ByBudgetIndicator");
		ReportCommand.VariantKey = "RuleOperationResultByBudgetIndicator";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//     ValueTableRow
//
Function AddBudgetMetricsReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.ResultOfActualDataQuery) 
			And GetFunctionalOption("UseBudgeting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ResultOfActualDataQuery.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kết quả thực hiện quy tắc';
											|ru = 'Результат работы правил';
											|en = 'Rule operation result'; fa = 'نتیجه عملیات قاعده';
											|it = 'Результат работы правил';
											|pl = 'Rezultat działania reguł';
											|tr = 'Kural işlemi sonucu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ByBudgetIndicators");
		ReportCommand.VariantKey = "RuleOperationResultByBudgetIndicators";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ResultOfActualDataQuery);
	DescriptionOfReport.DefineFormSettings = True;
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "RuleOperationResultByBudgetItem");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "RuleOperationResultByBudgetIndicator");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "RuleOperationResultByBudgetItems");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "RuleOperationResultByBudgetIndicators");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "RuleOperationResultByBudgetItemsAndIndicators");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf