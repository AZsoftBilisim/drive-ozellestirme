#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.GoodsToReceive) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.GoodsToReceive.FullName();
		ReportCommand.Presentation = NStr("vi = 'Thực hiện tiếp nhận hàng hóa';
											|ru = 'Выполнение приемки товаров';
											|en = 'Goods receipt'; fa = 'رسید انبار';
											|it = 'Accettazione delle merci';
											|pl = 'Trwa przyjęcie towarów';
											|tr = 'Mal girişinin gerçekleştirilmesi'");
		
		ReportCommand.Importance      = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "GoodsToBeReceivedByOrder");
		
		ReportCommand.VariantKey =                    "StateOfAcceptanceContext";
		
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
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsToReceive);
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái của lệnh tiếp nhận.';
									|ru = 'Анализ состояний распоряжений на поступление.';
									|en = 'Analyze receipt reference states.'; fa = 'Analyze receipt reference states.';
									|it = 'Анализ состояний распоряжений на поступление.';
									|pl = 'Analiza statusów zamówień do wpływu.';
									|tr = 'Giriş siparişlerinin durumunun analizi.'");
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "AcceptanceState");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích trạng thái của lệnh tiếp nhận.';
									|ru = 'Анализ состояний распоряжений на поступление.';
									|en = 'Analyze receipt reference states.'; fa = 'Analyze receipt reference states.';
									|it = 'Анализ состояний распоряжений на поступление.';
									|pl = 'Analiza statusów zamówień do wpływu.';
									|tr = 'Giriş siparişlerinin durumunun analizi.'");
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.GoodsToReceive);
	DescriptionOfReport.DefineFormSettings = True;
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

#EndRegion

#EndRegion
		
#EndIf