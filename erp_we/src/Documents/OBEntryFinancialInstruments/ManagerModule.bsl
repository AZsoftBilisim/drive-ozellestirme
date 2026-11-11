#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then


#Region Public

#Region Posting

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection:
//     of Table elements<Register Name> - Assignment tables - a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryFinancialInstruments") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// Create a motion initialization request
	
	Query = New Query;
	FillInInitializationParameters(Query, DocumentRef);
	
	////////////////////////////////////////////////////////////////////////////
	// Let's form the request text
	
	QueryTexts = New ValueList;
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsToSupplementTextsOfRequests(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsAndAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	OBEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
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
	OBEntryLocalization.EnteringFinancialInstrumentBalancesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOnFinancialInstrumentsRequestTextTTReflectionInLocalAccounting();
EndFunction

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export
	
	DateOfRemainingGoods = New Boundary(Date, BoundaryType.Including);
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings Then
		Return BalancesOnSettlementsUnderLoanAndDepositAgreements(DateOfRemainingGoods, Companies);
	EndIf;
	
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyFieldsArray = New Array;
	KeyFieldsArray.Add("Organization");
	
	Return KeyFieldsArray;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// Adds a command to create a document based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryFinancialInstruments);
	
EndFunction

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

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	SelectedOperation = Undefined;
	
	If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		SelectedOperation = Parameters.Key.BusinessOperation;
	ElsIf Parameters.Property("FillingValues") Then
		Parameters.FillingValues.Property("BusinessOperation", SelectedOperation);
	ElsIf Parameters.Property("CopyingValue") Then
		SelectedOperation = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.CopyingValue,"BusinessOperation");
	ElsIf Parameters.Property("FilterByTransactionTypes") And Parameters.FilterByTransactionTypes.Count() = 1 Then
		SelectedOperation = Parameters.FilterByTransactionTypes[0].Value;
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", SelectedOperation);
		Parameters.Insert("FillingValues", FillingValues);
		If Parameters.Property("Organization") Then
			FillingValues.Insert("Organization", Parameters.Organization);
		EndIf;
		If Parameters.Property("RecordInOperationalAccounting") Then
			FillingValues.Insert("RecordInOperationalAccounting", Parameters.RecordInOperationalAccounting);
		EndIf;
		If Parameters.Property("PostInFinancialAndTaxAccounting") Then
			FillingValues.Insert("PostInFinancialAndTaxAccounting", Parameters.PostInFinancialAndTaxAccounting);
		EndIf;
		If Parameters.Property("RecordInMA") Then
			FillingValues.Insert("RecordInMA", Parameters.RecordInMA);
		EndIf;
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If Data.Ref <> Undefined Then
		Presentation = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Data.Ref,
			Data.Number,
			Data.Date,
			Data.BusinessOperation);
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(DataOfTabularPartCalculationsOnFinancialInstruments.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntryFinancialInstruments AS DocumentData
		|		LEFT JOIN Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS DataOfTabularPartCalculationsOnFinancialInstruments
		|		ON DocumentData.Ref = DataOfTabularPartCalculationsOnFinancialInstruments.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	DocumentData.EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.DeletionMark,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	DocumentData.Posted,
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Number",  Attributes.Number);
	
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                 Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                    Attributes.RecordInMA);
	Query.SetParameter("Comment",                    Attributes.Comment);
	Query.SetParameter("Posted",                       Attributes.Posted);
	Query.SetParameter("DeletionMark",                Attributes.DeletionMark);
	Query.SetParameter("EmployeeResponsible",                  Attributes.EmployeeResponsible);
	Query.SetParameter("DocumentAmount",                 Attributes.DocumentAmount);
	Query.SetParameter("EmptyAssignment",               Catalogs.Assignments.EmptyRef());
	Query.SetParameter("Patch",                    Attributes.Patch);
	Query.SetParameter("ReversedDocument",           Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",           Attributes.CorrectedDocument);
	Query.SetParameter("BusinessTransactionSetting", Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document." + Metadata.Documents.OBEntryFinancialInstruments.Name));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref"     ,               Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization",               Query.Parameters.Organization);
	QueryAnalyst.SetParameter("BusinessOperation",     Query.Parameters.BusinessOperation);
	QueryAnalyst.SetParameter("RecordInOperationalAccounting", Query.Parameters.RecordInOperationalAccounting);
	
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	
	QueryAnalyst.Text = "SELECT DISTINCT
		|	&Organization AS Organization,
		|	FinancialInstrumentsARAP.Partner AS Partner,
		|	FinancialInstrumentsARAP.Counterparty AS Counterparty,
		|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
		|	FinancialInstrumentsARAP.Contract.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS FinancialInstrumentsARAP
		|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|		ON (&Organization = RegisterAccountingAnalyticsForPartners.Organization)
		|			AND FinancialInstrumentsARAP.Partner = RegisterAccountingAnalyticsForPartners.Partner
		|			AND FinancialInstrumentsARAP.Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
		|			AND (VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract)
		|			AND (VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness)
		|WHERE
		|	FinancialInstrumentsARAP.Ref = &Ref
		|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings)
		|	AND RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL";
	
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates";
	
	QueryText =
	"SELECT
	|	CurrencyRatesCut.Currency,
	|	CurrencyRatesCut.CourseNumerator / CurrencyRatesCut.CourseDenominator AS ConversionFactor_
	|	
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			Currency IN
	|				(SELECT
	|					&ManagementAccountingCurrency
	|				
	|				UNION ALL
	|				
	|				SELECT DISTINCT
	|					EnteringLoanBalancesDepositsLoans.Contract.ARAPCurrency
	|				FROM
	|					Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS EnteringLoanBalancesDepositsLoans
	|				WHERE
	|					EnteringLoanBalancesDepositsLoans.Ref = &Ref
	|				) AND BaseCurrency = &LocalAccountingCurrency
	|	) AS CurrencyRatesCut";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	InitializeAnalyticsKeysForPartners(Query);
	
	QueryText =
	// The balance of the principal debt on loans and borrowings
	"SELECT
	|	SettlementsOnCreditsDeposits.LineNumber          AS LineNumber,
	|	&Period                                         AS Period,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                           AS RecordType,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	SettlementsOnCreditsDeposits.Contract              AS Contract,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|	END                                           AS ScheduleType,
	|	SettlementsOnCreditsDeposits.AmountType             AS AmountType,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.Contract.CashFlowItemOfReceiptIssuie
	|		ELSE SettlementsOnCreditsDeposits.Contract.CashFlowItemOfPrincipalDebt
	|	END                                           AS DimensionItem,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.Sum 
	|		ELSE -SettlementsOnCreditsDeposits.Sum 
	|	END                                           AS Sum,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN 
	|			CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE
	|			-CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|	END                                           AS SumMan,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.SumCompl
	|		ELSE -SettlementsOnCreditsDeposits.SumCompl 
	|	END                                           AS SumCompl,
	|	SettlementsOnCreditsDeposits.Contract.ARAPCurrency AS Currency,
	|	SettlementsOnCreditsDeposits.RowID  AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS SettlementsOnCreditsDeposits
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfContracts
	|		ON ExchangeRatesOfContracts.Currency = SettlementsOnCreditsDeposits.Contract.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND SettlementsOnCreditsDeposits.Counterparty = Dimension.Counterparty
	|		AND SettlementsOnCreditsDeposits.Partner = Dimension.Partner
	|		AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings)
	|	AND &RecordInOperationalAccounting
	|	AND SettlementsOnCreditsDeposits.Ref = &Ref
	|	AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|	AND SettlementsOnCreditsDeposits.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|
	|UNION ALL
	|
	// The balance of the principal debt on deposits and loans issued
	|SELECT
	|	SettlementsOnCreditsDeposits.LineNumber          AS LineNumber,
	|	&Period                                         AS Period,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0 
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END                                           AS RecordType,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	SettlementsOnCreditsDeposits.Contract              AS Contract,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Tranches)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|	END                                           AS ScheduleType,
	|	SettlementsOnCreditsDeposits.AmountType             AS AmountType,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.Contract.CashFlowItemOfReceiptIssuie
	|		ELSE SettlementsOnCreditsDeposits.Contract.CashFlowItemOfPrincipalDebt
	|	END                                           AS DimensionItem,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.Sum 
	|		ELSE -SettlementsOnCreditsDeposits.Sum 
	|	END                                           AS AmountInCurrency,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN 
	|			CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE
	|			-CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|	END                                            AS SumMan,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.SumCompl
	|		ELSE -SettlementsOnCreditsDeposits.SumCompl 
	|	END                                            AS SumCompl,
	|	SettlementsOnCreditsDeposits.Contract.ARAPCurrency AS Currency,
	|	SettlementsOnCreditsDeposits.RowID  AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS SettlementsOnCreditsDeposits
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfContracts
	|		ON ExchangeRatesOfContracts.Currency = SettlementsOnCreditsDeposits.Contract.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND SettlementsOnCreditsDeposits.Counterparty = Dimension.Counterparty
	|		AND SettlementsOnCreditsDeposits.Partner = Dimension.Partner
	|		AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings)
	|	AND &RecordInOperationalAccounting
	|	AND SettlementsOnCreditsDeposits.Ref = &Ref
	|	AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.PrincipalDebt)
	|	AND SettlementsOnCreditsDeposits.Contract.ContractKind <> VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|
	|UNION ALL
	|
	// Balance on paid \accrued interest and commission loans
	|SELECT
	|	SettlementsOnCreditsDeposits.LineNumber          AS LineNumber,
	|	&Period                                         AS Period,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum < 0 
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END                                           AS RecordType,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	SettlementsOnCreditsDeposits.Contract              AS Contract,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum < 0
	|		THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)
	|	END                                           AS ScheduleType,
	|	SettlementsOnCreditsDeposits.AmountType             AS AmountType,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN SettlementsOnCreditsDeposits.Contract.IncomeExpenseItemForInterestAccruals
	|		WHEN SettlementsOnCreditsDeposits.Sum > 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN SettlementsOnCreditsDeposits.Contract.IncomeExpenseItemForFeeAccruals
	|		WHEN SettlementsOnCreditsDeposits.Sum < 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN SettlementsOnCreditsDeposits.Contract.CashFlowItemOfInterestPayment
	|		WHEN SettlementsOnCreditsDeposits.Sum < 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN SettlementsOnCreditsDeposits.Contract.CashFlowItemOfFeePayment
	|	END                                           AS DimensionItem,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.Sum 
	|		ELSE -SettlementsOnCreditsDeposits.Sum 
	|	END                                           AS AmountInCurrency,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN 
	|			CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE
	|			-CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|	END                                           AS SumMan,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.SumCompl
	|		ELSE -SettlementsOnCreditsDeposits.SumCompl 
	|	END                                           AS SumCompl,
	|	SettlementsOnCreditsDeposits.Contract.ARAPCurrency AS Currency,
	|	SettlementsOnCreditsDeposits.RowID  AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS SettlementsOnCreditsDeposits
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfContracts
	|		ON ExchangeRatesOfContracts.Currency = SettlementsOnCreditsDeposits.Contract.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND SettlementsOnCreditsDeposits.Counterparty = Dimension.Counterparty
	|		AND SettlementsOnCreditsDeposits.Partner = Dimension.Partner
	|		AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings)
	|	AND &RecordInOperationalAccounting
	|	AND SettlementsOnCreditsDeposits.Ref = &Ref
	|	AND SettlementsOnCreditsDeposits.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|	AND SettlementsOnCreditsDeposits.AmountType IN (
	|		VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests),
	|		VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|	)
	|
	|UNION ALL
	|
	// Balance on paid\accrued interest and commission deposits
	|SELECT
	|	SettlementsOnCreditsDeposits.LineNumber          AS LineNumber,
	|	&Period                                         AS Period,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum < 0 
	|		THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                           AS RecordType,
	|	ISNULL(Dimension.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	SettlementsOnCreditsDeposits.Contract              AS Contract,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum < 0
	|		THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals)
	|	END                                           AS ScheduleType,
	|	SettlementsOnCreditsDeposits.AmountType             AS AmountType,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN SettlementsOnCreditsDeposits.Contract.IncomeExpenseItemForInterestAccruals
	|		WHEN SettlementsOnCreditsDeposits.Sum > 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN SettlementsOnCreditsDeposits.Contract.IncomeExpenseItemForFeeAccruals
	|		WHEN SettlementsOnCreditsDeposits.Sum < 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests)
	|			THEN SettlementsOnCreditsDeposits.Contract.CashFlowItemOfInterestPayment
	|		WHEN SettlementsOnCreditsDeposits.Sum < 0
	|			AND SettlementsOnCreditsDeposits.AmountType = VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|			THEN SettlementsOnCreditsDeposits.Contract.CashFlowItemOfFeePayment
	|	END                                           AS DimensionItem,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.Sum 
	|		ELSE -SettlementsOnCreditsDeposits.Sum 
	|	END                                           AS AmountInCurrency,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN 
	|			CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|		ELSE
	|			-CASE WHEN SettlementsOnCreditsDeposits.Contract.ARAPCurrency = &ManagementAccountingCurrency
	|				THEN SettlementsOnCreditsDeposits.Sum 
	|				ELSE SettlementsOnCreditsDeposits.Sum * ISNULL(ExchangeRatesOfContracts.ConversionFactor_, 1) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|			END
	|	END                                           AS SumMan,
	|	CASE WHEN SettlementsOnCreditsDeposits.Sum > 0
	|		THEN SettlementsOnCreditsDeposits.SumCompl
	|		ELSE -SettlementsOnCreditsDeposits.SumCompl 
	|	END                                           AS SumCompl,
	|	SettlementsOnCreditsDeposits.Contract.ARAPCurrency AS Currency,
	|	SettlementsOnCreditsDeposits.RowID  AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS SettlementsOnCreditsDeposits
	|		LEFT JOIN TTExchangeRates AS ExchangeRatesOfContracts
	|		ON ExchangeRatesOfContracts.Currency = SettlementsOnCreditsDeposits.Contract.ARAPCurrency
	|		LEFT JOIN TTExchangeRates AS ManExchangeRates
	|		ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND SettlementsOnCreditsDeposits.Counterparty = Dimension.Counterparty
	|		AND SettlementsOnCreditsDeposits.Partner = Dimension.Partner
	|		AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings)
	|	AND &RecordInOperationalAccounting
	|	AND SettlementsOnCreditsDeposits.Ref = &Ref
	|	AND SettlementsOnCreditsDeposits.Contract.ContractKind <> VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|	AND SettlementsOnCreditsDeposits.AmountType IN (
	|		VALUE(Enum.LoanAndDepositScheduleAmountTypes.Interests),
	|		VALUE(Enum.LoanAndDepositScheduleAmountTypes.Fee)
	|	)
	|
	|ORDER BY
	|	ScheduleType DESC,
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	CASE 
	|		WHEN COUNT(DISTINCT DataOfTabularPartCalculationsOnFinancialInstruments.Contract.ARAPCurrency) > 1
	|	THEN 0
	|		ELSE SUM(ISNULL(DataOfTabularPartCalculationsOnFinancialInstruments.Sum, 0))
	|	END AS Sum,
	|	CASE 
	|		WHEN COUNT(DataOfTabularPartCalculationsOnFinancialInstruments.Contract.ARAPCurrency) = 0
	|	THEN DocumentData.Organization.LocalAccountingCurrency
	|		WHEN COUNT(DISTINCT DataOfTabularPartCalculationsOnFinancialInstruments.Contract.ARAPCurrency) > 1
	|	THEN UNDEFINED
	|		ELSE MAX(DataOfTabularPartCalculationsOnFinancialInstruments.Contract.ARAPCurrency)
	|	END AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryFinancialInstruments AS DocumentData
	|		LEFT JOIN Document.OBEntryFinancialInstruments.FinancialInstrumentsARAP AS
	|			DataOfTabularPartCalculationsOnFinancialInstruments
	|		ON DocumentData.Ref = DataOfTabularPartCalculationsOnFinancialInstruments.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntryFinancialInstruments";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryFinancialInstruments));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
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
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	OBEntryLocalization.EnteringFinancialInstrumentBalancesAddPrintCommands(PrintCommands);
	
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
	Return
EndProcedure

#EndRegion

#Region ServiceProceduresForFillingInAccordingToOperationalAccountingData

Function BalancesOnSettlementsUnderLoanAndDepositAgreements(DateOfRemainingGoods, CompanyArray)
	
	Query = New Query("SELECT
		|	""FinancialInstrumentsARAP"" AS TablePartToFillIn,
		|	AnalyticsData.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.OBEntryDebtOutstandingOfLoansAndBorrowings) AS BusinessOperation,
		|	AnalyticsData.Partner,
		|	AnalyticsData.Counterparty,
		|	FinancialInstrumentsARAPBalance.Contract,
		|	SUM(CASE
		|			WHEN FinancialInstrumentsARAPBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
		|				THEN -1
		|			ELSE 1
		|		END * FinancialInstrumentsARAPBalance.SumBalance) AS Sum,
		|	SUM(CASE
		|			WHEN FinancialInstrumentsARAPBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
		|				THEN -1
		|			ELSE 1
		|		END * FinancialInstrumentsARAPBalance.SumComplBalance) AS SumCompl,
		|	SUM(CASE
		|			WHEN FinancialInstrumentsARAPBalance.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
		|				THEN -1
		|			ELSE 1
		|		END * FinancialInstrumentsARAPBalance.SumManBalance) AS SumMan,
		|	FinancialInstrumentsARAPBalance.AmountType
		|FROM
		|	AccumulationRegister.FinancialInstrumentsARAP.Balance(&Date, ) AS FinancialInstrumentsARAPBalance
		|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS AnalyticsData
		|		ON FinancialInstrumentsARAPBalance.AccountingDimensionByPartners = AnalyticsData.DimensionKey
		|			AND (AnalyticsData.Organization IN (&CompanyArray))
		|
		|GROUP BY
		|	AnalyticsData.Counterparty,
		|	FinancialInstrumentsARAPBalance.AmountType,
		|	AnalyticsData.Organization,
		|	AnalyticsData.Partner,
		|	FinancialInstrumentsARAPBalance.Contract
		|
		|ORDER BY
		|	Organization");
	
	Query.Parameters.Insert("CompanyArray", CompanyArray);
	Query.Parameters.Insert("Date",              DateOfRemainingGoods);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
