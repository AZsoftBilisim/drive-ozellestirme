#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Placement settings in the report panel.
//
// Parameters:
//   Settings - Structure - Used to describe report settings and options
//       , see the description of report variationsreferencesTree set-up Variantsconfiguration reports().
//   ReportSettings - ValueTreeRow - Settings for the placement of all report options.
//       See "Attributes For changes" of the Report variationfunctions.Tree set-upvariantsconfiguration reports().
//
// Description:
//   See ReportsOptionsOverridable.CustomizeReportsOptions.
//
// Auxiliary methods:
//   Setting the variant = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//   Report variationsreferences.Set the output mode of the Report panel(Settings, Report settings, True/False); 
// The report
//   supports only this mode.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.SetOutputModeInReportPanels(Settings, ReportSettings, False);
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings,
		"ReferenceCalculationDiscountingOfProvisionsAndContingentLiabilities");
	OptionSettings.Enabled = False;
	OptionSettings.LongDesc = NStr("vi = 'Bảng tính chiết khấu dự phòng chi phí trả trước.';
									|ru = 'Справка-расчет дисконтирования резервов предстоящих расходов.';
									|en = 'Detailed calculation of discounting of provisions and contingent liabilities.'; fa = 'Detailed calculation of discounting of provisions and contingent liabilities.';
									|it = 'Справка-расчет дисконтирования резервов предстоящих расходов.';
									|pl = 'Detailed calculation of discounting of provisions and contingent liabilities.';
									|tr = 'Karşılıkların ve şarta bağlı yükümlülüklerin iskonto edilmesine ilişkin hesaplama özeti.'");
EndProcedure

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If GetFunctionalOption("GenerateFutureExpenseCommitments")
		And AccessRight("View", Metadata.Reports.DetailedCalculationOfDiscountingOfProvisionsAndContingentLiabilities) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DetailedCalculationOfDiscountingOfProvisionsAndContingentLiabilities.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính chiết khấu dự phòng chi phí trả trước';
											|ru = 'Справка-расчет дисконтирования резервов предстоящих расходов';
											|en = 'Detailed calculation of discounting of provisions and contingent liabilities'; fa = 'محاسبه تفصیلی تنزیل ذخایر و بدهی‌های احتمالی';
											|it = 'Справка-расчет дисконтирования резервов предстоящих расходов';
											|pl = 'Detailed calculation of discounting of provisions and contingent liabilities';
											|tr = 'Karşılıkların ve şarta bağlı yükümlülüklerin iskonto edilmesine ilişkin hesaplama özeti'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
	
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#EndIf