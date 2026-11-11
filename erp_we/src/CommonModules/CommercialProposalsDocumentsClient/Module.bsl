////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers documents".
// General module.Commercial propositiondocumentclient
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Displays the edit form for the string details of the table part
//
// Parameters:
//  Form                    - ClientApplicationForm - The form in which the props are located.
//  FieldNameComment       - String           - Name of the Bank account that stores the string to be edited.
//  FieldNameIsComment   - String           - Name of the Bank account that stores the indication that the field is filled in.
//  NameOfEditField    - String           - Name of the form element to edit.
//  FieldNameOtherComment - String           - Name of the detail that contains a different comment on the line.
//
Procedure CommentStartChoice(Form, FieldNameComment, FieldNameIsComment, NameOfEditField, FieldNameOtherComment) Export

	CurrentData = Form.Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentData",               CurrentData);
	AdditionalParameters.Insert("AttributeNameComment",     FieldNameComment);
	AdditionalParameters.Insert("PropsNameHasComment", FieldNameIsComment);
	AdditionalParameters.Insert("Form",                       Form);
	AdditionalParameters.Insert("FieldNameOtherComment",    FieldNameOtherComment);

	CallbackDescriptionCompletion = New CallbackDescription("EditCommentCompletion", ThisObject, AdditionalParameters);
	CommonClient.ShowMultilineTextEditingForm(CallbackDescriptionCompletion, Form.Items[NameOfEditField].EditText);

EndProcedure

// Handler for the comment editing completion event
//
// Parameters:
//  EditResult - String    - result of editing the comment.
//  AdditionalParameters - Structure - contains data about the editing context.
//
Procedure EditCommentCompletion(EditResult, AdditionalParameters) Export
	
	If EditResult = Undefined Then
		Return;
	EndIf;
		
	If EditResult <> AdditionalParameters.CurrentData[AdditionalParameters.AttributeNameComment] Then
		
		AdditionalParameters.CurrentData[AdditionalParameters.AttributeNameComment] = EditResult;
		DetectPresenceOfCommentInLine(AdditionalParameters.CurrentData, 
		                                    AdditionalParameters.AttributeNameComment,
		                                    AdditionalParameters.FieldNameOtherComment, 
		                                    AdditionalParameters.PropsNameHasComment);
		
		AdditionalParameters.Form.Modified = True;
		
	EndIf;
	
EndProcedure

// Determines whether a comment is present in a row in the table part.
//
// Parameters:
//  CurrentData               - FormDataCollectionItem - a string that determines whether a comment exists.
//  FieldNameComment          - String           - name of the prop that stores the first comment in the line.
//  FieldNameOtherComment    - String           - name of the item that contains a different comment on the line.
//  PropsNameHasComment - String           - name of the account that stores the indication that the field is filled in.
//
Procedure DetectPresenceOfCommentInLine(CurrentData, FieldNameComment, FieldNameOtherComment, PropsNameHasComment) Export
	
	ThereIsCommentInLine = Not IsBlankString(CurrentData[FieldNameComment])
		Or Not IsBlankString(CurrentData[FieldNameOtherComment]);
	
	CurrentData[PropsNameHasComment] = ThereIsCommentInLine;
	
EndProcedure

// Opens a list of files attached to the object.
//
// Parameters:
//  Form - ClientApplicationForm - the form in which the command is executed
//
Procedure OpenListOfAttachedFiles(Form) Export

	FormObject = Form.Object; // DocumentObject	
	
	FormParameters = New Structure;
	FormParameters.Insert("FileOwner",  FormObject.Ref);
	FormParameters.Insert("ReadOnly", Form.ReadOnly);
	
	FixedSettings = New DataCompositionSettings;
	
	CommonClientServer.SetFilterItem(FixedSettings.Filter,
	            "Ref",
	            Form.AttachmentsWithANonEmptyCID,
	            DataCompositionComparisonType.NotInList);
	
	FormParameters.Insert("FixedSettings", FixedSettings);
	
	OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles", FormParameters);
	
EndProcedure

// Open the Form for selecting images from attached files.
// 
// Parameters:
//  Form - ClientApplicationForm - The Form of the object in which the Command is executed
//  FormParameters - See NewOptionsForOpeningImageSelectionForm
//  CompletionNotification - CallbackDescription, Undefined - description of the End notification
//  OpeningMode - FormWindowOpeningMode, Undefined - Owner window opening mode
Procedure OpenFormForSelectingImagesFromAttachedFiles(
		Form, FormParameters, CompletionNotification = Undefined, OpeningMode = Undefined) Export
	
	FormName  = "CommonForm.SelectingImagesFromAttachedFiles";
	
	If Not ValueIsFilled(OpeningMode) Then
		OpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	OpenForm(FormName, FormParameters, Form, , , , CompletionNotification, OpeningMode);
	
EndProcedure

// New options for opening the image selection Form.
// 
// Parameters:
//  AddressOfImageTable - String - The address of the temporary storage with a table of selected images
// 	FormIdentifier - UUID - Id of the Owner's Form
//  SelectedFile - DefinedType.ImageAttachmentsVendorRFQ, Undefined - Previously selected 
//  	image file. If the file is missing, it is undefined.
// 
// Returns:
//  Structure:
//  * AddressOfImageTable - String - The address of the temporary storage with a table of selected images
// 	* IdOfOwnerSForm - UUID - Id of the Owner's Form
//  * SelectedFile - DefinedType.ImageAttachmentsVendorRFQ, Undefined  - Previously selected
// 		image file. If the file is missing, it is undefined.
Function NewOptionsForOpeningImageSelectionForm(
		AddressOfImageTable, FormIdentifier, SelectedFile = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfImageTable", AddressOfImageTable);
	FormParameters.Insert("IdOfOwnerSForm", FormIdentifier);
	FormParameters.Insert("SelectedFile", SelectedFile);
	
	Return FormParameters;
	
EndFunction

// Configures the display of Form elements of the Image Management group and the filling in of the text image property
// 
// Parameters:
//  Form - ClientApplicationForm - The Form whose elements and their values need to be configured
Procedure CustomizeFormSImagePanel(Form) Export
	
	If Form.FormName <> "Document.RequestForQuotationFromClient.Form.DocumentForm"
		And Form.FormName <> "DataProcessor.RequestsForQuotation.Form.RequestCard" Then
		Return;
	EndIf;

	Form.ImageText = "";
	
	If Not Form.PanelIsDisplayed Then
		Return;
	EndIf;
	
	If Form.NumberOfImagesOfCurrentRow > 1 Then
		
		Form.ImageText = 
			StrTemplate("%1/%2", Form.IndexOfCurrentRowImage + 1, Form.NumberOfImagesOfCurrentRow);

		PreviousImageElement = Form.Items.Find("PreviousImage");
		PreviousImageElement.Enabled = Form.IndexOfCurrentRowImage > 0;

		ElementIsFollowingImage = Form.Items.Find("FollowingImage");
		ElementIsFollowingImage.Enabled = 
			Form.IndexOfCurrentRowImage + 1 < Form.NumberOfImagesOfCurrentRow;
			
	EndIf;
	
	ChangeVisibility = Form.NumberOfImagesOfCurrentRow < 2 And Form.NumberOfImagesOfPreviousRow > 1
		Or Form.NumberOfImagesOfCurrentRow > 1 And Form.NumberOfImagesOfPreviousRow < 2;

	If ChangeVisibility Then
								
		CommonClientServer.SetFormItemProperty(
			Form.Items, "ImageManagementGroup", "Visible", Form.NumberOfImagesOfCurrentRow > 1);
							
	EndIf;	

	Form.NumberOfImagesOfPreviousRow = Form.NumberOfImagesOfCurrentRow;								
	
EndProcedure

Function EventNameNewCCPPDocumentRecorded() Export
	Return "NewDocumentOfCCPPIsRecorded";	
EndFunction

Function EventNameRecordNewCCPPDocument() Export
	Return "RecordNewCCPPDocument";
EndFunction

#Region ListSelections


// Invoked when you select the current date or the date of the event.
// Changes the value of the current date or event date, depending on the selected value.
//
// Parameters:
//	ValueSelected - String - the selected selection value.
//	StandardProcessing - Boolean - flag for standard event processing.
//	Form - ClientApplicationForm - form of list of documents.
//	List - DynamicList - list of documents.
//	NameOfPropsRelevance - String - name of the relevant selection line item.
//	PropsNameEventDate - String - name of the details of the date on which the document will be expired.
//	FormItemName - String - name of the form element containing the selection by relevance.
//
Procedure WhenSelectingRelevanceSelection(ValueSelected, StandardProcessing, Form, List, NameOfPropsRelevance, PropsNameEventDate, FormItemName) Export
	
	If ValueSelected = "ExpiresOnDate" Then
		
		StandardProcessing = False;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("List", List);
		AdditionalParameters.Insert("NameOfPropsRelevance", NameOfPropsRelevance);
		AdditionalParameters.Insert("PropsNameEventDate",  PropsNameEventDate);
		AdditionalParameters.Insert("FormItemName",         FormItemName);
		
		OnCloseNotifyDescription = New CallbackDescription("WhenSelectingRelevanceSelectionCompletion", ThisObject, AdditionalParameters);
		
		StandardProcessing = True;
		CommercialProposalsDocumentsClientOverridable.ShowDateSelection(Form.EventDate, OnCloseNotifyDescription, StandardProcessing);
		
		If StandardProcessing Then
			ShowInputDate(OnCloseNotifyDescription, Form.EventDate, NStr("vi = 'Hãy chọn ngày';
																		|ru = 'Выберите дату';
																		|en = 'Select date'; fa = 'انتخاب تاریخ';
																		|it = 'Selezionate una data';
																		|pl = 'Wybierz datę';
																		|tr = 'Tarih seçin'"), DateFractions.Date);
		EndIf;
		
		Return;
		
	Else
		
		EventDate = Date(1,1,1);
		
	EndIf;
	
EndProcedure

// Completion procedure for pre-selection of Actuality().
// Sets the selection by date of relevance in the list form. Changes the value of the up-to-date date 
// depending on the up-to-date string.
//
// Parameters:
//	DateOfSelection - Date - the date value entered by the user as a result of the dialog.
//	AdditionalParameters - Structure - advanced setting.
//
Procedure WhenSelectingRelevanceSelectionCompletion(DateOfSelection, AdditionalParameters) Export
	
	Form = AdditionalParameters.Form;
	FormItem = Form.Items[AdditionalParameters.FormItemName];
	ChoiceList = FormItem.ChoiceList;
	
	If ValueIsFilled(DateOfSelection) Then
		
		Form[AdditionalParameters.PropsNameEventDate] = DateOfSelection;

		ListItem = ChoiceList.FindByValue("ExpiresOnDateSelected");
		SelectionPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hết hạn vào ngày %1';
																								|ru = 'Истекает на дату %1';
																								|en = 'Expires on %1'; fa = 'Expires on %1';
																								|it = 'Scade il %1';
																								|pl = 'Dobiega końca w dniu %1';
																								|tr = 'Son kullanma tarihi %1'"), Format(DateOfSelection, "DLF=D"));
		If ListItem <> Undefined Then
			ListItem.Presentation = SelectionPresentation;
		Else
			ChoiceList.Add("ExpiresOnDateSelected", SelectionPresentation);
		EndIf;
		Form[AdditionalParameters.NameOfPropsRelevance] = "ExpiresOnDateSelected";
		
	Else
		
		CommercialProposalsDocumentsClientServer.DeleteSelectedDateFromList(ChoiceList);
		
	EndIf;
	
	CommercialProposalsDocumentsClientServer.WhenChangingRelevanceSelection(
		AdditionalParameters.List,
		Form[AdditionalParameters.NameOfPropsRelevance], 
		Form[AdditionalParameters.PropsNameEventDate], 
		CommonClient.SessionDate(),
		ChoiceList);
	
	Form.RefreshDataRepresentation();
	
EndProcedure

#EndRegion

#EndRegion
