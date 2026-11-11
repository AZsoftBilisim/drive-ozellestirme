
#Region Private

// Sets the current page of the form element groupobjectsuse Pages
// 
// Parameters:
// 	Form - ClientApplicationForm - The form where you want to change the elements.
// 	ThereAreRefs - Boolean - True if there are references to the object.
// 	
Procedure GetVerificationResult(Form, ThereAreRefs = Undefined) Export
	
	If ThereAreRefs = Undefined Then
		ThereAreRefs = GetFromTempStorage(Form.StorageAddress);
	EndIf;
	
	If ThereAreRefs Then
		CurrentPage = Form.Items.ObjectIsUsedObjectIsUsedGroup;
	Else
		CurrentPage = Form.Items.ObjectIsUsedObjectIsNotUsedGroup;
	EndIf;
	
	Form.Items.ObjectIsUsedPagesGroup.CurrentPage = CurrentPage;
	
EndProcedure

#EndRegion
