////////////////////////////////////////////////////////////////////////////////
// Procedures used to localize the document "Changing the parameters of the IA".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

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

#EndRegion