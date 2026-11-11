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
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("IntangibleAssets");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");

	VendorInvoiceServicesAndAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.VendorInvoiceServicesAndAssets") Then
		DocumentRef = Document.Ref;
		DocumentObject = Document;
	Else
		DocumentRef = Document;
		DocumentObject = Document.GetObject();
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If AddlParameters <> Undefined
		And AddlParameters.Property("TempTablesManager")
		And AddlParameters.TempTablesManager <> Undefined Then
		Query.TempTablesManager = AddlParameters.TempTablesManager;
	Else
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject);
		QueryTextRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers, DocumentObject);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers, DocumentObject);
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers, DocumentObject);
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject);
		
		VendorInvoiceServicesAndAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
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
	
	Documents.ARAPSettlement.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.PurchaseAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.ApplicationForImportationOfGoods.AddGenerateCommand(GenerationCommands);
	
	VendorInvoiceServicesAndAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	Documents.ReverseVATAccrual.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "Purchase of services and other assets".
//
// Parameters:
//  GenerationCommands - ValueTable - The description in the creation of the base is undefined.Before adding a command to create a base
// Returns:
// 	ValueTableRow - The description in the creation of the base is undefined.Before adding a command to create a base.Teamsreferences 
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.VendorInvoiceServicesAndAssets) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.VendorInvoiceServicesAndAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.VendorInvoiceServicesAndAssets);
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
	
	ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	
	ReportCommand = Reports.DetailedCalculationOfDiscountingInterestExpenseAccrual.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	VendorInvoiceServicesAndAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("Contract");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		
		ArrayOfOperationDetails.Add("Contract");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CashFlowItem");
	EndIf;
	
EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - Arbitrary - link to the document
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		ARAPCurrency = Selection.ARAPCurrency;
		Currency = Selection.Currency;
		BusinessOperation = Selection.BusinessOperation;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		Rate = Selection.Rate;
		Repetition = Selection.Repetition;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = 0;
		AmountARAP = 0;
		Rate = 1;
		Repetition = 1;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	
	Return AttributesStructure1;

EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'In biên bản / hóa đơn GTGT';
							|ru = 'Акт';
							|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
							|it = 'Atto';
							|pl = 'Customer invoice — Services';
							|tr = 'Tutanak'"));
	VendorInvoiceServicesAndAssetsLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return VendorInvoiceServicesAndAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return VendorInvoiceServicesAndAssetsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Expenses";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	SetupParameters.ArticleType     = "ArticleType";
	
	SetupParameters.AvailabilityByOperation = True;
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("ExpensesPresentationOfRecordingInComplAccounting");
	
	Return SetupParameters;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions 
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Expenses";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpensesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("ExpensesDimensionOfRevenue");
	
	VendorInvoiceServicesAndAssetsLocalization.AddOptionsForSelectingArticlesAndAnalytics(ChoiceParameters, BusinessOperation);

	Return ChoiceParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation");
		BusinessOperation = StructureFillingData.BusinessOperation;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)";
	ParametersStructure.ChangesPaymentPlan               = BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	
	#EndRegion
	
	#Region OptionalParameters
	
	//Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.PathToTSData                    = "Object.Expenses";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	
	ParametersStructure.CashAccount                            = "";
	
	//The details for the object of calculations are used in conducting.
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	
	//The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement                      = "PaymentSettlement";
	//The name of the table element of the form that displays the amount of settlements.
	//Used to set the conditional design.
	//It should be filled in if the document supports line-by-line manual editing of settlement amounts.
	ParametersStructure.FormItems.AmountOfTSSettlements            = "ExpensesAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup           = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness          = "LineOfBusiness";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	ParametersStructure.CourseNumerator                          = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                        = "Object.CourseDenominator";
	
	//The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies                    = "CurrencyDecoration";
	
	//If it is not necessary to show the amount and currency of mutual settlements based on the data of the document.
	ParametersStructure.DonTShowCalculations                            = BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder;
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	//Function Payment stages and payment date
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	
	//The name of the hyperlink that displays the current payment rules of the document and opens the Payment Rules form.
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";

	#EndRegion
	
	#Region MutualSettlementsStatus
	
	//The name of the hyperlink that displays the status of calculations and opens the corresponding report,
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	
	#EndRegion
	
	ParametersStructure.DocumentExchangeRateDate             = "Object.DocumentExchangeRateDate";
	
	ParametersStructure.OperationWithSelfEmployedPerson                 = "Object.OperationWithSelfEmployedPerson";
	
	Return ParametersStructure;
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CounterpartyBankAccount", Parameters);
	
EndProcedure

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceServicesAndAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for filling in VAT taxation for purchases
//
// Parameters:
//  Object - DocumentObject.VendorInvoiceServicesAndAssets, DocumentRef.VendorInvoiceServicesAndAssets, FormDataStructure - the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases.
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	If TypeOf(Object) = Type("DocumentObject.VendorInvoiceServicesAndAssets")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Counterparty,Contract,Date");
	EndIf;
	
	FillParameters.Counterparty = ObjectData.Counterparty;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.Period  = ObjectData.Date;
	FillParameters.PurchaseOnArticles = True;
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the completion of VAT taxation for purchases
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceServicesAndAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - structure of parameters, See VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases.
//
Function VerificationParametersFillingInDocumentOnVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	FillParameters.TabularSectionName = "Expenses";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for checking the filling in of the document by type of activity VAT
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceServicesAndAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  Structure - structure of parameters, See VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity.
//
Function ParametersForCheckingDocumentFillingByTypeOfActivity(Object) Export
	
	FillParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	FillParameters.TabularSectionName = "Expenses";
	FillParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	FillParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	FillParameters.DetailsNameItemOfAssetsLiabilities = "ExpenseItem";
	FillParameters.NameOfAssetLiabilityAnalystDetails = "AssetsLiabilitiesDimension";
	
	Return FillParameters;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.VendorInvoiceServicesAndAssets, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref = Object.Ref;
	RegistrationParameters.Date = Object.Date;
	RegistrationParameters.Organization = Object.Organization;
	RegistrationParameters.Counterparty = Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

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

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "VendorInvoiceServicesAndAssets");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.VendorInvoiceServicesAndAssets";
	
	RequestHasSource = True;
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "DocumentData";
		RequestHasSource = False;
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "FATable";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "TableOfIA";
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.PaymentDate AS PaymentDate,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.Department AS Department,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.PurchaseForActivity AS PurchaseForActivity,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.AccountingForLBCosts AS AccountingForLBCosts,
	|	DocumentData.AccountingForSettlementsWithSuppliersUnderLB AS AccountingForSettlementsWithSuppliersUnderLB,
	|	DocumentData.DocumentAmount                 AS DocumentAmount,
	|	DocumentData.IncomingDocumentDate         AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber        AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.Number                          AS Number,
	|	DocumentData.Comment                    AS Comment,
	|	DocumentData.DeletionMark                AS DeletionMark,
	|	DocumentData.Posted                       AS Posted,
	|	DocumentData.Manager                       AS Manager,
	|	DocumentData.Author                          AS Author,
	|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	DocumentData.AdjustmentPeriod_            AS AdjustmentPeriod_
	|FROM
	|	DocumentDataHeader AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("ManagementAccountingCurrency",		 Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("PriceIncludesVAT",				 ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", 	GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("ControlIssueOfCashByPurposes", GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Query.SetParameter("ControlIssueOfCashByPurposes", GetFunctionalOption("ControlIssueOfCashByPurposes"));
	
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
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableExpenses(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date,
	|	DocumentData.PaymentDate,
	|	DocumentData.DocumentExchangeRateDate,
	|	DocumentData.Organization,
	|	DocumentData.Partner,
	|	DocumentData.Counterparty,
	|	DocumentData.Currency,
	|	DocumentData.CourseNumerator,
	|	DocumentData.CourseDenominator,
	|	DocumentData.ARAPCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.PriceIncludesVAT,
	|	DocumentData.Department,
	|	DocumentData.BusinessOperation,
	|	DocumentData.PaymentMethod,
	|	DocumentData.Contract,
	|	DocumentData.Contract.AllowableAmountPayable AS AllowableAmountPayable,
	|	DocumentData.CashFlowItem,
	|	DocumentData.AdvanceHolder,
	|	DocumentData.VATTaxation,
	|	DocumentData.PurchaseForActivity,
	|	DocumentData.FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	DocumentData.Number,
	|	DocumentData.IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName,
	|	DocumentData.Manager,
	|	DocumentData.Author,
	|	DocumentData.DocumentAmount,
	|	DocumentData.AmountARAP,
	|	DocumentData.ARAPObjectSettings,
	|	DocumentData.Comment,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	DocumentData.ActualTransactionDate AS AdjustmentPeriod_
	|INTO DocumentDataHeader
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref IN (&Ref)
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableExpenses(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	DocumentTable.RowID,
	|	DocumentTable.Content,
	|	DocumentTable.Count,
	|	DocumentTable.Price,
	|	DocumentTable.Sum,
	|	DocumentTable.VATRate,
	|	DocumentTable.VATAmount,
	|	DocumentTable.AmountIncludingVAT,
	|	DocumentTable.ExpenseItem,
	|	DocumentTable.DimensionOfExpenses,
	|	DocumentTable.AmountARAP,
	|	DocumentTable.AmountVATARAP,
	|	DocumentTable.Department,
	|	DocumentTable.AllocationComment,
	|	DocumentTable.DimensionOfRevenue,
	|	DocumentTable.AssetsLiabilitiesDimension,
	|	DocumentTable.LineOfBusiness,
	|	DocumentTable.GLAccountSettings,
	|	DocumentTable.GLAccountSettings.GLAccount AS SettingUpLedgerAccountsLedgerAccount,
	|	DocumentTable.CCDNumber,
	|	DocumentTable.FEACNCode,
	|	DocumentTable.QuantityByGBRN,
	|	ARTICLES__.VATAssetTaxClass AS ItemOfExpensesAssetTaxClassVAT,
	|	ARTICLES__.CostAllocationOptionLocal AS ExpenseItemCostAllocationOptionLocal,
	|	ARTICLES__.SeparateVATAccountingOption AS ExpenseItemIsVariantOfSeparateVATAccounting,
	|	ARTICLES__.Ref AS ExpenseItemLink,
	|	DocumentTable.FEACNCode.TracedGoods AS HSCodeTraceableItem,
	|	DocumentTable.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType
	|INTO DocumentDataTableExpenses
	|FROM
	|	Document.VendorInvoiceServicesAndAssets.Expenses AS DocumentTable
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|INDEX BY
	|	Ref
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests)
	
	QueryText =
	"SELECT
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.LineNumber,
	|	PaymentDecryptionTable.ARAPObject,
	|
	|	PaymentDecryptionTable.Sum,
	|	PaymentDecryptionTable.AmountARAP
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.VendorInvoiceServicesAndAssets.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref IN (&Ref)
	|INDEX BY
	|	Ref
	|";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure


Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.VendorInvoiceServicesAndAssets"));
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Expenses"" 							AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN &SimplifiedTaxationSystem
	|			THEN DocumentData.PurchaseForActivity
	|		WHEN ISNULL(DocumentTable.ItemOfExpensesAssetTaxClassVAT, UNDEFINED) IN
	|		  (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
	|		  AND ISNULL(DocumentTable.ExpenseItemCostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		  AND ISNULL(DocumentTable.ExpenseItemIsVariantOfSeparateVATAccounting, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		WHEN ISNULL(DocumentTable.ExpenseItemIsVariantOfSeparateVATAccounting, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		ELSE DocumentData.PurchaseForActivity
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN NOT DocumentTable.ExpenseItemLink IS NULL
	|			THEN DocumentTable.ItemOfExpensesAssetTaxClassVAT
	|		WHEN DocumentTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			  AND DocumentTable.AssetsLiabilitiesDimension REFS Catalog.Assets
	|			THEN VALUE(Enum.AssetKinds.FA)
	|		WHEN DocumentTable.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			  AND DocumentTable.AssetsLiabilitiesDimension REFS Catalog.IntangibleAssets
	|			THEN VALUE(Enum.AssetKinds.IA)
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END AS AssetTaxClass,
	|	0 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	TableExpenses.Ref AS Ref,
	|	TableExpenses.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	TableExpenses.VATRate AS VATRate,
	|	TableExpenses.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableExpenses.VATAmount AS VATAmount,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0)
	|	END AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0) AS VATAmountMan,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl + Amounts.VATAmountCompl
	|		ELSE ISNULL(Amounts.AmountIncludingVATCompl, 0)
	|	END AS SumCompl,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0)
	|	END AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0) AS VATAmountCompl,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan + Amounts.VATAmountMan
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) 
	|	END AS SumMan,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 
	|	END AS CostTD,
	|	
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGiven, 0) <> 0
	|			THEN Amounts.AmountGiven + TableExpenses.AmountVATARAP
	|		ELSE 
	|			TableExpenses.AmountARAP
	|	END AS AmountARAP,
	|	TableExpenses.AmountVATARAP AS AmountVATARAP,
	|	TableExpenses.RowID AS RowID,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.IDARAPObject,
	|	TableExpenses.ExpenseItem.CostAllocationOptionLocal AS ExpenseItemCostAllocationOptionLocal,
	|	TableExpenses.ExpenseItem.VATAssetTaxClass AS ItemOfExpensesAssetTaxClassVAT
	|INTO TTExpenses
	|FROM
	|	DocumentDataTableExpenses AS TableExpenses
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|	ON TableExpenses.Ref = DocumentData.Ref
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON TableExpenses.Ref = Amounts.Ref
	|	 AND TableExpenses.RowID = Amounts.RowID
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableExpenses.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Expenses""
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTOtherAssetsLiabilities";
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	TableExpenses.Ref AS Ref,
	|	TableExpenses.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.ExpenseItem AS AssetAndLiabilityItem,
	|	TableExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	TableExpenses.VATRate AS VATRate,
	|	TableExpenses.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableExpenses.VATAmount AS VATAmount,
	|	
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)     AS VATAmountMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl + Amounts.VATAmountCompl
	|		ELSE ISNULL(Amounts.AmountIncludingVATCompl, 0) END) AS SumCompl,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)    AS VATAmountCompl,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan + Amounts.VATAmountMan
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) END) AS SumMan,
	|
	|	TableExpenses.AmountARAP AS AmountARAP,
	|	TableExpenses.AmountVATARAP AS AmountVATARAP,
	|	TableExpenses.GLAccountSettings AS GLAccountSettings,
	|	TableExpenses.SettingUpLedgerAccountsLedgerAccount AS GLAccount,
	|	TableExpenses.RowID AS RowID,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.IDARAPObject AS IDARAPObject
	|
	|INTO TTOtherAssetsLiabilities
	|FROM
	|	DocumentDataTableExpenses AS TableExpenses
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON TableExpenses.Ref = DocumentData.Ref
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON TableExpenses.Ref = Amounts.Ref
	|	 AND TableExpenses.RowID = Amounts.RowID
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableExpenses.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Expenses""
	|	
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExpenses", QueryTexts) Then
		QueryTextTableTTExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableExpenses.LineNumber AS LineNumber,
	|	TableExpenses.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableExpenses.VariancePeriod AS VariancePeriod,
	|	TableExpenses.Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	TableExpenses.VATActivityType AS VATActivityType,
	|
	|	TableExpenses.SumMan AS AmountIncludingVAT,
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVATMan,
	|
	|	TableExpenses.SumCompl AS AmountIncludingVATCompl,
	|	TableExpenses.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	TableExpenses.CostTD AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	TableExpenses.RowID AS RowID,
	|	TableExpenses.IDARAPObject AS FinRecordID,
	|	CASE
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE TableExpenses.ItemOfExpensesAssetTaxClassVAT
	|					WHEN VALUE(Enum.AssetKinds.FA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfConstructionObjects)
	|					WHEN VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAndRDReceipt)
	|				END
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN  VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherAssets)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherServices)
	|	END AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTExpenses AS TableExpenses
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExpenses", QueryTexts) Then
		QueryTextTableTTExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableExpenses.LineNumber AS LineNumber,
	|	TableExpenses.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableExpenses.VariancePeriod AS VariancePeriod,
	|	TableExpenses.Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	TableExpenses.ExpenseItem AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TableExpenses.LotVendorAttributes AS LotVendorAttributes,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	TableExpenses.VATActivityType AS VATActivityType,
	|
	|	TableExpenses.SumMan AS Cost,
	|	TableExpenses.AmountExcludingVATMan AS CostExcludingVAT,
	|	TableExpenses.VATAmountMan AS VATManag,
	|	TableExpenses.AmountExcludingVATCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	TableExpenses.CostTD AS CostTD,
	|	TableExpenses.VATAmountCompl AS VATLocal,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	TableExpenses.RowID AS RowID,
	|	TableExpenses.IDARAPObject AS FinRecordID,
	|	CASE
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE TableExpenses.ItemOfExpensesAssetTaxClassVAT
	|					WHEN VALUE(Enum.AssetKinds.FA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfConstructionObjects)
	|					WHEN VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Catalog.BusinessTransactionsSettings.IntangibleAssetsAndRDReceipt)
	|				END
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN  VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherAssets)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherServices)
	|	END AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTExpenses AS TableExpenses
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExpenses", QueryTexts) Then
		QueryTextTableTTExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
	
	QueryText = "
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&Department                         AS Department,
	|	&Currency                                AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	&BusinessOperation                 AS BusinessOperation,
	|	&CashFlowItem         AS CashFlowItem,
	|	SUM(TableExpenses.AmountIncludingVAT)         AS Sum,
	|	CAST(SUM(TableExpenses.AmountIncludingVAT)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(SUM(TableExpenses.AmountIncludingVAT)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	SUM(TableExpenses.AmountIncludingVAT)         AS ToReport,
	|	
	|	TableExpenses.RowID AS FinRecordID,
	|	&BusinessTransactionSetting    AS BusinessTransactionSetting
	|	
	|FROM
	|	TTExpenses AS TableExpenses
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|
	|GROUP BY
	|	TableExpenses.Ref,
	|	TableExpenses.RowID 
	|";
	
	Else
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export

	QueryTextdata_ = "
	|SELECT
	|	""Expenses"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	CASE WHEN DocumentData.DocumentExchangeRateDate <> DATETIME(1, 1, 1)
	|			THEN DocumentData.DocumentExchangeRateDate
	|		ELSE DocumentData.Date 
	|	END AS VATBasePeriod,
	|	CASE WHEN DocumentData.DocumentExchangeRateDate <> DATETIME(1, 1, 1)
	|			THEN DocumentData.DocumentExchangeRateDate
	|		ELSE DocumentData.Date 
	|	END AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	DocumentTable.AmountVATARAP AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	DocumentDataTableExpenses AS DocumentTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON DocumentTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExpenses", QueryTexts) Then
		QueryTextTableTTExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN
	|				CASE TableExpenses.ItemOfExpensesAssetTaxClassVAT
	|					WHEN VALUE(Enum.AssetKinds.FA)
	|						THEN VALUE(Enum.BusinessTransactions.ReceiptOfFixedAssets)
	|					WHEN VALUE(Enum.AssetKinds.ConstructionInProgressObjects)
	|						THEN VALUE(Enum.BusinessTransactions.ReceiptOfConstructionObjects)
	|					WHEN VALUE(Enum.AssetKinds.IA)
	|						THEN VALUE(Enum.BusinessTransactions.IntangibleAssetsAndRDReceipt)
	|				END
	|		WHEN TableExpenses.ExpenseItemCostAllocationOptionLocal = 
	|				VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|			THEN  VALUE(Enum.BusinessTransactions.ReceiptOfOtherAssets)
	|		ELSE VALUE(Enum.BusinessTransactions.ReceiptOfOtherServices)
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	TableExpenses.ARAPObject AS ARAPObject,
	|	
	|	TableExpenses.LineOfBusiness AS LineOfBusinessItems,
	|	TableExpenses.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	TableExpenses.SumMan AS Sum,
	|	TableExpenses.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableExpenses.SumCompl AS SumCompl,
	|	TableExpenses.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	TableExpenses.AmountIncludingVAT AS AmountInCurrency,
	|	TableExpenses.AmountIncludingVAT - TableExpenses.VATAmount AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableExpenses.AmountARAP AS AmountInARAPCurrency,
	|	TableExpenses.AmountARAP - TableExpenses.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|	
	|	TableExpenses.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TableExpenses.IDARAPObject AS FinRecordID
	|FROM
	|	TTExpenses AS TableExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ReceiptOfOtherAssets) AS BusinessOperation,
	|	&Organization AS Organization,
	|	TableOtherAssetsLiabilities.Department AS Department,
	|	
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	TableOtherAssetsLiabilities.ARAPObject AS ARAPObject,
	|	
	|	TableOtherAssetsLiabilities.LineOfBusiness AS LineOfBusinessItems,
	|	TableOtherAssetsLiabilities.AssetAndLiabilityItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	TableOtherAssetsLiabilities.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	TableOtherAssetsLiabilities.SumMan AS Sum,
	|	TableOtherAssetsLiabilities.AmountExcludingVATMan AS AmountExcludingVAT,
	|	TableOtherAssetsLiabilities.SumCompl AS SumCompl,
	|	TableOtherAssetsLiabilities.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	TableOtherAssetsLiabilities.AmountIncludingVAT AS AmountInCurrency,
	|	TableOtherAssetsLiabilities.AmountIncludingVAT - TableOtherAssetsLiabilities.VATAmount AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	TableOtherAssetsLiabilities.AmountARAP AS AmountInARAPCurrency,
	|	TableOtherAssetsLiabilities.AmountARAP - TableOtherAssetsLiabilities.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|	
	|	TableOtherAssetsLiabilities.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	TableOtherAssetsLiabilities.IDARAPObject AS FinRecordID
	|FROM
	|	TTOtherAssetsLiabilities AS TableOtherAssetsLiabilities
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithRecordingAsOtherIncome) AS BusinessOperation,
	|	&Organization AS Organization,
	|	TableExpenses.Department AS Department,
	|	
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	
	|	TableExpenses.LineOfBusiness AS LineOfBusinessItems,
	|	TableExpenses.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	-ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATMan + DocumentAmountsInAccountingCurrency.VATAmountMan, 0) AS Sum,
	|	-ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATMan, 0) AS AmountExcludingVAT,
	|	-ISNULL(DocumentAmountsInAccountingCurrency.AmountIncludingVATCompl, 0) AS SumCompl,
	|	-ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, 0) AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	-(TableExpenses.AmountIncludingVAT) AS AmountInCurrency,
	|	-(TableExpenses.AmountIncludingVAT - TableExpenses.VATAmount) AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	-(TableExpenses.AmountARAP) AS AmountInARAPCurrency,
	|	-(TableExpenses.AmountARAP - TableExpenses.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.IDARAPObject AS FinRecordID
	|FROM
	|	DocumentDataTableExpenses AS TableExpenses
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON TableExpenses.Ref = DocumentData.Ref
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
	|	ON
	|		TableExpenses.Ref = DocumentAmountsInAccountingCurrency.Ref
	|		AND TableExpenses.RowID = DocumentAmountsInAccountingCurrency.RowID
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|"; 

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCashCounterparty(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
	
	QueryText = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(Enum.BusinessTransactions.AdvanceHolderPaymentToVendor) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|
	|	DocumentData.AdvanceHolder AS Cash,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusinessCash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	DocumentData.Currency AS PaymentCurrency,
	|
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForLBCosts THEN
	|			&LineOfBusiness 
	|	END AS CounterpartyLineOfBusiness,
	|	DocumentData.Contract AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	
	|	CAST(DocumentData.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|	CAST(DocumentData.DocumentAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS PaymentAmountLocal,
	|	DocumentData.DocumentAmount AS PaymentAmountPaymentCurrency,
	|
	|	0 AS PostpaymentAmount,
	|	0 AS PostpaymentAmountLocal,
	|	0 AS PaymentAmountInPaymentCurrency,
	|	
	|	0 AS PrepaymentAmountMan,
	|	0 AS PrepaymentAmountLocal,
	|	0 AS PrepaymentAmount,
	|
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|
	|	DocumentData.AmountARAP AS PaymentAmountInTheSettlementCurrency,
	|	0 AS PostPaymentAmountInARAPCurrency,
	|	0 AS PrepaymentAmountInARAPCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	UNDEFINED AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|";
	
	Else
		Return "";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	OtherAssetsLiabilities.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	OtherAssetsLiabilities.Organization AS Organization,
	|	OtherAssetsLiabilities.Department AS Department,
	|	OtherAssetsLiabilities.LineOfBusiness AS LineOfBusiness,
	|	OtherAssetsLiabilities.AssetAndLiabilityItem AS AssetRef,
	|	CASE
	|		WHEN OtherAssetsLiabilities.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE OtherAssetsLiabilities.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	OtherAssetsLiabilities.SumMan AS Sum
	|FROM
	|	TTOtherAssetsLiabilities AS OtherAssetsLiabilities
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTRegisteredRecordsInOtherAssetsLiabilities";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialRegisteredRecordsOnOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRegisteredRecordsInOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTRegisteredRecordsInOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.QueryTextTableOtherAssetsAndLiabilitiesRecords();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialRegisteredRecordsOnOtherAssetsLiabilities(Query, QueryTexts)
	
	RegisterName = "TTInitialRegisteredRecordsOnOtherAssetsLiabilities";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherAssetsLiabilities", QueryTexts) Then
		QueryTextTableTTOtherAssetsLiabilities(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	OtherAssetsLiabilities.Period AS Period,
	|	OtherAssetsLiabilities.Organization AS Organization,
	|	OtherAssetsLiabilities.Department AS Department,
	|	OtherAssetsLiabilities.LineOfBusiness AS LineOfBusiness,
	|	OtherAssetsLiabilities.AssetAndLiabilityItem AS AssetRef,
	|	OtherAssetsLiabilities.AssetsLiabilitiesDimension AS Dimension,
	|	OtherAssetsLiabilities.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	OtherAssetsLiabilities.VATActivityType AS VATActivityType,
	|
	|	OtherAssetsLiabilities.SumCompl AS SumCompl,
	|	OtherAssetsLiabilities.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	OtherAssetsLiabilities.SumMan AS SumMan,
	|	OtherAssetsLiabilities.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	OtherAssetsLiabilities.SumMan AS AmountIncludingVAT,
	|	OtherAssetsLiabilities.AmountExcludingVATMan AS AmountExcludingVAT,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	OtherAssetsLiabilities.RowID,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN OtherAssetsLiabilities.RowID
	|		ELSE OtherAssetsLiabilities.IDARAPObject
	|	END AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfOtherAssets) AS BusinessTransactionSetting
	|INTO TTInitialRegisteredRecordsOnOtherAssetsLiabilities
	|FROM
	|	TTOtherAssetsLiabilities AS OtherAssetsLiabilities
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers, DocumentObject)
	
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
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
	
	Query.SetParameter("TypesOfTaxationVATIsIncludedInCost",
		VATAccountingERP.ActivitiesVATIsIncludedInCost());
		
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableExpenses.Department AS Department,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	TableExpenses.ExpenseItem AS IncomeItem,
	|	TableExpenses.DimensionOfRevenue AS DimensionOfRevenue,
	|	- ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATMan + DocumentAmountsInAccountingCurrency.VATAmountMan, 0) AS Sum,
	|	- CASE 
	|		WHEN DocumentData.PurchaseForActivity IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl + DocumentAmountsInAccountingCurrency.VATAmountCompl, 0)
	|		ELSE ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, 0)
	|	END AS SumCompl,
	|	- CASE 
	|		WHEN DocumentData.PurchaseForActivity IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATMan + DocumentAmountsInAccountingCurrency.VATAmountMan, 0)
	|		ELSE ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATMan, 0)
	|	END AS SumMan,
	|	VALUE(Enum.BusinessTransactions.DebitNoteWithRecordingAsOtherIncome) AS BusinessOperation,
	|	DocumentData.IDARAPObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.DebitNoteWithRecordingAsOtherIncome) AS BusinessTransactionSetting
	|FROM
	|	DocumentDataTableExpenses AS TableExpenses
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON TableExpenses.Ref = DocumentData.Ref
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
	|	ON
	|		TableExpenses.Ref = DocumentAmountsInAccountingCurrency.Ref
	|		AND TableExpenses.RowID = DocumentAmountsInAccountingCurrency.RowID
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND VALUETYPE(TableExpenses.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers, DocumentObject)
	
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
	|	FATable.Department                 AS Department,
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Posted                               AS Posted,
	|	FATable.DimensionOfExpenses             AS FixedAsset,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	TRUE                                  AS RecordInTA
	|
	|FROM
	|	DocumentDataTableExpenses AS FATable
	|
	|		LEFT JOIN DocumentDataTableExpenses AS DoublesTable
	|		ON DoublesTable.Ref = FATable.Ref
	|			AND DoublesTable.DimensionOfExpenses = FATable.DimensionOfExpenses
	|			AND DoublesTable.LineNumber < FATable.LineNumber
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
	|	AND DoublesTable.Ref IS NULL
	|";
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableExpenses", "Document.VendorInvoiceServicesAndAssets.Expenses");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers, DocumentObject)
	
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
	|	TableOfIA.Department                AS Department,
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Posted                               AS Posted,
	|	TableOfIA.DimensionOfExpenses            AS IntangibleAsset,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	TRUE                                  AS RecordInTA
	|
	|FROM
	|	DocumentDataTableExpenses AS TableOfIA
	|
	|		LEFT JOIN DocumentDataTableExpenses AS DoublesTable
	|		ON DoublesTable.Ref = TableOfIA.Ref
	|			AND DoublesTable.DimensionOfExpenses = TableOfIA.DimensionOfExpenses
	|			AND DoublesTable.LineNumber < TableOfIA.LineNumber
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
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableExpenses", "Document.VendorInvoiceServicesAndAssets.Expenses");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
																			 Query.Parameters.ARAPCurrency,
																			 Query.Parameters.Period,
																			 Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	DocumentData.Date AS Period,
	|	Expenses.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Counterparty AS Shipper,
	|	Expenses.Ref AS DocumentAcquisitions,
	|	Expenses.Ref AS OriginalTradeDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS ReduceAmountVATDeduction,
	|	UNDEFINED AS PurchaseAdjustmentDocument,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.PurchaseForActivity AS VATActivityType,
	|	Expenses.VATRate AS VATRate,
	|	UNDEFINED AS Products,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|	UNDEFINED AS CCDNumber,
	|	Expenses.Department AS AccountingDivision,
	|	Expenses.LineOfBusiness AS LineOfBusiness,
	|	FALSE AS PurchasePerBatchOfProduction,
	|	UNDEFINED AS LineOfBusinessOfProductionParty,
	|	UNDEFINED AS ToExpenseAs,
	|	Expenses.ExpenseItem AS ExpenseItem,
	|	Expenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	Expenses.ExpenseItem AS ItemOfOtherAssets,
	|	Expenses.AssetsLiabilitiesDimension AS AnalyticsOfOtherAssets,
	|	UNDEFINED AS Purpose,
	|	Expenses.RowID AS RowID,
	|	DocumentData.IDARAPObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	DocumentDataTableExpenses AS Expenses
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON Expenses.Ref = DocumentData.Ref
	|WHERE
	|	Expenses.Ref IN (&Ref)
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN DocumentDataHeader.DocumentExchangeRateDate = DATETIME(1, 1, 1)
		|			THEN DocumentDataHeader.Date
		|		ELSE DocumentDataHeader.DocumentExchangeRateDate
		|	END AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	CASE
		|		WHEN DocumentDataHeader.DocumentExchangeRateDate = DATETIME(1, 1, 1)
		|			THEN DocumentDataHeader.Date
		|		ELSE DocumentDataHeader.DocumentExchangeRateDate
		|	END AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                                         AS Ref,
		|	Table.Organization                                                    AS Organization,
		|	Table.Partner                                                        AS Partner,
		|	Table.Date                                                           AS RecorderDate,
		|	Table.Number                                                          AS RecorderNumber,
		|	Table.Contract                                                        AS Contract,
		|	
		|	Table.ARAPObject                                                 AS ARAPObject,
		|	Table.PaymentDate                                                    AS PaymentDate,
		|	UNDEFINED                                                           AS PaymentOption,
		|	UNDEFINED                                                           AS PurchaseOrder_,
		|	Table.DocumentAmount                                                 AS Sum,
		|	Table.AmountARAP                                            AS AmountARAP,
		|	0                                                                      AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings                                                AS ARAPObjectSettings,
		|	FALSE                                                                   AS InvoiceForOrders,
		|	Table.ARAPCurrency                                           AS ARAPCurrency,
		|	Table.BusinessOperation                                          AS BusinessOperation,
		|	Table.PaymentMethod                                                    AS PaymentMethod,
		|	Table.Currency                                                         AS DocumentCurrency,
		|	CASE
		|		WHEN Table.DocumentExchangeRateDate = DATETIME(1,1,1)
		|			THEN Table.Date
		|		ELSE Table.DocumentExchangeRateDate
		|	END                                                                  AS DateOfCourse,
		|	UNDEFINED                                                           AS LinkedDocument
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)";
	
	Else
		TextPurchase = "";
	EndIf;
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                         AS Ref,
		|	Table.Organization                                             	   AS Organization,
		|	Table.Partner                                                 	   AS Partner,
		|	Table.Date                                                           AS RecorderDate,
		|	Table.Number                                                          AS RecorderNumber,
		|	Table.PaymentDate                                                    AS PaymentDate,
		|	Table.Contract                                                        AS Contract,
		|	
		|	Table.ARAPObject                                                 AS ARAPObject,
		|	Table.ARAPObjectSettings                                                AS ARAPObjectSettings,
		|	FALSE                                                                   AS InvoiceForOrders,
		|	FALSE                                                                   AS ExceedingOrder,
		|	VALUE(Document.PurchaseOrder.EmptyRef)                        AS PurchaseOrder_,
		|	Table.AmountARAP                                            AS AmountDue,
		|	Table.ARAPCurrency                                           AS ARAPCurrency,
		|	Table.BusinessOperation                                          AS BusinessOperation,
		|	Table.PaymentMethod                                                    AS PaymentMethod,
		|	Table.Currency                                                         AS DocumentCurrency,
		|	UNDEFINED                                                           AS PaymentOption,
		|	UNDEFINED                                                           AS LinkedDocument
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|	AND Table.Ref IN (&Ref)";
	
	Else
		TextPaymentPlan_ = "";
	EndIf;
	
	#EndRegion
	
	#Region TextProducts_1
	
	If DocumentObject = Undefined
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
	
	TextProducts_1 = "
		|SELECT
		|	Table.Ref                                  AS Ref,
		|	Table.Organization                             AS Organization,
		|	Table.Partner                                 AS Partner,
		|	Table.Date                                    AS RecorderDate,
		|	Table.Number                                   AS RecorderNumber,
		|	
		|	Table.ARAPObject                          AS ARAPObject,
		|	Table.ARAPObjectSettings                         AS ARAPObjectSettings,
		|	FALSE                                            AS InvoiceForOrders,
		|	FALSE                                            AS ExceedingOrder,
		|	VALUE(Document.PurchaseOrder.EmptyRef) AS PurchaseOrder_,
		|	Table.AmountARAP                     AS IncreaseToAdmission,
		|	Table.AmountARAP                     AS ReduceToAdmission,
		|	Table.AmountARAP                     AS AmountARAP,
		|	Table.ARAPCurrency                    AS ARAPCurrency,
		|	Table.BusinessOperation                   AS BusinessOperation,
		|	Table.Currency                                  AS DocumentCurrency
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|	AND Table.Ref IN (&Ref)
		|";
	
	Else
		TextPaymentPlan_ = "";
	EndIf;
	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	DocumentData.Organization                                              AS Organization,
		|	DocumentData.Partner                                                  AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	DocumentData.ARAPObject                                           AS CalculationObjectReceiver,
		|
		|	DocumentData.ARAPCurrency                                     AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	DocumentData.Currency                                                   AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	DocumentData.Date                                                     AS RecorderDate,
		|	DocumentData.Contract                                                  AS Contract,
		|	CASE
		|		WHEN DocumentData.DocumentExchangeRateDate = DATETIME(1,1,1)
		|			THEN DocumentData.Date
		|		ELSE DocumentData.DocumentExchangeRateDate
		|	END                                                                    AS DateOfCourse,
		|	DocumentData.Number                                                    AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|			ON Table.Ref = DocumentData.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	#EndRegion

	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset, TextProducts_1);
	
EndProcedure

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	VendorInvoiceServicesAndAssetsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
		
	VendorInvoiceServicesAndAssetsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

#EndRegion

#Region Posting

#EndRegion

#EndRegion

#EndIf
