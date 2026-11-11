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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsWithExpiringCertificates);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "GoodsWithExpiringCertificates");
	OptionDetails.LongDesc = NStr("vi = 'Hạn hiệu lực kết thúc theo chứng thư nào?';
									|ru = 'По каким сертификатам заканчивается срок действия?';
									|en = 'Check which certificates are about to expire.'; fa = 'Check which certificates are about to expire.';
									|it = 'По каким сертификатам заканчивается срок действия?';
									|pl = 'Według jakich certyfikatów upływa termin ważności?';
									|tr = 'Hangi sertifikaların geçerlilik süresi yakında sona ereceğini kontrol et.'");
	OptionDetails.Enabled = True;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
