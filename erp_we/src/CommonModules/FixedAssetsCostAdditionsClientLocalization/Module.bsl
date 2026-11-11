////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "OS Modernization".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

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
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

Function RequiresServerCallToConfigureFormElements(Object, StructureOfChangedProps) Export


	Return False;
	
EndFunction
 
Procedure StartChoice(Item, ChoiceData, StandardProcessing, Form) Export

	
EndProcedure

Procedure AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export

	
EndProcedure

Procedure TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, Form) Export

	
EndProcedure
 
#EndRegion

#Region Private


#EndRegion
