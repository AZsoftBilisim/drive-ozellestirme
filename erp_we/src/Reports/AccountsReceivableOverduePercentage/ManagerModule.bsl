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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AccountsReceivableOverduePercentage);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thay đổi tỷ lệ các khoản phải thu quá hạn chia theo kỳ.';
									|ru = 'Анализ изменения доли просроченной дебиторской задолженности с разбивкой по периодам.';
									|en = 'Analyze overdue receivable share change broken down by periods.'; fa = 'Analyze overdue receivable share change broken down by periods.';
									|it = 'Анализ изменения доли просроченной дебиторской задолженности с разбивкой по периодам.';
									|pl = 'Analiza zmiany udziału zaległej należności z podziałem na okresy.';
									|tr = 'Vadesi geçen alacakların payındaki değişimlerin dönemlere göre analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ShareOfOverdueDZ");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thay đổi tỷ lệ các khoản phải thu quá hạn chia theo kỳ.';
									|ru = 'Анализ изменения доли просроченной дебиторской задолженности с разбивкой по периодам.';
									|en = 'Analyze overdue receivable share change broken down by periods.'; fa = 'Analyze overdue receivable share change broken down by periods.';
									|it = 'Анализ изменения доли просроченной дебиторской задолженности с разбивкой по периодам.';
									|pl = 'Analiza zmiany udziału zaległej należności z podziałem na okresy.';
									|tr = 'Vadesi geçen alacakların payındaki değişimlerin dönemlere göre analizi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
