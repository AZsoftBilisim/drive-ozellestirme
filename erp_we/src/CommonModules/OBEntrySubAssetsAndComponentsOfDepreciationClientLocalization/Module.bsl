////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Entering balances of non-current assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Parameters:
// 	Item - FormField - 
// 	Form - ClientApplicationForm - 
Procedure FormForEditingOS_LineWhenChangingProps(Item, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	
	
	TMCommonUseClient.ContinueChangingProps(
		Form, 
		Item.Name, 
		ServerCallRequired_,
		AdditionalParameters);
	
EndProcedure

// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure FormFixedAssets_WhenExecutingCommand(Command, Form) Export

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
