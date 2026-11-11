#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ReportsOptions

// The configuration options for that report.
// More detailed - See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DiscountsAppliedInDocument)
			And AccessRight("View", Metadata.Catalogs.DiscountsMarkups)
			And GetFunctionalOption("UseDiscountsMarkupsInSales") Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DiscountsAppliedInDocument.FullName();
		ReportCommand.Presentation = NStr("vi = 'Chiết khấu được áp dụng';
											|ru = 'Примененные скидки';
											|en = 'Applied discounts'; fa = 'تخفیف‌های اعمال‌شده';
											|it = 'Sconti applicati';
											|pl = 'Zastosowane rabaty';
											|tr = 'Uygulanan indirimler'");
		
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,"BusinessOperation",
			Enums.BusinessTransactions.DeliveryForPrincipal, DataCompositionComparisonType.NotEqual);
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndIf