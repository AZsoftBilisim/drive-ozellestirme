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
	
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	
	DiscrepancyReportFollowingReceiptLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DiscrepancyReportFollowingReceipt") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	QueryTextTablePurchaseOrders(Query, QueryTexts, Registers);
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
	// 1) Single-pass order. Storno of Registered Records on the warehouse of a separate financial document being drawn up.
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	// 2) Single-pass order. Closing the discrepancy order - an order for Goods to be received when reflected by a separate FIN. a document.
	//   In addition to the "Add without registration" action, as an Incoming Order will be issued according to the current order. 
	// 3) The formation of an order for receipt in a two-way, if the option "Issue and add" and the invoice was on order.
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	
	// 2) Single-pass order. Closing the discrepancy invoice - an order for Goods to be received.  when reflecting a separate fin. a document. 
	// In addition to the "Add without registration" action, as an Incoming Order will be issued according to the current order. 
	// 4) Not a one-way order, only an order shipment. Acceptance of surplus goods to the warehouse, for the action "Return without registration".
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	
	// 5) Non-random one-way operation, only the order reflection of surpluses / shortages. Actions "To issue..." purchase adjustment
	// The act performs the functions of an order to reflect surpluses/shortages.
	RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	// 6) Single-pass order. Planning the shipment of goods for the "Return without registration" action.
	// 4) Not a one-way order, only an order shipment. Planning the shipment of goods for the "Return without registration" action.
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	// 6) Single-pass order. Registration of the planned shipment of goods for the "Return without registration" action.
	// Including the write-off of the goods in the warehouse if the shipment is extraordinary.
	// 4) Not a one-way order, only an order shipment. Registration of the planned shipment of goods for the "Return without registration" action.
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
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

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "TypeOfBaseDocumentForNonConformanceCertificate,Date,BusinessOperation";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - structure of object details values required for filling in parameters for specifying series
// Returns:
//  Structure - See ProductsServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingReceipt";
	
	WarehouseSeriesParameters = New Structure;
	WarehouseSeriesParameters.Insert("UseItemsBatch", GetFunctionalOption("UseItemsBatch"));
	WarehouseSeriesParameters.Insert("UseCostAccountingByBatches",GetFunctionalOption("UseCostAccountingByBatchesWarehouse"));
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent
		Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer);
		
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceiptFromVendor);
		
	Else
		TextOfEssay = NStr("vi = 'Không hỗ trợ nhận tham số sê-ri đối với biên bản có kiểu cơ sở %TypeOfAct%.';
							|ru = 'Не поддерживается получение параметров серий для акта с типом основания %TypeOfAct%.';
							|en = 'Receipt of batch parameters for certificate with base document type %TypeOfAct% is not supported.'; fa = 'Receipt of batch parameters for certificate with base document type %TypeOfAct% is not supported.';
							|it = 'La ricezione dei parametri delle serie per un atto con il tipo di causale %TypeOfAct% non è supportata.';
							|pl = 'Nie jest obsługiwane pobieranie parametrów serii dla aktu z typem podstawy %TypeOfAct%.';
							|tr = '%TypeOfAct%temel tipe sahip bir eylem için seri parametrelerinin alınması desteklenmez.'");
		TextOfEssay = StrReplace(TextOfEssay, "%TypeOfAct%", Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Raise TextOfEssay;
	EndIf;
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
		
	SeriesSpecificationParameters.LinkFields.Add("FilledUsingBaseDocument");
	SeriesSpecificationParameters.LinkFields.Add("DocumentBasis");
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Action");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.SeriesOnlyForCostPrice  = False;
	SeriesSpecificationParameters.Date                         = Object.Date;
	
	OperationsInTransit = New Array();
	OperationsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	OperationsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	OperationsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	
	NonInvoicingOperations = New Array();
	NonInvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	NonInvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	
	BusinessTransactionGoodsInTransitAndNonInvoicing = OperationsInTransit.Find(Object.BusinessOperation) <> Undefined
		Or NonInvoicingOperations.Find(Object.BusinessOperation) <> Undefined;
	TheseAreGoodsInTransit = OperationsInTransit.Find(Object.BusinessOperation) <> Undefined;
	
	SeriesSpecificationParameters.QueryOptions.Insert("TheseAreGoodsInTransit", TheseAreGoodsInTransit);
	SeriesSpecificationParameters.QueryOptions.Insert("UninvoicedReceiptDocumentIsUsed", BusinessTransactionGoodsInTransitAndNonInvoicing);
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.FilledUsingBaseDocument,
	|	Goods.DocumentBasis,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusRecipient,
	|	Goods.Action,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Warehouse,
	|	Goods.FilledUsingBaseDocument,
	|	Goods.DocumentBasis,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Action,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.FilledUsingBaseDocument,
	|	Goods.DocumentBasis,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Action,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.FilledUsingBaseDocument,
	|	SetOfSeries.DocumentBasis,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Action,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.FilledUsingBaseDocument,
	|	SetOfSeries.DocumentBasis,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Action,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.FilledUsingBaseDocument,
	|	SetOfSeries.DocumentBasis,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Action
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusRecipient AS OldStatusOfSpecifyingRecipientSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			OR &UninvoicedReceiptDocumentIsUsed
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND (ProductsToRequest.Count > 0
	|								OR ProductsToRequest.FilledUsingBaseDocument)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND (ProductsToRequest.Count > 0
	|								OR ProductsToRequest.FilledUsingBaseDocument)
	|						THEN 8
	|					ELSE 7
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|					OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|				AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByReturnFromCustomer
	|						AND &ReceivingByReturnFromACustomer
	|					OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingFromVendor
	|						AND &ReceiptFromVendor)
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND (ProductsToRequest.Count > 0
	|											OR ProductsToRequest.FilledUsingBaseDocument)
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND (ProductsToRequest.Count > 0
	|										OR ProductsToRequest.FilledUsingBaseDocument)
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|						WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|						AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|						AND ProductsToRequest.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|						THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|						ELSE 13
	|						END
	|					ELSE 0
	|					END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatusSender,
	|	CASE WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|			AND Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|			AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|					OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue)
	|			AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|			AND ProductsToRequest.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|			THEN CASE
	|				WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|					THEN 4
	|				ELSE 3
	|				END
	|			ELSE 0
	|	END AS StatusOfIndicationOfSeriesOfGoodsUponAcceptance,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					AND &UninvoicedReceiptDocumentIsUsed
	|					THEN
	|						CASE
	|							WHEN ((ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries
	|										AND NOT &TheseAreGoodsInTransit)
	|									OR (ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor)
	|										AND &TheseAreGoodsInTransit)
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatusGoodsAtPartners
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|				AND ProductsToRequest.DocumentBasis = SeriesToRequest.DocumentBasis
	|				AND ProductsToRequest.FilledUsingBaseDocument = SeriesToRequest.FilledUsingBaseDocument
	|				AND ProductsToRequest.Action = SeriesToRequest.Action
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|			AND Goods.DocumentBasis = ProductsToRequest.DocumentBasis
	|			AND Goods.FilledUsingBaseDocument = ProductsToRequest.FilledUsingBaseDocument
	|			AND Goods.Action = ProductsToRequest.Action
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	CASE
	|		WHEN &UninvoicedReceiptDocumentIsUsed
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatusRecipient
	|	END AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN &UninvoicedReceiptDocumentIsUsed
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		WHEN Statuses.BatchesIndicationStatusSender IN (13, 14)
	|			AND Statuses.BatchesIndicationStatusRecipient = 0
	|			THEN Statuses.BatchesIndicationStatusSender
	|		WHEN Statuses.StatusOfIndicationOfSeriesOfGoodsUponAcceptance IN (3, 4)
	|			AND Statuses.BatchesIndicationStatusRecipient = 0
	|			THEN Statuses.StatusOfIndicationOfSeriesOfGoodsUponAcceptance
	|		ELSE Statuses.BatchesIndicationStatusRecipient
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN &UninvoicedReceiptDocumentIsUsed
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		WHEN Statuses.BatchesIndicationStatusSender IN (13, 14)
	|			AND Statuses.BatchesIndicationStatusRecipient = 0
	|			THEN Statuses.BatchesIndicationStatusSender
	|		WHEN Statuses.StatusOfIndicationOfSeriesOfGoodsUponAcceptance IN (3, 4)
	|			AND Statuses.BatchesIndicationStatusRecipient = 0
	|			THEN Statuses.StatusOfIndicationOfSeriesOfGoodsUponAcceptance
	|		ELSE Statuses.BatchesIndicationStatusRecipient
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR
	|	CASE
	|		WHEN &UninvoicedReceiptDocumentIsUsed
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatusRecipient
	|	END <> Statuses.OldStatusOfSpecifyingRecipientSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
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
		
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"DiscrepanciesPostingMethod",
															Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries,
															ComparisonType.Equal);
	EndIf;
	
	DiscrepancyReportFollowingReceiptLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Report of discrepancies after acceptance".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
//	Returns:
//		ValueTableRow - description of the created team.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.DiscrepancyReportFollowingReceipt) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DiscrepancyReportFollowingReceipt);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions =
			"UseNonConformanceCertificatesFollowingAcceptance
			|,UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5
			|,UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5
			|";
		
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
	
	DiscrepancyReportFollowingReceiptLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)";
	DestinationPattern.Partner = "Object.Partner";
	DestinationPattern.Contract = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
	// The needs for work in the recipient department.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Goods.Department";
	
	Return FormTemplate;
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingReceipt - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.Department = Object.Department;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Or
		Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer  Then
		
		FillParameters.ReturnOfGoodsFromCustomer = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		FillParameters.ReturnOfGoodsFromCommissionAgent = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingReceipt - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period =  Object.Date;

	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
		
	If BusinessTransactionsPurchasingFromSupplier.Find(Object.BusinessOperation) <> Undefined
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
		
	ElsIf BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoods = True;
		
	ElsIf  Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale  Then
		
		FillParameters.PurchaseOfGoods = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
		FillParameters.ConsignmentProcurement = True;
		
	ElsIf  Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		FillParameters.PurchaseViaAdvanceHolder = True;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		
		FillParameters.PurchaseOfGoods = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
//  Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParametersArray = New Array;
	
	#Region OtherExpensesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object.Goods";
	ChoiceParameters.AssetRef                = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation     = Enums.BusinessTransactions.PurchaseFromSupplier
	                                         Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
	                                         Or BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
	                                         Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
	                                         Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
	                                         Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
	                                         Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU);
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("FilledUsingBaseDocument", False);
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingReceipt - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,Warehouse,ToExpenseAs";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlContract", Object.Contract);
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.ToExpenseAs AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
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
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(TypeOfBaseDocumentForNonConformanceCertificate)";

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
	JobPrintingRules.VHFWarehouses				= True;
	
	PrintRules.Add(JobPrintingRules);
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.SurplusesRecord		= True;
	JobPrintingRules.VHFWarehouses				= True;
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

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

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("TypeOfBaseDocumentForNonConformanceCertificate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi trả lại từ khách hàng %1 ngày %2';
										|ru = 'Акт о расхождениях после возврата от клиента %1 от %2';
										|en = 'Discrepancy report following the return of goods from a customer %1 dated %2'; fa = 'Discrepancy report following the return of goods from a customer %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo il reso dal cliente %1 di %2';
										|pl = 'Protokół o odchyleniu po zwrocie od klienta %1 z dn. %2';
										|tr = '%1Müşteriden %2 tarihli iade tutarsızlık raporu'"); 
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi nhập hàng vào lưu kho %1 ngày %2';
										|ru = 'Акт о расхождениях после приемки товаров на хранение %1 от %2';
										|en = 'VMI procurement discrepancy report %1 dated %2'; fa = 'VMI procurement discrepancy report %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo la ricezione delle merci in stoccaggio %1 di %2';
										|pl = 'Protokół o odchyleniu po przyjęciu towarów do przechowywania %1 z dn. %2';
										|tr = '%2 tarihli depolanan stok farkları raporu %1'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate =
						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận nguyên vật liệu từ bên đặt gia công %1 ngày %2';
										|ru = 'Акт о расхождениях после поступления сырья от давальца %1 от %2';
										|en = 'Discrepancy report following the receipt of raw materials from a provider %1 dated %2'; fa = 'Discrepancy report following the receipt of raw materials from a provider %1 dated %2';
										|it = 'Акт о расхождениях после поступления сырья от давальца %1 от %2';
										|pl = 'Discrepancy report following the receipt of raw materials from a provider %1 dated %2';
										|tr = 'Hammaddelerin %1sağlayıcından alınması sonrası %2 tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận hàng hóa từ bên lưu kho %1 ngày %2';
										|ru = 'Акт о расхождениях после поступления товаров от хранителя %1 от %2';
										|en = 'Discrepancy report following VMI return %1 dated %2'; fa = 'Discrepancy report following VMI return %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo la ricezione delle merci dallo stoccaggio %1 di %2';
										|pl = 'Protokół o odchyleniu po przyjęciu towarów od depozytariusza %1 z dn. %2';
										|tr = 'Malların %1 VMI''dan teslim alınması sonrası %2 tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận từ bên nhận gia công %1 ngày %2';
										|ru = 'Акт о расхождениях после поступления от переработчика %1 от %2';
										|en = 'Discrepancy report following the receipt of goods from a subcontractor %1 dated %2'; fa = 'Discrepancy report following the receipt of goods from a subcontractor %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo la ricezione dal gestore %1 di %2';
										|pl = 'Protokół o odchyleniu po przyjęciu od przetwórcy %1 z dn. %2';
										|tr = '%1 Fason üreticiden teslim alım sonrası %2 tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi trả lại nguyên vật liệu từ bên nhận gia công %1 ngày %2';
										|ru = 'Акт о расхождениях после возврата сырья от переработчика %1 от %2';
										|en = 'Discrepancy report following the return of raw materials from a subcontractor %1 dated %2'; fa = 'Discrepancy report following the return of raw materials from a subcontractor %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo il reso di materie prime dal gestore %1 di %2';
										|pl = 'Protokół o odchyleniu po zwrocie od surowców od przetwórcy %1 z dn. %2';
										|tr = 'Hammaddelerin %1 fason üreticiden iadesi sonrası %2 tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận hàng hóa từ bên nhận ký gửi %1 ngày %2';
										|ru = 'Акт о расхождениях после поступления товаров от комиссионера %1 от %2';
										|en = 'Discrepancy report following the receipt of goods from a consignee %1 dated %2'; fa = 'Discrepancy report following the receipt of goods from a consignee %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo la ricezione delle merci dal commissionario %1 di %2';
										|pl = 'Protokół o odchyleniu po przyjęciu towarów od komisanta %1 z dn. %2';
										|tr = 'Malların %1konsinyeden alınması sonrası %2 tarihli tutarsızlık raporu'");
	Else
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi tiếp nhận %1 ngày %2';
										|ru = 'Акт о расхождениях после поступления %1 от %2';
										|en = 'Discrepancy report following the receipt of goods %1 dated %2'; fa = 'Discrepancy report following the receipt of goods %1 dated %2';
										|it = 'Акт о расхождениях после поступления %1 от %2';
										|pl = 'Discrepancy report following the receipt of goods %1 dated %2';
										|tr = '%1Teslim alım sonrası %2tarihli tutarsızlık raporu'");
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
		Data.Number,
		Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;
	QueryTextDocumentData(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

// To create shared temporary tables in document update handlers.
// Parameters:
//  ListOfRequests - Array of String
Procedure QueryTextDocumentData(ListOfRequests) Export
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataDocumentDataTableGoodsToConnectToSeries(ListOfRequests);
	QueryTextDocumentDataBatchTable(ListOfRequests);
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader =
		"SELECT
		|	HeaderData_.Ref AS Ref,
		|	HeaderData_.DataVersion AS DataVersion,
		|	HeaderData_.DeletionMark AS DeletionMark,
		|	HeaderData_.Number AS Number,
		|	HeaderData_.Date AS Date,
		|	HeaderData_.Posted AS Posted,
		|	HeaderData_.Organization AS Organization,
		|	HeaderData_.Currency AS Currency,
		|	HeaderData_.Partner AS Partner,
		|	HeaderData_.Counterparty AS Counterparty,
		|	HeaderData_.Comment AS Comment,
		|	HeaderData_.ContactPerson AS ContactPerson,
		|	HeaderData_.Terms AS Terms,
		|	HeaderData_.Status AS Status,
		|	HeaderData_.Manager AS Manager,
		|	HeaderData_.VATTaxation AS VATTaxation,
		|	HeaderData_.PriceIncludesVAT AS PriceIncludesVAT,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	HeaderData_.Contract AS Contract,
		|	HeaderData_.AdditionalInformation AS AdditionalInformation,
		|	HeaderData_.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
		|	HeaderData_.TypeOfBaseDocumentForNonConformanceCertificate AS TypeOfBaseDocumentForNonConformanceCertificate,
		|	HeaderData_.Department AS Department,
		|	HeaderData_.BaseDocumentForDrawingUpCertificate AS BaseDocumentForDrawingUpCertificate,
		|	HeaderData_.PlaceForGoodsReceipt AS PlaceForGoodsReceipt,
		|	HeaderData_.DateOfGoodsDelivery AS DateOfGoodsDelivery,
		|	HeaderData_.ListOfSupportingDocuments AS ListOfSupportingDocuments,
		|	HeaderData_.InvitedPartnerRepresentative AS InvitedPartnerRepresentative,
		|	HeaderData_.DocumentKindForInvitationOfPartnerRepresentative AS DocumentKindForInvitationOfPartnerRepresentative,
		|	HeaderData_.NumberOfDocumentOnPartnerRepresentativeInvitation AS NumberOfDocumentOnPartnerRepresentativeInvitation,
		|	HeaderData_.Shipper AS Shipper,
		|	HeaderData_.Manufacturer AS Manufacturer,
		|	HeaderData_.InsuranceCompany AS InsuranceCompany,
		|	HeaderData_.InsuranceCompanyCounterparty AS InsuranceCompanyCounterparty,
		|	HeaderData_.PurchaseContractNumber AS PurchaseContractNumber,
		|	HeaderData_.DateOfPurchaseContract AS DateOfPurchaseContract,
		|	HeaderData_.CommercialReportNumber AS CommercialReportNumber,
		|	HeaderData_.DateOfCommercialReport AS DateOfCommercialReport,
		|	HeaderData_.QualityCertificateNumber AS QualityCertificateNumber,
		|	HeaderData_.QualityCertificateDate AS QualityCertificateDate,
		|	HeaderData_.VeterinaryCertificateNumber AS VeterinaryCertificateNumber,
		|	HeaderData_.VeterinaryCertificateDate AS VeterinaryCertificateDate,
		|	HeaderData_.RailConsignmentNoteNumber AS RailConsignmentNoteNumber,
		|	HeaderData_.RailConsignmentNoteDate AS RailConsignmentNoteDate,
		|	HeaderData_.BillOfLadingNumber AS BillOfLadingNumber,
		|	HeaderData_.BillOfLadingDate AS BillOfLadingDate,
		|	HeaderData_.DeliveryMethod AS DeliveryMethod,
		|	HeaderData_.VehicleNumber AS VehicleNumber,
		|	HeaderData_.SenderWarehouse AS SenderWarehouse,
		|	HeaderData_.InformationOnTransportConditionAccordingToSupportingDocuments AS InformationOnTransportConditionAccordingToSupportingDocuments,
		|	HeaderData_.InformationOnActualTransportCondition AS InformationOnActualTransportCondition,
		|	HeaderData_.GoodsStorageConditionsBeforeItsOpeningInDestinationWarehouse AS GoodsStorageConditionsBeforeItsOpeningInDestinationWarehouse,
		|	HeaderData_.InformationOnTemperatureWhenUnloading AS InformationOnTemperatureWhenUnloading,
		|	HeaderData_.PackageAndContainerCondition AS PackageAndContainerCondition,
		|	HeaderData_.InformationOnExternalMarking AS InformationOnExternalMarking,
		|	HeaderData_.PackageOpeningDate AS PackageOpeningDate,
		|	HeaderData_.CompanyThatWeighedAndSealedGoods AS CompanyThatWeighedAndSealedGoods,
		|	HeaderData_.GoodsPickingProcedureForRandomInspection AS GoodsPickingProcedureForRandomInspection,
		|	HeaderData_.QuantityWeightMeasurementMethod AS QuantityWeightMeasurementMethod,
		|	HeaderData_.PlaceToDetermineQuantityWeight AS PlaceToDetermineQuantityWeight,
		|	HeaderData_.InformationOnWeightMeasuringDevicesOperability AS InformationOnWeightMeasuringDevicesOperability,
		|	HeaderData_.OtherData AS OtherData,
		|	HeaderData_.DefectDetailedDescription AS DefectDetailedDescription,
		|	HeaderData_.CommissionConclusion AS CommissionConclusion,
		|	HeaderData_.Application AS Application,
		|	HeaderData_.DocumentCertifyingPowersOfVendorSRepresentative AS DocumentCertifyingPowersOfVendorSRepresentative,
		|	HeaderData_.NumberOfDocumentCertifyingPowersOfVendorSRepresentative AS NumberOfDocumentCertifyingPowersOfVendorSRepresentative,
		|	HeaderData_.DateOfIssueOfDocumentConfirmingAuthorityOfPartnerRepresentative AS DateOfIssueOfDocumentConfirmingAuthorityOfPartnerRepresentative,
		|	HeaderData_.NumberOfAnnexSheets AS NumberOfAnnexSheets,
		|	HeaderData_.ExecutiveDecision AS ExecutiveDecision,
		|	HeaderData_.WarehousemanWhoReceivedGoods AS WarehousemanWhoReceivedGoods,
		|	HeaderData_.GrossWeightAccordingToManufacturer AS GrossWeightAccordingToManufacturer,
		|	HeaderData_.DateOfGoodsDispatch AS DateOfGoodsDispatch,
		|	HeaderData_.GrossWeightAtDeparturePoint AS GrossWeightAtDeparturePoint,
		|	HeaderData_.GrossWeightAtDestinationPoint AS GrossWeightAtDestinationPoint,
		|	HeaderData_.NumberOfUnitLoadsAccordingToSenderDocuments AS NumberOfUnitLoadsAccordingToSenderDocuments,
		|	HeaderData_.NumberOfUnitLoadsAsReceived AS NumberOfUnitLoadsAsReceived,
		|	HeaderData_.GrossWeightAccordingToSenderDocuments AS GrossWeightAccordingToSenderDocuments,
		|	HeaderData_.ActualGrossWeight AS ActualGrossWeight,
		|	HeaderData_.NetWeightAccordingToSenderDocuments AS NetWeightAccordingToSenderDocuments,
		|	HeaderData_.ActualNetWeight AS ActualNetWeight,
		|	HeaderData_.PackageWeightAccordingToSenderDocuments AS PackageWeightAccordingToSenderDocuments,
		|	HeaderData_.ActualPackageWeight AS ActualPackageWeight,
		|	HeaderData_.FillingDegreeAccordingToSenderDocuments AS FillingDegreeAccordingToSenderDocuments,
		|	HeaderData_.ActualFillingDegree AS ActualFillingDegree,
		|	HeaderData_.CommissionChairperson AS CommissionChairperson,
		|	HeaderData_.JobTitleOfCommissionChairperson AS JobTitleOfCommissionChairperson,
		|	HeaderData_.CommissionMember1 AS CommissionMember1,
		|	HeaderData_.CommitteeMemberJobTitle1 AS CommitteeMemberJobTitle1,
		|	HeaderData_.CommissionMember2 AS CommissionMember2,
		|	HeaderData_.CommitteeMemberJobTitle2 AS CommitteeMemberJobTitle2,
		|	HeaderData_.CommissionMember3 AS CommissionMember3,
		|	HeaderData_.CommitteeMemberJobTitle3 AS CommitteeMemberJobTitle3,
		|	HeaderData_.Director AS Director,
		|	HeaderData_.ChiefAccountant AS ChiefAccountant,
		|	HeaderData_.TemperatureInsideMeatFish AS TemperatureInsideMeatFish,
		|	HeaderData_.JobTitleExecutive AS JobTitleExecutive,
		|	HeaderData_.DateOfDocumentOnPartnerRepresentativeInvitation AS DateOfDocumentOnPartnerRepresentativeInvitation,
		|	HeaderData_.DeparturePoint AS DeparturePoint,
		|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
		|	HeaderData_.NumberOfBaseDocument AS NumberOfBaseDocument,
		|	HeaderData_.ReferenceDocumentDateForCertificate AS ReferenceDocumentDateForCertificate,
		|	HeaderData_.Author AS Author,
		|	HeaderData_.Presentation AS Presentation,
		|	HeaderData_.PointInTime AS PointInTime,
		|	HeaderData_.Ref.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
		|	) AS SeparatePurchasingOfGoods,
		|	HeaderData_.Ref.BusinessOperation IN(
		|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|		AND ISNULL(HeaderData_.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices),
		|			FALSE) AS SeparatePurchasingOfServices
		|INTO DocumentDataHeader
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt AS HeaderData_
		|WHERE
		|	HeaderData_.Ref IN(&Ref)";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Goods.LineNumber AS LineNumber,
		|	Goods.PartnerProducts AS PartnerProducts,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.ToControlQuality AS ToControlQuality,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Package AS Package,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.Count AS Count,
		|	Goods.VendorPriceKind AS VendorPriceKind,
		|	Goods.Price AS Price,
		|	Goods.Sum AS Sum,
		|	Goods.VATRate AS VATRate,
		|	Goods.VATAmount AS VATAmount,
		|	Goods.AmountIncludingVAT AS AmountIncludingVAT,
		|	Goods.PurchaseOrder AS PurchaseOrder,
		|	Goods.RowCode AS RowCode,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
		|	Goods.DocumentBasis AS DocumentBasis,
		|	Goods.FilledUsingBaseDocument AS FilledUsingBaseDocument,
		|	Goods.NumberOfPackagesByDocument AS NumberOfPackagesByDocument,
		|	Goods.CountByDocument AS CountByDocument,
		|	Goods.SumByDocument AS SumByDocument,
		|	Goods.VATAmountByDocument AS VATAmountByDocument,
		|	Goods.AmountIncludingVATByDocument AS AmountIncludingVATByDocument,
		|	Goods.PassportNumber AS PassportNumber,
		|	Goods.Action AS Action,
		|	Goods.VendorSComment AS VendorSComment,
		|	Goods.ManagerComment AS ManagerComment,
		|	Goods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
		|	Goods.ThirdPartyIsGuilty AS ThirdPartyIsGuilty,
		|	Goods.ToExpenseAs AS ToExpenseAs,
		|	Goods.ExpenseItem AS ExpenseItem,
		|	Goods.DimensionOfExpenses AS DimensionOfExpenses,
		|	Goods.Department AS Department,
		|	Goods.SalesOpportunity AS SalesOpportunity,
		|	Goods.CCDNumber AS CCDNumber,
		|	Goods.Certificate AS Certificate,
		|	NOT Goods.PurchaseOrder IN(
		|		UNDEFINED,
		|		VALUE(Document.PurchaseOrder.EmptyRef),
		
		|		VALUE(Document.SubcontractOrder2_5.EmptyRef),
		
		|		VALUE(Document.MaterialProviderOrder2_5.EmptyRef),
		
		|		VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)) AS ReceiptUnderOrders,
		|	ISNULL(Goods.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages, FALSE) AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	ISNULL(Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages, DATETIME(1,1,1)) AS StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	ISNULL(Goods.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt, FALSE) AS UseWarehouseManagemantSystemForGoodsReceipt,
		|	ISNULL(Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt, DATETIME(1,1,1)) AS StartDateOfWarehouseManagemantSystemForGoodsReceipt,
		|	ISNULL(Goods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue, FALSE) AS UseWarehouseManagemantSystemForGoodsIssue,
		|	ISNULL(Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1)) AS StartDateOfWarehouseManagemantSystemForGoodsIssue,
		|	Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage)) AS ThisIsAProduct,
		// Fields for two-way services, in them the behavior is the same for works and services. 
		|	Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.Work_5),
		|		VALUE(Enum.ItemsTypes.OperationService)) AS IsService
		|INTO DocumentDataTableItems
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS Goods
		|WHERE
		|	Goods.Ref IN(&Ref)
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure QueryTextDocumentDataDocumentDataTableGoodsToConnectToSeries(ListOfRequests)
	
	QueryTextTableGoods =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.DocumentBasis AS DocumentBasis,
		|	Goods.FilledUsingBaseDocument AS FilledUsingBaseDocument,
		|	Goods.Action AS Action,
		|	MAX(Goods.ToControlQuality) AS ToControlQuality,
		|	MAX(Goods.ControlledLotReference) AS ControlledLotReference,
		|	MAX(Goods.BatchesIndicationStatus) AS BatchesIndicationStatus,
		|	MAX(Goods.ThisIsAProduct) AS ThisIsAProduct,
		|	MAX(Goods.UseWarehouseManagemantSystemForGoodsReceipt) AS UseWarehouseManagemantSystemForGoodsReceipt,
		|	MAX(Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt) AS StartDateOfWarehouseManagemantSystemForGoodsReceipt,
		|	MAX(Goods.UseWarehouseManagemantSystemForGoodsSurplusesShortages) AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	MAX(Goods.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages) AS StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	MAX(Goods.UseWarehouseManagemantSystemForGoodsIssue) AS UseWarehouseManagemantSystemForGoodsIssue,
		|	MAX(Goods.StartDateOfWarehouseManagemantSystemForGoodsIssue) AS StartDateOfWarehouseManagemantSystemForGoodsIssue
		|INTO DocumentDataTableGoodsToConnectToSeries
		|FROM
		|	DocumentDataTableItems AS Goods
		|GROUP BY
		|	Goods.Ref,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Warehouse,
		|	Goods.DocumentBasis,
		|	Goods.FilledUsingBaseDocument,
		|	Goods.Action
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure QueryTextDocumentDataBatchTable(ListOfRequests)
	
	QueryTextTableSetOfSeries =
		"SELECT
		|	SetOfSeries.Ref AS Ref,
		|	SetOfSeries.LineNumber AS LineNumber,
		|	SetOfSeries.Series AS Series,
		|	SetOfSeries.Count AS Count,
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SetOfSeries.Purpose AS Purpose,
		|	SetOfSeries.Warehouse AS Warehouse,
		|	SetOfSeries.CountByDocument AS CountByDocument,
		|	SetOfSeries.DocumentBasis AS DocumentBasis,
		|	SetOfSeries.FilledUsingBaseDocument AS FilledUsingBaseDocument,
		|	SetOfSeries.Action AS Action
		|INTO DocumentDataBatchTable
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS SetOfSeries
		|WHERE
		|	SetOfSeries.Ref IN(&Ref)
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryTextTableSetOfSeries);
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	HeaderData_.Date AS Period,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.Partner AS Partner,
	|	HeaderData_.Counterparty AS Counterparty,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Currency AS Currency,
	|	HeaderData_.Status AS Status,
	|	HeaderData_.PriceIncludesVAT AS PriceIncludesVAT,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.Contract AS Contract,
	|	HeaderData_.Department AS Department,
	|	HeaderData_.Manager AS Manager,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
	|	HeaderData_.TypeOfBaseDocumentForNonConformanceCertificate AS TypeOfBaseDocumentForNonConformanceCertificate,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                        Attributes.Period);
	Query.SetParameter("DeletionMark",               Attributes.DeletionMark);
	Query.SetParameter("Posted",                      Attributes.Posted);
	Query.SetParameter("Partner",                       Attributes.Partner);
	Query.SetParameter("Counterparty",                    Attributes.Counterparty);
	Query.SetParameter("Currency",                        Attributes.Currency);
	Query.SetParameter("Status",                        Attributes.Status);
	Query.SetParameter("Organization",                   Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",               Attributes.PriceIncludesVAT);
	Query.SetParameter("BusinessOperation",         Attributes.BusinessOperation);
	Query.SetParameter("Contract",                       Attributes.Contract);
	Query.SetParameter("Department",                 Attributes.Department);
	Query.SetParameter("Manager",                 	   Attributes.Manager);
	Query.SetParameter("MetadataIdentifier",       Common.MetadataObjectID("Document.DiscrepancyReportFollowingReceipt"));
	Query.SetParameter("NumberForPrinting",       		   ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("Number",       		   		   Attributes.Number);
	Query.SetParameter("DiscrepanciesPostingMethod",    Attributes.DiscrepanciesPostingMethod);
	Query.SetParameter("WarehouseOperation",             WarehouseOperationByBaseType(Attributes.TypeOfBaseDocumentForNonConformanceCertificate));
	Query.SetParameter("Comment",                   Attributes.Comment);
	Query.SetParameter("Author",                         Attributes.Author);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	If PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Attributes.GoodsReceiptOption) Then
		Query.SetParameter("InvoiceIsOrder", True);
	Else
		Query.SetParameter("InvoiceIsOrder", False);
	EndIf;
	
	TwoWayOperations = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
	Query.SetParameter("TwoWayOperations", TwoWayOperations);
	
EndProcedure

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	// Order warehouse, one-way warehouse. The actual Balance of the goods in the warehouse corresponds to the accounting
	// one immediately after the receipt order is issued. The act decided that they would issue a discrepancy in
	// the financial outline without changing the purchase document:
	// - by means of a warehouse act: Registration of surplus goods / Write-off of goods shortages
	// - by adjusting the purchase (available only for the Act of Purchasing goods and services):
	//   Increase the purchase, Increase the free Balance /
	//   Increase the purchase, Take into account the inventory /
	//   Reduce the purchase, Reduce the free Balance /
	//   Reduce the purchase, Take into account the inventory.
	// Both documents have Registered Records in the warehouse, which will lead to a distortion of accounting in the warehouse. It is necessary to reverse.
	// The warehouse act and the Purchase Adjustment may contain series that are only indicated at cost.
	// The mechanics of holding these documents in the warehouse assumes that the series is stored in the goods table.
	// The series in the Certificate of Discrepancies are filled in according to parameters similar to the Purchase of goods and services. The series at cost
	// is indicated in the goods table and will be taken into account by the mechanics of the warehouse on a regular basis. 
	
	// Storno warehouse act / adjustment of purchase at the order warehouse in odnohodovka.
	QueryTextDocument_ =
		"SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	CASE
		|		WHEN Goods.ToControlQuality
		|			THEN Goods.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.CountByDocument - Goods.Count AS Count
		|FROM
		|	DocumentDataTableItems AS Goods
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN(&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date
		|	AND (Goods.Action IN(
		|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
		|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses))
		|		OR Header.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|			AND Header.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|			AND Goods.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)))";
	
	WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.Ref                   AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	GoodsTable.Ref.Date              AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	CASE WHEN GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
	|			GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                  AS Warehouse,
	|	GoodsTable.CountByDocument - GoodsTable.Count               AS Ordered,
	|	GoodsTable.CountByDocument - GoodsTable.Count               AS ToRegister
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND GoodsTable.RowCode <> 0
	|	AND GoodsTable.PurchaseOrder NOT IN (
	|		UNDEFINED,
	|		VALUE(Document.MaterialProviderOrder2_5.EmptyRef),
	|		VALUE(Document.PurchaseOrder.EmptyRef),
	|		VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
	|		)
	|
	|	AND GoodsTable.CountByDocument <> GoodsTable.Count
	|	AND GoodsTable.Ref.Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|
	|	AND GoodsTable.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|	AND GoodsTable.Action IN(
	|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|
	|	AND GoodsTable.Ref.BusinessOperation IN(
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	// Odnohodovka. The act decided that they would issue a discrepancy in
	// the financial outline without changing the purchase document:
	// - by means of a warehouse act: Registration of surplus goods / Write-off of goods shortages
	// - by adjusting the purchase (available only for the Act of Purchasing goods and services):
	//   Increase the purchase, Increase the free Balance /
	//   Increase the purchase, Take into account the inventory /
	//   Reduce the purchase, Reduce the free Balance /
	//   Reduce the purchase, Take into account the inventory.
	// In this case, you need to remove the discrepancy from the register of Goods for receipt.
	// The warehouse mechanics of operation uses the series regularly, since in the Act they are edited in the same manner as in
	// Purchase of goods and services.
	// Similarly, if you decide to return the surplus without paperwork.
	// In a two-way system, these Registered Recorded movements are performed in the fins that are being processed. documents: "Adjustment of acquisition"
	// and Write-off of discrepancies between acquisition and receipt.
	
	// Two-way. The act decided that they would issue a discrepancy in
	// the financial outline without changing the purchase document:
	// - by adjusting the purchase (available only for the Act of Purchasing goods and services):
	//   Reduce the purchase, Reduce the free Balance /
	//   Reduce the purchase, Take into account the inventory.
	// At the same time, they will deliver undelivered goods - the action in the "Arrange and deliver" Act.
	// In this case, it is necessary to issue an order for additional delivery according to the same order only if the line of discrepancy on the order,
	// then the new invoice will be issued according to the same order. It is necessary to make Register Recorded increasing the order in Goods for receipt.
	// The of operation is executed with an empty series, since the series are not specified in the orders.
	
	// Elimination of discrepancies in the PH of Goods for receipt in a one-way package.
	QueryTextDocument_ =
		"SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Header.Contract AS Contract,
		|	Header.Terms AS Terms,
		|	Header.Partner AS Sender,
		|	Header.BusinessOperation AS BusinessOperation,
		|	Header.GoodsReceiptOption AS GoodsReceiptOption,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Goods.DocumentBasis AS Invoice,
		|	Goods.PurchaseOrder AS OrderDocument,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ToControlQuality AS ToControlQuality,
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		//	The Registered Record is in excess of the order, regardless of whether the order line is or not, so as not to distort the resource of the order-invoice bundle.
		|	Goods.ReceiptUnderOrders AS ExceedingOrder,
		|	TRUE AS ThisIsAnInvoice,
		|	Goods.Count - Goods.CountByDocument AS Count,
		|	Goods.ReceiptUnderOrders AS ReceiptUnderOrders
		|FROM
		|	DocumentDataTableItems AS Goods
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN (&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND(
		|		NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|			AND (Goods.Action IN(
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration))
		|				OR Header.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|					AND Header.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|					AND Goods.Action IN(
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))))
		|
		|UNION ALL
		|
		// Issuing an order for the "Issue and add" action.
		|SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Header.Contract AS Contract,
		|	Header.Terms AS Terms,
		|	Header.Partner AS Sender,
		|	Header.BusinessOperation AS BusinessOperation,
		|	Header.GoodsReceiptOption AS GoodsReceiptOption,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	UNDEFINED AS Invoice,
		|	Goods.PurchaseOrder AS OrderDocument,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ToControlQuality AS ToControlQuality,
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	UNDEFINED AS ControlledLotReference,
		|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
		|	0 AS BatchesIndicationStatus,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS ThisIsAnInvoice,
		|	Goods.CountByDocument - Goods.Count AS Count,
		|	FALSE AS ReceiptUnderOrders
		|FROM
		|	DocumentDataTableItems AS Goods
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN (&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND (Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|		OR Header.SeparatePurchasingOfServices AND Goods.IsService)
		|	AND VALUETYPE(Goods.PurchaseOrder) = TYPE(Document.PurchaseOrder)
		|	AND Goods.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|	AND Goods.RowCode <> 0
		|	AND Header.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|	AND Header.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|	AND Goods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)";
	
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"Goods");
	
EndProcedure

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)
	
	// Odnohodovka. The act decided that they would issue a discrepancy in
	// the financial outline without changing the purchase document:
	// - by means of a warehouse act: Registration of surplus goods / Write-off of goods shortages
	// - by adjusting the purchase (available only for the Act of Purchasing goods and services):
	//   Increase the purchase, Increase the free Balance /
	//   Increase the purchase, Take into account the inventory /
	//   Reduce the purchase, Reduce the free Balance /
	//   Reduce the purchase, Take into account the inventory.
	// In this case, you need to remove the discrepancy from the register of Goods for receipt for all actions in the Act.
	// The warehouse mechanics of operation uses the series regularly, since in the Act they are edited in the same manner as in
	// Purchase of goods and services.
	// Similarly, if you decide to return the surplus without paperwork.
	
	// Elimination of discrepancies in the PH of Goods for receipt.
	RegisterName = "GoodsToReceive";
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		QueryTextDocument_ =
			"SELECT
			|	Header.Ref AS Ref,
			|	Header.Date AS Date,
			|	Header.Contract AS Contract,
			|	Header.Terms AS Terms,
			|	Header.Partner AS Sender,
			|	Header.BusinessOperation AS BusinessOperation,
			|	Header.GoodsReceiptOption AS GoodsReceiptOption,
			|	FALSE AS Patch,
			|	UNDEFINED AS CorrectedDocument,
			|	Goods.DocumentBasis AS Invoice,
			|	Goods.PurchaseOrder AS OrderDocument,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Purpose AS Purpose,
			|	Goods.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	Goods.ControlledLotReference AS ControlledLotReference,
			|	Goods.Series AS Series,
			|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
		//	The Registered Record is in excess of the order, regardless of whether the order line is or not, so as not to distort the resource of the order-invoice bundle.
			|	Goods.ReceiptUnderOrders AS ExceedingOrder,
			|	TRUE AS ThisIsAnInvoice,
			|	Goods.Count - Goods.CountByDocument AS Count,
			|	Goods.ReceiptUnderOrders AS ReceiptUnderOrders,
			|	FALSE AS ThisIsAdjustmentInsideInvoice
			|FROM
			|	DocumentDataTableItems AS Goods
			|		INNER JOIN DocumentDataHeader AS Header
			|		ON Header.Ref = Goods.Ref
			|WHERE
			|	Header.Ref IN (&Ref)
			|	AND Header.Status IN(
			|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
			|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
			|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
			|	AND (Goods.Action IN(
			|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
			|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),
			|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration))
			|		OR Header.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
			|			AND Header.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
			|			AND Goods.Action IN(
			|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
			|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
			|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
			|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)))";
		
		AdditionalSeriesConnectionFields = New Array();
		AdditionalSeriesConnectionFields.Add("FilledUsingBaseDocument");
		AdditionalSeriesConnectionFields.Add("DocumentBasis");
		AdditionalSeriesConnectionFields.Add("Action");
		AdditionalSeriesConnectionFields.Add("Purpose");
		
		SubstitutionOfSeriesFields = New Map();
		SubstitutionOfSeriesFields.Insert("SeriesData_.Count",
			"(SeriesData_.Count - SeriesData_.CountByDocument)");
		
		ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
		ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
		ParametersOfModularHolding.SynonymForDocumentTable = "Goods";
		ParametersOfModularHolding.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
		ParametersOfModularHolding.SubstitutionOfSeriesFields = SubstitutionOfSeriesFields;
		
		WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(Query,
			QueryTexts,
			RegisterName,
			QueryTextDocument_,
			Metadata.Documents.DiscrepancyReportFollowingReceipt,
			ParametersOfModularHolding);
		
	EndIf;
	
	// Not an order warehouse, a one-way warehouse. The actual Balance of the goods in the warehouse does not correspond to the accounting.
	// The act decided to "Return without registration." To return the goods (issue a spending order if necessary)
	// It must first be accepted for Goods in warehouses, since the documents are not reissued and the surplus has not been identified in any way.
	// The series indication policies are warehouse "by Balance in the warehouse" and "when planning shipment", the series should be taken from a separate tabular part.
	
	// Acceptance of goods to the warehouse on the waybill.
	RegisterName = "ProductStock";
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		QueryTextDocument_ =
			"SELECT
			|	Header.Ref AS Ref,
			|	Header.Date AS Date,
			|	Header.Contract AS Contract,
			|	Header.Terms AS Terms,
			|	Header.Partner AS Sender,
			|	Header.BusinessOperation AS BusinessOperation,
			|	Header.GoodsReceiptOption AS GoodsReceiptOption,
			|	FALSE AS Patch,
			|	UNDEFINED AS CorrectedDocument,
			|	Goods.DocumentBasis AS Invoice,
			|	Goods.PurchaseOrder AS OrderDocument,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Purpose AS Purpose,
			|	Goods.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	Goods.ControlledLotReference AS ControlledLotReference,
			|	Goods.Series AS Series,
			|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	FALSE AS ExceedingOrder,
			|	TRUE AS ThisIsAnInvoice,
			|	Goods.Count - Goods.CountByDocument AS Count,
			|	FALSE AS ReceiptUnderOrders,
			|	FALSE AS ThisIsAdjustmentInsideInvoice
			|FROM
			|	DocumentDataTableItems AS Goods
			|		INNER JOIN DocumentDataHeader AS Header
			|		ON Header.Ref = Goods.Ref
			|WHERE
			|	Header.Ref IN (&Ref)
			|	AND Header.Status IN(
			|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
			|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
			|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
			|	AND NOT (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date)
			|	AND Goods.UseWarehouseManagemantSystemForGoodsIssue AND Goods.StartDateOfWarehouseManagemantSystemForGoodsIssue <= Header.Date
			|	AND Goods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)";
		
		AdditionalSeriesConnectionFields = New Array();
		AdditionalSeriesConnectionFields.Add("FilledUsingBaseDocument");
		AdditionalSeriesConnectionFields.Add("DocumentBasis");
		AdditionalSeriesConnectionFields.Add("Action");
		AdditionalSeriesConnectionFields.Add("Purpose");
		
		SubstitutionOfSeriesFields = New Map();
		SubstitutionOfSeriesFields.Insert("SeriesData_.Count",
			"(SeriesData_.Count - SeriesData_.CountByDocument)");
		
		ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
		ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
		ParametersOfModularHolding.SynonymForDocumentTable = "Goods";
		ParametersOfModularHolding.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
		ParametersOfModularHolding.SubstitutionOfSeriesFields = SubstitutionOfSeriesFields;
		
		WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(Query,
			QueryTexts,
			RegisterName,
			QueryTextDocument_,
			Metadata.Documents.DiscrepancyReportFollowingReceipt,
			ParametersOfModularHolding);
		
	EndIf;
	
EndProcedure

Procedure RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers)

	// Not an order warehouse, a one-way warehouse. The actual Balance of the goods in the warehouse does not correspond to the accounting.
	// The act decided that they would issue a discrepancy in
	// the financial outline without changing the receipt document:
	// - by adjusting the purchase (available only for the Act of Purchasing goods and services):
	//   Increase the purchase, Increase the free Balance /
	//   Increase the purchase, Take into account the inventory /
	//   Reduce the purchase, Reduce the free Balance /
	//   Reduce the purchase, Take into account the inventory.
	// In this case, the Act takes over the functions of an order to reflect surpluses/shortages
	// in order to eliminate the discrepancy in the warehouse. Otherwise, the storekeeper is forced to issue an Order for the reflection of surpluses / shortages, which immediately after
	// registration leads to the appearance of the task of registration of the Warehouse act in the appropriate workplace. And in this case, it is not formalized,
	// since an adjustment of the receipt is being formalized.
	
	// Registration of surplus/shortage in the warehouse.
	QueryTextDocument_ =
		"SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	CASE
		|		WHEN Goods.ToControlQuality
		|			THEN Goods.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count - Goods.CountByDocument AS Count,
		|	TRUE AS RemainderChanges,
		// When Registering Recorded a warehouse is not an order for acceptance, such a warehouse cannot be an address warehouse, so we do not pass the fields for the address warehouse.
		|	UNDEFINED AS Premise,
		|	UNDEFINED AS Cell,
		|	0 AS NumberOfPackages,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package
		|FROM
		|	DocumentDataTableItems AS Goods
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN (&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND NOT (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date)
		|	AND (Goods.UseWarehouseManagemantSystemForGoodsSurplusesShortages AND Goods.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= Header.Date)
		|	AND Header.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|	AND Header.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|	AND Goods.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
		// The series are either not specified, or are indicated in the tabular part "Goods".
		|	AND Goods.BatchesIndicationStatus IN(0,14)
		|
		|UNION ALL
		|
		// The series are indicated in the Act in a separate tabular part, and in the warehouse of operation it is expected that they are in the table "Goods"
		|SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	SetOfSeries.Warehouse AS Warehouse,
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SetOfSeries.Purpose AS Purpose,
		|	CASE
		|		WHEN Goods.ToControlQuality
		|			THEN Goods.ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	SetOfSeries.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	SetOfSeries.Count - SetOfSeries.CountByDocument AS Count,
		|	TRUE AS RemainderChanges,
		// When Registering Recorded a warehouse is not an order for acceptance, such a warehouse cannot be an address warehouse, so we do not pass the fields for the address warehouse.
		|	UNDEFINED AS Premise,
		|	UNDEFINED AS Cell,
		|	0 AS NumberOfPackages,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package
		|FROM
		|	DocumentDataBatchTable AS SetOfSeries
		|		INNER JOIN DocumentDataTableGoodsToConnectToSeries AS Goods
		|		ON Goods.Ref = SetOfSeries.Ref
		|		AND Goods.Products = SetOfSeries.Products
		|		AND Goods.Characteristic = SetOfSeries.Characteristic
		|		AND Goods.Purpose = SetOfSeries.Purpose
		|		AND Goods.Warehouse = SetOfSeries.Warehouse
		|		AND Goods.DocumentBasis = SetOfSeries.DocumentBasis
		|		AND Goods.FilledUsingBaseDocument = SetOfSeries.FilledUsingBaseDocument
		|		AND Goods.Action = SetOfSeries.Action
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN (&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND NOT (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date)
		|	AND Goods.UseWarehouseManagemantSystemForGoodsSurplusesShortages AND Goods.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= Header.Date
		|	AND Header.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|	AND Header.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|	AND NOT Goods.BatchesIndicationStatus IN(0,14)
		|	AND Goods.Action IN(
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))";
	
	WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	// Odnohodovka. If you selected the "Return without registration" action in the report, then:
	// 1) If the acceptance is order, then you need to issue an order to ship the goods in the warehouse. Next, the goods in the warehouse will be written
	// off with an expense order (or an act if the shipment is not an order).
	// The policy of specifying the series "when planning shipment" is not supported, since there are no series in the act and it will not be possible to issue an order
	// for the shipment of such series.
	// 2) If the acceptance is not an order and the shipment is not an order, then there is no need to Register Records - the goods have not been accepted and are not being shipped.
	// 3) If the acceptance is not order-based and the shipment is order-based, then you need to issue an order to ship the goods in the warehouse. Next, the goods will
	// be shipped by a spending order. At the same time, the act still has to register the surplus so that the expenditure order has something to ship. 
	// The policy of specifying the series "when planning shipment" is supported, but the series in the act lies in a separate tabular part
	// , while the warehouse of operation of shipment planning awaits the series in the tabular part "Goods", therefore we get the series
	// in a special way.
	
	// Planning the shipment of goods "Return without registration".
	QueryTextDocument_ =
		"SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Period,
		|	Header.Ref AS OrderDocument,
		|	Header.Ref AS Invoice,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Header.Partner AS Recipient,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count - Goods.CountByDocument AS Count,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	FALSE AS ShipmentByOrder
		|FROM
		|	DocumentDataTableItems AS Goods
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN(&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND Goods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
		|	AND (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date
		|		OR (Goods.UseWarehouseManagemantSystemForGoodsIssue AND Goods.StartDateOfWarehouseManagemantSystemForGoodsIssue <= Header.Date)
					// In a non-ordinary warehouse for acceptance, there are series in the document "when planning shipment", but they need to be taken from the series table.
		|			AND Goods.BatchesIndicationStatus <> 10)
		|
		|UNION ALL
		|
		|SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Period,
		|	Header.Ref AS OrderDocument,
		|	Header.Ref AS Invoice,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Header.Partner AS Recipient,
		|	SetOfSeries.Warehouse AS Warehouse,
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SetOfSeries.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	SetOfSeries.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	SetOfSeries.Count - SetOfSeries.CountByDocument AS Count,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	FALSE AS ShipmentByOrder
		|FROM
		|	DocumentDataBatchTable AS SetOfSeries
		|		INNER JOIN DocumentDataTableGoodsToConnectToSeries AS Goods
		|		ON Goods.Ref = SetOfSeries.Ref
		|		AND Goods.Products = SetOfSeries.Products
		|		AND Goods.Characteristic = SetOfSeries.Characteristic
		|		AND Goods.Purpose = SetOfSeries.Purpose
		|		AND Goods.Warehouse = SetOfSeries.Warehouse
		|		AND Goods.DocumentBasis = SetOfSeries.DocumentBasis
		|		AND Goods.FilledUsingBaseDocument = SetOfSeries.FilledUsingBaseDocument
		|		AND Goods.Action = SetOfSeries.Action
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN(&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND Goods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
		// At a non-ordinary warehouse of the "when planning shipment" series for acceptance.
		|	AND NOT (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date)
		|	AND (Goods.UseWarehouseManagemantSystemForGoodsIssue AND Goods.StartDateOfWarehouseManagemantSystemForGoodsIssue <= Header.Date)
		|	AND Goods.BatchesIndicationStatus = 10";
	
	WarehousesServer.ScheduleShipmentOfGoods(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	// Odnohodovka. If you selected the "Return without registration" action in the report, then:
	// 1) If order acceptance - an order for shipment was issued earlier, the act must simulate the design of the shipment of goods.
	// If the warehouse is an order warehouse for shipment, such Registered Records will allow Goods to be closed for shipment.
	// Serial indication policies are not supported when planning a shipment, because there are no series in the report.
	// If the warehouse for shipment is not an order warehouse, then such Registered Records will also write off the Balance of Goods in the warehouses.
	// Serial indication policies for Balances in the warehouse and during shipment planning are not supported, since there are no series in the report.
	// 2) If the acceptance is not an order and the shipment is not an order, then there is no need to Register Records - the goods have not been accepted and are not being shipped.
	// 3) If the acceptance is not order-based and the shipment is order-based - an order for shipment was issued earlier, the act should simulate
	// the execution of the shipment of goods, such Registered Recording will allow the Goods to be closed for shipment. Goods in warehouses will be written OFF by a spending order.
	// The policy of specifying the series "when planning shipment" is supported, but the series in the act lies in a separate tabular part
	// , while the warehouse of operation of shipment planning awaits the series in the tabular part "Goods", therefore we get the series
	// in a special way.
	
	QueryTextDocument_ =
		"SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Period,
		|	Header.Ref AS OrderDocument,
		|	Header.Ref AS Invoice,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Header.Partner AS Recipient,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count - Goods.CountByDocument AS Count,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	FALSE AS ShipmentByOrder
		|FROM
		|	DocumentDataTableItems AS Goods
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN(&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND Goods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
		|	AND (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date
		|		OR (Goods.UseWarehouseManagemantSystemForGoodsIssue AND Goods.StartDateOfWarehouseManagemantSystemForGoodsIssue <= Header.Date)
					// In a non-ordinary warehouse for acceptance, there are series in the document "when planning shipment", but they need to be taken from the series table.
		|			AND Goods.BatchesIndicationStatus <> 10)";
	
	SubstitutionOfSeriesFields = New Map();
	SubstitutionOfSeriesFields.Insert("SeriesData_.Count",
		"(SeriesData_.Count - SeriesData_.CountByDocument)");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.SynonymForDocumentTable = "Goods";
	ParametersOfModularHolding.SubstitutionOfSeriesFields = SubstitutionOfSeriesFields;
	ParametersOfModularHolding.MetadataObject = Documents.DiscrepancyReportFollowingReceipt.EmptyRef().Metadata();
	
	WarehousesServer.ArrangeShipmentOfGoodsWithConfigurationOfSeriesConnection(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		ParametersOfModularHolding);
		
	QueryTextDocument_ =
		"SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Period,
		|	Header.Ref AS OrderDocument,
		|	Header.Ref AS Invoice,
		|	FALSE AS Patch,
		|	UNDEFINED AS CorrectedDocument,
		|	Header.Partner AS Recipient,
		|	SetOfSeries.Warehouse AS Warehouse,
		|	SetOfSeries.Products AS Products,
		|	SetOfSeries.Characteristic AS Characteristic,
		|	SetOfSeries.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	SetOfSeries.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	SetOfSeries.Count - SetOfSeries.CountByDocument AS Count,
		|	FALSE AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	FALSE AS ShipmentByOrder
		|FROM
		|	DocumentDataBatchTable AS SetOfSeries
		|		INNER JOIN DocumentDataTableGoodsToConnectToSeries AS Goods
		|		ON Goods.Ref = SetOfSeries.Ref
		|		AND Goods.Products = SetOfSeries.Products
		|		AND Goods.Characteristic = SetOfSeries.Characteristic
		|		AND Goods.Purpose = SetOfSeries.Purpose
		|		AND Goods.Warehouse = SetOfSeries.Warehouse
		|		AND Goods.DocumentBasis = SetOfSeries.DocumentBasis
		|		AND Goods.FilledUsingBaseDocument = SetOfSeries.FilledUsingBaseDocument
		|		AND Goods.Action = SetOfSeries.Action
		|		INNER JOIN DocumentDataHeader AS Header
		|		ON Header.Ref = Goods.Ref
		|WHERE
		|	Header.Ref IN(&Ref)
		|	AND Header.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND NOT Header.SeparatePurchasingOfGoods AND Goods.ThisIsAProduct
		|	AND Goods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
		|	AND NOT (Goods.UseWarehouseManagemantSystemForGoodsReceipt AND Goods.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Header.Date)
		|	AND (Goods.UseWarehouseManagemantSystemForGoodsIssue AND Goods.StartDateOfWarehouseManagemantSystemForGoodsIssue <= Header.Date)
		// At a non-ordinary warehouse of the "when planning shipment" series for acceptance.
		|	AND Goods.BatchesIndicationStatus = 10";
	
	WarehousesServer.ArrangeShipmentOfGoods(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
	
EndProcedure

Function QueryTextTTSetOfSeries(Query, QueryTexts)
	
	RegisterName = "TTSeries";
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Warehouse AS Warehouse,
	|	SeriesTable.Action AS Action,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	&WarehouseOperation AS WarehouseOperation,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnReceiving,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS OrderSchemeWhenReflectingSurplusShortages,
	|	CASE
	|		WHEN NOT CatWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				OR CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord,
	|	SeriesTable.Count - SeriesTable.CountByDocument AS Discrepancies
	|INTO TTSeries
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS SeriesTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouse
	|		ON (CatWarehouse.Ref = SeriesTable.Warehouse)
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> SeriesTable.CountByDocument
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices)
	|	AND &Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Action,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	&WarehouseOperation,
	|	CASE
	|		WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Period
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
	|		WHEN NOT CatWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				OR CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > &Period
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	GoodsTable.Count - GoodsTable.CountByDocument
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouse
	|		ON (CatWarehouse.Ref = GoodsTable.Warehouse)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.CountByDocument <> GoodsTable.Count
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND NOT GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND NOT GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices)
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
		QueryTextTTSetOfSeries(Query, QueryTexts)
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	UNDEFINED                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	
	|	GoodsTable.AdvancedWarehousingOnReceiving
	|	AND NOT GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	AND GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)       
	|
	|UNION ALL
	|
	// Reduction of warehouse balances with an irregular acceptance scheme
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	UNDEFINED                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	//3K
	|	   NOT GoodsTable.AdvancedWarehousingOnReceiving 
	|	   AND GoodsTable.OrderSchemeWhenReflectingSurplusShortages 
	|	   AND &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|	   AND NOT &WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReceiptFromVendor)
	|	   AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_)
	|				OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|
	|UNION ALL
	// Compensation of the warehouse receipt adjustment under the order acceptance scheme
	// Optimistically considering that the shortage is already reflected in the receipt order.
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	UNDEFINED                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	//3K
	|	   GoodsTable.AdvancedWarehousingOnReceiving 
	|	   AND NOT GoodsTable.OrderSchemeWhenReflectingSurplusShortages 
	|	   AND &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|	   AND NOT &WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReceiptFromVendor)
	|	   AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_)
	|				OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
	|
	|UNION ALL
	/////////////////////////////////////////
	// Excess at acceptance (Discrepancies > 0).
	//
	// Compensation of the warehouse receipt adjustment under the order acceptance scheme
	// Optimistically, we believe that the receipt order has already reflected the fact of the surplus.
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	&Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	
	|	AND GoodsTable.AdvancedWarehousingOnReceiving 
	|	AND NOT GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	//8O
	|	AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome)
	|		
	//6K
	|		OR ((&DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|			AND NOT &WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReceiptFromVendor))
	|	   		  AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered)
	|				  OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered))))
	|	
	|
	|UNION ALL
	// Increase in warehouse balances with an irregular acceptance scheme
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	//6K
	|	   NOT GoodsTable.AdvancedWarehousingOnReceiving 
	|	   AND GoodsTable.OrderSchemeWhenReflectingSurplusShortages 
	|	   AND &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|	   AND NOT &WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReceiptFromVendor)
	|	   AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered)
	|				OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered))
	|
	|UNION ALL
	/////////////////////////////////////////
	// Shortage at acceptance (Discrepancies < 0).
	//
	// Compesation of the write-off of the shortage, optimistically considering that the shortage is already reflected in the receipt order.
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	UNDEFINED                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	GoodsTable.AdvancedWarehousingOnReceiving
	|	AND GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	AND (
	//3K
	|		(&DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|			AND NOT &WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReceiptFromVendor)
	|			AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_)
	|				OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)))
	//7From1
	|		OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
	|	)
	|
	|UNION ALL
	|
	/////////////////////////////////////////
	// Excess at acceptance (Discrepancies > 0).
	//
	// Compensation for the recording of the surplus, optimistically considering that the surplus has already been reflected in the incoming order.
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation AS WarehouseOperation,
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	GoodsTable.AdvancedWarehousingOnReceiving
	|	AND GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	AND (
	//6K	
	|		(&DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
	|			AND NOT &WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReceiptFromVendor)
	|			AND (GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered)
	|				OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)))
	//8O
	|		OR GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome)
	|	)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function WarehouseOperationByBaseType(TypeOfBaseDocumentForNonConformanceCertificate)
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		WarehouseOperation = Enums.WarehouseTransactions.ReceiptFromVendor;
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent
		Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		WarehouseOperation = Enums.WarehouseTransactions.ReceivingByReturnFromACustomer;
		
	Else
		WarehouseOperation = Undefined;
	EndIf;
	
	Return WarehouseOperation;
	
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                    AS LineOfBusiness,
	|	CASE
	|		WHEN DocumentData.NumberOfStorageLocations = 1
	|			THEN DocumentData.StorageLocation
	|		ELSE UNDEFINED
	|	END                    AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	0                        AS Sum,
	|	&Status                  AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Author                   AS Author,
	|	FALSE                     AS ReverseTransactionCorrection,
	|	UNDEFINED             AS ReversedDocument,
	|	UNDEFINED             AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
		
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref                                                             AS Ref,
	|	MAX(
	|		ISNULL(GoodsTable.DocumentBasis.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	MAX(GoodsTable.Warehouse)                                       AS StorageLocation,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.DocumentBasis.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities,
	|	COUNT(DISTINCT GoodsTable.Warehouse)                           AS NumberOfStorageLocations
	|INTO TTBases
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DocumentData
	|		LEFT JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.DiscrepancyReportFollowingReceipt";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
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
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation,
		TemporaryTableQueryTexts);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Parish for old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ToControlQuality
		|			THEN TabPart.ControlledLotReference
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|		AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|		AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
		|		AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		// Parish for old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	TabPart.RowCode <> 0 AS OnSchedule,
		|	
		|	CASE
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|		AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|		AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered))
		|		AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|		AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|		AND TabPart.Action IN(
		|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices),
		|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|			VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered))
		|		AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		// On the other hand, the document "Adjustment of the purchase of goods", since the receipt order has already reflected the surplus/ shortage in the warehouse.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ToControlQuality
		|			THEN TabPart.ControlledLotReference
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND NOT TabPart.Ref.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		AND (TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome)
		|				OR (TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|					AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice))
		|					AND TabPart.Action IN(
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)))
		|		AND (NOT TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|			OR TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		// On the other hand, the document "Adjustment of the purchase of goods", since the receipt order has already reflected the surplus/ shortage in the warehouse.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND NOT TabPart.Ref.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		AND (TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
		|				OR (TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|					AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice))
		|					AND TabPart.Action IN(
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)))
		|		AND (NOT TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|			OR TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// With the method of reflection by making adjustments, the order reflection of surpluses /shortages is blocked by the act, the act reflects the surplus/shortage independently.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	CASE
		|		WHEN TabPart.ToControlQuality
		|			THEN TabPart.ControlledLotReference
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND NOT(TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|			AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date)
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|			AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date
		|		AND NOT TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|			AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|			AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		// With the method of reflection by making adjustments, the order reflection of surpluses /shortages is blocked by the act, the act reflects the surplus/shortage independently.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND NOT(TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|			AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date)
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|			AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date
		|		AND NOT TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|			AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|			AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered))";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// With the method of reflection by making adjustments, the act corrects the receipt schedule.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	CASE
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|					VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		WHEN TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|					OR TabPart.PurchaseOrder IN(
		|							UNDEFINED,
		|							VALUE(Document.PurchaseOrder.EmptyRef),
		|							VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
		|			THEN TabPart.DocumentBasis
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|		AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|		AND TabPart.Action IN(
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|				VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices))
		|		AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND TabPart.RowCode <> 0
		|
		|UNION ALL
		|
		// With the method of reflection by making adjustments, the act corrects the receipt schedule.
		|SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	-(TabPart.Count - TabPart.CountByDocument) AS Count,
		|	CASE
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|					VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		WHEN TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|					OR TabPart.PurchaseOrder IN(
		|							UNDEFINED,
		|							VALUE(Document.PurchaseOrder.EmptyRef),
		|							VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
		|			THEN TabPart.DocumentBasis
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND (TabPart.Action IN(
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses),
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration))
		|				OR (TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|					AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice))
		|					AND TabPart.Action IN(
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterOverdelivered),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)))
		|		AND (TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|					AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|				AND NOT TabPart.Ref.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)))
		|
		|UNION ALL
		|
		|SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	CASE
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN TabPart.Ref.GoodsReceiptOption IN(
		|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status IN(
		|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|	AND TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries)
		|	AND TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
		|	AND TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
		|	AND VALUETYPE(TabPart.PurchaseOrder) = TYPE(Document.PurchaseOrder)
		|	AND TabPart.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|	AND TabPart.RowCode <> 0
		|	AND(
		|		TabPart.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			AND TabPart.Ref.BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			AND TabPart.Ref.BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|			AND ISNULL(TabPart.Ref.Contract.PurchaseRegistrationOption = VALUE(Enum.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices),
		|				FALSE))";
	
	StockAllocationRecords.CancelScheduledStockArrival(Query, QueryTexts, Registers, QueryTextTabPart);
	
	QueryTextTabPart =
		// Shipment of over-delivered goods without control.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count - TabPart.CountByDocument AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
EndProcedure

#EndRegion

#Region FillType

// Refills the document, including the actual quantity, by warehouse.
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingReceipt - Act,
//  Warehouse - CatalogRef.Warehouses - warehouse,
//  FactReceiptManager - AccumulationRegisterManager,DocumentManager - the fact-getting module.
//  ActOfFoundation - DocumentRef.GoodsQualityControlCertificate - Act
// Returns:
// Structure - structure with fields:
//  * ResultingTable - See Document.DiscrepancyReportFollowingReceipt.Goods
//  * ResultingSeriesTable - See Document.DiscrepancyReportFollowingReceipt.SetOfSeries
Function FillActual(Object, Warehouse, FactReceiptManager, ActOfFoundation) Export
	
	SeparatorText = InvoicesServer.QuerySeparatorText();
	
	FillParameters = DocumentFillingParameters();
	
	SetPrivilegedMode(True);
	AdvancedWarehousingOnReceiving = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Warehouse, Object.Date);
	SetPrivilegedMode(False);
	
	FactOfAcceptance = New Structure("ResultingTable, ResultingSeriesTable");
	
	If FactReceiptManager = AccumulationRegisters.GoodsToReceive And Not AdvancedWarehousingOnReceiving Then
		
		RowFilter = New Structure("Warehouse", Warehouse);
		FactOfAcceptance.ResultingTable = Object.Goods.Unload(RowFilter);
		FactOfAcceptance.ResultingSeriesTable = Object.SetOfSeries.Unload(RowFilter);
		
		Return FactOfAcceptance;
		
	EndIf;
	
	RowFilter = New Structure("Warehouse", Warehouse);
	InvoiceTable = Object.Goods.Unload(RowFilter);
	InvoiceTable.Columns.Add("QuantityMaximum", New TypeDescription("Number"));
	InvoiceTable.Columns.Add("QuantityInOrder", New TypeDescription("Number"));
	InvoiceTable.Columns.Add("NoteQuantity", New TypeDescription("Number"));
	InvoiceTable.Columns.Add("ReferenceOrder");
	
	ContractAcceptanceOptions = New Array();
	ContractAcceptanceOptions.Add(Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices);
	ContractAcceptanceOptions.Add(Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices);
	ContractAcceptanceOptions.Add(Enums.GoodsReceiptOptions.ByContractsAfterInvoices);
	
	AnArrayOfOrders = New Array();
	
	For Each LineProducts_ In InvoiceTable Do
		LineProducts_.QuantityMaximum = Max(LineProducts_.Count, LineProducts_.CountByDocument);
		If ValueIsFilled(LineProducts_.PurchaseOrder) Then
			LineProducts_.ReferenceOrder = LineProducts_.PurchaseOrder;
		Else
			LineProducts_.ReferenceOrder = LineProducts_.DocumentBasis;
		EndIf;
		
		DetailsOfOrder = Common.ObjectAttributesValues(LineProducts_.ReferenceOrder, "GoodsReceiptOption, Contract");
		If ContractAcceptanceOptions.Find(DetailsOfOrder.GoodsReceiptOption) <> Undefined Then
			AnArrayOfOrders.Add(DetailsOfOrder.Contract);
			LineProducts_.ReferenceOrder = DetailsOfOrder.Contract;
		EndIf;
		
	EndDo;
	
	CommonClientServer.SupplementArray(AnArrayOfOrders, InvoiceTable.UnloadColumn("ReferenceOrder"));
	AnArrayOfOrders = CommonClientServer.CollapseArray(AnArrayOfOrders);
	
	ReferencesForOrders = Common.CopyRecursive(AnArrayOfOrders);
	CommonClientServer.SupplementArray(ReferencesForOrders, InvoiceTable.UnloadColumn("DocumentBasis"));
	
	ExcludedInvoices = InvoiceTable.UnloadColumn("DocumentBasis");
	ExcludedInvoices = CommonClientServer.CollapseArray(ExcludedInvoices);
	
	// Orders
	
	Filter = New Map();
	Filter.Insert("Ref", "References");
	Filter.Insert("Table.Warehouse", "Warehouse");
	Filter.Insert("Table.Products.ItemsType", "ItemsTypes");
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		QueryTextOrderDocument = Documents.PurchaseOrder.QueryTextDocumentGoods(Filter);
		
		Filter = New Structure();
		Filter.Insert("PurchaseOrder", "References");
		Filter.Insert("Warehouse", "Warehouse");
		
		RequestTextForOrders = AccumulationRegisters.PurchaseOrders.QueryTextBalance(
			"TTAccountingData",
			Filter,
			"ToRegister <> 0");
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate =
						Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		
		QueryTextOrderDocument = Documents.MaterialProviderOrder2_5.QueryTextDocumentGoods(Filter, "");
		
		Filter = New Structure("PurchaseOrder", "References");
		Filter.Insert("Warehouse", "Warehouse");
		RequestTextForOrders =
			AccumulationRegisters.PurchaseOrders.QueryTextBalance("TTAccountingData", Filter, "ToRegister <> 0");
	Else
		
		QueryTextOrderDocument = Documents.RequestForReturnOfGoodsFromCustomer.QueryTextDocumentGoods(Filter);
		
		Filter = New Structure();
		Filter.Insert("ReferenceOrder", "References");
		
		RequestTextForOrders = AccumulationRegisters.ShipmentAndReturnReferences.QueryTextBalancesOnReturns(
			"TTAccountingData",
			Filter,
			"ToRegister <> 0");
			
	EndIf;
	
	QueryText = RequestTextForOrders
					+ SeparatorText
					+ QueryTextOrderDocument;
					
	ItemsTypes = New Array();
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
		
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("References", AnArrayOfOrders);
	Query.SetParameter("Recorder",  ExcludedInvoices);
	Query.SetParameter("ItemsTypes", ItemsTypes); 
	Query.SetParameter("Warehouse", Warehouse);
	
	OrdersTable = Query.Execute().Unload();
	OrderColumn           = OrdersTable.Columns.Find("PurchaseOrder"); // ValueTableColumn
	ColumnToDesign     = OrdersTable.Columns.ToRegister; // ValueTableColumn
	ColumnToDesign.Name     = "QuantityInOrder";
	
	Query = New Query();
	
	If FactReceiptManager = AccumulationRegisters.GoodsToReceive Then
		RegisterData = AccumulationRegisters.GoodsToReceive.Accepted(ReferencesForOrders, Warehouse);
	ElsIf FactReceiptManager = Documents.GoodsQualityControlCertificate Then
		RegisterData = Documents.GoodsQualityControlCertificate.Accepted(ActOfFoundation, Warehouse);
	EndIf;

	TableOrders = Object.Goods.Unload(New Array()).CopyColumns();
	
	TypesOfOrders = New TypeDescription("DocumentRef.PurchaseOrder, DocumentRef.RequestForReturnOfGoodsFromCustomer, 
		|DocumentRef.MaterialProviderOrder2_5,
		|DocumentRef.ReturnOfGoodsFromCustomer, DocumentRef.VendorInvoice, 
		|DocumentRef.GoodsReceiptForStorage, CatalogRef.CounterpartyContracts, CatalogRef.TermsOfPurchaseFromVendors,
		|DocumentRef.ReceiptOfGoodsFromCustodian");
	
	TableOrders.Columns.Add("ReferenceOrder", TypesOfOrders);
	
	CommonClientServer.SupplementTable(RegisterData, TableOrders);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.DiscrepancyReportFollowingReceipt);
	TableOrders = AddJoinMethodToTable(TableOrders, SeriesSpecificationParameters);
	ColumnQuantity = TableOrders.Columns.Count; //ValueTableColumn 
	
	ColumnQuantity.Name = "NoteQuantity";
	
	// Distribution of the resulting tables
	If OrderColumn <> Undefined Then
		OrderColumn.Name = "ReferenceOrder";
	EndIf;
	
	InvoiceTable.Indexes.Add(FillParameters.KeyFields);
	
	// Adding the number of orders
	Var_Key = "ReferenceOrder, Warehouse, RowCode";
	
	Condition = "On [QuantityMaximum]";
	InvoicesServer.AllocateQuantity(OrdersTable, InvoiceTable, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, InvoiceTable, "QuantityInOrder");
	
	InvoiceTable = AddJoinMethodToTable(InvoiceTable, SeriesSpecificationParameters);
	
	// Adding the number of orders.
	
	OriginalInvoiceTable = InvoiceTable.Copy();
	// The division of the tables of the table of the invoice and the table of the received certificates into several according to the "Method of connection" field.
	InvoiceTables = SupplyServer.SplitTableByKeyValue(InvoiceTable, "ConnectionMethod_");
	TablesOfResults = SupplyServer.SplitTableByKeyValue(TableOrders, "ConnectionMethod_");
	
	// Formation of the structure of actions with separated tables
	ActionsWithResultingTables = New Structure();
	
	For Each KeyValue In InvoiceTables Do
		
		Var_Key = KeyValue.Key.ConnectionMethod_;
		StructureOfActions = New Structure("InvoiceTable, TableReceivedRemainder", KeyValue.Table, TableOrders.CopyColumns());
		ActionsWithResultingTables.Insert(Var_Key, StructureOfActions);
		
	EndDo;
	
	For Each KeyValue In TablesOfResults Do
		
		Var_Key = KeyValue.Key.ConnectionMethod_;
		
		If ActionsWithResultingTables.Property(Var_Key) Then
			StructureOfActions = ActionsWithResultingTables[Var_Key];
			StructureOfActions.TableReceivedRemainder = KeyValue.Table;
		Else
			StructureOfActions = New Structure("InvoiceTable, TableReceivedRemainder", InvoiceTable.CopyColumns(), KeyValue.Table);
			ActionsWithResultingTables.Insert(Var_Key, StructureOfActions);
		EndIf;
		
	EndDo;
	
	DataForFillingInTabularPartOfBatches = Undefined;
	If Not AdvancedWarehousingOnReceiving And ActionsWithResultingTables.Property("A3") Then
		DataForFillingInTabularPartOfBatches = ActionsWithResultingTables.A3.TableReceivedRemainder.Copy(); // ValueTable
	EndIf;
	If DataForFillingInTabularPartOfBatches = Undefined And Not AdvancedWarehousingOnReceiving And ActionsWithResultingTables.Property("A2") Then
		DataForFillingInTabularPartOfBatches = ActionsWithResultingTables.A2.TableReceivedRemainder.CopyColumns(); // ValueTable
	EndIf;
	
	ResultingTable      = InvoiceTable.CopyColumns();
	ResultingSeriesTable = InvoiceTable.CopyColumns();
	
	UninvoicedReceiptDocumentIsUsed = PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(Object.BusinessOperation);
	
	DocumentQuantityMayBeExceeded = False;
	ItIsPossibleToUniquelyIdentifyOrder = 
		Not PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Object.GoodsReceiptOption)
			And Not UninvoicedReceiptDocumentIsUsed
			And Not FactReceiptManager = Documents.GoodsQualityControlCertificate;
	
	For Each KeyValue In ActionsWithResultingTables Do
		
		Action = KeyValue.Key;
		StructureOfActions = KeyValue.Value;
		
		ActionInvoiceTable = StructureOfActions.InvoiceTable;
		OrderTableByAction    = StructureOfActions.TableReceivedRemainder;
		// Temporary restriction. The Certificate of Quality Control does not specify reference series. It is impossible to fill in the fact correctly.
		If FactReceiptManager = Documents.GoodsQualityControlCertificate And Action = "A2" Then
			OrderTableByAction.Clear();
		EndIf;
		
		If Not ItIsPossibleToUniquelyIdentifyOrder Then
			Var_Key = "Warehouse, Products, Characteristic, Series, Purpose";
		Else
			Var_Key = "ReferenceOrder, Warehouse, Products, Characteristic, Series, Purpose";
		EndIf;
		
		If Action = "A0" Or Action = "A3" Or Action = "A2" Then
			Var_Key = StrReplace(Var_Key, ", Series", "")
		EndIf;
		
		Passages = ?(Action = "A1", 2, 1);
		For Passage = 1 To Passages Do
			
			If Passage = 1 Then
				// There are invoices and orders
				Condition = "[QuantityMaximum], [QuantityInOrder], On [QuantityInOrder]";
				InvoicesServer.AllocateQuantity(OrderTableByAction, ActionInvoiceTable, "NoteQuantity", Var_Key, Condition, False);
				
				// There are orders, no invoices
				Condition = "NOT [QuantityMaximum], [QuantityInOrder], On [QuantityInOrder]";
				InvoicesServer.AllocateQuantity(OrderTableByAction, ActionInvoiceTable, "NoteQuantity", Var_Key, Condition, False);
				
				// There are invoices, no orders
				Condition = "[QuantityMaximum], NOT [QuantityInOrder], On [QuantityMaximum]";
				InvoicesServer.AllocateQuantity(OrderTableByAction, ActionInvoiceTable, "NoteQuantity", Var_Key, Condition, True);
			Else
				// The case is being worked out when there are lines with an empty series in the act, but a series with the status 14 is expected.
				
				Var_Key = StrReplace(Var_Key, ", Series", "");
				
				TheStructureOfTheSearch = New Structure("Series", Catalogs.ItemsBatches.EmptyRef());
				FoundRows = ActionInvoiceTable.FindRows(TheStructureOfTheSearch);
				InvoiceTableForActionEmptyBatches = ActionInvoiceTable.Copy(FoundRows);
				
				For Each RowToDelete In FoundRows Do
					ActionInvoiceTable.Delete(RowToDelete);
				EndDo;
				
				// There are invoices and orders
				Condition = "[QuantityMaximum], [QuantityInOrder], On [QuantityInOrder]";
				InvoicesServer.DistributeQuantityAndFill(OrderTableByAction, InvoiceTableForActionEmptyBatches, "NoteQuantity", Var_Key, Condition, False, "Series");
				
				// There are orders, no invoices
				Condition = "NOT [QuantityMaximum], [QuantityInOrder], On [QuantityInOrder]";
				InvoicesServer.DistributeQuantityAndFill(OrderTableByAction, InvoiceTableForActionEmptyBatches, "NoteQuantity", Var_Key, Condition, False, "Series");
				
				// There are invoices, no orders
				Condition = "[QuantityMaximum], NOT [QuantityInOrder], On [QuantityMaximum]";
				InvoicesServer.DistributeQuantityAndFill(OrderTableByAction, InvoiceTableForActionEmptyBatches, "NoteQuantity", Var_Key, Condition, True, "Series");
				
				CommonClientServer.SupplementTable(InvoiceTableForActionEmptyBatches, ActionInvoiceTable);
				
				// The case when batch A was expected, but batches A and B. In this case, a separate line will be created for Batch B
				// with the amount of the document equal to the same field in line c of batch A.
				// I.e. duplication occurs in this field, which is processed below.
				DocumentQuantityMayBeExceeded = True;
				
			EndIf;
			
		EndDo;
		
		// Adding an undistributed number of orders in separate lines
		InvoicesServer.SupplementTable(OrderTableByAction, ActionInvoiceTable, "NoteQuantity");
		
		// Assignment of new lines to orders and base documents
		AcceptableTypesOfFoundationDocument = New Array();
		AcceptableTypesOfFoundationDocument.Add(Type("DocumentRef.ReturnOfGoodsFromCustomer"));
		AcceptableTypesOfFoundationDocument.Add(Type("DocumentRef.VendorInvoice"));
		AcceptableTypesOfFoundationDocument.Add(Type("DocumentRef.ReceiptOfGoodsFromCustodian"));
		AcceptableTypesOfFoundationDocument.Add(Type("DocumentRef.GoodsReceiptForStorage"));
		
		FilterParameters = New Structure("PurchaseOrder", Documents.PurchaseOrder.EmptyRef());
		RowsWithEmptyOrder = ActionInvoiceTable.FindRows(FilterParameters);
		FilterParameters.PurchaseOrder = Undefined;
		CommonClientServer.SupplementArray(RowsWithEmptyOrder, ActionInvoiceTable.FindRows(FilterParameters));
		For Each String In RowsWithEmptyOrder Do
			If TypeOf(String.ReferenceOrder) = Type("DocumentRef.PurchaseOrder") Then
				String.PurchaseOrder = String.ReferenceOrder;
				FilterParameters.PurchaseOrder = String.ReferenceOrder;
				LinesWithBaseDocument = Object.Goods.FindRows(FilterParameters);
				
				FoundDocumentBase = LinesWithBaseDocument[0].DocumentBasis;
				If LinesWithBaseDocument.Count() > 0
					And AcceptableTypesOfFoundationDocument.Find(TypeOf(FoundDocumentBase)) <> Undefined Then
					String.DocumentBasis = FoundDocumentBase;
				EndIf;
			ElsIf AcceptableTypesOfFoundationDocument.Find(TypeOf(String.ReferenceOrder)) <> Undefined Then
				String.DocumentBasis = String.ReferenceOrder;
			EndIf;
		EndDo;
		
		CommonClientServer.SupplementTable(ActionInvoiceTable, ResultingTable);
		
	EndDo;
	
	ColumnQuantity        = ResultingTable.Columns.Count; // ValueTableColumn
	ColumnQuantityInOrder_ = ResultingTable.Columns.NoteQuantity; // ValueTableColumn
	
	ColumnQuantity.Name             = "QuantityBeforeChange_";
	ColumnQuantityInOrder_.Name      = "Count";
	
	ColumnQuantity        = ResultingSeriesTable.Columns.Count; // ValueTableColumn
	ColumnQuantityInOrder_ = ResultingSeriesTable.Columns.NoteQuantity; // ValueTableColumn
	
	ColumnQuantity.Name        = "QuantityBeforeChange_";
	ColumnQuantityInOrder_.Name = "Count";
	
	// Deleting empty lines
	LinesNotByDocument = ResultingTable.FindRows(New Structure("CountByDocument", 0));
	For Each String In LinesNotByDocument Do
		If String.Count = 0 Then
			ResultingTable.Delete(String);
		EndIf;
	EndDo;
	
	If DocumentQuantityMayBeExceeded Then
		// Updating the Quantity field to a document - in some cases it may be duplicated.
		If Not ItIsPossibleToUniquelyIdentifyOrder Then
			Var_Key = "Warehouse, Products, Characteristic, Series, Purpose";
		Else
			Var_Key = "ReferenceOrder, Warehouse, Products, Characteristic, Series, Purpose";
		EndIf;
		
		Condition = "[CountByDocument], On [CountByDocument]";
		OriginalInvoiceTable.Columns.CountByDocument.Name = "DocumentQuantityNew";
		ResultingTable.FillValues(False, "FilledUsingBaseDocument");
		
		InvoicesServer.DistributeQuantityAndFill(OriginalInvoiceTable, ResultingTable, "DocumentQuantityNew", Var_Key, Condition, False, "FilledUsingBaseDocument");
		
		Var_Key = StrReplace(Var_Key, ", Series", "");
		InvoicesServer.DistributeQuantityAndFill(OriginalInvoiceTable, ResultingTable, "DocumentQuantityNew", Var_Key, Condition, False, "FilledUsingBaseDocument");
		
		ResultingTable.Columns.CountByDocument.Name = "QuantityAccordingToDocumentIsOld";
		ResultingTable.Columns.DocumentQuantityNew.Name = "CountByDocument";
	EndIf;
	
	ResultingTable.Sort("LineNumber");
	FactOfAcceptance.ResultingTable = ResultingTable;
	
	If DataForFillingInTabularPartOfBatches <> Undefined Then
		
		SourceTable1 = ResultingTable.Copy();
		Condition = "On [NoteQuantity]";
		Var_Key = "Products,Characteristic,Purpose,Warehouse";
		InvoicesServer.DistributeQuantityAndFill(
			SourceTable1,
			DataForFillingInTabularPartOfBatches,
			"CountByDocument",
			Var_Key,
			Condition,
			True,
			"FilledUsingBaseDocument,DocumentBasis");
			
		// Addition of the series table with series rows that were indicated in the base, when filled in on the basis, but did not arrive in fact.
		RowFilter = New Structure("Warehouse,FilledUsingBaseDocument", Warehouse, True);
		BaseLines = Object.SetOfSeries.Unload(RowFilter);
		BaseLines.Columns.Add("Add", New TypeDescription("Boolean"));
		
		RowFilter = New Structure(Var_Key);
		DataForFillingInTabularPartOfBatches.Indexes.Add(Var_Key);
		For Each TableRow In BaseLines Do
			FillPropertyValues(RowFilter, TableRow);
			If DataForFillingInTabularPartOfBatches.FindRows(RowFilter).Count() = 0 Then
				TableRow.Add = True;
			EndIf;
		EndDo;
		BaseLines = BaseLines.Copy(New Structure("Add", True));
		TMCommonUse.AddRowsToTable(DataForFillingInTabularPartOfBatches, BaseLines);
		
		DataForFillingInTabularPartOfBatches.Columns.NoteQuantity.Name = "Count";
		
	Else
		DataForFillingInTabularPartOfBatches = ResultingTable.Copy(New Array());
	EndIf;
	FactOfAcceptance.ResultingSeriesTable = DataForFillingInTabularPartOfBatches;
	
	Return FactOfAcceptance;
	
EndFunction

Function AddJoinMethodToTable(Table, SeriesSpecificationParameters)
	
	Table.Columns.Add("ConnectionMethod_", New TypeDescription("String"));
	
	LineNumber = 1;
	For Each String In Table Do
		String["LineNumber"] = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	// Getting series indication statuses
	ObjectToFillInSeries = New Structure();
	ObjectToFillInSeries.Insert("Goods", Table);
	ObjectToFillInSeries.Insert("SetOfSeries", Table.CopyColumns());
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ObjectToFillInSeries, SeriesSpecificationParameters);
	
	// Calculation of the connection method/
	QueryText = 
	"SELECT
	|	Table.LineNumber,
	|	CASE
	|		WHEN Table.BatchesIndicationStatusRecipient IN (0)
	|			THEN ""A0""
	|		WHEN Table.BatchesIndicationStatusRecipient IN (13, 14)
	|			THEN ""A1""
	|		WHEN Table.BatchesIndicationStatusRecipient IN (1, 2)
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

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("DocumentName",     "DiscrepancyReportFollowingReceipt");
	FillParameters.Insert("RegisterNameOrder", "PurchaseOrders");
	FillParameters.Insert("FieldNameOrder",     "PurchaseOrder");
	
	FillParameters.Insert("KeyFields",     "ReferenceOrder, Products, Characteristic, Series, Warehouse, Purpose");
	
	Return FillParameters;
	
EndFunction

Procedure UpdateDependentDetailsAfterFillingInFactOfAcceptance(Object) Export
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		RowsToProcess = New Array();
		
		For Each LineProducts_ In Object.Goods Do
			If Not ValueIsFilled(LineProducts_.VATRate) Then
				RowsToProcess.Add(LineProducts_);
			EndIf;
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			CachedValues);
		
	EndIf;
	
	Suffix = "ByDocument";
	
	StructureOfActions = New Structure;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate =
						PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider")
		Or Object.TypeOfBaseDocumentForNonConformanceCertificate = PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage") Then
		
		StructureOfActions.Insert("FillInProductNameOfProductPartner", Object.Partner);
		
	EndIf;
	
	StructureOfActions.Insert(
		"RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", Suffix);
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateSuffixAmount", Suffix);
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
		StructureOfRecalculationOfAmount.Insert("Suffix", Suffix);
		
		StructureOfActions.Insert("RecalculateVATAmount",         StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT",        StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmountSuffix",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateSumWithVATSuffix", StructureOfRecalculationOfAmount);
		
	EndIf;
	
	If TypeOf(Object) = Type("FormDataStructure") Then
		StructureOfActions.Insert("FlagForAcceptanceComment");
		StructureOfActions.Insert("RecalculateDiscrepanciesAfterAcceptance");
	EndIf;
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods,StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#Region Print

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
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"DiscrepanciesPostingMethod",
														Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries,
														DataCompositionComparisonType.Equal);

	DiscrepancyReportFollowingReceiptLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	DiscrepancyReportFollowingReceiptLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// Fills in data for recipients of printed forms
// 
// Parameters:
//  PrintObjectDataStructure - See PrintFormGeneration.NewPrintObjectDataStructure
//
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
EndProcedure

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region StatusChange

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
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
	|	Document.DiscrepancyReportFollowingReceipt AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.StatusesOfDiscrepancyReport - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.DiscrepancyReportFollowingReceipt.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.42";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("fa677e44-2598-49a2-824b-75b3fe7952c0");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.DiscrepancyReportFollowingReceipt.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Biên bản chênh lệch sau khi nhận"":';
								|ru = 'Обновление документов ""Акт о расхождениях после приемки"":';
								|en = 'Update the ""Receipt discrepancy report"" documents:'; fa = 'Update the ""Receipt discrepancy report"" documents:';
								|it = 'Update the ""Receipt discrepancy report"" documents:';
								|pl = 'Update the ""Receipt discrepancy report"" documents:';
								|tr = '""Stok farkları raporu"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền ""Trạng thái chỉ ra sê-ri cho kho nhận"".';
								|ru = '- заполняет ""Статус указания серии для склада приёма"".';
								|en = '- Fills in ""Batch specification status for receiving warehouse"".'; fa = '- Fills in ""Batch specification status for receiving warehouse"".';
								|it = '- Fills in ""Batch specification status for receiving warehouse"".';
								|pl = '- Fills in ""Batch specification status for receiving warehouse"".';
								|tr = '- ""Kabul ambarı için parti gösterge durumu""nu doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.DiscrepancyReportFollowingReceipt";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ProductsToRequest.Ref AS Ref
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS ProductsToRequest
	|		INNER JOIN Catalog.Products AS ItemListOfReport
	|			ON ProductsToRequest.Products = ItemListOfReport.Ref
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON ProductsToRequest.Warehouse = Warehouses.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			ON BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse
	|				AND ItemListOfReport.ProductKind = BatchAccountingPolicies.Ref
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentData
	|			ON ProductsToRequest.Ref = DocumentData.Ref
	|WHERE
	|	ProductsToRequest.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND ProductsToRequest.BatchesIndicationStatus <> ProductsToRequest.BatchesIndicationStatusRecipient
	|	AND (DocumentData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|												VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|												VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|												VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|												VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
	|			OR NOT BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			OR NOT(BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					AND Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|					AND DocumentData.Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|					AND ProductsToRequest.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)))";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.DiscrepancyReportFollowingReceipt";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref        AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN Document.DiscrepancyReportFollowingReceipt AS DocumentAttributes
	|	ON UpdatedData.Ref = DocumentAttributes.Ref
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				For Each String In DocumentObject.Goods Do
					String.BatchesIndicationStatusRecipient = String.BatchesIndicationStatus;
				EndDo;
				ObjectModified = True;
			EndIf;
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
