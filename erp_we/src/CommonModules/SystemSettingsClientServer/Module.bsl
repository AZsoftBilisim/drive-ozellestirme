////////////////////////////////////////////////////////////////////////////////
// Client-server procedures and functions that control system settings.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Constructor for describing global search results
//
// Returns:
//  Structure - global search result:
//   * Value - Undefined, Arbitrary - parameters passed when selecting the global search result.
//   * Presentation - String, FormattedString - The Presentation displayed to the user.
//   * Picture - Picture - image search result.
//   * ActionDetails - String - description of the action when selecting a global search result.
Function NewGlobalSearchResult() Export
	
	Result = New Structure;
	Result.Insert("Value", Undefined);
	Result.Insert("Presentation", "");
	Result.Insert("Picture", New Picture);
	Result.Insert("ActionDetails", "");
	
	Return Result;
	
EndFunction

#EndRegion