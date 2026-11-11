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
	
	If TypeOf(Document) = Type("DocumentObject.ProductRangeChange") Then
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
		
		QueryTextTableProductRange(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ForAllRows(ValueAllowed(ISNULL(Goods.PriceKind, VALUE(Catalog.TypesOfPrices.EmptyRef))))";

EndProcedure

// End StandardSubsystems.AccessManagement

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
	
	Documents.ProductRangeChange.AddCreateCommandBasedOnCreateOrderForInternalConsumption(GenerationCommands);
	
	Documents.ProductRangeChange.AddCreateCommandBasedOnCreateMoveOrder(GenerationCommands);
	
	DataProcessors.SetUpStockReplenishment.AddInstallInventoryMaintenanceCommand(GenerationCommands);
	
	DataProcessors.SetUpStockReplenishment.AddConfigureInventoryMaintenanceCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddGenerateCommand(GenerationCommands);
	
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command of creation of the document "changing the range".
// 
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// 
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddCreateCommandBasedOnCreateOrderForInternalConsumption(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryConsumptionOrder) And GetFunctionalOption("UseProductRange") Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateOrderForInternalConsumption";
		CreateBasedOnCommand.Id = "CreateOrderForInternalConsumption";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Đơn hàng tiêu dùng nội bộ';
												|ru = 'Заказ на внутреннее потребление';
												|en = 'Inventory consumption order'; fa = 'سفارش مصرف موجودی';
												|it = 'Ordine per il consumo interno';
												|pl = 'Zamówienie na konsumpcję wewnętrzną';
												|tr = 'Stok tüketim siparişi'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseInventoryConsumptionOrders";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command of creation of the document "changing the range".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddCreateCommandBasedOnCreateMoveOrder(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.TransferOrder) And GetFunctionalOption("UseProductRange") Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateTransferOrder";
		CreateBasedOnCommand.Id = "CreateTransferOrder";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
												|ru = 'Заказ на перемещение';
												|en = 'Transfer order'; fa = 'سفارش انتقال';
												|it = 'Ordine di trasferimento';
												|pl = 'Zamówienie na przesunięcie';
												|tr = 'Transfer emri'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferOrders";
		
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
//      * Id - Number - sequence number of the line;
//       the remaining columns correspond to the columns of the File upload layout.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document
//                                        that needs to be filled in from the addressable Data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//     * Column       - String - name of the column where the ambiguity was detected
//     * Id - Number  - ID of the string where the ambiguity was detected.
//   FullTabularSectionName   - String - full name of the table part where data is loaded.
//   AdditionalParameters   - Structure - Contains:
//      * ItemsCollection  - CatalogRef.ItemsCollections - collection of items.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Goods =  GetFromTempStorage(AddressOfMappingTable); // See MapDataToImport.ConflictsList
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // See MapDataToImport.ConflictsList
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(DataForComparison.Barcode AS STRING(&BarcodeLength_)) AS Barcode,
	|	CAST(DataForComparison.Code AS STRING(&Code_Length)) AS Code,
	|	CAST(DataForComparison.SKU AS STRING(&ArticleLength)) AS SKU,
	|	CAST(DataForComparison.Products AS STRING(&ProductLength)) AS Products,
	|	CAST(DataForComparison.PriceKind AS STRING(&TypesOfPricesLength)) AS PriceKind,
	|	CAST(DataForComparison.SalesRank AS STRING(&SalesRatingLength)) AS SalesRank,
	|	DataForComparison.Id AS Id
	|INTO DataForComparison
	|FROM
	|	&DataForComparison AS DataForComparison
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ItemsBarcodes.Products AS ProductsLink,
	|	ItemsBarcodes.Barcode,
	|	DataForComparison.Id AS Id
	|INTO MappedProductByBarcode
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON (ItemsBarcodes.Barcode = DataForComparison.Barcode)
	|WHERE
	|	NOT ItemsBarcodes.Products IS NULL 
	|	AND CASE
	|			WHEN &UseCollectionManagement
	|				THEN ItemsBarcodes.Products.ItemsCollection = &ItemsCollection
	|			ELSE TRUE
	|		END
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForComparison.Code,
	|	DataForComparison.Id AS Id
	|INTO DataToMatchByCode
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN MappedProductByBarcode AS MappedProductByBarcode
	|		ON (DataForComparison.Barcode = MappedProductByBarcode.Barcode)
	|WHERE
	|	MappedProductByBarcode.Barcode IS NULL 
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatProducts.Ref AS ProductsLink,
	|	CatProducts.Code,
	|	DataForComparison.Id AS Id
	|INTO MappedProductsByCode
	|FROM
	|	DataToMatchByCode AS DataForComparison
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON (CatProducts.Code = DataForComparison.Code)
	|WHERE
	|	NOT CatProducts.Ref IS NULL 
	|	AND CASE
	|			WHEN &UseCollectionManagement
	|				THEN CatProducts.ItemsCollection = &ItemsCollection
	|			ELSE TRUE
	|		END
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForComparison.Products,
	|	DataForComparison.Id AS Id
	|INTO DataForMatchingByName
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN MappedProductByBarcode AS MappedProductByBarcode
	|		ON (DataForComparison.Barcode = MappedProductByBarcode.Barcode)
	|		LEFT JOIN MappedProductsByCode AS MappedProductsByCode
	|		ON (DataForComparison.Code = MappedProductsByCode.Code)
	|WHERE
	|	MappedProductByBarcode.Barcode IS NULL 
	|	AND MappedProductsByCode.Code IS NULL 
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(CatProducts.Ref) AS ProductsLink,
	|	DataForMatchingByName.Id,
	|	COUNT(DataForMatchingByName.Id) AS Count
	|FROM
	|	DataForMatchingByName AS DataForMatchingByName
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON (CatProducts.Description = DataForMatchingByName.Products)
	|WHERE
	|	NOT CatProducts.Ref IS NULL 
	|	AND CASE
	|			WHEN &UseCollectionManagement
	|				THEN CatProducts.ItemsCollection = &ItemsCollection
	|			ELSE TRUE
	|		END
	|
	|GROUP BY
	|	DataForMatchingByName.Id
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(MappedProductByBarcode.ProductsLink),
	|	MappedProductByBarcode.Id,
	|	COUNT(MappedProductByBarcode.Id)
	|FROM
	|	MappedProductByBarcode AS MappedProductByBarcode
	|
	|GROUP BY
	|	MappedProductByBarcode.Id
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(MappedProductsByCode.ProductsLink),
	|	MappedProductsByCode.Id,
	|	COUNT(MappedProductsByCode.Id)
	|FROM
	|	MappedProductsByCode AS MappedProductsByCode
	|
	|GROUP BY
	|	MappedProductsByCode.Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TypesOfPrices.Ref) AS PriceTypeReference,
	|	DataForComparison.Id,
	|	COUNT(DataForComparison.Id) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
	|		ON (TypesOfPrices.UseWhileSellingToCustomers)
	|			AND (TypesOfPrices.Description = DataForComparison.PriceKind)
	|WHERE
	|	NOT TypesOfPrices.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(SalesRanks.Ref) AS SalesRatingLink,
	|	DataForComparison.Id,
	|	COUNT(DataForComparison.Id) AS Count
	|FROM
	|	DataForComparison AS DataForComparison
	|		LEFT JOIN Catalog.SalesRanks AS SalesRanks
	|		ON (SalesRanks.Description = DataForComparison.SalesRank)
	|WHERE
	|	NOT SalesRanks.Ref IS NULL 
	|
	|GROUP BY
	|	DataForComparison.Id";
	
	BarcodeLength_ = Metadata.InformationRegisters.ItemsBarcodes.Dimensions.Find("Barcode").Type.StringQualifiers.Length;
	MetadataProducts = Metadata.Catalogs.Products;
	Code_Length = MetadataProducts.CodeLength;
	ArticleLength = MetadataProducts.Attributes.Find("SKU").Type.StringQualifiers.Length;
	ProductLength = MetadataProducts.DescriptionLength;
	TypesOfPricesLength = Metadata.Catalogs.TypesOfPrices.DescriptionLength;
	SalesRatingLength = Metadata.Catalogs.SalesRanks.DescriptionLength;
	
	Query.Text = StrReplace(Query.Text, "&BarcodeLength_", BarcodeLength_);
	Query.Text = StrReplace(Query.Text, "&Code_Length", Code_Length);
	Query.Text = StrReplace(Query.Text, "&ArticleLength", ArticleLength);
	Query.Text = StrReplace(Query.Text, "&ProductLength", ProductLength);
	Query.Text = StrReplace(Query.Text, "&TypesOfPricesLength", TypesOfPricesLength);
	Query.Text = StrReplace(Query.Text, "&SalesRatingLength", SalesRatingLength);
	
	If DataToImport.Columns.Find("PriceKind") = Undefined 
		Or DataToImport.Columns.Find("SalesRank") = Undefined Then
	
		DataForComparison = DataToImport.Copy();
		If DataToImport.Columns.Find("PriceKind") = Undefined Then
			DataForComparison.Columns.Add("PriceKind", New TypeDescription("String"));
		EndIf;
		
		If DataToImport.Columns.Find("SalesRank") = Undefined Then
			DataForComparison.Columns.Add("SalesRank", New TypeDescription("String")); 
		EndIf;
	Else
		DataForComparison = DataToImport;
	EndIf; 
	
	Query.SetParameter("DataForComparison", DataForComparison);
	Query.SetParameter("UseCollectionManagement", GetFunctionalOption("UseCollectionManagement"));
	Query.SetParameter("ItemsCollection", AdditionalParameters.ItemsCollection);
	
	QueriesResults = Query.ExecuteBatch();
	
	TableOfProducts = QueriesResults[5].Unload();
	TableTypesOfPrices = QueriesResults[6].Unload();
	TableSalesRatings = QueriesResults[7].Unload();
	
	ProductRangeRoles = New Map;
	ProductRangeRoles.Insert(NStr("vi = 'Phân loại hàng hóa thường xuyên';
									|ru = 'Постоянный ассортимент';
									|en = 'Regular product range'; fa = 'سبد محصول عادی';
									|it = 'Gamma costante';
									|pl = 'Stały asortyment';
									|tr = 'Kalıcı ürün gamı'"), Enums.ProductRangeRoles.RegularProductRange);
	ProductRangeRoles.Insert("RegularProductRange", Enums.ProductRangeRoles.RegularProductRange);
	ProductRangeRoles.Insert(NStr("vi = 'Danh điểm hàng hóa bổ sung';
									|ru = 'Дополнительный ассортимент';
									|en = 'Additional product range'; fa = 'سبد محصول تکمیلی';
									|it = 'Gamma opzionale';
									|pl = 'Dodatkowy asortyment';
									|tr = 'Ek ürün gamı'"), Enums.ProductRangeRoles.AdditionalProductRange);
	ProductRangeRoles.Insert("AdditionalProductRange", Enums.ProductRangeRoles.AdditionalProductRange);
	ProductRangeRoles.Insert(NStr("vi = 'Danh điểm hàng hóa bán thử';
									|ru = 'Пробный ассортимент';
									|en = 'Trial product range'; fa = 'سبد محصول آزمایشی';
									|it = 'Gamma di prova';
									|pl = 'Próbny asortyment';
									|tr = 'Deneme ürün gamı'"), Enums.ProductRangeRoles.TrialProductRange);
	ProductRangeRoles.Insert("TrialProductRange", Enums.ProductRangeRoles.TrialProductRange);
	
	UseSeveralPriceTypes = GetFunctionalOption("UseSeveralPriceTypes");
	
	For Each TableRow In DataToImport Do 
		
		NewRow = Goods.Add();
		NewRow.Id = TableRow.Id;
		NewRow.ProductRangeRole = ProductRangeRoles.Get(TrimAll(TableRow.ProductRangeRole));
		
		StringProducts_ = TableOfProducts.Find(TableRow.Id, "Id");
		If StringProducts_ <> Undefined Then 
			If StringProducts_.Count = 1 Then 
				NewRow.Products  = StringProducts_.ProductsLink;
			ElsIf StringProducts_.Count > 1 Then 
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id; 
				WritingAboutAmbiguity.Column = "Products";
			EndIf;
		EndIf;
		
		If UseSeveralPriceTypes Then
			
			PriceViewString = TableTypesOfPrices.Find(TableRow.Id, "Id");
			If PriceViewString <> Undefined Then 
				If PriceViewString.Count = 1 Then 
					NewRow.PriceKind  = PriceViewString.PriceTypeReference;
				ElsIf PriceViewString.Count > 1 Then 
					WritingAboutAmbiguity = ConflictsList.Add();
					WritingAboutAmbiguity.Id = TableRow.Id; 
					WritingAboutAmbiguity.Column = "PriceKind";
				EndIf;
			EndIf;
		
		EndIf; 
		
		SalesRatingLine_ = TableSalesRatings.Find(TableRow.Id, "Id");
		If SalesRatingLine_ <> Undefined Then 
			If SalesRatingLine_.Count = 1 Then 
				NewRow.SalesRank  = SalesRatingLine_.SalesRatingLink;
			ElsIf SalesRatingLine_.Count > 1 Then 
				WritingAboutAmbiguity = ConflictsList.Add();
				WritingAboutAmbiguity.Id = TableRow.Id; 
				WritingAboutAmbiguity.Column = "SalesRank";
			EndIf;
		EndIf;
	EndDo;
	
	PutToTempStorage(Goods, AddressOfMappingTable);
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
//
// Parameters:
//   FullTabularSectionName  - String - full name of the table part where data is loaded.
//  ConflictsList    - Array - list with ambiguous data
//  ColumnName                - String - name of the column where the ambiguity occurs
//  LoadedValuesString - String - Loaded data based on which the ambiguity occurred
//  AdditionalParameters   - Structure - structure of additional parameters
//
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	If ColumnName = "Products" Then

		Query = New Query;
		Query.Text = 
		"SELECT
		|	Products.Ref
		|FROM
		|	Catalog.Products AS Products
		|WHERE
		|	Products.Description = &Description";
		Query.SetParameter("Description", LoadedValuesString.Products);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			ConflictsList.Add(SelectionDetailRecords.Ref);
		EndDo;
	EndIf;
	
	If ColumnName = "SalesRank" Then

		Query = New Query;
		Query.Text = 
		"SELECT
		|	SalesRatings.Ref
		|FROM
		|	Catalog.SalesRanks AS SalesRatings
		|WHERE
		|	SalesRatings.Description = &Description";
		Query.SetParameter("Description", LoadedValuesString.SalesRank);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			ConflictsList.Add(SelectionDetailRecords.Ref);
		EndDo;
	EndIf;
	
	If ColumnName = "PriceKind" Then

		Query = New Query;
		Query.Text = 
		"SELECT
		|	TypesOfPrices.Ref
		|FROM
		|	Catalog.TypesOfPrices AS TypesOfPrices
		|WHERE
		|	TypesOfPrices.Description = &Description
		|	AND TypesOfPrices.UseWhileSellingToCustomers";
		Query.SetParameter("Description", LoadedValuesString.PriceKind);
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

Function QueryTextTableProductRange(Query, QueryTexts, Registers)
	
	RegisterName = "ProductRange";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	Goods.Ref.Date AS Period,
	|	Goods.Products AS Products,
	|	Goods.Ref.PlanningObject AS PlanningObject,
	|	Goods.ProductRangeRole AS ProductRangeRole,
	|	CASE
	|		WHEN Goods.Ref.Phase = VALUE(Enum.ProductRangePhases.OnlyPurchasesAreAllowed)
	|			THEN TRUE
	|		WHEN Goods.Ref.Phase = VALUE(Enum.ProductRangePhases.PurchasesAndSalesArePermitted)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS PurchasesAreAllowed,
	|	CASE
	|		WHEN Goods.Ref.Phase = VALUE(Enum.ProductRangePhases.OnlySalesAreAllowed)
	|			THEN TRUE
	|		WHEN Goods.Ref.Phase = VALUE(Enum.ProductRangePhases.PurchasesAndSalesArePermitted)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SalesAreAllowed,
	|	Goods.PriceKind AS PriceKind,
	|	Goods.SalesRank AS SalesRank,
	|	Goods.Ref.ItemsCollection AS ItemsCollection
	|FROM
	|	Document.ProductRangeChange.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Operation = VALUE(Enum.ProductRangeChangeTransactions.ChangeInProductRange)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.PurchaseStartDate,
	|	Goods.Products,
	|	Goods.Ref.PlanningObject,
	|	Goods.ProductRangeRole,
	|	TRUE,
	|	CASE
	|		WHEN Goods.Ref.PurchaseStartDate = Goods.Ref.SalesStartDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	Goods.PriceKind,
	|	Goods.SalesRank AS SalesRank,
	|	Goods.Ref.ItemsCollection
	|FROM
	|	Document.ProductRangeChange.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Operation = VALUE(Enum.ProductRangeChangeTransactions.CollectionManagement)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.SalesStartDate,
	|	Goods.Products,
	|	Goods.Ref.PlanningObject,
	|	Goods.ProductRangeRole,
	|	CASE
	|		WHEN Goods.Ref.PurchaseRestrictionDate > Goods.Ref.SalesStartDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	TRUE,
	|	Goods.PriceKind,
	|	Goods.SalesRank AS SalesRank,
	|	Goods.Ref.ItemsCollection
	|FROM
	|	Document.ProductRangeChange.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Operation = VALUE(Enum.ProductRangeChangeTransactions.CollectionManagement)
	|	AND Goods.Ref.PurchaseStartDate <> Goods.Ref.SalesStartDate
	|			AND Goods.Ref.PurchaseRestrictionDate <> Goods.Ref.SalesStartDate
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.PurchaseRestrictionDate,
	|	Goods.Products,
	|	Goods.Ref.PlanningObject,
	|	Goods.ProductRangeRole,
	|	FALSE,
	|	CASE
	|		WHEN Goods.Ref.PurchaseRestrictionDate < Goods.Ref.SalesRestrictionDate
	|				AND Goods.Ref.PurchaseRestrictionDate >= Goods.Ref.SalesStartDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	Goods.PriceKind,
	|	Goods.SalesRank AS SalesRank,
	|	Goods.Ref.ItemsCollection
	|FROM
	|	Document.ProductRangeChange.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Operation = VALUE(Enum.ProductRangeChangeTransactions.CollectionManagement)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Ref.SalesRestrictionDate,
	|	Goods.Products,
	|	Goods.Ref.PlanningObject,
	|	Goods.ProductRangeRole,
	|	CASE
	|		WHEN Goods.Ref.PurchaseRestrictionDate > Goods.Ref.SalesRestrictionDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	FALSE,
	|	Goods.PriceKind,
	|	Goods.SalesRank AS SalesRank,
	|	Goods.Ref.ItemsCollection
	|FROM
	|	Document.ProductRangeChange.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Operation = VALUE(Enum.ProductRangeChangeTransactions.CollectionManagement)
	|	AND Goods.Ref.PurchaseRestrictionDate <> Goods.Ref.SalesRestrictionDate
	|
	|ORDER BY
	|	Period,
	|	Products,
	|	PlanningObject";
	
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

// Adds a command of creation of the document "changing the range".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ProductRangeChange) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ProductRangeChange.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ProductRangeChange);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProductRange";
		
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

#EndRegion

#EndIf
