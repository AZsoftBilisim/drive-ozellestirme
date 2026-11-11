#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//  See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//  Undefined, ValueTableRow - Add a report command
//
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.UseAccountsAndExtraDimensionInSettings) 
			And GetFunctionalOption("UseFinancialAccounting") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.UseAccountsAndExtraDimensionInSettings.FullName();
		ReportCommand.Presentation = NStr("vi = 'Sử dụng tài khoản';
											|ru = 'Использование счета';
											|en = 'Use account'; fa = 'استفاده از حساب';
											|it = 'Utilizzo del conto';
											|pl = 'Wykorzystanie rachunku';
											|tr = 'Hesap kullanımı'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FormParameters = New Structure("UserSettingsKey", "UsingContextualReportInvoice");
		ReportCommand.VariantKey = "AccountUsageContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.UseAccountsAndExtraDimensionInSettings);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tùy chỉnh báo cáo và mẫu bút toán, trong đó sử dụng các tài khoản của hệ thống tài khoản và khoản mục.';
									|ru = 'Анализ настроек отчетов и шаблонов проводок, где используются счета плана счетов и субконто.';
									|en = 'Analyze report and posting template settings where accounts of chart of accounts and extra dimensions are used.'; fa = 'Analyze report and posting template settings where accounts of chart of accounts and extra dimensions are used.';
									|it = 'Анализ настроек отчетов и шаблонов проводок, где используются счета плана счетов и субконто.';
									|pl = 'Analiza ustawień raportów i szablonów dekretowania, gdzie są używane konta planu kont i subkont.';
									|tr = 'Muhasebe hesap planı ve ekstra boyut hesaplarının kullanıldığı rapor ayarlarının ve kayıt şablonlarının analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "UseAccountsAndExtraDimensionInSettings");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích tùy chỉnh báo cáo và mẫu bút toán, trong đó sử dụng các tài khoản của hệ thống tài khoản và khoản mục.';
									|ru = 'Анализ настроек отчетов и шаблонов проводок, где используются счета плана счетов и субконто.';
									|en = 'Analyze report and posting template settings where accounts of chart of accounts and extra dimensions are used.'; fa = 'Analyze report and posting template settings where accounts of chart of accounts and extra dimensions are used.';
									|it = 'Анализ настроек отчетов и шаблонов проводок, где используются счета плана счетов и субконто.';
									|pl = 'Analiza ustawień raportów i szablonów dekretowania, gdzie są używane konta planu kont i subkont.';
									|tr = 'Muhasebe hesap planı ve ekstra boyut hesaplarının kullanıldığı rapor ayarlarının ve kayıt şablonlarının analizi.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "AccountUsageContext");	
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf