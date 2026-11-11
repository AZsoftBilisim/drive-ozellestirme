#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	ValueTableRow, Undefined - the generated command to output to the submenu.
Function AddReportCommand(ReportsCommands) Export

	If GetFunctionalOption("UseCashFlowLimits") Then
		
		If AccessRight("View", Metadata.Reports.CashFlowLimits)
			And Not GetFunctionalOption("UseBudgetingCashFlowLimits")
			Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.CashFlowLimits.FullName();
			ReportCommand.Presentation = NStr("vi = 'Hạn mức chi tiền';
												|ru = 'Лимиты расхода ДС';
												|en = 'Cash flow limits'; fa = 'سقف‌های جریان وجوه نقد';
												|it = 'Limiti delle uscite monetarie';
												|pl = 'Limity wydatków środków pieniężnych';
												|tr = 'Nakit gider limitleri'");
			
			ReportCommand.MultipleChoice = False;
			ReportCommand.Importance = "Ordinary";
			ReportCommand.VariantKey = "CashFlowLimitsContext";
			
			Return ReportCommand;
			
		EndIf;
		
	EndIf;
	If AccessRight("View", Metadata.Reports.CashFlowLimitsForBudgetingData)
		And GetFunctionalOption("UseBudgetingCashFlowLimits")
		And GetFunctionalOption("ControllingLimitsBasedOnBudgetingData2_4") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CashFlowLimitsForBudgetingData.FullName();
		ReportCommand.Presentation = NStr("vi = 'Hạn mức chi tiền';
											|ru = 'Лимиты расхода ДС';
											|en = 'Cash flow limits'; fa = 'سقف‌های جریان وجوه نقد';
											|it = 'Limiti delle uscite monetarie';
											|pl = 'Limity wydatków środków pieniężnych';
											|tr = 'Nakit gider limitleri'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "UseOfCashFlowLimitsContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CashFlowLimits);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích theo kế hoạch-thực tế có sử dụng hạn mức trong kỳ.';
									|ru = 'План-фактный анализ использования лимитов за период.';
									|en = 'View variance analysis of cash flow limits over the period.'; fa = 'View variance analysis of cash flow limits over the period.';
									|it = 'План-фактный анализ использования лимитов за период.';
									|pl = 'Aktualny plan analiza używania limitów za okres.';
									|tr = 'Dönem için limit kullanımının varyans analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UseOfCashFlowLimits");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích theo kế hoạch và thực tế sử dụng hạn chế trong kỳ.
		|Dạng LCTT nào đã vượt quá hoặc quá hạn một phần?';
		|ru = 'План-фактный анализ использования лимитов за период.
		|По каким статьям ДДС есть превышение или лимит израсходован не полностью?';
		|en = 'View variance analysis of cash flow limits over the period.
		|Check which cash flow items have an exceeded limit or not fully reached limit.'; fa = 'View variance analysis of cash flow limits over the period.
		|Check which cash flow items have an exceeded limit or not fully reached limit.';
		|it = 'План-фактный анализ использования лимитов за период.
		|По каким статьям ДДС есть превышение или лимит израсходован не полностью?';
		|pl = 'Aktualny plan analiza używania limitów za okres. 
		|Według jakich pozycji przepływów pienięśnych jest przekroczenie lub limit jest wydatkowany nie w całości?';
		|tr = 'Dönem için limit kullanımının varyans analizi.
		| Nakit akışın hangi kalemleri için limit aşımı mevcut veya limit tamamen kullanılmadı?'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CashFlowLimitsContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf