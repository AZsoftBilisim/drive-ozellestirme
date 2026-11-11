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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.IntercompanySales);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích lợi nhuận trong bán hàng giữa các doanh nghiệp của tập đoàn.';
									|ru = 'Анализ прибыли при продажах между организациями предприятия.';
									|en = 'Profit analysis on sales among enterprise companies.'; fa = 'Profit analysis on sales among enterprise companies.';
									|it = 'Анализ прибыли при продажах между организациями предприятия.';
									|pl = 'Analiza zysku przy sprzedaży między firmami przedsiębiorstwa.';
									|tr = 'İşletmenin iş yerleri arasındaki satışlardan elde edilen kârın analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "IntercompanySales");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thu nhập đã nhận khi bán hàng giữa các doanh nghiệp,
		|thuộc công ty thương mại.';
		|ru = 'Анализ прибыли, полученной при оформлении продаж товаров между организациями, 
		|входящими в состав торгового предприятия.';
		|en = 'Analyze the profit received upon registering goods sales between companies
		|included in a trading enterprise.'; fa = 'Analyze the profit received upon registering goods sales between companies
		|included in a trading enterprise.';
		|it = 'Анализ прибыли, полученной при оформлении продаж товаров между организациями, 
		|входящими в состав торгового предприятия.';
		|pl = 'Analiza zysku, otrzymanego podczas rejestracji sprzedaży towarów między firmami, 
		|wchodzącymi do składu przedsiębiorstwa handlowego.';
		|tr = 'Bir ticaret işletmesinin parçası olan iş yerleri arasındaki 
		|ürün satışlarının kaydından elde edilen kârın analizi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
