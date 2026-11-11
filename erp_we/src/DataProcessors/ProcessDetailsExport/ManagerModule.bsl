#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates process description data for uploading
//
// Parameters:
//  GenerationParameters  - Structure - 
//
// Returns:
//   Structure  - Contains:
//     * Success               - Boolean - indicates that the report was generated successfully.
//     * ErrorsMessages    - Array - error messages in case the data preparation failed.
//     * PreparedData  - Structure - prepared data.
//
Function ResultOfReceivingDataForUploading(GenerationParameters) Export
	
	PreparedData = New Structure;
	PreparedData.Insert("ProcessDescriptions", Undefined);
	PreparedData.Insert("Glossary",         Undefined);
	
	DataAcquisitionResult = New Structure;
	DataAcquisitionResult.Insert("Success",               True);
	DataAcquisitionResult.Insert("ErrorsMessages",    New Array);
	DataAcquisitionResult.Insert("PreparedData",  PreparedData);
	
	PrepareDescriptionDataForUploading(DataAcquisitionResult, GenerationParameters.ComposerSettings, GenerationParameters.ThisIsFullUpload);
	
	If DataAcquisitionResult.Success Then
		PrepareGlossaryDataForUploading(DataAcquisitionResult, GenerationParameters.ThisIsFullUpload);
	EndIf;
	
	Return DataAcquisitionResult;
	
EndFunction 

// Used by a background job to retrieve process description data for uploading.
// Parameters:
//  GenerationParameters  - Structure - 
//  StorageAddress         - String - the address of the temporary storage where the received data will be placed
//
Procedure GetDataFromUploadedDescriptions(GenerationParameters, StorageAddress) Export
	
	DataAcquisitionResult = ResultOfReceivingDataForUploading(GenerationParameters);
	
	PutToTempStorage(DataAcquisitionResult, StorageAddress);
	
EndProcedure 

// Used by a background task to get navigation links from uploaded descriptions to generate screenshots.
// Parameters:
//  GenerationParameters  - Structure - 
//  StorageAddress         - String - the address of the temporary storage where the received data will be placed
//
Procedure GetNavigationLinksFromDescriptions(GenerationParameters, StorageAddress) Export
	
	ResultOfGettingNavigationLinks = ResultOfGettingNavigationLinksFromUploadedDescriptions(GenerationParameters);
	
	PutToTempStorage(ResultOfGettingNavigationLinks, StorageAddress);
	
EndProcedure

#EndRegion 

#Region Private

#Region PreparationOfProcessDescriptions

Function NewDescriptionTreeForUploading()
	
	DescriptionsToUpload = New ValueTree;
	
	DescriptionsToUpload.Columns.Add("Scenario",                New TypeDescription("CatalogRef.DemoScenarios"));
	DescriptionsToUpload.Columns.Add("ScenarioDescriptions",        New TypeDescription("ValueTable"));
	DescriptionsToUpload.Columns.Add("FullCode",               Common.StringTypeDetails(150));
	DescriptionsToUpload.Columns.Add("UUID", Common.StringTypeDetails(50));
	DescriptionsToUpload.Columns.Add("HashOfId",       Common.StringTypeDetails(50));
	DescriptionsToUpload.Columns.Add("Descriptions_ToUpload",       Common.TypeDescriptionNumber(2,0, AllowedSign.Nonnegative));
	DescriptionsToUpload.Columns.Add("ScriptDetails",       Common.StringTypeDetails(0));
	
	Return DescriptionsToUpload;
	
EndFunction

Procedure PrepareDescriptionDataForUploading(Result, ComposerSettings, ThisIsFullUpload)
	
	DescriptionsToUpload = NewDescriptionTreeForUploading();
	
	Query = New Query;
	
	If Not ThisIsFullUpload Then
		
		SetSelectionQueryText(Query, ComposerSettings);
		
		Query.Text = Query.Text + Common.QueryBatchSeparator();
		
		AddUploadQueryText(Query); 
		
	Else
		
		Query.Text = QueryTextFullUploadingOfDescriptions();
	
	EndIf;
	
	QueryResult = Query.Execute();
	
	DataTree = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	ProcessDescriptionsOfTreeLine = New Map;
	
	ProcessDataTreeRows(DataTree.Rows, DescriptionsToUpload.Rows, Undefined, ProcessDescriptionsOfTreeLine);
	
	AddJSONDataOfScriptAttributes(ProcessDescriptionsOfTreeLine);
	
	Result.PreparedData.ProcessDescriptions = DescriptionsToUpload;
	
EndProcedure

Function QueryTextFullUploadingOfDescriptions()
	
	Return "
	|SELECT
	|	DemoScenarios.Ref                             AS Ref,
	|	DemoScenariosScenarioDescriptions.LanguageCode           AS LanguageCode,
	|	DemoScenariosScenarioDescriptions.AttachedFile AS AttachedFile,
	|	DemoScenarios.FullCode                          AS FullCode
	|FROM
	|	Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
	|		INNER JOIN Catalog.DemoScenarios AS DemoScenarios
	|		ON DemoScenariosScenarioDescriptions.Ref = DemoScenarios.Ref
	|
	|ORDER BY
	|	FullCode
	|TOTALS BY
	|	Ref HIERARCHY
	|";
	
EndFunction

Procedure AddJSONDataOfScriptAttributes(ProcessDescriptionsOfTreeLine)

	ScenariosForGettingData = New Array;
	For Each MapItem In ProcessDescriptionsOfTreeLine Do
		
		ScenariosForGettingData.Add(MapItem.Key);
		
	EndDo;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DemoScenarios.Ref            AS Ref,
	|	DemoScenarios.DeletionMark   AS DeletionMark,
	|	DemoScenarios.Parent          AS Parent,
	|	DemoScenarios.IsFolder         AS IsFolder,
	|	DemoScenarios.Code               AS Code,
	|	DemoScenarios.Description      AS Description,
	|	DemoScenarios.FullCode         AS FullCode,
	|	DemoScenarios.Status            AS Status,
	|	DemoScenarios.Comment       AS Comment,
	|	DemoScenarios.GroupType         AS GroupType,
	|	DemoScenarios.DescriptionLanguage1 AS DescriptionLanguage1,
	|	DemoScenarios.DescriptionLanguage2 AS DescriptionLanguage2,
	|	DemoScenarios.AccessGroupProfiles.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Profile AS Profile
	|	) AS AccessGroupProfiles,
	|	DemoScenarios.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	) AS ConfigurationObjects
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|WHERE
	|	DemoScenarios.Ref IN (&ArrayOfScenarios)";
	
	Query.SetParameter("ArrayOfScenarios", ScenariosForGettingData);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do 
		
		DescriptionAttributesData = DemoScenarios.NewAttributeDataDescriptionOfProcesses();
		
		FillPropertyValues(DescriptionAttributesData, Selection, , "AccessGroupProfiles, ConfigurationObjects");
		
		DescriptionAttributesData.AccessGroupProfiles = Selection.AccessGroupProfiles.Unload();
		DescriptionAttributesData.ConfigurationObjects = Selection.ConfigurationObjects.Unload();
		
		TreeRow = ProcessDescriptionsOfTreeLine.Get(Selection.Ref);
		If TreeRow <> Undefined Then
			TreeRow.ScriptDetails = DemoScenarios.JSONTextAttributesDescriptionOfProcesses(DescriptionAttributesData);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ProcessDataTreeRows(QueryTreeRows, FormTreeStrings, FormTreeRow, ProcessDescriptionsOfTreeLine)
	
	For Each QueryTreeString In QueryTreeRows Do
		
		If QueryTreeString.LanguageCode = NULL
			Or QueryTreeString.AttachedFile = NULL Then
			
			ParentString = QueryTreeString.Parent;
			If ParentString <> Undefined
				And ParentString.Ref = QueryTreeString.Ref Then
				
				Continue;
				
			EndIf;
			
			NewRowOfFormTree = FormTreeStrings.Add();
			NewRowOfFormTree.Scenario         = QueryTreeString.Ref;
			NewRowOfFormTree.FullCode        = QueryTreeString.FullCode;
			NewRowOfFormTree.ScenarioDescriptions = NewDescriptionTable();
			
			ProcessDescriptionsOfTreeLine.Insert(QueryTreeString.Ref, NewRowOfFormTree);
			
			NewRowOfFormTree.UUID = StrReplace(QueryTreeString.Ref.UUID(), "-", "_");
			NewRowOfFormTree.HashOfId       = Format(DemoScenarios.TextHash(NewRowOfFormTree.UUID), "NG=0");
			
			ProcessDataTreeRows(QueryTreeString.Rows, NewRowOfFormTree.Rows, NewRowOfFormTree, ProcessDescriptionsOfTreeLine);
			
		Else
			
			AddScenarioDescriptionsToTree(FormTreeRow, QueryTreeString);
			
			FormTreeRow.Descriptions_ToUpload = FormTreeRow.ScenarioDescriptions.Count();
			
		EndIf;
		
	EndDo

EndProcedure

Function NewDescriptionTable()
	
	ScenarioDescriptions = New ValueTable;
	
	ScenarioDescriptions.Columns.Add("LanguageCode", Common.StringTypeDetails(2));
	ScenarioDescriptions.Columns.Add("HTMLText", Common.StringTypeDetails(0));
	
	Return ScenarioDescriptions
	
EndFunction

Procedure AddScenarioDescriptionsToTree(FormTreeRow, QueryTreeString)

	NewRowOfDescriptionTable = FormTreeRow.ScenarioDescriptions.Add();
	NewRowOfDescriptionTable.LanguageCode = QueryTreeString.LanguageCode;
	
	FileData = FilesOperations.FileData(QueryTreeString.AttachedFile);
	NewRowOfDescriptionTable.HTMLText = DemoScenarios.HTMLTextBasedOnAttachedFileData(FileData);

EndProcedure

Procedure SetSelectionQueryText(Query, ComposerSettings)

	CompositionSchema = DataProcessors.ProcessDetailsExport.GetTemplate("ProcessDetailsFilter");
	
	TemplateComposer = New DataCompositionTemplateComposer();
	DataCompositionTemplate = TemplateComposer.Execute(CompositionSchema, 
	                                                    ComposerSettings,,,
	                                                    Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Query.Text = DataCompositionTemplate.DataSets.MainDataSet.Query;
	
	For Each Parameter In DataCompositionTemplate.ParameterValues Do
		Query.Parameters.Insert(Parameter.Name, Parameter.Value);
	EndDo;
	
	FoundItemFROM = StrFind(Query.Text,"FROM");
	If FoundItemFROM <> 0 Then
		Query.Text = Left(Query.Text,FoundItemFROM - 1) + "  INTO FilterByScenarios
		|  " + Right(Query.Text,StrLen(Query.Text) - FoundItemFROM + 1);
		
	EndIf;

EndProcedure

Procedure AddUploadQueryText(Query)

	TextOfMainRequest = "
	|SELECT
	|	DemoScenarios.Ref                             AS Ref,
	|	DemoScenariosScenarioDescriptions.LanguageCode           AS LanguageCode,
	|	DemoScenariosScenarioDescriptions.AttachedFile AS AttachedFile,
	|	DemoScenarios.FullCode                          AS FullCode
	|FROM
	|	Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
	|		INNER JOIN FilterByScenarios AS FilterByScenarios
	|		ON DemoScenariosScenarioDescriptions.Ref = FilterByScenarios.ProcessDescription
	|			AND DemoScenariosScenarioDescriptions.AttachedFile = FilterByScenarios.AttachedFile
	|		INNER JOIN Catalog.DemoScenarios AS DemoScenarios
	|		ON DemoScenariosScenarioDescriptions.Ref = DemoScenarios.Ref
	|
	|ORDER BY
	|	FullCode
	|TOTALS BY
	|	Ref HIERARCHY
	|";

	Query.Text = Query.Text + TextOfMainRequest;

EndProcedure

#EndRegion 

#Region PreparingGlossary

Function NewTableGlossaryForUploading()
	
	DescriptionsToUpload = New ValueTable;
	
	DescriptionsToUpload.Columns.Add("Glossary",               New TypeDescription("CatalogRef.Glossary"));
	DescriptionsToUpload.Columns.Add("GlossaryDetails",       New TypeDescription("ValueTable"));
	DescriptionsToUpload.Columns.Add("UUID", Common.StringTypeDetails(50));
	DescriptionsToUpload.Columns.Add("AttributesOfGlossary",      Common.StringTypeDetails(0));
	
	Return DescriptionsToUpload;
	
EndFunction

Procedure PrepareGlossaryDataForUploading(DataAcquisitionResult, ThisIsFullUpload)
	
	GlossaryForUploading = NewTableGlossaryForUploading();
	
	Query = New Query;
	
	If ThisIsFullUpload Then
		
		Query.Text = QueryTextFullGlossaryUpload();
		
	Else
		
		GlossariesUsed = GlossariesUsedInUploadedDescriptions(DataAcquisitionResult.PreparedData.ProcessDescriptions);
		Query.Text = QueryTextPartialUploadingOfGlossary();
		Query.SetParameter("GlossariesUsed", GlossariesUsed);
		
	EndIf; 
	
	Query.Text =  Query.Text + PartOfQueryTextUploadingGlossaryOrganize();
	
	QueryResult = Query.Execute();
	
	FillInGlossaryTableForUploading(QueryResult, GlossaryForUploading);
	
	DataAcquisitionResult.PreparedData.Glossary = GlossaryForUploading;
	
EndProcedure

Function GlossariesUsedInUploadedDescriptions(TreeOfUploadedDescriptions)
	
	
	GlossariesUsed = New Array;
	
	For Each TreeRow In TreeOfUploadedDescriptions.Rows Do
		
		IdentifyGlossariesUsedByTreeLine(TreeRow, GlossariesUsed);
		
	EndDo;
	
	Return GlossariesUsed;
	
EndFunction

Procedure IdentifyGlossariesUsedByTreeLine(TreeRow, GlossariesUsed)
	
	For Each StringDescriptionInLanguage In TreeRow.ScenarioDescriptions Do
		
		LinksInDescription = DemoScenarios.UniqueLinksInHTML5Document(StringDescriptionInLanguage.HTMLText);
		
		For Each LinkInDescription In LinksInDescription Do
			
			If StrFind(LinkInDescription, "e1cib/data/Catalog.Glossary") <> 0 Then
				
				LinkToGlossary = DemoScenariosServerCall.LinkToPlaceViaNavigationLink(LinkInDescription);
				
				If LinkToGlossary <> Undefined
					And GlossariesUsed.Find(LinkToGlossary) = Undefined Then
					
					GlossariesUsed.Add(LinkToGlossary);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		IdentifyGlossariesUsedByTreeLine(SubordinateRow, GlossariesUsed);
		
	EndDo
	
EndProcedure

Procedure FillInGlossaryTableForUploading(QueryResult, GlossaryForUploading) 
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		NewRow = GlossaryForUploading.Add();
		
		NewRow.Glossary               = Selection.Ref;
		NewRow.GlossaryDetails       = NewDescriptionTable();
		
		GlossaryAttributes = DemoScenarios.NewAttributeDataGlossary();
		FillPropertyValues(GlossaryAttributes, Selection, , "ConfigurationObjects");
		GlossaryAttributes.ConfigurationObjects = Selection.ConfigurationObjects.Unload();
		
		NewRow.AttributesOfGlossary      = DemoScenarios.TextOfGlossarySJSONAttributes(GlossaryAttributes);
		NewRow.UUID = String(Selection.Ref.UUID());

		FillInGlossaryDescriptionTable(NewRow, Selection);
		
	EndDo;
	
EndProcedure

Procedure FillInGlossaryDescriptionTable(RowOfGlossaryTable, Selection)

	GlossaryDetails = Selection.GlossaryDetails.Unload();
	
	For Each DescriptionStringSelection In  GlossaryDetails Do
		
		NewRow = RowOfGlossaryTable.GlossaryDetails.Add();
		NewRow.LanguageCode = DescriptionStringSelection.LanguageCode; 
		
		HTMLText = "";
		Attachments = New Structure;
		FormattedDescriptionDocument = DescriptionStringSelection.LongDesc.Get();
		FormattedDescriptionDocument.GetHTML(HTMLText, Attachments);
		
		NewRow.HTMLText = HTMLText; 
		
	EndDo;
	
EndProcedure

Function QueryTextFullGlossaryUpload()
	
	Return "
	|SELECT
	|	Glossary.Ref            AS Ref,
	|	Glossary.DataVersion      AS DataVersion,
	|	Glossary.DeletionMark   AS DeletionMark,
	|	Glossary.Code               AS Code,
	|	Glossary.Description      AS Description,
	|	Glossary.DescriptionLanguage1 AS DescriptionLanguage1,
	|	Glossary.DescriptionLanguage2 AS DescriptionLanguage2,
	|	Glossary.ConfigurationObjects.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		ConfigurationObject AS ConfigurationObject
	|	)                           AS ConfigurationObjects,
	|	Glossary.GlossaryDetails.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		LanguageCode AS LanguageCode,
	|		LongDesc AS LongDesc
	|	)                           AS GlossaryDetails
	|FROM
	|	Catalog.Glossary AS Glossary";
	
EndFunction

Function QueryTextPartialUploadingOfGlossary() 
	
	Return  QueryTextFullGlossaryUpload() + "
	|WHERE
	|	Glossary.Ref IN(&GlossariesUsed)";
	
	
EndFunction

Function PartOfQueryTextUploadingGlossaryOrganize() 

	Return "
	|
	|ORDER BY
	|	Glossary.Code";
	
EndFunction


#EndRegion

#Region GettingNavigationLinksFromDescriptions

Function ResultOfGettingNavigationLinksFromUploadedDescriptions(GenerationParameters)
	
	ResultOfLinkAnalysis = DemoScenarios.NewLinkAnalysisResult();
	
	ResultOfGettingNavigationLinks = New Structure;
	ResultOfGettingNavigationLinks.Insert("Success",               True);
	ResultOfGettingNavigationLinks.Insert("ErrorsMessages",    New Array);
	ResultOfGettingNavigationLinks.Insert("PreparedData",  ResultOfLinkAnalysis);
	
	For Each ScenarioData In GenerationParameters.ScriptsToUpload Do
		
		ParseDescriptionLinksAccordingToScript(ScenarioData, ResultOfLinkAnalysis);
		
	EndDo;
	
	Return ResultOfGettingNavigationLinks;
	
EndFunction

Procedure ParseDescriptionLinksAccordingToScript(DescriptionTreeString, ResultOfLinkAnalysis)
	
	For Each DescriptionData In DescriptionTreeString.DetailsList1 Do
		
		AddDescriptionLinksToParsingResult(DescriptionData.HTMLText, ResultOfLinkAnalysis, DescriptionTreeString, DescriptionData.LanguageCode)
		
	EndDo;
	
EndProcedure

Function AddDescriptionLinksToParsingResult(ScenarioText, ParsingResult, DescriptionTreeString, LanguageCode)
	
	UniqueRefs = DemoScenarios.UniqueLinksInHTML5Document(ScenarioText);
	
	For Each UniqueLink In UniqueRefs Do
		
		If StrFind(UniqueLink, "e1cib/command/") <> 0 Then
			
			RefData = NewDataNavigationLinks();
			RefData.RefType = "Command";
			RefData.EntireLink = UniqueLink;
			
			PositionOfFound = StrFind(UniqueLink, "e1cib/command/");
			
			URL = Right(UniqueLink, StrLen(UniqueLink) + 1 - PositionOfFound); 
			
			AddTheseLinksToCollection(ParsingResult.Commands, URL, RefData, DescriptionTreeString, LanguageCode);
			
		ElsIf StrFind(UniqueLink, "e1cib/list/") <> 0 Then
			
			RefData = NewDataNavigationLinks();
			RefData.RefType = "List";
			RefData.EntireLink = UniqueLink;
			
			PositionOfFound = StrFind(UniqueLink, "e1cib/list/");
			
			URL = Right(UniqueLink, StrLen(UniqueLink) + 1 - PositionOfFound);
			
			AddTheseLinksToCollection(ParsingResult.Lists, URL, RefData, DescriptionTreeString, LanguageCode);
			
		ElsIf StrFind(UniqueLink, "e1cib/data/") <> 0 Then
			
			RefData = NewDataNavigationLinks();
			RefData.RefType = "LinkToInformationSecurityObject";
			RefData.EntireLink = UniqueLink;
			
			PositionOfFound = StrFind(UniqueLink, "e1cib/data/");
			
			URL = Right(UniqueLink, StrLen(UniqueLink) + 1 - PositionOfFound);
			
			RefData.LinkToInformationSecurityObject = DemoScenariosServerCall.LinkToPlaceViaNavigationLink(URL);
			
			AddTheseLinksToCollection(ParsingResult.ObjectsRefs, URL, RefData, DescriptionTreeString, LanguageCode);
			
		Else
			
			RefData = NewDataNavigationLinks();
			RefData.RefType = "ExternalRef";
			RefData.EntireLink = UniqueLink;
			
			AddTheseLinksToCollection(ParsingResult.ExternalRefs, UniqueLink, RefData, DescriptionTreeString, LanguageCode);
			
		EndIf; 
		
		RefData.HashOfLink= Format(DemoScenarios.TextHash(UniqueLink), "NG=0");
		
	EndDo;
	
EndFunction

Function NewDataNavigationLinks()

	RefData = New Structure;
	RefData.Insert("RefType",           "");
	RefData.Insert("EntireLink",       "");
	RefData.Insert("HashOfLink",           "");
	RefData.Insert("LinkToInformationSecurityObject",    "");
	RefData.Insert("Title",           ""); 
	RefData.Insert("BudgetingScenarios",            New Array);
	RefData.Insert("DataOfPage",       Undefined);
	
	Return RefData;

EndFunction

Procedure AddTheseLinksToCollection(Collection, URL, RefData, DescriptionTreeString, LanguageCode)
	
	ScenarioData = New Structure;
	ScenarioData.Insert("Scenario",            DescriptionTreeString.Scenario);
	ScenarioData.Insert("RowID", DescriptionTreeString.RowID);
	ScenarioData.Insert("LanguageCode",            LanguageCode); 
	
	CollectionItem = Collection.Get(URL);
	
	If CollectionItem = Undefined Then 
		RefData.BudgetingScenarios.Add(ScenarioData);
		Collection.Insert(URL, RefData);
	Else
		CollectionItem.BudgetingScenarios.Add(ScenarioData);
	EndIf;
	
EndProcedure

#EndRegion 

#EndRegion 

#EndIf
