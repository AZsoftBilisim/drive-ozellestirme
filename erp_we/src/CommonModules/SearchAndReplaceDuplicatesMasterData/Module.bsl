
#Region Public

// Searches for duplicate Master Data records based on active rules and records the found duplicates
// in the information register of the Duplicate confirmation.
//
Procedure SearchForMasterDataDuplicates() Export 
	
	Common.OnStartExecuteScheduledJob();
	ExecuteSearchForMasterDataDuplicates();
	
EndProcedure

// The handler of the routine task "Zamenadublansi". Replaces duplicate links to originals in the database according to the data
// of the Information Register of Dublin. Each pair of substitutions is processed separately in turn in order to be able to accurately
// identify errors associated with this particular substitution.
//
Procedure ReplaceMasterDataDuplicates() Export
	
	Common.OnStartExecuteScheduledJob();
	
	ReplacementPairs = InformationRegisters.MasterDataDuplicates.ReplacementPairs();
	
	ReplacementParameters = Common.RefsReplacementParameters();
	ReplacementParameters.DeletionMethod = "Directly";
	ReplacementParameters.IncludeBusinessLogic = False;
	
	PortionSize = 100;
	ReplacementPortion = New Map;
	Counter = 0;
	
	For Each DuplicateOriginal In ReplacementPairs Do
		ReplacementPortion.Insert(DuplicateOriginal.Key, DuplicateOriginal.Value);
		Counter = Counter + 1;
		
		If Counter >= PortionSize Then
			ProcessReplacementPortion(ReplacementPortion, ReplacementParameters);
			ReplacementPortion.Clear();
			Counter = 0;
		EndIf;
	EndDo;
	
	If ReplacementPortion.Count() > 0 Then
		ProcessReplacementPortion(ReplacementPortion, ReplacementParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure ProcessReplacementPortion(ReplacementPortion, ReplacementParameters)
	
	ReplacementErrors = Common.ReplaceReferences(ReplacementPortion, ReplacementParameters);
	If ReplacementErrors.Count() > 0 Then
		InformationRegisters.MasterDataDuplicates.UpdateInformationAboutReplacementErrors(ReplacementErrors);
	EndIf;
	
EndProcedure

// Searches for new Master Data duplicates according to the specified or all active rules.
//
// Parameters:
//   Rule - CatalogRef.MasterDataDuplicateSearchRules - rule for searching for duplicates, if not specified - search by all active rules.
//
Procedure ExecuteSearchForMasterDataDuplicates(Rule = Undefined) Export 
	
	Query = New Query;
	QueryText = 
		"SELECT
		|	MasterDataDuplicateSearchRules.Ref AS Ref
		|FROM
		|	Catalog.MasterDataDuplicateSearchRules AS MasterDataDuplicateSearchRules
		|WHERE
		|	MasterDataDuplicateSearchRules.Active
		|	AND &FilterByRule";
	
	If Rule <> Undefined Then
		QueryText = StrReplace(QueryText, "MasterDataDuplicateSearchRules.Active", "TRUE");
		QueryText = StrReplace(QueryText, "&FilterByRule", "MasterDataDuplicateSearchRules.Ref = &Rule");
		Query.SetParameter("Rule", Rule);
	Else
		QueryText = StrReplace(QueryText, "&FilterByRule", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		Query = Catalogs.MasterDataDuplicateSearchRules.GenerateRequestBasedOnRule(Selection.Ref, False);
		PairsOfTakes = Query.Execute().Unload();
		
		InformationRegisters.MasterDataDuplicatesToConfirm.CheckDuplicatesForComplianceWithSearchRule(PairsOfTakes, Selection.Ref);
		SearchAndReplaceDuplicatesMasterDataOverridable.WhenSearchingForMasterDataDuplicates(PairsOfTakes, Selection.Ref);
		
		If ValueIsFilled(Rule) Then
			CalculationOfPlacesOfUse = Undefined;
		Else
			CalculationOfPlacesOfUse = False;
		EndIf;
		InformationRegisters.MasterDataDuplicatesToConfirm.AddDuplicates(PairsOfTakes, Selection.Ref, CalculationOfPlacesOfUse);
		
	EndDo;
	
EndProcedure

// Returns a table of related objects to supplement the information of the main object in the duplicate comparison report.
//
// Returns:
//   ValueTable:
//      *LinkedObject - MetadataObject - the metadata object of the subordinate object.
//      *LinksField - String - the name of the Attribute that defines the relationship between the main and subordinate object.
//
Function RelatedObjects() Export
	
	RelatedObjects = New ValueTable;
	RelatedObjects.Columns.Add("LinkedObject", New TypeDescription("MetadataObject"));
	RelatedObjects.Columns.Add("LinksField", New TypeDescription("String"));
	
	Return RelatedObjects;
	
EndFunction

// Returns object relationships specifying the type of the relationship field.
//
// Returns:
//   ValueTable:
//      * AttributeType - Type
//      * AttributeName - String
//      * Key - String
//      * Metadata - MetadataObject
//
Function ObjectsLinks() Export
	
	ObjectsLinks = New ValueTable;
	ObjectsLinks.Columns.Add("AttributeType", New TypeDescription("Type"));
	ObjectsLinks.Columns.Add("AttributeName", New TypeDescription("String", , New StringQualifiers(0)));
	ObjectsLinks.Columns.Add("Key", New TypeDescription("String", , New StringQualifiers(0)));
	ObjectsLinks.Columns.Add("Metadata", New TypeDescription("MetadataObject"));
	
	Return ObjectsLinks;
	
EndFunction

// Returns the Attributes that are excluded from display when creating a report on comparing duplicates.
//
// Returns:
//   ValueTable:
//      * AttributeName - String - the name of the Attribute or table part.
//      * TabularSectionName - String - filled in if the Attribute is located in the table part.
//      * Metadata - MetadataObject
//
Function ExceptionsToComparisonDetails() Export
	
	ExceptionAttributes = New ValueTable();
	ExceptionAttributes.Columns.Add("Metadata", New TypeDescription("MetadataObject"));
	ExceptionAttributes.Columns.Add("TabularSectionName", New TypeDescription("String"));
	ExceptionAttributes.Columns.Add("AttributeName", New TypeDescription("String"));
	
	Return ExceptionAttributes;
	
EndFunction

#EndRegion
