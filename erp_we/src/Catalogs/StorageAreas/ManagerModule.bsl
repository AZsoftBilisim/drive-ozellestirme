#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export

	Result = New Array;
	
	Result.Add("Owner");
 	Result.Add("Premise");

	Return Result;

EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
// Returns:
//	Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Owner");
	NotAttributesToEdit.Add("Premise");
	
	Return NotAttributesToEdit;
	
EndFunction

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
		
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

#EndRegion

#Region FormCommandsEventHandlers

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#EndRegion

#Region Private

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

