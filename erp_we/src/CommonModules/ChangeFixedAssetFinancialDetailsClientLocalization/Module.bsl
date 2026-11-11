
#Region Internal

// 
// Parameters:
// 	TagName - String - 
// 	Form - ClientApplicationForm -  
// 	AdditionalParameters - Undefined - 
Procedure OnChangeAttribute(TagName, Form, AdditionalParameters = Undefined) Export

	ServerCallRequired_ = False;
	ContinueChangingProps = True;
	
	
	If ContinueChangingProps Then
		
		TMCommonUseClient.ContinueChangingProps(
			Form, 
			TagName, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

// 
// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure OnExecuteCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	Object = Form.Object;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

#EndRegion
