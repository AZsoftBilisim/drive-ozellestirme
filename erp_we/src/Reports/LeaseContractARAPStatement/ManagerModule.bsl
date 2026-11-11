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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.LeaseContractARAPStatement);
	DescriptionOfReport.FunctionalOptions.Add("UseNonCurrentAssets2_4");
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Trạng thái hạch toán theo hợp đồng thuê (cho thuê).';
									|ru = 'Состояние расчетов по договорам аренды (лизинга).';
									|en = 'State of AR/AP under rental (financial lease) contracts.'; fa = 'State of AR/AP under rental (financial lease) contracts.';
									|it = 'Состояние расчетов по договорам аренды (лизинга).';
									|pl = 'Status rozliczeń wg umów dzierżawy (leasingu).';
									|tr = 'Kira (finansal kiralama) sözleşmeleri kapsamındaki ödemelerin durumu.'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ByCustomerContract");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
