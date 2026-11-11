#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//
// Returns:
//	ValueTableRow, Undefined - the generated command to output to the submenu.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát khoản tạm ứng đã chi cho người nhận tạm ứng';
											|ru = 'Контроль выданных подотчетному лицу авансов';
											|en = 'Control of advances paid to advance holder'; fa = 'کنترل پیش‌پرداخت‌های پرداخت‌شده به تنخواه‌گردان';
											|it = 'Controllo dei pagamenti anticipati rilasciati alla persona responsabile titola di anticipo';
											|pl = 'Kontrola wydanych zaliczek osobie odpowiedzialnej';
											|tr = 'Sorumlu kişiye verilen avansların kontrolü'");
		ReportCommand.VisibilityInForms = "ListForm, DocumentsListForm, FormOfListOfRequestsForApproval";
		ReportCommand.Order       = 70;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ControlOnApplicationContext";
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.IssueCashToAdvanceHolder,
			DataCompositionComparisonType.Equal);
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest.FullName();
		ReportCommand.Presentation = NStr("vi = 'Kiểm soát khoản tạm ứng đã chi cho người nhận tạm ứng';
											|ru = 'Контроль выданных подотчетному лицу авансов';
											|en = 'Control of advances paid to advance holder'; fa = 'کنترل پیش‌پرداخت‌های پرداخت‌شده به تنخواه‌گردان';
											|it = 'Controllo dei pagamenti anticipati rilasciati alla persona responsabile titola di anticipo';
											|pl = 'Kontrola wydanych zaliczek osobie odpowiedzialnej';
											|tr = 'Sorumlu kişiye verilen avansların kontrolü'");
		ReportCommand.VisibilityInForms = "DocumentForm";
		ReportCommand.Order       = 70;
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		ReportCommand.VariantKey = "ControlOnApplicationContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ControlOfAdvancesPaidToAdvanceHolderUnderRequest);
	DescriptionOfReport.DefineFormSettings = True;
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "ApplicationControl");
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ControlOnApplicationContext");
	OptionDetails.LongDesc = NStr("vi = 'Số tiền mà người nhận tạm ứng chưa lập bảng kê?';
									|ru = 'На какую сумму не отчитался подотчетник?';
									|en = 'How much did the advance holder not report?'; fa = 'How much did the advance holder not report?';
									|it = 'На какую сумму не отчитался подотчетник?';
									|pl = 'How much did the advance holder not report?';
									|tr = 'Sorumlu kişi hangi tutarı bildirmedi?'");
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf