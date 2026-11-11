
#Region Public

// Handles the search and replace event in the Forms of demo scripts
//
// Parameters:
//  EventParameters  - See NewAlertSettingsSearchAndReplaceChanges
//  Form             - ClientApplicationForm - The Form in which the event occurs
//
Procedure HandleSearchAndReplaceEvent(EventParameters, Form) Export
	
	DemoScenario = Form.Object.Ref;
	
	If EventParameters.DemoScenario <> DemoScenario Then
		
		Return;
		
	EndIf;
	
	NotificationParameters = NewAlertSettingsSearchAndReplaceChanges();
	NotificationParameters.DemoScenario = DemoScenario;
	
	If EventParameters.Operation = "FindAllOccurrences" Then
		
		CancelSearchResultsIfNecessary(Form);
		
		OperationResult = SearchResultForAllOccurrences(Form.ScenarioText, EventParameters);
		
		If OperationResult.ThereAreSearchResults Then
			
			Form.SearchIsCompleted = True;
			Form.SearchString  = EventParameters.WhatWeAreChanging;
			Form.LastDirectionOfSearch  = "GoForward";
			
			NotificationParameters.ThereAreSearchResults       = True;
			NotificationParameters.ThereIsFollowingResult     = OperationResult.PositionsFound.Count() > 1;
			NotificationParameters.ThereIsCurCurrentSearchResult = True;
			
		EndIf;
		
		Notify("DemoScenarios_ChangingParametersOfSearchAndReplaceForm", NotificationParameters, Form);
		
	ElsIf EventParameters.Operation = "ReplaceAllOccurrences" Then 
		
		OperationResult = ResultOfReplacingAllOccurrences(Form.ScenarioText, EventParameters);
		
		If OperationResult.ReplacementWasPerformed Then
			
			Form.SearchIsCompleted               = True;
			Form.SearchString                = "";
			Form.LastDirectionOfSearch  = "";
			Form.ThereAreEditingChanges = True; 
			Form.Modified          = True;
			
		EndIf;
			
		Notify("DemoScenarios_ChangingParametersOfSearchAndReplaceForm", NotificationParameters, Form); 
		
	ElsIf EventParameters.Operation = "ReplaceCur" Then 
		
		OperationResult = ResultOfReplacingCurCurrentOccurrence(Form.ScenarioText, EventParameters, Form.LastDirectionOfSearch);
		
		If OperationResult.ReplacementWasPerformed Then
			Form.ThereAreEditingChanges = True;
			Form.Modified          = True;
		EndIf;
		
		If Not OperationResult.ThereIsFollowingFound 
			And Not OperationResult.ThereIsPreviousFound Then
			
			NotificationParameters.ThereAreSearchResults = False;
			Form.SearchIsCompleted                      = True;
			Form.SearchString                       = "";
			Form.LastDirectionOfSearch         = "";
			
		EndIf;
		
		If OperationResult.ThereIsFollowingFound
			Or OperationResult.ThereIsPreviousFound 
			Or OperationResult.ThereIsCurCurrentSearchResult Then
			
			NotificationParameters.ThereAreSearchResults = True;
			
		EndIf;
		
		NotificationParameters.ThereIsFollowingResult     = OperationResult.ThereIsFollowingFound;
		NotificationParameters.ThereIsPreviousResult    = OperationResult.ThereIsPreviousFound;
		NotificationParameters.ThereIsCurCurrentSearchResult = OperationResult.ThereIsCurCurrentSearchResult;
		
		Notify("DemoScenarios_ChangingParametersOfSearchAndReplaceForm", NotificationParameters, Form);

		
	ElsIf EventParameters.Operation = "FindNext" Then 
		
		OperationResult = SearchResultForFollowing(Form.ScenarioText, EventParameters);
		
		NotificationParameters.ThereAreSearchResults       = True;
		NotificationParameters.ThereIsFollowingResult     = OperationResult.ThereIsFollowingFound;
		NotificationParameters.ThereIsPreviousResult    = OperationResult.ThereIsPreviousFound;
		NotificationParameters.ThereIsCurCurrentSearchResult = True;
		
		Form.LastDirectionOfSearch             = "GoForward";
		
		Notify("DemoScenarios_ChangingParametersOfSearchAndReplaceForm", NotificationParameters, Form);
		
	ElsIf EventParameters.Operation = "FindPrevious" Then 
		
		OperationResult = PreviousSearchResult(Form.ScenarioText, EventParameters);
		
		NotificationParameters.ThereAreSearchResults       = True;
		NotificationParameters.ThereIsFollowingResult     = OperationResult.ThereIsFollowingFound;
		NotificationParameters.ThereIsPreviousResult    = OperationResult.ThereIsPreviousFound;
		NotificationParameters.ThereIsCurCurrentSearchResult = True;
		
		Form.LastDirectionOfSearch             = "Back";
		
		Notify("DemoScenarios_ChangingParametersOfSearchAndReplaceForm", NotificationParameters, Form);
		
	EndIf;
	
EndProcedure

// Handles the Form closing and replacement event
//
// Parameters:
//  Form  - ClientApplicationForm - The Form in which the event is processed
//
Procedure AfterClosingSearchAndReplaceForm(Form) Export
	
	CancelSearchResultsIfNecessary(Form);
	TransferResultsOfChangesIfNecessary(Form);
	
EndProcedure

// Handles the event for accepting translation results
//
// Parameters:
//  Form                   - ClientApplicationForm - The Form in which the event is processed
//  Result               - DialogReturnCode - the user's response to the question about accepting translation results
//  AdditionalParameters  - Structure - additional event data
//
Procedure AfterAcceptingTranslationResults(Form, Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		
		Return;
		
	EndIf;
	
	Form.ScenarioText               = AdditionalParameters.TextIsTranslated;
	Form.ThereAreEditingChanges = True;
	Form.Modified          = True;
	
	TransferResultsOfChangesIfNecessary(Form);
	
EndProcedure

// Handles a click event in an HTML document field
//
// Parameters:
//  Form                 - ClientApplicationForm - The Form in which the event occurs
//  Item               - FormField - field of the Form where the event occurs
//  EventData         - Structure - Event data
//  StandardProcessing  - Boolean - a sign of the standard event processing
//
Procedure WhenYouClickInHTMLDocumentField(Form, Item, EventData, StandardProcessing) Export
	
	If EventData <> Undefined
		And Not IsBlankString(EventData.Href) > 0 Then
		
		StandardProcessing             = False;
		PrefixInternalDatabaseRef      = "/e1cib";
		PrefixInternalLinkOfDocument = "e1c:";
		
		If StrFind(EventData.Href, DemoScenariosClientServer.PrefixOfAttachedFileLink()) Then 
			
			PrefixOfAttachedFileLink = DemoScenariosClientServer.PrefixOfAttachedFileLink();
			PrefixLength                   = StrLen(PrefixOfAttachedFileLink);
		
			PositionOfFound = StrFind(EventData.Href, PrefixOfAttachedFileLink);
		
			If PositionOfFound = 0 Then 
				Return;
			EndIf;
			
			ScreenshotID = Right(EventData.Href, StrLen(EventData.Href) - PositionOfFound - PrefixLength + 1);
			
			SearchParameters = New Structure;
			SearchParameters.Insert("ScreenshotID", ScreenshotID);
			FoundRows = Form.Object.IDsOfScreenshotFiles.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 
				And ValueIsFilled(FoundRows[0].AttachedFile) Then
			
				OpenScreenshotAttachedFile(FoundRows[0].AttachedFile, Form);
				
			EndIf; 
			
		ElsIf StrFind(EventData.Href, PrefixInternalDatabaseRef) Then
			
			PrefixLength     = StrLen(PrefixInternalDatabaseRef);
			PositionOfFound = StrFind(EventData.Href, PrefixInternalDatabaseRef);
			
			If PositionOfFound = 0 Then 
				Return;
			EndIf;
			
			URL = Right(EventData.Href, StrLen(EventData.Href) - PositionOfFound);
			FileSystemClient.OpenURL(URL);
			
		ElsIf StrStartsWith(EventData.Href, PrefixInternalLinkOfDocument) Then
			
			AnchorPosition = StrFind(EventData.Href, "#");
			
			If AnchorPosition > 0 Then
				WarningText = NStr("ru = 'Переход по ссылке внутри документа не поддерживается';
									|vi = 'Following the link inside the document is not supported';
									|en = 'Following the link inside the document is not supported'; fa = 'Following the link inside the document is not supported';
									|it = 'Following the link inside the document is not supported';
									|pl = 'Following the link inside the document is not supported';
									|tr = 'Belge içindeki bağlantıya geçiş desteklenmiyor'");
				ShowMessageBox(, WarningText, 10);
				StandardProcessing = True;
			EndIf;
			
		Else
			
			FileSystemClient.OpenURL(EventData.Href);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Opens the search and replace Form in demo scenarios
//
// Parameters:
//  Form                   - ClientApplicationForm - The Form from which the search Form opens
//
Procedure OpenSearchForm(Form) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("DemoScenario", Form.Object.Ref);
	If Form.SearchParametersWhenOpening <> Undefined Then
		OpeningParameters.Insert("SearchParametersWhenOpening", Form.SearchParametersWhenOpening); 
	EndIf;
	
	FormClosingNotification = New CallbackDescription("AfterClosingSearchAndReplaceForm", Form);
	
	OpenForm("Catalog.DemoScenarios.Form.SearchAndReplace", OpeningParameters, Form,
	             ,,,FormClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Performs translation from the viewing language in the Form of a demo script
//
// Parameters:
//  Form                     - ClientApplicationForm - The Form in which the translation is performed
//  SourceText             - String - Source text
//  TranslationText             - String - The text contained in the Attribute in which the translation will be placed
//  SourceLanguage              - String - the code of the language from which the translation is being made
//  TranslationLanguage              - String - the language to be translated into
//  ErrorMessageElement  - FormField - the field for which the error message will be displayed
//  Attachments                  - Undefined, Structure - HTML document attachments
//
Procedure TranslateFromViewingLanguage(Form, SourceText, TranslationText, SourceLanguage, TranslationLanguage, ErrorMessageElement, Attachments = Undefined) Export
	
	If ValueIsFilled(TranslationLanguage)
		And ValueIsFilled(SourceLanguage) 
		And Not TranslationLanguage = SourceLanguage Then 
		
		TransitionResult = DemoScenariosServerCall.ResultOfTranslationIntoOtherLanguages(SourceText, SourceLanguage, TranslationLanguage);
		If Not TransitionResult.Success Then
			
			CommonClient.MessageToUser(TransitionResult.UserMessage,, ErrorMessageElement);
			
		Else
			
			If TransitionResult.TextIsTranslated <> TranslationText Then
				
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("TextIsTranslated", TransitionResult.TextIsTranslated);
				AdditionalParameters.Insert("Attachments",          Attachments);
				
				NotificationOfQuestionAfterTransfer = New CallbackDescription("AfterAnsweringQuestionAfterTranslation", Form, AdditionalParameters);
				QueryText = StrTemplate(NStr("vi = 'Theo kết quả dịch, sẽ thay đổi nội dung bằng ngôn ngữ ""%1"", tiếp tục?';
											|ru = 'В результате перевода текст на языке ""%1"" будет изменен, продолжить?';
											|en = 'After the translation, the text in the %1 language will be changed. Continue?'; fa = 'After the translation, the text in the %1 language will be changed. Continue?';
											|it = 'В результате перевода текст на языке ""%1"" будет изменен, продолжить?';
											|pl = 'After the translation, the text in the %1 language will be changed. Continue?';
											|tr = 'Çeviri sonucunda ""%1"" dilindeki metin değişecektir, devam edilsin mi?'"), TranslationLanguage);
				ShowQueryBox(NotificationOfQuestionAfterTransfer, QueryText, QuestionDialogMode.YesNo);
				
				
			Else
				
				TexMessages = StrTemplate(NStr("vi = 'Sau khi dịch, không thay đổi nội dung bằng ngôn ngữ ""%1""';
												|ru = 'После перевода текст на языке ""%1"" изменен не был';
												|en = 'After the translation, the text in the %1 language was not changed'; fa = 'After the translation, the text in the %1 language was not changed';
												|it = 'После перевода текст на языке ""%1"" изменен не был';
												|pl = 'After the translation, the text in the %1 language was not changed';
												|tr = 'Çeviriden sonra ""%1"" dilindeki metin değişmedi'"), TranslationLanguage);
				CommonClient.MessageToUser(TexMessages,, ErrorMessageElement);
				
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion 

#Region Internal

#Region FilesOperations

// Handles the beginning of file selection
//
// Parameters:
//  Form                          - ClientApplicationForm - The Form in which the event occurs
//  SelectionDialogMode             - FileDialogMode - what is selected, file or directory
//  AttributeName                   - String - the name of the Form Attribute to which the selected file will be saved
//  AddSlash                   - Boolean - indicates whether to add a slash to the selection result 
//  NotificationAfterProcessingSelection - CallbackDescription - where will the post-processing of the selection take place 
//  DefaultDirectory             - String - the directory where you will be prompted to select a file
//
Procedure ProcessingStartOfFileSelection(Form, SelectionDialogMode, AttributeName, AddSlash, NotificationAfterProcessingSelection, DefaultDirectory = Undefined) Export
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("AttributeName",                   AttributeName);
	NotificationParameters.Insert("AddSlash",                   AddSlash);
	NotificationParameters.Insert("Form",                          Form);
	NotificationParameters.Insert("NotificationAfterProcessingSelection", NotificationAfterProcessingSelection);

	Notification = New CallbackDescription("NotificationAfterFileSelection", ThisObject, NotificationParameters);
	
	OpenFileDialog = New FileDialog(SelectionDialogMode);
	OpenFileDialog.Multiselect = False;
	If DefaultDirectory <> Undefined Then
		OpenFileDialog.Directory = DefaultDirectory;
	EndIf; 
	
	FileSystemClient.ShowSelectionDialog(Notification, OpenFileDialog);
	
EndProcedure

// Notification handler after selecting files
//
// Parameters:
//   SelectedFiles          - Array of String, Undefined -
//   AdditionalParameters - Structure -
//
Procedure NotificationAfterFileSelection(SelectedFiles, AdditionalParameters) Export
	
	If (TypeOf(SelectedFiles) <> Type("Array")) Or (SelectedFiles.Count() = 0) Then
		Return;
	EndIf;
	
	SelectedFile = SelectedFiles[0];
	If AdditionalParameters.AddSlash Then
		SelectedFile = FolderAddSlash(SelectedFile);
	EndIf;
	
	If TypeOf(AdditionalParameters.AttributeName) = Type("Structure") Then
		
		RowData = AdditionalParameters.Form[AdditionalParameters.AttributeName.TabularSectionName].FindByID(AdditionalParameters.AttributeName.String_Id);
		If RowData <> Undefined Then
			
			RowData[AdditionalParameters.AttributeName.AttributeName] = SelectedFile;
			
		EndIf;
		
	Else
		
		AdditionalParameters.Form[AdditionalParameters.AttributeName] = SelectedFile;
	
	EndIf;
	
	If TypeOf(AdditionalParameters.NotificationAfterProcessingSelection) = Type("CallbackDescription") Then
		
		RunCallback(AdditionalParameters.NotificationAfterProcessingSelection, SelectedFile);
		
	EndIf;
	
EndProcedure

// Adds a slash to the folder name
//
// Parameters:
//  Directory  - String - the folder for which processing is required
//
// Returns:
//   String - processed directory name
//
Function FolderAddSlash(Directory) Export
	
	If Not StrEndsWith(Directory, GetPathSeparator()) Then
		Directory = Directory + GetPathSeparator();
	EndIf;
	
	Return Directory;
	
EndFunction

#EndRegion

#EndRegion 

#Region Private

// New search and replace alert options.
// 
// Returns:
//  Structure - Contains:
// * ThereAreSearchResults       - Boolean -
// * ThereIsFollowingResult     - Boolean -
// * ThereIsPreviousResult    - Boolean -
// * ThereIsCurCurrentSearchResult - Boolean -
// * DemoScenario   - CatalogRef.DemoScenarios -
Function NewAlertSettingsSearchAndReplaceChanges()
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("ThereAreSearchResults",       False);
	NotificationParameters.Insert("ThereIsFollowingResult",     False);
	NotificationParameters.Insert("ThereIsPreviousResult",    False);
	NotificationParameters.Insert("ThereIsCurCurrentSearchResult", False);
	NotificationParameters.Insert("DemoScenario",   PredefinedValue("Catalog.DemoScenarios.EmptyRef"));
	
	Return NotificationParameters;

EndFunction

Function SearchResultForAllOccurrences(ScenarioText, EventParameters) 
	
	Result = New Structure;
	Result.Insert("ThereAreSearchResults", False);
	Result.Insert("PositionsFound",    Undefined);
	
	PositionsFoundInText =  DemoScenariosClientServer.PositionsFoundInText(ScenarioText, EventParameters);
	
	If PositionsFoundInText.Count() > 0 Then
		HighlightWhatIsFoundInText(ScenarioText, EventParameters.WhatWeAreChanging, PositionsFoundInText);
		Result.ThereAreSearchResults = True;
		Result.PositionsFound    = PositionsFoundInText;
	EndIf;
	
	Return Result;
	
EndFunction

Function ResultOfReplacingCurCurrentOccurrence(TextToChange, EventParameters, LastDirectionOfSearch)
	
	Result = New Structure;
	Result.Insert("ReplacementWasPerformed",        False);
	Result.Insert("ThereIsPreviousFound",    False);
	Result.Insert("ThereIsFollowingFound",     False);
	Result.Insert("ThereIsCurCurrentSearchResult", False);
	
	WhatIsLengthWeChangeTo = StrLen(EventParameters.WhatAreWeChangingTo);
	
	
#Region ReplacingCur
	
	SelectionParametersForCurCurrentFound = SelectionParametersForCurCurrentTextFound();

	StartPosition   = 1;
	
	HighlightedTextIsCurrentlyFound        = TextWithSelectionTags(SelectionParametersForCurCurrentFound, EventParameters.WhatWeAreChanging);
	LengthOfSelectedTextCurFound = StrLen(HighlightedTextIsCurrentlyFound);
	FoundPosition                       = StrFind(TextToChange, HighlightedTextIsCurrentlyFound, SearchDirection.FromBegin, StartPosition); 
	
	If FoundPosition <> 0 Then
		
		TextToChange = Left(TextToChange, FoundPosition - 1) 
		                    + EventParameters.WhatAreWeChangingTo
		                    + Right(TextToChange, StrLen(TextToChange) - FoundPosition - LengthOfSelectedTextCurFound + 1);
		
		Result.ReplacementWasPerformed = True;
		
	EndIf; 
	
#EndRegion

#Region HighlightingFollowing

	ParametersForHighlightingWhatWasFound  = SelectionParametersForFoundText();
	
	If LastDirectionOfSearch = "Back" Then
		
		StartPosition        = FoundPosition - 1; 
		TextSearchDirection = SearchDirection.FromEnd;
		
	Else
		
		StartPosition        = FoundPosition + WhatIsLengthWeChangeTo;
		TextSearchDirection = SearchDirection.FromBegin;
		
	EndIf;
	
	HighlightedTextFound      = TextWithSelectionTags(ParametersForHighlightingWhatWasFound, EventParameters.WhatWeAreChanging);
	LengthSelectedTextFound = StrLen(HighlightedTextFound);
	FoundPosition              = StrFind(TextToChange, HighlightedTextFound, TextSearchDirection, StartPosition); 
	
	If FoundPosition <> 0 Then
		
		TextToChange = Left(TextToChange, FoundPosition - 1) 
		                    + HighlightedTextIsCurrentlyFound
		                    + Right(TextToChange, StrLen(TextToChange) - FoundPosition - LengthSelectedTextFound + 1);
		
		Result.ThereIsFollowingFound     = StrFind(TextToChange, HighlightedTextFound, SearchDirection.FromBegin, FoundPosition) <> 0;
		Result.ThereIsPreviousFound    = StrFind(TextToChange, HighlightedTextFound, SearchDirection.FromEnd, FoundPosition - 1) <> 0;
		Result.ThereIsCurCurrentSearchResult = True;
		
	Else
		
		Result.ThereIsFollowingFound  = StrFind(TextToChange, HighlightedTextFound, SearchDirection.FromBegin, 1) <> 0;
		
	EndIf;
	
#EndRegion
	
	Return Result;
	
EndFunction

Function ResultOfReplacingAllOccurrences(TextToChange, EventParameters)
	
	Result = New Structure;
	Result.Insert("ReplacementWasPerformed", False);
	Result.Insert("PositionsOfReplaced",  Undefined);
	
	PositionsOfReplaced = New Array;
	ArrayOfTextToReplace = New Array;
	
	ArrayOfTextToReplace.Add(TextWithSelectionTags(SelectionParametersForFoundText(), EventParameters.WhatWeAreChanging));
	ArrayOfTextToReplace.Add(TextWithSelectionTags(SelectionParametersForCurCurrentTextFound(), EventParameters.WhatWeAreChanging));
	
	For Each SelectedText In ArrayOfTextToReplace Do
	
		StartPosition   = 1;
		LengthOfSelectedText = StrLen(SelectedText);
		WhatIsLengthWeChangeTo       = StrLen(EventParameters.WhatAreWeChangingTo);
		FoundPosition       = StrFind(TextToChange, SelectedText, SearchDirection.FromBegin, StartPosition);
		
		While FoundPosition <> 0 Do
			
			TextToChange = Left(TextToChange, FoundPosition - 1) 
			                    + EventParameters.WhatAreWeChangingTo
			                    + Right(TextToChange, StrLen(TextToChange) - FoundPosition - LengthOfSelectedText + 1);
			
			StartPosition = FoundPosition + WhatIsLengthWeChangeTo;
			PositionsOfReplaced.Add(FoundPosition);
			
			FoundPosition = StrFind(TextToChange, SelectedText, SearchDirection.FromBegin, StartPosition);
			
		EndDo; 
	
	EndDo;
	
	If PositionsOfReplaced.Count() > 0 Then
		Result.ThereWasEditChange = True;
		Result.PositionsOfReplaced              = PositionsOfReplaced;
	EndIf;
	
	Return Result;
	
EndFunction

Function PreviousSearchResult(ScenarioText, EventParameters)
	
	Result = New Structure;
	Result.Insert("ThereIsPreviousFound", False);
	Result.Insert("ThereIsFollowingFound",  False);
	
	SelectionParametersForCurCurrentFound = SelectionParametersForCurCurrentTextFound();
	ParametersForHighlightingWhatWasFound         = SelectionParametersForFoundText();
	
	StartPosition       = 1;
	HighlightedTextIsCurrentlyFound        = TextWithSelectionTags(SelectionParametersForCurCurrentFound, EventParameters.WhatWeAreChanging);
	LengthOfSelectedTextCurFound = StrLen(HighlightedTextIsCurrentlyFound); 
	HighlightedTextFound               = TextWithSelectionTags(ParametersForHighlightingWhatWasFound, EventParameters.WhatWeAreChanging); 
	LengthSelectedTextFound          = StrLen(HighlightedTextFound);
	
	FoundPosition = StrFind(ScenarioText, HighlightedTextIsCurrentlyFound, SearchDirection.FromBegin, StartPosition);
	
	If FoundPosition <> 0 Then
		
		ScenarioText = Left(ScenarioText, FoundPosition - 1) 
		                    + HighlightedTextFound
		                    + Right(ScenarioText, StrLen(ScenarioText) - FoundPosition - LengthOfSelectedTextCurFound + 1);
		
		StartPosition = FoundPosition - 1;
		Result.ThereIsFollowingFound = True;
		
	EndIf;
	
	FoundPosition = StrFind(ScenarioText, HighlightedTextFound, SearchDirection.FromEnd, StartPosition );
	
	If FoundPosition <> 0 Then
		
		ScenarioText = Left(ScenarioText, FoundPosition - 1) 
		                + HighlightedTextIsCurrentlyFound
		                + Right(ScenarioText, StrLen(ScenarioText) - FoundPosition - LengthSelectedTextFound + 1);
		
		Result.ThereIsPreviousFound = StrFind(ScenarioText, HighlightedTextFound, SearchDirection.FromEnd, FoundPosition); 
		
	EndIf;
	
	Return Result;
	
EndFunction

Function SearchResultForFollowing(ScenarioText, EventParameters)
	
	Result = New Structure;
	Result.Insert("ThereIsPreviousFound", False);
	Result.Insert("ThereIsFollowingFound",  False);
	
	SelectionParametersForCurCurrentFound = SelectionParametersForCurCurrentTextFound();
	ParametersForHighlightingWhatWasFound         = SelectionParametersForFoundText();
	
	StartPosition       = 1;
	HighlightedTextIsCurrentlyFound        = TextWithSelectionTags(SelectionParametersForCurCurrentFound, EventParameters.WhatWeAreChanging);
	LengthOfSelectedTextCurFound = StrLen(HighlightedTextIsCurrentlyFound); 
	HighlightedTextFound               = TextWithSelectionTags(ParametersForHighlightingWhatWasFound, EventParameters.WhatWeAreChanging); 
	LengthSelectedTextFound          = StrLen(HighlightedTextFound);
	
	FoundPosition = StrFind(ScenarioText, HighlightedTextIsCurrentlyFound, SearchDirection.FromBegin, StartPosition);
	
	If FoundPosition <> 0 Then
		
		ScenarioText = Left(ScenarioText, FoundPosition - 1) 
		                    + HighlightedTextFound
		                    + Right(ScenarioText, StrLen(ScenarioText) - FoundPosition - LengthOfSelectedTextCurFound + 1);
		
		StartPosition = FoundPosition + LengthSelectedTextFound;
		Result.ThereIsPreviousFound = True;
		
	EndIf;
	
	FoundPosition = StrFind(ScenarioText, HighlightedTextFound, SearchDirection.FromBegin, StartPosition);
	
	If FoundPosition <> 0 Then
		
		ScenarioText = Left(ScenarioText, FoundPosition - 1) 
		                + HighlightedTextIsCurrentlyFound
		                + Right(ScenarioText, StrLen(ScenarioText) - FoundPosition - LengthSelectedTextFound + 1); 
		
		Result.ThereIsFollowingFound = StrFind(ScenarioText, HighlightedTextFound, SearchDirection.FromBegin, FoundPosition) <> 0; 
		
	EndIf;
	
	Return Result;
	
EndFunction

Function TextWithSelectionTags(ParametersOfSelection, HighlightedText)
	
	Return ParametersOfSelection.StartTag + HighlightedText + ParametersOfSelection.EndTag1;
	
EndFunction

Procedure HighlightWhatIsFoundInText(TextToChange, HighlightedText, PositionsFoundInText)
	
	Move                  = 0;
	LengthOfHighlightedText = StrLen(HighlightedText);
	LengthOfEntireText       = StrLen(TextToChange);
	NewPositionsFound = New Array;
	
	ThisIsCurCurrentlyFound = True;

	For Each PositionOfWhatWasFoundInText In PositionsFoundInText Do
		
		If ThisIsCurCurrentlyFound Then
			SelectionParametersForFoundText = SelectionParametersForCurCurrentTextFound();
		Else
			SelectionParametersForFoundText = SelectionParametersForFoundText();
		EndIf;
		
		NewPositionsFound.Add(PositionOfWhatWasFoundInText + Move);
		
		TextToChange = Left(TextToChange, PositionOfWhatWasFoundInText + Move -1)
			+ TextWithSelectionTags(SelectionParametersForFoundText, HighlightedText)
			+ Right(TextToChange, LengthOfEntireText - PositionOfWhatWasFoundInText - LengthOfHighlightedText + 1);
			
		Move = Move + SelectionParametersForFoundText.ResultingShift;
		ThisIsCurCurrentlyFound = False;
		
	EndDo;
	
	PositionsFoundInText = NewPositionsFound;
	
EndProcedure

Procedure DeselectSearchResults(TextToChange, SearchString)
	
	CancelSelectionInText(TextToChange, SelectionParametersForFoundText(), SearchString);
	CancelSelectionInText(TextToChange, SelectionParametersForCurCurrentTextFound(), SearchString);

EndProcedure

Procedure CancelSelectionInText(TextToChange, ParametersOfSelection, SearchString)
	
	StartPosition       = 1;
	SelectedText        = TextWithSelectionTags(ParametersOfSelection, SearchString);
	LengthOfSelectedText = StrLen(SelectedText);
	SearchStringLength      = StrLen(SearchString);
	FoundPosition       = StrFind(TextToChange, SelectedText, SearchDirection.FromBegin, StartPosition);
	
	While FoundPosition <> 0 Do
		
		TextToChange = Left(TextToChange, FoundPosition - 1) 
		                    + SearchString
		                    + Right(TextToChange, StrLen(TextToChange) - FoundPosition - LengthOfSelectedText + 1);
		
		StartPosition = FoundPosition + SearchStringLength;
		FoundPosition = StrFind(TextToChange, SelectedText, SearchDirection.FromBegin, StartPosition);
		
	EndDo
	
EndProcedure

Function SelectionParametersForFoundText()
	
	ParametersOfSelection = New Structure;
	ParametersOfSelection.Insert("StartTag", "<span style='color:#FF7C80;background:white'>");
	ParametersOfSelection.Insert("EndTag1", "</span>");
	ParametersOfSelection.Insert("ResultingShift", StrLen(ParametersOfSelection.StartTag) + StrLen(ParametersOfSelection.EndTag1));

	Return ParametersOfSelection;

EndFunction

Function SelectionParametersForCurCurrentTextFound()
	
	ParametersOfSelection = New Structure;
	ParametersOfSelection.Insert("StartTag", "<span style='color:#339966;background:silver'>");
	ParametersOfSelection.Insert("EndTag1", "</span>");
	ParametersOfSelection.Insert("ResultingShift", StrLen(ParametersOfSelection.StartTag) + StrLen(ParametersOfSelection.EndTag1));

	Return ParametersOfSelection;

EndFunction

Procedure CancelSearchResultsIfNecessary(Form)
	
	If Form.SearchIsCompleted Then
		
		DeselectSearchResults(Form.ScenarioText, Form.SearchString);
		Form.SearchIsCompleted = False;
		Form.SearchString  = "";
		
	EndIf;
	
EndProcedure 

Procedure TransferResultsOfChangesIfNecessary(Form)
	
	If Form.ThereAreEditingChanges Then
		
		TheStructureOfTheSearch = New Structure("LanguageCode", Form.ScriptLanguage);
		
		FoundRows = Form.ScenarioDescriptions.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			FoundRows[0].HTMLText       = Form.ScenarioText;
			FoundRows[0].ThereAreEditingChanges = True;
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure OpenScreenshotAttachedFile(Ref, Form) Export

	FileData = FilesOperationsClient.FileData(Ref, Form.UUID);
	
	FilesOperationsClient.OpenFile(FileData);
	
EndProcedure

#EndRegion 

