#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	CommandsSources = New Structure;
	CommandsSources.Insert("PackageReturnsDocumentsCommandBar", "Document.ReturnOfGoodsToVendor.Form.ListForm");
	
	For Each SourceOfCommands In CommandsSources Do
		SourcePrintCommands = PrintManagement.FormPrintCommands(SourceOfCommands.Value);
		SourcePrintCommands.FillValues(SourceOfCommands.Key, "PlacingLocation");
		CommonClientServer.SupplementTable(SourcePrintCommands, PrintCommands);
	EndDo;

EndProcedure

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndIf
