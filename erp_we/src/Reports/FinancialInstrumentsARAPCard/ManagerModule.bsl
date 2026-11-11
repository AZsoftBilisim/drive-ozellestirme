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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.FinancialInstrumentsARAPCard);
	DescriptionOfReport.DefineFormSettings = True;
	BriefDescriptionOfReport = NStr("vi = 'Diễn giải tính và thanh toán đến chứng từ nguồn ghi.
		|Chứng từ nào đã tạo số dư hạch toán hiện tại?';
		|ru = 'Расшифровка начислений и оплат до документов регистраторов.
		|Какие документы сформировали текущее сальдо расчетов?';
		|en = 'Drills down charges and payments to recorder documents.
		|What documents have generated the current AR/AP balance?'; fa = 'Drills down charges and payments to recorder documents.
		|What documents have generated the current AR/AP balance?';
		|it = 'Расшифровка начислений и оплат до документов регистраторов.
		|Какие документы сформировали текущее сальдо расчетов?';
		|pl = 'Drills down charges and payments to recorder documents.
		|What documents have generated the current AR/AP balance?';
		|tr = 'Tahakkukları ve ödemeleri kayıt memurlarının belgelerine kadar genişletin.
		|Mevcut hesap bakiyesini hangi belgeler oluşturmuş?'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "FinancialInstrumentsARAPCard");
	OptionDetails.LongDesc = BriefDescriptionOfReport;
	OptionDetails.FunctionalOptions.Add("EnterpriseManagement");
	OptionDetails.FunctionalOptions.Add("ComplexAutomation");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TMCardOfSettlementsOnFinancialInstruments");
	OptionDetails.LongDesc = BriefDescriptionOfReport;
	OptionDetails.FunctionalOptions.Add("TradeManagement");
	OptionDetails.FunctionalOptions.Add("BaseVersion");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "SettlementCardForFinancialInstrumentsContext");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "CardOfSettlementsOnFinancialInstrumentsTMContext");
	
EndProcedure

// Adds the "Financial Instruments Settlement Card" report command to the list of commands.
// Grouping by partner/counterparty
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
// 	- ValueTableRow: See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands.
// 	- Undefined - If there are no rights to view the report.
//
Function AddReportCommand(ReportsCommands) Export
	If Constants.NewOnlineARAPAccounting.Get() Then
		If AccessRight("View", Metadata.Reports.FinancialInstrumentsARAPCard) Then
			
			ReportCommand = ReportsCommands.Add();
			
			ReportCommand.Manager = Metadata.Reports.FinancialInstrumentsARAPCard.FullName();
			ReportCommand.Presentation = Metadata.Reports.FinancialInstrumentsARAPCard.Synonym;
			
			ReportCommand.MultipleChoice = True;
			ReportCommand.Importance = "Ordinary";
			ReportCommand.AdditionalParameters.Insert("CommandName", "CardForFinancialInstruments");
			ReportCommand.VariantKey = "SettlementCardForFinancialInstrumentsContext";
			
			Return ReportCommand;
			
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction

#EndRegion

#EndRegion

#EndIf
