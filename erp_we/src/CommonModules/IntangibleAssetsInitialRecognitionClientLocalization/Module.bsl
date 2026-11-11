////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Acceptance for accounting of IA".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region DocumentForm

Procedure AfterWrite(Object) Export

	
EndProcedure

// Parameters:
// 	Item - FormField - 
// 	Form - ClientApplicationForm -
Procedure OnChangeAttribute(Item, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueChangingProps = True;
	
	
	If ContinueChangingProps Then
		
		TMCommonUseClient.ContinueChangingProps(
			Form, 
			Item.Name, 
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
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

Procedure StartChoice(Item, ChoiceData, StandardProcessing, Form) Export

	
EndProcedure

Procedure AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export

	
EndProcedure

Procedure TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, Form) Export

	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region DocumentForm


#EndRegion

#EndRegion
