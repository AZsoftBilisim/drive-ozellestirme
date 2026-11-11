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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.VendorsAccountsPayable);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái thanh toán hiện tại với nhà cung cấp.
		|Công nợ phải trả nhà cung cấp hiện tại là bao nhiêu? Số tiền dự tính tiếp nhận là bao nhiêu?
		|Số tiền dự tính thanh toán cho nhà cung cấp là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|en = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.'; fa = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.';
		|it = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|pl = 'Bieżący status zobowiązań dostawcom. 
		|Jakie zobowiązanie dostawcy jest teraz? Na jaką wartość jest planowany wpływ? 
		|Na jaką kwotę jest oczekiwana płatność dostawcy?';
		|tr = 'Tedarikçilerle yapılan alacak/borç muhasebesinin mevcut durumu.
		|Tedarikçinin şu anda ne kadar borcu var? Ne kadar giriş bekleniyor?
		|Tedarikçiye ne kadar ödenmesi bekleniyor?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "VendorsAccountsPayable");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái thanh toán hiện tại với nhà cung cấp.
		|Công nợ phải trả nhà cung cấp hiện tại là bao nhiêu? Số tiền dự tính tiếp nhận là bao nhiêu?
		|Số tiền dự tính thanh toán cho nhà cung cấp là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|en = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.'; fa = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.';
		|it = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|pl = 'Bieżący status zobowiązań dostawcom. 
		|Jakie zobowiązanie dostawcy jest teraz? Na jaką wartość jest planowany wpływ? 
		|Na jaką kwotę jest oczekiwana płatność dostawcy?';
		|tr = 'Tedarikçilerle yapılan alacak/borç muhasebesinin mevcut durumu.
		|Tedarikçinin şu anda ne kadar borcu var? Ne kadar giriş bekleniyor?
		|Tedarikçiye ne kadar ödenmesi bekleniyor?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("NotBaseVersion");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DebtToSuppliersBasic");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái thanh toán hiện tại với nhà cung cấp.
		|Công nợ phải trả nhà cung cấp hiện tại là bao nhiêu? Số tiền dự tính tiếp nhận là bao nhiêu?
		|Số tiền dự tính thanh toán cho nhà cung cấp là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|en = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.'; fa = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.';
		|it = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|pl = 'Bieżący status zobowiązań dostawcom. 
		|Jakie zobowiązanie dostawcy jest teraz? Na jaką wartość jest planowany wpływ? 
		|Na jaką kwotę jest oczekiwana płatność dostawcy?';
		|tr = 'Tedarikçilerle yapılan alacak/borç muhasebesinin mevcut durumu.
		|Tedarikçinin şu anda ne kadar borcu var? Ne kadar giriş bekleniyor?
		|Tedarikçiye ne kadar ödenmesi bekleniyor?'");
	TMReportOptionsOverridable.SetImportanceOfReportOption(OptionDetails, "Important");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "IndebtednessToSuppliersForSettlementObject");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DebtToSuppliersForObjectOfSettlementsBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DebtToServiceProvider");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DebtToSupplierContextBasic");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DebtToServiceProviders");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "DebtToSuppliersContextBasic");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "IndebtednessToSuppliersMobileClient");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái thanh toán hiện tại với nhà cung cấp.
		|Công nợ phải trả nhà cung cấp hiện tại là bao nhiêu? Số tiền dự tính tiếp nhận là bao nhiêu?
		|Số tiền dự tính thanh toán cho nhà cung cấp là bao nhiêu?';
		|ru = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|en = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.'; fa = 'The current state of vendor AR/AP.
		|Check the accounts payable to the vendor now. Verify the amount of delivered goods.
		|Check the amount of payment to the vendor.';
		|it = 'Текущее состояние расчетов с поставщиками.
		|Какой долг поставщику сейчас? На какую сумму планируется поступление?
		|На какую сумма ожидается оплата поставщику?';
		|pl = 'Bieżący status zobowiązań dostawcom. 
		|Jakie zobowiązanie dostawcy jest teraz? Na jaką wartość jest planowany wpływ? 
		|Na jaką kwotę jest oczekiwana płatność dostawcy?';
		|tr = 'Tedarikçilerle yapılan alacak/borç muhasebesinin mevcut durumu.
		|Tedarikçinin şu anda ne kadar borcu var? Ne kadar giriş bekleniyor?
		|Tedarikçiye ne kadar ödenmesi bekleniyor?'");
	OptionDetails.Description = NStr("vi = 'Nợ phải trả nhà cung cấp (di động)';
									|ru = 'Задолженность поставщикам (моб.)';
									|en = 'Vendor payables (mob. client)'; fa = 'پرداختنی‌های فروشنده (کلاینت موبایل)';
									|it = 'Задолженность поставщикам (моб.)';
									|pl = 'Zadłużenie wobec dostawców (mob.)';
									|tr = 'Tedarikçi borcu (mob.)'");
	OptionDetails.DefaultVisibility = True;
	OptionDetails.Purpose = Enums.ReportOptionPurposes.ForSmartphones;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
