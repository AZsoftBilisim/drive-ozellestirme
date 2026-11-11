#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
EndProcedure

// Returns parameters for selecting articles in the document.
//
// Parameters:
//  PurchaseObjective - EnumRef.PurchaseObjectives - The corresponding Attribute of the document
// 
// Returns:
// 	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(PurchaseObjective) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.AvailabilityByOperation = PurchaseTargetsWithBDRLimitControl().Find(PurchaseObjective) <> Undefined;
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
	
	// The needs for work in the recipient department.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Goods.Department";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
		
	Return FormTemplate;
	
EndFunction

#Region AttachableCommands

#Region GenerateFrom

// Adds a command to create a "Purchase Request" document.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - Added table row if the Command is available
//@skip-check function-return-types
Function AddGenerateCommand(GenerationCommands) Export
	
	CreateBasedOnCommand = Undefined;
	
	MetadataOfDocument = Metadata.Documents.PurchaseRequest;
	If AccessRight("Insert", MetadataOfDocument) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = MetadataOfDocument.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(MetadataOfDocument);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseRequests";
		
	EndIf;
	
	Return CreateBasedOnCommand;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	PurchaseRequestLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
		
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfExecutionDocumentCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
		
	ReportCommand = Reports.VariancesFromPurchaseConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	ReportCommand = Reports.LimitsByBudgetingData.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.FunctionalOptions = "UseIEBLimitsOnPurchases";
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,
			"PurchaseObjective",
			PurchaseTargetsWithBDRLimitControl(),
			DataCompositionComparisonType.InList);
	EndIf;
EndProcedure

// Initializes the status structure of the document
//
// Returns:
//  Structure - See Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.DisplayTableForOrder = 1;
	
	Return StructureState;
	
EndFunction

#EndRegion

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	If Not AccessRight("Edit", Metadata.Documents.PurchaseRequest)
		Or Not GetFunctionalOption("UsePurchaseRequests") Then
		Return;
	EndIf;
	
	Performer = CommonQueryParameters.User;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED TOP 1
	|	ISNULL(COUNT(PurchaseRequest.Ref), 0) AS NumberOfRequests
	|FROM
	|	Document.PurchaseRequest AS PurchaseRequest
	|WHERE
	|	PurchaseRequest.Performer = &Performer
	|	AND PurchaseRequest.Posted";
	
	Query.SetParameter("Performer", Performer);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	NumberOfApplicationsToBeProcessed = Selection.NumberOfRequests;
	HasToDoItems = ValueIsFilled(NumberOfApplicationsToBeProcessed);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterApplicationsForWorkingOut(Performer));
	FormParameters.Insert("PurposeUseKey", "ApplicationsForWorkingOut");
	FormParameters.Insert("Filter", New Structure("Posted", True));
	
	ParentID = "PurchaseRequests";
	
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = ParentID;
	UserTaskParent.Presentation  = NStr("vi = 'Yêu cầu mua hàng';
										|ru = 'Заявки на закупку';
										|en = 'Purchase requests'; fa = 'درخواست‌های خرید';
										|it = 'Purchase requests';
										|pl = 'Purchase requests';
										|tr = 'Satın alma talepleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	UserTaskParent.HasToDoItems       = HasToDoItems;
	
	CurCase = ToDoList.Add();
	CurCase.Id = "PurchaseRequestsForProcessing";
	CurCase.Presentation = NStr("vi = 'Yêu cầu mua hàng cần xử lý';
								|ru = 'Заявки на закупку к отработке';
								|en = 'Purchase requests to process'; fa = 'Purchase requests to process';
								|it = 'Purchase requests to process';
								|pl = 'Purchase requests to process';
								|tr = 'İşlenecek satın alma talepleri'");
	CurCase.Count = NumberOfApplicationsToBeProcessed;
	CurCase.Form = "Document.PurchaseRequest.ListForm";
	CurCase.FormParameters = FormParameters;
	CurCase.Owner = ParentID;
	CurCase.HasToDoItems = HasToDoItems;
		
EndProcedure

#EndRegion

#Region FillingInStatistics

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Warehouse, Department, EmployeeResponsible", Parameters);
	
EndProcedure

#EndRegion

#Region ObjectsVersioning

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
	Return; // empty handler
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region AccessManagement

// Description of the access restriction logic.
// 
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)";

EndProcedure

#EndRegion

#Region ProcessingOfTabularPart

#Region FillInVATTaxationPurchases

// Returns the parameters for filling in the "Taxation Lands" Attribute for a row in the table part.
// IMPORTANT! The Attribute "Business Operation" should be added to the line.
// 
// Parameters:
//  RowOfGoods - FormDataCollectionItem, ValueTableRow - table part string 
//  ActionParameters - Structure:
//   * Date - Date - document date.
// 
// Returns:
// See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
Function VATTaxationParameters(RowOfGoods, ActionParameters) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Period     = ActionParameters.Date;
	FillParameters.Counterparty = RowOfGoods.Counterparty;
	FillParameters.Contract    = RowOfGoods.Contract;
	 
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
		
	If BusinessTransactionsPurchasingFromSupplier.Find(RowOfGoods.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = True;
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(RowOfGoods.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
		
	ElsIf BusinessTransactionsImportPurchase.Find(RowOfGoods.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoods = True;
		
	ElsIf  RowOfGoods.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		FillParameters.VMIProcurement = True;
		
	ElsIf RowOfGoods.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
		FillParameters.ConsignmentProcurement = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndRegion

#Region Internal

// Contains methods describing the interaction of purchase requests with orders to suppliers
#Region PurchaseOrders

// Receives the request based on which the order was created to the supplier.
// 
// Parameters:
//  PurchaseOrder - DocumentRef.PurchaseOrder, DocumentObject.PurchaseOrder, FormDataStructure - The order, the basis of which must be received.
// 
// Returns:
//  DocumentRef.PurchaseRequest - Request-the basis of the order to the supplier
Function ApplicationForBasisOfPurchaseOrderToSupplier(Val PurchaseOrder) Export
	
	ReturnValue = EmptyRef();
	
	If TypeOf(PurchaseOrder) <> Type("DocumentRef.PurchaseOrder") Then
		
		If ValueIsFilled(PurchaseOrder.DocumentBasis)
			And TypeOf(PurchaseOrder.DocumentBasis) = Type("DocumentRef.PurchaseRequest") Then
			
			// For cases when a new object was created based on an application.
			Return PurchaseOrder.DocumentBasis;
		
		ElsIf ValueIsFilled(PurchaseOrder.Ref) Then
			
			// Execution of standard search logic for commercial offer requests.
			PurchaseOrder = PurchaseOrder.Ref;
			
		Else // A new object that was not created based on an application.
			
			Return ReturnValue;
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	Filters = NewSelectionsOfPresentationsOfProcurementApplications();
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.PurchaseOrder, PurchaseOrder);
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.OrderWasCreatedBasedOnRequest, True);
	
	Query = New Query;
	Query.Text = QueryTextOrdersOfApplications(Filters, False);
	SetSelectionOfPurchaseRequestsInRequestParameters(Query, Filters);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ReturnValue = Selection.PurchaseRequest;
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Complete the list of values with query texts 
// to form the "To Order" table of the "Document Execution Statuses" report.
// 
// Parameters:
//  QueriesTexts - ValueList of String - Updated list of query texts
//  NameOfRequestSelectionParameter - String - The name of the parameter that passes the array of purchase requests in the updated request.
Procedure AddQueryTextOfTableToOrder(QueriesTexts, NameOfRequestSelectionParameter) Export
	
	Filters = NewSelectionsOfPresentationsOfProcurementApplications();
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.PurchaseRequest, "&" + NameOfRequestSelectionParameter, True);
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.OrderPosted, True);
	
	QueryBatchSeparator = Common.QueryBatchSeparator();
	
	QueryTextOrdersOfApplications = QueryTextOrdersOfApplications(Filters) + QueryBatchSeparator;
	QueryTextPurchaseRequestsReceiptInDetail = QueryTextPurchaseRequestsReceiptInDetail(Filters) + QueryBatchSeparator;
	QueryTextPurchaseRequestsExpenseInDetail = QueryTextPurchaseRequestsExpenseInDetail() + QueryBatchSeparator;
	QueryTextPurchaseRequestsHardKeyBalances = QueryTextPurchaseRequestsHardKeyBalances() + QueryBatchSeparator;
	QueryTextPurchaseRequestsBalancesWithoutAgreements = QueryTextPurchaseRequestsBalancesWithoutAgreements() + QueryBatchSeparator;
	QueryTextPurchaseRequestsBalancesWithoutPartners = QueryTextPurchaseRequestsBalancesWithoutPartners() + QueryBatchSeparator;
	QueryTextPurchaseRequestsBalancesAreSummarized = QueryTextPurchaseRequestsBalancesAreSummarized(
		"PurchaseRequestsBalancesAreSummarized",
		True) + QueryBatchSeparator;
	QueryTextTableToOrder = QueryTextTableToOrder() + QueryBatchSeparator;
	
	QueriesTexts.Add(QueryTextOrdersOfApplications,                          "PurchaseRequestOrders");
	QueriesTexts.Add(QueryTextPurchaseRequestsReceiptInDetail,         "PurchaseRequestsReceiptInDetail");
	QueriesTexts.Add(QueryTextPurchaseRequestsExpenseInDetail,         "PurchaseRequestsExpenseInDetail");
	QueriesTexts.Add(QueryTextPurchaseRequestsHardKeyBalances, "PurchaseRequestsHardKeyBalances");
	QueriesTexts.Add(QueryTextPurchaseRequestsBalancesWithoutAgreements,   "PurchaseRequestsBalancesWithoutAgreements");
	QueriesTexts.Add(QueryTextPurchaseRequestsBalancesWithoutPartners,    "PurchaseRequestsBalancesWithoutPartners");
	QueriesTexts.Add(QueryTextPurchaseRequestsBalancesAreSummarized,       "PurchaseRequestsBalancesAreSummarized");
	QueriesTexts.Add(QueryTextTableToOrder,                        "TableToOrder");
	
EndProcedure

// Describes the order to be entered on the specified lines of the purchase request.
// 
// Parameters:
//  PurchaseRequest - DocumentRef.PurchaseRequest - The basis for the order being created to the supplier
//  LineNumbers - Array of Number - The line numbers of the purchase request for which the order is generated to the supplier.
// 
// Returns:
//  Structure - Description Of The Order To Be Created:
// * OrderData - 
//   - Undefined
//   - Structure:
//   ** Basis - DocumentRef.PurchaseRequest - For which the order is created.
//   ** Organization - CatalogRef.Companies
//   ** Warehouse - CatalogRef.Warehouses
//   ** Department - CatalogRef.BusinessStructure
//   ** Currency - CatalogRef.Currencies
//   ** PriceIncludesVAT - Boolean
//   ** Partner - CatalogRef.Partners
//   ** Counterparty - CatalogRef.Counterparties
//   ** Terms - CatalogRef.TermsOfPurchaseFromVendors
//   ** Contract - CatalogRef.CounterpartyContracts
//   ** Goods - ValueTable:
//     *** Products - CatalogRef.Products
//     *** Characteristic - CatalogRef.ItemsCharacteristics
//     *** Purpose - CatalogRef.Assignments
//     *** PartnerProducts - CatalogRef.ProductCrossReferences
//     *** VendorPriceKind - CatalogRef.VendorPriceTypes
//     *** Price -Number
//     *** VATRate - CatalogRef.VATRates
//     *** Count - Number
//     *** NumberOfPackages - Number
//     *** Package - CatalogRef.PackagesAndUnitsOfMeasure
//     *** Warehouse - CatalogRef.Warehouses
//     *** Department - CatalogRef.BusinessStructure
//     *** Sum - Number
//     *** VATAmount - Number
//     *** AmountIncludingVAT - Number
// * ProcessedSourceLines - Number - The number of source lines of the purchase order that will be ordered in the created order.
// * NotProcessedSourceLines - Number - The number of source lines of the purchase request that require the creation of an order to the supplier,
//    but cannot be added to the order, because they have other values of the Attributes that form the order header.
//
Function DescriptionOfOrderToBeCreated(PurchaseRequest, LineNumbers) Export
	
	DescriptionOfOrderToBeCreated = Undefined;
	MinimumSourceLineNumber = Undefined;
	NotProcessedRows_ = 0;
	For Each OrderDescription In DescriptionOfOrdersToBeCreated(PurchaseRequest, LineNumbers) Do
		
		NotProcessedRows_ = NotProcessedRows_ + OrderDescription.ProcessedSourceLines;
		
		If MinimumSourceLineNumber = Undefined
			Or MinimumSourceLineNumber > OrderDescription.MinimumSourceLineNumber Then
			MinimumSourceLineNumber = OrderDescription.MinimumSourceLineNumber;
			DescriptionOfOrderToBeCreated = OrderDescription;
		EndIf;
		
	EndDo;
	
	OrderData = Undefined;
	ProcessedSourceLines = 0;
	If DescriptionOfOrderToBeCreated <> Undefined Then
		ProcessedSourceLines = DescriptionOfOrderToBeCreated.ProcessedSourceLines;
		NotProcessedRows_ = NotProcessedRows_ - ProcessedSourceLines;
		OrderData = DescriptionOfOrderToBeCreated.OrderData;
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("OrderData", OrderData);
	ReturnValue.Insert("ProcessedSourceLines", ProcessedSourceLines);
	ReturnValue.Insert("NotProcessedSourceLines", NotProcessedRows_);
	
	Return ReturnValue;
	
EndFunction

// Generates the Query Text of the "Balance" for purchase requests that provide purchase plans
// Parameters:
//  NameOfPlanTable - String - The name of the temporary table of purchase plans that is used to search for purchase requests.
//  NameOfRemainderTable - String - The name of the temporary table with the "Balances" of purchase requests that will be generated when the returned Query Text is executed.
// Returns:
//  String - The text of the query that forms a temporary table with the name <Header tablename>.
Function QueryTextBalancesOfPurchaseRequestsAccordingToPlans(NameOfPlanTable, NameOfRemainderTable) Export
	
	PurposeOfUse = "BalancesOfPurchaseRequestsAccordingToPlans";
	QueriesTexts = New Array;
	
	// The search for applications is carried out with selection by "hard key" and date in order to limit the amount of data for calculation as much as possible.
	// In this case, the further calculation of the Balance is performed without taking into account the date, because there may be a situation when:
	// - In the month x-2 in the application y1 pieces
	// - In the month x-1 in the application y2 pieces
	// - In month x order to supplier y3 pieces.
	// In this case, if the plan for the month is x-1, then the Balance should be calculated as y1 + y2 - y3
	// Note: in the "hard key" section, the maximum date in the application section is used.
	// The table collapses, because there may be several rows in the plan with the same "hard key".
	QueryTextHardKeyForPurchasePlans = StrReplace(
	"SELECT DISTINCT
	|	RequestForPurchaseOfGoods.Ref         AS PurchaseRequest,
	|	RequestForPurchaseOfGoods.Products   AS Products,
	|	RequestForPurchaseOfGoods.Characteristic AS Characteristic,
	|	RequestForPurchaseOfGoods.Warehouse          AS Warehouse,
	|	RequestForPurchaseOfGoods.Purpose     AS Purpose,
	|	RequestForPurchaseOfGoods.Department  AS Department,
	|	RequestForPurchaseOfGoods.Partner        AS Partner,
	|	RequestForPurchaseOfGoods.Terms     AS Terms
	|INTO HardKeySelection
	|FROM
	|	Document.PurchaseRequest.Goods AS RequestForPurchaseOfGoods
	|		INNER JOIN NameOfPlanTable AS NameOfPlanTable
	|		ON (RequestForPurchaseOfGoods.RequestedDeliveryDate BETWEEN NameOfPlanTable.DateOfReceipt AND NameOfPlanTable.ReceiptPeriodEnd)
	|			AND RequestForPurchaseOfGoods.Products = NameOfPlanTable.Products
	|			AND RequestForPurchaseOfGoods.Characteristic = NameOfPlanTable.Characteristic
	|			AND (NOT &PlanningByAssignments
	|				OR NameOfPlanTable.Purpose = RequestForPurchaseOfGoods.Purpose)
	|			AND (NameOfPlanTable.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), RequestForPurchaseOfGoods.Warehouse))
	|			AND (NameOfPlanTable.PartnerPlan IN (VALUE(Catalog.Partners.EmptyRef), RequestForPurchaseOfGoods.Partner))
	|			AND (NameOfPlanTable.AgreementPlan = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|				OR NameOfPlanTable.Terms = RequestForPurchaseOfGoods.Terms)
	|		INNER JOIN Document.PurchaseRequest AS PurchaseRequest
	|		ON RequestForPurchaseOfGoods.Ref = PurchaseRequest.Ref
	|WHERE
	|	NameOfPlanTable.Department IN (VALUE(Catalog.BusinessStructure.EmptyRef), PurchaseRequest.Department)
	|	AND PurchaseRequest.Posted
	|	AND NOT RequestForPurchaseOfGoods.Canceled",
	"NameOfPlanTable",
	NameOfPlanTable);
	
	QueriesTexts.Add(QueryTextHardKeyForPurchasePlans);
	
	Filters = NewSelectionsOfPresentationsOfProcurementApplications();
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.ApplicationHasBeenCompleted, True);
	QueriesTexts.Add(QueryTextPurchaseRequestsReceiptInDetail(
		Filters,
		PurposeOfUse,
		"HardKeySelection")); // The main selections are superimposed on the input table.
		
	Filters = NewSelectionsOfPresentationsOfProcurementApplications();
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.PurchaseRequest,
		"SELECT T.PurchaseRequest FROM PurchaseRequestsReceiptInDetail AS T", // Work with applications found on the plans.
		True);
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.OrderPosted, True);
	
	QueriesTexts.Add(QueryTextOrdersOfApplications(Filters));
	QueriesTexts.Add(QueryTextPurchaseRequestsExpenseInDetail());
	QueriesTexts.Add(QueryTextPurchaseRequestsHardKeyBalances());
	QueriesTexts.Add(QueryTextPurchaseRequestsBalancesWithoutAgreements());
	QueriesTexts.Add(QueryTextPurchaseRequestsBalancesWithoutPartners());
	QueriesTexts.Add(QueryTextPurchaseRequestsBalancesAreSummarized(NameOfRemainderTable));
	
	QueryText = StrConcat(
		QueriesTexts,
		Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

// Generates the text that needs to be inserted into the resulting query of the data layout scheme as the table
// to be used, so that when calculating the Balance using the "Textquestion_ostatkizayavoknazakupoplanam" to save the correct dimensions, because
// the DCS optimizes the query and the link to the document does not fall into the groupings of intermediate TT.
// As a result, the maximum date is calculated not in the section of the application, but in a less detailed section.
// Adding the use of a field to disable this optimization.
// 
// Parameters:
//   NameOfRemainderTable - String - See QueryTextBalancesOfPurchaseRequestsAccordingToPlans.NameOfRemainderTable
//
// Returns:
//  String - Query text
Function TextOfUseOfIntermediateFieldsOfFormationOfBalance(NameOfRemainderTable) Export
	
	Return StrReplace(
	"(SELECT
	|SUM(0) AS UnusedField
	|FROM
	|	NameOfRemainderTable AS NameOfRemainderTable
	|WHERE
	|	FALSE
	|	AND NameOfRemainderTable.PurchaseRequest = NULL)",
	"NameOfRemainderTable",
	NameOfRemainderTable);
	
EndFunction

// Checks for the presence of unordered lines in the purchase request.
//
// Parameters:
//   Object - DocumentObject.PurchaseRequest, FormDataStructure - object of the purchase request
//
// Returns:
//   Boolean - indicates whether there are lines that are not ordered
Function ThereAreLinesThatAreNotOrdered(Object) Export
	
	BalancesLineByLine = Undefined;
	If ValueIsFilled(Object.Ref) And Object.Posted Then
		BalancesLineByLine = RestOfApplicationsLineByLine(Object).Get(Object.Ref);
	EndIf;
	
	Return ValueIsFilled(BalancesLineByLine);
	
EndFunction

// Cancels lines that were not ordered in the purchase order.
//
// Parameters:
//   Object - DocumentObject.PurchaseRequest, FormDataStructure - object of the purchase request
//
// Returns:
//   Structure:
//    * RowsWithQuantityChanges - Array of DocumentTabularSectionRow.PurchaseRequest.Goods - Rows of products in which the quantity has changed.
//    * CancelledRows - Array of DocumentTabularSectionRow.PurchaseRequest.Goods - Product lines with the "canceled" flag set
//    * ModifiedRows - Array of DocumentTabularSectionRow.PurchaseRequest.Goods - Contains "Rows with a change in number" and "Canceled rows".
Function UndoLinesThatAreNotOrdered(Object) Export
	
	BalancesLineByLine = Undefined;
	If ValueIsFilled(Object.Ref) Then
		BalancesLineByLine = RestOfApplicationsLineByLine(Object).Get(Object.Ref);
	EndIf;
	
	ReturnValue = New Structure;
	ReturnValue.Insert("RowsWithQuantityChanges", New Array);
	ReturnValue.Insert("CancelledRows", New Array);
	ReturnValue.Insert("ModifiedRows", New Array);
	
	For ReverseIndex = -Object.Goods.Count() + 1 To 0 Do
		
		RowOfGoods = Object.Goods[-ReverseIndex];
		
		If BalancesLineByLine = Undefined Then
			
			// The link was not created, which means there are no orders and the Balance is equal to the current value.
			Balance = RowOfGoods.Count;
			
		Else
			
			Balance = BalancesLineByLine.Get(RowOfGoods.LineNumber);
			If Balance = Undefined Then
				// Orders have been placed by line, no actions are required.
				Continue;
			EndIf;
			
		EndIf;
		
		If Balance = RowOfGoods.Count Then
			
			RowOfGoods.Canceled = True;
			
			ReturnValue.CancelledRows.Add(RowOfGoods);
			ReturnValue.ModifiedRows.Add(RowOfGoods);
			
		Else // Splitting the line into two:
			
			RowOfGoods.Count = RowOfGoods.Count - Balance;
			
			ReturnValue.RowsWithQuantityChanges.Add(RowOfGoods);
			ReturnValue.ModifiedRows.Add(RowOfGoods);
			
			CanceledLine = Object.Goods.Insert(RowOfGoods.LineNumber);
			FillPropertyValues(CanceledLine, RowOfGoods);
			CanceledLine.Canceled = True;
			CanceledLine.Count = Balance;
			
			ReturnValue.RowsWithQuantityChanges.Add(CanceledLine);
			ReturnValue.CancelledRows.Add(CanceledLine);
			ReturnValue.ModifiedRows.Add(CanceledLine);
			
		EndIf;
		
	EndDo;
	
	Actions = New Structure;
	Actions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	CommonClientServer.SupplementStructure(Actions, PurchaseRequestClientServer.ActionsForRecalculatingAmount(Object.PriceIncludesVAT), True);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReturnValue.RowsWithQuantityChanges,
		Actions,
		Object.Goods,
		BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues());
		
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region BDRLimits

// Returns a flag about checking the BDR limits in the purchase request.
// 
// Parameters:
//  PurchaseRequest - DocumentObject.PurchaseRequest, FormDataStructure - Purchase Request
// 
// Returns:
//  Boolean
Function MonitorBDRLimits(PurchaseRequest) Export
	
	Return UseBDRLimits()
		And PurchaseTargetsWithBDRLimitControl().Find(PurchaseRequest.PurchaseObjective) <> Undefined;
	
EndFunction

// Target purchases for which the BDR limits are monitored
// 
// Returns:
//  Array of EnumRef.PurchaseObjectives
Function PurchaseTargetsWithBDRLimitControl() Export

	ReturnValue = New Array;
	
	If UseBDRLimits() Then
		ReturnValue.Add(Enums.PurchaseObjectives.OwnNeeds);
	EndIf;
	
	Return ReturnValue;

EndFunction

// Returns the flag for using BDR limits in purchase requests.
// 
// Returns:
//  Boolean
Function UseBDRLimits() Export
	
	ReturnValue = False;
	ReturnValue = LimitsByBudgetingDataServer.UseIEBLimitsOnPurchases();
	Return ReturnValue;
	
EndFunction

// Text for error output when creating a list of documents.
// It is removed from processing 
// if there are documents with the required Attributes of the BDR limit control that are not filled in,
// so as not to display a lot of the same type of errors. 
// 
// Returns:
//  String - Error Text of the BDR Limits
Function ErrorTextOfBDRLimits() Export
	
	Return NStr("vi = 'Cần điền mục tin kiểm soát hạn mức và kết chuyển chứng từ';
				|ru = 'Необходимо заполнить реквизиты контроля лимитов и провести документы';
				|en = 'Fill in the limit control attributes and post the documents'; fa = 'Fill in the limit control attributes and post the documents';
				|it = 'Fill in the limit control attributes and post the documents';
				|pl = 'Fill in the limit control attributes and post the documents';
				|tr = 'Limit kontrol özniteliklerini doldurmalı ve belgeleri kaydetmelisiniz'");
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Filters

Function FilterApplicationsForWorkingOut(Performer)
	
	ListFilter = NewListSelection();
	ListFilter.Performer.Add(Performer);
	
	Return ListFilter;
	
EndFunction

// The structure of the fast selection of a dynamic list. 
// 
// Returns:
//  Structure - New List Selection:
// * Manager - ValueList of CatalogRef.Users 
// * Performer - ValueList of CatalogRef.Users 
// * EmployeeResponsible - ValueList of CatalogRef.Users
// * Status - ValueList of EnumRef.PurchaseRequestStatuses
// * Author - ValueList of CatalogRef.Users
Function NewListSelection() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Manager", New ValueList);
	ReturnValue.Insert("Performer", New ValueList);
	ReturnValue.Insert("EmployeeResponsible", New ValueList);
	ReturnValue.Insert("Status", New ValueList);
	ReturnValue.Insert("Author", New ValueList);
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region Posting

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.PurchaseRequest, DocumentRef.PurchaseRequest - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - See DocumentsPosting.AdditionalParametersDocumentDataForPosting
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;

	If TypeOf(Document) = Type("DocumentObject.PurchaseRequest") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	 
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.RequestedDeliveryDate AS DateOfReceipt,
		|	FALSE AS AvailableForConsumption,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.PurchaseRequest.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

#EndRegion

#Region Other

// Names of Attributes of the purchase conditions.
// 
// Returns:
//  Array of String - The Names Of The Details Of The Terms Of Purchase
Function NamesOfDetailsOfTermsOfPurchase() Export
	
	ReturnValue = New Array;
	
	ReturnValue.Add("Partner");
	ReturnValue.Add("Counterparty");
	ReturnValue.Add("Terms");
	ReturnValue.Add("Contract");
	ReturnValue.Add("Price");
	ReturnValue.Add("Sum");
	ReturnValue.Add("VATRate");
	ReturnValue.Add("VATAmount");
	
	Return ReturnValue; 
	
EndFunction

// Describes the business of operations of agreements available for selection in the purchase application.
// 
// Returns:
//  Array of EnumRef.BusinessTransactions - Available of operations.
Function AvailableAgreementOfOperations() Export
	
	ReturnValue = New Array;
	
	ReturnValue.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	ReturnValue.Add(Enums.BusinessTransactions.PurchaseByImport);
	ReturnValue.Add(Enums.BusinessTransactions.ImportFromEAEU);
	
	Return ReturnValue;
	
EndFunction

// There is no household in the document. of operation and, accordingly, the selection of Contracts for it.
// If the agreement is specified in the line, then the selection will be performed by household. of operations from the agreement.
// But if the agreement is not specified, then it is necessary to limit the choice to purchase Contracts. For this purpose, type selection is used.
// 
// Returns:
//  Array of EnumRef.ContractTypes
Function AvailableTypesOfContracts() Export
	
	ReturnValue = New Array;
	
	ReturnValue.Add(Enums.ContractTypes.WithVendor);
	ReturnValue.Add(Enums.ContractTypes.Import);
	ReturnValue.Add(Enums.ContractTypes.PurchaseEAEU);
	
	Return ReturnValue;
	
EndFunction

// Defines the names of the Attributes that are involved in debiting the limits for the document.
// 
// Returns:
//  Array of String - the names of the details.
//
Function NamesOfDetailsOfLimitingAnalyst() Export
	
	ReturnValue = New Array;
	
	ReturnValue.Add("Goods.BudgetFlowItem");
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region PurchaseOrders

// Generates a description of orders for the supplier to create based on the purchase request.
//
// Parameters:
//   PurchaseRequest - DocumentRef.PurchaseRequest - link to the Purchase Request document
//   LineNumbers - Array of Number - line numbers of the Products tabular part.
//
// Returns:
//   Array of Structure - array of structures describing orders to be created
Function DescriptionOfOrdersToBeCreated(PurchaseRequest, LineNumbers)
	
	#Region QueryText
	QueryText =
	"SELECT
	|	Balance.PurchaseRequest AS PurchaseRequest,
	|	Balance.LineNumber AS LineNumber,
	|	Balance.Count AS Count
	|INTO Balance
	|FROM
	|	&Balance AS Balance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Header.Ref                                     AS Basis,
	|	TabularSection.Products                      AS Products,
	|	TabularSection.Characteristic                    AS Characteristic,
	|	TabularSection.Purpose                        AS Purpose,
	|	Header.Organization                                AS Organization,
	|	TabularSection.Warehouse                             AS Warehouse,
	|	TabularSection.Department                     AS Department,
	|	Header.Currency                                     AS Currency,
	|	Header.PriceIncludesVAT                            AS PriceIncludesVAT,
	|	TabularSection.Partner                           AS Partner,
	|	TabularSection.Counterparty                        AS Counterparty,
	|	TabularSection.Terms                        AS Terms,
	|	TabularSection.Contract                           AS Contract,
	|	TabularSection.PartnerProducts              AS PartnerProducts,
	|	TabularSection.VendorPriceKind                 AS VendorPriceKind,
	|	TabularSection.Price                              AS Price,
	|	TabularSection.VATRate                         AS VATRate,
	|	TabularSection.LineNumber                       AS LineNumber,
	|	Balance.Count                               AS Count,
	|	TabularSection.Package                          AS Package,
	|	Header.Department                              AS CapDivision,
	|	Header.Warehouse                                      AS TheStockCaps,
	|	TabularSection.Sum                             AS Sum,
	|	TabularSection.VATAmount                          AS VATAmount,
	|	TabularSection.AmountIncludingVAT                         AS AmountIncludingVAT,
	|	TabularSection.NumberOfPackages                AS NumberOfPackages,
	|	Balance.Count <> TabularSection.Count  AS RecountIsRequired,
	|	
	|	// Contracts with the procedure for the settlement of ""Sub-agreements of contractors"" set the n.D. in the order, do not allow it to be changed and use it as a selection by appointment.
	|	// In other cases, N.D. is not used in the order, or it can be cleared to select any destination.
	|	CASE WHEN ISNULL(CounterpartyContracts.ARAPObjectSettings,
	|				VALUE(Enum.ARAPObjectSettings.EmptyRef)) = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts) THEN
	|		CounterpartyContracts.LineOfBusiness
	|	ELSE
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                                            AS LineOfBusiness,
	|	
	|	&UseAccountingOfOtherIncomeExpenses AND TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|                                                    AS ToExpenseAs
	|FROM
	|	Document.PurchaseRequest.Goods AS TabularSection
	|		LEFT JOIN Document.PurchaseRequest AS Header
	|		ON TabularSection.Ref = Header.Ref
	|		INNER JOIN Balance AS Balance
	|		ON TabularSection.Ref = Balance.PurchaseRequest
	|			AND TabularSection.LineNumber = Balance.LineNumber
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON TabularSection.Contract = CounterpartyContracts.Ref
	|WHERE
	|	TabularSection.Ref = &PurchaseRequest
	|	AND TabularSection.LineNumber IN(&LineNumbers)";
	#EndRegion

	HeaderFields = New Array;
	HeaderFields.Add("Basis");
	HeaderFields.Add("Organization");
	HeaderFields.Add("TheStockCaps");
	HeaderFields.Add("CapDivision");
	HeaderFields.Add("Currency");
	HeaderFields.Add("PriceIncludesVAT");
	HeaderFields.Add("Partner");
	HeaderFields.Add("Counterparty");
	HeaderFields.Add("Terms");
	HeaderFields.Add("Contract");
	HeaderFields.Add("LineOfBusiness");
	
	ExcludedTableColumns = New Array;
	ExcludedTableColumns.Add("LineNumber");
	ExcludedTableColumns.Add("RecountIsRequired");
	CommonClientServer.SupplementArray(ExcludedTableColumns, HeaderFields);
	
	Query = New Query;
	Query.Text = QueryText + "
	|ORDER BY
	|	" + StrConcat(HeaderFields, ",
	|	") + ",
	|	LineNumber"; // To get the minimum line included in the order.
	
	Query.SetParameter("Balance", TableOfApplicationBalancesLineByLine(PurchaseRequest));
	Query.SetParameter("PurchaseRequest", PurchaseRequest);
	Query.SetParameter("LineNumbers", LineNumbers);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	
	RawData = Query.Execute().Unload();
	ValuesInCache = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("RecountIsRequired", True);
	TheStructureOfTheSearch.Insert("PriceIncludesVAT", False);
	
	ValuesPriceIncludesVAT = New Array;
	ValuesPriceIncludesVAT.Add(False);
	ValuesPriceIncludesVAT.Add(True);
	
	For Each PriceIncludesVAT In ValuesPriceIncludesVAT Do
		
		TheStructureOfTheSearch.PriceIncludesVAT = PriceIncludesVAT;
		FoundRows = RawData.FindRows(TheStructureOfTheSearch);
		
		Actions = New Structure;
		Actions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
		CommonClientServer.SupplementStructure(Actions, PurchaseRequestClientServer.ActionsForRecalculatingAmount(PriceIncludesVAT), True);
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			FoundRows,
			Actions,
			RawData,
			ValuesInCache);
		
	EndDo;
	
	Renamings = New Structure;
	Renamings.Insert("TheStockCaps", "Warehouse");
	Renamings.Insert("CapDivision", "Department");
	
	DataFromOrders = SupplyServer.SplitTableByKeyValue(RawData, StrConcat(HeaderFields, ", "));
	DescriptionOfOrders = New Array;
	For Each KeyAndTable In DataFromOrders Do
		
		OrderData = New Structure;
		For Each KeyField In KeyAndTable.Key Do
			
			FieldName = KeyField.Key;
			FieldName = CommonClientServer.StructureProperty(Renamings, FieldName, FieldName);
			
			OrderData.Insert(FieldName, KeyField.Value);
			
		EndDo;
		
		Goods = KeyAndTable.Table;
		OrderData.Insert("Goods", Goods);
		
		OrderDescription = New Structure;
		OrderDescription.Insert("OrderData", OrderData);
		OrderDescription.Insert("MinimumSourceLineNumber", Goods[0].LineNumber);
		Goods.Columns.Delete("LineNumber");
		
		OrderDescription.Insert("ProcessedSourceLines", Goods.Count());
		
		DescriptionOfOrders.Add(OrderDescription);
		
	EndDo;
	
	Return DescriptionOfOrders;
	
EndFunction

// Description of the relationship between purchase requests and orders to suppliers.
// 
// Parameters:
// Filters - See NewSelectionsOfPresentationsOfProcurementApplications
//  PutInTempTable - Boolean - Determines the need to create a temporary table "ordersapplications"
// 
// Returns:
//  String - Query text
Function QueryTextOrdersOfApplications(Filters, PutInTempTable = True)
		
	QueryText = 
	"SELECT ALLOWED
	|	DocumentPurchaseOrder.Ref AS PurchaseOrder,
	|	DocumentPurchaseOrder.DocumentBasis AS PurchaseRequest
	|INTO OrdersOfApplications
	|FROM
	|	Document.PurchaseOrder AS DocumentPurchaseOrder
	|WHERE
	|	&AvailableSelections";
	
	If Not PutInTempTable Then
		QueryText = StrReplace(QueryText,
			"INTO OrdersOfApplications",
			"");
	EndIf;
	
	AvailableSelections = NewAvailableSelectionsOfPurchaseRequests();
	AvailableSelections.PurchaseRequest = "DocumentPurchaseOrder.DocumentBasis";
	AvailableSelections.PurchaseOrder = "DocumentPurchaseOrder.Ref";
	AvailableSelections.OrderWasCreatedBasedOnRequest = "DocumentPurchaseOrder.DocumentBasis REFS Document.PurchaseRequest";
	AvailableSelections.OrderPosted = "DocumentPurchaseOrder.Posted";
	QueryText = SetSelectionOfPurchaseRequestsInQueryText(QueryText, Filters, AvailableSelections);
	
	AvailableSelections = NewAvailableSelectionsOfPurchaseRequests();
	PurchaseRequestLocalization.CompleteQueryTextOfOrders(QueryText, AvailableSelections);
	QueryText = SetSelectionOfPurchaseRequestsInQueryText(QueryText, Filters, AvailableSelections);
	
	Return QueryText;
	
EndFunction

// Purchase demand generated by purchase requests.
// 
// Returns:
//  String - Query text
Function QueryTextPurchaseRequestsReceiptInDetail(Filters, PurposeOfUse = "", SourceDetails = Undefined)
	
	QueryText = 
	"SELECT
	|	RequestForPurchaseOfGoods.Ref               AS PurchaseRequest,
	|	RequestForPurchaseOfGoods.Products         AS Products,
	|	RequestForPurchaseOfGoods.Characteristic       AS Characteristic,
	|	RequestForPurchaseOfGoods.Purpose           AS Purpose,
	|	PurchaseRequestHeader.Organization           AS Organization,
	|	RequestForPurchaseOfGoods.Warehouse                AS Warehouse,
	|	RequestForPurchaseOfGoods.Department        AS Department,
	|	RequestForPurchaseOfGoods.Partner              AS Partner,
	|	RequestForPurchaseOfGoods.Terms           AS Terms,
	|	RequestForPurchaseOfGoods.Counterparty           AS Counterparty,
	|	RequestForPurchaseOfGoods.Contract              AS Contract,
	|	PurchaseRequestHeader.Currency                AS Currency,
	|	PurchaseRequestHeader.PriceIncludesVAT       AS PriceIncludesVAT,
	|	RequestForPurchaseOfGoods.PartnerProducts AS PartnerProducts,
	|	RequestForPurchaseOfGoods.VendorPriceKind    AS VendorPriceKind,
	|	RequestForPurchaseOfGoods.Price                 AS Price,
	|	RequestForPurchaseOfGoods.VATRate            AS VATRate,
	|	RequestForPurchaseOfGoods.LineNumber          AS LineNumber,
	|	RequestForPurchaseOfGoods.Count           AS Count,
	|	RequestForPurchaseOfGoods.Package             AS Package,
	|	PurchaseRequestHeader.Department         AS CapDivision,
	|	PurchaseRequestHeader.Warehouse                 AS TheStockCaps,
	|	CASE
	|		WHEN RequestForPurchaseOfGoods.RequestedDeliveryDate = DATETIME(1, 1, 1)
	|			THEN PurchaseRequestHeader.Date
	|		ELSE RequestForPurchaseOfGoods.RequestedDeliveryDate
	|	END                                  AS DateOfReceipt
	|INTO PurchaseRequestsReceiptInDetail
	|FROM
	|	Document.PurchaseRequest.Goods AS RequestForPurchaseOfGoods
	|		LEFT JOIN Document.PurchaseRequest AS PurchaseRequestHeader
	|		ON RequestForPurchaseOfGoods.Ref = PurchaseRequestHeader.Ref
	|			AND (&RelationshipToSelectionTable)
	|WHERE
	|	NOT RequestForPurchaseOfGoods.Canceled
	|	AND &AvailableSelections";
	
	AvailableSelections = NewAvailableSelectionsOfPurchaseRequests();
	AvailableSelections.PurchaseRequest = "RequestForPurchaseOfGoods.Ref";
	AvailableSelections.ApplicationHasBeenCompleted = "PurchaseRequestHeader.Posted";
	QueryText = SetSelectionOfPurchaseRequestsInQueryText(QueryText, Filters, AvailableSelections);
	
	TextOfLinkToSelectionTable = "";
	If PurposeOfUse = "BalancesOfPurchaseRequestsAccordingToPlans" Then
		
		SelectionTableName_ = SourceDetails; // The name is a temporary table with a hard key.
		TextOfLinkToSelectionTable = StrReplace(
		"INNER JOIN SelectionTableName_ AS SelectionTableName_
		|		ON RequestForPurchaseOfGoods.Products      = SelectionTableName_.Products
		|			AND RequestForPurchaseOfGoods.Characteristic = SelectionTableName_.Characteristic
		|			AND RequestForPurchaseOfGoods.Warehouse          = SelectionTableName_.Warehouse
		|			AND RequestForPurchaseOfGoods.Purpose     = SelectionTableName_.Purpose
		|			AND RequestForPurchaseOfGoods.Department  = SelectionTableName_.Department
		|			AND SelectionTableName_.Partner IN (RequestForPurchaseOfGoods.Partner,
		|			                                   VALUE(Catalog.Partners.EmptyRef)) 
		|			AND SelectionTableName_.Terms IN (RequestForPurchaseOfGoods.Terms,
		|			                                      VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef))",
		"SelectionTableName_",
		SelectionTableName_);
		
		// Empty in the plan -- > No selection
		// Filled in the plan --> 
		
	ElsIf PurposeOfUse = "ByObject" Then
		
		// We replace the receipt of data "by reference" with the transmission of data through parameters:
		QueryText = StrReplace(QueryText, "Document.PurchaseRequest.Goods", "&Goods");
		QueryText = StrReplace(QueryText, "PurchaseRequestHeader.", "&");
		
		// We remove unnecessary links, leaving only the table of goods:
		QuerySchema = New QuerySchema;
		QuerySchema.SetQueryText(QueryText);
		PackageRequest = RequestSchemes.RequestRequestPackage(QuerySchema);
		
		For Each SelectionOperator In PackageRequest.Operators Do
			
			For ReverseIndex = -SelectionOperator.Sources.Count() + 1 To 0 Do
				
				IndexOf = -ReverseIndex;
				SourceDetails = SelectionOperator.Sources.Get(IndexOf);
				
				If TypeOf(SourceDetails) <> Type("QuerySchemaSource")
					Or SourceDetails.Source.TableName  <> "&Goods" Then
					SelectionOperator.Sources.Delete(IndexOf);
				EndIf;
				
			EndDo;
			
		EndDo;
		
		QueryText = QuerySchema.GetQueryText();
		
	ElsIf PurposeOfUse <> "" Then
		
		ErrorText = NStr("vi = 'Giá trị không hợp lệ ""%1"" đối với tham số %2 trong phương thức %3';
						|ru = 'Недопустимое значение ""%1"" для параметра %2 в методе %3';
						|en = 'Incorrect %1 value for the %2 parameter in the %3 method'; fa = 'Incorrect %1 value for the %2 parameter in the %3 method';
						|it = 'Incorrect %1 value for the %2 parameter in the %3 method';
						|pl = 'Incorrect %1 value for the %2 parameter in the %3 method';
						|tr = '%3 metodundaki %2 parametresi için ""%1"" değeri geçersiz'");
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText,
			PurposeOfUse,
			"PurposeOfUse",
			"Document.PurchaseRequest.QueryTextPurchaseRequestsReceiptInDetail");
		
		Raise ErrorText;
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND (&RelationshipToSelectionTable)", TextOfLinkToSelectionTable);
	
	Return QueryText;
	
EndFunction

// Supplying the need for procurement (orders to suppliers, "closing" purchase requests).
// 
// Returns:
//  String - Query text
Function QueryTextPurchaseRequestsExpenseInDetail()
	
	QueryText = 
	"SELECT
	|	OrdersOfApplications.PurchaseRequest                                    AS PurchaseRequest,
	|	PurchaseOrders.Products                                  AS Products,
	|	PurchaseOrders.Characteristic                                AS Characteristic,
	|	ISNULL(PurchaseOrderGoods.Purpose,
	|		VALUE(Catalog.Assignments.EmptyRef))               AS Purpose,
	|	PurchaseOrderHeader.Organization                                AS Organization,
	|	PurchaseOrders.Warehouse                                         AS Warehouse,
	|	ISNULL(PurchaseOrderGoods.Department,
	|		VALUE(Catalog.BusinessStructure.EmptyRef))     AS Department,
	|	PurchaseOrderHeader.Partner                                    AS Partner,
	|	PurchaseOrderHeader.Terms                                 AS Terms,
	|	PurchaseOrderHeader.Counterparty                                 AS Counterparty,
	|	PurchaseOrderHeader.Contract                                    AS Contract,
	|	PurchaseOrderHeader.Currency                                     AS Currency,
	|	PurchaseOrderHeader.PriceIncludesVAT                            AS PriceIncludesVAT,
	|	ISNULL(PurchaseOrderGoods.PartnerProducts,
	|		VALUE(Catalog.ProductCrossReferences.EmptyRef)) AS PartnerProducts,
	|	ISNULL(PurchaseOrderGoods.VendorPriceKind,
	|		VALUE(Catalog.VendorPriceTypes.EmptyRef))       AS VendorPriceKind,
	|	ISNULL(PurchaseOrderGoods.Price, 0)                         AS Price,
	|	ISNULL(PurchaseOrderGoods.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))                AS VATRate,
	|	CASE
	|		WHEN PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN PurchaseOrders.ToRegister
	|		ELSE 0
	|	END                                                           AS Received,
	|	CASE
	|		WHEN PurchaseOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN PurchaseOrders.Ordered
	|		ELSE 0
	|	END                                                           AS Ordered,
	|	RECORDAUTONUMBER()                                               AS RecNo
	|INTO PurchaseRequestsExpenseInDetail
	|FROM
	|	AccumulationRegister.PurchaseOrders AS PurchaseOrders
	|		INNER JOIN OrdersOfApplications AS OrdersOfApplications
	|		ON PurchaseOrders.PurchaseOrder = OrdersOfApplications.PurchaseOrder
	|		LEFT JOIN Document.PurchaseOrder.Goods AS PurchaseOrderGoods
	|		ON PurchaseOrders.PurchaseOrder   = PurchaseOrderGoods.Ref
	|			AND PurchaseOrders.Products   = PurchaseOrderGoods.Products
	|			AND PurchaseOrders.Characteristic = PurchaseOrderGoods.Characteristic
	|			AND PurchaseOrders.RowCode      = PurchaseOrderGoods.RowCode
	|			AND PurchaseOrders.Warehouse          = PurchaseOrderGoods.Warehouse
	|		LEFT JOIN Document.PurchaseOrder AS PurchaseOrderHeader
	|		ON PurchaseOrders.PurchaseOrder = PurchaseOrderHeader.Ref";
	
	Return QueryText;
	
EndFunction

// Rules for the distribution of orders for purchase requests.
// 
// Returns:
//  String - Query text
Function QueryTextOfPurchaseRequestLineBalanceCalculationData()
	
	QueryText = 
	"SELECT
	|	PurchaseRequestsReceiptInDetail.PurchaseRequest AS PurchaseRequest,
	|	PurchaseRequestsReceiptInDetail.LineNumber AS LineNumber,
	|	PurchaseRequestsExpenseInDetail.RecNo AS ExpenseRecordNumber,
	|	PurchaseRequestsReceiptInDetail.Partner <> VALUE(Catalog.Partners.EmptyRef) AS PartnerIsFull,
	|	PurchaseRequestsReceiptInDetail.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|		AND PurchaseRequestsReceiptInDetail.Terms <> VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS AgreementIsFilled,
	|	PurchaseRequestsReceiptInDetail.Counterparty = PurchaseRequestsExpenseInDetail.Counterparty
	|		AND PurchaseRequestsReceiptInDetail.Contract = PurchaseRequestsExpenseInDetail.Contract
	|		AND PurchaseRequestsReceiptInDetail.Currency = PurchaseRequestsExpenseInDetail.Currency
	|		AND PurchaseRequestsReceiptInDetail.PriceIncludesVAT = PurchaseRequestsExpenseInDetail.PriceIncludesVAT
	|		AND PurchaseRequestsReceiptInDetail.PartnerProducts = PurchaseRequestsExpenseInDetail.PartnerProducts
	|		AND PurchaseRequestsReceiptInDetail.VendorPriceKind = PurchaseRequestsExpenseInDetail.VendorPriceKind
	|		AND PurchaseRequestsReceiptInDetail.Price = PurchaseRequestsExpenseInDetail.Price
	|		AND PurchaseRequestsReceiptInDetail.VATRate = PurchaseRequestsExpenseInDetail.VATRate AS SoftKeyMatches
	|FROM
	|	PurchaseRequestsReceiptInDetail AS PurchaseRequestsReceiptInDetail
	|		INNER JOIN PurchaseRequestsExpenseInDetail AS PurchaseRequestsExpenseInDetail
	|		ON PurchaseRequestsReceiptInDetail.PurchaseRequest = PurchaseRequestsExpenseInDetail.PurchaseRequest
	|			AND PurchaseRequestsReceiptInDetail.Products = PurchaseRequestsExpenseInDetail.Products
	|			AND PurchaseRequestsReceiptInDetail.Characteristic = PurchaseRequestsExpenseInDetail.Characteristic
	|			AND PurchaseRequestsReceiptInDetail.Purpose = PurchaseRequestsExpenseInDetail.Purpose
	|			AND PurchaseRequestsReceiptInDetail.Organization = PurchaseRequestsExpenseInDetail.Organization
	|			AND PurchaseRequestsReceiptInDetail.Warehouse = PurchaseRequestsExpenseInDetail.Warehouse
	|			AND PurchaseRequestsReceiptInDetail.Department = PurchaseRequestsExpenseInDetail.Department
	|			AND (PurchaseRequestsReceiptInDetail.Partner = PurchaseRequestsExpenseInDetail.Partner
	|				OR PurchaseRequestsReceiptInDetail.Partner = VALUE(Catalog.Partners.EmptyRef))
	|			AND (PurchaseRequestsReceiptInDetail.Terms = PurchaseRequestsExpenseInDetail.Terms
	|				OR PurchaseRequestsReceiptInDetail.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef))
	|
	|ORDER BY
	|	PurchaseRequest,
	|	PartnerIsFull DESC,
	|	AgreementIsFilled DESC,
	|	SoftKeyMatches DESC,
	|	PurchaseRequestsReceiptInDetail.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseRequestsReceiptInDetail.PurchaseRequest AS PurchaseRequest,
	|	PurchaseRequestsReceiptInDetail.LineNumber AS LineNumber,
	|	PurchaseRequestsReceiptInDetail.Count AS Count
	|FROM
	|	PurchaseRequestsReceiptInDetail AS PurchaseRequestsReceiptInDetail
	|
	|ORDER BY
	|	PurchaseRequest
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseRequestsExpenseInDetail.RecNo AS RecNo,
	|	PurchaseRequestsExpenseInDetail.PurchaseRequest AS PurchaseRequest,
	|	PurchaseRequestsExpenseInDetail.Ordered AS Count
	|FROM
	|	PurchaseRequestsExpenseInDetail AS PurchaseRequestsExpenseInDetail
	|
	|ORDER BY
	|	RecNo";
	
	Return QueryText;
	
EndFunction

// Generates a table of Balances of applications line by line.
//
// Parameters:
//   PurchaseRequest - DocumentRef.PurchaseRequest - Purchase Request
//
// Returns:
//   ValueTable - ValueTable:
//     * PurchaseRequest - DocumentRef.PurchaseRequest - For which the Balance was received.
//     * LineNumber - Number - Line number of the purchase request.
//     * Count - Number - the Balance of the line.
Function TableOfApplicationBalancesLineByLine(PurchaseRequest)
	
	ReturnValue = New ValueTable;
	ReturnValue.Columns.Add("PurchaseRequest", New TypeDescription("DocumentRef.PurchaseRequest"));
	ReturnValue.Columns.Add("LineNumber", Common.TypeDescriptionNumber(15, 0));
	ReturnValue.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
	
	For Each Application_Description In RestOfApplicationsLineByLine(PurchaseRequest) Do
		
		For Each KeyAndValue In Application_Description.Value Do
			
			TableRow = ReturnValue.Add();
			TableRow.PurchaseRequest = Application_Description.Key;
			TableRow.LineNumber = KeyAndValue.Key;
			TableRow.Count = KeyAndValue.Value;
			
		EndDo;
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Returns the Balance of requests line by line.
//
// Parameters:
//   PurchaseRequest - Array of DocumentRef.PurchaseRequest, DocumentObject.PurchaseRequest, FormDataStructure - Applications for calculating the Balance
//
// Returns:
//   Map of KeyAndValue:
//      * Key - DocumentRef.PurchaseRequest
//      * Value - Map of KeyAndValue:
//          ** Key - Number - Line number of the purchase request.
//          ** Value - Number - Quantity-the Balance of the line.
Function RestOfApplicationsLineByLine(PurchaseRequest)
	
	TheseAreRemnantsOfObject = TypeOf(PurchaseRequest) = Type("DocumentObject.PurchaseRequest")
		Or TypeOf(PurchaseRequest) = Type("FormDataStructure");
		
	Filters = NewSelectionsOfPresentationsOfProcurementApplications();
	EstablishSelectionOfPresentationsOfProcurementApplications(Filters.OrderPosted, True);
	
	QueriesTexts = New Array;
	If TheseAreRemnantsOfObject Then
		EstablishSelectionOfPresentationsOfProcurementApplications(Filters.PurchaseRequest, PurchaseRequest.Ref);
		QueriesTexts.Add(QueryTextPurchaseRequestsReceiptInDetail(Filters, "ByObject"));
	Else
		EstablishSelectionOfPresentationsOfProcurementApplications(Filters.PurchaseRequest, PurchaseRequest);
		QueriesTexts.Add(QueryTextPurchaseRequestsReceiptInDetail(Filters));
	EndIf;
	
	QueriesTexts.Add(QueryTextOrdersOfApplications(Filters));
	QueriesTexts.Add(QueryTextPurchaseRequestsExpenseInDetail());
	QueriesTexts.Add(QueryTextOfPurchaseRequestLineBalanceCalculationData());
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Query = New Query(QueryText);
	SetSelectionOfPurchaseRequestsInRequestParameters(Query, Filters);
	
	If TheseAreRemnantsOfObject Then
		
		Goods = PurchaseRequest.Goods.Unload();
		Goods.Columns.Add("Ref", New TypeDescription("DocumentRef.PurchaseRequest"));
		Goods.FillValues(PurchaseRequest.Ref, "Ref");
		Query.SetParameter("Goods", Goods);
		
		// All header fields have been replaced with parameters of the same name. Let's set their values:
		TheParametersOfThe = New Structure(
			StrConcat(
				Common.UnloadColumn(
					Query.FindParameters(),
					"Name"),
				", "));
		FillPropertyValues(TheParametersOfThe, PurchaseRequest);
		CommonClientServer.SupplementStructure(Query.Parameters, TheParametersOfThe, False);
		
	EndIf;
	
	PackageResult = Query.ExecuteBatch();
	Selection = PackageResult[PackageResult.Count() - 3].Select();
	ParishSelection = PackageResult[PackageResult.Count() - 2].Select();
	ExpenseData = PackageResult[PackageResult.Count() - 1].Unload();
	
	CurrentRequest = EmptyRef();
	DescriptionOfApplications = New Map;
	Application_Description = Undefined;
	While ParishSelection.Next() Do
		
		If CurrentRequest <> ParishSelection.PurchaseRequest Then
			
			CurrentRequest = ParishSelection.PurchaseRequest;
			
			Application_Description = New Map;
			DescriptionOfApplications.Insert(CurrentRequest, Application_Description);
			
		EndIf;
		
		Application_Description.Insert(ParishSelection.LineNumber, ParishSelection.Count);
		
	EndDo;
	
	IndexShiftFromRecordNumber = ?(ValueIsFilled(ExpenseData),
		ExpenseData[0].RecNo,
		0);
		
	CurrentRequest = EmptyRef();
	While Selection.Next() Do
		
		If CurrentRequest <> Selection.PurchaseRequest Then 
			Application_Description = DescriptionOfApplications[Selection.PurchaseRequest];
		EndIf;
		
		Balance = Application_Description[Selection.LineNumber];
		If Balance = Undefined Then
			Continue;
		EndIf;
		
		ExpenseLine = ExpenseData.Get(Selection.ExpenseRecordNumber - IndexShiftFromRecordNumber);
		If ExpenseLine.Count = 0 Then
			Continue;
		EndIf;
		
		ToWriteOff = Min(Balance, ExpenseLine.Count);
		ExpenseLine.Count = ExpenseLine.Count - ToWriteOff;
		Balance = Balance - ToWriteOff;
		
		If Balance = 0 Then
			Application_Description.Delete(Selection.LineNumber);
		Else
			Application_Description[Selection.LineNumber] = Balance;
		EndIf;
		
	EndDo;
	
	Return DescriptionOfApplications;
	
EndFunction

// Convolution of receipts and expenses.
Function QueryTextPurchaseRequestsHardKeyBalances()
	
	QueryText = 
	"SELECT
	|	HardKeyBalances.PurchaseRequest              AS PurchaseRequest,
	|	HardKeyBalances.Products                 AS Products,
	|	HardKeyBalances.Characteristic               AS Characteristic,
	|	HardKeyBalances.Purpose                   AS Purpose,
	|	HardKeyBalances.Organization                  AS Organization,
	|	HardKeyBalances.Warehouse                        AS Warehouse,
	|	HardKeyBalances.Department                AS Department,
	|	HardKeyBalances.Partner                      AS Partner,
	|	HardKeyBalances.Terms                   AS Terms,
	|	SUM(HardKeyBalances.InApplication)               AS InApplication,
	|	SUM(HardKeyBalances.Ordered)              AS Ordered,
	|	SUM(HardKeyBalances.Count)            AS Count,
	|	SUM(HardKeyBalances.Received)             AS Received,
	|	MAX(HardKeyBalances.PackagingUnitsInApplication)    AS PackagingUnitsInApplication,
	|	MAX(HardKeyBalances.DateOfReceipt)    AS DateOfReceipt,
	|	MAX(HardKeyBalances.CapDivision) AS CapDivision
	|INTO PurchaseRequestsHardKeyBalances
	|FROM
	|	(SELECT
	|		PurchaseRequestsReceiptInDetail.PurchaseRequest    AS PurchaseRequest,
	|		PurchaseRequestsReceiptInDetail.Products       AS Products,
	|		PurchaseRequestsReceiptInDetail.Characteristic     AS Characteristic,
	|		PurchaseRequestsReceiptInDetail.Purpose         AS Purpose,
	|		PurchaseRequestsReceiptInDetail.Organization        AS Organization,
	|		PurchaseRequestsReceiptInDetail.Warehouse              AS Warehouse,
	|		PurchaseRequestsReceiptInDetail.Department      AS Department,
	|		PurchaseRequestsReceiptInDetail.Partner            AS Partner,
	|		PurchaseRequestsReceiptInDetail.Terms         AS Terms,
	|		PurchaseRequestsReceiptInDetail.Count         AS InApplication,
	|		0                                                AS Ordered,
	|		PurchaseRequestsReceiptInDetail.Count         AS Count,
	|		0                                                AS Received,
	|		PurchaseRequestsReceiptInDetail.Package           AS PackagingUnitsInApplication,
	|		PurchaseRequestsReceiptInDetail.DateOfReceipt    AS DateOfReceipt,
	|		PurchaseRequestsReceiptInDetail.CapDivision AS CapDivision
	|	FROM
	|		PurchaseRequestsReceiptInDetail AS PurchaseRequestsReceiptInDetail
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		PurchaseRequestsExpenseInDetail.PurchaseRequest              AS PurchaseRequest,
	|		PurchaseRequestsExpenseInDetail.Products                 AS Products,
	|		PurchaseRequestsExpenseInDetail.Characteristic               AS Characteristic,
	|		PurchaseRequestsExpenseInDetail.Purpose                   AS Purpose,
	|		PurchaseRequestsExpenseInDetail.Organization                  AS Organization,
	|		PurchaseRequestsExpenseInDetail.Warehouse                        AS Warehouse,
	|		PurchaseRequestsExpenseInDetail.Department                AS Department,
	|		PurchaseRequestsExpenseInDetail.Partner                      AS Partner,
	|		PurchaseRequestsExpenseInDetail.Terms                   AS Terms,
	|		0                                                          AS InApplication,
	|		PurchaseRequestsExpenseInDetail.Ordered                     AS Ordered,
	|		-PurchaseRequestsExpenseInDetail.Ordered                    AS Count,
	|		PurchaseRequestsExpenseInDetail.Received                    AS Received,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PackagingUnitsInApplication,
	|		DATETIME(1, 1, 1)                                         AS DateOfReceipt,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)     AS CapDivision
	|	FROM
	|		PurchaseRequestsExpenseInDetail AS PurchaseRequestsExpenseInDetail) AS HardKeyBalances
	|
	|GROUP BY
	|	HardKeyBalances.PurchaseRequest,
	|	HardKeyBalances.Products,
	|	HardKeyBalances.Characteristic,
	|	HardKeyBalances.Purpose,
	|	HardKeyBalances.Organization,
	|	HardKeyBalances.Warehouse,
	|	HardKeyBalances.Department,
	|	HardKeyBalances.Partner,
	|	HardKeyBalances.Terms";
	
	Return QueryText;
	
EndFunction

// Write-off of a re-delivery from lines with empty agreements.
Function QueryTextPurchaseRequestsBalancesWithoutAgreements()
	
	QueryText = 
	"SELECT
	|	BalancesWithoutAgreements.PurchaseRequest              AS PurchaseRequest,
	|	BalancesWithoutAgreements.Products                 AS Products,
	|	BalancesWithoutAgreements.Characteristic               AS Characteristic,
	|	BalancesWithoutAgreements.Purpose                   AS Purpose,
	|	BalancesWithoutAgreements.Organization                  AS Organization,
	|	BalancesWithoutAgreements.Warehouse                        AS Warehouse,
	|	BalancesWithoutAgreements.Department                AS Department,
	|	BalancesWithoutAgreements.Partner                      AS Partner,
	|	BalancesWithoutAgreements.Terms                   AS Terms,
	|	SUM(BalancesWithoutAgreements.InApplication)               AS InApplication,
	|	SUM(BalancesWithoutAgreements.Ordered)              AS Ordered,
	|	SUM(BalancesWithoutAgreements.Count)            AS Count,
	|	SUM(BalancesWithoutAgreements.Received)             AS Received,
	|	MAX(BalancesWithoutAgreements.PackagingUnitsInApplication)    AS PackagingUnitsInApplication,
	|	MAX(BalancesWithoutAgreements.DateOfReceipt)    AS DateOfReceipt,
	|	MAX(BalancesWithoutAgreements.CapDivision) AS CapDivision
	|INTO PurchaseRequestsBalancesWithoutAgreements
	|FROM
	|	(SELECT
	|		BalancesWithoutAgreements.PurchaseRequest    AS PurchaseRequest,
	|		BalancesWithoutAgreements.Products       AS Products,
	|		BalancesWithoutAgreements.Characteristic     AS Characteristic,
	|		BalancesWithoutAgreements.Purpose         AS Purpose,
	|		BalancesWithoutAgreements.Organization        AS Organization,
	|		BalancesWithoutAgreements.Warehouse              AS Warehouse,
	|		BalancesWithoutAgreements.Department      AS Department,
	|		BalancesWithoutAgreements.Partner            AS Partner,
	|		BalancesWithoutAgreements.Terms         AS Terms,
	|		BalancesWithoutAgreements.InApplication            AS InApplication,
	|		BalancesWithoutAgreements.Ordered           AS Ordered,
	|		BalancesWithoutAgreements.Count         AS Count,
	|		BalancesWithoutAgreements.Received          AS Received,
	|		BalancesWithoutAgreements.PackagingUnitsInApplication    AS PackagingUnitsInApplication,
	|		BalancesWithoutAgreements.DateOfReceipt    AS DateOfReceipt,
	|		BalancesWithoutAgreements.CapDivision AS CapDivision
	|	FROM
	|		PurchaseRequestsHardKeyBalances AS BalancesWithoutAgreements
	|	WHERE
	|		BalancesWithoutAgreements.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|		AND BalancesWithoutAgreements.Count > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NegativeBalancesExcludingAgreements.PurchaseRequest     AS PurchaseRequest,
	|		NegativeBalancesExcludingAgreements.Products        AS Products,
	|		NegativeBalancesExcludingAgreements.Characteristic      AS Characteristic,
	|		NegativeBalancesExcludingAgreements.Purpose          AS Purpose,
	|		NegativeBalancesExcludingAgreements.Organization         AS Organization,
	|		NegativeBalancesExcludingAgreements.Warehouse               AS Warehouse,
	|		NegativeBalancesExcludingAgreements.Department       AS Department,
	|		NegativeBalancesExcludingAgreements.Partner             AS Partner,
	|		VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)  AS Terms,
	|		NegativeBalancesExcludingAgreements.InApplication             AS InApplication,
	|		NegativeBalancesExcludingAgreements.Ordered            AS Ordered,
	|		NegativeBalancesExcludingAgreements.Count          AS Count,
	|		NegativeBalancesExcludingAgreements.Received           AS Received,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PackagingUnitsInApplication,
	|		DATETIME(1, 1, 1)                                         AS DateOfReceipt,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)     AS CapDivision
	|	FROM
	|		PurchaseRequestsHardKeyBalances AS NegativeBalancesExcludingAgreements
	|	WHERE
	|		NegativeBalancesExcludingAgreements.Count < 0) AS BalancesWithoutAgreements
	|
	|GROUP BY
	|	BalancesWithoutAgreements.Department,
	|	BalancesWithoutAgreements.PurchaseRequest,
	|	BalancesWithoutAgreements.Partner,
	|	BalancesWithoutAgreements.Organization,
	|	BalancesWithoutAgreements.Products,
	|	BalancesWithoutAgreements.Purpose,
	|	BalancesWithoutAgreements.Terms,
	|	BalancesWithoutAgreements.Warehouse,
	|	BalancesWithoutAgreements.Characteristic";
	
	Return QueryText;
	
EndFunction

// Write-off of a re-delivery from lines with empty partners.
Function QueryTextPurchaseRequestsBalancesWithoutPartners()
	
	QueryText = 
	"SELECT
	|	BalancesWithoutPartners.PurchaseRequest              AS PurchaseRequest,
	|	BalancesWithoutPartners.Products                 AS Products,
	|	BalancesWithoutPartners.Characteristic               AS Characteristic,
	|	BalancesWithoutPartners.Purpose                   AS Purpose,
	|	BalancesWithoutPartners.Organization                  AS Organization,
	|	BalancesWithoutPartners.Warehouse                        AS Warehouse,
	|	BalancesWithoutPartners.Department                AS Department,
	|	BalancesWithoutPartners.Partner                      AS Partner,
	|	BalancesWithoutPartners.Terms                   AS Terms,
	|	SUM(BalancesWithoutPartners.InApplication)               AS InApplication,
	|	SUM(BalancesWithoutPartners.Ordered)              AS Ordered,
	|	SUM(BalancesWithoutPartners.Count)            AS Count,
	|	SUM(BalancesWithoutPartners.Received)             AS Received,
	|	MAX(BalancesWithoutPartners.PackagingUnitsInApplication)    AS PackagingUnitsInApplication,
	|	MAX(BalancesWithoutPartners.DateOfReceipt)    AS DateOfReceipt,
	|	MAX(BalancesWithoutPartners.CapDivision) AS CapDivision
	|INTO PurchaseRequestsBalancesWithoutPartners
	|FROM
	|	(SELECT
	|		BalancesWithoutPartners.PurchaseRequest    AS PurchaseRequest,
	|		BalancesWithoutPartners.Products       AS Products,
	|		BalancesWithoutPartners.Characteristic     AS Characteristic,
	|		BalancesWithoutPartners.Purpose         AS Purpose,
	|		BalancesWithoutPartners.Organization        AS Organization,
	|		BalancesWithoutPartners.Warehouse              AS Warehouse,
	|		BalancesWithoutPartners.Department      AS Department,
	|		BalancesWithoutPartners.Partner            AS Partner,
	|		BalancesWithoutPartners.Terms         AS Terms,
	|		BalancesWithoutPartners.InApplication            AS InApplication,
	|		BalancesWithoutPartners.Ordered           AS Ordered,
	|		BalancesWithoutPartners.Count         AS Count,
	|		BalancesWithoutPartners.Received          AS Received,
	|		BalancesWithoutPartners.PackagingUnitsInApplication    AS PackagingUnitsInApplication,
	|		BalancesWithoutPartners.DateOfReceipt    AS DateOfReceipt,
	|		BalancesWithoutPartners.CapDivision AS CapDivision
	|	FROM
	|		PurchaseRequestsBalancesWithoutAgreements AS BalancesWithoutPartners
	|	WHERE
	|		BalancesWithoutPartners.Partner = VALUE(Catalog.Partners.EmptyRef)
	|		AND BalancesWithoutPartners.Terms = VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|		AND BalancesWithoutPartners.Count > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		NegativeBalancesExcludingPartners.PurchaseRequest      AS PurchaseRequest,
	|		NegativeBalancesExcludingPartners.Products         AS Products,
	|		NegativeBalancesExcludingPartners.Characteristic       AS Characteristic,
	|		NegativeBalancesExcludingPartners.Purpose           AS Purpose,
	|		NegativeBalancesExcludingPartners.Organization          AS Organization,
	|		NegativeBalancesExcludingPartners.Warehouse                AS Warehouse,
	|		NegativeBalancesExcludingPartners.Department        AS Department,
	|		VALUE(Catalog.Partners.EmptyRef)                 AS Partner,
	|		VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)  AS Terms,
	|		NegativeBalancesExcludingPartners.InApplication              AS InApplication,
	|		NegativeBalancesExcludingPartners.Ordered             AS Ordered,
	|		NegativeBalancesExcludingPartners.Count           AS Count,
	|		NegativeBalancesExcludingPartners.Received            AS Received,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PackagingUnitsInApplication,
	|		DATETIME(1, 1, 1)                                         AS DateOfReceipt,
	|		VALUE(Catalog.BusinessStructure.EmptyRef)     AS CapDivision
	|	FROM
	|		PurchaseRequestsBalancesWithoutAgreements AS NegativeBalancesExcludingPartners
	|	WHERE
	|		NegativeBalancesExcludingPartners.Count < 0) AS BalancesWithoutPartners
	|
	|GROUP BY
	|	BalancesWithoutPartners.PurchaseRequest,
	|	BalancesWithoutPartners.Products,
	|	BalancesWithoutPartners.Characteristic,
	|	BalancesWithoutPartners.Purpose,
	|	BalancesWithoutPartners.Organization,
	|	BalancesWithoutPartners.Warehouse,
	|	BalancesWithoutPartners.Department,
	|	BalancesWithoutPartners.Partner,
	|	BalancesWithoutPartners.Terms";
	
	Return QueryText;
	
EndFunction

// Combining the original receipt-expense convolution with clarifications for debiting over-delivery from empty agreements and partners.
Function QueryTextPurchaseRequestsBalancesAreSummarized(TempTableName = "PurchaseRequestsBalancesAreSummarized", ReceiptIsUsed = False)
	
	QueryText = 
	"SELECT
	|	HardKeyBalances.PurchaseRequest    AS PurchaseRequest,
	|	HardKeyBalances.Products       AS Products,
	|	HardKeyBalances.Characteristic     AS Characteristic,
	|	HardKeyBalances.Purpose         AS Purpose,
	|	HardKeyBalances.Organization        AS Organization,
	|	HardKeyBalances.Warehouse              AS Warehouse,
	|	HardKeyBalances.Department      AS Department,
	|	HardKeyBalances.Partner            AS Partner,
	|	HardKeyBalances.Terms         AS Terms,
	|	HardKeyBalances.InApplication            AS InApplication,
	|	HardKeyBalances.Ordered           AS Ordered,
	|	HardKeyBalances.Count         AS Count,
	|	HardKeyBalances.Received          AS Received,
	|	HardKeyBalances.PackagingUnitsInApplication    AS PackagingUnitsInApplication,
	|	HardKeyBalances.DateOfReceipt    AS DateOfReceipt,
	|	HardKeyBalances.CapDivision AS CapDivision
	|INTO PurchaseRequestsBalancesAreSummarized
	|FROM
	|	PurchaseRequestsHardKeyBalances AS HardKeyBalances
	|WHERE
	|	HardKeyBalances.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|	AND HardKeyBalances.Terms <> VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|	AND (HardKeyBalances.Count > 0
	|		OR &ReceiptIsUsed AND HardKeyBalances.InApplication - HardKeyBalances.Received > 0)
	|
	|UNION ALL
	|
	|SELECT
	|	BalancesWithoutAgreements.PurchaseRequest    AS PurchaseRequest,
	|	BalancesWithoutAgreements.Products       AS Products,
	|	BalancesWithoutAgreements.Characteristic     AS Characteristic,
	|	BalancesWithoutAgreements.Purpose         AS Purpose,
	|	BalancesWithoutAgreements.Organization        AS Organization,
	|	BalancesWithoutAgreements.Warehouse              AS Warehouse,
	|	BalancesWithoutAgreements.Department      AS Department,
	|	BalancesWithoutAgreements.Partner            AS Partner,
	|	BalancesWithoutAgreements.Terms         AS Terms,
	|	BalancesWithoutAgreements.InApplication            AS InApplication,
	|	BalancesWithoutAgreements.Ordered           AS Ordered,
	|	BalancesWithoutAgreements.Count         AS Count,
	|	BalancesWithoutAgreements.Received          AS Received,
	|	BalancesWithoutAgreements.PackagingUnitsInApplication    AS PackagingUnitsInApplication,
	|	BalancesWithoutAgreements.DateOfReceipt    AS DateOfReceipt,
	|	BalancesWithoutAgreements.CapDivision AS CapDivision
	|FROM
	|	PurchaseRequestsBalancesWithoutAgreements AS BalancesWithoutAgreements
	|WHERE
	|	BalancesWithoutAgreements.Partner <> VALUE(Catalog.Partners.EmptyRef)
	|	AND (BalancesWithoutAgreements.Count > 0
	|		OR &ReceiptIsUsed AND BalancesWithoutAgreements.InApplication - BalancesWithoutAgreements.Received > 0)
	|
	|UNION ALL
	|
	|SELECT
	|	BalancesWithoutPartners.PurchaseRequest    AS PurchaseRequest,
	|	BalancesWithoutPartners.Products       AS Products,
	|	BalancesWithoutPartners.Characteristic     AS Characteristic,
	|	BalancesWithoutPartners.Purpose         AS Purpose,
	|	BalancesWithoutPartners.Organization        AS Organization,
	|	BalancesWithoutPartners.Warehouse              AS Warehouse,
	|	BalancesWithoutPartners.Department      AS Department,
	|	BalancesWithoutPartners.Partner            AS Partner,
	|	BalancesWithoutPartners.Terms         AS Terms,
	|	BalancesWithoutPartners.InApplication            AS InApplication,
	|	BalancesWithoutPartners.Ordered           AS Ordered,
	|	BalancesWithoutPartners.Count         AS Count,
	|	BalancesWithoutPartners.Received          AS Received,
	|	BalancesWithoutPartners.PackagingUnitsInApplication    AS PackagingUnitsInApplication,
	|	BalancesWithoutPartners.DateOfReceipt    AS DateOfReceipt,
	|	BalancesWithoutPartners.CapDivision AS CapDivision
	|FROM
	|	PurchaseRequestsBalancesWithoutPartners AS BalancesWithoutPartners
	|WHERE
	|	BalancesWithoutPartners.Count > 0
	|	AND (BalancesWithoutPartners.Count > 0
	|		OR &ReceiptIsUsed AND BalancesWithoutPartners.InApplication - BalancesWithoutPartners.Received > 0)";
	
	UsingReceiptsInRequest = Format(ReceiptIsUsed, "BF=FALSE; BT=TRUE");
	QueryText = StrReplace(QueryText, "&ReceiptIsUsed", UsingReceiptsInRequest);
	
	QueryText = StrReplace(
		QueryText, 
		"INTO PurchaseRequestsBalancesAreSummarized",
		"INTO " + TempTableName);
		
	Return QueryText;
	
EndFunction

// Data for displaying the "To Order" table in the "Document Execution Statuses" report
// 
// Returns:
//  String - Query text
Function QueryTextTableToOrder()
	
	QueryText = 
	"SELECT
	|	PurchaseRequestsBalancesAreSummarized.PurchaseRequest               AS Document,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Products)   AS ProductsPresentation,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Characteristic) AS CharacteristicPresentation,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Purpose)     AS PurposePresentation,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Warehouse)          AS WarehousePresentation,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Department)  AS DepartmentPresentation,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Partner)        AS PartnerPresentation,
	|	PRESENTATION(PurchaseRequestsBalancesAreSummarized.Terms)     AS TermsPresentation,
	|	CASE
	|		WHEN PurchaseRequestsBalancesAreSummarized.PackagingUnitsInApplication = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(PurchaseRequestsBalancesAreSummarized.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(PurchaseRequestsBalancesAreSummarized.PackagingUnitsInApplication)
	|	END AS PackagePresentation,
	|	CASE
	|		WHEN PurchaseRequestsBalancesAreSummarized.PackagingUnitsInApplication = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(PurchaseRequestsBalancesAreSummarized.Products.UnitOfMeasure)
	|		ELSE PRESENTATION(PurchaseRequestsBalancesAreSummarized.PackagingUnitsInApplication)
	|	END AS Package,
	|	PurchaseRequestsBalancesAreSummarized.InApplication   / &RequestTextForPackingCoefficient  AS InApplication,
	|	PurchaseRequestsBalancesAreSummarized.Ordered  / &RequestTextForPackingCoefficient  AS Ordered,
	|	PurchaseRequestsBalancesAreSummarized.Received / &RequestTextForPackingCoefficient  AS Received,
	|	PurchaseRequestsBalancesAreSummarized.Count / &RequestTextForPackingCoefficient AS ToOrder,
	|
	|	CASE
	|		WHEN PurchaseRequestsBalancesAreSummarized.Ordered = 0
	|			THEN 0
	|		WHEN PurchaseRequestsBalancesAreSummarized.Ordered < PurchaseRequestsBalancesAreSummarized.InApplication
	|			THEN 1
	|		WHEN PurchaseRequestsBalancesAreSummarized.Received < PurchaseRequestsBalancesAreSummarized.InApplication
	|			THEN 2
	|		ELSE 3
	|	END AS OutputPriority
	| 
	|
	|FROM
	|	PurchaseRequestsBalancesAreSummarized AS PurchaseRequestsBalancesAreSummarized
	|
	|ORDER BY
	|	OutputPriority,
	|	PurchaseRequestsBalancesAreSummarized.Products,
	|	PurchaseRequestsBalancesAreSummarized.Characteristic,
	|	PurchaseRequestsBalancesAreSummarized.Purpose,
	|	PurchaseRequestsBalancesAreSummarized.Warehouse,
	|	PurchaseRequestsBalancesAreSummarized.Department
	|TOTALS BY
	|	Document";
	
	RequestTextForPackingCoefficient = StrTemplate("ISNULL(%1, 1)",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"PurchaseRequestsBalancesAreSummarized.PackagingUnitsInApplication",
				"PurchaseRequestsBalancesAreSummarized.Products"));
			
	QueryText = StrReplace(QueryText,
		"&RequestTextForPackingCoefficient",
		RequestTextForPackingCoefficient);
	
	Return QueryText;
	
EndFunction

#Region SelectionOfPresentationsOfPurchaseRequests
// An analogue of query builder selections for working with temporary tables, tables of values, and the ability to substitute query texts instead of selection values.
// For use:
// 1. Initialize the description of selections for the current request: New selection of submissions for the Purchase order().
// 2. Set the necessary selections using the method: "Set the selection of submissions for the Purchase order()". For example:
//    Set Up a Selection of Submissions for the Purchase window(New Selection of submissions for the Purchase window.Application for purchase, Documents.Bid for purchase.Find the number("1"));
//    As a result, if the request text supports selection based on the purchase request, the corresponding condition will be added.
// 3. Add the keyword "&Available Selections" to the query text in the "WHERE" section. For example:
//    Query text = "Select T.Link From the "WHERE & Available Selections"
// 4. Describe the left parts of the selections available in the request text using the method: "New Available selections for Purchase". For example:
//     New Available selections for the Purchase order.Bid for purchase = "t.Link";
// 5. Change the text of the request by calling the method: "Set the request to purchase the request text".
//     In the example, because the selection is set for the purchase request (item 2) and the request text supports it (item 3. + item4), the text will be received:
//     "Select T.Link From t WHERE T.link = &Parameter"
// 6. Set the request parameters using the method: "Set the Request parameters".

// Constructor for describing selection values in the current query.
// 
// Returns:
//  Structure
Function NewSelectionsOfPresentationsOfProcurementApplications()
	
	FilterTemplate = New Structure;
	FilterTemplate.Insert("Use", False);
	FilterTemplate.Insert("ThisIsRequestText", False);
	FilterTemplate.Insert("Value", Undefined);
	FilterTemplate.Insert("IdInRequest", "");
	
	ReturnValue = New Structure(
		NamesOfSelectionsOfPresentationsOfPurchaseRequests());
	
	For Each KeyAndValue In ReturnValue Do
		
		FilterName = KeyAndValue.Key;
		FilterElement = Common.CopyRecursive(FilterTemplate);
		FilterElement.IdInRequest = FilterName;
		
		ReturnValue[FilterName] = FilterElement;
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Constructor for describing selections that the current query text supports.
// 
// Returns:
//  Structure
Function NewAvailableSelectionsOfPurchaseRequests()
	
	ReturnValue = New Structure(
		NamesOfSelectionsOfPresentationsOfPurchaseRequests());
	
	For Each KeyAndValue In ReturnValue Do
		
		FilterName = KeyAndValue.Key;
		ReturnValue[FilterName] = "";
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// The names of all available selections in the Presentations of purchase requests. 
// 
// Returns:
//  String - Names Of Selections Of Presentations Of Purchase Requests
Function NamesOfSelectionsOfPresentationsOfPurchaseRequests()
	
	ReturnValue = 
	"PurchaseRequest,
	|ApplicationHasBeenCompleted,
	|
	|PurchaseOrder,
	|OrderPosted,
	|OrderWasCreatedBasedOnRequest";
	
	Return ReturnValue;
	
EndFunction

// Adds descriptions of the selection in the request.
//
// Parameters:
//   FilterElement - Structure - Specifies which field will be selected in the request:
//       For example, the newly available selections for the Purchase order().Bid for purchase.
//       For the names of the available fields, see "The names of the selections for the Purchase Order()". 
//   FilterValue - Arbitrary - The selection value that will be set to the request parameter.
//   ThisIsRequestText - Boolean - If True, then instead of setting the query parameter, the text from the value will be substituted.
Procedure EstablishSelectionOfPresentationsOfProcurementApplications(FilterElement, FilterValue, ThisIsRequestText = False)

	FilterElement.Use = True;
	FilterElement.ThisIsRequestText = ThisIsRequestText;
	If ThisIsRequestText Then
		FilterElement.IdInRequest = FilterValue;
	Else
		FilterElement.Value = FilterValue;
	EndIf;
	
EndProcedure

// Sets the described selections as query parameters. 
// 
// Parameters:
//  Query - Query - Request to set parameters in.
//  Filters - Structure - See NewSelectionsOfPresentationsOfProcurementApplications()
Procedure SetSelectionOfPurchaseRequestsInRequestParameters(Query, Filters)
	
	For Each KeyAndValue In Filters Do
		
		FilterElement = KeyAndValue.Value;
		
		If Not FilterElement.Use
			Or FilterElement.ThisIsRequestText Then
			Continue;
		EndIf;
		
		Query.SetParameter(FilterElement.IdInRequest, FilterElement.Value);
		
	EndDo;
	
EndProcedure

// Sets selections in the Query Text based on the values described.
// 
// Parameters:
//  QueryText - String - with the keyword "&AVAILABLE selections" in the "WHERE" section.
//  Filters - Structure - See NewSelectionsOfPresentationsOfProcurementApplications()
//  AvailableSelections - Structure - See NewAvailableSelectionsOfPurchaseRequests()
// 
// Returns:
//  String - Set The Selection Of Purchase Requests In The Query Text
Function SetSelectionOfPurchaseRequestsInQueryText(Val QueryText, Filters, AvailableSelections)
	
	SelectionText_ = New Array;
	SelectionText_.Add("TRUE");
	For Each KeyAndValue In AvailableSelections Do
		
		FilterElement = Filters[KeyAndValue.Key];
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		LeftPart = KeyAndValue.Value;
		If IsBlankString(LeftPart) Then
			Continue;
		EndIf;
		
		ValueType = TypeOf(FilterElement.Value);
		If FilterElement.ThisIsRequestText Then
			
			ConditionTemplate = "%1 IN (%2)";  //@query-part
			
		ElsIf ValueType = Type("Array") Then
			
			ConditionTemplate = StrTemplate("%1 IN (&%2)");
			
		ElsIf ValueType = Type("Boolean") Then
			
			If FilterElement.Value Then
				ConditionTemplate = "%1";  //@query-part
			Else
				ConditionTemplate = "NOT %1";  //@query-part
			EndIf;
			
		Else
			
			ConditionTemplate = "%1 = &%2"; //@query-part
			
		EndIf;
		
		SelectionText_.Add(StringFunctionsClientServer.SubstituteParametersToString(
			ConditionTemplate,
			LeftPart,
			FilterElement.IdInRequest));
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&AvailableSelections", StrConcat(SelectionText_, "
	|	AND "));  //@query-part
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion
#Region ControllingLimitsBasedOnBudgetingData

// Returns the Query Text for creating a temporary table with data sources for rules for getting actual data on budget items.
// Data sources depend on the business of operation of the document.
//
// Returns:
//  String - Query text
//
Function QueryTextDataSourcesOfRulesForObtainingFact() Export
	
	QueryText = 
	"SELECT
	|	BusinessTransactionsSettings.Ref AS DataSource,
	|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Receipt AS Receipt,
	|	BusinessTransactionsSettings.Expense AS Expense
	|INTO DataSourcesOfRulesForObtainingFact
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|WHERE
	|	BusinessTransactionsSettings.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand)";
	
	Return QueryText;
	
EndFunction

// Returns the Query Text as the source of actual data for the document.
// The source of actual data depends on the types of accounting data of operation rules for obtaining actual data on budget items.
//
// Parameters:
//  Expense - EnumRef.AccountingDataTypes - Business expense of operation
//  Receipt - EnumRef.AccountingDataTypes - Business Receipt of operation
//  TempTableName - String - name of the temp table (if not specified, the temp table is not generated)
//
// Returns:
//  String - Query text
//
Function QueryTextFactSourceByTypeOfAccountingData(Expense, Receipt, TempTableName = "") Export
	
	QueryText =
	"SELECT
	|	DataTable.Date AS Period,
	|	DataTable.Ref AS Recorder,
	|	DataTable.Organization AS Organization,
	|	DataTable.Department AS Department,
	|	DataTable.Department AS IncomeExpenseBusinessUnit,
	|	DataTable.Warehouse AS Warehouse,
	|	DataTable.LineOfBusiness AS LineOfBusinessOfIncomeExpenses,
	|	ExpensesTable.Products AS Products,
	|	ExpensesTable.BudgetFlowItem AS BudgetFlowItem,
	|	ExpensesTable.ExpenseItem AS IncomeAndExpenseItem,
	|	ExpensesTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DataTable.Currency AS Currency,
	|	CASE
	|		WHEN DataTable.PriceIncludesVAT
	|			THEN ExpensesTable.Sum - ExpensesTable.VATAmount
	|		ELSE ExpensesTable.Sum
	|	END AS Sum,
	|	CASE
	|		WHEN DataTable.Status = VALUE(Enum.PurchaseRequestStatuses.Closed_)
	|			THEN CASE
	|				WHEN DataTable.PriceIncludesVAT
	|					THEN ExpensesTable.Sum - ExpensesTable.VATAmount
	|				ELSE ExpensesTable.Sum
	|			END
	|		ELSE 0
	|	END AS SumReal
	|INTO TempTableName
	|FROM
	|	Document.PurchaseRequest AS DataTable
	|		INNER JOIN Document.PurchaseRequest.Goods AS ExpensesTable
	|		ON DataTable.Ref = ExpensesTable.Ref
	|WHERE
	|	DataTable.Ref = &Document
	|	AND NOT ExpensesTable.Canceled
	|	AND DataTable.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO TempTableName", "");
		QueryText = StrReplace(QueryText, "DataTable.Ref = &Document", "DataTable.Posted");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion
#EndRegion

#EndIf
