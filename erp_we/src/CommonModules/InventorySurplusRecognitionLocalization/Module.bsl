
#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	AccountingForTraceableGoodsLocalization.ToClearQuantityByRPTVWhenSurplusGoodsAreStockSurplusRecognition(Object);
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export


EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure

// Returns data for the formation of the MX - 1 printing form.
//
// Parameters:
//	PrintParameters	- Structure -additional print settings.
//	ObjectsArray	- Array of DocumentRef.InventorySurplusRecognition - collection of values of links to documents
//																				for which you want to get data.
//
// Returns:
//	Structure - a collection of data used for printing, containing the following properties:
//		* HeaderResults			- QueryResult - data for the document header.
//		* WarehouseResults		- QueryResult - data about the responsible storage warehouse.
//		* ResultForTabularPart	- QueryResult - data of the tabular part of the document.
//		* ErrorResults		- QueryResult - data about errors that occur when printing a document.
//
Function GetDataForMX1PrintingPlate(PrintParameters, ObjectsArray) Export
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	
	If Not ValueIsFilled(ColumnOfCodes) Then
		ColumnOfCodes = "Code";
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref									AS Ref,
	|	ISNULL(DocumentData.CorrectedDocument.Number, DocumentData.Number)	AS Number,
	|	ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date)	AS Date,
	|	ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date)	AS DocumentDate,
	|	DocumentData.Organization								AS Organization,
	|	DocumentData.Warehouse									AS Warehouse,
	|	ISNULL(Warehouses.CustodyWarehouse, FALSE)		AS CustodyWarehouse,
	|	DocumentData.Organization = Warehouses.Depository	AS CompanyDepositor,
	|	Warehouses.SourseOfInformationAboutPricesForPrinting				AS SourseOfInformationAboutPricesForPrinting,
	|	Warehouses.AccountingPriceType									AS PriceKind,
	|	Warehouses.AccountingPriceType.PriceCurrency						AS PriceCurrency,
	|	InventoryCostCalculationCompanies.Ref.PreliminaryCalculation	AS PreliminaryCalculation,
	|	DocumentData.Date									AS DateOfReceiptOfCostPrice
	|INTO DocumentData
	|FROM
	|	Document.InventorySurplusRecognition AS DocumentData
	|		LEFT JOIN Document.InventoryCostCalculation.Companies AS InventoryCostCalculationCompanies
	|		ON InventoryCostCalculationCompanies.Ref.Date BETWEEN BEGINOFPERIOD(DocumentData.Date, MONTH) AND ENDOFPERIOD(DocumentData.Date, MONTH)
	|			AND InventoryCostCalculationCompanies.Ref.Posted
	|			AND DocumentData.Organization = InventoryCostCalculationCompanies.Organization
	|			AND InventoryCostCalculationCompanies.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|		
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON DocumentData.Warehouse = Warehouses.Ref
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Ref IN(&DocumentsArray)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentData.Ref								AS Ref,
	|	DocumentData.Number								AS Number,
	|	DocumentData.Date								AS Date,
	|	DocumentData.DocumentDate						AS DocumentDate,
	|	DocumentData.Organization							AS Organization,
	|	DocumentData.Warehouse								AS Warehouse,
	|	DocumentData.SourseOfInformationAboutPricesForPrinting	AS SourseOfInformationAboutPricesForPrinting,
	|	DocumentData.PriceKind								AS PriceKind,
	|	DocumentData.PriceCurrency							AS PriceCurrency,
	|	DocumentData.PreliminaryCalculation				AS PreliminaryCalculation,
	|	DocumentData.DateOfReceiptOfCostPrice			AS DateOfReceiptOfCostPrice
	|INTO TTHeader
	|FROM
	|	DocumentData AS DocumentData
	|WHERE
	|	DocumentData.CustodyWarehouse
	|	AND NOT DocumentData.CompanyDepositor
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.Ref AS Ref,
	|	Header.Warehouse AS Warehouse,
	|	Goods.Products.UnitOfMeasure AS Package,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Series AS Series,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Products.UnitOfMeasure.Presentation AS UnitOfMeasurementName,
	|	Goods.Products.UnitOfMeasure.Code AS UnitOfMeasureCode,
	|	Goods.Products.UnitOfMeasure.Presentation AS PackageKind,
	|	Goods.Count AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	ENDOFPERIOD(Goods.Ref.Date, DAY) AS DateOfPriceReceipt,
	|	Header.PriceKind AS PriceKind,
	|	Header.PriceCurrency AS PriceCurrency
	|INTO TTProducts_1
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS Goods
	|		INNER JOIN TTHeader AS Header
	|		ON Goods.Ref = Header.Ref
	|WHERE
	|	Goods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (Header.SourseOfInformationAboutPricesForPrinting = VALUE(Enum.SourcesOfPriceInformationForPrinting.ByPriceType)
	|		OR (Header.SourseOfInformationAboutPricesForPrinting = VALUE(Enum.SourcesOfPriceInformationForPrinting.ByCost)
	|			AND Header.PreliminaryCalculation IS NULL))
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Header.Organization AS Organization,
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure AS Package,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure.Presentation AS UnitOfMeasurementName,
	|	InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure.Code AS UnitOfMeasureCode,
	|	InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure.Presentation PackageKind,
	|	InventoryKinds.Count AS NumberOfPackages,
	|	InventoryKinds.Count AS Count,
	|	ENDOFPERIOD(InventoryKinds.Ref.Date, DAY) AS DateOfPriceReceipt,
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation.AccountingPriceType AS PriceKind,
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation.AccountingPriceType.PriceCurrency AS PriceCurrency,
	|	Header.PreliminaryCalculation AS PreliminaryCalculation
	|INTO TTTypesOfStocks
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS InventoryKinds
	|		INNER JOIN TTHeader AS Header
	|		ON InventoryKinds.Ref = Header.Ref
	|WHERE
	|	InventoryKinds.ItemsLocationAttributes.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND InventoryKinds.ItemsLocationAttributes.StorageLocation.SourseOfInformationAboutPricesForPrinting = VALUE(Enum.SourcesOfPriceInformationForPrinting.ByCost)
	|;
	|";
	
	WarehousesServer.AddRequestTextForPrintedFormsMX1X3(Query);
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("ColumnOfCodes", ColumnOfCodes);
	
	ResultsArray = Query.ExecuteBatch();
	HeaderResults			= ResultsArray[ResultsArray.UBound() - 3];
	WarehouseResults			= ResultsArray[ResultsArray.UBound() - 2];
	ResultForTabularPart	= ResultsArray[ResultsArray.UBound() - 1];
	ErrorResults			= ResultsArray[ResultsArray.UBound()];
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",			HeaderResults);
	DataStructureForPrinting.Insert("WarehouseResults",			WarehouseResults);
	DataStructureForPrinting.Insert("ResultForTabularPart",	ResultForTabularPart);
	DataStructureForPrinting.Insert("ErrorResults",			ErrorResults);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion
#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion
#EndRegion

#Region Private

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure


#EndRegion

#EndRegion
