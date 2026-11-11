////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Sale of services and other assets".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region DocumentForm

// The procedure is called back when changing the form details.
// 
// Parameters:
//	TagName - String - Name of the form element
//	Form - ClientApplicationForm - the form of the document
//	AdditionalParameters - Structure - additional processing parameters
//
Procedure OnChangeAttribute(TagName, Form, AdditionalParameters = Undefined) Export

	ServerCallRequired_ = False;
	ContinueChangingProps = True;
	Items = Form.Items;
	
	
	If ContinueChangingProps Then
		
		TMCommonUseClient.ContinueChangingProps(
			Form, 
			TagName, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

// Handler procedure when executing a form command.
// 
// Parameters:
//	Command - FormCommand - form commands
//	Form - ClientApplicationForm - Form
// 
Procedure OnExecuteCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	Items = Form.Items;
	ContinueCommandExecution = True;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

// This procedure adds to the list of document types that can be used as a basis for entering a document.
// Parameters:
//	Form - ClientApplicationForm - the form of the document
//	TypesList - ValueList - list of document types
//
Procedure AddToListOfBaseTypes(Form, TypesList) Export

	
EndProcedure
 
#EndRegion

#EndRegion

