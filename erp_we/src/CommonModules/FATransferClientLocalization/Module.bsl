////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Moving OS".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region DocumentForm

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

Procedure StartChoice(Item, ChoiceData, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure AfterWritingInForm(Form, Object) Export

	
	Return; // WE have an empty handler.
	
EndProcedure
 
#EndRegion

#EndRegion

