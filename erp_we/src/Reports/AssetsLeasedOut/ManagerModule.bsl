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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.AssetsLeasedOut);
	DescriptionOfReport.FunctionalOptions.Add("UseNonCurrentAssets2_4");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những TSCĐ nào đã được chuyển vào thuê?
									 |Người thuê là ai?
									 |Thời hạn thuê?';
									 |ru = 'Какие ОС были переданы в аренду?
									 |Кому были переданы?
									 |Какой срок аренды?';
									 |en = 'View the fixed assets provided to lessee.
									 |Check the lessees.
									 |Track the lease terms.'; fa = 'View the fixed assets provided to lessee.
									 |Check the lessees.
									 |Track the lease terms.';
									 |it = 'Какие ОС были переданы в аренду?
									 |Кому были переданы?
									 |Какой срок аренды?';
									 |pl = 'Jakie środki trwałe przekazano do dzierżawy?
									 |Komu przekazane?
									 |Jaki jest okres dzierżawy?';
									 |tr = 'Hangi sabit kıymetler kiralanmıştır?
									 | Kime kiralanmıştır? 
									 |Kiralama süresi ne kadar?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AssetsLeasedOut");
	OptionDetails.LongDesc = NStr("vi = 'Những TSCĐ nào đã được chuyển vào thuê?
									 |Người thuê là ai?
									 |Thời hạn thuê?';
									 |ru = 'Какие ОС были переданы в аренду?
									 |Кому были переданы?
									 |Какой срок аренды?';
									 |en = 'View the fixed assets provided to lessee.
									 |Check the lessees.
									 |Track the lease terms.'; fa = 'View the fixed assets provided to lessee.
									 |Check the lessees.
									 |Track the lease terms.';
									 |it = 'Какие ОС были переданы в аренду?
									 |Кому были переданы?
									 |Какой срок аренды?';
									 |pl = 'Jakie środki trwałe przekazano do dzierżawy?
									 |Komu przekazane?
									 |Jaki jest okres dzierżawy?';
									 |tr = 'Hangi sabit kıymetler kiralanmıştır?
									 | Kime kiralanmıştır? 
									 |Kiralama süresi ne kadar?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
