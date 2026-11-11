////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Acceptance of the OS".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region DocumentForm

// 
// Parameters:
// 	Item - FormField - 
// 	Form - ClientApplicationForm - 
Procedure OnChangeAttribute(Item, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueChangingProps = True;
	
	
	NonCurrentAssetsClientLocalization.WhenChangingDetailsOfAcceptanceForAccountingFA(
		Item, Form, AdditionalParameters, ServerCallRequired_);
	
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

Function RequiresServerCallToConfigureFormElements(Object, StructureOfChangedProps) Export

	
	Return False;

EndFunction

Procedure URLProcessing(Form, FormattedStringURL, StandardProcessing) Export
	
	
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
