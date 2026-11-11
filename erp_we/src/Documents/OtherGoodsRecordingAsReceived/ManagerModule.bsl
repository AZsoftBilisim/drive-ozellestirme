#If Not MobileStandaloneServer Then
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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("InventoryInOperation");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FixedAssets");
	OtherGoodsRecordingAsReceivedLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of data tables to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.OtherGoodsRecordingAsReceived") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableInventoryInOperation(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		OtherGoodsRecordingAsReceivedLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.OtherGoodsRecordingAsReceived);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Generates tables of movements when performing the operation "Closing expenses from the disposal of fixed assets".
//
// Parameters:
//  TempTablesManager	- TempTablesManager - Contains auxiliary temporary tables that can be used for forming movements.
//  RegisterRecordsPeriod - Date - The month in which Registered Records are generated
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfRegisteredRecordsInClosingExpensesFromDisposalOfFA(TempTablesManager, RegisterRecordsPeriod) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("RegisterRecordsPeriod", RegisterRecordsPeriod);
	
	GetDocumentData(Query);

	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	ClosingExpensesFromDisposalOfFixedAssets.SetRequestParameters(Query);
	
	QueryTexts = New ValueList;
	
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableOtherExpenses(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableOtherIncome(QueryTexts);
	ClosingExpensesFromDisposalOfFixedAssets.QueryTextTableRegisterRecordsProductsIncomeExpenses(QueryTexts);
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.TempTablesManager = TempTablesManager;
	AddlParameters.OnlyMarkedOnes = True;
	
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return TablesForRegisteredRecords;
	
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
	
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	TransactionList = New Array;
	TransactionList.Add(Enums.BusinessTransactions.ReceiptFromProduction);
	TransactionList.Add(Enums.BusinessTransactions.InventoryConsumptionReverseTransaction);
	TransactionList.Add(Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities);
	TransactionList.Add(Enums.BusinessTransactions.GoodsReceiptByExpencesAssets);
	
	CommandCorrection = DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
	If CommandCorrection <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CommandCorrection,
			"BusinessOperation",
			TransactionList,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	TheStornoTeam = DocumentCorrection.AddReverseCommand(
		GenerationCommands,
		EmptyRef().Metadata());
	
	If TheStornoTeam <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			TheStornoTeam,
			"BusinessOperation",
			TransactionList,
			DataCompositionComparisonType.InList);
		
	EndIf;
	
	OtherGoodsRecordingAsReceivedLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Other goods posting".
//
// Parameters:
//  GenerationCommands - ValueTable - command table
// Returns:
//  ValueTableRow, Undefined - added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.OtherGoodsRecordingAsReceived) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.OtherGoodsRecordingAsReceived.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.OtherGoodsRecordingAsReceived);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseOtherGoodsRecordingAsReceived";
	
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
	
	OtherGoodsRecordingAsReceivedLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("PriceKind");
	ArrayOfAllProps.Add("Currency");
	ArrayOfAllProps.Add("RetirementItem");
	ArrayOfAllProps.Add("Goods.Price");
	ArrayOfAllProps.Add("Goods.Sum");
	ArrayOfAllProps.Add("Goods.ExpenseAs");
	ArrayOfAllProps.Add("Goods.CCDNumber");
	ArrayOfAllProps.Add("Goods.FixedAsset");
	ArrayOfAllProps.Add("Goods.AssetID");
	ArrayOfAllProps.Add("Goods.Individual");
	ArrayOfAllProps.Add("Goods.Lot");
	ArrayOfAllProps.Add("Goods.CompletionDate_");
	ArrayOfAllProps.Add("Goods.LineOfBusiness");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction Then
		ArrayOfOperationDetails.Add("PriceKind");
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
	ElsIf BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		ArrayOfOperationDetails.Add("Goods.ExpenseAs");
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities Then
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets Then
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RegistrationAtFADisposal Then
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("RetirementItem");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.FixedAsset");
	ElsIf BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		ArrayOfOperationDetails.Add("PriceKind");
		ArrayOfOperationDetails.Add("Currency");
		ArrayOfOperationDetails.Add("Goods.QuantityByGBRN");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.Individual");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.LineOfBusiness");
		ArrayOfOperationDetails.Add("Goods.AssetID");
		ArrayOfOperationDetails.Add("Goods.Lot");
		If GetFunctionalOption("TradeManagement") Then
			ArrayOfOperationDetails.Add("Goods.CompletionDate_");
		EndIf;
	EndIf;
	
	OtherGoodsRecordingAsReceivedLocalization.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
		
EndProcedure

// Fills in arrays of form elements that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllElements - Array - Array of all form elements that depend on the business operation
//	ArrayOfOperationElements - Array - Array of names of form elements used in the selected business operation.
//
Procedure FillInNamesOfElementsForBusinessOperation(BusinessOperation, ArrayOfAllElements, ArrayOfOperationElements) Export
	
	ArrayOfAllElements = New Array;
	ArrayOfAllElements.Add("GoodsRefillByReceiving");
	ArrayOfAllElements.Add("GoodsFillInPricesByPriceKind");
	ArrayOfAllElements.Add("GoodsChangeQuality");
	ArrayOfAllElements.Add("PickUpProductsBasedOnBalancesInDivision");
	ArrayOfAllElements.Add("GoodsAddItemsFromDebitDocuments");
	ArrayOfAllElements.Add("GoodsOriginCountry");
	ArrayOfAllElements.Add("GoodsSelectTheTmtsvexploitation");

	ArrayOfOperationElements = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction Then
		ArrayOfOperationElements.Add("GoodsRefillByReceiving");
		ArrayOfOperationElements.Add("GoodsFillInPricesByPriceKind");
		ArrayOfOperationElements.Add("GoodsChangeQuality");
		ArrayOfOperationElements.Add("GoodsOriginCountry");
	ElsIf BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		ArrayOfOperationElements.Add("GoodsAddItemsFromDebitDocuments");
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets Then
		ArrayOfOperationElements.Add("GoodsRefillByReceiving");
		ArrayOfOperationElements.Add("GoodsChangeQuality");
		ArrayOfOperationElements.Add("GoodsOriginCountry");
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities Then
		ArrayOfOperationElements.Add("GoodsRefillByReceiving");
		ArrayOfOperationElements.Add("GoodsChangeQuality");
		ArrayOfOperationElements.Add("GoodsOriginCountry");
	ElsIf BusinessOperation = Enums.BusinessTransactions.RegistrationAtFADisposal Then
		ArrayOfOperationElements.Add("GoodsRefillByReceiving");
		ArrayOfOperationElements.Add("GoodsFillInPricesByPriceKind");
		ArrayOfOperationElements.Add("GoodsChangeQuality");
		ArrayOfOperationElements.Add("GoodsOriginCountry");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		
		ArrayOfOperationElements.Add("GoodsRefillByReceiving");
		ArrayOfOperationElements.Add("GoodsFillInPricesByPriceKind");
		ArrayOfOperationElements.Add("GoodsOriginCountry");
		ArrayOfOperationElements.Add("GoodsSelectTheTmtsvexploitation");
		
	EndIf;
	
EndProcedure

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Department,Status,Date,BusinessOperation";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.OtherGoodsRecordingAsReceived";
	
	RecipientSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		
		ItIsPossibleToTakeIntoAccountSeriesInOperation = InventoryInOperationCached.ItIsPossibleToTakeIntoAccountSeriesInOperation();
		
		SeriesSpecificationParameters.UseItemsBatch = 
			ItIsPossibleToTakeIntoAccountSeriesInOperation
			Or (RecipientSeriesParameters.UseItemsBatch
				And (Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date))
					Or RecipientSeriesParameters.UseCostAccountingByBatches);

		SeriesSpecificationParameters.UseCostAccountingByBatches =
			ItIsPossibleToTakeIntoAccountSeriesInOperation 
			Or RecipientSeriesParameters.UseCostAccountingByBatches;
		
	Else
		
		SeriesSpecificationParameters.UseItemsBatch = 
			RecipientSeriesParameters.UseItemsBatch
			And (Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date))
				Or RecipientSeriesParameters.UseCostAccountingByBatches;

		SeriesSpecificationParameters.UseCostAccountingByBatches = RecipientSeriesParameters.UseCostAccountingByBatches;
		
	EndIf;
	
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions);
	If Object.BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.DisposalInventoryInOperation);
	EndIf;

	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");

	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Ref");
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//	FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//		of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - order for receipt or shipment.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	Return FieldValuesToIdentifyReferences.Ref;	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusSender,
	|	Goods.BatchesIndicationStatusRecipient,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusSender AS OldStatusOfSenderIndication,
	|	Goods.BatchesIndicationStatusRecipient AS OldStatusOfSpecifyingRecipientSeries,
	|
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|							WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|								OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|												AND ProductsToRequest.Count > 0
	|											THEN 10
	|										ELSE 9
	|									END
	|							ELSE 0
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|					THEN CASE
	|							WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|								OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|												AND ProductsToRequest.Count > 0
	|											THEN 8
	|										ELSE 7
	|									END
	|							ELSE 0
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|						AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|							OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|						AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByOtherRecordingAsReceived
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN CASE
	|										WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|												AND ProductsToRequest.Count > 0
	|											THEN 4
	|										ELSE 3
	|									END
	|							ELSE CASE
	|									WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|											AND ProductsToRequest.Count > 0
	|										THEN 2
	|									ELSE 1
	|								END
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatusRecipient,
	|
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|				OR NOT &DisposalInventoryInOperation
	|			THEN 0
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingInventoryInOperation
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 20
	|					ELSE 19
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusSender
	|
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber						AS LineNumber,
	|	Statuses.BatchesIndicationStatusSender	AS BatchesIndicationStatusSender,
	|	Statuses.BatchesIndicationStatusRecipient	AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatusSender > 0
	|			THEN Statuses.BatchesIndicationStatusSender
	|		ELSE Statuses.BatchesIndicationStatusRecipient
	|	END									AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	(Statuses.BatchesIndicationStatusSender <> Statuses.OldStatusOfSenderIndication
	|			OR Statuses.BatchesIndicationStatusRecipient <> Statuses.OldStatusOfSpecifyingRecipientSeries
	|			OR CASE
	|					WHEN Statuses.BatchesIndicationStatusSender > 0
	|						THEN Statuses.BatchesIndicationStatusSender
	|					ELSE Statuses.BatchesIndicationStatusRecipient
	|				END <> Statuses.OldStatusOfSpecifyingSeries)
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return OtherGoodsRecordingAsReceivedLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return OtherGoodsRecordingAsReceivedLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.OtherGoodsRecordingAsReceived, DocumentRef.OtherGoodsRecordingAsReceived - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Date,
		|DateOfReceipt,
		|Number,
		|BusinessOperation,
		|Department,
		|LineOfBusiness,
		|Organization,
		|Department,
		|Patch,
		|CorrectedDocument");
	
	If ObjectAttributes.Ref <> Undefined And ObjectAttributes.Patch Then
		Attributes = AttributesOfControlledLotReference(ObjectAttributes.CorrectedDocument, FieldNameControlledLotReference);
		Return Attributes;
	EndIf;
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Attributes.Sender = ObjectAttributes.Department;
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.OtherGoodsRecordingAsReceived - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.ReadableFields = "Products";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// Sets the conditional design of the document type in the dynamic list for the business operation of the document.
//
// Parameters:
//  List - DynamicList - Dynamic form list.
//
Procedure SetConditionalListAppearance(List) Export
	
	FormattedField = "Type";
	
	// Income-based accounting
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormattedField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.OtherGoodsRecordingAsReceived");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi tăng vào tài khoản thu nhập';
													|ru = 'Оприходование за счет доходов';
													|en = 'Receipt recognition (income)'; fa = 'Receipt recognition (income)';
													|it = 'Registrazione in contabilità per conto dei ricavi';
													|pl = 'Zaksięgowanie kosztem przychodów';
													|tr = 'İlaveler, gelire karşı'"));
	
	// The capitalization of the costs
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormattedField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.OtherGoodsRecordingAsReceived");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Ghi tăng vào tài khoản chi phí';
													|ru = 'Оприходование за счет расходов';
													|en = 'Receipt recognition (expenses)'; fa = 'Receipt recognition (expenses)';
													|it = 'Registrazione in contabilità per conto delle spese';
													|pl = 'Zaksięgowanie kosztem wydatków';
													|tr = 'İlaveler (gidere karşı)'"));
	
	// Write-off as expenses storno
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormattedField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.OtherGoodsRecordingAsReceived");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đảo ngược ghi giảm vào chi phí';
													|ru = 'Сторно списания на расходы';
													|en = 'Inventory consumption storno'; fa = 'استورنو مصرف موجودی';
													|it = 'Storno storni alle spese';
													|pl = 'Storno wyksięgowania na wydatki';
													|tr = 'Masraflardan geri ödeme yapılması'"));
	
	// Receipt from production
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormattedField);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.ReceiptFromProduction;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.OtherGoodsRecordingAsReceived");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tiếp nhận từ sản xuất';
													|ru = 'Поступление из производства';
													|en = 'Receipt from production'; fa = 'دریافت از تولید';
													|it = 'Entrata dalla produzione';
													|pl = 'Wpływ z produkcji';
													|tr = 'Üretimden giriş'"));
	// Return from operation
	
	Item = List.SettingsComposer.FixedSettings.ConditionalAppearance.Items.Add();
	Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Type");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BusinessOperation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.PutOutOfOperation;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Type");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Type("DocumentRef.OtherGoodsRecordingAsReceived");
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thu lại từ sử dụng';
													|ru = 'Возврат из эксплуатации';
													|en = 'Put out of operation'; fa = 'خارج کردن از بهره‌برداری';
													|it = 'Reso dall''esercizio';
													|pl = 'Zwrot z eksploatacji';
													|tr = 'Ekipman iadesi'"));

EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ToControlQuality = "Object.Goods.ToControlQuality";
	
	Return FormTemplate;
	
EndFunction

// Returns a list of all households. operations used in the document.
// 
// Parameters:
// 	Object - DocumentObject.OtherGoodsRecordingAsReceived - Document to fill in the list of available operations for
// 	
// Returns:
// 	Array - A list of all households. operations used in the document.
//
Function BusinessOperationsOfDocument(Object = Undefined) Export

	Patch = False;
	If Object <> Undefined Then
		Patch = Object.Patch;
	EndIf;
	
	TransactionList = New Array;
	TransactionList.Add(Enums.BusinessTransactions.ReceiptFromProduction);
	
	TransactionList.Add(Enums.BusinessTransactions.InventoryConsumptionReverseTransaction);
	If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		TransactionList.Add(Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities);
		TransactionList.Add(Enums.BusinessTransactions.GoodsReceiptByExpencesAssets);
	EndIf;
	TransactionList.Add(Enums.BusinessTransactions.RegistrationAtFADisposal);
	If Not Patch Then
		TransactionList.Add(Enums.BusinessTransactions.PutOutOfOperation);
	EndIf;
		
	Return TransactionList;
	
EndFunction

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
	|	AND ValueAllowed(Warehouse)
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

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation = True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function OperationsWhereYouDonTNeedToFillOutDivision() Export

	OperationArray = New Array;
	OperationArray.Add(Enums.BusinessTransactions.GoodsReceiptByExpencesAssets);
	OperationArray.Add(Enums.BusinessTransactions.PutOutOfOperation);
	
	Return OperationArray;

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Returns:
//  See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.DataPath = "Object.Goods";
	SetupParameters.ArticleType = "ArticleType";
	SetupParameters.AssetAndLiabilityItem = "ExpenseAndIncomeItem";
	
	// Form elements that are used for customization.
	SetupParameters.FormItems.Add("GoodsTransactionRecordingPresentation");
	
	If BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		
		SetupParameters.AvailabilityByOperation = False;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction Then
		
		SetupParameters.AvailabilityByOperation = False;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		
		SetupParameters.AvailabilityByOperation = True;
		
	EndIf;
	
	Return SetupParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseAndIncomeItem";
	ChoiceParameters.ArticleType = "ArticleType";
	
	If BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByExpencesAssets Then
		
		ChoiceParameters.ChoosingExpenseItem = True;
		ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		
		ChoiceParameters.ChoosingExpenseItem = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction Then
		
		ChoiceParameters.ChoosingExpenseItem = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsReceiptByIncomeLiabilities Then
		
		ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
		ChoiceParameters.ChoosingIncomeItem = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.RegistrationAtFADisposal Then
		
		ChoiceParameters.ChoosingIncomeItem = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		
		ChoiceParameters.ChoosingIncomeItem = True;
		
	EndIf;
	
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseAndIncomeItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("GoodsAssetsLiabilitiesDimension");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("GoodsDimensionOfRevenue");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);

	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);

	Query.Text =
	"SELECT
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Currency                AS Currency,
	|	DocumentData.Department         AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Warehouse                 AS Warehouse,
	|	DocumentData.RetirementItem AS RetirementItem,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                 AS AdvancedWarehousingOnGoodsReceipt,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.EmployeeResponsible         AS EmployeeResponsible,
	|	DocumentData.Comment           AS Comment,
	|	DocumentData.DeletionMark       AS DeletionMark,
	|	DocumentData.Patch           AS Patch,
	|	DocumentData.ReversedDocument  AS ReversedDocument,
	|	DocumentData.CorrectedDocument  AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted              AS Posted,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromProduction)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ReceiptFromProduction)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.InventoryConsumptionReverseTransaction)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.RegistrationAtFADisposal)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.GoodsRecordingAsReceived)
	|	END AS BusinessTransactionSetting
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
EndProcedure

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentsList
	|
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableItems
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject
	|
	|INTO DocumentDataTableItems
	|
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	ValuesOfHoldingParameters.Insert("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	ValuesOfHoldingParameters.Insert("EmptyBatch_", Catalogs.ItemsBatches.EmptyRef());
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.OtherGoodsRecordingAsReceived"));
	ValuesOfHoldingParameters.Insert("StartDateOfFSB5", '000101010000');
	ValuesOfHoldingParameters.Insert("UseTraceableImportedGoodsAccounting", GetFunctionalOption("UseTraceableImportedGoodsAccounting")); 
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert(
		"BO_AdjustmentOfExpensesFromDisposalOfFixedAssets", 
		Enums.BusinessTransactions.AdjustmentOfExpensesFromDisposalOfFixedAssets);
		
	ValuesOfHoldingParameters.Insert(
		"SettingHO_AdjustmentOfExpensesFromDisposalOfFA", 
		Catalogs.BusinessTransactionsSettings.AdjustmentOfExpensesFromDisposalOfFixedAssets);
	
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;

	OtherGoodsRecordingAsReceivedLocalization.SupplementValuesOfParameters(ValuesOfHoldingParameters, Attributes);
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency,
		Undefined,
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
	
EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure InitializeProductAnalysisKeys(Query)

	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Department",          Query.Parameters.Department);
	QueryAnalyst.SetParameter("EmptyBatch_",            Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	Tab.Series,
	|	Tab.Warehouse,
	|	Tab.Products,
	|	Tab.Characteristic,
	|	Tab.Purpose
	|FROM (
	|	SELECT DISTINCT
	|		GoodsTable.Series AS Series,
	|		&Department AS Warehouse,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Purpose AS Purpose
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|
	|		LEFT JOIN
	|			InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON
	|			  GoodsTable.Products = Dimension.Products
	|			AND GoodsTable.Characteristic = Dimension.Characteristic
	|			AND GoodsTable.Series = Dimension.Series
	|			AND GoodsTable.Purpose = Dimension.Purpose
	|			AND &Department = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		&EmptyBatch_ AS Series,
	|		&Department AS Warehouse,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|
	|		LEFT JOIN
	|			InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON
	|			GoodsTable.Products = Dimension.Products
	|			AND GoodsTable.Characteristic = Dimension.Characteristic
	|			AND &EmptyAssignment = Dimension.Purpose
	|			AND &EmptyBatch_ = Dimension.Series
	|			AND &Department = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		GoodsTable.ItemsLocationAttributes.Series AS Series,
	|		GoodsTable.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		GoodsTable.ItemsLocationAttributes.Products AS Products,
	|		GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|		LEFT JOIN
	|			InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON
	|			GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND &EmptyAssignment = Dimension.Purpose
	|			AND GoodsTable.ItemsLocationAttributes.Series = Dimension.Series
	|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		GoodsTable.ItemsLocationAttributes.Series AS Series,
	|		GoodsTable.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		GoodsTable.ItemsLocationAttributes.Products AS Products,
	|		GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment AS Purpose
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.InventoryKinds AS GoodsTable
	|		LEFT JOIN
	|			InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON
	|			GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND &EmptyAssignment = Dimension.Purpose
	|			AND GoodsTable.ItemsLocationAttributes.Series = Dimension.Series
	|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	) AS Tab";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParameterTaxationOfOrganization(Query)
	
	If Query.Parameters.Property("TaxationOfOrganization") Then
		Return;
	EndIf;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Query.Parameters.Organization, Query.Parameters.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.OtherGoodsRecordingAsReceived.Name,
		"Goods");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Goods"" 													 		 AS TabularSectionName,
	|	DocumentTable.LineNumber 										 AS LineNumber,
	|	UNDEFINED														 AS Vendor,
	|	UNDEFINED														 AS Counterparty,
	|	UNDEFINED 														 AS VATRate,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) 						 AS AssetTaxClass,
	|	LineCodes.RowCode													 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS DocumentTable
	|	INNER JOIN Document.OtherGoodsRecordingAsReceived AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.Ref	 						AS Ref,
	|	GoodsTable.LineNumber	 					AS LineNumber,
	|	GoodsTable.Products	 					AS Products,
	|	GoodsTable.Characteristic 					AS Characteristic,
	|	GoodsTable.Purpose						AS Purpose,
	|	GoodsTable.Series			 					AS Series,
	|	GoodsTable.InventoryOwnerAttribute	 					AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber	 						AS CCDNumber,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.ExpenseAndIncomeItem				AS ExpenseAndIncomeItem,
	|	GoodsTable.DimensionOfExpenses					AS DimensionOfExpenses,
	|	GoodsTable.DimensionOfRevenue					AS DimensionOfRevenue,
	|	GoodsTable.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings				AS GLAccountSettings,
	|	GoodsTable.FixedAsset				    AS FixedAsset,
	|	GoodsTable.Lot AS Lot,
	|	ISNULL(GoodsTable.Lot.OperationCategory.MethodOfRepaymentOfCostOfAC,
	|		VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)) AS MethodOfRepaymentOfCostOfAC,
	|	ISNULL(GoodsTable.Lot.OperationCategory.MethodOfRepaymentOfCostTA,
	|		VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)) AS MethodOfRepaymentOfCostTA,
	|	GoodsTable.Count							AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	GoodsTable.Sum								AS Sum,
	|	GoodsTable.ItemsLocationAttributes 		AS ItemsLocationAttributes,
	|	GoodsTable.ExpenseAs					AS ExpenseAs,
	|	&Warehouse											AS Warehouse,
	|	GoodsTable.RowID               AS RowID 
	|INTO TTProducts_1
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	GoodsTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts) Export
	
	RegisterName = "TTTableProducts";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAnalysisKeys(Query);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "DocumentDataTableItems");
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "DocumentDataTableItems");
	QueryText =
	"SELECT
	|	GoodsTable.Ref	 					AS Ref,
	|	GoodsTable.LineNumber                	AS LineNumber,
	|	GoodsTable.Products               	AS Products,
	|	GoodsTable.Characteristic             	AS Characteristic,
	|	GoodsTable.Purpose                 	AS Purpose,
	|	GoodsTable.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey     	AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	CorDimension.DimensionKey               	AS CorItemsLocationAttributes,
	|	GoodsTable.Series			 				AS Series,
	|	GoodsTable.CCDNumber						AS CCDNumber,
	|	GoodsTable.InventoryOwnerAttribute	 				AS InventoryOwnerAttribute,
	|	GoodsTable.AssetTaxClass					AS AssetTaxClass,
	|	GoodsTable.VATActivityType			AS VATActivityType,
	|	GoodsTable.LotVendorAttributes 			AS LotVendorAttributes,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.ExpenseAndIncomeItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN GoodsTable.ExpenseAndIncomeItem
	|		ELSE UNDEFINED
	|	END										AS ExpenseItem,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.ExpenseAndIncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|			THEN GoodsTable.ExpenseAndIncomeItem
	|		ELSE UNDEFINED
	|	END										AS IncomeItem,
	|	CASE
	|		WHEN VALUETYPE(GoodsTable.ExpenseAndIncomeItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|		THEN GoodsTable.ExpenseAndIncomeItem
	|		ELSE UNDEFINED
	|	END										AS AssetAndLiabilityItem,
	|	GoodsTable.DimensionOfExpenses 			AS DimensionOfExpenses,
	|	GoodsTable.DimensionOfRevenue 				AS DimensionOfRevenue,
	|	GoodsTable.AssetsLiabilitiesDimension 	AS AssetsLiabilitiesDimension,
	|	GoodsTable.GLAccountSettings			AS GLAccountSettings,
	|	GoodsTable.FixedAsset			    AS FixedAsset,
	|	FALocation.FixedAssetsLocation           AS FALocation,
	|	FixedAssetsAccountingProcedure.LineOfBusiness      AS FAActivity,
	|	GoodsTable.Lot                        AS Lot,
	|	GoodsTable.MethodOfRepaymentOfCostOfAC    AS MethodOfRepaymentOfCostOfAC,
	|	GoodsTable.MethodOfRepaymentOfCostTA    AS MethodOfRepaymentOfCostTA,
	|	GoodsTable.Count	 				AS Count,
	|	GoodsTable.QuantityByGBRN 				AS QuantityByGBRN,
	|	GoodsTable.Sum			 				AS Sum,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	GoodsTable.Warehouse							AS Warehouse,
	|	CAST(GoodsTable.Warehouse AS Catalog.Warehouses).ShopFloorStockroom				 AS ShopFloorStockroom,
	|	GoodsTable.ExpenseAs				AS ExpenseAs,
	|	GoodsTable.RowID           AS RowID
	|INTO TTTableProducts
	|FROM
	|	TTProducts_1 AS GoodsTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON GoodsTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND GoodsTable.ItemsLocationAttributes.CHARACTERISTIC = AnalyticsWithoutAssignment.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CorDimension
	|	ON
	|		GoodsTable.Products = CorDimension.Products
	|		AND GoodsTable.Characteristic = CorDimension.Characteristic
	|		AND GoodsTable.Series = CorDimension.Series
	|		AND GoodsTable.Purpose = CorDimension.Purpose
	|		AND (&Department = CorDimension.StorageLocation)
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CorDimension.ProductCostElement
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.FixedAsset = GoodsTable.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.FixedAsset = GoodsTable.FixedAsset
	|";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Returns the text of the request to create a temporary table in the types of reserves
//	Parameters:
//		Query - Query - General request of the event
//		QueryTexts - Array of String - Array Of Request Texts
//	Returns:
//		String - query text.
//
Function QueryTextTTInventoryKinds(Query, QueryTexts) Export
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText =
	"SELECT
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.OriginWarehouse AS OriginWarehouse,
	|	InventoryKinds.InventoryOwnerAttributeShipment AS InventoryOwnerAttributeShipment,
	|	InventoryKinds.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributesShipment AS ItemsLocationAttributesShipment,
	|	InventoryKinds.ExpenseItem AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	InventoryKinds.Series AS Series,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	CommitteeKeys.DimensionKey AS CommitteeAnalytics,
	|	InventoryKinds.RowID AS RowID
	|INTO TTTypesOfStocks
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.InventoryKinds AS InventoryKinds
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|		ON CommitteeKeys.Products = InventoryKinds.ItemsLocationAttributes.Products
	|		AND CommitteeKeys.Characteristic = InventoryKinds.ItemsLocationAttributes.Characteristic
	|		AND CommitteeKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND CommitteeKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND CommitteeKeys.StorageLocation = InventoryKinds.InventoryOwnerAttribute.GoodsOwner
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|WHERE
	|	InventoryKinds.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName); 
	Return QueryText;
	
EndFunction

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                       AS Ref,
	|	UNDEFINED                               AS OrderDocument,
	|	GoodsTable.Ref                       AS Invoice,
	|	GoodsTable.Ref.Patch           AS Patch,
	|	GoodsTable.Ref.CorrectedDocument  AS CorrectedDocument,
	|	GoodsTable.Ref.Date                  AS Date,
	|	UNDEFINED                               AS Contract,
	|	UNDEFINED                               AS Terms,
	|	GoodsTable.Ref.GoodsReceiptOption AS GoodsReceiptOption,
	|	GoodsTable.Ref.Warehouse                 AS Warehouse,
	|	GoodsTable.Ref.Department         AS Sender,
	|	GoodsTable.Ref.BusinessOperation AS BusinessOperation,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.Purpose                   AS Purpose,
	|	GoodsTable.ToControlQuality    AS ToControlQuality,
	|	GoodsTable.Ref.ControlledLotReference  AS ControlledLotReference,
	|	FALSE                                       AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	FALSE                                       AS ExceedingOrder,
	|	GoodsTable.Series                        AS Series,
	|	GoodsTable.Count                   AS Count,
	|	FALSE                                       AS ReceiptUnderOrders,
	|	TRUE                                     AS ThisIsAnInvoice,
	|	FALSE                                       AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)";	
	
	CurrentMetadataObject1 = Metadata.Documents.OtherGoodsRecordingAsReceived;
	
	WarehousesServer.CreateReceiptOfGoodsOnOneWayBasis(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1,
		"SetOfSeries",
		"GoodsTable");
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                       AS Ref,
	|	UNDEFINED                               AS OrderDocument,
	|	GoodsTable.Ref                       AS Invoice,
	|	GoodsTable.Ref.Patch           AS Patch,
	|	GoodsTable.Ref.CorrectedDocument  AS CorrectedDocument,
	|	
	|	CASE WHEN GoodsTable.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				GoodsTable.Ref.DateOfReceipt
	|			ELSE
	|				GoodsTable.Ref.Date
	|		END AS Date,
	|	
	|	UNDEFINED                               AS Contract,
	|	UNDEFINED                               AS Terms,
	|	GoodsTable.Ref.GoodsReceiptOption AS GoodsReceiptOption,
	|	GoodsTable.Ref.Warehouse                 AS Warehouse,
	|	GoodsTable.Ref.Department         AS Sender,
	|	GoodsTable.Ref.BusinessOperation AS BusinessOperation,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.Purpose                   AS Purpose,
	|	GoodsTable.ToControlQuality    AS ToControlQuality,
	|	FALSE                                       AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.Ref.ControlledLotReference  AS ControlledLotReference,
	|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	FALSE                                       AS ExceedingOrder,
	|	GoodsTable.Series                        AS Series,
	|	GoodsTable.Count                   AS Count,
	|	FALSE                                       AS ReceiptUnderOrders,
	|	TRUE                                     AS ThisIsAnInvoice
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)";	
	
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
	|	VALUE(Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	NOT &AdvancedWarehousingOnGoodsReceipt AS ThisIsWarehouseRecord
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	&Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.GoodsReceiptByOtherTransactions),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	NOT &AdvancedWarehousingOnGoodsReceipt
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period AS DateOfReceipt,
	|	GoodsTable.Products               AS Products,
	|	GoodsTable.Characteristic             AS Characteristic,
	|	GoodsTable.Series                      AS Series,
	|	GoodsTable.Purpose                 AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber       AS CCDNumber
	|FROM
	|	TTTableProducts AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON
	|		GoodsTable.InventoryOwnerAttribute					  = UninvoicedReceipts.InventoryOwnerAttribute 
	|		AND GoodsTable.Products				  = UninvoicedReceipts.Products
	|		AND GoodsTable.Characteristic				  = UninvoicedReceipts.Characteristic 
	|		AND GoodsTable.Series						  = UninvoicedReceipts.Series
	|		AND GoodsTable.Purpose					  = UninvoicedReceipts.Purpose 
	|		AND GoodsTable.CCDNumber				  = UninvoicedReceipts.CCDNumber 
	|
	|WHERE
	|	&BusinessOperation <> VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|	AND (UninvoicedReceipts.DateOfReceipt IS NULL
	|	     OR UninvoicedReceipts.DateOfReceipt < &Period)
	|
	|ORDER BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Purpose,
	|	GoodsTable.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTInventoryKinds(Query, QueryTexts);
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = 
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED AS ShipmentCompany,
	|	UNDEFINED AS VATTaxation,
	|	TRUE AS Primary
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation <> VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|
	|UNION ALL
	|
	| SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE 
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|			THEN TableTypesOfStocks_.CommitteeAnalytics
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributesShipment <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributesShipment
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes
	|	END AS CorItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment AS CorInventoryOwnerAttribute,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	&Organization AS ShipmentCompany,
	|	(CASE WHEN TableTypesOfStocks_.ExpenseItem.CostAllocationOptionLocal
	|		= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|	THEN
	|		VALUE(Enum.VATTaxationTypes.ByActualUsage) 
	|	WHEN TableTypesOfStocks_.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.Allocation) THEN
	|		UNDEFINED
	|	ELSE
	|		WriteOff.ConsumptionForActivity
	|	END) AS VATTaxation,
	|	FALSE AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|	INNER JOIN Document.InventoryConsumption AS WriteOff
	|		ON TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = WriteOff.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTInventoryKinds(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber            AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute             AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeAnalytics     AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency      AS Currency,
	|	TableTypesOfStocks_.CCDNumber               AS CCDNumber,
	|	0                                         AS Count,
	|	0                                         AS RevenueAmount,
	|	0                                         AS RevenueAmountExclVATLocal,
	|	0                                         AS RevenueAmountMan,
	|	-TableTypesOfStocks_.Count            AS QuantityConsumed,
	|	0                                         AS QuantityToRegister,
	|	0                                         AS QuantityForRegistrationByProductBatchID,
	|	0                                         AS RevenueAmountToRegister,
	|	-TableTypesOfStocks_.Count            AS QuantityConsumedForIncoiceRegistration,
	|	-TableTypesOfStocks_.QuantityByGBRN      AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.Products           AS Products,
	|	TableTypesOfStocks_.Characteristic         AS Characteristic,
	|	&BusinessOperation                    AS BusinessOperation,
	|	UNDEFINED                              AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices     AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.RowID    AS FinRecordID,
	|	&BusinessTransactionSetting           AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID    AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""Goods"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	GoodsTable.LineNumber                 AS LineNumber,
	|	&Organization                              AS Organization,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes        AS LotVendorAttributes,
	|	&Ref                                   AS DocumentInflow,
	|	GoodsTable.Count                  AS Count,
	|	GoodsTable.SumMan                    AS Cost,
	|	GoodsTable.SumMan                    AS CostExcludingVAT,
	|	GoodsTable.SumCompl                   AS LocalCost,
	|	CASE WHEN GoodsTable.ExpenseItem.EnteredInTaxAccounting = FALSE THEN
	|		GoodsTable.SumCompl
	|	ELSE
	|		0
	|	END AS PermanentDifference,
	|	0                                         AS CostTD,
	|	GoodsTable.Products                AS Products,
	|	GoodsTable.Characteristic              AS Characteristic,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities),
	|		VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets),
	|		VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal),
	|		VALUE(Enum.BusinessTransactions.ReceiptFromProduction))
	|	AND &BatchAccountingVersion21
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	GoodsTable.LineNumber                 AS LineNumber,
	|	&Organization                              AS Organization,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes        AS LotVendorAttributes,
	|	&Ref                                   AS DocumentInflow,
	|	GoodsTable.Count                  AS Count,
	|	GoodsTable.SumMan                    AS Cost,
	|	GoodsTable.SumMan                    AS CostExcludingVAT,
	|	GoodsTable.SumCompl                   AS LocalCost,
	|	CASE WHEN GoodsTable.ExpenseItem.EnteredInTaxAccounting = FALSE THEN
	|		GoodsTable.SumCompl
	|	ELSE
	|		0
	|	END AS PermanentDifference,
	|	CASE
	|		WHEN GoodsTable.MethodOfRepaymentOfCostOfAC <> VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|			AND GoodsTable.MethodOfRepaymentOfCostTA = VALUE(Enum.WaysToRepayCostOfInventory.OnCommissioning)
	|			AND GoodsTable.Lot.StartDateOfOperation < &StartDateOfFSB5
	|		THEN GoodsTable.SumCompl
	|		ELSE
	|	0
	|	END
	|	AS CostTD,
	|	GoodsTable.Products                AS Products,
	|	GoodsTable.Characteristic              AS Characteristic,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.PutOutOfOperation)
	|	AND &BatchAccountingVersion21
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTInventoryKinds(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	GoodsTable.ExpenseItem AS IncomeAndExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS DimensionOfRevenue,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	GoodsTable.Count AS Count,
	|	GoodsTable.SumMan   AS Cost,
	|	GoodsTable.SumMan   AS CostExcludingVAT,
	|	GoodsTable.SumCompl  AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		GoodsTable.InventoryOwnerAttribute
	|	ELSE 
	|		GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	GoodsTable.Purpose.LineOfBusiness AS ProductLineOfBusiness
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReceiptFromProduction))
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	CASE
	|		WHEN GoodsTable.IncomeItem <> UNDEFINED
	|			THEN GoodsTable.IncomeItem
	|		ELSE GoodsTable.AssetAndLiabilityItem
	|	END AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	GoodsTable.Count AS Count,
	|	GoodsTable.SumMan   AS Cost,
	|	GoodsTable.SumMan   AS CostExcludingVAT,
	|	GoodsTable.SumCompl  AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		GoodsTable.InventoryOwnerAttribute
	|	ELSE 
	|		GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	GoodsTable.Purpose.LineOfBusiness AS ProductLineOfBusiness
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities)
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	CASE
	|		WHEN GoodsTable.ExpenseItem <> UNDEFINED
	|			THEN GoodsTable.ExpenseItem
	|		ELSE GoodsTable.AssetAndLiabilityItem
	|	END AS IncomeAndExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS DimensionOfRevenue,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	GoodsTable.Count AS Count,
	|	GoodsTable.SumMan   AS Cost,
	|	GoodsTable.SumMan   AS CostExcludingVAT,
	|	GoodsTable.SumCompl  AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		GoodsTable.InventoryOwnerAttribute
	|	ELSE 
	|		GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	GoodsTable.Purpose.LineOfBusiness AS ProductLineOfBusiness
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets)
	|	
	|UNION ALL
	|	
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE
	|		WHEN GoodsTable.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			GoodsTable.CommitteeAnalytics
	|		ELSE
	|			CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|				THEN GoodsTable.ItemsLocationAttributes
	|				ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|			END
	|	END AS ItemsLocationAttributes,
	|	&Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			GoodsTable.InventoryOwnerAttributeShipment.InventoryType
	|		ELSE GoodsTable.InventoryType
	|	END AS InventoryType,
	|	CASE
	|		WHEN GoodsTable.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			UNDEFINED
	|		ELSE GoodsTable.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|
	|	GoodsTable.ExpenseItem AS IncomeAndExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS DimensionOfRevenue,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	- GoodsTable.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN
	|				CASE WHEN GoodsTable.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|					UNDEFINED
	|				ELSE
	|					GoodsTable.InventoryOwnerAttribute
	|				END
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness
	|
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|	
	|	INNER JOIN Document.InventoryConsumption AS WriteOff
	|	ON GoodsTable.DocumentSalesOfGoodsAndServices = WriteOff.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|
	|UNION ALL	
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	GoodsTable.IncomeItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	GoodsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	GoodsTable.Count AS Count,
	|	GoodsTable.SumMan   AS Cost,
	|	GoodsTable.SumMan   AS CostExcludingVAT,
	|	GoodsTable.SumCompl  AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		GoodsTable.InventoryOwnerAttribute
	|	ELSE 
	|		GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	GoodsTable.Purpose.LineOfBusiness AS ProductLineOfBusiness
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation IN (VALUE(Enum.BusinessTransactions.PutOutOfOperation))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	GoodsTable.IncomeItem,
	|	GoodsTable.DimensionOfRevenue,
	|	
	|	GoodsTable.SumMan AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.SumMan
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN GoodsTable.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	
	|	&BusinessOperation   AS BusinessOperation,
	|	&LineOfBusiness AS LineOfBusiness,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.IncomeItem <> UNDEFINED
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	GoodsTable.IncomeItem,
	|	GoodsTable.DimensionOfRevenue,
	|	
	|	GoodsTable.SumMan AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.SumMan
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN GoodsTable.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	
	|	&BusinessOperation   AS BusinessOperation,
	|	&LineOfBusiness AS LineOfBusiness,
	|
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.IncomeItem <> UNDEFINED
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PutOutOfOperation)
	|
	|UNION ALL
	|
	// Dr 01.09 - Cr 91.01 – The cost of TMC
	|SELECT  
	|	&Period AS Period,
	|	
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	GoodsTable.FALocation AS Department,
	|	GoodsTable.IncomeItem,
	|	GoodsTable.DimensionOfRevenue,
	|	
	|	0 AS Sum,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	
	|	&BO_AdjustmentOfExpensesFromDisposalOfFixedAssets   AS BusinessOperation,
	|	GoodsTable.FAActivity AS LineOfBusiness,
	|
	|	GoodsTable.RowID AS FinRecordID,
	|	&SettingHO_AdjustmentOfExpensesFromDisposalOfFA   AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|";
	
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.AssetAndLiabilityItem AS AssetRef,
	|	CASE
	|		WHEN GoodsTable.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE GoodsTable.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	GoodsTable.SumMan AS Sum
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.AssetAndLiabilityItem <> UNDEFINED
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities),
	|								VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets))
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.AssetAndLiabilityItem AS AssetRef,
	|	GoodsTable.AssetsLiabilitiesDimension AS Dimension,
	|	GoodsTable.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	GoodsTable.SumCompl AS SumCompl,
	|	GoodsTable.SumMan AS SumMan,
	|	GoodsTable.SumMan AS AmountIncludingVAT,
	|	GoodsTable.SumMan AS AmountExcludingVAT,
	|
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.AssetAndLiabilityItem <> UNDEFINED
	|	AND &BusinessOperation IN (VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities),
	|								VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS Counterparty,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                   AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	0                                       AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	""""                                    AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref                                                             AS Ref,
	|	MAX(
	|		ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities
	|INTO TTBases
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentData
	|		LEFT JOIN Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&AdjustmentPeriod_                      AS VariancePeriod,
	|	&Organization                              AS Organization,
	|	&Department                            AS Department,
	|	GoodsTable.ExpenseItem              AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses           AS DimensionOfExpenses,
	|	&LineOfBusiness                  AS LineOfBusiness,
	|	UNDEFINED                              AS VATActivityType,
	|
	|	-GoodsTable.SumMan                   AS AmountIncludingVAT,
	|	-GoodsTable.SumMan                   AS AmountExcludingVAT,
	|	-GoodsTable.SumMan                   AS AmountExcludingVATMan,
	|	-GoodsTable.SumCompl                  AS AmountIncludingVATCompl,
	|	-GoodsTable.SumCompl                  AS AmountExcludingVATCompl,
	|	0                                         AS PermanentDifference,
	|	0                                         AS CostTD,
	|	&BusinessOperation                    AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID         AS FinRecordID,
	|	 VALUE(Catalog.BusinessTransactionsSettings.ReceiptFromProduction) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromProduction)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&AdjustmentPeriod_                      AS VariancePeriod,
	|	&Organization                              AS Organization,
	|	&Department                            AS Department,
	|	GoodsTable.ExpenseItem              AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses           AS DimensionOfExpenses,
	|	&LineOfBusiness                  AS LineOfBusiness,
	|	UNDEFINED                              AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID         AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.InventoryConsumptionReverseTransaction) AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&AdjustmentPeriod_                      AS VariancePeriod,
	|	&Organization                              AS Organization,
	|	&Department                            AS Department,
	|	GoodsTable.ExpenseItem              AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses           AS DimensionOfExpenses,
	|	&LineOfBusiness                  AS LineOfBusiness,
	|	UNDEFINED                              AS VATActivityType,
	|
	|	-GoodsTable.SumMan                   AS AmountIncludingVAT,
	|	-GoodsTable.SumMan                   AS AmountExcludingVAT,
	|	-GoodsTable.SumMan                   AS AmountExcludingVATMan,
	|	-GoodsTable.SumCompl                  AS AmountIncludingVATCompl,
	|	-GoodsTable.SumCompl                  AS AmountExcludingVATCompl,
	|	CASE
	|		WHEN NOT GoodsTable.ExpenseItem.EnteredInTaxAccounting
	|			THEN -GoodsTable.SumCompl
	|		ELSE 0
	|	END                                     AS PermanentDifference,
	|	0                                         AS CostTD,
	|	&BusinessOperation                    AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID         AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsRecordingAsReceived) AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets)
	|
	|UNION ALL
	|
	// Dr 10 - Cr 01.09 – The cost of the shopping center 
	|SELECT
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	&AdjustmentPeriod_                      AS VariancePeriod,
	|	&Organization                              AS Organization,
	|	GoodsTable.FALocation           AS Department,
	|	&RetirementItem                    AS ExpenseItem,
	|	GoodsTable.FixedAsset            AS DimensionOfExpenses,
	|	GoodsTable.FAActivity   AS LineOfBusiness,
	|	UNDEFINED                              AS VATActivityType,
	|
	|	GoodsTable.SumMan                    AS AmountIncludingVAT,
	|	GoodsTable.SumMan                    AS AmountExcludingVAT,
	|	GoodsTable.SumMan                    AS AmountExcludingVATMan,
	|	GoodsTable.SumCompl                   AS AmountIncludingVATCompl,
	|	GoodsTable.SumCompl                   AS AmountExcludingVATCompl,
	|	0                                         AS PermanentDifference,
	|	0                                         AS CostTD,
	|	&BusinessOperation                    AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID         AS FinRecordID,
	|	&BusinessTransactionSetting           AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|
	|UNION ALL
	|
	// Dr 01.09 - Cr 91.01 – The cost of TMC
	|SELECT  
	|	&Period                                   AS Period,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&AdjustmentPeriod_                      AS VariancePeriod,
	|	&Organization                              AS Organization,
	|	GoodsTable.FALocation           AS Department,
	|	&RetirementItem                    AS ExpenseItem,
	|	GoodsTable.FixedAsset            AS DimensionOfExpenses,
	|	GoodsTable.FAActivity   AS LineOfBusiness,
	|	UNDEFINED                              AS VATActivityType,
	|
	|	0                                         AS AmountIncludingVAT,
	|	0                                         AS AmountExcludingVAT,
	|	0                                         AS AmountExcludingVATMan,
	|	0                                         AS AmountIncludingVATCompl,
	|	0                                         AS AmountExcludingVATCompl,
	|	0                                         AS PermanentDifference,
	|	-GoodsTable.SumCompl                  AS CostTD,
	|	&BO_AdjustmentOfExpensesFromDisposalOfFixedAssets      AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID         AS FinRecordID,
	|	&SettingHO_AdjustmentOfExpensesFromDisposalOfFA AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTAnalysisOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTAnalysisOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	Expenses.ExpenseItem,
	|	Expenses.DimensionOfExpenses,
	|	Expenses.CompanyRecipient
	|
	|INTO TTAnalysisOfOtherExpenses
	|FROM
	|	TTOtherExpenses_ AS Expenses
	|WHERE
	|	Expenses.CompanyRecipient <> &Organization
	|";
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Organization                             AS Organization,
	|	&Department                           AS Department,
	|	&Ref                                  AS ExpenseReceiptDocument,
	|	GoodsTable.ExpenseItem             AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses          AS DimensionOfExpenses,
	|	UNDEFINED                             AS AssetsLiabilitiesDimension,
	|	GoodsTable.LotVendorAttributes       AS LotVendorAttributes,
	|	&LineOfBusiness                 AS LineOfBusiness,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.VATActivityType         AS VATActivityType,
	|
	|	-GoodsTable.SumMan  AS Cost,
	|	-GoodsTable.SumMan  AS CostExcludingVAT,
	|	0 AS VATManag,
	|	-GoodsTable.SumCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReceiptFromProduction) AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ReceiptFromProduction),
	|		VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets))
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref         AS Ref,
		|	TabPart.Ref.Date    AS Period,
		|	TabPart.Products   AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse   AS Warehouse,
		|	TabPart.Purpose     AS Purpose,
		|	TabPart.Ref.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count     AS Count,
		|	FALSE                    AS OnSchedule,
		|	UNDEFINED            AS OrderInSchedule
		|FROM
		|	Document.OtherGoodsRecordingAsReceived.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
		|		OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.OtherGoodsRecordingAsReceived.Goods AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|	AND TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse   AS Warehouse,
		|	
		|	CASE WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE THEN
		|				VALUE(Catalog.Assignments.EmptyRef)
		|			ELSE
		|				TabPart.Purpose
		|		END AS Purpose,
		|	
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	
		|	CASE
		|		WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.OtherGoodsRecordingAsReceived.EmptyRef)
		|			THEN TabPart.Ref
		|		ELSE TabPart.Ref.CorrectedDocument
		|	END AS OrderDocument,
		|	
		|	CASE WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
		|				TabPart.Ref.DateOfReceipt
		|			ELSE
		|				TabPart.Ref.Date
		|		END AS DateOfReceipt,
		|	
		|	TRUE                  AS AvailableForConsumption,
		|	FALSE                    AS OnSchedule,
		|	UNDEFINED            AS OrderInSchedule,
		|	0                       AS QuantityInGraph
		|FROM
		|	Document.OtherGoodsRecordingAsReceived.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

Function QueryTextTableInventoryInOperation(Query, QueryTexts, Registers)
	
	RegisterName = "InventoryInOperation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	&Organization                             AS Organization,
	|	&Department                           AS Department,
	|	TabularSection.Individual            AS Individual,
	|	TabularSection.Products              AS Products,
	|	TabularSection.Characteristic            AS Characteristic,
	|	CASE
	|		WHEN TabularSection.BatchesIndicationStatusSender = 20
	|			THEN TabularSection.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                    AS Series,
	|	CASE
	|		WHEN &UseTraceableImportedGoodsAccounting
	|			THEN TabularSection.CCDNumber
	|		ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|	END                                    AS CCDNumber,
	|	TabularSection.Lot                    AS Lot,
	|	TabularSection.LineOfBusiness   AS LineOfBusiness,
	|	TabularSection.AssetID          AS AssetID,
	|	TabularSection.Count                AS Count,
	|	TabularSection.QuantityByGBRN          AS QuantityByGBRN,
	|
	|	&BusinessOperation                   AS BusinessOperation,
	|	&BusinessTransactionSetting          AS BusinessTransactionSetting,
	|	TabularSection.RowID       AS FinRecordID
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS TabularSection
	|WHERE
	|	TabularSection.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PutOutOfOperation)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&Posted                               AS Posted,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentData
	|
	|		LEFT JOIN Document.OtherGoodsRecordingAsReceived.Goods AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN Document.OtherGoodsRecordingAsReceived.Goods AS DoublesTable
	|		ON DoublesTable.Ref = FATable.Ref
	|			AND DoublesTable.FixedAsset = FATable.FixedAsset
	|			AND DoublesTable.LineNumber < FATable.LineNumber
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal)
	|	AND DoublesTable.Ref IS NULL";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("TaxationOfOrganization");
	
	If Query <> Undefined Then
		SetRequestParameterTaxationOfOrganization(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableProducts");
	AdditionalTables.Add("TTTypesOfStocks");
	AdditionalTables.Add("TTAnalysisOfOtherExpenses");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableProducts(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTInventoryKinds(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[2], QueryTexts) Then
			QueryTextTableTTAnalysisOfOtherExpenses(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region InternalReceipt_Product
	
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
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN NOT &Patch
	|		THEN DocumentTable.Ref
	|		ELSE DocumentTable.CorrectedDocument
	|	END 											AS Lot,
	|	&TaxationOfOrganization						AS VATActivityType,
	|	UNDEFINED									AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes 		AS LotVendorAttributes,
	|	CASE WHEN NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											AS LotVendorAttributesCorr,
	|	0 												AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	UNDEFINED 						AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 		AS Count,
	|	TableTypesOfStocks_.RowID 				 		AS RowID,
	|	TableTypesOfStocks_.SumMan 						 		AS Cost,
	|	TableTypesOfStocks_.SumMan 						 		AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl 								AS LocalCost,
	|	0                                   				 		AS VATLocal,
	|	TableTypesOfStocks_.SumMan 						 		AS CostMan,
	|	0 													 		AS VATManag,
	|	0 													 		AS OffBalanceCost,
	|	0 													 		AS OffBalanceCostLocal,
	|	0													 		AS AddExpensesForGoods,
	|	0													 		AS AdditionalExpensesExcludingVAT,
	|	0															AS AddExpensesLocal,
	|	0															AS AddExpensesMan,
	|	CASE 
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities)
	|			THEN CASE 
	|					WHEN TableTypesOfStocks_.IncomeItem.EnteredInTaxAccounting = FALSE
	|						THEN TableTypesOfStocks_.SumCompl
	|					ELSE 0
	|				END 
	|		ELSE CASE
	|				WHEN TableTypesOfStocks_.ExpenseItem.EnteredInTaxAccounting = FALSE
	|					THEN TableTypesOfStocks_.SumCompl
	|				ELSE 0
	|			END
	|	END 												 		AS PermanentDifference,
	|	0
	|																AS CostTD,
	|	0													 		AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID    	 					  AS FinRecordID,
	|	&BusinessTransactionSetting          						  AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.PutOutOfOperation),
	|					VALUE(Enum.BusinessTransactions.GoodsReceiptByIncomeLiabilities),
	|					VALUE(Enum.BusinessTransactions.GoodsReceiptByExpencesAssets),
	|					VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal),
	|					VALUE(Enum.BusinessTransactions.ReceiptFromProduction))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	#Region WriteOffForExpensesAssets_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 					AS Period,
	|	DocumentTable.Ref 				AS Ref,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices	AS DocumentSource,
	|	WriteOff.Date							AS SourceDocumentPeriod,
	|	UNDEFINED 							AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_					AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	UNDEFINED									AS VATActivityType,
	|	UNDEFINED									AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, UNDEFINED) AS CorCompany,
	|	CASE 
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|			THEN TableTypesOfStocks_.CommitteeAnalytics
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributesShipment <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributesShipment
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes
	|	END 														AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment		    			AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    			AS ExpenseItemAssets,
	|	TableTypesOfStocks_.DimensionOfExpenses		    			AS AssetExpenseAnalytics,
	|	DocumentTable.LineOfBusiness					AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	UNDEFINED						AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction) 		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	 									AS RowID,
	|	TableTypesOfStocks_.RowID 						 		 		AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.InventoryConsumptionReverseTransaction) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|		INNER JOIN Document.InventoryConsumption AS WriteOff
	|			ON TableTypesOfStocks_.DocumentSalesOfGoodsAndServices = WriteOff.Ref
	|		LEFT JOIN TTAnalysisOfOtherExpenses AS OtherExpenses
	|			ON OtherExpenses.ExpenseItem = TableTypesOfStocks_.ExpenseItem
	|			AND OtherExpenses.DimensionOfExpenses = TableTypesOfStocks_.DimensionOfExpenses
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction)
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Registering goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Ghi tăng hàng hóa';
									|ru = 'Оприходование товаров';
									|en = 'Receipt of goods'; fa = 'رسید کالا';
									|it = 'Registrazione delle merci in contabilità';
									|pl = 'Zaksięgowanie towarów';
									|tr = 'Ürünlerin girilmesi'");
	PrintCommand.CheckPostingBeforePrint = True;

	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");

	OtherGoodsRecordingAsReceivedLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Invoice",
			NStr("vi = 'Ghi tăng hàng hóa';
				|ru = 'Оприходование товаров';
				|en = 'Receipt of goods'; fa = 'رسید کالا';
				|it = 'Registrazione delle merci in contabilità';
				|pl = 'Zaksięgowanie towarów';
				|tr = 'Ürünlerin girilmesi'"), FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	EndIf;
	OtherGoodsRecordingAsReceivedLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	If ValueIsFilled(AdditionalColumn) Then
		OutputAdditionalColumn = True;
	Else
		OutputAdditionalColumn = False;
		AdditionalColumn = "Code";
	EndIf;

	Query = New Query;
	QueryText =
	"SELECT
	|	Document.Ref AS Ref,
	|	Document.Number AS Number,
	|	Document.Date AS Date,
	|	Document.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	Document.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	Document.Warehouse AS Warehouse,
	|	Document.Currency AS Currency,
	|	Document.Department AS Department,
	|	Document.Organization AS Organization,
	|	PRESENTATION(Document.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(Document.Department) AS DepartmentPresentation
	|FROM
	|	Document.OtherGoodsRecordingAsReceived AS Document
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.Code AS AdditionalColumn,
	|	GoodsTable.Products.DescriptionFull AS ProductsPresentation,
	|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	&QueryTextUnitOfMeasureDescription AS UnitOfMeasurePresentation,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatus = 14
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	GoodsTable.Series.Presentation
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|WHERE
	|	NOT GoodsTable.BatchesIndicationStatus IN (4, 6, 8, 10)
	|	AND GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Products.Code,
	|	GoodsTable.Products.DescriptionFull,
	|	GoodsTable.Characteristic.DescriptionFull,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure),
	|	MAX(SeriesTable.Count),
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Price,
	|	GoodsTable.Sum,
	|	GoodsTable.Ref,
	|	MAX(SeriesTable.Count),
	|	SeriesTable.Series,
	|	SeriesTable.Series.Presentation
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS GoodsTable
	|		INNER JOIN Document.OtherGoodsRecordingAsReceived.SetOfSeries AS SeriesTable
	|		ON GoodsTable.Products = SeriesTable.Products
	|			AND GoodsTable.Characteristic = SeriesTable.Characteristic
	|			AND GoodsTable.Purpose = SeriesTable.Purpose
	|			AND GoodsTable.Ref = SeriesTable.Ref
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Products.Code,
	|	GoodsTable.Products.DescriptionFull,
	|	GoodsTable.Characteristic.DescriptionFull,
	|	GoodsTable.LineNumber,
	|	GoodsTable.Price,
	|	GoodsTable.Ref,
	|	SeriesTable.LineNumber,
	|	GoodsTable.Sum,
	|	SeriesTable.Series,
	|	SeriesTable.Series.Presentation,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure)
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (4, 6, 8, 10)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	QueryText = StrReplace(QueryText, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"GoodsTable.Package",
			"GoodsTable.Products"));
	
	If OutputAdditionalColumn And AdditionalColumn <> "Code" Then 
		QueryText = StrReplace(QueryText, "Products.Code", "Products." + AdditionalColumn);
	EndIf;
	
	Query.Text = QueryText;
	
	DocumentAttributes = New Structure("Number, Date, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym = NStr("vi = 'Ghi tăng hàng hóa';
							|ru = 'Оприходование товаров';
							|en = 'Receipt of goods'; fa = 'رسید کالا';
							|it = 'Registrazione delle merci in contabilità';
							|pl = 'Zaksięgowanie towarów';
							|tr = 'Ürünlerin girilmesi'", Common.DefaultLanguageCode());

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_OtherGoodsRecordingAsReceived_GoodsRecordingAsReceived";
	
	Template = PrintManagement.PrintFormTemplate("Document.OtherGoodsRecordingAsReceived.PF_MXL_GoodsRecordingAsReceived");
	
	If GetFunctionalOption("UseBusinessUnits") Then
		HeaderArea_ = Template.GetArea("Title");
	Else
		HeaderArea_ = Template.GetArea("TitleWithoutDivision");
	EndIf;
	
	HeaderArea_ = Template.GetArea("Title");

	If OutputAdditionalColumn Then
		Area_TableHeader        = Template.GetArea("TableHeader");
		AreaRow              = Template.GetArea("String");
		TableBasementArea       = Template.GetArea("TableFooter");
		Area_TableHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
	Else
		Area_TableHeader        = Template.GetArea("TableHeaderWithoutAdditionalColumn");
		AreaRow              = Template.GetArea("RowWithoutAdditionalColumn");	
		TableBasementArea       = Template.GetArea("TableBasementWithoutAdditionalColumn");
	EndIf;
	
	LabelArea       = Template.GetArea("Signatures");
	RegionAmountInWords = Template.GetArea("AmountInWords");
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResults = Query.ExecuteBatch();
	
	DocumentsSelection = QueryResults[0].Select();
	SelectionByTableParts = QueryResults[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	While DocumentsSelection.Next() Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		// We display the header of the invoice.
		FillPropertyValues(DocumentAttributes, DocumentsSelection);
		HeaderArea_.Parameters.Fill(DocumentsSelection);
		DataOfArea = New Structure;
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		DataOfArea.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		DataOfArea.Insert("TitleText",
						TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		DataOfArea.Insert("WarehousePresentation", WarehousesServer.GetWarehousePresentation(DocumentsSelection.WarehousePresentation));
		HeaderArea_.Parameters.Fill(DataOfArea);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);
		// Output of the header.
		
		TabDocument.Put(Area_TableHeader);
				
		AmountTotal = 0;
		TotalItems_1 = 0;
		
		// Output of strings.
		SelectionByTableParts.FindNext(New Structure("Ref",DocumentsSelection.Ref));
		
		SelectionByLines = SelectionByTableParts.Select();
		
		While SelectionByLines.Next() Do
									
			// Nomenclature.
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			AreaRow.Parameters.OwnGoodsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectionByLines.ProductsPresentation,
				SelectionByLines.CharacteristicPresentation,
				,
				SelectionByLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			
			// Data on prices, quantity.
			AreaRow.Parameters.Fill(SelectionByLines);
			
			AmountTotal = AmountTotal + SelectionByLines.Sum;
			TotalItems_1 = TotalItems_1 + 1;
			
			AreaRow.Parameters.LineNumber = TotalItems_1;
			TabDocument.Put(AreaRow);
			
		EndDo;
		
		// Output of the basement.
		TabDocument.Put(TableBasementArea);
		
		// Withdrawal of the Amount in words.
		RegionAmountInWords.Parameters.AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountTotal,
			DocumentsSelection.Currency);
		
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng %TotalItems_1%, tổng số tiền %AmountTotal% %Currency%';
									|ru = 'Всего наименований %TotalItems_1%, на сумму %AmountTotal% %Currency%';
									|en = 'Total names %TotalItems_1%, in the amount of %AmountTotal% %Currency%'; fa = 'Total names %TotalItems_1%, in the amount of %AmountTotal% %Currency%';
									|it = 'Totale articoli %TotalItems_1%, per un totale di %AmountTotal% %Currency%';
									|pl = 'Razem pozycji %TotalItems_1%, o wartości %AmountTotal% %Currency%';
									|tr = '%AmountTotal% tutar için, toplam tanım %TotalItems_1% %Currency%'", Common.DefaultLanguageCode());
		
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%AmountTotal%", Format(AmountTotal, "NFD=2"));
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%Currency%", String(DocumentsSelection.Currency));
		
		RegionAmountInWords.Parameters.TotalString = TextOfResultingLine;
		
		TabDocument.Put(RegionAmountInWords);
		
		// Output of signatures.
		TabDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);
		
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

#EndRegion

#Region LinesOfBusiness

// Parameters for embedding business lines in a document.
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
// Returns:
//  See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	If Form.Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromProduction Then
		DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	Else
		DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	EndIf;
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region Other

// Fill in based on inventory.
// 
// Parameters:
//  Object - DocumentObject.OtherGoodsRecordingAsReceived - Object
//  ArrayOfLineNumbers - Array of Number - Array Of Line Numbers
// 
// Returns:
//  Boolean - True if the filling is completed.
Function FillInOnBasisOfInventoryOfInventoryItemsOfOperation(Object, ArrayOfLineNumbers = Undefined) Export

	If Not ValueIsFilled(Object.DocumentBasis) Then
		Return True;
	EndIf;
	
	FillingData = Documents.PhysicalCountOfInventoryInOperation.FillingDataBasedOnInventory(
							Object.DocumentBasis, 
							Object.Date, 
							Enums.ActionsBasedOnPhysicalInventoryCount.PutOutOfOperation, 
							ArrayOfLineNumbers);
							
	Selection = FillingData.Attributes.Select();
	Selection.Next();
	FillPropertyValues(Object, Selection);
	
	If FillingData.TabularSection.IsEmpty() Then
		Return False;
	EndIf;
	
	CachedValues = Undefined;
	
	StructureOfActions = New Structure;
	
	ChoiceParameters = InventoryInOperationClientServer.ParametersOfSelectionOfGoodsInOperation();
	ChoiceParameters.Date = Object.Date;
	ChoiceParameters.Organization = Object.Organization;
	ChoiceParameters.Department = Object.Department;
	ChoiceParameters.CurrentRegistrar = Object.Ref;
	
	StructureOfActions.Insert("FillInBatchOfTMTSV", ChoiceParameters);
	
	RowsToProcess = New Array();
	
	Selection = FillingData.TabularSection.Select();
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		FillPropertyValues(NewRow, Selection);
		
		NewRow.Count = Selection.Quantity_Actual - Selection.QuantityAccordingToAccountingData;
		NewRow.NumberOfPackages = NewRow.Count;
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
		BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	If ValueIsFilled(Object.PriceKind) Then
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", Object.Date);
		FillParameters.Insert("Currency", Object.Currency);
		FillParameters.Insert("PriceKind", Object.PriceKind);
		FillParameters.Insert("Organization", Object.Organization);
				
		StructureOfActions = New Structure("RecalculateAmount", "NumberOfPackages");
		EnterprisePricesFillingServer.FillInPrices(Object.Goods,, FillParameters, StructureOfActions);
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.RecordInventoryInOperation);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	Return True;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.OtherGoodsRecordingAsReceived";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnGoodsReceipt",
		"	CASE
		|		WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
