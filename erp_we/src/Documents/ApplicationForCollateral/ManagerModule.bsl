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
	DocumentMechanisms.Add("ControlOfBudgetingLimits");
	Return;
	
EndProcedure

// Additional data sources for movements.
// 
// Parameters:
//  RegisterName - String - Register name
// 
// Returns:
//  Map of KeyAndValue:
//    * Key - String - LongDesc
//    * Value - String - LongDesc
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.ApplicationForCollateral, DocumentRef.ApplicationForCollateral - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	Structure of KeyAndValue - Tables Of Conduct:
//			* Key - String - table name
//			* Value - ValueTable - The data table of the event.
//	List of values From String - a list of values containing Query Texts and their names.
//						Returned if the 'Get Request texts' property of the Dopparameters parameter
//						is set to True.
//@skip-check function-return-types -- The structure of the tables is dynamic, not described
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;

	If TypeOf(Document) = Type("DocumentObject.ApplicationForCollateral") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("StatusesThatHaveBeenApproved", 
		Enums.ProvisionRequestStatuses.StatusesThatHaveBeenApproved());
	
	QueryTexts = New ValueList;
	
	//@skip-check constructor-function-return-section
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Returns parameters for selecting articles in the document.
//
// Parameters:
//  SuppliedByPurchase - Boolean - True if the request is provided by purchase
// 
// Returns:
// See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(SuppliedByPurchase) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.AvailabilityByOperation = False;
	If GetFunctionalOption("UseIEBLimitsOnConsumption")
		Or GetFunctionalOption("UseIEBLimitsOnPurchases") And SuppliedByPurchase Then
		ChoiceParameters.AvailabilityByOperation = True;
	EndIf;
	ChoiceParameters.FormItems.AssetRef.Add("ItemExpenseItem");
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ItemExpenseAnalytics");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#Region GenerateFrom

// Adds a command to create a document "Application for security".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - Added table row if the Command is available
//@skip-check function-return-types
Function AddGenerateCommand(GenerationCommands) Export
	
	CreateBasedOnCommand = Undefined;
	
	MetadataOfDocument = Metadata.Documents.ApplicationForCollateral;
	If AccessRight("Insert", MetadataOfDocument) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = MetadataOfDocument.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(MetadataOfDocument);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProvisionRequests";
		
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
	
	SupplyCommands = New Array; // Available only in the "On execution" State
	PurchasingCommands = New Array; // Available only if the purchase is secured
	
	// The need to secure orders:
	SupplyCommands.Add(Documents.InventoryConsumptionOrder.AddGenerateCommand(GenerationCommands));
	
	// Internal source of security:
	SupplyCommands.Add(Documents.TransferOrder.AddGenerateCommand(GenerationCommands));
	SupplyCommands.Add(Documents.InventoryTransfer.AddGenerateCommand(GenerationCommands));
	SupplyCommands.Add(Documents.InventoryConsumption.AddGenerateCommand(GenerationCommands));
	SupplyCommands.Add(Documents.ProductionOrder2_2.AddGenerateCommand(GenerationCommands));
	
	// External supply source:
	PurchasingCommands.Add(Documents.PurchaseOrder.AddGenerateCommand(GenerationCommands));
	PurchasingCommands.Add(Documents.VendorInvoice.AddGenerateCommand(GenerationCommands));
	PurchasingCommands.Add(Documents.VendorInvoiceServicesAndAssets.AddGenerateCommand(GenerationCommands));
	
	// Payment documents:
	PurchasingCommands.Add(Documents.PaymentRequest.AddGenerateCommand(GenerationCommands));
	PurchasingCommands.Add(Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands));
	PurchasingCommands.Add(Documents.CashVoucher.AddGenerateCommand(GenerationCommands));
	
	CommonClientServer.SupplementArray(SupplyCommands, PurchasingCommands);
	
	For Each Command In SupplyCommands Do
		
		If Command = Undefined Then
			Continue; // There are no rights to the object being created, the command is not being created
		EndIf;
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "Status", Enums.ProvisionRequestStatuses.OnExecution);
	EndDo;
	
	For Each Command In PurchasingCommands Do
		
		If Command = Undefined Then
			Continue; // There are no rights to the object being created, the command is not being created 
		EndIf;
		
		AttachableCommands.AddCommandVisibilityCondition(Command, "SuppliedByPurchase", True);
	EndDo;
	
	ApplicationForCollateralLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
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
	ReportCommand = Reports.LimitsByBudgetingData.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand, "SuppliedByPurchase", True);
		ReportCommand.FunctionalOptions = "UseIEBLimitsOnPurchases";
	EndIf;
	ReportCommand = Reports.LimitsByBudgetingData.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.FunctionalOptions = "UseIEBLimitsOnConsumption";
	EndIf;
EndProcedure

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	If Not AccessRight("Edit", Metadata.Documents.ApplicationForCollateral)
		Or Not GetFunctionalOption("UseProvisionRequests") Then
		Return;
	EndIf;
	
	Performer = CommonQueryParameters.User;
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED TOP 1
	|	ISNULL(COUNT(ApplicationForCollateral.Ref), 0) AS NumberOfRequests
	|FROM
	|	Document.ApplicationForCollateral AS ApplicationForCollateral
	|WHERE
	|	ApplicationForCollateral.Performer = &Performer
	|	AND NOT ApplicationForCollateral.DeletionMark"; // The draft also requires working out
	
	Query.SetParameter("Performer", Performer);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	NumberOfApplicationsToBeProcessed = Selection.NumberOfRequests;
	HasToDoItems = ValueIsFilled(NumberOfApplicationsToBeProcessed);
		
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterApplicationsForWorkingOut(Performer));
	FormParameters.Insert("PurposeUseKey", "ApplicationsForWorkingOut");
	FormParameters.Insert("Filter", New Structure("DeletionMark", False));
		
	ParentID = "InternalInventoryTransfers";
	
	UserTaskParent = ToDoList.Find(ParentID, "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = ParentID;
		UserTaskParent.Presentation  = NStr("vi = 'Điều chuyển hàng hóa nội bộ';
											|ru = 'Внутреннее товародвижение';
											|en = 'Internal inventory transfers'; fa = 'انتقالات داخلی موجودی';
											|it = 'Flusso di prodotti interno';
											|pl = 'Wewnętrzny ruch towarów';
											|tr = 'Dahili stok transferleri'");
		UserTaskParent.Owner       = Metadata.Subsystems.Warehouse;
	EndIf;
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or HasToDoItems;
	
	CurCase = ToDoList.Add();
	CurCase.Id = "SupplyApplicationDocuments";
	CurCase.Presentation = NStr("vi = 'Giấy đề nghị cung cấp cần xử lý';
								|ru = 'Заявки на обеспечение к отработке';
								|en = 'Provision requests to process'; fa = 'Provision requests to process';
								|it = 'Provision requests to process';
								|pl = 'Provision requests to process';
								|tr = 'İşlenecek tedarik talepleri'");
	CurCase.Count = NumberOfApplicationsToBeProcessed;
	CurCase.Form = "Document.ApplicationForCollateral.ListForm";
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
		"Organization, Department, Warehouse, EmployeeResponsible", Parameters);
	
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

#EndRegion

#EndRegion

#Region Internal

// Parameters for receiving fill-in data based on.
// 
// Returns:
//  Structure - Parameters For Receiving Fill-In Data Based On:
// * WorkWithStringsIsSupported - Boolean - In the document to be filled in, you can specify the nomenclature by the line
// * ItemsType - Array of EnumRef.ItemsTypes
Function ParametersForReceivingFillInDataBasedOn() Export

	ReturnValue = New Structure;
	ReturnValue.Insert("WorkWithStringsIsSupported", False);
	ReturnValue.Insert("ItemsType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
	Return ReturnValue;
	
EndFunction

// Returns data for filling out a document based on a Security Request.
//
// Parameters:
//   Ref - DocumentRef.ApplicationForCollateral - the foundation document
//   ReceivingParameters - See ParametersForReceivingFillInDataBasedOn
//
// Returns:
//   Structure:
//     * Header - Structure:
//         ** Organization - CatalogRef.Companies
//         ** Department - CatalogRef.BusinessStructure
//         ** Warehouse - CatalogRef.Warehouses
//         ** LineOfBusiness - CatalogRef.LinesOfBusiness
//      * Goods - ValueTable:
//         ** ProductsAsAString - String
//         ** Products - CatalogRef.Products
//         ** Characteristic - CatalogRef.ItemsCharacteristics
//         ** Package - CatalogRef.PackagesAndUnitsOfMeasure
//         ** Count - Number
//         ** NumberOfPackages - Number
//         ** Sum - Number
//         ** ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems
//         ** DimensionOfExpenses - Characteristic.ExpenseItems
//         ** BudgetFlowItem - CatalogRef.BudgetFlowItems
//         ** ToExpenseAs - Boolean
Function FillingDataBasedOn(Ref, Val ReceivingParameters = Undefined) Export
	
	If ReceivingParameters = Undefined Then
		ReceivingParameters = ParametersForReceivingFillInDataBasedOn();
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	CommonClientServer.SupplementStructure(Query.Parameters, ReceivingParameters);
	QueryTexts = New ValueList;
	
	QueryTexts.Add(
		"SELECT
		|	ApplicationForCollateral.Organization             AS Organization,
		|	ApplicationForCollateral.Department           AS Department,
		|	ApplicationForCollateral.Warehouse                   AS Warehouse,
		|	ApplicationForCollateral.Currency                  AS Currency,
		|	ApplicationForCollateral.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.ApplicationForCollateral AS ApplicationForCollateral
		|WHERE
		|	ApplicationForCollateral.Ref = &Ref",
		"Header");
	
	QueryTexts.Add(
		"SELECT
		|	GoodsTable.ProductsAsAString AS ProductsAsAString,
		|	GoodsTable.Products        AS Products,
		|	GoodsTable.Characteristic      AS Characteristic,
		|	GoodsTable.Package            AS Package,
		|	GoodsTable.Count          AS Count,
		|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
		|	GoodsTable.Sum               AS Sum,
		|	TRUE                            AS ToExpenseAs,
		|	GoodsTable.DimensionOfExpenses   AS DimensionOfExpenses,
		|	GoodsTable.ExpenseItem      AS ExpenseItem,
		|	Header.LineOfBusiness     AS LineOfBusiness
		|FROM
		|	Document.ApplicationForCollateral.Goods AS GoodsTable
		|	INNER JOIN Document.ApplicationForCollateral AS Header
		|		ON GoodsTable.Ref = Header.Ref
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND (GoodsTable.Products.ItemsType IN (&ItemsType)
		|		OR GoodsTable.Products = VALUE(Catalog.Products.EmptyRef)
		| 			AND &WorkWithStringsIsSupported)",
		"Goods");

	PackageResult = TMCommonUse.GetQueryResults(Query, QueryTexts);
	
	QueryResult = PackageResult.Header; // QueryResult
	Selection = QueryResult.Select();
	Selection.Next();
	
	Header = New Structure;
	For Each Column In Selection.Owner().Columns Do
		Header.Insert(Column.Name, Selection[Column.Name]);
	EndDo;
	
	Goods = PackageResult.Goods.Unload(); // ValueTable
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Header", Header);
	ReturnValue.Insert("Goods", Goods);
	
	Return ReturnValue;
	
EndFunction

// Returns data used in processing the filling of payment documents.
//
// Parameters:
//   Ref - DocumentRef.ApplicationForCollateral - link to the document "Application for collateral"
//
// Returns:
//   Structure:
//     * HeaderRequestResult - QueryResult - Data for the document header
Function DataForPayment(Ref) Export

	Query = New Query;
	Query.Text = 
	"SELECT
	|	Header.Organization                                             AS Organization,
	|	Header.Department                                           AS Department,
	|	Header.DocumentAmount                                          AS Sum,
	|	Header.Currency                                                  AS Currency,
	|	Header.Currency                                                  AS ARAPCurrency,
	|	Header.LineOfBusiness                                 AS LineOfBusiness,
	|	&Ref                                                       AS DocumentBasis,
	|	&Period                                                       AS RequiredPaymentDate,
	|	
	|	VALUE(Enum.BusinessTransactions.PaymentToVendor) AS BusinessOperation,
	|
	|	// Required Attributes of the ""Fill in the requestionresultsquest"" methods:
	|	VALUE(Catalog.Partners.EmptyRef)                    AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef)                 AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)        AS Contract,
	|	VALUE(Catalog.CompaniesBankAccounts.EmptyRef)  AS BankAccount,
	|	VALUE(Catalog.CounterpartyBankAccounts.EmptyRef) AS CounterpartyBankAccount,
	|	VALUE(Enum.PaymentForms.EmptyRef)               AS PaymentMethodOfPaymentRequest,
	|	FALSE                                                          AS PaymentMethodCash,    // Set to true if the application form is not filled in
	|	FALSE                                                          AS PaymentMethodBankAccount  // Set to true if the application form is not filled in
	|FROM
	|	Document.ApplicationForCollateral AS Header
	|WHERE
	|	Header.Ref = &Ref";

	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Period", CurrentSessionDate());
	
	HeaderRequestResult = Query.Execute();
	
	ReturnValue = New Structure;
	ReturnValue.Insert("HeaderRequestResult", HeaderRequestResult);
	
	Return ReturnValue;
	
EndFunction

// Fills in the tabular part "Decryption of payment" of the payment document based on the application for collateral.
// Parameters:
//  PaymentDocument - DocumentObject.PaymentRequest, DocumentObject.CashVoucher, DocumentObject.BankAccountIssue - The document to be filled in.
//  DataForPayment - See DataForPayment
Procedure FillInPaymentTranscript(PaymentDocument, DataForPayment) Export
	
	// The data of the tabular part is not used to fill in the transcript, because there is no information for breakdown in them.
	// Reusing the data to fill in the header
	Selection = DataForPayment.HeaderRequestResult.Select();
	Selection.Next();
	
	PaymentDocument.ARAPDetails.Clear();
	DecryptionString = PaymentDocument.ARAPDetails.Add();
	
	DecryptionString.Organization = Selection.Organization;
	DecryptionString.CashFlowItem = Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Enums.BusinessTransactions.PaymentToVendor);
	DecryptionString.Sum = Selection.Sum;
	DecryptionString.AmountARAP = Selection.Sum;
	DecryptionString.ARAPCurrency = Selection.Currency;
	
	PaymentDocument.DocumentAmount = PaymentDocument.ARAPDetails.Total("Sum");
	
EndProcedure

#Region BDRLimits

// Returns the flag for using BDR limits in supply requests.
// 
// Returns:
//  Boolean
Function UseBDRLimits() Export
	
	ReturnValue = False;
	ReturnValue = LimitsByBudgetingDataServer.UseBDRLimits();
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Determines whether the purchase Attributes should be displayed in the document.
// 
// Parameters:
//  Object - DocumentObject.ApplicationForCollateral, FormDataStructure - For which it is necessary to determine the need for verification.
// 
// Returns:
//  Boolean
Function DisplayPurchaseAttributes(Object) Export
	
	Return Object.SuppliedByPurchase
		Or UseBDRLimits();
	 	
EndFunction

// Determines whether it is necessary to check the correctness of filling in the purchase Attributes.
// 
// Parameters:
//  Object - DocumentObject.ApplicationForCollateral, FormDataStructure - For which it is necessary to determine the need for verification.
// 
// Returns:
//  Boolean
Function CheckPurchaseAttributes(Object) Export
	
	// If limits are maintained, then prices are always processed.
	// In other cases, they are used only for information and are not controlled.
	Return CheckAttributesOfLimitAnalyst(Object);
	
EndFunction

// Defines the names of the Attributes describing the purchase.
// 
// Returns:
//  Array of String - the names of the details.
//
Function NamesOfPurchaseDetails() Export
	
	ReturnValue = New Array;
	
	ReturnValue.Add("Currency");
	
	ReturnValue.Add("Goods.Price");
	ReturnValue.Add("Goods.Sum");
	
	Return ReturnValue;
	
EndFunction

// Determines the need to check the correctness of filling in the Attributes of the limiting analyst.
// 
// Parameters:
//  Object - DocumentObject.ApplicationForCollateral, FormDataStructure - For which it is necessary to determine the need for verification.
// 
// Returns:
//  Boolean
Function CheckAttributesOfLimitAnalyst(Object) Export
	
	ReturnValue = False;
	ReturnValue = 
		// Prior to the agreement, prices and other analytics may change and be updated.
		Enums.ProvisionRequestStatuses.AgreedUpon(Object.Status)
	 	And LimitsByBudgetingDataServer.UseBDRLimits();
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

// Defines the names of the Attributes that must be filled in in the header of the document.
// 
// Returns:
//  Array of String - the names of the details.
//
Function NamesOfHeaderDetails() Export
	
	ReturnValue = New Array;
	
	ReturnValue.Add("Organization");
	ReturnValue.Add("EmployeeResponsible");
	ReturnValue.Add("Department");
	ReturnValue.Add("Warehouse");
	
	Return ReturnValue;
	
EndFunction

#Region Filters

Function FilterApplicationsForWorkingOut(Performer)
	
	ListFilter = NewListSelection();
	ListFilter.Performer.Add(Performer);
	
	Return ListFilter;
	
EndFunction

// New list selection.
// 
// Returns:
//  Structure - New List Selection:
// * Performer - ValueList of CatalogRef.Users 
// * EmployeeResponsible - ValueList of CatalogRef.Users 
// * Status - ValueList  of EnumRef.ProvisionRequestStatuses 
// * Author - ValueList of CatalogRef.Users 
Function NewListSelection() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Performer", New ValueList);
	ReturnValue.Insert("EmployeeResponsible", New ValueList);
	ReturnValue.Insert("Status", New ValueList);
	ReturnValue.Insert("Author", New ValueList);
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region Posting

// The document's user interface is simplified. The recording mode of a document is determined by its Status.
// 
// Parameters:
//  Object - DocumentObject.ApplicationForCollateral, FormDataStructure - For which you need to define the recording mode.
// 
// Returns:
//  DocumentWriteMode
Function WriteMode(Object) Export
	
	ReturnValue = DocumentWriteMode.Write;
	
	PreviousState = New Structure;
	PreviousState.Insert("Posted", False);
	PreviousState.Insert("DeletionMark", False);
	
	If ValueIsFilled(Object.Ref) Then
		PreviousState = Common.ObjectAttributesValues(
			Object.Ref,
			CommonClientServer.StructureKeysToString(PreviousState));
	EndIf;
	
	Post = Enums.ProvisionRequestStatuses.Post(Object.Status);
	
	If Object.DeletionMark  
		And Not PreviousState.DeletionMark
		And PreviousState.Posted Then
		
		// A deletion mark is set for the completed document. Cancel the event.
		ReturnValue = DocumentWriteMode.UndoPosting; 
		
	ElsIf Not Post And PreviousState.Posted Then
		
		// The Status that does not require holding has been set.
		ReturnValue = DocumentWriteMode.UndoPosting;
		
	ElsIf Post Then
		
		// Including for those marked for deletion (an exception will be raised)
		ReturnValue = DocumentWriteMode.Posting;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

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
	|	ExpensesTable.Sum AS Sum,
	|	CASE
	|		WHEN DataTable.Status = VALUE(Enum.ProvisionRequestStatuses.Executed)
	|			THEN ExpensesTable.Sum
	|		ELSE 0
	|	END AS SumReal
	|INTO TempTableName
	|FROM
	|	Document.ApplicationForCollateral AS DataTable
	|		INNER JOIN Document.ApplicationForCollateral.Goods AS ExpensesTable
	|		ON DataTable.Ref = ExpensesTable.Ref
	|WHERE
	|	NOT DataTable.Status IN (VALUE(Enum.ProvisionRequestStatuses.Draft), VALUE(Enum.ProvisionRequestStatuses.RolledBack))
	|	AND DataTable.Ref = &Document
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
