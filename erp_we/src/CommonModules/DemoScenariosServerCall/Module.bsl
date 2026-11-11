
#Region Private

// Saves the settings for displaying Forms of demo scripts and glossary
//
// Parameters:
//  ViewOption  - String - the Form display option can take the values "Editing", "Viewing", "Translation"
//
Procedure SaveFormDisplayModeSetting(ViewOption) Export

	Common.CommonSettingsStorageSave("DisplayModeProcessDescriptionForm",
		                                              "UserSettings",
		                                              ViewOption);
	
EndProcedure

// Performs translation
//
// Parameters:
//  SourceText             - String - Source text
//  SourceLanguage              - String - the code of the language from which the translation is being made
//  TranslationLanguage              - String - the language to be translated into
//
// Returns:
//   Structure   - SeeDemoScenarios.ResultOfTranslationIntoOtherLanguages 
//
Function ResultOfTranslationIntoOtherLanguages(SourceText, SourceLanguage, TranslationLanguage) Export

	Return DemoScenarios.ResultOfTranslationIntoOtherLanguages(SourceText, SourceLanguage, TranslationLanguage)

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

#EndRegion
