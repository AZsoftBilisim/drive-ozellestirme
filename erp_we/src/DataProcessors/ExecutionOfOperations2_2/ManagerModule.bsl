#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	Return;
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Return;
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	Return;
EndProcedure

// Returns the structure of parameters set in the form opening settings.
//
// Returns:
//  Structure
//
Function GetUserSettings() Export
	
	Query = New Query(
		"SELECT
		|	ConfigureFormOpeningOnStartingApplication.Parameters AS Parameters
		|FROM
		|	InformationRegister.ConfigureFormOpeningOnStartingApplication AS ConfigureFormOpeningOnStartingApplication
		|WHERE
		|	ConfigureFormOpeningOnStartingApplication.User = &User
		|	AND ConfigureFormOpeningOnStartingApplication.OpenedForm = &OpenedForm");
	
	Query.SetParameter("OpenedForm",
		Enums.FormsOpenedOnApplicationStart.MobileWorkplaceExecutionOfOperations);
	
	Query.SetParameter("User", Users.CurrentUser());
	
	Result = Query.Execute().Select();
	
	If Result.Next() Then
		StorageParametersSet = Result.Parameters;// ValueStorage
		Return StorageParametersSet.Get();
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Other


#EndRegion

#Region InterfaceImplementation

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

#EndIf
