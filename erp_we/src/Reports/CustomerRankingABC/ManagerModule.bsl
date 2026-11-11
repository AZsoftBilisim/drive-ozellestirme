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
	
	DisplayReportOptions = False;
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomerRankingABC);
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những nhóm khách hàng nào mua nhiều nhất?';
									|ru = 'Какие группы клиентов покупают более всего?';
									|en = 'Which customer groups are more active?'; fa = 'Which customer groups are more active?';
									|it = 'Какие группы клиентов покупают более всего?';
									|pl = 'Jakie grupy klientów kupują najwięcej?';
									|tr = 'En çok hangi müşteri grupları satın alıyor?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích thay đổi số lượng và mối quan hệ giữa khách hàng mua nhiều, trung bình và ít.';
									|ru = 'Анализ изменения количества и соотношения клиентов, покупающих много, средне и мало.';
									|en = 'Analysis of quantity and ratio of customers who buy a lot, average and little.'; fa = 'Analysis of quantity and ratio of customers who buy a lot, average and little.';
									|it = 'Анализ изменения количества и соотношения клиентов, покупающих много, средне и мало.';
									|pl = 'Analiza zmiany ilości i relacji klientów, kupujących dużo, średnio i mało.';
									|tr = 'Çok, orta ve az satın alan müşterilerin sayı ve oranlarındaki değişimin analizi.'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
