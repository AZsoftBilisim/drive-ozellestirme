#Region Public

Procedure OnChangeAttribute(TagName, Form) Export
	
	TMCommonUseClient.ContinueChangingProps(Form, TagName, True);
	
EndProcedure

Procedure ExecuteCommand(CommandName, Form) Export
	
	TMCommonUseClient.ContinueChangingProps(Form, CommandName, False);
	
EndProcedure

#EndRegion