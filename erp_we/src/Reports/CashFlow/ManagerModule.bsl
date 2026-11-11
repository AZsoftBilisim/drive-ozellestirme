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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CashFlow);
	DescriptionOfReport.Description = NStr("vi = 'Dạng lưu chuyển tiền tệ';
											|ru = 'Движение денежных средств';
											|en = 'Cash flow'; fa = 'جریان وجوه نقد';
											|it = 'Движение денежных средств';
											|pl = 'Przepływ środków pieniężnych';
											|tr = 'Nakit akışı'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashFlow");
	OptionDetails.LongDesc = NStr("vi = 'Biến động vốn bằng tiền nào đã diễn ra và được lập kế hoạch hàng tháng trong kỳ?
		|Từ các nguồn nào, hướng sử dụng nào và theo dạng LCTT nào?';
		|ru = 'Какие движения денежных средств происходили и планируются помесячно за период?
		|Из каких источников, на какие направления использования, по каким статьям ДДС?';
		|en = 'Verify what cash flows occurred and are planned monthly over the period.
		|Check the cash flow sources, lines of use, and cash flow items.'; fa = 'Verify what cash flows occurred and are planned monthly over the period.
		|Check the cash flow sources, lines of use, and cash flow items.';
		|it = 'Какие движения денежных средств происходили и планируются помесячно за период?
		|Из каких источников, на какие направления использования, по каким статьям ДДС?';
		|pl = 'Jakie przepływy środków pieniężnych odbywali się i są planowane co miesiąc za okres?
		|Z jakich źródeł, na jakie kierunki używania, wg jakich pozycji przepływów środków pieniężnych?';
		|tr = 'Dönem içinde aylık olarak gerçekleşen ve planlanan nakit akışları nelerdir?
		|Hangi kaynaklardan, hangi iş kolları için, hangi nakit akışı öğeleri için?'");
	OptionDetails.Description = NStr("vi = 'Lưu chuyển tiền tệ';
									|ru = 'Движение денежных средств';
									|en = 'Cash flow'; fa = 'جریان وجوه نقد';
									|it = 'Движение денежных средств';
									|pl = 'Przepływ środków pieniężnych';
									|tr = 'Nakit akışı'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashFlowByLinesOfBusiness");
	OptionDetails.LongDesc = NStr("vi = 'Biến động vốn bằng tiền nào đã diễn ra và được lập kế hoạch hàng tháng trong kỳ theo mảng hoạt động?
		|Từ các nguồn nào, hướng sử dụng nào và theo dạng LCTT nào?';
		|ru = 'Какие движения денежных средств происходили и планируются помесячно за период по направлению деятельности?
		|Из каких источников, на какие направления использования, по каким статьям ДДС?';
		|en = 'Verify what cash flows occurred and are planned monthly over the period by a line of business.
		|Check the cash flow sources, lines of use, and cash flow items.'; fa = 'Verify what cash flows occurred and are planned monthly over the period by a line of business.
		|Check the cash flow sources, lines of use, and cash flow items.';
		|it = 'Какие движения денежных средств происходили и планируются помесячно за период по направлению деятельности?
		|Из каких источников, на какие направления использования, по каким статьям ДДС?';
		|pl = 'Jakie przepływy środków pieniężnych odbywali się i są planowane co miesiąc za okres wg kierunku działalności?
		|Z jakich źródeł, na jakie kierunki używania, wg jakich pozycji przepływów środków pieniężnych?';
		|tr = 'Dönem içinde iş koluna göre aylık olarak gerçekleşen ve planlanan nakit akışları nelerdir?
		|Hangi kaynaklardan, hangi iş kolları için, hangi nakit akışı öğeleri için?'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails.Description = NStr("vi = 'Lưu chuyển tiền tệ theo hướng hoạt động';
									|ru = 'Движение денежных средств по направлениям деятельности';
									|en = 'Cash flow by lines of business'; fa = 'جریان نقدی بر اساس خطوط کسب‌وکار';
									|it = 'Движение денежных средств по направлениям деятельности';
									|pl = 'Przepływ środków pieniężnych wedłu rodzajów działalności';
									|tr = 'İş koluna göre nakit akışı'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashFlowCorrespondences");
	OptionDetails.LongDesc = NStr("vi = 'Mối quan hệ giữa nơi lưu trữ tiền với các nguồn thu nhập và hướng sử dụng là gì?';
									|ru = 'Какова связь мест хранения денежных средств с источниками поступления и направлениями использования?';
									|en = 'What is the connection between the cash storage location with cash inflow sources and lines of use?'; fa = 'What is the connection between the cash storage location with cash inflow sources and lines of use?';
									|it = 'Какова связь мест хранения денежных средств с источниками поступления и направлениями использования?';
									|pl = 'Jaki związek miejsc przechowywania środków pieniężnych ze źródłami wpływów i kierunkami używania?';
									|tr = 'Nakit varlıkların tutulduğu konumların gelir kaynakları ve kullanım alanları ile bağlantısı nedir?'");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails.Description = NStr("vi = 'Đối ứng lưu chuyển tiền tệ';
									|ru = 'Корреспонденции движения денежных средств';
									|en = 'Cash flow correspondences'; fa = 'حساب‌های مقابل جریان نقدی';
									|it = 'Корреспонденции движения денежных средств';
									|pl = 'Korespondencje przepływów środków pieniężnych';
									|tr = 'Nakit akışı muhabirleri'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashFlowMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Biến động vốn bằng tiền nào đã diễn ra và được lập kế hoạch hàng tháng trong kỳ?
		|Từ các nguồn nào, hướng sử dụng nào và theo dạng LCTT nào?';
		|ru = 'Какие движения денежных средств происходили и планируются помесячно за период?
		|Из каких источников, на какие направления использования, по каким статьям ДДС?';
		|en = 'Verify what cash flows occurred and are planned monthly over the period.
		|Check the cash flow sources, lines of use, and cash flow items.'; fa = 'Verify what cash flows occurred and are planned monthly over the period.
		|Check the cash flow sources, lines of use, and cash flow items.';
		|it = 'Какие движения денежных средств происходили и планируются помесячно за период?
		|Из каких источников, на какие направления использования, по каким статьям ДДС?';
		|pl = 'Jakie przepływy środków pieniężnych odbywali się i są planowane co miesiąc za okres?
		|Z jakich źródeł, na jakie kierunki używania, wg jakich pozycji przepływów środków pieniężnych?';
		|tr = 'Dönem içinde aylık olarak gerçekleşen ve planlanan nakit akışları nelerdir?
		|Hangi kaynaklardan, hangi iş kolları için, hangi nakit akışı öğeleri için?'");
	OptionDetails.Description = NStr("vi = 'Lưu chuyển tiền tệ (di động)';
									|ru = 'Движение денежных средств (моб.)';
									|en = 'Cash flow (mob. client)'; fa = 'جریان نقدی (کلاینت موبایل)';
									|it = 'Движение денежных средств (моб.)';
									|pl = 'Przepływ środków pieniężnych (mob.)';
									|tr = 'Nakit akışı (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
