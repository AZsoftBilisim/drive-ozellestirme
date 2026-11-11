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
	
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
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
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReverseVATAccrual") Then
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
		
		QueryTextTableVATInvoiced(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		
		DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction


#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// Adds the command to create the document "Calculation of reverse VAT".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:  
//	 ValueTableRow, Undefined - the command to output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReverseVATAccrual) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReverseVATAccrual.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReverseVATAccrual);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseVATReverseCharge";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Returns parameters for creating a list of documents for calculating reverse VAT
//
// Returns:
// 	Structure - verification parameters:
// 		* Organization - CatalogRef.Companies - Selection by organization. If Undefined, then for all.
// 		* Counterparty - CatalogRef.Counterparties - Selection by counterparty. If Undefined, then for all.
// 		* BeginOfPeriod - Date - Selection of documents older than the specified date.
// 		* EndOfPeriod - Date - Selection of documents younger than the specified date.
//
Function ParametersForCreatingListOfDocumentsForCalculatingReverseVAT() Export
	
	BackgroundJobParameters = New Structure;
	BackgroundJobParameters.Insert("Organization");
	BackgroundJobParameters.Insert("Counterparty");
	BackgroundJobParameters.Insert("BeginOfPeriod");
	BackgroundJobParameters.Insert("EndOfPeriod");
	
	Return BackgroundJobParameters;
	
EndFunction

// Generates a list of documents for calculating reverse VAT
//
// Parameters:
// 	 Parameters - Structure -
//
// Returns:
//	QueryResult - The result of the query
Function UpdateListOfOrders(Parameters) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	DocumentInflow.Ref AS DocumentBasis,
	|	DocumentInflow.Date AS Date,
	|	DocumentInflow.Organization AS Organization,
	|	DocumentInflow.Counterparty AS Counterparty,
	|	DocumentInflow.Currency AS Currency,
	|	DocumentInflow.DocumentAmount AS DocumentAmount
	|FROM
	|	Document.VendorInvoice AS DocumentInflow
	|		LEFT JOIN Document.ReverseVATAccrual AS ReverseVATAccrual
	|		ON DocumentInflow.Ref = ReverseVATAccrual.DocumentBasis 
	|WHERE
	|	DocumentInflow.Posted
	|	AND &OrganizationConditions
	|	AND &ConditionByCounterparty
	|	AND &ConditionByDate
	|	AND DocumentInflow.VATTaxation = VALUE(Enum.VATTaxationTypes.VATReverseCharge)
	|	AND ReverseVATAccrual.Ref IS NULL 
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref,
	|	DocumentInflow.Date,
	|	DocumentInflow.Organization AS Organization,
	|	DocumentInflow.Counterparty,
	|	DocumentInflow.Currency,
	|	DocumentInflow.DocumentAmount
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentInflow
	|		LEFT JOIN Document.ReverseVATAccrual AS ReverseVATAccrual
	|		ON DocumentInflow.Ref = ReverseVATAccrual.DocumentBasis
	|WHERE
	|	DocumentInflow.Posted
	|	AND &OrganizationConditions
	|	AND &ConditionByCounterparty
	|	AND &ConditionByDate
	|	AND DocumentInflow.VATTaxation = VALUE(Enum.VATTaxationTypes.VATReverseCharge)
	|	AND ReverseVATAccrual.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref,
	|	DocumentInflow.Date,
	|	DocumentInflow.Organization AS Organization,
	|	DocumentInflow.Counterparty,
	|	DocumentInflow.Currency,
	|	DocumentInflow.DocumentAmount
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentInflow
	|		LEFT JOIN Document.ReverseVATAccrual AS ReverseVATAccrual
	|		ON DocumentInflow.Ref = ReverseVATAccrual.DocumentBasis
	|WHERE
	|	DocumentInflow.Posted
	|	AND &OrganizationConditions
	|	AND &ConditionByCounterparty
	|	AND &ConditionByDate
	|	AND DocumentInflow.VATTaxation = VALUE(Enum.VATTaxationTypes.VATReverseCharge)
	|	AND ReverseVATAccrual.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref,
	|	DocumentInflow.Date,
	|	DocumentInflow.Organization AS Organization,
	|	DocumentInflow.Counterparty,
	|	DocumentInflow.Currency,
	|	DocumentInflow.DocumentAmount
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS DocumentInflow
	|		LEFT JOIN Document.ReverseVATAccrual AS ReverseVATAccrual
	|		ON DocumentInflow.Ref = ReverseVATAccrual.DocumentBasis
	|WHERE
	|	DocumentInflow.Posted
	|	AND &OrganizationConditions
	|	AND &ConditionByCounterparty
	|	AND &ConditionByDate
	|	AND DocumentInflow.VATTaxation = VALUE(Enum.VATTaxationTypes.VATReverseCharge)
	|	AND ReverseVATAccrual.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInflow.Ref,
	|	DocumentInflow.Date,
	|	DocumentInflow.Organization AS Organization,
	|	DocumentInflow.Counterparty,
	|	DocumentInflow.Currency,
	|	DocumentInflow.DocumentAmount
	|FROM
	|	Document.PurchaseAdjustment AS DocumentInflow
	|		LEFT JOIN Document.ReverseVATAccrual AS ReverseVATAccrual
	|		ON DocumentInflow.Ref = ReverseVATAccrual.DocumentBasis
	|WHERE
	|	DocumentInflow.Posted
	|	AND &OrganizationConditions
	|	AND &ConditionByCounterparty
	|	AND &ConditionByDate
	|	AND DocumentInflow.VATTaxation = VALUE(Enum.VATTaxationTypes.VATReverseCharge)
	|	AND ReverseVATAccrual.Ref IS NULL
	|";
	
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Counterparty", Parameters.Counterparty);
	Query.SetParameter("BeginOfPeriod", Parameters.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Parameters.EndOfPeriod);
	
	OrganizationConditions = "TRUE";
	If ValueIsFilled(Parameters.Organization) Then
		
		OrganizationConditions = "DocumentInflow.Organization = &Organization";
		
	EndIf;
	Query.Text = StrReplace(Query.Text, "&OrganizationConditions", OrganizationConditions);
	
	ConditionByCounterparty = "TRUE";
	If ValueIsFilled(Parameters.Counterparty) Then
		
		ConditionByCounterparty = "DocumentInflow.Counterparty = &Counterparty";
		
	EndIf;
	Query.Text = StrReplace(Query.Text, "&ConditionByCounterparty", ConditionByCounterparty);
	
	ConditionByDate = "DocumentInflow.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod";
	If Not ValueIsFilled(Parameters.EndOfPeriod) Then
		
		ConditionByDate = "DocumentInflow.Date >= &BeginOfPeriod"
		
	EndIf;
	Query.Text = StrReplace(Query.Text, "&ConditionByDate", ConditionByDate);
	
	QueryResult = Query.Execute();
	
	Return QueryResult;
	
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
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

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
	|	DocumentData.Date AS Period,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.Number AS Number,
	|	DocumentData.Number AS NumberForPrinting,
	|	DocumentData.Department AS Department,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.VATAmount AS VATAmount,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("Period", Attributes.Date);
	Query.SetParameter("DateCreated", Attributes.Period);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.ReverseVATAccrual"));
	Query.SetParameter("VATRate", VATAccountingERP.DefaultVATRate(Attributes.Organization, Attributes.Period, True));
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.ReverseVATAccrual);
	Query.SetParameter("CompanyManagementAccounting",
		CalculationOfCostCached.CompanyManagementAccounting(Attributes.Period));
	
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&Counterparty AS Counterparty,
	|	&Department AS Department,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	&VATAmount AS Sum,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	CASE
	|		WHEN &Partner = VALUE(Catalog.Partners.EmptyRef)
	|			THEN DocumentData.Counterparty.Partner
	|		ELSE &Partner
	|	END AS Partner,
	|	FALSE AS AdditionalRecord,
	|	&Period AS RecordingInAccountingDate,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction


Function QueryTextTableVATInvoiced(Query, QueryTexts, Registers)
	
	RegisterName = "VATInvoiced";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetParameterConversionFactorToCurrencyMan(Query);
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DocumentBasis AS TaxInvoice,
	|	DocumentData.Counterparty AS Vendor,
	|	VALUE(Enum.AssetKinds.VATReverseCharge) AS AssetTaxClass,
	|	Rows.VATRate AS VATRate,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	Rows.TaxBase AS AmountExcludingVAT,
	|	Rows.VATAmount AS VAT,
	|	UNDEFINED AS CorVATActivityTypes,
	|	DocumentData.Department AS Department,
	|	"""" AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	Rows.RowID AS FinRecordID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	CASE 
	|		WHEN &CompanyManagementAccounting 
	|			THEN Rows.VATAmount * &ConversionRateToManCurrency
	|		ELSE 0
	|	END AS VATManag
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|	
	|	INNER JOIN
	|		Document.ReverseVATAccrual.VATAccrual AS Rows
	|	ON
	|		Rows.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		BusinessTransactionsSettings.BusinessOperation = &BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND (Rows.VATAmount <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetParameterConversionFactorToCurrencyMan(Query);
	
	Query.SetParameter("VAT_TaxAgent", Catalogs.TaxContributionKinds.GetLinkOfPredefinedElement("VAT_TaxAgent"));
	
	QueryText =
	"SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Taxes) AS AssetRef,
	|	&VAT_TaxAgent AS Dimension,
	|	SUM(DocumentData.VATAmount * &ConversionRateToManCurrency) AS Sum
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|	
	|	INNER JOIN
	|		Document.ReverseVATAccrual.VATAccrual AS Rows
	|	ON
	|		Rows.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (Rows.VATAmount <> 0)
	|
	|GROUP BY
	|	DocumentData.Date,
	|	DocumentData.Organization";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVATRegisterRecords(Query, QueryTexts, Registers)
	
	RegisterName = "VATRegisterRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetParameterConversionFactorToCurrencyMan(Query);
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	VALUE(Enum.VATRegisterRecordTypes.Outgoing) AS EntryType,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.DocumentBasis AS TaxInvoice,
	|	Rows.VATRate AS VATRate,
	|	VALUE(Enum.AssetKinds.VATReverseCharge) AS AssetTaxClass,
	|	Rows.TaxBase AS AmountExcludingVAT,
	|	Rows.VATAmount AS VAT,
	|	CASE 
	|		WHEN &CompanyManagementAccounting 
	|			THEN Rows.VATAmount * &ConversionRateToManCurrency
	|		ELSE 0
	|	END AS VATManag,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS PeriodEndTransaction,
	|	Rows.RowID AS FinRecordID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|	
	|	INNER JOIN
	|		Document.ReverseVATAccrual.VATAccrual AS Rows
	|	ON
	|		Rows.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		BusinessTransactionsSettings.BusinessOperation = &BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (Rows.VATAmount <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	InitializeTTOfBatchOfOtherExpenses(Query, QueryTexts);
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses(, True);
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure InitializeTTOfBatchOfOtherExpenses(Query, QueryTexts)
	
	If Query.Parameters.Property("TTOfBatchOfOtherExpensesHasBeenInitialized") Then
		Return;
	EndIf;
	
	SetParameterConversionFactorToCurrencyMan(Query);
	InitializeAnalysisKeysForDocumentBatchAccounting(Query);
	
	RequestForBatchOfOtherExpenses = New Query;
	RequestForBatchOfOtherExpenses.TempTablesManager = Query.TempTablesManager;
	RequestForBatchOfOtherExpenses.SetParameter("Ref", Query.Parameters.Ref);
	RequestForBatchOfOtherExpenses.SetParameter("CompanyManagementAccounting", Query.Parameters.CompanyManagementAccounting);
	RequestForBatchOfOtherExpenses.SetParameter("ConversionRateToManCurrency", Query.Parameters.ConversionRateToManCurrency);
	RequestForBatchOfOtherExpenses.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	
	RequestForBatchOfOtherExpenses.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.VATOfTaxAgent) AS ExpenseItem,
	|	DocumentData.DocumentBasis AS DimensionOfExpenses,
	|	DocumentData.DocumentBasis AS ExpenseReceiptDocument,
	|	Dimension.LotVendorAttributes AS LotVendorAttributes,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)AS VATActivityType,
	|	0 AS CostExcludingVAT,
	|	Rows.VATAmount AS VATLocal,
	|	CASE 
	|		WHEN &CompanyManagementAccounting 
	|			THEN Rows.VATAmount * &ConversionRateToManCurrency
	|		ELSE 0
	|	END AS VATManag,
	|	&BusinessOperation AS BusinessOperation,
	|	Rows.RowID AS FinRecordID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	Rows.VATAmount * &ConversionRateToManCurrency AS VATAmountMan
	|INTO TTLotsOfOtherExpensesOtherExpenses
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|	INNER JOIN
	|		Document.ReverseVATAccrual.VATAccrual AS Rows
	|		INNER JOIN TTTableOfPartyAccountingAnalysts AS Dimension
	|		ON Rows.RowID = Dimension.LineNumber
	|	ON
	|		Rows.Ref = DocumentData.Ref
	|
	|	LEFT JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		BusinessTransactionsSettings.BusinessOperation = &BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (Rows.VATAmount <> 0)
	|";
	
	RequestForBatchOfOtherExpenses.Execute();
	VATLotsOfOtherExpenses = AccumulationRegisters.ItemisedExpensesLots.CreateRecordSet();
	VATLotsOfOtherExpenses.Load(CostCalculationAppliedAlgorithms.UnloadTemporaryTable(RequestForBatchOfOtherExpenses.TempTablesManager, "TTLotsOfOtherExpensesOtherExpenses"));
	
	RequestForBatchOfOtherExpenses.SetParameter("VATLotsOfOtherExpenses", VATLotsOfOtherExpenses);
	RequestForBatchOfOtherExpenses.Text = 
	"SELECT
	|	ItemisedExpensesLots.DimensionOfExpenses,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef) AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	ItemisedExpensesLots.LotVendorAttributes,
	|	ItemisedExpensesLots.RecordType,
	|	ItemisedExpensesLots.CostTD,
	|	ItemisedExpensesLots.ExpenseReceiptDocument,
	|	ItemisedExpensesLots.VATActivityType,
	|	ItemisedExpensesLots.VATLocal,
	|	ItemisedExpensesLots.VATManag,
	|	ItemisedExpensesLots.VATTaxation,
	|	ItemisedExpensesLots.LineNumber,
	|	ItemisedExpensesLots.Organization,
	|	ItemisedExpensesLots.Period,
	|	ItemisedExpensesLots.Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	ItemisedExpensesLots.PermanentDifference,
	|	ItemisedExpensesLots.Recorder,
	|	ItemisedExpensesLots.ExpenseItem,
	|	ItemisedExpensesLots.Cost,
	|	ItemisedExpensesLots.CostExcludingVAT,
	|	ItemisedExpensesLots.LocalCost,
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting,
	|	"""" AS FinRecordID
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	&VATLotsOfOtherExpenses AS ItemisedExpensesLots";
	
	RequestForBatchOfOtherExpenses.Execute();
	
	ArrayOfPeriods = New Array;
	ArrayOfPeriods.Add(Query.Parameters.DateCreated);

	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(
		Query,
		Query.Parameters,
		ArrayOfPeriods);
	
	Query.SetParameter("TTOfBatchOfOtherExpensesHasBeenInitialized", True);
	
EndProcedure

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	InitializeTTOfBatchOfOtherExpenses(Query, QueryTexts);
	
	QueryText = "
	|SELECT TOP 0
	|	ExpensesTable.Period AS Period,
	|	ExpensesTable.RecordType AS RecordType,
	|	ExpensesTable.Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	ExpensesTable.Department AS Department,
	|	ExpensesTable.LineOfBusiness AS LineOfBusiness,
	|	ExpensesTable.ExpenseItem AS ExpenseItem,
	|	ExpensesTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	ExpensesTable.BusinessOperation AS BusinessOperation,
	|	ExpensesTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	"""" AS RowID,
	|	"""" AS FinRecordID,
	|	ExpensesTable.BusinessTransactionSetting AS BusinessTransactionSetting 
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses AS ExpensesTable
	|
	|UNION ALL
	|
	|SELECT
	|	ExpensesTable.Period AS Period,
	|	ExpensesTable.RecordType AS RecordType,
	|	ExpensesTable.Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	ExpensesTable.Department AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	ExpensesTable.ExpenseItem AS ExpenseItem,
	|	ExpensesTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	ExpensesTable.VATActivityType AS VATActivityType,
	|
	|	SUM(ExpensesTable.VATAmountMan) AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	SUM(ExpensesTable.VATLocal) AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	NULL AS ItemsLocationAttributes,
	|	
	|	"""" AS RowID,
	|	ExpensesTable.FinRecordID AS FinRecordID,
	|	UNDEFINED AS BusinessTransactionSetting 
	|
	|FROM
	|	TTLotsOfOtherExpensesOtherExpenses AS ExpensesTable
	|
	|GROUP BY
	|	ExpensesTable.Period,
	|	ExpensesTable.RecordType,
	|	ExpensesTable.Organization,
	|	ExpensesTable.Department,
	|	ExpensesTable.ExpenseItem,
	|	ExpensesTable.DimensionOfExpenses,
	|	ExpensesTable.VATActivityType,
	|	ExpensesTable.FinRecordID
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure SetParameterConversionFactorToCurrencyMan(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency") Then
		Return;
	EndIf;
	
	ConversionRateToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
										Query.Parameters.LocalAccountingCurrency,
										Constants.ManagementAccountingCurrency.Get(),
										Query.Parameters.Period);
										
	Query.SetParameter("ConversionRateToManCurrency", ConversionRateToManCurrency);
	
EndProcedure

Procedure InitializeAnalysisKeysForDocumentBatchAccounting(Query)
	
	If Query.Parameters.Property("DocumentBatchTrackingAnalyticsKeysAreInitialized") Then
		Return;
	EndIf;
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	SetRequestParameterTaxationOfOrganization(Query);
	
	TextSelectionOfAnalystField =
	"SELECT
	|	Rows.RowID AS LineNumber,
	|	""VATAccrual"" AS TabularSectionName,
	|	DocumentData.Partner AS Vendor,
	|	DocumentData.Counterparty AS Counterparty,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATTaxation,
	|	Rows.VATRate AS VATRate,
	|	VALUE(Enum.AssetKinds.VATReverseCharge) AS AssetTaxClass,
	|	0 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ReverseVATAccrual AS DocumentData
	|	INNER JOIN
	|		Document.ReverseVATAccrual.VATAccrual AS Rows
	|	ON
	|		Rows.Ref = DocumentData.Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query);
	
	Query.Text = QueryText;
	Query.Execute();
	
	Query.SetParameter("DocumentBatchTrackingAnalyticsKeysAreInitialized", True);
	
EndProcedure

Procedure SetRequestParameterTaxationOfOrganization(Query)
	
	If Query.Parameters.Property("TaxationOfOrganization") Then
		Return;
	EndIf;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Query.Parameters.Organization, Query.Parameters.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReverseVATAccrual";
	SynonymForDocumentTable = "DocumentData";
	RequestHasSource    = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("CorrectionInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ReverseVATAccrual"));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.ReverseVATAccrual);
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
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

#EndRegion

#EndRegion

#EndIf
