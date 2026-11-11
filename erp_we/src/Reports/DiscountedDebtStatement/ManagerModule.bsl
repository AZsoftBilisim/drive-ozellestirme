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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DiscountedDebtStatement);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DiscountedDebtStatement");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích công nợ phải trả nhà cung cấp có tính chiết khấu.
	|Làm thế nào để thay đổi chi phí tính chiết khấu theo phần trăm và công nợ trong kỳ chỉ định?';
	|ru = 'Анализ дисконтированной кредиторской задолженности поставщикам.
	|Как изменялись процентные расходы дисконтирования и задолженность за указанный период?';
	|en = 'Analyze the discounted accounts payable to vendors.
	|Check how the discounting interest expenses and debt changed over the specified period.'; fa = 'Analyze the discounted accounts payable to vendors.
	|Check how the discounting interest expenses and debt changed over the specified period.';
	|it = 'Анализ дисконтированной кредиторской задолженности поставщикам.
	|Как изменялись процентные расходы дисконтирования и задолженность за указанный период?';
	|pl = 'Analiza dyskontowanego zobowiązania dostawcom.
	|Jak zmieniały się koszty odsetkowe dyskontowania i zadłużenie za podany okres?';
	|tr = 'Tedarikçilere ödenecek iskonto edilmiş borçların analizi.
	|İskonto edilmiş faiz giderleri ve borç belirtilen dönemde nasıl değişti?'");
	OptionDetails.Enabled = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
