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
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses"); // to generate a table of register changes
	DocumentMechanisms.Add("InventoryInOperation");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	InventoryConsumptionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryConsumption") Then
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
		
		QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers);
		QueryTextTableInventoryInOperation(Query, QueryTexts, Registers);
		InventoryConsumptionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.InventoryConsumption);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
		
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.InventoryConsumption - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export

	QueryTexts = New ValueList;
	Query        = FillInInitialParameters(DocumentRef, QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.InventoryConsumption) AS KindOfTransactionWithExcisableGoods,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|	AND (TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|		OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|		OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0)";
	
	QueryTexts.Add(QueryText);

	Results = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	Return Results[Results.UBound()];
	
EndFunction

// We are forming a request to receive data to fill in the register of "Movement on other assets and liabilities".
//
// Parameters:
//	DocumentRef - DocumentRef.InventoryConsumption - link to the document.
//
// Returns:
//	QueryResult - data on movements of other assets and liabilities.
//
Function GetDataOnOtherAssetsLiabilities(DocumentRef) Export
	
	QueryTexts = New ValueList;
	Query        = FillInInitialParameters(DocumentRef, QueryTexts);
	
	Registers = New Structure;
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	Registers.Insert(RegisterName, Undefined);
	
	QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
	Results = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	Return Results[Results.UBound()];

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
	
	Documents.OtherGoodsRecordingAsReceived.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	CommandCorrection = DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	If CommandCorrection <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CommandCorrection,
			"BusinessOperation",
			Enums.BusinessTransactions.GoodsConsumptionOnDemand,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	TheStornoTeam = DocumentCorrection.AddReverseCommand(
		GenerationCommands,
		EmptyRef().Metadata());
	
	If TheStornoTeam <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			TheStornoTeam,
			"BusinessOperation",
			Enums.BusinessTransactions.GoodsConsumptionOnDemand,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	Documents.RMOrder.AddGenerateCommand(GenerationCommands);
	Documents.RMRequest.AddGenerateCommand(GenerationCommands);
	InventoryConsumptionLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "Internal Consumption".
//
// Parameters:
//  GenerationCommands - ValueTable - command table
// Returns:
//  ValueTableRow, Undefined - added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryConsumption) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryConsumption.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryConsumption);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseInventoryConsumption";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document "Internal Consumption".
//
// Parameters:
//  GenerationCommands - ValueTable - command table
// Returns:
//  ValueTableRow, Undefined - added command.
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryConsumption) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateInternalConsumptionBasedOnOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryConsumption.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryConsumption);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseInventoryConsumption";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command to create a document "Internal Consumption".
//
// Parameters:
//  GenerationCommands - ValueTable - command table
// Returns:
//  ValueTableRow, Undefined - added command.
Function AddCreateBasedOnExpenseWriteOffAssetsCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryConsumption) And GetFunctionalOption("UseInventoryConsumption") Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.WriteOffForExpensesAssetsBasedOn";
		CreateBasedOnCommand.Id = "WriteOffForExpensesAssetsBasedOn";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Ghi giảm vào chi phí / tài sản';
												|ru = 'Списание на расходы / активы';
												|en = 'Incur as expenses/assets'; fa = 'منظور به‌عنوان هزینه/دارایی';
												|it = 'Storno sulla voce di spese/ attivi';
												|pl = 'Spisanie w koszty / aktywa';
												|tr = 'Giderlere / varlıklara yaz'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "NotBaseVersion";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds the command to create the document "Internal consumption of goods".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateCommandBasedOnCommissioning(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.InventoryConsumption) 
		And GetFunctionalOption("UseInventoryConsumption") Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.TransferToOperationOnBasisOf";
		CreateBasedOnCommand.Id = "TransferToOperationOnBasisOf";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Đưa vào sử dụng';
												|ru = 'Передача в эксплуатацию';
												|en = 'Commissioning'; fa = 'بهره‌برداری';
												|it = 'Consegna in esercizio';
												|pl = 'Przekazanie do eksploatacji';
												|tr = 'Ekipman çıkışı'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "NotBaseVersion";
		
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
	
	InventoryConsumptionLocalization.AddReportCommands(ReportsCommands, Parameters);

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
	FillParameters.Insert("FormIsOpen",          False);
	FillParameters.Insert("ObjectForm",          Undefined);
	FillParameters.Insert("FillByWarehouseDocument",     Undefined);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	FillParameters.Insert("Warehouse",                 Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("Organization",           Catalogs.Companies.EmptyRef());
	FillParameters.Insert("Department",         Catalogs.BusinessStructure.EmptyRef());
	FillParameters.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	FillParameters.Insert("FilterByWarehouse",         True);
	FillParameters.Insert("ExpenseLineOfBusinessIsSpecifiedInList", False);
	
	FillParameters.Insert("DocumentName",          "InventoryConsumption");
	FillParameters.Insert("RegisterNameOrder",      "InventoryConsumptionOrders");
	FillParameters.Insert("FieldNameOrder",          "InventoryConsumptionOrder");
	
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
	
	If Not ValueIsFilled(FillParameters.Warehouse) Then
		FillParameters.Warehouse = HeaderAttributes.Warehouse;
	EndIf;
	
	FillParameters.Organization				= HeaderAttributes.Organization;
	FillParameters.Department			= HeaderAttributes.Department;
	FillParameters.BusinessOperation	= HeaderAttributes.BusinessOperation;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		FillParameters.FillByWarehouseDocument = InvoicesServer.FillByWarehouseDocument(FillParameters.Warehouse);
	EndIf;
	
	FillParameters.ExpenseLineOfBusinessIsSpecifiedInList = ToIncicializeAreasOfActivityOfExpenses(AnArrayOfOrders);
	
EndProcedure

// Returns the maximum value of the Attribute line of business of expenses for orders.
//
// Parameters:
//  AnArrayOfOrders - Array of DocumentRef.InventoryConsumptionOrder, DocumentRef.RMOrder - links to the orders.
// Returns:
//   Boolean - the value of the direction of expenditure.
//
Function ToIncicializeAreasOfActivityOfExpenses(AnArrayOfOrders) Export
	
	ExpenseLineOfBusinessIsSpecifiedInList = False;
	
	QueryTexts = New Array();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	InventoryConsumptionOrder.Ref AS OrderDocument,
			|	InventoryConsumptionOrder.ExpenseLineOfBusinessIsSpecifiedInList AS ExpenseLineOfBusinessIsSpecifiedInList
			|INTO TTOrdersSelection
			|FROM
			|	Document.InventoryConsumptionOrder AS InventoryConsumptionOrder
			|WHERE
			|	InventoryConsumptionOrder.Ref IN (&References)
			|	AND InventoryConsumptionOrder.Posted";
		QueryTexts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT DISTINCT
			|	RMOrder.Ref AS OrderDocument,
			|	FALSE AS ExpenseLineOfBusinessIsSpecifiedInList
			|FROM
			|	Document.RMOrder AS RMOrder
			|WHERE
			|	RMOrder.Ref IN (&References)
			|	AND RMOrder.Posted";
		QueryTexts.Add(Text);
		
	EndIf;
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = QueryText + "
		|
		|;
		|
		|//////////////////////////////////////////////////
		|";
		
	QueryText =  QueryText + 
		"SELECT
		|	ISNULL(MAX(TTOrdersSelection.ExpenseLineOfBusinessIsSpecifiedInList), FALSE) AS LBOfExpensesInvoice
		|FROM
		|	TTOrdersSelection AS TTOrdersSelection";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("References", AnArrayOfOrders);
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		Selection = QueryResult.Select();
		If Selection.Next() Then
			ExpenseLineOfBusinessIsSpecifiedInList = Selection.LBOfExpensesInvoice;
		EndIf;
	EndIf;
	
	Return ExpenseLineOfBusinessIsSpecifiedInList;
	
EndFunction

// Returns the result of a request to fill in an invoice for orders/orders
//
// Parameters:
//  SelectionData_   - Structure - fields that will be used to select order balances for filling in the document
//  CallContext - String - defines the context of the procedure call: "Selection", "Filling In".
//
// Returns:
//  Structure - a structure containing a selection of the query result and additional data to fill in.
//
Function RequestResultForOrderBalances(SelectionData_, CallContext) Export
	
	// Description of all possible request parameters.
	QueryParameters = New Structure("SelectByOrder_, AnArrayOfOrders,
	                                    |Organization, Warehouse, BusinessOperation, SalesOpportunity,
	                                    |Recorder, InvoiceGoods, InvoiceForOrders");
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
		
		RequestParametersForOrderReplenishment(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	ElsIf CallContext = "FillingInOrders" Then
		
		RequestParametersToFillInForOrders(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	EndIf;
	
	// Filling on the basis of repair orders is always done in one warehouse.
	If SelectionData_.Property("HeaderAttributes") And SelectionData_.HeaderAttributes.Property("Warehouse") Then
		QueryParameters.Warehouse = SelectionData_.HeaderAttributes.Warehouse;
	EndIf;
	// Description of all possible query texts.
	QueriesTexts = New Map();
	QueriesTexts.Insert("TTOrdersSelection",    QueryTextOfTemporaryOrderTable());
	QueriesTexts.Insert("TTLBOfExpensesIsIndicatedInList",    QueryTextOfTemporaryTableOfLBExpenses());
	QueriesTexts.Insert("TTInvoice",      RequestTextForTemporaryInvoiceTable());
	QueriesTexts.Insert("TableShipped", RequestTextShippedByOrders());
	
	// The subqueries used to form the "Form Table" table must be wrapped by the Textquery method(...).
	SubqueryTexts_ = New Map();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		SubqueryTexts_.Insert("BlockRegisterOrders",          RequestTextUpperCaseOrders());
		SubqueryTexts_.Insert("StornoInvoiceBlock",        RequestTextInvoice());
	EndIf;
	SubqueryTexts_.Insert("BlockNewRegisteredRecordsInvoice", RequestTextNewTrafficInvoice());
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		SubqueryTexts_.Insert("BlockRegisterOrdersRepairs",   RequestTextRegisterBalancesOrdersRepairs());
		SubqueryTexts_.Insert("BlockStornoOverheadRepairs", RequestTextReverseInvoiceRepairs());
	EndIf;
	For Each Item In ListOfRequests Do
		Item.Presentation = QueriesTexts[Item.Value];
	EndDo;
	
	Item = ListOfRequests.FindByValue("TableOfContents_");
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

// Creates a structure for creating internal consumption of goods for one or more internal
// heating orders/repair orders If the header details differ in the transmitted orders, an error message is issued.
//
// Parameters:
//  ReferencesArrray - Array - domestic consumption orders for which you need to enter an invoice
//  OrderProperties_ - Structure - the structure where the header details from the order array will be placed.
//
// Returns:
//  Boolean - False if the details of the header differ in the transferred orders.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	QueryTexts = New Array();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	OrderDocument.BusinessOperation AS BusinessOperation,
			|	OrderDocument.Organization AS Organization,
			|	OrderDocument.Department AS Department,
			|	CASE
			|		WHEN COUNT(DISTINCT
			|			CASE
			|				WHEN OrderingProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
			|					THEN VALUE(Catalog.Warehouses.EmptyRef)
			|				ELSE OrderDocument.Warehouse
			|			END) = 1
			|			THEN MAX(OrderDocument.Warehouse)
			|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
			|	END AS Warehouse,
			|	OrderDocument.SalesOpportunity AS SalesOpportunity,
			|	OrderDocument.ConsumptionForActivity AS ConsumptionForActivity,
			|	OrderDocument.LineOfBusiness AS LineOfBusiness,
			|	OrderDocument.ExpenseLineOfBusinessIsSpecifiedInList AS ExpenseLineOfBusinessIsSpecifiedInList
			|FROM
			|	Document.InventoryConsumptionOrder AS OrderDocument
			|	
			|	INNER JOIN Document.InventoryConsumptionOrder.Goods AS OrderingProducts
			|	ON OrderDocument.Ref = OrderingProducts.Ref
			|
			|WHERE
			|	OrderDocument.Ref = &OrderDocument
			|
			|GROUP BY
			|	OrderDocument.BusinessOperation,
			|	OrderDocument.Organization,
			|	OrderDocument.Department,
			|	OrderDocument.SalesOpportunity,
			|	OrderDocument.ConsumptionForActivity,
			|	OrderDocument.LineOfBusiness,
			|	OrderDocument.ExpenseLineOfBusinessIsSpecifiedInList
			|";
		QueryTexts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT
			|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) AS BusinessOperation,
			|	OrderDocument.Organization AS Organization,
			|	OrderDocument.Department AS Department,
			|	CASE WHEN COUNT(DISTINCT UsedMaterials.Warehouse) = 1 THEN
			|		MAX(UsedMaterials.Warehouse)
			|	ELSE
			|		VALUE(Catalog.Warehouses.EmptyRef)
			|	END AS Warehouse,
			|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
			|	OrderDocument.ConsumptionForActivity AS ConsumptionForActivity,
			|	OrderDocument.LineOfBusiness AS LineOfBusiness,
			|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS ExpenseLineOfBusinessIsSpecifiedInList
			|FROM
			|	Document.RMOrder AS OrderDocument
			|		INNER JOIN Document.RMOrder.MaterialsAndWorks AS UsedMaterials
			|		ON OrderDocument.Ref = UsedMaterials.Ref
			|WHERE
			|	OrderDocument.Ref = &OrderDocument
			|
			|GROUP BY
			|	OrderDocument.Organization,
			|	OrderDocument.Department,
			|	OrderDocument.ConsumptionForActivity,
			|	OrderDocument.LineOfBusiness";
		QueryTexts.Add(Text);
		
	EndIf;
	Query = New Query();
	Query.Text = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Query.SetParameter("OrderDocument", ReferencesArrray[0]);
	
	HeaderAttributes = New Structure("BusinessOperation, Organization, Warehouse, SalesOpportunity, Department,
		|ConsumptionForActivity, LineOfBusiness, ExpenseLineOfBusinessIsSpecifiedInList");
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(HeaderAttributes, Selection);
	EndIf;
	
	Return HeaderAttributes;
	
EndFunction

// Generates the data necessary to verify the entry of the invoice on the basis of orders.
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
	DataToEnter.Insert("Warehouse");
	DataToEnter.Insert("BusinessOperation");
	
	QueriesTexts = New Array;
	
	Texts = New Array();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	InventoryConsumptionOrder.Ref AS Basis,
			|	InventoryConsumptionOrder.Status AS Status,
			|	InventoryConsumptionOrder.Warehouse  AS Warehouse,
			|	InventoryConsumptionOrder.BusinessOperation AS BusinessOperation
			|FROM
			|	Document.InventoryConsumptionOrder AS InventoryConsumptionOrder
			|WHERE
			|	InventoryConsumptionOrder.Ref IN(&References)";
		Texts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT DISTINCT
			|	RMOrder.Ref AS Basis,
			|	RMOrder.Status AS Status,
			|	RMOrderMaterialsAndWorks.Warehouse AS Warehouse,
			|	VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand) AS BusinessOperation
			|FROM
			|	Document.RMOrder AS RMOrder
			|		LEFT JOIN Document.RMOrder.MaterialsAndWorks AS RMOrderMaterialsAndWorks
			|		ON RMOrder.Ref = RMOrderMaterialsAndWorks.Ref
			|			AND NOT RMOrderMaterialsAndWorks.Canceled
			|WHERE
			|	RMOrder.Ref IN(&References)";
		Texts.Add(Text);
		
	EndIf;
	Text = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	QueriesTexts.Add(Text);
	
	Texts = New Array();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT TOP 1
			|	1
			|FROM
			|	Document.InventoryConsumptionOrder.Goods AS GoodsFromOrder
			|WHERE
			|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|	AND GoodsFromOrder.Ref IN(&References)
			|	AND NOT GoodsFromOrder.Canceled";
		Texts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT TOP 1
			|	1
			|FROM
			|	Document.RMOrder.MaterialsAndWorks AS GoodsFromOrder
			|WHERE
			|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
			|	AND GoodsFromOrder.Ref IN(&References)
			|	AND NOT GoodsFromOrder.Canceled";
		Texts.Add(Text);
		
	EndIf;
	Text = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	
	QueriesTexts.Add(Text);
	
	QueriesTexts.Add(AccumulationRegisters.InventoryConsumptionOrders.QueryTextBalance("TTBalancesForRegistration"));
	QueriesTexts.Add(
		"SELECT DISTINCT
		|	RequirementsForRegistration_1.InventoryConsumptionOrder AS InstructionsForRegistration
		|FROM
		|	TTBalancesForRegistration AS RequirementsForRegistration_1");
	QueriesTexts.Add(
		"SELECT
		|	MAX(RequirementsForRegistration_1.Warehouse) AS Warehouse,
		|	COUNT(DISTINCT RequirementsForRegistration_1.Warehouse) > 1 AS DifferentWarehouses
		|FROM
		|	TTBalancesForRegistration AS RequirementsForRegistration_1");
	
	Query = New Query(StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("References", References);
	Query.SetParameter("Recorder", Undefined);
	Query.SetParameter("FilterByWarehouse", False);
	Query.SetParameter("Warehouse", Undefined);
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	If Selection.Count() = 1 And Selection.Next() Then
		DataToEnter.Basis     = Selection.Basis;
		DataToEnter.Status        = Selection.Status;
		DataToEnter.ThereIsShip = Not Result[1].IsEmpty();
		
		DataToEnter.BusinessOperation = Selection.BusinessOperation;
	EndIf;
	
	If Not Result[3].IsEmpty() Then
		DataToEnter.InstructionsForRegistration = Result[3].Unload().UnloadColumn("InstructionsForRegistration");
		Selection = Result[4].Select();
		If Selection.Next() Then
			DataToEnter.CanBeGrouped = Not Selection.DifferentWarehouses;
			DataToEnter.Warehouse = Selection.Warehouse;
		EndIf;
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
		FilterBusinessTransactions.LoadValues(BusinessOperationsOfDocument());
	EndIf;
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID(Metadata.Documents.InventoryConsumption));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	FilterParameters.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	OpeningParameters = New Structure("FormName, FormParameters");
	OpeningParameters.FormName = "DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration";
	OpeningParameters.FormParameters = New Structure;
	OpeningParameters.FormParameters.Insert("FormAssignmentKey",     "DomesticConsumption");
	OpeningParameters.FormParameters.Insert("QuickFilterStructure", FilterParameters);
	
	Return OpeningParameters;
	
EndFunction

// The procedure fills in the object fields
//
// Parameters:
//  Object				 - DocumentObject.InventoryConsumption	 - object to fill in
//  FillParameters	 - Structure									 - structure containing keys RequisitePro, Iaregistry, Imabalances
//  AnArrayOfOrders		 - Array										 - array of orders.
//
Procedure FillInHeaderOfOrderDocument(Object, FillParameters, AnArrayOfOrders) Export
	
	FillPropertyValues(Object, FillParameters.HeaderAttributes);
	
	Object.Warehouse = FillParameters.Warehouse;
	Object.ConsumptionByOrders = True;
	Object.ExpenseLineOfBusinessIsSpecifiedInList = FillParameters.ExpenseLineOfBusinessIsSpecifiedInList;
	
	Object.Date = CurrentSessionDate();
	
	// Filling out the order(s) in the header.
	If AnArrayOfOrders.Count() = 1 Then
		Object.InventoryConsumptionOrder = AnArrayOfOrders[0];
	Else
		
		OrdersServer.FillInOrderInOrderHeaderInTableSection(
			Object.InventoryConsumptionOrder, 
			Object.Goods, 
			FillParameters.FieldNameOrder);
			
	EndIf;
	
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
	
	If FillParameters.FormIsOpen Then
		FormOrSelectionOptions = FillParameters.ObjectForm;
	Else
		FormOrSelectionOptions = Documents.InventoryConsumption.ItemsAndDimensionsSelectionParameters(FillParameters.BusinessOperation);
	EndIf;
	
	IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts(
		StructureOfActions,
		FormOrSelectionOptions,
		FillParameters.BusinessOperation,
		FillParameters.Organization,
		FillParameters.Department);
		
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Returns an array containing the passed invoice, as well as:
// A. an Order from an array of orders (if there is one element in the array)
// B. All orders that fit the selection by header details.
//
// Parameters:
//  Invoice		 - DocumentRef.InventoryConsumption -
//  HeaderAttributes	 - Structure - It must contain the keys Organization, Warehouse,
//  								Transaction, business Operation, and direction of Activity.
//
// Returns:
//  Array - an array of documents is ordered for internal use, ordered for repair.
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	Query = New Query();
	Query.SetParameter("Recorder",             Invoice);
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("Warehouse",                   HeaderAttributes.Warehouse);
	Query.SetParameter("SalesOpportunity",                  HeaderAttributes.SalesOpportunity);
	Query.SetParameter("BusinessOperation",   HeaderAttributes.BusinessOperation);
	Query.SetParameter("LineOfBusiness", HeaderAttributes.LineOfBusiness);
	
	QueryTexts = New Array();
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT ALLOWED
			|	InventoryConsumptionOrder.Ref AS OrderDocument
			|FROM
			|	Document.InventoryConsumptionOrder AS InventoryConsumptionOrder
			|WHERE
			|	InventoryConsumptionOrder.Organization = &Organization
			|	AND InventoryConsumptionOrder.Warehouse = &Warehouse
			|	AND InventoryConsumptionOrder.SalesOpportunity = &SalesOpportunity
			|	AND InventoryConsumptionOrder.BusinessOperation = &BusinessOperation
			|	AND InventoryConsumptionOrder.LineOfBusiness = &LineOfBusiness
			|	AND InventoryConsumptionOrder.Posted";
		QueryTexts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT DISTINCT
			|	RMOrder.Ref AS OrderDocument
			|FROM
			|	Document.RMOrder AS RMOrder
			|		INNER JOIN Document.RMOrder.MaterialsAndWorks AS Goods
			|		ON RMOrder.Ref = Goods.Ref
			|WHERE
			|	RMOrder.Organization = &Organization
			|	AND (Goods.Warehouse = &Warehouse
			|		OR Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
			|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|	AND RMOrder.LineOfBusiness = &LineOfBusiness
			|	AND RMOrder.Posted";
		QueryTexts.Add(Text);
		
	EndIf;
	Text =
		"SELECT
		|	&Recorder AS OrderDocument";
	QueryTexts.Add(Text);
	
	Query.Text = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	Return Query.Execute().Unload().UnloadColumn("OrderDocument");
	
EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	If GetFunctionalOption("UseInventoryConsumptionForMultipleOrders") Then
		Return "Organization, LineOfBusiness, Department, ConsumptionForActivity";
	Else
		Return "Ref";
	EndIf;
	
EndFunction

Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes) Export
	
	// If you do not need to fill in an order, we pass empty query parameters - an empty table will be returned for orders.
	If FillParameters.FillByWarehouseDocument Then
		ReferencesForOrders = FillParameters.AnArrayOfOrders;
		RegistrarForOrders  = Recorder;
	Else
		ReferencesForOrders = Undefined;
		RegistrarForOrders  = Undefined;
	EndIf;
	
	// Orders
	
	QueryTexts = New Array();
	
	RequestTextForOrders = AccumulationRegisters.InventoryConsumptionOrders.QueryTextBalance("TTAccountingData");
		
	QueryTexts.Add(RequestTextForOrders);
	
	Texts = New Array();
	
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		QueryTextOrderDocument = Documents.InventoryConsumptionOrder.QueryTextDocumentGoods();
		Texts.Add(QueryTextOrderDocument);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Filter = New Structure();
		Filter.Insert("Ref", "References");
		Filter.Insert("Warehouse",  "Warehouse");
		
		QueryTextOrderDocument = Documents.RMOrder.QueryTextDocumentGoods(Filter);
		Texts.Add(QueryTextOrderDocument);
		
	EndIf;
	Text = StrConcat(Texts, TMCommonUse.QuerySeparatorInJoin());
	QueryTexts.Add(Text);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("References",  FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder",   Recorder);
	Query.SetParameter("Warehouse",         FillParameters.Warehouse);
	Query.SetParameter("FilterByWarehouse", FillParameters.FilterByWarehouse);
	Query.SetParameter("ExpenseLineOfBusinessIsSpecifiedInList", FillParameters.ExpenseLineOfBusinessIsSpecifiedInList);
	
	OrdersTable = Query.Execute().Unload();
	
	OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";
	
	// Orders_3
	QueryTexts = New Array;
	
	QueryTexts.Add(
	"SELECT
	|	OrdersTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
	|	OrdersTable.Products                 AS Products,
	|	OrdersTable.Characteristic               AS Characteristic,
	|	OrdersTable.Purpose                   AS Purpose,
	|	OrdersTable.Series                        AS Series,
	|	OrdersTable.Warehouse                        AS Warehouse,
	|	OrdersTable.QuantityInOrder            AS Count
	|INTO OrdersTable
	|FROM
	|	&OrdersTable AS OrdersTable
	|");
	
	Filter = New Map;
	TMCommonUse.AddSelectionItemToCollection(Filter, "Warehouse", "&Warehouse");
	
	QueryTextsBalance = New Array;
	QueryTextsBalance.Add(AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue(Filter));
	
	// Adding jobs
	QueryTextsBalance.Add(
	"SELECT
	|	OrdersTable.InventoryConsumptionOrder AS ReferenceOrder,
	|	OrdersTable.Products                 AS Products,
	|	OrdersTable.Characteristic               AS Characteristic,
	|	OrdersTable.Purpose                   AS Purpose,
	|	OrdersTable.Warehouse                        AS Warehouse,
	|	OrdersTable.Series                        AS Series,
	|	OrdersTable.Count                   AS Count,
	|	0                                          AS AssemblyInProgress
	|FROM
	|	OrdersTable AS OrdersTable
	|	
	|	INNER JOIN Catalog.Products AS CatProducts
	|	ON CatProducts.Ref = OrdersTable.Products
	|
	|WHERE
	|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|");
	
	QueryTexts.Add(StrConcat(QueryTextsBalance, TMCommonUse.QuerySeparatorInJoin()));
	
	Query = New Query();
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("References",  ReferencesForOrders);
	Query.SetParameter("Recorder",   RegistrarForOrders);
	Query.SetParameter("Warehouse",         FillParameters.Warehouse);
	Query.SetParameter("OrdersTable", OrdersTable);
	TableOrders = Query.Execute().Unload();
	
	TableOrders.Columns.Count.Name   = "NoteQuantity";
	TableOrders.Columns.ReferenceOrder.Name = "InventoryConsumptionOrder";
	TableOrders.Columns.AssemblyInProgress.Name = "NumberInProgress";
	
	// Distribution of the resulting tables
	
	Goods.Indexes.Add("InventoryConsumptionOrder, " + FillParameters.KeyFields);
	
	// Adding the number of orders
	Var_Key = "InventoryConsumptionOrder, RowCode, " + FillParameters.KeyFields;
	
	Condition = "On [Count]";
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
	// Adding the number of orders.
	Var_Key = "InventoryConsumptionOrder, " + FillParameters.KeyFields;
	
	// There are invoices and orders
	Condition = "[Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are orders, no invoices
	Condition = "NOT [Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are invoices, no orders
	Condition = "[Count], NOT [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
	
	// Additional information - how much product is collected
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NumberInProgress", Var_Key, "", True);
	
	If ReferencesForOrders <> Undefined Then
		InventoryConsumptionLocalization.FillInBarcodesOfPackages(ReferencesForOrders, Goods, PackageBarcodes);
	EndIf;
	
EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Date,BusinessOperation,Status";
	
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
	SeriesSpecificationParameters.FullObjectName = FullObjectName();
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		
		ItIsPossibleToTakeIntoAccountSeriesInOperation = InventoryInOperationCached.ItIsPossibleToTakeIntoAccountSeriesInOperation();
	
		SeriesSpecificationParameters.UseItemsBatch =
			ItIsPossibleToTakeIntoAccountSeriesInOperation
			Or WarehouseSeriesParameters.UseItemsBatch;
			
		SeriesSpecificationParameters.UseCostAccountingByBatches =
			ItIsPossibleToTakeIntoAccountSeriesInOperation 
			Or WarehouseSeriesParameters.UseCostAccountingByBatches;
		
	Else
		
		SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
		SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		
	EndIf;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentForInternalNeeds);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation
		And Object.Status = Enums.InternalConsumptionStatuses.Accepted Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingInventoryInOperation);
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice	= True;
	SeriesSpecificationParameters.Date	= Object.Date;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");

	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_InventoryConsumptionOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
// 
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//		
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	&Warehouse                     AS Warehouse,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Warehouse             AS Warehouse,
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	&Warehouse               AS Warehouse,
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Count     AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	SetOfSeries.Warehouse             AS Warehouse,
	|	SetOfSeries.Products      AS Products,
	|	SetOfSeries.Characteristic    AS Characteristic,
	|	SetOfSeries.Purpose        AS Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusSender AS OldStatusOfSenderIndication,
	|	Goods.BatchesIndicationStatusRecipient AS OldStatusOfSpecifyingRecipientSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN
	|				CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN
	|							CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE
	|						CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentForInternalNeeds
	|			THEN
	|				CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN
	|							CASE
	|								WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|									THEN 4
	|								ELSE 2
	|							END
	|					ELSE
	|						CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN 3
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusSender,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|				OR NOT &ReceivingInventoryInOperation
	|			THEN 0
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingInventoryInOperation
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 20
	|					ELSE 19
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|		
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|		
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|			AND ProductsToRequest.Warehouse = BatchAccountingPolicies.Warehouse
	|		
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|			ON ProductsToRequest.Warehouse = Warehouses.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber                    AS LineNumber,
	|	Statuses.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Statuses.BatchesIndicationStatusRecipient  AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatusRecipient > 0
	|			THEN Statuses.BatchesIndicationStatusRecipient
	|		ELSE Statuses.BatchesIndicationStatusSender
	|	END                                  AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatusSender <> Statuses.OldStatusOfSenderIndication
	|		OR Statuses.BatchesIndicationStatusRecipient <> Statuses.OldStatusOfSpecifyingRecipientSeries
	|		OR CASE
	|				WHEN Statuses.BatchesIndicationStatusRecipient > 0
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE Statuses.BatchesIndicationStatusSender
	|			END <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//	FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//		of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - order for receipt or shipment.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	If FieldValuesToIdentifyReferences.Goods_RowCode <> 0 Then 
		Return FieldValuesToIdentifyReferences.Goods_InventoryConsumptionOrder;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// The procedure fills in a series of items for expenditure orders issued based on this document.
//
// Parameters:
//  Object - DocumentObject.InventoryConsumption, FormDataStructure - The document to be filled in.
//
Procedure FillInShippingInstructions(Object) Export
	
	ParametersOfUseOfSeriesInStock = New Structure("Warehouse", Object.Warehouse);
	
	SetPrivilegedMode(True);
	ItIsPossibleToTakeIntoAccountSeriesInOperation = False;
	UseItemsBatchWarehouse = GetFunctionalOption("UseItemsBatchWarehouse",
																	ParametersOfUseOfSeriesInStock);
	UseWarehouseManagemantSystemForGoodsIssue = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.Warehouse, Object.Date);
	SetPrivilegedMode(False);
	
	FillingInSeries = ItIsPossibleToTakeIntoAccountSeriesInOperation
						And UseItemsBatchWarehouse
						And UseWarehouseManagemantSystemForGoodsIssue;
	
	If Not FillingInSeries Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT DISTINCT
	|	ConsumptionOfGoods.InventoryConsumptionOrder AS Ref
	|INTO References
	|FROM
	|	&Goods AS ConsumptionOfGoods
	|WHERE
	|	ConsumptionOfGoods.InventoryConsumptionOrder <> &DefaultOrder_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsIssueNotes.Ref AS Ref
	|INTO GoodsIssueNotes
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNotes
	|
	|WHERE
	|	GoodsIssueNotes.Posted
	|	AND GoodsIssueNotes.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.GoodsIssueNote.GoodsByReferences AS Goods
	|			WHERE
	|				Goods.Ref = GoodsIssueNotes.Ref
	|				AND CASE
	|					WHEN &ConsumptionByOrders
	|						THEN Goods.ReferenceOrder IN
	|								(SELECT
	|									References.Ref AS Ref
	|								FROM
	|									References AS References)
	|					ELSE Goods.ReferenceOrder = &Ref
	|				END
	|			)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	ConsumptionOfGoods.Ref AS Ref
	|INTO ConsumptionOfGoods
	|FROM
	|	Document.InventoryConsumption AS ConsumptionOfGoods
	|
	|WHERE
	|	ConsumptionOfGoods.Posted
	|	AND ConsumptionOfGoods.Ref <> &Ref
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.InventoryConsumption.Goods AS Goods
	|			WHERE
	|				Goods.Ref = ConsumptionOfGoods.Ref
	|				AND NOT Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				AND Goods.InventoryConsumptionOrder IN
	|						(SELECT
	|							References.Ref AS Ref
	|						FROM
	|							References AS References)
	|			)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	GoodsIssueNotes AS GoodsIssueNotes
	|		LEFT JOIN Document.GoodsIssueNote.GoodsByReferences AS Goods
	|		ON Goods.Ref = GoodsIssueNotes.Ref
	|			AND NOT CASE
	|				WHEN &ConsumptionByOrders
	|					THEN Goods.ReferenceOrder IN
	|							(SELECT
	|								References.Ref AS Ref
	|							FROM
	|								References AS References)
	|				ELSE Goods.ReferenceOrder = &Ref
	|			END
	|
	|WHERE
	|	NOT Goods.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	ConsumptionOfGoods AS ConsumptionOfGoods
	|		LEFT JOIN Document.InventoryConsumption.Goods AS Goods
	|			ON ConsumptionOfGoods.Ref = Goods.Ref
	|			AND NOT Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND NOT Goods.InventoryConsumptionOrder IN
	|					(SELECT
	|						References.Ref AS Ref
	|					FROM
	|						References AS References)
	|
	|WHERE
	|	NOT Goods.Ref IS NULL";
	
	DefaultOrder_ = Documents.InventoryConsumptionOrder.EmptyRef();
	DefaultOrder_ = Undefined;
	UnloadedColumns = "LineNumber, Products ,Characteristic, Purpose, Count, 
							|InventoryConsumptionOrder";
	Goods = Object.Goods.Unload(, UnloadedColumns);
	
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("ConsumptionByOrders", Object.ConsumptionByOrders);
	Query.SetParameter("DefaultOrder_", DefaultOrder_);
	Query.SetParameter("Goods", Goods);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Query.Text =
	"SELECT
	|	Balance.Products		AS Products,
	|	Balance.Characteristic		AS Characteristic,
	|	Balance.Purpose			AS Purpose,
	|	Balance.Series				AS Series,
	|	SUM(Balance.Count)	AS Count
	|FROM
	|	(SELECT
	|		Goods.Products		AS Products,
	|		Goods.Characteristic	AS Characteristic,
	|		Goods.Purpose		AS Purpose,
	|		Goods.Series			AS Series,
	|		Goods.Count		AS Count
	|	FROM
	|		GoodsIssueNotes AS GoodsIssueNotes
	|			LEFT JOIN Document.GoodsIssueNote.ShippedGoods AS Goods
	|			ON Goods.Ref = GoodsIssueNotes.Ref
	|				AND Goods.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
	|				AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	WHERE
	|		NOT Goods.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Products		AS Products,
	|		Goods.Characteristic	AS Characteristic,
	|		Goods.Purpose		AS Purpose,
	|		Goods.Series			AS Series,
	|		-Goods.Count		AS Count
	|	FROM
	|		ConsumptionOfGoods AS ConsumptionOfGoods
	|			LEFT JOIN Document.InventoryConsumption.Goods AS Goods
	|			ON ConsumptionOfGoods.Ref = Goods.Ref
	|				AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	WHERE
	|		NOT Goods.Ref IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SetOfSeries.Products		AS Products,
	|		SetOfSeries.Characteristic	AS Characteristic,
	|		SetOfSeries.Purpose		AS Purpose,
	|		SetOfSeries.Series				AS Series,
	|		-SetOfSeries.Count		AS Count
	|	FROM
	|		ConsumptionOfGoods AS ConsumptionOfGoods
	|			LEFT JOIN Document.InventoryConsumption.SetOfSeries AS SetOfSeries
	|			ON ConsumptionOfGoods.Ref = SetOfSeries.Ref
	|	WHERE
	|		NOT SetOfSeries.Ref IS NULL
	|	
	|	) AS Balance
	|
	|GROUP BY
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Purpose,
	|	Balance.Series
	|
	|HAVING
	|	SUM(Balance.Count) <> 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.LineNumber		AS LineNumber,
	|	Goods.Products		AS Products,
	|	Goods.Characteristic	AS Characteristic,
	|	Goods.Purpose		AS Purpose,
	|	Goods.Count		AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|WHERE
	|	Goods.Count > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS AllProducts
	|		ON Goods.Products = AllProducts.Ref
	|		
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON AllProducts.ProductKind = ItemKinds.Ref
	|			AND (ISNULL(ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
	|				OR ISNULL(ItemKinds.BatchAccountingPolicy.SpecifyWhenPlanningShipment, FALSE)
	|				OR ISNULL(ItemKinds.BatchAccountingPolicy.SeriesAccountingInventoryInOperation, FALSE))
	|
	|WHERE
	|	NOT ItemKinds.Ref IS NULL
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	Goods.Products			AS Products,
	|	Goods.Characteristic		AS Characteristic,
	|	Goods.Purpose			AS Purpose,
	|	SUM(Goods.Count)	AS Count
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS AllProducts
	|		ON Goods.Products = AllProducts.Ref
	|		
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON AllProducts.ProductKind = ItemKinds.Ref
	|			AND (ISNULL(ItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
	|				OR ISNULL(ItemKinds.BatchAccountingPolicy.SpecifyWhenPlanningShipment, FALSE)
	|				OR ISNULL(ItemKinds.BatchAccountingPolicy.SeriesAccountingInventoryInOperation, FALSE))
	|
	|WHERE
	|	ItemKinds.Ref IS NULL
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose";
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	OrderSeriesTable = QueryResult[0].Unload();
	
	SearchFieldsWithoutSeries_	= "Products, Characteristic, Purpose";
	SearchFieldsWithSeries	= "Products, Characteristic, Purpose, Series";
	
	SelectingRowsWithoutSeries	= New Structure(SearchFieldsWithoutSeries_);
	SelectingRowsWithSeries	= New Structure(SearchFieldsWithSeries);
	
	OrderSeriesTable.Indexes.Add(SearchFieldsWithoutSeries_);
	OrderSeriesTable.Indexes.Add(SearchFieldsWithSeries);
	
	ReadyForProcessing_ = New Array;
	ActionsWithString = New Structure("RecalculateNumberOfPackages");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	SelectingLineNumbersWithSeries = QueryResult[2].Select();
	
	While SelectingLineNumbersWithSeries.Next() Do
		
		RowOfGoods = Object.Goods[SelectingLineNumbersWithSeries.LineNumber - 1];
		
		ProductBalance = RowOfGoods.Count;
		BalanceOfOriginalProduct = ProductBalance;
		
		RowFilter = ?(ValueIsFilled(RowOfGoods.Series), SelectingRowsWithSeries, SelectingRowsWithoutSeries);
		FillPropertyValues(RowFilter, RowOfGoods);
		
		RowsWithSeries_ = OrderSeriesTable.FindRows(RowFilter);
		
		If RowsWithSeries_.Count() Then
			
			FirstRow = True;
			
			For Each RowWithSeries In RowsWithSeries_ Do
				
				If RowWithSeries.Count <= 0 Then
					Continue;
				EndIf;
				
				If Not FirstRow Then
					NewRow = Object.Goods.Add();
					FillPropertyValues(NewRow, RowOfGoods);
					
					RowOfGoods = NewRow;
				EndIf;
				
				FirstRow = False;
				FillingCount = Min(ProductBalance, RowWithSeries.Count);
				
				RowOfGoods.Series = RowWithSeries.Series;
				RowOfGoods.Count = FillingCount;
				
				ReadyForProcessing_.Add(RowOfGoods);
				
				RowWithSeries.Count = RowWithSeries.Count - FillingCount;
				
				ProductBalance = ProductBalance - FillingCount;
				
				If ProductBalance <= 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If ProductBalance > 0 Then
			
			If BalanceOfOriginalProduct > ProductBalance Then
				NewRow = Object.Goods.Add();
				FillPropertyValues(NewRow, RowOfGoods);
				
				RowOfGoods = NewRow;
				RowOfGoods.Count = ProductBalance;
				
				ReadyForProcessing_.Add(RowOfGoods);
			EndIf;
			
			RowOfGoods.Series = Undefined;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		ActionsWithString,
		Object.Goods,
		CachedValues);
	
	Object.SetOfSeries.Clear();
	
	RowFilter = SelectingRowsWithoutSeries;
	
	SampleProducts_ = QueryResult[3].Select();
	
	While SampleProducts_.Next() Do
		
		ProductBalance = SampleProducts_.Count;
		FillPropertyValues(RowFilter, SampleProducts_);
		
		RowsWithSeries_ = OrderSeriesTable.FindRows(RowFilter);
		
		For Each RowWithSeries In RowsWithSeries_ Do
			
			If RowWithSeries.Count = 0 Then
				Continue;
			EndIf;
			
			NewRow = Object.SetOfSeries.Add();
			FillPropertyValues(NewRow, SampleProducts_);
			
			FillingCount = Min(ProductBalance,RowWithSeries.Count);
			
			NewRow.Series = RowWithSeries.Series;
			NewRow.Count = FillingCount;
			
			RowWithSeries.Count = RowWithSeries.Count - FillingCount;
			
			ProductBalance = ProductBalance - FillingCount;
			
			If ProductBalance = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ChangeOfStatus

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
// 		DocumentsArray - Array of DocumentRef.InventoryConsumption - An array of references to documents that should be reviewed
// 		NewStatus - String - Name of the new status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.InternalConsumptionStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	DocumentsTable.BusinessOperation AS BusinessOperation,
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
	|	Document.InventoryConsumption AS DocumentsTable
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
// 		NewStatus - EnumRef.InternalConsumptionStatuses - New status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	MeaningOfNewStatus = Enums.InternalConsumptionStatuses[NewStatus];
	
	If ValidationSample.BusinessOperation <> Enums.BusinessTransactions.TransferToOperation Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %1 chưa đặt trạng thái ""%2"", bởi vì trạng thái không được dùng đối với giao dịch đã chọn trong chứng từ';
						|ru = 'У документа %1 статус ""%2"" не установлен, т.к. статусы не используются для операции, выбранной в документе';
						|en = '""%2"" status of the %1 document is not set as statuses are not used for the operation selected in the document'; fa = '""%2"" status of the %1 document is not set as statuses are not used for the operation selected in the document';
						|it = 'Presso il documento %1 lo stato ""%2"" non è impostato, poiché gli stati non sono utilizzati per le operazioni selezionate nel documento';
						|pl = 'Dla dokumentu %1 status ""%2"" nie jest ustawiony, ponieważ statusy nie są używane dla operacji, wybranej w dokumencie';
						|tr = 'Belgede seçilen işlem için durumlar kullanılmadığından %1 belgesinde ""%2"" durumu ayarlanmamıştır'");
		ErrorText = StrTemplate(ErrorText, ValidationSample.Ref, ValidationSample.PresentationOfNewStatus);
		
		Common.MessageToUser(ErrorText, ValidationSample.Ref,,, Cancel);
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  ValueTable - See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	If GetFunctionalOption("UseInventoryConsumptionStatuses") Then
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.InternalConsumptionStatuses.Shipped);
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.InternalConsumptionStatuses.Accepted);
	EndIf;
	
	Return Table;
	
EndFunction

#EndRegion

#Region Other

// Returns a list of all households. operations used in the document.
// 
// Returns:
// 	Array - A list of all households. operations used in the document.
//
Function BusinessOperationsOfDocument() Export

	TransactionList = New Array;
	TransactionList.Add(Enums.BusinessTransactions.GoodsConsumptionOnDemand);
	TransactionList.Add(Enums.BusinessTransactions.TransferToOperation);
	
	Return TransactionList;
	
EndFunction

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.InventoryConsumption - link to the document.
//
// Returns:
//	Structure - details of domestic consumption of goods.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.InventoryConsumption AS DocumentData
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
		Organization,);
	
	Return AttributesStructure1;

EndFunction

// Fills in an array of details that depend on the business operation of the document.
//
// Parameters:
//  BusinessOperation	 - EnumRef.BusinessTransactions	 -
//  ArrayOfAllProps	 - Array									 - Array of all banking details that depend on the business operation
//  ArrayOfOperationDetails - Array									 - Array of names of Bank details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	ArrayOfAllProps.Add("Goods.Individual");
	ArrayOfAllProps.Add("Goods.OperationCategory");
	ArrayOfAllProps.Add("Goods.AssetID");
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		ArrayOfOperationDetails.Add("Goods.Individual");
		ArrayOfOperationDetails.Add("Goods.OperationCategory");
		ArrayOfOperationDetails.Add("Goods.AssetID");
	EndIf;
	
EndProcedure

// Sets the conditional design of the document type in the dynamic list for the business operation of the document.
//
// Parameters:
//  List - DynamicList - Dynamic form list.
//
Procedure SetConditionalListAppearance(List) Export
	
	FormattedField = "Type";
	
	// Write-off on assets/liabilities
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormattedField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.InventoryConsumption");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi giảm vào chi phí';
													|ru = 'Списание на расходы';
													|en = 'Incur as expenses'; fa = 'منظور به‌عنوان هزینه';
													|it = 'Storno sulle spese';
													|pl = 'Spisanie na wydatki';
													|tr = 'Gider yazma'"));
	
	#Region TransferToOperation
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Type");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.TransferToOperation;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.InventoryConsumption");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đưa vào sử dụng';
													|ru = 'Передача в эксплуатацию';
													|en = 'Commissioning'; fa = 'بهره‌برداری';
													|it = 'Consegna in esercizio';
													|pl = 'Przekazanie do eksploatacji';
													|tr = 'Ekipman çıkışı'"));
	
	#EndRegion
	
EndProcedure

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object - DocumentObject.InventoryConsumption, FormDataStructure - the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	
	FillParameters.Organization             = Object.Organization;
	FillParameters.Date                    = Object.Date;
	FillParameters.Warehouse                   = Object.Warehouse;
	FillParameters.Contract                 = Undefined;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
		FillParameters.WriteOffOfGoodsAndWorksForItems = True;
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToProduction Then
		FillParameters.MovementOfGoodsAndWorksInProduction = True;
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		FillParameters.TransferToOperation = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return InventoryConsumptionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return InventoryConsumptionLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
// Initializes the status structure of the document
//
// Returns:
//  Structure - contains the following keys:
//     * DisplayShipmentTables   - Number -
//     * ThisIsAnInvoice              - Boolean -
//     * WarehouseInHeader               - Boolean -
//     * TextProductServiceShipment  - String -
//     * NameOfInvoiceForOrdersField - String -
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("DisplayShipmentTables", 1);
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("WarehouseInHeader", True);
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Goods'; fa = 'کالاها';
															|it = 'Articolo';
															|pl = 'Goods';
															|tr = 'Ürün'"));
	StructureState.Insert("NameOfInvoiceForOrdersField", "ConsumptionByOrders");
	
	Return StructureState;
	
EndFunction

// Parameters for embedding business lines in a document.
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
// Returns:
//  See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	DocumentProcessingProcedure.NameOfFormElementIsSeparate = "GoodsWithAssignment";
	DocumentProcessingProcedure.NameOfGroupOfCommandElementsIsSeparate = "ProductsTeamGroupSeparately";
	DocumentProcessingProcedure.OrderDetailsName = "ConsumptionByOrders";
	
	Return DocumentProcessingProcedure;
	
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
	|	AND ValueAllowed(Department)
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
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region Internal

#Region FillingInDocumentOnOrdersOrders

Function TableDataAndDocument(Invoice) Export
	
	QueryText =
	"SELECT
	|	Table.LineNumber                  AS LineNumber,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	Table.Package                     AS Package,
	|	Table.NumberOfPackages           AS NumberOfPackages,
	|	Table.Count                   AS Count,
	|	Table.RowCode                    AS RowCode,
	|	Table.BatchesIndicationStatus          AS BatchesIndicationStatus,
	|	Table.ExpenseItem               AS ExpenseItem,
	|	Table.DimensionOfExpenses            AS DimensionOfExpenses,
	|	CASE WHEN Table.Ref.ConsumptionByOrders
	|		THEN Table.InventoryConsumptionOrder
	|		ELSE Table.Ref
	|	END                                AS InventoryConsumptionOrder,
	|	Table.RowID          AS RowID,
	|	Table.Series                        AS Series,
	|	Table.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	Table.ProductsGroup              AS ProductsGroup,
	|	Table.Purpose                   AS Purpose,
	|	Table.Individual               AS Individual,
	|	Table.OperationCategory        AS OperationCategory,
	|	Table.Lot                       AS Lot,
	|	Table.AssetID             AS AssetID,
	|	Table.LineOfBusiness      AS LineOfBusiness
	|FROM
	|	Document.InventoryConsumption.Goods AS Table
	|WHERE
	|	Table.Ref = &Invoice";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

// Returns parameters for setting up accounting accounts in the document.
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// Returns:
//  See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.DataPath = "Object.Goods";
	SetupParameters.ArticleType = "ArticleType";
	
	// Form elements that are used for customization.
	SetupParameters.FormItems.Add("GoodsTransactionRecordingPresentation");
	
	InventoryConsumptionLocalization.AccountingAccountSettings_(
		SetupParameters,
		BusinessOperation);
	
	Return SetupParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("GoodsAssetsLiabilitiesDimension");
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		
		ChoiceParameters.SelectingItemOfAssetsLiabilities = False;
		
		ListOfConditions = New Structure;
		ListOfConditions.Insert("DimensionOfExpensesRequired_", True);
		ListOfConditions.Insert("AccountAsGroupFA", False);
		ChoiceParameters.ConditionsForMandatoryAnalyticsInRows = ListOfConditions;
		
	EndIf;
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If GetFunctionalOption("BaseVersion") Then

		StandardProcessing = False;
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Ghi giảm hàng hóa vào nhu cầu kinh doanh %1 ngày %2';
				|ru = 'Списание товаров на хознужды %1 от %2';
				|en = 'Goods write-off to business needs %1 from %2'; fa = 'Goods write-off to business needs %1 from %2';
				|it = 'Storno merci per fabbisogni economici %1 dal %2';
				|pl = 'Rozchód towarów na potrzeby gospodarcze %1 z dn. %2';
				|tr = '%2''nin %1''inin ticari ihtiyaçları için malların gider yazılması'"),
			Data.Number,
			Data.Date);
		
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If ValueIsFilled(Parameters.SearchString) Then
		
		StandardProcessing = False;
		
		Query = New Query;
		
		FieldsStructure = New Structure;
		FieldsStructure.Insert("Products");
		FieldsStructure.Insert("Characteristic");
		FieldsStructure.Insert("Individual");
		FieldsStructure.Insert("ExpenseItem");
		FieldsStructure.Insert("DimensionOfExpenses");
		
		FilterCriterion = "TRUE";
		For Each SelectionKeyAndValue In Parameters.Filter Do
			If FieldsStructure.Property(SelectionKeyAndValue.Key) Then
				FilterCriterion = FilterCriterion + "
					|	AND Rows." + SelectionKeyAndValue.Key + " = &" + SelectionKeyAndValue.Key;
				Query.SetParameter(SelectionKeyAndValue.Key, SelectionKeyAndValue.Value);
			EndIf;
		EndDo;
		
		QueryText = "SELECT DISTINCT TOP 50
		|	Documents.Ref,
		|	Documents.Number,
		|	Documents.Date,
		|	Documents.DeletionMark
		|FROM
		|	Document.InventoryConsumption AS Documents";
		
		If FilterCriterion <> "TRUE" Then
			QueryText = QueryText + "
			|	INNER JOIN Document.InventoryConsumption.Goods AS Rows
			|		ON Rows.Ref = Documents.Ref";
		EndIf;
		
		QueryText = QueryText + "
		|WHERE
		|	Documents.Number LIKE &SearchString
		|   AND &FilterCriterion
		|";
		Query.SetParameter("SearchString", Parameters.SearchString + "%");
		Query.Text = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
		
		ChoiceData = New ValueList;

		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			ValueText = TrimAll(Selection.Number) + " (" + Selection.Date + ")";
			
			ListValue = New Structure;
			ListValue.Insert("Value", Selection.Ref);
			ListValue.Insert("DeletionMark", Selection.DeletionMark);
		
			ChoiceData.Add(ListValue, ValueText);
			
		EndDo; 	
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function FullObjectName()
	Return "Document.InventoryConsumption";
EndFunction

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	If RegisterName = "GoodsForIssue" Then
		DataSources.Insert("Goods.InventoryConsumptionOrder");	
	EndIf;
	
	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	Table.Date                           AS Period,
		|	Table.Number                          AS Number,
		|	Table.Organization                    AS Organization,
		|	Table.Warehouse                          AS Warehouse,
		|	Table.Ref                         AS Ref,
		|	Table.Department                  AS Department,
		|	ISNULL(Table.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
		|	Table.Date                           AS ReferenceDate,
		|	Table.BusinessOperation          AS BusinessOperation,
		|	Table.InventoryConsumptionOrder   AS InventoryConsumptionOrder,
		|	Table.ConsumptionByOrders           AS ByOrderForInternalConsumption,
		|	Table.ConsumptionForActivity     AS ConsumptionForActivity,
		|	Table.LineOfBusiness        AS LineOfBusiness,
		|	Table.ExpenseLineOfBusinessIsSpecifiedInList AS ExpenseLineOfBusinessIsSpecifiedInList,
		|	Table.EmployeeResponsible                  AS Manager,
		|	Table.SalesOpportunity                         AS SalesOpportunity,
		|	ISNULL(Table.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
		|	CASE
		|		WHEN Table.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND Table.Date >= Table.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                  AS AdvancedWarehousingOnShipment,
		|	Table.EmployeeResponsible                  AS EmployeeResponsible,
		|	Table.Comment                    AS Comment,
		|	Table.Patch                    AS Patch,
		|	Table.ReversedDocument           AS ReversedDocument,
		|	Table.CorrectedDocument           AS CorrectedDocument,
		|	Table.DeletionMark                AS DeletionMark,
		|	Table.Posted                       AS Posted,
		|	Table.Status                         AS Status,
		|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting,
		|	Table.CorrectedDocument.Date      AS AdjustmentPeriod_
		|FROM
		|	Document.InventoryConsumption AS Table
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON Table.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	Table.Ref = &Ref";

	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Warehouse",                            Attributes.Warehouse);
	Query.SetParameter("Period",                           Attributes.Period);
	Query.SetParameter("ReferenceDate",                 Attributes.ReferenceDate);
	Query.SetParameter("Organization",                      Attributes.Organization);
	Query.SetParameter("BusinessOperation",            Attributes.BusinessOperation);
	Query.SetParameter("AdvancedWarehousingOnShipment",         Attributes.AdvancedWarehousingOnShipment);
	Query.SetParameter("InventoryConsumptionOrder",     Attributes.InventoryConsumptionOrder);
	Query.SetParameter("ByOrderForInternalConsumption",  Attributes.ByOrderForInternalConsumption);
	Query.SetParameter("SalesOpportunity",                           Attributes.SalesOpportunity);
	Query.SetParameter("EnabledGoodsAssignmentInSalesOpportunity",  Attributes.EnabledGoodsAssignmentInSalesOpportunity);
	Query.SetParameter("OptionOfAssignedAccountingOfGoods", Attributes.OptionOfAssignedAccountingOfGoods);
	Query.SetParameter("Department",                    Attributes.Department);
	Query.SetParameter("ConsumptionForActivity",       Attributes.ConsumptionForActivity);
	Query.SetParameter("LineOfBusiness",          Attributes.LineOfBusiness);
	Query.SetParameter("ExpenseLineOfBusinessIsSpecifiedInList", Attributes.ExpenseLineOfBusinessIsSpecifiedInList);
	Query.SetParameter("Manager",                         Attributes.Manager);
	Query.SetParameter("Currency",                           Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("EmptyLinkKey",                  New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("EmptyBatch_",                      Catalogs.ItemsBatches.EmptyRef());
	Query.SetParameter("EmptyAssignment",                 Catalogs.Assignments.EmptyRef());
	
	Query.SetParameter("WarehouseOperation", Enums.WarehouseTransactions.ShipmentForInternalNeeds);
	
	Query.SetParameter("Number",                            Attributes.Number);
	Query.SetParameter("EmployeeResponsible",                    Attributes.EmployeeResponsible);
	Query.SetParameter("Comment",                      Attributes.Comment);
	Query.SetParameter("DeletionMark",                  Attributes.DeletionMark);
	Query.SetParameter("Posted",                         Attributes.Posted);
	
	Query.SetParameter("Patch",                      Attributes.Patch);
	Query.SetParameter("ReversedDocument",             Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",             Attributes.CorrectedDocument);
	
	Query.SetParameter("BusinessTransactionSetting",   Attributes.BusinessTransactionSetting);
	Query.SetParameter("Status",                           Attributes.Status);
	Query.SetParameter("AdjustmentPeriod_",              Attributes.AdjustmentPeriod_);
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID(FullObjectName()));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Tiêu dùng nội bộ';
															|ru = 'Внутреннее потребление';
															|en = 'Inventory consumption'; fa = 'مصرف موجودی';
															|it = 'Consumo interno';
															|pl = 'Konsumpcja wewnętrzna';
															|tr = 'Stok tüketimi'"));
	ValuesOfHoldingParameters.Insert("StartDateOfFSB5", '000101010000');
	ValuesOfHoldingParameters.Insert("WriteOffCostOfInventoryItemsInOperation", False);

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		ValuesOfHoldingParameters.Insert(
			"UseTraceableImportedGoodsAccounting",
			AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Attributes.Period));
			
	EndIf; 
	
	InventoryConsumptionLocalization.SupplementValuesOfParameters(ValuesOfHoldingParameters, Attributes);
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;

	QueryAnalyst = New Query("
	|SELECT
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series
	|FROM
	|	(SELECT DISTINCT
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		&EmptyBatch_ AS Series
	|	FROM
	|		Document.InventoryConsumption.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		&EmptyBatch_ AS Series
	|	FROM
	|		Document.InventoryConsumption.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TypesOfOwnerStocks.GoodsOwner AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		&EmptyBatch_ AS Series
	|	FROM
	|		Document.InventoryConsumption.InventoryKinds AS TableTypesOfStocks_
	|
	|		INNER JOIN
	|			Catalog.InventoryKinds AS TypesOfOwnerStocks
	|		ON
	|			TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND TypesOfOwnerStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TypesOfOwnerStocks.GoodsOwner AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		&EmptyBatch_ AS Series
	|	FROM
	|		Document.InventoryConsumption.InventoryKinds AS TableTypesOfStocks_
	|
	|		INNER JOIN
	|			Catalog.InventoryKinds AS TypesOfOwnerStocks
	|		ON
	|			TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND TypesOfOwnerStocks.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	// Inventory accounting analytics with an empty assignment
	|	SELECT DISTINCT
	|		GoodsTable.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		GoodsTable.ItemsLocationAttributes.Products AS Products,
	|		GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose,
	|		GoodsTable.ItemsLocationAttributes.Series AS Series
	|	FROM
	|		Document.InventoryConsumption.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND GoodsTable.ItemsLocationAttributes.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	) AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|		AND GoodsTable.Series = Dimension.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series
	|");
	
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Department",          Query.Parameters.Department);
	QueryAnalyst.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("EmptyBatch_",            Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("BusinessOperation",  Query.Parameters.BusinessOperation);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
		Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure
Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRatioFromLocalToMan") Then
		Return;
	EndIf;
	
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	RatePeriod = Query.Parameters.Period;

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	
EndProcedure
Function QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, Registers)
	
	RegisterName = "InventoryConsumptionOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
		|SELECT
		|	GoodsTable.LineNumber                  AS LineNumber,
		|	VALUE(AccumulationRecordType.Expense)     AS RecordType,
		|	GoodsTable.Ref.Date                  AS Period,
		|	GoodsTable.InventoryConsumptionOrder AS InventoryConsumptionOrder,
		|	GoodsTable.Products                 AS Products,
		|	GoodsTable.Characteristic               AS Characteristic,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatusSender IN(10, 14)
		|			THEN GoodsTable.Series
		|	END                                      AS Series,
		|	GoodsTable.RowCode                    AS RowCode,
		|	CASE
		|		WHEN GoodsTable.Products.ItemsType IN (
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN &Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END                                      AS Warehouse,
		|	GoodsTable.Count                   AS Ordered,
		|	GoodsTable.Count                   AS ToRegister
		|FROM
		|	Document.InventoryConsumption.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.RowCode <> 0
		|	AND &ByOrderForInternalConsumption
		|
		|";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	QueryText = "
	|SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfSender,
	|	UNDEFINED AS WareroomOfRecipient,
	|	&WarehouseOperation AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	NOT &AdvancedWarehousingOnShipment AS ThisIsWarehouseRecord
	|FROM
	|	Document.InventoryConsumption.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	GoodsTable.Series,
	|	GoodsTable.Count,
	|	&Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	UNDEFINED,
	|	&WarehouseOperation,
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	NOT &AdvancedWarehousingOnShipment
	|FROM
	|	Document.InventoryConsumption.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period									AS Period,
	|	VALUE(AccumulationRecordType.Expense)	AS RecordType,
	|	&Organization							AS Organization,
	|	&Department							AS Department,
	|	TTProducts_1.Products					AS Products,
	|	TTProducts_1.Characteristic					AS Characteristic,
	|	TTProducts_1.Purpose						AS Purpose,
	|	TTProducts_1.Count						AS Count
	|FROM
	|	Document.InventoryConsumption.Goods AS TTProducts_1
	|WHERE
	|	TTProducts_1.Ref = &Ref
	|	AND TTProducts_1.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TTProducts_1.Products.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts) Export
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	QueryText = "
		|SELECT
		|	TableTypesOfStocks_.LineNumber                AS LineNumber,
		|	Catalog.InventoryOwnerAttributeOfCompanyGoodsOwner                AS InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
		|		THEN TableTypesOfStocks_.ItemsLocationAttributes
		|		ELSE DimensionCostOfProduction.DimensionKey
		|	END                                         AS CostAccountingAnalytics,
		|	Dimension.Products                        AS Products,
		|	Dimension.Characteristic                      AS Characteristic,
		|	Dimension.Purpose                          AS Purpose,
		|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
		|	TableTypesOfStocks_.Count                 AS Count,
		|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityByGBRN,
		|	&BusinessOperation                        AS BusinessOperation,
		// If we write off goods or components for an article on the modernization or purchase of an OS, then we bring
		// all incoming VAT to a common denominator (always "hanging"" the balance on 19 accounts).
		|	CASE
		|		WHEN TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|			AND TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
		|			AND TableTypesOfStocks_.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
		|		WHEN TableTypesOfStocks_.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
		|	ELSE
		|		&ConsumptionForActivity
		|	END                                         AS VATTaxation,
		|	TableTypesOfStocks_.ExpenseItem             AS ExpenseItem,
		|	TableTypesOfStocks_.DimensionOfExpenses          AS DimensionOfExpenses,
		|	TableTypesOfStocks_.AssetsLiabilitiesDimension   AS AssetsLiabilitiesDimension,
 		|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute       AS CorInventoryOwnerAttribute,
		|	CommitteeKeys.DimensionKey                  AS CommitteeAnalytics,
		|	CommitteeKeysWithoutAssignment.DimensionKey     AS CommitteeAnalyticsWithoutAssignment,
		|	CASE WHEN Catalog.GoodsOwner REFS Catalog.Companies
		|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
		|		ELSE AnalysisOfCalculations.DimensionKey
		|	END                                         AS AnalysisOfSettlementsWithCommittee,
		|	CommitteeKeys.StorageLocation				  AS Consignor,
		|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType      AS InventoryType,
		|	TableTypesOfStocks_.RowID        AS RowID,
		|	TableTypesOfStocks_.FinRecordID     AS FinRecordID,
		|	TableTypesOfStocks_.GLAccountSettings       AS GLAccountSettings,
		|	GoodsTable.OperationCategory           AS OperationCategory,
		|	GoodsTable.Lot                          AS Lot,
		|	TableTypesOfStocks_.ExciseTaxAmount                AS ExciseAmountInCurrencyLocal,
		|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan
		|		AS NUMBER(31, 2))                         AS ExciseAmountInCurrencyMgmt,
		|	CASE
		|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList
		|			THEN TableTypesOfStocks_.LineOfBusiness
		|		ELSE &LineOfBusiness
		|	END                                         AS LineOfBusiness,
		|	ProductionKeys.DimensionKey               AS DimensionOfProduction,
		|	Dimension.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
		|	CASE
		|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                         AS TraceableWork
		|
		|INTO TTTypesOfStocks
		|FROM
		|	Document.InventoryConsumption.InventoryKinds AS TableTypesOfStocks_
		|
		|	LEFT JOIN
		|		Document.InventoryConsumption.Goods AS GoodsTable
		|	ON
		|		TableTypesOfStocks_.Ref = GoodsTable.Ref AND TableTypesOfStocks_.RowID = GoodsTable.RowID
		|
		|	INNER JOIN
		|		Catalog.InventoryKinds AS Catalog
		|	ON
		|		TableTypesOfStocks_.InventoryOwnerAttribute = Catalog.Ref
		|
		|	LEFT JOIN
		|		Catalog.InventoryLocationAttributeKeys AS Dimension
		|	ON
		|		TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
		|
		|	LEFT JOIN
		|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
		|	ON
		|		Dimension.Products = CommitteeKeys.Products
		|		AND Dimension.Characteristic = CommitteeKeys.Characteristic
		|		AND Dimension.Purpose = CommitteeKeys.Purpose
		|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
		|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeKeys.StorageLocation
		|
		|	LEFT JOIN
		|		InformationRegister.ItemsLocationAttributes AS CommitteeKeysWithoutAssignment
		|	ON
		|		CommitteeKeys.Products = CommitteeKeysWithoutAssignment.Products
		|		AND CommitteeKeys.Characteristic = CommitteeKeysWithoutAssignment.Characteristic
		|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeysWithoutAssignment.Purpose
		|		AND CommitteeKeys.Series = CommitteeKeysWithoutAssignment.Series
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeysWithoutAssignment.ProductCostElement
		|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeKeysWithoutAssignment.StorageLocation
		|
		|	LEFT JOIN
		|		InformationRegister.ItemsLocationAttributes AS ProductionKeys
		|	ON
		|		Dimension.Products = ProductionKeys.Products
		|		AND Dimension.Characteristic = ProductionKeys.Characteristic
		|		AND Dimension.Purpose = ProductionKeys.Purpose
		|		AND TableTypesOfStocks_.Series = ProductionKeys.Series
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = ProductionKeys.ProductCostElement
		|		AND &Department = ProductionKeys.StorageLocation
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCostOfProduction
		|	ON Dimension.Products = DimensionCostOfProduction.Products
		|		AND Dimension.Characteristic = DimensionCostOfProduction.Characteristic
		|		AND Dimension.Series = DimensionCostOfProduction.Series
		|		AND Dimension.StorageLocation = DimensionCostOfProduction.StorageLocation
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionCostOfProduction.ProductCostElement
		|		AND &EmptyAssignment = DimensionCostOfProduction.Purpose
		|
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
		|		ON AnalysisOfCalculations.Organization = &Organization
		|		AND AnalysisOfCalculations.Partner = Catalog.GoodsOwner
		|		AND AnalysisOfCalculations.Counterparty = Catalog.Counterparty
		|		AND AnalysisOfCalculations.Contract = Catalog.Contract
		|		AND AnalysisOfCalculations.LineOfBusiness = TableTypesOfStocks_.Purpose.LineOfBusiness
		|	
		|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
		|		ON AnalysisOfIntercampaniCalculations.Organization = &Organization
		|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
		|		AND AnalysisOfIntercampaniCalculations.Counterparty = Catalog.Counterparty
		|		AND AnalysisOfIntercampaniCalculations.Contract = Catalog.Contract
		|		AND AnalysisOfCalculations.LineOfBusiness = TableTypesOfStocks_.Purpose.LineOfBusiness
		|WHERE
		|	TableTypesOfStocks_.Ref = &Ref
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber                      AS LineNumber,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)  AS InventoryOwnerAttributeOfCompanyGoodsOwner,
		|	VALUE(Catalog.InventoryKinds.EmptyRef)  AS InventoryOwnerAttribute,
		|	GoodsTable.ItemsLocationAttributes       AS ItemsLocationAttributes,
		|	CASE
		|		WHEN &KeepRecordsOfInventoryCostByAssignments
		|			THEN GoodsTable.ItemsLocationAttributes
		|		ELSE DimensionCostOfProduction.DimensionKey
		|	END                                          AS CostAccountingAnalytics,
		|	Dimension.Products                         AS Products,
		|	Dimension.Characteristic                       AS Characteristic,
		|	Dimension.Purpose                           AS Purpose,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)    AS CCDNumber,
		|	GoodsTable.Count                       AS Count,
		|	0                                              AS QuantityByGBRN,
		|	&BusinessOperation                         AS BusinessOperation,
		// If we write off goods or components for an article on the modernization or purchase of an OS, then we bring
		// all incoming VAT to a common denominator (always "hanging"" the balance on 19 accounts).
		|	CASE
		|		WHEN GoodsTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
		|			AND GoodsTable.ExpenseItem.VATAssetTaxClass IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
		|			AND GoodsTable.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
		|		WHEN GoodsTable.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
		|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
		|		ELSE &ConsumptionForActivity
		|	END                                           AS VATTaxation,
		|	GoodsTable.ExpenseItem                    AS ExpenseItem,
		|	GoodsTable.DimensionOfExpenses                 AS DimensionOfExpenses,
		|	GoodsTable.AssetsLiabilitiesDimension          AS AssetsLiabilitiesDimension,
 		|	VALUE(Catalog.InventoryKinds.EmptyRef)   AS CorInventoryOwnerAttribute,
		|	UNDEFINED                                    AS CommitteeAnalytics,
		|	UNDEFINED                                    AS CommitteeAnalyticsWithoutAssignment,
		|	UNDEFINED                                    AS AnalysisOfSettlementsWithCommittee,
		|	UNDEFINED                                    AS Consignor,
		|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
		|	GoodsTable.RowID               AS RowID,
		|	GoodsTable.RowID               AS FinRecordID,
		|	GoodsTable.GLAccountSettings              AS GLAccountSettings,
		|	GoodsTable.OperationCategory             AS OperationCategory,
		|	GoodsTable.Lot                            AS Lot,
		|	0                                               AS ExciseAmountInCurrencyLocal,
		|	0                                               AS ExciseAmountInCurrencyMgmt,
		|	CASE
		|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList
		|			THEN GoodsTable.LineOfBusiness
		|		ELSE &LineOfBusiness
		|	END                                           AS LineOfBusiness,
		|	ProductionKeys.DimensionKey                 AS DimensionOfProduction,
		|	Dimension.WarehouseArea.ShopFloorStockroom   AS ShopFloorStockroom,
		|	FALSE                                            AS TraceableWork
		|FROM
		|	Document.InventoryConsumption.Goods AS GoodsTable
		|	
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
		|	ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS ProductionKeys
		|	ON Dimension.Products = ProductionKeys.Products
		|	AND Dimension.Characteristic = ProductionKeys.Characteristic
		|	AND Dimension.Purpose = ProductionKeys.Purpose
		|	AND GoodsTable.Series = ProductionKeys.Series
		|	AND VALUE(Catalog.ProductCostElements.EmptyRef) = ProductionKeys.ProductCostElement
		|	AND &Department = ProductionKeys.StorageLocation
		|
		|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCostOfProduction
		|	ON Dimension.Products = DimensionCostOfProduction.Products
		|	AND Dimension.Characteristic = DimensionCostOfProduction.Characteristic
		|	AND Dimension.Series = DimensionCostOfProduction.Series
		|	AND Dimension.StorageLocation = DimensionCostOfProduction.StorageLocation
		|	AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionCostOfProduction.ProductCostElement
		|	AND &EmptyAssignment = DimensionCostOfProduction.Purpose
		|
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND GoodsTable.ItemsLocationAttributes NOT IN
		|		(SELECT DISTINCT
		|			InventoryKinds.ItemsLocationAttributes
		|		FROM
		|			Document.InventoryConsumption.InventoryKinds AS InventoryKinds
		|		WHERE
		|			InventoryKinds.Ref = &Ref)
		|";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Organization AS ShipmentCompany,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	CASE
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN CASE TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass
	|					WHEN VALUE(Enum.AssetKinds.FA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
	|				END
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|				AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostTA <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|				AND (&Period < DATEADD(&StartDateOfFSB5, MONTH, -1)
	|					OR &Period < &StartDateOfFSB5
	|						AND NOT &WriteOffCostOfInventoryItemsInOperation)
	|			THEN VALUE(Enum.BusinessTransactions.CommissioningACAndTA)
	|
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND (TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|					OR &Period >= &StartDateOfFSB5
	|					OR &Period >= DATEADD(&StartDateOfFSB5, MONTH, -1)
	|						AND &WriteOffCostOfInventoryItemsInOperation)
	|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation AS VATTaxation,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.ExpenseItem.ExpensesOccur AS ExpenseItemTypeOfExpense,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.CommitteeAnalytics
	|		ELSE UNDEFINED
	|	END AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.CorInventoryOwnerAttribute
	|	END AS CorInventoryOwnerAttribute
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableTypesOfStocks_.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Organization AS ShipmentCompany,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	CASE
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN CASE TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass
	|					WHEN VALUE(Enum.AssetKinds.FA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
	|				END
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|				AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostTA <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|				AND (&Period < DATEADD(&StartDateOfFSB5, MONTH, -1)
	|					OR &Period < &StartDateOfFSB5
	|						AND NOT &WriteOffCostOfInventoryItemsInOperation)
	|			THEN VALUE(Enum.BusinessTransactions.CommissioningACAndTA)
	|
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND (TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|					OR &Period >= &StartDateOfFSB5
	|					OR &Period >= DATEADD(&StartDateOfFSB5, MONTH, -1)
	|						AND &WriteOffCostOfInventoryItemsInOperation)
	|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation AS VATTaxation,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.ExpenseItem.ExpensesOccur AS ExpenseItemTypeOfExpense,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.TraceableWork
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers) Export
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProductsOfOrganizations.LineNumber AS LineNumber,
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.Warehouse AS Warehouse,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.ExpenseItem AS ExpenseItem,
	|	TTProductsOfOrganizations.DimensionOfExpenses AS DimensionOfExpenses,
	|	TTProductsOfOrganizations.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	&Period                                            AS Period,
	|	&Warehouse                                             AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.Products                    AS Products,
	|	TableTypesOfStocks_.Characteristic                  AS Characteristic,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	&BusinessOperation                             AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation              AS VATTaxation
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber            AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute             AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalyticsWithoutAssignment AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency      AS Currency,
	|	TableTypesOfStocks_.CCDNumber               AS CCDNumber,
	|	0                                         AS Count,
	|	0                                         AS RevenueAmount,
	|	0                                         AS RevenueAmountExclVATLocal,
	|	0                                         AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count             AS QuantityConsumed,
	|	0                                         AS QuantityToRegister,
	|	0                                         AS QuantityForRegistrationByProductBatchID,
	|	0                                         AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.Count             AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN       AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.Products           AS Products,
	|	TableTypesOfStocks_.Characteristic         AS Characteristic,
	|	&BusinessOperation                    AS BusinessOperation,
	|	UNDEFINED                              AS CorInventoryOwnerAttribute,
	|	UNDEFINED                              AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.VATTaxation     AS VATTaxation,
	|	TableTypesOfStocks_.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|		 		AND Rows.OperationCategory.MethodOfRepaymentOfCostOfAC <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|		 		AND Rows.OperationCategory.MethodOfRepaymentOfCostTA <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|		 		AND (&Period < DATEADD(&StartDateOfFSB5, MONTH, -1)
	|						OR &Period < &StartDateOfFSB5
	|				AND NOT &WriteOffCostOfInventoryItemsInOperation)
	|
	|			THEN VALUE(Enum.BusinessTransactions.CommissioningACAndTA)
	|
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND (Rows.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|					OR &Period >= &StartDateOfFSB5
	|					OR &Period >= DATEADD(&StartDateOfFSB5, MONTH, -1)
	|						AND &WriteOffCostOfInventoryItemsInOperation)
	|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|
	|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND Rows.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE 
	|					WHEN Rows.ExpenseItem.VATAssetTaxClass IN (
	|							VALUE(Enum.AssetKinds.FA),
	|							VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN Rows.ExpenseItem.VATAssetTaxClass = VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
	|				END
	|
	|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND Rows.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|
	|		WHEN Rows.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			Rows.CommitteeAnalyticsWithoutAssignment
	|		ELSE
	|			CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|				THEN Rows.ItemsLocationAttributes
	|				ELSE Rows.CostAccountingAnalytics
	|			END
	|	END AS ItemsLocationAttributes,
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN Rows.Consignor
	|		WHEN Rows.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN &Department
	|		ELSE &Warehouse
	|	END AS Warehouse,
	|
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN UNDEFINED
	|		ELSE Rows.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN Rows.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN
	|				CASE WHEN Rows.Products.TracedGoods
	|					THEN Rows.InventoryOwnerAttribute.InventoryType
	|					ELSE UNDEFINED
	|				END
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END AS InventoryType,
	|
	|	Rows.ExpenseItem AS IncomeAndExpenseItem,
	|	Rows.DimensionOfExpenses AS DimensionOfExpenses,
	|	Rows.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	CASE WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			InventoryKinds.Contract.LineOfBusiness
	|		ELSE
	|			CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|				THEN Rows.ItemsLocationAttributes.Purpose.LineOfBusiness
	|				ELSE Rows.CostAccountingAnalytics.Purpose.LineOfBusiness
	|			END
	|	END AS ProductLineOfBusiness,
	|	CASE
	|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList
	|			THEN Rows.LineOfBusiness
	|		ELSE &LineOfBusiness
	|	END AS LineOfBusinessItems,
	|
	|	Rows.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	CASE
	|		WHEN Rows.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN Rows.Products
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN Rows.InventoryOwnerAttribute
	|		ELSE Rows.Products
	|	END AS SourceOfProductFinancialAccountingGroup
	|
	|FROM
	|	TTTypesOfStocks AS Rows
	|	LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|	ON Rows.InventoryOwnerAttribute = InventoryKinds.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.ExpenseItem AS AssetRef,
	|	GoodsTable.DimensionOfExpenses AS Dimension,
	|	GoodsTable.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	SUM(GoodsTable.ExciseAmountInCurrencyLocal) AS SumCompl,
	|	SUM(GoodsTable.ExciseAmountInCurrencyMgmt) AS SumMan,
	|	SUM(GoodsTable.ExciseAmountInCurrencyMgmt) AS AmountIncludingVAT,
	|	SUM(GoodsTable.ExciseAmountInCurrencyMgmt) AS AmountExcludingVAT,
	|
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND &UseExcisableGoods
	|
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.GLAccountSettings,
	|	GoodsTable.FinRecordID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
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
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|			AND NOT DocumentGoods.InventoryConsumptionOrder IN(UNDEFINED,
	|																VALUE(Document.RMOrder.EmptyRef),
	|																VALUE(Document.InventoryConsumptionOrder.EmptyRef))
	|			THEN DocumentGoods.InventoryConsumptionOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	HeaderData_.Ref					AS Invoice,
	|	HeaderData_.Patch				AS Patch,
	|	HeaderData_.CorrectedDocument	AS CorrectedDocument,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|			AND NOT DocumentGoods.InventoryConsumptionOrder IN(UNDEFINED,
	|																VALUE(Document.RMOrder.EmptyRef),
	|																VALUE(Document.InventoryConsumptionOrder.EmptyRef))
	|			THEN DocumentGoods.InventoryConsumptionOrder.Department
	|		ELSE HeaderData_.Department
	|	END								AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatusSender	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|				AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.InventoryConsumption.Goods AS DocumentGoods
	|		LEFT JOIN Document.InventoryConsumption AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|			AND NOT DocumentGoods.InventoryConsumptionOrder IN(UNDEFINED,
	|																VALUE(Document.RMOrder.EmptyRef),
	|																VALUE(Document.InventoryConsumptionOrder.EmptyRef))
	|			THEN DocumentGoods.InventoryConsumptionOrder
	|		ELSE UNDEFINED
	|	END								AS OrderDocument,
	|	HeaderData_.Ref					AS Invoice,
	|	HeaderData_.Patch				AS Patch,
	|	HeaderData_.CorrectedDocument	AS CorrectedDocument,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|			AND NOT DocumentGoods.InventoryConsumptionOrder IN(UNDEFINED,
	|																VALUE(Document.RMOrder.EmptyRef),
	|																VALUE(Document.InventoryConsumptionOrder.EmptyRef))
	|			THEN DocumentGoods.InventoryConsumptionOrder.Department
	|		ELSE HeaderData_.Department
	|	END								AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.Purpose			AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatusSender	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|				AND DocumentGoods.RowCode = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	CASE
	|		WHEN HeaderData_.ConsumptionByOrders
	|			THEN TRUE
	|		ELSE FALSE
	|	END								AS ShipmentByOrder
	|FROM
	|	Document.InventoryConsumption.Goods AS DocumentGoods
	|		LEFT JOIN Document.InventoryConsumption AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.Count <> 0";
	
	MetadataObject	= Metadata.Documents.InventoryConsumption;
	TSSeriesName			= "SetOfSeries";
	
	WarehousesServer.ArrangeShipmentOfGoods(Query,
										QueryTexts,
										Registers,
										TextOfDocumentDataRequest,
										MetadataObject,
										TSSeriesName);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE
	|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList
	|			THEN TableExpenses.LineOfBusiness
	|		ELSE &LineOfBusiness
	|	END AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	TableExpenses.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTTypesOfStocks AS TableExpenses
	|WHERE
	|	TableExpenses.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND NOT &UseExcisableGoods
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	SUM(TableExpenses.ExciseAmountInCurrencyMgmt) AS AmountIncludingVAT,
	|	SUM(TableExpenses.ExciseAmountInCurrencyMgmt) AS AmountExcludingVAT,
	|	SUM(TableExpenses.ExciseAmountInCurrencyMgmt) AS AmountExcludingVATMan,
	|	SUM(TableExpenses.ExciseAmountInCurrencyLocal) AS AmountIncludingVATCompl,
	|	SUM(TableExpenses.ExciseAmountInCurrencyLocal) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	TableExpenses.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS TableExpenses
	|WHERE
	|	TableExpenses.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|	AND &UseExcisableGoods
	|
	|GROUP BY
	|	TableExpenses.ExpenseItem,
	|	TableExpenses.DimensionOfExpenses,
	|	TableExpenses.FinRecordID
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	FullDocumentName = "Document.InventoryConsumption";
	
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnShipment", 
		"CASE
		|		WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("ByOrderForInternalConsumption",
		"GoodsTable.Ref.ConsumptionByOrders");
	
	If RegisterName = "StockAllocationRecords" Then
		
		QueryTexts = New ValueList();
		SynonymForDocumentTable = "TabPart";
		ReflectStockDistribution(Query, QueryTexts, RegisterName);
		QueryText = StrConcat(QueryTexts.UnloadValues(), TMCommonUse.QuerySeparatorInJoin());
		
	ElsIf RegisterName = "InventoryConsumptionOrders" Then
		QueryText = QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "FATable";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "TableOfIA";
	EndIf;
	
	If QueryText = Undefined Then
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
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments"
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.InventoryConsumption.Goods AS TabPart
		|WHERE
		|	TabPart.RowCode = 0";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

Function QueryTextTableInventoryInOperation(Query, QueryTexts, Registers)
	
	RegisterName = "InventoryInOperation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                      AS Organization,
	|	&Department                    AS Department,
	|	Table.Individual            AS Individual,
	|	Table.Products              AS Products,
	|	Table.Characteristic            AS Characteristic,
	|	Table.Lot                    AS Lot,
	|
	|	CASE
	|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList
	|			THEN Table.LineOfBusiness
	|		ELSE &LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	Table.AssetID          AS AssetID,
	|
	|	CASE
	|		WHEN Table.BatchesIndicationStatusRecipient = 20
	|			THEN Table.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|
	|	InventoryKinds.Count       AS Count,
	|
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|			THEN InventoryKinds.CCDNumber
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END AS CCDNumber,
	|
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|			THEN InventoryKinds.QuantityByGBRN
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END AS QuantityByGBRN
	|
	|FROM
	|	Document.InventoryConsumption.Goods AS Table
	|
	|		LEFT JOIN Document.InventoryConsumption.InventoryKinds AS InventoryKinds
	|		ON InventoryKinds.Ref = &Ref
	|		AND InventoryKinds.RowID = Table.RowID
	|
	|WHERE
	|	Table.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|	AND Table.OperationCategory.PropertyAccounting
	|	AND &Status = VALUE(Enum.InternalConsumptionStatuses.Accepted)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Period                                 AS Date,
	|	&Ref                                 AS Ref,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Posted                               AS Posted,
	|	FATable.DimensionOfExpenses             AS FixedAsset,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	TRUE                                  AS RecordInTA
	|
	|FROM
	|	Document.InventoryConsumption.Goods AS FATable
	|
	|		LEFT JOIN Document.InventoryConsumption.Goods AS DoublesTable
	|		ON DoublesTable.Ref = FATable.Ref
	|			AND DoublesTable.DimensionOfExpenses = FATable.DimensionOfExpenses
	|			AND DoublesTable.LineNumber < FATable.LineNumber
	|			AND (DoublesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|WHERE
	|	FATable.Ref = &Ref
	|
	|	AND (FATable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR FATable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR FATable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND FATable.DimensionOfExpenses <> UNDEFINED
	|	AND (FATable.DimensionOfExpenses REFS Catalog.Assets
	|			AND FATable.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|		OR FATable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|			AND FATable.DimensionOfExpenses <> VALUE(Catalog.ConstructionObjects.EmptyRef))
	|
	|	AND DoublesTable.Ref IS NULL";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0)   AS RecNo,
	|	&Period                                 AS Date,
	|	&Ref                                 AS Ref,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Posted                               AS Posted,
	|	TableOfIA.DimensionOfExpenses            AS IntangibleAsset,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	TRUE                                  AS RecordInTA
	|
	|FROM
	|	Document.InventoryConsumption.Goods AS TableOfIA
	|
	|		LEFT JOIN Document.InventoryConsumption.Goods AS DoublesTable
	|		ON DoublesTable.Ref = TableOfIA.Ref
	|			AND DoublesTable.DimensionOfExpenses = TableOfIA.DimensionOfExpenses
	|			AND DoublesTable.LineNumber < TableOfIA.LineNumber
	|			AND (DoublesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|WHERE
	|	TableOfIA.Ref = &Ref
	|
	|	AND (TableOfIA.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR TableOfIA.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR TableOfIA.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND TableOfIA.DimensionOfExpenses <> UNDEFINED
	|	AND TableOfIA.DimensionOfExpenses REFS Catalog.IntangibleAssets
	|	AND TableOfIA.DimensionOfExpenses <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|
	|	AND DoublesTable.Ref IS NULL
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

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
	AdditionalTables.Add("TTTypesOfStocks");
	AdditionalTables.Add("TTOtherExpenses_");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region WriteOffForExpensesAssets_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, UNDEFINED) AS CorCompany,
	|	UNDEFINED 								    			AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute				  			AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    			AS ExpenseItemAssets,
	|	CASE WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN TableTypesOfStocks_.DimensionOfExpenses                
	|		ELSE TableTypesOfStocks_.AssetsLiabilitiesDimension
	|	END    						  			    			AS AssetExpenseAnalytics,
	|	CASE
	|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList
	|			THEN TableTypesOfStocks_.LineOfBusiness
	|		ELSE &LineOfBusiness
	|	END														AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	TableTypesOfStocks_.GLAccountSettings 					 AS GLAccountSettings,
	|	
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|		 		AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|		 		AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostTA <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|		 		AND (&Period < DATEADD(&StartDateOfFSB5, MONTH, -1)
	|					OR &Period < &StartDateOfFSB5
	|				AND NOT &WriteOffCostOfInventoryItemsInOperation)
	|
	|			THEN VALUE(Enum.BusinessTransactions.CommissioningACAndTA)
	|
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND (TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|					OR &Period >= &StartDateOfFSB5
	|					OR &Period >= DATEADD(&StartDateOfFSB5, MONTH, -1)
	|						AND &WriteOffCostOfInventoryItemsInOperation)
	|			THEN VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
	|
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE 
	|					WHEN TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass IN (
	|							VALUE(Enum.AssetKinds.FA),
	|							VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
	|						THEN VALUE(Enum.BusinessTransactions.TransferToFixedAssets)
	|					WHEN TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass = VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Enum.BusinessTransactions.TransferToIntangibleAssetsAndRD)
	|				END
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN VALUE(Enum.BusinessTransactions.TransferForOtherPurposes)
	|		ELSE
	|			DocumentTable.BusinessOperation
	|	END 														 AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 						 AS RowID,
	|	TableTypesOfStocks_.FinRecordID					 AS FinRecordID,
	|
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|		 		AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|		 		AND TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostTA <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|		 		AND (&Period < DATEADD(&StartDateOfFSB5, MONTH, -1)
	|					OR &Period < &StartDateOfFSB5
	|				AND NOT &WriteOffCostOfInventoryItemsInOperation)
	|
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferToOperation)
	|
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
	|				AND (TableTypesOfStocks_.OperationCategory.MethodOfRepaymentOfCostOfAC = VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|					OR &Period >= &StartDateOfFSB5
	|					OR &Period >= DATEADD(&StartDateOfFSB5, MONTH, -1)
	|						AND &WriteOffCostOfInventoryItemsInOperation)
	|
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsConsumptionOnDemand)
	|
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE 
	|					WHEN TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass IN (
	|							VALUE(Enum.AssetKinds.FA),
	|							VALUE(Enum.AssetKinds.ConstructionInProgressObjects))
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.TransferToFixedAssets)
	|					WHEN TableTypesOfStocks_.ExpenseItem.VATAssetTaxClass = VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.TransferToIntangibleAssetsAndRD)
	|				END
	|
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|				AND TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferForOtherPurposes)
	|
	|		WHEN TableTypesOfStocks_.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferForOtherPurposes)
	|
	|		ELSE &BusinessTransactionSetting
	|	END AS BusinessTransactionSetting
	|
	|FROM
	|	Document.InventoryConsumption AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN TTOtherExpenses_ AS OtherExpenses
	|		ON OtherExpenses.ExpenseItem = TableTypesOfStocks_.ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = TableTypesOfStocks_.DimensionOfExpenses
	|		AND OtherExpenses.FinRecordID = TableTypesOfStocks_.FinRecordID
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View",  Metadata.Documents.InventoryConsumption))
		And (AccessRight("Insert", Metadata.Documents.InventoryConsumption)
			Or AccessRight("Update", Metadata.Documents.InventoryConsumption))
		And AccessRight("View",  Metadata.Documents.RMOrder)
		And AccessRight("View",  Metadata.Documents.InventoryConsumptionOrder)
		And AccessRight("Read",    Metadata.AccumulationRegisters.InventoryConsumptionOrders)
		And AccessRight("Read",    Metadata.AccumulationRegisters.GoodsForIssue)
		And GetFunctionalOption("UseInventoryConsumptionOrders");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	InternalRequirementsOfGoodsForRegistration = DataProcessors.LogOfInternalDocuments.NumberOfLinesForLayout(
		BusinessOperationsOfDocument());
	
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
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or InternalRequirementsOfGoodsForRegistration > 0;
	
	OpeningParameters = ParametersForOpeningWorkplaceForm();
	OpeningParameters.FormParameters.Insert("FormAssignmentKey", "ToDoList");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "InternalRequirementsForRegistration";
	ToDoItem.HasToDoItems       = InternalRequirementsOfGoodsForRegistration > 0;
	ToDoItem.Presentation  = NStr("vi = 'Tiêu dùng hàng hóa nội bộ cần lập';
									|ru = 'Внутренние потребления к оформлению';
									|en = 'Inventory consumptions to register'; fa = 'Inventory consumptions to register';
									|it = 'Consumo interno da formalizzare';
									|pl = 'Konsumpcja wewnętrzna do zatwierdzenia';
									|tr = 'Kaydedilecek stok tüketimi'");
	ToDoItem.Count     = InternalRequirementsOfGoodsForRegistration;
	ToDoItem.Important         = False;
	ToDoItem.Form          = OpeningParameters.FormName;
	ToDoItem.FormParameters = OpeningParameters.FormParameters;
	ToDoItem.Owner       = "InternalInventoryTransfers";
	
EndProcedure

#EndRegion

#Region Other

Procedure ProcessDocumentAfterAddingLines(Object) Export
	SplitLinesOfObjectsOfOperationWithInventoryAccounting(Object);
EndProcedure

Procedure SplitLinesOfObjectsOfOperationWithInventoryAccounting(Object)
	
	Table = Object.Goods;
	
	// Getting the categories of operation of the document.
	ArrayOfCategories = New Array();
	
	For Each TableRow In Table Do
		
		If ValueIsFilled(TableRow.OperationCategory) Then
			ArrayOfCategories.Add(TableRow.OperationCategory);
		EndIf;
		
	EndDo;
	
	If ArrayOfCategories.Count() = 0 Then
		Return;
	EndIf;
	
	// Obtaining categories of operation with inventory management.
	Query = New Query();
	Query.SetParameter("ArrayOfCategories", ArrayOfCategories);
	Query.Text =
		"SELECT
		|	CatOperationCategories.Ref AS Ref
		|FROM
		|	Catalog.OperationCategories AS CatOperationCategories
		|WHERE
		|	CatOperationCategories.StocktakingRecord
		|	AND CatOperationCategories.Ref IN(&ArrayOfCategories)";
	
	CategoriesWithInventoryAccounting = Query.Execute().Unload().UnloadColumn("Ref");
	
	// Splitting lines for categories of operation with inventory management.
	If CategoriesWithInventoryAccounting.Count() > 0 Then
		
		TotalRows = Table.Count();
		// Crawling the table, searching for rows.
		For Counter = 1 To TotalRows Do
			
			TableRow = Table[TotalRows - Counter];
			If CategoriesWithInventoryAccounting.Find(TableRow.OperationCategory) <> Undefined Then
				
				// Splitting lines.
				QuantityPerLine = TableRow.Count - 1;
				TableRow.NumberOfPackages = 1;
				TableRow.Count = 1;
				TableRow.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				
				While QuantityPerLine > 0 Do
					NewRow = Table.Add();
					FillPropertyValues(NewRow, TableRow);
					QuantityPerLine = QuantityPerLine - 1;
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.InventoryConsumption) Then
		// Domestic consumption
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InventoryConsumption";
		PrintCommand.Presentation = ?(GetFunctionalOption("BaseVersion"),NStr("vi = 'Ghi giảm hàng hóa cho nhu cầu kinh doanh';
																				|ru = 'Списание товаров на хознужды';
																				|en = 'Write off goods to business needs'; fa = 'Write off goods to business needs';
																				|it = 'Storno delle merci per fabbisogni economici';
																				|pl = 'Rozhód towarów na potrzeby gospodarcze';
																				|tr = 'Ev ihtiyaçları için malların gider yazılması'"),NStr("vi = 'Tiêu dùng hàng hóa nội bộ';
																																|ru = 'Внутреннее потребление';
																																|en = 'Inventory consumption'; fa = 'مصرف موجودی';
																																|it = 'Consumo interno';
																																|pl = 'Konsumpcja wewnętrzna';
																																|tr = 'Stok tüketimi'"));
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;

	// Task for the selection of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
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

		AttachableCommands.AddCommandVisibilityCondition(
			PrintCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToOperation,
			ComparisonType.Equal);
			
	EndIf;
	InventoryConsumptionLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InventoryConsumption") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InventoryConsumption",
			NStr("vi = 'Tiêu dùng hàng hóa nội bộ';
				|ru = 'Внутреннее потребление';
				|en = 'Inventory consumption'; fa = 'مصرف موجودی';
				|it = 'Consumo interno';
				|pl = 'Konsumpcja wewnętrzna';
				|tr = 'Stok tüketimi'"),
			PrintingInternalConsumption(ObjectsArray, PrintObjects));
		
	EndIf;
	
	InventoryConsumptionLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function PrintingInternalConsumption(ObjectsArray, PrintObjects)

	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputAdditionalColumn = ValueIsFilled(NameOfCodeColumn);

	RequestForDocuments = New Query;
	RequestForDocuments.SetParameter("ObjectsArray", ObjectsArray);
	RequestForDocuments.Text =
	"SELECT
	|	Document.Ref                             AS Ref,
	|	Document.Number                              AS Number,
	|	Document.Date                               AS Date,
	|	Document.CorrectedDocument.Number         AS NumberOfDocumentBeingCorrected,
	|	Document.CorrectedDocument.Date          AS DateOfDocumentBeingCorrected,
	|	REFPRESENTATION(Document.Warehouse)         AS Warehouse,
	|	REFPRESENTATION(Document.Department)	AS Department,
	|	Document.Organization					    AS Organization,
	|	Document.Organization.Prefix                AS Prefix,
	|	GoodsTable.LineNumber                   AS LineNumber,
	|	&AdditionalColumn                                 AS AdditionalColumn,
	|	GoodsTable.Products.DescriptionFull   AS Products,
	|	GoodsTable.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
	|		ELSE REFPRESENTATION(GoodsTable.Package)
	|	END                                       AS Package,
	|	GoodsTable.NumberOfPackages            AS Count
	|FROM
	|	Document.InventoryConsumption AS Document
	|	
	|	INNER JOIN Document.InventoryConsumption.Goods AS GoodsTable
	|	ON GoodsTable.Ref = Document.Ref
	|
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Date, Ref, LineNumber
	|
	|TOTALS
	|	MAX(Number),
	|	MAX(Date),
	|	MAX(NumberOfDocumentBeingCorrected),
	|	MAX(DateOfDocumentBeingCorrected),
	|	MAX(Warehouse),
	|	MAX(Department),
	|	MAX(Organization),
	|	MAX(Prefix)
	|BY
	|	Ref
	|";
	
	SubstitutionOfAdditionalColumn = "0";
	If OutputAdditionalColumn Then
		SubstitutionOfAdditionalColumn = "GoodsTable.Products." + NameOfCodeColumn;
	EndIf;
	
	RequestForDocuments.Text = StrReplace(RequestForDocuments.Text, "&AdditionalColumn", SubstitutionOfAdditionalColumn);
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_InventoryConsumption";

	DocumentAttributes = New Structure("Number, Date, Prefix, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	If GetFunctionalOption("BaseVersion") Then
		DocumentSynonym = NStr("vi = 'Ghi giảm hàng hóa và thực hiện các công việc cho nhu cầu kinh doanh';
								|ru = 'Списание товаров и работ на хознужды';
								|en = 'Write off goods and works for business needs'; fa = 'Write off goods and works for business needs';
								|it = 'Storno articoli e lavori per fini aziendali';
								|pl = 'Rozchód towarów i prac na potrzeby gospodarcze';
								|tr = 'Ev ihtiyaçları için malların ve işlerin gider yazılması'");
	Else
		DocumentSynonym = Metadata.Documents.InventoryConsumption.Synonym;
	EndIf;

	Template = PrintManagement.PrintFormTemplate("Document.InventoryConsumption.PF_MXL_InventoryConsumption");
	HeaderArea_ = Template.GetArea("Title");
	LabelArea   = Template.GetArea("Signatures");
	If OutputAdditionalColumn Then
		AreaRow       = Template.GetArea("RowColumn");
		Area_TableHeader = Template.GetArea("TableHeaderAdditionalColumn");
	Else
		AreaRow       = Template.GetArea("String");
		Area_TableHeader = Template.GetArea("TableHeader");
	EndIf;
	
	FirstDocument = True;
	DocumentsSelection = RequestForDocuments.Execute().Select(QueryResultIteration.ByGroups);
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	While DocumentsSelection.Next() Do
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		// Header output.
		FillPropertyValues(DocumentAttributes, DocumentsSelection);
		HeaderArea_.Parameters.Fill(DocumentsSelection);
		DataOfArea = New Structure;
		DataOfArea.Insert("TitleText",
						TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		DataOfArea.Insert("Organization", NamesAsOfDate.AbbreviatedDescription);
		HeaderArea_.Parameters.Fill(DataOfArea);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);
		
		// Output of the header.
		If OutputAdditionalColumn Then
			Area_TableHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
		EndIf;
		TabDocument.Put(Area_TableHeader);
		
		// Output of document lines.
		
		StringSelection = DocumentsSelection.Select(); // QueryResultSelection
		While StringSelection.Next() Do
			
			AreaRow.Parameters.Fill(StringSelection);
			
			AreaRow.Parameters.Products = ProductsClientServer.PresentationOfProductsForPrinting(
				StringSelection.Products,
				StringSelection.Characteristic,
				,
				,
				AdditionalParametersProductPresentation);
			
			TabDocument.Put(AreaRow);
			
		EndDo;
		
		// Output of the basement.
		TabDocument.Put(LabelArea);

		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);

	EndDo;
	
	Return TabDocument;

EndFunction

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
	|	Document.InventoryConsumption.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToOperation)
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

#Region FillingInDocument_

Procedure RequestParametersToCreateBasedOn(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", True);
	QueryParameters.Insert("Warehouse", SelectionData_.HeaderAttributes.Warehouse);
	QueryParameters.Insert("LineOfBusiness", SelectionData_.HeaderAttributes.LineOfBusiness);
	QueryParameters.Insert("ExpenseLineOfBusinessIsSpecifiedInList", SelectionData_.ExpenseLineOfBusinessIsSpecifiedInList);
	
	If SelectionData_.FillByWarehouseDocument Then
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TTLBOfExpensesIsIndicatedInList");
		QueryNames.Add("TableShipped");
		
		QueryNames.Add("TableOfContents_");
		SubqueryNames.Add("BlockRegisterOrders");
		SubqueryNames.Add("BlockRegisterOrdersRepairs");
	Else
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TTLBOfExpensesIsIndicatedInList");
		
		QueryNames.Add("TableOfContents_");
		SubqueryNames.Add("BlockRegisterOrders");
		SubqueryNames.Add("BlockRegisterOrdersRepairs");
	EndIf;
	
EndProcedure

Procedure QueryParametersForMatching(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("SelectByOrder_", SelectionData_.AnArrayOfOrders.Count() = 1);
	QueryParameters.Insert("Recorder",      SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("Organization",      SelectionData_.HeaderAttributes.Organization);
	QueryParameters.Insert("Warehouse",            SelectionData_.HeaderAttributes.Warehouse);
	QueryParameters.Insert("BusinessOperation", SelectionData_.HeaderAttributes.BusinessOperation);
	QueryParameters.Insert("SalesOpportunity",                SelectionData_.HeaderAttributes.SalesOpportunity);
	QueryParameters.Insert("LineOfBusiness", SelectionData_.HeaderAttributes.LineOfBusiness);
	QueryParameters.Insert("InvoiceGoods",       SelectionData_.InvoiceGoods);
	QueryParameters.Insert("InvoiceForOrders",    SelectionData_.InvoiceForOrders);
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", True);
	QueryParameters.Insert("ExpenseLineOfBusinessIsSpecifiedInList", SelectionData_.ExpenseLineOfBusinessIsSpecifiedInList);
	
	QueryNames.Add("TTOrdersSelection");
	QueryNames.Add("TTLBOfExpensesIsIndicatedInList");
	QueryNames.Add("TTInvoice");
	QueryNames.Add("TableShipped");
	
	QueryNames.Add("TableOfContents_");
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		SubqueryNames.Add("BlockRegisterOrders");
		SubqueryNames.Add("StornoInvoiceBlock");
	EndIf;
	SubqueryNames.Add("BlockNewRegisteredRecordsInvoice");
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		SubqueryNames.Add("BlockRegisterOrdersRepairs");
		SubqueryNames.Add("BlockStornoOverheadRepairs");
	EndIf;
EndProcedure

Procedure RequestParametersForOrderReplenishment(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",      SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_",   True);
	QueryParameters.Insert("Recorder",        SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("Warehouse",              SelectionData_.HeaderAttributes.Warehouse);
	QueryParameters.Insert("InvoiceGoods",    SelectionData_.InvoiceGoods);
	QueryParameters.Insert("InvoiceForOrders", SelectionData_.InvoiceForOrders);
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", True);
	QueryParameters.Insert("FillInAsNeeded", True);
	QueryParameters.Insert("ExpenseLineOfBusinessIsSpecifiedInList", SelectionData_.ExpenseLineOfBusinessIsSpecifiedInList);
	
	QueryNames.Add("TTOrdersSelection");
	QueryNames.Add("TTLBOfExpensesIsIndicatedInList");
	QueryNames.Add("TTInvoice");
	QueryNames.Add("TableShipped");
	
	QueryNames.Add("TableOfContents_");
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		SubqueryNames.Add("BlockRegisterOrders");
		SubqueryNames.Add("StornoInvoiceBlock");
	EndIf;
	SubqueryNames.Add("BlockNewRegisteredRecordsInvoice");
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		SubqueryNames.Add("BlockRegisterOrdersRepairs");
		SubqueryNames.Add("BlockStornoOverheadRepairs");
	EndIf;
EndProcedure

Procedure RequestParametersToFillInForOrders(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", SelectionData_.AnArrayOfOrders.Count() = 1);
	QueryParameters.Insert("Recorder",      SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("Organization",      SelectionData_.HeaderAttributes.Organization);
	QueryParameters.Insert("Warehouse",            SelectionData_.HeaderAttributes.Warehouse);
	QueryParameters.Insert("BusinessOperation", SelectionData_.HeaderAttributes.BusinessOperation);
	QueryParameters.Insert("SalesOpportunity",                SelectionData_.HeaderAttributes.SalesOpportunity);
	QueryParameters.Insert("LineOfBusiness", SelectionData_.HeaderAttributes.LineOfBusiness);
	QueryParameters.Insert("ExpenseLineOfBusinessIsSpecifiedInList", SelectionData_.ExpenseLineOfBusinessIsSpecifiedInList);
	
	If SelectionData_.FillByWarehouseDocument Then
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TTLBOfExpensesIsIndicatedInList");
		QueryNames.Add("TableShipped");
		
		QueryNames.Add("TableOfContents_");
		If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
			SubqueryNames.Add("BlockRegisterOrders");
			SubqueryNames.Add("StornoInvoiceBlock");
		EndIf;
		If AccessRight("Read", Metadata.Documents.RMOrder) Then
			SubqueryNames.Add("BlockRegisterOrdersRepairs");
			SubqueryNames.Add("BlockStornoOverheadRepairs");
		EndIf;
	Else
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TTLBOfExpensesIsIndicatedInList");
		
		QueryNames.Add("TableOfContents_");
		If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
			SubqueryNames.Add("BlockRegisterOrders");
			SubqueryNames.Add("StornoInvoiceBlock");
		EndIf;
		If AccessRight("Read", Metadata.Documents.RMOrder) Then
			SubqueryNames.Add("BlockRegisterOrdersRepairs");
			SubqueryNames.Add("BlockStornoOverheadRepairs");
		EndIf;
	EndIf;
	
EndProcedure

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
		|	Table.ExpenseItem        AS ExpenseItem,
		|	Table.DimensionOfExpenses     AS DimensionOfExpenses,
		|	Table.Individual        AS Individual,
		|	Table.OperationCategory AS OperationCategory,
		|	Table.ProductsGroup       AS ProductsGroup,
		|	Table.LineOfBusiness AS LineOfBusiness,
		|	&ExpenseLineOfBusinessIsSpecifiedInList AS ExpenseLineOfBusinessIsSpecifiedInList, 
		|
		|	Table.RowCode             AS RowCode,
		|	Table.Package              AS Package,
		|
		|	CASE WHEN NOT &InvoiceForOrders THEN
		|				&Recorder
		|			ELSE
		|				Table.InventoryConsumptionOrder
		|		END                     AS OrderDocument
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

Function QueryTextOfTemporaryOrderTable()
	
	QueryTexts = New Array();
	Text =
		"SELECT
		|	&Recorder AS OrderDocument,
		|	&ExpenseLineOfBusinessIsSpecifiedInList AS ExpenseLineOfBusinessIsSpecifiedInList
		|INTO TTOrdersSelection";
	QueryTexts.Add(Text);
	
	If AccessRight("Read", Metadata.Documents.InventoryConsumptionOrder) Then
		
		Text =
			"SELECT
			|	InventoryConsumptionOrder.Ref AS OrderDocument,
			|	InventoryConsumptionOrder.ExpenseLineOfBusinessIsSpecifiedInList AS ExpenseLineOfBusinessIsSpecifiedInList
			|FROM
			|	Document.InventoryConsumptionOrder AS InventoryConsumptionOrder
			|WHERE
			|	CASE
			|		WHEN &SelectByOrder_ THEN
			|			InventoryConsumptionOrder.Ref IN (&AnArrayOfOrders)
			|		ELSE
			|			InventoryConsumptionOrder.Organization           = &Organization
			|			AND InventoryConsumptionOrder.Warehouse                 = &Warehouse
			|			AND InventoryConsumptionOrder.SalesOpportunity                = &SalesOpportunity
			|			AND InventoryConsumptionOrder.BusinessOperation = &BusinessOperation
			|			AND InventoryConsumptionOrder.LineOfBusiness = &LineOfBusiness
			|	END
			|	AND InventoryConsumptionOrder.Posted";
		QueryTexts.Add(Text);
		
	EndIf;
	If AccessRight("Read", Metadata.Documents.RMOrder) Then
		
		Text =
			"SELECT DISTINCT
			|	RMOrder.Ref AS OrderDocument,
			|	FALSE AS ExpenseLineOfBusinessIsSpecifiedInList
			|FROM
			|	Document.RMOrder AS RMOrder
			|		INNER JOIN Document.RMOrder.MaterialsAndWorks AS Goods
			|		ON RMOrder.Ref = Goods.Ref
			|WHERE
			|	CASE
			|		WHEN &SelectByOrder_ THEN
			|			RMOrder.Ref IN (&AnArrayOfOrders)
			|		ELSE
			|			RMOrder.Organization           = &Organization
			|			AND (Goods.Warehouse                        = &Warehouse
			|				OR Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))
			|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)
			|			AND RMOrder.LineOfBusiness = &LineOfBusiness
			|	END
			|	AND RMOrder.Posted";
		QueryTexts.Add(Text);
		
	EndIf;
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = QueryText + "
		|
		|;
		|
		|//////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function QueryTextOfTemporaryTableOfLBExpenses()
	
	QueryText = 
		"SELECT
		|	ISNULL(MAX(TTOrdersSelection.ExpenseLineOfBusinessIsSpecifiedInList), FALSE) AS LBOfExpensesInvoice
		|INTO TTLBOfExpensesIsIndicatedInList
		|FROM
		|	TTOrdersSelection AS TTOrdersSelection";
	
	QueryText = QueryText + "
		|
		|;
		|
		|//////////////////////////////////////////////////
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
		|	Set.OrderDocument             AS InventoryConsumptionOrder,
		|	Set.RowCode         AS RowCode,
		|
		|	Set.Products                     AS Products,
		|	Set.Characteristic                   AS Characteristic,
		|	MAX(Set.Purpose)             AS Purpose,
		|	Set.Series                            AS Series,
		|	MAX(Set.Date)                   AS Date,
		|	MAX(Set.LineNumber)            AS LineNumber,
		|	MAX(Set.LineOfBusiness) AS LineOfBusiness,
		|	MAX(Set.ExpenseLineOfBusinessIsSpecifiedInList) AS ExpenseLineOfBusinessIsSpecifiedInList,
		|	MAX(Set.DateOfShipment)           AS DateOfShipment,
		|	MAX(Set.ExpenseItem)         AS ExpenseItem,
		|	MAX(Set.DimensionOfExpenses)      AS DimensionOfExpenses,
		|	MAX(Set.ProductsGroup)        AS ProductsGroup,
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
		|	SUM(Set.QuantityInInvoice)     AS QuantityInInvoice,
		|
		|	MAX(Set.Individual)        AS Individual,
		|	MAX(Set.OperationCategory) AS OperationCategory
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

Function RequestTextUpperCaseOrders()
	
	QueryText =
		"	SELECT
		|		TableBalance.InventoryConsumptionOrder AS OrderDocument,
		|		TableBalance.RowCode          AS RowCode,
		|
		|		TableBalance.ToRegisterBalance AS QuantityInOrder,
		|		0                                 AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableBalance.Products       AS Products,
		|		TableBalance.Characteristic     AS Characteristic,
		|
		|		CASE WHEN Table.WithAssignment THEN
		|			
		|					Table.Ref.Purpose
		|			
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			
		|			END                         AS Purpose,
		|
		|		TableBalance.Series              AS Series,
		|		Table.Ref.Date               AS Date,
		|		Table.LineNumber               AS LineNumber,
		|		Table.DateOfShipment              AS DateOfShipment,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				CASE 
		|					WHEN Table.Ref.ExpenseLineOfBusinessIsSpecifiedInList THEN
		|						Table.LineOfBusiness
		|					ELSE
		|						Table.Ref.LineOfBusiness
		|				END
		|			ELSE
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		END                             AS LineOfBusiness,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				TRUE
		|			ELSE
		|				Table.Ref.ExpenseLineOfBusinessIsSpecifiedInList
		|		END AS ExpenseLineOfBusinessIsSpecifiedInList,
		|		Table.ExpenseItem            AS ExpenseItem,
		|		Table.DimensionOfExpenses         AS DimensionOfExpenses,
		|		Table.ProductsGroup           AS ProductsGroup,
		|		FALSE                              AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		Table.Individual               AS Individual,
		|		Table.OperationCategory        AS OperationCategory
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders.Balance(,
		|				(InventoryConsumptionOrder, Warehouse) IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument,
		|						&Warehouse AS Warehouse
		|					FROM
		|						TTOrdersSelection AS Table)) AS TableBalance
		|
		|			INNER JOIN Document.InventoryConsumptionOrder.Goods AS Table
		|			ON TableBalance.InventoryConsumptionOrder = Table.Ref
		|			 AND TableBalance.RowCode = Table.RowCode
		|			LEFT JOIN TTLBOfExpensesIsIndicatedInList AS LBOfExpenses
		|			ON TRUE";
	
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
			
	Return QueryText;
	
EndFunction

Function RequestTextInvoice()
	
	QueryText =
		"	SELECT
		|		TableStorno.InventoryConsumptionOrder AS OrderDocument,
		|		TableStorno.RowCode          AS RowCode,
		|
		|		TableStorno.ToRegister        AS QuantityInOrder,
		|		0                                AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableStorno.Products       AS Products,
		|		TableStorno.Characteristic     AS Characteristic,
		|
		|		CASE WHEN Table.WithAssignment THEN
		|			
		|					Table.Ref.Purpose
		|			
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			
		|			END                        AS Purpose,
		|
		|		TableStorno.Series              AS Series,
		|		Table.Ref.Date              AS Date,
		|		Table.LineNumber              AS LineNumber,
		|		Table.DateOfShipment             AS DateOfShipment,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				CASE 
		|					WHEN Table.Ref.ExpenseLineOfBusinessIsSpecifiedInList THEN
		|						Table.LineOfBusiness
		|					ELSE
		|						Table.Ref.LineOfBusiness
		|				END
		|			ELSE
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		END                             AS LineOfBusiness,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				TRUE
		|			ELSE
		|				Table.Ref.ExpenseLineOfBusinessIsSpecifiedInList
		|		END AS ExpenseLineOfBusinessIsSpecifiedInList,
		|		Table.ExpenseItem           AS ExpenseItem,
		|		Table.DimensionOfExpenses        AS DimensionOfExpenses,
		|		Table.ProductsGroup          AS ProductsGroup,
		|		FALSE                             AS ExistsInTheDocument,
		|
		|		Table.Package                 AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		Table.Individual               AS Individual,
		|		Table.OperationCategory        AS OperationCategory
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders AS TableStorno
		|
		|			INNER JOIN Document.InventoryConsumptionOrder.Goods AS Table
		|			ON Table.Ref = TableStorno.InventoryConsumptionOrder
		|			 AND Table.RowCode = TableStorno.RowCode
		|			LEFT JOIN TTLBOfExpensesIsIndicatedInList AS LBOfExpenses
		|			ON TRUE
		|
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND (TableStorno.InventoryConsumptionOrder, TableStorno.Warehouse) IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument,
		|				&Warehouse AS Warehouse
		|			FROM
		|				TTOrdersSelection AS Table)
		|		AND TableStorno.Active";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
			
	Return QueryText;
	
EndFunction

Function RequestTextRegisterBalancesOrdersRepairs()
	
	QueryText =
		"	SELECT
		|		TableBalance.InventoryConsumptionOrder AS OrderDocument,
		|		TableBalance.RowCode          AS RowCode,
		|
		|		TableBalance.ToRegisterBalance AS QuantityInOrder,
		|		0                                 AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableBalance.Products       AS Products,
		|		TableBalance.Characteristic     AS Characteristic,
		|
		|		CASE WHEN Table.WithAssignment THEN
		|			
		|					Table.Ref.Purpose
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			
		|			END                         AS Purpose,
		|
		|		TableBalance.Series              AS Series,
		|		Table.Ref.Date               AS Date,
		|		Table.LineNumber               AS LineNumber,
		|
		|		CASE WHEN Table.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|					Table.Ref.CompletedOn
		|				ELSE
		|					Table.Ref.StartDate
		|			END                         AS DateOfShipment,
		|
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				Table.Ref.LineOfBusiness
		|			ELSE
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		END AS LineOfBusiness,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END AS ExpenseLineOfBusinessIsSpecifiedInList,
		|		RM.ExpenseItem                                       AS ExpenseItem,
		|		CASE 
		|			WHEN RM.ExpenseItem.ExpensesOnAssets
		|				THEN Table.Ref.Asset
		|			WHEN RM.ExpenseItem.RMOrderExpenses
		|				THEN Table.Ref
		|			ELSE UNDEFINED
		|		END AS DimensionOfExpenses,
		|		VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|		FALSE                                                         AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		VALUE(Catalog.Persons.EmptyRef)             AS Individual,
		|		VALUE(Catalog.OperationCategories.EmptyRef)      AS OperationCategory
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders.Balance(,
		|				(InventoryConsumptionOrder, Warehouse) IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument,
		|						&Warehouse AS Warehouse
		|					FROM
		|						TTOrdersSelection AS Table)) AS TableBalance
		|
		|			INNER JOIN Document.RMOrder.MaterialsAndWorks AS Table
		|			ON TableBalance.InventoryConsumptionOrder = Table.Ref
		|			 AND TableBalance.RowCode = Table.RowCode
		|
		|			INNER JOIN Document.RMOrder.RM AS RM
		|			ON Table.Ref = RM.Ref
		|				AND Table.RMCode = RM.RMCode
		|			LEFT JOIN TTLBOfExpensesIsIndicatedInList AS LBOfExpenses
		|			ON TRUE";
	
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
			
	Return QueryText;
	
EndFunction

Function RequestTextReverseInvoiceRepairs()
	
	QueryText =
		"	SELECT
		|		TableStorno.InventoryConsumptionOrder AS OrderDocument,
		|		TableStorno.RowCode          AS RowCode,
		|
		|		TableStorno.ToRegister        AS QuantityInOrder,
		|		0                                AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableStorno.Products       AS Products,
		|		TableStorno.Characteristic     AS Characteristic,
		|
		|		CASE WHEN Table.WithAssignment THEN
		|			
		|					Table.Ref.Purpose
		|
		|				ELSE
		|
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			
		|			END                         AS Purpose,
		|
		|		TableStorno.Series               AS Series,
		|		Table.Ref.Date               AS Date,
		|		Table.LineNumber               AS LineNumber,
		|
		|		CASE WHEN Table.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|					Table.Ref.CompletedOn
		|				ELSE
		|					Table.Ref.StartDate
		|			END                         AS DateOfShipment,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				Table.Ref.LineOfBusiness
		|			ELSE
		|				VALUE(Catalog.LinesOfBusiness.EmptyRef)			
		|		END AS LineOfBusiness,
		|		CASE 
		|			WHEN LBOfExpenses.LBOfExpensesInvoice THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END AS ExpenseLineOfBusinessIsSpecifiedInList,
		|		RM.ExpenseItem                                       AS ExpenseItem,
		|		CASE 
		|			WHEN RM.ExpenseItem.ExpensesOnAssets
		|				THEN Table.Ref.Asset
		|			WHEN RM.ExpenseItem.RMOrderExpenses
		|				THEN Table.Ref
		|			ELSE UNDEFINED
		|		END AS DimensionOfExpenses,
		|		VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
		|		FALSE                                                         AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		VALUE(Catalog.Persons.EmptyRef)             AS Individual,
		|		VALUE(Catalog.OperationCategories.EmptyRef)      AS OperationCategory
		|	FROM
		|		AccumulationRegister.InventoryConsumptionOrders AS TableStorno
		|
		|			INNER JOIN Document.RMOrder.MaterialsAndWorks AS Table
		|			ON Table.Ref = TableStorno.InventoryConsumptionOrder
		|			 AND Table.RowCode = TableStorno.RowCode
		|
		|			INNER JOIN Document.RMOrder.RM AS RM
		|			ON Table.Ref = RM.Ref
		|				AND Table.RMCode = RM.RMCode
		|			LEFT JOIN TTLBOfExpensesIsIndicatedInList AS LBOfExpenses
		|			ON TRUE
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND (TableStorno.InventoryConsumptionOrder, TableStorno.Warehouse) IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument,
		|				&Warehouse AS Warehouse
		|			FROM
		|				TTOrdersSelection AS Table)
		|		AND TableStorno.Active";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
			
	Return QueryText;
	
EndFunction
Function RequestTextShippedByOrders()
	
	QueryText =
		"SELECT
		|	TableBalance.DocumentShipments       AS InventoryConsumptionOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Series                  AS Series,
		|	TableBalance.Purpose             AS Purpose,
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
		|		 + TableBalance.Assembled)         AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsForIssue AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentShipments
		|		 AND &Warehouse = TableBalance.Warehouse
		|		 AND TableBalance.Active
		|
		|GROUP BY
		|	TableBalance.DocumentShipments,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Series, TableBalance.Purpose
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
		|			END + TableBalance.Assembled) > 0
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextNewTrafficInvoice()
	
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
		|		Table.ExpenseItem        AS ExpenseItem,
		|		Table.DimensionOfExpenses     AS DimensionOfExpenses,
		|		Table.ProductsGroup       AS ProductsGroup,
		|		TRUE                        AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor,
		|
		|		Table.Individual               AS Individual,
		|		Table.OperationCategory        AS OperationCategory
		|	FROM
		|		TTInvoice AS Table";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure)",
		"Table.Products"));
			
	Return QueryText;
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

Function FillInInitialParameters(DocumentRef, QueryTexts)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.InventoryConsumption AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";

	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	QueryText =
	"SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_
	|INTO TTCategoriesOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(
	|			&Period,
	|			(Products, Country) IN
	|				(SELECT
	|					T.Products AS Products,
	|					&RegistrationCountry AS Country
	|				FROM
	|					Document.InventoryConsumption.Goods AS T
	|				WHERE
	|					T.Ref = &Ref)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods";

	QueryTexts.Add(QueryText, "TTCategoriesOfExcisableItems");

	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.FinRecordID AS FinRecordID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseAmountInCurrencyLocal,
	|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	ISNULL(TableExciseCategories.ExcisableGoodsCategory, VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)) AS ExcisableGoodsCategory,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SubjectToExcise
	|			THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * TableTypesOfStocks_.Count
	|		ELSE 0
	|	END AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.GLAccountSettings AS GLAccountSettings
	|INTO TTTypesOfStocks
	|FROM
	|	Document.InventoryConsumption.InventoryKinds AS TableTypesOfStocks_
	|		INNER JOIN TTCategoriesOfExcisableItems AS TableExciseCategories
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = TableExciseCategories.Products
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableExciseCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)";
	
	QueryTexts.Add(QueryText, "TTTypesOfStocks");
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	Query.SetParameter("UseExcisableGoods", GetFunctionalOption("UseExcisableGoods"));

	Return Query;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
