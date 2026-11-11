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
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.FixedAssetsWithImpairment)
		And NonCurrentAssets.VNAManagementIsUsed_2_4() Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.FixedAssetsWithImpairment.FullName();
		ReportCommand.Presentation = NStr("vi = 'Tài sản dài hạn có giảm giá trị';
											|ru = 'Внеоборотные активы с обесценением';
											|en = 'Fixed and intangible assets with impairment'; fa = 'دارایی‌های ثابت و نامشهود دارای کاهش ارزش';
											|it = 'Attivi non correnti con svalutazione';
											|pl = 'Aktywa nieobrotowe z utratą wartości';
											|tr = 'Değer kaybına uğrayan duran varlıklar'");
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = True;
		ReportCommand.AdditionalParameters.Insert("CommandName", "FixedAssetsWithImpairment");
		ReportCommand.VariantKey = "FixedAssetsWithImpairment";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction


// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.FixedAssetsWithImpairment.AddReportCommand(ReportsCommands);

EndProcedure



#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FixedAssetsWithImpairment);
	DescriptionOfReport.FunctionalOptions.Add("UseNonCurrentAssets2_4");
	DescriptionOfReport.FunctionalOptions.Add("UseFixedAssetImpairment");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Số dư khấu hao theo tài sản dài hạn có gom nhóm theo đơn vị tạo tiền.';
									|ru = 'Остаток обесценения по внеоборотным активам с группировкой по единицам генерирующим денежные средства.';
									|en = 'Impairment balance for fixed assets with grouping by cash-generation units.'; fa = 'Impairment balance for fixed assets with grouping by cash-generation units.';
									|it = 'Остаток обесценения по внеоборотным активам с группировкой по единицам генерирующим денежные средства.';
									|pl = 'Saldo utraty wartości według aktywów nieobrotowych z grupowaniem według jednostek generujących środki pieniężne.';
									|tr = 'Nakit üreten birimlere göre gruplandırılmış duran varlıklar için değer düşüklüğü bakiyesi.'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf