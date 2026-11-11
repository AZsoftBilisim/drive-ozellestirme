//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   DisplayReportOptions - Boolean
//
Procedure CustomizeReportOptions(Settings, DisplayReportOptions) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BalancesAndMovementsOfCashInCashRegisters);
	ReportsOptions.SetOutputModeInReportPanels(Settings, DescriptionOfReport, DisplayReportOptions);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát tiền mặt tại quầy thu ngân.';
									|ru = 'Контроль денежных средств в кассах ККМ.';
									|en = 'Control cash in cash registers.'; fa = 'Control cash in cash registers.';
									|it = 'Контроль денежных средств в кассах ККМ.';
									|pl = 'Kontrola środki pieniężnych-gotówki w kasach.';
									|tr = 'Yazar kasalarda nakit kontrolü.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashFlowsOfCashRegister");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát vốn bằng tiền tại quầy thu ngân.
		|Đã nộp và rút bao nhiêu tiền và khi nào vào quầy thu ngân nào?';
		|ru = 'Контроль денежных средств в кассах ККМ.
		|В какой кассе ККМ, когда и сколько денежных средств приходило или уходило?';
		|en = 'Control cash in cash registers.
		|Track in which cash register, when and how much cash was put in and taken out.'; fa = 'Control cash in cash registers.
		|Track in which cash register, when and how much cash was put in and taken out.';
		|it = 'Контроль денежных средств в кассах ККМ.
		|В какой кассе ККМ, когда и сколько денежных средств приходило или уходило?';
		|pl = 'Kontrola środków pieniężnych-gotówki w kasach. 
		|W jakiej kasie, kiedy i ile środków pieniężnych-gotówki wpływało lub upływało?';
		|tr = 'Yazar kasalarda nakit kontrolü
		|Yazar kasaların hangisine, ne zaman ve ne kadar nakit girdi veya çıktı?'");
	OptionDetails.FunctionalOptions.Add("UseMultipleCurrencies");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CashFlowsOfCashRegisteredOneCurrency");
	OptionDetails.LongDesc = NStr("vi = 'Kiểm soát vốn bằng tiền tại quầy thu ngân.
		|Đã nộp và rút bao nhiêu tiền và khi nào vào quầy thu ngân nào?';
		|ru = 'Контроль денежных средств в кассах ККМ.
		|В какой кассе ККМ, когда и сколько денежных средств приходило или уходило?';
		|en = 'Control cash in cash registers.
		|Track in which cash register, when and how much cash was put in and taken out.'; fa = 'Control cash in cash registers.
		|Track in which cash register, when and how much cash was put in and taken out.';
		|it = 'Контроль денежных средств в кассах ККМ.
		|В какой кассе ККМ, когда и сколько денежных средств приходило или уходило?';
		|pl = 'Kontrola środków pieniężnych-gotówki w kasach. 
		|W jakiej kasie, kiedy i ile środków pieniężnych-gotówki wpływało lub upływało?';
		|tr = 'Yazar kasalarda nakit kontrolü
		|Yazar kasaların hangisine, ne zaman ve ne kadar nakit girdi veya çıktı?'");
	OptionDetails.FunctionalOptions.Add("NotUseMultipleCurrencies");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
