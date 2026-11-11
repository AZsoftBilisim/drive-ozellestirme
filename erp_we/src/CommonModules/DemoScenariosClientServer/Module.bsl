#Region Public

// Reflects the Cur Status on the Form of the demo script
//
// Parameters:
//  Form - ClientApplicationForm - The Form for which the Status is displayed
//
Procedure ReflectCurStatusOnForm(Form) Export
	
	Items = Form.Items;
	
	Items.FormSetStatus_InProgress.Check       = (Form.Object.Status = PredefinedValue("Enum.ProcessDetailsStatuses.InProgress"));
	Items.FormSetStatusForVerification.Check    = (Form.Object.Status = PredefinedValue("Enum.ProcessDetailsStatuses.OnValidation"));
	Items.FormSetStatusThereAreComments.Check = (Form.Object.Status = PredefinedValue("Enum.ProcessDetailsStatuses.RemarksFound"));
	Items.FormSetStatus_Checked.Check     = (Form.Object.Status = PredefinedValue("Enum.ProcessDetailsStatuses.Checked"));
	
	If Not ValueIsFilled(Form.Object.Status) Then
		SubmenuTitle = NStr("vi = 'Chưa chỉ ra trạng thái';
							|ru = 'Статус не указан';
							|en = 'Status is not specified'; fa = 'Status is not specified';
							|it = 'Статус не указан';
							|pl = 'Status is not specified';
							|tr = 'Durum belirtilmedi'");
	Else
		SubmenuTitle = String(Form.Object.Status);
	EndIf; 
	
	Items.StatusSubmenu.Title = SubmenuTitle;
	
EndProcedure

// Gets the language code from the Command name
//
// Parameters:
//  CommandName - String - the name of the Command from which the language code is derived
//  CommandPrefix - String - Command name without language code
//  
//  Returns:
//    String - the language code derived from the Command name
//
Function LanguageCodeFromCommandName(CommandName, CommandPrefix) Export

	Return Right(CommandName, StrLen(CommandName) - StrLen(CommandPrefix)); 

EndFunction

// Gets the language code from the name of the attached file
//
// Parameters:
//  FileName - String - the name of the file from which the language code is derived
//  
//  Returns:
//    String - the language code derived from the file name
//
Function LanguageCodeFromFileName(FileName) Export
	
	LanguageCode = "";
	
	SeparatorLocation = StrFind(FileName, "_", SearchDirection.FromEnd);
	
	If SeparatorLocation <> 0 Then
		
		LanguageCode = Right(FileName, StrLen(FileName) - SeparatorLocation);
		
	EndIf;
	
	Return LanguageCode;
	
EndFunction

// Reflects the Cur languages in the Form of a demo script
//
// Parameters:
//  Form - ClientApplicationForm  - The Form for which languages are displayed
//  AttributeNameLanguageCodeReading          - String - the name of the Form Attribute that contains the viewing language code
//  AttributeNameLanguageCodeEditing  - String - the name of the Form Attribute that contains the editing language code
//
Procedure ReflectCurLanguagesOnForm(Form, AttributeNameLanguageCodeReading, AttributeNameLanguageCodeEditing) Export
	
	ReflectLanguageInSubmenu(Form, AttributeNameLanguageCodeEditing, "EditingLanguageSubmenu", "SwitchToEditingLanguage_");
	ReflectLanguageInSubmenu(Form, AttributeNameLanguageCodeReading, "SubmenuViewingLanguage", "SwitchToViewingLanguage_");
	
EndProcedure 

// Generates the title of the translation Command on the Form
//
// Parameters:
//  SourceLanguage - String - the language the translation is being made from
//  TranslationLanguage - String - the language the translation is being translated into
//  FormItem - FormButton - translation Commands button
//
Procedure GenerateTitleOfTranslationCommands(SourceLanguage, TranslationLanguage, FormItem) Export
	
	FormItem.Title = StrTemplate("%1 -> %2", SourceLanguage, TranslationLanguage);
	FormItem.Enabled =  ValueIsFilled(SourceLanguage)
	                            And ValueIsFilled(TranslationLanguage)
	                            And (SourceLanguage <> TranslationLanguage);
	
EndProcedure

// Sets the flag for the Cur of the Form display option in the submenu
//
// Parameters:
//  Form - ClientApplicationForm - Form, where flag is set
//
Procedure MarkCommandsForSwitchingFormDisplayOption(Form) Export
	
	Items                = Form.Items;
	FormDisplayOption = Form.FormDisplayOption;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormSetViewMode", "Check", FormDisplayOption = "View");
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormSetEditingMode", "Check", FormDisplayOption = "Edit");
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormSetTranslationOption", "Check", FormDisplayOption = "Translation");
	
EndProcedure

// Constructor of parameters for switching the Form display options
//
// Returns:
//   Structure   - Contains:
//    *Form                          - ClientApplicationForm, Undefined - The Form in which the switch is performed
//    *NewOption                   - String - the option to switch to
//    *LastOption                 - String - previous display option
//    *AttributeNameLanguageReading         - String - the name of the Form Attribute where the view text is located
//    *AttributeNameLanguageEditing - String - the name of the Form Attribute where the editing text is located
//    *LanguageSwitchingCompleted     - Boolean - indicates that when switching the Form mode, the language was also switched
//    *AttributeNameLanguageSwitched     - String - the name of the text Form Attribute for which the language was switched
//    *SwitchedToLanguage              - String - the code of the language to which the switch was made
//    *ConfigurationLanguages              - ValueList of String - cached configuration languages
//
Function NewDisplayOptionSwitchingOptions() Export
	
	SwitchingParameters = New Structure;
	
	SwitchingParameters.Insert("Form",                          Undefined);
	SwitchingParameters.Insert("NewOption",                   "");
	SwitchingParameters.Insert("LastOption",                 "");
	SwitchingParameters.Insert("AttributeNameLanguageReading",         "");
	SwitchingParameters.Insert("AttributeNameLanguageEditing", "");
	SwitchingParameters.Insert("LanguageSwitchingCompleted",     False);
	SwitchingParameters.Insert("AttributeNameLanguageSwitched",     "");
	SwitchingParameters.Insert("SwitchedToLanguage",              "");
	SwitchingParameters.Insert("ConfigurationLanguages",              New ValueList);
	
	Return SwitchingParameters;
	
EndFunction

// Toggles the display option in the Form
//
// Parameters:
//  SwitchingParameters -  See NewDisplayOptionSwitchingOptions 
//
Procedure SwitchDisplayOption(SwitchingParameters) Export

	If Not ValueIsFilled(SwitchingParameters.NewOption) Then
		SwitchingParameters.NewOption = "View";
	EndIf;
	
	SwitchingParameters.LastOption = SwitchingParameters.Form.FormDisplayOption;
	SwitchingParameters.Form.FormDisplayOption = SwitchingParameters.NewOption;
	
	If SwitchingParameters.NewOption = "Edit" Then 
		
		SwitchingParameters.Form.Items.SubmenuViewEditMode.Title = NStr("vi = 'Soạn';
																		|ru = 'Редактирование';
																		|en = 'Edit'; fa = 'ویرایش';
																		|it = 'Редактирование';
																		|pl = 'Edit';
																		|tr = 'Düzenleme'");
		
	ElsIf SwitchingParameters.NewOption = "View" Then
		
		SwitchingParameters.Form.Items.SubmenuViewEditMode.Title = NStr("vi = 'Xem';
																		|ru = 'Просмотр';
																		|en = 'View'; fa = 'مشاهده';
																		|it = 'Просмотр';
																		|pl = 'View';
																		|tr = 'Görüntüleme'");
		
	ElsIf SwitchingParameters.NewOption = "Translation" Then
		
		SwitchingParameters.Form.Items.SubmenuViewEditMode.Title = NStr("vi = 'Dịch';
																		|ru = 'Перевод';
																		|en = 'Translate'; fa = 'ترجمه';
																		|it = 'Перевод';
																		|pl = 'Translate';
																		|tr = 'Çeviri'");
		
	EndIf;
	
	ChangeLanguagesAfterChangingDisplayOption(SwitchingParameters);
	
	DemoScenariosServerCall.SaveFormDisplayModeSetting(SwitchingParameters.NewOption);
	
EndProcedure

// Retrieves HTML text from the table part of the Form Attributes by language code
//
// Parameters:
//  Form             - ClientApplicationForm - The Form for which the action is performed
//  LanguageCode          - String - the language code to get the text for
//  TabularSectionName - String - name of the tabular part of the Form
//  AttributeName      - String - the name of the Attribute of the table part
//
// Returns:
//   String   - HTML Text By Language Code
//
Function HTMLTextByLanguageCode(Form, LanguageCode, TabularSectionName, AttributeName) Export
	
	FoundText = "";
	TheStructureOfTheSearch = New Structure("LanguageCode", LanguageCode);
	
	FoundRows = Form[TabularSectionName].FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		FoundText = FoundRows[0][AttributeName];
	EndIf;
	
	If IsBlankString(FoundText) Then
		Return EmptyHTMLText();
	Else
		Return FoundText;
	EndIf;
	
EndFunction

// Retrieves the attached script file by the language code
//
// Parameters:
//  Form    - ClientApplicationForm - The Form for which the action is performed
//  LanguageCode - String - the language code to get the attached file for
//
// Returns:
//   CatalogRef.DemoScenariosAttachedFiles - Attached Script File
//
Function AttachedScriptFile(Form, LanguageCode) Export
	
	AttachedFile = Undefined;
	TheStructureOfTheSearch = New Structure("LanguageCode", LanguageCode);
	
	FoundRows = Form.Object.ScenarioDescriptions.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		AttachedFile =   FoundRows[0].AttachedFile;
	EndIf;
	
	Return AttachedFile;
	
EndFunction

// Checks whether the attached script file has been created
//
// Parameters:
//  Form    - ClientApplicationForm - The Form for which the action is performed
//  LanguageCode - String - the language code for which you want to check the creation of the attached file
//
// Returns:
//   Boolean - True if created, false if not.
//
Function AttachedFileHasBeenCreatedAccordingToScript(Form, LanguageCode) Export 
	
	FileWasCreated = False;
	TheStructureOfTheSearch = New Structure("LanguageCode", LanguageCode); 
	
	FoundRows = Form.ScenarioDescriptions.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		FileWasCreated = ValueIsFilled(FoundRows[0].ModificationDate);
	EndIf;
	
	Return FileWasCreated;
	
EndFunction

// Retrieves script data in the required language
//
// Parameters:
//  Form - ClientApplicationForm - The Form for which the action is performed
//  LanguageCode - String - the language code to get the language data for
//  TabularSectionName - String - the name of the tabular part of the Form Attribute that contains the data
//
// Returns:
//   Structure - Contains:
//    *HTMLText                                         - String - text previously received from the file
//    *CurScriptIsAvailableForEditing          - Boolean - is the file available for editing
//    *CurrentScriptIsBeingEditedByCurrentUser  - Boolean - is the file already being edited by the Cur user
//    *PresentationOfEditingState              - String - used for Form output from editing Commands
//
Function ScriptDataInLanguage(Form, LanguageCode, TabularSectionName) Export
	
	ScriptDataInLanguage = New Structure;
	ScriptDataInLanguage.Insert("HTMLText",                                        "");
	ScriptDataInLanguage.Insert("CurScriptIsAvailableForEditing",         False);
	ScriptDataInLanguage.Insert("CurrentScriptIsBeingEditedByCurrentUser", False);
	ScriptDataInLanguage.Insert("PresentationOfEditingState",             "");
	
	TheStructureOfTheSearch = New Structure("LanguageCode", LanguageCode);
	FoundRows = Form[TabularSectionName].FindRows(TheStructureOfTheSearch);
	
	If FoundRows.Count() > 0 Then
		
		ScriptDataInLanguage.HTMLText = FoundRows[0].HTMLText;
		ScriptDataInLanguage.PresentationOfEditingState = PresentationOfEditingState(Form, FoundRows[0]);
		ScriptDataInLanguage.CurrentScriptIsBeingEditedByCurrentUser = (FoundRows[0].BeingEditedBy = Form.CurrentUser);
		ScriptDataInLanguage.CurScriptIsAvailableForEditing = (Not FoundRows[0].IsBeingEdited) 
		                                                                  Or (FoundRows[0].BeingEditedBy = Form.CurrentUser);
		
	Else
		
		NewRow = Form[TabularSectionName].Add();
		NewRow.LanguageCode  = LanguageCode;
		NewRow.HTMLText = EmptyHTMLText();
		
		ScriptDataInLanguage.HTMLText = NewRow.HTMLText;
		ScriptDataInLanguage.PresentationOfEditingState = PresentationOfEditingState(Form, NewRow);
		ScriptDataInLanguage.CurScriptIsAvailableForEditing = True;
	
	EndIf;
	
	Return ScriptDataInLanguage;
	
	
EndFunction

// Generates empty HTML text
//
// Returns:
//   String - empty HTML text with the necessary tags.
//
Function EmptyHTMLText() Export 

	HTMLText = "";
	AddBodyTagsIfNecessary(HTMLText);
	
	Return HTMLText; 
	
EndFunction 

// Adds HTML document tags to the text if they are missing
//
// Parameters:
//  TextToProcess1 - String - processed text
//
Procedure AddBodyTagsIfNecessary(TextToProcess1) Export
	
	NoBody = (StrOccurrenceCount(Lower(TextToProcess1), "<body") = 0);
	NoHeader = (StrOccurrenceCount(Lower(TextToProcess1), "<html") = 0);
	If NoBody And NoHeader Then
		TextToProcess1 = "<body>" + TextToProcess1 + "</body>"
	EndIf;
	If NoHeader Then
		TextToProcess1 = "<html><meta charset=""""UTF-8"""">" + TextToProcess1 + "</html>"
	EndIf;
	
EndProcedure

// Generates the full text in a string to form the name of the attached file
// 
// Parameters:
//  FullCode - String - full Catalog code
//
// Returns:
//   String - empty HTML text with the necessary tags.
//
Function FullLineCodeForFileName(FullCode) Export

	Return StrReplace(FullCode, ".", "_");

EndFunction

// Returns the name of the script description file
//
// Returns:
//   String - 
//
Function NameOfScriptDescriptionFile(FullCode, LanguageCode) Export
	
	Return StrTemplate("%1_%2_%3",
	                  "DescriptionOfScenario_" ,
	                   FullLineCodeForFileName(FullCode), 
	                   LanguageCode);
	
EndFunction

// Performs a search in the text and returns the position of the found
// 
// Parameters:
//  WhereAreWeLooking          - String - the text in which the search is performed
//  EventParameters - Structure - search event parameters
//
// Returns:
//   Array of Number - positions found in the text.
//
Function PositionsFoundInText(WhereAreWeLooking, EventParameters) Export
	
	PositionsFound = New Array;
	
	WhatAreWeLookingFor          = EventParameters.WhatWeAreChanging;
	StartPosition = 1;
	LengthThatWeAreLookingFor     = StrLen(WhatAreWeLookingFor);
	
	FoundPosition = StrFind(WhereAreWeLooking, WhatAreWeLookingFor, SearchDirection.FromBegin, StartPosition);
	
	While FoundPosition <> 0 Do
		
		MeetsRequirements_ = WhatIsFoundMeetsRequirements(WhereAreWeLooking, WhatAreWeLookingFor,  FoundPosition, EventParameters);
		
		If MeetsRequirements_ Then
			PositionsFound.Add(FoundPosition);
		EndIf;
		
		StartPosition = FoundPosition + LengthThatWeAreLookingFor;
		FoundPosition = StrFind(WhereAreWeLooking, WhatAreWeLookingFor, SearchDirection.FromBegin, StartPosition);
		
	EndDo;
	
	Return PositionsFound;
	
EndFunction

// Retrieves HTML text from a formatted document
// 
// Parameters:
//  FormattedDocument - FormattedDocument - from which the HTML text is extracted
//
// Returns:
//   String - extracted HTML text.
//
Function HTMLTextFromFormattedDocument(FormattedDocument) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("HTML", "");
	ReturnStructure.Insert("Attachments", New Structure);
	
	FormattedDocument.GetHTML(ReturnStructure.HTML, ReturnStructure.Attachments);
	
	Return ReturnStructure;
	
EndFunction

// Retrieves a formatted document from HTML text
// 
// Parameters:
//  HTMLText - String - the HTML text from which the formatted document is formed
//  Attachments  - Structure - images placed in HTML text
//
// Returns:
//   String - extracted HTML text.
//
Function FormattedDocumentFromHTMLData(HTMLText, Attachments) Export
	
	FormattedDocument = New FormattedDocument;
	FormattedDocument.SetHTML(HTMLText, Attachments);
	
	Return FormattedDocument;
	
EndFunction

// Checks whether what is found in the text meets the requirements
// 
// Parameters:
//  WhereAreWeLooking         - String - the text in which the search is performed
//  WhatAreWeLookingFor          - String - the text we are looking for
//  FoundPosition - Number - The Position Of What Was Found In The Text
//  EventParameters - Structure - search parameters
//
// Returns:
//   Boolean - True if it satisfies the condition.
//
Function WhatIsFoundMeetsRequirements(WhereAreWeLooking, WhatAreWeLookingFor, FoundPosition, EventParameters) Export
	
	LengthThatWeAreLookingFor     = StrLen(WhatAreWeLookingFor);
	TextLength      = StrLen(WhereAreWeLooking);
	
	MeetsRequirements_ = True;
	
	If EventParameters.CaseSensitive Then
		
		FoundRow = Mid(WhereAreWeLooking, FoundPosition, LengthThatWeAreLookingFor);
		If FoundRow <> WhatAreWeLookingFor Then
			MeetsRequirements_ = False;
		EndIf;
		
	EndIf;
	
	If EventParameters.SearchForWholeWord
		And MeetsRequirements_ Then
		
		If FoundPosition = 1 Then
			PreviousChar = "";
		Else
			PreviousChar = Mid(WhereAreWeLooking, FoundPosition - 1, 1);
		EndIf;
		
		If ItIsNotExcluded(PreviousChar) Then
			MeetsRequirements_ = False;
		EndIf;
		
		If MeetsRequirements_ Then
			If FoundPosition = TextLength - LengthThatWeAreLookingFor Then
				SubsequentCharacter = "";
			Else
				SubsequentCharacter = Mid(WhereAreWeLooking, FoundPosition + LengthThatWeAreLookingFor, 1);
			EndIf;
			
			If ItIsNotExcluded(SubsequentCharacter) Then
				MeetsRequirements_ = False;
			EndIf;
		EndIf;
		
	EndIf;
	
	If MeetsRequirements_ Then
		MeetsRequirements_ = TextMatchesSearchConditionInHyperlink(
			WhereAreWeLooking, WhatAreWeLookingFor, FoundPosition, EventParameters.HowToSearchInHyperlinks);
	EndIf;
		
	Return MeetsRequirements_;
	
EndFunction

// Returns the text of the message to the user with non-specific parameters for opening the printed Form "Process Album"
//
// Returns:
//   String - Message text
//
Function MessageTextIncorrectProcessAlbumParameters() Export
	
	Return NStr("vi = 'Chưa chọn nhóm kịch bản minh họa để tạo album quy trình';
				|ru = 'Не выбрано ни одной группы демонстрационных сценариев для формирования альбома процессов';
				|en = 'No demo scenario group is selected to generate a process album'; fa = 'No demo scenario group is selected to generate a process album';
				|it = 'Не выбрано ни одной группы демонстрационных сценариев для формирования альбома процессов';
				|pl = 'No demo scenario group is selected to generate a process album';
				|tr = 'Süreç albümü oluşturmak için herhangi bir demo senaryo grubu seçilmedi'");
	
EndFunction

// Converts a unique identifier to a string
// 
// Parameters:
//  UUID - UUID - which will be converted to a string
// 
// Returns:
//   String - 
//
Function UUIDAsString1(UUID) Export
	
	Return StrReplace(String(UUID), "-", "_");
	
EndFunction

// Returns the name of the folder for uploading process descriptions
//
// Returns:
//   String - 
//
Function NameOfProcessDescriptionUploadDirectory() Export
	
	Return "DescriptionOfTheProcess";
	
EndFunction

// Returns the name of the folder for uploading process descriptions
//
// Returns:
//   String - 
//
Function NameOfGlossaryCatalog() Export
	
	Return "Glossary";
	
EndFunction

// Returns the name of the folder where screenshots were uploaded
//
// Returns:
//   String - 
//
Function NameOfUploadFolderScreenshots() Export
	
	Return "ScreenShots";
	
EndFunction

// Returns the name of the upload description file
//
// Returns:
//   String - 
//
Function FileNameUploadDescription() Export
	
	Return "Description.json";
	
EndFunction

// Generates the text of the delivery description
// 
// Parameters:
//  ConfigurationDescription   - String - passed string
//  Vendor              - String - 
//
// Returns:
//   String  -
//
Function DeliveryDescriptionText(ConfigurationDescription, Vendor) Export
	
	Return  StrTemplate(NStr("vi = '%1, nhà cung cấp - %2';
							|ru = '%1, поставщик - %2';
							|en = '%1, vendor - %2'; fa = '%1, vendor - %2';
							|it = '%1, поставщик - %2';
							|pl = '%1, vendor - %2';
							|tr = '%1, tedarikçi; %2'"), ConfigurationDescription, Vendor);
	
EndFunction

// Returns the ID of the external component to get screenshots of
// 
// Returns:
//   String  - 
//
Function IdOfExternalComponentForGettingScreenshots() Export
	
	Return "WindowsControl"; 
	
EndFunction

// Extracts the language code and script ID from the file name
// 
// Parameters:
//  FileName   - String -
//
// Returns:
//   Structure  - Contains:
//     * LanguageCode  - String - indicates whether the operation was successful
//     * Data        - Map -
//
Function LanguageCodeIdFromDescriptionFileName(FileName) Export
	
	FileData = New Structure;
	FileData.Insert("LanguageCode",              Left(FileName, 2));
	FileData.Insert("ScriptID", New UUID(StrReplace(Right(FileName, StrLen(FileName)-3), "_", "-")));
	
	Return FileData;
	
EndFunction

// Retrieves the identifier from the file name containing the Catalog Attributes
// 
// Parameters:
//  FileName   - String -
//
// Returns:
//   UUID - 
//
Function IdFromFileNameAttributes(FileName) Export
	
	Return New UUID(StrReplace(Right(FileName, StrLen(FileName)-11), "_", "-"))
	
EndFunction

// Returns the prefix of the navigation link in the "Demo and Connected Files" Catalog
//
// Returns:
//   UUID - 
//
Function PrefixOfAttachedFileLink() Export
	
	Return "e1cib/data/Catalog.DemoScenariosAttachedFiles?";
	
EndFunction

// Checks if the folder exists on the disk
//
// Parameters:
//  CatalogBeingChecked - String - The Catalog Being Checked
//
// Returns:
//   Boolean - True if the directory exists
//
Function FolderOnDiskExists(CatalogBeingChecked) Export

	DirectoryOnHardDrive = New File(CatalogBeingChecked);
	If DirectoryOnHardDrive.Exists() Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

// Generates the title of the navigator part of the helpers for loading and unloading
//
// Parameters:
//  PartTitle       - String - title of the navigator part
//  NavigationCommand     - String - the Command that will be contained in the hyperlink
//  Enabled          - Boolean - indicates whether the Command is available 
//  IsCurrent           - Boolean - indicates whether the Command is available
//
// Returns:
//   String - generated part of the header
//
Function TitleOfNavigatorPartOfAssistant(PartTitle, NavigationCommand, Enabled, IsCurrent) Export

	If Enabled And Not IsCurrent Then
		
		Return FormattedStringWithHyperlink( PartTitle, NavigationCommand);
		
	ElsIf IsCurrent Then
		
		Return FormattedStringWithHyperlink(PartTitle, "", False, , True);
		
	Else
		
		Return PartTitle;
		
	EndIf;

EndFunction

#EndRegion

#Region Private

Function FormattedStringWithHyperlink(StringText, HyperlinkText, DisplayHyperlink = True, TextColor = Undefined, Fatty = False)
	
	If Fatty Then
		Font = New Font(,,True);
	Else
		Font = Undefined;
	EndIf;
	
	If DisplayHyperlink Then
		
		GeneratedRow =  New FormattedString(StringText,
		                                                    Font,
		                                                    TextColor,
		                                                    ,
		                                                    HyperlinkText);
	Else
		
		GeneratedRow = New FormattedString(StringText, Font, TextColor);
		
	EndIf;

	Return GeneratedRow;
	
EndFunction

Procedure ChangeLanguagesAfterChangingDisplayOption(SwitchingParameters)
	
	If IsBlankString(SwitchingParameters.AttributeNameLanguageReading)
		Or IsBlankString(SwitchingParameters.AttributeNameLanguageEditing) Then
		
		Return;
		
	EndIf;
	
	If SwitchingParameters.LastOption = "Edit" 
		And SwitchingParameters.NewOption = "View" Then 
		
		SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageReading] = 
			SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageEditing];
		SwitchingParameters.LanguageSwitchingCompleted = True;
		SwitchingParameters.AttributeNameLanguageSwitched = SwitchingParameters.AttributeNameLanguageReading;
		SwitchingParameters.SwitchedToLanguage          = SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageEditing];
		
		
	ElsIf SwitchingParameters.LastOption = "View" 
		And SwitchingParameters.NewOption = "Edit" Then 
		
		SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageEditing] =
			SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageReading];
		SwitchingParameters.LanguageSwitchingCompleted = True;
		SwitchingParameters.AttributeNameLanguageSwitched = SwitchingParameters.AttributeNameLanguageEditing;
		SwitchingParameters.SwitchedToLanguage          = SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageReading];
		
	ElsIf SwitchingParameters.NewOption = "Translation"
		And SwitchingParameters.ConfigurationLanguages.Count() = 2 Then
		
		If SwitchingParameters.LastOption = "View" Then
			
			SourceLanguage =  SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageReading];
			TargetLanguage =  SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageEditing];
			SwitchingParameters.AttributeNameLanguageSwitched = SwitchingParameters.AttributeNameLanguageEditing;
			
		ElsIf SwitchingParameters.LastOption = "Edit" Then
			
			SourceLanguage =  SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageEditing];
			TargetLanguage =  SwitchingParameters.Form[SwitchingParameters.AttributeNameLanguageReading];
			SwitchingParameters.AttributeNameLanguageSwitched = SwitchingParameters.AttributeNameLanguageReading;
			
		EndIf;
		
		If SourceLanguage = TargetLanguage Then
			
			ListItem = SwitchingParameters.ConfigurationLanguages.FindByValue(SourceLanguage);
			ElementIndex = SwitchingParameters.ConfigurationLanguages.IndexOf(ListItem); 
			SwitchingParameters.LanguageSwitchingCompleted = True;
			
			If ElementIndex = 0 Then
				SwitchingParameters.SwitchedToLanguage = SwitchingParameters.ConfigurationLanguages[1].Value;
			ElsIf ElementIndex = 1 Then 
				SwitchingParameters.SwitchedToLanguage = SwitchingParameters.ConfigurationLanguages[0].Value;
			EndIf;
			
		EndIf;
		
	EndIf; 
	
EndProcedure

Function PresentationOfEditingState(Form, FileData)
	
	If Not ValueIsFilled(FileData.ModificationDate)
		And Not ValueIsFilled(FileData.ChangedBy) Then
		
		Return "";
		
	EndIf;
	
	TextChanged = StrTemplate(NStr("vi = 'Đã thay đổi %1 (%2)';
									|ru = 'Изменен %1 (%2)';
									|en = 'Changed %1 (%2)'; fa = 'Changed %1 (%2)';
									|it = 'Изменен %1 (%2)';
									|pl = 'Changed %1 (%2)';
									|tr = '%1 değişti (%2)'"), Format(FileData.ModificationDate, "DLF=DT"), String(FileData.ChangedBy));
	TextCaptured = "";
	
	If FileData.IsBeingEdited Then
		
		TextCaptured = StrTemplate(NStr("vi = 'Đang soạn %1, đã chiếm %2';
										|ru = 'Редактируется %1, захвачен %2';
										|en = 'Edited by %1, locked by %2'; fa = 'Edited by %1, locked by %2';
										|it = 'Редактируется %1, захвачен %2';
										|pl = 'Edited by %1, locked by %2';
										|tr = '%1 düzenlenmektedir, %2 alındı'"), FileData.BeingEditedBy, Format(FileData.DateOfCapture, "DLF=DT"));
		
		If Form.CurrentUser <> FileData.BeingEditedBy Then
			ColorCaptured = Form.ColorIsCapturedByAnotherUser;
		Else
			ColorCaptured = Form.ColorIsCapturedByCurUser;
		EndIf;
		
		TextCaptured = New FormattedString(TextCaptured,,ColorCaptured);
		
	EndIf;
	
	Return New FormattedString(TextChanged, ". ", TextCaptured);
	
EndFunction 

Procedure ReflectLanguageInSubmenu(Form, AttributeNameLanguageCode, NameOfSubmenuElement, CommandPrefix)

	Items = Form.Items;
	
	SubmenuTitle = NStr("vi = 'Chưa chọn ngôn ngữ';
						|ru = 'Язык не выбран';
						|en = 'The language is not selected'; fa = 'The language is not selected';
						|it = 'Язык не выбран';
						|pl = 'The language is not selected';
						|tr = 'Dil seçilmedi'"); 
	
	For Each EditingLanguageElement In Form.Items[NameOfSubmenuElement].ChildItems Do
		
		LanguageCode = LanguageCodeFromCommandName(EditingLanguageElement.CommandName, CommandPrefix);
		If LanguageCode = Form[AttributeNameLanguageCode] Then
			EditingLanguageElement.Check = True;
			SubmenuTitle = LanguageCode; 
		Else
			EditingLanguageElement.Check = False;
		EndIf;
		
	EndDo;
	
	Form.Items[NameOfSubmenuElement].Title = SubmenuTitle;

EndProcedure 

Function ItIsNotExcluded(Char)
	
	If StrLen(Char) = 0 Then
		Return True;
	EndIf;
	
	ArrayOfCharactersToExclude = New Array;
	ArrayOfCharactersToExclude.Add(".");
	ArrayOfCharactersToExclude.Add(",");
	ArrayOfCharactersToExclude.Add(" ");
	ArrayOfCharactersToExclude.Add(";");
	ArrayOfCharactersToExclude.Add(":");
	ArrayOfCharactersToExclude.Add(" ");
	ArrayOfCharactersToExclude.Add("]");
	ArrayOfCharactersToExclude.Add("[");
	ArrayOfCharactersToExclude.Add("(");
	ArrayOfCharactersToExclude.Add(")");
	ArrayOfCharactersToExclude.Add("!");
	ArrayOfCharactersToExclude.Add("@");
	ArrayOfCharactersToExclude.Add("#");
	ArrayOfCharactersToExclude.Add("№");
	ArrayOfCharactersToExclude.Add("^");
	ArrayOfCharactersToExclude.Add("*");
	ArrayOfCharactersToExclude.Add("-");
	ArrayOfCharactersToExclude.Add("_");
	ArrayOfCharactersToExclude.Add("+");
	ArrayOfCharactersToExclude.Add("=");
	ArrayOfCharactersToExclude.Add("?");
	ArrayOfCharactersToExclude.Add(">");
	ArrayOfCharactersToExclude.Add("<");
	ArrayOfCharactersToExclude.Add("%");
	ArrayOfCharactersToExclude.Add("$");
	ArrayOfCharactersToExclude.Add("&");
	ArrayOfCharactersToExclude.Add(" ");
	ArrayOfCharactersToExclude.Add("\"); 
	ArrayOfCharactersToExclude.Add("|");
	ArrayOfCharactersToExclude.Add("/");
	ArrayOfCharactersToExclude.Add(Chars.CR);
	ArrayOfCharactersToExclude.Add(Chars.VTab);
	ArrayOfCharactersToExclude.Add(Chars.NBSp);
	ArrayOfCharactersToExclude.Add(Chars.LF);
	ArrayOfCharactersToExclude.Add(Chars.FF);
	ArrayOfCharactersToExclude.Add(Chars.Tab);
	
	If ArrayOfCharactersToExclude.Find(Char) = Undefined Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Checks whether the text found in the hyperlink matches the search conditions
// 
// Parameters:
//  WhereAreWeLooking                   - String - the text in which the search is performed
//  WhatAreWeLookingFor                   - String - the text we are looking for
//  PositionOfFound         - Number - The Position Of What Was Found In The Text
//  HyperlinkSearchOption - String - it can take the values "Ignore" or "Only link to the target"
//
// Returns:
//   Boolean - True if it satisfies the condition.
//
Function TextMatchesSearchConditionInHyperlink(WhereAreWeLooking, WhatAreWeLookingFor, PositionOfFound, HyperlinkSearchOption)
	
	HyperlinkTagPosition = StrFind(WhereAreWeLooking, "<a", SearchDirection.FromEnd, PositionOfFound);
	If HyperlinkTagPosition = 0 Then
		Return True;
	EndIf;
	
	WhereAreWeLookingForClosingTag = Mid(WhereAreWeLooking, HyperlinkTagPosition, PositionOfFound - HyperlinkTagPosition);
	PositionFoundClosingTag =  StrFind(WhereAreWeLookingForClosingTag, ">", SearchDirection.FromBegin, 1);
	If PositionFoundClosingTag <> 0 Then
		Return True;
	EndIf; 
	
	If HyperlinkSearchOption = "Ignore" Then
		Return False;
	EndIf;
	
	PositionOfLinkQuotationMark = StrFind(WhereAreWeLookingForClosingTag, """", SearchDirection.FromBegin, 1);
	PrecedingTextWithoutQuotationMarks = Right(WhereAreWeLookingForClosingTag, StrLen(WhereAreWeLookingForClosingTag) - PositionOfLinkQuotationMark); 
	
	If Not IsBlankString(PrecedingTextWithoutQuotationMarks)
		And HyperlinkSearchOption = "OnlyEntireLink" Then
		Return False;
	EndIf;
	
	LengthThatWeAreLookingFor = StrLen(WhatAreWeLookingFor);
	StartPosition = PositionOfFound + LengthThatWeAreLookingFor;
	
	PositionOfClosingHyperlinkTag = StrFind(WhereAreWeLooking, ">", SearchDirection.FromBegin, StartPosition);
	SubsequentHyperlinkText = Mid(WhereAreWeLooking, StartPosition, PositionOfClosingHyperlinkTag - StartPosition - 1);
	
	If Not IsBlankString(SubsequentHyperlinkText)
		And HyperlinkSearchOption = "OnlyEntireLink" Then
		Return False;
	EndIf; 
	
	Return True;
	
EndFunction

#EndRegion