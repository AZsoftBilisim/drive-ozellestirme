#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public


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

#Region Private

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	TeamDescriptions = New Structure;


	SortingList = New ValueList;
	For Each Itm In TeamDescriptions Do
		SortingList.Add(Itm.Key, Itm.Value.Presentation);
	EndDo;
	SortingList.SortByPresentation();

	For Each AleOfList In SortingList Do
		CommandDetails = TeamDescriptions[AleOfList.Value];
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = AleOfList.Value;
		PrintCommand.Presentation = CommandDetails.Presentation;
		PrintCommand.Handler = CommandDetails.Handler;
	
	EndDo;
	
EndProcedure


#EndRegion

#EndRegion

#EndIf