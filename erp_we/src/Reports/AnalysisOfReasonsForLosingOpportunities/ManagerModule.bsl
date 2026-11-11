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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AnalysisOfReasonsForLosingOpportunities);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Nguyên nhân nào dẫn đến thua vụ việc?';
									|ru = 'Какие причины привели к проигрышу сделок?';
									|en = 'Verify the reasons for losing sales opportunities.'; fa = 'Verify the reasons for losing sales opportunities.';
									|it = 'Какие причины привели к проигрышу сделок?';
									|pl = 'Jakie przyczyny doprowadziły do przegrania transakcji?';
									|tr = 'Hangi nedenler satış fırsatı kaybına yol açmıştır?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ReasonsForLosingSalesOpportunities");
	OptionDetails.LongDesc = NStr("vi = 'Những nguyên nhân nào dẫn đến thua vụ việc?
		|Của người quản lý nào?
		|Với khách hàng nào?';
		|ru = 'Какие причины привели к проигрышу сделок?
		|У каких менеджеров?
		|С какими клиентами?';
		|en = 'Verify the reasons for losing sales opportunities.
		|Check which managers and customers were involved.
		|'; fa = 'Verify the reasons for losing sales opportunities.
		|Check which managers and customers were involved.
		|';
		|it = 'Какие причины привели к проигрышу сделок?
		|У каких менеджеров?
		|С какими клиентами?';
		|pl = 'Jakie przyczyny doprowadziły do przegrania transakcji? 
		|U jakich menedżerów? 
		|Z jakimi klientami?';
		|tr = 'Hangi nedenler satış fırsatı kaybına yol açmıştır?
		|Hangi yöneticilerde?
		|Hangi müşteriler ile?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
