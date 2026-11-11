////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Input of lease settlement balances".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure OnExecuteCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure


#EndRegion