#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// For the "report Options" subsystem when working in the service model.
// 
// Returns:
//  Array - Settings options
//
Function SettingVariants() Export
	
	Result = New Array;
	
	Variant = New Structure;
	Variant.Insert("Name",           "FinancialStateOfCompany");
	Variant.Insert("Presentation", NStr("vi = 'Trạng thái tài chính';
										|ru = 'Финансовое состояние';
										|en = 'Financial condition'; fa = 'وضعیت مالی';
										|it = 'Stato finanziario';
										|pl = 'Sytuacja finansowa';
										|tr = 'Mali durum'"));
	Result.Add(Variant);
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FinancialCondition);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "FinancialStateOfCompany");
	OptionDetails.LongDesc = NStr("vi = 'Các chỉ tiêu tài chính nào theo dạng tài sản và nợ phải trả?';
									|ru = 'Каковы финансовые показатели по статьям активов и обязательств?';
									|en = 'What are financial indicators of items of assets and liabilities?'; fa = 'What are financial indicators of items of assets and liabilities?';
									|it = 'Каковы финансовые показатели по статьям активов и обязательств?';
									|pl = 'Jakie są wskaźniki według pozycji aktywów i zobowiązań?';
									|tr = 'Varlıklar ve yükümlülüklere göre finansal göstergeler nelerdir?'");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ManagementBalanceSheetIsOutdated");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "BalanceControlObsolete");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "AssetLiabilityCardContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOfInputOfBalances");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf