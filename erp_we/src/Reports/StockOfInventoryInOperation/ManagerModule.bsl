#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   
// Returns:
//   ValueTableRow - new report command.
Function AddCommandLeftoversFromOperation(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.StockOfInventoryInOperation) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.StockOfInventoryInOperation.FullName();
		ReportCommand.Presentation = NStr("vi = 'Số dư vật tư đang sử dụng';
											|ru = 'Остатки ТМЦ в эксплуатации';
											|en = 'Balance of inventory in operation'; fa = 'مانده موجودی در بهره‌برداری';
											|it = 'Saldi beni materiali in lavorazione';
											|pl = 'Stan zapasów w eksploatacji';
											|tr = 'Kullanımdaki stok bakiyesi'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "StockOfInventoryInOperation");
		
		ReportCommand.VariantKey = "ByProductContext";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf