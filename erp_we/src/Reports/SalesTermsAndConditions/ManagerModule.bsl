#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SalesTermsAndConditions) 
			And GetFunctionalOption("ToUseTermsOfSales") 
			And Not PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SalesTermsAndConditions.FullName();
		ReportCommand.Presentation = NStr("vi = 'Điều kiện bán hàng';
											|ru = 'Условия продаж';
											|en = 'Sales terms and conditions'; fa = 'شرایط و ضوابط فروش';
											|it = 'Condizioni di vendita';
											|pl = 'Warunki sprzedaży';
											|tr = 'Satış koşulları'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.AdditionalParameters.Insert("CommandName", "SalesTermsAndConditions");
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddPartnerReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.SalesTermsAndConditions) 
			And GetFunctionalOption("ToUseTermsOfSales") 
			And Not PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.SalesTermsAndConditions.FullName();
		ReportCommand.Presentation = NStr("vi = 'Điều kiện bán hàng dành cho khách';
											|ru = 'Условия продаж клиенту';
											|en = 'Customer sales terms and conditions'; fa = 'Customer sales terms and conditions';
											|it = 'Condizioni di vendita al cliente';
											|pl = 'Warunki sprzedaży dla klienta';
											|tr = 'Müşteriye satış koşulları'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		ReportCommand.FunctionalOptions = "UseCustomerPartnerDataContext";
		ReportCommand.AdditionalParameters.Insert("CommandName", "TermsOfSalesByPartner");
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.SalesTermsAndConditions);
	DescriptionOfReport.DefineFormSettings = True;
	DescriptionOfReport.FunctionalOptions.Add("UsePriceManagementSystem20");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'So sánh điều kiện bán hàng thực tế với các điều kiện đã ghi nhận trong thỏa thuận.';
									|ru = 'Сравнение фактических условий продаж товаров с зарегистрированными в соглашениях.';
									|en = 'Comparison between actual sales terms and conditions of goods and conditions registered in agreements.'; fa = 'Comparison between actual sales terms and conditions of goods and conditions registered in agreements.';
									|it = 'Сравнение фактических условий продаж товаров с зарегистрированными в соглашениях.';
									|pl = 'Porównanie faktycznych warunków sprzedaż towarów z zarejestrowanymi w umowach.';
									|tr = 'Ürünlerin gerçek satış koşullarının sözleşmelerde kayıtlı olanlarla karşılaştırılması.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CommonParameters");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thỏa thuận chung về bán hàng theo dạng giá, lịch biểu thanh toán, kỳ hiệu lực, giao dịch kinh tế, kho bãi và thời hạn giao hàng.';
									|ru = 'Анализ типовых соглашений о продажах по видам цен, графикам оплат, периодам действия, хозяйственным операциям, складам и срокам поставки номенклатуры.';
									|en = 'Analyze standard sales terms and conditions by price types, payment schedules, validity periods, business transactions, warehouses, and items delivery periods.'; fa = 'Analyze standard sales terms and conditions by price types, payment schedules, validity periods, business transactions, warehouses, and items delivery periods.';
									|it = 'Анализ типовых соглашений о продажах по видам цен, графикам оплат, периодам действия, хозяйственным операциям, складам и срокам поставки номенклатуры.';
									|pl = 'Analiza typowych kontraktów o sprzedaży według rodzajów cen, harmonogramów płatności, okresów działania, operacji gospodarczych, magazynów i terminów dostawy produktów.';
									|tr = 'Standart satış sözleşmelerinin fiyat türleri, ödeme planları, geçerlilik süreleri, ticari işlemler, ambarlar ve öğenin teslimat koşullarına göre analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Prices");
	OptionDetails.LongDesc = NStr("vi = 'Dữ liệu tổng hợp về nhóm giá và thỏa thuận.';
									|ru = 'Сводные данные по ценовым группам и соглашениям.';
									|en = 'Summary information about price groups and terms of sales.'; fa = 'Summary information about price groups and terms of sales.';
									|it = 'Сводные данные по ценовым группам и соглашениям.';
									|pl = 'Podsumowanie danych według grup cenowych i umów.';
									|tr = 'Fiyat grupları ve anlaşmalara göre özet veriler.'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf