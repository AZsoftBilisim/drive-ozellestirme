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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ExpenseStructureByFixedAssets);
	DescriptionOfReport.FunctionalOptions.Add("UseNonCurrentAssets2_4");
	DescriptionOfReport.FunctionalOptions.Add("UseRMManagement");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí đưa vào TSCĐ là bao nhiêu?';
									|ru = 'Какие затраты отнесены на основные средства?';
									|en = 'View expenses allocated to fixed assets.'; fa = 'View expenses allocated to fixed assets.';
									|it = 'Какие затраты отнесены на основные средства?';
									|pl = 'Jakie rozchody są odniesione na środki trwałe?';
									|tr = 'Sabit kıymetlere hangi giderler tahsis edilmiştir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ExpenseStructureByFixedAssets");
	OptionDetails.LongDesc = NStr("vi = 'Chi phí đưa vào TSCĐ là bao nhiêu?';
									|ru = 'Какие затраты отнесены на основные средства?';
									|en = 'View expenses allocated to fixed assets.'; fa = 'View expenses allocated to fixed assets.';
									|it = 'Какие затраты отнесены на основные средства?';
									|pl = 'Jakie rozchody są odniesione na środki trwałe?';
									|tr = 'Sabit kıymetlere hangi giderler tahsis edilmiştir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
