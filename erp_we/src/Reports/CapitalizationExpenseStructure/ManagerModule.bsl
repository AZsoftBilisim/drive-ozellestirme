#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// ValueTable - see the Menu Reports function.Create a collection of Team reports.
// Undefined.
//
Function AddIAReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.CapitalizationExpenseStructure) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CapitalizationExpenseStructure.FullName();
		ReportCommand.Presentation = NStr("vi = 'Cơ cấu chi phí vốn hóa';
											|ru = 'Структура затрат на капитализацию';
											|en = 'Capital expenditures'; fa = 'مخارج سرمایه‌ای';
											|it = 'Struttura delle spese di capitalizzazione';
											|pl = 'Struktura rozchodów na kapitalizację';
											|tr = 'Sermaye maliyetlerinin yapısı'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "IACostStructure");
		ReportCommand.VariantKey = "CostStructure_";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.CapitalizationExpenseStructure) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CapitalizationExpenseStructure.FullName();
		ReportCommand.Presentation = NStr("vi = 'Cơ cấu chi phí vốn hóa';
											|ru = 'Структура затрат на капитализацию';
											|en = 'Capital expenditures'; fa = 'مخارج سرمایه‌ای';
											|it = 'Struttura delle spese di capitalizzazione';
											|pl = 'Struktura rozchodów na kapitalizację';
											|tr = 'Sermaye maliyetlerinin yapısı'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.AdditionalParameters.Insert("CommandName", "CostStructure_");
		ReportCommand.VariantKey = "CostStructure_";
		
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
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.CapitalizationExpenseStructure);
	DescriptionOfReport.Enabled = True;
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Cơ cấu của chi phí cơ sở vật chất theo doanh nghiệp là gì?';
									|ru = 'Какова структура затрат на объект по организациям?';
									|en = 'What is the object cost structure by companies?'; fa = 'What is the object cost structure by companies?';
									|it = 'Какова структура затрат на объект по организациям?';
									|pl = 'Jaka jest struktura rozchodów na obiekt wg firm?';
									|tr = 'İş yerlerine göre nesne başına gider yapısı nedir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "CostStructure_");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Cơ cấu của chi phí cơ sở vật chất theo doanh nghiệp là gì?';
									|ru = 'Какова структура затрат на объект по организациям?';
									|en = 'What is the object cost structure by companies?'; fa = 'What is the object cost structure by companies?';
									|it = 'Какова структура затрат на объект по организациям?';
									|pl = 'Jaka jest struktura rozchodów na obiekt wg firm?';
									|tr = 'İş yerlerine göre nesne başına gider yapısı nedir?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "EnterpriseCostStructure");
	OptionDetails.Enabled = True;
	OptionDetails.LongDesc = NStr("vi = 'Cơ cấu của chi phí cơ sở vật chất theo tập đoàn là gì?';
									|ru = 'Какова структура затрат на объект по предприятию?';
									|en = 'What is the object cost structure at enterprise?'; fa = 'What is the object cost structure at enterprise?';
									|it = 'Какова структура затрат на объект по предприятию?';
									|pl = 'Jaka jest struktura rozchodów na obiekt wg przedsiębiorstwa?';
									|tr = 'İşletmeye göre nesne başına gider yapısı nedir?'");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf