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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CreateReportsToConsignor);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc lập bảng kê kịp thời dành cho người đặt ký gửi.';
									|ru = 'Контроль за своевременным предоставлением отчетности комитенту.';
									|en = 'Control the timeliness of reporting provision to the consignor.'; fa = 'Control the timeliness of reporting provision to the consignor.';
									|it = 'Контроль за своевременным предоставлением отчетности комитенту.';
									|pl = 'Kontrola za terminowym dostarczeniem raportów komitentowi.';
									|tr = 'Göndericiye raporların zamanında sunulmasının kontrolü.'");
	OptionDetails.FunctionalOptions.Add("UsePurchaseCommission");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CreateReportsToConsignor");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc gửi đúng hạn bảng kê cho người đặt ký gửi.
		|Chúng ta vẫn chưa lập bảng kê cho những hàng hóa nào với số lượng và giá trị bao nhiêu?';
		|ru = 'Контроль за своевременным предоставлением отчетности комитенту.
		|По каким товарам, на какие количество и сумму мы не отчитались?';
		|en = 'Control over timely provision of reporting to a consignor.
		|For which goods, and for which quantity and amount have we not reported?'; fa = 'Control over timely provision of reporting to a consignor.
		|For which goods, and for which quantity and amount have we not reported?';
		|it = 'Контроль за своевременным предоставлением отчетности комитенту.
		|По каким товарам, на какие количество и сумму мы не отчитались?';
		|pl = 'Kontrola za terminowym dostarczeniem raportów komitentowi. 
		|Według jakich towarów, na jakie ilości i wartości nie wysłaliśmy raportów?';
		|tr = 'Göndericiye raporların zamanında sunulmasının kontrolü.
		|Hangi ürünler kapsamında, hangi miktarları ve tutarları raporlamadık?'");
	OptionDetails.FunctionalOptions.Add("UsePurchaseCommission");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
