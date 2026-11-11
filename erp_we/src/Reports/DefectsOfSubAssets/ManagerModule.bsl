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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.DefectsOfSubAssets);
	DescriptionOfReport.FunctionalOptions.Add("UseSubAssets");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Những hỏng hóc nào đã đăng ký?';
									|ru = 'Какие дефекты были зарегистрированы?';
									|en = 'View the registered defects.'; fa = 'View the registered defects.';
									|it = 'Какие дефекты были зарегистрированы?';
									|pl = 'Jakie wady zostały zarejestrowane?';
									|tr = 'Ne tür kusurlar rapor edildi?'");
		
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "DefectsOfSubAssets");
	OptionDetails.LongDesc = NStr("vi = 'Những hỏng hóc nào đã đăng ký?';
									|ru = 'Какие дефекты были зарегистрированы?';
									|en = 'View the registered defects.'; fa = 'View the registered defects.';
									|it = 'Какие дефекты были зарегистрированы?';
									|pl = 'Jakie wady zostały zarejestrowane?';
									|tr = 'Ne tür kusurlar rapor edildi?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
