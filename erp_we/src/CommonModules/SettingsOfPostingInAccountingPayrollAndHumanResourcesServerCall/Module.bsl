
#Region Internal   

// Returns parameters for displaying reflection settings in HR accounting.
//
// Returns:
//   Structure - display parameters for setting the reflection in accounting:
//    *FilterDate - Date - date of selection for setting up reflection in accounting.
//    *Organization - CatalogRef.Companies - The company to set up the reflection in accounting.
//    *Department - CatalogRef.BusinessStructure - the division for setting up the reflection in accounting.
//    *Employee - CatalogRef.EmployeesHR - employee to set up the reflection in accounting.
//    *Document - Undefined - a document for setting up reflection in accounting.
//    *SelectionLevel - String - Selection Level
//
Function GetDisplayParameters() Export


	Return SettingsOfPostingInAccountingPayrollAndHumanResourcesServer.DisplayParameters(); 
	
EndFunction

#EndRegion
