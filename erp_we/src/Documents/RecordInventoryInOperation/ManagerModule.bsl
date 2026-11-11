#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	RecordInventoryInOperationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);

	DocumentMechanisms.Add("SerialAccounting");
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
	
	If TypeOf(Document) = Type("DocumentObject.RecordInventoryInOperation") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableInventoryInOperation(QueryTexts, Registers);
		QueryTextTableCostOfInventoryInOperation(QueryTexts, Registers);

		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		RecordInventoryInOperationLocalization.AddRequestTexts(Query, QueryTexts, Registers);

	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
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
	SeriesSpecificationParameters.FullObjectName = "Document.RecordInventoryInOperation";
	
	SeriesSpecificationParameters.UseItemsBatch = InventoryInOperationCached.ItIsPossibleToTakeIntoAccountSeriesInOperation();
	SeriesSpecificationParameters.UseCostAccountingByBatches = SeriesSpecificationParameters.UseItemsBatch;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.RecordInventoryInOperation);
	
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
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
	|	Goods.Count AS Count,
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
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
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
	
	Documents.Decomissioning.AddGenerateCommand(GenerationCommands);
	Documents.TransferInOperation.AddGenerateCommand(GenerationCommands);
	
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
	
	If AccessRight("Insert", Metadata.Documents.RecordInventoryInOperation) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RecordInventoryInOperation.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RecordInventoryInOperation);
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
	
	FullDocumentName = "Document.RecordInventoryInOperation";
	
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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.RecordInventoryInOperation AS DocumentData
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.RecordInventoryInOperation"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.RecordInventoryInOperation);

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
		ValuesOfHoldingParameters.Insert("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
		ValuesOfHoldingParameters.Insert("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure QueryTextTableInventoryInOperation(QueryTexts, Registers)
	
	RegisterName = "InventoryInOperation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Text = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|
	|	&Organization                             AS Organization,
	|	&Department                           AS Department,
	|	TabularSection.Individual            AS Individual,
	|	TabularSection.Products              AS Products,
	|	TabularSection.Characteristic            AS Characteristic,
	|	TabularSection.Series                     AS Series,
	|	TabularSection.Lot                    AS Lot,
	|	TabularSection.CCDNumber                  AS CCDNumber,
	|	&LineOfBusiness                 AS LineOfBusiness,
	|	TabularSection.AssetID          AS AssetID,
	|	TabularSection.Count                AS Count,
	|	TabularSection.QuantityByGBRN          AS QuantityByGBRN
	|FROM
	|	Document.RecordInventoryInOperation.Goods AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

Procedure QueryTextTableCostOfInventoryInOperation(QueryTexts, Registers)
	
	RegisterName = "CostOfInventoryInOperation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                           AS Period,
	|	&Organization                      AS Organization,
	|	Table.Products              AS Products,
	|	Table.Characteristic            AS Characteristic,
	|	Table.Series                     AS Series,
	|	Table.AssetID          AS AssetID,
	|	Table.Lot                    AS Lot,
	|	Table.RowID       AS RowID,
	|	
	|	Table.Count                AS Count,
	|
	|	Table.Sum * &FactorOfConversionToCurrencyOfRegul  AS LocalCost,
	|	Table.Sum * &ConversionRateToManCurrency   AS CostMan
	|
	|FROM
	|	Document.RecordInventoryInOperation.Goods AS Table
	|	
	|WHERE
	|	Table.Ref = &Ref
	|	AND Table.Sum <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

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

#Region ConductingLocalAccounting

// The text of the reflection in the Local accounting.
// 
// Returns:
//  String - Text of reflection in regl accounting
Function TextOfReflectionInLocalAccounting() Export

	Return RecordInventoryInOperationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The text of the query that generates temporary tables when reflected in Local accounting.
// 
// Returns:
//  String - Text of the request for Reflection in regl accounting
Function RequestTextTTReflectedInLocalAccounting() Export

	Return "";

EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("View", Metadata.DataProcessors.PrintLabelsOfInventoryInOperation) Then
	
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "InventoryInOperationClient.PrintingOfTMTSVOperationLabelsFromDocument";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "Labels";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;

	EndIf;
	
	RecordInventoryInOperationLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Retrieves data for printing labels.
// 
// Parameters:
//  DocumentsArray - Array - array of documents
// 
// Returns:
//  ValueTable - Label Printing Data
Function LabelPrintingData(DocumentsArray) Export

	QueryText =
	"SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.AssetID AS AssetID,
	|	GoodsTable.Individual AS Individual,
	|	GoodsTable.Lot AS Lot
	|FROM
	|	Document.RecordInventoryInOperation.Goods AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND GoodsTable.Ref.Posted
	|
	|ORDER BY
	|	Ref,
	|	LineNumber";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.Execute();
	
	DataForPrint = QueryResult.Unload();
	
	Return DataForPrint;
	
EndFunction

#EndRegion

#Region Other

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "PriceKind,Department");

EndProcedure

// Fill in based on inventory.
// 
// Parameters:
//  Object - DocumentObject.RecordInventoryInOperation - Object
//  ArrayOfLineNumbers - Array of Number - Array Of Line Numbers
// 
// Returns:
//  Boolean - True if the filling is completed.
Function FillInBasedOnInventory(Object, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return True;
	EndIf;
	
	FillingData = Documents.PhysicalCountOfInventoryInOperation.FillingDataBasedOnInventory(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.RecordingAsReceived, 
							ArrayOfLineNumbers);
							
	Selection = FillingData.Attributes.Select();
	Selection.Next();
	FillPropertyValues(Object, Selection);
	
	If FillingData.TabularSection.IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = FillingData.TabularSection.Select();
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.Count = Selection.Quantity_Actual - Selection.QuantityAccordingToAccountingData;
		NewRow.NumberOfPackages = NewRow.Count;
		
	EndDo;
	
	If ValueIsFilled(Object.PriceKind) Then
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", Object.Date);
		FillParameters.Insert("Currency", Object.Currency);
		FillParameters.Insert("PriceKind", Object.PriceKind);
		FillParameters.Insert("Organization", Object.Organization);
				
		StructureOfActions = New Structure("RecalculateAmount", "NumberOfPackages");
		EnterprisePricesFillingServer.FillInPrices(Object.Goods,, FillParameters, StructureOfActions);
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.RecordInventoryInOperation);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Return True;
	
EndFunction

#EndRegion

#EndRegion

#EndIf