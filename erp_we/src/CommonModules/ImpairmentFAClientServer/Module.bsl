#Region Public

// Managing the visibility of the EGDS.
// 
// Parameters:
//  Form    - ClientApplicationForm
//  Items - String - Comma-separated names of form elements.
Procedure CGUVisibilityManagement(Form, Items) Export
	
	VNAImpairmentIsAvailable = ImpairmentFAServerCall.UseFixedAssetImpairment();
	
	ItemsNames = StrSplit(Items, ",");
	
	For Each Item In ItemsNames Do
		TagName = TrimAll(Item);
		
		If Not IsBlankString(TagName) Then
			Form.Items[TagName].Visible = VNAImpairmentIsAvailable;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

