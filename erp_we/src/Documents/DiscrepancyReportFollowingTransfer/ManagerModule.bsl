#If Not MobileStandaloneServer Then
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
	DocumentMechanisms.Add("DocumentsRegistry");
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
//  Structure - a collection of data tables to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DiscrepancyReportFollowingTransfer") Then
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers);
	
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
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

// Names of the details that the parameters for specifying the series depend on.
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "SourceWarehouse,DestinationWarehouse,Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//   See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SetPrivilegedMode(True);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingTransfer";
	
	SerialSenderParameters = WarehousesServer.UseOfSeriesInStock(Object.SourceWarehouse, False);
	RecipientWarehouseSeriesParameters  = WarehousesServer.UseOfSeriesInStock(Object.DestinationWarehouse, False);
	
	UseRecipientOrderScheme  = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.DestinationWarehouse, Object.Date, False);
	UseSenderOrderScheme = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.SourceWarehouse, Object.Date);
	
	SetPrivilegedMode(False);
	
	SeriesSpecificationParameters.UseItemsBatch = SerialSenderParameters.UseItemsBatch
														Or (RecipientWarehouseSeriesParameters.UseItemsBatch
														And Not UseRecipientOrderScheme)
														Or RecipientWarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = SerialSenderParameters.UseCostAccountingByBatches
														Or RecipientWarehouseSeriesParameters.UseCostAccountingByBatches;
														
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentByTransfer);
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByTransfer);
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentSender");
	SeriesSpecificationParameters.LinkFields.Add("FilledUsingBaseDocument");
	SeriesSpecificationParameters.LinkFields.Add("DocumentBasis");
	SeriesSpecificationParameters.LinkFields.Add("Action");
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotOfTheSender");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.WarehouseFieldName = "SourceWarehouse";
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotOfTheSender";
	
	SeriesSpecificationParameters.NameOfSenderWarehouseField = "SourceWarehouse";
	SeriesSpecificationParameters.NameOfRecipientWarehouseField  = "DestinationWarehouse";
	
	SeriesSpecificationParameters.ShipmentPlanning = False;
	SeriesSpecificationParameters.SelectionPlanning   = False;
	SeriesSpecificationParameters.FactOfSelection           = True;
	
	SeriesSpecificationParameters.RegisterSeries = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//	Parameters:
//		SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.AssignmentSender AS AssignmentSender,
	|	Goods.ControlledLotOfTheSender AS ControlledLotOfTheSender,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Action AS Action,
	|	Goods.DocumentBasis AS DocumentBasis,
	|	Goods.FilledUsingBaseDocument AS FilledUsingBaseDocument
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.AssignmentSender AS AssignmentSender,
	|	Goods.ControlledLotOfTheSender AS ControlledLotOfTheSender,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Action AS Action,
	|	Goods.DocumentBasis AS DocumentBasis,
	|	Goods.FilledUsingBaseDocument AS FilledUsingBaseDocument
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.AssignmentSender,
	|	Goods.ControlledLotOfTheSender,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind,
	|	Goods.Action,
	|	Goods.DocumentBasis,
	|	Goods.FilledUsingBaseDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.AssignmentSender AS AssignmentSender,
	|	SetOfSeries.ControlledLotOfTheSender AS ControlledLotOfTheSender,
	|	SetOfSeries.Count AS Count,
	|	SetOfSeries.Action AS Action,
	|	SetOfSeries.DocumentBasis AS DocumentBasis,
	|	SetOfSeries.FilledUsingBaseDocument AS FilledUsingBaseDocument
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.AssignmentSender AS AssignmentSender,
	|	SetOfSeries.ControlledLotOfTheSender AS ControlledLotOfTheSender,
	|	SUM(SetOfSeries.Count) AS Count,
	|	SetOfSeries.Action AS Action,
	|	SetOfSeries.DocumentBasis AS DocumentBasis,
	|	SetOfSeries.FilledUsingBaseDocument AS FilledUsingBaseDocument
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.ControlledLotOfTheSender,
	|	SetOfSeries.Action,
	|	SetOfSeries.DocumentBasis,
	|	SetOfSeries.FilledUsingBaseDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.Count = 0
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.Count = 0
	|						THEN 11
	|					ELSE 9
	|				END
	|		WHEN SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.BatchesAccountingByFEFO
	|									THEN 6
	|								ELSE 8
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.BatchesAccountingByFEFO
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = 0
	|											THEN 25
	|										ELSE 5
	|									END
	|							ELSE CASE
	|									WHEN ProductsToRequest.Count = 0
	|										THEN 27
	|									ELSE 7
	|								END
	|						END
	|				END
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyOnShipmentByTransfer
	|				AND &FactOfSelection
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.AccountForRemainingSeries
	|									THEN 4
	|								ELSE 2
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = 0
	|											THEN 23
	|										ELSE 3
	|									END
	|							ELSE CASE
	|									WHEN ProductsToRequest.Count = 0
	|										THEN 21
	|									ELSE 1
	|								END
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusSender,
	|	CASE
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.Count = 0
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &Date >= DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|				AND &ReceivingByTransfer
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.Count = 0
	|						THEN 11
	|					ELSE 9
	|				END
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.BatchesAccountingByFEFO
	|									THEN 6
	|								ELSE 8
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.BatchesAccountingByFEFO
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = 0
	|											THEN 25
	|										ELSE 5
	|									END
	|							ELSE CASE
	|									WHEN ProductsToRequest.Count = 0
	|										THEN 27
	|									ELSE 7
	|								END
	|						END
	|				END
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyOnReceivingByTransfer
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.AccountForRemainingSeries
	|									THEN 4
	|								ELSE 2
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = 0
	|											THEN 23
	|										ELSE 3
	|									END
	|							ELSE CASE
	|									WHEN ProductsToRequest.Count = 0
	|										THEN 21
	|									ELSE 1
	|								END
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	Goods.BatchesIndicationStatusSender AS StatusOfSpecifyingSenderSeriesIsOld,
	|	Goods.BatchesIndicationStatusRecipient AS StatusOfSpecifyingRecipientSeriesIsOld
	|INTO Statuses
	|FROM
	|	ProductsToRequest AS ProductsToRequest
	|		INNER JOIN Goods AS Goods
	|		ON ProductsToRequest.Products = Goods.Products
	|			AND ProductsToRequest.Characteristic = Goods.Characteristic
	|			AND ProductsToRequest.Purpose = Goods.Purpose
	|			AND ProductsToRequest.AssignmentSender = Goods.AssignmentSender
	|			AND ProductsToRequest.ControlledLotOfTheSender = Goods.ControlledLotOfTheSender
	|			AND ProductsToRequest.Action = Goods.Action
	|			AND ProductsToRequest.DocumentBasis = Goods.DocumentBasis
	|			AND ProductsToRequest.FilledUsingBaseDocument = Goods.FilledUsingBaseDocument
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.AssignmentSender = SeriesToRequest.AssignmentSender
	|			AND ProductsToRequest.ControlledLotOfTheSender = SeriesToRequest.ControlledLotOfTheSender
	|			AND ProductsToRequest.Action = SeriesToRequest.Action
	|			AND ProductsToRequest.DocumentBasis = SeriesToRequest.DocumentBasis
	|			AND ProductsToRequest.FilledUsingBaseDocument = SeriesToRequest.FilledUsingBaseDocument
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesSender
	|			INNER JOIN Catalog.Warehouses AS SourceWarehouse
	|			ON (SourceWarehouse.Ref = &SourceWarehouse)
	|				AND (SeriesAccountingPoliciesSender.Warehouse = &SourceWarehouse)
	|		ON ProductsToRequest.ProductKind = SeriesAccountingPoliciesSender.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesRecipient
	|			INNER JOIN Catalog.Warehouses AS DestinationWarehouse
	|			ON (DestinationWarehouse.Ref = &DestinationWarehouse)
	|				AND (SeriesAccountingPoliciesRecipient.Warehouse = &DestinationWarehouse)
	|		ON ProductsToRequest.ProductKind = SeriesAccountingPoliciesRecipient.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	CASE
	|		WHEN &ReceivingByTransfer
	|			THEN Statuses.BatchesIndicationStatusRecipient
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatusRecipient IN (13, 14, 15, 9, 10, 11)
	|				AND Statuses.BatchesIndicationStatusSender <> 0
	|			THEN Statuses.BatchesIndicationStatusRecipient
	|		WHEN Statuses.BatchesIndicationStatusSender IN (5, 6, 25)
	|			THEN Statuses.BatchesIndicationStatusSender
	|		WHEN Statuses.BatchesIndicationStatusSender > CASE
	|				WHEN &ReceivingByTransfer
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE 0
	|			END
	|			THEN Statuses.BatchesIndicationStatusSender
	|		ELSE CASE
	|				WHEN &ReceivingByTransfer
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	(Statuses.BatchesIndicationStatusSender <> Statuses.StatusOfSpecifyingSenderSeriesIsOld
	|			OR CASE
	|				WHEN &ReceivingByTransfer
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE 0
	|			END <> Statuses.StatusOfSpecifyingRecipientSeriesIsOld
	|			OR CASE
	|				WHEN Statuses.BatchesIndicationStatusRecipient IN (13, 14, 15, 9, 10, 11)
	|						AND Statuses.BatchesIndicationStatusSender <> 0
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				WHEN Statuses.BatchesIndicationStatusSender IN (5, 6, 25)
	|					THEN Statuses.BatchesIndicationStatusSender
	|				WHEN Statuses.BatchesIndicationStatusSender > CASE
	|						WHEN &ReceivingByTransfer
	|							THEN Statuses.BatchesIndicationStatusRecipient
	|						ELSE 0
	|					END
	|					THEN Statuses.BatchesIndicationStatusSender
	|				ELSE CASE
	|						WHEN &ReceivingByTransfer
	|							THEN Statuses.BatchesIndicationStatusRecipient
	|						ELSE 0
	|					END
	|			END <> Statuses.StatusOfSpecifyingSeriesIsOld)";
	
	Return QueryText;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	CreateBasedOnCommand = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(
									GenerationCommands);
	
	If CreateBasedOnCommand <> Undefined Then
		ActStatuses = New Array;
		ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
		ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
		
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"Status",
															ActStatuses,
															ComparisonType.InList);
	EndIf;
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "Report of discrepancies after moving".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands.
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.DiscrepancyReportFollowingTransfer) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DiscrepancyReportFollowingTransfer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DiscrepancyReportFollowingTransfer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseNonConformanceCertificatesFollowingTransfer";
		
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

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	
	FillParameters.Insert("DocumentName",     "DiscrepancyReportFollowingTransfer");
	FillParameters.Insert("RegisterNameOrder", "TransferOrders");
	FillParameters.Insert("FieldNameOrder",     "OrderDocument");
	
	FillParameters.Insert("KeyFields",     "ReferenceOrder, Products, Characteristic, Series, Purpose");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	FillParameters.HeaderAttributes	= HeaderAttributes;
	
EndProcedure

// Creates a structure for creating an order document
//  If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray - Array - domestic consumption orders for which you need to enter an invoice.
//  OrderProperties_ - Undefined - a formal parameter for the functionalization of the mechanism.
//
// Returns:
//  Structure - the structure where the header details from the order array will be placed.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	Attributes = New Structure("Organization, CompanyRecipient, SourceWarehouse, DestinationWarehouse, BusinessOperation,
		|Department, GoodsReceiptOption");
	
	HeaderAttributes = Common.ObjectAttributesValues(ReferencesArrray[0], Attributes);
	
	Return HeaderAttributes;
	
EndFunction

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//  Goods				 - FormDataCollection - Table part " Products"
//  FillParameters	 - Structure -
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters) Export
	
	SuffixRecalculationParameters = "ByDocument";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", SuffixRecalculationParameters);
	StructureOfActions.Insert("RecalculateDiscrepancies");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Returns the request text required to fill in the document based on the product Movement document.
//
// Returns:
//   String - Query text
//
Function RequestTextBasedOnMove() Export

	QueryText = 
	"SELECT ALLOWED
	|	NOT InventoryTransfer.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN InventoryTransfer.Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
	|				OR InventoryTransfer.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	InventoryTransfer.Ref AS DocumentBasis,
	|	InventoryTransfer.Status AS DocumentStatus,
	|	InventoryTransfer.Organization,
	|	InventoryTransfer.CompanyRecipient,
	|	InventoryTransfer.EmployeeResponsible AS Manager,
	|	InventoryTransfer.SourceWarehouse,
	|	InventoryTransfer.DestinationWarehouse,
	|	InventoryTransfer.BusinessOperation
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref IN (&Basis1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MovementOfGoodsGoods.Products,
	|	MovementOfGoodsGoods.Characteristic,
	|	MovementOfGoodsGoods.Series,
	|	MovementOfGoodsGoods.Purpose,
	|	MovementOfGoodsGoods.AssignmentSender,
	|	MovementOfGoodsGoods.ControlledLotOfTheSender,
	|	MovementOfGoodsGoods.Package,
	|	MovementOfGoodsGoods.NumberOfPackages,
	|	MovementOfGoodsGoods.Count,
	|	MovementOfGoodsGoods.BatchesIndicationStatus,
	|	MovementOfGoodsGoods.Ref AS DocumentBasis,
	|	MovementOfGoodsGoods.TransferOrder AS OrderDocument,
	|	MovementOfGoodsGoods.RowCode AS RowCode,
	|	TRUE AS FilledUsingBaseDocument,
	|	MovementOfGoodsGoods.NumberOfPackages AS NumberOfPackagesByDocument,
	|	MovementOfGoodsGoods.Count AS CountByDocument
	|FROM
	|	Document.InventoryTransfer.Goods AS MovementOfGoodsGoods
	|WHERE
	|	MovementOfGoodsGoods.Ref IN (&Basis1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InventoryTransferSetOfSeries.Series,
	|	TRUE AS FilledUsingBaseDocument,
	|	InventoryTransferSetOfSeries.Count,
	|	InventoryTransferSetOfSeries.Count AS CountByDocument,
	|	InventoryTransferSetOfSeries.Products,
	|	InventoryTransferSetOfSeries.Characteristic,
	|	InventoryTransferSetOfSeries.Purpose,
	|	InventoryTransferSetOfSeries.AssignmentSender,
	|	InventoryTransferSetOfSeries.ControlledLotOfTheSender,
	|	InventoryTransferSetOfSeries.Ref AS DocumentBasis
	|FROM
	|	Document.InventoryTransfer.SetOfSeries AS InventoryTransferSetOfSeries
	|WHERE
	|	InventoryTransferSetOfSeries.Ref IN (&Basis1)";
	
	Return QueryText;

EndFunction 

// Returns a list of fields in the Products table part
//
// Returns:
//  String - list of fields
//
Function ListOfTSFieldsWithString() Export
	
	Return "LineNumber,
	|DescriptionText,
	|Products,
	|Characteristic,
	|Purpose,
	|Package,
	|NumberOfPackages,
	|Count,
	|OrderDocument,
	|RowCode,
	|Series,
	|BatchesIndicationStatus,
	|DocumentBasis,
	|FilledUsingBaseDocument,
	|NumberOfPackagesByDocument,
	|CountByDocument,
	|Action,
	|RecipientComment,
	|ManagerComment,
	|BatchesIndicationStatusSender,
	|BatchesIndicationStatusRecipient,
	|AssignmentSender,
	|ControlledLotOfTheSender";
	
EndFunction

// Returns a list of details that can be used to group orders within a single act.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	Return "Organization, CompanyRecipient, SourceWarehouse, DestinationWarehouse, BusinessOperation, GoodsReceiptOption";
	
EndFunction

// Refills the document, including the actual quantity, by warehouse.
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingTransfer - Act
//  Warehouse - CatalogRef.Warehouses - Warehouse
//  FactReceiptManager - AccumulationRegisterManager,DocumentManager - fact getting module
//  ActOfFoundation - DocumentRef.GoodsQualityControlCertificate - Act
// Returns:
//  Structure - structure with fields:
//   * ResultingTable - See Document.DiscrepancyReportFollowingTransfer.Goods
//   * ResultingSeriesTable - See Document.DiscrepancyReportFollowingTransfer.SetOfSeries
Function FillActual(Object, Warehouse, FactReceiptManager, ActOfFoundation) Export
	
	AdvancedWarehousingOnShipment = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(
		Object.SourceWarehouse, Object.Date);
	AdvancedWarehousingOnGoodsReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(
		Object.DestinationWarehouse, Object.Date);
	SeriesSpecificationParameters = Documents.DiscrepancyReportFollowingTransfer.SeriesSpecificationParameters(Object);
	
	FillParameters = Documents.DiscrepancyReportFollowingTransfer.DocumentFillingParameters();
	
	InvoiceTable = Object.Goods.Unload(New Array);
	InvoiceTable.Columns.Add("ReferenceOrder");
	InvoiceTable.Columns.Add("QuantityMaximum", New TypeDescription("Number"));
	InvoiceTable.Columns.Add("QuantityInOrder", New TypeDescription("Number"));
	InvoiceTable.Columns.Add("NoteQuantity", New TypeDescription("Number"));
	
	For Each LineProducts_ In Object.Goods Do
		
		NewRow = InvoiceTable.Add();
		FillPropertyValues(NewRow, LineProducts_);
		NewRow.ReferenceOrder = ?(ValueIsFilled(NewRow.OrderDocument), NewRow.OrderDocument, NewRow.DocumentBasis);
		NewRow.QuantityMaximum = Max(NewRow.Count, NewRow.CountByDocument);
		
	EndDo;
	If Not AdvancedWarehousingOnShipment And AdvancedWarehousingOnGoodsReceipt Then
		
		SeriesTable = Object.SetOfSeries.Unload();
		SeriesTable.Columns.Add("QuantityToDistribution", New TypeDescription("Number"));
		For Each RowSeries In SeriesTable Do
			RowSeries.QuantityToDistribution = Max(RowSeries.Count, RowSeries.CountByDocument);
		EndDo;
		
		Var_Key = "Products,Characteristic," + StrConcat(SeriesSpecificationParameters.LinkFields, ",");
		Condition = "[BatchesIndicationStatusSender], On [QuantityMaximum]";
		InvoicesServer.DistributeQuantityAndFill(
			SeriesTable,
			InvoiceTable,
			"QuantityToDistribution",
			Var_Key,
			Condition,
			True,
			"Series,Count,CountByDocument");
		InvoiceTable.Columns.Delete("QuantityToDistribution");
		
	EndIf;
	
	AnArrayOfOrders = InvoiceTable.UnloadColumn("ReferenceOrder");
	AnArrayOfOrders = CommonClientServer.CollapseArray(AnArrayOfOrders);
	
	ReferencesForOrders = Common.CopyRecursive(AnArrayOfOrders);
	CommonClientServer.SupplementArray(ReferencesForOrders,
		InvoiceTable.UnloadColumn("DocumentBasis"));
	
	ExcludedInvoices = InvoiceTable.UnloadColumn("DocumentBasis");
	ExcludedInvoices = CommonClientServer.CollapseArray(ExcludedInvoices);
	
	// Orders
	
	RequestTextForOrders = AccumulationRegisters.TransferOrders.QueryTextBalance("TTAccountingData");
	
	QueryTextOrderDocument = Documents.TransferOrder.QueryTextDocumentGoods();
	
	QueryText = RequestTextForOrders
		+ Common.QueryBatchSeparator()
		+ QueryTextOrderDocument;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("References", AnArrayOfOrders);
	Query.SetParameter("Recorder",  ExcludedInvoices);
	
	OrdersTable = Query.Execute().Unload();
	
	OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";
	OrdersTable.Columns.TransferOrder.Name = "OrderDocument";
	
	// Orders_3
	TableOrders = Object.Goods.Unload(New Array()).CopyColumns();
	TableOrders.Columns.Add("ReferenceOrder",
		New TypeDescription("DocumentRef.TransferOrder, DocumentRef.InventoryTransfer"));
		
	If FactReceiptManager = AccumulationRegisters.GoodsToReceive Then
		
		Query = New Query();
		TextOfRequestRemainsToIssue = AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders(True);
		Query.Text = TextOfRequestRemainsToIssue;
		Query.SetParameter("References", ReferencesForOrders);
		Query.SetParameter("Recorder",  ExcludedInvoices);
		
		SetPrivilegedMode(True);
		CommonClientServer.SupplementTable(Query.Execute().Unload(), TableOrders);
		SetPrivilegedMode(False);
		
	ElsIf FactReceiptManager = Documents.GoodsQualityControlCertificate Then
		SetPrivilegedMode(True);
		RegisterData = Documents.GoodsQualityControlCertificate.Accepted(ActOfFoundation, Warehouse);
		CommonClientServer.SupplementTable(RegisterData, TableOrders);
		SetPrivilegedMode(False);
	EndIf;
	
	TableOrders = AddJoinMethodToTable(
		TableOrders,
		SeriesSpecificationParameters,
		Object.SourceWarehouse,
		Object.DestinationWarehouse);
	
	TableOrders.Columns.Count.Name = "NoteQuantity";
	
	// Distribution of the resulting tables
	
	InvoiceTable.Indexes.Add(FillParameters.KeyFields);
	
	// Adding the number of orders
	Var_Key = "OrderDocument, RowCode";
	
	Condition = "On [QuantityMaximum]";
	InvoicesServer.AllocateQuantity(OrdersTable, InvoiceTable, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, InvoiceTable, "QuantityInOrder");
	
	InvoiceTable = AddJoinMethodToTable(
		InvoiceTable,
		SeriesSpecificationParameters,
		Object.SourceWarehouse,
		Object.DestinationWarehouse);
	
	// Adding the number of orders.
	
	// The division of the tables of the table of the invoice and the table of the received certificates into several according to the "Method of connection" field.
	InvoiceTables = SupplyServer.SplitTableByKeyValue(InvoiceTable, "ConnectionMethod_");
	TablesOfResults = SupplyServer.SplitTableByKeyValue(TableOrders, "ConnectionMethod_");
	
	// Formation of the structure of actions with separated tables
	ActionsWithResultingTables = New Structure();
	
	For Each KeyValue In InvoiceTables Do
		
		Var_Key = KeyValue.Key.ConnectionMethod_;
		StructureOfActions = New Structure("InvoiceTable, TableReceivedRemainder",
			KeyValue.Table, TableOrders.CopyColumns());
		ActionsWithResultingTables.Insert(Var_Key, StructureOfActions);
		
	EndDo;
	
	For Each KeyValue In TablesOfResults Do
		
		Var_Key = KeyValue.Key.ConnectionMethod_;
		
		If ActionsWithResultingTables.Property(Var_Key) Then
			StructureOfActions = ActionsWithResultingTables[Var_Key];
			StructureOfActions.TableReceivedRemainder = KeyValue.Table;
		Else
			StructureOfActions = New Structure("InvoiceTable, TableReceivedRemainder",
				InvoiceTable.CopyColumns(), KeyValue.Table);
			ActionsWithResultingTables.Insert(Var_Key, StructureOfActions);
		EndIf;
		
	EndDo;

	ResultingTable      = InvoiceTable.CopyColumns();
	ResultingSeriesTable = InvoiceTable.CopyColumns();
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Object.GoodsReceiptOption);

	For Each KeyValue In ActionsWithResultingTables Do
		
		Action = KeyValue.Key;
		StructureOfActions = KeyValue.Value;
		
		ActionInvoiceTable = StructureOfActions.InvoiceTable;
		OrderTableByAction    = StructureOfActions.TableReceivedRemainder;
		
		If InvoiceIsOrder Or FactReceiptManager = Documents.GoodsQualityControlCertificate Then
			Var_Key = "Products, Characteristic, Series, Purpose";
		Else
			Var_Key = "ReferenceOrder, Products, Characteristic, Series, Purpose";
		EndIf;
		
		If Action = "A0" Or Action = "A3" Then
			Var_Key = StrReplace(Var_Key, ", Series", "")
		EndIf;
		
		// There are invoices and orders
		Condition = "[QuantityMaximum], [QuantityInOrder], On [QuantityInOrder]";
		InvoicesServer.AllocateQuantity(
			OrderTableByAction,
			ActionInvoiceTable,
			"NoteQuantity",
			Var_Key,
			Condition,
			False);
		
		// There are orders, no invoices
		Condition = "NOT [QuantityMaximum], [QuantityInOrder], On [QuantityInOrder]";
		InvoicesServer.AllocateQuantity(
			OrderTableByAction,
			ActionInvoiceTable,
			"NoteQuantity",
			Var_Key,
			Condition, False);
		
		// There are invoices, no orders
		Condition = "[QuantityMaximum], NOT [QuantityInOrder], On [QuantityMaximum]";
		InvoicesServer.AllocateQuantity(
			OrderTableByAction,
			ActionInvoiceTable,
			"NoteQuantity",
			Var_Key,
			Condition,
			True);
		
		// Adding an undistributed number of orders in separate lines
		InvoicesServer.SupplementTable(OrderTableByAction, ActionInvoiceTable, "NoteQuantity");
		
		// Assignment of new lines to orders and base documents
		FilterParameters = New Structure("OrderDocument", Documents.TransferOrder.EmptyRef());
		RowsWithEmptyOrder = ActionInvoiceTable.FindRows(FilterParameters);
		For Each String In RowsWithEmptyOrder Do
			If TypeOf(String.ReferenceOrder) = Type("DocumentRef.TransferOrder") Then
				LineWithBaseDocument = ActionInvoiceTable.Find(String.ReferenceOrder, "OrderDocument");
				String.OrderDocument = String.ReferenceOrder;
				If LineWithBaseDocument <> Undefined Then
					String.DocumentBasis = LineWithBaseDocument.DocumentBasis;
				EndIf;
			ElsIf TypeOf(String.ReferenceOrder) = Type("DocumentRef.InventoryTransfer") Then
				LineWithBaseDocument = ActionInvoiceTable.Find(String.ReferenceOrder, "DocumentBasis");
				If LineWithBaseDocument <> Undefined Then
					String.OrderDocument = LineWithBaseDocument.OrderDocument;
				EndIf;
				String.DocumentBasis = String.ReferenceOrder;
			EndIf;
		EndDo;
		
		If Action = "A4" Then
			// Specifying series in a separate "Series" table
			
			// The data will be transferred to the "Series" table unchanged
			CommonClientServer.SupplementTable(ActionInvoiceTable, ResultingSeriesTable);
			
			// The same data must be transferred to the "Products" table, but with an empty series,
			// grouped by all fields, and summarized by "Quantity" and "Quantity Document".
			Grouping_Fields = Documents.DiscrepancyReportFollowingTransfer.ListOfTSFieldsWithString();
			Grouping_Fields = StrReplace(Grouping_Fields, "LineNumber,", "");
			Grouping_Fields = StrReplace(Grouping_Fields, "Series,", "");
			Grouping_Fields = StrReplace(Grouping_Fields, "Count,", "");
			Grouping_Fields = StrReplace(Grouping_Fields, "CountByDocument,", "");
			Grouping_Fields = StrReplace(Grouping_Fields, "NumberOfPackages,", "");
			Grouping_Fields = StrReplace(Grouping_Fields, "NumberOfPackagesByDocument,", "");
			
			ActionInvoiceTable.GroupBy(Grouping_Fields, "Count, CountByDocument, NoteQuantity");
			
		EndIf;
		
		CommonClientServer.SupplementTable(ActionInvoiceTable, ResultingTable);
		
	EndDo;
	
	ResultingTable.Columns.Count.Name             = "QuantityBeforeChange_";
	ResultingTable.Columns.NoteQuantity.Name      = "Count";
	
	ResultingSeriesTable.Columns.Count.Name        = "QuantityBeforeChange_";
	ResultingSeriesTable.Columns.NoteQuantity.Name = "Count";
	
	// Deleting empty lines
	LinesNotByDocument = ResultingTable.FindRows(New Structure("CountByDocument", 0));
	For Each String In LinesNotByDocument Do
		If String.Count = 0 Then
			ResultingTable.Delete(String);
		EndIf;
	EndDo;
	
	Result = New Structure("ResultingTable,ResultingSeriesTable",
		ResultingTable, ResultingSeriesTable);
	Return Result;

EndFunction

#EndRegion

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.NotApproved);
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.Approved);
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.ForCompletion);
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.Processed_);
	
	Return Table;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	// Needs for goods in the sending warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.SourceWarehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
	Return FormTemplate;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
// Object - DocumentObject.DiscrepancyReportFollowingTransfer - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInSenderSControlledLotReference - See QualityControl.New_ActionParameters
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	
	ActionName = "FillInSenderSControlledLotReference";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "OrderDocument,DocumentBasis";
	ActionParameters.EditableFields = "ControlledLotOfTheSender";
	ActionParameters.QueryText =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	CASE
		|		WHEN CAST(Table.DocumentBasis AS Document.InventoryTransfer).LockedGoodsTransfer
		|			THEN CAST(Table.DocumentBasis AS Document.InventoryTransfer).ControlledLotOfTheSender
		|		WHEN CAST(Table.OrderDocument AS Document.TransferOrder).LockedGoodsTransfer
		|			THEN CAST(Table.OrderDocument AS Document.TransferOrder).ControlledLotOfTheSender
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotOfTheSender
		|FROM
		|	#DataSource AS Table";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.DiscrepancyReportFollowingTransfer";
	ActionParameters.ReadableFields = "Products,ControlledLotOfTheSender";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.DestinationWarehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.OverridableProcessingInObjectManager = True;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.DiscrepancyReportFollowingTransfer";
	ActionParameters.ReadableFields = "Products,ControlledLotOfTheSender";
	ActionParameters.EditableFields = "SubjectToUnlocking,QualityConfirmationDate";
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	ActionParameters.OverridableProcessingInObjectManager = True;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.ControlledLotOfTheSender AS ControlledLotReference,
		|	&QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInMustBeUnblockedDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// The procedure for redefining the processing of the table part for the action "Fill in the quality control data".
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString
//  DataForProcessing - See BatchProcessingOfTablePartServer.DataForStringProcessing
//  ActionParameters - See QualityControl.New_ActionParameters
//  FillInRegular - Boolean - if the Truth is set inside the procedure, then the regular logic will be executed.
Procedure FillInCheckQualityDateOfQualityConfirmation(CurrentRow, DataForProcessing, ActionParameters, FillInRegular) Export
	
	If ValueIsFilled(CurrentRow.ControlledLotOfTheSender) Then
		
		CurrentRow.ToControlQuality = True;
		CurrentRow.QualityConfirmationDate = '00010101'; // is filled in by the action Fill in is waiting for the blocking of the Quality confirmation date.
		FillInRegular = False;
		
	EndIf;
	
EndProcedure

// The procedure for redefining the processing of the table part for the action "Fill in the required blockingthe Quality confirmation data".
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString
//  DataForProcessing - See BatchProcessingOfTablePartServer.DataForStringProcessing
//  ActionParameters - See QualityControl.New_ActionParameters
//  FillInRegular - Boolean - if the Truth is set inside the procedure, then the regular logic will be executed.
Procedure FillInUnblockableDateOfQualityConfirmation(CurrentRow, DataForProcessing, ActionParameters, FillInRegular) Export
	
	FillInRegular = False; // since there is no need to change the controlled Lot reference in the tabular part, it is filled in with the action to fill in the sender's controlled part
	If ValueIsFilled(CurrentRow.ControlledLotOfTheSender) Then
		
		CurrentRow.SubjectToUnlocking = DataForProcessing.SubjectToUnlocking;
		CurrentRow.QualityConfirmationDate = DataForProcessing.QualityConfirmationDate;
		// Controlled Party - we do not fill it out.
		FillInRegular = False;
		
	Else
		
		CurrentRow.SubjectToUnlocking = True;
		// The Quality confirmation dataproof is filled in by the action Fill in the Quality control dataproof.
		// Controlled Party - we do not fill it out.
		
	EndIf;
	
EndProcedure

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
	|	AND( ValueAllowed(SourceWarehouse)
	|	OR ValueAllowed(DestinationWarehouse)
	|	) ";

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

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array - the elements of which is the structure (See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand)
//          .
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Array;
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.SurplusesRecord		= True;
	JobPrintingRules.WarehouseFieldName			= "DestinationWarehouse";
	
	PrintRules.Add(JobPrintingRules);
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.WarehouseFieldName = "SourceWarehouse";
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion

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
	|	HeaderData_.Date                         AS Period,
	|	HeaderData_.Ref                       AS Ref,
	|	HeaderData_.Organization                  AS Organization,
	|	HeaderData_.Status                       AS Status,
	|	HeaderData_.SourceWarehouse             AS SourceWarehouse,
	|	HeaderData_.DestinationWarehouse              AS DestinationWarehouse,
	|	HeaderData_.BusinessOperation        AS BusinessOperation,
	|	HeaderData_.Number                        AS Number,
	|	HeaderData_.Manager                     AS Manager,
	|	HeaderData_.Department                AS Department,
	|	HeaderData_.Comment                  AS Comment,
	|	HeaderData_.DeletionMark              AS DeletionMark,
	|	HeaderData_.Author                        AS Author,
	|	HeaderData_.Posted                     AS Posted
	|
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                           Attributes.Period);
	Query.SetParameter("Ref",                           Attributes.Ref);
	Query.SetParameter("Status",                           Attributes.Status);
	Query.SetParameter("Organization",                      Attributes.Organization);
	Query.SetParameter("BusinessOperation",            Attributes.BusinessOperation);
	Query.SetParameter("SourceWarehouse",                 Attributes.SourceWarehouse);
	Query.SetParameter("DestinationWarehouse",                  Attributes.DestinationWarehouse);
	Query.SetParameter("WarehouseOperation",                Enums.WarehouseTransactions.ShipmentByTransfer);
	Query.SetParameter("Number",       		   		      Attributes.Number);
	Query.SetParameter("NumberForPrinting",       	          ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("Manager",                         Attributes.Manager);
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID("Document.DiscrepancyReportFollowingTransfer"));
	Query.SetParameter("Department",                    Attributes.Department);
	Query.SetParameter("Comment",                      Attributes.Comment);
	Query.SetParameter("DeletionMark",                  Attributes.DeletionMark);
	Query.SetParameter("Posted",                         Attributes.Posted);
	Query.SetParameter("Author",                            Attributes.Author);
	
	WarehouseInformationToSender = "";
	If ValueIsFilled(Attributes.SourceWarehouse) Then
		StringPattern = "vi = 'Điều chuyển từ ""%1""';
						|ru = 'Перемещение с ""%1""';
						|en = 'Transfer from ""%1""';
						|it = 'Trasferimento da ""%1""';
						|pl = 'Przenoszenie z ""%1""';
						|tr = '""%1''dan"" transfer'"; // @NStr
		WarehouseInformationToSender = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.SourceWarehouse);
	EndIf;
	Query.SetParameter("WarehouseInformationToSender", WarehouseInformationToSender);
	WarehouseInformationRecipient = "";
	If ValueIsFilled(Attributes.DestinationWarehouse) Then
		StringPattern = "vi = 'Điều chuyển đến ""%1""';
						|ru = 'Перемещение на ""%1""';
						|en = 'Transfer to ""%1""';
						|it = 'Trasferimento a ""%1""';
						|pl = 'Przenoszenie do ""%1""';
						|tr = '""%1''na"" transfer'"; // @NStr
		WarehouseInformationRecipient = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.DestinationWarehouse);
	EndIf;
	Query.SetParameter("WarehouseInformationRecipient", WarehouseInformationRecipient);
	
EndProcedure

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	ContainsGoodsInWarehousesRegister = False;
	ContainsRegisterGoodsForRegistrationOfSurplusesShortages = False;
	If ValueIsFilled(Registers) Then
		If TypeOf(Registers) = Type("String")
			And Registers = "ProductStock" Then
			ContainsGoodsInWarehousesRegister = True;
		ElsIf TypeOf(Registers) = Type("String")
			And Registers = "GoodsForRegistrationOfSurplusesAndShortages" Then
			ContainsRegisterGoodsForRegistrationOfSurplusesShortages = True;
		ElsIf TypeOf(Registers) = Type("Structure") Then
			If Registers.Property("ProductStock") Then
				ContainsGoodsInWarehousesRegister = True;
			EndIf;
			If Registers.Property("GoodsForRegistrationOfSurplusesAndShortages") Then
				ContainsRegisterGoodsForRegistrationOfSurplusesShortages = True;
			EndIf;
		EndIf;
	EndIf;
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                    AS Ref,
	|	GoodsTable.Ref.Date               AS Date,
	|	GoodsTable.Ref.SourceWarehouse   AS Warehouse,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Purpose                AS Purpose,
	|	GoodsTable.ControlledLotOfTheSender AS ControlledLotReference,
	|	GoodsTable.Series                     AS Series,
	|	GoodsTable.CountByDocument
	|		- GoodsTable.Count          AS Count,
	|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired))";
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("ProductStock", Registers) Then
		WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, "ProductStock", QueryTextDocument_);
	EndIf;
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                    AS Ref,
	|	GoodsTable.Ref.Date               AS Date,
	|	GoodsTable.Ref.SourceWarehouse   AS Warehouse,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Purpose                AS Purpose,
	|	GoodsTable.ControlledLotOfTheSender AS ControlledLotReference,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus = 14
	|			THEN
	|				GoodsTable.Series
	|			ELSE
	|				VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                   AS Series,
	|	GoodsTable.CountByDocument
	|		- GoodsTable.Count          AS Count,
	|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired))";
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("GoodsForRegistrationOfSurplusesAndShortages", Registers) Then
		WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, "GoodsForRegistrationOfSurplusesAndShortages", QueryTextDocument_);
	EndIf;
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                    AS Ref,
	|	GoodsTable.Ref.Date               AS Date,
	|	GoodsTable.Ref.DestinationWarehouse    AS Warehouse,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Purpose                AS Purpose,
	|	CASE
	|		WHEN GoodsTable.ToControlQuality
	|			THEN GoodsTable.ControlledLotReference
	|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
	|	END AS ControlledLotReference,
	|	GoodsTable.Series                     AS Series,
	|	(GoodsTable.CountByDocument
	|		- GoodsTable.Count)         AS Count,
	|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus,
	|	GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|		OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial) AS ItIsAllowedToReflectBalanceOnOrderWarehouse,
	|	GoodsTable.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|		AND GoodsTable.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial) AS ItIsAllowedToReflectBalanceForNonOrderWarehouse
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref                    AS Ref,
	|	GoodsTable.Ref.Date               AS Date,
	|	GoodsTable.Ref.DestinationWarehouse    AS Warehouse,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Purpose                AS Purpose,
	|	CASE
	|		WHEN GoodsTable.ToControlQuality
	|			THEN GoodsTable.ControlledLotReference
	|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
	|	END AS ControlledLotReference,
	|	GoodsTable.Series                     AS Series,
	|	(GoodsTable.CountByDocument
	|		- GoodsTable.Count)         AS Count,
	|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus,
	|	GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|		OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial) AS ItIsAllowedToReflectBalanceOnOrderWarehouse,
	|	GoodsTable.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|		AND GoodsTable.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial) AS ItIsAllowedToReflectBalanceForNonOrderWarehouse
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND GoodsTable.Ref.Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage))
	|	";
	
	If DocumentsPosting.RequiresTableForRegisteredRecords("ProductStock", Registers) Then
		WarehousesServer.ArrangeSurplusShortagesInWarehouseWithSelectionByOrder(Query, QueryTexts, "ProductStock", QueryTextDocument_);
	EndIf;
	
	If ContainsGoodsInWarehousesRegister Then
		// 
		QueryTextDocument_ =
		"SELECT
		|	GoodsTable.Ref                    AS Ref,
		|	GoodsTable.Ref.Date               AS Date,
		|	GoodsTable.Ref.SourceWarehouse   AS Warehouse,
		|	GoodsTable.Products              AS Products,
		|	GoodsTable.Characteristic            AS Characteristic,
		|	GoodsTable.Purpose                AS Purpose,
		|	CASE
		|		WHEN GoodsTable.ToControlQuality
		|			THEN GoodsTable.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	GoodsTable.Series                     AS Series,
		|	GoodsTable.CountByDocument
		|		- GoodsTable.Count          AS Count,
		|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN(&Ref)
		|	AND GoodsTable.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND GoodsTable.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))";
		
		RegisterForMovement = "ProductStock";
		
		WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, RegisterForMovement, QueryTextDocument_);
	EndIf;
	
	If ContainsRegisterGoodsForRegistrationOfSurplusesShortages Then
		// 
		QueryTextDocument_ =
		"SELECT
		|	GoodsTable.Ref                    AS Ref,
		|	GoodsTable.Ref.Date               AS Date,
		|	GoodsTable.Ref.SourceWarehouse   AS Warehouse,
		|	GoodsTable.Products              AS Products,
		|	GoodsTable.Characteristic            AS Characteristic,
		|	GoodsTable.Purpose                AS Purpose,
		|	CASE
		|		WHEN GoodsTable.ToControlQuality
		|			THEN GoodsTable.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus = 14
		|			THEN
		|				GoodsTable.Series
		|			ELSE
		|				VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END                                   AS Series,
		|	GoodsTable.CountByDocument
		|		- GoodsTable.Count          AS Count,
		|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN(&Ref)
		|	AND GoodsTable.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND GoodsTable.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.Ref                    AS Ref,
		|	GoodsTable.Ref.Date               AS Date,
		|	GoodsTable.Ref.SourceWarehouse   AS Warehouse,
		|	GoodsTable.Products              AS Products,
		|	GoodsTable.Characteristic            AS Characteristic,
		|	GoodsTable.Purpose                AS Purpose,
		|	CASE
		|		WHEN GoodsTable.ToControlQuality
		|			THEN GoodsTable.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatus = 14
		|			THEN
		|				GoodsTable.Series
		|			ELSE
		|				VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END                                   AS Series,
		|	GoodsTable.CountByDocument
		|		- GoodsTable.Count          AS Count,
		|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN(&Ref)
		|	AND GoodsTable.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND GoodsTable.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.Ref                    AS Ref,
		|	GoodsTable.Ref.Date               AS Date,
		|	GoodsTable.Ref.DestinationWarehouse    AS Warehouse,
		|	GoodsTable.Products              AS Products,
		|	GoodsTable.Characteristic            AS Characteristic,
		|	GoodsTable.Purpose                AS Purpose,
		|	CASE
		|		WHEN GoodsTable.ToControlQuality
		|			THEN GoodsTable.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	GoodsTable.Series                     AS Series,
		|	GoodsTable.CountByDocument
		|		- GoodsTable.Count          AS Count,
		|	GoodsTable.BatchesIndicationStatus       AS BatchesIndicationStatus
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN(&Ref)
		|	AND GoodsTable.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND GoodsTable.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage))";
		
		RegisterForMovement = "GoodsForRegistrationOfSurplusesAndShortages";
		
		WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, RegisterForMovement, QueryTextDocument_);
	EndIf;
	
EndProcedure

Procedure ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                        AS Ref,
	|	GoodsTable.OrderDocument                         AS OrderDocument,
	|	GoodsTable.DocumentBasis             AS Invoice,
	|	FALSE                                        AS Patch,
	|	UNDEFINED                                AS CorrectedDocument,
	|	GoodsTable.Ref.Date                   AS Date,
	|	GoodsTable.Ref.Date                   AS DateOfPlannedReceipt,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                AS Terms,
	|	GoodsTable.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	GoodsTable.Ref.DestinationWarehouse        AS Warehouse,
	|	GoodsTable.Ref.SourceWarehouse       AS Sender,
	|	GoodsTable.Ref.BusinessOperation  AS BusinessOperation,
	|	GoodsTable.Products                  AS Products,
	|	GoodsTable.Characteristic                AS Characteristic,
	|	GoodsTable.Purpose                    AS Purpose,
	|	GoodsTable.ToControlQuality     AS ToControlQuality,
	|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference          AS ControlledLotReference,
	|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	// Refusal of movements according to the co-formation of the load distribution.
	|	TRUE                                      AS ExceedingOrder,
	|	GoodsTable.Series                         AS Series,
	|	GoodsTable.Count
	|		- GoodsTable.CountByDocument   AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef) AS ReceiptUnderOrders,
	|	TRUE                                      AS ThisIsAnInvoice
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage))";
	
	WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
		
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                        AS Ref,
	|	GoodsTable.OrderDocument                         AS OrderDocument,
	|	GoodsTable.DocumentBasis             AS Invoice,
	|	FALSE                                        AS Patch,
	|	UNDEFINED                                AS CorrectedDocument,
	|	GoodsTable.Ref.Date                   AS Date,
	|	GoodsTable.Ref.Date                   AS DateOfPlannedReceipt,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                AS Terms,
	|	CASE
	|		WHEN GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			THEN
	|				VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			ELSE
	|				GoodsTable.Ref.GoodsReceiptOption
	|	END                                       AS GoodsReceiptOption,
	|	GoodsTable.Ref.DestinationWarehouse        AS Warehouse,
	|	GoodsTable.Ref.SourceWarehouse       AS Sender,
	|	GoodsTable.Ref.BusinessOperation  AS BusinessOperation,
	|	GoodsTable.Products                  AS Products,
	|	GoodsTable.Characteristic                AS Characteristic,
	|	GoodsTable.Purpose                    AS Purpose,
	|	GoodsTable.ToControlQuality     AS ToControlQuality,
	|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference          AS ControlledLotReference,
	|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	// Refusal of movements according to the co-formation of the load distribution.
	|	TRUE                                      AS ExceedingOrder,
	|	GoodsTable.Series                         AS Series,
	|	GoodsTable.Count
	|		- GoodsTable.CountByDocument   AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef) AS ReceiptUnderOrders,
	|	TRUE                                      AS ThisIsAnInvoice
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))";
	
	WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
		
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                                        AS Ref,
	|	GoodsTable.DocumentBasis                                             AS Invoice,
	|	FALSE                                                                        AS Patch,
	|	UNDEFINED                                                                AS CorrectedDocument,
	|	GoodsTable.OrderDocument                                                         AS OrderDocument,
	|	GoodsTable.Ref.Date                                                   AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)                      AS Contract,
	|	UNDEFINED                                                                AS Terms,
	|	CASE
	|		WHEN GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			THEN
	|				VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			ELSE
	|				GoodsTable.Ref.GoodsReceiptOption
	|	END                                                                       AS GoodsReceiptOption,
	|	GoodsTable.Ref.DestinationWarehouse                                        AS Warehouse,
	|	GoodsTable.Ref.SourceWarehouse                                       AS Sender,
	|	GoodsTable.Ref.BusinessOperation                                  AS BusinessOperation,
	|	GoodsTable.Products                                                  AS Products,
	|	GoodsTable.Characteristic                                                AS Characteristic,
	|	GoodsTable.Purpose                                                    AS Purpose,
	|	GoodsTable.ToControlQuality                                     AS ToControlQuality,
	|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference                                          AS ControlledLotReference,
	|	GoodsTable.BatchesIndicationStatusRecipient                                 AS BatchesIndicationStatus,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode = 0                                           AS ExceedingOrder,
	|	GoodsTable.Series                                                         AS Series,
	|	GoodsTable.Count - GoodsTable.CountByDocument              AS Count,
	|	TRUE                                                                      AS ReceiptUnderOrders,
	|	TRUE                                                                      AS ThisIsAnInvoice
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage))";
	
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                                        AS Ref,
	|	UNDEFINED                                                                AS Invoice,
	|	FALSE                                                                        AS Patch,
	|	UNDEFINED                                                                AS CorrectedDocument,
	|	GoodsTable.OrderDocument                                                         AS OrderDocument,
	|	GoodsTable.Ref.Date                                                   AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)                      AS Contract,
	|	UNDEFINED                                                                AS Terms,
	|	GoodsTable.Ref.GoodsReceiptOption                                  AS GoodsReceiptOption,
	|	GoodsTable.Ref.DestinationWarehouse                                        AS Warehouse,
	|	GoodsTable.Ref.SourceWarehouse                                       AS Sender,
	|	GoodsTable.Ref.BusinessOperation                                  AS BusinessOperation,
	|	GoodsTable.Products                                                  AS Products,
	|	GoodsTable.Characteristic                                                AS Characteristic,
	|	GoodsTable.Purpose                                                    AS Purpose,
	|	GoodsTable.ToControlQuality                                     AS ToControlQuality,
	|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference                                          AS ControlledLotReference,
	|	0                                                                           AS BatchesIndicationStatus,
	// For refusal of movements according to the co-formation of the load-bearing.
	|	TRUE                                                                      AS ExceedingOrder,
	|	GoodsTable.Series                                                         AS Series,
	|	GoodsTable.Count - GoodsTable.CountByDocument              AS Count,
	|	TRUE                                                                      AS ReceiptUnderOrders,
	|	FALSE                                                                        AS ThisIsAnInvoice
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|	AND GoodsTable.RowCode <> 0
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial))";
	
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                                        AS Ref,
	|	GoodsTable.DocumentBasis                                             AS Invoice,
	|	FALSE                                                                        AS Patch,
	|	UNDEFINED                                                                AS CorrectedDocument,
	|	CASE
	|		WHEN GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			THEN
	|				GoodsTable.DocumentBasis
	|			ELSE
	|				GoodsTable.OrderDocument
	|	END                                                                       AS OrderDocument,
	|	GoodsTable.Ref.Date                                                   AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)                      AS Contract,
	|	UNDEFINED                                                                AS Terms,
	|	CASE
	|		WHEN GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			THEN
	|				VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			ELSE
	|				GoodsTable.Ref.GoodsReceiptOption
	|	END                                                                       AS GoodsReceiptOption,
	|	GoodsTable.Ref.DestinationWarehouse                                        AS Warehouse,
	|	GoodsTable.Ref.SourceWarehouse                                       AS Sender,
	|	GoodsTable.Ref.BusinessOperation                                  AS BusinessOperation,
	|	GoodsTable.Products                                                  AS Products,
	|	GoodsTable.Characteristic                                                AS Characteristic,
	|	GoodsTable.Purpose                                                    AS Purpose,
	|	GoodsTable.ToControlQuality                                     AS ToControlQuality,
	|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference                                          AS ControlledLotReference,
	|	0                                                                           AS BatchesIndicationStatus,
	// For refusal of movements according to the co-formation of the load-bearing.
	|	TRUE                                                                      AS ExceedingOrder,
	|	GoodsTable.Series                                                         AS Series,
	|	GoodsTable.Count - GoodsTable.CountByDocument              AS Count,
	|	TRUE                                                                      AS ReceiptUnderOrders,
	|	FALSE                                                                        AS ThisIsAnInvoice
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))";
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.ThisIsDiscrepancyReport = True;
	MethodParameters.SynonymForDocumentTable = "GoodsTable";
	
	WarehousesServer.ScheduleDeliveryOfProductsWithSettings(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		MethodParameters);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                         AS Ref,
	|	GoodsTable.Ref.Date                                    AS Period,
	|	CASE
	|		WHEN GoodsTable.OrderDocument IN (
	|				VALUE(Document.TransferOrder.EmptyRef),
	|				UNDEFINED)
	|			THEN
	|				GoodsTable.DocumentBasis
	|			ELSE
	|				GoodsTable.OrderDocument
	|	END                                                        AS OrderDocument,
	|	GoodsTable.Ref                                         AS Invoice,
	|	FALSE                                                         AS Patch,
	|	UNDEFINED                                                 AS CorrectedDocument,
	|	GoodsTable.Ref.DestinationWarehouse                         AS Recipient,
	|	GoodsTable.Ref.SourceWarehouse                        AS Warehouse,
	|	GoodsTable.Products                                   AS Products,
	|	GoodsTable.Characteristic                                 AS Characteristic,
	|	GoodsTable.AssignmentSender                          AS Purpose,
	|	GoodsTable.ControlledLotOfTheSender                AS ControlledLotReference,
	|	GoodsTable.Series                                          AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                 AS BatchesIndicationStatus,
	|	GoodsTable.CountByDocument
	|		- GoodsTable.Count                               AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.InventoryTransfer.EmptyRef)
	|		AND GoodsTable.RowCode = 0                            AS ExceedingOrder,
	|	FALSE                                                         AS Canceled,
	|	TRUE                                                       AS ThisIsAnInvoice,
	|	GoodsTable.OrderDocument
	|		<> VALUE(Document.TransferOrder.EmptyRef)  AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND (GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			OR GoodsTable.RowCode = 0)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))";
	
	WarehousesServer.ScheduleShipmentOfGoods(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
	
	QueryTextDocument_ = "SELECT
	|	GoodsTable.Ref                                         AS Ref,
	|	GoodsTable.Ref.Date                                    AS Period,
	|	GoodsTable.Ref                                         AS OrderDocument,
	|	GoodsTable.Ref                                         AS Invoice,
	|	FALSE                                                         AS Patch,
	|	UNDEFINED                                                 AS CorrectedDocument,
	|	GoodsTable.Ref.SourceWarehouse                        AS Recipient,
	|	GoodsTable.Ref.DestinationWarehouse                         AS Warehouse,
	|	GoodsTable.Products                                   AS Products,
	|	GoodsTable.Characteristic                                 AS Characteristic,
	|	GoodsTable.AssignmentSender                          AS Purpose,
	|	GoodsTable.ControlledLotOfTheSender                AS ControlledLotReference,
	|	GoodsTable.Series                                          AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                 AS BatchesIndicationStatus,
	|	-(GoodsTable.CountByDocument
	|		- GoodsTable.Count)                              AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.InventoryTransfer.EmptyRef)
	|		AND GoodsTable.RowCode = 0                            AS ExceedingOrder,
	|	FALSE                                                         AS Canceled,
	|	TRUE                                                       AS ThisIsAnInvoice,
	|	GoodsTable.OrderDocument
	|		<> VALUE(Document.TransferOrder.EmptyRef)  AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND (GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			OR GoodsTable.RowCode = 0)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))";

	WarehousesServer.ScheduleShipmentOfGoods(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                        AS Ref,
	|	GoodsTable.Ref.Date                                   AS Period,
	|	CASE
	|		WHEN GoodsTable.OrderDocument IN (
	|				VALUE(Document.TransferOrder.EmptyRef),
	|				UNDEFINED)
	|			THEN
	|				GoodsTable.DocumentBasis
	|			ELSE
	|				GoodsTable.OrderDocument
	|	END                                                       AS OrderDocument,
	|	GoodsTable.Ref                                        AS Invoice,
	|	FALSE                                                        AS Patch,
	|	UNDEFINED                                                AS CorrectedDocument,
	|	GoodsTable.Ref.DestinationWarehouse                        AS Recipient,
	|	GoodsTable.Ref.SourceWarehouse                       AS Warehouse,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.AssignmentSender                         AS Purpose,
	|	GoodsTable.ControlledLotOfTheSender               AS ControlledLotReference,
	|	GoodsTable.Series                                         AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                AS BatchesIndicationStatus,
	|	GoodsTable.CountByDocument
	|		- GoodsTable.Count                              AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode = 0                           AS ExceedingOrder,
	|	FALSE                                                        AS Canceled,
	|	FALSE                                                        AS ThisIsAnInvoice,
	|	FALSE                                                        AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode <> 0
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))";
	
	WarehousesServer.ScheduleShipmentOfGoods(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                        AS Ref,
	|	GoodsTable.Ref.Date                                   AS Period,
	|	GoodsTable.Ref                                        AS OrderDocument,
	|	GoodsTable.Ref                                        AS Invoice,
	|	FALSE                                                        AS Patch,
	|	UNDEFINED                                                AS CorrectedDocument,
	|	GoodsTable.Ref.SourceWarehouse                       AS Recipient,
	|	GoodsTable.Ref.DestinationWarehouse                        AS Warehouse,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.AssignmentSender                         AS Purpose,
	|	GoodsTable.ControlledLotOfTheSender               AS ControlledLotReference,
	|	GoodsTable.Series                                         AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                AS BatchesIndicationStatus,
	|	-(GoodsTable.CountByDocument
	|		- GoodsTable.Count)                             AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode = 0                           AS ExceedingOrder,
	|	FALSE                                                        AS Canceled,
	|	FALSE                                                        AS ThisIsAnInvoice,
	|	FALSE                                                        AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode <> 0
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))";

	WarehousesServer.ScheduleShipmentOfGoods(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	CurrentMetadataObject1 = Metadata.Documents.DiscrepancyReportFollowingTransfer;
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                        AS Ref,
	|	GoodsTable.Ref.Date                                   AS Period,
	|	CASE
	|		WHEN GoodsTable.OrderDocument IN (
	|				VALUE(Document.TransferOrder.EmptyRef),
	|				UNDEFINED)
	|			THEN
	|				GoodsTable.DocumentBasis
	|			ELSE
	|				GoodsTable.OrderDocument
	|	END                                                       AS OrderDocument,
	|	GoodsTable.Ref                                        AS Invoice,
	|	FALSE                                                        AS Patch,
	|	UNDEFINED                                                AS CorrectedDocument,
	|	GoodsTable.Ref.DestinationWarehouse                        AS Recipient,
	|	GoodsTable.Ref.SourceWarehouse                       AS Warehouse,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.AssignmentSender                         AS Purpose,
	|	GoodsTable.Purpose                                    AS PurposeForConnection,
	|	GoodsTable.ControlledLotOfTheSender               AS ControlledLotReference,
	|	GoodsTable.Series                                         AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                AS BatchesIndicationStatus,
	|	GoodsTable.CountByDocument
	|		- GoodsTable.Count                              AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode = 0                           AS ExceedingOrder,
	|	TRUE                                                      AS ThisIsAnInvoice,
	|	GoodsTable.OrderDocument
	|		<> VALUE(Document.TransferOrder.EmptyRef) AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND (GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			OR GoodsTable.RowCode = 0)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))";
	
	SubstitutionOfSeriesFields = New Map();
	SubstitutionOfSeriesFields.Insert("SeriesData_.Count",
		"(SeriesData_.CountByDocument - SeriesData_.Count)");
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Purpose", "PurposeForConnection");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.SynonymForDocumentTable = "GoodsTable";
	ParametersOfModularHolding.SubstitutionOfSeriesFields = SubstitutionOfSeriesFields;
	ParametersOfModularHolding.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	ParametersOfModularHolding.MetadataObject = Metadata.Documents.DiscrepancyReportFollowingTransfer;
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		ParametersOfModularHolding);
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                        AS Ref,
	|	GoodsTable.Ref.Date                                   AS Period,
	|	GoodsTable.Ref                                        AS OrderDocument,
	|	GoodsTable.Ref                                        AS Invoice,
	|	FALSE                                                        AS Patch,
	|	UNDEFINED                                                AS CorrectedDocument,
	|	GoodsTable.Ref.SourceWarehouse                       AS Recipient,
	|	GoodsTable.Ref.DestinationWarehouse                        AS Warehouse,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.AssignmentSender                         AS Purpose,
	|	GoodsTable.Purpose                                    AS PurposeForConnection,
	|	GoodsTable.ControlledLotOfTheSender               AS ControlledLotReference,
	|	GoodsTable.Series                                         AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                AS BatchesIndicationStatus,
	|	-(GoodsTable.CountByDocument
	|		- GoodsTable.Count)                             AS Count,
	|	GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode = 0                           AS ExceedingOrder,
	|	TRUE                                                      AS ThisIsAnInvoice,
	|	GoodsTable.OrderDocument
	|		<> VALUE(Document.TransferOrder.EmptyRef) AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND (GoodsTable.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
	|			OR GoodsTable.RowCode = 0)
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))";
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		ParametersOfModularHolding);

	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                        AS Ref,
	|	GoodsTable.Ref.Date                                   AS Period,
	|	CASE
	|		WHEN GoodsTable.OrderDocument IN (
	|				VALUE(Document.TransferOrder.EmptyRef),
	|				UNDEFINED)
	|			THEN
	|				GoodsTable.DocumentBasis
	|			ELSE
	|				GoodsTable.OrderDocument
	|	END                                                       AS OrderDocument,
	|	GoodsTable.Ref                                        AS Invoice,
	|	FALSE                                                        AS Patch,
	|	UNDEFINED                                                AS CorrectedDocument,
	|	GoodsTable.Ref.DestinationWarehouse                        AS Recipient,
	|	GoodsTable.Ref.SourceWarehouse                       AS Warehouse,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.AssignmentSender                         AS Purpose,
	|	GoodsTable.Purpose                                    AS PurposeForConnection,
	|	GoodsTable.ControlledLotOfTheSender               AS ControlledLotReference,
	|	GoodsTable.Series                                         AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                AS BatchesIndicationStatus,
	|	GoodsTable.CountByDocument
	|		- GoodsTable.Count                              AS Count,
	|	FALSE                                                        AS ExceedingOrder,
	|	FALSE                                                        AS ThisIsAnInvoice,
	|	FALSE                                                        AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode <> 0
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))";
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		ParametersOfModularHolding);
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                        AS Ref,
	|	GoodsTable.Ref.Date                                   AS Period,
	|	GoodsTable.Ref                                        AS OrderDocument,
	|	GoodsTable.Ref                                        AS Invoice,
	|	FALSE                                                        AS Patch,
	|	UNDEFINED                                                AS CorrectedDocument,
	|	GoodsTable.Ref.SourceWarehouse                       AS Recipient,
	|	GoodsTable.Ref.DestinationWarehouse                        AS Warehouse,
	|	GoodsTable.Products                                  AS Products,
	|	GoodsTable.Characteristic                                AS Characteristic,
	|	GoodsTable.AssignmentSender                         AS Purpose,
	|	GoodsTable.Purpose                                    AS PurposeForConnection,
	|	GoodsTable.ControlledLotOfTheSender               AS ControlledLotReference,
	|	GoodsTable.Series                                         AS Series,
	|	GoodsTable.BatchesIndicationStatusSender                AS BatchesIndicationStatus,
	|	-(GoodsTable.CountByDocument
	|		- GoodsTable.Count)                             AS Count,
	|	FALSE                                                        AS ExceedingOrder,
	|	FALSE                                                        AS ThisIsAnInvoice,
	|	FALSE                                                        AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|		AND GoodsTable.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|		AND GoodsTable.RowCode <> 0
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|		AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))";
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		ParametersOfModularHolding);
	
EndProcedure

Function QueryTextTTSetOfSeries(Query, QueryTexts)
	
	RegisterName = "TTSeries";
	
	QueryText = 
	"SELECT
	|	SeriesTable.Ref AS Ref,
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	&SourceWarehouse AS SourceWarehouse,
	|	&DestinationWarehouse AS DestinationWarehouse,
	|	SeriesTable.Action AS Action,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	&WarehouseOperation AS WarehouseOperation,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderSchemeWhenReflectingSurplusShortages,
	|	CASE
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderChartForShipmentAtAcceptanceWarehouse,
	|	CASE
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderChartForAcceptanceAtAcceptanceWarehouse,
	|	CASE
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderSchemeWhenReflectingSurplusShortagesAtAcceptanceWarehouse,
	|	CASE
	|		WHEN NOT CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord,
	|	CASE
	|		WHEN NOT DestinationWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseMovementInAcceptanceWarehouse,
	|	SeriesTable.Count - SeriesTable.CountByDocument AS Discrepancies
	|INTO TTSeries
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.SetOfSeries AS SeriesTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouse
	|		ON (CatWarehouse.Ref = &SourceWarehouse)
	|		INNER JOIN Catalog.Warehouses AS DestinationWarehouse
	|		ON (DestinationWarehouse.Ref = &DestinationWarehouse)
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> SeriesTable.CountByDocument
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND &Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Ref AS Ref,
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Series,
	|	&SourceWarehouse,
	|	&DestinationWarehouse,
	|	SeriesTable.Action,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	&WarehouseOperation,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderChartForShipmentAtAcceptanceWarehouse,
	|	CASE
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderChartForAcceptanceAtAcceptanceWarehouse,
	|	CASE
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderSchemeWhenReflectingSurplusShortagesAtAcceptanceWarehouse,
	|	CASE
	|		WHEN NOT CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN NOT DestinationWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				OR DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseMovementInAcceptanceWarehouse,
	|	SeriesTable.Count - SeriesTable.CountByDocument
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS SeriesTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouse
	|		ON (CatWarehouse.Ref = &SourceWarehouse)
	|		INNER JOIN Catalog.Warehouses AS DestinationWarehouse
	|		ON (DestinationWarehouse.Ref = &DestinationWarehouse)
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.CountByDocument <> SeriesTable.Count
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND &Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSeries", QueryTexts) Then
		QueryTextTTSetOfSeries(Query, QueryTexts);
	EndIf;
	
	QueryText =
	// Write-off of the shortage (Discrepancies < 0).
	"SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord)
	|	                                       AS WarehouseOperation,
	|	
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	SeriesTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|	
	|		OR SeriesTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)))
	|
	|UNION ALL
	|
	// Accounting of surpluses (Discrepancies > 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	VALUE(Catalog.Assignments.EmptyRef)
	|	                                       AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord)
	|	                                       AS WarehouseOperation,
	|	
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	SeriesTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(SeriesTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery)))
	|
	|UNION ALL
	|
	// Pre-shipment in case of shortage in an irregular warehouse (Discrepancies < 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	SeriesTable.WarehouseOperation        AS WarehouseOperation,
	|
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	NOT SeriesTable.AdvancedWarehousingOnShipment
	|	AND SeriesTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|	
	|		OR SeriesTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)))
	|	
	|UNION ALL
	|
	// Reflection of the surplus in the order warehouse for shipment with an irregular pattern of reflection of the surplus, in case of shortage at the customer
	// (Discrepancies < 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	SeriesTable.WarehouseOperation        AS WarehouseOperation,
	|	
	|	-SeriesTable.Discrepancies             AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	SeriesTable.AdvancedWarehousingOnShipment
	|	AND NOT SeriesTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|	
	|		OR SeriesTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)))
	|	
	|UNION ALL
	|
	// Compensation of the over-order invoice for the shipment of excess in an irregular warehouse (Discrepancies > 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	SeriesTable.WarehouseOperation        AS WarehouseOperation,
	|	
	|	-SeriesTable.Discrepancies             AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	NOT SeriesTable.AdvancedWarehousingOnShipment
	|	AND SeriesTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND SeriesTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
	|	
	|UNION ALL
	|
	// Reflection of the shortage in the order warehouse for shipment with an irregular pattern of reflecting surpluses, with a surplus from the client
	// (Discrepancies > 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	SeriesTable.WarehouseOperation        AS WarehouseOperation,
	|	
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	SeriesTable.AdvancedWarehousingOnShipment
	|	AND NOT SeriesTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND SeriesTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseMovementInAcceptanceWarehouse AS ThisIsWarehouseRecord,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	
	|	SeriesTable.OrderChartForAcceptanceAtAcceptanceWarehouse
	|	AND NOT SeriesTable.OrderSchemeWhenReflectingSurplusShortagesAtAcceptanceWarehouse
	|	AND SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|
	|UNION ALL
	|
	/////////////////////////////////////////
	// Excess at acceptance (Discrepancies > 0).
	//
	// Compensation for the adjustment of the receipt in the warehouse under the order acceptance scheme.
	// Optimistically, we believe that the receipt order has already reflected the fact of the surplus.
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseMovementInAcceptanceWarehouse     AS ThisIsWarehouseRecord,
	|	SeriesTable.WarehouseOperation AS WarehouseOperation,
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	&Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	
	|	AND SeriesTable.OrderChartForAcceptanceAtAcceptanceWarehouse
	|	AND NOT SeriesTable.OrderSchemeWhenReflectingSurplusShortagesAtAcceptanceWarehouse
	|	AND SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|
	| UNION ALL
	|
	/////////////////////////////////////////
	// Shortage at acceptance (Discrepancies < 0).
	//
	// Compesation of the write-off of the shortage, optimistically considering that the shortage is already reflected in the receipt order.
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	SeriesTable.Products             AS Products,
	|	SeriesTable.Characteristic           AS Characteristic,
	|	SeriesTable.SourceWarehouse         AS Sender,
	|	SeriesTable.DestinationWarehouse          AS Recipient,
	|	SeriesTable.Purpose               AS Purpose,
	|	SeriesTable.Series                    AS Series,
	|	SeriesTable.ThisIsWarehouseMovementInAcceptanceWarehouse     AS ThisIsWarehouseRecord,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	SeriesTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS SeriesTable
	|WHERE
	|	SeriesTable.OrderSchemeWhenReflectingSurplusShortagesAtAcceptanceWarehouse
	|	AND SeriesTable.OrderChartForAcceptanceAtAcceptanceWarehouse
	|	AND SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.Department            AS Department,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.Author                    AS Author,
	|	FALSE                                     AS ReverseTransactionCorrection,
	|	UNDEFINED                             AS ReversedDocument,
	|	UNDEFINED                             AS CorrectedDocument,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	UNDEFINED                             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	CASE
	|		WHEN TableDocumentRegistry.NumberOfActivities = 1
	|			THEN TableDocumentRegistry.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                      AS LineOfBusiness,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	TableDocumentRegistry.Department                      AS Department,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber
	|INTO TTBases
	|	FROM
	|	(SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&Organization                                  AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|		&SourceWarehouse                             AS StorageLocation,
	|		&Department                                AS Department,
	|		&Manager                                     AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING(100))        AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		FALSE                                          AS AdditionalRecord,
	|		&WarehouseInformationRecipient                 AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		MAX(
	|			ISNULL(GoodsTable.AssignmentSender.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS LineOfBusiness,
	|		COUNT(
	|			DISTINCT ISNULL(GoodsTable.AssignmentSender.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS NumberOfActivities
	|	FROM
	|		Document.DiscrepancyReportFollowingTransfer AS DocumentData
	|			LEFT JOIN Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	GROUP BY
	|		DocumentData.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&Organization                                  AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|		&DestinationWarehouse                              AS StorageLocation,
	|		&Department                                AS Department,
	|		&Manager                                     AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING(100))        AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		TRUE                                        AS AdditionalRecord,
	|		&WarehouseInformationToSender                AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		MAX(
	|			ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS LineOfBusiness,
	|		COUNT(
	|			DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|		                                              AS NumberOfActivities
	|	FROM
	|		Document.DiscrepancyReportFollowingTransfer AS DocumentData
	|			LEFT JOIN Document.DiscrepancyReportFollowingTransfer.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	GROUP BY
	|		DocumentData.Ref) AS TableDocumentRegistry
	|
	|GROUP BY
	|	TableDocumentRegistry.RefType,
	|	TableDocumentRegistry.Organization,
	|	TableDocumentRegistry.BusinessOperation,
	|	TableDocumentRegistry.Partner,
	|	TableDocumentRegistry.Counterparty,
	|	CASE
	|		WHEN TableDocumentRegistry.NumberOfActivities = 1
	|			THEN TableDocumentRegistry.LineOfBusiness
	|		ELSE UNDEFINED
	|	END,
	|	TableDocumentRegistry.Department,
	|	TableDocumentRegistry.StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate,
	|	TableDocumentRegistry.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList();
	
	FullDocumentName           = "Document.DiscrepancyReportFollowingTransfer";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",                 """""");
	RedefiningParameterCalculation.Insert("WarehouseInformationRecipient",  """""");
	RedefiningParameterCalculation.Insert("WarehouseInformationToSender", """""");
	RedefiningParameterCalculation.Insert("WarehouseOperation",
												"VALUE(Enum.WarehouseTransactions.SurplusesRecord)");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "SeriesTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

// Generates a verification request when changing the status of the list of documents.
//
// Parameters:
//	DocumentsArray - Array - Array of links to documents to check.
//	NewStatus - String - Name of the new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfDiscrepancyReport[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes.
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string.
//	NewStatus - EnumRef.StatusesOfDiscrepancyReport - new status.
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.SourceWarehouse AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	TabPart.ControlledLotOfTheSender AS ControlledLotReference,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	VALUE(Enum.SupplyOptions.ToSupply) AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	DATETIME(1, 1, 1) AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status = VALUE(Enum.StatusesOfDiscrepancyReport.Approved)
		|		AND TabPart.CountByDocument - TabPart.Count > 0
		|		AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired))";
	
	// Formation of the shipment schedule of the additional goods in the preliminary status.
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		// Compensation for order changes in the order to reflect surpluses/shortages in the warehouse.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.SourceWarehouse AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	TabPart.ControlledLotOfTheSender AS ControlledLotReference,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
		|		 AND TabPart.Ref.SourceWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|		 AND TabPart.Ref.SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date";
		
		StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	/////////////////////////////////////////////////////////////
	// The receiving warehouse. Shortage at acceptance (Discrepancies < 0).
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.DestinationWarehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ToControlQuality
		|			THEN TabPart.ControlledLotReference
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	FALSE AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND TabPart.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND (NOT TabPart.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|			OR TabPart.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date)
		|		AND TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)";
	
	// The document "Write-off of item shortages" / "Registration of surplus items" is storno because the receipt order has already reflected the shortage/surplus in the warehouse.
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.DestinationWarehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND TabPart.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND (NOT TabPart.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|			OR TabPart.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date)
		|		AND TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)";
	
	// The document "Write-off of item shortages" / "Registration of surplus items" is storno because the receipt order has already reflected the shortage/surplus in the warehouse.
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// At the warehouse of the order for acceptance, with the method of reflection that does not provide for a change in the document of movement, it is 
		// necessary to suspend in the act of Registering Records according to the schedule of the incoming order for the amount of surplus/ shortage. 
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.DestinationWarehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	-(TabPart.Count - TabPart.CountByDocument) AS Count,
		|	CASE
		|		WHEN TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|				OR TabPart.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
		|			THEN TabPart.DocumentBasis
		|		ELSE TabPart.OrderDocument
		|	END AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND TabPart.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration))
		|	AND TabPart.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.CancelScheduledStockArrival(Query, QueryTexts, Registers, QueryTextTabPart);
	
	QueryTextTabPart =
		// Shipment of over-delivered goods without control.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.DestinationWarehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotOfTheSender AS ControlledLotReference,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingTransfer.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND TabPart.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|	AND TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnWithoutRegistration)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
EndProcedure

#EndRegion

#Region Other

Function RequestTextDocumentsAndMovingOrder() Export
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	MovementOfGoodsGoods.Ref AS DocumentBasis,
	|	MovementOfGoodsGoods.TransferOrder AS OrderDocument,
	|	UNDEFINED AS Warehouse
	|FROM
	|	Document.InventoryTransfer.Goods AS MovementOfGoodsGoods
	|WHERE
	|	MovementOfGoodsGoods.Ref IN(&ArrayOfBases)
	|TOTALS BY
	|	DocumentBasis";
	
	Return QueryText;
	
EndFunction

Function AddJoinMethodToTable(Table, SeriesSpecificationParameters, SourceWarehouse, DestinationWarehouse)
	
	Table.Columns.Add("ConnectionMethod_", New TypeDescription("String"));
	
	LineNumber = 1;
	For Each String In Table Do
		String.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	// Getting series indication statuses
	ObjectToFillInSeries = New Structure();
	ObjectToFillInSeries.Insert("Goods", Table);
	ObjectToFillInSeries.Insert("SetOfSeries", Table.CopyColumns());
	ObjectToFillInSeries.Insert("SourceWarehouse", SourceWarehouse);
	ObjectToFillInSeries.Insert("DestinationWarehouse", DestinationWarehouse);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ObjectToFillInSeries, SeriesSpecificationParameters);
	
	// Calculation of the connection method
	QueryText = 
	"SELECT
	|	Table.LineNumber,
	|	CASE
	|		WHEN Table.BatchesIndicationStatusSender IN (0)
	|				AND Table.BatchesIndicationStatusRecipient IN (0)
	|			THEN ""A0""
	|		WHEN Table.BatchesIndicationStatusSender IN (1, 2, 3, 4, 5, 6, 7, 8)
	|			THEN ""A4""
	|		WHEN Table.BatchesIndicationStatusSender IN (9, 10, 13, 14)
	|			THEN ""A2""
	|		WHEN Table.BatchesIndicationStatusSender IN (0)
	|				AND Table.BatchesIndicationStatusRecipient IN (13, 14)
	|			THEN ""A2""
	|		ELSE ""A3""
	|	END AS ConnectionMethod_
	|INTO TTProducts_1
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.LineNumber,
	|	TTProducts_1.ConnectionMethod_
	|FROM
	|	TTProducts_1 AS TTProducts_1";
	
	Query = New Query();
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Table", ObjectToFillInSeries.Goods);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		String = Table[Selection.LineNumber - 1];
		String.ConnectionMethod_ = Selection.ConnectionMethod_;
		
	EndDo;
	
	Table.Sort("ConnectionMethod_");
	
	Return Table;
	
EndFunction

#EndRegion

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ActStatuses = New Array;
	ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
	ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														ActStatuses,
														ComparisonType.InList);
	
	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"SelectionTask");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														ActStatuses,
														ComparisonType.InList);
	
EndProcedure

#EndRegion

#EndIf
#EndIf
