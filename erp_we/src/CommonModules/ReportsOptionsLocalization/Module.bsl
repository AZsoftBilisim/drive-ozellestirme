#Region Public

////////////////////////////////////////////////////////////////////////////////
// Report Placement Settings
// See ReportsOptionsOverridable.DefineSectionsWithReportOptions
//
Procedure DefineSectionsWithReportOptions(Sections) Export
	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Report Command Settings
// See ReportsOptionsOverridable.DefineObjectsWithReportCommands
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	

EndProcedure

// Sets the settings that are used as standard for subsystem objects.
// See ReportsOptionsOverridable.OnDefineSettings
// 
Procedure OnDefineSettings(Settings) Export
	
	
EndProcedure

// Sets the settings for placing report options in the report panel.
// See ReportsOptionsOverridable.CustomizeReportsOptions
// 
Procedure CustomizeReportsOptions(Settings) Export
	
		
EndProcedure

// Contains descriptions of changes to the names of report variants. It is used
// when updating the information base, in order to control the referential integrity
// and to save the option settings made by the administrator.
// See ReportsOptionsOverridable.RegisterChangesOfReportOptionsKeys
// 
Procedure RegisterChangesOfReportOptionsKeys(Changes) Export
	
	
EndProcedure

// Returns the name and parameters of the form with information about the mobile application to display in reports
//
// Returns:
// 	Structure - Keys:
// 		* FormName - String - Name of the general form
// 		* FormParameters - Structure - contains fields:
// 			** DescriptionLayoutName - String - Name of the general layout with information about the mobile application
// 			** ApplicationName_2 - String - Application Name
Function InformationAboutMobileApp() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("FormName", "");
	
	FormParameters = New Structure;
	FormParameters.Insert("DescriptionLayoutName", "");
	FormParameters.Insert("ApplicationName_2", "");
	LongDesc.Insert("FormParameters", FormParameters);
	
	
	Return LongDesc;
	
EndFunction

#Region CheckingAndSearchingForCounterparty

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   VisibilityInForms - String - a comma-separated list of forms to display the command.
Procedure AddCounterpartyVerificationCommand(ReportsCommands, VisibilityInForms = Undefined) Export
	
	
EndProcedure

// Adds the Search for Contractors command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   VisibilityInForms - String - a comma-separated list of forms to display the command.
Procedure AddCommandSearchForCounterparties(ReportsCommands, VisibilityInForms = Undefined) Export
	
	
EndProcedure

#EndRegion

#EndRegion
