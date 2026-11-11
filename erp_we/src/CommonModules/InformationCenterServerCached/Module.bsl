
#Region Internal

// Returns a table with information links for forms
//
// Parameters:
//	HashPathToForm - String - hash of the full path to the form.
//
// Returns:
//	ValueTable - table of information links for a form with columns:
//	* Description - String - the name of the information link
//	* Address - String - external address of the information link
//	* Weight - Number - information link weight
//	* RelevantFrom - Date - date when the information link started being up to date
//	* RelevantTo - Date - end date relevance of information and links
//	* ToolTip - String - hint for an informational link.
//
Function InformationReferences(HashPathToForm) Export
	
	Query = New Query;
	Query.SetParameter("Hash", HashPathToForm);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.Text = 
	"SELECT
	|	FullPathsToForms.Ref AS Ref
	|INTO PathsToForms
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|WHERE
	|	FullPathsToForms.Hash = &Hash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InformationReferencesForForms.Description AS Description,
	|	InformationReferencesForForms.Address AS Address,
	|	InformationReferencesForForms.Weight AS Weight,
	|	InformationReferencesForForms.RelevantFrom AS RelevantFrom,
	|	InformationReferencesForForms.RelevantTo AS RelevantTo,
	|	InformationReferencesForForms.ToolTip AS ToolTip
	|FROM
	|	PathsToForms AS PathsToForms
	|		INNER JOIN Catalog.InformationReferencesForForms AS InformationReferencesForForms
	|		ON PathsToForms.Ref = InformationReferencesForForms.FullFormPath
	|WHERE
	|	InformationReferencesForForms.RelevantFrom <= &CurrentDate
	|	AND InformationReferencesForForms.RelevantTo >= &CurrentDate
	|
	|ORDER BY
	|	Weight DESC";
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion