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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.EfficiencyOfCustomerOpportunities);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Số lượng vụ việc giành được, thất bại hoặc đang làm việc là bao nhiêu?';
									|ru = 'Какое количество сделок выиграно, проиграно или находится в работе?';
									|en = 'Check how many sales opportunities are won, lost, or in progress.'; fa = 'Check how many sales opportunities are won, lost, or in progress.';
									|it = 'Какое количество сделок выиграно, проиграно или находится в работе?';
									|pl = 'Jaka ilość transakcji zostało wygrano, przegrano lub znajdują się w pracy?';
									|tr = 'Kaç satış fırsatı kazanıldı, kaybedildi veya işlem sürecinde?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TransactionEfficiency");
	OptionDetails.LongDesc = NStr("vi = 'Số lượng vụ việc giành được, thất bại hoặc đang làm việc là bao nhiêu?
		|Số tiền bán hàng tiềm năng là bao nhiêu?';
		|ru = 'Какое количество сделок выиграно, проиграно или находится в работе?
		|На какую потенциальную сумму продаж?';
		|en = 'Check how many sales opportunities are won, lost, or in progress.
		|Verify for what potential sales amount.'; fa = 'Check how many sales opportunities are won, lost, or in progress.
		|Verify for what potential sales amount.';
		|it = 'Какое количество сделок выиграно, проиграно или находится в работе?
		|На какую потенциальную сумму продаж?';
		|pl = 'Jaka ilość transakcji zostało wygrano, przegrano lub znajdują się w pracy? 
		|Na jaką potencjalną wartość sprzedaży?';
		|tr = 'Kaç  satış fırsatı kazanıldı, kaybedildi veya işlem sürecinde?
		|Potansiyel satış tutarı nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
