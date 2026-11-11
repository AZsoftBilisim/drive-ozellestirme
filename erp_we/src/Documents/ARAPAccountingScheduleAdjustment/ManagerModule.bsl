#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("FinancialAccounting");
EndProcedure

// Generates RegisteredRecords tables
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure of KeyAndValue - a list of register names for which you want to table:
//  * Key - String - Name of the register table.
//  * Value - Undefined
//  AddlParameters - Structure - additional parameters for obtaining data that define the context of the event:
//  * Key - String - parameter name.
//  * Value - Arbitrary - parameter value.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export

	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;

	If TypeOf(Document) = Type("DocumentObject.ARAPAccountingScheduleAdjustment") Then
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
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers);
		QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers);
		
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
	
	AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the "Purchase of goods and services" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ARAPAccountingScheduleAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ARAPAccountingScheduleAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ARAPAccountingScheduleAdjustment);
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
	
	If AccessRight("View", Metadata.Reports.CustomerDebtsByDeadlines) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.CustomerDebtsByDeadlines.FullName();
		ReportCommand.Presentation = Metadata.Reports.CustomerDebtsByDeadlines.Synonym;
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "CustomerReceivablesByTimeContext";
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.AdjustCustomerPaymentSchedule);
			
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Counterparty",
			,
			DataCompositionComparisonType.Filled);
		
	EndIf;
	
	If AccessRight("View", Metadata.Reports.VendorPayablesByDeadlines) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.VendorPayablesByDeadlines.FullName();
		ReportCommand.Presentation = Metadata.Reports.VendorPayablesByDeadlines.Synonym;
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "VendorPayablesByTimeContext";
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.AdjustVendorPaymentSchedule);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Counterparty",
			,
			DataCompositionComparisonType.Filled);
		
	EndIf;
	
	If AccessRight("View", Metadata.Reports.PaymentsFromCustomersByDeadlines) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PaymentsFromCustomersByDeadlines.FullName();
		ReportCommand.Presentation = Metadata.Reports.PaymentsFromCustomersByDeadlines.Synonym;
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "CustomerPaymentsByTimeContext";
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Counterparty",
			,
			DataCompositionComparisonType.Filled);
		
	EndIf;
	
	If AccessRight("View", Metadata.Reports.PaymentsToVendorsByDeadlines) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.PaymentsToVendorsByDeadlines.FullName();
		ReportCommand.Presentation = Metadata.Reports.PaymentsToVendorsByDeadlines.Synonym;
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.VariantKey = "PaymentsToSuppliersByTimeContext";
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			"Counterparty",
			,
			DataCompositionComparisonType.Filled);
		
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
	|	AND ValueAllowed(NewSchedule_.Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Gets settlement objects from the documents for adjusting the settlement schedule.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef.ARAPAccountingScheduleAdjustment
// 
// Returns:
//  Array of CatalogRef.ARAPObjects
Function ObjectsOfAdjustmentCalculations(DocumentsArray) Export
	
	Query = New Query;
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.Text = "
		|SELECT DISTINCT
		|	ARAPAccountingScheduleAdjustmentNewSchedule_.ARAPObject AS ARAPObject
		|FROM
		|	Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS ARAPAccountingScheduleAdjustmentNewSchedule_
		|WHERE
		|	ARAPAccountingScheduleAdjustmentNewSchedule_.Ref IN(&DocumentsArray)";
	
	Return Query.Execute().Unload().UnloadColumn("ARAPObject");
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Ref                                           AS Ref,
	|	ISNULL(DocumentsRegistry.IBDocumentDate, DocumentData.Date) AS Period,
	|	DocumentData.BusinessOperation                            AS BusinessOperation,
	|	DocumentData.FinRecordID                           AS FinRecordID
	|FROM
	|	Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentsRegistry.Ref = DocumentData.ARAPDocument
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentData.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ScheduleData.Currency AS Currency
	|FROM
	|	Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS ScheduleData
	|WHERE
	|	ScheduleData.Ref = &Ref
	|";

	QueryResults = Query.ExecuteBatch();
	AttributesTable = QueryResults[0].Unload();
	Attributes = AttributesTable[0];
	For Each Column In AttributesTable.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID("Document.ARAPAccountingScheduleAdjustment"));
	SettingUpHO = Catalogs.BusinessTransactionsSettings.FindByAttribute("BusinessOperation", Attributes.BusinessOperation);
	Query.SetParameter("BusinessTransactionSetting", SettingUpHO);
	Query.SetParameter("SettlementTransaction", Enums.SettlementOperations.ARAPAdjustment);
	Selection = QueryResults[1].Select();
	Currencies = New Array;
	While Selection.Next() Do
		Currencies.Add(Selection.Currency);
	EndDo;
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	Currencies.Add(CurrencyOfMan);
	Query.SetParameter("ArrayOfCurrencies", Currencies);
	Query.SetParameter("CurrencyOfMan", CurrencyOfMan);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)

	RegisterName = "DocumentsRegistry";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	TheseGrounds.Partner                 AS Partner,
	|	UNDEFINED                            AS StorageLocation,
	|	DocumentData.Counterparty              AS Counterparty,
	|	TheseGrounds.Department           AS Department,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	DocumentData.Author                   AS EmployeeResponsible,
	|	FALSE                                    AS AdditionalRecord,
	|	""""                                    AS More,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Date                    AS SourceDocumentDate,
	|	DocumentData.Number                   AS SourceDocumentNumber,
	|	DocumentData.DocumentAmount          AS Sum,
	|	DocumentData.Currency                  AS Currency,
	|	TheseGrounds.Contract                 AS Contract,
	|	TheseGrounds.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Date                    AS RecordingInAccountingDate
	|FROM Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS TheseGrounds
	|		ON TheseGrounds.Ref = DocumentData.ARAPDocument
	|			AND NOT TheseGrounds.AdditionalRecord
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Function QueryTextTableCustomersARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "CustomersARAPAccounting";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	Calculations.Date                      AS Period,
	|	Calculations.Date                      AS RecorderDate,
	|	Calculations.RecorderNumber         AS RecorderNumber,
	|	Calculations.PaymentDate               AS PaymentDate,
	|	Calculations.RecordType               AS RecordType,
	|	
	|	// Dimensions
	|	AnalyticsRegister.DimensionKey    AS AccountingDimensionByPartners,
	|	Calculations.Organization               AS Organization,
	|	Calculations.Counterparty                AS Counterparty,
	|	Calculations.Partner                   AS Partner,
	|	Calculations.Contract                   AS Contract,
	|	Calculations.LineOfBusiness   AS LineOfBusiness,
	|	
	|	Calculations.ARAPObject            AS ARAPObject,
	|	Calculations.Currency                    AS Currency,
	|	
	|	// Resources
	|	// The amount in the settlement currency.
	|	SUM(Calculations.Sum)              AS Sum,
	|	SUM(0)                          AS AmountDue,
	|	
	|	SUM(
	|		CASE 
	|			WHEN Calculations.Currency = Calculations.ARAPObject.Organization.LocalAccountingCurrency 
	|				THEN Calculations.Sum
	|			WHEN ISNULL(MutualSettlementsExchangeRate.CourseDenominator, 0) = 0 
	|				THEN Calculations.Sum
	|			ELSE CAST(Calculations.Sum * ISNULL(MutualSettlementsExchangeRate.CourseNumerator, 1) / ISNULL(MutualSettlementsExchangeRate.CourseDenominator, 1) AS NUMBER(31,2))
	|		END)                        AS SumCompl,
	|	SUM(
	|		CASE 
	|			WHEN Calculations.Currency = &CurrencyOfMan 
	|				THEN Calculations.Sum
	|			WHEN ISNULL(ManSExchangeRate.CourseDenominator, 0) = 0 
	|				THEN Calculations.Sum
	|			ELSE CAST(Calculations.Sum * ISNULL(MutualSettlementsExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1)  
	|			                                / (ISNULL(MutualSettlementsExchangeRate.CourseDenominator, 1) * ISNULL(ManSExchangeRate.CourseNumerator, 1)) AS NUMBER(31,2))
	|		END)                        AS SumMan,
	|	
	|	// Attributes
	|	Calculations.BusinessOperation     AS BusinessOperation,
	|	Calculations.ARAPDocument         AS ARAPDocument,
	|	Calculations.Currency                    AS DocumentCurrency,
	|	&FinRecordID           AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting,
	|	5                                 AS TypeOfOperationForSorting,
	|	Calculations.Order                   AS OrderOfOperationsWithinDocument,
	|	&SettlementTransaction           AS SettlementTransaction
	|
	|FROM (SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		DATETIME(1,1,1)                          AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.CompanyRecipient
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		TabularSection.Sum                      AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		1                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustCustomerPaymentSchedule)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		TabularSection.Date                       AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.CompanyRecipient
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		TabularSection.Sum                      AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		2                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustCustomerPaymentSchedule)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		DATETIME(1,1,1)                          AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.CompanyRecipient
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		-TabularSection.Sum                     AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		1                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		TabularSection.Date                       AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.CompanyRecipient
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		TabularSection.Sum                      AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		2                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule)
	|	) AS Calculations
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS AnalyticsRegister
	|	ON
	|		Calculations.Organization = AnalyticsRegister.Organization
	|		AND Calculations.Partner = AnalyticsRegister.Partner
	|		AND Calculations.Counterparty = AnalyticsRegister.Counterparty
	|		AND Calculations.Contract = AnalyticsRegister.Contract
	|		AND Calculations.LineOfBusiness = AnalyticsRegister.LineOfBusiness
	|
	|	LEFT JOIN
	|		TTExchangeRates AS MutualSettlementsExchangeRate
	|	ON
	|		Calculations.ARAPObject = MutualSettlementsExchangeRate.ARAPObject
	|		AND Calculations.Currency = MutualSettlementsExchangeRate.Currency
	|		AND Calculations.ARAPObject.Organization.LocalAccountingCurrency = MutualSettlementsExchangeRate.BaseCurrency
	|
	|	LEFT JOIN
	|		TTExchangeRates AS ManSExchangeRate
	|	ON
	|		Calculations.ARAPObject = ManSExchangeRate.ARAPObject
	|		AND &CurrencyOfMan = ManSExchangeRate.Currency
	|		AND Calculations.ARAPObject.Organization.LocalAccountingCurrency = ManSExchangeRate.BaseCurrency
	|
	|GROUP BY
	|	Calculations.Date,
	|	Calculations.RecorderNumber,
	|	Calculations.PaymentDate,
	|	Calculations.RecordType,
	|
	|	// Dimensions
	|	AnalyticsRegister.DimensionKey,
	|	Calculations.Organization,
	|	Calculations.Counterparty,
	|	Calculations.Partner,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	
	|	// Attributes
	|	Calculations.BusinessOperation,
	|	Calculations.ARAPDocument,
	|	Calculations.Order
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableVendorsARAPAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "VendorsARAPAccounting";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	Calculations.Date                      AS Period,
	|	Calculations.Date                      AS RecorderDate,
	|	Calculations.RecorderNumber         AS RecorderNumber,
	|	Calculations.PaymentDate               AS PaymentDate,
	|	Calculations.RecordType               AS RecordType,
	|	
	|	// Dimensions
	|	AnalyticsRegister.DimensionKey    AS AccountingDimensionByPartners,
	|	Calculations.Organization               AS Organization,
	|	Calculations.Counterparty                AS Counterparty,
	|	Calculations.Partner                   AS Partner,
	|	Calculations.Contract                   AS Contract,
	|	Calculations.LineOfBusiness   AS LineOfBusiness,
	|	
	|	Calculations.ARAPObject            AS ARAPObject,
	|	Calculations.Currency                    AS Currency,
	|	
	|	// Resources
	|	// The amount in the settlement currency.
	|	SUM(Calculations.Sum)              AS Sum,
	|	SUM(0)                          AS AmountDue,
	|	
	|	SUM(
	|		CASE 
	|			WHEN Calculations.Currency = Calculations.ARAPObject.Organization.LocalAccountingCurrency 
	|				THEN Calculations.Sum
	|			WHEN ISNULL(MutualSettlementsExchangeRate.CourseDenominator, 0) = 0 
	|				THEN Calculations.Sum
	|			ELSE CAST(Calculations.Sum * ISNULL(MutualSettlementsExchangeRate.CourseNumerator, 1) / ISNULL(MutualSettlementsExchangeRate.CourseDenominator, 1) AS NUMBER(31,2))
	|		END)                        AS SumCompl,
	|	SUM(
	|		CASE 
	|			WHEN Calculations.Currency = &CurrencyOfMan 
	|				THEN Calculations.Sum
	|			WHEN ISNULL(ManSExchangeRate.CourseDenominator, 0) = 0 
	|				THEN Calculations.Sum
	|			ELSE CAST(Calculations.Sum * ISNULL(MutualSettlementsExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1)  
	|			                                / (ISNULL(MutualSettlementsExchangeRate.CourseDenominator, 1) * ISNULL(ManSExchangeRate.CourseNumerator, 1)) AS NUMBER(31,2))
	|		END)                        AS SumMan,
	|	
	|	// Attributes
	|	Calculations.BusinessOperation     AS BusinessOperation,
	|	Calculations.ARAPDocument         AS ARAPDocument,
	|	Calculations.Currency                    AS DocumentCurrency,
	|	&FinRecordID           AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting,
	|	5                                 AS TypeOfOperationForSorting,
	|	Calculations.Order                   AS OrderOfOperationsWithinDocument,
	|	&SettlementTransaction           AS SettlementTransaction
	|
	|FROM (SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		DATETIME(1,1,1)                          AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.Organization
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		TabularSection.Sum                      AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		1                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustVendorPaymentSchedule)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		TabularSection.Date                       AS PaymentDate,
	|		VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.Organization
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		TabularSection.Sum                      AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		2                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustVendorPaymentSchedule)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		DATETIME(1,1,1)                          AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.Organization
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		-TabularSection.Sum                     AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		1                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Date                      AS Date,
	|		DocumentData.Number                     AS RecorderNumber,
	|		TabularSection.Date                       AS PaymentDate,
	|		VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|		
	|		TabularSection.ARAPObject.Organization AS Organization,
	|		CASE
	|			WHEN DocumentData.Counterparty <> VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN TabularSection.ARAPObject.Counterparty
	|			ELSE DocumentData.Organization
	|		END                                     AS Counterparty,
	|		TabularSection.Partner                    AS Partner,
	|		TabularSection.Contract                    AS Contract,
	|		TabularSection.LineOfBusiness    AS LineOfBusiness,
	|		
	|		TabularSection.ARAPObject             AS ARAPObject,
	|		TabularSection.Currency                     AS Currency,
	|		
	|		TabularSection.Sum                      AS Sum,
	|		
	|		DocumentData.BusinessOperation     AS BusinessOperation,
	|		DocumentData.ARAPDocument         AS ARAPDocument,
	|		2                                         AS Order
	|	
	|	FROM
	|		Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS TabularSection
	|		INNER JOIN
	|			Document.ARAPAccountingScheduleAdjustment AS DocumentData
	|		ON
	|			DocumentData.Ref = TabularSection.Ref
	|	WHERE
	|		TabularSection.Ref = &Ref
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule)
	|	) AS Calculations
	|
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS AnalyticsRegister
	|	ON
	|		Calculations.Organization = AnalyticsRegister.Organization
	|		AND Calculations.Partner = AnalyticsRegister.Partner
	|		AND Calculations.Counterparty = AnalyticsRegister.Counterparty
	|		AND Calculations.Contract = AnalyticsRegister.Contract
	|		AND Calculations.LineOfBusiness = AnalyticsRegister.LineOfBusiness
	|
	|	LEFT JOIN
	|		TTExchangeRates AS MutualSettlementsExchangeRate
	|	ON
	|		Calculations.ARAPObject = MutualSettlementsExchangeRate.ARAPObject
	|		AND Calculations.Currency = MutualSettlementsExchangeRate.Currency
	|		AND Calculations.ARAPObject.Organization.LocalAccountingCurrency = MutualSettlementsExchangeRate.BaseCurrency
	|
	|	LEFT JOIN
	|		TTExchangeRates AS ManSExchangeRate
	|	ON
	|		Calculations.ARAPObject = ManSExchangeRate.ARAPObject
	|		AND &CurrencyOfMan = ManSExchangeRate.Currency
	|		AND Calculations.ARAPObject.Organization.LocalAccountingCurrency = ManSExchangeRate.BaseCurrency
	|
	|GROUP BY
	|	Calculations.Date,
	|	Calculations.RecorderNumber,
	|	Calculations.PaymentDate,
	|	Calculations.RecordType,
	|
	|	// Dimensions
	|	AnalyticsRegister.DimensionKey,
	|	Calculations.Organization,
	|	Calculations.Counterparty,
	|	Calculations.Partner,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	
	|	// Attributes
	|	Calculations.BusinessOperation,
	|	Calculations.ARAPDocument,
	|	Calculations.Order
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates(QueryTexts)
	
	TempTableName = "TTExchangeRates";
	
	QueryText = "
		|SELECT DISTINCT
		|	ISNULL(ISNULL(IntercompanyContracts.Ref, CounterpartyContracts.Ref), UNDEFINED) AS Contract,
		|	ISNULL(ISNULL(IntercompanyContracts.Date, CounterpartyContracts.Date), &Period) AS Date,
		|	ISNULL(ISNULL(IntercompanyContracts.ContractRateOption, CounterpartyContracts.ContractRateOption), VALUE(Enum.ContractRateOptions.Mutable)) AS ContractRateOption,
		|	ISNULL(ISNULL(IntercompanyContracts.ARAPCurrency, CounterpartyContracts.ARAPCurrency), ARAPObjects.Currency) AS ARAPCurrency,
		|	ARAPObjects.Currency AS DocumentCurrency,
		|	ARAPObjects.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Object AS CalculationObjectObject,
		|	ARAPObjects.ARAPObjectType AS ARAPObjectType
		|INTO TTCalculationObjects_
		|FROM
		|	Document.ARAPAccountingScheduleAdjustment.NewSchedule_ AS DocumentData
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON (DocumentData.ARAPObject = ARAPObjects.Ref)
		|		LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|		ON (ARAPObjects.Contract = IntercompanyContracts.Ref)
		|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON (ARAPObjects.Contract = CounterpartyContracts.Ref)
		|WHERE
		|	DocumentData.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ARAPObjects.Object AS CalculationObjectObject,
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Date AS DateOfCourse,
		|	DocumentCurrenciesAndRates.DocumentCurrency AS DocumentCurrency,
		|	DocumentCurrenciesAndRates.ARAPCurrency AS ARAPCurrency,
		|	DocumentCurrenciesAndRates.LocalAccountingCurrency AS LocalAccountingCurrency,
		|	DocumentCurrenciesAndRates.RateARAPCurrencyNumerator AS RateARAPCurrencyNumerator,
		|	DocumentCurrenciesAndRates.RateARAPCurrencyDenominator AS RateARAPCurrencyDenominator,
		|	DocumentCurrenciesAndRates.RateManagementAccountingCurrencyNumerator AS RateManagementAccountingCurrencyNumerator,
		|	DocumentCurrenciesAndRates.RateManagementAccountingCurrencyDenominator AS RateManagementAccountingCurrencyDenominator,
		|	DocumentCurrenciesAndRates.RateDocumentCurrencyNumerator AS RateDocumentCurrencyNumerator,
		|	DocumentCurrenciesAndRates.RateDocumentCurrencyDenominator AS RateDocumentCurrencyDenominator
		|INTO TTFixedRate
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|		INNER JOIN TTCalculationObjects_ AS TTCalculationObjects_
		|		ON ARAPObjects.Contract = TTCalculationObjects_.Contract
		|		INNER JOIN InformationRegister.DocumentCurrenciesAndRates AS DocumentCurrenciesAndRates
		|		ON ARAPObjects.Object = DocumentCurrenciesAndRates.Document
		|WHERE
		|	ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
		|	AND TTCalculationObjects_.ContractRateOption = VALUE(Enum.ContractRateOptions.FixedAsOfShipmentDate)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ExRates.ARAPObject  AS ARAPObject,
		|	ExRates.Currency          AS Currency,
		|	ExRates.BaseCurrency   AS BaseCurrency,
		|	ExRates.CourseNumerator   AS CourseNumerator,
		|	ExRates.CourseDenominator AS CourseDenominator
		|INTO TTExchangeRates
		|FROM
		|	(SELECT
		|		TTCalculationObjects_.ARAPObject AS ARAPObject,
		|		TTCalculationObjects_.ARAPCurrency AS Currency,
		|		TTCalculationObjects_.LocalAccountingCurrency AS BaseCurrency,
		|		RatesByContracts.Period AS DateOfCourse,
		|		RatesByContracts.CourseNumerator AS CourseNumerator,
		|		RatesByContracts.CourseDenominator AS CourseDenominator
		|	FROM
		|		TTCalculationObjects_ AS TTCalculationObjects_
		|			INNER JOIN InformationRegister.ARAPAccountingExchangeRatesForContracts.SliceLast(
		|					&Period,
		|					Contract IN
		|						(SELECT
		|							TTCalculationObjects_.Contract
		|						FROM
		|							TTCalculationObjects_)) AS RatesByContracts
		|			ON TTCalculationObjects_.Contract = RatesByContracts.Contract
		|	WHERE
		|		TTCalculationObjects_.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|		AND TTCalculationObjects_.DocumentCurrency = TTCalculationObjects_.LocalAccountingCurrency
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTCalculationObjects_.ARAPObject,
		|		RelativeCourses.Currency,
		|		RelativeCourses.BaseCurrency,
		|		RelativeCourses.Period,
		|		RelativeCourses.CourseNumerator,
		|		RelativeCourses.CourseDenominator
		|	FROM
		|		TTCalculationObjects_ AS TTCalculationObjects_
		|			INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(
		|					&Period,
		|					Currency IN
		|							(&ArrayOfCurrencies)
		|						AND BaseCurrency IN
		|							(SELECT
		|								TTCalculationObjects_.LocalAccountingCurrency
		|							FROM
		|								TTCalculationObjects_)) AS RelativeCourses
		|			ON TTCalculationObjects_.LocalAccountingCurrency = RelativeCourses.BaseCurrency
		|	WHERE
		|		NOT(TTCalculationObjects_.ARAPCurrency = RelativeCourses.Currency
		|					AND TTCalculationObjects_.ContractRateOption = VALUE(Enum.ContractRateOptions.SpecifiedInContract)
		|					AND TTCalculationObjects_.DocumentCurrency = TTCalculationObjects_.LocalAccountingCurrency)
		|		AND NOT TTCalculationObjects_.CalculationObjectObject IN
		|					(SELECT
		|						T.CalculationObjectObject
		|					FROM
		|						TTFixedRate AS T)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTFixedRate.ARAPObject,
		|		TTFixedRate.DocumentCurrency,
		|		TTFixedRate.LocalAccountingCurrency,
		|		TTFixedRate.DateOfCourse,
		|		TTFixedRate.RateDocumentCurrencyNumerator,
		|		TTFixedRate.RateDocumentCurrencyDenominator
		|	FROM
		|		TTFixedRate AS TTFixedRate
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTFixedRate.ARAPObject,
		|		TTFixedRate.ARAPCurrency,
		|		TTFixedRate.LocalAccountingCurrency,
		|		TTFixedRate.DateOfCourse,
		|		TTFixedRate.RateARAPCurrencyNumerator,
		|		TTFixedRate.RateARAPCurrencyDenominator
		|	FROM
		|		TTFixedRate AS TTFixedRate
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTFixedRate.ARAPObject,
		|		&CurrencyOfMan,
		|		TTFixedRate.LocalAccountingCurrency,
		|		TTFixedRate.DateOfCourse,
		|		TTFixedRate.RateManagementAccountingCurrencyNumerator,
		|		TTFixedRate.RateManagementAccountingCurrencyDenominator
		|	FROM
		|		TTFixedRate AS TTFixedRate
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTFixedRate.ARAPObject,
		|		TTFixedRate.LocalAccountingCurrency,
		|		TTFixedRate.LocalAccountingCurrency,
		|		TTFixedRate.DateOfCourse,
		|		1,
		|		1
		|	FROM
		|		TTFixedRate AS TTFixedRate) AS ExRates
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTCalculationObjects_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTFixedRate
		|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

#EndRegion

Function QueryTextForFillingData(SelectionByPrimaryDocument = False) Export 
	
	QueryText = "
		|SELECT ALLOWED
		|	TRUE                                                 AS CustomersARAPAccounting,
		|	CustomersARAPAccounting.AccountingDimensionByPartners            AS AccountingDimensionByPartners, 
		|	DimensionKeysOfAccountingByPartners.Partner                 AS Partner,
		|	CustomersARAPAccounting.ARAPObject                       AS ARAPObject,
		|	DimensionKeysOfAccountingByPartners.Contract                 AS Contract,
		|	DimensionKeysOfAccountingByPartners.LineOfBusiness AS LineOfBusiness,
		|	CustomersARAPAccounting.Currency                               AS Currency,
		|	CASE
		|		WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CustomersARAPAccounting.Sum
		|		ELSE -CustomersARAPAccounting.Sum
		|	END                                                  AS Sum,
		|	CustomersARAPAccounting.PaymentDate                          AS PaymentDate,
		|	CustomersARAPAccounting.RecorderDate                     AS RecorderDate,
		|	CustomersARAPAccounting.Recorder                          AS Recorder
		|INTO TTCalculationsData
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	&FilterCriterion
		|	AND Active
		|	AND Sum <> 0
		|	AND BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|	AND BusinessOperation <> VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
		|	
		|
		|UNION ALL
		|
		|SELECT
		|	FALSE                                                   AS CustomersARAPAccounting,
		|	VendorsARAPAccounting.AccountingDimensionByPartners         AS AccountingDimensionByPartners, 
		|	DimensionKeysOfAccountingByPartners.Partner                 AS Partner,
		|	VendorsARAPAccounting.ARAPObject                    AS ARAPObject,
		|	DimensionKeysOfAccountingByPartners.Contract                 AS Contract,
		|	DimensionKeysOfAccountingByPartners.LineOfBusiness AS LineOfBusiness,
		|	VendorsARAPAccounting.Currency                            AS Currency,
		|	CASE
		|		WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN VendorsARAPAccounting.Sum
		|		ELSE -VendorsARAPAccounting.Sum
		|	END                                                  AS Sum,
		|	VendorsARAPAccounting.PaymentDate                       AS PaymentDate,
		|	VendorsARAPAccounting.RecorderDate                  AS RecorderDate,
		|	VendorsARAPAccounting.Recorder                       AS Recorder
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|		LEFT JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	&FilterCriterion
		|	AND Active
		|	AND Sum <> 0
		|	AND BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|	AND BusinessOperation <> VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Calculations.BusinessOperation   AS BusinessOperation,
		|	Calculations.Partner                 AS Partner,
		|	Calculations.ARAPObject          AS ARAPObject,
		|	Calculations.Contract                 AS Contract,
		|	Calculations.LineOfBusiness AS LineOfBusiness,
		|	Calculations.Currency                  AS Currency,
		|	SUM(Calculations.Sum)            AS Sum,
		|	Calculations.Date                    AS Date
		|FROM (SELECT
		|		VALUE(Enum.BusinessTransactions.AdjustCustomerPaymentSchedule) AS BusinessOperation,
		|		Calculations.Partner                 AS Partner,
		|		Calculations.ARAPObject          AS ARAPObject,
		|		Calculations.Contract                 AS Contract,
		|		Calculations.LineOfBusiness AS LineOfBusiness,
		|		Calculations.Currency                  AS Currency,
		|		Calculations.Sum                   AS Sum,
		|		CASE
		|			WHEN Calculations.PaymentDate = DATETIME(1, 1, 1)
		|				THEN BEGINOFPERIOD(Calculations.RecorderDate, DAY)
		|			ELSE Calculations.PaymentDate
		|		END                           AS Date
		|	FROM
		|		TTCalculationsData AS Calculations
		|	WHERE
		|		Calculations.Sum > 0
		|		AND Calculations.CustomersARAPAccounting
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.BusinessTransactions.AdjustVendorPaymentSchedule) AS BusinessOperation,
		|		Calculations.Partner                 AS Partner,
		|		Calculations.ARAPObject          AS ARAPObject,
		|		Calculations.Contract                 AS Contract,
		|		Calculations.LineOfBusiness AS LineOfBusiness,
		|		Calculations.Currency                  AS Currency,
		|		Calculations.Sum                   AS Sum,
		|		CASE
		|			WHEN Calculations.PaymentDate = DATETIME(1, 1, 1)
		|				THEN BEGINOFPERIOD(Calculations.RecorderDate, DAY)
		|			ELSE Calculations.PaymentDate
		|		END                           AS Date
		|	FROM
		|		TTCalculationsData AS Calculations
		|	WHERE
		|		Calculations.Sum > 0
		|		AND NOT Calculations.CustomersARAPAccounting
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.BusinessTransactions.AdjustCustomerPrepaymentRepaymentSchedule) AS BusinessOperation,
		|		Calculations.Partner                 AS Partner,
		|		Calculations.ARAPObject          AS ARAPObject,
		|		Calculations.Contract                 AS Contract,
		|		Calculations.LineOfBusiness AS LineOfBusiness,
		|		Calculations.Currency                  AS Currency,
		|		-Calculations.Sum                  AS Sum,
		|		Calculations.PaymentDate             AS Date
		|	FROM
		|		TTCalculationsData AS Calculations
		|	WHERE
		|		Calculations.Sum < 0
		|		AND Calculations.CustomersARAPAccounting
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		VALUE(Enum.BusinessTransactions.AdjustVendorPrepaymentRepaymentSchedule) AS BusinessOperation,
		|		Calculations.Partner                 AS Partner,
		|		Calculations.ARAPObject          AS ARAPObject,
		|		Calculations.Contract                 AS Contract,
		|		Calculations.LineOfBusiness AS LineOfBusiness,
		|		Calculations.Currency                  AS Currency,
		|		-Calculations.Sum                  AS Sum,
		|		Calculations.PaymentDate             AS Date
		|	FROM
		|		TTCalculationsData AS Calculations
		|	WHERE
		|		Calculations.Sum < 0
		|		AND NOT Calculations.CustomersARAPAccounting
		|	) AS Calculations
		|
		|GROUP BY
		|	Calculations.BusinessOperation,
		|	Calculations.Partner,
		|	Calculations.ARAPObject,
		|	Calculations.Contract,
		|	Calculations.LineOfBusiness,
		|	Calculations.Currency,
		|	Calculations.Date
		|
		|ORDER BY
		|	Date,
		|	ARAPObject
		|
		|TOTALS BY
		|	BusinessOperation
		|";
	
	If SelectionByPrimaryDocument Then
		QueryText = StrReplace(QueryText, "&FilterCriterion", "ARAPDocument = &ARAPDocument AND Recorder REFS Document.OBEntryARAP");
	Else
		QueryText = StrReplace(QueryText, "&FilterCriterion", "Recorder = &ARAPDocument");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextOfDocumentsBasedOn() Export
	
	Return "
		|SELECT ALLOWED
		|	ARAPAccountingScheduleAdjustment.Ref AS Ref,
		|	ARAPAccountingScheduleAdjustment.DocumentBasis AS DocumentBasis,
		|	ARAPAccountingScheduleAdjustment.BusinessOperation AS BusinessOperation
		|FROM
		|	Document.ARAPAccountingScheduleAdjustment AS ARAPAccountingScheduleAdjustment
		|WHERE
		|	ARAPAccountingScheduleAdjustment.ARAPDocument = &ARAPDocumentOfAdjustment
		|	AND ARAPAccountingScheduleAdjustment.Ref <> &Ref
		|	AND ARAPAccountingScheduleAdjustment.Posted";
	
EndFunction

Function LastAdjustment(TableRows, CurrentRow = Undefined) Export
	Result = CurrentRow;
	For Each AdjustmentLine In TableRows Do
		If CurrentRow = Undefined Then
			CurrentRow = AdjustmentLine;
			If TypeOf(AdjustmentLine.DocumentBasis) <> Type("DocumentRef.ARAPAccountingScheduleAdjustment") Then
				Result = AdjustmentLine;
			EndIf;
		EndIf;
		If AdjustmentLine.DocumentBasis = CurrentRow.Ref Then
			Result = LastAdjustment(TableRows, AdjustmentLine.Ref);
			Break;
		EndIf;
	EndDo;
	Return Result;
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
			RequestHasSource,,);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
