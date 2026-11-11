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
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of value table elements with data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReceiptOfCashRegisterAdjustment") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		RequestTextTableOfMovementOfProductSeriesReverse(Query, QueryTexts, Registers);
		RequestTextProductSeriesMovementTableSale(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ArrangeShipmentAtRetail(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Status,Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.FullObjectName = "Document.ReceiptOfCashRegisterAdjustment";
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;

	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.RetailShipment);

	If WarehousesServer.UseWarerooms(Object.Warehouse) Then
		SeriesSpecificationParameters.LinkFields.Add("Premise");
	EndIf;
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.SelectionPlanning = True;	
	SeriesSpecificationParameters.FactOfSelection = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.ReadOnly = (Object.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);

	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the status of the document.
//
// Parameters:
//  Ref - DocumentRef.CashRegisterReceipt - Link to the CMC receipt.
//
// Returns:
//  EnumRef.CashRegisterReceiptStatuses - The status of the KKM receipt.
//
Function DocumentStatus(Ref) Export
	
	Query = New Query;
	Query.Text = "SELECT
	|	CashRegisterReceipt.Status
	|FROM
	|	Document.CashRegisterReceipt AS CashRegisterReceipt
	|WHERE
	|	CashRegisterReceipt.Ref = &Ref";
	
	Query.SetParameter("Ref", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.Status;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	ThereArePremises = (SeriesSpecificationParameters.LinkFields.Find("Premise") <> Undefined);
	If ThereArePremises Then
		Return RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises();
	Else
		Return TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms();
	EndIf;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Return;
	
EndProcedure

// Determines the presence of the document correction receipt by the transmitted link to the Receipt of the correction.
// The correction check must be carried out and reflected in the register of Fiscal operation information.
//
// Parameters:
//	CashRegisterReceipt - DocumentRef.CashRegisterReceipt - The Cash register receipt that you need to use to determine whether there are correction receipts
//	OnlyErrorCorrection - Boolean - Truth, search only for types of correction "Error correction"
// Returns:
//	Boolean - There are correction checks for the transferred Cash register receipt
Function ThereIsCorrectionForCashRegisterReceipt(CashRegisterReceipt, OnlyErrorCorrection = False) Export
	
	// There is no previously created document for the CHECKCM document Correction
	Query = New Query;
	Query.Text =
	"SELECT
	|	ReceiptOfCashRegisterAdjustment.Ref AS Ref
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	|		INNER JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = FiscalTransactions.DocumentBasis
	|	
	|WHERE
	|	ReceiptOfCashRegisterAdjustment.Posted
	|	AND ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = &CashRegisterReceipt
	|   AND (&AllTypesOfCorrectionChecks
	|		OR ReceiptOfCashRegisterAdjustment.TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors))
	|	AND (FiscalTransactions.CashRegisterReceiptNumber <> &IsBlankString)";
	Query.SetParameter("CashRegisterReceipt", CashRegisterReceipt);
	Query.SetParameter("AllTypesOfCorrectionChecks", Not OnlyErrorCorrection);
	Query.SetParameter("IsBlankString", "");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.CashRegisterReceipt - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
	Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Warehouse;
	
	FillParameters.Retail_ = True;
	
	Return FillParameters;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(CashRegister)
	|	AND ValueAllowed(Warehouse)";

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Archived                                        AS Archived,
	|	DocumentData.Ref                                          AS Ref,
	|	DocumentData.CashRegisterReceipt 											AS CashRegisterReceipt,
	|	DocumentData.TypeOfCorrection 									AS TypeOfCorrection,
	|	DocumentData.CashRegister.Owner                               AS Organization,
	|	DocumentData.Partner                                         AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef)                   AS Counterparty,
	|	DocumentData.Date                                            AS Period,
	|	DocumentData.Currency                                          AS Currency,
	|	DocumentData.Warehouse                                           AS Warehouse,
	|	DocumentData.PriceIncludesVAT                                 AS PriceIncludesVAT,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|	VALUE(Catalog.CashFlowReportItems.CashReceiptFromCustomer) AS CashFlowItem,
	|	DocumentData.Status                                                        AS Status,
	|	DocumentData.LoyaltyCard.Owner.LoyaltyProgram AS LoyaltyProgram,
	|	DocumentData.CashRegister.Department                          AS Department
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Archived",                                 Attributes.Archived);
	Query.SetParameter("Ref",                                   DocumentRef);
	Query.SetParameter("TypeOfCorrection",                             Attributes.TypeOfCorrection);
	Query.SetParameter("CashRegisterReceipt",                                   Attributes.CashRegisterReceipt);
	Query.SetParameter("Warehouse",                                    Attributes.Warehouse);
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("Currency",                                   Attributes.Currency);
	Query.SetParameter("Organization",                              Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation",                    Attributes.BusinessOperation);
	Query.SetParameter("CashFlowItem",            Attributes.CashFlowItem);
	Query.SetParameter("ReceiptCompleted",                                Attributes.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Query.SetParameter("GoodsIsReserved",                      Attributes.Status = Enums.CashRegisterReceiptStatuses.DeferredWithReservation);
	Query.SetParameter("Partner",                                  Attributes.Partner);
	Query.SetParameter("LoyaltyProgram",              Attributes.LoyaltyProgram);
	Query.SetParameter("Department",                            Attributes.Department);
	
EndProcedure

Procedure ArrangeShipmentAtRetail(Query, QueryTexts, Registers)
	
	// KKM receipt reversal
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentHeader.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	-DocumentGoods.Count			AS Count,
	|	FALSE								AS GoodsReturn
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS DocumentHeader
	|	INNER JOIN Document.CashRegisterReceipt.Goods AS DocumentGoods
	|		ON DocumentHeader.CashRegisterReceipt = DocumentGoods.Ref
	|
	|WHERE
	|	DocumentHeader.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|	AND NOT DocumentHeader.Archived
	|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)";
	
	MetadataObject	= Metadata.Documents.CashRegisterReceipt;
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.SynonymForDocumentTable = "DocumentHeader";
	
	WarehousesServer.ArrangeShipmentAtRetail(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										MethodParameters);
	
	// Correction
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.Ref.Date			AS Period,
	|	DocumentGoods.Ref.Warehouse		AS Warehouse,
	|	DocumentGoods.Premise			AS Premise,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS GoodsReturn
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment.Goods AS DocumentGoods
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|	AND NOT DocumentGoods.Ref.Archived
	|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)";
	
	MetadataObject	= Metadata.Documents.ReceiptOfCashRegisterAdjustment;
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.SynonymForDocumentTable = "DocumentGoods";
	
	WarehousesServer.ArrangeShipmentAtRetail(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										MethodParameters);
	
EndProcedure

Function RequestTextTableOfMovementOfProductSeriesReverse(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	-SeriesTable.Count AS Count,
	|	&Warehouse AS Sender,
	|	&Partner AS Partner,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment) AS WarehouseOperation,
	|	SeriesTable.Premise AS WareroomOfSender,
	|	&Period AS Period,
	|	&Ref AS Document,
	|	&Ref AS Recorder,
	|	SeriesTable.LineNumber AS LineNumber,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.CashRegisterReceipt.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &CashRegisterReceipt
	|	AND SeriesTable.Count <> 0
	|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|	AND NOT &Archived
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	-GoodsTable.Count,
	|	&Warehouse,
	|	&Partner,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment),
	|	GoodsTable.Premise,
	|	&Period,
	|	&Ref,
	|	&Ref,
	|	GoodsTable.LineNumber,
	|	TRUE
	|FROM
	|	Document.CashRegisterReceipt.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &CashRegisterReceipt
	|	AND GoodsTable.Count <> 0
	|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|	AND NOT &Archived
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function RequestTextProductSeriesMovementTableSale(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Sender,
	|	&Partner AS Partner,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment) AS WarehouseOperation,
	|	SeriesTable.Premise AS WareroomOfSender,
	|	&Period AS Period,
	|	&Ref AS Document,
	|	&Ref AS Recorder,
	|	SeriesTable.LineNumber AS LineNumber,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND NOT &Archived
	|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Warehouse,
	|	&Partner,
	|	VALUE(Enum.WarehouseTransactions.RetailShipment),
	|	GoodsTable.Premise,
	|	&Period,
	|	&Ref,
	|	&Ref,
	|	GoodsTable.LineNumber,
	|	TRUE
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND NOT &Archived
	|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	ReceiptProducts.Products AS Products,
		|	ReceiptProducts.Characteristic AS Characteristic,
		|	CASE
		|		WHEN ReceiptProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &Department
		|		ELSE ReceiptProducts.Ref.Warehouse
		|	END AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	ReceiptProducts.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment AS TabPart
		|		LEFT JOIN Document.CashRegisterReceipt.Goods AS ReceiptProducts
		|		ON ReceiptProducts.Ref = TabPart.CashRegisterReceipt
		|WHERE
		|	NOT TabPart.Archived
		|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.ReceiptOfCashRegisterAdjustment.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Archived
		|	AND &TypeOfCorrection = VALUE(Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
// 	PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	Return;
	
EndProcedure

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
	
	Return;
	
EndProcedure

// The function receives data for generating the printed form of the Product receipt.
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultForTabularPart - QueryResult
// 		* DocumentTitle - String
//
Function GetDataForPrintedFormProductReceipt(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	DocReceipt.Number                     AS Number,
	|	DocReceipt.Date                      AS Date,
	|	DocReceipt.Ref                    AS Ref,
	|	DocReceipt.CashRegister                  AS CashRegister,
	|	DocReceipt.Currency                    AS Currency,
	|	DocReceipt.PriceIncludesVAT           AS PriceIncludesVAT,
	|	DocReceipt.CashRegister.Presentation    AS Customer,
	|	DocReceipt.Cashier.Individual     AS EmployeeResponsible,
	|	DocReceipt.Organization               AS Organization,
	|	DocReceipt.Organization.Prefix       AS Prefix,
	|	DocReceipt.Organization.Presentation AS Vendor,
	|	DocReceipt.DocumentAmount            AS DocumentAmount,
	|	DocReceipt.CashRegister.Department    AS Department
	|FROM
	|	Document.CashRegisterReceipt AS DocReceipt
	|WHERE
	|	DocReceipt.Ref IN (&DocumentsArray)
	|ORDER BY
	|	DocReceipt.PointInTime
	|;
	|
	|SELECT
	|	Table.Ref                            AS Ref,
	|
	|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                                                 AS ProductsInSet,
	|	Table.ItemVariantOfSet                                               AS ItemVariantOfSet,
	|
	|	Table.LineNumber        AS LineNumber,
	|	Table.Products       AS Products,
	|	Table.Characteristic     AS Characteristic,
	|	Table.Count         AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	Table.Package                          AS Package,
	|	Table.Price                              AS Price,
	|	Table.NumberOfPackages * Table.Price - Table.Sum AS DiscountAmount,
	|	Table.NumberOfPackages * Table.Price                 AS AmountWithoutADiscount,
	|	Table.Sum                                             AS Sum,
	|	Table.VATAmount                                          AS VATAmount,
	|	Table.Premise                                         AS Premise
	|INTO Goods
	|FROM
	|	Document.CashRegisterReceipt.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN (&DocumentsArray)
	|;
	|
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)                       AS Sum,
	|	SUM(Table.VATAmount)                    AS VATAmount,
	|	SUM(Table.DiscountAmount)                 AS DiscountAmount,
	|	SUM(Table.Sum - Table.DiscountAmount) AS AmountWithoutADiscount
	|INTO KitsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                                  AS Ref,
	|	Components.Ref                                           AS ItemKitConfiguration,
	|	Components.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Components.Ref.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	SUM(CASE WHEN ISNULL(Components.Count, 0) <> 0 THEN
	|		Goods.Count / Components.Count
	|	ELSE
	|		1
	|	END) AS Count
	|INTO TableOptional
	|FROM
	|	Goods AS Goods
	|	
	|		LEFT JOIN Catalog.ProductKitConfigurations.Goods AS Components
	|		ON Components.Ref = Goods.ItemKitConfiguration
	|		 AND Components.Ref.ProductsOfMainComponent   = Goods.Products
	|		 AND Components.Ref.MainComponentCharacteristic = Goods.Characteristic
	|		 AND Components.Products                             = Goods.Products
	|		 AND Components.Characteristic                           = Goods.Characteristic
	|
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	AND NOT Components.Count IS NULL
	|GROUP BY
	|	Goods.Ref,
	|	Components.Ref,
	|	Components.Ref.PresentationOptionInPrintForms,
	|	Components.Ref.SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOptional.ItemKitConfiguration,
	|	TableOptional.PresentationOptionInPrintForms,
	|	TableOptional.SetPricingOption,
	
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TableOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TableOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount,
	|	Table.DiscountAmount                       AS DiscountAmount,
	|	Table.AmountWithoutADiscount                    AS AmountWithoutADiscount
	|INTO Kits
	|FROM
	|	KitsPreparation AS Table
	|		LEFT JOIN TableOptional AS TableOptional
	|		ON Table.ProductsInSet = TableOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TableOptional.ItemVariantOfSet
	|		AND Table.Ref = TableOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|
	|
	|SELECT
	|	Table.Ref                            AS Ref,
	|
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.SetPricingOption                  AS SetPricingOption,
	|	Table.ProductsInSet                        AS ProductsInSet,
	|	Table.ItemVariantOfSet                      AS ItemVariantOfSet,
	|	Table.TheseAreComponents                          AS TheseAreComponents,
	|	Table.IsRecordsSet                                  AS IsRecordsSet,
	|
	|	Table.LineNumber                       AS LineNumber,
	|	Table.Products.DescriptionFull   AS FullNameOfProduct_,
	|	Table.Products.Code                  AS Code,
	|	Table.Products.SKU              AS SKU,
	|	Table.Characteristic.DescriptionFull AS FullNameOfCharacteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Table.Package.Description
	|	END                      AS PackageName,
	|	Table.NumberOfPackages AS Count,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(Table.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(Table.Package)
	|	END                                     AS UnitOfMeasure,
	|	Table.Package                          AS Package,
	|	Table.Price                              AS Price,
	|	Table.NumberOfPackages * Table.Price - Table.Sum AS DiscountAmount,
	|	Table.Sum                                             AS Sum,
	|	Table.VATAmount                                          AS VATAmount,
	|	Table.Premise                                         AS Premise
	|FROM
	|(
	|	SELECT
	|		Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		Table.SetPricingOption AS SetPricingOption,
	|		Table.Ref,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(Kits.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(Kits.LineNumber, 0) <> 0 THEN
	|			Kits.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATAmount,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.Premise
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN Kits AS Kits
	|			ON Kits.ProductsInSet = Table.ProductsInSet
	|			 AND Kits.ItemVariantOfSet = Table.ItemVariantOfSet
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND Table.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		Kits.PresentationOptionInPrintForms,
	|		Kits.SetPricingOption AS SetPricingOption,
	|		Kits.Ref,
	|		Kits.ProductsInSet,
	|		Kits.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		Kits.LineNumber,
	|		Kits.ProductsInSet,
	|		Kits.Count,
	|		Kits.NumberOfPackages,
	|		Kits.AmountWithoutADiscount / ISNULL(Kits.NumberOfPackages, 1) AS Price,
	|		Kits.Sum AS Sum,
	|		Kits.VATAmount,
	|		Kits.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		Kits.DiscountAmount,
	|		Kits.AmountWithoutADiscount,
	|		UNDEFINED AS Premise
	|	FROM
	|		Kits AS Kits
	|	WHERE
	|		Kits.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Table
	|
	|ORDER BY
	|	Table.LineNumber,
	|	IsRecordsSet DESC
	|");
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure(
		"HeaderResults, ResultForTabularPart, DocumentTitle",
		RequestResultsPackage[0],
		RequestResultsPackage[5],
		NStr("vi = 'Phiếu tính tiền';
			|ru = 'Товарный чек';
			|en = 'Sales receipt'; fa = 'رسید فروش';
			|it = 'Ricevuta di vendita';
			|pl = 'Paragon towarowy';
			|tr = 'Satış makbuzu'"));
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

// Returns the text of the query to calculate the status of the guidance series (With premises)
//	Returns:
//		String - query text.
//
Function RequestTextForFillingInStatusesForSpecifyingSeriesWithPremises()
	
	QueryText = 
	"SELECT
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Premise,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Premise,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Premise = ProductsToRequest.Premise
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON Goods.Products = SeriesToRequest.Products
	|			AND Goods.Characteristic = SeriesToRequest.Characteristic
	|			AND Goods.Premise = SeriesToRequest.Premise
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
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

// Returns the text of the query to calculate the status of the guidance series (Without spaces)
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeriesWithoutRooms()
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|		BatchAccountingPolicies.Ref AS Ref,
	|		BatchAccountingPolicies.BatchAccountingPolicy AS BatchAccountingPolicy,
	|		BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches AS UseCostAccountingByBatches,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment AS SpecifyWhenPlanningShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking AS SpecifyWhenPlanningPicking,
	|		BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO AS BatchesAccountingByFEFO,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult AS SpecifyByPickingResult,
	|		BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnRetailShipment AS SpecifyOnRetailShipment,
	|		BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries AS AccountForRemainingSeries
	|INTO SeriesAccountingPoliciesForRequest
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|	INNER JOIN ProductsToRequest AS ProductsToRequest
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|WHERE 
	|	(BatchAccountingPolicies.Warehouse = &Warehouse)	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN &SeriesOnlyForCostPrice
	|			THEN 0
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.SpecifyOnRetailShipment
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			ON Goods.Products = ProductsToRequest.Products
	|				AND Goods.Characteristic = ProductsToRequest.Characteristic
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON Goods.Products = SeriesToRequest.Products
	|				AND Goods.Characteristic = SeriesToRequest.Characteristic
	|		LEFT JOIN SeriesAccountingPoliciesForRequest AS BatchAccountingPolicies
	|			ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
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

#EndIf
