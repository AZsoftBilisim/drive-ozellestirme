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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LotList);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc tiếp nhận và ghi giảm lô hàng.
		|Kiểm soát phân bổ chi phí bởi cơ chế quản lý lô hàng.';
		|ru = 'Контроль поступлений и списаний партий товаров.
		|Контроль распределения расходов механизмом партионного учета.';
		|en = 'Control how you can receive and write off lots. 
		|Control expense allocation using lot accounting.'; fa = 'Control how you can receive and write off lots. 
		|Control expense allocation using lot accounting.';
		|it = 'Контроль поступлений и списаний партий товаров.
		|Контроль распределения расходов механизмом партионного учета.';
		|pl = 'Kontrola wpłat i rozchodów partii towarów. 
		|Kontrola podziału rozchodów przez mechanizm ewidencji partii.';
		|tr = 'Ürün sevkiyatlarının girişlerinin ve gider yazma kontrolü.
		|Giderlerin lot muhasebesi mekanizmasıyla dağıtımının kontrolü.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "EnterpriseBatchList");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc tiếp nhận và ghi giảm lô hàng.
		|Kiểm soát phân bổ chi phí bởi cơ chế quản lý lô hàng.';
		|ru = 'Контроль поступлений и списаний партий товаров.
		|Контроль распределения расходов механизмом партионного учета.';
		|en = 'Control how you can receive and write off lots. 
		|Control expense allocation using lot accounting.'; fa = 'Control how you can receive and write off lots. 
		|Control expense allocation using lot accounting.';
		|it = 'Контроль поступлений и списаний партий товаров.
		|Контроль распределения расходов механизмом партионного учета.';
		|pl = 'Kontrola wpłat i rozchodów partii towarów. 
		|Kontrola podziału rozchodów przez mechanizm ewidencji partii.';
		|tr = 'Ürün sevkiyatlarının girişlerinin ve gider yazma kontrolü.
		|Giderlerin lot muhasebesi mekanizmasıyla dağıtımının kontrolü.'");
	OptionDetails.FunctionalOptions.Add("UseCustomerInvoiceIntercompany");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CompanyBatchList");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát việc tiếp nhận và ghi giảm lô hàng.
		|Kiểm soát phân bổ chi phí bởi cơ chế quản lý lô hàng.';
		|ru = 'Контроль поступлений и списаний партий товаров.
		|Контроль распределения расходов механизмом партионного учета.';
		|en = 'Control how you can receive and write off lots. 
		|Control expense allocation using lot accounting.'; fa = 'Control how you can receive and write off lots. 
		|Control expense allocation using lot accounting.';
		|it = 'Контроль поступлений и списаний партий товаров.
		|Контроль распределения расходов механизмом партионного учета.';
		|pl = 'Kontrola wpłat i rozchodów partii towarów. 
		|Kontrola podziału rozchodów przez mechanizm ewidencji partii.';
		|tr = 'Ürün sevkiyatlarının girişlerinin ve gider yazma kontrolü.
		|Giderlerin lot muhasebesi mekanizmasıyla dağıtımının kontrolü.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
