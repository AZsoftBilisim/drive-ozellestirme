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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.RMProgress);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những lệnh sửa chữa được thực hiện, hoàn thành, hoặc hết hạn?';
									|ru = 'Какие заказы на ремонт оформлены, выполнены или просрочены?';
									|en = 'What R&M orders are registered, completed or overdue?'; fa = 'What R&M orders are registered, completed or overdue?';
									|it = 'Какие заказы на ремонт оформлены, выполнены или просрочены?';
									|pl = 'Jakie są zamówienia na remont są sporządzone, wykonane lub zaległe?';
									|tr = 'Hangi bakım-onarım siparişleri düzenlendi, tamamlandı veya süresi geçti?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "RMProgress");
	OptionDetails.LongDesc = NStr("vi = 'Đã tạo những đơn hàng sửa chữa nào?
		|Có bao nhiêu đơn đặt hàng sửa chữa đã thực hiện theo kế hoạch?
		|Có công việc sửa chữa quá hạn hay không?';
		|ru = 'Какие заказы на ремонт оформлены?
		|Сколько заказов на ремонт выполнено по плану?
		|Есть ли просроченные ремонтные работы?';
		|en = 'View registered R&M orders.
		|Check how many R&M orders are timely completed.
		|Check if there any overdue R&M.'; fa = 'View registered R&M orders.
		|Check how many R&M orders are timely completed.
		|Check if there any overdue R&M.';
		|it = 'Какие заказы на ремонт оформлены?
		|Сколько заказов на ремонт выполнено по плану?
		|Есть ли просроченные ремонтные работы?';
		|pl = 'Jakie są zamówienia na remont są sporządzone?
		|Ile zamówień na remont wykonano według planu?
		|Czy są zaległe prace remontowe?';
		|tr = 'Hangi bakım-onarım siparişleri düzenlendi?
		|Plana göre kaç bakım-onarım siparişi tamamlandı?
		|Süresi geçmiş bakım-onarımlar var mı?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
