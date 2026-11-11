////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the directory "Objects of operation".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Parameters:
// 	TagName - String - 
// 	Form - ClientApplicationForm -
//  AdditionalParameters - Structure - 
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

Procedure StartSelectingProps(Form, Item, ChoiceData, StandardProcessing) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure NotificationProcessing(Form, EventName, Parameter, Source) Export

	
	Return; // WE have an empty handler.
	
EndProcedure

Procedure OnExecuteCommand(Command, Form) Export

	
	Return; // WE have an empty handler.
	
EndProcedure
 
#EndRegion

