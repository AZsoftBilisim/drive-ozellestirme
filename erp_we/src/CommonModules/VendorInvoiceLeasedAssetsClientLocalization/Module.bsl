////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Purchase of leased operating systems".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region DocumentForm

// 
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
