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
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	ReturnablePackagingRedemptionByCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReturnablePackagingRedemptionByCustomer") Then
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
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		ReturnablePackagingRedemptionByCustomerLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
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
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	ReturnablePackagingRedemptionByCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "customer Repurchase of returnable containers".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.ReturnablePackagingRedemptionByCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReturnablePackagingRedemptionByCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReturnablePackagingRedemptionByCustomer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseReusablePackage";
	

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
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingProvided.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReturnablePackagingRedemptionByCustomerLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
//	DocumentRef - DocumentRef - Link to the document.
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
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
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
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
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
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
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
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("ByOrder", False);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.ReturnablePackagingRedemptionByCustomer - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	
	FillParameters.ReturnablePackagingRedemptionByCustomer = True;
	
	Return FillParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                    = True;
	ParametersStructure.PaymentType_                          = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage            = "";
	
	ParametersStructure.CourseNumerator                        = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                      = "Object.CourseDenominator";
	ParametersStructure.CashAccount                                = "Object.CashAccount";
	ParametersStructure.PaymentID                 = "Object.PaymentID";
	
	ParametersStructure.PathToTSData                        = "Object.Goods";
	ParametersStructure.PropsNameTSOrder                  = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption      = "Object.ARAPDetails";
	
	ParametersStructure.Manager                             = "Object.Manager";
	ParametersStructure.InvoiceForOrders                   = "";
	ParametersStructure.OrderBase                       = "";
	ParametersStructure.PaymentSchedule                         = "Object.PaymentSchedule";
	
	ParametersStructure.PaymentDate                          = "Object.PaymentDate";
	
	ParametersStructure.FormItems.LabelCurrencies          = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages           = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations         = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement            = "PaymentSettlement";
	ParametersStructure.FormItems.AmountOfTSSettlements  = "GoodsAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.PathToTSDataPaymentSteps             = "";
	ParametersStructure.PaymentStepsText                   = "Form.PaymentStepsText";
	ParametersStructure.DocumentAmountForm                  = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm               = "";
	ParametersStructure.PaymentStagesViewOnly            = False;
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = False;
	
	ParametersStructure.ARAPObject                       = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

#Region BasisForPrint

// Returns the base structure based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReturnablePackagingRedemptionByCustomer - 
//		The object of the document that you need to get the base text from.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function StructureOfBaseForPrinting(Object) Export
	
	BaseStructure = BaseStructure(Object);
	
	Return BaseStructure;
	
EndFunction

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReturnablePackagingRedemptionByCustomer - 
//		The document object to get the selection list from.
//
// Returns:
//	ValueTable - A list of variants of the base texts.
//
Function PrintBasisTable(Object) Export
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	If ValueIsFilled(Object.Contract) Then
		
		BaseStructure = BaseStructure(Object);
		
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		
	EndIf;
	
	Return TableOfBases_;
	
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
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Partner)";

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

#Region VATAccounting

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.ReturnablePackagingRedemptionByCustomer, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref					= Object.Ref;
	RegistrationParameters.Date					= Object.Date;
	RegistrationParameters.Organization			= Object.Organization;
	RegistrationParameters.Counterparty				= Object.Counterparty;
	RegistrationParameters.VATTaxation		= Object.VATTaxation;
	
	RegistrationParameters.GoodsSales = True;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms, Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
EndProcedure

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
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.Department           AS Department,
	|	DocumentData.PriceIncludesVAT         AS PriceIncludesVAT,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.PaymentMethod             AS PaymentMethod,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.VATTaxation      AS VATTaxation,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.DepositForPackageIsRequired AS DepositForPackageIsRequired,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.ReferenceDocumentDateForPrintForms           AS ReferenceDocumentDateForPrintForms,
	|	DocumentData.BaseDocumentNumber          AS BaseDocumentNumber,
	|	DocumentData.CourseNumerator AS   Rate,
	|	DocumentData.CourseDenominator  AS Repetition,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Attributes.Currency, Attributes.ARAPCurrency, Attributes.Period, Attributes.Organization);
	
	Query.SetParameter("Period",                                   Attributes.Period);
	Query.SetParameter("Number",                                    Attributes.Number);
	Query.SetParameter("BeginningOfMonthOfPeriod",                      BegOfMonth(Attributes.Period));
	Query.SetParameter("Currency",                                   Attributes.Currency);
	Query.SetParameter("Organization",                              Attributes.Organization);
	Query.SetParameter("Partner",                                  Attributes.Partner);
	Query.SetParameter("Counterparty",                               Attributes.Counterparty);
	Query.SetParameter("PriceIncludesVAT",                          ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("Department",                            Attributes.Department);
	Query.SetParameter("LineOfBusiness",                  Attributes.LineOfBusiness);
	Query.SetParameter("ARAPCurrency",                     Attributes.ARAPCurrency);
	Query.SetParameter("Terms",                               Attributes.Terms);
	Query.SetParameter("AccountingDimensionByPartners",                InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Attributes));
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("PaymentMethod",                              Attributes.PaymentMethod);
	Query.SetParameter("Contract",                                  Attributes.Contract);
	Query.SetParameter("VATTaxation",                       Attributes.VATTaxation);
	Query.SetParameter("LocalAccountingCurrency",           Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",               Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("Manager",                                 Attributes.Manager);
	Query.SetParameter("DepositForPackageIsRequired",                  Attributes.DepositForPackageIsRequired);
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses",    GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("ARAPObject",                           Attributes.ARAPObject);  
	Query.SetParameter("IDARAPObject",             Attributes.IDARAPObject);
	Query.SetParameter("BusinessOperation",                    Enums.BusinessTransactions.SaleToCustomer);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",          Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	Query.SetParameter("MetadataIdentifier",                  Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("BusinessOperation",                    Enums.BusinessTransactions.SaleToCustomer);
	Query.SetParameter("Comment",                              Attributes.Comment);
	Query.SetParameter("DocumentAmount",                           Attributes.DocumentAmount);
	Query.SetParameter("Posted",                                 Attributes.Posted);
	Query.SetParameter("DeletionMark",                          Attributes.DeletionMark);
	Query.SetParameter("BaseDocumentNumber",                           Attributes.BaseDocumentNumber);
	Query.SetParameter("ReferenceDocumentDateForPrintForms",                            Attributes.ReferenceDocumentDateForPrintForms);
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		ContractInformation = NStr("vi = 'Theo hợp đồng ""%Contract%""';
									|ru = 'По договору ""%Contract%""';
									|en = 'Under the ""%Contract%"" contract'; fa = 'Under the ""%Contract%"" contract';
									|it = 'In base al contratto ""%Contract%""';
									|pl = 'Według umowy ""%Contract%""';
									|tr = '""%Contract%"" sözleşmesi kapsamında'", CommonClientServer.DefaultLanguageCode());
		ContractInformation = StrReplace(ContractInformation, "%Contract%", Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	ComplianceOfTypesOfStocks = InitializeInventoryTypes(Attributes);
	Query.SetParameter("ComplianceOfTypesOfStocks", ComplianceOfTypesOfStocks);
	
	AccountingAnalyticsForManPartners = Undefined;
	Query.SetParameter("AccountingAnalyticsForManPartners", AccountingAnalyticsForManPartners);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function InitializeInventoryTypes(Attributes)
	
	ComplianceOfTypesOfStocks = New ValueTable;
	ComplianceOfTypesOfStocks.Columns.Add("InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds")); 
	ComplianceOfTypesOfStocks.Columns.Add("New_KindOfInventory", New TypeDescription("CatalogRef.InventoryKinds")); 
	
	Return ComplianceOfTypesOfStocks;

EndFunction

Function QueryTextTableTransferredReturnablePackaging(Query, QueryTexts, Registers)
	RegisterName = "TransferredReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	TTTableTypesOfStocks.LineNumber         AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)   AS RecordType,
	|	&Period                                  AS Period,
	|	TTTableTypesOfStocks.Products        AS Products,
	|	TTTableTypesOfStocks.Characteristic      AS Characteristic,
	|	TTTableTypesOfStocks.Count          AS Count,
	|	TTTableTypesOfStocks.QuantityByGBRN    AS QuantityByGBRN,
	|	TTTableTypesOfStocks.AmountIncludingVAT           AS Sum,
	|	CASE WHEN TTTableTypesOfStocks.InventoryOwnerAttributeShipment <> VALUE(Catalog.InventoryKinds.EmptyRef) THEN
	|		TTTableTypesOfStocks.InventoryOwnerAttributeShipment
	|	ELSE
	|		TTTableTypesOfStocks.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TTTableTypesOfStocks.CCDNumber            AS CCDNumber,
	|	&Partner                                 AS Partner,
	|	TTTableTypesOfStocks.DocumentSalesOfGoodsAndServices  AS DocumentTransfers_,
	|	&DepositForPackageIsRequired                 AS DepositIsRequired,
	|	TRUE                                   AS Buyout,
	|	
	|	&IDARAPObject            AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReturnablePackagingRedemptionByCustomer) AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableTypesOfStocks AS TTTableTypesOfStocks
	|WHERE
	|	TTTableTypesOfStocks.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks"; 
	
	// A temporary table of VTTABLES with columns in the currencies of upr, regl and mutual settlements.
	QueryText = "
	|
	|SELECT
	|	InventoryKinds.LineNumber                  AS LineNumber,
	|	InventoryKinds.Ref                       AS Ref,
	|	&Organization                             AS Organization,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType        AS InventoryType,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.Count                   AS Count,
	|	InventoryKinds.QuantityByGBRN             AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	InventoryKinds.CCDNumber                     AS CCDNumber,
	|	InventoryKinds.OriginWarehouse                AS OriginWarehouse,
	|	InventoryKinds.InventoryOwnerAttributeShipment           AS InventoryOwnerAttributeShipment,
	|	InventoryKinds.DocumentSalesOfGoodsAndServices.Date      AS SalePeriod,
	|	CASE WHEN InventoryKinds.DocumentSalesOfGoodsAndServices = VALUE(Document.CustomerInvoice.EmptyRef) THEN
	|		UNDEFINED
	|	ELSE
	|		InventoryKinds.DocumentSalesOfGoodsAndServices
	|	END AS DocumentSalesOfGoodsAndServices,
	|	ISNULL(InventoryKinds.DocumentSalesOfGoodsAndServices.SalesOrder, UNDEFINED) AS OrderingImplementation,
	|	ISNULL(
	|		InventoryKinds.DocumentSalesOfGoodsAndServices.Department,
	|		&Department
	|	) AS ImplementationDivision,
	|	CAST(InventoryKinds.AmountIncludingVAT
	|	 * &ConversionRateToManCurrency
	|		AS NUMBER(31,2))                     AS AmountIncludingVATMan,
	|	CAST((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount)
	|	 * &ConversionRateToManCurrency
	|		AS NUMBER(31,2))                     AS AmountExcludingVATMan,
	|
	|	CAST((InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount)
	|	 * &FactorOfConversionToCurrencyOfRegul
	|		AS NUMBER(31,2))                     AS AmountExcludingVATCompl
	|
	|INTO TTTableTypesOfStocks
	|
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ReturnablePackagingRedemptionByCustomer) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&ARAPObject AS ARAPObject,
	|	
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATAccruedOnRepurchaseOfReusablePackage) AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	&Partner AS DimensionOfExpenses,
	|	
	|	SUM(CAST(GoodsTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))) AS Sum,
	|	0 AS AmountExcludingVAT,
	|	SUM(CAST(GoodsTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	SUM(GoodsTable.VATAmount) AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(CASE WHEN GoodsTable.AmountIncludingVAT <> 0 THEN
	|			CAST(GoodsTable.AmountARAP * GoodsTable.VATAmount / GoodsTable.AmountIncludingVAT AS NUMBER(31,2))
	|		ELSE
	|			0
	|		END) AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	&IDARAPObject AS FinRecordID
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|HAVING
	|	SUM(GoodsTable.VATAmount) > 0
	|"; 
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	InventoryKinds.Ref.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	InventoryKinds.Ref.Counterparty AS Counterparty,
	|	InventoryKinds.Ref.Contract AS Contract,
	|	InventoryKinds.Ref.Shipper AS Shipper,
	|	InventoryKinds.Ref.GoodsRecipient AS GoodsRecipient,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Department AS Department,
	|	UNDEFINED AS ConsignedGoodsCustomer,
	|	FALSE AS SalesViaCommissionAgent,
	|	InventoryKinds.Ref AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ImplementationAdjustmentDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS RetailSaleOfGoods,
	|	InventoryKinds.Ref.ARAPObject AS ARAPObject,
	|	InventoryKinds.Ref.VATTaxation AS VATTaxation,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	"""" AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryKinds.Count
	|		ELSE InventoryKinds.NumberOfPackages
	|	END AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryKinds.ItemsLocationAttributes.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END AS UnitOfMeasure,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	0 AS ExciseTaxAmount,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	UNDEFINED AS FEACNCode,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|	&IDARAPObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|";
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryKinds.Package",
			"InventoryKinds.ItemsLocationAttributes.Products"));
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses();
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATAccruedOnRepurchaseOfReusablePackage) AS ExpenseItem,
	|	&Partner AS DimensionOfExpenses,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	// In management accounting, THE VAT Amount is NOT reflected in expenses, because there is no correspondence for this amount in THE Man's BALANCE SHEET.
	// In THE Local ACCOUNTING and in THE Man ACCOUNTING of ORGANIZATIONS, THE VAT Amount is reflected in expenses and corresponds to the register of "VAT movements". 
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	SUM(CAST(GoodsTable.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2))) AS AmountExcludingVATMan,
	|	SUM(CAST(GoodsTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS AmountIncludingVATCompl,
	|	SUM(CAST(GoodsTable.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	&IDARAPObject AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.VATOnAcquiredAssetsWriteOff) AS BusinessTransactionSetting
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|HAVING
	|	SUM(GoodsTable.VATAmount) > 0
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
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

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ReturnablePackagingRedemptionByCustomerLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReturnablePackagingRedemptionByCustomerLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer.ARAPDetails AS Table
		|		LEFT JOIN Document.ReturnablePackagingRedemptionByCustomer AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Sale
	
	TextSale = "
		|SELECT
		|	Table.Ref     	                                               		 AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.PaymentDate                                           	 AS PaymentDate,
		|	NULL		                                                       		 AS SalesOrder_,
		|	FALSE							                                   		 AS InvoiceForOrders,
		|	Table.AmountARAP    	            			           		 AS AmountARAP,
		|	0                                                                  		 AS AmountARAPByPackage,
		|	Table.AmountIncludingVAT										  	   			 AS Sum,
		|	
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.SaleToCustomer)     		 AS BusinessOperation,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Currency                                             	   	 AS DocumentCurrency,
		|	NULL				                                               		 AS PaymentOption,
		|	FALSE			                                                   		 AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.DepositForPackageIsRequired";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT 
		|	Table.Ref                                                    		 AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.Ref.ARAPObject                                            AS ARAPObject,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SaleToCustomer)     		 AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate                                               AS PaymentDate,
		|	NULL				                                               		 AS PaymentOption,
		|	Table.AmountARAP		    				           			 AS AmountDue,
		|	TRUE														       		 AS ExcludeDuringControl,
		|	FALSE							                                   		 AS InvoiceForOrders,
		|	NULL  		                                                       		 AS SalesOrder_,
		|	FALSE			                                                         AS ExceedingOrder,
		|	UNDEFINED                                                             AS LinkedDocument
		|	
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.DepositForPackageIsRequired";
	
	#EndRegion
		
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum				                                             AS Sum,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)			     AS BusinessOperation
		|	
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.Ref.DepositForPackageIsRequired
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If Users.IsFullUser() Then
		// Repurchase of returnable containers
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Invoice";
		PrintCommand.Presentation = NStr("vi = 'Mua lại bao bì luân chuyển';
										|ru = 'Выкуп возвратной тары';
										|en = 'Customer invoice — returnable packaging'; fa = 'فاکتور مشتری — بسته‌بندی برگشتی';
										|it = 'Riscatto dell''imballaggio riutilizzabile';
										|pl = 'Wykup tary zwrotnej';
										|tr = 'İade ambalajların itfası'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Mua lại bao bì luân chuyển';
												|ru = 'Выкуп возвратной тары';
												|en = 'Customer invoice — returnable packaging'; fa = 'فاکتور مشتری — بسته‌بندی برگشتی';
												|it = 'Riscatto dell''imballaggio riutilizzabile';
												|pl = 'Wykup tary zwrotnej';
												|tr = 'İade ambalajların itfası'");
	EndIf;

	If Users.IsFullUser() Then
		// Register of GTD numbers
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CCDNumberRegistry";
		PrintCommand.Presentation = NStr("vi = 'Số đăng ký tờ khai hải quan';
										|ru = 'Реестр номеров ГТД';
										|en = 'CCD number registry'; fa = 'دفتر ثبت شماره‌های CCD';
										|it = 'Registro numeri delle dichiarazioni doganali di carico';
										|pl = 'Wykaz numerów towarowej deklaracji celnej';
										|tr = 'Gümrük beyanname numaralarının kaydı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.FunctionalOptions = "UseImportedGoods";
	EndIf;
	
	If Users.IsFullUser() And Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Commercial invoice';
										|ru = 'Commercial invoice';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Commercial invoice';
										|pl = 'Commercial invoice';
										|tr = 'Commercial invoice'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;
	
	ReturnablePackagingRedemptionByCustomerLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Invoice", NStr("vi = 'Mua lại bao bì luân chuyển';
																									|ru = 'Выкуп возвратной тары';
																									|en = 'Customer invoice — returnable packaging'; fa = 'فاکتور مشتری — بسته‌بندی برگشتی';
																									|it = 'Riscatto dell''imballaggio riutilizzabile';
																									|pl = 'Wykup tary zwrotnej';
																									|tr = 'İade ambalajların itfası'"), FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CCDNumberRegistry") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CCDNumberRegistry", NStr("vi = 'Số đăng ký tờ khai hải quan';
																												|ru = 'Реестр номеров ГТД';
																												|en = 'CCD number registry'; fa = 'دفتر ثبت شماره‌های CCD';
																												|it = 'Registro numeri delle dichiarazioni doganali di carico';
																												|pl = 'Wykaz numerów towarowej deklaracji celnej';
																												|tr = 'Gümrük beyanname numaralarının kaydı'"), FormPrintedFormRegisterOfCCDNumbers(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	ReturnablePackagingRedemptionByCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else

		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.ReturnablePackagingRedemptionByCustomer.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"Invoice");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormInvoice(PrintKit.Objects, PrintObjects));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CCDNumberRegistry");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			FormPrintedFormRegisterOfCCDNumbers(PrintKit.Objects, PrintObjects));
	EndDo;

	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceInt");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.ReturnablePackagingRedemptionByCustomer", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	ReturnablePackagingRedemptionByCustomerLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.ReturnablePackagingRedemptionByCustomer",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "Invoice", NStr("vi = 'Giao hàng';
																								|ru = 'Реализация товаров';
																								|en = 'Goods sales'; fa = 'فروش کالا';
																								|it = 'Vendita delle merci';
																								|pl = 'Sprzedaż towarów';
																								|tr = 'Ürünlerin satışı'"), 0);
	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceInt", NStr("vi = 'Invoice';
																										|ru = 'Invoice';
																										|en = 'Invoice'; fa = 'فاکتور';
																										|it = 'Invoice';
																										|pl = 'Invoice';
																										|tr = 'Invoice'"), 2);
	EndIf;
	ReturnablePackagingRedemptionByCustomerLocalization.PrintFormsSet(PrintFormsSet);
	Return PrintFormsSet;
	
EndFunction

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	QueryText =
	"SELECT
	|	ReturnablePackagingRedemptionByCustomer.Ref AS Ref,
	|	ReturnablePackagingRedemptionByCustomer.Number AS Number,
	|	ReturnablePackagingRedemptionByCustomer.Date AS Date,
	|	ReturnablePackagingRedemptionByCustomer.Partner AS Partner,
	|	ReturnablePackagingRedemptionByCustomer.Counterparty AS Recipient,
	|	ReturnablePackagingRedemptionByCustomer.Organization AS Organization,
	|	ReturnablePackagingRedemptionByCustomer.Organization.Prefix AS Prefix,
	|	ReturnablePackagingRedemptionByCustomer.Currency AS Currency,
	|	ReturnablePackagingRedemptionByCustomer.PriceIncludesVAT AS PriceIncludesVAT,
	|	CASE
	|		WHEN ReturnablePackagingRedemptionByCustomer.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR ReturnablePackagingRedemptionByCustomer.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	ReturnablePackagingRedemptionByCustomer.IssuiedBy AS VacationProduced
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS ReturnablePackagingRedemptionByCustomer
	|WHERE
	|	ReturnablePackagingRedemptionByCustomer.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductNameFull_,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Description AS UnitPrice,
	|	NestedQuery.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.VATRate AS VATRate,
	|	NestedQuery.Price AS Price,
	|	NestedQuery.Count AS Count,
	|	NestedQuery.Sum AS Sum,
	|	NestedQuery.VATAmount AS VATAmount,
	|	NestedQuery.LineNumber AS LineNumber
	|FROM
	|	(SELECT
	|		ReturnablePackagingRedemptionByCustomer.Ref AS Ref,
	|		ReturnablePackagingRedemptionByCustomer.Products AS Products,
	|		CASE
	|			WHEN ReturnablePackagingRedemptionByCustomer.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|		&QueryTextUnitOfMeasure AS UnitOfMeasure,
	|		ReturnablePackagingRedemptionByCustomer.Characteristic AS Characteristic,
	|		ReturnablePackagingRedemptionByCustomer.Package AS Package,
	|		ReturnablePackagingRedemptionByCustomer.VATRate AS VATRate,
	|		ReturnablePackagingRedemptionByCustomer.Price AS Price,
	|		ReturnablePackagingRedemptionByCustomer.NumberOfPackages AS Count,
	|		ReturnablePackagingRedemptionByCustomer.Sum AS Sum,
	|		ReturnablePackagingRedemptionByCustomer.VATAmount AS VATAmount,
	|		ReturnablePackagingRedemptionByCustomer.LineNumber AS LineNumber
	|	FROM
	|		Document.ReturnablePackagingRedemptionByCustomer.Goods AS ReturnablePackagingRedemptionByCustomer
	|	WHERE
	|		ReturnablePackagingRedemptionByCustomer.Ref IN(&DocumentsArray)
	|		AND ReturnablePackagingRedemptionByCustomer.Products.ItemsType  IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
		
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ReturnablePackagingRedemptionByCustomer.Package",
			"ReturnablePackagingRedemptionByCustomer.Products"));
			
	QueryText = StrReplace(QueryText,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"ReturnablePackagingRedemptionByCustomer.Package",
			"ReturnablePackagingRedemptionByCustomer.Products"));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentsArray", ObjectsArray);

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReturnablePackagingRedemptionByCustomer_Invoice";
	
	ResultsArray 		= Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	ShowVAT = Constants.DisplayAdditionalVATColumns.Get();
	
	FirstDocument = True;
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there are only services in the invoice, let's move on to the next document
		
		If FollowingIsFound Then
			ProductSelection_1 = SelectionByDocuments.Select();
			ThereIsVAT = PrintData.ConsiderVAT;
			ProductSelection_1.Reset();
		Else
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in hóa đơn';
					|ru = 'В документе %1 отсутствуют товары. Печать накладной не требуется';
					|en = 'Goods are missing in document %1. Printing of the invoice is not required'; fa = 'Goods are missing in document %1. Printing of the invoice is not required';
					|it = 'Il documento %1 non contiene le merci. La stampa della bolla non è richiesta';
					|pl = 'Brak towarów w dokumencie %1. Nie jest potrzebne drukowanie zlecenia.';
					|tr = '%1 belgesinde mal bulunmamaktadır. İrsaliyenin yazdırılmasına gerek yoktur'"),
				PrintData.Ref);
				
			CommonClientServer.MessageToUser(
				Text,
				PrintData.Ref);
			Continue;
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.CustomerInvoice.PF_MXL_GoodsSales");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Mua lại bao bì luân chuyển';
																												|ru = 'Выкуп возвратной тары';
																												|en = 'Customer invoice — returnable packaging'; fa = 'فاکتور مشتری — بسته‌بندی برگشتی';
																												|it = 'Riscatto dell''imballaggio riutilizzabile';
																												|pl = 'Wykup tary zwrotnej';
																												|tr = 'İade ambalajların itfası'", Common.DefaultLanguageCode())));
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("TitleUnderscore");
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Organization);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Recipient);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		
		ThereAreDiscounts = False;
		NamesOfLineAreas = NamesOfLineAreas(ThereAreDiscounts, ThereIsVAT And ShowVAT);
		ColumnAreaNames = ColumnAreaNames(ThereAreDiscounts, ThereIsVAT And ShowVAT);
		
		ProductColumnArea = Template.Area("FirstColumnOfGoods");
		ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth
			+ ?(OutputCodes, 0, Template.Area("ColumnOfCodes").ColumnWidth)
			+ 15; // Increasing the width to the right border
		
		RoomArea  = Template.GetArea(NamesOfLineAreas.TableHeader + "|LineNumber");
		AreaCodes   = Template.GetArea(NamesOfLineAreas.TableHeader + "|ColumnOfCodes");
		ProductArea   = Template.GetArea(NamesOfLineAreas.TableHeader + "|" + ColumnAreaNames.OwnGoods);
		DataArea  = Template.GetArea(NamesOfLineAreas.TableHeader + "|" + ColumnAreaNames.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		RoomArea  = Template.GetArea(NamesOfLineAreas.TableRow + "|LineNumber");
		AreaCodes   = Template.GetArea(NamesOfLineAreas.TableRow + "|ColumnOfCodes");
		ProductArea   = Template.GetArea(NamesOfLineAreas.TableRow + "|" + ColumnAreaNames.OwnGoods);
		DataArea  = Template.GetArea(NamesOfLineAreas.TableRow + "|" + ColumnAreaNames.Data);
		
		Sum          = 0;
		VATAmount       = 0;
		TotalOfDiscounts    = 0;
		LineNumber    = 0;
		TotalWithoutDiscounts = 0;
		
		// Output the rows of the Goods table
			
		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			
			DataStructureLineNumber = New Structure("LineNumber", LineNumber);
			RoomArea.Parameters.Fill(DataStructureLineNumber);
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersProductPresentation);
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			ProductArea.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductArea);
			
			DataArea.Parameters.Fill(ProductSelection_1);
			
			SpreadsheetDocument.Join(DataArea);
			
			Sum          = Sum          + ProductSelection_1.Sum;
			VATAmount       = VATAmount       + ProductSelection_1.VATAmount;
			
		EndDo;
		
		// We output the basement
		
		RoomArea  = Template.GetArea(NamesOfLineAreas.TableFooter + "|LineNumber");
		AreaCodes   = Template.GetArea(NamesOfLineAreas.TableFooter + "|ColumnOfCodes");
		ProductArea   = Template.GetArea(NamesOfLineAreas.TableFooter + "|" + ColumnAreaNames.OwnGoods);
		DataArea  = Template.GetArea(NamesOfLineAreas.TableFooter + "|" + ColumnAreaNames.Data);
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		TotalDataStructure = New Structure;
		TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		DataArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the total of the ADS
		If GetFunctionalOption("UseVATAccounting") Then
			Area = Template.GetArea("VATBasement");
			DataStructureVATBasement = New Structure;
			DataStructureVATBasement.Insert("TotalVAT", VATAmount);
			If ThereIsVAT Then
				DataStructureVATBasement.Insert("VAT", ?(PrintData.PriceIncludesVAT,
				NStr("vi = 'Trong đó, thuế GTGT:';
					|ru = 'В том числе НДС:';
					|en = 'Including VAT:'; fa = 'Including VAT:';
					|it = 'IVA compresa:';
					|pl = 'W tym VAT';
					|tr = 'KDV dahil:'", Common.DefaultLanguageCode()),
				NStr("vi = 'Thuế GTGT:';
					|ru = 'Сумма НДС:';
					|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
					|it = 'Importo IVA:';
					|pl = 'Wartość VAT';
					|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			Else
				DataStructureVATBasement.Insert("VAT", NStr("vi = 'Không gồm thuế (GTGT)';
															|ru = 'Без налога (НДС)';
															|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
															|it = 'senza imposta (IVA)';
															|pl = 'bez podatku (VAT)';
															|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
			EndIf;
			Area.Parameters.Fill(DataStructureVATBasement);
			SpreadsheetDocument.Join(Area);
		EndIf;
		// We output the Amount in words
		
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số %1, thành tiền %2';
				|ru = 'Всего наименований %1, на сумму %2';
				|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
				|it = 'Totale articoli %1, per importo di %2';
				|pl = 'Razem pozycji %1, na kwotę %2';
				|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
			ProductSelection_1.Count(),
			PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		DataStructureTotal = New Structure;
		DataStructureTotal.Insert("TotalString", TotalString);
		DataStructureTotal.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
		TemplateArea.Parameters.Fill(DataStructureTotal);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			DataStructureVacationProduced =
				New Structure("VacationProduced", PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date));
			TemplateArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

EndFunction

Function NamesOfLineAreas(ThereAreDiscounts, ThereIsVAT)
	
	ReturnStructure = New Structure("TableHeader, TableRow, TableFooter");
	
	If ThereAreDiscounts And ThereIsVAT Then
		ReturnStructure.TableHeader = "TableHeaderWithDiscountWithVAT";
		ReturnStructure.TableRow = "TableRowWithDiscountWithVAT";
		ReturnStructure.TableFooter = "TableBasementWithVATDiscount";
	ElsIf ThereAreDiscounts And Not ThereIsVAT Then
		ReturnStructure.TableHeader = "TableHeaderWithDiscount";
		ReturnStructure.TableRow = "TableRowWithDiscount";
		ReturnStructure.TableFooter = "BasementTablesAtDiscount";
	ElsIf Not ThereAreDiscounts And ThereIsVAT Then
		ReturnStructure.TableHeader = "HeaderOfTableWithVAT";
		ReturnStructure.TableRow = "TableRowWithVAT";
		ReturnStructure.TableFooter = "BasementTableWithVAT";
	Else
		ReturnStructure.TableHeader = "TableHeader";
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.TableFooter = "TableFooter";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function ColumnAreaNames(ThereAreDiscounts, ThereIsVAT)
	
	ReturnStructure = New Structure("OwnGoods, Data");
	
	If ThereAreDiscounts And ThereIsVAT Then
		ReturnStructure.OwnGoods = "DiscountedGoodsWithVAT";
		ReturnStructure.Data = "DiscountedDataWithVAT";
	ElsIf ThereAreDiscounts Or ThereIsVAT Then
		ReturnStructure.OwnGoods = "ProductWithDiscountOrWithVAT";
		ReturnStructure.Data = "DiscountedOrWithVATData";
	Else
		ReturnStructure.OwnGoods = "OwnGoods";
		ReturnStructure.Data = "Data";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function FormPrintedFormRegisterOfCCDNumbers(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ReturnablePackagingRedemptionByCustomer_CCDNumberRegistry";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query("
	|SELECT DISTINCT
	|	TableTypesOfStocks_.Ref AS Ref
	|
	|INTO TTDocumentTable_
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref IN(&ObjectsArray)
	|	AND TableTypesOfStocks_.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Manager.Individual AS NameOfManager
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|
	|	INNER JOIN
	|		TTDocumentTable_ AS DocumentsTable
	|	ON
	|		DocumentData.Ref = DocumentsTable.Ref
	|
	|ORDER BY
	|	Ref
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.Ref AS Ref,
	|	PRESENTATION(TableTypesOfStocks_.ItemsLocationAttributes.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.Code AS Code,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.SKU AS SKU,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.DescriptionFull AS ItemName,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic.DescriptionFull AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.OriginCountry AS OriginCountry,
	|
	|	SUM(TableTypesOfStocks_.Count) AS Count
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer.InventoryKinds AS TableTypesOfStocks_
	|
	|	INNER JOIN
	|		TTDocumentTable_ AS DocumentsTable
	|	ON
	|		TableTypesOfStocks_.Ref = DocumentsTable.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|
	|GROUP BY
	|	TableTypesOfStocks_.Ref,
	|	TableTypesOfStocks_.LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic,
	|	TableTypesOfStocks_.CCDNumber
	|
	|ORDER BY
	|	Ref,
	|	TableTypesOfStocks_.LineNumber
	|
	|TOTALS BY
	|	Ref
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS DocumentData
	|
	|	LEFT JOIN
	|		TTDocumentTable_ AS DocumentsTable
	|	ON
	|		DocumentData.Ref = DocumentsTable.Ref
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND DocumentsTable.Ref IS NULL
	|
	|ORDER BY
	|	Ref
	|");
	Query.SetParameter("ObjectsArray", ObjectsArray);
		
	Template = PrintManagement.PrintFormTemplate("Document.CustomerInvoice.PF_MXL_CCDNumberRegistry");
		
	ResultsArray = Query.ExecuteBatch();
	
	// Array of results[0] - VtTablitsAdocuments
	ResultPrintData				= ResultsArray[1]; // QueryResult
	ResultDocumentSelection		= ResultsArray[2]; // QueryResult
	ResultIsSampleOfDocumentsWithoutCCD	= ResultsArray[3]; // QueryResult
	
	PrintData 						= ResultPrintData.Select();
	SelectionByDocuments 				= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	SelectionOfDocumentsWithoutCCD 			= ResultIsSampleOfDocumentsWithoutCCD.Select();
	
	FirstDocument = True;
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While PrintData.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Area = Template.GetArea("Header");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
		Area.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Bảng kê số tờ khai hải quan kèm hóa đơn';
																									|ru = 'Реестр номеров ГТД к накладной';
																									|en = 'CCD number registry to invoice'; fa = 'CCD number registry to invoice';
																									|it = 'Registro numeri delle dichiarazioni doganali di carico per la bolla di accompagnamento';
																									|pl = 'Wykaz numerów towarowej deklaracji celnej do zlecenia transportowego';
																									|tr = 'GB numaralarının irsaliyeye kaydedilmesi'", Common.DefaultLanguageCode()));
		Area.Parameters.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date),
			"FullDescr");
		Area.Parameters.PartnerPresentation_ = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date),
			"FullDescr");
		Area.Parameters.Organization = PrintData.Organization;
		Area.Parameters.Counterparty = PrintData.Counterparty;
		SpreadsheetDocument.Put(Area);
				
		Area = Template.GetArea("TableHeader|BeginningOfTheLine");
		SpreadsheetDocument.Put(Area);
		If OutputCodes Then
			Area = Template.GetArea("TableHeader|ColumnOfCodes");
			Area.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
			SpreadsheetDocument.Join(Area);
		EndIf;
		Area = Template.GetArea("TableHeader|ProductColumn_");
		SpreadsheetDocument.Join(Area);
				
		LineNumber = 1;
		
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		ProductSelection_1 = SelectionByDocuments.Select();
		While ProductSelection_1.Next() Do
					
			Area = Template.GetArea("TableRow|BeginningOfTheLine");
			Area.Parameters.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
			SpreadsheetDocument.Put(Area);
			
			If OutputCodes Then
				Area = Template.GetArea("TableRow|ColumnOfCodes");
				Area.Parameters.CodeValue = ProductSelection_1[NameOfCodeColumn];
				SpreadsheetDocument.Join(Area);
			EndIf;
			
			Area = Template.GetArea("TableRow|ProductColumn_");
			Area.Parameters.Fill(ProductSelection_1);
			Area.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ItemName,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersProductPresentation);
			
			SpreadsheetDocument.Join(Area);
			
		EndDo;
				
		Area = Template.GetArea("TableFooter|BeginningOfTheLine");
		SpreadsheetDocument.Put(Area);
		If OutputCodes Then
			Area = Template.GetArea("TableFooter|ColumnOfCodes");
			SpreadsheetDocument.Join(Area);
		EndIf;
		Area = Template.GetArea("TableFooter|ProductColumn_");
		SpreadsheetDocument.Join(Area);
						
		Area = Template.GetArea("Signatures");
		Area.Parameters.TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số mục %1';
				|ru = 'Всего наименований %1';
				|en = 'Total items %1'; fa = 'Total items %1';
				|it = 'Totale articoli %1';
				|pl = 'Razem pozycji %1';
				|tr = 'Toplam tanım %1'", Common.DefaultLanguageCode()), String(LineNumber - 1));
		If ValueIsFilled(PrintData.NameOfManager) Then
			Area.Parameters.Manager = PersonsTM.IndividualShortName(PrintData.NameOfManager, PrintData.Date);
		EndIf;
		SpreadsheetDocument.Put(Area);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
			
	EndDo;
	
	// We will output messages about documents for which it is not required to print a register of GTD numbers.
	While SelectionOfDocumentsWithoutCCD.Next() Do
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1 không có hàng hóa với số tờ khai hải quan. Không cần in Bảng kê số tờ khai hải quan.';
				|ru = 'В документе %1 отсутствуют товары с номерами ГТД. Печать реестра номеров ГТД не требуется.';
				|en = 'Goods with CCD numbers are missing in document %1. Printing of CCD number registry is not required.'; fa = 'Goods with CCD numbers are missing in document %1. Printing of CCD number registry is not required.';
				|it = 'Non ci sono merci con i numeri delle dichiarazioni doganali di carico nel documento %1. Non è necessario stampare il registro dei numeri delle dichiarazioni doganali di carico.';
				|pl = 'W dokumencie %1 nie ma towarów z numerami towarowej deklaracji celnej. Drukowanie rejestru numerów towarowej deklaracji celnej nie jest potrzebne.';
				|tr = '%1 belgesinde GB Numarası olan mal bulunmamaktadır. GB Numarası kaydının yazdırılmasına gerek yoktur.'"),
			String(SelectionOfDocumentsWithoutCCD.Ref));
		CommonClientServer.MessageToUser(
			Text,
			SelectionOfDocumentsWithoutCCD.Ref);
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
		If GoodsDeliveryClientServer.UsedDelivery20() Then
			PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Carrier");
		EndIf;
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	If GoodsDeliveryClientServer.UsedDelivery20() Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	EndIf;
	
EndProcedure


Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	FALSE AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.ReturnablePackagingRedemptionByCustomer AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	0 AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	0 AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref											AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|	0                                                        AS DiscountAmount,
	|	Goods.Sum                                             AS AmountWithoutADiscount,
	|	FALSE AS ThisIsReusablePackage
	|FROM 
	|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Goods.LineNumber
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

#Region Other

// Returns the base text based on document data
//
// Parameters:
//	Object - FormDataStructure, DocumentObject.ReturnablePackagingRedemptionByCustomer - The object of the document that you need to get the base text from.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object)
	
	StructureBase = New Structure;
	StructureBase.Insert("Basis");
	StructureBase.Insert("BaseDocumentNumber");
	StructureBase.Insert("ReferenceDocumentDateForPrintForms");
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And ValueIsFilled(Object.Contract) Then
		
		Query = New Query(
			"SELECT ALLOWED
			|	CounterpartyContracts.NameForPrinting AS Basis,
			|	CounterpartyContracts.Date AS ReferenceDocumentDateForPrintForms,
			|	CounterpartyContracts.Number AS BaseDocumentNumber
			|FROM
			|	Catalog.CounterpartyContracts AS CounterpartyContracts
			|WHERE
			|	CounterpartyContracts.Ref = &Ref");
		Query.SetParameter("Ref", Object.Contract);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			StructureBase.Basis = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

#EndRegion

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReturnablePackagingRedemptionByCustomer";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessOperation",
		Enums.BusinessTransactions.SaleToCustomer);
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("NumberAccordingToCustomerData", """""");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&ReferenceDocumentDateForPrintForms                          AS SourceDocumentDate,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&BaseDocumentNumber                         AS SourceDocumentNumber,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
