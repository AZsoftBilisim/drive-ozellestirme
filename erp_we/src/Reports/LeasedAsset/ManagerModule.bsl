//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LeasedAsset);
	DescriptionOfReport.FunctionalOptions.Add("UseNonCurrentAssets2_4");
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những TSCĐ nào đã nhận thuê?
									 |Người cho thuê là ai?
									 |Thời hạn thuê?';
									 |ru = 'Какие ОС были получены в аренду?
									 |От кого были получены?
									 |Какой срок аренды?';
									 |en = 'View leased fixed assets.
									 |Check the lessors.
									 |Track the lease terms.'; fa = 'View leased fixed assets.
									 |Check the lessors.
									 |Track the lease terms.';
									 |it = 'Какие ОС были получены в аренду?
									 |От кого были получены?
									 |Какой срок аренды?';
									 |pl = 'Jakie środki trwałe otrzymano do dzierżawy?
									 |Od kogo były otrzymane?
									 |Jaki jest okres dzierżawy?';
									 |tr = 'Hangi sabit kıymetler kiralanmıştır?
									 | Kimden kiralanmıştır?
									 | Kiralama süresi ne kadardır?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "LeasedAsset");
	OptionDetails.LongDesc = NStr("vi = 'Những TSCĐ nào đã nhận thuê?
									 |Người cho thuê là ai?
									 |Thời hạn thuê?';
									 |ru = 'Какие ОС были получены в аренду?
									 |От кого были получены?
									 |Какой срок аренды?';
									 |en = 'View leased fixed assets.
									 |Check the lessors.
									 |Track the lease terms.'; fa = 'View leased fixed assets.
									 |Check the lessors.
									 |Track the lease terms.';
									 |it = 'Какие ОС были получены в аренду?
									 |От кого были получены?
									 |Какой срок аренды?';
									 |pl = 'Jakie środki trwałe otrzymano do dzierżawy?
									 |Od kogo były otrzymane?
									 |Jaki jest okres dzierżawy?';
									 |tr = 'Hangi sabit kıymetler kiralanmıştır?
									 | Kimden kiralanmıştır?
									 | Kiralama süresi ne kadardır?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
