//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ComplianceCAAccountingIsKept - Boolean
//
Procedure CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FixedAssetRegister);
	DescriptionOfReport.Enabled = Not ComplianceCAAccountingIsKept;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Tài sản cố định nào trong doanh nghiệp?';
									|ru = 'Какие основные средства числятся в организации?';
									|en = 'View company''s fixed assets.'; fa = 'View company''s fixed assets.';
									|it = 'Какие основные средства числятся в организации?';
									|pl = 'Jakie środki trwałe są zarejestrowane w firmie?';
									|tr = 'İş yerinin sabit kıymetleri nelerdir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
