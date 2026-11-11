////////////////////////////////////////////////////////////////////////////////
// Contains the procedures of the Internal Use document intended for localization.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region DocumentForm

// Called when the business Operation details in the document are changed
//
Procedure BusinessOperationOnChange(Form) Export

	
	TMCommonUseClient.ContinueChangingProps(
		Form, 
		"BusinessOperation", 
		True, 
		New Structure("ClearGoods", False));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private


#EndRegion
