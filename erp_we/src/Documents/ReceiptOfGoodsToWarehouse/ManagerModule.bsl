#If Not MobileStandaloneServer Then
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
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);	
EndProcedure

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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReceiptOfGoodsToWarehouseLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReceiptOfGoodsToWarehouse") Then
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		ReceiptOfGoodsToWarehouseLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.ReceiptOfGoodsToWarehouse);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
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
	Documents.TransferOrder.AddGenerateCommand(GenerationCommands);
	Documents.InventoryTransfer.AddGenerateCommand(GenerationCommands);
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	Documents.VendorPriceList.AddGenerateCommand(GenerationCommands);
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	ReceiptOfGoodsToWarehouseLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Populates the list of creation commands based on.
//
// Parameters:
//   CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTable - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddGenerateCommand(CreateCommandsBasedOn) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsToWarehouse) Then
		
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Id = Metadata.Documents.ReceiptOfGoodsToWarehouse.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReceiptOfGoodsToWarehouse);
		CreateBasedOnCommand.VerificationOfImplementationBeforeCreationBasedOn = True;
		
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

	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfExecutionDocumentCommand(ReportsCommands);
	
	ReceiptOfGoodsToWarehouseLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse, BusinessOperation, Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
//	Parameters:
//		Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
//	Returns:
//		See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.ReceiptOfGoodsToWarehouse";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = 
					WarehouseSeriesParameters.UseItemsBatch
					And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date)
						Or WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice    = False;
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceiptFromVendor);
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusGoodsAtPartners");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Ref");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Terms");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Contract");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("GoodsReceiptOption");
	
	TheseAreGoodsInTransit = ThisIsReceiptOfGoodsInTransit(Object.BusinessOperation);
	SeriesSpecificationParameters.QueryOptions.Insert("TheseAreGoodsInTransit", TheseAreGoodsInTransit);
	
	Return SeriesSpecificationParameters;
	
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
	|	Goods.BatchesIndicationStatusGoodsAtPartners,
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
	|	Goods.BatchesIndicationStatusGoodsAtPartners AS OldProductSeriesIndicationStatusFromPartners,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|							THEN 14
	|						ELSE 13
	|						END
	|				WHEN NOT &SeriesOnlyForCostPrice
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|								THEN CASE
	|										WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|												OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|											THEN CASE
	|													WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|															AND ProductsToRequest.Count > 0
	|														THEN 10
	|													ELSE 9
	|												END
	|										ELSE 0
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|								THEN CASE
	|										WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|												OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|											THEN CASE
	|													WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|															AND ProductsToRequest.Count > 0
	|														THEN 8
	|													ELSE 7
	|												END
	|										ELSE 0
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|									AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|										OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|									AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingFromVendor
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|											THEN CASE
	|													WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|															AND ProductsToRequest.Count > 0
	|														THEN 4
	|													ELSE 3
	|												END
	|										ELSE CASE
	|												WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|														AND ProductsToRequest.Count > 0
	|													THEN 2
	|												ELSE 1
	|											END
	|									END
	|							ELSE 0
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN ((ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries
	|										AND NOT &TheseAreGoodsInTransit)
	|									OR (ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor
	|										AND &TheseAreGoodsInTransit))
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatusGoodsAtPartners
	|	
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber                         AS LineNumber,
	|	Statuses.BatchesIndicationStatus                 AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatusGoodsAtPartners AS BatchesIndicationStatusGoodsAtPartners,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                       AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.OldProductSeriesIndicationStatusFromPartners <> Statuses.BatchesIndicationStatusGoodsAtPartners
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return ReceiptOfGoodsToWarehouseLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReceiptOfGoodsToWarehouseLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.ReceiptOfGoodsToWarehouse, DocumentRef.ReceiptOfGoodsToWarehouse - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Contract,
		|Partner,
		|Ref,
		|Date,
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department,
		|Patch,
		|CorrectedDocument");
	
	If ObjectAttributes.Ref <> Undefined And ObjectAttributes.Patch Then
		Attributes = AttributesOfControlledLotReference(ObjectAttributes.CorrectedDocument, FieldNameControlledLotReference);
		Return Attributes;
	EndIf;
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.DateOfReceipt = ObjectAttributes.Date;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.Partner;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
// Object - DocumentObject.ReceiptOfGoodsToWarehouse - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	&QualityControlContract AS Contract,
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

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	GoodsReceiptOption = FieldValuesToIdentifyReferences.GoodsReceiptOption;
	
	If Not ValueIsFilled(FieldValuesToIdentifyReferences.Terms)
		And Not ValueIsFilled(FieldValuesToIdentifyReferences.Contract) Then
		Return FieldValuesToIdentifyReferences.Ref;
	ElsIf Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(GoodsReceiptOption) Then
		Return FieldValuesToIdentifyReferences.Terms;
	ElsIf Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(GoodsReceiptOption) Then
		Return FieldValuesToIdentifyReferences.Contract;
	EndIf;
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True,
																		"Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ToControlQuality = "Object.Goods.ToControlQuality";
	
	Return FormTemplate;
	
EndFunction

// Fills in the parameters of a request that retrieves data about business operations used in the document.
//
// Parameters:
//	QueryOptions - Structure - request parameters to initialize:
//		* BusinessTransactionsPurchasingFromSupplier				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsImportPurchase				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsProcurementInEAEUCountries			 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsAdmissionToCommission				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsGoodsInTransit					 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsUnfacturedDeliveries		 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsDoNotShareProcurementProcessing	 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//
Procedure FillInParametersOfBusinessOperations(QueryOptions) Export
	
	UseImports = GetFunctionalOption("UseImports");
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	UseGoodsInTransitFromVendors = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	
	BusinessTransactionsPurchasingFromSupplier = New Array;
	
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsPurchasingFromSupplier.Add(
			Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	EndIf;
	
	If UseUninvoicedDeliveries Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.
			PurchaseFromVendorUninvoicedDelivery);
	EndIf;
	
	BusinessTransactionsImportPurchase = New Array;
	If UseImports
		And UseGoodsInTransitFromVendors Then
		
		BusinessTransactionsImportPurchase.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
		
	EndIf;
	
	BusinessTransactionsProcurementInEAEUCountries = New Array;
	If UseImportOfGoodsFromCustomsUnion Then
		If UseGoodsInTransitFromVendors Then
		BusinessTransactionsProcurementInEAEUCountries.Add(
			Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
		EndIf;
		
		If UseUninvoicedDeliveries Then
			BusinessTransactionsProcurementInEAEUCountries.Add(
				Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
		EndIf;
	EndIf;
	
	BusinessTransactionsGoodsInTransit = New Array;
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
		If UseImports Then
			BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
		EndIf;
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
		EndIf;
	EndIf;
	
	BusinessTransactionsUnfacturedDeliveries = New Array;
	If UseUninvoicedDeliveries Then
		BusinessTransactionsUnfacturedDeliveries.Add(
			Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
		
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsUnfacturedDeliveries.Add(
				Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
		EndIf;
	EndIf;
	
	QueryOptions.BusinessTransactionsPurchasingFromSupplier           = BusinessTransactionsPurchasingFromSupplier;
	QueryOptions.BusinessTransactionsImportPurchase             = BusinessTransactionsImportPurchase;
	QueryOptions.BusinessTransactionsProcurementInEAEUCountries          = BusinessTransactionsProcurementInEAEUCountries;
	QueryOptions.BusinessTransactionsGoodsInTransit                  = BusinessTransactionsGoodsInTransit;
	QueryOptions.BusinessTransactionsUnfacturedDeliveries    = BusinessTransactionsUnfacturedDeliveries;
	
EndProcedure

// Initializes the status structure of the document.
//
// Returns:
//   Structure - initialized document execution structure.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayReceiptTables", 1);
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("WarehouseInHeader",  True);
	
	Return StructureState;
	
EndFunction

// Fills in the GTD numbers in the transmitted TOR according to the customs Declaration document Or according to the data
// of goods in transit (according to the PH of the goods Organizations).
// 
// Parameters:
// 	Goods - ValueTable - the unloaded tabular part of the Goods of the document or the table of values
// 	 intended for loading into this tabular part. Composition of required columns:
// 		* Products - CatalogRef.Products -
// 		* Characteristic - CatalogRef.ItemsCharacteristics - 
// 		* Purpose - CatalogRef.Assignments - 
// 		* Series - CatalogRef.ItemsBatches - 
// 		* CCDNumber - CatalogRef.CCDNumbers -  
// 	ReferenceOrder - DefinedType.ReceiptReferenceOrder - The order of receipt. 
// 	Warehouse - CatalogRef.Warehouses - Document warehouse.
// 	Contract - CatalogRef.CounterpartyContracts - A contract document.
// 	ThisIsImportOperation - Boolean - Indicates the business operation Import goods in transit in the document.
// 	
// Returns:
// 	ValueTable - data for subsequent distribution to the incoming table of values. Composition of columns:
// 		* Products - CatalogRef.Products - 
// 		* Characteristic - CatalogRef.ItemsCharacteristics - 
// 		* Warehouse - CatalogRef.Warehouses - 
// 		* CCDNumber - CatalogRef.CCDNumbers - 
// 		* OriginCountry - CatalogRef.WorldCountries -  
// 		* NumberOfCCDRooms - Number - 
Function FillInCCDNumbers(Goods, ReferenceOrder, Warehouse, Contract, ThisIsImportOperation = False) Export
	
	QueryText = 
	"SELECT DISTINCT
	|	CAST(SourceTable.Products AS Catalog.Products) AS Products,
	|	SourceTable.Characteristic AS Characteristic,
	|	SourceTable.Purpose AS Purpose,
	|	SourceTable.Series AS Series,
	|	SourceTable.CCDNumber AS CCDNumber,
	|	&Warehouse AS Warehouse,
	|	&Contract AS Contract,
	|	&DocumentInflow AS DocumentInflow
	|INTO TTTableProducts
	|FROM
	|	&SourceTable AS SourceTable
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|
	|SELECT DISTINCT
	|	SourceTable.Products AS Products,
	|	SourceTable.Characteristic AS Characteristic,
	|	SourceTable.Purpose AS Purpose,
	|	SourceTable.Series AS Series,
	|	SourceTable.Warehouse AS Warehouse,
	|	SourceTable.Contract AS Contract,
	|	SourceTable.DocumentInflow AS DocumentInflow
	|
	|INTO GoodsTable
	|FROM
	|	TTTableProducts AS SourceTable
	|WHERE
	|	SourceTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	AND SourceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND SourceTable.Products.KeepRecordsByCCD
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsLocationAttributes.Ref AS ItemsLocationAttributes
	|INTO TTSelectionOfOrganizationsProductsFromPartners
	|FROM
	|	GoodsTable AS GoodsTable
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS ItemsLocationAttributes
	|		ON ItemsLocationAttributes.Products = GoodsTable.Products
	|			AND ItemsLocationAttributes.Characteristic = GoodsTable.Characteristic
	|			AND ItemsLocationAttributes.Purpose = GoodsTable.Purpose
	|			AND ItemsLocationAttributes.Series = GoodsTable.Series
	|			AND ItemsLocationAttributes.Contract = GoodsTable.Contract
	|WHERE
	|	NOT &ImportOperation
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	OrdersTable.Recorder AS Invoice,
	|	OrdersTable.Products AS Products,
	|	OrdersTable.Characteristic AS Characteristic,
	|	OrdersTable.Warehouse AS Warehouse
	|INTO TTListOfAcquisitions
	|FROM
	|	AccumulationRegister.PurchaseOrders AS OrdersTable
	|		INNER JOIN GoodsTable AS GoodsTable
	|		ON OrdersTable.PurchaseOrder = GoodsTable.DocumentInflow
	|		AND OrdersTable.Products = GoodsTable.Products
	|		AND OrdersTable.Characteristic = GoodsTable.Characteristic
	|		AND OrdersTable.Warehouse = GoodsTable.Warehouse
	|
	|WHERE
	|	VALUETYPE(OrdersTable.Recorder) = TYPE(Document.VendorInvoice)
	|
	|UNION ALL
	|
	|SELECT
	|	AcquisitionGoods.Ref AS Invoice,
	|	AcquisitionGoods.Products AS Products,
	|	AcquisitionGoods.Characteristic AS Characteristic,
	|	AcquisitionGoods.Warehouse AS Warehouse
	|FROM
	|	Document.VendorInvoice.Goods AS AcquisitionGoods
	|		INNER JOIN GoodsTable AS GoodsTable
	|		ON (AcquisitionGoods.Ref = GoodsTable.DocumentInflow
	|			OR AcquisitionGoods.Ref.Terms = GoodsTable.DocumentInflow
	|			OR AcquisitionGoods.Ref.Contract = GoodsTable.DocumentInflow)
	|		AND AcquisitionGoods.Products = GoodsTable.Products
	|		AND AcquisitionGoods.Characteristic = GoodsTable.Characteristic
	|		AND AcquisitionGoods.Warehouse = GoodsTable.Warehouse
	|WHERE
	|	AcquisitionGoods.Ref.Posted
	|
	|;
	|
	|SELECT
	|	CustomsDeclaration.Ref AS CustomsDeclaration,
	|	CustomsDeclaration.Products AS Products,
	|	CustomsDeclaration.Characteristic AS Characteristic,
	|	CustomsDeclaration.Warehouse AS Warehouse,
	|	CustomsDeclaration.CCDNumber AS CCDNumber,
	|	SUM(CustomsDeclaration.Count) AS Count
	|INTO TTCustomsDeclarations
	|FROM
	|	Document.CCDImport.Goods AS CustomsDeclaration
	|		INNER JOIN TTListOfAcquisitions AS Purchase
	|		ON Purchase.Invoice = CustomsDeclaration.DocumentInflow
	|			AND Purchase.Products = CustomsDeclaration.Products
	|			AND Purchase.Characteristic = CustomsDeclaration.Characteristic
	|			AND Purchase.Warehouse = CustomsDeclaration.Warehouse
	|			AND Purchase.Products = CustomsDeclaration.Products
	|
	|WHERE
	|	&ImportOperation
	|
	|GROUP BY
	|	CustomsDeclaration.Ref,
	|	CustomsDeclaration.Products,
	|	CustomsDeclaration.Characteristic,
	|	CustomsDeclaration.Warehouse,
	|	CustomsDeclaration.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CompanyGoods.ItemsLocationAttributes.Products	AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic	AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	CompanyGoods.ItemsLocationAttributes.Series			AS Series,
	|	CompanyGoods.ItemsLocationAttributes.Purpose		AS Purpose,
	|	CompanyGoods.CCDNumber									AS CCDNumber,
	|	CompanyGoods.CountBalance							AS Count
	|INTO TTProductsFromPartners
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			,
	|			(ItemsLocationAttributes) IN
	|				(SELECT
	|					Table_Selection.ItemsLocationAttributes
	|				FROM
	|					TTSelectionOfOrganizationsProductsFromPartners AS Table_Selection)
	|	) AS CompanyGoods
	|WHERE
	|	CompanyGoods.CountBalance > 0
	|	AND NOT &ImportOperation
	|;
	|
	|SELECT DISTINCT
	|	Inflow.Ref AS UninvoicedReceipt,
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	Inflow.Ref.Warehouse AS Warehouse,
	|	Inflow.CCDNumber AS CCDNumber,
	|	SUM(Inflow.Count) AS Count
	|INTO TTReceiptOfGoods
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS Inflow
	|		INNER JOIN GoodsTable AS GoodsTable
	|		ON Inflow.Ref.ReferenceOrder = GoodsTable.DocumentInflow
	|		AND Inflow.Products = GoodsTable.Products
	|		AND Inflow.Characteristic = GoodsTable.Characteristic
	|		AND Inflow.Ref.Warehouse = GoodsTable.Warehouse
	|WHERE
	|	Inflow.Ref.Posted
	|
	|GROUP BY
	|	Inflow.Ref,
	|	Inflow.Products,
	|	Inflow.Characteristic,
	|	Inflow.CCDNumber
	|;
	|
	|SELECT
	|	DataSet.Products,
	|	DataSet.Characteristic,
	|	DataSet.Warehouse,
	|	DataSet.CCDNumber,
	|	DataSet.CCDNumber.OriginCountry AS OriginCountry,
	|	SUM(DataSet.Count) AS NumberOfCCDRooms
	|FROM
	|	(
	|	SELECT
	|		Declarations.Products,
	|		Declarations.Characteristic,
	|		Declarations.Warehouse,
	|		Declarations.CCDNumber,
	|		Declarations.Count
	|	FROM
	|		TTCustomsDeclarations AS Declarations
	|
	|	UNION ALL
	|
	|	SELECT
	|		AtPartners.Products,
	|		AtPartners.Characteristic,
	|		AtPartners.Warehouse,
	|		AtPartners.CCDNumber,
	|		AtPartners.Count
	|	FROM
	|		TTProductsFromPartners AS AtPartners
	|
	|	UNION ALL
	|
	|	SELECT
	|		Inflow.Products,
	|		Inflow.Characteristic,
	|		Inflow.Warehouse,
	|		Inflow.CCDNumber,
	|		-Inflow.Count
	|	FROM
	|		TTReceiptOfGoods AS Inflow
	|	) AS DataSet
	|
	|GROUP BY
	|	DataSet.Products,
	|	DataSet.Characteristic,
	|	DataSet.Warehouse,
	|	DataSet.CCDNumber
	|";
	
	Query = New Query();
	Query.Text = QueryText;
	
	SourceTable = Goods.Copy();
	If SourceTable.Columns.Find("CCDNumber") = Undefined Then
		SourceTable.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	EndIf;
	
	If Goods.Columns.Find("CCDNumber") = Undefined Then
		Goods.Columns.Add("CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	EndIf;
	If Goods.Columns.Find("OriginCountry") = Undefined Then
		Goods.Columns.Add("OriginCountry", New TypeDescription("CatalogRef.WorldCountries"));
	EndIf;
	
	Query.SetParameter("SourceTable", SourceTable);
	Query.SetParameter("DocumentInflow", ReferenceOrder);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("ImportOperation", ThisIsImportOperation);
	
	Query.TempTablesManager = New TempTablesManager();
	
	CCDNumbers = Query.Execute().Unload();
	
	Var_Key = "Products, Characteristic";
	
	Condition = "On [Count]";
	InvoicesServer.DistributeQuantityAndFill(CCDNumbers, Goods, "NumberOfCCDRooms", Var_Key, Condition, False, "CCDNumber, OriginCountry");
	
	Return Goods;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Thu';
							|ru = 'Поступление';
							|en = 'Receipt'; fa = 'دریافت';
							|it = 'Arrivo';
							|pl = 'Receipt';
							|tr = 'Tahsilat'"));
	ReceiptOfGoodsToWarehouseLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
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

#Region VATAccounting

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ReceiptOfGoodsToWarehouse, DocumentObject.ReceiptOfGoodsToWarehouse - 
//				document of receipt of goods to the warehouse.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the tax levy of the Purchase order().
//
Function ParametersForFillingInVATTaxationPurchases(Document) Export
	
	DocumentAttributes = New Structure("Counterparty, Contract, BusinessOperation, Date");
	
	If TypeOf(Document) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillPropertyValues(FillParameters, DocumentAttributes);
	FillParameters.Period = DocumentAttributes.Date;
	BusinessTransactionsPurchasingFromSupplier  = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.ImportFromEAEU);
	BusinessTransactionsImportPurchase    = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseByImport);
	
	If BusinessTransactionsPurchasingFromSupplier.Find(DocumentAttributes.BusinessOperation) <> Undefined Then
		If DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit Then
			FillParameters.ReceiptOfGoodsInTransit = True;
		Else
			FillParameters.PurchaseOfGoods = True;
		EndIf;
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(DocumentAttributes.BusinessOperation) <> Undefined Then
		If DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit Then
			FillParameters.ReceiptOfGoodsInTransit = True;
		Else
			FillParameters.ImportOfGoodsFromCustomsUnion = True;
		EndIf;
	ElsIf BusinessTransactionsImportPurchase.Find(DocumentAttributes.BusinessOperation) <> Undefined Then
		FillParameters.ReceiptOfGoodsInTransit = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ReceiptOfGoodsToWarehouse, DocumentObject.ReceiptOfGoodsToWarehouse - 
//				document of receipt of goods to the warehouse.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Warehouse, Contract, LineOfBusiness, Department");
	
	If TypeOf(Document) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes);
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseByImport);
	
	If BusinessTransactionsPurchasingFromSupplier.Find(Document.BusinessOperation) <> Undefined
		Or BusinessTransactionsProcurementInEAEUCountries.Find(Document.BusinessOperation) <> Undefined
		Or BusinessTransactionsImportPurchase.Find(Document.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		
	EndIf;
	
	TheseAreGoodsInTransit = ThisIsReceiptOfGoodsInTransit(Document.BusinessOperation);
	
	If TheseAreGoodsInTransit Then
		FillParameters.Organization = Catalogs.Companies.EmptyRef();
		FillParameters.PurchaseOfGoods = False;
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "ReceiptOfGoodsToWarehouse");
	
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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.ReferenceOrder AS ReferenceOrder,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Counterparty.RegistrationCountry AS RegistrationCountry,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Terms.Currency AS AgreementCurrency,
	|	DocumentData.VendorPriceKind.Currency AS CurrencyOfSupplierSPriceType,
	|	DocumentData.VendorPriceKind,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.VATActivityType AS VATActivityType,
	|	DocumentData.Terms.PriceIncludesVAT AS PriceIncludesVATTerms,
	|	DocumentData.RegisterVendorPrices AS RegisterVendorPrices,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.ControlledLotReference AS ControlledLotReference,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Department AS Department,
	|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Author AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.SalesOpportunity AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ReceiptToOrderWarehouse,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber);
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	Query.SetParameter("Period", 							Attributes.Period);
	Query.SetParameter("Ref", 							Attributes.Ref);
	
	Query.SetParameter("ReferenceOrder", 						Attributes.ReferenceOrder);
	Query.SetParameter("Organization", 						Attributes.Organization);
	Query.SetParameter("AdjustmentPeriod_",				Attributes.AdjustmentPeriod_);
	Query.SetParameter("Partner", 							Attributes.Partner);
	Query.SetParameter("Counterparty", 						Attributes.Counterparty);
	Query.SetParameter("RegistrationCountry", 					Attributes.RegistrationCountry);
	Query.SetParameter("Terms", 						Attributes.Terms);
	Query.SetParameter("Currency", 							Attributes.Currency);
	Query.SetParameter("AgreementCurrency", 					Attributes.AgreementCurrency);
	Query.SetParameter("CurrencyOfSupplierSPriceType",			Attributes.CurrencyOfSupplierSPriceType);
	Query.SetParameter("VendorPriceKind",					Attributes.VendorPriceKind);
	Query.SetParameter("PriceIncludesVATOfDocument", 			Attributes.PriceIncludesVAT);
	Query.SetParameter("VATTaxation", 				Attributes.VATTaxation);
	Query.SetParameter("VATActivityType", 				Attributes.VATActivityType);
	Query.SetParameter("PriceIncludesVATTerms", 			Attributes.PriceIncludesVATTerms);
	Query.SetParameter("RegisterVendorPrices", 		Attributes.RegisterVendorPrices);
	Query.SetParameter("Warehouse", 								Attributes.Warehouse);
	Query.SetParameter("ControlledLotReference", 				Attributes.ControlledLotReference);
	Query.SetParameter("BusinessOperation", 				Attributes.BusinessOperation);
	Query.SetParameter("Department", 						Attributes.Department);
	Query.SetParameter("OptionOfAssignedAccountingOfGoods",	Attributes.OptionOfAssignedAccountingOfGoods);
	Query.SetParameter("GoodsReceiptOption", 				Attributes.GoodsReceiptOption);
	Query.SetParameter("Contract", 							Attributes.Contract);
	Query.SetParameter("Manager", 							Attributes.Manager);
	Query.SetParameter("Author", 								Attributes.Author);
	Query.SetParameter("LineOfBusiness", 			Attributes.LineOfBusiness);
	Query.SetParameter("SalesOpportunity", 							Attributes.SalesOpportunity);
	Query.SetParameter("EnabledGoodsAssignmentInSalesOpportunity",	Attributes.EnabledGoodsAssignmentInSalesOpportunity);
	Query.SetParameter("DocumentAmount", 					Attributes.DocumentAmount);
	Query.SetParameter("IncomingDocumentDate",				Attributes.IncomingDocumentDate);
	Query.SetParameter("IncomingDocumentNumber",			IncomingDocumentNumber);
	Query.SetParameter("Number", 								Attributes.Number);
	Query.SetParameter("Comment", 						Attributes.Comment);
	Query.SetParameter("DeletionMark", 					Attributes.DeletionMark);
	Query.SetParameter("Posted", 							Attributes.Posted);
	Query.SetParameter("ReceiptToOrderWarehouse", 		Attributes.ReceiptToOrderWarehouse);
	Query.SetParameter("Patch", 						Attributes.Patch);
	Query.SetParameter("ReversedDocument", 				Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument", 				Attributes.CorrectedDocument);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
	Query.SetParameter("BusinessTransactionsImportPurchase",		PurchasesServer.BusinessOperationsOnMain(
																		Enums.BusinessTransactions.PurchaseByImport));
	Query.SetParameter("MetadataIdentifier",       		Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("TaxationOfOrganization",			AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("BusinessTransactionSetting",     Attributes.BusinessTransactionSetting);
	Query.SetParameter("ExternalDocumentName",     Attributes.ExternalDocumentName);
	
	If Not ValueIsFilled(Attributes.GoodsReceiptOption) Then
		GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	Else
		GoodsReceiptOption = Attributes.GoodsReceiptOption;
	EndIf;
	
	If Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(GoodsReceiptOption)
		And Attributes.ReceiptToOrderWarehouse Then
		Query.SetParameter("DocumentInflow", Attributes.Contract);
	ElsIf Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(GoodsReceiptOption)
		And Attributes.ReceiptToOrderWarehouse Then
		Query.SetParameter("DocumentInflow", Attributes.Terms);
	ElsIf PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(GoodsReceiptOption) Then
		Query.SetParameter("DocumentInflow", Attributes.ReferenceOrder);
	Else
		Query.SetParameter("DocumentInflow", Attributes.ReferenceOrder);
	EndIf;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
	BusinessTransactionForReceipt = PairsOfSeparatePurchaseOperations.Get(Attributes.BusinessOperation);
	BusinessTransactionForReceipt = ?(Not ValueIsFilled(BusinessTransactionForReceipt),
		Attributes.BusinessOperation,
		BusinessTransactionForReceipt);
	
	Query.SetParameter("BusinessTransactionForReceipt", BusinessTransactionForReceipt);
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency IN (SELECT
	|				DefaultBaseCurrency.Value AS Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS
	|		RelativeExchangeRatesSliceLast
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableOfGoods_(Query, QueryTexts)
	
	RegisterName = "TemporaryTableOfGoods_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText =
		"SELECT
		|	Goods.PartnerProducts AS PartnerProducts,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	&VendorPriceKind AS VendorPriceKind,
		|	Goods.Package AS Package,
		|	CAST(Goods.Price * CASE
		|			WHEN &PriceIncludesVATOfDocument
		|					AND NOT &PriceIncludesVATTerms
		|				THEN 100 / (100 + Goods.VATRate.Rate1)
		|			WHEN NOT &PriceIncludesVATOfDocument
		|					AND &PriceIncludesVATTerms
		|				THEN (Goods.VATRate.Rate1 + 100) / 100
		|			ELSE 1
		|		END * CASE
		|			WHEN &Currency <> &AgreementCurrency
		|				THEN CASE
		|						WHEN ISNULL(ExchangeRatesOfAgreement_.CourseDenominator, 0) > 0
		|								AND ISNULL(ExchangeRatesOfAgreement_.CourseNumerator, 0) > 0
		|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
		|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
		|							THEN Currency_Rates.CourseNumerator * ExchangeRatesOfAgreement_.CourseDenominator / (ExchangeRatesOfAgreement_.CourseNumerator * Currency_Rates.CourseDenominator)
		|						ELSE 0
		|					END
		|			ELSE 1
		|		END AS NUMBER(31, 2)) AS Price
		|INTO TemporaryTableOfGoods_
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS Goods
		|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
		|		ON (Currency_Rates.Currency = &Currency)
		|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS ExchangeRatesOfAgreement_
		|		ON (ExchangeRatesOfAgreement_.Currency = &AgreementCurrency)
		|WHERE
		|	Goods.Ref = &Ref
		|	AND &RegisterVendorPrices";

	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTNomenclatureParameters(Query, QueryTexts)
	
	RegisterName = "TTNomenclatureParameters";
	
	QueryText = 
	"SELECT
	|	Goods.Ref AS Ref,
	|	MAX(Goods.BatchesIndicationStatus) AS BatchesIndicationStatus,
	|	MAX(ISNULL(Goods.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)) AS BatchesAccountingInUninvoicedGoodsDeliveries,
	|	MAX(ISNULL(Goods.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)) AS BatchesAccountingOfGoodsInTransitFromVendor,
	|	Goods.ItemsLocationAttributes.Products AS Products
	|INTO TTNomenclatureParameters
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.ItemsLocationAttributes.Products
	|
	|INDEX BY
	|	Ref,
	|	Products
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts)
	
	RegisterName = "ProductsWithDifferentPackagingPrices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf; 
	
	QueryText = "SELECT
	               |	Goods.Products AS Products,
	               |	Goods.Characteristic AS Characteristic,
	               |	&VendorPriceKind AS VendorPriceKind,
	               |	AVG(Goods.Price / CASE
	               |			WHEN Goods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	               |				THEN &QueryTextPackagingFactor
	               |			ELSE 1
	               |		END) AS PricePerBaseUnit,
	               |	COUNT(DISTINCT Goods.Package) AS NumberOfDifferentPackages
	               |INTO ProductsWithDifferentPackagingPrices
	               |FROM
	               |	TemporaryTableOfGoods_ AS Goods
	               |
	               |GROUP BY
	               |	Goods.Products,
	               |	Goods.Characteristic";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	CASE
	|		WHEN DataSource.Ref.ReferenceOrder IN
	|		(
	|		UNDEFINED,
	|		VALUE(Document.VendorInvoice.EmptyRef),
	|		VALUE(Document.PurchaseOrder.EmptyRef),
	|		VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|		VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		)
	|		THEN
	|			DataSource.Ref
	|		ELSE
	|			DataSource.Ref.ReferenceOrder
	|	END                                        AS Invoice,
	|	DataSource.Ref.ReferenceOrder           AS OrderDocument,
	|	DataSource.Ref.Contract                AS Contract,
	|	DataSource.Ref.Terms             AS Terms,
	|	DataSource.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	DataSource.Ref.Date                   AS Date,
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference   AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DataSource.BatchesIndicationStatusInWarehouses  AS BatchesIndicationStatusInWarehouses,
	|	DataSource.BatchesIndicationStatusGoodsAtPartners AS BatchesIndicationStatusGoodsAtPartners,
	|	FALSE                                         AS ExceedingOrder,
	|	DataSource.Ref.Warehouse                  AS Warehouse,
	|	DataSource.Ref.Partner                AS Sender,
	|	DataSource.Ref.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	NOT DataSource.Ref.ReferenceOrder IN
	|		(
	|		UNDEFINED,
	|		VALUE(Document.VendorInvoice.EmptyRef),
	|		VALUE(Document.PurchaseOrder.EmptyRef),
	|		VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|		VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|		)
	|	AS ReceiptUnderOrders
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN(&Ref)
	|
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.ReceiptOfGoodsToWarehouse;
	
	WarehousesServer.ToIssueReceiptOfGoodsOnDvukhodovka(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1,
		"SetOfSeries");

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
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	&Partner AS Sender,
	|	VALUE(Enum.WarehouseTransactions.ReceiptFromVendor) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	CASE
	|		WHEN NOT &ReceiptToOrderWarehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.SetOfSeries AS SeriesTable
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
	|	&Partner,
	|	VALUE(Enum.WarehouseTransactions.ReceiptFromVendor),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	CASE
	|		WHEN NOT &ReceiptToOrderWarehouse
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ProductsWithDifferentPackagingPrices", QueryTexts) Then
		QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "SELECT
	               |	MAX(Goods.PartnerProducts) AS PartnerProducts,
	               |	Goods.Products AS Products,
	               |	Goods.Characteristic AS Characteristic,
	               |	&VendorPriceKind AS VendorPriceKind,
	               |	&CurrencyOfSupplierSPriceType AS Currency,
	               |	&Period AS Period,
	               |	&Partner AS Partner,
	               |	MIN(CASE
	               |			WHEN ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	               |				THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	               |			ELSE Goods.Package
	               |		END) AS Package,
	               |	CAST(AVG(CASE
	               |				WHEN ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	               |					THEN ProductsWithDifferentPackagingPrices.PricePerBaseUnit
	               |				ELSE Goods.Price
	               |			END * CASE
	               |				WHEN &Currency <> Goods.VendorPriceKind.Currency
	               |					THEN CASE
	               |							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	               |									AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	               |									AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	               |									AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	               |								THEN Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator / (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	               |							ELSE 0
	               |						END
	               |				ELSE 1
	               |			END) AS NUMBER(31,2)) AS Price
	               |FROM
	               |	TemporaryTableOfGoods_ AS Goods
	               |		LEFT JOIN ProductsWithDifferentPackagingPrices AS ProductsWithDifferentPackagingPrices
	               |		ON Goods.Products = ProductsWithDifferentPackagingPrices.Products
	               |			AND Goods.Characteristic = ProductsWithDifferentPackagingPrices.Characteristic
	               |		LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
	               |		ON (Currency_Rates.Currency = &Currency)
	               |		LEFT JOIN TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	               |		ON (CurrencyRatesPrices.Currency = &CurrencyOfSupplierSPriceType)
	               |WHERE
	               |	NOT Goods.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	               |
	               |GROUP BY
	               |	Goods.Products,
	               |	Goods.Characteristic";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTNomenclatureParameters", QueryTexts) Then
		QueryTextTTNomenclatureParameters(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	GoodsTable.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	0                                           AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	TRUE                                      AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (GoodsTable.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|	)
	|	AND NOT (GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	// Series at cost (14).
	|		AND (GoodsTable.BatchesIndicationStatus = 14
	|		AND NOT (ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
	|			OR ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)))
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	GoodsTable.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.WarehouseInventoryAttributes            AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                      AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	GoodsTable.QuantityByGBRN              AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	TRUE                                      AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
	|		INNER JOIN TTNomenclatureParameters AS SeriesStatusData
	|		ON GoodsTable.Ref = SeriesStatusData.Ref
	|			AND GoodsTable.ItemsLocationAttributes.Products = SeriesStatusData.Products
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (GoodsTable.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|	)
	|	AND GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	// Series at cost (14).
	|	AND (SeriesStatusData.BatchesIndicationStatus = 14
	|		AND NOT (SeriesStatusData.BatchesAccountingInUninvoicedGoodsDeliveries
	|			OR SeriesStatusData.BatchesAccountingOfGoodsInTransitFromVendor))
	|
	|UNION ALL
	|
	// In transit, purchase compensation for GTD with series at cost.
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	Analysts.DimensionKey AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	0                                           AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	TRUE                                      AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Analysts
	|		ON GoodsTable.ItemsLocationAttributes.Products = Analysts.Products
	|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Analysts.Characteristic
	|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = Analysts.StorageLocation
	|			AND GoodsTable.ItemsLocationAttributes.Purpose = Analysts.Purpose
	|			AND GoodsTable.ItemsLocationAttributes.ProductCostElement = Analysts.ProductCostElement
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Analysts.Series
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (GoodsTable.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|	)
	|	AND GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	// Series at cost (14).
	|	AND (GoodsTable.BatchesIndicationStatus = 14
	|		AND NOT (ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
	|			OR ISNULL(GoodsTable.ItemsLocationAttributes.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)))
	|
	|UNION ALL
	|
	// En route, reverse purchases for GTD (including RNPT) with series at cost price.
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Period                                     AS Period,
	|	Analysts.DimensionKey AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.WarehouseInventoryAttributes            AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                      AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	GoodsTable.QuantityByGBRN              AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	TRUE                                      AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Analysts
	|		ON GoodsTable.ItemsLocationAttributes.Products = Analysts.Products
	|			AND GoodsTable.ItemsLocationAttributes.Characteristic = Analysts.Characteristic
	|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = Analysts.StorageLocation
	|			AND GoodsTable.ItemsLocationAttributes.Purpose = Analysts.Purpose
	|			AND GoodsTable.ItemsLocationAttributes.ProductCostElement = Analysts.ProductCostElement
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Analysts.Series
	|		INNER JOIN TTNomenclatureParameters AS SeriesStatusData
	|		ON GoodsTable.Ref = SeriesStatusData.Ref
	|			AND GoodsTable.ItemsLocationAttributes.Products = SeriesStatusData.Products
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (GoodsTable.Ref.BusinessOperation IN
	|		(VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|	)
	|	AND GoodsTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	// Series at cost (14).
	|	AND (SeriesStatusData.BatchesIndicationStatus = 14
	|		AND NOT (SeriesStatusData.BatchesAccountingInUninvoicedGoodsDeliveries
	|			OR SeriesStatusData.BatchesAccountingOfGoodsInTransitFromVendor))
	|
	|UNION ALL
	|
	// Goods are on the way.
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Period                                     AS Period,
	|	GoodsTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	0                                           AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	FALSE                                        AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
	|	)
	|
	|
	|UNION ALL
	|
	// Non-invoice.
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Period                                     AS Period,
	|	GoodsTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	0                                           AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	FALSE                                        AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|	)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization                                AS Organization,
	|	GoodsTable.WarehouseInventoryAttributes            AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	GoodsTable.Count                    AS Count,
	|	0                                           AS QuantityByGBRN,
	|	&BusinessOperation                      AS BusinessOperation,
	|	UNDEFINED                                AS ShipmentCompany,
	|	FALSE                                        AS Primary
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|	)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period                      AS DateOfReceipt,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses <> 0
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                        AS Series,
	|	GoodsTable.Purpose     AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON GoodsTable.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND GoodsTable.Products = UninvoicedReceipts.Products
	|			AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic
	|			AND GoodsTable.Series = UninvoicedReceipts.Series
	|			AND GoodsTable.Purpose = UninvoicedReceipts.Purpose
	|			AND VALUE(Catalog.CCDNumbers.EmptyRef) = UninvoicedReceipts.CCDNumber
	|WHERE
	|	GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (UninvoicedReceipts.DateOfReceipt IS NULL
	|			OR UninvoicedReceipts.DateOfReceipt < &Period)
	|	AND GoodsTable.Ref = &Ref
	|
	|ORDER BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses <> 0
	|			THEN GoodsTable.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	GoodsTable.Purpose";
	
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&Warehouse                   AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&IncomingDocumentDate  AS SourceDocumentDate,
	|	&IncomingDocumentNumber AS SourceDocumentNumber,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency,
	    Query.Parameters.Currency,
	    Query.Parameters.Period,
	    Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.ReceiptOfGoodsToWarehouse.Name,
		"InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds""							AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN DocumentData.BusinessOperation IN (
	|		  VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		  VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		  VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|			THEN DocumentData.VATActivityType
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|				AND DocumentData.LineOfBusiness.Purpose.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|				AND DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentData.VATActivityType
	|	END                               	AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.ReceiptOfGoodsToWarehouse AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.ItemsLocationAttributes.Products
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = "
	|SELECT DISTINCT
	|	InventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	&EmptyAssignment AS Purpose,
	|	InventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	InventoryKinds.ItemsLocationAttributes.StorageLocation AS StorageLocation
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON InventoryKinds.ItemsLocationAttributes.Products = Dimension.Products
	|			AND InventoryKinds.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributes.Series = Dimension.Series
	|			AND InventoryKinds.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Products AS Products,
	|	InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Characteristic AS Characteristic,
	|	&EmptyAssignment AS Purpose,
	|	InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Series AS Series,
	|	InventoryKinds.ItemsLocationAttributesGoodsAtPartners.StorageLocation AS StorageLocation
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Products = Dimension.Products
	|			AND InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Characteristic = Dimension.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Series = Dimension.Series
	|			AND InventoryKinds.ItemsLocationAttributesGoodsAtPartners.StorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	 
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	
	|	ItemsLocationAttributesGoodsAtPartners.Products AS PartnerProducts_,
	|	ItemsLocationAttributesGoodsAtPartners.Characteristic AS CharacteristicsOfPartners,
	|	ItemsLocationAttributesGoodsAtPartners.Series AS SeriesWithPartners,
	|	ItemsLocationAttributesGoodsAtPartners.Purpose AS AppointmentWithPartners,
	
	|	TableTypesOfStocks_.ItemsLocationAttributes AS DimensionOfProductItem,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfProductsWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS AnalyticsProductsFromPartners,
	|	AnalyticsForPartnersWithoutAppointment.DimensionKey AS AnalyticsProductsFromPartnersWithoutDestination,
	|
	|	TableOfBatchAccountingAnalysts.VATTaxation AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.WarehouseInventoryAttributes AS WarehouseInventoryAttributes,
	|	TableTypesOfStocks_.WarehouseInventoryAttributes.InventoryType AS TypeOfStockInStock,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Count AS Count,
	|
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVATMan,
	|	CAST(TableTypesOfStocks_.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS VATAmountMan,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|	
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	CAST(TableTypesOfStocks_.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS VATAmountCompl,
	|
	|	TableTypesOfStocks_.RowID AS RowID
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsForPartnersWithoutAppointment
	|		ON TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.Products = AnalyticsForPartnersWithoutAppointment.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.Characteristic = AnalyticsForPartnersWithoutAppointment.Characteristic
	|			AND TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.Series = AnalyticsForPartnersWithoutAppointment.Series
	|			AND TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners.StorageLocation = AnalyticsForPartnersWithoutAppointment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsForPartnersWithoutAppointment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = TableTypesOfStocks_.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction	

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 

	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	InventoryKinds.AnalyticsProductsFromPartners AS ItemsLocationAttributes,
	|	&Contract AS Warehouse,
	|	InventoryKinds.LineOfBusiness AS LineOfBusiness,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.DimensionOfProductItem AS CorItemsLocationAttributes,
	|	InventoryKinds.Warehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.LineOfBusiness AS CorLineOfBusiness,
	|	InventoryKinds.TypeOfStockInStock AS CorInventoryType,
	|	InventoryKinds.WarehouseInventoryAttributes AS CorInventoryOwnerAttribute,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.Count AS CorQuantity,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.WarehouseInventoryAttributes
	|		ELSE InventoryKinds.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	InventoryKinds.AnalyticsProductsFromPartners AS ItemsLocationAttributes,
	|	&Contract AS Warehouse,
	|	InventoryKinds.LineOfBusiness AS LineOfBusiness,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.DimensionOfProductItem AS CorItemsLocationAttributes,
	|	InventoryKinds.Warehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.LineOfBusiness AS CorLineOfBusiness,
	|	InventoryKinds.TypeOfStockInStock AS CorInventoryType,
	|	InventoryKinds.WarehouseInventoryAttributes AS CorInventoryOwnerAttribute,
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.Count AS CorQuantity,
	|	InventoryKinds.AmountIncludingVATMan AS Cost,
	|	InventoryKinds.AmountExcludingVATMan AS CostExcludingVAT,
	|	InventoryKinds.AmountExcludingVATCompl AS LocalCost,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|		THEN
	|			CASE WHEN InventoryKinds.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN
	|				InventoryKinds.AmountIncludingVATMan
	|			ELSE
	|				InventoryKinds.AmountExcludingVATMan
	|			END
	|		ELSE 0
	|	END AS CostMan,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.WarehouseInventoryAttributes
	|		ELSE InventoryKinds.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	TemporaryTableQueryTexts = New Map();
	
	FullDocumentName      = "Document.ReceiptOfGoodsToWarehouse";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	RedefiningParameterCalculation.Insert("BusinessTransactionForReceipt", 
		"CASE
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
		|		THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
		|		THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
		|		THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
		|		THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
		|		THEN VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|END");
	RedefiningParameterCalculation.Insert("DocumentInflow",
		"CASE
		|WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|THEN
		|	GoodsTable.Ref.Contract
		|WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|														  VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|														  VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|THEN
		|	GoodsTable.Ref.Terms
		|ELSE
		|	GoodsTable.Ref.ReferenceOrder
		|END");
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	ElsIf RegisterName = "CompanyGoods" Then
		TemporaryTableQueryTexts.Insert("TTNomenclatureParameters",
			QueryTextTTNomenclatureParameters(Query, QueryTexts));
		QueryText = QueryTextTableCompanyGoods(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	&ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TRUE AS OnSchedule,
		|	TabPart.Ref.ReferenceOrder AS OrderInSchedule
		|FROM
		|	Document.ReceiptOfGoodsToWarehouse.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
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
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Moving_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.AnalyticsProductsFromPartners      	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 	AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.DimensionOfProductItem			AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.WarehouseInventoryAttributes				AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity					AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.Manager				AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion

	#Region ExternalReceipt_Product_UnfacturedDeliveryIEAES_Expense
	
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
	|	TableTypesOfStocks_.AnalyticsProductsFromPartners		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	CASE WHEN &Patch
	|		THEN DocumentTable.CorrectedDocument
	|		ELSE DocumentTable.Ref
	|	END 												AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			 	AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.DimensionOfProductItem			AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.WarehouseInventoryAttributes				AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	UNDEFINED 									AS RowID,
	|
	|	TableTypesOfStocks_.AmountIncludingVATMan 				AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl				AS LocalCost,
	|	TableTypesOfStocks_.VATAmountCompl					AS VATLocal,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS CostMan,
	|	TableTypesOfStocks_.VATAmountMan					AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	(CASE
	|		WHEN DocumentTable.Contract.ProcedureToRecordUninvoicedDeliveriesTA 
	|		 = VALUE(Enum.OptionsToRecordUninvoicedDeliveriesTA.RecordOnInvoiceEntry)
	|			THEN CASE
	|				WHEN TableTypesOfStocks_.VATActivityType IN (
	|				 VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				 VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|					THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|				ELSE TableTypesOfStocks_.AmountExcludingVATCompl END
	|		ELSE 0 END) 								AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries) AS AccountingSection,
	|	CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 											AS CorAccountingSection,
	|	DocumentTable.BusinessOperation 			AS BusinessOperation,
	|	TableTypesOfStocks_.RowID			AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ExternalReceipt_Product_UnfacturedDeliveryIEAES_Arrival
	
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
	|	TableTypesOfStocks_.DimensionOfProductItem			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.WarehouseInventoryAttributes				AS InventoryOwnerAttribute,
	|	CASE WHEN &Patch
	|		THEN DocumentTable.CorrectedDocument
	|		ELSE DocumentTable.Ref
	|	END 												AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			 	AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	UNDEFINED 									AS RowID,
	|
	|	TableTypesOfStocks_.AmountIncludingVATMan 				AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl				AS LocalCost,
	|	TableTypesOfStocks_.VATAmountCompl					AS VATLocal,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS CostMan,
	|	TableTypesOfStocks_.VATAmountMan					AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	(CASE
	|		WHEN DocumentTable.Contract.ProcedureToRecordUninvoicedDeliveriesTA 
	|		 = VALUE(Enum.OptionsToRecordUninvoicedDeliveriesTA.RecordOnInvoiceEntry)
	|			THEN CASE
	|				WHEN TableTypesOfStocks_.VATActivityType IN (
	|				 VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				 VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|					THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|				ELSE TableTypesOfStocks_.AmountExcludingVATCompl END
	|		ELSE 0 END) 								AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			AS BusinessOperation,
	|	TableTypesOfStocks_.RowID			AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	
	Return JobPrintingRules;
	
EndFunction


// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Receipt invoice
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PurchaseInvoice";
	PrintCommand.Presentation = NStr("vi = 'Hóa đơn nhập hàng';
									|ru = 'Приходная накладная';
									|en = 'Purchase invoice'; fa = 'فاکتور خرید';
									|it = 'Bolla di acquisto';
									|pl = 'Faktura przyjęcie z zewnątrz';
									|tr = 'Sevk irsaliyesi'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	
	ReceiptOfGoodsToWarehouseLocalization.AddPrintCommands(PrintCommands);
	
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PurchaseInvoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"PurchaseInvoice", 
			NStr("vi = 'Hóa đơn nhập hàng';
				|ru = 'Приходная накладная';
				|en = 'Purchase invoice'; fa = 'فاکتور خرید';
				|it = 'Bolla di acquisto';
				|pl = 'Faktura przyjęcie z zewnątrz';
				|tr = 'Sevk irsaliyesi'"), 
			FormPrintedFormReceiptInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
EndProcedure

Function FormPrintedFormReceiptInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_UninvoicedReceipt_PurchaseInvoice";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	PackagingUsage = GetFunctionalOption("UseItemPackages");
	
	Query = New Query(
	"SELECT DISTINCT
	|	Documents.Ref AS Ref,
	|	Documents.Organization AS Organization,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	Documents.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	Documents.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	Documents.Patch AS Patch,
	|	Documents.Organization.Prefix AS Prefix,
	|	Documents.Warehouse AS Warehouse
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS Documents
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	&QueryTextUnitOfMeasureDescription AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	Goods.Products.DescriptionFull AS Products,
	|	Goods.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END AS Package,
	|	FALSE AS ThisIsReusablePackage
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	Goods.LineNumber
	|TOTALS BY
	|	Ref");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
			
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Template = PrintManagement.PrintFormTemplate("Document.ReceiptOfGoodsToWarehouse.PF_MXL_PurchaseInvoice");
	
	Offset_ = SpreadsheetDocumentShiftType.Vertical;
	WidthOfDeletedColumns = 0;
	If ColumnOfCodes <> "SKU" Then
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("SKU").ColumnWidth;
		Template.DeleteArea(Template.Area("SKU"), Offset_);
	EndIf;
	If ColumnOfCodes<>"Code" Then
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("Code").ColumnWidth;
		Template.DeleteArea(Template.Area("Code"), Offset_);
	EndIf;
	
	If Not PackagingUsage Then
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("PackingQuantity_").ColumnWidth;
		Template.DeleteArea(Template.Area("PackingQuantity_"), Offset_);
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("PackagePresentation").ColumnWidth;
		Template.DeleteArea(Template.Area("PackagePresentation"), Offset_);
	EndIf;
	AreaOfFirstColumnOfGoods = Template.Area("FirstColumnOfGoods");
	AreaOfFirstColumnOfGoods.ColumnWidth = AreaOfFirstColumnOfGoods.ColumnWidth + WidthOfDeletedColumns;
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	// Creating an array to check: which of the documents were not included in the selection
	ValidationArray = New Array;
	For Each Ref In ObjectsArray Do
		ValidationArray.Add(Ref);
	EndDo;
	
	DocumentAttributes = New Structure(
		"Number, Date, Prefix, Presentation, PresentationOfOrder, RepresentationOfTheOrganization, PartnerPresentation_, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentAttributes.Insert("TitleText", NStr("vi = 'Hóa đơn nhập hàng';
												|ru = 'Приходная накладная';
												|en = 'Purchase invoice'; fa = 'فاکتور خرید';
												|it = 'Bolla di acquisto';
												|pl = 'Faktura przyjęcie z zewnątrz';
												|tr = 'Sevk irsaliyesi'", Common.DefaultLanguageCode()));
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		If Not SelectionByDocuments.FindNext(New Structure("Ref", PrintData.Ref)) Then
			Continue;
		EndIf;
		
		ValidationArray.Delete(ValidationArray.Find(PrintData.Ref));
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes, PrintData);
		DocumentAttributes.PresentationOfOrder = TMCommonUseClientServer.GenerateDocumentTitle(
			DocumentAttributes, 
			NStr("vi = 'Tiếp nhận hàng hóa';
				|ru = 'Поступление товаров';
				|en = 'Warehouse receipt'; fa = 'دریافت انبار';
				|it = 'Arrivo delle merci';
				|pl = 'Wpływ towarów';
				|tr = 'İrsaliye'", Common.DefaultLanguageCode()));
		DocumentAttributes.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(
				PrintData.Organization,
				?(PrintData.Patch, PrintData.DateOfDocumentBeingCorrected, PrintData.Date)
			),
			"FullDescr");
		DocumentAttributes.PartnerPresentation_ = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(
				PrintData.Counterparty,
				?(PrintData.Patch, PrintData.DateOfDocumentBeingCorrected, PrintData.Date)
			),
			"FullDescr");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		Area = Template.GetArea("Title");
		Area.Parameters.Fill(DocumentAttributes);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
		SpreadsheetDocument.Put(Area);
		
		Area = Template.GetArea("Header");
		Area.Parameters.Fill(DocumentAttributes);
		HeaderDataStructure_ = New Structure;
		HeaderDataStructure_.Insert("WarehousePresentation_", PrintData.Warehouse);
		Area.Parameters.Fill(HeaderDataStructure_);
		SpreadsheetDocument.Put(Area);
		
		Area = Template.GetArea("Vendor");
		Area.Parameters.Fill(DocumentAttributes);
		SpreadsheetDocument.Put(Area);
		
		Area = Template.GetArea("Customer");
		Area.Parameters.Fill(DocumentAttributes);
		SpreadsheetDocument.Put(Area);
		
		SpreadsheetDocument.Put(Template.GetArea("TableHeader"));
		
		LineCount = 1;
		ProductSelection_1 = SelectionByDocuments.Select();
		While ProductSelection_1.Next() Do
			
			Area = Template.GetArea("TableRow");
			DataStructureLineNumber = New Structure("LineNumber", LineCount);
			Area.Parameters.Fill(DataStructureLineNumber);
			
			LineCount = LineCount + 1;
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.Products,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint);
				
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			Area.Parameters.Fill(ProductDataStructure);
			Area.Parameters.Fill(ProductSelection_1);
			SpreadsheetDocument.Put(Area);
			
		EndDo;
		
		Area = Template.GetArea("TableFooter");
		SpreadsheetDocument.Put(Area);
		
		Area = Template.GetArea("Signatures");
		TextOfResultingLine = NStr("vi = 'Tổng số là %TotalItems_1%';
									|ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
									|it = 'Totale articoli %TotalItems_1%';
									|pl = 'Razem pozycji %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", LineCount-1);
		DataStructureSummaryRow = New Structure;
		DataStructureSummaryRow.Insert("TotalString", TextOfResultingLine);
		Area.Parameters.Fill(DataStructureSummaryRow);
		SpreadsheetDocument.Put(Area);
			
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	For Each Ref In ValidationArray Do
		CommonClientServer.MessageToUser(
			StrReplace(
				NStr("vi = 'Trong chứng từ %Ref% không có hàng hóa. Không cần in phiếu nhập kho.';
					|ru = 'В документе %Ref% отсутствуют товары. Печать приходной накладной не требуется.';
					|en = 'No goods in the %Ref% document. Stamp of the purchase invoice is not required.'; fa = 'No goods in the %Ref% document. Stamp of the purchase invoice is not required.';
					|it = 'Il documento %Ref% non contiene le merci. La stampa della bolla di acquisto non è richiesta.';
					|pl = 'Brak towarów w dokumencie %Ref%. Nie jest potrzebne drukowanie zlecenia przyjęcia towaru.';
					|tr = '%Ref%belgesinde herhangi bir mal bulunmamaktadır. İrsaliye yazdırmaya gerek yoktur.'"),
				"%Ref%",
				Ref
			),
			Ref);
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

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

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled = (CommonQueryParameters.IsFullUser
						Or AccessRight("View", Metadata.Documents.ReceiptOfGoodsToWarehouse))
					And AccessRight("Insert", Metadata.Documents.ReceiptOfGoodsToWarehouse)
					And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive)
					And (GetFunctionalOption("UseGoodsInTransitFromVendors")
						Or GetFunctionalOption("UseUninvoicedDeliveries"));
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT TableOfOrders.DocumentInflow) AS OrdersForRegistrationReceiptOfGoodsInProgress
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			(DocumentInflow REFS Document.PurchaseOrder
	|				OR DocumentInflow REFS Document.VendorInvoice
	|				OR DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors)
	|					AND BusinessOperation IN (&ListOfBusinessTransactions)) AS TableOfOrders
	|WHERE
	|	TableOfOrders.ToRegisterReceiptsByReferenceBalance <> 0
	|	OR TableOfOrders.ToRegisterReceiptsByInvoicesBalance <> 0";
	
	ListOfBusinessTransactions = New ValueList;
	ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
	ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	ListOfBusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	ListOfBusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	ListOfBusinessTransactions.Add(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit);
	
	Query.SetParameter("ListOfBusinessTransactions", ListOfBusinessTransactions);
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Documentsapplication of goods
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "UninvoicedReceiptDocuments";
	UserTaskParent.Presentation  = NStr("vi = 'Chứng từ nhận hàng';
										|ru = 'Документы поступления товаров';
										|en = 'Goods pick-up from customer documents'; fa = 'Goods pick-up from customer documents';
										|it = 'Documenti relativi all''arrivo delle merci';
										|pl = 'Dokumenty odbioru towarów';
										|tr = 'İrsaliye belgeleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	UserTaskParent.HasToDoItems       = Result.OrdersForRegistrationReceiptOfGoodsInProgress > 0;
	
	// Orders of the formalapproachments of goods in the work
	FilterParameters = New Structure;
	FilterParameters.Insert("EconomicOperationOfAcceptance", ListOfBusinessTransactions);
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("CurrentPageName", "ReceiptOrderPage");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OrdersForRegistrationReceiptOfGoodsInProgress";
	ToDoItem.HasToDoItems       = Result.OrdersForRegistrationReceiptOfGoodsInProgress > 0;
	ToDoItem.Presentation  = NStr("vi = 'Lệnh lập chứng từ đang làm việc';
									|ru = 'Распоряжения на оформление в работе';
									|en = 'References for registration in progress'; fa = 'References for registration in progress';
									|it = 'Le disposizioni per la formalizzazione sono in esecuzione';
									|pl = 'Zamówienia rejestracji są w toku wykonywania';
									|tr = 'İş yerinde işleme alınacak siparişler'");
	ToDoItem.Count     = Result.OrdersForRegistrationReceiptOfGoodsInProgress;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "UninvoicedReceiptDocuments";
	
EndProcedure

#EndRegion

#Region Other

Function FullObjectName()
	Return "Document.ReceiptOfGoodsToWarehouse";
EndFunction

// Determines whether the business of operation belongs to the group of operations of receipt of goods in transit.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions
//
// Returns:
//  Boolean
//
Function ThisIsReceiptOfGoodsInTransit(BusinessOperation) Export
	
	OperationGoodsInTransit =
		BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit;
	
	Return OperationGoodsInTransit;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
