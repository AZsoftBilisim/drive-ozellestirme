#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
// 	Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//              .
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	#Region OtherExpenses
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object.OtherExpenses";
	ChoiceParameters.AssetRef                = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	ChoiceParameters.ChoosingExpenseItem   = True;
	ChoiceParameters.DimensionOfExpenses     = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("OtherExpensesDimensionOfExpenses");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	#EndRegion
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

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
//     of Table elements<Register name> - data table to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryOtherExpenses") Then
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
	QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
	QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	OBEntryLocalization.EnteringBalancesOtherExpensesSupplementTextsOfRequestsForHolding(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
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
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringBalancesOtherExpensesRegisterAccountingMechanisms(DocumentMechanisms);
	
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
	OBEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
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
	OBEntryLocalization.EnteringBalancesOtherExpensesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOtherExpensesForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.EnteringBalancesOtherExpensesRequestTextTTReflectedInLocalAccounting();
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
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryOfOtherExpenses Then
		
		Return BalancesOfOtherExpenses(DateOfRemainingGoods, Companies, AdditionalSelection);
		
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
	KeyFieldsArray.Add("Department");
	
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
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryOtherExpenses);
	
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

#Region InitializingDocumentAndDocumentParameters

// Initialization parameters for registering invoices received
//  Parameters:
//    ObjectData - DocumentObject.OBEntryOtherExpenses - Object of the balance entry document
//
//  Returns:
//    See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
Function InitializeParametersForVATActivities(ObjectData) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization             = ObjectData.Organization;
	FillParameters.Date                    = ObjectData.Date;
	FillParameters.PurchaseOfGoods     = True;
	
	Return FillParameters;
	
EndFunction

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
		If Parameters.Property("PostInCostAccounting") Then
			FillingValues.Insert("PostInCostAccounting", Parameters.PostInCostAccounting);
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
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Department AS Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.PostInCostAccounting AS PostInCostAccounting,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(DataOfTabularPartOtherExpenses.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntryOtherExpenses AS DocumentData
		|		LEFT JOIN Document.OBEntryOtherExpenses.OtherExpenses AS DataOfTabularPartOtherExpenses
		|		ON DocumentData.Ref = DataOfTabularPartOtherExpenses.Ref
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
		|	DocumentData.Currency,
		|	DocumentData.Department,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	DocumentData.EmployeeResponsible,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.DeletionMark,
		|	DocumentData.Posted,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	DocumentData.PostInCostAccounting,
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();

	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Number",  Attributes.Number);
	
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("Department",                  Attributes.Department);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                 Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                    Attributes.RecordInMA);
	Query.SetParameter("Comment",                    Attributes.Comment);
	Query.SetParameter("Posted",                       Attributes.Posted);
	Query.SetParameter("Currency",                         Attributes.Currency);
	Query.SetParameter("DeletionMark",                Attributes.DeletionMark);
	Query.SetParameter("EmployeeResponsible",                  Attributes.EmployeeResponsible);
	Query.SetParameter("DocumentAmount",                 Attributes.DocumentAmount);
	Query.SetParameter("EmptyAssignment",               Catalogs.Assignments.EmptyRef());
	Query.SetParameter("Patch",                    Attributes.Patch);
	Query.SetParameter("ReversedDocument",           Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",           Attributes.CorrectedDocument);
	Query.SetParameter("BusinessTransactionSetting", Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document." + Metadata.Documents.OBEntryOtherExpenses.Name));
	Query.SetParameter("PostInCostAccounting",
		Attributes.PostInCostAccounting
		And CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Attributes.Period), True));
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	Query.SetParameter("TaxationOfOrganization",     AccountingParametersForOrganization.BasicTaxationVATSales);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField = "SELECT
		|	""OtherExpenses""                                                       AS TabularSectionName,
		|	DocumentTable.LineNumber                                            AS LineNumber,
		|	VALUE(Catalog.Partners.EmptyRef)                              AS Vendor,
		|	VALUE(Catalog.Counterparties.EmptyRef)                           AS Counterparty,
		|	DocumentTable.VATRate                                              AS VATRate,
		|	CASE WHEN ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) =
		|	  VALUE(Enum.SeparateVATAccountingOptions.Allocation) 
		|		THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
		|		WHEN DocumentData.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
		|			THEN DocumentData.VATActivityType
		|		ELSE &TaxationOfOrganization
		|	END                                                                   AS VATTaxation,
		|	ARTICLES__.VATAssetTaxClass                                                   AS AssetTaxClass,
		|	0                                                                       AS RowCode
		|INTO TTBatchAccountingAnalyst
		|FROM
		|	Document.OBEntryOtherExpenses.OtherExpenses AS DocumentTable
		|	INNER JOIN Document.OBEntryOtherExpenses AS DocumentData
		|		ON DocumentData.Ref = DocumentTable.Ref
		|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
		|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
		|WHERE
		|	DocumentTable.Ref = &Ref
		|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataCosts(Query, QueryTexts) Export
	
	RegisterName = "TTDataCosts";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryTextAITAccountingPolicy = CalculationOfCostLocalization.AITSettingsQueryText("", 
		"EnteringBalancesOtherExpenses_QueryTextTTTheseExpenses");
	QueryTexts.Add(QueryTextAITAccountingPolicy, RegisterName);
	
	QueryText =
	"SELECT
	|	Document.Organization                               AS Organization,
	|	Document.Date                                      AS Date,
	|	DocumentDataExpenses.LineNumber                 AS LineNumber,
	|	Document.Department                             AS Department,
	|	DocumentDataExpenses.LineOfBusiness     AS LineOfBusiness,
	|	DocumentDataExpenses.ExpenseItem              AS ExpenseItem,
	|	DocumentDataExpenses.DimensionOfExpenses           AS DimensionOfExpenses,
	|	DocumentDataExpenses.Ref                      AS ExpenseReceiptDocument,
	|	DocumentDataExpenses.RowID         AS RowID,
	|
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			   AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	   AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes    AS LotVendorAttributes,
	|
	|	DocumentDataExpenses.Sum                       AS Sum,
	|	DocumentDataExpenses.AmountExcludingVAT                 AS AmountExcludingVAT,
	|	DocumentDataExpenses.SumCompl                   AS SumCompl,
	|	DocumentDataExpenses.VATLocal                     AS VATLocal,
	|	DocumentDataExpenses.AmountPermanentDifferences                     AS AmountPermanentDifferences,
	|	DocumentDataExpenses.AmountTemporaryDifferences                     AS AmountTemporaryDifferences,
	|	CASE
	|		WHEN DocumentDataExpenses.ExpenseItem.RecognizedInAITExpenses
	|			 AND ISNULL(AITAccountingPolicy.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE)
	|			 AND Document.RecordAIT
	|			THEN DocumentDataExpenses.AITAmount
	|		ELSE 0
	|	END AS AITAmount
	|
	|INTO TTDataCosts
	|FROM
	|	Document.OBEntryOtherExpenses.OtherExpenses AS DocumentDataExpenses
	|
	|	INNER JOIN
	|		Document.OBEntryOtherExpenses AS Document
	|	ON
	|		DocumentDataExpenses.Ref = Document.Ref
	|
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		DocumentDataExpenses.ExpenseItem = ExpenseItems.Ref
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= DocumentDataExpenses.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""OtherExpenses""
	|
	|	LEFT JOIN AITAccountingPolicy AS AITAccountingPolicy
	|	ON Document.Organization = AITAccountingPolicy.Organization
	|
	|WHERE
	|	DocumentDataExpenses.Ref = &Ref
	|	AND &PostInCostAccounting";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	TTDataCosts.Date                    AS Period,
	|	TTDataCosts.Organization             AS Organization,
	|	TTDataCosts.Department           AS Department,
	|	TTDataCosts.LineOfBusiness AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem          AS ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses       AS DimensionOfExpenses,
	|	TTDataCosts.VATActivityType      AS VATActivityType,
	|
	|	TTDataCosts.Sum                   AS AmountIncludingVAT,
	|	TTDataCosts.AmountExcludingVAT             AS AmountExcludingVAT,
	|	TTDataCosts.AmountExcludingVAT             AS AmountExcludingVATMan,
	|
	|	TTDataCosts.SumCompl
	|		+ TTDataCosts.VATLocal           AS AmountIncludingVATCompl,
	|	TTDataCosts.SumCompl               AS AmountExcludingVATCompl,
	|	TTDataCosts.AmountPermanentDifferences                 AS PermanentDifference,
	|	TTDataCosts.AmountTemporaryDifferences                 AS CostTD,
	|	TTDataCosts.AITAmount                AS AITAmount,
	|	UNDEFINED                            AS BusinessOperation,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|	TTDataCosts.RowID     AS FinRecordID,
	|	&BusinessTransactionSetting         AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&RecordInOperationalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	AdditionalFields = "";
	
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(AdditionalFields);
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
	
	AdditionalFields = "";
	
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(AdditionalFields);
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTDataCosts", QueryTexts) Then
		QueryTextTTDataCosts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	TTDataCosts.Date                        AS Period,
	|	TTDataCosts.Organization                 AS Organization,
	|	TTDataCosts.Department               AS Department,
	|	TTDataCosts.LineOfBusiness     AS LineOfBusiness,
	|	TTDataCosts.ExpenseItem              AS ExpenseItem,
	|	TTDataCosts.DimensionOfExpenses           AS DimensionOfExpenses,
	|	UNDEFINED                                AS AssetsLiabilitiesDimension,
	|	TTDataCosts.ExpenseReceiptDocument AS ExpenseReceiptDocument,
	|	TTDataCosts.LotVendorAttributes        AS LotVendorAttributes,
	|	UNDEFINED                                AS ItemsLocationAttributes,
	|	TTDataCosts.VATActivityType          AS VATActivityType,
	|
	|	TTDataCosts.Sum                       AS Cost,
	|	TTDataCosts.AmountExcludingVAT                 AS CostExcludingVAT,
	|	TTDataCosts.Sum
	|		- TTDataCosts.AmountExcludingVAT           AS VATManag,
	|	TTDataCosts.SumCompl                   AS LocalCost,
	|	TTDataCosts.VATLocal                     AS VATLocal,
	|	TTDataCosts.AmountPermanentDifferences                     AS PermanentDifference,
	|	TTDataCosts.AmountTemporaryDifferences                     AS CostTD,
	|
	|	UNDEFINED                                AS BusinessOperation,
	|	TTDataCosts.RowID         AS FinRecordID,
	|	&BusinessTransactionSetting             AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTDataCosts AS TTDataCosts
	|
	|WHERE
	|	&RecordInOperationalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
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
	|	SUM(ISNULL(DataOfTabularPartOtherExpenses.Sum, 0)) AS Sum,
	|	&Currency AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryOtherExpenses AS DocumentData
	|		LEFT JOIN Document.OBEntryOtherExpenses.OtherExpenses AS DataOfTabularPartOtherExpenses
	|		ON DocumentData.Ref = DataOfTabularPartOtherExpenses.Ref
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
	
	FullDocumentName = "Document.OBEntryOtherExpenses";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryOtherExpenses));
	
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

#Region Other

// Determines the visibility of the form group that contains the accounting types checkboxes.
// Used in forms where all types of accounting are available.
//
// Parameters:
//  Object - DocumentObject.OBEntryOtherExpenses - A document for which it is necessary to calculate the group display
//
// Returns:
//	 Boolean - A flag that signals whether or not to show the group on the form
// 
Function VisibilityOfAccountingGroups(Object) Export
	
	VisibilityOfAccountingGroups = GetFunctionalOption("UseLocal")
		Or CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Object.Date), True);
	
	Return VisibilityOfAccountingGroups;
	
EndFunction


#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	OBEntryLocalization.EnteringBalancesOtherExpensesAddPrintCommands(PrintCommands);
	
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
	
EndProcedure

#EndRegion

#Region ServiceProceduresForFillingInAccordingToOperationalAccountingData

Function BalancesOfOtherExpenses(DateOfRemainingGoods, CompanyArray, AddtlFilter)
	
	Query = New Query("SELECT
		|	""OtherExpenses"" AS TablePartToFillIn,
		|	OtherExpensesBalance.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.OBEntryOfOtherExpenses) AS BusinessOperation,
		|	OtherExpensesBalance.Department,
		|	OtherExpensesBalance.LineOfBusiness,
		|	OtherExpensesBalance.ExpenseItem,
		|	OtherExpensesBalance.DimensionOfExpenses,
		|	SUM(OtherExpensesBalance.SumComplBalance) AS SumCompl,
		|	SUM(OtherExpensesBalance.PermanentDifferenceBalance) AS AmountPermanentDifferences,
		|	SUM(OtherExpensesBalance.CostTDBalance) AS AmountTemporaryDifferences,
		|	SUM(OtherExpensesBalance.AmountExcludingVATBalance) AS AmountExcludingVAT,
		|	SUM(OtherExpensesBalance.SumBalance) AS Sum
		|FROM
		|	AccumulationRegister.OtherExpenses.Balance(&Date, Organization IN (&CompanyArray) AND &SubdivisionCondition) AS OtherExpensesBalance
		|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|		ON OtherExpensesBalance.ExpenseItem = ExpenseItems.Ref
		|
		|GROUP BY
		|	OtherExpensesBalance.Organization,
		|	OtherExpensesBalance.Department,
		|	OtherExpensesBalance.LineOfBusiness,
		|	OtherExpensesBalance.ExpenseItem,
		|	OtherExpensesBalance.DimensionOfExpenses	
		|
		|HAVING
		|	SUM(OtherExpensesBalance.SumComplBalance) > 0
		|
		|ORDER BY
		|	Organization");
	
	Query.Parameters.Insert("CompanyArray", CompanyArray);
	Query.Parameters.Insert("Date", DateOfRemainingGoods);
	
	If ValueIsFilled(AddtlFilter) Then
		Query.Text = StrReplace(Query.Text , "&SubdivisionCondition", "Department = &Department");
		Query.Parameters.Insert("Department", AddtlFilter.Department);
	Else
		Query.Text = StrReplace(Query.Text , "&SubdivisionCondition", "TRUE");
	EndIf;
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
