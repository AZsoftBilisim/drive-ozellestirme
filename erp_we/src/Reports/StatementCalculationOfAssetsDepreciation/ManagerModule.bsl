#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	ValueTableRow -
//
Function AddFAReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.StatementCalculationOfAssetsDepreciation)
		And NonCurrentAssets.VNAManagementIsUsed_2_4()
		And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StatementCalculationOfAssetsDepreciation.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính khấu hao';
											|ru = 'Справка-расчет амортизации';
											|en = 'Sheet of fixed assets depreciation charges'; fa = 'برگه محاسبات استهلاک دارایی‌های ثابت';
											|it = 'Informazioni sul calcolo dell''ammortamento';
											|pl = 'Zaświadczenie-obliczanie amortyzacji';
											|tr = 'Amortisman hesaplama özeti'");
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = True;
		ReportCommand.AdditionalParameters.Insert("CommandName", "HelpFACalculation");
		ReportCommand.VariantKey = "HelpFADepreciationCalculation";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	ValueTableRow - Team settings.
Function AddReportCommandOnFADepreciationDocument(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.StatementCalculationOfAssetsDepreciation)
		And NonCurrentAssets.VNAManagementIsUsed_2_4()
		And Not NonCurrentAssetsInternal.ComplianceCAAccountingIsKept() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StatementCalculationOfAssetsDepreciation.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính khấu hao';
											|ru = 'Справка-расчет амортизации';
											|en = 'Sheet of fixed assets depreciation charges'; fa = 'برگه محاسبات استهلاک دارایی‌های ثابت';
											|it = 'Informazioni sul calcolo dell''ammortamento';
											|pl = 'Zaświadczenie-obliczanie amortyzacji';
											|tr = 'Amortisman hesaplama özeti'");
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		ReportCommand.VariantKey = "ReferenceCalculationOfDocumentDepreciationFAContext";
		ReportCommand.AdditionalParameters.Insert("CommandName", "ReferenceCalculationOfDocumentDepreciationFA");
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ComplianceCAAccountingIsKept - Boolean
//
Procedure CustomizeReportOptions(Settings, ComplianceCAAccountingIsKept) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.StatementCalculationOfAssetsDepreciation);
	DescriptionOfReport.Enabled = Not ComplianceCAAccountingIsKept;
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Công thức cho khấu hao là gì?';
									|ru = 'По какой формуле рассчитана амортизация?';
									|en = 'Analyze accrued depreciation of the assets.'; fa = 'Analyze accrued depreciation of the assets.';
									|it = 'По какой формуле рассчитана амортизация?';
									|pl = 'Jaka formuła służy do amortyzacji?';
									|tr = 'Amortismanı hesaplamak için hangi formül kullanılmıştır?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "HelpFADepreciationCalculation");
	OptionDetails.Enabled = Not ComplianceCAAccountingIsKept;
	OptionDetails.LongDesc = NStr("vi = 'Công thức cho khấu hao là gì?';
									|ru = 'По какой формуле рассчитана амортизация?';
									|en = 'Analyze accrued depreciation of the assets.'; fa = 'Analyze accrued depreciation of the assets.';
									|it = 'По какой формуле рассчитана амортизация?';
									|pl = 'Jaka formuła służy do amortyzacji?';
									|tr = 'Amortismanı hesaplamak için hangi formül kullanılmıştır?'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ReferenceCalculationOfDocumentDepreciationFAContext");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf