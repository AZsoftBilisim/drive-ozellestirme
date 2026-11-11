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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.BonusPoints);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Số dư điểm thưởng được tính cho khách hàng là bao nhiêu?';
									|ru = 'Сколько осталось бонусных баллов, начисленных клиенту?';
									|en = 'Check how many accrued bonus points are available.'; fa = 'Check how many accrued bonus points are available.';
									|it = 'Сколько осталось бонусных баллов, начисленных клиенту?';
									|pl = 'Ile zostało punktów bonusowych, naliczonych klientowi?';
									|tr = 'Müşteriye tahakkuk eden kaç bonus puan kaldı?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BalanceBonusPoints");
	OptionDetails.LongDesc = NStr("vi = 'Khách hàng còn lại bao nhiêu điểm thưởng?
		|Điểm tích lũy còn lại theo chương trình tích điểm khách hàng thân thiết nào?';
		|ru = 'Сколько осталось бонусных баллов, начисленных клиенту?
		|По каким бонусным программам остались начисленные баллы?';
		|en = 'Check how many accrued bonus points are available.
		|Verify which rewards programs have accrued bonus points.'; fa = 'Check how many accrued bonus points are available.
		|Verify which rewards programs have accrued bonus points.';
		|it = 'Сколько осталось бонусных баллов, начисленных клиенту?
		|По каким бонусным программам остались начисленные баллы?';
		|pl = 'Ile zostało punktów bonusowych, naliczonych klientowi? 
		|Według jakich programów bonusowych zostały naliczone punkty?';
		|tr = 'Müşteriye tahakkuk eden kaç bonus puan kaldı?
		|Hangi bonus programları için tahakkuk eden puanlar kaldı?'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "BalanceOfBonusPointsIsBasic");
	OptionDetails.LongDesc = NStr("vi = 'Số dư điểm thưởng được tính cho khách hàng là bao nhiêu?';
									|ru = 'Сколько осталось бонусных баллов, начисленных клиенту?';
									|en = 'Check how many accrued bonus points are available.'; fa = 'Check how many accrued bonus points are available.';
									|it = 'Сколько осталось бонусных баллов, начисленных клиенту?';
									|pl = 'Ile zostało punktów bonusowych, naliczonych klientowi?';
									|tr = 'Müşteriye tahakkuk eden kaç bonus puan kaldı?'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
