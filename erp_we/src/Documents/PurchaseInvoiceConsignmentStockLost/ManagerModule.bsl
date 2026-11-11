#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
EndProcedure

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
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	
	PurchaseInvoiceConsignmentStockLostLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.PurchaseInvoiceConsignmentStockLost") Then
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
		
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		PurchaseInvoiceConsignmentStockLostLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
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
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	PurchaseInvoiceConsignmentStockLostLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "report to the Commitee on write-off".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PurchaseInvoiceConsignmentStockLost) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PurchaseInvoiceConsignmentStockLost.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PurchaseInvoiceConsignmentStockLost);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseCommission";
	

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
	
	Reports.StateOfSettlementsWithConsignors.AddReportCommand(ReportsCommands);
	
	Reports.GoodsReceivedByCommissionAgent.AddReportCommand(ReportsCommands);
	
	PurchaseInvoiceConsignmentStockLostLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.PurchaseInvoiceConsignmentStockLost - link to the document.
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
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.DocumentAmount AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.EndOfPeriod AS EndOfPeriod,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings
	|
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
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
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		BeginOfPeriod = Selection.BeginOfPeriod;
		EndOfPeriod = Selection.EndOfPeriod;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		BeginOfPeriod = Undefined;
		EndOfPeriod = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.ConsignmentReportToVendor);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP); 
	AttributesStructure1.Insert("BeginOfPeriod", BeginOfPeriod);
	AttributesStructure1.Insert("EndOfPeriod", EndOfPeriod);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.PurchaseInvoiceConsignmentStockLost - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period  = Object.Date;
	FillParameters.ConsignmentProcurement = True;
	
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

	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ParametersStructure.ARAPCurrency             = "";
	ParametersStructure.AmountARAP              = "";
	ParametersStructure.AmountARAPByPackage        = ""; 

	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.InvoiceForOrders               = "";
	ParametersStructure.OrderBase                   = "";
	
	ParametersStructure.FormItems.LabelCurrencies      = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentSettlement";
	ParametersStructure.FormItems.FinancialAccountingGroup  = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return PurchaseInvoiceConsignmentStockLostLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return PurchaseInvoiceConsignmentStockLostLocalization.RequestTextTTReflectedInLocalAccounting();

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
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	DocumentData.Date        AS Period,
		|	DocumentData.Number       AS Number,
		|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
		|	DocumentData.Ref      AS Ref,
		|	DocumentData.Currency      AS Currency,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Partner     AS Partner,
		|	DocumentData.Counterparty  AS Counterparty,
		|	DocumentData.Contract     AS Contract,
		|	
		|	CASE WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1) THEN
		|				DocumentData.Date
		|			ELSE
		|				DocumentData.EndOfPeriod
		|		END                   AS EndOfPeriod,
		|	
		|	DocumentData.Terms    AS Terms,
		|	DocumentData.Department AS Department,
		|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.VATTaxation AS VATTaxation,
		|	DocumentData.Manager      AS Manager,
		|	DocumentData.Author         AS Author,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
		|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
		|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
		|	DocumentData.PaymentDate                AS PaymentDate,
		|	DocumentData.Patch                AS Patch,
		|	DocumentData.ReversedDocument       AS ReversedDocument,
		|	DocumentData.CorrectedDocument       AS CorrectedDocument,
		|	DocumentData.ARAPObject             AS ARAPObject,
		|	DocumentData.ARAPObject.UUID AS IDARAPObject
		|FROM
		|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
		|	
		|WHERE
		|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                 Attributes.Period);
	Query.SetParameter("Number",                  Attributes.Number);
	Query.SetParameter("AdjustmentPeriod_",    Attributes.AdjustmentPeriod_);
	Query.SetParameter("EndOfPeriod",           EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("Currency",                 Attributes.Currency);
	Query.SetParameter("ARAPCurrency",   Attributes.Currency);
	Query.SetParameter("Organization",            Attributes.Organization);
	Query.SetParameter("Partner",                Attributes.Partner);
	Query.SetParameter("Terms",             Attributes.Terms);
	Query.SetParameter("Department",          Attributes.Department);
	Query.SetParameter("Contract",                Attributes.Contract);
	Query.SetParameter("ARAPObject",         Attributes.ARAPObject);
	Query.SetParameter("Counterparty",             Attributes.Counterparty);
	Query.SetParameter("Manager",               Attributes.Manager);
	Query.SetParameter("Author",                  Attributes.Author);
	Query.SetParameter("VATTaxation",     Attributes.VATTaxation);

	Query.SetParameter("LocalAccountingCurrency", Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("BusinessOperation",          Enums.BusinessTransactions.PurchaseInvoiceConsignmentStockLost);
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.PurchaseInvoiceConsignmentStockLost);
	Query.SetParameter("TaxationOfOrganization",		VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period).BasicTaxationVATSales);
	
	Query.SetParameter("AccountingForLBCosts",					Attributes.AccountingForLBCosts);
	Query.SetParameter("AccountingForIncomeUnderLB",				Attributes.AccountingForIncomeUnderLB);
	Query.SetParameter("AccountingForSettlementsWithSuppliersUnderLB", Attributes.AccountingForSettlementsWithSuppliersUnderLB);
	Query.SetParameter("IDARAPObject",  Attributes.IDARAPObject);
		
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter("LineOfBusiness", Attributes.LineOfBusiness);
	Query.SetParameter("Patch",             Attributes.Patch);
	Query.SetParameter("ReversedDocument",    Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",    Attributes.CorrectedDocument);
	Query.SetParameter("PaymentDate",             Attributes.PaymentDate);
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID(
		EmptyRef().Metadata().FullName()));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	&Period                                       AS Period,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	&Currency                                       AS Currency,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	0                                             AS RevenueAmount,
	|	0                                             AS RevenueAmountExclVATLocal,
	|	0                                             AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count                 AS QuantityConsumed,
	|	0                                             AS QuantityConsumedForIncoiceRegistration,
	|	0                                             AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&BusinessOperation                        AS BusinessOperation,
	|	&IDARAPObject                 AS FinRecordID,
	|	&BusinessTransactionSetting               AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID        AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.Count > 0
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	&EndOfPeriod                                 AS Period,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	&Currency                                       AS Currency,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	0                                             AS RevenueAmount,
	|	0                                             AS RevenueAmountExclVATLocal,
	|	0                                             AS RevenueAmountMan,
	|	0                                             AS QuantityConsumed,
	|	TableTypesOfStocks_.Count                 AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&BusinessOperation                        AS BusinessOperation,
	|	&IDARAPObject                 AS FinRecordID,
	|	&BusinessTransactionSetting               AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID        AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.Count > 0
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&EndOfPeriod                                 AS Period,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	&Currency                                       AS Currency,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	0                                             AS RevenueAmount,
	|	0                                             AS RevenueAmountExclVATLocal,
	|	0                                             AS RevenueAmountMan,
	|	-TableTypesOfStocks_.Count                AS QuantityConsumed,
	|	-TableTypesOfStocks_.Count                AS QuantityConsumedForIncoiceRegistration,
	|	-TableTypesOfStocks_.QuantityByGBRN          AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&BusinessOperation                        AS BusinessOperation,
	|	&IDARAPObject                 AS FinRecordID,
	|	&BusinessTransactionSetting               AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID        AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.Count < 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
		|	&EndOfPeriod                                 AS Period,
		|	&Ref                                       AS Recorder,
		|	&Organization                                  AS Organization,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	&Ref                                       AS DocumentInflow,
		|	UNDEFINED                                  AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.LotVendorAttributes       AS LotVendorAttributes,
		|	TableTypesOfStocks_.Count                 AS Count,
		|	TableTypesOfStocks_.Cost                  AS Cost,
		|	TableTypesOfStocks_.CostExcludingVAT            AS CostExcludingVAT,
		|	TableTypesOfStocks_.LocalCost              AS LocalCost,
		|	0                                             AS VATLocal,
		|	TableTypesOfStocks_.Products               AS Products,
		|	TableTypesOfStocks_.Characteristic             AS Characteristic,
		|	&BusinessOperation                        AS BusinessOperation,
		|	TRUE                                        AS Primary,
		|	UNDEFINED                                  AS DocumentSource
		|FROM
		|	TTTypesOfStocks AS TableTypesOfStocks_
		|WHERE
		|	&BatchAccountingVersion21
		|	AND TableTypesOfStocks_.Count > 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
	EndIf;
	
	QueryText =
		// Record debt to the consignor 
		"SELECT
		|	&Period AS Period,
		|	VALUE(Enum.BusinessTransactions.RecordDebtToConsignor) AS BusinessOperation,
		|	&Organization AS Organization,
		|	&Department AS Department,
		|	&Manager AS Manager,
		|
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|		THEN Contract.LineOfBusiness
		|		ELSE TableTypesOfStocks_.LineOfBusiness
		|	END AS ProductLineOfBusiness,
		|	TableTypesOfStocks_.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
		|			VALUE(Enum.InventoryTypes.OwnGoods)
		|		ELSE TableTypesOfStocks_.InventoryType
		|	END AS InventoryType,
		|	CASE
		|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
		|			UNDEFINED
		|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
		|	END AS InventoryOwnerAttribute,
		|
		|	&Partner AS Partner,
		|	&Counterparty AS Counterparty,
		|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
		|		&LineOfBusiness
		|	END AS CounterpartyLineOfBusiness,
		|	&Terms AS Terms,
		|	&Contract AS Contract,
		|	UNDEFINED AS OrderDocument,
		|
		|	TableTypesOfStocks_.Count AS Count,
		|
		|	TableTypesOfStocks_.Cost AS Sum,
		|	TableTypesOfStocks_.CostExcludingVAT AS AmountExcludingVAT,
		|	TableTypesOfStocks_.LocalCost AS SumCompl,
		|	TableTypesOfStocks_.LocalCost - TableTypesOfStocks_.VATLocal AS LocalAmountExcludingVAT,
		|	0 AS DiscountAmount,
		|
		|	TableTypesOfStocks_.Cost AS Cost,
		|	TableTypesOfStocks_.CostExcludingVAT AS CostExcludingVAT,
		|	TableTypesOfStocks_.LocalCost AS LocalCost,
		|	0 AS AddExpensesForGoods,
		|	0 AS AdditionalExpensesExcludingVAT,
		|
		|	&Currency AS DocumentCurrency,
		|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
		|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
		|
		|	&Currency AS ARAPCurrency,
		|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
		|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
		|
		|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
		|		THEN TableTypesOfStocks_.InventoryOwnerAttribute
		|		ELSE TableTypesOfStocks_.Products
		|	END AS SourceOfProductFinancialAccountingGroup,
		|
		|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
		|FROM
		|	TTTypesOfStocks AS TableTypesOfStocks_
		|	LEFT JOIN Catalog.CounterpartyContracts AS Contract
		|	ON Contract.Ref = &Contract";
	
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
	|	&Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	UNDEFINED AS BusinessOperation,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS StorageLocation,
	|	&Department AS Department,
	|	&Manager AS EmployeeResponsible,
	|	&Author AS Author,
	|	DocumentData.Comment AS Comment,
	|	&Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	&Period AS SourceDocumentDate,
	|	&Number AS SourceDocumentNumber,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = EmptyRef().Metadata().FullName();
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;

	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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
			,);
		
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountIncludingVAT AS AmountARAP,
	|	DocumentTable.VATAmount AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";

	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	TextSelectionOfAnalystField = "
	|SELECT
	|	""InventoryKinds""					AS TabularSectionName,
	|	DocumentTable.LineNumber	AS LineNumber,
	|	UNDEFINED					AS Vendor,
	|	UNDEFINED					AS Counterparty,
	|	UNDEFINED					AS VATRate,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) AS AssetTaxClass,
	|	0								AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(
						TextSelectionOfAnalystField,
						Query,
						QueryTexts);
	
	Return QueryText;
	
EndFunction

Function TemporaryTableQueryTextInventoryTypes(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber                          AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes           AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.CCDNumber                             AS CCDNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType                AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                           AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count                           AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                     AS QuantityByGBRN,
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))  AS Cost,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))  AS CostExcludingVAT,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|	CAST(TableTypesOfStocks_.VATAmount
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS VATLocal,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN CAST((TableTypesOfStocks_.AmountIncludingVAT)
	|				* &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                   AS CostMan,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation	AS Warehouse,
	|	TableTypesOfStocks_.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount								AS VATAmount,
	|	TableTypesOfStocks_.RowID					AS RowID,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass					AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation			AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes			AS LotVendorAttributes
	|INTO TTTypesOfStocks
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|			AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, Query.Parameters.Currency, Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

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
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.PurchaseInvoiceConsignmentStockLost.ARAPDetails AS Table
		|		LEFT JOIN Document.PurchaseInvoiceConsignmentStockLost AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Ref.Organization                                              AS Organization,
		|	Table.Ref.Partner                                                  AS Partner,
		|	Table.Ref.Date                                                     AS RecorderDate,
		|	Table.Ref.Number                                                    AS RecorderNumber,
		|	
		|	Table.Ref.ARAPObject                                           AS ARAPObject,
		|	Table.Ref.PaymentDate                                              AS PaymentDate,
		|	UNDEFINED                                                            AS PaymentOption,
		|	UNDEFINED                                                            AS PurchaseOrder_,
		|	
		|	Table.AmountIncludingVAT                                                       AS Sum,
		|	Table.AmountIncludingVAT                                                       AS AmountARAP,
		|	0                                                                       AS AmountARAPByPackage,
		|
		|	Table.Ref.ARAPObjectSettings                                          AS ARAPObjectSettings,
		|	FALSE                                                                    AS InvoiceForOrders,
		|	Table.Ref.Currency                                                   AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)    AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                              AS PaymentMethod,
		|	Table.Ref.Currency                                                   AS DocumentCurrency,
		|	Table.Ref.Date                                                     AS DateOfCourse,
		|	UNDEFINED                                                            AS LinkedDocument
		|FROM
		|	Document.PurchaseInvoiceConsignmentStockLost.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                          AS Ref,
		|	Table.Ref.Organization                                              AS Organization,
		|	Table.Ref.Partner                                                  AS Partner,
		|	Table.Ref.Date                                                     AS RecorderDate,
		|	Table.Ref.Number                                                    AS RecorderNumber,
		|	Table.Ref.PaymentDate                                              AS PaymentDate,
		|	
		|	Table.Ref.ARAPObject                                           AS ARAPObject,
		|	Table.Ref.ARAPObjectSettings                                          AS ARAPObjectSettings,
		|	FALSE                                                                    AS InvoiceForOrders,
		|	FALSE                                                                    AS ExceedingOrder,
		|	UNDEFINED                                                            AS PurchaseOrder_,
		|	Table.AmountIncludingVAT                                                       AS AmountDue,
		|	Table.Ref.Currency                                                   AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)    AS BusinessOperation,
		|	Table.Ref.PaymentMethod                                              AS PaymentMethod,
		|	Table.Ref.Currency                                                   AS DocumentCurrency,
		|	UNDEFINED                                                            AS PaymentOption,
		|	UNDEFINED                                                            AS LinkedDocument
		|FROM
		|	Document.PurchaseInvoiceConsignmentStockLost.Goods AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Organization                                               AS Organization,
		|	Table.Ref.Partner                                                   AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                            AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.PurchaseInvoiceConsignmentStockLost.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
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
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			TemporaryTableQueryTextInventoryTypes(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 												AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	&TaxationOfOrganization							AS VATActivityType,
	|	DocumentTable.VATTaxation					AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	UNDEFINED 					AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	UNDEFINED 									AS RowID,
	|	TableTypesOfStocks_.Cost					AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT				AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	0                                   			AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	0 												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)	AS BusinessOperation,
	|	&IDARAPObject	 										AS FinRecordID,
	|	&BusinessTransactionSetting                 						AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Count > 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region DisposalAtFixedCost_Item
	
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
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS InventoryOwnerAttribute,
	|	&TaxationOfOrganization						AS VATActivityType,
	|	DocumentTable.VATTaxation				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED																AS CorItemsLocationAttributes,
	|	UNDEFINED	  															AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance) AS ExpenseItemAssets,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products					AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.GoodsValueVariance)  AS IncomeItem,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products					AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	UNDEFINED 					AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|	-TableTypesOfStocks_.Cost			AS Cost,
	|	-TableTypesOfStocks_.CostExcludingVAT		AS CostExcludingVAT,
	|	-TableTypesOfStocks_.LocalCost		AS LocalCost,
	|	-TableTypesOfStocks_.CostMan 		AS CostMan,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost)	AS BusinessOperation,
	|	&IDARAPObject	 										AS FinRecordID,
	|	&BusinessTransactionSetting                 						AS BusinessTransactionSetting
	|
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Count < 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Write-off report to consignor
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
	PrintCommand.Id = "CommissionAgentSReportWriteOff";
	PrintCommand.Presentation = NStr("vi = 'Báo cáo ghi giảm cho người đặt ký gửi';
									|ru = 'Отчет комитенту о списании';
									|en = 'Vendor consignment stock adjustment'; fa = 'تعدیل موجودی امانی تأمین‌کننده';
									|it = 'Report al committente sullo storno';
									|pl = 'Raport dla komitenta o spisaniu';
									|tr = 'Satıcı konsinye stok düzeltmesi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Báo cáo ghi giảm cho người đặt ký gửi';
											|ru = 'Отчет комитенту о списании';
											|en = 'Vendor consignment stock adjustment'; fa = 'تعدیل موجودی امانی تأمین‌کننده';
											|it = 'Report al committente sullo storno';
											|pl = 'Raport dla komitenta o spisaniu';
											|tr = 'Gider yazmalara dair gönderici raporu'");
	
	PurchaseInvoiceConsignmentStockLostLocalization.AddPrintCommands(PrintCommands);

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
	PurchaseInvoiceConsignmentStockLostLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

// Returns data for the formation of the printed form "Report on the commission on the write-off"
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array of DocumentRef.PurchaseInvoiceConsignmentStockLost - links to documents for which you need
//																		to get data.
//
// Returns:
//	Structure - a collection of data used when printing the UPD, containing the following properties:
//		* Title - String - Report header.
//		* HeaderResults - QueryResult - general data of the document.
//		* ResultForTabularPart - QueryResult - data of the tabular part of the document.
//		* DocumentTraceabilityData - ValueTable - a table containing information about the traceability of the document, with the following columns:
//			** Ref - DocumentRef.PurchaseInvoiceConsignmentStockLost - link to the document.
//			** ThereIsRNPT - Boolean - indicates that the document contains traceability information.
//		* TraceableComponents - ValueTable - - description of the table of information on traceable components, with the following columns:
//			** CCDNumber - CatalogRef.CCDNumbers - link to the RPT number of the kit.
//			** ProductBatchIDNumber - String - product registration number.
//			** QuantityByGBRN - Number - the standard number of components per unit of the kit.
//			** FEACNUnitOfMeasure - String - name of the unit of measurement.
//
Function GetDataForPrintedFormCommissionReportOnDebiting(PrintParameters, ObjectsArray) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref						AS Ref,
	|	DocumentData.Number						AS Number,
	|	DocumentData.Date						AS Date,
	|	DocumentData.CorrectedDocument.Number	AS NumberOfDocumentBeingCorrected,
	|	DocumentData.CorrectedDocument.Date	AS DateOfDocumentBeingCorrected,
	|	DocumentData.Counterparty					AS Consignor,
	|	DocumentData.Organization					AS Consignee,
	|	DocumentData.Organization.Prefix			AS Prefix,
	|	DocumentData.Currency						AS Currency,
	|	""""										AS CommitteeRepresentative,
	|	DocumentData.Manager.Individual		AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	NestedQuery.Ref												AS Ref,
	|	MAX(NestedQuery.LineNumber)								AS LineNumber,
	|	NestedQuery.ItemsLocationAttributes							AS ItemsLocationAttributes,
	|	NestedQuery.Products										AS Products,
	|	NestedQuery.Products.DescriptionFull						AS ProductItemName,
	|	NestedQuery.Products.Code									AS Code,
	|	NestedQuery.Products.SKU								AS SKU,
	|	NestedQuery.Products.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull					AS Characteristic,
	|	NestedQuery.UnitOfMeasure.Presentation						AS UnitOfMeasurementName,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END																AS Package,
	|	SUM(NestedQuery.Count)									AS Count,
	|	SUM(0)															AS QuantityByGBRN,
	|	NestedQuery.Price												AS Price,
	|	SUM(NestedQuery.Sum)										AS Sum,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)							AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef)					AS CCDNumberType,
	|	""""																AS ProductBatchIDNumber
	|FROM
	|	(SELECT
	|		GoodsTable.Ref						AS Ref,
	|		GoodsTable.LineNumber					AS LineNumber,
	|		GoodsTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		GoodsTable.Products					AS Products,
	|		CASE
	|			WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN GoodsTable.Products.UnitOfMeasure
	|			ELSE GoodsTable.Package
	|		END										AS UnitOfMeasure,
	|		GoodsTable.Characteristic				AS Characteristic,
	|		GoodsTable.Package						AS Package,
	|		GoodsTable.NumberOfPackages			AS Count,
	|		GoodsTable.Price							AS Price,
	|		GoodsTable.AmountIncludingVAT						AS Sum
	|	FROM
	|		Document.PurchaseInvoiceConsignmentStockLost.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|		AND GoodsTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|														VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.ItemsLocationAttributes,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.UnitOfMeasure,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.Price
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(Sum)
	|BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.Ref	AS Ref,
	|	MAX(CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|				AND BEGINOFPERIOD(Goods.Ref.Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart
	|				AND ISNULL(Goods.CCDNumber.CCDNumberType, UNDEFINED) IN(VALUE(Enum.CCDNumberTypes.ProductBatchIDNumber),
	|																		VALUE(Enum.CCDNumberTypes.KitRNPT))
	|			THEN TRUE
	|		ELSE FALSE
	|	END)			AS ThereIsRNPT
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost.InventoryKinds AS Goods
	|
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	Goods.Ref
	|
	|ORDER BY
	|	Goods.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	DocumentTable.CCDNumber							AS CCDNumber,
	|	CASE
	|		WHEN Components.ProductBatchIDNumber.RegistrationNumber = """"
	|			THEN Components.ProductBatchIDNumber
	|		ELSE Components.ProductBatchIDNumber.RegistrationNumber
	|	END												AS ProductBatchIDNumber,
	|	Components.QuantityByGBRN						AS QuantityByGBRN,
	|	Components.FEACNUnitOfMeasure.Presentation	AS FEACNUnitOfMeasure
	|FROM
	|	Document.PurchaseInvoiceConsignmentStockLost.InventoryKinds AS DocumentTable
	|		INNER JOIN Catalog.CCDNumbers.TraceableComponents AS Components
	|		ON DocumentTable.CCDNumber = Components.Ref";
	
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"NestedQuery.Package",
									"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Title = NStr("vi = 'Báo cáo ghi giảm cho người đặt ký gửi';
				|ru = 'Отчет комитенту о списании';
				|en = 'Vendor consignment stock adjustment'; fa = 'تعدیل موجودی امانی تأمین‌کننده';
				|it = 'Report al committente sullo storno';
				|pl = 'Raport dla komitenta o spisaniu';
				|tr = 'Tedarikçi konsinye stok ayarlaması'", Common.DefaultLanguageCode());
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderResults					= ResultsArray[0]; // QueryResult - 
	ResultForTabularPart			= ResultsArray[1]; // QueryResult - 
	DocumentTraceabilityData	= ResultsArray[2].Unload(); // ValueTable - 
	TraceableComponents			= ResultsArray[3].Unload(); // ValueTable - 
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("Title",							Title);
	DataStructureForPrinting.Insert("HeaderResults",					HeaderResults);
	DataStructureForPrinting.Insert("ResultForTabularPart",			ResultForTabularPart);
	DataStructureForPrinting.Insert("DocumentTraceabilityData",	DocumentTraceabilityData);
	DataStructureForPrinting.Insert("TraceableComponents",		TraceableComponents);
	
	Return DataStructureForPrinting;
	
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

#Region Other

#EndRegion

#Region Posting

#EndRegion

#EndRegion

#EndIf
