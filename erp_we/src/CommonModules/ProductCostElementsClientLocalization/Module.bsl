#Region Public

// On changing the Attributes of the reference list of Articulation articles.
// 
// Parameters:
//  TagName - String - Command name
//  Form - ClientApplicationForm - Form of the calculation article
Procedure OnChangeAttribute(TagName, Form) Export
	
	TMCommonUseClient.ContinueChangingProps(Form, TagName, True);
	
EndProcedure

// Execute the command of the Statikalculation directory.
// 
// Parameters:
//  CommandName - String - Command name
//  Form - ClientApplicationForm - Form of the calculation article
Procedure ExecuteCommand(CommandName, Form) Export
	
	TMCommonUseClient.ContinueCommandExecution(Form, CommandName, False);
	
EndProcedure

#EndRegion