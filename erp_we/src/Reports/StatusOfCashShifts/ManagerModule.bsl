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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatusOfCashShifts);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái phiên thu ngân theo doanh nghiệp và kho bãi.
		|Kiểm soát việc lập bảng kê bán lẻ/trả lại theo từng hệ thống thuế áp dụng.';
		|ru = 'Анализ состояния кассовых смен по организациям и складам.
		|Контроль создания отчетов о розничных продажах/возвратах в разрезе применяемых СНО.';
		|en = 'Analyze the state of POS shifts by companies and warehouses.
		|Control generation of reports on retail sales/returns broken down by the TS used.'; fa = 'Analyze the state of POS shifts by companies and warehouses.
		|Control generation of reports on retail sales/returns broken down by the TS used.';
		|it = 'Анализ состояния кассовых смен по организациям и складам.
		|Контроль создания отчетов о розничных продажах/возвратах в разрезе применяемых СНО.';
		|pl = 'Analiza statusów zmian kasowych według firm i magazynów.
		|Kontrola utworzenia raportów o sprzedaży detalicznej/zwrotach w przekroju stosowanych rodzajów opodatkowania.';
		|tr = 'İş yerlerine ve ambarlara göre POS vardiyalarının durumunun analizi.
		|Uygulanan VS bağlamında perakende satışlar/iadeler hakkında raporların oluşturulmasının kontrolü.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
