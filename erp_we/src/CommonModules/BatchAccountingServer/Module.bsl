#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.ItemisedExpensesLots);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.GoodsCostVariances);
		
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.ItemisedExpensesLots);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.GoodsCostVariances);
		
		
		Parameters.ControlRegistersOfChanges.Add(Metadata.AccumulationRegisters.InventoryCost);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.ItemisedExpensesLots);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.InventoryCost);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.GoodsCostVariances);
	EndIf;	
	
	Parameters.ThereAreDerivedMotions = Document.RegisterRecords.Find(Metadata.AccumulationRegisters.InventoryCost.Name) <> Undefined;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of KeyAndValue - Correspondence of the full register name to the text of the reversal request:
//   * Key - String - Register name
//   * Value - String - Query text
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();

	// Filling in the fields must correspond to the functions:
	// Calculation of the cost of filling in the parties.The text of the Movement of the corrected documents during the period()
	// Calculation of the cost of the filling of the parties.The text of the movement of the corrected documents of the past period()
	
	RegisterMetadata = Metadata.AccumulationRegisters.InventoryCost;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryTemplate = "
		|SELECT
		|	DocumentsStorno.Date AS Period,
		|	BEGINOFPERIOD(RegisterData.Period, MONTH) AS PeriodOfPrimaryRegisteredRecords,
		|	CASE 
		|		WHEN RegisterData.VariancePeriod <> DATETIME(1,1,1)
		|			THEN RegisterData.VariancePeriod
		|		ELSE RegisterData.Period END AS VariancePeriod,
		|	&TTFields,
		// When the Cur period is reversed:
		//	For additional The type of record "Reverse expenses" is set
		//	, the type of record "Supplement" is saved
		//	For consumable Registered Records:
		//	- for the record type "Consumption" with a filled cor. accounting section
		//	- , the record type "Reverse" is set - for the record type "Consumption" with an empty cor. accounting section 
		//	- , the record type "Reverse consumption" is set -
		//	- for the record type "Write-off of another party", the record type "Write-off of another Party" is set - for the record type "Write-off of the statistics of the non-party", the record type is set records "Cancellation of the registration of the Party"
		//	- for the type of record "Reverse" the type of record "Reverse return"
		//	For incoming Registered Records is set:
		//	- for the record type "Moving", the record type "Correction of the current period" is set
		//	- for the record type "Consumption", the record type "Reverse consumption" is set (used when invoicing the delivery)
		//	- for the record type "Batch", the record type "Acquisition adjustment" is
		//	- set - for the record type
		// "Return of another deposit", the record type "Reverse return of another deposit" is set When reversing previous period:
		//	For additional The type of record "Adjustment of the acquisition of the past period" is set
		//	For the type of record "Supplement" is set for the type of record "Supplementation of the past period"
		//	For the type of record "Return of the past period" is set for the type of record "Return of the past period"
		//	For the incoming Registered Records with the type of record "Displacement" is set
		//	for the record "Correction of the displacement of the past period" For the expenditure Registered Records is set for the type of record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record "Return of the past period" is set for the record " Correction of the "Log period"
		//	For incoming Registered Records, the type is set "Acquisition adjustment" records, except for the "Consumption" record type.
		|	(CASE
		// Correction of the previous period
		|		WHEN RegisterData.Period < BEGINOFPERIOD(DocumentsStorno.Date, MONTH) THEN
		|			CASE WHEN  RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement) 
		|				THEN VALUE(Enum.LotRecordTypes.AdditionPreviousPeriod)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|				THEN VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn)
		|
		|			WHEN RegisterData.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|					VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|					VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|					VALUE(Enum.LotRecordTypes.CostAdjustment),
		|					VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|				THEN VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
		|
		|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			    AND RegisterData.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.Move),
		|					VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|				THEN VALUE(Enum.LotRecordTypes.CorrectPreviousPeriodTransfer)
		|				
		|			WHEN RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				AND NOT RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|			 OR RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot)
		|				THEN VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|
		// For the reverse document, the Purchase of goods and services for the invoice of delivery, the type of record is supplemented,
		// because for the purposes of distributing batches, it is necessary to create a record with the cost taking into account the calculated deviations in cost.
		// Such movements are formed in the Text Movement function of the corrected documents of the invoices and deliveries().
		// Conditions for filling in the record type, the addition must meet the conditions for data sampling in this function.
		|			WHEN RegisterData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			 AND VALUETYPE(RegisterData.Recorder) = TYPE(Document.VendorInvoice)
		|				THEN VALUE(Enum.LotRecordTypes.Supplement)
		|
		|			ELSE VALUE(Enum.LotRecordTypes.PreviousPeriodCorrections) END
		// Correction of the current period
		|		ELSE
		|			CASE WHEN  RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Supplement) 
		|				THEN VALUE(Enum.LotRecordTypes.Supplement)
		// To return the goods from the customer, we leave the current types of records
		|			WHEN RegisterData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|			 AND RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Move)
		|				THEN RegisterData.EntryType
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
		|				THEN VALUE(Enum.LotRecordTypes.ReverseOfPreviousPeriodsReturn)
		// Incoming traffic
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Lot) 
		|				THEN VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
		|				THEN VALUE(Enum.LotRecordTypes.Lot)
		|
		|			WHEN RegisterData.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|					VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|					VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|					VALUE(Enum.LotRecordTypes.CostAdjustment),
		|					VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|				THEN VALUE(Enum.LotRecordTypes.AdditionalExpensesReverseTransaction)
		|
		|			WHEN RegisterData.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.Move),
		|					VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis))
		|				THEN VALUE(Enum.LotRecordTypes.CurrentPeriodCorrections)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|			 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		// Expendable movements
		// There is a separate rule for the sale of goods between organizations and sale without transfer of ownership
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|			 AND RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		 										       VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|				THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|			 AND RegisterData.CorAccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|				THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|			 AND RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|				THEN VALUE(Enum.LotRecordTypes.ReversingEntry)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
		|				THEN VALUE(Enum.LotRecordTypes.ReverseOfCostAllocationToOtherLots)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot)
		|				THEN VALUE(Enum.LotRecordTypes.StornoOfWriteOffOfBalanceWithoutLot)
		|
		|			WHEN RegisterData.EntryType IN (
		|					VALUE(Enum.LotRecordTypes.ReversingEntry),
		|					VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction))
		|				THEN VALUE(Enum.LotRecordTypes.ReturnReverseTransaction)
		|
		|			WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
		|			THEN VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouseReverseTransaction)
		|
		|			ELSE RegisterData.EntryType END
		|		END) AS EntryType,
		// When the current period is cancelled:
		//	For incoming RegisteredRecorded, the document source is filled in with the document being cancelled, except for the storno record type "Consumption" (storno of the delivery invoice).
		//	For storno invoicing of delivery, the Document Source field is filled in with a link to the invoice document being cancelled.
		//	The document source is being filled in for the expenditure Registered Recorded:
		//	- a link to the document being cancelled for the disposal of goods (if there is no corresponding incoming Registered Record - the "Accounting Department" field is not filled
		//	- in - a link to the corrective document for the movement of goods (if there is a corresponding incoming Registered Record) 
		|	(CASE
		// There is a separate rule for the sale of goods between organizations and sale without transfer of ownership
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany),
		|		 										   VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
		|		 AND RegisterData.Period >= BEGINOFPERIOD(DocumentsStorno.Date, MONTH)
		|			THEN RegisterData.Recorder
		|
		|		WHEN RegisterData.EntryType = VALUE(Enum.LotRecordTypes.Consumption)
		|		 AND RegisterData.Period >= BEGINOFPERIOD(DocumentsStorno.Date, MONTH)
		|		 AND RegisterData.CorAccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
		|		 AND RegisterData.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN DocumentsStorno.Ref
		// When canceling additional expenses with the specified batch, the document source is filled in with the batch (from the original source document)
		// This is necessary to build a chain of additional expenses by the <- Side of additional expenses
		// When correcting cost adjustment records, the document source is filled in with the original source document.
		|		WHEN RegisterData.EntryType IN (
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified),
		|				VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified),
		|				VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod),
		|				VALUE(Enum.LotRecordTypes.CostAdjustment),
		|				VALUE(Enum.LotRecordTypes.IncludeExciseInCost))
		|			THEN RegisterData.DocumentSource
		|
		|		ELSE RegisterData.Recorder END) AS DocumentSource,
		|	TRUE AS ReversingEntry,
		// Fields that can't be filled in when using the Average Moving Average
		// Similar conditions are used in the textstoring of the query() of this module
		|	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|		AND RegisterData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
		|		THEN UNDEFINED
		|		ELSE RegisterData.Lot
		|	END AS Lot,
		|	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|		AND RegisterData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
		|			AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
		|		THEN UNDEFINED
		|		ELSE RegisterData.LotVendorAttributes
		|	END AS LotVendorAttributes,
		|	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|			AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
		|		THEN UNDEFINED
		|		ELSE RegisterData.FinancialAccountingDimension
		|	END AS FinancialAccountingDimension,
		|	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|			AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
		|		THEN UNDEFINED
		|		ELSE RegisterData.VATActivityType
		|	END AS VATActivityType,
		|	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|		THEN FALSE
		|		ELSE RegisterData.LotCalculation
		|	END AS LotCalculation,
		|	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|		THEN FALSE
		|		ELSE RegisterData.CalculationOfCost
		|	END AS CalculationOfCost
		// The Registered Records are storno used in the calculation of deviations for the method of estimating the average slip in the general module for calculating the cost of conducting documents.
		|INTO TTReversalDataCost
		|FROM
		|	AccumulationRegister.InventoryCost AS RegisterData
		|	INNER JOIN
		|		#DocumentName AS DocumentsStorno
		|	ON
		|		RegisterData.Recorder = DocumentsStorno.ReversedDocument
		|		AND DocumentsStorno.Ref IN (&Ref)
		|	LEFT JOIN TTParametersOfBatchAccountingForConducting AS AccountingPolicy
		|		ON BEGINOFPERIOD(DocumentsStorno.Date, MONTH) = AccountingPolicy.Period
		|		AND RegisterData.Organization = AccountingPolicy.Organization
		|WHERE
		|	NOT RegisterData.ReversingEntry 
		|	AND (ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|		OR (NOT RegisterData.LotCalculation
		|		   AND NOT RegisterData.CalculationOfCost))
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	RegisterData.Period,
		|	RegisterData.VariancePeriod,
		|	&SelectionFields1,
		|	RegisterData.EntryType,
		|	RegisterData.DocumentSource,
		|	RegisterData.ReversingEntry,
		|	RegisterData.Lot,
		|	RegisterData.LotVendorAttributes,
		|	RegisterData.FinancialAccountingDimension,
		|	RegisterData.VATActivityType,
		|	RegisterData.LotCalculation,
		|	RegisterData.CalculationOfCost
		|FROM
		|	TTReversalDataCost AS RegisterData
		|";
		
		ArrayOfSelectionFields = New Array; // sum fields without changing the sign 
		ArrayOfTTFields = New Array; // sum fields with a minus sign
		
		Exceptions = New Array;
		Exceptions.Add("Active");
		Exceptions.Add("RecNo");
		Exceptions.Add("Recorder");
		Exceptions.Add("Period");
		Exceptions.Add("ReversingEntry");
		Exceptions.Add("EntryType");
		Exceptions.Add("DocumentSource");
		Exceptions.Add("Lot");
		Exceptions.Add("LotVendorAttributes");
		Exceptions.Add("FinancialAccountingDimension");
		Exceptions.Add("VATActivityType");
		Exceptions.Add("LotCalculation");
		Exceptions.Add("CalculationOfCost");
		Exceptions.Add("VariancePeriod");
	
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
			ArrayOfTTFields,
			Exceptions);
			
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
			ArrayOfTTFields,
			Exceptions);
			
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
			ArrayOfTTFields,
			Exceptions,
			True);
			
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
			ArrayOfTTFields,
			Exceptions,
			True);
			
		SelectionFieldText = StrConcat(ArrayOfSelectionFields,"," + Chars.LF + "	");
		TextOfTTField = StrConcat(ArrayOfTTFields,"," + Chars.LF + "	");
		
		QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
		QueryText = StrReplace(QueryText, "&TTFields", TextOfTTField);
		QueryText = StrReplace(QueryText, "#DocumentName", MetadataOfDocument.FullName());
		
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
		
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.ItemisedExpensesLots;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryTemplate = "
		|SELECT
		|	DocumentsStorno.Ref  AS Recorder,
		|	DocumentsStorno.Date AS Period,
		|	CASE
		|		WHEN RegisterData.VariancePeriod <> DATETIME(1,1,1)
		|			THEN RegisterData.VariancePeriod
		|		ELSE RegisterData.Period END AS VariancePeriod,
		|	&SelectionFields1,
		// We do not fill in the VAT amounts when reversing, because the distribution of the reversed VAT amounts is performed in the VAT accounting mechanism
		// according to the movements of the "VAT presented" register. 
		|	0 AS VATLocal,
		|	0 AS VATManag,
		|	TRUE AS ReversingEntry
		|FROM
		|	AccumulationRegister.ItemisedExpensesLots AS RegisterData
		|	INNER JOIN
		|		#DocumentName AS DocumentsStorno
		|	ON
		|		RegisterData.Recorder = DocumentsStorno.ReversedDocument
		|		AND DocumentsStorno.Ref IN (&Ref)
		|	LEFT JOIN TTParametersOfBatchAccountingForConducting AS AccountingPolicy
		|		ON BEGINOFPERIOD(DocumentsStorno.Date, MONTH) = AccountingPolicy.Period
		|		AND RegisterData.Organization = AccountingPolicy.Organization
		|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
		|		ON AssetRef.Ref = RegisterData.ExpenseItem
		|WHERE
		|	NOT RegisterData.ReversingEntry 
		|	AND (ISNULL(AccountingPolicy.MovingAverage, FALSE)
		|		OR (NOT RegisterData.LotCalculation
		|		   AND NOT RegisterData.CalculationOfCost))
		// The condition for selecting records must match the functions:
		// See AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses()
		// See VATAccountingERP.ReflectPurchaseFromSupplier()
		// See CostCalculationDataPreparation.TextOfArticleRequestWithSeparateConsiderationOfNDSInRegisterOfPartyOfOtherExpenses()
		|	AND &UseAccountingOfOtherIncomeExpenses
		|	AND (AssetRef.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			AND (&ItemizeMaterialAndItemizedExpensesInInventoryCost
		|				OR &SeparateAccountingOfGoodsByVATTaxation
		|			)
		|		OR AssetRef.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
		|			AND (&ItemizeMaterialAndItemizedExpensesInInventoryCost
		|				OR &SeparateAccountingOfGoodsByVATTaxation
		|			)
		|	)
		|";
		
		ArrayOfSelectionFields = New Array;
		
		Exceptions = New Array;
		Exceptions.Add("Recorder");
		Exceptions.Add("Period");
		Exceptions.Add("ReversingEntry");
		Exceptions.Add("LineNumber");
		Exceptions.Add("Active");
		Exceptions.Add("VariancePeriod");
		Exceptions.Add("VATLocal");
		Exceptions.Add("VATManag");
	
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
			ArrayOfSelectionFields,
			Exceptions);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
		DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
			ArrayOfSelectionFields,
			Exceptions,
			True);
			
		SelectionFieldText= StrConcat(ArrayOfSelectionFields,"," + Chars.LF);
		
		QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
		QueryText = StrReplace(QueryText, "&RegisterName", RegisterMetadata.FullName());
		QueryText = StrReplace(QueryText, "#DocumentName", MetadataOfDocument.FullName());
		
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.GoodsCostVariances;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableItemisedExpensesLots", 
		AccumulationRegisters.ItemisedExpensesLots.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableInventoryCost", 
		AccumulationRegisters.InventoryCost.RequestTextMonitoringBanDate(Query));
	
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave batch accounting.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "ItemisedExpensesLots");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "InventoryCost");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "GoodsCostVariances");
	
	
EndProcedure

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	AccumulationRegisters.InventoryCost.InitializeSavingRecordsetRegisteredRecordsForPeriod(
		Document.RegisterRecords.InventoryCost, Document.AdditionalProperties);
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject, Structure - the document being recorded contains:
//  	* AdditionalProperties - Structure:
//  		** DocumentsPosting - Structure:
//  			*** DocumentProperties - FixedStructure:
//  				**** IsNew - Boolean
//  				**** WriteMode - DocumentWriteMode
//  				**** PostingMode - DocumentPostingMode
//  				**** Posted - Boolean
//  			*** ControlTables - Structure:
//  				**** TTAverageSlidingInventoryCost - Structure:
//  					***** ThereAreRecordsInTable - Boolean
//  					***** Parameters - Structure:
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	If CalculationOfCostCached.ValuesOfTechnologicalParameters().DoNotControlSequenceAtMediumSlip Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereAreRecordsInTable(Document, "TTAverageSlidingInventoryCost") Then
		Return;
	EndIf;
	
	OrganizationTable = Document.AdditionalProperties.DocumentsPosting.ControlTables.TTAverageSlidingInventoryCost.Parameters.MediumSlipOrganizations;
	MinimumPeriod = Date(1,1,1);
	
	For Each CurrRow In OrganizationTable Do
		
		If Not ValueIsFilled(MinimumPeriod) Then
			MinimumPeriod = CurrRow.Period;
		Else
			MinimumPeriod = Min(CurrRow.Period, MinimumPeriod);
		EndIf;
		
	EndDo;
	
	WriteMode = ?(Document.AdditionalProperties.Property("WriteMode"), Document.AdditionalProperties.WriteMode, Undefined);
	Query.SetParameter("UndoPosting", WriteMode = DocumentWriteMode.UndoPosting);
	Query.SetParameter("MinimumPeriodOfRegisteredRecordsOfCost", MinimumPeriod);
	Query.SetParameter("Recorder", Document.Ref);
	
	ControlRequestText =
	"SELECT
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS IsOperationReceipt,
	|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	T.AccountingSection,
	|	T.InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	SUM(T.CountUpdate) AS CountUpdate,
	|	T.Period,
	|	MAX(Filter.EndOfPeriod) AS EndOfPeriod
	|INTO TTRegisteredRecordedSelectionOfInventoryCostsPreliminary
	|FROM
	|	ChangesTableInventoryCost AS T
	|	INNER JOIN TTAverageSlidingInventoryCost AS Filter
	|		ON T.Organization = Filter.Organization
	|		AND T.Period = Filter.Period
	|WHERE
	|	NOT VALUETYPE(T.Recorder) IN (
	|		TYPE(Document.CostCalculationRecorder),
	|		TYPE(Document.InventoryCostCalculation))
	|	AND NOT T.ReversingEntry
	// When canceling the document, we do not control the Registered Recorded Expense.
	|	AND NOT (&UndoPosting AND T.RecordType = VALUE(AccumulationRecordType.Expense))
	|GROUP BY
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CAST(T.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys),
	|	T.AccountingSection,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	T.Period
	|HAVING
	|	SUM(T.CountUpdate) <> 0
	|INDEX BY
	|	ItemsLocationAttributes
	|";

	QueryTexts.Add(ControlRequestText);
	
	ControlRequestText =
	"SELECT
	|	T.IsOperationReceipt,
	|	T.ItemsLocationAttributes.Products AS Products,
	|	T.ItemsLocationAttributes.StorageLocation AS StorageLocation,
	|	T.ItemsLocationAttributes,
	|	T.AccountingSection,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	T.Period,
	|	T.EndOfPeriod
	|INTO TTRegisteredRecordedSelectionOfInventoryCosts
	|FROM
	|	TTRegisteredRecordedSelectionOfInventoryCostsPreliminary AS T
	|WHERE
	|	(T.IsOperationReceipt AND T.CountUpdate < 0)
	|	OR
	|	(NOT T.IsOperationReceipt	AND T.CountUpdate > 0)
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Organization
	|";
	
	QueryTexts.Add(ControlRequestText);
	
	ControlRequestText =
	"SELECT
	|	Filter.IsOperationReceipt AS IsOperationReceipt,
	|	Filter.Organization AS Organization,
	|	Filter.Products AS Products,
	|	Filter.StorageLocation AS StorageLocation,
	|	MAX(T.Period) AS Period
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN TTRegisteredRecordedSelectionOfInventoryCosts AS Filter
	|		ON T.Organization = Filter.Organization
	|		AND T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
	|		AND T.AccountingSection = Filter.AccountingSection
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Recorder <> &Recorder
	|		AND CASE
	|			WHEN FALSE
	|				THEN FALSE
	|			WHEN VALUETYPE(&Recorder) = TYPE(Document.ProductionStage2_2)
	|				THEN BEGINOFPERIOD(T.Period, DAY) > Filter.Period
	|			ELSE ((Filter.IsOperationReceipt AND T.Period > Filter.Period)
	|					OR (NOT Filter.IsOperationReceipt AND BEGINOFPERIOD(T.Period, DAY) > Filter.Period))
	|		  END
	|		AND (T.Period < Filter.EndOfPeriod OR Filter.EndOfPeriod = DATETIME(1,1,1))
	|		AND ((Filter.IsOperationReceipt AND T.RecordType = VALUE(AccumulationRecordType.Expense))
	|			OR (NOT Filter.IsOperationReceipt AND T.RecordType = VALUE(AccumulationRecordType.Receipt)))
	|		AND NOT VALUETYPE(T.Recorder) IN (
	|			TYPE(Document.RegisterAdjustment),
	|			TYPE(Document.CostCalculationRecorder),
	|			TYPE(Document.InventoryCostCalculation))
	|WHERE
	|	T.Period > &MinimumPeriodOfRegisteredRecordsOfCost
	|	AND (T.Count <> 0
	|		OR T.Cost <> 0
	|		OR T.CostExcludingVAT <> 0
	|		OR T.LocalCost <> 0
	|		OR T.CostMan <> 0
	|		OR T.OffBalanceCost <> 0
	|		OR T.OffBalanceCostLocal <> 0)
	|GROUP BY
	|	Filter.IsOperationReceipt,
	|	Filter.Organization,
	|	Filter.Products,
	|	Filter.StorageLocation
	|ORDER BY
	|	Organization,
	|	IsOperationReceipt,
	|	Products,
	|	StorageLocation
	|";
	
	QueryTexts.Add(ControlRequestText, "ErrorsInventoryCosts");
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	If ControlResults.Property("ErrorsInventoryCosts")
	 And ValueIsFilled(ControlResults.ErrorsInventoryCosts) Then
		
		For Each ErrorString In ControlResults.ErrorsInventoryCosts Do
			
			If ErrorString.IsOperationReceipt Then
				
				MessageText = NStr("vi = 'Sau chứng từ hiện tại, đã phản ánh việc xuất theo doanh nghiệp ""%1"", mặt hàng ""%2"" và kho bãi ""%3"".
					|Để giảm việc nhập đã phản ánh trước đó, cần sử dụng chứng từ ""Đảo ngược"".';
					|ru = 'После текущего документа уже отражен расход по организации ""%1"", номенклатуре ""%2"" и месту хранения ""%3"".
					|Для уменьшения ранее отраженного прихода необходимо использовать документ ""Сторно"".';
					|en = 'After the current document, the expense for the ""%1"" company, the ""%2"" item, and the ""%3"" storage location was recorded.
					|To reduce the previously recorded income, use the ""Storno"" document.'; fa = 'After the current document, the expense for the ""%1"" company, the ""%2"" item, and the ""%3"" storage location was recorded.
					|To reduce the previously recorded income, use the ""Storno"" document.';
					|it = 'After the current document, the expense for the ""%1"" company, the ""%2"" item, and the ""%3"" storage location was recorded.
					|To reduce the previously recorded income, use the ""Storno"" document.';
					|pl = 'After the current document, the expense for the ""%1"" company, the ""%2"" item, and the ""%3"" storage location was recorded.
					|To reduce the previously recorded income, use the ""Storno"" document.';
					|tr = 'Mevcut belgeden sonra ""%1"" iş yeri,""%2"" öğesi ve ""%3"" ambarı zaten bir gider kaydetmiştir. 
					| Önceden kaydedilen geliri azaltmak için ""Ters Sipariş"" belgesini kullanın.'");
				
			Else
				
				MessageText = NStr("vi = 'Ngày xuất sớm hơn ngày nhập gần nhất theo doanh nghiệp ""%1"", mặt hàng ""%2"" và nơi cất giữ ""%3"".
					|Không thể xác định giá trị trung bình liên hoàn. Đặt ngày chứng từ muộn hơn %4.
					|Trong một số dạng chứng từ, ngày xuất được chỉ ra trong các phần bảng của chứng từ.';
					|ru = 'Дата расхода ранее последнего прихода по организации ""%1"", номенклатуре ""%2"" и месту хранения ""%3"".
					|Среднескользящая стоимость не может быть определена. Установите дату документа позднее %4.
					|В некоторых видах документов дата расхода указывается в табличных частях документа.';
					|en = 'The expense date is earlier than the last receipt for the ""%1"" company, the ""%2"" item and the ""%3"" storage location.
					|Cannot identify the moving average cost. Set the document date later than %4.
					|In some types of documents, the expense date is specified in the document tables.'; fa = 'The expense date is earlier than the last receipt for the ""%1"" company, the ""%2"" item and the ""%3"" storage location.
					|Cannot identify the moving average cost. Set the document date later than %4.
					|In some types of documents, the expense date is specified in the document tables.';
					|it = 'The expense date is earlier than the last receipt for the ""%1"" company, the ""%2"" item and the ""%3"" storage location.
					|Cannot identify the moving average cost. Set the document date later than %4.
					|In some types of documents, the expense date is specified in the document tables.';
					|pl = 'The expense date is earlier than the last receipt for the ""%1"" company, the ""%2"" item and the ""%3"" storage location.
					|Cannot identify the moving average cost. Set the document date later than %4.
					|In some types of documents, the expense date is specified in the document tables.';
					|tr = 'Belge tarihini ""%1"" iş yeri, ""%2"" öğesi ve ""%3"" ambarı için son giderden daha önce ayarlayın. 
					|Belge tarihini %4 değerinden sonraya ayarlayın.
					|Bazı belge türlerinde tüketim tarihi, belgenin tablolarında belirtilir.'");
				
			EndIf;
		
		    MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageText,
				ErrorString.Organization,
				ErrorString.Products,
				ErrorString.StorageLocation,
				Format(ErrorString.Period, "DLF=DT"));
			
			Common.MessageToUser(MessageText, Document,,, Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Generates the request body for the reversal of entries on the register of accumulation.
// For numeric resources and numeric details, the register generates entries with a minus sign.
// 
// Parameters:
// 	RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register for reversal.
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the accumulation register for reversal.
// 	
// Returns:
// 	String - The text of the reversing request.
Function TextOfReversingRequest(RegisterMetadata, MetadataOfDocument) Export
	
	QueryTemplate =
	"SELECT
	|	DocumentsStorno.Ref  AS Recorder,
	|	DocumentsStorno.Date AS Period,
	|	RegisterData.Period AS AdjustmentPeriod_,
	|	&SelectionFields1,
	|	TRUE AS ReversingEntry
	|FROM
	|	&RegisterName AS RegisterData
	|	INNER JOIN #DocumentName AS DocumentsStorno
	|		ON RegisterData.Recorder = DocumentsStorno.ReversedDocument
	|		AND DocumentsStorno.Ref IN (&Ref)
	|	LEFT JOIN TTParametersOfBatchAccountingForConducting AS AccountingPolicy
	|		ON BEGINOFPERIOD(DocumentsStorno.Date, MONTH) = AccountingPolicy.Period
	|		AND &Organization = AccountingPolicy.Organization
	|WHERE
	|	NOT RegisterData.ReversingEntry 
	|	AND (&AddConditions)";
	
	ArrayOfSelectionFields = New Array;
	
	Exceptions = New Array;
	Exceptions.Add("Recorder");
	Exceptions.Add("Period");
	Exceptions.Add("ReversingEntry");
	Exceptions.Add("LineNumber");
	Exceptions.Add("Active");
	
	RedefinedFields = New Array;
	RedefinedFields.Add("LotCalculation");
	RedefinedFields.Add("CalculationOfCost");
	RedefinedFields.Add("Lot");
	RedefinedFields.Add("LotVendorAttributes");
	RedefinedFields.Add("FinancialAccountingDimension");
	RedefinedFields.Add("VATActivityType");
	RedefinedFields.Add("AdjustmentPeriod_");
	RedefinedFields.Add("VariancePeriod");
	RedefinedFields.Add("DocumentRegisterRecords");

	CommonClientServer.SupplementArray(Exceptions, RedefinedFields, True);
	
	DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
		ArrayOfSelectionFields,
		Exceptions);
	DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
		ArrayOfSelectionFields,
		Exceptions);
	DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
		ArrayOfSelectionFields,
		Exceptions,
		True);
	DocumentsPosting.AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
		ArrayOfSelectionFields,
		Exceptions,
		True);
		
	// Fields to fill in by condition
	ThereIsACompany = RegisterMetadata.Dimensions.Find("Organization") <> Undefined;
	ThereIsCalculationOfParties = RegisterMetadata.Attributes.Find("LotCalculation") <> Undefined;
	ThereIsCostCalculation = RegisterMetadata.Attributes.Find("CalculationOfCost") <> Undefined;
	ThereIsPeriodOfDeviation = RegisterMetadata.Attributes.Find("VariancePeriod") <> Undefined;
	ThereIsTransferRecord = RegisterMetadata.Attributes.Find("DocumentRegisterRecords") <> Undefined;
	
	If ThereIsACompany Then
		QueryTemplate = StrReplace(QueryTemplate, "&Organization", "RegisterData.Organization");
	Else
		QueryTemplate = StrReplace(QueryTemplate, "&Organization", "RegisterData.AccountingDimensionByPartners.Organization");
	EndIf;
	
	// The same conditions are used for Registering Records according to the cost register in the text of the Registration Request() of this module.
	For Each FieldName In RedefinedFields Do
		
		If RegisterMetadata.Dimensions.Find(FieldName) = Undefined Then
			
			If FieldName = "LotCalculation" And ThereIsCalculationOfParties Then
				FieldPattern = 
					"	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
					|		THEN FALSE
					|		ELSE RegisterData.LotCalculation
					|	END AS LotCalculation";
			ElsIf FieldName = "CalculationOfCost" And ThereIsCostCalculation Then
				FieldPattern = 
					"	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
					|		THEN FALSE
					|		ELSE RegisterData.CalculationOfCost
					|	END AS CalculationOfCost";
			ElsIf ThereIsPeriodOfDeviation And FieldName = "VariancePeriod" Then
				FieldPattern = 
					"	CASE
					|		WHEN RegisterData.VariancePeriod <> DATETIME(1,1,1)
					|			THEN RegisterData.VariancePeriod
					|		ELSE RegisterData.Period END AS VariancePeriod";
			ElsIf ThereIsTransferRecord And FieldName = "DocumentRegisterRecords" Then
				FieldPattern = 
					"	CASE
					|		WHEN RegisterData.DocumentRegisterRecords = VALUE(Document.AllocationOfOtherCosts.EmptyRef)
					|			THEN UNDEFINED
					|		ELSE RegisterData.DocumentRegisterRecords END AS DocumentRegisterRecords";
			Else
				Continue;
			EndIf;
			
		Else
			If FieldName = "Lot" Then
				FieldPattern = 
					"	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
					|	 AND RegisterData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
					|	 AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
					|		THEN UNDEFINED
					|		ELSE RegisterData.Lot
					|	END AS Lot";
			ElsIf FieldName = "LotVendorAttributes" Then
				FieldPattern = 
					"	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
					|	 AND RegisterData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
					|	 AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
					|		THEN UNDEFINED
					|		ELSE RegisterData.LotVendorAttributes
					|	END AS LotVendorAttributes";
			ElsIf FieldName = "FinancialAccountingDimension" Then
				FieldPattern = 
					"	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
					|	 AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
					|		THEN UNDEFINED
					|		ELSE RegisterData.FinancialAccountingDimension
					|	END AS FinancialAccountingDimension";
			ElsIf FieldName = "VATActivityType" Then
				FieldPattern = 
					"	CASE WHEN ISNULL(AccountingPolicy.MovingAverage, FALSE)
					|	 AND VALUETYPE(RegisterData.Lot) <> TYPE(Catalog.ProductionLots)
					|		THEN UNDEFINED
					|		ELSE RegisterData.VATActivityType
					|	END AS VATActivityType";
			ElsIf FieldName = "VariancePeriod" Then
				FieldPattern = 
					"	CASE
					|		WHEN RegisterData.VariancePeriod <> DATETIME(1,1,1)
					|			THEN RegisterData.VariancePeriod
					|		ELSE RegisterData.Period END AS VariancePeriod";
			Else
				Continue;
			EndIf;
			
		EndIf;
		
		ArrayOfSelectionFields.Add(FieldPattern);
		
	EndDo;
	
	SelectionFieldText = StrConcat(ArrayOfSelectionFields,"," + Chars.LF);
	
	AdditionalTermsAndConditions = "";
	
	If ThereIsCalculationOfParties And ThereIsCostCalculation Then
		AdditionalTermsAndConditions = "ISNULL(AccountingPolicy.MovingAverage, FALSE) OR (NOT RegisterData.LotCalculation AND NOT RegisterData.CalculationOfCost)";
	ElsIf ThereIsCalculationOfParties Then
		AdditionalTermsAndConditions = "ISNULL(AccountingPolicy.MovingAverage, FALSE) OR NOT RegisterData.LotCalculation";
	ElsIf ThereIsCostCalculation Then
		AdditionalTermsAndConditions = "ISNULL(AccountingPolicy.MovingAverage, FALSE) OR NOT RegisterData.CalculationOfCost";
	Else
		AdditionalTermsAndConditions = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
	QueryText = StrReplace(QueryText, "&RegisterName",  RegisterMetadata.FullName());
	QueryText = StrReplace(QueryText, "#DocumentName", MetadataOfDocument.FullName());
	QueryText = StrReplace(QueryText, "&AddConditions",	  AdditionalTermsAndConditions);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region RecordingRegisteredRecordsInRegisters

// Generates entries in the register of tasks for calculating the cost price, when changing the entries in the registers.
//
// Parameters:
//  Document - DocumentObject - the Registrar registers the movements
//  TempTablesManager - TempTablesManager - a temporary table Manager that contains tables of register changes.
//
Procedure ReflectCostCalculationTasks(Document, TempTablesManager) Export
	
	If ExchangePlans.MasterNode() <> Undefined Then // tasks are installed only in the main node.
		Return;
	EndIf;
	
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("BatchAccountingServer.ReflectCostCalculationTasks");
	
	Query = New Query();
	MatchingRequests = MatchingRequestsToControlRegisters(Query);
	
	QueryTemplate = "
	|SELECT DISTINCT
	|	Table.Month        AS Month,
	|	Table.Organization  AS Organization,
	|	Table.Document     AS Document,
	|	Table.ChangedDataForBatchAccountingVersion21 AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	&DataCollection AS Table
	|;
	|";
		
	TheTextOfASubquery = "";
	TempTablesQueryText = "";
	TemporaryTableNames = "";
		
	For Each MapItem In MatchingRequests Do
		AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			TempTablesManager.Tables,
			TheTextOfASubquery,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;
	
	TextDestroyW = MonthEndTransactionsServer.TemporaryTableDestructionQueryTest(TemporaryTableNames);
	
	If ValueIsFilled(TheTextOfASubquery) Then // there is at least one control register.
		QueryText = TempTablesQueryText
			+ StrReplace(QueryTemplate, "&DataCollection", "(" + TheTextOfASubquery + ")")
			+ TextDestroyW;
			
		Query.Text = QueryText;
		Query.TempTablesManager = TempTablesManager;
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
		
			Selection = Result.Select();
			JobNumber = Constants.NumberOfJobForCalculatingCost.Get();
			While Selection.Next() Do
				InformationRegisters.JobsForCalculatingCost.CreateRegisterEntry(
					Selection.Month,
					Selection.Document,
					Selection.Organization,
					JobNumber,
					Selection.ChangedDataForBatchAccountingVersion21);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

#EndRegion

#Region JobRegisterUtilityMethods

Function MatchingRequestsToControlRegisters(Query)
	
	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableProductsRelease", QueryTextProductsRelease(Query));
	MatchingQueryTexts.Insert("ChangesTableRevenueAndCOGS", QueryTextRevenueAndCOGS(Query));
	MatchingQueryTexts.Insert("ChangesTableRevenueServicesAndAssets", QueryTextRevenueServicesAndAssets(Query));
	MatchingQueryTexts.Insert("ChangesTableMaterialsAndWorksInProduction", QueryTextMaterialsAndWorksInProduction(Query));
	MatchingQueryTexts.Insert("ChangesTableWorkInProgressLots", QueryTextWorkInProgressLots(Query));
	MatchingQueryTexts.Insert("ChangesTableBatchesOfProductionCosts", QueryTextBatchesOfProductionCosts(Query));
	MatchingQueryTexts.Insert("ChangesTableItemisedExpensesLots", QueryTextItemisedExpensesLots(Query));
	MatchingQueryTexts.Insert("ChangesTableExpenseBatchesToGoodsCost", QueryTextExpenseBatchesToGoodsCost(Query));
	MatchingQueryTexts.Insert("ChangesTableLotsOfGoodsOfOrganizations", QueryTextLotsOfGoodsOfOrganizations(Query));
	MatchingQueryTexts.Insert("ChangesTableLotsOfGoodsTransferredToCommission", QueryTextLotsOfGoodsTransferredToCommission(Query));
	MatchingQueryTexts.Insert("ChangesTableOtherExpenses", QueryTextOtherExpenses(Query));
	MatchingQueryTexts.Insert("ChangesTableOtherWorkInProgressExpenses", QueryTextOtherWorkInProgressExpenses(Query));
	MatchingQueryTexts.Insert("ChangesTableInventoryCost", QueryTextInventoryCost(Query));
	MatchingQueryTexts.Insert("ChangesTableGoodsCostVariances", QueryTextGoodsCostVariances(Query));
	MatchingQueryTexts.Insert("ChangesTableGoodsToBeRegisteredInReportsToConsignor", QueryTextGoodsToBeRegisteredInReportsToConsignor(Query));
	MatchingQueryTexts.Insert("ChangesTableCompanyGoods", QueryTextCompanyGoods(Query));
	MatchingQueryTexts.Insert("ChangesTableCompanyGoodsForTransfer", QueryTextCompanyGoodsForTransfer(Query));
	MatchingQueryTexts.Insert("ChangesTableGoodsTransferredToCommissionAgent", QueryTextGoodsTransferredToCommissionAgent(Query));
	MatchingQueryTexts.Insert("ChangesTableWIPLaborCosts", QueryTextWIPLaborCosts(Query));
	MatchingQueryTexts.Insert("TableOfChangesDetailingBatchesOfGoodsForLBSiUSN", RequestTextDetailingBatchesOfGoodsForLBSiUSN(Query));
	MatchingQueryTexts.Insert("TableOfChangesDetailingBatchesOfGoodsForLBSiUSN2_4", RequestTextDetailingBatchesOfGoodsForLBSiUSN2_4(Query));
	MatchingQueryTexts.Insert("ChangesTableFutureExpenseCommitments", QueryTextFutureExpenseCommitments(Query));
	Return MatchingQueryTexts;

EndFunction

// Complements the text of the request for creating tasks.
// 
// Parameters:
// 	TableName - String - name of the table to search in the temporary table Manager.
// 	QueriesTexts - See InitializeStructureOfQueryTexts
// 	Tables - TempTablesManager - Manager of temporary query tables.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
//
Procedure AddTaskRequestText(TableName, QueriesTexts, Tables, QueryText, TempTablesQueryText, TemporaryTableNames) Export
	If Tables.Find(TableName) <> Undefined Then
		If ValueIsFilled(QueryText) Then
			QueryText = QueryText + "
			|
			|UNION ALL
			|";
		EndIf;
		QueryText = QueryText + QueriesTexts.QueryText;
		TempTablesQueryText = TempTablesQueryText + QueriesTexts.TempTablesQueryText;
		If ValueIsFilled(QueriesTexts.TemporaryTableNames) Then
			TemporaryTableNames = TemporaryTableNames + ", " + QueriesTexts.TemporaryTableNames;
		EndIf;
	EndIf;
EndProcedure

// Initializes the structure of query texts
// 
// Parameters:
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
// Returns:
// 	Structure - LongDesc:
// * QueryText - String - a string with the request text.
// * TempTablesQueryText - String - a string containing the text of a temporary table query.
// * TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
//
Function InitializeStructureOfQueryTexts(QueryText, TempTablesQueryText = "", TemporaryTableNames = "") Export
	StructureOfQueryTexts_ = New Structure("QueryText, TempTablesQueryText, TemporaryTableNames",
		QueryText,
		TempTablesQueryText,
		TemporaryTableNames);
	Return StructureOfQueryTexts_
EndFunction

Function TextOfTaskRequestIsUniversal(NameOfChangeTable, ChangedDataForBatchAccountingVersion21 = False, ThereIsCorOrganization = False) Export
	QueryText = "
	|SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document,
	|	&ChangedDataForBatchAccountingVersion21 AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	&NameOfChangeTable AS Table
	|";
	
	If ThereIsCorOrganization Then
		QueryText = QueryText + "
		|UNION
		|
		|SELECT DISTINCT
		|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
		|	Table.CorCompany AS Organization,
		|	Table.Recorder AS Document,
		|	&ChangedDataForBatchAccountingVersion21 AS ChangedDataForBatchAccountingVersion21
		|FROM
		|	&NameOfChangeTable AS Table
		|WHERE
		|	Table.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
		|";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&NameOfChangeTable", NameOfChangeTable);
	If ChangedDataForBatchAccountingVersion21 Then
		QueryText = StrReplace(QueryText, "&ChangedDataForBatchAccountingVersion21", "TRUE");
	Else
		QueryText = StrReplace(QueryText, "&ChangedDataForBatchAccountingVersion21", "FALSE");
	EndIf;
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_
EndFunction

#Region TextsOfRequestsTasksForCalculatingCostPrice

Function QueryTextProductsRelease(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableProductsRelease");
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextRevenueAndCOGS(Query)
	
	QueryText =
	"SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	PartnerAccountingAnalyticsKeys.Organization AS Organization,
	|	ChangesTable.Recorder AS Document,
	|	FALSE AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	ChangesTableRevenueAndCOGS AS ChangesTable
	|	INNER JOIN
	|		InformationRegister.AccountingDimensionByPartners AS PartnerAccountingAnalyticsKeys
	|	ON
	|		ChangesTable.AccountingDimensionByPartners = PartnerAccountingAnalyticsKeys.DimensionKey";
	
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextRevenueServicesAndAssets(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableRevenueServicesAndAssets");
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextMaterialsAndWorksInProduction(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableMaterialsAndWorksInProduction");
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextWorkInProgressLots(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableWorkInProgressLots", True);
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextBatchesOfProductionCosts(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableBatchesOfProductionCosts");
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextItemisedExpensesLots(Query)
	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	Table.Organization                  AS Organization,
	|	Table.Recorder                  AS Document,
	|	FALSE                                 AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	ChangesTableItemisedExpensesLots AS Table
	|WHERE
	|	Table.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|	OR Table.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|";
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextExpenseBatchesToGoodsCost(Query)
	
	QueryText = 
	"SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	Table.Organization                  AS Organization,
	|	Table.Recorder                  AS Document,
	|	TRUE                               AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	ChangesTableExpenseBatchesToGoodsCost AS Table
	|";
	
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextLotsOfGoodsOfOrganizations(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableLotsOfGoodsOfOrganizations", True);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextLotsOfGoodsTransferredToCommission(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableLotsOfGoodsTransferredToCommission", True);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextOtherExpenses(Query)
	
	TempTablesQueryText = "";
	TextDestroyW = "";
	
	TempTablesQueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DD.Organization AS Organization,
	|	MIN(BEGINOFPERIOD(DD.Period, MONTH)) AS BeginOfPeriod,
	|	MAX(ENDOFPERIOD(DD.Period, MONTH)) AS PeriodEnding
	|INTO
	|	TTDatesTableOfChangesOtherExpenses
	|FROM
	|	ChangesTableOtherExpenses AS DD
	|GROUP BY
	|	DD.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(AccountingPolicy.Period) AS Period,
	|	AccountingPolicy.Organization AS Organization
	|
	|INTO TTAccountingPolicyPeriods
	|FROM
	|	TTDatesTableOfChangesOtherExpenses AS DatesTableOfChanges
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON DatesTableOfChanges.Organization = AccountingPolicy.Organization
	|		AND DatesTableOfChanges.BeginOfPeriod >= AccountingPolicy.Period
	|GROUP BY
	|	AccountingPolicy.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAccountingPolicyPeriods.Organization AS Organization,
	|	AccountingPolicy.AllocateVariancesInPreviousPeriods
	|
	|INTO TTAccountingPolicyForOrganizations
	|FROM
	|	TTAccountingPolicyPeriods AS TTAccountingPolicyPeriods
	|	INNER JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicy
	|		ON TTAccountingPolicyPeriods.Period = AccountingPolicy.Period
	|		AND TTAccountingPolicyPeriods.Organization = AccountingPolicy.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 1 Service
	|SELECT DISTINCT
	|	Reserves.Organization AS Organization,
	|	Reserves.LineOfBusiness AS LineOfBusiness,
	|	Reserves.ProvisionObject AS ProvisionObject
	|INTO TTMovementOfReserves
	|FROM
	|	AccumulationRegister.FutureExpenseCommitments AS Reserves
	|	INNER JOIN ChangesTableOtherExpenses AS TableOtherExpenses
	|		ON TableOtherExpenses.Organization = Reserves.Organization
	|		AND TableOtherExpenses.LineOfBusiness = Reserves.LineOfBusiness
	|	INNER JOIN TTDatesTableOfChangesOtherExpenses AS TTDates
	|		ON TTDates.Organization = Reserves.Organization
	|WHERE
	|	Reserves.Period BETWEEN TTDates.BeginOfPeriod AND TTDates.PeriodEnding
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 2 Service
	|SELECT DISTINCT
	|	ExpenseItems.ExpenseItem AS ExpenseItem,
	|	ExpenseItems.DimensionOfExpenses AS DimensionOfExpenses,
	|	ExpenseItems.AnyExpenseDimension AS AnyExpenseDimension,
	|	TTMovementOfReserves.Organization AS Organization,
	|	TTMovementOfReserves.LineOfBusiness AS LineOfBusiness
	|INTO ReserveItems
	|FROM
	|	TTMovementOfReserves AS TTMovementOfReserves
	|		INNER JOIN Catalog.AccountingObjectsOfFutureExpenseCommitments.UseReserve AS ExpenseItems
	|		ON TTMovementOfReserves.ProvisionObject = ExpenseItems.Ref
	|
	|;
	|";
	
	TextDestroyW = "TTDatesTableOfChangesOtherExpenses, TTAccountingPolicyPeriods
	|, TTMovementOfReserves, ReserveItems
	|";
	
	QueryText = "
	|SELECT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	ChangesTable.Organization                  AS Organization,
	|	ChangesTable.Recorder                  AS Document,
	|	FALSE                                          AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	ChangesTableOtherExpenses AS ChangesTable
	|	LEFT JOIN TTAccountingPolicyForOrganizations AS AccountingPolicy
	|		ON AccountingPolicy.Organization = ChangesTable.Organization
	|	LEFT JOIN ReserveItems AS ReserveItems
	|		ON ChangesTable.Organization = ReserveItems.Organization
	|		AND ChangesTable.LineOfBusiness = ReserveItems.LineOfBusiness
	|		AND ChangesTable.ExpenseItem = ReserveItems.ExpenseItem
	|		AND (ChangesTable.DimensionOfExpenses = ReserveItems.DimensionOfExpenses OR ReserveItems.AnyExpenseDimension)
	|WHERE
	|	(ChangesTable.ExpenseItem.CostAllocationOptionManag IN (
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
	|		VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|		VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCosts))
	|		AND (ChangesTable.Sum <> 0 OR ChangesTable.AmountExcludingVAT <> 0 OR ChangesTable.SumMan <> 0)
	|	OR ChangesTable.ExpenseItem.CostAllocationOptionLocal IN (
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
	|		VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|		VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCosts))
	|		AND (ChangesTable.SumCompl <> 0)
	|	OR ChangesTable.ExpenseItem.CostAllocationOptionTax IN (
	|		VALUE(Enum.CostAllocationOptions.ToInventoryCost),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCostDirect),
	|		VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold),
	|		VALUE(Enum.CostAllocationOptions.ToCostCenters),
	|		VALUE(Enum.CostAllocationOptions.ToProductionCosts))
	|		AND (ChangesTable.SumCompl + ChangesTable.PermanentDifference + ChangesTable.CostTD <> 0)
	|	OR ChangesTable.ExpenseItem.ExpenseKind IN (&RationingExpenses)
	|	OR NOT ReserveItems.ExpenseItem IS NULL
	// If the deviation period is filled in, then it is necessary to create tasks for calculating the cost of allocating
	// expenses based on the previous period. 
	|	OR ISNULL(AccountingPolicy.AllocateVariancesInPreviousPeriods, FALSE)
	|		AND ChangesTable.VariancePeriod <> DATETIME(1,1,1)
	|		AND ChangesTable.VariancePeriod < BEGINOFPERIOD(ChangesTable.Period, MONTH)
	|	)
	|	AND NOT ChangesTable.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|	AND (NOT ChangesTable.Recorder REFS Document.AllocationOfOtherCosts
	|		OR (ChangesTable.Recorder REFS Document.AllocationOfOtherCosts
	|			AND CAST(ChangesTable.Recorder AS Document.AllocationOfOtherCosts).AssignAllocationSetting = 
	|				VALUE(Enum.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots)))
	|
	|GROUP BY
	|
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH),
	|	ChangesTable.Recorder,
	|	ChangesTable.Period,
	|	ChangesTable.Organization,
	|	ChangesTable.Department,
	|	ChangesTable.ExpenseItem,
	|	ChangesTable.DimensionOfExpenses,
	|	ChangesTable.LineOfBusiness,
	|	ChangesTable.BusinessOperation,
	|	ChangesTable.ItemsLocationAttributes,
	|	ChangesTable.VariancePeriod
	|HAVING
	|	SUM(ChangesTable.Sum) <> 0
	|	OR SUM(ChangesTable.AmountExcludingVAT) <> 0
	|	OR SUM(ChangesTable.SumCompl) <> 0
	|	OR SUM(ChangesTable.PermanentDifference) <> 0
	|	OR SUM(ChangesTable.CostTD) <> 0
	|	OR SUM(ChangesTable.AITAmount) <> 0
	|";
	Query.SetParameter("RationingExpenses", Enums.ExpenseKindsTA.RationingExpenses());
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText, TempTablesQueryText, TextDestroyW);
	Return StructureOfQueryTexts_
EndFunction

Function QueryTextOtherWorkInProgressExpenses(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableOtherWorkInProgressExpenses");
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextInventoryCost(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableInventoryCost", False, True);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextGoodsCostVariances(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableGoodsCostVariances", False, False);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextGoodsToBeRegisteredInReportsToConsignor(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableGoodsToBeRegisteredInReportsToConsignor", True);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextCompanyGoods(Query)
	QueryText = "
	|SELECT DISTINCT
	|	BEGINOFPERIOD(Table.Period, MONTH) AS Month,
	|	Table.Organization AS Organization,
	|	Table.Recorder AS Document,
	|	(CASE
	|		WHEN FALSE THEN FALSE // For ease of tagging.
	|		ELSE TRUE END) AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	ChangesTableCompanyGoods AS Table
	|";
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextCompanyGoodsForTransfer(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableCompanyGoodsForTransfer", True);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextGoodsTransferredToCommissionAgent(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableGoodsTransferredToCommissionAgent", True);
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextWIPLaborCosts(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("ChangesTableWIPLaborCosts");
	Return StructureOfQueryTexts_;
EndFunction

Function RequestTextDetailingBatchesOfGoodsForLBSiUSN(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("TableOfChangesDetailingBatchesOfGoodsForLBSiUSN");
	Return StructureOfQueryTexts_;
EndFunction

Function RequestTextDetailingBatchesOfGoodsForLBSiUSN2_4(Query)
	StructureOfQueryTexts_ = TextOfTaskRequestIsUniversal("TableOfChangesDetailingBatchesOfGoodsForLBSiUSN2_4");
	Return StructureOfQueryTexts_;
EndFunction

Function QueryTextFutureExpenseCommitments(Query)
	QueryText = "
	|SELECT DISTINCT
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH) AS Month,
	|	ChangesTable.Organization                  AS Organization,
	|	ChangesTable.Recorder                  AS Document,
	|	FALSE                                          AS ChangedDataForBatchAccountingVersion21
	|FROM
	|	ChangesTableFutureExpenseCommitments AS ChangesTable
	|		LEFT JOIN Catalog.AccountingObjectsOfFutureExpenseCommitments.UseReserve AS Table
	|			ON ChangesTable.ProvisionObject = Table.Ref
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems ARTICLES__
	|			ON Table.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	(ARTICLES__.CostAllocationOptionManag
	|		= VALUE(Enum.CostAllocationOptions.ToProductionCosts)
	|	OR ARTICLES__.CostAllocationOptionLocal
	|		= VALUE(Enum.CostAllocationOptions.ToProductionCosts))
	|
	|GROUP BY
	|
	|	BEGINOFPERIOD(ChangesTable.Period, MONTH),
	|	ChangesTable.Recorder,
	|	ChangesTable.Period,
	|	ChangesTable.Organization,
	|	ChangesTable.ReserveKind,
	|	ChangesTable.LineOfBusiness,
	|	ChangesTable.ProvisionObject
	|HAVING
	|	SUM(ChangesTable.SumMan) <> 0
	|	OR SUM(ChangesTable.SumCompl) <> 0
	|";
	StructureOfQueryTexts_ = InitializeStructureOfQueryTexts(QueryText);
	Return StructureOfQueryTexts_;
EndFunction
#EndRegion

#EndRegion

#Region Checks

// Returns the month of the first movements in the cost register.
// We can assume that this date corresponds to the beginning of accounting in the IB.
//
// Returns:
//	Date - The period of the first movements in the cost register.
//
Function PeriodOfFirstRegisteredRecordsOfRegisterCost() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	T.Period AS Period
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|
	|ORDER BY
	|	Period";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = BegOfMonth(Selection.Period);
	Else
		Result = Date(1,1,1);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the month of the last movements according to the cost register.
// We can assume that this date corresponds to the last accounting transactions in the information Security.
//
// Returns:
//	Date - The period of the last movements according to the cost register.
//
Function PeriodOfLastRegisteredRecordsOfRegisterCost() Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	T.Period AS Period
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|
	|ORDER BY
	|	Period DESC";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = BegOfMonth(Selection.Period);
	Else
		Result = Date(1,1,1);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the month of the first movements generated in batch accounting version 2.2
//
// Returns:
//	Date - The period of the first movements formed in the batch accounting version 2.2
//
Function PeriodOfFirstRegisteredRecordsBatchAccountingVersion22() Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	CASE
	|		WHEN T.EntryType = VALUE(Enum.LotRecordTypes.InternalMigrationToLotAccounting22)
	|			THEN DATEADD(ENDOFPERIOD(T.Period, MONTH), SECOND, 1)
	|		ELSE BEGINOFPERIOD(T.Period, MONTH)
	|	END AS Period
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|WHERE
	|	T.VATActivityType <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|
	|ORDER BY
	|	T.Period";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = Selection.Period;
	Else
		Result = Date(1,1,1);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region RecalculationOfPastPeriods

// Creates cost calculation tasks when you enable or disable cost accounting by destination or
// when you change the period when you enable cost accounting by destination.
//
Procedure PlanCostRecalculationWhenChangingCostAccountingForPurposes() Export
	
	// For each organization, a period is determined, starting from which it is necessary to recalculate the cost.
	// 1) When enabling accounting by appointment or changing the date of inclusion, the minimum period of two is taken:
	//	- the period of the first movement of the cost price, in which appointments have already been taken into account
	//	- the period of the first movement of the cost price, after the date of inclusion of accounting by appointment
	// 2) When switching off accounting by appointment, the period of the first cost movements is taken,
	//	in which appointments were previously taken into account
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = "
	|SELECT
	|	Keys.Ref
	|INTO AnalyticsWithAssignments
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS Keys
	|WHERE
	|	Keys.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|;
	|SELECT
	|	TimeIntervals.Organization AS Organization,
	|	MIN(TimeIntervals.Month) AS Month
	|INTO TTCostRecalculation
	|FROM (
	// When enabling accounting by appointment or changing the date, we determine the minimum period before the inclusion period
	// in which there are movements with appointments.
	|	SELECT
	|		InventoryCost.Organization AS Organization,
	|		MIN(BEGINOFPERIOD(InventoryCost.Period, MONTH)) AS Month
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
	|			ON AnalyticsWithAssignments.Ref = InventoryCost.ItemsLocationAttributes
	|		LEFT JOIN Constants AS Constants
	|			ON (TRUE)
	|	WHERE
	|		Constants.KeepRecordsOfInventoryCostByAssignments
	|		AND InventoryCost.Period < BEGINOFPERIOD(Constants.CostAccountingByAssignmentValidFrom, MONTH)	
	|	GROUP BY
	|		InventoryCost.Organization
	|
	// When enabling accounting by appointment or changing the date, we determine the minimum period in which there are movements after the inclusion period.
	|	UNION ALL
	|	SELECT
	|		InventoryCost.Organization AS Organization,
	|		MIN(BEGINOFPERIOD(InventoryCost.Period, MONTH)) AS Month
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|		LEFT JOIN Constants AS Constants
	|			ON (TRUE)
	|	WHERE
	|		Constants.KeepRecordsOfInventoryCostByAssignments
	|		AND InventoryCost.Period >= BEGINOFPERIOD(Constants.CostAccountingByAssignmentValidFrom, MONTH)
	|	GROUP BY
	|		InventoryCost.Organization
	|
	// When switching off accounting by appointment, we determine the minimum period in which there are movements with appointments.
	|	UNION ALL
	|	SELECT
	|		InventoryCost.Organization AS Organization,
	|		MIN(BEGINOFPERIOD(InventoryCost.Period, MONTH)) AS Month
	|	FROM
	|		AccumulationRegister.InventoryCost AS InventoryCost
	|		INNER JOIN AnalyticsWithAssignments AS AnalyticsWithAssignments
	|			ON AnalyticsWithAssignments.Ref = InventoryCost.ItemsLocationAttributes
	|		LEFT JOIN Constants AS Constants
	|			ON (TRUE)
	|	WHERE
	|		NOT Constants.KeepRecordsOfInventoryCostByAssignments
	|	GROUP BY
	|		InventoryCost.Organization
	| 	) AS TimeIntervals
	|GROUP BY
	|	TimeIntervals.Organization
	|INDEX BY
	|	Organization
	|";
	
	GenerateTasksForCostRecalculation(Query);
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query.TempTablesManager, "AnalyticsWithAssignments, TTCostRecalculation");
	
EndProcedure

Procedure GenerateTasksForCostRecalculation(Query) Export
	
	SetPrivilegedMode(True);
	
	Query.Execute();
	
	Query.Text =
	"SELECT
	|	Jobs.Organization AS Organization,
	|	MIN(BEGINOFPERIOD(Jobs.Month, Month)) AS Month
	|INTO TTTasksToCalculate
	|FROM
	|	InformationRegister.JobsForCalculatingCost AS Jobs
	|		INNER JOIN TTCostRecalculation AS Recalculations
	|		ON Jobs.Organization = Recalculations.Organization
	|
	|GROUP BY
	|	Jobs.Organization
	|
	|INDEX BY
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Recalculations.Organization,
	|	Recalculations.Month
	|FROM
	|	TTCostRecalculation AS Recalculations
	|		LEFT JOIN TTTasksToCalculate AS Jobs
	|		ON Recalculations.Organization = Jobs.Organization
	|WHERE
	|	(Jobs.Month IS NULL 
	|			OR Jobs.Month > Recalculations.Month)";
	
	Selection = Query.Execute().Select();
	
	InformationRegisters.JobsForCalculatingCost.CreateRegisterEntriesBasedOnSampleData(Selection);
	
EndProcedure

#EndRegion

#EndRegion
