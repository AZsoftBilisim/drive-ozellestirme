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
	
	DocumentMechanisms.Add("InventoryPlanning");
	
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
	
	If TypeOf(Document) = Type("DocumentObject.SalesPlansAllocationBaseByCategories") Then
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
		
		QueryTextTableStandardsOfSalesPlanAllocationByCategories(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

#EndRegion

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

// Adds a command to create the document "Standard distribution of sales plans by category".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.SalesPlansAllocationBaseByCategories) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SalesPlansAllocationBaseByCategories.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SalesPlansAllocationBaseByCategories);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSalesPlansByCategories";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

// Returns the structure of details that can be used to enter distribution standards,
// and takes into account the values of functional options.
//
// Parameters:
//  ConsiderFunctionalOptions  - Boolean - If True, returns a list including the FO
//                 If False, returns the full list of banking details.
//
// Returns:
//   Structure   - The structure of the details for which standards can be entered.
//
Function GetDetailsForRegulations(ConsiderFunctionalOptions = True) Export

	AttributesStructure1 = New Structure;
	
	AttributeStructure = New Structure;
	AttributeStructure.Insert("AttributeType", "CatalogRef.Manufacturers");
	AttributeStructure.Insert("TableName", "Catalog.Manufacturers");
	AttributeStructure.Insert("Presentation", NStr("vi = 'Nhà sản xuất';
													|ru = 'Производитель';
													|en = 'Manufacturer'; fa = 'تولیدکننده';
													|it = 'Produttore';
													|pl = 'Manufacturer';
													|tr = 'Üretici'"));
	AttributesStructure1.Insert("Manufacturer", AttributeStructure);
	
	AttributeStructure = New Structure;
	AttributeStructure.Insert("AttributeType", "CatalogRef.Brands");
	AttributeStructure.Insert("TableName", "Catalog.Brands");
	AttributeStructure.Insert("Presentation", NStr("vi = 'Nhãn hiệu (thương hiệu)';
													|ru = 'Марка (бренд)';
													|en = 'Brand'; fa = 'برند';
													|it = 'Marchio';
													|pl = 'Marka (brand)';
													|tr = 'Marka (marka)'"));
	AttributesStructure1.Insert("Brand", AttributeStructure);
	
	If GetFunctionalOption("UseCollectionManagement") Or Not ConsiderFunctionalOptions Then
	
		AttributeStructure = New Structure;
		AttributeStructure.Insert("AttributeType", "CatalogRef.ItemsCollections");
		AttributeStructure.Insert("TableName", "Catalog.ItemsCollections");
		AttributeStructure.Insert("Presentation", NStr("vi = 'Bộ sưu tập (thời vụ)';
														|ru = 'Коллекция (сезон)';
														|en = 'Collection (season)'; fa = 'کلکسیون (فصل)';
														|it = 'Collezione (stagione)';
														|pl = 'Kolekcja (sezon)';
														|tr = 'Koleksiyon (sezon)'"));
		AttributesStructure1.Insert("ItemsCollection", AttributeStructure);
	
	EndIf; 
	
	
	If GetFunctionalOption("UseSeasonalIndexes") Or Not ConsiderFunctionalOptions Then
	
		AttributeStructure = New Structure;
		AttributeStructure.Insert("AttributeType", "CatalogRef.SeasonalGroups");
		AttributeStructure.Insert("TableName", "Catalog.SeasonalGroups");
		AttributeStructure.Insert("Presentation",  NStr("vi = 'Nhóm thời vụ';
														|ru = 'Сезонная группа';
														|en = 'Seasonal group'; fa = 'گروه فصلی';
														|it = 'Gruppo stagionale';
														|pl = 'Grupa sezonowa';
														|tr = 'Mevsimsel grup'"));
		AttributesStructure1.Insert("ItemsGroup", AttributeStructure);
	
	EndIf; 
	
	If GetFunctionalOption("UsePriceGroups") Or Not ConsiderFunctionalOptions Then
	
		AttributeStructure = New Structure;
		AttributeStructure.Insert("AttributeType", "CatalogRef.PriceGroups");
		AttributeStructure.Insert("TableName", "Catalog.PriceGroups");
		AttributeStructure.Insert("Presentation", NStr("vi = 'Nhóm giá';
														|ru = 'Ценовая группа';
														|en = 'Price group'; fa = 'گروه قیمت';
														|it = 'Gruppo dei prezzi';
														|pl = 'Grupa cenowa';
														|tr = 'Fiyat grubu'"));
		AttributesStructure1.Insert("PriceGroup", AttributeStructure);
	
	EndIf; 
	
	Return AttributesStructure1;

EndFunction

// Returns a list of additional details for standards
//
// Parameters:
//  ProductCategory  - CatalogRef.ProductCategories - Product category in the context of which we get properties.
//
// Returns:
//   ValueList   - A list containing links to additional details and their representations.
//
Function GetAdditionalDetailsForRegulations(ProductCategory) Export

	ListOfAdditionalProperties = New ValueList;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	1 AS Order,
	|	Attributes.LineNumber AS LineNumber,
	|	Attributes.Property,
	|	AddAttributes.Title AS Description
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS Attributes
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets AS Set
	|		ON Attributes.Ref = Set.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AddAttributes
	|		ON Attributes.Property = AddAttributes.Ref
	|WHERE
	|	NOT Set.IsFolder
	|	AND Set.Ref = &Set_Catalog_Products_Overall
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	2,
	|	Attributes.LineNumber,
	|	Attributes.Property,
	|	AddAttributes.Title
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS Attributes
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets AS Set
	|		ON Attributes.Ref = Set.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AddAttributes
	|		ON Attributes.Property = AddAttributes.Ref
	|WHERE
	|	NOT Set.IsFolder
	|	AND Set.Ref = CAST(&ProductCategory AS Catalog.ProductCategories).Owner.PropertiesSet
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	3,
	|	Attributes.LineNumber,
	|	Attributes.Property,
	|	AddAttributes.Title
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS Attributes
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets AS Set
	|		ON Attributes.Ref = Set.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AddAttributes
	|		ON Attributes.Property = AddAttributes.Ref
	|WHERE
	|	NOT Set.IsFolder
	|	AND Set.Ref = &Set_Catalog_ItemsCharacteristics_Overall
	|	AND &ItemVariantsAreUsed
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	4,
	|	Attributes.LineNumber,
	|	Attributes.Property,
	|	AddAttributes.Title
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS Attributes
	|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets AS Set
	|		ON Attributes.Ref = Set.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AddAttributes
	|		ON Attributes.Property = AddAttributes.Ref
	|WHERE
	|	NOT Set.IsFolder
	|	AND &ItemVariantsAreUsed
	|	AND Set.Ref = CAST(&ProductCategory AS Catalog.ProductCategories).Owner.CharacteristicsPropertySet
	|
	|ORDER BY
	|	Order,
	|	LineNumber,
	|	Description";
	
	ItemVariantsAreUsed = GetFunctionalOption("UseItemVariants");
	
	Query.SetParameter("ProductCategory", ProductCategory);
	Query.SetParameter("ItemVariantsAreUsed", ItemVariantsAreUsed);
	Query.SetParameter("Set_Catalog_Products_Overall", PropertyManager.PropertiesSetByName("Catalog_Products_Overall"));
	Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));

	QueryResult = Query.Execute();

	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		If ItemVariantsAreUsed Then
			ListOfAdditionalProperties.Add(SelectionDetailRecords.Property);
		Else
			ListOfAdditionalProperties.Add(SelectionDetailRecords.Property, SelectionDetailRecords.Description);
		EndIf; 
	EndDo;
	
	Return ListOfAdditionalProperties;

EndFunction

// Calculates the coefficients according to the statistics of sales
//
// Parameters:
//  Parameters		- Structure - contains settings for the calculation of the coefficients
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CalculateStandardsForSalesStatistics(Parameters, StorageAddress) Export
	
	Settings = Common.CommonSettingsStorageLoad(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID);
	
	If TypeOf(Settings) <> Type("Structure") Then
		
		Return;
		
	EndIf;
	
	If Parameters.FillingVariant = 1 Then
	
		DataCompositionSchema = Documents.SalesPlansAllocationBaseByCategories.GetTemplate("FillingBySalesStatisticsItemProperty");
	
	ElsIf Parameters.FillingVariant = 2 Then
	
		DataCompositionSchema = Documents.SalesPlansAllocationBaseByCategories.GetTemplate("FillingBySalesStatisticsVariantProperty");
	
	Else
	
		DataCompositionSchema = Documents.SalesPlansAllocationBaseByCategories.GetTemplate("FillingBySalesStatisticsItemAttributes");
		
		SearchSubstring = "CatProducts.ItemsGroup";
		ReplaceSubstring = "CatProducts."+Parameters.Attribute;
		DataCompositionSchema.DataSets[0].Query = StrReplace(DataCompositionSchema.DataSets[0].Query, SearchSubstring, ReplaceSubstring);
	
	EndIf;
	
	UserSettings = Undefined;
	If Settings.Property("UserSettings") Then
	
		UserSettings = Settings.UserSettings;
	
	EndIf;
	
	// Loading Settings
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	If UserSettings <> Undefined Then
		
		SettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "BeginOfPeriod", Parameters.StartDate);
	DataCompositionClientServer.SetParameter(SettingsComposer, "EndOfPeriod", Parameters.EndDate);
	DataCompositionClientServer.SetParameter(SettingsComposer, "ProductCategory", Parameters.ProductCategory);
	DataCompositionClientServer.SetParameter(SettingsComposer, "Property", Parameters.Property);
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(),,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	
	// The table of values in which the result will be received
	TableOfCoefficients = New ValueTable;
	
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(TableOfCoefficients);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);
	
	If Parameters.AllocationShareProcedure > 0 Then
		
		For Each TSRow In TableOfCoefficients Do
			
			If ValueIsFilled(TSRow.AllocationPercentage) Then
				TSRow.AllocationPercentage = Int(TSRow.AllocationPercentage * Pow(10, Parameters.AllocationShareProcedure))
			EndIf;
			
		EndDo;
		
	EndIf;
	PutToTempStorage(TableOfCoefficients, StorageAddress);
	
	SetPrivilegedMode(True);
	Common.CommonSettingsStorageDelete(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID, Users.CurrentUser());
	
EndProcedure

// Fills in the table of standards with all possible values, taking into account those already set earlier, or entered in the document.
//
// Parameters:
//  Standards  - CatalogRef.ProductCategories - Product category in the context of which we get standards
//  ProductCategory  - CatalogRef.ProductCategories - Product category in the context of which we get properties
//  Attribute  - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo, String - Details for which
//                                                                                      the standard values are filled in
//  OnDate  - Date - The date on which the values of the established standards are selected.
//
Procedure FillTableOfStandardsWithAllValues(Standards, ProductCategory, Attribute, OnDate) Export

	If Not ValueIsFilled(Attribute) Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Standards.LineNumber,
	|	Standards.Value,
	|	Standards.AllocationPercentage
	|INTO Standards
	|FROM
	|	&Standards AS Standards
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Standards.LineNumber,
	|	Standards.Value,
	|	Standards.AllocationPercentage
	|INTO CurRegulations
	|FROM
	|	InformationRegister.StandardsOfSalesPlanAllocationByCategories.SliceLast(
	|			&OnDate,
	|			Attribute = &Attribute
	|				AND ProductCategory = &ProductCategory) AS StandardsForDistributionOfSlices
	|		INNER JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByAttributes AS Standards
	|		ON StandardsForDistributionOfSlices.NormativeStandard = Standards.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	Standards.LineNumber,
	|	Standards.Value,
	|	Standards.AllocationPercentage
	|FROM
	|	InformationRegister.StandardsOfSalesPlanAllocationByCategories.SliceLast(
	|			&OnDate,
	|			Attribute = &Attribute
	|				AND ProductCategory = &ProductCategory) AS StandardsForDistributionOfSlices
	|		INNER JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByProperties AS Standards
	|		ON StandardsForDistributionOfSlices.NormativeStandard = Standards.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 99999
	|	ValueTable.Ref AS Value,
	|	ISNULL(Standards.AllocationPercentage, ISNULL(CurRegulations.AllocationPercentage, 0)) AS AllocationPercentage,
	|	ISNULL(Standards.LineNumber, 99999) AS Order
	|FROM
	|	&ValueTable AS ValueTable
	|		LEFT JOIN Standards AS Standards
	|		ON ValueTable.Ref = Standards.Value
	|		LEFT JOIN CurRegulations AS CurRegulations
	|		ON ValueTable.Ref = CurRegulations.Value
	|WHERE
	|	NOT ValueTable.DeletionMark
	|	AND &FilterText1
	|
	|ORDER BY
	|	Order";
	
	
	
	FilterText1 = "";
	
	If TypeOf(Attribute) = Type("String") Then
		
		AttributesStructure1 = GetDetailsForRegulations();
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			Return;
			
		EndIf;
		
		TableName = AttributeStructure.TableName;
		MDOfObject = Metadata.FindByFullName(TableName);
	
	Else
	
		ValueType = Common.ObjectAttributeValue(Attribute, "ValueType");
		If Not Common.IsReference(ValueType.Types()[0]) Then
			
			Standards.Clear();
			Return;
		
		EndIf; 
		
		MDOfObject = Metadata.FindByType(ValueType.Types()[0]);
		TableName = MDOfObject.FullName();
		
		If Common.IsCatalog(MDOfObject) And MDOfObject.Owners.Contains(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo) Then
			FilterText1 = "AND ValueTable.Owner = &Attribute";
		EndIf;
		
	EndIf; 
	
	If (Metadata.Catalogs.Contains(MDOfObject) 
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MDOfObject)) 
		And MDOfObject.Hierarchical 
		And MDOfObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		FilterText1 = FilterText1 + "
			|	AND NOT ValueTable.IsFolder";
	EndIf; 
	
	Query.SetParameter("ProductCategory", ProductCategory);
	Query.SetParameter("Attribute", Attribute);
	Query.SetParameter("OnDate", OnDate);
	
	Query.Text = StrReplace(Query.Text, "&ValueTable", TableName);
	Query.Text = StrReplace(Query.Text, "AND &FilterText1", FilterText1);
	
	Query.SetParameter("Standards", Standards.Unload());
	
	QueryResult = Query.Execute();

	ValueTable = QueryResult.Unload();
	
	Standards.Load(ValueTable);

EndProcedure

// Fills in the table of standards with all possible values, taking into account those already set earlier, or entered in the document.
//
// Parameters:
//  Standards  - CatalogRef.ProductCategories - Product category in the context of which we get standards
//  ProductCategory  - CatalogRef.ProductCategories - Product category in the context of which we get properties
//  Attribute  - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo, String - Details for which
//                                                                                      the standard values are filled in
//  FillingVariant - Number
//  OnDate  - Date - The date on which the values of the established standards are selected.
//
Procedure FillInTableOfStandardsWithValuesUsedInProductList(Standards, ProductCategory, Attribute, FillingVariant, OnDate) Export

	If Not ValueIsFilled(Attribute) Then
		Return;
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Standards.LineNumber,
	|	Standards.Value,
	|	Standards.AllocationPercentage
	|INTO Standards
	|FROM
	|	&Standards AS Standards
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Standards.LineNumber,
	|	Standards.Value,
	|	Standards.AllocationPercentage
	|INTO CurRegulations
	|FROM
	|	InformationRegister.StandardsOfSalesPlanAllocationByCategories.SliceLast(
	|			&OnDate,
	|			Attribute = &Attribute
	|				AND ProductCategory = &ProductCategory) AS StandardsForDistributionOfSlices
	|		INNER JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByAttributes AS Standards
	|		ON StandardsForDistributionOfSlices.NormativeStandard = Standards.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	Standards.LineNumber,
	|	Standards.Value,
	|	Standards.AllocationPercentage
	|FROM
	|	InformationRegister.StandardsOfSalesPlanAllocationByCategories.SliceLast(
	|			&OnDate,
	|			Attribute = &Attribute
	|				AND ProductCategory = &ProductCategory) AS StandardsForDistributionOfSlices
	|		INNER JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByProperties AS Standards
	|		ON StandardsForDistributionOfSlices.NormativeStandard = Standards.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 99999
	|	&NameOfValueSProps AS Value,
	|	ISNULL(Standards.AllocationPercentage, ISNULL(CurRegulations.AllocationPercentage, 0)) AS AllocationPercentage,
	|	ISNULL(Standards.LineNumber, 99999) AS Order
	|FROM
	|	&ValueTable AS ValueTable
	|		LEFT JOIN Standards AS Standards
	|		ON &NameOfValueSProps = Standards.Value
	|		LEFT JOIN CurRegulations AS CurRegulations
	|		ON &NameOfValueSProps = CurRegulations.Value
	|WHERE
	|	
	|	&ByProperty_
	|
	|ORDER BY
	|	Order";
	
	ByProperty_ = "";
	NameOfValueSProps = "";
	
	If TypeOf(Attribute) = Type("String") Then
		
		AttributesStructure1 = GetDetailsForRegulations();
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			Return;
			
		EndIf;
		
		TableName = "Catalog.Products";
		NameOfValueSProps = "ValueTable."+Attribute;
		ByProperty_ = "NOT ValueTable.DeletionMark
			|	AND ValueTable.ProductCategory = &ProductCategory";
		
	Else
		
		ByProperty_ = "ValueTable.Property = &Attribute
			|	AND NOT ValueTable.Ref.DeletionMark";
		NameOfValueSProps = "ValueTable.Value";
		
		If FillingVariant = 2 Then
		
			TableName = "Catalog.ItemsCharacteristics.AdditionalAttributes";
			ByProperty_ = ByProperty_ + "
				|	AND (ValueTable.Ref.Owner REFS Catalog.Products
				|				AND ValueTable.Ref.Owner.ProductCategory = &ProductCategory
				|			OR ValueTable.Ref.Owner = &ProductKind)";
				
			ProductKind = Common.ObjectAttributeValue(ProductCategory, "Owner");
			Query.SetParameter("ProductKind", ProductKind);
		Else
		
			TableName = "Catalog.Products.AdditionalAttributes";
			ByProperty_ = ByProperty_ + "
				|	AND ValueTable.Ref.ProductCategory = &ProductCategory";
			
		EndIf; 
		
	EndIf; 
	
	Query.SetParameter("ProductCategory", ProductCategory);
	Query.SetParameter("Attribute", Attribute);
	Query.SetParameter("OnDate", OnDate);
	
	Query.Text = StrReplace(Query.Text, "&ValueTable", TableName);
	Query.Text = StrReplace(Query.Text, "&NameOfValueSProps", NameOfValueSProps);
	Query.Text = StrReplace(Query.Text, "&ByProperty_", ByProperty_);
	
	Query.SetParameter("Standards", Standards.Unload());
	
	QueryResult = Query.Execute();

	ValueTable = QueryResult.Unload();
	
	Standards.Load(ValueTable);

EndProcedure

// Returns a variant of filling in the standard values for the Bank details
//
// Parameters:
//  ProductCategory  - CatalogRef.ProductCategories - Product category in the context of which we get properties
//  Attribute  - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo, String - The prop that
//                                                                                      the option is defined for.
//
// Returns:
//  Number - The value "0" for the item details, "1" for the additional.item details, "2" for
//          additional characteristic details.
//
Function FillingVariant(ProductCategory, Attribute) Export

	FillingVariant = 0;
	
	If ValueIsFilled(Attribute) And TypeOf(Attribute) = Type("String") Then
	
		FillingVariant = 0;
		
	ElsIf ValueIsFilled(Attribute) And TypeOf(Attribute) <> Type("String") Then
		
		FillingVariant = 1;
		
		If GetFunctionalOption("UseItemVariants") Then
			
			Query = New Query;
			Query.Text = 
			"SELECT
			|	Set.Property
			|FROM
			|	Catalog.ItemKinds AS ItemKinds
			|		INNER JOIN Catalog.ProductCategories AS ProductCategories
			|		ON ItemKinds.Ref = ProductCategories.Owner
			|			AND (ProductCategories.Ref = &ProductCategory)
			|		LEFT JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS Set
			|		ON (ItemKinds.UseCharacteristics)
			|			AND (ItemKinds.CharacteristicsPropertySet = Set.Ref
			|				OR Set.Ref = &Set_Catalog_ItemsCharacteristics_Overall)
			|WHERE
			|	Set.Property = &Attribute
			|	AND ItemKinds.UseCharacteristics";
			
			Query.SetParameter("ProductCategory", ProductCategory);
			Query.SetParameter("Attribute", Attribute);
			Query.SetParameter("Set_Catalog_ItemsCharacteristics_Overall", PropertyManager.PropertiesSetByName("Catalog_ItemsCharacteristics_Overall"));
			
			QueryResult = Query.Execute();
			
			If Not QueryResult.IsEmpty() Then
				
				FillingVariant = 2;
				
			EndIf;
		
		EndIf; 
		
	EndIf; 
	
	Return FillingVariant;

EndFunction

// Changes the values of indicators in the table, taking into account the distribution standards for product categories.
//
// Parameters:
//  ResultTable2  - ValueTable - The table where the metrics will be recalculated for the records
//  MetricFieldNames  - Array - array of names of the result table details that will be recalculated according to the standards
//  DistributeByProductRange  - Boolean - This flag determines whether to distribute standards by item
//                                         or only by characteristics.
//
Procedure RecalculateIndicatorsByDistributionStandards(ResultTable2, MetricFieldNames, DistributeByProductRange = True) Export
	
	If ResultTable2.Columns.Find("Period") = Undefined 
		Or ResultTable2.Columns.Find("Products") = Undefined Then
		Return;
	EndIf;
	
	ThereAreValuesOfIndicators = False;
	For Each MetricFieldName In MetricFieldNames Do
	
		If ResultTable2.Columns.Find(MetricFieldName) = Undefined Then
			Return;
		EndIf;
		
		// Recalculation of indicators only if not zero values
		If ResultTable2.Total(MetricFieldName) <> 0 Then
			ThereAreValuesOfIndicators = True;
		EndIf; 
	
	EndDo;
	
	If Not ThereAreValuesOfIndicators Then
		Return;
	EndIf; 
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	If Not DistributeByProductRange And Not UseItemVariants Then
		Return;
	EndIf;
	
	TemplateForAdditionalFields = "
	|	ResultTable2.%FieldName%,";
	AdditionalFields = "";
	For Each Column In ResultTable2.Columns Do
		
		If MetricFieldNames.Find(Column.Name) <> Undefined
			Or Column.Name = "Period"
			Or Column.Name = "Products"
			Or Column.Name = "Characteristic"
			Or Column.Name = "Purpose" Then
			
			Continue;
			
		EndIf; 
		
		FieldName = StrReplace(TemplateForAdditionalFields, "%FieldName%", Column.Name);
		AdditionalFields  = AdditionalFields + FieldName;
	
	EndDo; 
	
	MetricFieldTemplate = "
	|	ResultTable2.%MetricFieldName% AS %MetricFieldName%,";
	TemplateForMaximumMetricFields = "
	|	MAX(ResultTable2.%MetricFieldName%) AS %MetricFieldName%,";
	TemplateForIndicatorFields = "
	|	MAX(%MetricFieldName%)";
	TemplateSelectionOfCompletedIndicators = "
	|	ResultTable2.%MetricFieldName% <> 0";
	TemplateForSelectingIndicatorsThatAreNotFilledIn = "
	|	ResultTable2.%MetricFieldName%  = 0 ";
	
	IndicatorFields = "";
	MaximumMetricFields = "";
	SelectionOfCompletedIndicators = "";
	SelectingIndicatorsThatAreNotFilledIn = "";
	
	TotalsOfIndicatorFields = "";
	
	For Each MetricFieldName In MetricFieldNames Do
		
		FieldName = StrReplace(MetricFieldTemplate, "%MetricFieldName%", MetricFieldName);
		IndicatorFields  = IndicatorFields + FieldName;
		
		FieldName = StrReplace(TemplateForMaximumMetricFields, "%MetricFieldName%", MetricFieldName);
		MaximumMetricFields  = MaximumMetricFields + FieldName;
		
		FieldName = StrReplace(TemplateForIndicatorFields, "%MetricFieldName%", MetricFieldName);
		TotalsOfIndicatorFields  = TotalsOfIndicatorFields +?(ValueIsFilled(TotalsOfIndicatorFields), ", ", "")+ FieldName;
		
		FieldName = StrReplace(TemplateSelectionOfCompletedIndicators, "%MetricFieldName%", MetricFieldName);
		SelectionOfCompletedIndicators  = SelectionOfCompletedIndicators + ?(ValueIsFilled(SelectionOfCompletedIndicators), " OR ", "") + FieldName;
		
		FieldName = StrReplace(TemplateForSelectingIndicatorsThatAreNotFilledIn, "%MetricFieldName%", MetricFieldName);
		SelectingIndicatorsThatAreNotFilledIn  = SelectingIndicatorsThatAreNotFilledIn + ?(ValueIsFilled(SelectingIndicatorsThatAreNotFilledIn), " And ", "") + FieldName;
	
	EndDo; 
	
	SourceDataTable = ResultTable2.Copy();
	ResultTable2.Clear();
	
	If ResultTable2.Columns.Find("Characteristic") = Undefined Then
		SourceDataTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		SourceDataTable.FillValues(Catalogs.ItemsCharacteristics.EmptyRef(), "Characteristic");
	EndIf;
	
	If SourceDataTable.Columns.Find("Purpose") = Undefined Then
		SourceDataTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		SourceDataTable.FillValues(Catalogs.Assignments.EmptyRef(), "Purpose");
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ResultTable2.Period AS Period,
	|	&AdditionalFields AS AdditionalFields,
	|	&IndicatorFields AS IndicatorFields,
	|	ResultTable2.Products AS Products,
	|	ResultTable2.Characteristic,
	|	ResultTable2.Purpose
	|INTO TimeResultTable
	|FROM
	|	&ResultTable2 AS ResultTable2
	|WHERE
	|	&SelectionOfCompletedIndicators
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResultTable2.Period AS Period,
	|	&AdditionalFields AS AdditionalFields,
	|	&IndicatorFields AS IndicatorFields,
	|	ResultTable2.Products AS Products,
	|	ResultTable2.Characteristic,
	|	ResultTable2.Purpose
	|INTO SelectingResultTable
	|FROM
	|	&ResultTable2 AS ResultTable2
	|WHERE
	|	&SelectingIndicatorsThatAreNotFilledIn
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	ResultTable2.Period AS Period,
	|	&AdditionalFields AS AdditionalFields,
	|	&IndicatorFields AS IndicatorFields,
	|	ResultTable2.Products AS Products,
	|	ResultTable2.Characteristic AS Characteristic,
	|	ResultTable2.Purpose AS Purpose,
	|	CatProducts.ProductCategory AS ProductCategory
	|INTO ResultTable2
	|FROM
	|	TimeResultTable AS ResultTable2
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON ResultTable2.Products = CatProducts.Ref
	|
	|INDEX BY
	|	Period,
	|	ProductCategory,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TimeResultTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ResultTable2.Period AS Period,
	|	&MaximumMetricFields AS MaximumMetricFields,
	|	ResultTable2.ProductCategory AS ProductCategory,
	|	ResultTable2.Purpose AS Purpose
	|INTO ProductCategories
	|FROM
	|	ResultTable2 AS ResultTable2
	|WHERE
	|	ResultTable2.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
	|
	|GROUP BY
	|	ResultTable2.Period,
	|	ResultTable2.ProductCategory,
	|	ResultTable2.Purpose
	|
	|INDEX BY
	|	Period,
	|	ProductCategory,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(DistributionStandards.Period) AS StandardPeriod_,
	|	ProductCategories.Period AS Period,
	|	ProductCategories.ProductCategory AS ProductCategory,
	|	DistributionStandards.Attribute
	|INTO RegulatoryPeriods
	|FROM
	|	ProductCategories AS ProductCategories
	|		INNER JOIN InformationRegister.StandardsOfSalesPlanAllocationByCategories AS DistributionStandards
	|		ON ProductCategories.Period >= DistributionStandards.Period
	|			AND ProductCategories.ProductCategory = DistributionStandards.ProductCategory
	|
	|GROUP BY
	|	ProductCategories.Period,
	|	ProductCategories.ProductCategory,
	|	DistributionStandards.Attribute
	|
	|INDEX BY
	|	StandardPeriod_,
	|	ProductCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegulatoryPeriods.Period,
	|	RegulatoryPeriods.ProductCategory,
	|	RegulatoryPeriods.Attribute,
	|	DistributionStandards.NormativeStandard,
	|	DistributionStandards.ByItemVariants
	|INTO Standards
	|FROM
	|	RegulatoryPeriods AS RegulatoryPeriods
	|		INNER JOIN InformationRegister.StandardsOfSalesPlanAllocationByCategories AS DistributionStandards
	|		ON RegulatoryPeriods.StandardPeriod_ = DistributionStandards.Period
	|			AND RegulatoryPeriods.ProductCategory = DistributionStandards.ProductCategory
	|			AND RegulatoryPeriods.Attribute = DistributionStandards.Attribute
	|WHERE
	|	DistributionStandards.Valid
	|	AND ((&UseItemVariants AND DistributionStandards.ByItemVariants)
	|			OR (&DistributeByProductRange AND NOT DistributionStandards.ByItemVariants))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegulatoryPeriods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StandardsOfDistributionStandardsForBankingDetails.Ref AS NormativeStandard,
	|	StandardsOfDistributionStandardsForBankingDetails.Value,
	|	StandardsOfDistributionStandardsForBankingDetails.NormalizedPercentage AS Share
	|INTO ValuesOfStandards
	|FROM
	|	Document.SalesPlansAllocationBaseByCategories.StandardsByAttributes AS StandardsOfDistributionStandardsForBankingDetails
	|WHERE
	|	StandardsOfDistributionStandardsForBankingDetails.Ref IN
	|			(SELECT DISTINCT
	|				Standards.NormativeStandard
	|			FROM
	|				Standards AS Standards)
	|
	|UNION ALL
	|
	|SELECT
	|	DistributionStandardsPropertyStandards.Ref,
	|	DistributionStandardsPropertyStandards.Value,
	|	DistributionStandardsPropertyStandards.NormalizedPercentage
	|FROM
	|	Document.SalesPlansAllocationBaseByCategories.StandardsByProperties AS DistributionStandardsPropertyStandards
	|WHERE
	|	DistributionStandardsPropertyStandards.Ref IN
	|			(SELECT DISTINCT
	|				Standards.NormativeStandard
	|			FROM
	|				Standards AS Standards)
	|
	|INDEX BY
	|	NormativeStandard
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Standards.Period AS Period,
	|	Standards.ProductCategory AS ProductCategory,
	|	Standards.Attribute AS Attribute,
	|	Standards.NormativeStandard,
	|	Standards.ByItemVariants,
	|	AdditionalAttributesAndInfo.ValueType
	|FROM
	|	Standards AS Standards
	|		LEFT JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON Standards.Attribute = AdditionalAttributesAndInfo.Ref
	|
	|ORDER BY
	|	Period,
	|	ProductCategory,
	|	Standards.ByItemVariants,
	|	Attribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP Standards
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResultTable2.Period AS Period,
	|	&IndicatorFields AS IndicatorFields,
	|	ResultTable2.ProductCategory AS ProductCategory,
	|	ResultTable2.Purpose AS Purpose
	|FROM
	|	ProductCategories AS ResultTable2
	|
	|ORDER BY
	|	Period,
	|	ProductCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductCategories.Period AS Period,
	|	ProductCategories.ProductCategory AS ProductCategory,
	|	ProductCategories.Purpose AS Purpose,
	|	CatProducts.Ref AS Products,
	|	CASE
	|		WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		ELSE ItemsCharacteristics.Ref
	|	END AS Characteristic
	|INTO FullCompositionOfProductCategory
	|FROM
	|	ProductCategories AS ProductCategories
	|		INNER JOIN Catalog.Products AS CatProducts
	|			LEFT JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|			ON (CASE
	|					WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|						THEN CatProducts.Ref
	|					WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|						THEN CatProducts.ItemVariantsOwner
	|					WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|						THEN CatProducts.ProductKind
	|					ELSE UNDEFINED
	|				END = ItemsCharacteristics.Owner)
	|		ON ProductCategories.ProductCategory = CatProducts.ProductCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ProductCategories
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FullCompositionOfProductCategory.Period AS Period,
	|	&AdditionalFields AS AdditionalFields,
	|	&IndicatorFields AS IndicatorFields,
	|	FullCompositionOfProductCategory.ProductCategory AS ProductCategory,
	|	FullCompositionOfProductCategory.Purpose AS Purpose,
	|	FullCompositionOfProductCategory.Products AS Products,
	|	FullCompositionOfProductCategory.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ResultTable2.Products IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS NotChoose
	|INTO AugmentedResultTable
	|FROM
	|	FullCompositionOfProductCategory AS FullCompositionOfProductCategory
	|		LEFT JOIN ResultTable2 AS ResultTable2
	|		ON FullCompositionOfProductCategory.Period = ResultTable2.Period
	|			AND FullCompositionOfProductCategory.ProductCategory = ResultTable2.ProductCategory
	|			AND FullCompositionOfProductCategory.Products = ResultTable2.Products
	|			AND FullCompositionOfProductCategory.Characteristic = ResultTable2.Characteristic
	|			AND FullCompositionOfProductCategory.Purpose = ResultTable2.Purpose
	|
	|INDEX BY
	|	Period,
	|	ProductCategory,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResultTable2.Period AS Period,
	|	&AdditionalFields AS AdditionalFields,
	|	&IndicatorFields AS IndicatorFields,
	|	ResultTable2.Products AS Products,
	|	ResultTable2.Characteristic,
	|	ResultTable2.Purpose
	|FROM
	|	SelectingResultTable AS ResultTable2
	|
	|UNION ALL
	|
	|SELECT
	|	ResultTable2.Period AS Period,
	|	&AdditionalFields AS AdditionalFields,
	|	&IndicatorFields AS IndicatorFields,
	|	ResultTable2.Products AS Products,
	|	ResultTable2.Characteristic,
	|	ResultTable2.Purpose
	|FROM
	|	ResultTable2 AS ResultTable2
	|WHERE
	|	ResultTable2.ProductCategory = VALUE(Catalog.ProductCategories.EmptyRef)
	|
	|ORDER BY
	|	Period,
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SelectingResultTable";
	
	Query.Text = StrReplace(Query.Text, "&AdditionalFields AS AdditionalFields,", AdditionalFields);
	Query.Text = StrReplace(Query.Text, "&IndicatorFields AS IndicatorFields,", IndicatorFields);
	Query.Text = StrReplace(Query.Text, "&MaximumMetricFields AS MaximumMetricFields,", MaximumMetricFields);
	
	Query.Text = StrReplace(Query.Text, "&SelectionOfCompletedIndicators", SelectionOfCompletedIndicators);
	Query.Text = StrReplace(Query.Text, "&SelectingIndicatorsThatAreNotFilledIn", SelectingIndicatorsThatAreNotFilledIn);
	
	Query.SetParameter("ResultTable2", SourceDataTable);
	
	Query.SetParameter("UseItemVariants", UseItemVariants);
	Query.SetParameter("DistributeByProductRange", DistributeByProductRange);
	
	TempTablesManager = New TempTablesManager();
	Query.TempTablesManager = TempTablesManager;
	
	QueryResults = Query.ExecuteBatch();
	
	ResultTable2.Clear();
	
	TableOfStandards = QueryResults[9].Unload();
	SamplingProductCategories = QueryResults[11].Select();
	
	SelectionResultTable = QueryResults[15].Select();
	While SelectionResultTable.Next() Do
		NewRow = ResultTable2.Add();
		FillPropertyValues(NewRow, SelectionResultTable);
	EndDo;
	
	QueryTemplate = 
	"SELECT
	|	ResultTable2.Period,
	|	&AdditionalFields AS AdditionalFields,
	|	ResultTable2.Products,
	|	ResultTable2.Characteristic,
	|	ResultTable2.Purpose,
	|	ResultTable2.ProductCategory,
	|	ResultTable2.NotChoose,
	|	&TextShareTest AS TextShareTest,
	|	&TextShare AS Share
	|FROM
	|	AugmentedResultTable AS ResultTable2
	|WHERE
	|	ResultTable2.Period = &Period
	|	AND ResultTable2.ProductCategory = &ProductCategory
	|	AND ResultTable2.Purpose = &Purpose";
	
	TextConnection_ = "AugmentedResultTable AS ResultTable2
						|		WHERE &TextSharedByBankingDetails
						|		AND &TextByProperties
						|		AND &TextOnPropertiesCharacteristics";
	QueryTemplate = StrReplace(QueryTemplate, "AugmentedResultTable AS ResultTable2", TextConnection_);
	
	If DistributeByProductRange Then
		QueryTemplate = StrReplace(QueryTemplate, "&AdditionalFields AS AdditionalFields,", AdditionalFields);
	Else
		
		QueryTemplate = StrReplace(QueryTemplate, "&AdditionalFields AS AdditionalFields,", AdditionalFields + " " + IndicatorFields);
	
		QueryTemplate = QueryTemplate + "
		|TOTALS
		|	&TotalsOfIndicatorFields
		|BY
		|	Products";
		
		QueryTemplate = StrReplace(QueryTemplate, "&TotalsOfIndicatorFields", TotalsOfIndicatorFields);
	
	EndIf; 
	
	ShareTemplate = "ISNULL(ValuesOfStandards%StandardNumber%.Share, 0)";
	TemplateShareTest = "ValuesOfStandards%StandardNumber%.Share AS Share%StandardNumber%, ";
	
	TemplateSharedByDetails = "
	|		INNER JOIN Catalog.Products AS CatProducts
	|			%ZaproByBankingDetails%
	|		ON ResultTable2.Products = CatProducts.Ref";
	TemplateByBankingDetails = "
	|			LEFT JOIN ValuesOfStandards AS ValuesOfStandards%StandardNumber%
	|			ON (ValuesOfStandards%StandardNumber%.NormativeStandard = &NormativeStandard%StandardNumber%)
	|				AND CatProducts.%AttributeName% = ValuesOfStandards%StandardNumber%.Value"; 
	
	TemplateByProperties = "
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS AddAttributes%StandardNumber%
	|		ON (AddAttributes%StandardNumber%.Property = &Property%StandardNumber%)
	|			AND ResultTable2.Products = AddAttributes%StandardNumber%.Ref
	|		LEFT JOIN ValuesOfStandards AS ValuesOfStandards%StandardNumber%
	|		ON (ValuesOfStandards%StandardNumber%.NormativeStandard = &NormativeStandard%StandardNumber%)
	|			AND (CASE
	|				WHEN ISNULL(AddAttributes%StandardNumber%.Value, UNDEFINED) = ValuesOfStandards%StandardNumber%.Value
	|					THEN TRUE
	|				WHEN ISNULL(AddAttributes%StandardNumber%.Value, FALSE) = ValuesOfStandards%StandardNumber%.Value
	|					THEN TRUE
	|				ELSE FALSE
	|			END)";
	
	TemplateForPropertiesCharacteristics = "
	|		LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS AddAttributes%StandardNumber%
	|		ON (AddAttributes%StandardNumber%.Property = &Property%StandardNumber%)
	|			AND ResultTable2.Characteristic = AddAttributes%StandardNumber%.Ref
	|		LEFT JOIN ValuesOfStandards AS ValuesOfStandards%StandardNumber%
	|		ON (ValuesOfStandards%StandardNumber%.NormativeStandard = &NormativeStandard%StandardNumber%)
	|			AND (CASE
	|				WHEN ISNULL(AddAttributes%StandardNumber%.Value, UNDEFINED) = ValuesOfStandards%StandardNumber%.Value
	|					THEN TRUE
	|				WHEN ISNULL(AddAttributes%StandardNumber%.Value, FALSE) = ValuesOfStandards%StandardNumber%.Value
	|					THEN TRUE
	|				ELSE FALSE
	|			END)";
	
	// Bypass by periods and product categories - in order to get their own standards for each period for the product category.
	While SamplingProductCategories.Next() Do
		
		Query.SetParameter("Period", SamplingProductCategories.Period);
		Query.SetParameter("ProductCategory", SamplingProductCategories.ProductCategory);
		Query.SetParameter("Purpose", SamplingProductCategories.Purpose);
		
		TextShare = "";
		TextShareTest = "";
		TextSharedByBankingDetails = "";
		TextByBankingDetails = "";
		TextByProperties = "";
		TextOnPropertiesCharacteristics = "";
		
		Filter = New Structure;
		Filter.Insert("Period", SamplingProductCategories.Period);
		Filter.Insert("ProductCategory", SamplingProductCategories.ProductCategory);
		
		// For each of the current standards, we add a request for a Cartesian product.
		FoundStandards = TableOfStandards.FindRows(Filter);
		NormativeStandard = 0;
		For Each FoundStandard In FoundStandards Do
			
			NormativeStandard = NormativeStandard + 1;
			StandardNumber = Format(NormativeStandard, "NG=0");
			
			If TypeOf(FoundStandard.Attribute) = Type("String") Then
				// Request for item details
				
				TextShare = TextShare + ?(IsBlankString(TextShare), "", " * ") + StrReplace(ShareTemplate, "%StandardNumber%", StandardNumber);
				TextSharedByBankingDetails = TemplateSharedByDetails;
				
				QueryText = StrReplace(TemplateByBankingDetails, "%AttributeName%", FoundStandard.Attribute);
				TextByBankingDetails = TextByBankingDetails + StrReplace(QueryText, "%StandardNumber%", StandardNumber);
				Query.SetParameter("NormativeStandard"+StandardNumber, FoundStandard.NormativeStandard);
				
				TextShareTest = TextShareTest + StrReplace(TemplateShareTest, "%StandardNumber%", StandardNumber);
				
			Else
				If UseItemVariants And FoundStandard.ByItemVariants Then
					// Request for an addendum.the details of the characteristics of the nomenclature
					
					TextShare = TextShare + ?(IsBlankString(TextShare), "", " * ") + StrReplace(ShareTemplate, "%StandardNumber%", StandardNumber);
					TextByFeatureProperty = StrReplace(TemplateForPropertiesCharacteristics, "%StandardNumber%", StandardNumber);
					
					If ValueIsFilled(FoundStandard.ValueType) 
						And FoundStandard.ValueType.Types().Count() = 1
						And Common.IsReference(FoundStandard.ValueType.Types()[0]) Then
						
						TableName = Common.TableNameByRef(FoundStandard.ValueType.AdjustValue(Undefined));
						TextByFeatureProperty = StrReplace(TextByFeatureProperty, "UNDEFINED", "VALUE("+TableName+".EmptyRef)");
					
					EndIf;
					
					TextOnPropertiesCharacteristics = TextOnPropertiesCharacteristics + TextByFeatureProperty;
					Query.SetParameter("NormativeStandard"+StandardNumber, FoundStandard.NormativeStandard);
					Query.SetParameter("Property"+StandardNumber, FoundStandard.Attribute);
					
					TextShareTest = TextShareTest + StrReplace(TemplateShareTest, "%StandardNumber%", StandardNumber);
				
				Else
					// Request for additional details of the item
					
					TextShare = TextShare + ?(IsBlankString(TextShare), "", " * ") + StrReplace(ShareTemplate, "%StandardNumber%", StandardNumber);
					
					TextByProperty = StrReplace(TemplateByProperties, "%StandardNumber%", StandardNumber);
					If ValueIsFilled(FoundStandard.ValueType) 
						And FoundStandard.ValueType.Types().Count() = 1
						And Common.IsReference(FoundStandard.ValueType.Types()[0]) Then
						
						TableName = Common.TableNameByRef(FoundStandard.ValueType.AdjustValue(Undefined));
						TextByProperty = StrReplace(TextByProperty, "UNDEFINED", "VALUE("+TableName+".EmptyRef)");
					
					EndIf; 
					
					TextByProperties = TextByProperties + TextByProperty;
					Query.SetParameter("NormativeStandard"+StandardNumber, FoundStandard.NormativeStandard);
					Query.SetParameter("Property"+StandardNumber, FoundStandard.Attribute);
					
					TextShareTest = TextShareTest + StrReplace(TemplateShareTest, "%StandardNumber%", StandardNumber);
				
				EndIf
			EndIf;
			
		EndDo; 
		
		If Not IsBlankString(TextSharedByBankingDetails) Then
			TextSharedByBankingDetails = StrReplace(TextSharedByBankingDetails, "%ZaproByBankingDetails%", TextByBankingDetails);
		EndIf; 
		
		If IsBlankString(TextShare) Then
			// If there are no standards, we will distribute them proportionally
			TextShare = "1";
		
		EndIf; 
		
		Query.Text = QueryTemplate;
		
		Query.Text = StrReplace(Query.Text, "WHERE &TextSharedByBankingDetails", TextSharedByBankingDetails);
		
		Query.Text = StrReplace(Query.Text, "&TextShareTest AS TextShareTest,", TextShareTest);
		Query.Text = StrReplace(Query.Text, "&TextShare", TextShare);
		
		Query.Text = StrReplace(Query.Text, "AND &TextOnPropertiesCharacteristics", TextOnPropertiesCharacteristics);
		
		Query.Text = StrReplace(Query.Text, "AND &TextByProperties", TextByProperties);		
		
		QueryResult = Query.Execute();
		
		If DistributeByProductRange Then
			
			Allocation = QueryResult.Unload();
			
			ArrayOfCoefficients = Allocation.UnloadColumn("Share");
			For Each MetricFieldName In MetricFieldNames Do
				ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(
					SamplingProductCategories[MetricFieldName],
					ArrayOfCoefficients,
					3);
				If Allocation.Columns.Find(MetricFieldName) = Undefined Then
					Allocation.Columns.Add(MetricFieldName, TMCommonUse.GetDescriptionOfNumberTypes(15,3));
				EndIf;
				If ArrayOfAmounts <> Undefined Then
					Allocation.LoadColumn(ArrayOfAmounts, MetricFieldName);
				EndIf; 
			EndDo;
			
			For Each DistributionString In Allocation Do
				If DistributionString.NotChoose Then
					Continue;
				EndIf;
				NewRow = ResultTable2.Add();
				FillPropertyValues(NewRow, DistributionString);
				
			EndDo;
		
		Else
			
			Allocation = QueryResult.Unload(QueryResultIteration.ByGroups);
			
			For Each MetricFieldName In MetricFieldNames Do
				If Allocation.Columns.Find(MetricFieldName) = Undefined Then
					Allocation.Columns.Add(MetricFieldName, TMCommonUse.GetDescriptionOfNumberTypes(15,3));
				EndIf;
			EndDo;
			
			For Each CharacteristicDistributionString In Allocation.Rows Do
				
				ArrayOfCoefficients = CharacteristicDistributionString.Rows.UnloadColumn("Share");
				For Each MetricFieldName In MetricFieldNames Do
					ArrayOfAmounts = Common.DistributeAmountInProportionToCoefficients(
						CharacteristicDistributionString[MetricFieldName],
						ArrayOfCoefficients,
						3);
					If ArrayOfAmounts <> Undefined Then
						CharacteristicDistributionString.Rows.LoadColumn(ArrayOfAmounts, MetricFieldName);
					EndIf;
				EndDo;
				
				For Each DistributionString In CharacteristicDistributionString.Rows Do
					If DistributionString.NotChoose Then
						Continue;
					EndIf;
					NewRow = ResultTable2.Add();
					FillPropertyValues(NewRow, DistributionString);
					
				EndDo;
			EndDo; 
			
			
		
		EndIf; 
		 
	
	EndDo; 
	
	TempTablesManager.Close();

EndProcedure

// The function returns a table of standards for the product
//
// Parameters:
//  OnDate - Date - The date on which the current distribution standards are determined.
//  Products - CatalogRef.Products - The item item for which standards are defined.
//  Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the nomenclature for which
//                   standards are defined.
//  StandardsForProducts - Boolean - The flag determines whether or not the standards for the nomenclature or just the characteristics.
//
// Returns:
//  ValueTable - a table with established standards.
//
Function GetDistributionStandards(OnDate, Products, Characteristic = Undefined, StandardsForProducts = True) Export
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	If Not StandardsForProducts And Not UseItemVariants Then
		Return Undefined;
	EndIf;
	
	If Characteristic = Undefined Then
		Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	CatalogProducts.Ref AS Products,
	|	ISNULL(CatalogCharacteristics.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	CatalogProducts.ProductCategory AS ProductCategory
	|INTO TimeResultTable
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		LEFT JOIN Catalog.ItemsCharacteristics AS CatalogCharacteristics
	|		ON (CatalogCharacteristics.Ref = &Characteristic)
	|			AND (CatalogCharacteristics.Owner = CASE
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|					THEN CatalogProducts.ProductKind
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|					THEN CatalogProducts.Ref
	|				WHEN CatalogProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|					THEN CatalogProducts.ItemVariantsOwner
	|				ELSE FALSE
	|			END)
	|WHERE
	|	CatalogProducts.Ref = &Products
	|	AND CatalogProducts.ProductCategory <> VALUE(Catalog.ProductCategories.EmptyRef)
	|
	|INDEX BY
	|	ProductCategory,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StandardsForDistributionOfSlices.ProductCategory,
	|	StandardsForDistributionOfSlices.Attribute,
	|	StandardsForDistributionOfSlices.NormativeStandard,
	|	StandardsForDistributionOfSlices.ByItemVariants
	|INTO DistributionStandards
	|FROM
	|	InformationRegister.StandardsOfSalesPlanAllocationByCategories.SliceLast(
	|			&OnDate,
	|			ProductCategory IN
	|				(SELECT DISTINCT
	|					ResultTable2.ProductCategory
	|				FROM
	|					TimeResultTable AS ResultTable2)) AS StandardsForDistributionOfSlices
	|WHERE
	|	StandardsForDistributionOfSlices.Valid
	|	AND (&UseItemVariants AND StandardsForDistributionOfSlices.ByItemVariants)
	|			OR (&StandardsForProducts AND NOT StandardsForDistributionOfSlices.ByItemVariants)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DistributionStandards.ProductCategory,
	|	DistributionStandards.Attribute,
	|	DistributionStandards.NormativeStandard,
	|	DistributionStandards.ByItemVariants,
	|	ResultTable2.Products,
	|	ResultTable2.Characteristic
	|INTO ResultTable2
	|FROM
	|	TimeResultTable AS ResultTable2
	|		INNER JOIN DistributionStandards AS DistributionStandards
	|		ON ResultTable2.ProductCategory = DistributionStandards.ProductCategory
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DistributionStandards
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TimeResultTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResultTable2.ProductCategory,
	|	ResultTable2.Attribute,
	|	ResultTable2.NormativeStandard,
	|	ResultTable2.ByItemVariants
	|FROM
	|	ResultTable2 AS ResultTable2
	|WHERE
	|	NOT ResultTable2.ByItemVariants
	|	AND VALUETYPE(ResultTable2.Attribute) = TYPE(STRING)";
	
	
	
	Query.SetParameter("UseItemVariants", UseItemVariants);
	
	Query.SetParameter("StandardsForProducts", StandardsForProducts);
	
	Query.SetParameter("Products",   Products);
	Query.SetParameter("Characteristic", Characteristic);
	Query.SetParameter("OnDate",         OnDate);
	
	TempTablesManager = New TempTablesManager();
	Query.TempTablesManager = TempTablesManager;
	
	QueryResults = Query.ExecuteBatch();  

	SelectionDetailRecords = QueryResults[5].Select();
	
	
	Query.Text = 
	"SELECT
	|	RequestingResults.NormativeStandard AS Document,
	|	RequestingResults.NormativeStandard.Number AS DocumentNumber,
	|	RequestingResults.NormativeStandard.Date AS DocumentDate,
	|	ISNULL(StandardsByProperties.AllocationPercentage, 0) AS AllocationPercentage
	|FROM
	|	(SELECT
	|		ResultTable2.NormativeStandard AS NormativeStandard,
	|		ISNULL(ProductsAdditionalDetails.Value, UNDEFINED) AS Value
	|	FROM
	|		ResultTable2 AS ResultTable2
	|			LEFT JOIN Catalog.Products.AdditionalAttributes AS ProductsAdditionalDetails
	|			ON ResultTable2.Products = ProductsAdditionalDetails.Ref
	|				AND ResultTable2.Attribute = ProductsAdditionalDetails.Property
	|	WHERE
	|		VALUETYPE(ResultTable2.Attribute) <> TYPE(STRING)
	|		AND NOT ResultTable2.ByItemVariants) AS RequestingResults
	|		INNER JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByProperties AS StandardsByProperties
	|		ON RequestingResults.NormativeStandard = StandardsByProperties.Ref
	|			AND (RequestingResults.Value = StandardsByProperties.Value
	|				OR RequestingResults.Value = UNDEFINED
	|					AND StandardsByProperties.ThisIsAnEmptyValue)
	|
	|UNION ALL
	|
	|SELECT
	|	RequestingResults.NormativeStandard,
	|	RequestingResults.NormativeStandard.Number,
	|	RequestingResults.NormativeStandard.Date,
	|	ISNULL(StandardsByProperties.AllocationPercentage, 0)
	|FROM
	|	(SELECT
	|		ResultTable2.NormativeStandard AS NormativeStandard,
	|		ISNULL(ItemsCharacteristicsAdditionalAttributes.Value, UNDEFINED) AS Value
	|	FROM
	|		ResultTable2 AS ResultTable2
	|			LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS ItemsCharacteristicsAdditionalAttributes
	|			ON ResultTable2.Characteristic = ItemsCharacteristicsAdditionalAttributes.Ref
	|				AND ResultTable2.Attribute = ItemsCharacteristicsAdditionalAttributes.Property
	|	WHERE
	|		VALUETYPE(ResultTable2.Attribute) <> TYPE(STRING)
	|		AND ResultTable2.ByItemVariants) AS RequestingResults
	|		INNER JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByProperties AS StandardsByProperties
	|		ON RequestingResults.NormativeStandard = StandardsByProperties.Ref
	|			AND (RequestingResults.Value = StandardsByProperties.Value
	|				OR RequestingResults.Value = UNDEFINED
	|					AND StandardsByProperties.ThisIsAnEmptyValue)
	|";
	
	RequestTemplateForBankingDetails = 
	"
	|
	|UNION ALL
	|
	|SELECT
	|	ResultTable2.NormativeStandard,
	|	ResultTable2.NormativeStandard.Number,
	|	ResultTable2.NormativeStandard.Date,
	|	ISNULL(StandardsByAttributes.AllocationPercentage, 0)
	|FROM
	|	ResultTable2 AS ResultTable2
	|		LEFT JOIN Document.SalesPlansAllocationBaseByCategories.StandardsByAttributes AS StandardsByAttributes
	|		ON ResultTable2.NormativeStandard = StandardsByAttributes.Ref
	|			AND &QueryTextAttributeName = StandardsByAttributes.Value
	|WHERE
	|	ResultTable2.Attribute = &RequestTextDetailsByStandardNumber";
	
	NormativeStandard = 0;
	While SelectionDetailRecords.Next() Do
		
		NormativeStandard = NormativeStandard + 1;
		StandardNumber = Format(NormativeStandard, "NG=0");
		
		RequestTextByBankingDetails = StrReplace(
			RequestTemplateForBankingDetails, 
			"&RequestTextDetailsByStandardNumber", 
			"&Attribute"+StandardNumber);
		
		RequestTextByBankingDetails = StrReplace(
			RequestTextByBankingDetails, 
			"&QueryTextAttributeName", 
			"ResultTable2.Products."+ SelectionDetailRecords.Attribute +"");
		
		Query.Text = Query.Text + RequestTextByBankingDetails;
		
		Query.SetParameter("Attribute"+StandardNumber, SelectionDetailRecords.Attribute);
		
	EndDo;

	QueryResult = Query.Execute();
	
	TableOfStandards = QueryResult.Unload();
	
	TempTablesManager.Close();
	
	Return TableOfStandards;

EndFunction 

////////////////////////////////////////////////////////////////////////////////
// Interface for working with the File Upload subsystem.

// Sets the download parameters.
//
// Parameters:
//  Parameters - Structure - structure of parameters to load from a file to the table part.
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	DescriptionLength = 150;
	
	If TypeOf(Parameters.AdditionalParameters.Attribute) = Type("String") Then
		
		AttributesStructure1 = GetDetailsForRegulations();
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Parameters.AdditionalParameters.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			Return;
			
		EndIf;
		
		MDOfObject = Metadata.FindByFullName(AttributeStructure.TableName);
		
		DescriptionLength = MDOfObject.DescriptionLength;
	Else
		
		DescriptionOfValueType = Common.ObjectAttributeValue(Parameters.AdditionalParameters.Attribute, "ValueType");
		MDOfObject = Metadata.FindByType(DescriptionOfValueType.Types()[0]);
		
		DescriptionLength = MDOfObject.DescriptionLength;
	EndIf;
	
	Parameters.ColumnDataType.Insert("Value", New TypeDescription("String",, New StringQualifiers(DescriptionLength)));
	
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
//   AdditionalParameters   - Structure - additional parameters.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Standards =  GetFromTempStorage(AddressOfMappingTable); // See MapDataToImport.ConflictsList 
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // See MapDataToImport.ConflictsList
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(DataForComparison.Value AS STRING(&DescriptionLength)) AS Value,
	|	DataForComparison.Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ValueTable.Ref) AS LinkValue,
	|	DataForComparison.Id,
	|	COUNT(DataForComparison.Id) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN &ValueTable AS ValueTable
	|		ON (ValueTable.Description = DataForComparison.Value)
	|			AND &FilterText1
	|WHERE
	|	NOT ValueTable.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.Id";
	
	FilterText1 = "";
	
	If TypeOf(AdditionalParameters.Attribute) = Type("String") Then
		
		AttributesStructure1 = GetDetailsForRegulations();
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(AdditionalParameters.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			Return;
			
		EndIf;
		
		TableName = AttributeStructure.TableName;
		MDOfObject = Metadata.FindByFullName(TableName);
		
	Else
	
		ValueType = Common.ObjectAttributeValue(AdditionalParameters.Attribute, "ValueType");
		If Not Common.IsReference(ValueType.Types()[0]) Then
			
			Return;
		
		EndIf; 
		
		MDOfObject = Metadata.FindByType(ValueType.Types()[0]);
		TableName = MDOfObject.FullName();
		
		If Common.IsCatalog(MDOfObject) And MDOfObject.Owners.Contains(Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo) Then
			FilterText1 = "AND ValueTable.Owner = &Attribute";
		EndIf;
		
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&DescriptionLength", MDOfObject.DescriptionLength);
	
	If (Metadata.Catalogs.Contains(MDOfObject) 
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MDOfObject)) 
		And MDOfObject.Hierarchical 
		And MDOfObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
		
		FilterText1 = FilterText1 + "
			|	AND NOT ValueTable.IsFolder";
	EndIf; 
	
	Query.SetParameter("Attribute", AdditionalParameters.Attribute);
	
	Query.Text = StrReplace(Query.Text, "&ValueTable", TableName);
	Query.Text = StrReplace(Query.Text, "AND &FilterText1", FilterText1);
	
	
	Query.SetParameter("DataForComparison", DataToImport);
	
	QueriesResults = Query.ExecuteBatch();
	
	TableValue = QueriesResults[1].Unload();
	
	For Each TableRow In DataToImport Do 
		
		NewRow = Standards.Add();
		NewRow.Id = TableRow.Id;
		NewRow.AllocationPercentage = TableRow.AllocationPercentage;
		
		StringValue2 = TableValue.Find(TableRow.Id, "Id");
		If StringValue2 <> Undefined Then 
			If StringValue2.Count = 1 Then 
				NewRow.Value  = StringValue2.LinkValue;
			ElsIf StringValue2.Count > 1 Then 
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id; 
				WritingAboutAmbiguity.Column = "Value";
			EndIf;
		EndIf;
		
	EndDo;
	
	PutToTempStorage(Standards, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
//
// Parameters:
//  FullTabularSectionName  - String - full name of the table part where data is loaded
//  ConflictsList    - Array - list with ambiguous data
//  ColumnName                - String - name of the column where the ambiguity occurs
//  LoadedValuesString - String - Loaded data based on which the ambiguity occurred
//   AdditionalParameters   - Structure - additional parameters
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	If ColumnName = "Value" Then

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
	
	
EndProcedure

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

#Region Posting

Function QueryTextTableStandardsOfSalesPlanAllocationByCategories(Query, QueryTexts, Registers)
	
	RegisterName = "StandardsOfSalesPlanAllocationByCategories";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	Document.ValidityStartDate AS Period,
	|	Document.ProductCategory,
	|	Document.Attribute,
	|	CASE
	|		WHEN Document.Operation = VALUE(Enum.TransactionsOfStandardsAllocation.SetStandard)
	|			THEN Document.Ref
	|		ELSE UNDEFINED
	|	END AS NormativeStandard,
	|	CASE
	|		WHEN Document.Operation = VALUE(Enum.TransactionsOfStandardsAllocation.SetStandard)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Valid,
	|	CASE
	|		WHEN Document.FillingVariant = 2
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ByItemVariants
	|FROM
	|	Document.SalesPlansAllocationBaseByCategories AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
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
	
	Return; // Stub
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
