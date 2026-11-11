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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CustomerLoyaltyXYZ);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những khách hàng nào mua thường xuyên?';
									|ru = 'Какие клиенты покупают регулярно?';
									|en = 'Check which customers buy regularly.'; fa = 'Check which customers buy regularly.';
									|it = 'Какие клиенты покупают регулярно?';
									|pl = 'Jakie klienty kupują regularnie?';
									|tr = 'Hangi müşteriler düzenli olarak satın almaktadır?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "Main");
	OptionDetails.LongDesc = NStr("vi = 'Những khách hàng nào mua hàng ổn định?
		|Những khách hàng nào chỉ mua một lần?';
		|ru = 'Какие клиенты покупают стабильно?
		|Какие клиенты являются разовыми?';
		|en = 'Track which customers buy consistently.
		|See which customers make one-time purchases.'; fa = 'Track which customers buy consistently.
		|See which customers make one-time purchases.';
		|it = 'Какие клиенты покупают стабильно?
		|Какие клиенты являются разовыми?';
		|pl = 'Jakie klienty kupują stabilnie? 
		|Jakie klienty są razowymi?';
		|tr = 'Hangi müşteriler sürekli satın almaktadır?
		|Hangi müşteriler tek seferliktir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
