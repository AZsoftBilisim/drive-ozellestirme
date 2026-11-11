#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// 
// Returns:
//  Undefined, ValueTableRow - Add the command card of the asset liability
//
Function AddAssetLiabilityCardCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.TrialBalanceOfAssetsAndLiabilities) 
			And GetFunctionalOption("UseBalanceSheetStatement") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.TrialBalanceOfAssetsAndLiabilities.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thẻ tài sản/nguồn vốn';
											|ru = 'Карточка актива/пассива';
											|en = 'Card of asset/liability'; fa = 'کارت دارایی/بدهی';
											|it = 'Scheda attività/passività';
											|pl = 'Karta aktywów/zobowiązań';
											|tr = 'Aktif/pasif kartı'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.FunctionalOptions = "NotBaseVersion";
		ReportCommand.VariantKey = "AssetLiabilityCard";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.TrialBalanceOfAssetsAndLiabilities);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "OSVAssetsLiabilities");
	OptionDetails.DefaultVisibility = False;
	OptionDetails.LongDesc = NStr("vi = 'Số dư của tài sản và nguồn vốn vào đầu kỳ, cuối kỳ và số tiền phát sinh trong kỳ.';
									|ru = 'Остатки активов и пассивов на начало и на конец периода и суммы оборотов за период.';
									|en = 'Balance of assets and liabilities as of the start and end of the period and turnover amount for the period.'; fa = 'Balance of assets and liabilities as of the start and end of the period and turnover amount for the period.';
									|it = 'Остатки активов и пассивов на начало и на конец периода и суммы оборотов за период.';
									|pl = 'Ostatki aktywów i zobowiązań na początek i na koniec okresu i wartości obrotów za okres.';
									|tr = 'Dönem başı ve dönem sonundaki varlık ve yükümlülük bakiyeleri ile dönem ciro tutarı.'");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "AssetLiabilityCard");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf