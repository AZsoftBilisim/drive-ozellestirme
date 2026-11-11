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
	
	DocumentMechanisms.Add("InventoryInOperation");
	DocumentMechanisms.Add("DocumentsRegistry");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PhysicalCountOfInventoryInOperation") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

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

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.PhysicalCountOfInventoryInOperation";
	
	SeriesSpecificationParameters.UseItemsBatch = InventoryInOperationCached.ItIsPossibleToTakeIntoAccountSeriesInOperation();
	SeriesSpecificationParameters.UseCostAccountingByBatches = SeriesSpecificationParameters.UseItemsBatch;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.PhysicalCountOfInventoryInOperation);
	
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.FieldNameQuantity = "Quantity_Actual";
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
// 
// Parameters:
//	SeriesSpecificationParameters - See SeriesSpecificationParameters
//		
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingInventoryInOperation
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 20
	|					ELSE 19
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|
	|INTO Statuses
	|
	|FROM
	|	Goods AS Goods
	|
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Series = ProductsToRequest.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.RecordInventoryInOperation.AddGenerateCommand(GenerationCommands);
	Documents.OtherGoodsRecordingAsReceived.AddGenerateCommand(GenerationCommands);
	Documents.TransferInOperation.AddGenerateCommand(GenerationCommands);
	Documents.Decomissioning.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "FA Inventory".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.PhysicalCountOfInventoryInOperation) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PhysicalCountOfInventoryInOperation.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PhysicalCountOfInventoryInOperation);
		CreateBasedOnCommand.WriteMode = "Post";
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

// Returns data for filling in the document based on the inventory.
//
// Parameters:
// 		DocumentBasis - DocumentRef.PhysicalCountOfInventoryInOperation - Link to the inventory document.
// 		Date - Date - Date of filling.
// 		Action - EnumRef.ActionsBasedOnPhysicalInventoryCount - In the framework of which action it is required to receive data (registration, write-off, refund).
// 		ArrayOfLineNumbers - Array of Number - An array with line numbers based on which to fill out the document.
//
// Returns:
//  Structure - Contains:
//  	* Attributes - QueryResult - Result of the request for data Attributes of the document
//  	* TabularSection - QueryResult - Result of a query for data in the table part
//
Function FillingDataBasedOnInventory(DocumentBasis, Date, Action = Undefined, Val ArrayOfLineNumbers = Undefined) Export
	
	TableManager = New TempTablesManager;

	AddCreatedDocumentsBasedOn(TableManager, DocumentBasis);
	
	QueryText =
	"SELECT
	|	DocumentData.Date AS DocumentDate,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Individual AS Individual
	|FROM
	|	Document.PhysicalCountOfInventoryInOperation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.AssetID AS AssetID,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Individual AS Individual,
	|	SUM(GoodsTable.QuantityAccordingToAccountingData) AS QuantityAccordingToAccountingData,
	|	SUM(GoodsTable.Quantity_Actual) AS Quantity_Actual
	|FROM
	|	Document.PhysicalCountOfInventoryInOperation.Goods AS GoodsTable
	|
	|		LEFT JOIN TTDocumentsBasedOn AS DocumentsBasedOn
	|		ON (GoodsTable.Ref.Individual = DocumentsBasedOn.Individual
	|				OR GoodsTable.Ref.Individual = VALUE(Catalog.Persons.EmptyRef)
	|					AND GoodsTable.Individual = DocumentsBasedOn.Individual)
	|
	|			AND (GoodsTable.AssetID = DocumentsBasedOn.AssetID
	|				OR GoodsTable.AssetID = """"
	|					AND GoodsTable.Action = VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived))
	|
	|			AND GoodsTable.Products = DocumentsBasedOn.Products
	|			AND GoodsTable.Characteristic = DocumentsBasedOn.Characteristic
	|			AND GoodsTable.Series = DocumentsBasedOn.Series
	|			AND GoodsTable.Action = DocumentsBasedOn.Action
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|	AND (NOT &ArrayOfLineNumbersIsSet
	|			OR GoodsTable.LineNumber IN (&ArrayOfLineNumbers))
	|
	|	AND (NOT &ActionSet
	|			OR GoodsTable.Action = &Action)
	|
	|	AND DocumentsBasedOn.Ref IS NULL
	|
	|GROUP BY
	|	GoodsTable.AssetID,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Individual
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TableManager;
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Date", Date);
	Query.SetParameter("ActionSet", ValueIsFilled(Action));
	Query.SetParameter("Action", Action);
	Query.SetParameter("ArrayOfLineNumbers", ?(ArrayOfLineNumbers = Undefined, New Array, ArrayOfLineNumbers));
	Query.SetParameter("ArrayOfLineNumbersIsSet", ?(ArrayOfLineNumbers = Undefined, False, True));
	
	Result = Query.ExecuteBatch();
	
	FillingData = New Structure;
	FillingData.Insert("Attributes", Result[Result.UBound()-1]);
	FillingData.Insert("TabularSection", Result[Result.UBound()]);
	
	Return FillingData;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.PhysicalCountOfInventoryInOperation";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.DeletionMark,
	|	DocumentData.Number,
	|	DocumentData.Posted,
	|	DocumentData.Comment,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.EmployeeResponsible
	|FROM
	|	Document.PhysicalCountOfInventoryInOperation AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.PhysicalCountOfInventoryInOperation"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.PhysicalCountOfInventoryInOperation);

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region FillType

// Returns IA accounting data.
//
// Parameters:
//  Ref - DocumentRef.PhysicalCountOfInventoryInOperation - 
//  Date - Date	- The date to get the data for.
//	Organization - CatalogRef.Companies -
//  Department - CatalogRef.BusinessStructure -
//  ListOfShoppingCenters - FormDataCollection - A list of Inventory centers to get data for.
//
// Returns:
//  ValueTable - Contains accounting data: 
//  	* Organization - CatalogRef.Companies -
//  	* Department - CatalogRef.BusinessStructure -
//  	* AssetID - String -
//  	* Products - CatalogRef.Products -
//  	* Characteristic - CatalogRef.ItemsCharacteristics -
//  	* Series - CatalogRef.ItemsBatches -
//  	* Individual - CatalogRef.Persons -
//  	* QuantityAccordingToAccountingData - Number -
//
Function DataOfAccounting(Ref, Date, Organization, Department, ListOfShoppingCenters) Export

	DataOfAccounting = New ValueTable();
	DataOfAccounting.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	DataOfAccounting.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	DataOfAccounting.Columns.Add("AssetID", Metadata.DefinedTypes.InventoryNumberOfInventoryInOperation.Type);
	DataOfAccounting.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	DataOfAccounting.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	DataOfAccounting.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	DataOfAccounting.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	DataOfAccounting.Columns.Add("QuantityAccordingToAccountingData", Common.TypeDescriptionNumber(15, 3));

	If ListOfShoppingCenters.Count() = 0 Then
		Return DataOfAccounting;
	EndIf;
	
	QueryText =
	"SELECT
	|	ListOfShoppingCenters.Products AS Products,
	|	ListOfShoppingCenters.Characteristic AS Characteristic,
	|	ListOfShoppingCenters.Series AS Series,
	|	ListOfShoppingCenters.AssetID AS AssetID
	|INTO ListOfShoppingCenters
	|FROM
	|	&ListOfShoppingCenters AS ListOfShoppingCenters
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	AssetID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InventoryInOperation.Organization AS Organization,
	|	InventoryInOperation.Department AS Department,
	|	InventoryInOperation.Individual AS Individual,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.AssetID AS AssetID,
	|	SUM(InventoryInOperation.QuantityAccordingToAccountingData) AS QuantityAccordingToAccountingData
	|FROM
	|	(SELECT
	|		InventoryInOperation.Organization AS Organization,
	|		InventoryInOperation.Department AS Department,
	|		InventoryInOperation.Individual AS Individual,
	|		InventoryInOperation.Products AS Products,
	|		InventoryInOperation.Characteristic AS Characteristic,
	|		InventoryInOperation.Series AS Series,
	|		InventoryInOperation.AssetID AS AssetID,
	|		InventoryInOperation.CountBalance AS QuantityAccordingToAccountingData
	|	FROM
	|		AccumulationRegister.InventoryInOperation.Balance(
	|				&Date,
	|				(Products, Characteristic, Series, AssetID) IN (
	|					SELECT
	|						ListOfShoppingCenters.Products,
	|						ListOfShoppingCenters.Characteristic,
	|						ListOfShoppingCenters.Series,
	|						ListOfShoppingCenters.AssetID
	|					FROM
	|						ListOfShoppingCenters AS ListOfShoppingCenters)) AS InventoryInOperation
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series AS Series,
	|		GoodsTable.AssetID AS AssetID,
	|		-GoodsTable.Count AS QuantityAccordingToAccountingData
	|	FROM
	|		Document.RecordInventoryInOperation AS DocumentData
	|
	|			INNER JOIN Document.RecordInventoryInOperation.Goods AS GoodsTable
	|			ON GoodsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &Ref
	|		AND &Ref <> VALUE(Document.PhysicalCountOfInventoryInOperation.EmptyRef)
	|		AND DocumentData.Organization = &Organization
	|		AND DocumentData.Department = &Department
	|		AND DocumentData.Date < &Date
	|		
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series AS Series,
	|		GoodsTable.AssetID AS AssetID,
	|		GoodsTable.Count AS QuantityAccordingToAccountingData
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived AS DocumentData
	|
	|			INNER JOIN Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|			ON GoodsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &Ref
	|		AND &Ref <> VALUE(Document.PhysicalCountOfInventoryInOperation.EmptyRef)
	|		AND DocumentData.Organization = &Organization
	|		AND DocumentData.Department = &Department
	|		AND DocumentData.Date < &Date
	|		
	|	UNION ALL
	|
	|	SELECT
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|		GoodsTable.Individual AS Individual,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Series AS Series,
	|		GoodsTable.AssetID AS AssetID,
	|		GoodsTable.Count AS QuantityAccordingToAccountingData
	|	FROM
	|		Document.Decomissioning AS DocumentData
	|
	|			INNER JOIN Document.Decomissioning.Goods AS GoodsTable
	|			ON GoodsTable.Ref = DocumentData.Ref
	|
	|	WHERE
	|		DocumentData.Posted
	|		AND DocumentData.DocumentBasis = &Ref
	|		AND &Ref <> VALUE(Document.PhysicalCountOfInventoryInOperation.EmptyRef)
	|		AND DocumentData.Organization = &Organization
	|		AND DocumentData.Department = &Department
	|		AND DocumentData.Date < &Date
	|
	|	) AS InventoryInOperation
	|
	|GROUP BY
	|	InventoryInOperation.Organization,
	|	InventoryInOperation.Department,
	|	InventoryInOperation.Individual,
	|	InventoryInOperation.Products,
	|	InventoryInOperation.Characteristic,
	|	InventoryInOperation.Series,
	|	InventoryInOperation.AssetID
	|
	|HAVING
	|	SUM(InventoryInOperation.QuantityAccordingToAccountingData) >=0
	|";
	
	Table_Inventory = New ValueTable();
	Table_Inventory.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Table_Inventory.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Table_Inventory.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	Table_Inventory.Columns.Add("AssetID", Metadata.DefinedTypes.InventoryNumberOfInventoryInOperation.Type);
	
	CommonClientServer.SupplementTable(ListOfShoppingCenters, Table_Inventory);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("Date", ?(ValueIsFilled(Date), EndOfDay(Date), EndOfDay(CurrentSessionDate())));
	Query.SetParameter("ListOfShoppingCenters", Table_Inventory);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		InventoryAccountingData = DataOfAccounting.Add();
		FillPropertyValues(InventoryAccountingData, Selection);
	
	EndDo;
	
	DataOfAccounting.Indexes.Add("Organization,Department,AssetID,Products,Characteristic,Series,Individual");
	
	Return DataOfAccounting;
	
EndFunction

// Fill in the accounting data.
// 
// Parameters:
//  Object - DocumentObject.PhysicalCountOfInventoryInOperation - Object
//  RowsCollection - FormDataCollection - Collection of strings
//  FillInServiceDetails - Boolean - Fill In Service Details
//	SetAction - Boolean - False if you need to leave the previously set action
Procedure FillInAccountingData(Object, RowsCollection, FillInServiceDetails = False, SetAction = True) Export

	DataOfAccounting = DataOfAccounting(
		Object.Ref, Object.Date, Object.Organization, Object.Department, RowsCollection);
	
	For Each RowData In RowsCollection Do
		
		LineAccountingData = LineAccountingData(Object.Organization, Object.Department, Object.Individual, RowData, DataOfAccounting);
		
		InventoryInOperationClientServer.FillInInventoryLineBasedOnAccountingData(
			Object, RowData, LineAccountingData, FillInServiceDetails, SetAction);
		
	EndDo; 

EndProcedure

// Gets accounting data for the Inventory line.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  Department - CatalogRef.BusinessStructure - Department
//  Individual - CatalogRef.Persons - A natural person
//  RowData - FormDataCollectionItem - this line
//  DataOfAccounting - See DataOfAccounting
// 
// Returns:
//  Undefined, Structure - Line Accounting Data:
// 		* Organization - CatalogRef.Companies -
// 		* Department - CatalogRef.BusinessStructure -
// 		* AssetID - String -
// 		* Products - CatalogRef.Products -
// 		* Characteristic - CatalogRef.ItemsCharacteristics -
// 		* Series - CatalogRef.ItemsBatches -
// 		* Individual - CatalogRef.Persons -
// 		* QuantityAccordingToAccountingData - Number -
Function LineAccountingData(Organization, Department, Individual, RowData, DataOfAccounting) Export
	
	FoundAccountingData = DataOfAccounting.FindRows(InventoryKey(Organization, Department, Individual, RowData));
	
	If FoundAccountingData.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	LineAccountingData = New Structure;
	LineAccountingData.Insert("Organization", FoundAccountingData[0].Organization);
	LineAccountingData.Insert("Department", FoundAccountingData[0].Department);
	LineAccountingData.Insert("Products", FoundAccountingData[0].Products);
	LineAccountingData.Insert("Characteristic", FoundAccountingData[0].Characteristic);
	LineAccountingData.Insert("Series", FoundAccountingData[0].Series);
	LineAccountingData.Insert("Individual", FoundAccountingData[0].Individual);
	LineAccountingData.Insert("QuantityAccordingToAccountingData", FoundAccountingData[0].QuantityAccordingToAccountingData);
	
	If ValueIsFilled(FoundAccountingData[0].AssetID) Then
		LineAccountingData.Insert("AssetID", FoundAccountingData[0].AssetID);
	Else
		LineAccountingData.Insert("AssetID", "");
	EndIf;
	
	Return LineAccountingData;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PhysicalCountOfInventoryInOperationLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

// Overrides the parameters for loading data from a file.
//
// Parameters:
//  Parameters - Structure:
//   * DataStructureTemplateName - String - the name of the layout. For example, "Uploading a file".
//   * TabularSectionName - String - The full name of the table part. For example, "Document._account to the payer.The table is missing.Products"
//   * RequiredColumns2 - Array of String - names of required columns.
//   * ColumnDataType - Map of KeyAndValue:
//      * Key - String - column name;
//      * Value - TypeDescription - the type of the column of uploaded data.
//   * AdditionalParameters - Structure
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
    
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
//
// Parameters:
//   AddressOfUploadedData - String - the address of the temporary storage with the table of values in which the downloaded data from the file is located. 
//   							Composition of columns: 
//     								ID - Number - sequence number of the line;
//     								The remaining columns correspond to the columns of the File Upload Template.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values, which is a copy of the tabular part of the document, 
//                                        which must be filled in from the Addressable data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//   							Composition of columns: 
//       							* Column - String - name of the column where the ambiguity was detected;
//       							* Id - Number - ID of the string where the ambiguity was detected.
//   FullTabularSectionName - String - full name of the table part where data is loaded.
//   AdditionalParameters - Arbitrary - Any additional information.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export

	QueryText =
	"SELECT
	|	DataToImport.Id AS Id,
	|	DataToImport.AssetID AS AssetID,
	|	DataToImport.ProductsAndServicesCode AS ProductsAndServicesCode,
	|	DataToImport.ProductIDOfItems AS ProductIDOfItems,
	|	DataToImport.Products AS Products,
	|	DataToImport.Characteristic AS Characteristic,
	|	DataToImport.Series AS Series,
	|	DataToImport.Individual AS Individual,
	|	DataToImport.Quantity_Actual AS Quantity_Actual,
	|	DataToImport.Comment AS Comment,
	|	DataToImport.ActionName AS ActionName
	|
	|INTO TTDownloadableData
	|
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DataToImport.Id AS Id,
	|	InventoryInOperation.Products AS Products,
	|	InventoryInOperation.Characteristic AS Characteristic,
	|	InventoryInOperation.Series AS Series,
	|	InventoryInOperation.Individual AS Individual,
	|	
	|	RECORDAUTONUMBER() AS RecNo
	|
	|INTO TTAllDataOnInventoryNumbers
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN AccumulationRegister.InventoryInOperation AS InventoryInOperation
	|		ON InventoryInOperation.AssetID = DataToImport.AssetID
	|			AND InventoryInOperation.Period < &Period
	|
	|WHERE
	|	DataToImport.AssetID <> """"
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnInventoryNumbers.Id AS Id,
	|	TTAllDataOnInventoryNumbers.Products AS Products,
	|	TTAllDataOnInventoryNumbers.Characteristic AS Characteristic,
	|	TTAllDataOnInventoryNumbers.Series AS Series,
	|	TTAllDataOnInventoryNumbers.Individual AS Individual,
	|	DataOnInventoryNumbers.Count AS Count
	|
	|INTO TTDataOnInventoryNumbers
	|
	|FROM
	|	(SELECT
	|		TTAllDataOnInventoryNumbers.Id AS Id,
	|		MAX(TTAllDataOnInventoryNumbers.RecNo) AS RecNo,
	|		COUNT(TTAllDataOnInventoryNumbers.RecNo) AS Count
	|	FROM
	|		TTAllDataOnInventoryNumbers AS TTAllDataOnInventoryNumbers
	|
	|	GROUP BY
	|		TTAllDataOnInventoryNumbers.Id
	|
	|	) AS DataOnInventoryNumbers
	|	
	|		INNER JOIN TTAllDataOnInventoryNumbers AS TTAllDataOnInventoryNumbers
	|		ON TTAllDataOnInventoryNumbers.RecNo = DataOnInventoryNumbers.RecNo
	|
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatProducts.Ref) AS Ref,
	|	COUNT(CatProducts.Ref) AS Count
	|
	|INTO TTProductsByArticle
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.SKU = DataToImport.ProductIDOfItems
	|			AND NOT CatProducts.DeletionMark
	|			AND NOT CatProducts.IsFolder
	|
	|WHERE
	|	DataToImport.ProductIDOfItems <> """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatProducts.Ref) AS Ref,
	|	COUNT(CatProducts.Ref) AS Count
	|
	|INTO TTProductListByCode
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
	|			AND NOT CatProducts.DeletionMark
	|			AND NOT CatProducts.IsFolder
	|
	|WHERE
	|	DataToImport.ProductsAndServicesCode <> """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatProducts.Ref) AS Ref,
	|	COUNT(CatProducts.Ref) AS Count
	|
	|INTO TTProductListByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Description = DataToImport.Products
	|			AND NOT CatProducts.DeletionMark
	|			AND NOT CatProducts.IsFolder
	|
	|WHERE
	|	DataToImport.Products <> """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	CatCharacteristics.Owner AS Owner,
	|	MAX(CatCharacteristics.Ref) AS Ref,
	|	COUNT(CatCharacteristics.Ref) AS Count
	|
	|INTO TTSpecificationsByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ItemsCharacteristics AS CatCharacteristics
	|		ON CatCharacteristics.Description = DataToImport.Products
	|			AND NOT CatCharacteristics.DeletionMark
	|
	|WHERE
	|	DataToImport.Characteristic <> """"
	|
	|GROUP BY
	|	DataToImport.Id,
	|	CatCharacteristics.Owner
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	CatSetOfSeries.ProductKind AS ProductKind,
	|	MAX(CatSetOfSeries.Ref) AS Ref,
	|	COUNT(CatSetOfSeries.Ref) AS Count
	|
	|INTO TTSeriesByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ItemsBatches AS CatSetOfSeries
	|		ON CatSetOfSeries.Description = DataToImport.Series
	|			AND NOT CatSetOfSeries.DeletionMark
	|
	|WHERE
	|	DataToImport.Series <> """"
	|
	|GROUP BY
	|	DataToImport.Id,
	|	CatSetOfSeries.ProductKind
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatPersons.Ref) AS Ref,
	|	COUNT(CatPersons.Ref) AS Count
	|
	|INTO TTIndividualsByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Persons AS CatPersons
	|		ON CatPersons.Description = DataToImport.Individual
	|			AND NOT CatPersons.DeletionMark
	|			AND NOT CatPersons.IsFolder
	|
	|WHERE
	|	DataToImport.Individual <> """"
	|	AND &UploadIndividual
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|
	|	CASE
	|		WHEN NOT TTProductListByName.Id IS NULL
	|
	|			THEN TTProductListByName.Ref
	|
	|		WHEN NOT TTProductsByArticle.Id IS NULL
	|
	|			THEN TTProductsByArticle.Ref
	|
	|		WHEN NOT TTProductListByCode.Id IS NULL
	|
	|			THEN TTProductListByCode.Ref
	|
	|		WHEN NOT TTDataOnInventoryNumbers.Id IS NULL
	|
	|			THEN TTDataOnInventoryNumbers.Products
	|
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|
	|	END AS Ref
	|
	|INTO TTFoundProduct
	| 
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		LEFT JOIN TTProductsByArticle AS TTProductsByArticle
	|		ON TTProductsByArticle.Id = DataToImport.Id
	|
	|		LEFT JOIN TTProductListByCode AS TTProductListByCode
	|		ON TTProductListByCode.Id = DataToImport.Id
	|
	|		LEFT JOIN TTProductListByName AS TTProductListByName
	|		ON TTProductListByName.Id = DataToImport.Id
	|
	|		LEFT JOIN TTDataOnInventoryNumbers AS TTDataOnInventoryNumbers
	|		ON TTDataOnInventoryNumbers.Id = DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	TTSpecificationsByName.Ref AS Ref
	|
	|INTO TTFoundCharacteristic
	| 
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		INNER JOIN TTFoundProduct AS TTFoundProduct
	|		ON TTFoundProduct.Id = DataToImport.Id
	|
	|		INNER JOIN TTSpecificationsByName AS TTSpecificationsByName
	|		ON TTSpecificationsByName.Id = DataToImport.Id
	|			AND (TTSpecificationsByName.Owner = TTFoundProduct.Ref
	|				OR TTSpecificationsByName.Owner = TTFoundProduct.Ref.ProductKind)
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	TTSeriesByName.Ref AS Ref
	|
	|INTO TTFoundSeries
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		INNER JOIN TTFoundProduct AS TTFoundProduct
	|		ON TTFoundProduct.Id = DataToImport.Id
	|
	|		INNER JOIN TTSeriesByName AS TTSeriesByName
	|		ON TTSeriesByName.Id = DataToImport.Id
	|			AND (TTSeriesByName.ProductKind = CASE
	|				WHEN TTFoundProduct.Ref.ProductKind.BatchSettingsAreTakenFromOtherItemsKind
	|					THEN TTFoundProduct.Ref.ProductKind.BatchOwner
	|				ELSE TTFoundProduct.Ref.ProductKind
	|				END)
	|
	|INDEX BY
	|	Id
	|  
	|////////////////////////////////////////////////////////////////////////////////
	|;
	|
	|SELECT
	|	DataToImport.AssetID AS AssetID,
	|
	|	ISNULL(TTFoundProduct.Ref, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(TTFoundCharacteristic.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ISNULL(TTFoundSeries.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|
	// Individual
	|	CASE
	|		WHEN NOT &UploadIndividual
	|
	|			THEN VALUE(Catalog.Persons.EmptyRef)
	|
	|		WHEN NOT TTIndividualsByName.Id IS NULL
	|
	|			THEN TTIndividualsByName.Ref
	|
	|		WHEN NOT TTDataOnInventoryNumbers.Id IS NULL
	|
	|			THEN TTDataOnInventoryNumbers.Individual
	|
	|		ELSE VALUE(Catalog.Persons.EmptyRef)
	|
	|	END AS Individual,
	|
	|	DataToImport.Quantity_Actual AS Quantity_Actual,
	|	DataToImport.Comment AS Comment,
	|	DataToImport.ActionName AS ActionName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		LEFT JOIN TTFoundProduct AS TTFoundProduct
	|		ON TTFoundProduct.Id = DataToImport.Id
	|
	|		LEFT JOIN TTFoundCharacteristic AS TTFoundCharacteristic
	|		ON TTFoundCharacteristic.Id = DataToImport.Id
	|
	|		LEFT JOIN TTFoundSeries AS TTFoundSeries
	|		ON TTFoundSeries.Id = DataToImport.Id
	|
	|		LEFT JOIN TTIndividualsByName AS TTIndividualsByName
	|		ON TTIndividualsByName.Id = DataToImport.Id
	|
	|		LEFT JOIN TTDataOnInventoryNumbers AS TTDataOnInventoryNumbers
	|		ON TTDataOnInventoryNumbers.Id = DataToImport.Id
	|
	|";
	
	GoodsTable = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // ValueTable
	
	If DataToImport.Columns.Find("Individual") = Undefined Then
		DataToImport.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	EndIf;
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("DataToImport", DataToImport);
	Query.SetParameter("Period", AdditionalParameters.Date);
	Query.SetParameter("UploadIndividual", Not ValueIsFilled(AdditionalParameters.Individual));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = GoodsTable.Add();
		FillPropertyValues(NewRow, Selection);
		
        If Upper(Selection.ActionName) = Upper(NStr("vi = 'Ghi tăng';
													|ru = 'Оприходовать';
													|en = 'Receive'; fa = 'دریافت';
													|it = 'Accettare';
													|pl = 'Receive';
													|tr = 'Envanter girişi yap'")) Then
        	NewRow.Action = Enums.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived;
        ElsIf Upper(Selection.ActionName) = Upper(NStr("vi = 'Trả lại';
														|ru = 'Вернуть';
														|en = 'Return'; fa = 'مرجوعی';
														|it = 'Restituire';
														|pl = 'Return';
														|tr = 'İade'")) Then
        	NewRow.Action = Enums.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation;
        EndIf;
		
	EndDo;
	
	PutToTempStorage(GoodsTable, AddressOfMappingTable);

EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
// 	FullTabularSectionName- String - full name of the table part where data is loaded.
// 	ConflictsList - Array - list of ambiguities.
// 	ColumnName - String - name of the column where the ambiguity occurs.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	
EndProcedure

#EndRegion

#Region Other

// Generates the Inventory key.
// 
// Parameters:
//  Organization - CatalogRef.Companies - Organization
//  Department - CatalogRef.BusinessStructure - Department
//  Individual - CatalogRef.Persons - A natural person
//  RowData - FormDataCollectionItem - this line
// 
// Returns:
//  Structure - Inventory key:
// 		* Organization - CatalogRef.Companies -
// 		* Department - CatalogRef.BusinessStructure -
// 		* AssetID - String -
// 		* Products - CatalogRef.Products -
// 		* Characteristic - CatalogRef.ItemsCharacteristics -
// 		* Series - CatalogRef.ItemsBatches -
// 		* Individual - CatalogRef.Persons -
Function InventoryKey(Organization, Department, Individual, RowData) Export
	
	KeyData = New Structure;
	KeyData.Insert("Organization", Organization);
	KeyData.Insert("Department", Department);
	KeyData.Insert("AssetID", RowData.AssetID);
	KeyData.Insert("Products", RowData.Products);
	KeyData.Insert("Characteristic", RowData.Characteristic);
	KeyData.Insert("Series", RowData.Series);
	
	If ValueIsFilled(Individual) Then
		KeyData.Insert("Individual", Individual);
	Else
		KeyData.Insert("Individual", RowData.Individual);
	EndIf;
	
	Return KeyData;
	
EndFunction

Function YouCanSetAction(RowData, NewAction) Export
	
	Result =
		(NewAction = Enums.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived
			Or NewAction = Enums.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation)
		And RowData.Quantity_Actual <> 0
		And RowData.Quantity_Actual > RowData.QuantityAccordingToAccountingData 
		And (RowData.QuantityAccordingToAccountingData <> 0
		 	Or NewAction = Enums.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived);
			 	
	Return Result;
	
EndFunction

// Adds a temporary table of documents created based on the inventory to the manager.
//
// Parameters:
// 	TableManager - TempTablesManager - Appointment Manager
// 	DocumentBasis - DocumentRef.PhysicalCountOfInventoryInOperation - Link to the inventory document
//
Procedure AddCreatedDocumentsBasedOn(TableManager, DocumentBasis)
	
	QueryText =
	"SELECT
	|	MIN(DocumentsBasedOn.Ref) AS Ref,
	|	DocumentsBasedOn.Individual AS Individual,
	|	DocumentsBasedOn.AssetID AS AssetID,
	|	DocumentsBasedOn.Products AS Products,
	|	DocumentsBasedOn.Characteristic AS Characteristic,
	|	DocumentsBasedOn.Series AS Series,
	|	DocumentsBasedOn.Action AS Action
	|
	|INTO TTDocumentsBasedOn
	|
	|FROM
	|	(SELECT
	|		Operation.Ref AS Ref,
	|		TabularSection.Individual AS Individual,
	|		TabularSection.AssetID AS AssetID,
	|		TabularSection.Products AS Products,
	|		TabularSection.Characteristic AS Characteristic,
	|		TabularSection.Series AS Series,
	|		VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived) AS Action
	|	FROM
	|		Document.RecordInventoryInOperation AS Operation
	|
	|			INNER JOIN Document.RecordInventoryInOperation.Goods AS TabularSection
	|			ON Operation.Ref = TabularSection.Ref
	|	WHERE
	|		Operation.Posted
	|		AND Operation.DocumentBasis = &DocumentBasis
	|
	|	UNION ALL
	|
	|	SELECT
	|		Operation.Ref,
	|		TabularSection.Individual AS Individual,
	|		TabularSection.AssetID AS AssetID,
	|		TabularSection.Products AS Products,
	|		TabularSection.Characteristic AS Characteristic,
	|		TabularSection.Series AS Series,
	|		VALUE(Enum.ActionsBasedOnPhysicalInventoryCount.WriteOff)
	|	FROM
	|		Document.Decomissioning AS Operation
	|
	|			INNER JOIN Document.Decomissioning.Goods AS TabularSection
	|			ON Operation.Ref = TabularSection.Ref
	|	WHERE
	|		Operation.Posted
	|		AND Operation.DocumentBasis = &DocumentBasis
	|
	|	) AS DocumentsBasedOn
	|
	|GROUP BY
	|	DocumentsBasedOn.Individual,
	|	DocumentsBasedOn.AssetID,
	|	DocumentsBasedOn.Products,
	|	DocumentsBasedOn.Characteristic,
	|	DocumentsBasedOn.Series,
	|	DocumentsBasedOn.Action";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TableManager;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.Execute();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf