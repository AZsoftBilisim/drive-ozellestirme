////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Cost adjustment and depreciation of the OS".
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

// 
// Parameters:
// 	Command - FormCommand - 
// 	Form - ClientApplicationForm - 
Procedure OnExecuteCommand(Command, Form) Export

	AdditionalParameters = Undefined;
	ServerCallRequired_ = False;
	ContinueCommandExecution = True;
	Object = Form.Object;
	
	
	If ContinueCommandExecution Then
		
		TMCommonUseClient.ContinueCommandExecution(
			Form, 
			Command.Name, 
			ServerCallRequired_,
			AdditionalParameters);
			
	EndIf; 
	
EndProcedure

Procedure TableFieldSelection(Item, RowSelected, Field, StandardProcessing, Form) Export

	
EndProcedure


#EndRegion

#EndRegion