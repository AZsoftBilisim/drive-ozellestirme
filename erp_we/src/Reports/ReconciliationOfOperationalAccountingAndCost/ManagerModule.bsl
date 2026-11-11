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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ReconciliationOfOperationalAccountingAndCost);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReconciliationOfOperationalAccountingAndCost");
	OptionDetails.LongDesc = NStr("vi = 'Đối chiếu số dư mặt hàng theo biểu ghi kế toán hoạt động và biểu ghi giá vốn hàng hóa.';
									|ru = 'Сверка остатков номенклатуры по оперативным регистрам и регистру себестоимости товаров.';
									|en = 'Reconcile inventory balances by current registers and the inventory cost register.'; fa = 'Reconcile inventory balances by current registers and the inventory cost register.';
									|it = 'Сверка остатков номенклатуры по оперативным регистрам и регистру себестоимости товаров.';
									|pl = 'Weryfikacja pozostałości nomenklatury według rejestrów operacyjnych oraz rejestru kosztów towarów.';
									|tr = 'Öğe bakiyelerinin operasyonel kayıtlara ve stok maliyeti kaydına göre mutabakatı.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
