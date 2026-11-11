////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Disposal of leased assets (off-balance sheet accounting)".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

#Region DocumentForm

Procedure AfterWrite(Form, WriteParameters) Export
	
	
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


#EndRegion

#EndRegion
