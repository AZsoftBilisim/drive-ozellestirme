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
Function AddCommandMovementTMTSVOperation(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ListOfInventoryInOperation) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.ListOfInventoryInOperation.FullName();
		ReportCommand.Presentation = NStr("vi = 'Biến động vật tư đang sử dụng';
											|ru = 'Движение ТМЦ в эксплуатации';
											|en = 'Movement of inventory in operation'; fa = 'Movement of inventory in operation';
											|it = 'Movimento beni materiali in lavorazione';
											|pl = 'Przepływy zapasów w eksploatacji';
											|tr = 'Kullanılan stok hareketleri'");
		
		
		ReportCommand.Importance = "Ordinary";
		ReportCommand.MultipleChoice = False;
		
		ReportCommand.AdditionalParameters.Insert("CommandName", "MovementOfTMTSVOperation");
		
		ReportCommand.VariantKey = "ByProductContext";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf