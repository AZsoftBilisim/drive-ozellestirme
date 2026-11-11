
#Region Public

#Region QualityCertificates

// Handler for the event for changing the Attributes of the item certificate list form.
//
// Parameters:
//	Item - FormField - the Form element that initiated the event.
//	Form - ClientApplicationForm - The Form of the list of certificates of the item in which the event was triggered.
//
Procedure WhenChangingDetails_CertificatesOfItem_FormOfList(Item, Form) Export
	
	
EndProcedure

// Handler of the Item certificate list Command form.
//
// Parameters:
//	Command - FormCommand - The Form Command that initiated the event.
//	Form - ClientApplicationForm - The Form of the list of certificates of the item in which the event was triggered.
//
Procedure ExecuteCommand_NomenclatureCertificates_ListForm(Command, Form) Export
	
	
EndProcedure

// Returns the result of checking the field selected by the user in the list of the Catalog of certificates of the item.
//
// Parameters:
//	Field - FormField - the selected form field.
//	Items -FormAllItems - form element.
//
// Returns:
//	Boolean - the result of checking the field selected by the user in the list of the item certificate Catalog.
//				TRUE - if the field of the column 'Status of Accreditation' is selected.
//
Function ChoosingStatusOfRosaccreditation(Field, Items) Export
	
	Result = False;
	
	
	Return Result;
	
EndFunction

// Performs processing of the selection of the 'Accreditation Status' field in the list table of the Catalog of certificates of the nomenclature.
//
// Parameters:
//	FormTable - FormTable - list table of the item certificate Catalog.
//	StandardProcessing - Boolean - indicates that the standard processing of the event handler being called has been performed.
//	ChangeElement - Boolean - indicates whether the selected item in the item certificate Catalog list needs to be changed.
//
Procedure WhenChoosingStatusOfRosaccreditation(FormTable, StandardProcessing, ChangeElement = True) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CheckFieldsBeforeSpecifyingSeries(EverythingIsFilled, Form, SeriesSpecificationParameters, CurrentData, IssueMessages) Export
	
	
	Return;
	
EndProcedure

Procedure GoHyperlink(Form, HyperlinkClickParameters, StandardProcessing) Export
	
	Return;
	
EndProcedure

Procedure HyperlinkClickParameters(Form, HyperlinkClickParameters, TagName, Hyperlink) Export
	
	Return;
	
EndProcedure

Procedure AllowObjectAttributeEditCompletion(Form, Result, AdditionalParameters) Export
	
	Return;
	
EndProcedure

#Region QualityCertificates


#EndRegion

#EndRegion