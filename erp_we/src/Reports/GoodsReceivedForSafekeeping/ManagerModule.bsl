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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsReceivedForSafekeeping);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa được chấp nhận để lưu kho từ bên gửi hàng?';
									|ru = 'Сколько товаров было принято на хранение от поклажедателей?';
									|en = 'Check how much VMI was received from vendors.'; fa = 'Check how much VMI was received from vendors.';
									|it = 'Сколько товаров было принято на хранение от поклажедателей?';
									|pl = 'Ile towarów zostało przyjęto na przechowywanie od deponentów?';
									|tr = 'Tedarikçilerden ne kadar VMI alındığını kontrol et.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsReceivedForSafekeeping");
	OptionDetails.LongDesc = NStr("vi = 'Có bao nhiêu hàng hóa được tiếp nhận để lưu kho từ bên thuê kho?
		|Có bao nhiêu hàng hóa trong kho?
		|Có bao nhiêu hàng hóa được tiếp nhận để lưu kho cần được mua lại?';
		|ru = 'Сколько товаров было принято на хранение от поклажедателей?
		|Сколько товаров хранится на складах?
		|Сколько принятых на хранение товаров необходимо выкупить?';
		|en = 'Check how much VMI was received from vendors.
		|Verify how many goods are stored in warehouses.
		|Check how much VMI needs to be purchased.'; fa = 'Check how much VMI was received from vendors.
		|Verify how many goods are stored in warehouses.
		|Check how much VMI needs to be purchased.';
		|it = 'Сколько товаров было принято на хранение от поклажедателей?
		|Сколько товаров хранится на складах?
		|Сколько принятых на хранение товаров необходимо выкупить?';
		|pl = 'Ile towarów zostało przyjęto na przechowywanie od deponentów?
		|Ile towarów jest przechowywano w magazynach?
		|Ile przyjętych na przechowywanie towarów należy wykupić?';
		|tr = 'Tedarikçilerden ne kadar VMI alındığını kontrol et.
		|Ambarlarda ne kadar VMI depolandığını kontrol et.
		|Ne kadar VMI satın alınması gerektiğini kontrol et.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
