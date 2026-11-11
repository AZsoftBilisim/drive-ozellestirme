#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ProductRangeManagement");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * Table - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.SetProductRangeQuotas") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		Query.SetParameter("Ref", DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableProductMixQuotas(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#Region Private

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Interface for working with the File Upload subsystem.

// Sets the download parameters.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
//
// Parameters:
//   AddressOfUploadedData    - String - the address of the temporary storage with the table of values in which
//                                        the downloaded data from the file is located. Composition of columns:
//     * Id - Number - sequence number of the line;
//      the remaining columns correspond to the columns of the File upload layout.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document
//                                        that needs to be filled in from the addressable Data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//     * Column       - String - name of the column where the ambiguity was detected;
//     * Id - Number  - ID of the string where the ambiguity was detected.
//   FullTabularSectionName   - String - full name of the table part where data is loaded.
//   AdditionalParameters   - Structure - additional parameters
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	ProductCategories =  GetFromTempStorage(AddressOfMappingTable); // See MapDataToImport.ConflictsList
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // See MapDataToImport.ConflictsList
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(DataForComparison.ProductCategory AS STRING(&LengthProductCategory)) AS ProductCategory,
	|	CAST(DataForComparison.Brand AS STRING(&BrandLength)) AS Brand,
	|	DataForComparison.Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ProductCategories.Ref) AS ProductCategoryLink,
	|	DataForComparison.Id,
	|	COUNT(DataForComparison.Id) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.ProductCategories AS ProductCategories
	|		ON (ProductCategories.Description = DataForComparison.ProductCategory)
	|			AND NOT ProductCategories.IsFolder
	|WHERE
	|	NOT ProductCategories.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(Brands.Ref) AS BrandLink,
	|	DataForComparison.Id,
	|	COUNT(DataForComparison.Id) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.Brands AS Brands
	|		ON (Brands.Description = DataForComparison.Brand)
	|			AND NOT Brands.IsFolder
	|WHERE
	|	NOT Brands.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.Id";
	
	Query.SetParameter("DataForComparison", DataToImport);
	
	LengthProductCategory = Metadata.Catalogs.ProductCategories.DescriptionLength;
	BrandLength = Metadata.Catalogs.Brands.DescriptionLength;
	
	Query.Text = StrReplace(Query.Text, "&LengthProductCategory", LengthProductCategory);
	Query.Text = StrReplace(Query.Text, "&BrandLength", BrandLength);
	
	QueriesResults = Query.ExecuteBatch();
	
	TableProductCategories = QueriesResults[1].Unload();
	BrandTable = QueriesResults[2].Unload();
	
	For Each TableRow In DataToImport Do 
		
		NewRow = ProductCategories.Add();
		NewRow.Id = TableRow.Id;
		NewRow.Quota = TableRow.Quota;
		NewRow.VariancePercentage = TableRow.VariancePercentage;
		
		ProductCategoryLine = TableProductCategories.Find(TableRow.Id, "Id");
		If ProductCategoryLine <> Undefined Then 
			If ProductCategoryLine.Count = 1 Then 
				NewRow.ProductCategory  = ProductCategoryLine.ProductCategoryLink;
			ElsIf ProductCategoryLine.Count > 1 Then 
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id; 
				WritingAboutAmbiguity.Column = "ProductCategory";
			EndIf;
		EndIf;
		
		MarkSLine = BrandTable.Find(TableRow.Id, "Id");
		If MarkSLine <> Undefined Then 
			If MarkSLine.Count = 1 Then 
				NewRow.Brand  = MarkSLine.BrandLink;
			ElsIf MarkSLine.Count > 1 Then 
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id; 
				WritingAboutAmbiguity.Column = "Brand";
			EndIf;
		EndIf;
		
	EndDo;
	
	PutToTempStorage(ProductCategories, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
//
// Parameters:
//  FullTabularSectionName  - String - full name of the table part where data is loaded.
//  ConflictsList    - Array - list with ambiguous data
//  ColumnName                - String - name of the column where the ambiguity occurred
//  LoadedValuesString - String - Loaded data based on which the ambiguity occurred
//  AdditionalParameters - Structure
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	If ColumnName = "ProductCategory" Then

		Query = New Query;
		Query.Text = 
		"SELECT
		|	ProductCategories.Ref
		|FROM
		|	Catalog.ProductCategories AS ProductCategories
		|WHERE
		|	ProductCategories.Description = &Description
		|	AND NOT ProductCategories.IsFolder";
		Query.SetParameter("Description", LoadedValuesString.ProductCategory);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			ConflictsList.Add(SelectionDetailRecords.Ref);  
		EndDo;
	EndIf;
	
	If ColumnName = "Brand" Then

		Query = New Query;
		Query.Text = 
		"SELECT
		|	Brands.Ref
		|FROM
		|	Catalog.Brands AS Brands
		|WHERE
		|	Brands.Description = &Description
		|	AND NOT Brands.IsFolder";
		Query.SetParameter("Description", LoadedValuesString.Brand);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			ConflictsList.Add(SelectionDetailRecords.Ref);  
		EndDo;
	EndIf;
	
EndProcedure

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function QueryTextTableProductMixQuotas(Query, QueryTexts, Registers)
	
	RegisterName = "ProductMixQuotas";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ProductCategories.LineNumber AS NStr,
	|	ProductCategories.Ref.ValidityStartDate AS Period,
	|	ProductCategories.ProductCategory AS ProductCategory,
	|	ProductCategories.Ref.PlanningObject AS PlanningObject,
	|	ProductCategories.Brand AS Brand,
	|	ProductCategories.Ref.ItemsCollection AS ItemsCollection,
	|	ProductCategories.Quota AS Quota,
	|	ProductCategories.VariancePercentage AS VariancePercentage
	|FROM
	|	Document.SetProductRangeQuotas.ProductCategories AS ProductCategories
	|WHERE
	|	ProductCategories.Ref = &Ref
	|
	|ORDER BY
	|	NStr";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region OtherItems

// Returns:
//  Boolean - There is a plan
Function ThereIsPlan_(AuditablePlanningObject, OnDate, CallingDocument) Export
	ThereIsPlan = False;
	Query = New Query("SELECT TOP 1
	|	Recorder AS Recorder
	|FROM
	|	InformationRegister.ProductMixQuotas AS ProductMixQuotas
	|WHERE
	|	ProductMixQuotas.Period = &Period
	|	AND ProductMixQuotas.PlanningObject = &PlanningObject");
	Query.SetParameter("Period", BegOfMonth(OnDate));
	Query.SetParameter("PlanningObject", AuditablePlanningObject);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If Selection.Recorder <> CallingDocument Then
			ThereIsPlan = True;
		EndIf;
	EndDo;
	Return ThereIsPlan;
EndFunction

#EndRegion

// Adds the command to create the document "setting assortment quotas".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.SetProductRangeQuotas) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SetProductRangeQuotas.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SetProductRangeQuotas);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductCategories";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

#EndRegion

#EndIf
