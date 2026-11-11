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
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, ReportSettings, "Main");
	OptionSettings.Enabled = False;
	OptionSettings.LongDesc = NStr("vi = 'Bảng tính thay đổi phần trăm chiết khấu dự phòng chi phí trả trước.';
									|ru = 'Справка-расчет изменения процентов дисконтирования резервов предстоящих расходов.';
									|en = 'Calculation of interest on discounting of provisions and contingent liabilities.'; fa = 'Calculation of interest on discounting of provisions and contingent liabilities.';
									|it = 'Справка-расчет изменения процентов дисконтирования резервов предстоящих расходов.';
									|pl = 'Calculation of interest on discounting of provisions and contingent liabilities.';
									|tr = 'İskonto edilen karşılıklar ve şarta bağlı yükümlülüklerin faiz değişimine ilişkin hesap özeti.'");
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

	If  GetFunctionalOption("GenerateFutureExpenseCommitments")
		And AccessRight("View", Metadata.Reports.DetailedCalculationProvisionDiscountingInterestOfFutureExpenseCommitments) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DetailedCalculationProvisionDiscountingInterestOfFutureExpenseCommitments.FullName();
		ReportCommand.Presentation = NStr("vi = 'Bảng tính thay đổi phần trăm chiết khấu dự phòng chi phí trả trước.';
											|ru = 'Справка-расчет изменения процентов дисконтирования резервов предстоящих расходов';
											|en = 'Calculation of interest on discounting of provisions and contingent liabilities'; fa = 'محاسبه بهره تنزیل ذخایر و بدهی‌های احتمالی';
											|it = 'Справка-расчет изменения процентов дисконтирования резервов предстоящих расходов';
											|pl = 'Calculation of interest on discounting of provisions and contingent liabilities';
											|tr = 'İskonto edilen karşılıklar ve şarta bağlı yükümlülüklerin faiz değişimine ilişkin hesap özeti'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
	
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#EndIf