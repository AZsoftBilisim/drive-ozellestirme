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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BlackListOfCustomersForDeliveryControl);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Đã cấm giao hàng cho những khách hàng nào?';
									|ru = 'Каким клиентам запрещена отгрузка?';
									|en = 'Which customers cannot ship?'; fa = 'Which customers cannot ship?';
									|it = 'Каким клиентам запрещена отгрузка?';
									|pl = 'Jakim klientom jest zabroniona wysyłka?';
									|tr = 'Hangi müşterilere sevkiyat yasaktır?'");
	OptionDetails.FunctionalOptions.Add("UseShipmentProhibition");
	DescriptionOfReport.DefaultVisibility = False;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BlackListOfCustomersForDeliveryControl");
	OptionDetails.LongDesc = NStr("vi = 'Những khách hàng nào bị cấm giao hàng?
		|Ai là người quản lý chính của khách hàng?
		|Bị cấm vì những lý do nào?';
		|ru = 'Каким клиентам запрещена отгрузка?
		|Кто основной менеджер клиента?
		|Какие причины запрета?';
		|en = 'Check to which customers delivery is blocked.
		|Verify the principal customer manager.
		|Check the delivery block reasons.'; fa = 'Check to which customers delivery is blocked.
		|Verify the principal customer manager.
		|Check the delivery block reasons.';
		|it = 'Каким клиентам запрещена отгрузка?
		|Кто основной менеджер клиента?
		|Какие причины запрета?';
		|pl = 'Jakim klientom jest zabroniona wysyłka?
		|Kto jest głównym menedżerem klienta?
		|Jakie przyczyny zakazu?';
		|tr = 'Hangi müşterilere sevkiyat yasaktır?
		|Müşterinin esas yöneticisi kimdir?
		|Yasağın nedenleri nelerdir?'");
	OptionDetails.FunctionalOptions.Add("UseShipmentProhibition");
	DescriptionOfReport.DefaultVisibility = False;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
