////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "OS Unification".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region DocumentForm

// Handler for the "when Changing" event.
// 
// Parameters:
// 	Item - FormField - form element.
// 	Form - ClientApplicationForm - shape.
Procedure OnChangeAttribute(Item, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueChangingProps = True;
	
	NonCurrentAssetsClientLocalization.WhenYouChangeDetailsOfFAUnion(
		Item, Form, AdditionalParameters, ServerCallRequired_);
	
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

// Handler for the "initial Selection" event for the form field.
// 
// Parameters:
//  Item - FormField - form element.
//  ChoiceData - ValueList - 
//  StandardProcessing - Boolean - 
//  Form - ClientApplicationForm - shape.
Procedure StartChoice(Item, ChoiceData, StandardProcessing, Form) Export

	
EndProcedure

// Handler for the "auto-selection" event for the form field.
// 
// Parameters:
//  Item - FormField - form element.
//  Text - String -
//  ChoiceData - ValueList -
//  DataGetParameters - Structure -
//  Waiting - Number -
//  StandardProcessing - Boolean -
//  Form - ClientApplicationForm - shape.
Procedure AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, Form) Export

	
EndProcedure

// Handler for the "end of Leadtext" event.
// 
// Parameters:
//  Item - FormField - form element.
//  Text - String - 
//  ChoiceData - ValueList -
//  DataGetParameters - Structure -
//  StandardProcessing - Boolean - 
//  Form - ClientApplicationForm -
Procedure TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, Form) Export

	
EndProcedure

#EndRegion

#EndRegion
