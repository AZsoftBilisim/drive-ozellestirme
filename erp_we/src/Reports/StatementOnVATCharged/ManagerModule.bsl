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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatementOnVATCharged);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByTypeOfActivity");
	OptionDetails.LongDesc =
		NStr("vi = 'Bảng kê thuế GTGT phải nộp theo dạng lĩnh vực hoạt động';
			|ru = 'Ведомость по НДС предъявленному по видам деятельности';
			|en = 'Statement on VAT charged by activity types'; fa = 'صورت VAT محاسبه‌شده بر اساس انواع فعالیت';
			|it = 'Ведомость по НДС предъявленному по видам деятельности';
			|pl = 'Zestawienie VAT zgłoszonego według rodzajów działalności';
			|tr = 'Faaliyet türüne göre beyan edilen KDV tablosu'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByLinesOfBusiness");
	OptionDetails.LongDesc =
		NStr("vi = 'Bảng kê thuế GTGT phải nộp theo lĩnh vực hoạt động';
			|ru = 'Ведомость по НДС предъявленному по направлениям деятельности';
			|en = 'Statement on VAT charged by lines of business'; fa = 'صورت VAT محاسبه‌شده بر اساس خطوط کسب‌وکار';
			|it = 'Ведомость по НДС предъявленному по направлениям деятельности';
			|pl = 'Zestawienie VAT zgłoszonego według rodzajów działalności';
			|tr = 'İş kollarına göre beyan edilen KDV tablosu'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ByBusinessUnits");
	OptionDetails.LongDesc =
		NStr("vi = 'Bảng kê thuế GTGT phải nộp theo bộ phận';
			|ru = 'Ведомость по НДС предъявленному по подразделениям';
			|en = 'Statement on VAT charged by business units'; fa = 'صورت VAT محاسبه‌شده بر اساس واحدهای تجاری';
			|it = 'Ведомость по НДС предъявленному по подразделениям';
			|pl = 'Zestawienie VAT zgłoszonego według działów';
			|tr = 'Departmanlara beyan edilen KDV tablosu'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
