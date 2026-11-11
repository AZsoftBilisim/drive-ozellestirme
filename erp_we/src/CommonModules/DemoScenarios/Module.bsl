#Region Internal

// Creates Form elements to display available languages
//
// Parameters:
//  Form - ClientApplicationForm  - The Form for which languages are displayed
//
Procedure CreateFormElementsConfigurationLanguages(Form) Export
	
	If ConfigurationLanguageElementsAreCreated(Form) Then
		Return;
	EndIf;
	
	ConfigurationLanguages = ConfigurationLanguages();
	
	For Each ConfigurationLanguage In ConfigurationLanguages Do
		
		PlacementGroup = Form.Items.EditingLanguageSubmenu;
	
		NewCommand = Form.Commands.Add("SwitchToEditingLanguage_" + ConfigurationLanguage);
		NewCommand.Action = "Attachable_ChangeEditingLanguage";
		
		SubmenuButton = Form.Items.Add("SwitchToEditingLanguage_" + ConfigurationLanguage,
		                                        Type("FormButton"),
		                                        PlacementGroup);
		
		SubmenuButton.Type                   = FormButtonType.CommandBarButton;
		SubmenuButton.CommandName            = NewCommand.Name;
		SubmenuButton.Title             = ConfigurationLanguage;
		SubmenuButton.OnlyInAllActions = False; 
		
		PlacementGroup = Form.Items.SubmenuViewingLanguage;
	
		NewCommand = Form.Commands.Add("SwitchToViewingLanguage_" + ConfigurationLanguage);
		NewCommand.Action = "Attachable_ChangeViewingLanguage";
		
		SubmenuButton = Form.Items.Add("SwitchToViewingLanguage_" + ConfigurationLanguage,
		                                        Type("FormButton"),
		                                        PlacementGroup);
		
		SubmenuButton.Type                   = FormButtonType.CommandBarButton;
		SubmenuButton.CommandName            = NewCommand.Name;
		SubmenuButton.Title             = ConfigurationLanguage;
		SubmenuButton.OnlyInAllActions = False;
		
	EndDo;

EndProcedure

// Returns the data of the attached file for processing in the Form of an object
//
// Parameters:
//  RefToAttachedFile - CatalogRef.DemoScenariosAttachedFiles - the file for which the data is obtained
// 
// Returns:
//   Structure   - Contains:
//    *Description    - String - file name
//    *HTMLText       - String - the text contained in the file
//    *ModificationDate - Date - last modified date
//    *ChangedBy         - CatalogRef.Users - the author of the last change
//    *IsBeingEdited   - Boolean - indicates that the file is currently being edited
//    *DateOfCapture     - Date - file capture date
//    *BeingEditedBy     - CatalogRef.Users - the user currently editing the file
//
Function AttachedFileDataForObjectForm(RefToAttachedFile) Export
	
	DateEmpty               = Date(1, 1, 1);
	UsersEmptyLink = Catalogs.Users.EmptyRef();
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Description",    "");
	ReturnStructure.Insert("HTMLText",       DemoScenariosClientServer.EmptyHTMLText());
	ReturnStructure.Insert("ModificationDate", DateEmpty);
	ReturnStructure.Insert("ChangedBy",         UsersEmptyLink);
	ReturnStructure.Insert("IsBeingEdited",   False);
	ReturnStructure.Insert("DateOfCapture",     DateEmpty);
	ReturnStructure.Insert("BeingEditedBy",     UsersEmptyLink); 
	
	If Not ValueIsFilled(RefToAttachedFile) Then
		Return ReturnStructure;
	EndIf;
	
	FileData = FilesOperations.FileData(RefToAttachedFile);
	
	ReturnStructure.HTMLText       = HTMLTextBasedOnAttachedFileData(FileData);
	ReturnStructure.ModificationDate = ToLocalTime(FileData.UniversalModificationDate);
	ReturnStructure.DateOfCapture     = FileData.LockedDate;
	ReturnStructure.BeingEditedBy     = FileData.BeingEditedBy;
	ReturnStructure.IsBeingEdited   = FileData.FileBeingEdited;
	ReturnStructure.ChangedBy         = FileData.CurrentVersionAuthor;
	ReturnStructure.Description    = FileData.Description;
	
	Return ReturnStructure;
	
EndFunction 

// Gets Cur current configuration languages
//
// Returns:
//   Array of String - 
//
Function ConfigurationLanguages() Export
	
	Languages = New Array;
	For Each Language In Metadata.Languages Do
		Languages.Add(Language.LanguageCode);
	EndDo;
	
	Return Languages;
	
EndFunction

// Generates a string for Presentation of configuration objects or profiles in viewing mode
//
// Parameters:
//  TitleOfPresentation  - String - line header
//  PresentationsList     - ValueList - contains Presentations of objects
//  MaxStringLength - Number - maximum length of the generated Presentation
//
// Returns:
//   String - generated Presentation
//
Function LinePresentationWithMore(TitleOfPresentation, PresentationsList, MaxStringLength) Export

	Presentation = TitleOfPresentation;
	
	ItemsProcessed = 0;
	For Each ListItem In PresentationsList Do
		
		If StrLen(Presentation) + StrLen(ListItem.Presentation) < MaxStringLength Then
			Presentation = Presentation + ?(ItemsProcessed = 0, " ", ", ") + ListItem.Presentation;
		Else
			Return Presentation + " " + StrTemplate(NStr("vi = 'và còn %1';
														|ru = 'и еще %1';
														|en = 'and also %1'; fa = 'and also %1';
														|it = 'e anche %1';
														|pl = 'i jeszcze %1';
														|tr = 've %1 daha'"), String(PresentationsList.Count() - ItemsProcessed));
		EndIf; 
		
		ItemsProcessed = ItemsProcessed + 1;
		
	EndDo; 
	
	Return Presentation;
	
EndFunction

// Loads the saved setting according to the Form display option for the user
//
// Parameters:
//  Form              - ClientApplicationForm  - The Form for which the action is performed
//  AvailableValues  - Array of String            - values available for the Cur current user
//  ObjectMetadata  - MetadataObject            - object metadata
//
Procedure LoadSettingForFormDisplayOption(Form, AvailableValues, ObjectMetadata) Export
	
	Form.ThereIsTheRightToEdit          = AccessRight("Update", ObjectMetadata);
	
	SettingDisplayMode = Common.CommonSettingsStorageLoad("DisplayModeProcessDescriptionForm",
	                                                                             "UserSettings",
	                                                                              Undefined);
	
	If Not ValueIsFilled(SettingDisplayMode) Then
		
		SettingDisplayMode = "View";
		
	EndIf;
	
	If Form.Parameters.Property("ExecuteSearch")
		And Not Form.Parameters.ExecuteSearch Then
		
		SettingDisplayMode = "Edit";
		
	EndIf;
	
	If AvailableValues.Find(SettingDisplayMode) = Undefined Then
		
		SettingDisplayMode = "View";
		
	EndIf;
	
	If Not Form.ThereIsTheRightToEdit Then
		
		SettingDisplayMode = "View";
		Form.Items.SubmenuViewEditMode.Visible = False;
		
	EndIf;
	
	SwitchingParameters = DemoScenariosClientServer.NewDisplayOptionSwitchingOptions();
	SwitchingParameters.Form                          = Form;
	SwitchingParameters.NewOption                   = SettingDisplayMode;
	
	DemoScenariosClientServer.SwitchDisplayOption(SwitchingParameters);
	
EndProcedure

// Sets the languages in the default Form
//
// Parameters:
//  Form                      - ClientApplicationForm  - The Form for which the action is performed
//  NameOfReadingAttribute         - String - the name of the Attribute that contains the text to view
//  AttributeNameEditing - String - the name of the Attribute that contains the text to edit
//
Procedure SetLanguageSettingInForm(Form, NameOfReadingAttribute, AttributeNameEditing) Export 
	
	CodeCurrentLanguage =  CurrentLanguage().LanguageCode;
	
	Form[AttributeNameEditing] = CodeCurrentLanguage;
	Form[NameOfReadingAttribute] = CodeCurrentLanguage;
	
EndProcedure

// Returns display options available to the user
//
// Parameters:
//  EnableTranslationMode  - Boolean - is it required to include the "Translation" option
//
// Returns:
//   Array of String - Available Display Options
//
Function AvailableDisplayOptions(EnableTranslationMode = True) Export
	
	AvailableOptions = New Array;
	AvailableOptions.Add("View");
	AvailableOptions.Add("Edit");
	
	If EnableTranslationMode Then
		AvailableOptions.Add("Translation");
	EndIf;
	
	Return AvailableOptions;
	
EndFunction

// Fills out scenario descriptions in the Form 
//
// Parameters:
//  CurrentObject         - CatalogObject.DemoScenarios - the object for which the action is performed
//  ScenarioDescriptionsForm - ValueTable - The Form Attribute where descriptions are placed
//
Procedure FillInScenarioDescriptions(CurrentObject, ScenarioDescriptionsForm) Export

	ScenarioDescriptionsForm.Clear();
	For Each CurRow In CurrentObject.ScenarioDescriptions Do
		
		NewRow = ScenarioDescriptionsForm.Add();
		Try
			AttachedFileData = AttachedFileDataForObjectForm(CurRow.AttachedFile);
			FillPropertyValues(NewRow, AttachedFileData);
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		NewRow.LanguageCode = CurRow.LanguageCode;
		
	EndDo;
	
EndProcedure

// Fills scenario descriptions in the Form with scenarios of another object 
//
// Parameters:
//  AnotherObject          - CatalogObject.DemoScenarios - the object whose descriptions are copied
//  ScenarioDescriptionsForm - ValueTable - The Form Attribute where descriptions are placed
//
Procedure FillScenarioDescriptionsInFormWithScenariosOfAnotherObject(AnotherObject, ScenarioDescriptionsForm) Export
	
	ScenarioDescriptionsForm.Clear();
	
	If ValueIsFilled(AnotherObject)
		And TypeOf(AnotherObject) = Type("CatalogRef.DemoScenarios") Then
		
		Query = New Query;
		Query.Text = "
		|SELECT
		|	DemoScenariosAttachedFiles.Ref AS Ref,
		|	DemoScenariosAttachedFiles.Description AS Description
		|FROM
		|	Catalog.DemoScenariosAttachedFiles AS DemoScenariosAttachedFiles
		|WHERE
		|	NOT DemoScenariosAttachedFiles.DeletionMark
		|	AND DemoScenariosAttachedFiles.FileOwner = &AnotherObject";
		
		Query.SetParameter("AnotherObject", AnotherObject);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
		
			NewRow = ScenarioDescriptionsForm.Add();
			AttachedFileData = AttachedFileDataForObjectForm(Selection.Ref);
			NewRow.HTMLText      = AttachedFileData.HTMLText;
			NewRow.LanguageCode       = DemoScenariosClientServer.LanguageCodeFromFileName(AttachedFileData.Description);
		
		EndDo;
		
	EndIf;
	
EndProcedure

// Creates an attached script file
//
// Parameters:
//  FileOwner - CatalogRef.DemoScenarios - the script for which the file is being created
//  Form         - ClientApplicationForm  - The Form in which the action is performed
//  LanguageCode       - String  - the code of the language for which the file is being created
//
// Returns:
//   Structure - Contains:
//     * Success            - Boolean - indicates whether the operation was successful
//     * AttachedFile - CatalogRef.DemoScenariosAttachedFiles, Undefined - link to the created file
//     * ErrorText        - String - error text in case of failure
//
Function ResultOfCreatingAttachedScriptFile(FileOwner, Form, LanguageCode) Export
	
	CatalogObject = Form.Object;
	
	CreationResult = New Structure;
	CreationResult.Insert("Success",            False);
	CreationResult.Insert("AttachedFile", Undefined);
	CreationResult.Insert("ErrorText",        "");
	
	If Not ValueIsFilled(LanguageCode) Then
		CreationResult.ErrorText = NStr("vi = 'Chưa chỉ ra mã ngôn ngữ';
										|ru = 'Не указан код языка';
										|en = 'Language code is not specified'; fa = 'Language code is not specified';
										|it = 'Не указан код языка';
										|pl = 'Language code is not specified';
										|tr = 'Dil kodu belirtilmedi'");
		Return CreationResult;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("LanguageCode", LanguageCode);
	
	ScenarioText = "";
	FoundRows = Form.ScenarioDescriptions.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		ScenarioText =   FoundRows[0].HTMLText;
	Else
		NewRow = Form.ScenarioDescriptions.Add();
		NewRow.LanguageCode = LanguageCode;
		NewRow.HTMLText = DemoScenariosClientServer.EmptyHTMLText();
		ScenarioText = NewRow.HTMLText
	EndIf;
	
	FileBinaryData = GetBinaryDataFromString(ScenarioText);
	AddressInTempStorage = PutToTempStorage(FileBinaryData, Form.UUID);
	
	FileRecordingOptions = FilesOperations.FileAddingOptions(); 
	FileRecordingOptions.FilesOwner              = FileOwner;
	FileRecordingOptions.BaseName            =  DemoScenariosClientServer.NameOfScriptDescriptionFile(CatalogObject.FullCode,LanguageCode);
	FileRecordingOptions.ExtensionWithoutPoint          = "HTML";
	FileRecordingOptions.ModificationTimeUniversal = Undefined;
	
	Try
	
		CreatedAttachedFile = FilesOperations.AppendFile(
		                                    FileRecordingOptions,
		                                    AddressInTempStorage,
		                                    "");
	
	Except
		
		CreationResult.ErrorText = BriefErrorDescription(ErrorInfo());
		Return CreationResult;
		
	EndTry;
	
	CreationResult.Success            = True;
	CreationResult.AttachedFile = CreatedAttachedFile;
	
	Return CreationResult;
	
EndFunction

// Writes a new attached script file from the object Form
//
// Parameters:
//  Form         - ClientApplicationForm  - The Form in which the action is performed
//  CurrentObject - CatalogObject.DemoScenarios - the script for which the files are being written
//  Cancel         - Boolean  - indicates that the operation failed
//
Procedure WriteNewScenarioDescriptionsFromObjectForm(Form, CurrentObject, Cancel) Export
	
	For Each DescriptionOfScenario In Form.ScenarioDescriptions Do
		
		If Not ValueIsFilled(DescriptionOfScenario.ModificationDate) Then
			
			If CurrentObject.Ref.IsEmpty() Then
				
				RefToNew = Catalogs.DemoScenarios.GetRef(Form.UUID);
				CurrentObject.SetNewObjectRef(RefToNew); 
				LinkToScript = CurrentObject.GetNewObjectRef();
				
			Else
				
				LinkToScript = CurrentObject.Ref;
				
			EndIf;
			
			CreationResult = ResultOfCreatingAttachedScriptFile(
				LinkToScript, 
				Form,
				DescriptionOfScenario.LanguageCode);
				
			If CreationResult.Success Then
				
				NewRow = CurrentObject.ScenarioDescriptions.Add();
				NewRow.LanguageCode           = DescriptionOfScenario.LanguageCode;
				NewRow.AttachedFile = CreationResult.AttachedFile;
				
				DescriptionOfScenario.ThereAreEditingChanges = False;
				
			Else
				
				Common.MessageToUser(CreationResult.ErrorText);
				Cancel = True;
				
			EndIf;
			
		EndIf;
		
		If DescriptionOfScenario.ThereAreEditingChanges Then
			
			AttachedFile = DemoScenariosClientServer.AttachedScriptFile(Form, DescriptionOfScenario.LanguageCode);
			
			SavingResult = ResultOfUpdatingAttachedFile(AttachedFile, Form.UUID, DescriptionOfScenario.HTMLText);
			
			If Not SavingResult Then
				Cancel = True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Updates the attached script file
//
// Parameters:
//  AttachedFile       - CatalogRef.DemoScenariosAttachedFiles - the file being updated
//  UUID  - UUID  - ID of the Form where the action is being performed
//  NewData              - String, BinaryData  - new file contents
//
// Returns:
//   Boolean - True if successful
//
Function ResultOfUpdatingAttachedFile(AttachedFile, UUID, NewData) Export
	
	CurCurrentDataOfAttachedFile = FilesOperations.FileData(AttachedFile, FilesOperationsClientServer.FileDataParameters());
	
	If TypeOf(NewData) = Type("String") Then
		NewData = GetBinaryDataFromString(NewData);
	EndIf;
	AddressInTempStorage = PutToTempStorage(NewData, UUID);
	
	FileInfo1 = FilesOperationsClientServer.FileInfo1("File"); 
	FileInfo1.TempFileStorageAddress = AddressInTempStorage;
	FileInfo1.ExtensionWithoutPoint = CurCurrentDataOfAttachedFile.Extension;
	If Not IsBlankString(FileInfo1.ExtensionWithoutPoint) Then
		FileInfo1.BaseName = Left(CurCurrentDataOfAttachedFile.FileName,
		                                  StrLen(CurCurrentDataOfAttachedFile.FileName) - StrLen(FileInfo1.ExtensionWithoutPoint) - 1);
	Else
		FileInfo1.BaseName = CurCurrentDataOfAttachedFile.FileName;
	EndIf;
	
	FileInfo1.Encoding = CurCurrentDataOfAttachedFile.Encoding;
	
	SavingResult = FilesOperationsInternalServerCall.SaveChangesAndUnlockFile(
		CurCurrentDataOfAttachedFile, FileInfo1, False, "", "", UUID); 
		
	Return SavingResult;
	
EndFunction

// Adds the roles of the process description subsystem to the profile
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription 
//
Procedure AddRolesReadingSubsystemObjectsDescribingProcesses(ProfileDetails) Export

	ProfileDetails.Roles.Add("SubsystemProcessDetails");
	ProfileDetails.Roles.Add("ReadGlossaries");
	ProfileDetails.Roles.Add("ReadDemoScenarios");
	
EndProcedure

// Processes the search parameters passed to the script Form when opening, if you want to perform a search
//
// Parameters:
//  Form      - ClientApplicationForm  - The Form for which the action is performed
//  Parameters  - Structure - parameters of the search being performed
//
Procedure ProcessSearchParametersPassedToObjectForm(Form, Parameters) Export
	
	If Parameters.Property("ExecuteSearch")
		And Parameters.ExecuteSearch Then
		
		Form.SearchParametersWhenOpening = Parameters.SearchParameters;
		
	EndIf;
	
EndProcedure

// Generates a DocumentHTML object from HTML text
//
// Parameters:
//  HTMLText   - String - the text from which the DocumentHTML object will be formed
//  Encoding   - String  - text encoding
//
// Returns:
//   HTMLDocument - generated object
//
Function HTMLDocumentObjectFromHTMLText(HTMLText, Encoding = Undefined) Export
	
	Builder = New DOMBuilder;
	HTMLReader = New HTMLReader;
	
	NewHTMLText = HTMLText;
	PositionOpenXML = StrFind(NewHTMLText,"<?xml");
	
	If PositionOpenXML > 0 Then
		
		PositionCloseXML = StrFind(NewHTMLText,"?>");
		If PositionCloseXML > 0 Then
			
			NewHTMLText = Left(NewHTMLText,PositionOpenXML - 1) + Right(NewHTMLText,StrLen(NewHTMLText) - PositionCloseXML -1);
			
		EndIf;
		
	EndIf;
	
	If Encoding = Undefined Then
		
		HTMLReader.SetString(HTMLText);
		
	Else
		
		Try
		
			HTMLReader.SetString(HTMLText, Encoding);
		
		Except
			
			HTMLReader.SetString(HTMLText);
			
		EndTry;
		
	EndIf;
	
	Return Builder.Read(HTMLReader);
	
EndFunction

// Performs translation
//
// Parameters:
//  TranslatedText - String - the text that is being translated
//  LanguageWeAreTranslatingFrom         - String  - the code of the language from which the translation is performed
//  LanguageWeAreTranslatingInto         - String  - the code of the language to which the translation is performed
//
// Returns:
//   Structure - Contains:
//     * Success               - Boolean - indicates whether the operation was successful
//     * UserMessage - String - text of the message to the user
//     * TextIsTranslated     - String - translation result
//
Function ResultOfTranslationIntoOtherLanguages(TranslatedText, LanguageWeAreTranslatingFrom, LanguageWeAreTranslatingInto) Export
	
	TransitionResult = New Structure;
	TransitionResult.Insert("Success",               False);
	TransitionResult.Insert("UserMessage", "");
	TransitionResult.Insert("TextIsTranslated"      , "");
	
	HTMLDocument = HTMLDocumentObjectFromHTMLText(TranslatedText);
	MatchingTextsToDocumentNodes = MatchingTextsToDocumentNodes(HTMLDocument.Body);
	
	If MatchingTextsToDocumentNodes.Count() = 0 Then
		
		TransitionResult.UserMessage = NStr("vi = 'Không tìm thấy nội dung để dịch trong kịch bản gốc';
											|ru = 'Текст для перевода в исходном сценарии найден не был';
											|en = 'The text for translation is not found in the source scenario'; fa = 'The text for translation is not found in the source scenario';
											|it = 'Текст для перевода в исходном сценарии найден не был';
											|pl = 'The text for translation is not found in the source scenario';
											|tr = 'Çeviri metni kaynak senaryoda bulunamadı'");
		Return TransitionResult;
		
	EndIf;
	
	ArrayOfStringsToTranslate = New Array;
	For Each MapItem In MatchingTextsToDocumentNodes Do
		ArrayOfStringsToTranslate.Add(MapItem.Value.Text);
	EndDo;
	
	Try
	
		DataForTranslation = TextTranslationTool.TranslateTheTexts(ArrayOfStringsToTranslate, LanguageWeAreTranslatingInto, LanguageWeAreTranslatingFrom); 
	
	Except
		
		TransitionResult.UserMessage = BriefErrorDescription(ErrorInfo());
		Return TransitionResult;

	EndTry;
	
	For Each TranslationElement In DataForTranslation Do
		
		TextHash = TextHash(TranslationElement.Key);
		
		NodesData = MatchingTextsToDocumentNodes.Get(TextHash);
		
		If NodesData <> Undefined Then
			
			For Each DocNode In NodesData.DocumentNodes Do
				
				DocNode.NodeValue = TranslationElement.Value;
				
			EndDo;
			
		EndIf;
	EndDo;
	
	TransitionResult.TextIsTranslated = HTMLTextFromHTMLDocumentObject(HTMLDocument);
	TransitionResult.Success         = True; 
	
	Return TransitionResult;
	
EndFunction

// Caches configuration languages in the Form Attributes
//
// Parameters:
//  Form         - ClientApplicationForm  - The Form in which the action is performed
//
Procedure SetConfigurationLanguagesInForm(Form) Export

	Form.ConfigurationLanguages = New ValueList;
	Form.ConfigurationLanguages.LoadValues(ConfigurationLanguages());

EndProcedure

// Gets the name of the multilingual Attribute of the object of the Cur language of the user
//
// Parameters:
//  AttributeName - String - Attribute name
//  Translatable language - string - code of the language from which the translation is performed
//
// Returns:
//   String - Name Of the Multilingual Attribute
//
Function NameOfMultilingualAttribute(AttributeName) Export
	
	Postfix = NationalLanguageSupportServer.CurrentLanguageSuffix();
	
	Return AttributeName + Postfix;

EndFunction

// The method resets the size and position of the window. Allows you to restore the Form dimensions
// after opening and closing collapsible Forms and redrawing elements based on visibility
// 
// Parameters:
//  Form - ClientApplicationForm - The Form where you want to reset the settings
//
Procedure ResetWindowLocationAndSize(Form) Export
	
	UserName = InfoBaseUsers.CurrentUser().Name;
	If AccessRight("SaveUserData", Metadata) Then
		SystemSettingsStorage.Delete(Form.FormName, "", UserName);
	EndIf;
	Form.WindowOptionsKey = String(New UUID);
	
EndProcedure

// Handler for a background search task in demo scenarios
//
// Parameters:
//  SearchParameters - Structure  - 
//  StorageAddress  - String  - the address where the result of the operation will be placed
//
Procedure PerformSearchInDemoScripts(SearchParameters, StorageAddress) Export
	
	SearchResult = ResultOfGlobalSearchInDemoScenarios(SearchParameters);
	
	PutToTempStorage(SearchResult, StorageAddress);
	
EndProcedure

// Handler for a background job to perform a replacement in demo scenarios
//
// Parameters:
//  ReplacementParameters - Structure  - 
//  StorageAddress - String  - the address where the result of the operation will be placed
//
Procedure PerformReplacementInDemoScenarios(ReplacementParameters, StorageAddress) Export
	
	ReplacementResult = ResultOfReplacementInDemoScenarios(ReplacementParameters);
	
	PutToTempStorage(ReplacementResult, StorageAddress);
	
EndProcedure 

// Handler for a background job to perform a replacement in demo scenarios
//
// Parameters:
//  ReplacementParameters - Structure  - 
//  StorageAddress - String  - the address where the result of the operation will be placed
//
Procedure TranslateDemoScripts (ReplacementParameters, StorageAddress) Export
	
	ReplacementResult = TranslationResultsInDemoScenarios(ReplacementParameters);
	
	PutToTempStorage(ReplacementResult, StorageAddress);
	
EndProcedure

// Searches for unique links in an HTML document
//
// Parameters:
//  ScenarioText   - String - HTML document text
//
// Returns:
//   Array of String - found links
//
Function UniqueLinksInHTML5Document(ScenarioText) Export

	TextLength = StrLen(ScenarioText);
	BeginningOfHyperlink = "<a href=""";
	LengthOfBeginningOfHyperlinkTag = 8;
	PositionOfFound = StrFind(ScenarioText, BeginningOfHyperlink, SearchDirection.FromBegin, 1);
	FoundRefs = New Array;
	
	While PositionOfFound <> 0 Do
		
		StartingSearchForHyperlinkBody = PositionOfFound + LengthOfBeginningOfHyperlinkTag;
		WhereAreWeLookingForHyperlinkBody = Right(ScenarioText, TextLength - StartingSearchForHyperlinkBody);
		PositionFoundIsEndOfHyperlink = StrFind(WhereAreWeLookingForHyperlinkBody, """", SearchDirection.FromBegin, LengthOfBeginningOfHyperlinkTag);
		If PositionFoundIsEndOfHyperlink = 0 Then
			Break;
		EndIf;
		
		FoundRef = Mid(ScenarioText, StartingSearchForHyperlinkBody + 1, PositionFoundIsEndOfHyperlink - 1);
		If FoundRefs.Find(FoundRef) = Undefined Then
			FoundRefs.Add(FoundRef);
		EndIf;
		
		PositionOfFound = StrFind(ScenarioText, BeginningOfHyperlink, SearchDirection.FromBegin, PositionOfFound + PositionFoundIsEndOfHyperlink);
		
	EndDo;
	
	Return FoundRefs;
	
EndFunction

// Gets a reference to an object from a navigation link
//
// Parameters:
//  URL  - String - 
//
// Returns:
//   CatalogRef, DocumentRef, Undefined - the link to the object obtained from the navigation link
//
Function LinkToPlaceViaNavigationLink(URL) Export
	
	FirstPoint = Find(URL, "e1cib/data/");
	SecondPoint = Find(URL, "?ref=");
	
	TypePresentation = Mid(URL, FirstPoint + 11, SecondPoint - FirstPoint - 11);
	IDPresentation = Mid(URL, SecondPoint + 5);
	IDPresentation = Right(IDPresentation, 8) + "-"
	                              + Mid(IDPresentation, 21, 4) + "-"
	                              + Mid(IDPresentation, 17, 4) + "-"
	                              + Left(IDPresentation, 4) + "-"
	                              + Mid(IDPresentation, 5, 12);
	
	Try
		RefType = PredefinedValue(TypePresentation + ".EmptyRef");
		ObjectManager = Common.ObjectManagerByRef(RefType);
		Result = ObjectManager.GetRef(New UUID(IDPresentation));
	Except
		Result = Undefined; 
	EndTry;
	
	Return Result;
	
EndFunction

// Generates a Presentation of the Cur version of the configuration
//
// Returns:
//   String - generated Presentation of the Cur version of the configuration
//
Function PresentationCurVersionOfConfiguration() Export
	
	Return StrTemplate(NStr("vi = '%1 phiên bản %2 ngày %3';
							|ru = '%1 версии %2 от %3';
							|en = '%1 versions %2 dated %3'; fa = '%1 versions %2 dated %3';
							|it = '%1 версии %2 от %3';
							|pl = '%1 versions %2 dated %3';
							|tr = '%3 itibarıyla %2 sürümlü %1'"),
	                  Metadata.BriefInformation, 
	                  Metadata.Version, 
	                  Format(CurrentSessionDate(), "DLF=D"));
	
EndFunction

// Generates process description data for uploading
//
// Parameters:
//  Vendor  - String - string Presentation of the process description provider
//
// Returns:
//   Structure  - Contains:
//     * Success               - Boolean - indicates that the report was generated successfully.
//     * ErrorsMessages    - Array of String - error messages in case the data preparation failed.
//     * PreparedData  - Structure - prepared data.
//
Function ResultOfPlacementForSupport(Vendor) Export
	
	ResultOfStatement = New Structure;
	ResultOfStatement.Insert("Success",           True);
	ResultOfStatement.Insert("ErrorMessage", "");
	
	CompleteStatementForSupport(ResultOfStatement, Vendor);
	
	Return ResultOfStatement;
	
EndFunction 

// It is used by the background task for setting process descriptions from the Cur version to support.
// Parameters:
//  GenerationParameters  - Structure - 
//  StorageAddress         - String - the address of the temporary storage where the received data will be placed
//
Procedure PutProcessDescriptionsOnSupportFromCurVersion(GenerationParameters, StorageAddress) Export
	
	ResultOfStatement = ResultOfPlacementForSupport(GenerationParameters.Vendor);
	
	PutToTempStorage(ResultOfStatement, StorageAddress);
	
EndProcedure

// Constructor of the structure containing the Attributes of the Process Description Catalog
//
// Returns:
//  Structure - Contains:
//   *Ref               - CatalogRef.DemoScenarios - 
//   *DeletionMark      - Boolean - 
//   *IsFolder            - Boolean - 
//   *GroupType            - EnumRef.TypesOfProcessDetailsGroups - 
//   *FullCode            - String - 
//   *Code                  - String -  
//   *Description         - String - 
//   *DescriptionLanguage1    - String - 
//   *DescriptionLanguage2    - String - 
//   *Comment          - String - 
//   *Status               - EnumRef.ProcessDetailsStatuses- 
//   *AccessGroupProfiles  - ValueTable - 
//   *ConfigurationObjects  - ValueTable - 
//
Function NewAttributeDataDescriptionOfProcesses() Export
	
	AttributesData = New Structure;
	
	AttributesData.Insert("Ref",             New TypeDescription("CatalogRef.DemoScenarios"));
	AttributesData.Insert("DeletionMark",    New TypeDescription("Boolean"));
	AttributesData.Insert("IsFolder",          New TypeDescription("Boolean"));
	AttributesData.Insert("GroupType",          New TypeDescription("EnumRef.TypesOfProcessDetailsGroups"));
	AttributesData.Insert("Parent",           New TypeDescription("CatalogRef.DemoScenarios"));
	AttributesData.Insert("FullCode",          Common.StringTypeDetails(100));
	AttributesData.Insert("Code",                Common.StringTypeDetails(3));
	AttributesData.Insert("Description",       Common.StringTypeDetails(150));
	AttributesData.Insert("DescriptionLanguage1",  Common.StringTypeDetails(150));
	AttributesData.Insert("DescriptionLanguage2",  Common.StringTypeDetails(150));
	AttributesData.Insert("Comment",        Common.StringTypeDetails(0));
	AttributesData.Insert("Status",             New TypeDescription("EnumRef.ProcessDetailsStatuses"));
	AttributesData.Insert("AccessGroupProfiles");
	AttributesData.Insert("ConfigurationObjects");
	
	Return AttributesData;
	
EndFunction

// Constructor of the structure containing the Attributes of the Glossary Catalog
//
// Returns:
//  Structure - Contains:
//   *Ref               - CatalogRef.Glossary - 
//   *DeletionMark      - Boolean - 
//   *Code                  - String -  
//   *Description         - String - 
//   *DescriptionLanguage1    - String - 
//   *DescriptionLanguage2    - String - 
//   *ConfigurationObjects  - ValueTable - 
//
Function NewAttributeDataGlossary() Export
	
	AttributesData = New Structure;
	
	AttributesData.Insert("Ref",             New TypeDescription("CatalogRef.DemoScenarios"));
	AttributesData.Insert("DeletionMark",    New TypeDescription("Boolean"));
	AttributesData.Insert("Code",                Common.StringTypeDetails(9));
	AttributesData.Insert("Description",       Common.StringTypeDetails(150));
	AttributesData.Insert("DescriptionLanguage1",  Common.StringTypeDetails(150));
	AttributesData.Insert("DescriptionLanguage2",  Common.StringTypeDetails(150));
	AttributesData.Insert("Comment",        Common.StringTypeDetails(0));
	AttributesData.Insert("ConfigurationObjects");
	
	Return AttributesData;
	
EndFunction 

// Generates a JSON object based on data from the Glossary Catalog
//
// Parameters:
//  GlossaryAttributes - See NewAttributeDataGlossary
//
// Returns:
//  String - 
//
Function TextOfGlossarySJSONAttributes(GlossaryAttributes) Export
	
	DataWriter = New JSONWriter;
	DataWriter.SetString();
	
	DataWriter.WriteStartObject();
	
	DataWriter.WritePropertyName("UUID");
	DataWriter.WriteValue(String(GlossaryAttributes.Ref.UUID()));
	
	DataWriter.WritePropertyName("DeletionMark");
	DataWriter.WriteValue(GlossaryAttributes.DeletionMark);
	
	DataWriter.WritePropertyName("Code");
	DataWriter.WriteValue(GlossaryAttributes.Code);
	
	DataWriter.WritePropertyName("Name");
	DataWriter.WriteValue(GlossaryAttributes.Description);
	
	DataWriter.WritePropertyName("NameLanguage1");
	DataWriter.WriteValue(GlossaryAttributes.DescriptionLanguage1);
	
	DataWriter.WritePropertyName("NameLanguage2");
	DataWriter.WriteValue(GlossaryAttributes.DescriptionLanguage2);
	
	DataWriter.WritePropertyName("ObjectsOfMetadata");
	DataWriter.WriteStartArray();
	
	For Each TableRow In GlossaryAttributes.ConfigurationObjects Do
		
		If ValueIsFilled(TableRow.ConfigurationObject) Then
			DataWriter.WriteValue(String(TableRow.ConfigurationObject.UUID()));
		EndIf;
		
	EndDo;
	
	DataWriter.WriteEndArray();
	
	DataWriter.WriteEndObject();
	
	JSONText = DataWriter.Close();
	
	Return JSONText;
	
EndFunction

// Generates a JSON object based on the data from the Process Description Catalog
//
// Parameters:
//  Data from the Glossary's Inquisitives - SeeNewAttributeDataDescriptionOfProcesses
//  ()
//
// Returns:
//  String - 
//
Function JSONTextAttributesDescriptionOfProcesses(DescriptionData) Export
	
	DataWriter = New JSONWriter;
	DataWriter.SetString();
	
	DataWriter.WriteStartObject();
	
	DataWriter.WritePropertyName("UUID");
	DataWriter.WriteValue(String(DescriptionData.Ref.UUID()));
	
	DataWriter.WritePropertyName("Parent");
	If ValueIsFilled(DescriptionData.Parent) Then
		DataWriter.WriteValue(String(DescriptionData.Parent.UUID()));
	Else
		DataWriter.WriteValue("");
	EndIf;
	
	DataWriter.WritePropertyName("DeletionMark");
	DataWriter.WriteValue(DescriptionData.DeletionMark);
	
	DataWriter.WritePropertyName("FullCode");
	DataWriter.WriteValue(DescriptionData.FullCode);
	
	DataWriter.WritePropertyName("Code");
	DataWriter.WriteValue(DescriptionData.Code);
	
	DataWriter.WritePropertyName("Name");
	DataWriter.WriteValue(DescriptionData.Description);
	
	DataWriter.WritePropertyName("Status");
	StatusValue = ?(ValueIsFilled(DescriptionData.Status), Enums.ProcessDetailsStatuses.IndexOf(DescriptionData.Status), -1);
	DataWriter.WriteValue(StatusValue);
	
	DataWriter.WritePropertyName("Comment");
	DataWriter.WriteValue(DescriptionData.Comment);
	
	DataWriter.WritePropertyName("IsGroup");
	DataWriter.WriteValue(DescriptionData.IsFolder);
	
	If DescriptionData.IsFolder Then
		DataWriter.WritePropertyName("KindOfGroup");
		DataWriter.WriteValue(Enums.TypesOfProcessDetailsGroups.IndexOf(DescriptionData.GroupType));
	EndIf;
	
	DataWriter.WritePropertyName("NameLanguage1");
	DataWriter.WriteValue(DescriptionData.DescriptionLanguage1);
	
	DataWriter.WritePropertyName("NameLanguage2");
	DataWriter.WriteValue(DescriptionData.DescriptionLanguage2);
	
	DataWriter.WritePropertyName("AccessGroupProfiles");
	DataWriter.WriteStartArray();
	
	For Each TableRow In DescriptionData.AccessGroupProfiles Do
		
		If ValueIsFilled(TableRow.Profile) Then
			DataWriter.WriteValue(String(TableRow.Profile.UUID()));
		EndIf;
		
	EndDo;
	
	DataWriter.WriteEndArray();
	
	DataWriter.WritePropertyName("ObjectsOfMetadata");
	DataWriter.WriteStartArray();
	
	For Each TableRow In DescriptionData.ConfigurationObjects Do
		
		If ValueIsFilled(TableRow.ConfigurationObject) Then
			DataWriter.WriteValue(String(TableRow.ConfigurationObject.UUID()));
		EndIf;
		
	EndDo;
	
	DataWriter.WriteEndArray();
	
	DataWriter.WriteEndObject();
	
	JSONText = DataWriter.Close();
		
	Return JSONText;
	
EndFunction

// Sets the constant "Process descriptions on support"
//
// Parameters:
//  DataOfConfiguration - String
//  Vendor          - String
//
Procedure SetProcessDescriptionConstantOnSupport(DataOfConfiguration, Vendor) Export
	
	SetPrivilegedMode(True);
	
	DataWriter = New JSONWriter;
	DataWriter.SetString();
	
	DataWriter.WriteStartObject();
	
	DataWriter.WritePropertyName("ConfigurationDescription");
	DataWriter.WriteValue(DataOfConfiguration);
	
	DataWriter.WritePropertyName("Supplier");
	DataWriter.WriteValue(Vendor);
	
	DataWriter.WriteEndObject();
	
	JSONText = DataWriter.Close();
	
	Constants.DetailsOfSupportProcesses.Set(JSONText);
	
EndProcedure

// Reads the data of the constant "Process descriptions on support"
//
// Returns:
//  Structure - Contains:
//   * DataOfConfiguration - String
//   * Vendor          - String
//
Function ResultOfReadingProcessDescriptionConstantsOnSupport() Export
	
	ConstantData = New Structure;
	ConstantData.Insert("DataOfConfiguration", "");
	ConstantData.Insert("Vendor",          "");
	
	SetPrivilegedMode(True); 
	
	DescriptionData = Constants.DetailsOfSupportProcesses.Get();
	
	ReadingResult = ResultOfReadingJSONString(DescriptionData, "");
	If Not ReadingResult.Success Then
		
		Return ConstantData;
		
	Else
		
		If Not CommonClientServer.HasAttributeOrObjectProperty(ReadingResult.Data, "ConfigurationDescription")
			Or Not CommonClientServer.HasAttributeOrObjectProperty(ReadingResult.Data, "Supplier") Then
			
			Return ConstantData;
			
		EndIf;
		
		ConstantData.DataOfConfiguration = ReadingResult.Data.ConfigurationDescription;
		ConstantData.Vendor          = ReadingResult.Data.Supplier; 
		
		Return ConstantData;
		
	EndIf;
	
EndFunction

// Reads a string that contains JSON
// 
// Parameters:
//  Value                - String - passed string
//  FormatErrorMessage  - String - an error message that will be issued if reading the format fails
//  ReadToMap  - Boolean - a sign of the need to convert the read data to a match
//
// Returns:
//   Structure  -  Contains:
//     * Success       - Boolean - indicates whether the operation was successful
//     * Data        - Map -
//     * ErrorText   - String - error text if the Operation ended 
//
Function ResultOfReadingJSONString(Value, FormatErrorMessage, ReadToMap = False) Export
	
	ReadingResult = New Structure;
	ReadingResult.Insert("Success",      True);
	ReadingResult.Insert("Data",       Undefined);
	ReadingResult.Insert("ErrorText",  "");
	
	If TypeOf(Value) <> Type("String")
		Or IsBlankString(Value)
		Or Left(Value, 1) = "<" Then
		ReadingResult.Success = False;
		ReadingResult.ErrorText = FormatErrorMessage;
		Return ReadingResult;
	EndIf;
	
	Result = Undefined;
	JSONReader = New JSONReader;
	Try
		JSONReader.SetString(Value);
		ReadingResult.Data = ReadJSON(JSONReader, ReadToMap);
		JSONReader.Close();
	Except
		
		ReadingResult.Success = False;
		ReadingResult.ErrorText = DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
	Return ReadingResult;
	
EndFunction

// Gets a hash of the text
//
// Returns:
//  Number -
//
Function TextHash(Text) Export
	
	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.Append(ValueToStringInternal(Text));
	
	Return DataHashing.HashSum;
	
EndFunction

// Creates a stream in memory from binary data
//
// Parameters:
//  Binary data is the data from which the stream is created
//
// Returns:
//  MemoryStream -
//
Function InMemoryStreamOfBinaryData(BinaryDataOfDownloadFile) Export
	
	DownloadStream = New MemoryStream;
	BinaryDataOfDownloadFile.Write(DownloadStream);
	
	Return DownloadStream;
	
EndFunction

// Constructor of the structure containing the Attributes of the result of parsing the document links
//
// Returns:
//  Structure - New Link Analysis Result:
// * Commands - Map of String- 
// * ObjectsRefs - Map of String - 
// * Lists - Map of String - 
// * ExternalRefs - Map of String - 
//
Function NewLinkAnalysisResult() Export
	
	Result = New Structure;
	Result.Insert("Commands",         New Map);
	Result.Insert("ObjectsRefs", New Map);
	Result.Insert("Lists",          New Map);
	Result.Insert("ExternalRefs",   New Map);
	
	Return Result;
	
EndFunction 

// Creates a directory on yandex.disk for unzipping files when uploading
//
// Returns:
//   Structure -  Contains:
//    * Success     - Boolean -  
//    * ErrorText - String -
//    * DirectoryName - String - name of the created folder
//
Function ResultOfCreatingDirectoryForUnzippingUploading() Export
	
	CreationResult = New Structure;
	CreationResult.Insert("Success",     True);
	CreationResult.Insert("ErrorText", "");
	CreationResult.Insert("DirectoryName", "");
	
	Try
		
		TempFileName = GetTempFileName(); 
		PathSeparator = GetPathSeparator();
		ArrayOfDirectoryStrings = StrSplit(TempFileName, PathSeparator); 
		ArrayOfDirectoryStrings.Delete(ArrayOfDirectoryStrings.Count() - 1); 
		DirectoryOfUnzippedFiles = StrConcat(ArrayOfDirectoryStrings, PathSeparator);
		DirectoryOfUnzippedFiles =  DirectoryOfUnzippedFiles + PathSeparator + "DesriptionUpload" + PathSeparator;
		
		If DemoScenariosClientServer.FolderOnDiskExists(DirectoryOfUnzippedFiles) Then
			
			DeleteFiles(DirectoryOfUnzippedFiles);
			
		Else
			
			CreateDirectory(DirectoryOfUnzippedFiles);
			
		EndIf;
		
		CreationResult.DirectoryName = DirectoryOfUnzippedFiles;
		
	Except
		
		CreationResult.Success = False;
		CreationResult.ErrorText = DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
	DeleteFiles(TempFileName);
	Return CreationResult;
	 
EndFunction

// Retrieves HTML text from attached file data
//
// Parameters:
//  FileData - SeeFilesOperations.FileData
//
// Returns:
//  String - 
//
Function HTMLTextBasedOnAttachedFileData(FileData) Export
	
	HTMLText = DemoScenariosClientServer.EmptyHTMLText();
	
	If IsTempStorageURL(FileData.RefToBinaryFileData) Then
		
		FileBinaryData = GetFromTempStorage(FileData.RefToBinaryFileData);
		HTMLText = GetStringFromBinaryData(FileBinaryData, "UTF-8");
		DemoScenariosClientServer.AddBodyTagsIfNecessary(HTMLText);
		
	EndIf;
	
	Return HTMLText;
	
EndFunction

#EndRegion

#Region Private

Function ConfigurationLanguageElementsAreCreated(Form)
	
	Return Form.Items.EditingLanguageSubmenu.ChildItems.Count() > 0;
	
EndFunction

Function TextContentOfHTMLText(HTMLText)
	
	FormattedDocument = New FormattedDocument;
	FormattedDocument.SetHTML(HTMLText, New Structure);
	Return FormattedDocument.GetText();
	
EndFunction

#Region Translation

Function HTMLTextFromHTMLDocumentObject(HTMLDocument)
	Try
		DOMWriter = New DOMWriter;
		HTMLWriter = New HTMLWriter;
		HTMLWriter.SetString();
		DOMWriter.Write(HTMLDocument,HTMLWriter);
		Return HTMLWriter.Close();
	Except
		Return "";
	EndTry;
	
EndFunction

Function MatchingTextsToDocumentNodes(HTMLDocumentBody)
	
	MatchingTextsToDocumentNodes = New Map;
	
	For Each ChildNode In HTMLDocumentBody.ChildNodes Do
		
		ProcessHTMLDocumentNodeDataToGetTextsForTranslation(ChildNode, MatchingTextsToDocumentNodes);
		
	EndDo;
	
	Return MatchingTextsToDocumentNodes;
	 
EndFunction

Procedure ProcessHTMLDocumentNodeDataToGetTextsForTranslation(DocNode, MatchingTextsToDocumentNodes)
	
	If DocNode.NodeType = DOMNodeType.Text Then
		
		If Not IsBlankString(DocNode.NodeValue) Then
			
			AddNodeDataForTranslation(MatchingTextsToDocumentNodes, DocNode);
			
		EndIf;
		
		
	Else 
		
		For Each ChildNode In DocNode.ChildNodes Do
		
			ProcessHTMLDocumentNodeDataToGetTextsForTranslation(ChildNode, MatchingTextsToDocumentNodes);
			
		EndDo;
		
	EndIf;

EndProcedure

Procedure AddNodeDataForTranslation(MatchingTextsToDocumentNodes, DocNode)
	
	TextHash = TextHash(DocNode.NodeValue);
	
	MapItem =  MatchingTextsToDocumentNodes.Get(TextHash);
	If MapItem = Undefined Then
		
		TextData = New Structure;
		TextData.Insert("Text",         DocNode.NodeValue);
		TextData.Insert("DocumentNodes", New Array);
		TextData.DocumentNodes.Add(DocNode);
		
		MatchingTextsToDocumentNodes.Insert(TextHash, TextData); 
		
	Else
		
		MapItem.DocumentNodes.Add(DocNode);
		
	EndIf;
	
EndProcedure


#EndRegion

#Region ReplacementInDemoScenarios

Function ResultOfReplacementInDemoScenarios(ReplacementParameters)

	ReplacementResult = New Structure;
	ReplacementResult.Insert("Success",    False);
	ReplacementResult.Insert("ToProcessing", ReplacementParameters.BudgetingScenarios.Count());
	ReplacementResult.Insert("Processed", 0);
	ReplacementResult.Insert("Errors",     New Array);
	
	For Each ScriptForProcessing In ReplacementParameters.BudgetingScenarios Do
		
		AllFilesHaveBeenProcessedSuccessfully = True;
		
		For Each FileData In ScriptForProcessing.FilesData Do
			
			AttachedFile = FileData.Value.FileRef;
			LanguageCode           = FileData.Value.LanguageCode;
			
			AttachedFileData = FilesOperations.FileData(AttachedFile);
			
			If AttachedFileData.FileBeingEdited Then
				
				ErrorText = StrTemplate(NStr("vi = 'Chưa thực hiện thay thế, kịch bản ""%1"" có mã ngôn ngữ ""%2"" do người sử dụng %3 soạn';
											|ru = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" редактируется пользователем %3';
											|en = 'Replacement is not performed. The %1 scenario with language code %2 is being edited by the %3 user'; fa = 'Replacement is not performed. The %1 scenario with language code %2 is being edited by the %3 user';
											|it = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" редактируется пользователем %3';
											|pl = 'Replacement is not performed. The %1 scenario with language code %2 is being edited by the %3 user';
											|tr = 'Değişim başarısız oldu, ""%2"" dil kodlu ""%1"" senaryosu %3 kullanıcısı tarafından düzenlenmektedir'"),
				                        String(ScriptForProcessing.Scenario), LanguageCode, AttachedFileData.BeingEditedBy);
				DataOfError = ReplacementErrorData(ScriptForProcessing.Scenario, LanguageCode, ErrorText);
				ReplacementResult.Errors.Add(DataOfError);
				AllFilesHaveBeenProcessedSuccessfully = False;
				Continue;
				
			EndIf;
	
			If IsTempStorageURL(AttachedFileData.RefToBinaryFileData) Then
				
				FileBinaryData = GetFromTempStorage(AttachedFileData.RefToBinaryFileData);
				HTMLText = GetStringFromBinaryData(FileBinaryData, "UTF-8");
				PositionsFound = DemoScenariosClientServer.PositionsFoundInText(HTMLText, ReplacementParameters);
				
				If PositionsFound.Count() > 0 Then
					
					ReplaceWhatIsFoundInText(HTMLText, ReplacementParameters, PositionsFound); 
					
				Else
					
					ErrorText = StrTemplate(NStr("vi = 'Chưa thực hiện thay thế, kịch bản ""%1"" với mã ngôn ngữ ""%2"" - chưa tìm thấy gì để thay thế';
												|ru = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" - не найдено что заменять';
												|en = 'Replacement is not performed. The %1 scenario with language code %2: cannot find what to replace'; fa = 'Replacement is not performed. The %1 scenario with language code %2: cannot find what to replace';
												|it = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" - не найдено что заменять';
												|pl = 'Replacement is not performed. The %1 scenario with language code %2: cannot find what to replace';
												|tr = 'Değişim başarısız oldu, ""%2"" dil kodlu ""%1"" senaryosunda değiştirilecek bir şey bulunmadı'"),
					               String(ScriptForProcessing.Scenario), LanguageCode);
					DataOfError = ReplacementErrorData(ScriptForProcessing.Scenario, LanguageCode, ErrorText);
					ReplacementResult.Errors.Add(DataOfError);
					AllFilesHaveBeenProcessedSuccessfully = False;
					Continue;
					
				EndIf;
				
				SavingResult = ResultOfUpdatingAttachedFile(AttachedFile, ReplacementParameters.UUID, HTMLText);
				
				If Not SavingResult Then
					
					ErrorText = StrTemplate(NStr("vi = 'Chưa thực hiện thay thế, kịch bản ""%1"" có mã ngôn ngữ ""%2"" - không thể ghi lại tệp';
												|ru = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" - не удалось записать файл';
												|en = 'Replacement is not performed. The %1 scenario with language code %2: cannot save the file'; fa = 'Replacement is not performed. The %1 scenario with language code %2: cannot save the file';
												|it = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" - не удалось записать файл';
												|pl = 'Replacement is not performed. The %1 scenario with language code %2: cannot save the file';
												|tr = 'Değişim başarısız oldu, ""%2"" dil kodlu ""%1"" senaryosunda dosya kaydedilemedi'"),
					               String(ScriptForProcessing.Scenario), LanguageCode);
					DataOfError = ReplacementErrorData(ScriptForProcessing.Scenario, LanguageCode, ErrorText);
					ReplacementResult.Errors.Add(DataOfError);
					AllFilesHaveBeenProcessedSuccessfully = False;
					Continue;
					
				EndIf;
				
			Else
				
				ErrorText = StrTemplate(NStr("vi = 'Chưa thực hiện thay thế, kịch bản ""%1"" với mã ngôn ngữ ""%2"" - chưa tìm thấy gì để thay thế';
											|ru = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" - не удалось получить данные файла';
											|en = 'Replacement is not performed. The %1 scenario with language code %2: cannot get file data'; fa = 'Replacement is not performed. The %1 scenario with language code %2: cannot get file data';
											|it = 'Замена не выполнена, сценарий ""%1"" с кодом языка ""%2"" - не удалось получить данные файла';
											|pl = 'Replacement is not performed. The %1 scenario with language code %2: cannot get file data';
											|tr = 'Değişim başarısız oldu, ""%2"" dil kodlu ""%1"" senaryosunda dosya verileri alınamadı'"),
				                        String(ScriptForProcessing.Scenario), LanguageCode);
				DataOfError = ReplacementErrorData(ScriptForProcessing.Scenario, LanguageCode, ErrorText);
				ReplacementResult.Errors.Add(DataOfError);
				AllFilesHaveBeenProcessedSuccessfully = False;
				Continue;
				
			EndIf;
			
		EndDo;
		
		If AllFilesHaveBeenProcessedSuccessfully Then
			ReplacementResult.Processed = ReplacementResult.Processed + 1;
		EndIf;
		
	EndDo;
	
	ReplacementResult.Success = True;
	
	Return ReplacementResult;
	
EndFunction

Function ReplacementErrorData(Scenario, LanguageCode, ErrorText)

	ReplacementErrorData = New Structure;
	ReplacementErrorData.Insert("Scenario",    Scenario);
	ReplacementErrorData.Insert("LanguageCode",    LanguageCode);
	ReplacementErrorData.Insert("ErrorText", ErrorText);
	
	Return ReplacementErrorData;
	
EndFunction

Procedure ReplaceWhatIsFoundInText(TextToChange, ReplacementParameters, PositionsFound)
	
	Move                      = 0;
	LengthThatWeChange             = StrLen(ReplacementParameters.WhatWeAreChanging);
	WhatIsLengthWeChangeTo           = StrLen(ReplacementParameters.WhatAreWeChangingTo);
	ShiftChangeAfterReplacement = WhatIsLengthWeChangeTo - LengthThatWeChange;
	LengthOfEntireText           = StrLen(TextToChange);
	
	For Each PositionOfWhatWasFoundInText In PositionsFound Do
		
		TextToChange = Left(TextToChange, PositionOfWhatWasFoundInText + Move -1)
			+ ReplacementParameters.WhatAreWeChangingTo
			+ Right(TextToChange, LengthOfEntireText - PositionOfWhatWasFoundInText - LengthThatWeChange + 1);
			
		Move = Move + ShiftChangeAfterReplacement;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region SearchInDemoScenarios

Function ResultOfGlobalSearchInDemoScenarios(SearchParameters) 
	
	SearchResult = New Structure;
	SearchResult.Insert("Success",               True);
	SearchResult.Insert("UserMessage", "");
	SearchResult.Insert("Results",            New Array);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DemoScenariosAttachedFiles.Ref AS AttachedFile,
	|	DemoScenarios.Ref                    AS Scenario
	|FROM
	|	Catalog.DemoScenariosAttachedFiles AS DemoScenariosAttachedFiles
	|		INNER JOIN Catalog.DemoScenarios AS DemoScenarios
	|		ON DemoScenariosAttachedFiles.FileOwner = DemoScenarios.Ref
	|WHERE
	|	NOT DemoScenarios.DeletionMark
	|	AND NOT DemoScenariosAttachedFiles.DeletionMark
	|TOTALS BY
	|	Scenario";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return SearchResult;
	EndIf;
	
	SampleScenarios = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SampleScenarios.Next() Do
		
		ItemFound = Undefined;
		
		SamplingFiles = SampleScenarios.Select();
		
		While SamplingFiles.Next() Do
			
			AttachedFileData = FilesOperations.FileData(SamplingFiles.AttachedFile);
			
			If IsTempStorageURL(AttachedFileData.RefToBinaryFileData) Then
				
				FileBinaryData = GetFromTempStorage(AttachedFileData.RefToBinaryFileData);
				HTMLText = GetStringFromBinaryData(FileBinaryData, "UTF-8");
				PositionsFound = DemoScenariosClientServer.PositionsFoundInText(HTMLText, SearchParameters);
				
				If PositionsFound.Count() > 0 Then
					
					If ItemFound = Undefined Then
						ItemFound = New Structure;
						ItemFound.Insert("Scenario", SampleScenarios.Scenario);
						ItemFound.Insert("OccurrencesCount", 0);
						ItemFound.Insert("FilesData", New Array);
					EndIf;
					
					ItemFound.OccurrencesCount = ItemFound.OccurrencesCount + PositionsFound.Count();
					ItemFound.FilesData.Add(DataOfFoundFileToReplace(AttachedFileData));
					
				EndIf;
					
			EndIf;
			
		EndDo;
		
		If ItemFound <> Undefined Then
			
			SearchResult.Results.Add(ItemFound);
			
		EndIf;
		
	EndDo;
	
	Return SearchResult;
	
EndFunction

Function DataOfFoundFileToReplace(AttachedFileData)
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("FileRef", AttachedFileData.Ref);
	ReturnStructure.Insert("LanguageCode", DemoScenariosClientServer.LanguageCodeFromFileName(AttachedFileData.Description));
	
	Return ReturnStructure;
	
EndFunction

#EndRegion 

#Region TranslationOfDemoScripts

Function TranslationResultsInDemoScenarios(ParametersOfTranslation)
	
	Result = New Structure;
	Result.Insert("TotalObjectCount", 0);
	Result.Insert("Translated",    0);
	Result.Insert("Errors",        New Array);
	
	Query = New Query;
	Query.Text = QueryTextTranslationOfDemoScripts();
	
	Query.SetParameter("BudgetingScenarios", ParametersOfTranslation.TranslatedScripts);
	Query.SetParameter("LanguageCodes", LanguageCodesTranslationParameters(ParametersOfTranslation));
	
	QueryResult = Query.Execute();

	SampleScenarios = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SampleScenarios.Next() Do
		
		Result.TotalObjectCount = Result.TotalObjectCount + 1; 
		
		ScriptTranslationParameters = NewScriptTranslationOptions(ParametersOfTranslation);
		ScriptTranslationParameters.Scenario = SampleScenarios.Scenario;
		
		SelectionAttachedFiles = SampleScenarios.Select();
		
		While SelectionAttachedFiles.Next() Do 
			
			If SelectionAttachedFiles.LanguageCode = ScriptTranslationParameters.SourceLanguage Then
				
				ScriptTranslationParameters.SourceLanguageFile = SelectionAttachedFiles.AttachedFile;
				
			ElsIf SelectionAttachedFiles.LanguageCode = ScriptTranslationParameters.TargetLanguage Then 
				
				ScriptTranslationParameters.TargetLanguageFile = SelectionAttachedFiles.AttachedFile;
				
			EndIf;
			
		EndDo;
		
		TranslateScript(ScriptTranslationParameters, Result);
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure TranslateScript(ScriptTranslationParameters, Result)
	
	HTMLSourceText   = "";
	SourceFileData = Undefined;
	TargetFileData  = Undefined;
	
	ErrorTemplateNothingToTranslate  = NStr("vi = 'Chưa tìm thấy nội dung để dịch từ ngôn ngữ ""%1"" trong kịch bản ""%2""';
											|ru = 'Текст для перевода с языка ""%1"" в сценарии ""%2"" не найден';
											|en = 'The text to translate from the %1 language is not found in the %2 scenario'; fa = 'The text to translate from the %1 language is not found in the %2 scenario';
											|it = 'Текст для перевода с языка ""%1"" в сценарии ""%2"" не найден';
											|pl = 'The text to translate from the %1 language is not found in the %2 scenario';
											|tr = '""%2"" senaryosunda ""%1"" dilinden çevrilecek metin bulunamadı'");
	TranslationErrorTemplateExists = NStr("vi = 'Đối với ngôn ngữ ""%1"" kịch bản ""%2"" đã có bản dịch, còn chưa đặt dấu hộp kiểm ""Ghi đè bản dịch""';
											|ru = 'Для языка ""%1"" сценария ""%2"" уже есть перевод, а флаг ""Перезаписывать переводы"" установлен не был';
											|en = 'Translation already exists for the %1 language of the %2 scenario, and the ""Overwrite translations"" check box is not selected'; fa = 'Translation already exists for the %1 language of the %2 scenario, and the ""Overwrite translations"" check box is not selected';
											|it = 'Для языка ""%1"" сценария ""%2"" уже есть перевод, а флаг ""Перезаписывать переводы"" установлен не был';
											|pl = 'Translation already exists for the %1 language of the %2 scenario, and the ""Overwrite translations"" check box is not selected';
											|tr = '""%2"" senaryosunun ""%1"" dili için zaten çeviri mevcut fakat ""Çevirilerin üzerine yaz"" işareti yapılandırılmadı'");
	ErrorTemplateTranslationFailed = NStr("vi = 'Chưa thực hiện dịch đối với kịch bản ""%1"" theo nguyên nhân %2';
											|ru = 'Перевод для сценария ""%1"" не выполнен по причине %2';
											|en = 'The %1 scenario is not translated due to %2'; fa = 'The %1 scenario is not translated due to %2';
											|it = 'Перевод для сценария ""%1"" не выполнен по причине %2';
											|pl = 'The %1 scenario is not translated due to %2';
											|tr = '""%1"" senaryosu için %2 nedeniyle çeviri gerçekleştirilemedi'");
	ErrorTemplateCouldNotBeRecorded = NStr("vi = 'Không thể ghi lại kịch bản ""%1"" sau khi dịch';
											|ru = 'Не удалось записать сценарий ""%1"" после перевода';
											|en = 'Cannot save the %1 scenario after translation'; fa = 'Cannot save the %1 scenario after translation';
											|it = 'Не удалось записать сценарий ""%1"" после перевода';
											|pl = 'Cannot save the %1 scenario after translation';
											|tr = 'Çeviriden sonra ""%1"" senaryosu kaydedilemedi'");
	ErrorTemplateCouldNotBeCreated  = NStr("vi = 'Không thể ghi lại các kịch bản ""%1"" sau khi dịch theo nguyên nhân ""%2""';
											|ru = 'Не удалось записать сценарий ""%1"" после перевода по причине ""%2""';
											|en = 'Cannot save the %1 scenario after translation due to %2'; fa = 'Cannot save the %1 scenario after translation due to %2';
											|it = 'Не удалось записать сценарий ""%1"" после перевода по причине ""%2""';
											|pl = 'Cannot save the %1 scenario after translation due to %2';
											|tr = 'Çeviriden sonra ""%1"" senaryosu ""%2"" nedeniyle kaydedilemedi'");
	ErrorPatternFailedStatus   = NStr("vi = 'Không thể cập nhật trạng thái kịch bản ""%1"" sau khi dịch theo nguyên nhân ""%2""';
										|ru = 'Не удалось обновить статус сценария ""%1"" после перевода по причине ""%2""';
										|en = 'Cannot update the %1 scenario status after translation due to %2'; fa = 'Cannot update the %1 scenario status after translation due to %2';
										|it = 'Не удалось обновить статус сценария ""%1"" после перевода по причине ""%2""';
										|pl = 'Cannot update the %1 scenario status after translation due to %2';
										|tr = 'Çeviriden sonra ""%1"" senaryosunun durumu ""%2"" nedeniyle güncellenemedi'");
	ErrorTemplateFileIsBeingEdited = NStr("vi = 'Kịch bản ""%1"" bằng ngôn ngữ ""%2"" bị chiếm để soạn, chưa thực hiện dịch';
											|ru = 'Сценарий ""%1"" на языке ""%2"" захвачен для редактирования, перевод не выполнен';
											|en = 'The %1 scenario in the %2 language is locked for editing. The translation is not performed'; fa = 'The %1 scenario in the %2 language is locked for editing. The translation is not performed';
											|it = 'Сценарий ""%1"" на языке ""%2"" захвачен для редактирования, перевод не выполнен';
											|pl = 'The %1 scenario in the %2 language is locked for editing. The translation is not performed';
											|tr = '""%2"" dilindeki ""%1"" senaryosu düzenleme için ele alındı, çeviri tamamlanmadı'");
	
	If Not ValueIsFilled(ScriptTranslationParameters.SourceLanguageFile) Then
		
		TranslationErrorData = NewTranslationErrorData();
		TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
		TranslationErrorData.LanguageCode    = ScriptTranslationParameters.SourceLanguage;
		TranslationErrorData.ErrorText = StrTemplate(ErrorTemplateNothingToTranslate,
		                                             ScriptTranslationParameters.SourceLanguage,
		                                             ScriptTranslationParameters.Scenario);
		
		Result.Errors.Add(TranslationErrorData);
		
		Return;
		
	EndIf;
	
	SourceFileData = FilesOperations.FileData(ScriptTranslationParameters.SourceLanguageFile);
	
	HTMLSourceText = HTMLTextBasedOnAttachedFileData(SourceFileData);
	TextContentSource = TextContentOfHTMLText(HTMLSourceText);
	
	If IsBlankString(TextContentSource) Then
		
		TranslationErrorData = NewTranslationErrorData();
		TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
		TranslationErrorData.LanguageCode    = ScriptTranslationParameters.SourceLanguage;
		TranslationErrorData.ErrorText = StrTemplate(ErrorTemplateNothingToTranslate,
		                                             ScriptTranslationParameters.SourceLanguage,
		                                             ScriptTranslationParameters.Scenario);
		
		Result.Errors.Add(TranslationErrorData);
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(ScriptTranslationParameters.TargetLanguageFile) Then
		
		TargetFileData = FilesOperations.FileData(ScriptTranslationParameters.TargetLanguageFile);
		
		If Not ScriptTranslationParameters.OverwriteExistingTranslation Then
			
			HTMLTargetText = HTMLTextBasedOnAttachedFileData(TargetFileData);
			TargetTextContent = TextContentOfHTMLText(HTMLTargetText);
			
			If Not IsBlankString(TargetTextContent) Then
				
				TranslationErrorData = NewTranslationErrorData();
				TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
				TranslationErrorData.LanguageCode    = ScriptTranslationParameters.TargetLanguage;
				TranslationErrorData.ErrorText = StrTemplate(TranslationErrorTemplateExists,
				                                             ScriptTranslationParameters.TargetLanguage,
				                                             ScriptTranslationParameters.Scenario);
				
				Result.Errors.Add(TranslationErrorData);
		
				Return;
				
			EndIf;
			
		EndIf;
		
		If TargetFileData.FileBeingEdited Then
			
			TranslationErrorData = NewTranslationErrorData();
			TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
			TranslationErrorData.LanguageCode    = ScriptTranslationParameters.TargetLanguage;
			TranslationErrorData.ErrorText = StrTemplate(ErrorTemplateFileIsBeingEdited,
			                                             ScriptTranslationParameters.Scenario,
			                                             ScriptTranslationParameters.TargetLanguage);
			
			Result.Errors.Add(TranslationErrorData);
	
			Return;
		
		EndIf;
		
	EndIf;
	
	TranslationResult = ResultOfTranslationIntoOtherLanguages(HTMLSourceText, ScriptTranslationParameters.SourceLanguage, ScriptTranslationParameters.TargetLanguage);
	
	If Not TranslationResult.Success Then
		
		TranslationErrorData = NewTranslationErrorData();
		TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
		TranslationErrorData.LanguageCode    = ScriptTranslationParameters.TargetLanguage;
		TranslationErrorData.ErrorText = StrTemplate(ErrorTemplateTranslationFailed,
		                                             ScriptTranslationParameters.Scenario,
		                                             TranslationResult.UserMessage);
		
		Result.Errors.Add(TranslationErrorData);

		Return;
		
	EndIf;
	
	If ValueIsFilled(ScriptTranslationParameters.TargetLanguageFile) Then
		
		SavingResult = ResultOfUpdatingAttachedFile(
				ScriptTranslationParameters.TargetLanguageFile,
				ScriptTranslationParameters.UUID, 
				TranslationResult.TextIsTranslated);
				
		If Not SavingResult Then
			
			TranslationErrorData = NewTranslationErrorData();
			TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
			TranslationErrorData.LanguageCode    = ScriptTranslationParameters.TargetLanguage;
			TranslationErrorData.ErrorText = StrTemplate(ErrorTemplateCouldNotBeRecorded,
			                                             ScriptTranslationParameters.Scenario);
			
			Result.Errors.Add(TranslationErrorData);
			
			Return;
			
		EndIf;
		
		Result.Translated = Result.Translated + 1;
		
	Else
		
		    CreationResult = ResultOfCreatingNewAttachedScriptFile(
			TranslationResult.TextIsTranslated,
			ScriptTranslationParameters.UUID,
			ScriptTranslationParameters.Scenario,
			ScriptTranslationParameters.TargetLanguage);
			
			If Not CreationResult.Success Then
				
				TranslationErrorData = NewTranslationErrorData();
				TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
				TranslationErrorData.LanguageCode    = ScriptTranslationParameters.TargetLanguage;
				TranslationErrorData.ErrorText = StrTemplate(ErrorTemplateCouldNotBeCreated,
				                                             ScriptTranslationParameters.Scenario,
				                                             CreationResult.ErrorText);
				
				Result.Errors.Add(TranslationErrorData);
				
			EndIf;
			
			Result.Translated = Result.Translated + 1;
		
	EndIf;
		
	If ScriptTranslationParameters.ToSetStatus Then
		
		Try
	
			Block = New DataLock;
			LockItem = Block.Add(ScriptTranslationParameters.Scenario.Metadata().FullName());
			LockItem.SetValue("Ref", ScriptTranslationParameters.Scenario.Ref);
			Block.Lock();
			
			ScenarioObject = ScriptTranslationParameters.Scenario.GetObject();
			ScenarioObject.Status = ScriptTranslationParameters.SetStatus_;
			
			ScenarioObject.Write();
			
		Except
			
			TranslationErrorData = NewTranslationErrorData();
			TranslationErrorData.Scenario    = ScriptTranslationParameters.Scenario;
			TranslationErrorData.LanguageCode    = ScriptTranslationParameters.TargetLanguage;
			TranslationErrorData.ErrorText = StrTemplate(ErrorPatternFailedStatus,
			                                             ScriptTranslationParameters.Scenario,
			                                             BriefErrorDescription(ErrorInfo()));
			
			Result.Errors.Add(TranslationErrorData)
		
		EndTry;
		
	EndIf;
	
EndProcedure

Function ResultOfCreatingNewAttachedScriptFile(ScenarioText, UUID, Scenario, LanguageCode)
	
	Result = New Structure;
	Result.Insert("Success",       False);
	Result.Insert("ErrorText",   "");
	
	ScenarioObject = Scenario.GetObject();
	
	FileBinaryData = GetBinaryDataFromString(ScenarioText);
	AddressInTempStorage = PutToTempStorage(FileBinaryData, UUID);
	
	FileRecordingOptions = FilesOperations.FileAddingOptions(); 
	FileRecordingOptions.FilesOwner              = Scenario;
	FileRecordingOptions.BaseName            = StrTemplate("%1_%2_%3", "DescriptionOfScenario_" ,
	                                                             DemoScenariosClientServer.FullLineCodeForFileName(ScenarioObject.FullCode), 
	                                                             LanguageCode);
	FileRecordingOptions.ExtensionWithoutPoint          = "HTML";
	FileRecordingOptions.ModificationTimeUniversal = Undefined;
	
	BeginTransaction();
	
	Try
	
		Block = New DataLock;
		LockItem = Block.Add(ScenarioObject.Ref.Metadata().FullName());
		LockItem.SetValue("Ref", ScenarioObject.Ref);
		Block.Lock();
	
		CreatedAttachedFile = FilesOperations.AppendFile(
		                                    FileRecordingOptions,
		                                    AddressInTempStorage,
		                                    "");
		
		NewRow = ScenarioObject.ScenarioDescriptions.Add();
		NewRow.LanguageCode           = LanguageCode;
		NewRow.AttachedFile = CreatedAttachedFile;
		
		ScenarioObject.Write();
		
		Result.Success = True;
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Result.ErrorText = BriefErrorDescription(ErrorInfo());
		
	EndTry;
	
	Return Result;	
	
EndFunction

Function NewTranslationErrorData()
	
	DataOfError = New Structure;
	DataOfError.Insert("Scenario", Undefined);
	DataOfError.Insert("LanguageCode", "");
	DataOfError.Insert("ErrorText", "");
	
	Return DataOfError;
	
EndFunction

Function NewScriptTranslationOptions(ParametersOfTranslation)
	
	Parameters = New Structure;
	
	Parameters.Insert("Scenario",                          Undefined);
	Parameters.Insert("OverwriteExistingTranslation", ParametersOfTranslation.OverwriteExistingTranslation);
	Parameters.Insert("ToSetStatus",               ParametersOfTranslation.ToSetStatus);
	Parameters.Insert("SetStatus_",             ParametersOfTranslation.SetStatus_);
	Parameters.Insert("SourceLanguage",                      ParametersOfTranslation.SourceLanguage);
	Parameters.Insert("TargetLanguage",                       ParametersOfTranslation.TargetLanguage);
	Parameters.Insert("UUID",           ParametersOfTranslation.UUID);
	Parameters.Insert("SourceLanguageFile",                  Undefined);
	Parameters.Insert("TargetLanguageFile",                   Undefined);
	
	Return Parameters;
	
EndFunction

Function QueryTextTranslationOfDemoScripts()
	
	Return "
	|SELECT
	|	DemoScenariosScenarioDescriptions.LanguageCode           AS LanguageCode,
	|	DemoScenariosScenarioDescriptions.Ref             AS Scenario,
	|	DemoScenariosScenarioDescriptions.AttachedFile AS AttachedFile
	|FROM
	|	Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
	|WHERE
	|	DemoScenariosScenarioDescriptions.Ref IN(&BudgetingScenarios)
	|	AND DemoScenariosScenarioDescriptions.LanguageCode IN(&LanguageCodes)
	|TOTALS BY
	|	Scenario";
	
EndFunction

Function LanguageCodesTranslationParameters(ParametersOfTranslation) 

	LanguagesCodes = New Array;
	
	LanguagesCodes.Add(ParametersOfTranslation.SourceLanguage);
	LanguagesCodes.Add(ParametersOfTranslation.TargetLanguage); 
	
	Return LanguagesCodes;
	
EndFunction

#EndRegion

#Region SettingUpForSupport

Procedure CompleteStatementForSupport(ResultOfStatement, Vendor)
	
	Query = New Query;
	Query.Text = QueryTextSettingUpForSupport();
	
	QueryResult = Query.ExecuteBatch();
	
	BeginTransaction();
	
	Try
	
		PutOnProcessDescriptionSupport(QueryResult[0]);
		PutGlossaryOnSupport(QueryResult[1]);
		
		SetProcessDescriptionConstantOnSupport(PresentationCurVersionOfConfiguration(), Vendor);
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Mô tả các quy trình';
				|ru = 'Описания процессов';
				|en = 'Process details'; fa = 'جزئیات فرایند';
				|it = 'Описания процессов';
				|pl = 'Process details';
				|tr = 'Süreç açıklamaları'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Catalogs.Users,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		ResultOfStatement.Success = False;
		
		ErrorMessageText = StrTemplate(NStr("vi = 'Chưa đặt mô tả quy trình hỗ trợ, do nguyên nhân %1';
											|ru = 'Постановка описаний процессов на поддержку не выполнена, по причине %1';
											|en = 'Support is not enabled for process details due to %1'; fa = 'Support is not enabled for process details due to %1';
											|it = 'Постановка описаний процессов на поддержку не выполнена, по причине %1';
											|pl = 'Support is not enabled for process details due to %1';
											|tr = '%1 nedeniyle süreç ayrıntıları desteğe gönderilmedi'"), 
		                         ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		ResultOfStatement.ErrorMessage = ErrorMessageText;
		
	EndTry;
	
EndProcedure

Procedure PutGlossaryOnSupport(QueryResult)
	
	SelectionLinkGlossary = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionLinkGlossary.Next() Do
		
		Data_To_Change = New Array;
		
		GlossaryAttributes = NewAttributeDataGlossary();
		GlossaryAttributes.Ref = SelectionLinkGlossary.LinkToCatalogGlossary;
		FillPropertyValues(GlossaryAttributes, SelectionLinkGlossary, , "ConfigurationObjects");
		GlossaryAttributes.ConfigurationObjects = SelectionLinkGlossary.ConfigurationObjects.Unload();
		
		JSONTextAttributesOfGlossary = TextOfGlossarySJSONAttributes(GlossaryAttributes);
		HashAttributesOfGlossary = TextHash(JSONTextAttributesOfGlossary);
		
		If HashAttributesOfGlossary <> SelectionLinkGlossary.HashOfSupplierDataAttributesOfGlossary Then
			
			Attributes_To_Change = NewDataToChangeDeliveryToSupport();
			Attributes_To_Change.HashDataType = "Ref";
			Attributes_To_Change.HashValue  = HashAttributesOfGlossary;
			
			Data_To_Change.Add(Attributes_To_Change);
			
		EndIf;
		
		SelectingDescriptionInLanguage = SelectionLinkGlossary.Select();
		
		While SelectingDescriptionInLanguage.Next() Do
			
			HTMLText = "";
			Attachments = New Structure;
			FormattedDescriptionDocument = SelectingDescriptionInLanguage.LongDesc.Get();
			FormattedDescriptionDocument.GetHTML(HTMLText, Attachments);
			
			HTMLDescriptionText = HTMLText;
			
			HashDescriptionsInLanguage = TextHash(HTMLDescriptionText);
			
			If HashDescriptionsInLanguage <> SelectingDescriptionInLanguage.HashOfDataOfGlossaryDescriptionProviderInLanguage Then
				
				Attributes_To_Change = NewDataToChangeDeliveryToSupport();
				Attributes_To_Change.HashDataType = SelectingDescriptionInLanguage.LanguageCode;
				Attributes_To_Change.HashValue  = HashDescriptionsInLanguage;
				
				Data_To_Change.Add(Attributes_To_Change);
				
			EndIf;
		
		EndDo;
		
		If Data_To_Change.Count() > 0 Then
			
			UpdateHashesInCatalogs(Data_To_Change, GlossaryAttributes.Ref, "GlossaryDetails");
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure PutOnProcessDescriptionSupport(QueryResult)
	
	SelectionLinkDescriptionOfProcesses = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionLinkDescriptionOfProcesses.Next() Do
		
		Data_To_Change = New Array;
		
		DescriptionAttributesData = NewAttributeDataDescriptionOfProcesses();
		
		FillPropertyValues(DescriptionAttributesData, SelectionLinkDescriptionOfProcesses, , "AccessGroupProfiles, ConfigurationObjects");
		
		DescriptionAttributesData.Ref              = SelectionLinkDescriptionOfProcesses.LinkDescriptionOfProcesses;
		DescriptionAttributesData.AccessGroupProfiles = SelectionLinkDescriptionOfProcesses.AccessGroupProfiles.Unload();
		DescriptionAttributesData.ConfigurationObjects = SelectionLinkDescriptionOfProcesses.ConfigurationObjects.Unload();
		
		JSONTextAttributesDescriptionOfProcesses = JSONTextAttributesDescriptionOfProcesses(DescriptionAttributesData); 
		
		HashAttributesOfDescription = TextHash(JSONTextAttributesDescriptionOfProcesses);
		
		If HashAttributesOfDescription <> SelectionLinkDescriptionOfProcesses.HashOfSupplierDataAttributesOfCatalog Then
			
			Attributes_To_Change = NewDataToChangeDeliveryToSupport();
			Attributes_To_Change.HashDataType = "Ref";
			Attributes_To_Change.HashValue  = HashAttributesOfDescription;
			
			Data_To_Change.Add(Attributes_To_Change);
			
		EndIf;
		
		SelectingDescriptionInLanguage = SelectionLinkDescriptionOfProcesses.Select();
		
		While SelectingDescriptionInLanguage.Next() Do
			
			If ValueIsFilled(SelectingDescriptionInLanguage.AttachedFile) Then
			
				FileData = FilesOperations.FileData(SelectingDescriptionInLanguage.AttachedFile);
				HTMLDescriptionText = HTMLTextBasedOnAttachedFileData(FileData); 
				HashDescriptionsInLanguage = TextHash(HTMLDescriptionText);
				
				If HashDescriptionsInLanguage <> SelectingDescriptionInLanguage.HashOfProviderSDataDescriptionInLanguage Then
					
					Attributes_To_Change = NewDataToChangeDeliveryToSupport();
					Attributes_To_Change.HashDataType = SelectingDescriptionInLanguage.LanguageCode;
					Attributes_To_Change.HashValue  = HashDescriptionsInLanguage;
					
					Data_To_Change.Add(Attributes_To_Change);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		If Data_To_Change.Count() > 0 Then
			
			UpdateHashesInCatalogs(Data_To_Change, DescriptionAttributesData.Ref, "ScenarioDescriptions");
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateHashesInCatalogs(Data_To_Change, LinkToCatalog, TabularSectionName)
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(LinkToCatalog.Metadata().FullName());
		LockItem.SetValue("Ref", LinkToCatalog);
		Block.Lock();
		
		CatalogObject = LinkToCatalog.GetObject();
		
		For Each DataOfHashBeingModified In Data_To_Change Do
			
			If DataOfHashBeingModified.HashDataType = "Ref" Then
				
				CatalogObject.VendorDataHash = DataOfHashBeingModified.HashValue;
				
			Else
				
				SearchParameters = New Structure;
				SearchParameters.Insert("LanguageCode", DataOfHashBeingModified.HashDataType);
				
				FoundRows = CatalogObject[TabularSectionName].FindRows(SearchParameters);
				
				For Each FoundRow In FoundRows Do
					
					FoundRow.VendorDataHash = DataOfHashBeingModified.HashValue;
					
				EndDo;
				
			EndIf;
			
		EndDo; 
		
		CatalogObject.Write();
		
	Except
		
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
	EndTry;
	
EndProcedure

Function NewDataToChangeDeliveryToSupport()
	
	Data_To_Change = New Structure;
	
	Data_To_Change.Insert("HashDataType", "");
	Data_To_Change.Insert("HashValue", Common.TypeDescriptionNumber(10));
	
	Return Data_To_Change;
	
EndFunction

Function QueryTextSettingUpForSupport()
	
	Return "
	|SELECT
	|	DemoScenariosScenarioDescriptions.LanguageCode            AS LanguageCode,
	|	DemoScenariosScenarioDescriptions.AttachedFile  AS AttachedFile,
	|	DemoScenariosScenarioDescriptions.VendorDataHash AS HashOfProviderSDataDescriptionInLanguage,
	|	DemoScenarios.Ref                              AS LinkDescriptionOfProcesses,
	|	DemoScenarios.VendorDataHash                 AS HashOfSupplierDataAttributesOfCatalog,
	|	DemoScenarios.DeletionMark                     AS DeletionMark,
	|	DemoScenarios.Parent                            AS Parent,
	|	DemoScenarios.IsFolder                           AS IsFolder,
	|	DemoScenarios.Code                                 AS Code,
	|	DemoScenarios.Description                        AS Description,
	|	DemoScenarios.FullCode                           AS FullCode,
	|	DemoScenarios.Status                              AS Status,
	|	DemoScenarios.Comment                         AS Comment,
	|	DemoScenarios.GroupType                           AS GroupType,
	|	DemoScenarios.DescriptionLanguage1                   AS DescriptionLanguage1,
	|	DemoScenarios.DescriptionLanguage2                   AS DescriptionLanguage2,
	|	DemoScenarios.AccessGroupProfiles.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Profile AS Profile
	|	)                                                            AS AccessGroupProfiles,
	|	DemoScenarios.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject                                      AS ConfigurationObject
	|	) AS ConfigurationObjects
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios 
	|		LEFT JOIN Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
	|		ON DemoScenariosScenarioDescriptions.Ref = DemoScenarios.Ref
	|TOTALS BY
	|	LinkDescriptionOfProcesses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GlossaryGlossaryDetails.LanguageCode            AS LanguageCode,
	|	GlossaryGlossaryDetails.LongDesc            AS LongDesc,
	|	GlossaryGlossaryDetails.VendorDataHash AS HashOfDataOfGlossaryDescriptionProviderInLanguage,
	|	Glossary.Ref                               AS LinkToCatalogGlossary,
	|	Glossary.VendorDataHash                  AS HashOfSupplierDataAttributesOfGlossary,
	|	Glossary.DeletionMark                      AS DeletionMark,
	|	Glossary.Code AS                              Code,
	|	Glossary.Description                         AS Description,
	|	Glossary.DescriptionLanguage1                    AS DescriptionLanguage1,
	|	Glossary.DescriptionLanguage2                    AS DescriptionLanguage2,
	|	Glossary.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	)                                              AS ConfigurationObjects
	|FROM
	|	Catalog.Glossary AS Glossary 
	|		LEFT JOIN Catalog.Glossary.GlossaryDetails AS GlossaryGlossaryDetails
	|		ON GlossaryGlossaryDetails.Ref = Glossary.Ref
	|TOTALS BY
	|	LinkToCatalogGlossary";
	
	
EndFunction 

#EndRegion

#EndRegion
