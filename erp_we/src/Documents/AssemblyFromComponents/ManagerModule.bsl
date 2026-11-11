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
	
	DocumentMechanisms.Add("InternalInventoryTransfers");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	AssemblyFromComponentsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.AssemblyFromComponents") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	ElsIf TypeOf(Document) = Type("DocumentRef.AssemblyFromComponents") Then
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	Else
		DocumentObject = Undefined;
		DocumentRef = Undefined;
	EndIf;
	
	Query = New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableAssemblyOrders(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AssemblyFromComponentsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers, DocumentObject);
	ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject);
	ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.AssemblyFromComponents);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
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

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	CreateBasedOnCommand = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(
									GenerationCommands);
	
	If CreateBasedOnCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"Status",
															Enums.GoodsAssemblyStatuses.AssembledDisassembled,
															ComparisonType.NotEqual);
	EndIf;
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	AssemblyFromComponentsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "assembling (disassembling) products".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AssemblyFromComponents) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AssemblyFromComponents.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AssemblyFromComponents);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAssemblyDisassembly";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document called "Product Assembly".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.AssemblyFromComponents) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.AssemblyOfGoodsCreateOnBasisOfOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.AssemblyFromComponents.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AssemblyFromComponents);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseAssemblyDisassembly";
		
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
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	AssemblyFromComponentsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region ChangeOfStatus

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
// 		DocumentsArray - Array - An array of references to documents that should be reviewed
// 		NewStatus - String - Name of the new status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.GoodsAssemblyStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                   AS StatusMatches,
	|	DocumentsTable.Posted              AS Posted,
	|	DocumentsTable.DeletionMark       AS DeletionMark,
	|	TRUE                                  AS Recording
	|FROM
	|	Document.AssemblyFromComponents AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction// Formationproverciprismenestatus();

// Returns the result of checking when the document status changes
//
// Parameters:
// 		ValidationSample - QueryResultSelection - Current selection string
// 		NewStatus - EnumRef.GoodsAssemblyStatuses - New status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the "Assembly of Goods" document
	
EndFunction

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Status,BusinessOperation,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - Contains keys:
//    * Header - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//    * TS    - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	UseOrderSchemeForAcceptance = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date);
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	Header = ProductsClientServer.SeriesSpecificationParameters();
	Header.FullObjectName = "Document.AssemblyFromComponents";
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Header.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch
											And (Not UseOrderSchemeForAcceptance
											Or WarehouseSeriesParameters.UseCostAccountingByBatches)
											And Object.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
											
		Header.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches
												And Object.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
		Header.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingOfAssembledSets);
	Else
		Header.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
		Header.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		Header.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipSetsForDisassembly);
	EndIf;
	Header.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	Header.LinkFields.Add("Purpose");
	
	Header.ThisIsAnInvoice = True;
	Header.ShipmentPlanning = Object.Status = Enums.GoodsAssemblyStatuses.InProgress;
	Header.SelectionPlanning   = Object.Status = Enums.GoodsAssemblyStatuses.InProgress;
	Header.FactOfSelection           = Object.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Header.RegisterSeries = True;
	Else
		Header.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(Header);
	EndIf;
	
	Header.ProductInHeader = True;
	Header.Date = Object.Date;
	Header.FieldNamesForOrderDefinition.Add("ByAssemblyDisassemblyOrder");
	Header.FieldNamesForOrderDefinition.Add("Ref");
	
	TS = ProductsClientServer.SeriesSpecificationParameters();
	
	TS.FullObjectName = "Document.AssemblyFromComponents";
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TS.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
		TS.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		TS.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipComponentsForAssembly);
	Else
		TS.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch
											And (Not UseOrderSchemeForAcceptance
											Or WarehouseSeriesParameters.UseCostAccountingByBatches)
											And Object.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
											
		TS.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches
											And Object.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
		TS.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly);
	EndIf;	
	
	TS.LinkFields.Add("Purpose");
	
	TS.ThisIsAnInvoice = True;
	TS.ShipmentPlanning = Object.Status = Object.Status = Enums.GoodsAssemblyStatuses.InProgress;
	TS.SelectionPlanning   = Object.Status = Object.Status = Enums.GoodsAssemblyStatuses.InProgress;
	TS.FactOfSelection           = Object.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TS.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(TS);
	Else
		TS.RegisterSeries = True;
	EndIf;
	
	TS.ProductInHeader = False;
	TS.Date = Object.Date;
	TS.FieldNamesForOrderDefinition.Add("ByAssemblyDisassemblyOrder");
	TS.FieldNamesForOrderDefinition.Add("Ref");
	
	SeriesSpecificationParameters = New Structure;
	
	SeriesSpecificationParameters.Insert("Header",Header);
	SeriesSpecificationParameters.Insert("TS",TS);
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.ProductInHeader Then
		
		If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ReceivingOfAssembledSets) <> Undefined Then
			
			QueryText = TextOfRequestToFillInStatusesSpecifyingAssemblyHeaderSeries();
			
		Else
			
			QueryText = RequestTextForFillingInStatusesSpecifyingSeriesOfDisassemblyHeader();
			
		EndIf;
		
	Else
		
		If SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ShipComponentsForAssembly) <> Undefined Then
			
			QueryText = RequestTextForFillingInStatusesForSpecifyingAssemblyTSSeries();
		
		Else
			
			QueryText = TextOfRequestToFillInStatusesForSpecifyingDisassemblyTSSeries();
			
		EndIf;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region FillingInByOrder

// Creates a structure for creating an Assembly of products for one or more Assembly orders
// If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray - Array - transfer orders for which you need to enter an invoice
//  OrderProperties_ - Structure, Undefined - the structure where the header details from the order array will be placed.
//
// Returns:
//  Boolean - False if the details of the header differ in the transferred orders.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	Attributes = New Structure("BusinessOperation, Organization, Warehouse, ProductKit, Department,
		|SalesOpportunity, LineOfBusiness, AssemblyForActivity, GoodsReceiptOption");
	
	Return Common.ObjectAttributesValues(ReferencesArrray[0], Attributes);;
	
EndFunction

// Generates the parameters necessary to verify the entry of the invoice based on orders.
// See GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder
//
// Parameters:
//  References - Array - list of orders on the basis of which the invoice is issued
//  BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued.
//
// Returns:
//  Structure - data for input verification.
//
Function DataForInputValidationBasedOn(References, BusinessOperation = Undefined) Export
	
	DataToEnter = New Structure("Basis, Status, ThereIsShip, InstructionsForRegistration, CanBeGrouped");
	DataToEnter.ThereIsShip = False;
	DataToEnter.CanBeGrouped = False;
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
		"SELECT
		|	ByAssemblyDisassemblyOrder.Ref AS Basis,
		|	ByAssemblyDisassemblyOrder.Status AS Status
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
		|WHERE
		|	ByAssemblyDisassemblyOrder.Ref IN(&References)");
	QueriesTexts.Add(
		"SELECT TOP 1
		|	1
		|FROM
		|	Document.ByAssemblyDisassemblyOrder.Goods AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND GoodsFromOrder.Ref IN(&References)
		|	AND GoodsFromOrder.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND NOT GoodsFromOrder.Canceled
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND GoodsFromOrder.Ref IN(&References)
		|	AND GoodsFromOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND GoodsFromOrder.Count > 0");
	QueriesTexts.Add(AccumulationRegisters.AssemblyOrders.QueryTextBalance("TTBalancesForRegistration"));
	QueriesTexts.Add(
		"SELECT DISTINCT
		|	RequirementsForRegistration_1.ByAssemblyDisassemblyOrder AS InstructionsForRegistration
		|FROM
		|	TTBalancesForRegistration AS RequirementsForRegistration_1");
	
	Query = New Query(StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("References", References);
	Query.SetParameter("Recorder", Undefined);
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	If Selection.Count() = 1 And Selection.Next() Then
		DataToEnter.Basis     = Selection.Basis;
		DataToEnter.Status        = Selection.Status;
		DataToEnter.ThereIsShip = Not Result[1].IsEmpty();
	EndIf;
	
	If Not Result[3].IsEmpty() Then
		DataToEnter.InstructionsForRegistration = Result[3].Unload().UnloadColumn("InstructionsForRegistration");
		DataToEnter.CanBeGrouped = True;
	EndIf;
	
	Return DataToEnter;
	
EndFunction

// Generates parameters for opening the workplace form "Documents for registration".
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued.
//
// Returns:
//  Structure - parameters for opening a form with fields:
//     * FormName - String - the name of the form RM
//     * FormParameters - Structure - parameters of the RM form.
//
Function ParametersForOpeningWorkplaceForm(BusinessOperation = Undefined) Export
	
	FilterBusinessTransactions = New ValueList;
	If ValueIsFilled(BusinessOperation) Then
		FilterBusinessTransactions.Add(BusinessOperation);
	Else
		FilterBusinessTransactions.Add(Enums.BusinessTransactions.AssemblyFromComponents);
		FilterBusinessTransactions.Add(Enums.BusinessTransactions.DisassemblyIntoComponents);
	EndIf;
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID(Metadata.Documents.AssemblyFromComponents));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	FilterParameters.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	OpeningParameters = New Structure("FormName, FormParameters");
	OpeningParameters.FormName = "DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration";
	OpeningParameters.FormParameters = New Structure;
	OpeningParameters.FormParameters.Insert("FormAssignmentKey",     "AssemblyDisassemblyOfGoods_");
	OpeningParameters.FormParameters.Insert("QuickFilterStructure", FilterParameters);
	
	Return OpeningParameters;
	
EndFunction

// Returns the result of a request to fill in an invoice for orders/orders
//
// Parameters:
//  SelectionData_   - Structure - fields that will be used to select order balances for filling in the document
//  CallContext - String - defines the context of calling the procedure:
//                             "Creation of a basis" - creation based on the order form, from the list of orders and from
//                                                     the spsik of orders for execution,
//                             "Filling" for orders from the invoice form when the flag is cocked "on order",
//                             "Selection" selection for orders /orders from the invoice form,
//                             "Re-filling" for shipment and acceptance from the list of orders for registration.
//
// Returns:
//  Structure - a structure containing tables of query execution results.
//
Function RequestResultForOrderBalances(SelectionData_, CallContext) Export
	
	// Description of all possible request parameters.
	QueryParameters = New Structure("SelectByOrder_, AnArrayOfOrders,
	                                    |Organization, Department, Warehouse, BusinessOperation,
	                                    |Recorder, InvoiceGoods");
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", False);
	QueryParameters.Insert("FillInAsNeeded", False);
	
	ListOfRequests   = New ValueList();
	SubqueryNames = New Array();
	
	// Processing of method call parameters.
	If CallContext = "GenerateFrom" Then
		
		RequestParametersToCreateBasedOn(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	ElsIf CallContext = "Pickup" Then
		
		QueryParametersForMatching(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	ElsIf CallContext = "ReFillingByOrders" Then
		
		RequestParametersToBeFilledIn(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	EndIf;
	
	// Description of all possible query texts.
	QueriesTexts = New Map();
	QueriesTexts.Insert("TTOrdersSelection",                        QueryTextOfTemporaryOrderTable());
	QueriesTexts.Insert("TTInvoice",                          RequestTextForTemporaryInvoiceTable());
	QueriesTexts.Insert("TableAssembledDisassembledComponents", RequestTextCollectedParsedComponents());
	QueriesTexts.Insert("TableAssembledDisassembledKit",      RequestTextCollectedParsedSet());
	QueriesTexts.Insert("TableSet",                      TextOfRequestRemainsOfRegisterOrdersAndReverseOfDocumentSet());
	QueriesTexts.Insert("SeriesTable",                         TextOfRequestRemainsOfSeriesOfDisassembledSetAndReverseDocument());
	QueriesTexts.Insert("SeriesTableIsDisassembled",                RequestTextParsedSeries());
	
	// The subqueries used to form the "form table" should be wrapped by the Textquery method(...).
	SubqueryTexts_ = New Map();
	SubqueryTexts_.Insert("BlockRegisterOrdersComponents",          RequestTextUpperCaseOrdersComponents());
	SubqueryTexts_.Insert("StornoInvoiceBlockComponents",        RequestTextReverseRegisteredRecordsInvoiceAccessories());
	SubqueryTexts_.Insert("BlockRegisterOrdersSet",               RequestTextLeftoversRegisterOrdersSet());
	SubqueryTexts_.Insert("BlockStornoOverheadKit",             RequestTextReverseInvoiceKit());
	SubqueryTexts_.Insert("BlockNewRegisteredRecordsInvoiceComponents", RequestTextNewTrafficInvoiceComponents());
	
	For Each Item In ListOfRequests Do
		Item.Presentation = QueriesTexts[Item.Value];
	EndDo;
	
	Item = ListOfRequests.FindByValue("TableComponents");
	If Item <> Undefined Then
		Item.Presentation = MergeRequestText(SubqueryNames, SubqueryTexts_);
	EndIf;
	
	// Request initialization.
	Query = New Query();
	
	For Each Parameter In QueryParameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	For Each Item In ListOfRequests Do
		Query.Text = Query.Text + Item.Presentation;
	EndDo;
	
	// Execution of the request, return of the result.
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	
	ResultStructure1 = New Structure();
	For Each Item In ListOfRequests Do
		ResultStructure1.Insert(Item.Value, QueryResult[ListOfRequests.IndexOf(Item)].Unload());
	EndDo;
	
	Return ResultStructure1;
	
EndFunction

// Checks whether there are spending orders on the order.
//
// Parameters:
//  References - DocumentRef - array of orders.
//
// Returns:
//  Boolean - True if there are orders, False if there are no orders.
//
Function ThereIsWarrantOnOrder(References) Export
	
	Query = New Query();
	Query.Text =
		"SELECT TOP 1
		|	1
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(, , , ,
		|	DocumentShipments IN (&Orders)
		|	AND Warehouse IN(
		|		SELECT
		|			CatWarehouses.Ref AS Warehouse
		|		FROM
		|			Catalog.Warehouses AS CatWarehouses
		|		WHERE
		|			CatWarehouses.UseWarehouseManagemantSystemForGoodsIssue
		|			AND CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &CurrentDayStart)) AS Table
		|WHERE
		|	Table.ToShipExpense + Table.AssembledReceipt > 0
		|	
		|UNION ALL
		|
		|SELECT TOP 1
		|	1
		|FROM
		|	AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(, , , ,
		|	DocumentInflow IN (&Orders)
		|	AND Warehouse IN(
		|		SELECT
		|			CatWarehouses.Ref AS Warehouse
		|		FROM
		|			Catalog.Warehouses AS CatWarehouses
		|		WHERE
		|			CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|			AND CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDayStart)) AS Table
		|WHERE
		|	Table.GoodsReceiptNotesToRegisterExpense > 0";
	
	Query.SetParameter("Orders", References);
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region ShipmentReferenceOrder

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - order for receipt or shipment.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	If ValueIsFilled(FieldValuesToIdentifyReferences.ByAssemblyDisassemblyOrder) Then
		Return FieldValuesToIdentifyReferences.ByAssemblyDisassemblyOrder;
	Else
		Return Undefined;
	EndIf;
EndFunction

#EndRegion

#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.AssemblyFromComponents, DocumentRef.AssemblyFromComponents - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Date,
		|DateOfReceipt,
		|Number,
		|Warehouse,
		|BusinessOperation,
		|LineOfBusiness,
		|Organization,
		|Department,
		|Patch,
		|CorrectedDocument");
	
	If ObjectAttributes.Ref <> Undefined And ObjectAttributes.Patch Then
		Attributes = AttributesOfControlledLotReference(ObjectAttributes.CorrectedDocument, FieldNameControlledLotReference);
		Return Attributes;
	EndIf;
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = Undefined;
	Attributes.Partner = Undefined;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Warehouse;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.AssemblyFromComponents - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * Goods - Structure - structure with fields:
//   ** Key - String
//   ** FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Header - Structure - structure with fields:
//   ** FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   ** Key - String
Function QualityControlActionParameters(Object) Export
	
	AllParameters = New Array();
	
	// Items.
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "Goods");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	
	ActionParameters.ReadableFields = "Products";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlBusinessTransaction", Object.BusinessOperation);
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	&QualityControlBusinessTransaction = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	AllParameters.Add(New Structure("Key,Parameters", "Goods", Action_Parameters));
	
	// Hat.
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "Header");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	
	ActionParameters.ReadableFields = "Products,Warehouse";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlBusinessTransaction", Object.BusinessOperation);
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	&QualityControlBusinessTransaction = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	AllParameters.Add(New Structure("Key,Parameters", "Header", Action_Parameters));
	
	Return New FixedArray(AllParameters);
	
EndFunction

// This function defines the details of the selected product movement.
//
// Parameters:
//  DocumentRef - DocumentRef.AssemblyFromComponents - link to the document.
//
// Returns:
//	Structure - details of the assembly of goods.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.AssemblyFromComponents AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
	Else
		Date = Date(1,1,1);
		Organization = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure("Date, Organization",
		Date,
		Organization);
	
	Return AttributesStructure1;

EndFunction

// Initializes the status structure of the document
//
// Returns:
//  Structure - contains the following keys:
//     * DisplayShipmentTables     - Number -
//     * DisplayReceiptTables  - Number -
//     * ThisIsAnInvoice                - Boolean -
//     * TextProductServiceShipment    - String -
//     * TextProductServiceReceipt - String -
//     * StructureOfAdditionalRequests        - Structure - contains the following keys:
//        ** QueryTextTTGoodsOrderInvoiceShipped   - String -
//        ** QueryTextTTGoodsArrival                      - String -
//        ** QueryTextTTGoodsOrdersReceiptInvoice - String -
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("DisplayShipmentTables", 1);
	StructureState.Insert("DisplayReceiptTables", 2);
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Product';
															|tr = 'Ürün'"));
	StructureState.Insert("TextProductServiceReceipt", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Product';
															|tr = 'Ürün'"));
	
	TTGoodsOrderInvoiceShipped = TemporaryTableGoodsOrderInvoiceShippedForStateOfExecutionReport();
	TTGoodsArrival = TemporaryGoodsReceiptTableForProgressStateReport();
	TTGoodsOrdersReceiptInvoice = TemporaryTableGoodsOrdersReceiptInvoiceForStateOfExecutionReport();
	
	StructureOfAdditionalRequests = New Structure();
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrderInvoiceShipped",   TTGoodsOrderInvoiceShipped);
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsArrival",                      TTGoodsArrival);
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrdersReceiptInvoice", TTGoodsOrdersReceiptInvoice);
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	
	Return StructureState;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the configuration,
// as well as information about the product of the document.
//
// Returns:
//	Structure - a collection containing the following document information:
//		* DocumentHeader - Structure - data about the goods of the document, which contain the following information:
//			** ItemsLocationAttributes - CatalogRef.InventoryLocationAttributeKeys - product analytics.
//			** Products - CatalogRef.Products - the nomenclature of the document.
//			** Characteristic - CatalogRef.ItemsCharacteristics - characteristics of the document.
//			** Purpose - CatalogRef.Assignments - purpose of the product.
//			** Series - CatalogRef.ItemsBatches - product series.
//			** BatchesIndicationStatus - Number - the status of the indication of the product series.
//			** Count - Number - amount of goods.
//			** QuantityByGBRN - Number - traceable quantity of imported goods.
//			** CCDNumber - CatalogRef.CCDNumbers - the product's GTD number.
//		* Goods - ValueTable, TabularSection, Undefined - data on the configuration of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentHeader = New Structure;
	DocumentHeader.Insert("ItemsLocationAttributes", Catalogs.InventoryLocationAttributeKeys.EmptyRef());
	DocumentHeader.Insert("Products", Catalogs.Products.EmptyRef());
	DocumentHeader.Insert("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	DocumentHeader.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	DocumentHeader.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
	DocumentHeader.Insert("BatchesIndicationStatus", 0);
	DocumentHeader.Insert("Count", 0);
	DocumentHeader.Insert("QuantityByGBRN", 0);
	DocumentHeader.Insert("CCDNumber", Catalogs.CCDNumbers.EmptyRef());
	
	DocumentTables = New Structure;
	DocumentTables.Insert("DocumentHeader", DocumentHeader);
	DocumentTables.Insert("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	FillParameters.Insert("FormIsOpen",          False);
	FillParameters.Insert("FillByWarehouseDocument",     Undefined);
	FillParameters.Insert("ByOrderOfAssembly",      False);
	
	Resources = New Array(2);
	Resources[0] = "Kit";
	Resources[1] = "Components";
	FillParameters.Insert("Resources", Resources);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	FillParameters.Insert("Warehouse",                 Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	
	FillParameters.Insert("DocumentName",          "AssemblyFromComponents");
	FillParameters.Insert("RegisterNameOrder",      "AssemblyOrders");
	FillParameters.Insert("FieldNameOrder",          "ByAssemblyDisassemblyOrder");
	
	FillParameters.Insert("KeyFields",          "Products, Characteristic, Series, Purpose");
	
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
	
	For Each OrderDocument In FillParameters.AnArrayOfOrders Do
		If ValueIsFilled(OrderDocument) And TypeOf(OrderDocument) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
			FillParameters.ByOrderOfAssembly = True;
			Break;
		EndIf;
	EndDo;
	
	FillParameters.BusinessOperation	= HeaderAttributes.BusinessOperation;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		FillParameters.FillByWarehouseDocument = InvoicesServer.FillByWarehouseDocument(HeaderAttributes.Warehouse);
	EndIf;
	
EndProcedure

// Returns the Products table
//
// Parameters:
//  Invoice - DocumentRef.AssemblyFromComponents - link to the invoice for PM Products that need to be returned
//  ByHeader   - Boolean - selection from PM Products, or document headers.
//
// Returns:
//  ValueTable - The tabular part of the goods assembly document.
//
Function TableDataAndDocument(Invoice, ByHeader = False) Export
	
	Query = New Query;
	
	If ByHeader Then
		Query.Text = 
		"SELECT
		|	0 AS LineNumber,
		|	ISNULL(AssemblyFromComponentsSetOfSeries.Count, AssemblyFromComponents.Count)         AS Count,
		|	ISNULL(AssemblyFromComponentsSetOfSeries.Products, AssemblyFromComponents.Products)     AS Products,
		|	ISNULL(AssemblyFromComponentsSetOfSeries.Characteristic, AssemblyFromComponents.Characteristic) AS Characteristic,
		|	ISNULL(AssemblyFromComponentsSetOfSeries.Purpose, AssemblyFromComponents.Purpose)         AS Purpose,
		|	ISNULL(AssemblyFromComponentsSetOfSeries.Series, AssemblyFromComponents.Series)                   AS Series,
		|	AssemblyFromComponents.Package                                                    AS Package,
		|	AssemblyFromComponentsSetOfSeries.LineNumber                                            AS RowID,
		|	AssemblyFromComponents.BatchesIndicationStatus                                         AS BatchesIndicationStatus,
		|	AssemblyFromComponents.ItemsLocationAttributes                                  AS ItemsLocationAttributes,
		|	CASE WHEN AssemblyFromComponents.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|		THEN AssemblyFromComponents.Ref
		|		ELSE AssemblyFromComponents.ByAssemblyDisassemblyOrder
		|	END                                                                     AS ByAssemblyDisassemblyOrder,
		|	1                                                                         AS RowCode
		|FROM
		|	Document.AssemblyFromComponents AS AssemblyFromComponents
		|		LEFT JOIN Document.AssemblyFromComponents.SetOfSeries AS AssemblyFromComponentsSetOfSeries
		|		ON (AssemblyFromComponentsSetOfSeries.Ref = AssemblyFromComponents.Ref)
		|WHERE
		|	AssemblyFromComponents.Ref = &Ref";
	Else
		Query.Text = 
		"SELECT
		|	AssemblyFromComponentsGoods.LineNumber                AS LineNumber,
		|	AssemblyFromComponentsGoods.Products               AS Products,
		|	AssemblyFromComponentsGoods.Characteristic             AS Characteristic,
		|	AssemblyFromComponentsGoods.Purpose                 AS Purpose,
		|	AssemblyFromComponentsGoods.Package                   AS Package,
		|	AssemblyFromComponentsGoods.NumberOfPackages         AS NumberOfPackages,
		|	AssemblyFromComponentsGoods.Count                 AS Count,
		|	AssemblyFromComponentsGoods.CostShare              AS CostShare,
		|	AssemblyFromComponentsGoods.RowCode                  AS RowCode,
		|	AssemblyFromComponentsGoods.BatchesIndicationStatus        AS BatchesIndicationStatus,
		|	AssemblyFromComponentsGoods.Series                      AS Series,
		|	AssemblyFromComponentsGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	AssemblyFromComponentsGoods.RowID        AS RowID,
		|	CASE WHEN AssemblyFromComponentsGoods.Ref.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|		THEN AssemblyFromComponentsGoods.Ref
		|		ELSE AssemblyFromComponentsGoods.Ref.ByAssemblyDisassemblyOrder
		|	END                                          AS ByAssemblyDisassemblyOrder
		|FROM
		|	Document.AssemblyFromComponents.Goods AS AssemblyFromComponentsGoods
		|WHERE
		|	AssemblyFromComponentsGoods.Ref = &Ref";
	EndIf;
	
	Query.SetParameter("Ref", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// The procedure fills in the object fields
//
// Parameters:
//  Object				 - DocumentObject.AssemblyFromComponents	 - object to fill in
//  FillParameters	 - Structure					 - structure containing the key of the folder prop (data source)
//  AnArrayOfOrders		 - Array						 - array of build orders.
//
Procedure FillInHeaderOfOrderDocument(Object, FillParameters, AnArrayOfOrders) Export
	
	FillPropertyValues(Object, FillParameters.HeaderAttributes);
	
	Date = OrdersServer.GetMinimumOrderShipmentDate(AnArrayOfOrders, FillParameters.RegisterNameOrder, 
		FillParameters.FieldNameOrder);
	
EndProcedure

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//  Goods				 - FormDataCollection - Table part " Products"
//  FillParameters	 - Structure -
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Fills in the passed parameter table for orders and warehouse orders.
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.AssemblyFromComponents - Link to the current invoice
//  FillParameters	 - Structure - The default parameters are defined in the document parameters () method.
//  PackageBarcodes	 - Undefined, ValueTable - table of barcodes of packages
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes) Export
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(FillParameters.HeaderAttributes.GoodsReceiptOption);
	
	For Each Resource In FillParameters.Resources Do
	
		ForSpendingOrders = ?(Resource = "Kit",
			FillParameters.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents,
			FillParameters.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents);
	
		// If you do not need to fill in an order, we pass empty query parameters - an empty table will be returned for orders.
		If FillParameters.FillByWarehouseDocument Then
			ReferencesForOrders = FillParameters.AnArrayOfOrders;
			RegistrarForOrders  = Recorder;
		Else
			ReferencesForOrders = Undefined;
			RegistrarForOrders  = Undefined;
		EndIf;
		
		// Orders
		
		RequestTextForOrders = AccumulationRegisters.AssemblyOrders.QueryTextBalance("TTAccountingData");
			
		QueryTextOrderDocument = Documents.ByAssemblyDisassemblyOrder.QueryTextDocumentGoods(Resource);
		
		QueryText = RequestTextForOrders
						+ Common.QueryBatchSeparator()
						+ QueryTextOrderDocument;
		
		Query = New Query();
		Query.Text = QueryText;
		Query.SetParameter("References", FillParameters.AnArrayOfOrders);
		Query.SetParameter("Recorder",  Recorder);
		
		OrdersTable = Query.Execute().Unload();
		
		OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";
		OrdersTable.Columns.Add("SetIndex");
		OrdersTable.FillValues(?(Resource = "Kit", 1, 0), "SetIndex");
		
		// Orders_3
		Query = New Query();
		
		// Assembly by header or disassembly by goods - receipt orders, otherwise - consumable
		If ForSpendingOrders Then 
			TextOfRequestRemainsToIssue = AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue();
		Else
			TextOfRequestRemainsToIssue = AccumulationRegisters.GoodsToReceive.TextOfRequestRemainsToIssueOrders();
		EndIf;
		
		Query.Text = TextOfRequestRemainsToIssue;
		
		Query.SetParameter("References",  ReferencesForOrders);
		Query.SetParameter("Recorder",   RegistrarForOrders);
		
		TableOrders = Query.Execute().Unload();
		
		TableOrders.Columns.Count.Name   = "NoteQuantity";
		TableOrders.Columns.ReferenceOrder.Name = "ByAssemblyDisassemblyOrder";
		If TableOrders.Columns.Find("AssemblyInProgress") <> Undefined Then
			TableOrders.Columns.AssemblyInProgress.Name   = "NumberInProgress";
		EndIf;
		TableOrders.Columns.Add("SetIndex");
		TableOrders.FillValues(?(Resource = "Kit", 1, 0), "SetIndex");
		
		// In these cases, only 14 series can be used (Cost accounting by series when planning shipment).
		FillingInAccordingToAcceptanceData = 
			FillParameters.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents And Resource <> "Kit"
			Or FillParameters.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents And Resource = "Kit";
		
		// Distribution of the resulting tables
		
		Goods.Indexes.Add("ByAssemblyDisassemblyOrder, " + FillParameters.KeyFields);
		
		// Adding the number of orders
		
		Var_Key = "ByAssemblyDisassemblyOrder, RowCode," + FillParameters.KeyFields;
		Var_Key = ?(FillingInAccordingToAcceptanceData, StrReplace(Var_Key, "Series", ""), Var_Key);
		
		Condition = "On [Count]";
		InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
		
		// Adding an undistributed number of orders in separate lines
		InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
		
		// Adding the number of orders.
		
		// When filling in on receipt orders, when the order is an invoice, it is impossible to connect by order.
		Var_Key = ?(InvoiceIsOrder And Not ForSpendingOrders, "", "ByAssemblyDisassemblyOrder, ") + FillParameters.KeyFields;
		Var_Key = ?(FillingInAccordingToAcceptanceData, StrReplace(Var_Key, "Series", ""), Var_Key);
		
		// In addition to the distribution of the quantity, it is necessary to copy as is the values of the Series field according to order data.
		FieldsToFillIn = ?(FillingInAccordingToAcceptanceData, "Series", "");
		
		// There are invoices and orders
		Condition = "[Count], [QuantityInOrder], On [QuantityInOrder]";
		InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, False, FieldsToFillIn);
		
		// There are orders, no invoices
		Condition = "NOT [Count], [QuantityInOrder], On [QuantityInOrder]";
		InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, False, FieldsToFillIn);
		
		// There are invoices, no orders
		Condition = "[Count], NOT [QuantityInOrder]";
		InvoicesServer.DistributeQuantityAndFill(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True, FieldsToFillIn);
		
		// There are measured goods and the permissible deviation is set
		InvoicesServer.DistributeDeviationOfDimensionalGoods(TableOrders, Goods, "QuantityInOrder", "NoteQuantity", Var_Key);
		
		// Adding an undistributed number of orders in separate lines, if the invoice is not on order.
		If Not FillParameters.ByOrderOfAssembly Then
			InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
		EndIf;
		
		// Additional information - how much product is collected
		If TableOrders.Columns.Find("NumberInProgress") <> Undefined Then
			InvoicesServer.AllocateQuantity(TableOrders, Goods, "NumberInProgress", Var_Key, "", True);
		EndIf;
	
	EndDo;
	
	If ForSpendingOrders And ReferencesForOrders <> Undefined Then
		AssemblyFromComponentsLocalization.FillInBarcodesOfPackages(ReferencesForOrders, Goods, PackageBarcodes);
	EndIf;
	
EndProcedure

// Fills in the document header from the passed product table
//
// Parameters:
//  Object		 - DocumentObject -
//  Table		 - ValueTable - A table containing the product header in one row, or several if you use a series.
//  								It must contain the following fields: Item, Characteristic, Series, Purpose, Quantity
//  ReferenceOrder - DocumentRef.ByAssemblyDisassemblyOrder -
//
Procedure ResubmitProductsInHeader(Object, Table, ReferenceOrder = Undefined) Export
	
	FullTable = Table.Copy();
	
	Table.GroupBy("Products, Characteristic, Series, Purpose, Count");
	
	Object.SetOfSeries.Clear();
	
	If FullTable.Count() > 0 Then
		FillPropertyValues(Object, FullTable[0]);
		Object.Count = FullTable.Total("Count");
		
		For Each String In Table Do
			If ValueIsFilled(String.Series) And String.Count > 0 Then
				NewSeries_ = Object.SetOfSeries.Add();
				FillPropertyValues(NewSeries_, String);
			EndIf;
		EndDo;
	EndIf;
	
	// Refilling the header
	If TypeOf(ReferenceOrder) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
		DetailsOfOrder = Common.ObjectAttributesValues(ReferenceOrder, 
		"Package, Purpose, WithAssignment");
		
		Object.Package = DetailsOfOrder.Package;
		
		SeparateSoftwareIsUsed = DetailsOfOrder.WithAssignment;
		
		PurposeOfHeaderIsUsed = ValueIsFilled(DetailsOfOrder.Purpose) 
			And Common.ObjectAttributeValue(DetailsOfOrder.Purpose, "RecordsInWarehouseRegisters")
			And SeparateSoftwareIsUsed;
		
		If PurposeOfHeaderIsUsed Then
			Object.Purpose = DetailsOfOrder.Purpose;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.ProductKit) Then
		
		Component = Common.ObjectAttributesValues(Object.ProductKit,
			New Structure("Products, Characteristic", "ProductsOfMainComponent", "MainComponentCharacteristic"));
		If ValueIsFilled(Component.Products) And ValueIsFilled(Object.Goods.FindRows(Component)) Then
			Object.ProductsOfMainComponent = Component.Products;
			Object.MainComponentCharacteristic = Component.Characteristic;
		EndIf;
		
	EndIf;
	
	StructureOfActions = New Structure("RecalculateNumberOfPackages");
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
		QualityControlClientServer.CacheByKey(CacheQualityControl, "Header"));
	BatchProcessingOfTablePartServer.ProcessTSString(Object, StructureOfActions, Undefined);
	
EndProcedure

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	Return "Ref";
	
EndFunction

#EndRegion

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	If GetFunctionalOption("UseGoodsAssemblyStatuses") Then
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.GoodsAssemblyStatuses.InProgress);
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.GoodsAssemblyStatuses.AssembledDisassembled);
	EndIf;
	
	Return Table;
	
EndFunction

// Parameters for embedding business lines in a document.
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
// Returns:
//  See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	
	TabularSectionNames = Undefined;
	If Form.Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TabularSectionNames = "Goods";
	EndIf;
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = TabularSectionNames;
	
	If Form.Object.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		TabularSectionNames = "Goods";
	EndIf;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = TabularSectionNames;
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	DocumentProcessingProcedure.NameOfFormElementIsSeparate = "GoodsWithAssignment";
	DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate = "ProductsTeamGroupSeparately";
	DocumentProcessingProcedure.OrderDetailsName = "ByAssemblyDisassemblyOrder";
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	// The need for kits in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Purpose", "Kits");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ToControlQuality = "Object.ToControlQuality";
	
	// Needs for components in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Components");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ToControlQuality = "Object.Goods.ToControlQuality";
	
	Return FormTemplate;
	
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
	JobPrintingRules.ReceiptOperation = True;
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion

#Region KitConfigurations

// Initializes the parameters for verifying the correctness of the set.
//
// Parameters:
//	Object - DocumentObject.AssemblyFromComponents,
//				This Formstructure is a document for which it is necessary to obtain the parameters of the kit verification.
//
// Returns:
//	Structure - See AccountingForTraceableGoodsLocalization.SetValidationParameters.
//
Function SetValidationParameters(Object) Export
	
	CheckParameters = AccountingForTraceableGoodsLocalization.SetValidationParameters();
	FillPropertyValues(CheckParameters, Object);
	
	CheckParameters.KitAssembly = Object.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents;
	
	CheckParameters.OptionForPresentationOfSetInPrintedFormsInHeader = False;
	
	Return CheckParameters;
	
EndFunction

#EndRegion
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.AssemblyFromComponents, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return DocumentObject.SubjectToExcise;
	
EndFunction

#EndRegion
#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	If RegisterName = "AvailableStock" Then
		DataSources.Insert("ByAssemblyDisassemblyOrder");
	EndIf;
	
	Return DataSources;

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	HeaderData_.Date AS Period,
		|	HeaderData_.Number AS Number,
		|	HeaderData_.Ref AS Ref,
		|	HeaderData_.Organization AS Organization,
		|	HeaderData_.Department AS Department,
		|	HeaderData_.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	HeaderData_.SalesOpportunity AS SalesOpportunity,
		|	HeaderData_.EnabledGoodsAssignmentInSalesOpportunity AS EnabledGoodsAssignmentInSalesOpportunity,
		|	HeaderData_.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder,
		|	HeaderData_.CustomAssembly AS CustomAssembly,
		|	HeaderData_.Date AS ReferenceDate,
		|	HeaderData_.Warehouse AS Warehouse,
		|	HeaderData_.Products AS Products,
		|	HeaderData_.Characteristic AS Characteristic,
		|	HeaderData_.Count AS Count,
		|	HeaderData_.Purpose AS Purpose,
		|	HeaderData_.Series AS Series,
		|	HeaderData_.Status AS Status,
		|	HeaderData_.AssemblyForActivity AS AssemblyForActivity,
		|	HeaderData_.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment,
		|	HeaderData_.AdvancedWarehousingOnGoodsReceipt AS AdvancedWarehousingOnGoodsReceipt,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	HeaderData_.MainComponentIsSpecified AS MainComponentIsSpecified,
		|	HeaderData_.LineOfBusiness AS LineOfBusiness,
		|	HeaderData_.EmployeeResponsible AS EmployeeResponsible,
		|	HeaderData_.Comment AS Comment,
		|	HeaderData_.DeletionMark AS DeletionMark,
		|	HeaderData_.Posted AS Posted,
		|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
		|	HeaderData_.Patch AS Patch,
		|	HeaderData_.ReversedDocument AS ReversedDocument,
		|	HeaderData_.CorrectedDocument AS CorrectedDocument,
		|	HeaderData_.CorrectedDocument.Date AS AdjustmentPeriod_,
		|	HeaderData_.ControlledLotReference AS ControlledLotReference,
		|	HeaderData_.ToControlQuality AS ToControlQuality,
		|	HeaderData_.QualityConfirmationDate AS QualityConfirmationDate,
		|	HeaderData_.BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS HeaderData_";

	Result = Query.Execute();

	ParametersStructure = TMCommonUse.FirstLineOfQueryResultInStructure(Result);
	TMCommonUse.SetRequestParameters(Query, ParametersStructure);

	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(ParametersStructure.GoodsReceiptOption);

	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("InvoiceIsOrder",   InvoiceIsOrder);	
	Query.SetParameter("NumberForPrinting",                    ObjectsPrefixesClientServer.NumberForPrinting(ParametersStructure.Number));
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID("Document.AssemblyFromComponents"));

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, ParametersStructure);

EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager();

	If DocumentRef = Undefined Then
		Return;
	EndIf;

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataBatchTable(ListOfRequests);
	QueryTextDataOfDocumentTableOfInventoryOwnerAttributes(ListOfRequests);
	QueryTextDataOfDocumentTableOfInventoryOwnerAttributesWriteOff(ListOfRequests);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();

EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = 
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Number AS Number,
		|	DocumentData.DateOfReceipt AS DateOfReceipt,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	ISNULL(Departments.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.SalesOpportunity AS SalesOpportunity,
		|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
		|	DocumentData.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder,
		|	DocumentData.ByAssemblyDisassemblyOrder <> VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef) AS CustomAssembly,
		|	DocumentData.Date AS ReferenceDate,
		|	DocumentData.Warehouse AS Warehouse,
		|	DocumentData.Products AS Products,
		|	DocumentData.Characteristic AS Characteristic,
		|	DocumentData.Count AS Count,
		|	DocumentData.ItemsLocationAttributes,
		|	DocumentData.Purpose AS Purpose,
		|	Assignments.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
		|	DocumentData.Series AS Series,
		|	DocumentData.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	DocumentData.Status AS Status,
		|	DocumentData.AssemblyForActivity AS AssemblyForActivity,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsIssue
		|		AND DocumentData.Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue AS AdvancedWarehousingOnShipment,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND DocumentData.Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS AdvancedWarehousingOnGoodsReceipt,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) AS ThisIsAssemblyFromComponents,
		|	DocumentData.ProductsOfMainComponent <> VALUE(Catalog.Products.EmptyRef) AS MainComponentIsSpecified,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Comment AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	DocumentData.ControlledLotReference AS ControlledLotReference,
		|	DocumentData.ToControlQuality AS ToControlQuality,
		|	DocumentData.QualityConfirmationDate AS QualityConfirmationDate,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
		|INTO DocumentDataHeader
		|FROM
		|	Document.AssemblyFromComponents AS DocumentData
		|		LEFT JOIN Catalog.BusinessStructure AS Departments
		|		ON DocumentData.Department = Departments.Ref
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON DocumentData.Warehouse = Warehouses.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON (Assignments.Ref = DocumentData.Purpose)
		|WHERE
		|	DocumentData.Ref IN(&Ref)
		|
		|INDEX BY
		|	DocumentData.Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods =
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.CostShare AS CostShare,
		|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTable.ToControlQuality AS ToControlQuality,
		|	GoodsTable.QualityConfirmationDate AS QualityConfirmationDate,
		|	Assignments.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
		|	GoodsTable.RowID AS RowID
		|INTO DocumentDataTableItems
		|FROM
		|	Document.AssemblyFromComponents.Goods AS GoodsTable
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
		|		ON (Packages.Ref = GoodsTable.Package)
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON (Assignments.Ref = GoodsTable.Purpose)
		|WHERE
		|	GoodsTable.Ref = &Ref
		|
		|INDEX BY
		|	GoodsTable.Ref";

	ListOfRequests.Add(QueryTextTableGoods);

EndProcedure

Procedure QueryTextDocumentDataBatchTable(ListOfRequests)

	QueryTextTableSetOfSeries =
		"SELECT
		|	SeriesTable.Ref AS Ref,
		|	SeriesTable.LineNumber AS LineNumber,
		|	SeriesTable.Products AS Products,
		|	SeriesTable.Characteristic AS Characteristic,
		|	SeriesTable.Purpose AS Purpose,
		|	Assignments.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
		|	SeriesTable.Series AS Series,
		|	SeriesTable.Count AS Count
		|INTO DocumentDataBatchTable
		|FROM
		|	Document.AssemblyFromComponents.SetOfSeries AS SeriesTable
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON Assignments.Ref = SeriesTable.Purpose
		|WHERE
		|	SeriesTable.Ref = &Ref
		|
		|INDEX BY
		|	SeriesTable.Ref";

	ListOfRequests.Add(QueryTextTableSetOfSeries);

EndProcedure

Procedure QueryTextDataOfDocumentTableOfInventoryOwnerAttributes(ListOfRequests)

	QueryTextTableInventoryOwnerAttributesGoodsReceipt =
		"SELECT
		|	TableTypesOfStocksRegistration.Ref AS Ref,
		|	TableTypesOfStocksRegistration.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableTypesOfStocksRegistration.CCDNumber AS CCDNumber,
		|	SUM(TableTypesOfStocksRegistration.Count) AS Count,
		|	SUM(TableTypesOfStocksRegistration.QuantityByGBRN) AS QuantityByGBRN,
		|	TableTypesOfStocksRegistration.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO DataOfDocumentTableOfInventoryOwnerAttributes
		|FROM
		|	Document.AssemblyFromComponents.InventoryOwnerAttributesGoodsReceipt AS TableTypesOfStocksRegistration
		|WHERE
		|	TableTypesOfStocksRegistration.Ref = &Ref
		|
		|GROUP BY
		|	TableTypesOfStocksRegistration.Ref,
		|	TableTypesOfStocksRegistration.InventoryOwnerAttribute,
		|	TableTypesOfStocksRegistration.CCDNumber,
		|	TableTypesOfStocksRegistration.ItemsLocationAttributes
		|
		|INDEX BY
		|	TableTypesOfStocksRegistration.Ref";

	ListOfRequests.Add(QueryTextTableInventoryOwnerAttributesGoodsReceipt);

EndProcedure

Procedure QueryTextDataOfDocumentTableOfInventoryOwnerAttributesWriteOff(ListOfRequests)

	QueryTextTableInventoryOwnerAttributesConsumption =
		"SELECT
		|	TableTypesOfInventoryWriteOff.Ref AS Ref,
		|	TableTypesOfInventoryWriteOff.LineNumber AS LineNumber,
		|	TableTypesOfInventoryWriteOff.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableTypesOfInventoryWriteOff.CCDNumber AS CCDNumber,
		|	TableTypesOfInventoryWriteOff.Count AS Count,
		|	TableTypesOfInventoryWriteOff.QuantityByGBRN AS QuantityByGBRN,
		|	TableTypesOfInventoryWriteOff.RowID AS RowID,
		|	TableTypesOfInventoryWriteOff.ItemsLocationAttributes AS ItemsLocationAttributes
		|INTO DataOfDocumentTableOfInventoryOwnerAttributesWriteOff
		|FROM
		|	Document.AssemblyFromComponents.InventoryOwnerAttributesConsumption AS TableTypesOfInventoryWriteOff
		|WHERE
		|	TableTypesOfInventoryWriteOff.Ref = &Ref
		|
		|INDEX BY
		|	TableTypesOfInventoryWriteOff.Ref";

	ListOfRequests.Add(QueryTextTableInventoryOwnerAttributesConsumption);

EndProcedure

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref",                Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Warehouse",                 Query.Parameters.Warehouse);
	QueryAnalyst.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	QueryAnalyst.SetParameter("Status",                Query.Parameters.Status);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	GoodsTable.Warehouse          AS Warehouse,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose     AS Purpose,
	|	GoodsTable.Series          AS Series
	|FROM (
	|	SELECT
	|		&Warehouse                         AS Warehouse,
	|		DocumentData.Products   AS Products,
	|		DocumentData.Characteristic AS Characteristic,
	|		DocumentData.Purpose     AS Purpose,
	|		DocumentData.Series          AS Series
	|	FROM
	|		Document.AssemblyFromComponents AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&Warehouse                         AS Warehouse,
	|		DocumentData.Products   AS Products,
	|		DocumentData.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		DocumentData.Series          AS Series
	|	FROM
	|		Document.AssemblyFromComponents AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner        AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series
	|	FROM
	|		Document.AssemblyFromComponents.InventoryOwnerAttributesConsumption AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TypesOfOwnerStocks.GoodsOwner                 AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series
	|	FROM
	|		Document.AssemblyFromComponents.InventoryOwnerAttributesConsumption AS TableTypesOfStocks_
	|
	|		INNER JOIN 
	|			Catalog.InventoryKinds AS TypesOfOwnerStocks
	|		ON
	|			TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND TypesOfOwnerStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	) AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		GoodsTable.Products     = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Purpose 	   = Dimension.Purpose
	|		AND GoodsTable.Series          = Dimension.Series
	|		AND GoodsTable.Warehouse          = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTableAssemblyOrders(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AssemblyOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	PartsOfQueryText = New Array;

	If DocumentObject = Undefined
		Or Not DocumentObject.ByAssemblyDisassemblyOrder.IsEmpty() Then
		// Sets, shipped series are specified in the header.
		TextOfRequestPart = 
			"SELECT
			|	VALUE(AccumulationRecordType.Expense) AS RecordType,
			|	GoodsTable.Date AS Period,
			|	GoodsTable.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	CASE
			|		WHEN GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|			THEN GoodsTable.Series
			|	END AS Series,
			|	1 AS RowCode,
			|	CASE
			|		WHEN GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|			THEN VALUE(Enum.InventoryMovementTypes.Inpayment)
			|		ELSE VALUE(Enum.InventoryMovementTypes.Shipment)
			|	END AS AssemblyType,
			|	GoodsTable.Count AS Ordered,
			|	GoodsTable.Count AS ToRegister
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.CustomAssembly
			|	AND (GoodsTable.BatchesIndicationStatus <> 10 // Including Status = 14, then the series is taken from the header.
			|			OR GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents))";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents
			And Not DocumentObject.ByAssemblyDisassemblyOrder.IsEmpty()) Then
		// Sets, shipped series are specified in a separate tabular part.
		TextOfRequestPart = 
			"SELECT
			|	VALUE(AccumulationRecordType.Expense) AS RecordType,
			|	HeaderData_.Date AS Period,
			|	HeaderData_.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Series AS Series,
			|	1 AS RowCode,
			|	VALUE(Enum.InventoryMovementTypes.Shipment) AS AssemblyType,
			|	GoodsTable.Count AS Ordered,
			|	GoodsTable.Count AS ToRegister
			|FROM
			|	DocumentDataBatchTable AS GoodsTable
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = GoodsTable.Ref)
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND HeaderData_.CustomAssembly
			|	AND GoodsTable.Products = HeaderData_.Products
			|	AND GoodsTable.Characteristic = HeaderData_.Characteristic
			|	AND GoodsTable.Purpose = HeaderData_.Purpose
			|	AND HeaderData_.BatchesIndicationStatus = 10 // Status = 10, then the series are taken from a separate tabular part of the Series
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or Not DocumentObject.ByAssemblyDisassemblyOrder.IsEmpty() Then
		// Accessories.
		TextOfRequestPart = 
		"SELECT
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	HeaderData_.Date AS Period,
		|	HeaderData_.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|			THEN GoodsTable.Series
		|	END AS Series,
		|	GoodsTable.RowCode AS RowCode,
		|	CASE
		|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|			THEN VALUE(Enum.InventoryMovementTypes.Shipment)
		|		ELSE VALUE(Enum.InventoryMovementTypes.Inpayment)
		|	END AS AssemblyType,
		|	GoodsTable.Count AS Ordered,
		|	GoodsTable.Count AS ToRegister
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = GoodsTable.Ref)
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND HeaderData_.CustomAssembly";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If PartsOfQueryText.Count() = 0 Then
		Return "";
	EndIf;

	QueryText = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Procedure ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject)
	
	ThereIsRegisterOfGoodsInWarehouses		= DocumentsPosting.RequiresTableForRegisteredRecords("ProductStock", Registers);
	ThereIsRegisterOfGoodsForReceipt	= DocumentsPosting.RequiresTableForRegisteredRecords("GoodsToReceive", Registers);
	
	If Not (ThereIsRegisterOfGoodsInWarehouses
		Or ThereIsRegisterOfGoodsForReceipt) Then
		
		Return;
		
	EndIf;
	
	PartsOfQueryTextGoodsInWarehouses		= New Array;
	PartsOfQueryTextOfGoodsToBeReceived	= New Array;
	
	If ThereIsRegisterOfGoodsInWarehouses
		And (DocumentObject = Undefined
			Or (DocumentObject.BatchesIndicationStatus <> 10
				And DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
				And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled)) Then
		
		// Assembly of kits.
		TextOfRequestPart = 
			"SELECT
			|	GoodsTable.Ref                AS Ref,
			|	GoodsTable.ByAssemblyDisassemblyOrder         AS OrderDocument,
			|	CASE
			|		WHEN GoodsTable.Patch
			|			THEN GoodsTable.CorrectedDocument
			|		ELSE GoodsTable.Ref
			|	END                               AS Invoice,
			|	GoodsTable.Date                  AS Date,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED                        AS Terms,
			|	GoodsTable.GoodsReceiptOption AS GoodsReceiptOption,
			|	GoodsTable.Warehouse                 AS Warehouse,
			|	GoodsTable.Warehouse                 AS Sender,
			|	GoodsTable.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products          AS Products,
			|	GoodsTable.Characteristic        AS Characteristic,
			|	GoodsTable.Purpose            AS Purpose,
			|	GoodsTable.ToControlQuality AS ToControlQuality,
			|	GoodsTable.ControlledLotReference  AS ControlledLotReference,
			|	FALSE                                AS RecordOfAPreviouslyReceivedLot,
			|	GoodsTable.BatchesIndicationStatus   AS BatchesIndicationStatus,
			|	GoodsTable.BatchesIndicationStatus   AS BatchesIndicationStatusInWarehouses,
			|	GoodsTable.BatchesIndicationStatus   AS BatchesIndicationStatusGoodsAtPartners,
			|	FALSE                                AS ExceedingOrder,
			|	GoodsTable.Series                 AS Series,
			|	GoodsTable.Count            AS Count,
			|	GoodsTable.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE                              AS ThisIsAnInvoice
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND GoodsTable.BatchesIndicationStatus <> 10
			|	AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND GoodsTable.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)";
		
		PartsOfQueryTextGoodsInWarehouses.Add(TextOfRequestPart);
		
	EndIf;
	
	If ThereIsRegisterOfGoodsInWarehouses
		And (DocumentObject = Undefined
			Or (DocumentObject.BatchesIndicationStatus = 10
				And DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
				And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled)) Then
		
		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Ref              AS Ref,
			|	HeaderData_.ByAssemblyDisassemblyOrder         AS OrderDocument,
			|	CASE
			|		WHEN HeaderData_.Patch
			|			THEN HeaderData_.CorrectedDocument
			|		ELSE HeaderData_.Ref
			|	END                             AS Invoice,
			|	HeaderData_.Date                  AS Date,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED                      AS Terms,
			|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
			|	HeaderData_.Warehouse                 AS Warehouse,
			|	HeaderData_.Warehouse                 AS Sender,
			|	HeaderData_.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products        AS Products,
			|	GoodsTable.Characteristic      AS Characteristic,
			|	GoodsTable.Purpose          AS Purpose,
			|	HeaderData_.ToControlQuality AS ToControlQuality,
			|	HeaderData_.ControlledLotReference AS ControlledLotReference,
			|	FALSE                              AS RecordOfAPreviouslyReceivedLot,
			|	HeaderData_.BatchesIndicationStatus   AS BatchesIndicationStatus,
			|	HeaderData_.BatchesIndicationStatus   AS BatchesIndicationStatusInWarehouses,
			|	HeaderData_.BatchesIndicationStatus   AS BatchesIndicationStatusGoodsAtPartners,
			|	FALSE                              AS ExceedingOrder,
			|	GoodsTable.Series               AS Series,
			|	GoodsTable.Count          AS Count,
			|	HeaderData_.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE                            AS ThisIsAnInvoice
			|FROM
			|	DocumentDataBatchTable AS GoodsTable
			|		INNER JOIN DocumentDataHeader AS HeaderData_
			|		ON GoodsTable.Ref = HeaderData_.Ref
			|			AND GoodsTable.Products = HeaderData_.Products
			|			AND GoodsTable.Characteristic = HeaderData_.Characteristic
			|			AND GoodsTable.Purpose = HeaderData_.Purpose
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND HeaderData_.BatchesIndicationStatus = 10
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND HeaderData_.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)";
		
		PartsOfQueryTextGoodsInWarehouses.Add(TextOfRequestPart);
		
	EndIf;
	
	If ThereIsRegisterOfGoodsForReceipt
		And (DocumentObject = Undefined
			Or (DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled
				And DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents)) Then
		
		TextOfRequestPart = 
			"SELECT
			|	GoodsTable.Ref                AS Ref,
			|	GoodsTable.ByAssemblyDisassemblyOrder         AS OrderDocument,
			|	CASE
			|		WHEN GoodsTable.Patch
			|			THEN GoodsTable.CorrectedDocument
			|		ELSE GoodsTable.Ref
			|	END                               AS Invoice,
			|	GoodsTable.Date                  AS Date,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED                        AS Terms,
			|	GoodsTable.GoodsReceiptOption AS GoodsReceiptOption,
			|	GoodsTable.Warehouse                 AS Warehouse,
			|	GoodsTable.Warehouse                 AS Sender,
			|	GoodsTable.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products          AS Products,
			|	GoodsTable.Characteristic        AS Characteristic,
			|	GoodsTable.Purpose            AS Purpose,
			|	GoodsTable.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	GoodsTable.ControlledLotReference AS ControlledLotReference,
			|	GoodsTable.BatchesIndicationStatus   AS BatchesIndicationStatus,
			|	GoodsTable.BatchesIndicationStatus   AS BatchesIndicationStatusInWarehouses,
			|	GoodsTable.BatchesIndicationStatus   AS BatchesIndicationStatusGoodsAtPartners,
			|	FALSE                                AS ExceedingOrder,
			|	GoodsTable.Series                 AS Series,
			|	GoodsTable.Count            AS Count,
			|	GoodsTable.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE                              AS ThisIsAnInvoice
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND GoodsTable.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)";
		
		PartsOfQueryTextOfGoodsToBeReceived.Add(TextOfRequestPart);
		
	EndIf;
	
	If (ThereIsRegisterOfGoodsInWarehouses
			Or ThereIsRegisterOfGoodsForReceipt)
		And (DocumentObject = Undefined
			Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents
				And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled)) Then
		
		// Disassembly for components.
		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Ref              AS Ref,
			|	HeaderData_.ByAssemblyDisassemblyOrder         AS OrderDocument,
			|	CASE
			|		WHEN HeaderData_.Patch
			|			THEN HeaderData_.CorrectedDocument
			|		ELSE HeaderData_.Ref
			|	END                             AS Invoice,
			|	HeaderData_.Date                  AS Date,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED                      AS Terms,
			|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
			|	HeaderData_.Warehouse                 AS Warehouse,
			|	HeaderData_.Warehouse                 AS Sender,
			|	HeaderData_.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products        AS Products,
			|	GoodsTable.Characteristic      AS Characteristic,
			|	GoodsTable.Purpose          AS Purpose,
			|	GoodsTable.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	HeaderData_.ControlledLotReference AS ControlledLotReference,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatusInWarehouses,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatusGoodsAtPartners,
			|	HeaderData_.CustomAssembly
			|		AND GoodsTable.RowCode = 0 AS ExceedingOrder,
			|	GoodsTable.Series               AS Series,
			|	GoodsTable.Count          AS Count,
			|	HeaderData_.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE                            AS ThisIsAnInvoice
			|FROM
			|	DocumentDataTableItems AS GoodsTable
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON GoodsTable.Ref = HeaderData_.Ref
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|	AND HeaderData_.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)";
		
		If ThereIsRegisterOfGoodsInWarehouses Then
			PartsOfQueryTextGoodsInWarehouses.Add(TextOfRequestPart);
		EndIf;
		
		If ThereIsRegisterOfGoodsForReceipt Then
			PartsOfQueryTextOfGoodsToBeReceived.Add(TextOfRequestPart);
		EndIf;
		
	EndIf;
	
	CurrentMetadataObject1 = Metadata.Documents.AssemblyFromComponents;
	
	If PartsOfQueryTextGoodsInWarehouses.Count() > 0 Then
		QueryTextDocument_ = StrConcat(PartsOfQueryTextGoodsInWarehouses,
											TMCommonUse.QuerySeparatorInJoin());
		
		WarehousesServer.ToIssueReceiptOfGoodsOnDvukhodovka(Query,
			QueryTexts,
			"ProductStock",
			QueryTextDocument_,
			CurrentMetadataObject1,
			"SetOfSeries",
			"GoodsTable");
	EndIf;
	
	If PartsOfQueryTextOfGoodsToBeReceived.Count() > 0 Then
		QueryTextDocument_ = StrConcat(PartsOfQueryTextOfGoodsToBeReceived,
											TMCommonUse.QuerySeparatorInJoin());
		
		WarehousesServer.ToIssueReceiptOfGoodsOnDvukhodovka(Query,
			QueryTexts,
			"GoodsToReceive",
			QueryTextDocument_,
			CurrentMetadataObject1,
			"SetOfSeries",
			"GoodsTable");
	EndIf;
	
EndProcedure

Procedure ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		// Assembly of kits.
		QueryTextDocument_ =
			"SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.ByAssemblyDisassemblyOrder AS OrderDocument,
			|	CASE
			|		WHEN GoodsTable.Patch
			|			THEN GoodsTable.CorrectedDocument
			|		ELSE GoodsTable.Ref
			|	END AS Invoice,
			|	GoodsTable.Patch AS Patch,
			|	GoodsTable.CorrectedDocument AS CorrectedDocument,
			|	GoodsTable.Date AS Date,
			|	GoodsTable.Date AS DateOfPlannedReceipt,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED AS Terms,
			|	GoodsTable.GoodsReceiptOption AS GoodsReceiptOption,
			|	GoodsTable.Warehouse AS Warehouse,
			|	GoodsTable.Warehouse AS Sender,
			|	GoodsTable.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Purpose AS Purpose,
			|	GoodsTable.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	GoodsTable.ControlledLotReference AS ControlledLotReference,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	FALSE AS ExceedingOrder,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Count AS Count,
			|	GoodsTable.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE AS ThisIsAnInvoice
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";	
		
		WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(
			Query,
			QueryTexts,
			Registers,
			QueryTextDocument_,
			"GoodsTable");
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		// Disassembly for components.
		QueryTextDocument_ =
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.ByAssemblyDisassemblyOrder AS OrderDocument,
			|	CASE
			|		WHEN HeaderData_.Patch
			|			THEN HeaderData_.CorrectedDocument
			|		ELSE HeaderData_.Ref
			|	END AS Invoice,
			|	HeaderData_.Patch AS Patch,
			|	HeaderData_.CorrectedDocument AS CorrectedDocument,
			|	HeaderData_.Date AS Date,
			|	HeaderData_.Date AS DateOfPlannedReceipt,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED AS Terms,
			|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
			|	HeaderData_.Warehouse AS Warehouse,
			|	HeaderData_.Warehouse AS Sender,
			|	HeaderData_.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Purpose AS Purpose,
			|	HeaderData_.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	HeaderData_.ControlledLotReference AS ControlledLotReference,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	HeaderData_.CustomAssembly
			|		AND GoodsTable.RowCode = 0 AS ExceedingOrder,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Count AS Count,
			|	HeaderData_.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE AS ThisIsAnInvoice
			|FROM
			|	DocumentDataTableItems AS GoodsTable
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = GoodsTable.Ref)
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		
		WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(
			Query,
			QueryTexts,
			Registers,
			QueryTextDocument_,
			"GoodsTable");
	EndIf;
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
		And (DocumentObject.Status = Enums.GoodsAssemblyStatuses.InProgress
			Or DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled) Then
		// Assembly of kits.
		QueryTextDocument_ =
			"SELECT
			|	GoodsTable.Ref AS Ref,
			|	CASE
			|		WHEN GoodsTable.Patch
			|			THEN GoodsTable.CorrectedDocument
			|		ELSE GoodsTable.Ref
			|	END AS Invoice,
			|	GoodsTable.Patch AS Patch,
			|	GoodsTable.CorrectedDocument AS CorrectedDocument,
			|	GoodsTable.ByAssemblyDisassemblyOrder AS OrderDocument,
			|	CASE
			|		WHEN GoodsTable.DateOfReceipt <> DATETIME(1, 1, 1)
			|			THEN GoodsTable.DateOfReceipt
			|		ELSE GoodsTable.Date
			|	END AS Date,
			|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
			|	UNDEFINED AS Terms,
			|	GoodsTable.GoodsReceiptOption AS GoodsReceiptOption,
			|	GoodsTable.Warehouse AS Warehouse,
			|	GoodsTable.Warehouse AS Sender,
			|	GoodsTable.BusinessOperation AS BusinessOperation,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Purpose AS Purpose,
			|	GoodsTable.ToControlQuality AS ToControlQuality,
			|	FALSE AS RecordOfAPreviouslyReceivedLot,
			|	GoodsTable.ControlledLotReference AS ControlledLotReference,
			|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	FALSE AS ExceedingOrder,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Count AS Count,
			|	GoodsTable.CustomAssembly AS ReceiptUnderOrders,
			|	TRUE AS ThisIsAnInvoice
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&Ref)
			|	AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND GoodsTable.Status IN (VALUE(Enum.GoodsAssemblyStatuses.InProgress), VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled))";
		
		WarehousesServer.ScheduleGoodsReceipt(
			Query,
			QueryTexts,
			Registers,
			QueryTextDocument_,
			"GoodsTable");
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents
		And (DocumentObject.Status = Enums.GoodsAssemblyStatuses.InProgress
			Or DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled) Then
		// Disassembly for components.
		QueryTextDocument_ =
		"SELECT
		|	HeaderData_.Ref AS Ref,
		|	CASE
		|		WHEN HeaderData_.Patch
		|			THEN HeaderData_.CorrectedDocument
		|		ELSE HeaderData_.Ref
		|	END AS Invoice,
		|	HeaderData_.Patch AS Patch,
		|	HeaderData_.CorrectedDocument AS CorrectedDocument,
		|	HeaderData_.ByAssemblyDisassemblyOrder AS OrderDocument,
		|	CASE
		|		WHEN HeaderData_.DateOfReceipt <> DATETIME(1, 1, 1)
		|			THEN HeaderData_.DateOfReceipt
		|		ELSE HeaderData_.Date
		|	END AS Date,
		|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
		|	UNDEFINED AS Terms,
		|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
		|	HeaderData_.Warehouse AS Warehouse,
		|	HeaderData_.Warehouse AS Sender,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.ToControlQuality AS ToControlQuality,
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	HeaderData_.ControlledLotReference AS ControlledLotReference,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	HeaderData_.CustomAssembly
		|		AND GoodsTable.RowCode = 0 AS ExceedingOrder,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Count AS Count,
		|	HeaderData_.CustomAssembly AS ReceiptUnderOrders,
		|	TRUE AS ThisIsAnInvoice
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = GoodsTable.Ref)
		|WHERE
		|	GoodsTable.Ref IN(&Ref)
		|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND HeaderData_.Status IN (VALUE(Enum.GoodsAssemblyStatuses.InProgress), VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled))";	
		
		WarehousesServer.ScheduleGoodsReceipt(
			Query,
			QueryTexts,
			Registers,
			QueryTextDocument_,
			"GoodsTable");
	EndIf;
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject)

	RegisterName = "GoodsBatchMovement";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	PartsOfQueryText = New Array;

	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		// Assembly - arrival of the kit
		TextOfRequestPart = 
			"SELECT
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	CASE
			|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
			|			THEN GoodsTable.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END AS Purpose,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Count AS Count,
			|	GoodsTable.Warehouse AS Sender,
			|	GoodsTable.Warehouse AS Recipient,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS RecipientCharacteristic,
			|	VALUE(Enum.WarehouseTransactions.ReceivingOfAssembledSets) AS WarehouseOperation,
			|	GoodsTable.Ref AS Document,
			|	GoodsTable.Date AS Period,
			|	NOT GoodsTable.AdvancedWarehousingOnGoodsReceipt AS ThisIsWarehouseRecord
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|	AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);

		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Products,
			|	HeaderData_.Characteristic,
			|	CASE
			|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
			|			THEN GoodsTable.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END,
			|	GoodsTable.Series,
			|	GoodsTable.Count,
			|	HeaderData_.Warehouse,
			|	HeaderData_.Warehouse,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
			|	VALUE(Enum.WarehouseTransactions.ReceivingOfAssembledSets),
			|	HeaderData_.Ref,
			|	HeaderData_.Date,
			|	NOT HeaderData_.AdvancedWarehousingOnGoodsReceipt
			|FROM
			|	DocumentDataBatchTable AS GoodsTable
			|		INNER JOIN DocumentDataHeader AS HeaderData_
			|		ON GoodsTable.Ref = HeaderData_.Ref
			|			AND GoodsTable.Products = HeaderData_.Products
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);

		// Assembly - consumption of components
		TextOfRequestPart = 
			"SELECT
			|	GoodsTable.Products,
			|	GoodsTable.Characteristic,
			|	CASE
			|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
			|			THEN GoodsTable.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END,
			|	GoodsTable.Series,
			|	GoodsTable.Count,
			|	HeaderData_.Warehouse,
			|	HeaderData_.Products,
			|	HeaderData_.Characteristic,
			|	VALUE(Enum.WarehouseTransactions.ShipComponentsForAssembly),
			|	HeaderData_.Ref,
			|	HeaderData_.Date,
			|	NOT HeaderData_.AdvancedWarehousingOnShipment
			|FROM
			|	DocumentDataTableItems AS GoodsTable
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = GoodsTable.Ref)
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);

		TextOfRequestPart = 
			"SELECT
			|	MAX(GoodsTable.Products),
			|	MAX(GoodsTable.Characteristic),
			|	CASE
			|		WHEN ISNULL(MAX(GoodsTable.AssigningTrafficToWarehouseRegisters), FALSE)
			|			THEN MAX(GoodsTable.Purpose)
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END,
			|	MAX(GoodsTable.Series),
			|	MAX(GoodsTable.Count),
			|	HeaderData_.Warehouse,
			|	HeaderData_.Products,
			|	HeaderData_.Characteristic,
			|	VALUE(Enum.WarehouseTransactions.ShipComponentsForAssembly),
			|	HeaderData_.Ref,
			|	HeaderData_.Date,
			|	NOT HeaderData_.AdvancedWarehousingOnShipment
			|FROM
			|	DocumentDataBatchTable AS GoodsTable
			|		INNER JOIN DocumentDataTableItems AS RestrictionTable
			|		ON (RestrictionTable.Ref = GoodsTable.Ref)
			|			AND (RestrictionTable.Products = GoodsTable.Products)
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = GoodsTable.Ref)
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|
			|GROUP BY
			|	HeaderData_.Ref,
			|	GoodsTable.LineNumber,
			|	HeaderData_.Warehouse,
			|	HeaderData_.Products,
			|	HeaderData_.Characteristic,
			|	HeaderData_.Date,
			|	HeaderData_.AdvancedWarehousingOnShipment";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		// Disassembly - arrival of components
		TextOfRequestPart = 
			"SELECT
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	CASE
			|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
			|			THEN GoodsTable.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END AS Purpose,
			|	GoodsTable.Series AS Series,
			|	GoodsTable.Count AS Count,
			|	HeaderData_.Warehouse AS Sender,
			|	HeaderData_.Warehouse AS Recipient,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS RecipientCharacteristic,
			|	VALUE(Enum.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly) AS WarehouseOperation,
			|	HeaderData_.Ref AS Document,
			|	HeaderData_.Date AS Period,
			|	NOT HeaderData_.AdvancedWarehousingOnGoodsReceipt AS ThisIsWarehouseRecord
			|FROM
			|	DocumentDataTableItems AS GoodsTable
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = GoodsTable.Ref)
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);

		TextOfRequestPart = 
			"SELECT
			|	MAX(GoodsTable.Products),
			|	MAX(GoodsTable.Characteristic),
			|	CASE
			|		WHEN ISNULL(MAX(GoodsTable.AssigningTrafficToWarehouseRegisters), FALSE)
			|			THEN MAX(GoodsTable.Purpose)
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END,
			|	MAX(GoodsTable.Series),
			|	MAX(GoodsTable.Count),
			|	HeaderData_.Warehouse,
			|	HeaderData_.Warehouse,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
			|	VALUE(Enum.WarehouseTransactions.ReceivingOfComponentsAfterDisassembly),
			|	HeaderData_.Ref,
			|	HeaderData_.Date,
			|	NOT HeaderData_.AdvancedWarehousingOnShipment
			|FROM
			|	DocumentDataBatchTable AS GoodsTable
			|		INNER JOIN DocumentDataTableItems AS RestrictionTable
			|		ON (RestrictionTable.Ref = GoodsTable.Ref)
			|			AND (RestrictionTable.Products = GoodsTable.Products)
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = GoodsTable.Ref)
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|
			|GROUP BY
			|	HeaderData_.Ref,
			|	GoodsTable.LineNumber,
			|	HeaderData_.Warehouse,
			|	HeaderData_.Date,
			|	HeaderData_.AdvancedWarehousingOnShipment,
			|	HeaderData_.Warehouse";
		PartsOfQueryText.Add(TextOfRequestPart);

		// Disassembly - kit consumption
		TextOfRequestPart = 
			"SELECT
			|	GoodsTable.Products,
			|	GoodsTable.Characteristic,
			|	CASE
			|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
			|			THEN GoodsTable.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END,
			|	GoodsTable.Series,
			|	GoodsTable.Count,
			|	GoodsTable.Warehouse,
			|	UNDEFINED,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
			|	VALUE(Enum.WarehouseTransactions.ShipSetsForDisassembly),
			|	GoodsTable.Ref,
			|	GoodsTable.Date,
			|	NOT GoodsTable.AdvancedWarehousingOnShipment
			|FROM
			|	DocumentDataHeader AS GoodsTable
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
			|	AND GoodsTable.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);

		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Products,
			|	HeaderData_.Characteristic,
			|	CASE
			|		WHEN ISNULL(GoodsTable.AssigningTrafficToWarehouseRegisters, FALSE)
			|			THEN HeaderData_.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END,
			|	GoodsTable.Series,
			|	GoodsTable.Count,
			|	HeaderData_.Warehouse,
			|	UNDEFINED,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
			|	VALUE(Enum.WarehouseTransactions.ShipSetsForDisassembly),
			|	HeaderData_.Ref,
			|	HeaderData_.Date,
			|	NOT HeaderData_.AdvancedWarehousingOnShipment
			|FROM
			|	DocumentDataBatchTable AS GoodsTable
			|		INNER JOIN DocumentDataHeader AS HeaderData_
			|		ON GoodsTable.Ref = HeaderData_.Ref
			|			AND GoodsTable.Products = HeaderData_.Products
			|WHERE
			|	GoodsTable.Ref = &Ref
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	QueryText = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTTable(Query);
	
	QueryText = 
		"SELECT DISTINCT
		|	HeaderData_.Date AS DateOfReceipt,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	GoodsTable.CCDNumber AS CCDNumber
		|FROM
		|	TTTableKits AS GoodsTable
		|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
		|		ON GoodsTable.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
		|			AND GoodsTable.Products = UninvoicedReceipts.Products
		|			AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic
		|			AND GoodsTable.Series = UninvoicedReceipts.Series
		|			AND GoodsTable.Purpose = UninvoicedReceipts.Purpose
		|			AND GoodsTable.CCDNumber = UninvoicedReceipts.CCDNumber
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = GoodsTable.Ref)
		|WHERE
		|	(UninvoicedReceipts.DateOfReceipt IS NULL
		|			OR UninvoicedReceipts.DateOfReceipt < BEGINOFPERIOD(HeaderData_.Date, DAY))
		|	AND HeaderData_.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
		|
		|ORDER BY
		|	GoodsTable.InventoryOwnerAttribute,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series,
		|	GoodsTable.Purpose,
		|	GoodsTable.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParameterOfKitAnalyst(Query)
	
	If Query.Parameters.Property("KitAnalytics") Then
		Return;
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	FieldsStructure = New Structure("Products, Characteristic, Series, Warehouse, Purpose");
	FillPropertyValues(FieldsStructure, Query.Parameters);
	
	Query.SetParameter("KitAnalytics",
				InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(FieldsStructure));
	
	FieldsStructure.Purpose = Catalogs.Assignments.EmptyRef();
	
	Query.SetParameter("KitAnalyticsWithoutAssignment", 
		InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(FieldsStructure));
	
EndProcedure

Procedure SetStockTypeParameterOfAssembledKit(Query)
	
	If Query.Parameters.Property("TypeOfStockOfAssembledSet") Then
		Return;
	EndIf;
	
	RequestStockType = New Query;
	RequestStockType.Text = 
		"SELECT TOP 1
		|	AssemblyFromComponentsInventoryOwnerAttributesGoodsReceipt.InventoryOwnerAttribute
		|FROM
		|	Document.AssemblyFromComponents.InventoryOwnerAttributesGoodsReceipt AS AssemblyFromComponentsInventoryOwnerAttributesGoodsReceipt
		|WHERE
		|	AssemblyFromComponentsInventoryOwnerAttributesGoodsReceipt.Ref = &Ref
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";
	RequestStockType.SetParameter("Ref",                  Query.Parameters.Ref);
	RequestStockType.SetParameter("BusinessOperation",   Query.Parameters.BusinessOperation);
	
	Selection = RequestStockType.Execute().Select();
	Query.SetParameter("TypeOfStockOfAssembledSet",
		?(Selection.Next(), Selection.InventoryOwnerAttribute, Catalogs.InventoryKinds.EmptyRef()));
	
EndProcedure

Procedure InitializeTTTable(Query)
	
	If Query.Parameters.Property("TTTableSetsInitialized") Then
		Return;
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	QueryTTTableKits = New Query;
	QueryTTTableKits.TempTablesManager = Query.TempTablesManager;
	QueryTTTableKits.SetParameter("Ref",                  Query.Parameters.Ref);
	QueryTTTableKits.SetParameter("Period",                  Query.Parameters.Period);
	QueryTTTableKits.SetParameter("BusinessOperation",   Query.Parameters.BusinessOperation);
	QueryTTTableKits.SetParameter("MainComponentIsSpecified", Query.Parameters.MainComponentIsSpecified);
	QueryTTTableKits.SetParameter("Organization", Query.Parameters.Organization);
	
	CreateTTTableBatchAccountingAnalyst(QueryTTTableKits);
	
	QueryTTTableKits.Text = 
	"SELECT
	|	Goods.Ref AS Ref,
	|	MIN(Goods.LineNumber) AS LineNumber,
	|	""Goods"" AS TabularSectionName,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	SUM(Goods.CostShare) AS CostShare,
	|	SUM(Goods.Count) AS Count,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTDocumentProducts_
	|FROM
	|	DocumentDataTableItems AS Goods
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON (HeaderData_.Ref = Goods.Ref)
	|WHERE
	|	Goods.Ref = &Ref
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.ItemsLocationAttributes
	|
	|UNION ALL
	|
	|SELECT
	|	Header.Ref,
	|	0,
	|	""Header"",
	|	Header.Products,
	|	Header.Characteristic,
	|	Header.Purpose,
	|	Header.Series,
	|	1,
	|	Header.Count,
	|	Header.ItemsLocationAttributes
	|FROM
	|	DocumentDataHeader AS Header
	|WHERE
	|	Header.Ref = &Ref
	|	AND Header.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentGoods.Ref AS Ref,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Purpose AS Purpose,
	|	DocumentGoods.Series AS Series,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	DocumentGoods.Count AS Count,
	|	DocumentGoods.CostShare AS CostShare,
	|	DocumentGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	0 AS QuantityByGBRN,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|FROM
	|	TTDocumentProducts_ AS DocumentGoods
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON DocumentGoods.LineNumber = TableOfBatchAccountingAnalysts.LineNumber
	|			AND DocumentGoods.TabularSectionName = TableOfBatchAccountingAnalysts.TabularSectionName
	|ORDER BY
	|	DocumentGoods.ItemsLocationAttributes,
	|	DocumentGoods.Count DESC
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	CASE
	|		WHEN TableTypesOfStocks_.QuantityByGBRN > 0
	|			THEN CAST(TableTypesOfStocks_.QuantityByGBRN / TableTypesOfStocks_.Count AS NUMBER(23, 11))
	|		ELSE
	|			0
	|	END AS RNPTCoefficient
	|FROM
	|	DataOfDocumentTableOfInventoryOwnerAttributes AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDocumentProducts_";
	
	// It is required to connect the data tables of the document table with the Order entry and the document item.
	// The connection in the request is difficult to implement due to the presence of a scenario with one product but different series in
	// Vttovarydocument and various CCD (RNPT) In this Document, the table shows the occurrence (many to many).
	
	Result = QueryTTTableKits.ExecuteBatch();
	ProductsToFillIn_ = Result[1].Unload();
	TypesOfStocksForDistribution = Result[2].Unload();
	TypesOfStocksForDistribution.Indexes.Add("ItemsLocationAttributes");
	
	// Without explicit typing of the value table, when it is further loaded into the temporary query table
	// , the accuracy of numeric fields will be cut off to 9 characters.
	Qualifier = New NumberQualifiers(23, 11);
	ProductsToFillIn_.Columns.QuantityByGBRN.Name = "QuantityAccordingToProductBatchIDWithoutTyping";
	ProductsToFillIn_.Columns.Add("QuantityByGBRN", New TypeDescription("Number", Qualifier));
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	For IndexOf = 0 To ProductsToFillIn_.Count() - 1 Do
		ItemToFillIn = ProductsToFillIn_[IndexOf];
		FillPropertyValues(TheStructureOfTheSearch, ItemToFillIn);
		FoundRows = TypesOfStocksForDistribution.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() = 0 Then
			ItemToFillIn.Count = 0;
			ItemToFillIn.QuantityByGBRN = 0;
			Continue;
		EndIf;
		
		InitialQuantity_ = ItemToFillIn.Count;
		
		For Each FoundRow In FoundRows Do
			If FoundRow.Count = 0 Then
				Continue;
			EndIf;
			If InitialQuantity_ = 0 Then
				Continue;
			EndIf;
			
			FillPropertyValues(ItemToFillIn, FoundRow, "InventoryOwnerAttribute, CCDNumber");
			If ItemToFillIn.Count = FoundRow.Count Then
				FillPropertyValues(ItemToFillIn, FoundRow, "Count, QuantityByGBRN");
				ItemToFillIn.CostShare = ItemToFillIn.CostShare * FoundRow.Count / ItemToFillIn.Count;
				
				FoundRow.Count = 0;
				FoundRow.QuantityByGBRN = 0;
				
				InitialQuantity_ = 0;
			ElsIf ItemToFillIn.Count < FoundRow.Count Then
				ItemToFillIn.QuantityByGBRN = ItemToFillIn.Count * FoundRow.RNPTCoefficient;
				ItemToFillIn.CostShare = ItemToFillIn.CostShare * FoundRow.Count / ItemToFillIn.Count;
				InitialQuantity_ = 0;
				
				FoundRow.Count = FoundRow.Count - ItemToFillIn.Count;
				FoundRow.QuantityByGBRN = FoundRow.QuantityByGBRN - ItemToFillIn.QuantityByGBRN;
			ElsIf ItemToFillIn.Count > FoundRow.Count Then
				// Select a new row at the end of the table to be filled, taking it out of the processing cycle.
				// The Cur line, on the contrary, can still be processed in the next iteration according to the found lines of stock types.
				NewLineProducts = ProductsToFillIn_.Add();
				FillPropertyValues(NewLineProducts, ItemToFillIn);
				FillPropertyValues(NewLineProducts, FoundRow, "Count, QuantityByGBRN");
				NewLineProducts.CostShare = NewLineProducts.CostShare * FoundRow.Count / NewLineProducts.Count;
				InitialQuantity_ = InitialQuantity_ - NewLineProducts.Count;
				
				ItemToFillIn.Count = ItemToFillIn.Count - FoundRow.Count;
				ItemToFillIn.QuantityByGBRN = ItemToFillIn.QuantityByGBRN - FoundRow.QuantityByGBRN;
			EndIf;
		EndDo;
	EndDo;
	
	TTQueryResultSetsTable = New Query();
	TTQueryResultSetsTable.TempTablesManager = QueryTTTableKits.TempTablesManager;
	TTQueryResultSetsTable.Text = 
	"SELECT
	|	DocumentGoods.Ref AS Ref,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Purpose AS Purpose,
	|	DocumentGoods.Series AS Series,
	|	DocumentGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DocumentGoods.CCDNumber AS CCDNumber,
	|	DocumentGoods.LotVendorAttributes AS LotVendorAttributes,
	|	DocumentGoods.Count AS Count,
	|	DocumentGoods.QuantityByGBRN AS QuantityByGBRN,
	|	DocumentGoods.CostShare AS CostShare,
	|	DocumentGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTTableKits
	|FROM
	|	&TTDocumentProducts_ AS DocumentGoods";
	TTQueryResultSetsTable.SetParameter("TTDocumentProducts_", ProductsToFillIn_);
	TTQueryResultSetsTable.Execute();
	
	Query.SetParameter("TTTableSetsInitialized", True);
	
EndProcedure

Procedure InitializeBusinessProducts(Query)
	
	If Query.Parameters.Property("BusinessProductsInitialized") Then
		Return;
	EndIf;
	
	InitializeTTTable(Query);
	InitializeTTInventoryTypes(Query);
	SetRequestParameterOfKitAnalyst(Query);
	SetStockTypeParameterOfAssembledKit(Query);
	
	RequestForGoods = New Query;
	RequestForGoods.TempTablesManager = Query.TempTablesManager;
	RequestForGoods.SetParameter("Ref",                  Query.Parameters.Ref);
	RequestForGoods.SetParameter("BusinessOperation",   Query.Parameters.BusinessOperation);
	RequestForGoods.SetParameter("MainComponentIsSpecified", Query.Parameters.MainComponentIsSpecified);
	RequestForGoods.SetParameter("Period",                  Query.Parameters.Period);
	RequestForGoods.SetParameter("Warehouse",                   Query.Parameters.Warehouse);
	RequestForGoods.SetParameter("Organization",             Query.Parameters.Organization);
	RequestForGoods.SetParameter("AssemblyForActivity",   Query.Parameters.AssemblyForActivity);
	RequestForGoods.SetParameter("TypeOfKitStock",      Query.Parameters.TypeOfStockOfAssembledSet);
	RequestForGoods.SetParameter("KitAnalytics",      Query.Parameters.KitAnalytics);
	RequestForGoods.SetParameter("Status",                  Query.Parameters.Status);
	RequestForGoods.Text = 
	"SELECT
	|	&Ref                                  AS Ref,
	|	GoodsTable.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Period                                  AS Period,
	|	&Warehouse                                   AS Warehouse,
	|	&Organization                             AS ShipmentCompany,
	|	&Organization                             AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	GoodsTable.Products               AS Products,
	|	GoodsTable.Characteristic             AS Characteristic,
	|	GoodsTable.CCDNumber                   AS CCDNumber,
	|	GoodsTable.Count                 AS Count,
	|	GoodsTable.QuantityByGBRN           AS QuantityByGBRN,
	|	&BusinessOperation                   AS BusinessOperation,
	|	UNDEFINED                             AS VATTaxation,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UNDEFINED                             AS CorInventoryOwnerAttribute,
	|	UNDEFINED                             AS CorItemsLocationAttributes,
	|
	|	UNDEFINED                             AS InitialStockView,
	|	UNDEFINED                             AS CommitteeProductAnalysis,
	|	TRUE                                   AS Primary,
	|	GoodsTable.CostShare              AS CostShare,
	|	
	|	""""                                     AS RowID
	|	
	|FROM
	|	TTTableKits AS GoodsTable
	|WHERE
	|	&Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref,
	|	TableTypesOfStocks_.LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period,
	|	&Warehouse,
	|	&Organization AS ShipmentCompany,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.CCDNumber,
	|	TableTypesOfStocks_.Count,
	|	TableTypesOfStocks_.QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	(CASE TableTypesOfStocks_.InventoryType
	|		WHEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN UNDEFINED
	|		ELSE CASE &BusinessOperation
	|			WHEN VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN &TypeOfKitStock
	|			ELSE UNDEFINED END
	|		END) AS CorInventoryOwnerAttribute,
	|	(CASE &BusinessOperation
	|		WHEN VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN &KitAnalytics
	|		ELSE UNDEFINED END)AS CorItemsLocationAttributes,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InitialStockView,
	|	TableTypesOfStocks_.CommitteeProductAnalysis,
	|	FALSE AS Primary,
	|	1 AS CostShare,
	|	
	|	TableTypesOfStocks_.RowID AS RowID
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|ORDER BY
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	InventoryOwnerAttribute,
	|	CCDNumber";
	
	Result = RequestForGoods.ExecuteBatch();
	
	TableProductsOfOrganizations = Result[0].Unload();
	FillInCorAnalysisOfNomeclatureAccounting(TableProductsOfOrganizations, Query.Parameters);
	
	RequestForGoods.SetParameter("TableProductsOfOrganizations", TableProductsOfOrganizations);
	RequestForGoods.Text = 
	"SELECT
	|	CompanyGoods.Ref,
	|	CompanyGoods.LineNumber,
	|	CompanyGoods.RecordType,
	|	CompanyGoods.Period,
	|	CompanyGoods.Warehouse,
	|	CompanyGoods.ShipmentCompany,
	|	CompanyGoods.Organization,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.Products,
	|	CompanyGoods.Characteristic,
	|	CompanyGoods.CCDNumber,
	|	CompanyGoods.Count,
	|	CompanyGoods.QuantityByGBRN,
	|	CompanyGoods.BusinessOperation,
	|	CompanyGoods.VATTaxation,
	|	CompanyGoods.ItemsLocationAttributes,
	|	CompanyGoods.CorInventoryOwnerAttribute,
	|	CompanyGoods.CorItemsLocationAttributes,
	|	CompanyGoods.InitialStockView,
	|	CompanyGoods.CommitteeProductAnalysis,
	|	CompanyGoods.Primary,
	|	CompanyGoods.CostShare,
	|	CompanyGoods.RowID
	|INTO TTProductsOfOrganizations
	|FROM
	|	&TableProductsOfOrganizations AS CompanyGoods";
	
	RequestForGoods.ExecuteBatch();
	
	Query.SetParameter("BusinessProductsInitialized", True);
	
EndProcedure

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeBusinessProducts(Query);
	
	QueryText =
	"SELECT
	|	CompanyGoods.LineNumber,
	|	CompanyGoods.RecordType,
	|	CompanyGoods.Period,
	|	CompanyGoods.Warehouse,
	|	CompanyGoods.ShipmentCompany,
	|	CompanyGoods.Organization,
	|	CompanyGoods.InventoryOwnerAttribute,
	|	CompanyGoods.Products,
	|	CompanyGoods.Characteristic,
	|	CompanyGoods.CCDNumber,
	|	CompanyGoods.Count,
	|	CompanyGoods.QuantityByGBRN,
	|	CompanyGoods.BusinessOperation,
	|	CompanyGoods.VATTaxation,
	|	CompanyGoods.ItemsLocationAttributes,
	|	CompanyGoods.CorInventoryOwnerAttribute,
	|	CompanyGoods.CorItemsLocationAttributes,
	|	CompanyGoods.Primary,
	|	CompanyGoods.CostShare
	|FROM
	|	TTProductsOfOrganizations AS CompanyGoods";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTInventoryTypes(Query);
	
	QueryText =
		"SELECT
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	HeaderData_.Date AS Period,
		|	HeaderData_.Warehouse AS Warehouse,
		|	TableTypesOfStocks_.OwnerSInventoryOwnersAttributesOfOwnerCompany AS CompanyOwner,
		|	TableTypesOfStocks_.Products AS Products,
		|	TableTypesOfStocks_.Characteristic AS Characteristic,
		|	TableTypesOfStocks_.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
		|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
		|	TableTypesOfStocks_.Count AS Count,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes
		|FROM
		|	TTTypesOfStocks AS TableTypesOfStocks_
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)
		|WHERE
		|	TableTypesOfStocks_.SaleOfAnotherCompanyInventory
		|
		|ORDER BY
		|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)

	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	InitializeTTInventoryTypes(Query);

	If Not Query.Parameters.Property("BusinessProductsInitialized") Then
		InitializeBusinessProducts(Query);
	EndIf;

	QueryText = 
		"SELECT
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	HeaderData_.Date AS Period,
		|	&Organization AS Organization,
		|	InventoryKinds.Currency AS Currency,
		|	InventoryKinds.Ref AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.Products AS Products,
		|	TableTypesOfStocks_.Characteristic AS Characteristic,
		|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	0 AS Count,
		|	TableTypesOfStocks_.Count AS QuantityConsumed,
		|	0 AS RevenueAmount,
		|	0 AS RevenueAmountExclVATLocal,
		|	0 AS RevenueAmountMan,
		|	0 AS QuantityToRegister,
		|	0 AS QuantityForRegistrationByProductBatchID,
		|	TableTypesOfStocks_.Count AS QuantityConsumedForIncoiceRegistration,
		|	TableTypesOfStocks_.QuantityByGBRN AS QuantityIsWrittenOffForRegistrationByProductBatchID,
		|	0 AS RevenueAmountToRegister,
		|	TableTypesOfStocks_.CommitteeProductAnalysis AS ItemsLocationAttributes,
		|	TableTypesOfStocks_.CorItemsLocationAttributes AS CorItemsLocationAttributes,
		|	TableTypesOfStocks_.RowID AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff) AS BusinessTransactionSetting,
		|	TableTypesOfStocks_.RowID AS RowID
		|FROM
		|	TTProductsOfOrganizations AS TableTypesOfStocks_
		|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
		|		ON (InventoryKinds.Ref = TableTypesOfStocks_.InitialStockView)
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)
		|WHERE
		|	InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|
		|ORDER BY
		|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeTTInventoryTypes(Query)
	
	If Query.Parameters.Property("TTInventoryTypesInitialized") Then
		Return;
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	RequestTTTypesOfStock = New Query;
	RequestTTTypesOfStock.TempTablesManager = Query.TempTablesManager;
	RequestTTTypesOfStock.SetParameter("Ref",                  Query.Parameters.Ref);
	RequestTTTypesOfStock.SetParameter("AssemblyForActivity",   Query.Parameters.AssemblyForActivity);
	
	RequestTTTypesOfStock.Text = 
	"SELECT
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TypesOfOwnerStocks.Ref AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TypesOfOwnerStocks.Organization AS OwnerSInventoryOwnersAttributesOfOwnerCompany,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	CommitteeAnalytics.DimensionKey AS CommitteeProductAnalysis,
	|	Dimension.Products AS Products,
	|	ISNULL(Dimension.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	Dimension.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(Dimension.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN Dimension.Purpose.VATActivityType
	|		ELSE &AssemblyForActivity
	|	END AS VATActivityType,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.RowID AS RowID
	|INTO TTTypesOfStocks
	|FROM
	|	DataOfDocumentTableOfInventoryOwnerAttributesWriteOff AS TableTypesOfStocks_
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|			ON (TypesOfOwnerStocks.Ref = InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner)
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = InventoryKinds.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON (Dimension.Products = AnalyticsWithoutAssignment.Products)
	|			AND (Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic)
	|			AND (Dimension.Series = AnalyticsWithoutAssignment.Series)
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND (Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|		ON (Dimension.Products = CommitteeAnalytics.Products)
	|			AND (Dimension.Characteristic = CommitteeAnalytics.Characteristic)
	|			AND (VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series)
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose)
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeAnalytics.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";

	RequestTTTypesOfStock.ExecuteBatch();
	
	Query.SetParameter("TTInventoryTypesInitialized", True);

EndProcedure

Procedure PerformDistributionOfCostOfComponentsOnSets(Query)
	
	If Query.Parameters.Property("CostOfComponentsForKitsIsDistributed") Then
		Return;
	EndIf;
	
	SetRequestParameterOfKitAnalyst(Query);
	InitializeProductAnalysisKeys(Query);
	InitializeTTInventoryTypes(Query);
	
	DistributionRequest = New Query;
	DistributionRequest.TempTablesManager = Query.TempTablesManager;
	DistributionRequest.SetParameter("Ref",                Query.Parameters.Ref);
	DistributionRequest.SetParameter("Period",                Query.Parameters.Period);
	DistributionRequest.SetParameter("KitAnalytics",    Query.Parameters.KitAnalytics);
	DistributionRequest.SetParameter("KitAnalyticsWithoutAssignment", Query.Parameters.KitAnalyticsWithoutAssignment);
	DistributionRequest.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	DistributionRequest.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", 
	                                                                Query.Parameters.GenerateInventoryOwnerAttributesByFinancialAccountingGroups);
	DistributionRequest.SetParameter("Organization",           Query.Parameters.Organization);
	DistributionRequest.SetParameter("LineOfBusiness", Query.Parameters.LineOfBusiness);
	DistributionRequest.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	CreateTTTableBatchAccountingAnalyst(DistributionRequest);
	
	DistributionRequest.Text = 
	// When assembling
	"SELECT DISTINCT
	|	InventoryOwnerAttributesGoodsReceipt.ItemsLocationAttributes,
	|	InventoryOwnerAttributesGoodsReceipt.InventoryOwnerAttribute
	|INTO TTInventoryTypesRegistration
	|FROM
	|	DataOfDocumentTableOfInventoryOwnerAttributes AS InventoryOwnerAttributesGoodsReceipt
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1 AS DocumentRowNumber,
	|	&Period AS Period,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN &KitAnalytics
	|		ELSE &KitAnalyticsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN DocumentData.Warehouse.ShopFloorStockroom
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS AccountingSection,
	|	
	|	CatInventoryKinds.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	1 AS CostShare,
	|	DocumentData.Count AS Count,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE 
	|		DocumentData.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	CASE WHEN CatInventoryKinds.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END AS AnalysisOfSettlementsWithCommittee,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	(CASE
	|		WHEN ISNULL(DocumentData.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentData.Purpose.VATActivityType
	|		ELSE DocumentData.AssemblyForActivity
	|	END) AS VATActivityType,
	|	"""" AS RowID
	|FROM
	|	DocumentDataHeader AS DocumentData
	|
	|	LEFT JOIN TTInventoryTypesRegistration AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = DocumentData.ItemsLocationAttributes
	|
	|	INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON CatInventoryKinds.Ref = TableTypesOfStocks_.InventoryOwnerAttribute
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = DocumentData.Organization
	|		AND AnalysisOfCalculations.Partner = CatInventoryKinds.GoodsOwner
	|		AND AnalysisOfCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfCalculations.LineOfBusiness = DocumentData.LineOfBusiness
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = DocumentData.Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfIntercampaniCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = DocumentData.LineOfBusiness
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 		= 0
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Header""
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) // When assembling
	|
	|UNION ALL
	|
	// During disassembly
	|SELECT
	|	GoodsTable.LineNumber AS DocumentRowNumber,
	|	&Period AS Period,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END AS ItemsLocationAttributes,
	|	&LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN DocumentData.Warehouse.ShopFloorStockroom
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS AccountingSection,
	|	
	|	CatInventoryKinds.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.CostShare AS CostShare,
	|	GoodsTable.Count AS Count,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE 
	|		GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	CASE WHEN CatInventoryKinds.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END AS AnalysisOfSettlementsWithCommittee,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	(CASE
	|		WHEN ISNULL(GoodsTable.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|				<> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN GoodsTable.Purpose.VATActivityType
	|		ELSE DocumentData.AssemblyForActivity
	|	END) AS VATActivityType,
	|	GoodsTable.RowID AS RowID
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = GoodsTable.Ref
	|
	|	LEFT JOIN TTInventoryTypesRegistration AS TableTypesOfStocks_
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = GoodsTable.ItemsLocationAttributes
	|
	|	INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON CatInventoryKinds.Ref = TableTypesOfStocks_.InventoryOwnerAttribute
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = DocumentData.Organization
	|		AND AnalysisOfCalculations.Partner = CatInventoryKinds.GoodsOwner
	|		AND AnalysisOfCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfCalculations.LineOfBusiness = DocumentData.LineOfBusiness
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = DocumentData.Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfIntercampaniCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = DocumentData.LineOfBusiness
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) // During disassembly
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(TableTypesOfStocks_.LineNumber) AS DocumentRowNumber,
	|	&Period AS Period,
	|	1 AS CostShare,
	|	CASE 
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			TableTypesOfStocks_.CommitteeProductAnalysis
	|		ELSE
	|			CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN TableTypesOfStocks_.ItemsLocationAttributes
	|				ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|			END
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN Dimension.StorageLocation.ShopFloorStockroom AND CatInventoryKinds.InventoryType <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS AccountingSection,
	|	
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS AnalyticsForDebitingAccounts,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS TypeOfInventoryWriteOffs,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			UNDEFINED
	|		ELSE
	|			TableTypesOfStocks_.InventoryOwnerAttribute
	|		END
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	SUM(TableTypesOfStocks_.Count) AS Count,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	CASE WHEN CatInventoryKinds.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END AS AnalysisOfSettlementsWithCommittee
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|	INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|	ON CatInventoryKinds.Ref = TableTypesOfStocks_.InventoryOwnerAttribute
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Partner = CatInventoryKinds.GoodsOwner
	|		AND AnalysisOfCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfCalculations.LineOfBusiness = &LineOfBusiness
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = &Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = CatInventoryKinds.Counterparty
	|		AND AnalysisOfIntercampaniCalculations.Contract = CatInventoryKinds.Contract
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = &LineOfBusiness
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),
	|										VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND TableTypesOfStocks_.Count > 0
	|GROUP BY
	|	CASE 
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			TableTypesOfStocks_.CommitteeProductAnalysis
	|		ELSE
	|			CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN TableTypesOfStocks_.ItemsLocationAttributes
	|				ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|			END
	|	END,
	|	TableTypesOfStocks_.LineOfBusiness,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END,
	|	
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryType,
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			UNDEFINED
	|		ELSE
	|			TableTypesOfStocks_.InventoryOwnerAttribute
	|		END
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END,
	|	CASE WHEN CatInventoryKinds.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END,
	|	CASE WHEN Dimension.StorageLocation.ShopFloorStockroom AND CatInventoryKinds.InventoryType <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END
	|
	|ORDER BY
	|	DocumentRowNumber";
	
	Result = DistributionRequest.ExecuteBatch();
	
	Allocation = DistributeCostOfComponentsToKits(
		Result[1].Unload(),
		Result[2].Unload(),
		Query.Parameters);
	
	DistributionRequest.SetParameter("TableCostOfGoods", Allocation.TableCostOfGoods);
	DistributionRequest.SetParameter("TableOfMotionProductsProducts",
		Allocation.TableOfMotionProductsProducts);
	DistributionRequest.Text = 
	"SELECT
	|	TableCostOfGoods.Period,
	|	TableCostOfGoods.Recorder,
	|	TableCostOfGoods.LineNumber,
	|	TableCostOfGoods.RecordType,
	|	TableCostOfGoods.ItemsLocationAttributes,
	|	TableCostOfGoods.AccountingSection,
	|	TableCostOfGoods.InventoryOwnerAttribute,
	|	TableCostOfGoods.Organization,
	|	TableCostOfGoods.Count,
	|	TableCostOfGoods.Cost,
	|	TableCostOfGoods.CostExcludingVAT,
	|	TableCostOfGoods.AddExpensesForGoods,
	|	TableCostOfGoods.AdditionalExpensesExcludingVAT,
	|	TableCostOfGoods.LocalCost,
	|	TableCostOfGoods.PermanentDifference,
	|	TableCostOfGoods.CostTD,
	|	TableCostOfGoods.BusinessOperation,
	|	TableCostOfGoods.CorItemsLocationAttributes,
	|	TableCostOfGoods.CorAccountingSection,
	|	TableCostOfGoods.CorInventoryOwnerAttribute,
	|	TableCostOfGoods.CorCompany,
	|	TableCostOfGoods.CorGrossInitialCostENT,
	|	TableCostOfGoods.AccountingDimensionByPartners,
	|	TableCostOfGoods.SalesOrder,
	|	TableCostOfGoods.Department,
	|	TableCostOfGoods.DimensionOfExpenses,
	|	TableCostOfGoods.ExpenseItemOfWriteOff,
	|	TableCostOfGoods.IncomeItem,
	|	TableCostOfGoods.DimensionOfRevenue,
	|	TableCostOfGoods.SalePeriod,
	|	TableCostOfGoods.AssetAndLiabilityItem,
	|	TableCostOfGoods.AssetsLiabilitiesDimension,
	|	TableCostOfGoods.DocumentRegisterRecords,
	|	TableCostOfGoods.RowID,
	|	TableCostOfGoods.ProductsGroup,
	//	batch accounting version 2.2
	|	TableCostOfGoods.Lot,
	|	TableCostOfGoods.LotVendorAttributes,
	|	TableCostOfGoods.FinancialAccountingDimension,
	|	TableCostOfGoods.VATActivityType,
	|	TableCostOfGoods.CorLot,
	|	TableCostOfGoods.LotVendorAttributesCorr,
	|	TableCostOfGoods.CorControllingAttributes,
	|	TableCostOfGoods.CorVATActivityTypes,
	|	TableCostOfGoods.EntryType,
	|
	|	TableCostOfGoods.FinRecordID
	|
	|INTO TTTableCostOfGoods
	|FROM
	|	&TableCostOfGoods AS TableCostOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfMotionProductsProducts.Period,
	|	TableOfMotionProductsProducts.Recorder,
	|	TableOfMotionProductsProducts.LineNumber,
	|	TableOfMotionProductsProducts.BusinessOperation,
	|	TableOfMotionProductsProducts.Organization,
	|	TableOfMotionProductsProducts.Department,
	|	TableOfMotionProductsProducts.ItemsLocationAttributes,
	|	TableOfMotionProductsProducts.LineOfBusiness,
	|	TableOfMotionProductsProducts.Warehouse,
	|	TableOfMotionProductsProducts.InventoryType,
	|	TableOfMotionProductsProducts.InventoryOwnerAttribute,
	|	TableOfMotionProductsProducts.CorItemsLocationAttributes,
	|	TableOfMotionProductsProducts.CorLineOfBusiness,
	|	TableOfMotionProductsProducts.CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableOfMotionProductsProducts.CorInventoryType,
	|	TableOfMotionProductsProducts.CorInventoryOwnerAttribute,
	|	TableOfMotionProductsProducts.Count,
	|	TableOfMotionProductsProducts.CorQuantity,
	|	TableOfMotionProductsProducts.Cost,
	|	TableOfMotionProductsProducts.CostExcludingVAT,
	|	TableOfMotionProductsProducts.LocalCost,
	|	TableOfMotionProductsProducts.SourceOfProductFinancialAccountingGroup,
	|	TableOfMotionProductsProducts.CorSourceOfItemsFinancialAccountingGroup,
	|	TableOfMotionProductsProducts.DocumentRegisterRecords,
	|	TableOfMotionProductsProducts.CorCompany
	|INTO TTTableOfMotionProductsProducts
	|FROM
	|	&TableOfMotionProductsProducts AS TableOfMotionProductsProducts";

	Result = DistributionRequest.ExecuteBatch();
	
	Query.SetParameter("CostOfComponentsForKitsIsDistributed", True);
	
EndProcedure

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	InitializeTTTable(Query);
	InitializeProductAnalysisKeys(Query);
	
	QueryText = "
	| SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Warehouse                                 AS Warehouse,
	|	&Organization                           AS Organization,
	|	DimensionKeys.DimensionKey           AS ItemsLocationAttributes,
	|	&Ref                                AS DocumentInflow,
	|	GoodsTable.InventoryOwnerAttribute               AS InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes     AS LotVendorAttributes,
	|	SUM(GoodsTable.Count)        AS Count,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	&BusinessOperation                 AS BusinessOperation,
	|	TRUE                                 AS Primary,
	|	&Ref                                AS DocumentSource
	|FROM
	|	TTTableKits AS GoodsTable
	|		
	|		LEFT JOIN 
	|			InformationRegister.ItemsLocationAttributes AS DimensionKeys
	|		ON 
	|			GoodsTable.Products = DimensionKeys.Products
	|			AND GoodsTable.Characteristic = DimensionKeys.Characteristic
	|			AND GoodsTable.Purpose = DimensionKeys.Purpose
	|			AND GoodsTable.Series = DimensionKeys.Series
	|			AND (&Warehouse = DimensionKeys.StorageLocation)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionKeys.ProductCostElement
	|WHERE
	|	&Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
	|	AND &BatchAccountingVersion21
	|GROUP BY
	|	DimensionKeys.DimensionKey,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	PerformDistributionOfCostOfComponentsOnSets(Query);
	
	QueryText =
	"SELECT
	|	TableOfMotionProductsProducts.Period,
	|	TableOfMotionProductsProducts.Recorder,
	|	TableOfMotionProductsProducts.LineNumber,
	|	TableOfMotionProductsProducts.BusinessOperation,
	|	TableOfMotionProductsProducts.Organization,
	|	TableOfMotionProductsProducts.Department,
	|	TableOfMotionProductsProducts.ItemsLocationAttributes,
	|	TableOfMotionProductsProducts.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableOfMotionProductsProducts.Warehouse,
	|	TableOfMotionProductsProducts.InventoryType,
	|	TableOfMotionProductsProducts.InventoryOwnerAttribute,
	|	TableOfMotionProductsProducts.CorItemsLocationAttributes,
	|	TableOfMotionProductsProducts.CorItemsLocationAttributes.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	TableOfMotionProductsProducts.CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableOfMotionProductsProducts.CorInventoryType,
	|	TableOfMotionProductsProducts.CorInventoryOwnerAttribute,
	|	TableOfMotionProductsProducts.Count,
	|	TableOfMotionProductsProducts.CorQuantity,
	|	TableOfMotionProductsProducts.Cost,
	|	TableOfMotionProductsProducts.CostExcludingVAT,
	|	TableOfMotionProductsProducts.LocalCost,
	|	TableOfMotionProductsProducts.SourceOfProductFinancialAccountingGroup,
	|	TableOfMotionProductsProducts.CorSourceOfItemsFinancialAccountingGroup,
	|	TableOfMotionProductsProducts.DocumentRegisterRecords,
	|	TableOfMotionProductsProducts.CorCompany
	|FROM
	|	TTTableOfMotionProductsProducts AS TableOfMotionProductsProducts";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
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
	|	&BusinessOperation                  AS BusinessOperation,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS Counterparty,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	UNDEFINED                            AS Currency,
	|	0                                       AS Sum,
	|	&Status                                 AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	""""                                    AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject)
	
	PartsOfQueryText = New Array;

	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	CASE
			|		WHEN HeaderData_.CustomAssembly
			|			THEN HeaderData_.ByAssemblyDisassemblyOrder
			|		ELSE UNDEFINED
			|	END AS OrderDocument,
			|	DocumentGoods.Ref AS Invoice,
			|	HeaderData_.Patch AS Patch,
			|	HeaderData_.CorrectedDocument AS CorrectedDocument,
			|	HeaderData_.Warehouse AS Recipient,
			|	HeaderData_.Warehouse AS Warehouse,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	DocumentGoods.Series AS Series,
			|	DocumentGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	DocumentGoods.Count AS Count,
			|	FALSE AS ExceedingOrder,
			|	FALSE AS Canceled,
			|	TRUE AS ThisIsAnInvoice,
			|	HeaderData_.CustomAssembly AS ShipmentByOrder
			|FROM
			|	DocumentDataTableItems AS DocumentGoods
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON DocumentGoods.Ref = HeaderData_.Ref
			|WHERE
			|	DocumentGoods.Ref IN(&Ref)
			|	AND DocumentGoods.Count <> 0
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.Count <> 0
			And DocumentObject.BatchesIndicationStatus <> 10
			And DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents) Then
		TextOfRequestPart = 
			"SELECT
			|	DocumentGoods.Ref AS Ref,
			|	DocumentGoods.Date AS Period,
			|	CASE
			|		WHEN DocumentGoods.CustomAssembly
			|			THEN DocumentGoods.ByAssemblyDisassemblyOrder
			|		ELSE UNDEFINED
			|	END AS OrderDocument,
			|	DocumentGoods.Ref AS Invoice,
			|	DocumentGoods.Patch AS Patch,
			|	DocumentGoods.CorrectedDocument AS CorrectedDocument,
			|	DocumentGoods.Warehouse AS Recipient,
			|	DocumentGoods.Warehouse AS Warehouse,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	DocumentGoods.Series AS Series,
			|	DocumentGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	DocumentGoods.Count AS Count,
			|	FALSE AS ExceedingOrder,
			|	FALSE AS Canceled,
			|	TRUE AS ThisIsAnInvoice,
			|	DocumentGoods.CustomAssembly AS ShipmentByOrder
			|FROM
			|	DocumentDataHeader AS DocumentGoods
			|WHERE
			|	DocumentGoods.Ref IN(&Ref)
			|	AND DocumentGoods.Count <> 0
			|	AND DocumentGoods.BatchesIndicationStatus <> 10
			|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.BatchesIndicationStatus = 10
			And DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents) Then
		TextOfRequestPart = 
			"SELECT
			|	DocumentGoods.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	CASE
			|		WHEN HeaderData_.CustomAssembly
			|			THEN HeaderData_.ByAssemblyDisassemblyOrder
			|		ELSE UNDEFINED
			|	END AS OrderDocument,
			|	DocumentGoods.Ref AS Invoice,
			|	HeaderData_.Patch AS Patch,
			|	HeaderData_.CorrectedDocument AS CorrectedDocument,
			|	HeaderData_.Warehouse AS Recipient,
			|	HeaderData_.Warehouse AS Warehouse,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	DocumentGoods.Series AS Series,
			|	HeaderData_.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	DocumentGoods.Count AS Count,
			|	FALSE AS ExceedingOrder,
			|	FALSE AS Canceled,
			|	TRUE AS ThisIsAnInvoice,
			|	HeaderData_.CustomAssembly AS ShipmentByOrder
			|FROM
			|	DocumentDataBatchTable AS DocumentGoods
			|		INNER JOIN DocumentDataHeader AS HeaderData_
			|		ON DocumentGoods.Ref = HeaderData_.Ref
			|			AND DocumentGoods.Products = HeaderData_.Products
			|			AND DocumentGoods.Characteristic = HeaderData_.Characteristic
			|			AND DocumentGoods.Purpose = HeaderData_.Purpose
			|WHERE
			|	DocumentGoods.Ref IN(&Ref)
			|	AND DocumentGoods.Count <> 0
			|	AND HeaderData_.BatchesIndicationStatus = 10
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;
	
	If PartsOfQueryText.Count() = 0 Then
		Return;
	EndIf;

	TextOfDocumentDataRequest = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());

	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject)
	
	PartsOfQueryText = New Array;

	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	CASE
			|		WHEN HeaderData_.CustomAssembly
			|			THEN HeaderData_.ByAssemblyDisassemblyOrder
			|		ELSE UNDEFINED
			|	END AS OrderDocument,
			|	DocumentGoods.Ref AS Invoice,
			|	HeaderData_.Patch AS Patch,
			|	HeaderData_.CorrectedDocument AS CorrectedDocument,
			|	HeaderData_.Warehouse AS Recipient,
			|	HeaderData_.Warehouse AS Warehouse,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Purpose AS Purpose,
			|	UNDEFINED AS ControlledLotReference,
			|	DocumentGoods.Series AS Series,
			|	DocumentGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	DocumentGoods.Count AS Count,
			|	FALSE AS ExceedingOrder,
			|	FALSE AS Canceled,
			|	TRUE AS ThisIsAnInvoice,
			|	HeaderData_.CustomAssembly AS ShipmentByOrder
			|FROM
			|	DocumentDataTableItems AS DocumentGoods
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON DocumentGoods.Ref = HeaderData_.Ref
			|WHERE
			|	DocumentGoods.Ref IN(&Ref)
			|	AND DocumentGoods.Count <> 0
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.Count <> 0
			And DocumentObject.BatchesIndicationStatus <> 10
			And DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents) Then
		TextOfRequestPart = 
			"SELECT
			|	DocumentGoods.Ref AS Ref,
			|	DocumentGoods.Date AS Period,
			|	CASE
			|		WHEN DocumentGoods.CustomAssembly
			|			THEN DocumentGoods.ByAssemblyDisassemblyOrder
			|		ELSE UNDEFINED
			|	END AS OrderDocument,
			|	DocumentGoods.Ref AS Invoice,
			|	DocumentGoods.Patch AS Patch,
			|	DocumentGoods.CorrectedDocument AS CorrectedDocument,
			|	DocumentGoods.Warehouse AS Recipient,
			|	DocumentGoods.Warehouse AS Warehouse,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Purpose AS Purpose,
			|	UNDEFINED AS ControlledLotReference,
			|	DocumentGoods.Series AS Series,
			|	DocumentGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	DocumentGoods.Count AS Count,
			|	FALSE AS ExceedingOrder,
			|	FALSE AS Canceled,
			|	TRUE AS ThisIsAnInvoice,
			|	DocumentGoods.CustomAssembly AS ShipmentByOrder
			|FROM
			|	DocumentDataHeader AS DocumentGoods
			|WHERE
			|	DocumentGoods.Ref IN(&Ref)
			|	AND DocumentGoods.Count <> 0
			|	AND DocumentGoods.BatchesIndicationStatus <> 10
			|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	If DocumentObject = Undefined
		Or (DocumentObject.BatchesIndicationStatus = 10
			And DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents) Then
		TextOfRequestPart = 
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	CASE
			|		WHEN HeaderData_.CustomAssembly
			|			THEN HeaderData_.ByAssemblyDisassemblyOrder
			|		ELSE UNDEFINED
			|	END AS OrderDocument,
			|	HeaderData_.Ref AS Invoice,
			|	HeaderData_.Patch AS Patch,
			|	HeaderData_.CorrectedDocument AS CorrectedDocument,
			|	HeaderData_.Warehouse AS Recipient,
			|	HeaderData_.Warehouse AS Warehouse,
			|	DocumentGoods.Products AS Products,
			|	DocumentGoods.Characteristic AS Characteristic,
			|	DocumentGoods.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	DocumentGoods.Series AS Series,
			|	HeaderData_.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	DocumentGoods.Count AS Count,
			|	FALSE AS ExceedingOrder,
			|	FALSE AS Canceled,
			|	TRUE AS ThisIsAnInvoice,
			|	HeaderData_.CustomAssembly AS ShipmentByOrder
			|FROM
			|	DocumentDataBatchTable AS DocumentGoods
			|		INNER JOIN DocumentDataHeader AS HeaderData_
			|		ON DocumentGoods.Ref = HeaderData_.Ref
			|			AND DocumentGoods.Products = HeaderData_.Products
			|			AND DocumentGoods.Characteristic = HeaderData_.Characteristic
			|			AND DocumentGoods.Purpose = HeaderData_.Purpose
			|WHERE
			|	DocumentGoods.Ref IN(&Ref)
			|	AND DocumentGoods.Count <> 0
			|	AND HeaderData_.BatchesIndicationStatus = 10
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;
	
	If PartsOfQueryText.Count() = 0 Then
		Return;
	EndIf;

	TextOfDocumentDataRequest = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());

	MetadataObject	= Metadata.Documents.AssemblyFromComponents;
	TSSeriesName			= "SetOfSeries";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										TSSeriesName);
	
EndProcedure

Function DistributeCostOfComponentsToKits(TableOfSets, TableOfComponents, Attributes)

	TableCostOfGoods = AccumulationRegisters.InventoryCost.CreateRecordSet().UnloadColumns();
	TableCostOfGoods.Columns.Delete("Active");
	
	TableOfMotionProductsProducts = AccumulationRegisters.RecordsProductsProducts.CreateRecordSet().UnloadColumns();
	TableOfMotionProductsProducts.Columns.Delete("Active");

	Result = New Structure;
	Result.Insert("TableCostOfGoods", TableCostOfGoods);
	Result.Insert("TableOfMotionProductsProducts", TableOfMotionProductsProducts);
	
	If TableOfSets.Count() = 0 Or TableOfComponents.Count() = 0 Then
		Return Result;
	EndIf;
	
	If TableOfSets.Count() = 1 Then
		DistributionArray = New Array(1); // a fraction of the cost may not be filled in
		DistributionArray[0] = 1;
	Else
		DistributionArray = TableOfSets.UnloadColumn("CostShare");
	EndIf;
	
	TotalNumberOfOutput = TableOfComponents.Count();
	
	BatchAccountingVersion22   = CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(Attributes.Period));
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Attributes.Organization, 
		BegOfMonth(Attributes.Period));
	 
	FIFORollingValuation = (AccountingPolicyParameters <> Undefined 
							And AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation);
	
	For Each EntryLine In TableOfComponents Do

		DistributedQuantity = Common.DistributeAmountInProportionToCoefficients(EntryLine.Count, DistributionArray, 3);
		IdOfLoginAccountSFin = String(New UUID);
		IdOfExitSFinEntry = "";

		Counter = 0;
		ComponentEntriesWithoutId = New Array();
		KitEntriesWithoutId = New Array();
		
		For Each ExitString In TableOfSets Do

			// The number of outputs must be calculated for each input line.
			If TotalNumberOfOutput <> 0 Then
				OutputQuantity = Round(ExitString.Count / TotalNumberOfOutput, 3, RoundMode.Round15as20);
			Else
				OutputQuantity = ExitString.Count;
			EndIf;

			ExitString.Count = ExitString.Count - OutputQuantity;
			
			ThisIsMeaningfulWayOut = DistributedQuantity[Counter] <> 0;
			
			If Not ThisIsMeaningfulWayOut Then
			ElsIf ValueIsFilled(ExitString.RowID) Then
				IdOfExitSFinEntry = ExitString.RowID;
			Else
				IdOfExitSFinEntry = IdOfLoginAccountSFin;
			EndIf;

			RecordComponents = TableCostOfGoods.Add();
			FillPropertyValues(RecordComponents, EntryLine);
			RecordComponents.RecordType = AccumulationRecordType.Expense;
			RecordComponents.Department = Attributes.Department;
			RecordComponents.CorItemsLocationAttributes = ExitString.ItemsLocationAttributes;
			RecordComponents.CorAccountingSection = ExitString.AccountingSection;
			RecordComponents.CorInventoryOwnerAttribute = ExitString.InventoryOwnerAttribute;
			RecordComponents.Count = DistributedQuantity[Counter];
			RecordComponents.AccountingDimensionByPartners = EntryLine.AnalysisOfSettlementsWithCommittee;
			RecordComponents.FinRecordID = IdOfExitSFinEntry;
			//	batch accounting version 2.2
			RecordComponents.RowID = "";
			RecordComponents.EntryType = Enums.LotRecordTypes.ExpensesToOtherProductionLots;
			
			// Write-off of commission components according to the accounting section "Goods accepted for commission".
			If EntryLine.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
				
				CommissionComponents = RecordComponents;
				
				CommissionComponents.AccountingSection = Enums.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent;
				CommissionComponents.InventoryOwnerAttribute = EntryLine.TypeOfInventoryWriteOffs;
				CommissionComponents.ItemsLocationAttributes = EntryLine.AnalyticsForDebitingAccounts;
				
			EndIf;

			RecordingKit = TableCostOfGoods.Add();
			FillPropertyValues(RecordingKit, ExitString);
			RecordingKit.RecordType = AccumulationRecordType.Receipt;
			RecordingKit.Department = Attributes.Department;
			RecordingKit.Count  = OutputQuantity;
			RecordingKit.FinRecordID = IdOfExitSFinEntry; 
			
			//	batch accounting version 2.2
			If BatchAccountingVersion22 Then
				
				If FIFORollingValuation Then
					RecordingKit.Lot = ?(Attributes.Patch, Attributes.CorrectedDocument, Attributes.Ref);
					RecordingKit.LotVendorAttributes = ExitString.LotVendorAttributes;
					RecordComponents.CorLot = ?(Attributes.Patch, Attributes.CorrectedDocument, Attributes.Ref);
					RecordComponents.LotVendorAttributesCorr = ExitString.LotVendorAttributes;
				Else
					RecordingKit.LotVendorAttributes = Catalogs.KeysForLotVendorAttributes.EmptyRef();
					RecordingKit.LotVendorAttributesCorr = ExitString.LotVendorAttributes;
				EndIf;
				
				If GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities") And Attributes.EnabledGoodsAssignmentInSalesOpportunity Then
					RecordingKit.FinancialAccountingDimension = Attributes.SalesOpportunity;
				ElsIf GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers")
				 And Attributes.OptionOfAssignedAccountingOfGoods = Enums.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit Then
					RecordingKit.FinancialAccountingDimension = Attributes.Department;
				EndIf;
				
				If GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities") And Attributes.EnabledGoodsAssignmentInSalesOpportunity Then
				
					RecordComponents.CorControllingAttributes = Attributes.SalesOpportunity;
					If EntryLine.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
						CommissionComponents.CorControllingAttributes = Attributes.SalesOpportunity;
					EndIf;
					
				ElsIf GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers")
				 And Attributes.OptionOfAssignedAccountingOfGoods = Enums.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit Then
					
					RecordComponents.CorControllingAttributes = Attributes.Department;
					If EntryLine.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
						CommissionComponents.CorControllingAttributes = Attributes.Department;
					EndIf;
					
				EndIf;
				
				RecordComponents.CorVATActivityTypes = ExitString.VATActivityType;
				If EntryLine.InventoryType = Enums.InventoryTypes.ConsignedGoods Then
					CommissionComponents.CorVATActivityTypes = ExitString.VATActivityType;
				EndIf;
				
			Else
				RecordingKit.LotVendorAttributes = Catalogs.KeysForLotVendorAttributes.EmptyRef();
				RecordingKit.VATActivityType = Undefined;
			EndIf;
			
			If ThisIsMeaningfulWayOut Then
				RecordingKit.RowID = "";
			Else
				RecordingKit.RowID = ExitString.RowID;
				If IsBlankString(IdOfExitSFinEntry) Then
					ComponentEntriesWithoutId.Add(RecordComponents);
					KitEntriesWithoutId.Add(RecordingKit);
				EndIf;
			EndIf;
			
			RecordingKit.EntryType = Enums.LotRecordTypes.Lot;
			
			// Movement Nomenclature - Nomenclature
			EntryProductsProducts = TableOfMotionProductsProducts.Add();
			FillPropertyValues(EntryProductsProducts, EntryLine);
			EntryProductsProducts.ItemsLocationAttributes = EntryLine.AnalyticsForDebitingAccounts;
			EntryProductsProducts.LineOfBusiness = EntryLine.LineOfBusiness;
			EntryProductsProducts.InventoryOwnerAttribute = EntryLine.TypeOfInventoryWriteOffs;
			EntryProductsProducts.Organization = Attributes.Organization;
			EntryProductsProducts.Department = Attributes.Department;
			EntryProductsProducts.Warehouse = Attributes.Warehouse;
			
			EntryProductsProducts.CorItemsLocationAttributes = ExitString.ItemsLocationAttributes;
			EntryProductsProducts.CorLineOfBusiness = ExitString.LineOfBusiness;
			EntryProductsProducts.CorWarehouseCorCommissionAgentCorBusinessUnit = Attributes.Warehouse;
			EntryProductsProducts.CorInventoryType = ExitString.InventoryType;
			EntryProductsProducts.CorInventoryOwnerAttribute = ExitString.InventoryOwnerAttribute;
			
			EntryProductsProducts.Count = DistributedQuantity[Counter];
			EntryProductsProducts.CorQuantity = OutputQuantity;
			
			EntryProductsProducts.CorSourceOfItemsFinancialAccountingGroup = ExitString.SourceOfProductFinancialAccountingGroup;

			Counter = Counter + 1;

		EndDo;

		TotalNumberOfOutput = TotalNumberOfOutput - 1;

		For Each RecordComponents In ComponentEntriesWithoutId Do
			RecordComponents.FinRecordID = IdOfExitSFinEntry;
		EndDo;

		For Each RecordingKit In KitEntriesWithoutId Do
			RecordingKit.FinRecordID = IdOfExitSFinEntry;
		EndDo;

	EndDo;

	TableCostOfGoods.FillValues(Attributes.Organization, "Organization");
	
	Result.TableCostOfGoods = TableCostOfGoods;
	Result.TableOfMotionProductsProducts = TableOfMotionProductsProducts;
	
	Return Result;

EndFunction

Procedure FillInCorAnalysisOfNomeclatureAccounting(TableProductsOfOrganizations, Attributes)
	If Attributes.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		Return;
	EndIf;
	
	UsedMaterials = TableProductsOfOrganizations.FindRows(New Structure("RecordType", AccumulationRecordType.Expense));
	Base = New Array;
	For Each Kit In TableProductsOfOrganizations Do
		Base.Add(?(Kit.RecordType = AccumulationRecordType.Receipt, Kit.CostShare, 0.));
	EndDo;
	
	TotalRows = TableProductsOfOrganizations.Count();
	For Each Material In UsedMaterials Do
		CountBalance = Material.Count;
		QuantityByGBRNBalance = Material.QuantityByGBRN;
		MaterialQuantities = Common.DistributeAmountInProportionToCoefficients(CountBalance, Base, 3);
		QuantitiesOfMaterialAccordingToRNPT = Common.DistributeAmountInProportionToCoefficients(QuantityByGBRNBalance, Base, 3);
		If MaterialQuantities = Undefined Then
			Continue;
		EndIf;
		LineNumber = 0;
		While LineNumber < TotalRows Do
			Kit = TableProductsOfOrganizations[LineNumber];
			
			If Kit.RecordType = AccumulationRecordType.Receipt Then
				NewCount = MaterialQuantities[LineNumber];
				CountBalance = CountBalance - NewCount;
				If CountBalance > 0. Then
					NewMaterial = TableProductsOfOrganizations.Add();
					FillPropertyValues(NewMaterial, Material);
				Else
					NewMaterial = Material;
				EndIf;
				NewMaterial.CorItemsLocationAttributes = Kit.ItemsLocationAttributes;
				NewMaterial.Count = NewCount;
				
				If QuantitiesOfMaterialAccordingToRNPT <> Undefined Then
					NewQuantityAccordingToRNPT = QuantitiesOfMaterialAccordingToRNPT[LineNumber];
					QuantityByGBRNBalance = QuantityByGBRNBalance - NewQuantityAccordingToRNPT;
					NewMaterial.QuantityByGBRN = NewQuantityAccordingToRNPT;
				EndIf;
				
				If Not ValueIsFilled(NewMaterial.CorInventoryOwnerAttribute) Then
					NewMaterial.CorInventoryOwnerAttribute = Kit.InventoryOwnerAttribute;
				EndIf;
				
				If CountBalance <= 0. Then
					Break;
				EndIf;
			EndIf;
			
			LineNumber = LineNumber + 1;
		EndDo;
	EndDo;
EndProcedure

Procedure CreateTTTableBatchAccountingAnalyst(Query)
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query, "TTTableOfPartyAccountingAnalysts") Then
		
		QueryText = Query.Text; // saving the Query Text
		
		Query.Text = QueryTextTTTableOfPartyAccountingAnalysts(Query);
		Query.Execute();
		
		Query.Text = QueryText; // restoring the request text
		
	EndIf;
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.AssemblyFromComponents";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnShipment",
		"	CASE
		|		WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnGoodsReceipt",
		"	CASE
		|		WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("CustomAssembly",
		"GoodsTable.Ref.ByAssemblyDisassemblyOrder <> VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	
	If RegisterName = "AssemblyOrders" Then
		
		QueryText = QueryTextTableAssemblyOrders(Query, QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "GoodsTable";
	
	ElsIf RegisterName = "GoodsBatchMovement" Then
		
		QueryText = QueryTextTableGoodsBatchMovement(Query, QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject)

	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		QueryTextTabPart =
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	HeaderData_.Warehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	TabPart.Count AS Count,
			|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
			|	TRUE AS ControlOfFreeResidue
			|FROM
			|	DocumentDataTableItems AS TabPart
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TabPart.Ref)
			|WHERE
			|	HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND TabPart.RowCode = 0";
			
		StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		QueryTextTabPart =
			"SELECT
			|	TabPart.Ref AS Ref,
			|	TabPart.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	TabPart.Warehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	TabPart.Count AS Count,
			|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
			|	TRUE AS ControlOfFreeResidue
			|FROM
			|	DocumentDataHeader AS TabPart
			|WHERE
			|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|	AND NOT TabPart.CustomAssembly";
		
		StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	EndIf;
	
	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents
			And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled) Then
		QueryTextTabPart =
			// The arrival of components during disassembly in an irregular warehouse or for old purposes.
			"SELECT
			|	TabPart.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	HeaderData_.Warehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	HeaderData_.ControlledLotReference AS ControlledLotReference,
			|	TabPart.ToControlQuality AS ToControlQuality,
			|	TabPart.ToControlQuality AS SubjectToUnlocking,
			|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
			|	TabPart.Count AS Count,
			|	HeaderData_.CustomAssembly AS OnSchedule,
			|	HeaderData_.ByAssemblyDisassemblyOrder AS OrderInSchedule
			|FROM
			|	DocumentDataTableItems AS TabPart
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TabPart.Ref)
			|WHERE
			|	HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|	AND HeaderData_.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
			|	AND (NOT HeaderData_.AdvancedWarehousingOnGoodsReceipt
			|			OR TabPart.AssigningTrafficToWarehouseRegisters = FALSE)";
		
		StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	EndIf;
	
	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
			And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled) Then
		QueryTextTabPart =
			// The arrival of kits during assembly in an irregular warehouse or for old purposes.
			"SELECT
			|	TabPart.Ref AS Ref,
			|	TabPart.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	TabPart.Warehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	TabPart.ControlledLotReference AS ControlledLotReference,
			|	TabPart.ToControlQuality AS ToControlQuality,
			|	TabPart.ToControlQuality AS SubjectToUnlocking,
			|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
			|	TabPart.Count AS Count,
			|	TabPart.CustomAssembly AS OnSchedule,
			|	TabPart.ByAssemblyDisassemblyOrder AS OrderInSchedule
			|FROM
			|	DocumentDataHeader AS TabPart
			|WHERE
			|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND TabPart.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
			|	AND (NOT TabPart.AdvancedWarehousingOnGoodsReceipt
			|			OR TabPart.AssigningTrafficToWarehouseRegisters = FALSE)";
		
		StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	EndIf;
	
	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents
			And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled) Then
		QueryTextTabPart =
			// The reverse of the components of the receipt order during disassembly for old purposes.
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	HeaderData_.Warehouse AS Warehouse,
			|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	FALSE AS ToControlQuality,
			|	FALSE AS SubjectToUnlocking,
			|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
			|	-TabPart.Count AS Count,
			|	FALSE AS OnSchedule,
			|	UNDEFINED AS OrderInSchedule
			|FROM
			|	DocumentDataTableItems AS TabPart
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TabPart.Ref)
			|WHERE
			|	HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|	AND HeaderData_.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
			|	AND TabPart.AssigningTrafficToWarehouseRegisters = FALSE
			|	AND HeaderData_.AdvancedWarehousingOnGoodsReceipt";
		
		StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	EndIf;
	
	If DocumentObject = Undefined
		Or (DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents
			And DocumentObject.Status = Enums.GoodsAssemblyStatuses.AssembledDisassembled) Then
		QueryTextTabPart =
			// Reverse sets of receipt orders when assembling for old purposes.
			"SELECT
			|	TabPart.Ref AS Ref,
			|	TabPart.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	TabPart.Warehouse AS Warehouse,
			|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	FALSE AS ToControlQuality,
			|	FALSE AS SubjectToUnlocking,
			|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
			|	-TabPart.Count AS Count,
			|	FALSE AS OnSchedule,
			|	UNDEFINED AS OrderInSchedule
			|FROM
			|	DocumentDataHeader AS TabPart
			|WHERE
			|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND TabPart.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
			|	AND TabPart.AssigningTrafficToWarehouseRegisters = FALSE
			|	AND TabPart.AdvancedWarehousingOnGoodsReceipt";
		
		StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		QueryTextTabPart =
			// Planning the arrival of components during disassembly.
			"SELECT
			|	HeaderData_.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	HeaderData_.Warehouse AS Warehouse,
			|	CASE
			|		WHEN TabPart.AssigningTrafficToWarehouseRegisters = FALSE
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE TabPart.Purpose
			|	END AS Purpose,
			|	TabPart.ToControlQuality AS ToControlQuality,
			|	TabPart.ToControlQuality AS SubjectToUnlocking,
			|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
			|	TabPart.Count AS Count,
			|	CASE
			|		WHEN HeaderData_.CorrectedDocument = VALUE(Document.AssemblyFromComponents.EmptyRef)
			|			THEN HeaderData_.Ref
			|		ELSE HeaderData_.CorrectedDocument
			|	END AS OrderDocument,
			|	CASE
			|		WHEN HeaderData_.DateOfReceipt <> DATETIME(1, 1, 1)
			|			THEN HeaderData_.DateOfReceipt
			|		ELSE HeaderData_.Date
			|	END AS DateOfReceipt,
			|	TRUE AS AvailableForConsumption,
			|	HeaderData_.CustomAssembly AS OnSchedule,
			|	HeaderData_.ByAssemblyDisassemblyOrder AS OrderInSchedule,
			|	TabPart.Count AS QuantityInGraph
			|FROM
			|	DocumentDataTableItems AS TabPart
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TabPart.Ref)
			|WHERE
			|	HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
			|	AND HeaderData_.AdvancedWarehousingOnGoodsReceipt
			|	AND (HeaderData_.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			OR NOT HeaderData_.CustomAssembly)";
		
		StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	EndIf;
	
	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.AssemblyFromComponents Then
		QueryTextTabPart =
			// Planning the arrival of kits during assembly.
			"SELECT
			|	TabPart.Ref AS Ref,
			|	TabPart.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	TabPart.Warehouse AS Warehouse,
			|	CASE
			|		WHEN TabPart.AssigningTrafficToWarehouseRegisters = FALSE
			|			THEN VALUE(Catalog.Assignments.EmptyRef)
			|		ELSE TabPart.Purpose
			|	END AS Purpose,
			|	TabPart.ToControlQuality AS ToControlQuality,
			|	TabPart.ToControlQuality AS SubjectToUnlocking,
			|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
			|	TabPart.Count AS Count,
			|	CASE
			|		WHEN TabPart.CorrectedDocument = VALUE(Document.AssemblyFromComponents.EmptyRef)
			|			THEN TabPart.Ref
			|		ELSE TabPart.CorrectedDocument
			|	END AS OrderDocument,
			|	CASE
			|		WHEN TabPart.DateOfReceipt <> DATETIME(1, 1, 1)
			|			THEN TabPart.DateOfReceipt
			|		ELSE TabPart.Date
			|	END AS DateOfReceipt,
			|	TRUE AS AvailableForConsumption,
			|	TabPart.CustomAssembly AS OnSchedule,
			|	TabPart.ByAssemblyDisassemblyOrder AS OrderInSchedule,
			|	TabPart.Count AS QuantityInGraph
			|FROM
			|	DocumentDataHeader AS TabPart
			|WHERE
			|	TabPart.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
			|	AND TabPart.AdvancedWarehousingOnGoodsReceipt
			|	AND (TabPart.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|			OR NOT TabPart.CustomAssembly)";
		
		StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	EndIf;
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	
	If Query <> Undefined Then
	
		PerformDistributionOfCostOfComponentsOnSets(Query);
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;

#Region WriteOffToOtherBatchesOf_Expenses
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.ItemsLocationAttributes				AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.CorVATActivityTypes						AS VATActivityType,
	|	TTTypesOfStocks.CorVATActivityTypes						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED											AS CorCompany,
	|	TTTypesOfStocks.CorLot									AS CorLot,
	|	TTTypesOfStocks.LotVendorAttributesCorr					AS LotVendorAttributesCorr,
	|	TTTypesOfStocks.CorItemsLocationAttributes				AS CorItemsLocationAttributes,
	|	TTTypesOfStocks.CorInventoryOwnerAttribute								AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	TTTypesOfStocks.Department				AS Department,
	|	UNDEFINED							AS Manager,
	|	TTTypesOfStocks.ProductsGroup 			AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count	AS Count,
	|
	// Optional fields
	|	TTTypesOfStocks.EntryType		AS EntryType,
	|
	// Other fields
	|	TTTypesOfStocks.RowID		AS RowID,
	|	TTTypesOfStocks.FinRecordID	AS FinRecordID,
	|	TTTypesOfStocks.BusinessOperation		AS BusinessOperation,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|FROM
	|	Document.AssemblyFromComponents AS DocumentTable
	|	INNER JOIN TTTableCostOfGoods AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
	|	AND TTTypesOfStocks.EntryType = VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);
	
	#EndRegion
	
#Region InternalReceipt_ReceiptOfProducts
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	TTTypesOfStocks.Organization								AS Organization,
	|	TTTypesOfStocks.ItemsLocationAttributes				AS ItemsLocationAttributes,
	|	TTTypesOfStocks.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	TTTypesOfStocks.VATActivityType						AS VATActivityType,
	|	TTTypesOfStocks.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TTTypesOfStocks.Lot				AS Lot,
	|	TTTypesOfStocks.LotVendorAttributes	AS LotVendorAttributes,
	|	0									AS RowCode,
	|
	// Corresponding fields
	|	TTTypesOfStocks.LotVendorAttributesCorr					AS LotVendorAttributesCorr,
	|	TTTypesOfStocks.CorItemsLocationAttributes				AS CorItemsLocationAttributes,
	|	TTTypesOfStocks.CorInventoryOwnerAttribute								AS CorInventoryOwnerAttribute,
	|	UNDEFINED											AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	TTTypesOfStocks.Department				AS Department,
	|	UNDEFINED							AS Manager,
	|	TTTypesOfStocks.ProductsGroup 			AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTypesOfStocks.Count		AS Count,
	|	TTTypesOfStocks.Cost			AS Cost,
	|	TTTypesOfStocks.CostExcludingVAT	AS CostExcludingVAT,
	|	TTTypesOfStocks.LocalCost		AS LocalCost,
	|	0 AS CostMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	TTTypesOfStocks.AddExpensesForGoods 		AS AddExpensesForGoods,
	|	TTTypesOfStocks.AdditionalExpensesExcludingVAT 	AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	TTTypesOfStocks.PermanentDifference AS PermanentDifference,
	|	TTTypesOfStocks.CostTD 	AS CostTD,
	|	0 AS CorGrossInitialCostENT,
	|
	// Other fields
	|	TTTypesOfStocks.RowID	 AS RowID,
	|	TTTypesOfStocks.FinRecordID AS FinRecordID,
	|	TTTypesOfStocks.BusinessOperation	 AS BusinessOperation,
	|	&BusinessTransactionSetting		 AS BusinessTransactionSetting,
	|	VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord) AS CostDefiningMethod
	|
	|FROM
	|	Document.AssemblyFromComponents AS DocumentTable
	|	INNER JOIN TTTableCostOfGoods AS TTTypesOfStocks
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Status = VALUE(Enum.GoodsAssemblyStatuses.AssembledDisassembled)
	|	AND TTTypesOfStocks.EntryType = VALUE(Enum.LotRecordTypes.Lot)
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);

	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return AssemblyFromComponentsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - query text.
Function RequestTextTTReflectedInLocalAccounting() Export

	Return AssemblyFromComponentsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("Update", Metadata.Documents.AssemblyFromComponents) Then
		// The Assembly of goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "AssemblyFromComponents";
		PrintCommand.Presentation = NStr("vi = 'Đóng bộ hàng hóa';
										|ru = 'Сборка товаров';
										|en = 'Product kitting'; fa = 'کیت‌سازی محصول';
										|it = 'Assemblaggio di merci';
										|pl = 'Kompletowanie towarów';
										|tr = 'Ürünlerin montajı'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														Enums.GoodsAssemblyStatuses.AssembledDisassembled,
														ComparisonType.Equal);
	
	// Task for the selection of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	
	AssemblyFromComponentsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "AssemblyFromComponents") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "AssemblyFromComponents",
				NStr("vi = 'Đóng bộ hàng hóa';
					|ru = 'Сборка товаров';
					|en = 'Product kitting'; fa = 'کیت‌سازی محصول';
					|it = 'Assemblaggio di merci';
					|pl = 'Kompletowanie towarów';
					|tr = 'Ürünlerin montajı'"),
				PrintingAssemblyOfGoods(ObjectsArray, PrintObjects));

	EndIf;
	AssemblyFromComponentsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

Function PrintingAssemblyOfGoods(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputAdditionalColumn = ValueIsFilled(AdditionalColumn);
	
	RequestForDocuments = New Query;
	RequestForDocuments.SetParameter("ObjectsArray", ObjectsArray);
	RequestForDocuments.Text =
	"
	|SELECT
	|	Document.Ref                          AS Ref,
	|	Document.Number                           AS Number,
	|	Document.Date                            AS Date,
	|	Document.CorrectedDocument.Number      AS NumberOfDocumentBeingCorrected,
	|	Document.CorrectedDocument.Date       AS DateOfDocumentBeingCorrected,
	|	Document.Warehouse                           AS Warehouse,
	|	Document.Organization                     AS Organization,
	|	PRESENTATION(Document.Warehouse)            AS WarehousePresentation,
	|	PRESENTATION(Document.Organization)      AS OrganizationPresentation,
	|	Document.Organization.Prefix             AS Prefix,
	|	Document.EmployeeResponsible.Individual.Description AS EmployeeResponsiblePresentation,
	|	&AdditionalHeaderColumn                         AS AdditionalColumn,
	|	Document.Products                    AS Products,
	|	Document.Products.DescriptionFull AS ProductsPresentation,
	|	Document.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|
	|	CASE WHEN Document.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			PRESENTATION(Document.Products.UnitOfMeasure)
	|		ELSE
	|			PRESENTATION(Document.Package)
	|	END                                    AS Package,
	|	Document.NumberOfPackages              AS Count,
	|	Document.BusinessOperation           AS BusinessOperation,
	|	Document.Goods.(
	|
	|		LineNumber AS LineNumber,
	|		&AdditionalColumnTabPart                 AS AdditionalColumn,
	|		Products                        AS Products,
	|		Products.DescriptionFull     AS ProductsPresentation,
	|		Characteristic.DescriptionFull 	AS CharacteristicPresentation,
	|		Characteristic                      AS Characteristic,
	|		CASE
	|			WHEN Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|				REFPRESENTATION(Products.UnitOfMeasure)
	|			ELSE
	|				REFPRESENTATION(Package)
	|		END              AS Package,
	|		NumberOfPackages AS Count
	|
	|	) AS GoodsTable
	|FROM
	|	Document.AssemblyFromComponents AS Document
	|
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|ORDER BY
	|	Date, Ref, LineNumber
	|";

	SubstitutionAdditionalColumnHeader = "0";
	SubstitutionDOPColumnTabPart = "0";
	If OutputAdditionalColumn Then
		
		SubstitutionAdditionalColumnHeader = "Document.Products." + AdditionalColumn;
		SubstitutionDOPColumnTabPart = "Products." + AdditionalColumn;
		
	EndIf;
	
	RequestForDocuments.Text = StrReplace(RequestForDocuments.Text, "&AdditionalColumnTabPart", SubstitutionDOPColumnTabPart);
	RequestForDocuments.Text = StrReplace(RequestForDocuments.Text, "&AdditionalHeaderColumn",    SubstitutionAdditionalColumnHeader);
	
	DocumentAttributes = New Structure("Number, Date, Prefix, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_AssemblyFromComponents";
	
	Template = PrintManagement.PrintFormTemplate("Document.AssemblyFromComponents.PF_MXL_AssemblyFromComponents");
	
	If OutputAdditionalColumn Then
		HeaderArea  = "HeaderWithAdditionalColumn";
		RowArea = "RowWithAdditionalColumn";
	Else
		HeaderArea  = "TableHeader";
		RowArea = "String";
	EndIf;
	
	FirstDocument = True;
	DocumentsSelection = RequestForDocuments.Execute().Select();
	While DocumentsSelection.Next() Do
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		// Header output.
		FillPropertyValues(DocumentAttributes, DocumentsSelection);
		
		TemplateArea = Template.GetArea("Title");
		TemplateArea.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, String(DocumentsSelection.BusinessOperation));
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, TemplateArea, DocumentsSelection.Ref);
		TabDocument.Put(TemplateArea);
		
		// Output of the kit.
		If OutputAdditionalColumn Then
			
			TemplateArea = Template.GetArea("KitCode");
			TemplateArea.Parameters.AdditionalColumn = PresentationOfCodesColumn + ":";
			TemplateArea.Parameters.ValueOfThisColumn = DocumentsSelection.AdditionalColumn;
			TabDocument.Put(TemplateArea);
			
		EndIf;
		
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
		
		TemplateArea = Template.GetArea("Kit");
		TemplateArea.Parameters.Kit = ProductsClientServer.PresentationOfProductsForPrinting(
			DocumentsSelection.ProductsPresentation,
			DocumentsSelection.CharacteristicPresentation,
			,
			,
			AdditionalParametersProductPresentation);
		TemplateArea.Parameters.Count = String(DocumentsSelection.Count) + " " + DocumentsSelection.Package;
		TabDocument.Put(TemplateArea);
		
		// Output of the report header.
		TemplateArea = Template.GetArea(HeaderArea);
		If OutputAdditionalColumn Then
			TemplateArea.Parameters.AdditionalColumn = PresentationOfCodesColumn;
		EndIf;
		TabDocument.Put(TemplateArea);
		
		// Output of document lines.
		SelectionDocumentsTableProducts = DocumentsSelection.GoodsTable; // QueryResultSelection - 
		SelectionByLines = SelectionDocumentsTableProducts.Select();
		
		AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
		AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
		
		While SelectionByLines.Next() Do
			
			TemplateArea = Template.GetArea(RowArea);
			TemplateArea.Parameters.Fill(SelectionByLines);
			
			TemplateArea.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectionByLines.ProductsPresentation,
				SelectionByLines.CharacteristicPresentation,
				,
				,
				AdditionalParametersProductPresentation);
			
			TabDocument.Put(TemplateArea);
			
		EndDo;
		
		// Output of signatures.
		TemplateArea = Template.GetArea("Signatures");
		TemplateArea.Parameters.EmployeeResponsiblePresentation = "/"+ DocumentsSelection.EmployeeResponsiblePresentation + "/";
		TabDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);
		
	EndDo;
	
	Return TabDocument;
	
EndFunction

// Returns the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting
// (placing) products.
//
// Returns:
//	String - the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting (placing) goods.
//
Function TextOfGoodsRequestDocumentForPrintingTaskForSelectingPlacingGoods() Export
	
	RequestText_1 =
	"SELECT
	|	DocumentData.Ref			AS Ref,
	|	1								AS LineNumber,
	|	DocumentData.Warehouse			AS Warehouse,
	|	&Premise						AS Premise,
	|	DocumentData.Products	AS Products,
	|	DocumentData.Characteristic	AS Characteristic,
	|	DocumentData.Series			AS Series
	|INTO DocumentGoods
	|FROM
	|	Document.AssemblyFromComponents AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|			THEN &ReceiptOperation = FALSE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|			THEN &ReceiptOperation = TRUE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.Ref					AS Ref,
	|	MIN(DocumentGoods.LineNumber)	AS LineNumber,
	|	DocumentData.Warehouse					AS Warehouse,
	|	&Premise								AS Premise,
	|	DocumentGoods.Products			AS Products,
	|	DocumentGoods.Characteristic			AS Characteristic,
	|	DocumentGoods.Series					AS Series
	|FROM
	|	Document.AssemblyFromComponents.Goods AS DocumentGoods
	|		INNER JOIN Document.AssemblyFromComponents AS DocumentData
	|		ON DocumentGoods.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&ObjectsArray)
	|	AND CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|			THEN &ReceiptOperation
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|			THEN NOT &ReceiptOperation
	|	END
	|
	|GROUP BY
	|	DocumentGoods.Ref,
	|	DocumentData.Warehouse,
	|	&Premise,
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series";
	
	RequestText_1 = StrReplace(RequestText_1, "&Premise", "VALUE(Catalog.Warerooms.EmptyRef)");
	
	Return RequestText_1;
	
EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.AssemblyFromComponents))
		And (AccessRight("Insert", Metadata.Documents.AssemblyFromComponents)
			Or AccessRight("Update", Metadata.Documents.AssemblyFromComponents))
		And AccessRight("View", Metadata.Documents.ByAssemblyDisassemblyOrder)
		And AccessRight("Read",   Metadata.AccumulationRegisters.AssemblyOrders)
		And GetFunctionalOption("UseAssemblyDisassemblyOrders");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	BsnsTransactions = New Array(2);
	BsnsTransactions[0] = Enums.BusinessTransactions.AssemblyFromComponents;
	BsnsTransactions[1] = Enums.BusinessTransactions.DisassemblyIntoComponents;
	
	AssemblyOfGoodsForRegistration = DataProcessors.LogOfInternalDocuments.NumberOfLinesForLayout(
		BsnsTransactions);
	
	// Filling out cases.
	// Internal Movement
	UserTaskParent = ToDoList.Find("InternalInventoryTransfers", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "InternalInventoryTransfers";
		UserTaskParent.Presentation  = NStr("vi = 'Điều chuyển hàng hóa nội bộ';
											|ru = 'Внутреннее товародвижение';
											|en = 'Internal inventory transfers'; fa = 'انتقالات داخلی موجودی';
											|it = 'Flusso di prodotti interno';
											|pl = 'Wewnętrzny ruch towarów';
											|tr = 'Dahili stok transferleri'");
		UserTaskParent.Owner       = Metadata.Subsystems.Warehouse;
	EndIf;
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or AssemblyOfGoodsForRegistration > 0;
	
	OpeningParameters = ParametersForOpeningWorkplaceForm();
	OpeningParameters.FormParameters.Insert("FormAssignmentKey", "ToDoList");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "PreparationOfGoodsForRegistration";
	ToDoItem.HasToDoItems       = AssemblyOfGoodsForRegistration > 0;
	ToDoItem.Presentation  = NStr("vi = 'Đóng bộ (tách bộ) hàng hóa cần tạo';
									|ru = 'Сборки (разборки) товаров к оформлению';
									|en = 'Kitting of goods to register'; fa = 'Kitting of goods to register';
									|it = 'Assemblaggio (disassemblaggio) delle merci alla formalizzazione';
									|pl = 'Montaż (demontaż) towarów do rejestracji';
									|tr = 'Düzenlenecek ürün montajı/demontajı'");
	ToDoItem.Count     = AssemblyOfGoodsForRegistration;
	ToDoItem.Important         = False;
	ToDoItem.Form          = OpeningParameters.FormName;
	ToDoItem.FormParameters = OpeningParameters.FormParameters;
	ToDoItem.Owner       = "InternalInventoryTransfers";
	
EndProcedure

#EndRegion

#Region SetOfSeries

Function TextOfRequestToFillInStatusesSpecifyingAssemblyHeaderSeries()
	
	QueryText = 
	"SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
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
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose,
	|	SUM(TableOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
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
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 8
	|					ELSE 7
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingAssembledKits
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
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
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
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

Function RequestTextForFillingInStatusesSpecifyingSeriesOfDisassemblyHeader()
	
	QueryText = 
	"SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
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
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose,
	|	SUM(TableOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
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
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND &FactOfSelection
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenShippingKitsForDisassembly
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
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
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
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

Function RequestTextForFillingInStatusesForSpecifyingAssemblyTSSeries()
	
	QueryText = 
	"SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
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
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose,
	|	SUM(TableOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
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
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND &FactOfSelection
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
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
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
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

Function TextOfRequestToFillInStatusesForSpecifyingDisassemblyTSSeries()
	
	QueryText = 
	"SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
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
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose,
	|	SUM(TableOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
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
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 8
	|					ELSE 7
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingComponentsAfterDisassembly
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
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
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
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

#Region FillingInDocument_

Procedure RequestParametersToCreateBasedOn(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", True);
	
	If SelectionData_.FillByWarehouseDocument Then
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TableAssembledDisassembledKit");
		QueryNames.Add("TableAssembledDisassembledComponents");
		QueryNames.Add("TableSet");
		
		QueryNames.Add("TableComponents");
		SubqueryNames.Add("BlockRegisterOrdersComponents");
		
		If SelectionData_.HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
			QueryNames.Add("SeriesTableIsDisassembled");
		EndIf;
		
	Else
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TableSet");
		
		QueryNames.Add("TableComponents");
		SubqueryNames.Add("BlockRegisterOrdersComponents");
		
		If SelectionData_.HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
			QueryNames.Add("SeriesTable");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure QueryParametersForMatching(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",         SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_",      SelectionData_.AnArrayOfOrders.Count() = 1);
	QueryParameters.Insert("Recorder",           SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("Organization",           SelectionData_.HeaderAttributes.Organization);
	QueryParameters.Insert("Department",         SelectionData_.HeaderAttributes.Department);
	QueryParameters.Insert("Warehouse",                 SelectionData_.HeaderAttributes.Warehouse);
	QueryParameters.Insert("BusinessOperation", SelectionData_.HeaderAttributes.BusinessOperation);
	QueryParameters.Insert("InvoiceGoods",       SelectionData_.InvoiceGoods);
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", True);
	QueryParameters.Insert("LineOfBusiness", SelectionData_.HeaderAttributes.LineOfBusiness);
	
	QueryNames.Add("TTOrdersSelection");
	QueryNames.Add("TTInvoice");
	QueryNames.Add("TableAssembledDisassembledComponents");
	QueryNames.Add("TableSet");
	QueryNames.Add("TableAssembledDisassembledKit");
	
	QueryNames.Add("TableComponents");
	SubqueryNames.Add("BlockRegisterOrdersComponents");
	SubqueryNames.Add("StornoInvoiceBlockComponents");
	SubqueryNames.Add("BlockRegisterOrdersSet");
	SubqueryNames.Add("BlockStornoOverheadKit");
	SubqueryNames.Add("BlockNewRegisteredRecordsInvoiceComponents");
	
EndProcedure

Procedure RequestParametersToBeFilledIn(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", True);
	QueryParameters.Insert("Recorder",      SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("InvoiceGoods",  SelectionData_.InvoiceGoods);
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", True);
	QueryParameters.Insert("FillInAsNeeded", True);
	
	QueryNames.Add("TTOrdersSelection");
	QueryNames.Add("TTInvoice");
	QueryNames.Add("TableAssembledDisassembledKit");
	QueryNames.Add("TableAssembledDisassembledComponents");
	QueryNames.Add("TableSet");
	
	QueryNames.Add("TableComponents");
	SubqueryNames.Add("BlockRegisterOrdersComponents");
	SubqueryNames.Add("StornoInvoiceBlockComponents");
	SubqueryNames.Add("BlockNewRegisteredRecordsInvoiceComponents");
	
	If SelectionData_.HeaderAttributes.BusinessOperation = Enums.BusinessTransactions.DisassemblyIntoComponents Then
		QueryNames.Add("SeriesTableIsDisassembled");
	EndIf;
	
EndProcedure

Function QueryTextOfTemporaryOrderTable()
	
	QueryText =
		"SELECT
		|	ByAssemblyDisassemblyOrder.Ref AS OrderDocument,
		|	CASE WHEN ByAssemblyDisassemblyOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END            AS ThisIsBuild,
		|	CASE WHEN ByAssemblyDisassemblyOrder.BatchesIndicationStatus = 10
		|		AND ByAssemblyDisassemblyOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END            AS SeriesAreIndicatedInSeparateTabularPart
		|INTO TTOrdersSelection
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS ByAssemblyDisassemblyOrder
		|WHERE
		|	CASE
		|		WHEN &SelectByOrder_ THEN
		|			ByAssemblyDisassemblyOrder.Ref IN (&AnArrayOfOrders)
		|		ELSE
		|			ByAssemblyDisassemblyOrder.Department = &Department
		|			AND ByAssemblyDisassemblyOrder.Organization = &Organization
		|			AND ByAssemblyDisassemblyOrder.Warehouse       = &Warehouse
		|			AND ByAssemblyDisassemblyOrder.BusinessOperation = &BusinessOperation
		|			AND ByAssemblyDisassemblyOrder.LineOfBusiness = &LineOfBusiness
		|	END
		|	AND ByAssemblyDisassemblyOrder.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	&Recorder AS OrderDocument,
		|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END            AS ThisIsBuild,
		|	CASE WHEN DocumentData.BatchesIndicationStatus = 10
		|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END            AS SeriesAreIndicatedInSeparateTabularPart
		|FROM
		|	Document.AssemblyFromComponents AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Recorder
		|;
		|
		|//////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextForTemporaryInvoiceTable()
	
	QueryText =
		"SELECT
		|	Table.Count            AS Count,
		|
		|	Table.LineNumber           AS LineNumber,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	Table.Purpose            AS Purpose,
		|	Table.Series                 AS Series,
		|
		|	Table.RowCode             AS RowCode,
		|	Table.Package              AS Package,
		|
		|	Table.OrderDocument                 AS OrderDocument
		|
		|INTO TTInvoice
		|FROM
		|	&InvoiceGoods AS Table
		|;
		|
		|//////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextUpperCaseOrdersComponents()
	
	QueryText =
		"	SELECT
		|		TableBalance.ByAssemblyDisassemblyOrder AS OrderDocument,
		|		TableBalance.RowCode     AS RowCode,
		|
		|		TableBalance.ToRegisterBalance AS QuantityInOrder,
		|		0                                 AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableBalance.Products        AS Products,
		|		TableBalance.Characteristic      AS Characteristic,
		|
		|		CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) THEN
		|
		|					Table.Purpose
		|
		|				WHEN Table.WithAssignment THEN
		|
		|						CASE WHEN Table.Ref.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
		|									Table.Ref.AssignmentGoods
		|								ELSE
		|									Table.Ref.Purpose
		|							END
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|
		|			END                            AS Purpose,
		|
		|		TableBalance.Series                 AS Series,
		|
		|		DocumentData.Date                 AS Date,
		|		Table.LineNumber                  AS LineNumber,
		|		DocumentData.AssemblyDisassemblyStart AS DateOfShipment,
		|		FALSE                                 AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		AccumulationRegister.AssemblyOrders.Balance(,
		|				ByAssemblyDisassemblyOrder IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument
		|					FROM
		|						TTOrdersSelection AS Table)) AS TableBalance
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder.Goods AS Table
		|			ON TableBalance.ByAssemblyDisassemblyOrder = Table.Ref
		|			 AND TableBalance.RowCode = Table.RowCode
		|
		|			// The use of communication by nomenclature allows you to always receive the remnants of components, and not kits.
		|			 AND TableBalance.Products = Table.Products
		|			 AND TableBalance.Characteristic = Table.Characteristic
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentData
		|			ON TableBalance.ByAssemblyDisassemblyOrder = DocumentData.Ref";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Return QueryText;
	
EndFunction

Function RequestTextLeftoversRegisterOrdersSet()
	
	QueryText =
		"	SELECT
		|		TableBalance.ByAssemblyDisassemblyOrder AS OrderDocument,
		|		TableBalance.RowCode     AS RowCode,
		|
		|		TableBalance.ToRegisterBalance AS QuantityInOrder,
		|		0                                 AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableBalance.Products        AS Products,
		|		TableBalance.Characteristic      AS Characteristic,
		|
		|		CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|
		|					DocumentData.Purpose
		|
		|				WHEN DocumentData.WithAssignment THEN
		|
		|					DocumentData.Purpose
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|
		|			END                            AS Purpose,
		|
		|		CASE WHEN DocumentData.BatchesIndicationStatus = 10 THEN
		|					VALUE(Catalog.ItemsBatches.EmptyRef)
		|				ELSE
		|					TableBalance.Series
		|			END                            AS Series,
		|
		|		DocumentData.Date                 AS Date,
		|		0                                    AS LineNumber,
		|		DocumentData.AssemblyDisassemblyStart AS DateOfShipment,
		|		FALSE                                 AS ExistsInTheDocument,
		|
		|		DocumentData.Package             AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		AccumulationRegister.AssemblyOrders.Balance(,
		|				ByAssemblyDisassemblyOrder IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument
		|					FROM
		|						TTOrdersSelection AS Table)) AS TableBalance
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentData
		|			ON TableBalance.ByAssemblyDisassemblyOrder = DocumentData.Ref
		|
		|			// The use of communication by nomenclature allows you to always receive the remnants of kits, and not components.
		|			 AND TableBalance.Products   = DocumentData.Products
		|			 AND TableBalance.Characteristic = DocumentData.Characteristic";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"DocumentData.Package",
			"DocumentData.Products"));
	
	Return QueryText;
	
EndFunction

Function RequestTextReverseRegisteredRecordsInvoiceAccessories()
	
	QueryText =
		"	SELECT
		|		TableStorno.ByAssemblyDisassemblyOrder      AS OrderDocument,
		|		TableStorno.RowCode          AS RowCode,
		|
		|		TableStorno.ToRegister        AS QuantityInOrder,
		|		0                                AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableStorno.Products       AS Products,
		|		TableStorno.Characteristic     AS Characteristic,
		|
		|		CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents) THEN
		|
		|					Table.Purpose
		|
		|				WHEN Table.WithAssignment THEN
		|
		|						Table.Ref.AssignmentGoods
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|
		|			END                            AS Purpose,
		|
		|		TableStorno.Series              AS Series,
		|		DocumentData.Date             AS Date,
		|		Table.LineNumber                  AS LineNumber,
		|		DocumentData.AssemblyDisassemblyStart AS DateOfShipment,
		|		FALSE                                 AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		AccumulationRegister.AssemblyOrders AS TableStorno
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder.Goods AS Table
		|			ON TableStorno.ByAssemblyDisassemblyOrder = Table.Ref
		|			 AND TableStorno.RowCode = Table.RowCode
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentData
		|			ON TableStorno.ByAssemblyDisassemblyOrder = DocumentData.Ref
		|
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND TableStorno.ByAssemblyDisassemblyOrder IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument
		|			FROM
		|				TTOrdersSelection AS Table)
		|
		|		// It is necessary to receive a lot of components only.
		|		AND(
		|			TableStorno.ByAssemblyDisassemblyOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|				AND TableStorno.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
		|
		|			OR TableStorno.ByAssemblyDisassemblyOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|				AND TableStorno.AssemblyType = VALUE(Enum.InventoryMovementTypes.Inpayment))
		|
		|		AND TableStorno.Active";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Return QueryText;
	
EndFunction

Function RequestTextReverseInvoiceKit()
	
	QueryText =
		"	SELECT
		|		TableStorno.ByAssemblyDisassemblyOrder      AS OrderDocument,
		|		TableStorno.RowCode          AS RowCode,
		|
		|		TableStorno.ToRegister        AS QuantityInOrder,
		|		0                                AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableStorno.Products       AS Products,
		|		TableStorno.Characteristic     AS Characteristic,
		|
		|		CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|
		|					DocumentData.Purpose
		|
		|				WHEN DocumentData.WithAssignment THEN
		|
		|					DocumentData.Purpose
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|
		|			END                            AS Purpose,
		|
		|		CASE WHEN DocumentData.BatchesIndicationStatus = 10 THEN
		|					VALUE(Catalog.ItemsBatches.EmptyRef)
		|				ELSE
		|					TableStorno.Series
		|			END                            AS Series,
		|
		|		DocumentData.Date                 AS Date,
		|		0                                    AS LineNumber,
		|		DocumentData.AssemblyDisassemblyStart AS DateOfShipment,
		|		FALSE                                 AS ExistsInTheDocument,
		|
		|		DocumentData.Package             AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		AccumulationRegister.AssemblyOrders AS TableStorno
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentData
		|			ON TableStorno.ByAssemblyDisassemblyOrder = DocumentData.Ref
		|
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND TableStorno.ByAssemblyDisassemblyOrder IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument
		|			FROM
		|				TTOrdersSelection AS Table)
		|
		|		// It is necessary to receive one hundred sets only.
		|		AND(
		|			TableStorno.ByAssemblyDisassemblyOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|				AND TableStorno.AssemblyType = VALUE(Enum.InventoryMovementTypes.Inpayment)
		|
		|			OR TableStorno.ByAssemblyDisassemblyOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|				AND TableStorno.AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment))
		|
		|		AND TableStorno.Active";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"DocumentData.Package",
			"DocumentData.Products"));
	
	Return QueryText;
	
EndFunction

Function RequestTextNewTrafficInvoiceComponents()
	
	QueryText =
		"	SELECT
		|		Table.OrderDocument       AS OrderDocument,
		|		Table.RowCode   AS RowCode,
		|		0                   AS QuantityInOrder,
		|		Table.Count  AS QuantityInInvoice,
		|
		|		// Background information.
		|		Table.Products          AS Products,
		|		Table.Characteristic        AS Characteristic,
		|		Table.Purpose            AS Purpose,
		|		Table.Series                 AS Series,
		|		UNDEFINED                  AS Date,
		|		Table.LineNumber           AS LineNumber,
		|		UNDEFINED                  AS DateOfShipment,
		|		TRUE                        AS ExistsInTheDocument,
		|
		|		Table.Package              AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		TTInvoice AS Table";
		
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure)",
			"CAST(Table.Products AS Catalog.Products)"));
	
	Return QueryText;
	
EndFunction

Function TextOfRequestRemainsOfRegisterOrdersAndReverseOfDocumentSet()
	
	QueryText =
		"SELECT
		|	MAX(Set.Products)   AS Products,
		|	MAX(Set.Characteristic) AS Characteristic,
		|
		|	MAX(Set.Purpose)     AS Purpose,
		|	MAX(Set.Package)       AS Package,
		|
		|	SUM(Set.Count)                   AS Count,
		|	SUM(Set.Count)
		|		/ MAX(Set.PackageFactor) AS NumberOfPackages,
		|	MAX(Set.PackageFactor) AS PackageFactor
		|FROM(
		|	SELECT
		|		TableBalance.Products   AS Products,
		|		TableBalance.Characteristic AS Characteristic,
		|
		|		CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|
		|					DocumentData.Purpose
		|
		|				WHEN DocumentData.WithAssignment THEN
		|
		|					DocumentData.Purpose
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|
		|			END                                         AS Purpose,
		|
		|
		|		DocumentData.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		TableBalance.ToRegisterBalance AS Count
		|
		|	FROM
		|		AccumulationRegister.AssemblyOrders.Balance(,
		|				ByAssemblyDisassemblyOrder IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument
		|					FROM
		|						TTOrdersSelection AS Table)) AS TableBalance
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentData
		|			ON TableBalance.ByAssemblyDisassemblyOrder = DocumentData.Ref
		|
		|			// The use of communication by nomenclature allows you to always receive the remnants of kits, and not components.
		|			 AND TableBalance.Products   = DocumentData.Products
		|			 AND TableBalance.Characteristic = DocumentData.Characteristic
		|
		|	UNION ALL
		|
		|	SELECT
		|		TableStorno.Products   AS Products,
		|		TableStorno.Characteristic AS Characteristic,
		|
		|		CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents) THEN
		|
		|					DocumentData.Purpose
		|
		|				WHEN DocumentData.WithAssignment THEN
		|
		|					DocumentData.Purpose
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|
		|			END                            AS Purpose,
		|
		|		DocumentData.Package  AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		TableStorno.ToRegister AS Count
		|	FROM
		|		AccumulationRegister.AssemblyOrders AS TableStorno
		|
		|			INNER JOIN Document.ByAssemblyDisassemblyOrder AS DocumentData
		|			ON DocumentData.Ref = &Recorder
		|
		|			// The use of communication by nomenclature allows you to always receive the remnants of kits, and not components.
		|			 AND TableStorno.Products   = DocumentData.Products
		|			 AND TableStorno.Characteristic = DocumentData.Characteristic
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND TableStorno.ByAssemblyDisassemblyOrder IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument
		|			FROM
		|				TTOrdersSelection AS Table)
		|		AND TableStorno.Active) AS Set
		|;
		|
		|///////////////////////////////////////////////////////
		|";
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"DocumentData.Package",
			"DocumentData.Products"));
	
	Return QueryText;
	
EndFunction

Function TextOfRequestRemainsOfSeriesOfDisassembledSetAndReverseDocument()
	
	QueryText =
		"SELECT
		|	Set.Products   AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Series          AS Series,
		|
		|	SUM(Set.Count) AS Count
		|FROM(
		|	SELECT
		|		TableBalance.Products       AS Products,
		|		TableBalance.Characteristic     AS Characteristic,
		|		TableBalance.Series              AS Series,
		|		TableBalance.ToRegisterBalance AS Count
		|
		|	FROM
		|		AccumulationRegister.AssemblyOrders.Balance(,
		|				ByAssemblyDisassemblyOrder IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument
		|					FROM
		|						TTOrdersSelection AS Table)
		|				AND AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
		|				AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS TableBalance
		|
		|	UNION ALL
		|
		|	SELECT
		|		TableStorno.Products   AS Products,
		|		TableStorno.Characteristic AS Characteristic,
		|		TableStorno.Series          AS Series,
		|		TableStorno.ToRegister    AS Count
		|	FROM
		|		AccumulationRegister.AssemblyOrders AS TableStorno
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND AssemblyType = VALUE(Enum.InventoryMovementTypes.Shipment)
		|		AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND TableStorno.ByAssemblyDisassemblyOrder IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument
		|			FROM
		|				TTOrdersSelection AS Table)
		|		AND TableStorno.Active) AS Set
		|GROUP BY
		|	Set.Products, Set.Characteristic, Set.Series
		|;
		|
		|////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextCollectedParsedComponents()
	
	QueryText =
		"SELECT
		|	TableBalance.DocumentShipments       AS ByAssemblyDisassemblyOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Purpose             AS Purpose,
		|	TableBalance.Series                  AS Series,
		|	1                                     AS PackageFactor,
		|	
		|	SUM(CASE WHEN TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|		END)                            AS AssemblyInProgress,
		|	
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &FillInAsNeeded AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled)         AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsForIssue AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentShipments
		|		 AND TableBalance.Active
		|		 AND Table.ThisIsBuild
		|
		|GROUP BY
		|	TableBalance.DocumentShipments,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Purpose, TableBalance.Series
		|
		|HAVING
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &ItIsGoingToTakeIntoAccount AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	TableBalance.DocumentInflow    AS ByAssemblyDisassemblyOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Purpose             AS Purpose,
		|	TableBalance.Series                  AS Series,
		|	1                                     AS PackageFactor,
		|	
		|	0                                     AS AssemblyInProgress,
		|	
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|					TableBalance.ToRegisterGoodsReceipts
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegisterGoodsReceipts
		|				ELSE
		|					0
		|			END)                        AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsToReceive AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentInflow
		|		 AND TableBalance.Active
		|		 AND NOT Table.ThisIsBuild
		|
		|GROUP BY
		|	TableBalance.DocumentInflow,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Purpose, TableBalance.Warehouse, TableBalance.Series
		|
		|HAVING
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|						TableBalance.ToRegister
		|					ELSE
		|						0
		|				END
		|			+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|						- TableBalance.ToRegister
		|					ELSE
		|						0
		|				END) > 0
		|
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextCollectedParsedSet()
	
	QueryText =
		"SELECT
		|	TableBalance.DocumentShipments       AS ByAssemblyDisassemblyOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Purpose             AS Purpose,
		|	CASE WHEN Table.SeriesAreIndicatedInSeparateTabularPart THEN
		|				VALUE(Catalog.ItemsBatches.EmptyRef)
		|			ELSE
		|				TableBalance.Series
		|		END AS Series,
		|	1                                     AS PackageFactor,
		|	
		|	SUM(CASE WHEN TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END)                        AS AssemblyInProgress,
		|	
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &FillInAsNeeded AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled)         AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsForIssue AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentShipments
		|		 AND TableBalance.Active
		|		 AND NOT Table.ThisIsBuild
		|
		|GROUP BY
		|	TableBalance.DocumentShipments,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Purpose,
		|	CASE WHEN Table.SeriesAreIndicatedInSeparateTabularPart THEN
		|				VALUE(Catalog.ItemsBatches.EmptyRef)
		|			ELSE
		|				TableBalance.Series
		|		END
		|
		|HAVING
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &ItIsGoingToTakeIntoAccount AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	TableBalance.DocumentInflow    AS ByAssemblyDisassemblyOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Purpose             AS Purpose,
		|	TableBalance.Series                  AS Series,
		|	1                                     AS PackageFactor,
		|	
		|	0                                     AS AssemblyInProgress,
		|	
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|					TableBalance.ToRegisterGoodsReceipts
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegisterGoodsReceipts
		|				ELSE
		|					0
		|		END)                            AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsToReceive AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentInflow
		|		 AND TableBalance.Active
		|		 AND Table.ThisIsBuild
		|
		|GROUP BY
		|	TableBalance.DocumentInflow,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Purpose, TableBalance.Warehouse, TableBalance.Series
		|
		|HAVING
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
		|						TableBalance.ToRegisterGoodsReceipts
		|					ELSE
		|						0
		|				END
		|			+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|						- TableBalance.ToRegisterGoodsReceipts
		|					ELSE
		|						0
		|				END) > 0
		|
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextParsedSeries()
	
	QueryText =
		"SELECT
		|	TableBalance.DocumentShipments       AS ByAssemblyDisassemblyOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Purpose             AS Purpose,
		|	TableBalance.Series                  AS Series,
		|	
		|	SUM(CASE WHEN TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END)                        AS AssemblyInProgress,
		|	
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &FillInAsNeeded AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled)         AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsForIssue AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentShipments
		|		 AND TableBalance.Active
		|		 AND Table.SeriesAreIndicatedInSeparateTabularPart
		|
		|GROUP BY
		|	TableBalance.DocumentShipments,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Purpose,
		|	TableBalance.Series
		|
		|HAVING
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &ItIsGoingToTakeIntoAccount AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled) > 0
		|
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function MergeRequestText(Names, Texts)
	
	MergeText = "";
	ThisIsFirstBlock = True;
	
	For Each Name In Names Do
		
		If ThisIsFirstBlock Then
			ThisIsFirstBlock = False;
		Else
			
			MergeText = MergeText + "
			                                      |
			                                      |	UNION ALL
			                                      |
			                                      |";
			
		EndIf;
		
		MergeText = MergeText + Texts[Name];
		
	EndDo;
	
	QueryText =
		"SELECT
		|	Set.OrderDocument             AS ByAssemblyDisassemblyOrder,
		|	Set.RowCode         AS RowCode,
		|
		|	Set.Products          AS Products,
		|	Set.Characteristic        AS Characteristic,
		|	Set.Series                 AS Series,
		|	MAX(Set.Purpose)  AS Purpose,
		|	MAX(Set.Date)                  AS Date,
		|	MAX(Set.LineNumber)           AS LineNumber,
		|	MAX(Set.DateOfShipment)          AS DateOfShipment,
		|	MAX(Set.ExistsInTheDocument) AS ExistsInTheDocument,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				Set.Package
		|			ELSE
		|				UNDEFINED
		|		END)                             AS PackingOfConsignmentNote,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				UNDEFINED
		|			ELSE
		|				Set.Package
		|		END)                             AS OrderPackage,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				Set.PackageFactor
		|			ELSE
		|				UNDEFINED
		|		END)                             AS PackingOfConsignmentNote_,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				UNDEFINED
		|			ELSE
		|				Set.PackageFactor
		|		END)                             AS OrderPackingRatio,
		|
		|
		|	SUM(Set.QuantityInOrder)        AS QuantityInOrder,
		|	SUM(Set.QuantityInInvoice)     AS QuantityInInvoice
		|
		|FROM MergeText AS Set
		|
		|GROUP BY
		|	Set.OrderDocument, Set.RowCode,
		|	Set.Products, Set.Characteristic, Set.Series,
		|	CASE WHEN Set.RowCode <> 0 THEN
		|				0
		|			ELSE
		|				Set.LineNumber
		|		END
		|
		|HAVING
		|	SUM(Set.QuantityInOrder) > 0 OR SUM(Set.QuantityInInvoice) > 0
		|
		|ORDER BY
		|	Date, OrderDocument, LineNumber
		|;
		|
		|/////////////////////////////////////////////////////////////////////
		|";
	
	QueryText = StrReplace(QueryText, "MergeText", "(" + MergeText + ")");
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts = Undefined)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Goods"" 									AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED 								AS VATRate,
	|	CASE
	|		WHEN ISNULL(DocumentTable.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentTable.Purpose.VATActivityType
	|		ELSE DocumentData.AssemblyForActivity
	|	END 										AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	DocumentTable.LineNumber				AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.AssemblyFromComponents.Goods AS DocumentTable
	|	INNER JOIN Document.AssemblyFromComponents AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|
	|UNION ALL
	|
	|SELECT
	|	""Header"" 									AS TabularSectionName,
	|	0 											AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED 								AS VATRate,
	|	CASE
	|		WHEN ISNULL(DocumentData.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentData.Purpose.VATActivityType
	|		ELSE DocumentData.AssemblyForActivity
	|	END 										AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	0											AS RowCode
	|FROM
	|	Document.AssemblyFromComponents AS DocumentData
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentData.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DocumentExecutionStateReport

Function TemporaryTableGoodsOrderInvoiceShippedForStateOfExecutionReport()
	
	QueryText = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	SUM(DocumentGoods.Count) AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.Ref.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|INTO TTGoodsNotShipped
		|FROM
		|	Document.AssemblyFromComponents.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND TTDocuments.Posted
		|	AND DocumentGoods.Ref.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
		|	DocumentGoods.Ref.Warehouse,
		|	TTDocuments.DocumentRef
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Count AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|FROM
		|	Document.AssemblyFromComponents AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	TTDocuments.Posted
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND DocumentGoods.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|;
		|";
	
	Return QueryText;
	
EndFunction

Function TemporaryGoodsReceiptTableForProgressStateReport()
	
	QueryText = "
		|SELECT ALLOWED
		|	Set.DocumentInflow AS DocumentInflow,
		|	Set.Products        AS Products,
		|	Set.Characteristic      AS Characteristic,
		|	Set.Warehouse               AS Warehouse,
		|
		|	FALSE                      AS SeparatePurchase,
		|
		|	SUM(Set.Accepts) AS Accepts,
		|	SUM(Set.Accepted)     AS Accepted,
		|	SUM(Set.Accept)     AS Accept,
		|	SUM(Set.Received)   AS Received,
		|
		|	SUM(Set.ToReceive) AS ToReceive,
		|	SUM(Set.ApplyAppearance)     AS ApplyAppearance,
		|	SUM(Set.Issued_1)    AS Issued_1,
		|
		|	MAX(Set.AdvancedWarehousingOnGoodsReceipt) AS AdvancedWarehousingOnGoodsReceipt
		|
		|INTO TTGoodsArrival
		|FROM(
		|	SELECT
		|		GoodsToReceive.DocumentInflow AS DocumentInflow,
		|		GoodsToReceive.Products        AS Products,
		|		GoodsToReceive.Characteristic      AS Characteristic,
		|		GoodsToReceive.Warehouse               AS Warehouse,
		|
		|		GoodsToReceive.AcceptsClosingBalance  AS Accepts,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense    AS Accepted,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterClosingBalance AS Accept,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense    AS Received,
		|
		|		0                                              AS ToReceive,
		|		0                                              AS ApplyAppearance,
		|		0                                              AS Issued_1,
		|
		|		CASE WHEN GoodsToReceive.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsToReceive.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|	FROM
		|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers( , , , ,
		|				DocumentInflow IN(
		|					SELECT
		|						TTDocuments.DocumentRef
		|					FROM
		|						TTDocuments AS TTDocuments)) AS GoodsToReceive
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsForRegistration.Ref             AS DocumentInflow,
		|		GoodsForRegistration.Products       AS Products,
		|		GoodsForRegistration.Characteristic     AS Characteristic,
		|		GoodsForRegistration.Ref.Warehouse       AS Warehouse,
		|
		|		0                                    AS Accepts,
		|		0                                    AS Accepted,
		|		0                                    AS Accept,
		|		0                                    AS Received,
		|
		|		GoodsForRegistration.Count         AS ToReceive,
		|		0                                    AS ApplyAppearance,
		|		GoodsForRegistration.Count         AS Issued_1,
		|
		|		CASE WHEN GoodsForRegistration.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsForRegistration.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|FROM
		|	Document.AssemblyFromComponents.Goods AS GoodsForRegistration
		|WHERE
		|	GoodsForRegistration.Ref.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|	AND GoodsForRegistration.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND GoodsForRegistration.Ref IN(
		|		SELECT
		|			TTDocuments.DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsForRegistration.Ref             AS DocumentInflow,
		|		GoodsForRegistration.Products       AS Products,
		|		GoodsForRegistration.Characteristic     AS Characteristic,
		|		GoodsForRegistration.Warehouse              AS Warehouse,
		|
		|		0                                    AS Accepts,
		|		0                                    AS Accepted,
		|		0                                    AS Accept,
		|		0                                    AS Received,
		|
		|		GoodsForRegistration.Count         AS ToReceive,
		|		0                                    AS ApplyAppearance,
		|		GoodsForRegistration.Count         AS Issued_1,
		|
		|		CASE WHEN GoodsForRegistration.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsForRegistration.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|FROM
		|	Document.AssemblyFromComponents AS GoodsForRegistration
		|WHERE
		|	GoodsForRegistration.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|	AND GoodsForRegistration.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND GoodsForRegistration.Ref IN(
		|		SELECT
		|			TTDocuments.DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)) AS Set
		|GROUP BY
		|	Set.DocumentInflow,
		|	Set.Products, Set.Characteristic, Set.Warehouse
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////";
	
	Return QueryText;
	
EndFunction

Function TemporaryTableGoodsOrdersReceiptInvoiceForStateOfExecutionReport()
	
	QueryText = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	SUM(DocumentGoods.Count) AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Ref.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|INTO TTGoodsNewArrival
		|FROM
		|	Document.AssemblyFromComponents.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	TTDocuments.Posted
		|	AND DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
		|	AND DocumentGoods.Ref.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Ref.Warehouse,
		|	TTDocuments.DocumentRef
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.Count AS Count,
		|	0 AS AmountIncludingVAT,
		|	DocumentGoods.Warehouse AS Warehouse,
		|	TTDocuments.DocumentRef AS Ref
		|FROM
		|	Document.AssemblyFromComponents AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	TTDocuments.Posted
		|	AND DocumentGoods.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)
		|	AND DocumentGoods.ByAssemblyDisassemblyOrder = VALUE(Document.ByAssemblyDisassemblyOrder.EmptyRef)
		|;
		|";
	
	Return QueryText;
	
EndFunction

#EndRegion



#Region VATActivityType

Function ParametersForFillingInVATActivityType(Document) Export
	
	Attributes = New Structure("Date, Organization, Warehouse, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.AssemblyFromComponents") Then
		Attributes = Common.ObjectAttributesValues(Document, Attributes);
	Else
		FillPropertyValues(Attributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date = Attributes.Date;
	FillParameters.Warehouse = Attributes.Warehouse;
	FillParameters.Organization = Attributes.Organization;
	FillParameters.LineOfBusiness = Attributes.LineOfBusiness;
	
	FillParameters.AssemblyDisassemblyOfGoods = True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
