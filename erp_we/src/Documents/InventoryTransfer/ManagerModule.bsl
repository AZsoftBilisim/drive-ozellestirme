#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn.DescriptionOfBankingDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, SourceWarehouse, DestinationWarehouse");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "BusinessOperation,Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyRecipient", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "TransferOrder";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, CompanyRecipient";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//                                registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("InternalInventoryTransfers");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	InventoryTransferLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryTransfer") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	ElsIf TypeOf(Document) = Type("DocumentRef.InventoryTransfer") Then
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	Else
		DocumentObject = Undefined;
		DocumentRef = Undefined;
	EndIf;

	Query = New Query;
	QueryTexts	= New ValueList;

	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableTransferOrders(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers, DocumentObject);
		
		InventoryTransferLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;

	ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject);
	ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers);
	ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.InventoryTransfer);
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

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.Date              AS Date,
	|	Header.DestinationWarehouse   AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	Header.DeliveryMethod    AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|		END               AS Address,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|		END               AS FieldValueAddress,
	|
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	Header.AdditionalDeliveryInformation
	|		                    AS AdditionalInformation,
	|	Header.SourceWarehouse  AS Warehouse,
	|	TRUE                  AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	Document.InventoryTransfer AS Header
	|WHERE
	|	Header.Ref IN (&References)
	|	AND (NOT Header.TransferAgainstOrders
	|		OR Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers)";
	
	Return QueryText;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer") Then
		Documents.DiscrepancyReportFollowingTransfer.AddGenerateCommand(GenerationCommands);
	EndIf;
	
	Documents.CustomerInvoiceIntercompany.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Command = Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LockedGoodsTransfer",
			False,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	Command = Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"LockedGoodsTransfer",
			False,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.PackingList.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	
	InventoryTransferLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command creation of the document "Movement of goods".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryTransfer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryTransfer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryTransfer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsTransfer";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Movement of goods".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryTransfer) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.MovementOfGoodsCreateOnBasisOfOrder";
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryTransfer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryTransfer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsTransfer";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "Movement of goods".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnWarehouseGroupCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryTransfer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryTransfer.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateMovementOfGoodsBasedOnGroupOfWarehouses";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryTransfer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsTransfer";
		
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
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	InventoryTransferLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in an array of details that depend on the business operation of the document.
//
// Parameters:
//  BusinessOperation	 - EnumRef.BusinessTransactions	 -
//  ArrayOfAllProps	 - Array									 - Array of all banking details that depend on the business operation
//  ArrayOfOperationDetails - Array									 - Array of names of Bank details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("CompanyRecipient");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
		ArrayOfOperationDetails.Add("CompanyRecipient");
	EndIf;
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "SourceWarehouse,DestinationWarehouse,Status,Date";
	
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
	
	SetPrivilegedMode(True);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.InventoryTransfer";
	
	SerialSenderParameters = WarehousesServer.UseOfSeriesInStock(Object.SourceWarehouse, False);
	RecipientWarehouseSeriesParameters  = WarehousesServer.UseOfSeriesInStock(Object.DestinationWarehouse, False);
	
	UseRecipientOrderScheme  = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(
		Object.DestinationWarehouse,
		Object.Date,
		False);
	
	SetPrivilegedMode(False);
	
	SeriesSpecificationParameters.UseItemsBatch = SerialSenderParameters.UseItemsBatch
														Or (RecipientWarehouseSeriesParameters.UseItemsBatch
														And Not UseRecipientOrderScheme)
														Or RecipientWarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = SerialSenderParameters.UseCostAccountingByBatches
														Or RecipientWarehouseSeriesParameters.UseCostAccountingByBatches;
														
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentByTransfer);
	If Object.Status = Enums.GoodsTransferStatuses.Accepted Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByTransfer);
	EndIf;
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentSender");
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotOfTheSender");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.WarehouseFieldName = "SourceWarehouse";
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotOfTheSender";
	
	SeriesSpecificationParameters.NameOfSenderWarehouseField = "SourceWarehouse";
	SeriesSpecificationParameters.NameOfRecipientWarehouseField  = "DestinationWarehouse";
	
	SeriesSpecificationParameters.ShipmentPlanning = False;
	SeriesSpecificationParameters.SelectionPlanning   = False;
	SeriesSpecificationParameters.FactOfSelection           = Object.Status = Enums.GoodsTransferStatuses.Shipped
	                                             Or Object.Status = Enums.GoodsTransferStatuses.Accepted;
	
	SeriesSpecificationParameters.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SeriesSpecificationParameters);
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusSender");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusRecipient");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_TransferOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_RowCode");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - order for receipt or shipment.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	If FieldValuesToIdentifyReferences.Goods_RowCode Then
		Return FieldValuesToIdentifyReferences.Goods_TransferOrder;
	Else
		Return Undefined;
	EndIf;
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
	|	Goods.AssignmentSender,
	|	Goods.ControlledLotOfTheSender,
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
	|	Goods.AssignmentSender,
	|	Goods.ControlledLotOfTheSender,
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
	|	Goods.AssignmentSender,
	|	Goods.ControlledLotOfTheSender,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.ControlledLotOfTheSender,
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
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.ControlledLotOfTheSender,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.ControlledLotOfTheSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								AND (SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.UseCostAccountingByBatches
	|									OR SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.BatchesAccountingByFEFO
	|									THEN 6
	|								ELSE 8
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.BatchesAccountingByFEFO
	|								THEN 5
	|							ELSE 7
	|						END
	|				END
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyOnShipmentByTransfer
	|				AND &FactOfSelection
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								AND (SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.UseCostAccountingByBatches
	|									OR SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.AccountForRemainingSeries
	|									THEN 4
	|								ELSE 2
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN 3
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusSender,
	|	CASE
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &Date >= DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								AND (SeriesAccountingPoliciesSender.BatchAccountingPolicy.UseCostAccountingByBatches
	|									OR SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.BatchesAccountingByFEFO
	|									THEN 6
	|								ELSE 8
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.BatchesAccountingByFEFO
	|								THEN 5
	|							ELSE 7
	|						END
	|				END
	|		WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.SpecifyOnReceivingByTransfer
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|								AND ProductsToRequest.Count > 0
	|							OR Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								AND (SeriesAccountingPoliciesSender.BatchAccountingPolicy.UseCostAccountingByBatches
	|									OR SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
	|						THEN CASE
	|								WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.AccountForRemainingSeries
	|									THEN 4
	|								ELSE 2
	|							END
	|					ELSE CASE
	|							WHEN SeriesAccountingPoliciesRecipient.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN 3
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	Goods.BatchesIndicationStatusSender AS StatusOfSpecifyingSenderSeriesIsOld,
	|	Goods.BatchesIndicationStatusRecipient AS StatusOfSpecifyingRecipientSeriesIsOld
	|INTO Statuses
	|FROM
	|	ProductsToRequest AS ProductsToRequest
	|		INNER JOIN Goods AS Goods
	|		ON ProductsToRequest.Products = Goods.Products
	|			AND ProductsToRequest.Characteristic = Goods.Characteristic
	|			AND ProductsToRequest.Purpose = Goods.Purpose
	|			AND ProductsToRequest.AssignmentSender = Goods.AssignmentSender
	|			AND ProductsToRequest.ControlledLotOfTheSender = Goods.ControlledLotOfTheSender
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.AssignmentSender = SeriesToRequest.AssignmentSender
	|			AND ProductsToRequest.ControlledLotOfTheSender = SeriesToRequest.ControlledLotOfTheSender
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesSender
	|			INNER JOIN Catalog.Warehouses AS SourceWarehouse
	|			ON (SourceWarehouse.Ref = &SourceWarehouse)
	|				AND (SeriesAccountingPoliciesSender.Warehouse = &SourceWarehouse)
	|		ON ProductsToRequest.ProductKind = SeriesAccountingPoliciesSender.Ref
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesRecipient
	|			INNER JOIN Catalog.Warehouses AS DestinationWarehouse
	|			ON (DestinationWarehouse.Ref = &DestinationWarehouse)
	|				AND (SeriesAccountingPoliciesRecipient.Warehouse = &DestinationWarehouse)
	|		ON ProductsToRequest.ProductKind = SeriesAccountingPoliciesRecipient.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber,
	|	Statuses.BatchesIndicationStatusSender,
	|	CASE
	|		WHEN &ReceivingByTransfer
	|			THEN Statuses.BatchesIndicationStatusRecipient
	|		ELSE 0
	|	END AS BatchesIndicationStatusRecipient,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatusRecipient IN (13, 14, 9, 10)
	|				AND Statuses.BatchesIndicationStatusSender <> 0
	|			THEN Statuses.BatchesIndicationStatusRecipient
	|		WHEN Statuses.BatchesIndicationStatusSender IN (5, 6)
	|			THEN Statuses.BatchesIndicationStatusSender
	|		WHEN Statuses.BatchesIndicationStatusSender > CASE
	|				WHEN &ReceivingByTransfer
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE 0
	|			END
	|			THEN Statuses.BatchesIndicationStatusSender
	|		ELSE CASE
	|				WHEN &ReceivingByTransfer
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	(Statuses.BatchesIndicationStatusSender <> Statuses.StatusOfSpecifyingSenderSeriesIsOld
	|			OR CASE
	|				WHEN &ReceivingByTransfer
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				ELSE 0
	|			END <> Statuses.StatusOfSpecifyingRecipientSeriesIsOld
	|			OR CASE
	|				WHEN Statuses.BatchesIndicationStatusRecipient IN (13, 14, 9, 10)
	|						AND Statuses.BatchesIndicationStatusSender <> 0
	|					THEN Statuses.BatchesIndicationStatusRecipient
	|				WHEN Statuses.BatchesIndicationStatusSender IN (5, 6)
	|					THEN Statuses.BatchesIndicationStatusSender
	|				WHEN Statuses.BatchesIndicationStatusSender > CASE
	|						WHEN &ReceivingByTransfer
	|							THEN Statuses.BatchesIndicationStatusRecipient
	|						ELSE 0
	|					END
	|					THEN Statuses.BatchesIndicationStatusSender
	|				ELSE CASE
	|						WHEN &ReceivingByTransfer
	|							THEN Statuses.BatchesIndicationStatusRecipient
	|						ELSE 0
	|					END
	|			END <> Statuses.StatusOfSpecifyingSeriesIsOld)
	|
	|ORDER BY
	|	Statuses.LineNumber";
	
	Return QueryText;	
EndFunction

// The procedure fills in a series of items for expenditure orders issued based on this document.
//
// Parameters:
//  Object - DocumentObject.InventoryTransfer, FormDataStructure - The document to be filled in.
//
Procedure FillInShippingInstructions(Object) Export
	
	SetPrivilegedMode(True);
	
	UseWarehouseManagemantSystemForGoodsIssue = WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(Object.SourceWarehouse, Object.Date);
	UseWarehouseManagemantSystemForGoodsReceipt = WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.DestinationWarehouse, Object.Date);
	
	SenderSeriesAreUsed = GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", Object.SourceWarehouse));
	RecipientSeriesAreUsed  = GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", Object.DestinationWarehouse));
	
	FillingInSeries = RecipientSeriesAreUsed
		And Not UseWarehouseManagemantSystemForGoodsReceipt
		And SenderSeriesAreUsed
		And UseWarehouseManagemantSystemForGoodsIssue;
		
	If Not FillingInSeries Then
		Return;
	EndIf;
	
	ReferenceArray = Undefined;
	If Object.TransferAgainstOrders Then
		ReferenceArray = Object.Goods.Unload(, "TransferOrder").UnloadColumn("TransferOrder");
	EndIf;
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("ReferenceOrder",         Object.Ref);
	Query.SetParameter("TransferAgainstOrders", Object.TransferAgainstOrders);
	Query.SetParameter("References",         ReferenceArray);
	
	Query.Text =
		"SELECT
		|	ExpenseOrder.Ref AS Ref
		|INTO GoodsIssueNotes
		|FROM
		|	Document.GoodsIssueNote AS ExpenseOrder
		|WHERE
		|	ExpenseOrder.Posted
		|		AND ExpenseOrder.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.GoodsIssueNote.GoodsByReferences AS Goods
		|			WHERE
		|				Goods.Ref = ExpenseOrder.Ref
		|					AND CASE WHEN &TransferAgainstOrders THEN
		|								Goods.ReferenceOrder IN(&References)
		|							ELSE
		|								Goods.ReferenceOrder = &ReferenceOrder
		|						END)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Move.Ref AS Ref
		|INTO Transfers
		|FROM
		|	Document.InventoryTransfer AS Move
		|WHERE
		|	Move.Ref <> &ReferenceOrder
		|		AND Move.Posted
		|		AND TRUE IN(
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.InventoryTransfer.Goods AS Goods
		|			WHERE
		|				Goods.Ref = Move.Ref
		|					AND Goods.TransferOrder IN(&References))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	GoodsIssueNotes AS GoodsIssueNotes
		|		
		|		LEFT JOIN Document.GoodsIssueNote.GoodsByReferences AS Goods
		|		ON Goods.Ref = GoodsIssueNotes.Ref
		|		AND NOT CASE WHEN &TransferAgainstOrders THEN
		|					Goods.ReferenceOrder IN(&References)
		|				ELSE
		|					Goods.ReferenceOrder = &ReferenceOrder
		|			END
		|WHERE
		|	NOT Goods.Ref IS NULL
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	Transfers AS Transfers
		|		
		|		LEFT JOIN Document.InventoryTransfer.Goods AS Goods
		|		ON Goods.Ref = Transfers.Ref
		|		AND NOT Goods.TransferOrder IN(&References)
		|WHERE
		|	NOT Goods.Ref IS NULL";
	
	If Not Query.Execute().IsEmpty() Then
		Return;
	EndIf;
	
	Query.Text =
		"SELECT
		|	Balance.Products          AS Products,
		|	Balance.Characteristic        AS Characteristic,
		|	Balance.AssignmentSender AS AssignmentSender,
		|	Balance.Series                 AS Series,
		|	SUM(Balance.Count)     AS Count
		|FROM(
		|	SELECT
		|		GoodsOfOrder.Products   AS Products,
		|		GoodsOfOrder.Characteristic AS Characteristic,
		|		GoodsOfOrder.Purpose     AS AssignmentSender,
		|		GoodsOfOrder.Series          AS Series,
		|		GoodsOfOrder.Count     AS Count
		|	FROM
		|		GoodsIssueNotes AS GoodsIssueNotes
		|			LEFT JOIN Document.GoodsIssueNote.ShippedGoods AS GoodsOfOrder
		|			ON GoodsOfOrder.Ref  = GoodsIssueNotes.Ref
		|			AND GoodsOfOrder.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
		|			AND GoodsOfOrder.Series   <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	WHERE
		|		NOT GoodsOfOrder.Ref IS NULL
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Goods.Products          AS Products,
		|		Goods.Characteristic        AS Characteristic,
		|		Goods.AssignmentSender AS AssignmentSender,
		|		Goods.Series                 AS Series,
		|		-Goods.Count           AS Count
		|	FROM
		|		Transfers AS Transfers
		|			LEFT JOIN Document.InventoryTransfer.Goods AS Goods
		|			ON Goods.Ref = Transfers.Ref
		|			AND Goods.Series  <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	WHERE
		|		NOT Goods.Ref IS NULL
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SetOfSeries.Products          AS Products,
		|		SetOfSeries.Characteristic        AS Characteristic,
		|		SetOfSeries.AssignmentSender AS AssignmentSender,
		|		SetOfSeries.Series                 AS Series,
		|		-SetOfSeries.Count           AS Count
		|	FROM
		|		Transfers AS Transfers
		|			LEFT JOIN Document.InventoryTransfer.SetOfSeries AS SetOfSeries
		|			ON SetOfSeries.Ref = Transfers.Ref
		|	WHERE
		|		NOT SetOfSeries.Ref IS NULL) AS Balance
		|GROUP BY
		|	Balance.Products,
		|	Balance.Characteristic,
		|	Balance.AssignmentSender,
		|	Balance.Series
		|HAVING
		|	SUM(Balance.Count) <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber           AS LineNumber,
		|	Goods.Products          AS Products,
		|	Goods.Characteristic        AS Characteristic,
		|	Goods.AssignmentSender AS AssignmentSender,
		|	Goods.Purpose            AS Purpose,
		|	Goods.Count            AS Count
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.Count > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber
		|FROM
		|	Goods AS Goods
		|		
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = Goods.Products
		|		
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS RecipientPolicy
		|		ON AllProducts.ProductKind = RecipientPolicy.Ref
		|		AND (RecipientPolicy.BatchAccountingPolicy.UseCostAccountingByBatches
		|			OR RecipientPolicy.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
		|		AND RecipientPolicy.Warehouse = &DestinationWarehouse
		|		
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SenderPolicy
		|		ON AllProducts.ProductKind = SenderPolicy.Ref
		|		AND (SenderPolicy.BatchAccountingPolicy.UseCostAccountingByBatches
		|			OR SenderPolicy.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
		|		AND SenderPolicy.Warehouse = &SourceWarehouse
		|WHERE
		|	NOT RecipientPolicy.Ref IS NULL OR NOT SenderPolicy.Ref IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products          AS Products,
		|	Goods.Characteristic        AS Characteristic,
		|	Goods.AssignmentSender AS AssignmentSender,
		|	Goods.Purpose            AS Purpose,
		|	SUM(Goods.Count)     AS Count
		|FROM
		|	Goods AS Goods
		|		
		|		LEFT JOIN Catalog.Products AS AllProducts
		|		ON AllProducts.Ref = Goods.Products
		|		
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS RecipientPolicy
		|		ON AllProducts.ProductKind = RecipientPolicy.Ref
		|		AND (RecipientPolicy.BatchAccountingPolicy.UseCostAccountingByBatches
		|			OR RecipientPolicy.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
		|		AND RecipientPolicy.Warehouse = &DestinationWarehouse
		|		
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SenderPolicy
		|		ON AllProducts.ProductKind = SenderPolicy.Ref
		|		AND (SenderPolicy.BatchAccountingPolicy.UseCostAccountingByBatches
		|			OR SenderPolicy.BatchAccountingPolicy.SpecifyWhenPlanningShipment)
		|		AND SenderPolicy.Warehouse = &SourceWarehouse
		|WHERE
		|	RecipientPolicy.Ref IS NULL AND SenderPolicy.Ref IS NULL
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.AssignmentSender";
	
	Goods = Object.Goods.Unload(,"LineNumber,Products,Characteristic,Purpose,AssignmentSender,Count");
	Query.SetParameter("Goods",           Goods);
	Query.SetParameter("DestinationWarehouse",  Object.DestinationWarehouse);
	Query.SetParameter("SourceWarehouse", Object.SourceWarehouse);
	
	QueryResult = Query.ExecuteBatch();
	OrderSeriesTable = QueryResult[0].Unload();
	
	SearchFieldsWithoutSeries_ = "Products,Characteristic,AssignmentSender";
	SearchStructureWithoutSeries_ = New Structure(SearchFieldsWithoutSeries_);
	OrderSeriesTable.Indexes.Add(SearchFieldsWithoutSeries_);
	
	SearchFieldsWithSeries = "Products,Characteristic,AssignmentSender,Series";
	SearchStructureWithSeries = New Structure(SearchFieldsWithSeries);
	OrderSeriesTable.Indexes.Add(SearchFieldsWithSeries);
	
	TheStructureOfTheSearch = Undefined;
	
	AddedAndChangedLines = New Array();
	
	SelectingLineNumbersWithWHSeries = QueryResult[2].Select();
	While SelectingLineNumbersWithWHSeries.Next() Do
		StringWithSeriesOfVHFProducts = Object.Goods[SelectingLineNumbersWithWHSeries.LineNumber - 1];
		// Fill in the "Series" column in the "Products" tabular part
		ProductBalance = StringWithSeriesOfVHFProducts.Count;
		BalanceOfOriginalProduct = ProductBalance;
		TheStructureOfTheSearch = ?(ValueIsFilled(StringWithSeriesOfVHFProducts.Series), SearchStructureWithSeries, SearchStructureWithoutSeries_);
		FillPropertyValues(TheStructureOfTheSearch, StringWithSeriesOfVHFProducts);
		ArrayOfRowsAndSeries = OrderSeriesTable.FindRows(TheStructureOfTheSearch);
		If ArrayOfRowsAndSeries.Count() > 0 Then
			FirstRow = True;
			For Each Page1 In ArrayOfRowsAndSeries Do
				If Page1.Count = 0 Then
					Continue;
				EndIf;
				If Not FirstRow Then
					NewRow = Object.Goods.Add();
					FillPropertyValues(NewRow, StringWithSeriesOfVHFProducts);
					StringWithSeriesOfVHFProducts = NewRow;
				EndIf;
				FirstRow = False;
				StringWithSeriesOfVHFProducts.Series = Page1.Series;
				FillingCount = Min(ProductBalance,Page1.Count);
				StringWithSeriesOfVHFProducts.Count = FillingCount;
				AddedAndChangedLines.Add(StringWithSeriesOfVHFProducts);
				Page1.Count  = Page1.Count  - FillingCount;
				ProductBalance = ProductBalance - FillingCount;
				If ProductBalance = 0 Then
					Break;
				EndIf;
			EndDo;
		EndIf;
		If ProductBalance > 0 Then
			If BalanceOfOriginalProduct > ProductBalance Then
				NewRow = Object.Goods.Add();
				FillPropertyValues(NewRow, StringWithSeriesOfVHFProducts);
				StringWithSeriesOfVHFProducts = NewRow;
				StringWithSeriesOfVHFProducts.Count = ProductBalance;
				AddedAndChangedLines.Add(StringWithSeriesOfVHFProducts);
			EndIf;
			StringWithSeriesOfVHFProducts.Series = Undefined;
		EndIf;
	EndDo;
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedAndChangedLines,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	Object.SetOfSeries.Clear();
	// It is necessary to bypass the Goods in order to distribute the series according to the communication fields that are not in the order (Destination).
	TheStructureOfTheSearch = SearchStructureWithoutSeries_;
	SampleProducts_ = QueryResult[3].Select();
	While SampleProducts_.Next() Do
		ProductBalance = SampleProducts_.Count;
		FillPropertyValues(TheStructureOfTheSearch, SampleProducts_);
		ArrayOfRowsAndSeries = OrderSeriesTable.FindRows(TheStructureOfTheSearch);
		For Each TableRow_ In ArrayOfRowsAndSeries Do
			If TableRow_.Count = 0 Then
				Continue;
			EndIf;
			NewLineTSSeries = Object.SetOfSeries.Add();
			FillPropertyValues(NewLineTSSeries,SampleProducts_);
			NewLineTSSeries.Series = TableRow_.Series;
			FillingCount = Min(ProductBalance,TableRow_.Count);
			NewLineTSSeries.Count = FillingCount;
			TableRow_.Count = TableRow_.Count - FillingCount;
			ProductBalance           = ProductBalance           - FillingCount;
			If ProductBalance = 0 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
// 		DocumentsArray - Array - An array of references to documents that should be reviewed
// 		NewStatus - String - Name of the new status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.GoodsTransferStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref                AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status)                  AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                    AS StatusMatches,
	|	DocumentsTable.Posted               AS Posted,
	|	DocumentsTable.DeletionMark        AS DeletionMark,
	|	TRUE                                   AS Recording
	|FROM
	|	Document.InventoryTransfer AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)
	|";
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction// Formationproverciprismenestatus();

// Returns the result of checking when the document status changes
//
// Parameters:
// 		ValidationSample - QueryResultSelection - Current selection string
// 		NewStatus - EnumRef.GoodsTransferStatuses - New status
// 		AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
// 		Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the "Moving of goods" document
	
EndFunction

// Creates a structure for creating product movement for one or more transfer orders
// 		If the header details differ in the submitted orders, an error message is displayed.
//
// Parameters:
//  ReferencesArrray - Array - transfer orders for which you need to enter an invoice
// 	OrderProperties_ - Undefined - a formal parameter for unifying a procedure call from a common mechanism
// 	
// Returns:
// 	Boolean - False if the details of the header differ in the transferred orders.
//
Function InvoiceFillingData(ReferencesArrray, OrderProperties_ = Undefined) Export
	
	Attributes = New Structure("BusinessOperation, Organization, CompanyRecipient, TransferForActivity,
		|SourceWarehouse, DestinationWarehouse, Department, LineOfBusiness, GoodsReceiptOption,
		|DeliveryMethod, CarrierPartner, DeliveryAddress, DeliveryAddressFieldValues, DeliveryAddressOfCarrier,
		|DeliveryAddressOfCarrierFieldValues, DeliveryZone, DeliveryTimeFrom, DeliveryTimeTo, AdditionalDeliveryInformation");
	
	Return Common.ObjectAttributesValues(ReferencesArrray[0], Attributes);
	
EndFunction

// Generates the parameters necessary to verify the entry of the invoice based on orders.
// See GenerationByReferenceTMServerCall.ParametersForOpeningInvoiceFormBasedOnOrder
//
// Parameters:
//  References - Array - list of orders on the basis of which the invoice is issued
//  BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued.
//
// Returns:
//  Structure - data for input verification.
//
Function DataForInputValidationBasedOn(References, BusinessOperation = Undefined) Export
	
	DataToEnter = New Structure("Basis, Status, ThereIsShip, InstructionsForRegistration, CanBeGrouped");
	DataToEnter.ThereIsShip = False;
	DataToEnter.CanBeGrouped = False;
	DataToEnter.Insert("BusinessOperation");
	
	QueriesTexts = New Array;
	QueriesTexts.Add(
		"SELECT
		|	TransferOrder.Ref AS Basis,
		|	TransferOrder.Status AS Status,
		|	TransferOrder.BusinessOperation AS BusinessOperation
		|FROM
		|	Document.TransferOrder AS TransferOrder
		|WHERE
		|	TransferOrder.Ref IN(&References)");
	QueriesTexts.Add(
		"SELECT TOP 1
		|	1
		|FROM
		|	Document.TransferOrder.Goods AS GoodsFromOrder
		|WHERE
		|	GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND GoodsFromOrder.Ref IN(&References)
		|	AND NOT GoodsFromOrder.Canceled");
	QueriesTexts.Add(AccumulationRegisters.TransferOrders.QueryTextBalance("TTBalancesForRegistration"));
	QueriesTexts.Add(
		"SELECT DISTINCT
		|	RequirementsForRegistration_1.TransferOrder AS InstructionsForRegistration
		|FROM
		|	TTBalancesForRegistration AS RequirementsForRegistration_1");
	
	Query = New Query(StrConcat(QueriesTexts, Common.QueryBatchSeparator()));
	Query.SetParameter("References", References);
	Query.SetParameter("Recorder", Undefined);
	Result = Query.ExecuteBatch();
	
	Selection = Result[0].Select();
	If Selection.Count() = 1 And Selection.Next() Then
		DataToEnter.Basis     = Selection.Basis;
		DataToEnter.Status        = Selection.Status;
		DataToEnter.ThereIsShip = Not Result[1].IsEmpty();
		
		DataToEnter.BusinessOperation = Selection.BusinessOperation;
	EndIf;
	
	If Not Result[3].IsEmpty() Then
		DataToEnter.InstructionsForRegistration = Result[3].Unload().UnloadColumn("InstructionsForRegistration");
		DataToEnter.CanBeGrouped = True;
	EndIf;
	
	Return DataToEnter;
	
EndFunction

// Generates parameters for opening the workplace form "Documents for registration".
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - type of operation of the invoice to be issued.
//
// Returns:
//  Structure - parameters for opening a form with fields:
//     * FormName - String - the name of the form RM
//     * FormParameters - Structure - parameters of the RM form.
//
Function ParametersForOpeningWorkplaceForm(BusinessOperation = Undefined) Export
	
	FilterBusinessTransactions = New ValueList;
	If ValueIsFilled(BusinessOperation) Then
		FilterBusinessTransactions.Add(BusinessOperation);
	Else
		FilterBusinessTransactions.Add(Enums.BusinessTransactions.InventoryTransfer);
		FilterBusinessTransactions.Add(Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices);
	EndIf;
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID(Metadata.Documents.InventoryTransfer));
	
	FilterParameters = New Structure;
	FilterParameters.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	FilterParameters.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	OpeningParameters = New Structure("FormName, FormParameters");
	OpeningParameters.FormName = "DataProcessor.LogOfInternalDocuments.Form.InternalDocumentsForRegistration";
	OpeningParameters.FormParameters = New Structure;
	OpeningParameters.FormParameters.Insert("FormAssignmentKey",     "MovementOfGoods_1");
	OpeningParameters.FormParameters.Insert("QuickFilterStructure", FilterParameters);
	
	Return OpeningParameters;
	
EndFunction

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request in the regl. accounting.
//
Function TextOfReflectionInLocalAccounting() Export

	Return InventoryTransferLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return InventoryTransferLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

// Returns the result of a request to fill in an invoice for orders/orders
//
// Parameters:
//  SelectionData_   - Structure - fields that will be used to select order balances for filling in the document
//  CallContext - String - defines the context of the procedure call: "Selection", "Filling In".
//
// Returns:
//  Structure - a structure containing a selection of the query result and additional data to fill in.
//
Function RequestResultForOrderBalances(SelectionData_, CallContext) Export
	
	// Description of all possible request parameters.
	QueryParameters = New Structure("SelectByOrder_, AnArrayOfOrders,
	                                    |Organization, SourceWarehouse, DestinationWarehouse,
	                                    |Recorder, InvoiceGoods");
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", False);
	QueryParameters.Insert("FillInAsNeeded", False);
	
	ListOfRequests   = New ValueList();
	SubqueryNames = New Array();
	
	// Processing of method call parameters.
	If CallContext = "GenerateFrom" Then
		
		RequestParametersToCreateBasedOn(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	ElsIf CallContext = "Pickup" Then
		
		QueryParametersForMatching(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	ElsIf CallContext = "ReFillingByOrders" Then
		
		RequestParametersForOrderReplenishment(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	ElsIf CallContext = "FillingInOrders" Then
		
		RequestParametersToFillInForOrders(QueryParameters, ListOfRequests, SubqueryNames, SelectionData_);
		
	EndIf;
	
	// Description of all possible query texts.
	QueriesTexts = New Map();
	QueriesTexts.Insert("TTOrdersSelection",    QueryTextOfTemporaryOrderTable());
	QueriesTexts.Insert("TTInvoice",      RequestTextForTemporaryInvoiceTable());
	QueriesTexts.Insert("TableShipped", RequestTextShippedByOrders());
	
	// The subqueries used to form the "Form Table" table must be wrapped by the Textquery method(...).
	SubqueryTexts_ = New Map();
	SubqueryTexts_.Insert("BlockRegisterOrders",          RequestTextUpperCaseOrders());
	SubqueryTexts_.Insert("StornoInvoiceBlock",        RequestTextInvoice());
	SubqueryTexts_.Insert("BlockNewRegisteredRecordsInvoice", RequestTextNewTrafficInvoice());
	
	For Each Item In ListOfRequests Do
		Item.Presentation = QueriesTexts[Item.Value];
	EndDo;
	
	Item = ListOfRequests.FindByValue("TableOfContents_");
	If Item <> Undefined Then
		Item.Presentation = MergeRequestText(SubqueryNames, SubqueryTexts_);
	EndIf;
	
	// Request initialization.
	Query = New Query();
	
	For Each Parameter In QueryParameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	For Each Item In ListOfRequests Do
		Query.Text = Query.Text + Item.Presentation;
	EndDo;
	
	// Execution of the request, return of the result.
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	
	ResultStructure1 = New Structure();
	For Each Item In ListOfRequests Do
		ResultStructure1.Insert(Item.Value, QueryResult[ListOfRequests.IndexOf(Item)].Unload());
	EndDo;
	
	Return ResultStructure1;
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//  Structure - contains the following keys:
//     * DisplayShipmentTables     - Number -
//     * DisplayReceiptTables  - Number -
//     * ThisIsAnInvoice                - Boolean -
//     * WarehouseInHeader                 - Boolean -
//     * WarehouseFieldName                - String -
//     * NameOfRecipientWarehouseField      - String -
//     * TextProductServiceShipment    - String -
//     * TextProductServiceReceipt - String -
//     * NameOfInvoiceForOrdersField   - String -
//     * StructureOfAdditionalRequests        - Structure - contains the following keys:
//        ** QueryTextTTGoodsArrival - String -
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("DisplayShipmentTables",    1);
	StructureState.Insert("DisplayReceiptTables", 2);
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("WarehouseInHeader",  True);
	StructureState.Insert("WarehouseFieldName",           "SourceWarehouse");
	StructureState.Insert("NameOfRecipientWarehouseField", "DestinationWarehouse");
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Towar';
															|tr = 'Ürün'"));
	StructureState.Insert("TextProductServiceReceipt", NStr("vi = 'Hàng hóa';
															|ru = 'Товар';
															|en = 'Product'; fa = 'کالا';
															|it = 'Merce';
															|pl = 'Towar';
															|tr = 'Ürün'"));
	StructureState.Insert("NameOfInvoiceForOrdersField", "TransferAgainstOrders");
	
	QueryTextTTGoodsArrival = TemporaryGoodsReceiptTableForProgressStateReport();
	
	StructureOfAdditionalRequests = New Structure();
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsArrival", QueryTextTTGoodsArrival);
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	
	Return StructureState;
	
EndFunction

#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.InventoryTransfer, DocumentRef.InventoryTransfer - Document.
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
		|SourceWarehouse,
		|LineOfBusiness,
		|Organization,
		|CompanyRecipient,
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
	
	If Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
		Attributes.Organization = ObjectAttributes.CompanyRecipient;
	Else
		Attributes.Organization = ObjectAttributes.Organization;
	EndIf;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.Sender = ObjectAttributes.SourceWarehouse;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.InventoryTransfer - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInSenderSControlledLotReference - See QualityControl.New_ActionParameters
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	
	ActionName = "FillInSenderSControlledLotReference";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "TransferOrder";
	ActionParameters.EditableFields = "ControlledLotOfTheSender";
	ActionParameters.QueryOptions.Insert("QualityControlControlledLotReference", Object.ControlledLotOfTheSender);
	ActionParameters.QueryOptions.Insert("QualityControlMovingOnOrders", Object.TransferAgainstOrders);
	ActionParameters.QueryOptions.Insert("QualityControlMovementOfBlockedItems",
		Object.LockedGoodsTransfer);
	ActionParameters.QueryOptions.Insert("QualityControlOrderForMoving", Object.TransferOrder);
	ActionParameters.QueryText =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	CASE
		|		WHEN &QualityControlMovementOfBlockedItems
		|			THEN &QualityControlControlledLotReference
		// The logic of receiving the order from the handler before recording is duplicated.
		|		WHEN &QualityControlMovingOnOrders
		|				AND &QualityControlOrderForMoving <> VALUE(Document.TransferOrder.EmptyRef)
		|				AND Table.TransferOrder = VALUE(Document.TransferOrder.EmptyRef)
		|				AND CAST(&QualityControlOrderForMoving AS Document.TransferOrder).LockedGoodsTransfer
		|			THEN
		|				CAST(&QualityControlOrderForMoving AS Document.TransferOrder).ControlledLotOfTheSender
		// The logic of interactive filling.
		|		WHEN ISNULL(CAST(Table.TransferOrder AS Document.TransferOrder).LockedGoodsTransfer, FALSE)
		|			THEN CAST(Table.TransferOrder AS Document.TransferOrder).ControlledLotOfTheSender
		|		ELSE
		|			VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotOfTheSender
		|FROM
		|	#DataSource AS Table";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.InventoryTransfer";
	ActionParameters.ReadableFields = "Products,ControlledLotOfTheSender";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.DestinationWarehouse);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlControlledLotReference", Object.ControlledLotOfTheSender);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlMovementOfBlockedItems",
		Object.LockedGoodsTransfer);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlMovingOnOrders", Object.TransferAgainstOrders);
	ActionParameters.OverridableProcessingInObjectManager = True;
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
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.InventoryTransfer";
	ActionParameters.ReadableFields = "Products,ControlledLotOfTheSender";
	ActionParameters.EditableFields = "SubjectToUnlocking,QualityConfirmationDate";
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlControlledLotReference", Object.ControlledLotOfTheSender);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlMovementOfBlockedItems",
		Object.LockedGoodsTransfer);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlMovingOnOrders", Object.TransferAgainstOrders);
	ActionParameters.OverridableProcessingInObjectManager = True;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.ControlledLotOfTheSender AS ControlledLotReference,
		|	&QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInMustBeUnblockedDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// The procedure for redefining the processing of the table part for the action "Fill in the quality control data".
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString
//  DataForProcessing - See BatchProcessingOfTablePartServer.DataForStringProcessing
//  ActionParameters - See QualityControl.New_ActionParameters
//  FillInRegular - Boolean - if the Truth is set inside the procedure, then the regular logic will be executed.
Procedure FillInCheckQualityDateOfQualityConfirmation(CurrentRow, DataForProcessing, ActionParameters, FillInRegular) Export
	
	If ValueIsFilled(CurrentRow.ControlledLotOfTheSender) Then
		
		CurrentRow.ToControlQuality = True;
		CurrentRow.QualityConfirmationDate = '00010101'; // is filled in by the action Fill in is waiting for the blocking of the Quality confirmation date.
		FillInRegular = False;
		
	EndIf;
	
EndProcedure

// The procedure for redefining the processing of the table part for the action "Fill in the required blockingthe Quality confirmation data".
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString
//  DataForProcessing - See BatchProcessingOfTablePartServer.DataForStringProcessing
//  ActionParameters - See QualityControl.New_ActionParameters
//  FillInRegular - Boolean - if the Truth is set inside the procedure, then the regular logic will be executed.
Procedure FillInUnblockableDateOfQualityConfirmation(CurrentRow, DataForProcessing, ActionParameters, FillInRegular) Export
	
	FillInRegular = False; // since there is no need to change the controlled Lot reference in the tabular part, it is filled in with the action to fill in the sender's controlled part
	If ValueIsFilled(CurrentRow.ControlledLotOfTheSender) Then
		
		CurrentRow.SubjectToUnlocking = DataForProcessing.SubjectToUnlocking;
		CurrentRow.QualityConfirmationDate = DataForProcessing.QualityConfirmationDate;
		// Controlled Party - we do not fill it out.
		FillInRegular = False;
		
	Else
		
		CurrentRow.SubjectToUnlocking = True;
		// The Quality confirmation dataproof is filled in by the action Fill in the Quality control dataproof.
		// Controlled Party - we do not fill it out.
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillType

// Returns the structure required for further use when filling out the document.
//
// Returns:
//   Structure - structure of document filling parameters.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",         Undefined);
	FillParameters.Insert("FormIsOpen",          False);
	FillParameters.Insert("FillByWarehouseDocument",     Undefined);
	
	FillParameters.Insert("HeaderAttributes",        Undefined);
	
	FillParameters.Insert("DocumentName",          "InventoryTransfer");
	FillParameters.Insert("RegisterNameOrder",      "TransferOrders");
	FillParameters.Insert("FieldNameOrder",          "TransferOrder");
	
	FillParameters.Insert("KeyFields",          "Products, Characteristic, Series, Purpose, AssignmentSender");
	
	Return FillParameters;
	
EndFunction

// Initializes the structure of filling parameters based on header details and orders.
//
// Parameters:
//  FillParameters	 - Structure - The default settings get in the method of Parametrization()
//  HeaderAttributes		 - Structure - Contains the keys that will be used for filling in
//  AnArrayOfOrders		 - Array - Links to orders that will be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	FillParameters.HeaderAttributes	= HeaderAttributes;
	
	If FillParameters.FillByWarehouseDocument = Undefined Then
		FillParameters.FillByWarehouseDocument = InvoicesServer.FillByWarehouseDocument(HeaderAttributes.SourceWarehouse);
	EndIf;
	
EndProcedure

// The procedure fills in the object fields
//
// Parameters:
//  Object				 - DocumentObject.InventoryTransfer - object to fill in
//  FillParameters	 - Structure						 - structure containing keys RequisitePro, Iaregistry, Imabalances
//  AnArrayOfOrders		 - Array							 - an array of transfer orders.
//
Procedure FillInHeaderOfOrderDocument(Object, FillParameters, AnArrayOfOrders) Export
	
	FillPropertyValues(Object, FillParameters.HeaderAttributes);
	
	Object.TransferAgainstOrders = True;
	
	If GetFunctionalOption("UseTransferAgainstSeveralOrders") Then
		SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
	EndIf;
	
	Object.Date = ?(AnArrayOfOrders.Count() = 1,
		OrdersServer.GetMinimumOrderShipmentDate(AnArrayOfOrders, FillParameters.RegisterNameOrder, 
			FillParameters.FieldNameOrder),
		OrdersServer.GetMaximumOrderShipmentDate(AnArrayOfOrders, FillParameters.RegisterNameOrder, 
			FillParameters.FieldNameOrder));
	
	// Filling in the series.
	CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.InventoryTransfer);
	ProductsServer.FillInSeriesByFEFO(Object, SeriesSpecificationParameters, False);
	
	// Filling out the order(s) in the header.
	If AnArrayOfOrders.Count() = 1 Then
		Object.TransferOrder = AnArrayOfOrders[0];
	Else
		OrdersServer.FillInOrderInOrderHeaderInTableSection(Object.TransferOrder, Object.Goods, FillParameters.FieldNameOrder);
	EndIf;
	
EndProcedure

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//  Goods				 - FormDataCollection - Table part " Products"
//  FillParameters	 - Structure -
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Returns the Products table
//
// Parameters:
//  Invoice - DocumentRef.InventoryTransfer - Link to the invoice, the table part of the Goods to be returned.
//
// Returns:
//  ValueTable - The tabular part of the goods movement document.
//
Function TableDataAndDocument(Invoice) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Table.LineNumber                    AS LineNumber,
	|	Table.Products                   AS Products,
	|	Table.Characteristic                 AS Characteristic,
	|	Table.ProductsInSet             AS ProductsInSet,
	|	Table.ItemVariantOfSet           AS ItemVariantOfSet,
	|	Table.Package                       AS Package,
	|	Table.NumberOfPackages             AS NumberOfPackages,
	|	Table.Count                     AS Count,
	|	Table.RowCode                      AS RowCode,
	|	Table.BatchesIndicationStatus            AS BatchesIndicationStatus,
	|	Table.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
	|	Table.BatchesIndicationStatusRecipient  AS BatchesIndicationStatusRecipient,
	|	CASE WHEN Table.Ref.TransferAgainstOrders
	|		THEN Table.TransferOrder
	|		ELSE Table.Ref
	|	END                                  AS TransferOrder,
	|	Table.SalesOpportunity                         AS SalesOpportunity,
	|	Table.Purpose                     AS Purpose,
	|	Table.AssignmentSender          AS AssignmentSender,
	|	Table.Series                          AS Series,
	|	Table.ItemsLocationAttributes     AS ItemsLocationAttributes,
	|	Table.RowID            AS RowID
	|FROM
	|	Document.InventoryTransfer.Goods AS Table
	|WHERE
	|	Table.Ref = &Invoice";
	
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Fills in the passed parameter table for orders and warehouse orders.
//
// Parameters:
//  Goods				 - ValueTable - Table products to fill In
//  Recorder			 - DocumentRef.InventoryTransfer - Link to the current invoice
//  FillParameters	 - Structure - The default parameters are defined in the document parameters () method.
//  PackageBarcodes	 - Undefined, ValueTable - Table of packaging barcodes
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes) Export
	
	// If you do not need to fill in an order, we pass empty query parameters - an empty table will be returned for orders.
	If FillParameters.FillByWarehouseDocument Then
		ReferencesForOrders = FillParameters.AnArrayOfOrders;
		RegistrarForOrders  = Recorder;
	Else
		ReferencesForOrders = Undefined;
		RegistrarForOrders  = Undefined;
	EndIf;
	
	// Orders
	
	RequestTextForOrders = AccumulationRegisters.TransferOrders.QueryTextBalance("TTAccountingData");
	
	QueryTextOrderDocument = Documents.TransferOrder.QueryTextDocumentGoods();
	
	QueryText = RequestTextForOrders
					+ Common.QueryBatchSeparator()
					+ QueryTextOrderDocument;
	
	Query = New Query();
	Query.Text = QueryText;
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder",  Recorder);
	
	OrdersTable = Query.Execute().Unload();
	
	OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";
	
	// Expense orders
	Query = New Query();
	
	TextOfRequestRemainsToIssue = AccumulationRegisters.GoodsForIssue.TextOfRequestRemainsToIssue();
	
	Query.Text = TextOfRequestRemainsToIssue;
	
	Query.SetParameter("References",  ReferencesForOrders);
	Query.SetParameter("Recorder",   RegistrarForOrders);
	
	TableOrders = Query.Execute().Unload();
	
	TableOrders.Columns.Count.Name   = "NoteQuantity";
	TableOrders.Columns.ReferenceOrder.Name = "TransferOrder";
	TableOrders.Columns.AssemblyInProgress.Name   = "NumberInProgress";
	
	TableOrders.Columns.Purpose.Name   = "AssignmentSender";
	
	// Distribution of the resulting tables
	
	Goods.Indexes.Add("TransferOrder, " + FillParameters.KeyFields);
	
	// Adding the number of orders
	Var_Key = "TransferOrder, RowCode, " + FillParameters.KeyFields;
	
	Condition = "On [Count]";
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
	// Adding the number of orders.
	Var_Key = "TransferOrder, " + StrReplace(FillParameters.KeyFields, "Purpose, AssignmentSender", "AssignmentSender");
	
	// There are invoices and orders
	Condition = "[Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are orders, no invoices
	Condition = "NOT [Count], [QuantityInOrder], On [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are invoices, no orders
	Condition = "[Count], NOT [QuantityInOrder]";
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NoteQuantity", Var_Key, Condition, True);
	
	// There are no sender series, there are recipient series
	Condition = "[Count], NOT [BatchesIndicationStatusSender]";
	InvoicesServer.AllocateQuantity(TableOrders.FindRows(New Structure("Series", Catalogs.ItemsBatches.EmptyRef())),
		Goods, "NoteQuantity", StrReplace(Var_Key, "Series,", ""), Condition, False);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(TableOrders, Goods, "NoteQuantity");
	
	// Additional information - how much product is collected
	InvoicesServer.AllocateQuantity(TableOrders, Goods, "NumberInProgress", Var_Key, "", True);
	
	If ReferencesForOrders <> Undefined Then
		InventoryTransferLocalization.FillInBarcodesOfPackages(ReferencesForOrders, Goods, PackageBarcodes);
	EndIf;
	
EndProcedure

// Returns an array containing the transmitted invoice, as well as:
// A. an Order from an array of orders (if there is one element in the array)
// B. All orders that are suitable for selection by Organization,
// 	sender warehouse, and recipient warehouse (if there is more than one element in the array).
//
// Parameters:
//  Invoice		 - DocumentRef.InventoryTransfer -
//  HeaderAttributes	 - Structure - It must contain the Organization, warehouse Sender, and warehouse Recipient keys.
//
// Returns:
//  Array - the array of documents is ordered to be moved.
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	Query = New Query();
	Query.SetParameter("Recorder",             Invoice);
	Query.SetParameter("BusinessOperation",   HeaderAttributes.BusinessOperation);
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("CompanyRecipient",   HeaderAttributes.CompanyRecipient);
	Query.SetParameter("SourceWarehouse",        HeaderAttributes.SourceWarehouse);
	Query.SetParameter("DestinationWarehouse",         HeaderAttributes.DestinationWarehouse);
	
	Query.Text =
		"SELECT
		|	TransferOrder.Ref AS OrderDocument
		|FROM
		|	Document.TransferOrder AS TransferOrder
		|WHERE
		|	TransferOrder.BusinessOperation   = &BusinessOperation
		|	AND TransferOrder.Organization           = &Organization
		|	AND TransferOrder.CompanyRecipient = &CompanyRecipient
		|	AND TransferOrder.SourceWarehouse      = &SourceWarehouse
		|	AND TransferOrder.DestinationWarehouse       = &DestinationWarehouse
		|	AND TransferOrder.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	&Recorder AS OrderDocument";
		
	Return Query.Execute().Unload().UnloadColumn("OrderDocument");
	
EndFunction

// Returns a list of details that can be used to group orders within a single invoice.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function KeyFieldsOfHeader() Export
	
	If GetFunctionalOption("UseTransferAgainstSeveralOrders") Then
		Return "BusinessOperation, Organization, CompanyRecipient, SourceWarehouse, DestinationWarehouse,
			|Department, GoodsReceiptOption";
	Else
		Return "Ref";
	EndIf;
	
EndFunction

#EndRegion

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	If GetFunctionalOption("UseGoodsTransferStatuses") Then
		
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.GoodsTransferStatuses.Shipped);
		TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.GoodsTransferStatuses.Accepted);
		
	EndIf;
	
	Return Table
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ ấn định lĩnh vực hoạt động ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Yalnızca ""%1"" iş kolu atamaları'"));
	
	// Remnants of goods in the sender warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Sender");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.SourceWarehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotOfTheSender";
	DescriptionOfColumns.DataPaths.ToControlQuality = "Object.Goods.ToControlQuality";
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Recipient");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.DestinationWarehouse";
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Goods.Purpose", "AllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
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
	|	AND( ValueAllowed(SourceWarehouse)
	|	OR ValueAllowed(DestinationWarehouse)
	|	) ";

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

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array of See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Array;
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.WarehouseFieldName			= "DestinationWarehouse";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.WarehouseFieldName = "SourceWarehouse";
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.InventoryTransfer, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return DocumentObject.BusinessOperation = Enums.BusinessTransactions.InventoryTransfer;
	
EndFunction

#EndRegion
#Region InterfaceImplementation

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

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.Text =
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.CorCompany AS CorCompany,
		|	DocumentData.SourceWarehouse AS SourceWarehouse,
		|	DocumentData.DestinationWarehouse AS DestinationWarehouse,
		|	DocumentData.RecipientSShopPantry AS RecipientSShopPantry,
		|	PRESENTATION(DocumentData.SourceWarehouse) AS SourceWarehousePresentation,
		|	PRESENTATION(DocumentData.DestinationWarehouse) AS DestinationWarehousePresentation,
		|	DocumentData.TransferOrder AS TransferOrder,
		|	DocumentData.TransferAgainstOrders AS TransferAgainstOrders,
		|	DocumentData.Date AS ReferenceDate,
		|	DocumentData.DateOfReceipt AS DateOfReceipt,
		|	DocumentData.Status AS Status,
		|	DocumentData.TransferForActivity AS TransferForActivity,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.EmployeeResponsible AS Manager,
		|	DocumentData.SalesOpportunity AS SalesOpportunity,
		|	DocumentData.EnabledGoodsAssignmentInSalesOpportunity AS EnabledGoodsAssignmentInSalesOpportunity,
		|	DocumentData.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment,
		|	DocumentData.AdvancedWarehousingOnGoodsReceipt AS AdvancedWarehousingOnGoodsReceipt,
		|	DocumentData.CompanyRecipient AS CompanyRecipient,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Author AS Author,
		|	DocumentData.Comment AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
		|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	DocumentDataHeader AS DocumentData";

	Result = Query.Execute();

	ParametersStructure = TMCommonUse.FirstLineOfQueryResultInStructure(Result);
	TMCommonUse.SetRequestParameters(Query, ParametersStructure);

	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(ParametersStructure.GoodsReceiptOption);

	Query.SetParameter("ByTransferOrder",            ParametersStructure.TransferAgainstOrders);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	EmptyOrderValue = New Array;
	EmptyOrderValue.Add(Undefined);
	EmptyOrderValue.Add(Documents.TransferOrder.EmptyRef());
	Query.SetParameter("EmptyOrderValue",             EmptyOrderValue);
	Query.SetParameter("NumberForPrinting",                    ObjectsPrefixesClientServer.NumberForPrinting(ParametersStructure.Number));
	Query.SetParameter("MetadataIdentifier",          Common.MetadataObjectID("Document.InventoryTransfer"));
	Query.SetParameter("InvoiceIsOrder",   InvoiceIsOrder);
	
	WarehouseInformationToSender = "";
	If ValueIsFilled(ParametersStructure.SourceWarehouse) Then
		StringPattern = "vi = 'Điều chuyển từ ""%1""';
						|ru = 'Перемещение с ""%1""';
						|en = 'Transfer from ""%1""';
						|it = 'Trasferimento da ""%1""';
						|pl = 'Przenoszenie z ""%1""';
						|tr = '""%1''dan"" transfer'"; // @NStr
		WarehouseInformationToSender = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, ParametersStructure.SourceWarehousePresentation);
	EndIf;
	Query.SetParameter("WarehouseInformationToSender", WarehouseInformationToSender);
	WarehouseInformationRecipient = "";
	If ValueIsFilled(ParametersStructure.DestinationWarehouse) Then
		StringPattern = "vi = 'Điều chuyển đến ""%1""';
						|ru = 'Перемещение на ""%1""';
						|en = 'Transfer to ""%1""';
						|it = 'Trasferimento a ""%1""';
						|pl = 'Przenoszenie do ""%1""';
						|tr = '""%1''na"" transfer'"; // @NStr
		WarehouseInformationRecipient = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, ParametersStructure.DestinationWarehousePresentation);
	EndIf;
	Query.SetParameter("WarehouseInformationRecipient", WarehouseInformationRecipient);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, ParametersStructure);
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager();

	If DocumentRef = Undefined Then
		Return;
	EndIf;

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataBatchTable(ListOfRequests);
	QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();

EndProcedure

// To create shared temporary tables in document update handlers.
// Parameters:
//  ListOfRequests - Array of String
Procedure QueryTextDocumentData(ListOfRequests) Export
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataBatchTable(ListOfRequests);
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = 
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Number AS Number,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	Departments.OptionOfAssignedAccountingOfGoods AS SubdivisionIsVariantOfSeparateAccountingOfItems,
		|	ISNULL(Departments.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
		|			THEN DocumentData.CompanyRecipient
		|		ELSE UNDEFINED
		|	END AS CorCompany,
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
		|			THEN DocumentData.CompanyRecipient
		|		ELSE DocumentData.Organization
		|	END AS CompanyRecipient,
		|	DocumentData.SourceWarehouse AS SourceWarehouse,
		|	DocumentData.DestinationWarehouse AS DestinationWarehouse,
		|	DocumentData.LockedGoodsTransfer AS LockedGoodsTransfer,
		|	RecipientWarehouses.ShopFloorStockroom AS RecipientSShopPantry,
		|	RecipientWarehouses.UseWarehouseManagemantSystemForGoodsReceipt AS WarehouseRecipientUseOrderSchemeWhenReceiving,
		|	RecipientWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS WarehouseRecipientDateOfStartOfOrderSchemeUponReceipt,
		|	WarehousesSenders.UseWarehouseManagemantSystemForGoodsIssue AS WarehouseSenderUseOrderSchemeWhenShipping,
		|	WarehousesSenders.StartDateOfWarehouseManagemantSystemForGoodsIssue AS WarehouseSenderDateOfStartOfOrderSchemeDuringShipment,
		|	WarehousesSenders.UseWarehouseManagemantSystemForGoodsIssue
		|		AND DocumentData.Date >= WarehousesSenders.StartDateOfWarehouseManagemantSystemForGoodsIssue AS AdvancedWarehousingOnShipment,
		|	RecipientWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND DocumentData.Date >= RecipientWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS AdvancedWarehousingOnGoodsReceipt,
		|	DocumentData.TransferOrder AS TransferOrder,
		|	DocumentData.TransferAgainstOrders AS TransferAgainstOrders,
		|	DocumentData.Date AS ReferenceDate,
		|	DocumentData.Status AS Status,
		|	DocumentData.TransferForActivity AS TransferForActivity,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.EmployeeResponsible AS Manager,
		|	DocumentData.SalesOpportunity AS SalesOpportunity,
		|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Author AS Author,
		|	DocumentData.Comment AS Comment,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	DocumentData.DateOfReceipt AS DateOfReceipt,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
		|INTO DocumentDataHeader
		|FROM
		|	Document.InventoryTransfer AS DocumentData
		|		LEFT JOIN Catalog.BusinessStructure AS Departments
		|		ON DocumentData.Department = Departments.Ref
		|		LEFT JOIN Catalog.Warehouses AS RecipientWarehouses
		|		ON DocumentData.DestinationWarehouse = RecipientWarehouses.Ref
		|		LEFT JOIN Catalog.Warehouses AS WarehousesSenders
		|		ON DocumentData.SourceWarehouse = WarehousesSenders.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref IN(&Ref)
		|
		|INDEX BY
		|	DocumentData.Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods =
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.BatchesIndicationStatusSender AS BatchesIndicationStatusSender,
		|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.TransferOrder AS TransferOrder,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Purpose,
		|	GoodsTable.AssignmentSender AS AssignmentSender,
		|	GoodsTable.ToControlQuality AS ToControlQuality,
		|	GoodsTable.SubjectToUnlocking AS SubjectToUnlocking,
		|	GoodsTable.QualityConfirmationDate AS QualityConfirmationDate,
		|	GoodsTable.ControlledLotOfTheSender AS ControlledLotOfTheSender,
		|	GoodsTable.ControlledLotReference AS ControlledLotReference,
		|	Assignments.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
		|	SenderSDestination.LineOfBusiness AS SenderSPurposeLineOfBusiness,
		|	SenderSDestination.RecordsInWarehouseRegisters AS DestinationOfSenderOfRegisteredRecordsOfWarehouseRegisters
		|INTO DocumentDataTableItems
		|FROM
		|	Document.InventoryTransfer.Goods AS GoodsTable
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
		|		ON (Packages.Ref = GoodsTable.Package)
		|		LEFT JOIN Catalog.Assignments AS SenderSDestination
		|		ON (SenderSDestination.Ref = GoodsTable.AssignmentSender)
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON (Assignments.Ref = GoodsTable.Purpose)
		|WHERE
		|	GoodsTable.Ref IN (&Ref)
		|
		|INDEX BY
		|	Ref";

	ListOfRequests.Add(QueryTextTableGoods);

EndProcedure

Procedure QueryTextDocumentDataBatchTable(ListOfRequests)

	QueryTextTableSetOfSeries =
		"SELECT
		|	SeriesTable.Ref AS Ref,
		|	SeriesTable.Products AS Products,
		|	SeriesTable.Characteristic AS Characteristic,
		|	SeriesTable.AssignmentSender AS AssignmentSender,
		|	Assignments.RecordsInWarehouseRegisters AS DestinationOfSenderOfRegisteredRecordsOfWarehouseRegisters,
		|	SeriesTable.Series AS Series,
		|	SeriesTable.Count AS Count
		|INTO DocumentDataBatchTable
		|FROM
		|	Document.InventoryTransfer.SetOfSeries AS SeriesTable
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON Assignments.Ref = SeriesTable.AssignmentSender
		|WHERE
		|	SeriesTable.Ref IN (&Ref)
		|
		|INDEX BY
		|	SeriesTable.Ref";

	ListOfRequests.Add(QueryTextTableSetOfSeries);

EndProcedure

Procedure QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests)

	QueryTextTableInventoryKinds =
		"SELECT
		|	TableTypesOfStocks_.Ref AS Ref,
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
		|	TableTypesOfStocks_.Count AS Count,
		|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
		|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
		|	TableTypesOfStocks_.Purpose AS Purpose,
		|	Assignments.VATActivityType AS PurposeOfVATSTaxationOfTypeOfActivity,
		|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
		|	TableTypesOfStocks_.RowID AS RowID,
		|	TableTypesOfStocks_.Series AS Series
		|INTO DocumentDataTableOfInventoryOwnerAttributes
		|FROM
		|	Document.InventoryTransfer.InventoryKinds AS TableTypesOfStocks_
		|		LEFT JOIN Catalog.Assignments AS Assignments
		|		ON (Assignments.Ref = TableTypesOfStocks_.Purpose)
		|WHERE
		|	TableTypesOfStocks_.Ref = &Ref
		|
		|INDEX BY
		|	TableTypesOfStocks_.Ref";

	ListOfRequests.Add(QueryTextTableInventoryKinds);

EndProcedure

Procedure InitializeProductAnalysisKeys(Query)

	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("DestinationWarehouse",        Query.Parameters.DestinationWarehouse);
	QueryAnalyst.SetParameter("Status",                 Query.Parameters.Status);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Table.Products        AS Products,
	|	Table.Characteristic      AS Characteristic,
	|	Table.Series      AS Series,
	|	Table.Purpose AS Purpose,
	|	Table.Warehouse              AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products        AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic      AS Characteristic,
	|		TableTypesOfStocks_.Series      AS Series,
	|		TableTypesOfStocks_.Purpose AS Purpose,
	|		&DestinationWarehouse              AS Warehouse
	|	FROM
	|		Document.InventoryTransfer.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Keys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products      = Keys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic  = Keys.Characteristic
	|		AND TableTypesOfStocks_.Series  = Keys.Series
	|		AND TableTypesOfStocks_.Purpose  = Keys.Purpose
	|		AND &DestinationWarehouse          = Keys.StorageLocation
	| 		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products        AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic      AS Characteristic,
	|		TableTypesOfStocks_.Series      AS Series,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		&DestinationWarehouse              AS Warehouse
	|	FROM
	|		Document.InventoryTransfer.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Keys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products      = Keys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic  = Keys.Characteristic
	|		AND TableTypesOfStocks_.Series  = Keys.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef)  = Keys.Purpose
	|		AND &DestinationWarehouse          = Keys.StorageLocation
	| 		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products        AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic      AS Characteristic,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Series               AS Series,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation               AS Warehouse
	|	FROM
	|		Document.InventoryTransfer.InventoryKinds AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Keys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products      = Keys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic  = Keys.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series  = Keys.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef)  = Keys.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = Keys.StorageLocation
	| 		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products   AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|		VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS Warehouse
	|	FROM
	|		Document.InventoryTransfer.InventoryKinds AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Keys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products      = Keys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic  = Keys.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = Keys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = Keys.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = Keys.StorageLocation
	| 		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Keys.ProductCostElement
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND TableTypesOfStocks_.RecipientInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	) AS Table
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Keys
	|	ON Table.Products = Keys.Products
	|		AND Table.Characteristic  = Keys.Characteristic
	|		AND Table.Series  = Keys.Series
	|		AND Table.Purpose = Keys.Purpose
	|		AND Table.Warehouse = Keys.StorageLocation
	|WHERE
	|	Keys.Products IS NULL
	|";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	InventoryLocationAttributeKeys.Products AS Products,
	|	InventoryLocationAttributeKeys.Characteristic AS Characteristic,
	|	WarehouseTerritories.ShopFloorStockroom AS SenderSShopPantry,
	|	HeaderData_.RecipientSShopPantry AS RecipientSShopPantry,
	|	InventoryLocationAttributeKeys.Ref AS SenderProductAnalysis,
	|	Assignments.LineOfBusiness AS LineOfBusinessSender,
	|	AnalyticsWithoutAssignment.DimensionKey AS ProductAnalysisSenderWithoutDestination,
	|	RecipientProductAnalysis.DimensionKey AS RecipientProductAnalysis,
	|	Assignments.LineOfBusiness AS LineOfBusinessRecipient,
	|	AnalyticsRecipientWithoutAssignment.DimensionKey AS ProductAnalysisRecipientWithoutAssignment,
	|	CommitteeAnalytics.DimensionKey AS CommitteeAccountingAnalytics,
	|	CASE
	|		WHEN ISNULL(TableTypesOfStocks_.PurposeOfVATSTaxationOfTypeOfActivity, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN TableTypesOfStocks_.PurposeOfVATSTaxationOfTypeOfActivity
	|		ELSE HeaderData_.TransferForActivity
	|	END AS VATActivityType,
	|	InventoryKinds.Ref AS InventoryOwnerAttribute,
	|	InventoryKinds.Currency AS Currency,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS InventoryOwnerAttributeGoodsReceipt,
	|	TypesOfStocksOfRecipient.InventoryType AS InventoryTypeRegistration,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	AnalysisOfCalculations.DimensionKey AS AnalysisOfSettlementsWithCommittee,
	|	TableTypesOfStocks_.RowID AS RowID
	|INTO TTTypesOfStocks
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS TableTypesOfStocks_
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|			LEFT JOIN Catalog.Assignments AS Assignments
	|			ON Assignments.Ref = InventoryLocationAttributeKeys.Purpose
	|			LEFT JOIN Catalog.Warehouses AS WarehouseTerritories
	|			ON WarehouseTerritories.Ref = InventoryLocationAttributeKeys.WarehouseArea
	|		ON (InventoryLocationAttributeKeys.Ref = TableTypesOfStocks_.ItemsLocationAttributes)
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON (InventoryKinds.Ref = TableTypesOfStocks_.InventoryOwnerAttribute)
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksOfRecipient
	|		ON (TypesOfStocksOfRecipient.Ref = TableTypesOfStocks_.RecipientInventoryOwnerAttribute)
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.CHARACTERISTIC = AnalyticsWithoutAssignment.Characteristic
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS RecipientProductAnalysis
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = RecipientProductAnalysis.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.CHARACTERISTIC = RecipientProductAnalysis.Characteristic
	|			AND TableTypesOfStocks_.Purpose = RecipientProductAnalysis.Purpose
	|			AND TableTypesOfStocks_.Series = RecipientProductAnalysis.Series
	|			AND (&DestinationWarehouse = RecipientProductAnalysis.StorageLocation)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = RecipientProductAnalysis.ProductCostElement)
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsRecipientWithoutAssignment
	|		ON (RecipientProductAnalysis.Products = AnalyticsRecipientWithoutAssignment.Products)
	|			AND (RecipientProductAnalysis.Characteristic = AnalyticsRecipientWithoutAssignment.Characteristic)
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsRecipientWithoutAssignment.Purpose)
	|			AND (RecipientProductAnalysis.Series = AnalyticsRecipientWithoutAssignment.Series)
	|			AND (RecipientProductAnalysis.StorageLocation = AnalyticsRecipientWithoutAssignment.StorageLocation)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsRecipientWithoutAssignment.ProductCostElement)
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON (AnalysisOfCalculations.Organization = &Organization)
	|			AND (AnalysisOfCalculations.Partner = TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner)
	|			AND (AnalysisOfCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty)
	|			AND (AnalysisOfCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract)
	|			AND (AnalysisOfCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeAnalytics.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.CHARACTERISTIC = CommitteeAnalytics.Characteristic
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose)
	|			AND (VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series)
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeAnalytics.StorageLocation
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement)
	|
	|WHERE
	|	TableTypesOfStocks_.Ref IN(&Ref)";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
EndProcedure

Function QueryTextTableTransferOrders(Query, QueryTexts, Registers)

	RegisterName = "TransferOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	GoodsTable.Ref.Date AS Period,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatusSender IN (10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.TransferOrder AS TransferOrder,
		|	GoodsTable.Count AS Ordered,
		|	GoodsTable.Count AS ToRegister
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN (&Ref)
		|	AND GoodsTable.RowCode <> 0
		|	AND &ByTransferOrder
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber,
		|	VALUE(AccumulationRecordType.Receipt),
		|	GoodsTable.Ref.Date,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatusSender IN (10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END,
		|	GoodsTable.RowCode,
		|	GoodsTable.TransferOrder,
		|	0,
		|	GoodsTable.Count
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN (&Ref)
		|	AND GoodsTable.RowCode = 0
		|	AND &ByTransferOrder
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber,
		|	VALUE(AccumulationRecordType.Expense),
		|	GoodsTable.Ref.Date,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	CASE
		|		WHEN GoodsTable.BatchesIndicationStatusSender IN (10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END,
		|	GoodsTable.RowCode,
		|	GoodsTable.TransferOrder,
		|	0,
		|	GoodsTable.Count
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN (&Ref)
		|	AND GoodsTable.RowCode = 0
		|	AND &ByTransferOrder";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Procedure ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.TransferOrder AS OrderDocument,
	|	CASE
	|		WHEN GoodsTable.Ref.Patch
	|			THEN GoodsTable.Ref.CorrectedDocument
	|		ELSE GoodsTable.Ref
	|	END AS Invoice,
	|	HeaderData_.Patch AS Patch,
	|	HeaderData_.CorrectedDocument AS CorrectedDocument,
	|	HeaderData_.Date AS Date,
	|	HeaderData_.Date AS DateOfPlannedReceipt,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED AS Terms,
	|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
	|	HeaderData_.DestinationWarehouse AS Warehouse,
	|	HeaderData_.SourceWarehouse AS Sender,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.ToControlQuality AS ToControlQuality,
	|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
	|	HeaderData_.TransferAgainstOrders
	|		AND GoodsTable.RowCode = 0 AS ExceedingOrder,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS Count,
	|	HeaderData_.TransferAgainstOrders AS ReceiptUnderOrders,
	|	TRUE AS ThisIsAnInvoice
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON (HeaderData_.Ref = GoodsTable.Ref)";
	
	WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_);
		
EndProcedure

Procedure ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject <> Undefined
		And DocumentObject.Status <> Enums.GoodsTransferStatuses.Accepted Then
		Return;
	EndIf;

	QueryTextDocument_ =
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.TransferOrder AS OrderDocument,
		|	CASE
		|		WHEN HeaderData_.Patch
		|			THEN HeaderData_.CorrectedDocument
		|		ELSE GoodsTable.Ref
		|	END AS Invoice,
		|	HeaderData_.Date AS Date,
		|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
		|	UNDEFINED AS Terms,
		|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
		|	HeaderData_.DestinationWarehouse AS Warehouse,
		|	HeaderData_.SourceWarehouse AS Sender,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.ToControlQuality AS ToControlQuality,
		|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
		|	GoodsTable.ControlledLotReference AS ControlledLotReference,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatusInWarehouses,
		|	GoodsTable.BatchesIndicationStatusSender AS BatchesIndicationStatusGoodsAtPartners,
		|	HeaderData_.TransferAgainstOrders
		|		AND GoodsTable.RowCode = 0 AS ExceedingOrder,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Count AS Count,
		|	HeaderData_.TransferAgainstOrders AS ReceiptUnderOrders,
		|	TRUE AS ThisIsAnInvoice
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = GoodsTable.Ref)
		|WHERE
		|	HeaderData_.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)";

	CurrentMetadataObject1 = Metadata.Documents.InventoryTransfer;
	
	WarehousesServer.ToIssueReceiptOfGoodsOnDvukhodovka(
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
		|	GoodsTable.Ref AS Ref,
		|	CASE
		|		WHEN GoodsTable.Ref.Patch
		|			THEN GoodsTable.Ref.CorrectedDocument
		|		ELSE GoodsTable.Ref
		|	END AS Invoice,
		|	HeaderData_.Patch AS Patch,
		|	HeaderData_.CorrectedDocument AS CorrectedDocument,
		|	GoodsTable.TransferOrder AS OrderDocument,
		|	CASE
		|		WHEN HeaderData_.DateOfReceipt <> DATETIME(1, 1, 1)
		|			THEN HeaderData_.DateOfReceipt
		|		ELSE HeaderData_.Date
		|	END AS Date,
		|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
		|	UNDEFINED AS Terms,
		|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
		|	HeaderData_.DestinationWarehouse AS Warehouse,
		|	HeaderData_.SourceWarehouse AS Sender,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.ToControlQuality AS ToControlQuality,
		|	GoodsTable.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef) AS RecordOfAPreviouslyReceivedLot,
		|	GoodsTable.ControlledLotReference AS ControlledLotReference,
		|	GoodsTable.BatchesIndicationStatusRecipient AS BatchesIndicationStatus,
		|	HeaderData_.TransferAgainstOrders
		|		AND GoodsTable.RowCode = 0 AS ExceedingOrder,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Count AS Count,
		|	HeaderData_.TransferAgainstOrders AS ReceiptUnderOrders,
		|	TRUE AS ThisIsAnInvoice
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = GoodsTable.Ref)";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_, "GoodsTable");
	
EndProcedure

Procedure QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
		"SELECT
		|	SeriesTable.Products AS Products,
		|	SeriesTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN SeriesTable.AssignmentSender <> VALUE(Catalog.Assignments.EmptyRef)
		|				AND SeriesTable.DestinationOfSenderOfRegisteredRecordsOfWarehouseRegisters
		|			THEN SeriesTable.AssignmentSender
		|	END AS Purpose,
		|	SeriesTable.Series AS Series,
		|	SeriesTable.Count AS Count,
		|	HeaderData_.SourceWarehouse AS Sender,
		|	HeaderData_.DestinationWarehouse AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ShipmentByTransfer) AS WarehouseOperation,
		|	SeriesTable.Ref AS Document,
		|	HeaderData_.Date AS Period,
		|	NOT(HeaderData_.AdvancedWarehousingOnShipment
		|			OR HeaderData_.AdvancedWarehousingOnGoodsReceipt) AS ThisIsWarehouseRecord
		|FROM
		|	DocumentDataBatchTable AS SeriesTable
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = SeriesTable.Ref)
		|WHERE
		|	SeriesTable.Ref IN(&Ref)
		|	AND SeriesTable.Count <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	SeriesTable.Products,
		|	SeriesTable.Characteristic,
		|	CASE
		|		WHEN SeriesTable.AssignmentSender <> VALUE(Catalog.Assignments.EmptyRef)
		|				AND SeriesTable.DestinationOfSenderOfRegisteredRecordsOfWarehouseRegisters
		|			THEN SeriesTable.AssignmentSender
		|	END,
		|	SeriesTable.Series,
		|	SeriesTable.Count,
		|	HeaderData_.SourceWarehouse,
		|	HeaderData_.DestinationWarehouse,
		|	VALUE(Enum.WarehouseTransactions.ShipmentByTransfer),
		|	SeriesTable.Ref,
		|	HeaderData_.Date,
		|	NOT(HeaderData_.AdvancedWarehousingOnShipment
		|			OR HeaderData_.AdvancedWarehousingOnGoodsReceipt)
		|FROM
		|	DocumentDataTableItems AS SeriesTable
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = SeriesTable.Ref)
		|WHERE
		|	SeriesTable.Ref IN(&Ref)
		|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";

	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	PartsOfQueryText = New Array;
	TextOfRequestPart = 
		"SELECT
		|	1 AS Order,
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	HeaderData_.Date AS Period,
		|	CASE
		|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
		|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
		|		ELSE HeaderData_.Organization
		|	END AS Organization,
		|	HeaderData_.Organization AS ShipmentCompany,
		|	TableTypesOfStocks_.SenderProductAnalysis AS ItemsLocationAttributes,
		|	TableTypesOfStocks_.Products AS Products,
		|	TableTypesOfStocks_.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory
		|			THEN TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
		|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
		|	END AS InventoryOwnerAttribute,
		|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
		|	TableTypesOfStocks_.Count AS Count,
		|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	TableTypesOfStocks_.VATActivityType AS VATTaxation,
		|	TableTypesOfStocks_.RecipientProductAnalysis AS CorItemsLocationAttributes,
		|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS CorInventoryOwnerAttribute
		|FROM
		|	TTTypesOfStocks AS TableTypesOfStocks_
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)";
	PartsOfQueryText.Add(TextOfRequestPart);

	If DocumentObject = Undefined
		Or DocumentObject.Status = Enums.GoodsTransferStatuses.Accepted Then
		TextOfRequestPart =
			"SELECT
			|	2,
			|	TableTypesOfStocks_.LineNumber,
			|	VALUE(AccumulationRecordType.Receipt),
			|	HeaderData_.Date,
			|	HeaderData_.CompanyRecipient,
			|	HeaderData_.Organization,
			|	TableTypesOfStocks_.RecipientProductAnalysis,
			|	TableTypesOfStocks_.Products,
			|	TableTypesOfStocks_.Characteristic,
			|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt,
			|	TableTypesOfStocks_.CCDNumber,
			|	TableTypesOfStocks_.Count,
			|	TableTypesOfStocks_.QuantityByGBRN,
			|	HeaderData_.BusinessOperation,
			|	UNDEFINED,
			|	UNDEFINED,
			|	TableTypesOfStocks_.InventoryOwnerAttribute
			|FROM
			|	TTTypesOfStocks AS TableTypesOfStocks_
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)
			|WHERE
			|	TableTypesOfStocks_.Ref.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)
			|
			|ORDER BY
			|	Order,
			|	LineNumber";
		PartsOfQueryText.Add(TextOfRequestPart);
	EndIf;

	QueryText = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)

	RegisterName = "CompanyGoodsForTransfer";

	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;

	QueryText =
		"SELECT
		|	Inventories.LineNumber AS LineNumber,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	HeaderData_.Date AS Period,
		|	Inventories.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
		|	Inventories.SenderProductAnalysis AS ItemsLocationAttributes,
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
		|	Inventories.CCDNumber AS CCDNumber,
		|	Inventories.Count AS Count
		|FROM
		|	TTTypesOfStocks AS Inventories
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON (HeaderData_.Ref = Inventories.Ref)
		|WHERE
		|	Inventories.SaleOfAnotherCompanyInventory
		|
		|ORDER BY
		|	LineNumber";

	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

Procedure QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers, DocumentObject)

	If DocumentObject <> Undefined
		And DocumentObject.Status <> Enums.GoodsTransferStatuses.Accepted Then
		Return;
	EndIf;

	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	PartsOfQueryText = New Array;
	TextOfRequestPart = 
	"SELECT
	|	HeaderData_.Date AS Period,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Department AS Department,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.SenderProductAnalysis
	|		ELSE TableTypesOfStocks_.ProductAnalysisSenderWithoutDestination
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusinessSender AS LineOfBusiness,
	|	HeaderData_.SourceWarehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.RecipientProductAnalysis
	|		ELSE TableTypesOfStocks_.ProductAnalysisRecipientWithoutAssignment
	|	END AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusinessRecipient AS CorLineOfBusiness,
	|	HeaderData_.DestinationWarehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt.InventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN 0
	|		ELSE TableTypesOfStocks_.Count
	|	END AS CorQuantity,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	HeaderData_.Ref AS DocumentRegisterRecords,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt
	|		ELSE TableTypesOfStocks_.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup,
	|	HeaderData_.CorCompany AS CorCompany
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)
	|WHERE
	|	HeaderData_.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)";

	PartsOfQueryText.Add(TextOfRequestPart);

	If DocumentObject = Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then

		TextOfRequestPart =
			"SELECT
			|	HeaderData_.Date,
			|	VALUE(Enum.BusinessTransactions.InternalGoodsReceipt),
			|	HeaderData_.CorCompany,
			|	HeaderData_.Department,
			|
			|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
			|		THEN TableTypesOfStocks_.SenderProductAnalysis
			|		ELSE TableTypesOfStocks_.ProductAnalysisSenderWithoutDestination
			|	END AS ItemsLocationAttributes,
			|	TableTypesOfStocks_.LineOfBusinessSender AS LineOfBusiness,
			|	HeaderData_.SourceWarehouse,
			|	TableTypesOfStocks_.InventoryType,
			|	TableTypesOfStocks_.InventoryOwnerAttribute,
			|
			|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
			|		THEN TableTypesOfStocks_.RecipientProductAnalysis
			|		ELSE TableTypesOfStocks_.ProductAnalysisRecipientWithoutAssignment
			|	END,
			|	TableTypesOfStocks_.LineOfBusinessRecipient AS CorLineOfBusiness,
			|	HeaderData_.DestinationWarehouse,
			|	TableTypesOfStocks_.InventoryTypeRegistration,
			|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt,
			|	0,
			|	TableTypesOfStocks_.Count,
			|	0,
			|	0,
			|	0,
			|	HeaderData_.Ref AS DocumentRegisterRecords,
			|	CASE
			|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
			|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
			|		ELSE TableTypesOfStocks_.Products
			|	END,
			|	CASE
			|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
			|			THEN TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt
			|		ELSE TableTypesOfStocks_.Products
			|	END,
			|	HeaderData_.Organization AS CorCompany
			|FROM
			|	TTTypesOfStocks AS TableTypesOfStocks_
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TableTypesOfStocks_.Ref)
			|WHERE
			|	HeaderData_.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)
			|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)";
	EndIf;

	QueryText = StrConcat(PartsOfQueryText, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

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
		|	DocumentData.Ref AS Ref,
		|	DocumentData.IBDocumentDate AS IBDocumentDate,
		|	DocumentData.IBDocumentNumber AS IBDocumentNumber,
		|	DocumentData.RefType AS RefType,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.StorageLocation AS StorageLocation,
		|	DocumentData.Department AS Department,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Author AS Author,
		|	DocumentData.Comment AS Comment,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.Sum AS Sum,
		|	DocumentData.Status AS Status,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.AdditionalRecord AS AdditionalRecord,
		|	DocumentData.More AS More,
		|	DocumentData.SourceDocumentDate AS SourceDocumentDate,
		|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
		|	DocumentData.IBDocumentDate AS RecordingInAccountingDate,
		|	DocumentData.Patch AS ReverseTransactionCorrection,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	UNDEFINED AS Priority
		|FROM
		|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
		"SELECT
		|	DocumentGoods.Ref AS Ref,
		|	HeaderData_.Date AS Period,
		|	CASE
		|		WHEN HeaderData_.TransferAgainstOrders
		|				AND DocumentGoods.TransferOrder <> VALUE(Document.TransferOrder.EmptyRef)
		|			THEN DocumentGoods.TransferOrder
		|		ELSE UNDEFINED
		|	END AS OrderDocument,
		|	HeaderData_.Ref AS Invoice,
		|	HeaderData_.Patch AS Patch,
		|	HeaderData_.CorrectedDocument AS CorrectedDocument,
		|	HeaderData_.DestinationWarehouse AS Recipient,
		|	HeaderData_.SourceWarehouse AS Warehouse,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.AssignmentSender AS Purpose,
		|	DocumentGoods.ControlledLotOfTheSender AS ControlledLotReference,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.BatchesIndicationStatusSender AS BatchesIndicationStatus,
		|	DocumentGoods.Count AS Count,
		|	HeaderData_.TransferAgainstOrders
		|		AND DocumentGoods.RowCode = 0 AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	HeaderData_.TransferAgainstOrders AS ShipmentByOrder
		|FROM
		|	DocumentDataTableItems AS DocumentGoods
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON HeaderData_.Ref = DocumentGoods.Ref
		|WHERE
		|	DocumentGoods.Count <> 0";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
		"SELECT
		|	DocumentGoods.Ref AS Ref,
		|	HeaderData_.Date AS Period,
		|	CASE
		|		WHEN HeaderData_.TransferAgainstOrders
		|				AND DocumentGoods.TransferOrder <> VALUE(Document.TransferOrder.EmptyRef)
		|			THEN DocumentGoods.TransferOrder
		|		ELSE UNDEFINED
		|	END AS OrderDocument,
		|	HeaderData_.Ref AS Invoice,
		|	HeaderData_.Patch AS Patch,
		|	HeaderData_.CorrectedDocument AS CorrectedDocument,
		|	HeaderData_.DestinationWarehouse AS Recipient,
		|	HeaderData_.SourceWarehouse AS Warehouse,
		|	DocumentGoods.Products AS Products,
		|	DocumentGoods.Characteristic AS Characteristic,
		|	DocumentGoods.AssignmentSender AS Purpose,
		|	DocumentGoods.Purpose AS PurposeForConnection,
		|	DocumentGoods.ControlledLotOfTheSender AS ControlledLotReference,
		|	DocumentGoods.Series AS Series,
		|	DocumentGoods.BatchesIndicationStatusSender AS BatchesIndicationStatus,
		|	DocumentGoods.Count AS Count,
		|	HeaderData_.TransferAgainstOrders
		|		AND DocumentGoods.RowCode = 0 AS ExceedingOrder,
		|	FALSE AS Canceled,
		|	TRUE AS ThisIsAnInvoice,
		|	HeaderData_.TransferAgainstOrders AS ShipmentByOrder
		|FROM
		|	DocumentDataTableItems AS DocumentGoods
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON DocumentGoods.Ref = HeaderData_.Ref
		|WHERE
		|	DocumentGoods.Count <> 0
		|	AND DocumentGoods.Ref IN(&Ref)";
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Purpose", "PurposeForConnection");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.SynonymForDocumentTable = "DocumentGoods";
	ParametersOfModularHolding.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	ParametersOfModularHolding.MetadataObject = Metadata.Documents.InventoryTransfer;
	
	WarehousesServer.ArrangeShipmentOfGoodsBySettingParameters(
		Query,
		QueryTexts,
		Registers,
		TextOfDocumentDataRequest,
		ParametersOfModularHolding);
	
EndProcedure

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
		"SELECT
		|	TableDocumentRegistry.Ref AS Ref,
		|	TableDocumentRegistry.IBDocumentDate AS IBDocumentDate,
		|	MAX(TableDocumentRegistry.IBDocumentNumber) AS IBDocumentNumber,
		|	TableDocumentRegistry.RefType AS RefType,
		|	TableDocumentRegistry.Organization AS Organization,
		|	TableDocumentRegistry.BusinessOperation AS BusinessOperation,
		|	TableDocumentRegistry.Partner AS Partner,
		|	TableDocumentRegistry.Counterparty AS Counterparty,
		|	CASE
		|		WHEN TableDocumentRegistry.NumberOfActivities = 1
		|			THEN TableDocumentRegistry.LineOfBusiness
		|		ELSE UNDEFINED
		|	END AS LineOfBusiness,
		|	TableDocumentRegistry.StorageLocation AS StorageLocation,
		|	TableDocumentRegistry.Department AS Department,
		|	MAX(TableDocumentRegistry.EmployeeResponsible) AS EmployeeResponsible,
		|	MAX(TableDocumentRegistry.Author) AS Author,
		|	MAX(TableDocumentRegistry.Comment) AS Comment,
		|	MAX(TableDocumentRegistry.Currency) AS Currency,
		|	MAX(TableDocumentRegistry.Sum) AS Sum,
		|	MAX(TableDocumentRegistry.Status) AS Status,
		|	MAX(TableDocumentRegistry.Posted) AS Posted,
		|	MAX(TableDocumentRegistry.DeletionMark) AS DeletionMark,
		|	MIN(TableDocumentRegistry.AdditionalRecord) AS AdditionalRecord,
		|	MAX(TableDocumentRegistry.More) AS More,
		|	MAX(TableDocumentRegistry.SourceDocumentDate) AS SourceDocumentDate,
		|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber,
		|	MAX(TableDocumentRegistry.Patch) AS Patch,
		|	MAX(TableDocumentRegistry.ReversedDocument) AS ReversedDocument,
		|	MAX(TableDocumentRegistry.CorrectedDocument) AS CorrectedDocument
		|INTO TTBases
		|FROM
		|	(SELECT
		|		DocumentData.Ref AS Ref,
		|		&Period AS IBDocumentDate,
		|		&Number AS IBDocumentNumber,
		|		&MetadataIdentifier AS RefType,
		|		&Organization AS Organization,
		|		&BusinessOperation AS BusinessOperation,
		|		UNDEFINED AS Partner,
		|		UNDEFINED AS Counterparty,
		|		MAX(ISNULL(GoodsTable.AssignmentSender.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
		|		COUNT(DISTINCT ISNULL(GoodsTable.AssignmentSender.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities,
		|		&SourceWarehouse AS StorageLocation,
		|		&Department AS Department,
		|		&EmployeeResponsible AS EmployeeResponsible,
		|		&Author AS Author,
		|		CAST(&Comment AS STRING(100)) AS Comment,
		|		UNDEFINED AS Currency,
		|		0 AS Sum,
		|		&Status AS Status,
		|		&Posted AS Posted,
		|		&DeletionMark AS DeletionMark,
		|		FALSE AS AdditionalRecord,
		|		&WarehouseInformationRecipient AS More,
		|		&Patch AS Patch,
		|		&ReversedDocument AS ReversedDocument,
		|		&CorrectedDocument AS CorrectedDocument,
		|		&Period AS SourceDocumentDate,
		|		&NumberForPrinting AS SourceDocumentNumber
		|	
		|	FROM
		|		Document.InventoryTransfer AS DocumentData
		|			LEFT JOIN Document.InventoryTransfer.Goods AS GoodsTable
		|			ON DocumentData.Ref = GoodsTable.Ref
		|	WHERE
		|		DocumentData.Ref = &Ref
		|	
		|	GROUP BY
		|		DocumentData.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentData.Ref AS Ref,
		|		&Period AS IBDocumentDate,
		|		&Number AS IBDocumentNumber,
		|		&MetadataIdentifier AS RefType,
		|		CASE
		|			WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
		|				THEN &CompanyRecipient
		|			ELSE &Organization
		|		END AS Organization,
		|		&BusinessOperation AS BusinessOperation,
		|		UNDEFINED AS Partner,
		|		UNDEFINED AS Counterparty,
		|		MAX(ISNULL(GoodsTable.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
		|		COUNT(DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities,
		|		&DestinationWarehouse AS StorageLocation,
		|		&Department AS Department,
		|		&EmployeeResponsible AS EmployeeResponsible,
		|		&Author AS Author,
		|		CAST(&Comment AS STRING(100)) AS Comment,
		|		UNDEFINED AS Currency,
		|		0 AS Sum,
		|		&Status AS Status,
		|		&Posted AS Posted,
		|		&DeletionMark AS DeletionMark,
		|		TRUE AS AdditionalRecord,
		|		&WarehouseInformationToSender AS More,
		|		&Patch AS Patch,
		|		&ReversedDocument AS ReversedDocument,
		|		&CorrectedDocument AS CorrectedDocument,
		|		&Period AS SourceDocumentDate,
		|		&NumberForPrinting AS SourceDocumentNumber
		|	FROM
		|		Document.InventoryTransfer AS DocumentData
		|			LEFT JOIN Document.InventoryTransfer.Goods AS GoodsTable
		|			ON DocumentData.Ref = GoodsTable.Ref
		|	WHERE
		|		DocumentData.Ref = &Ref
		|	
		|	GROUP BY
		|		DocumentData.Ref) AS TableDocumentRegistry
		|
		|GROUP BY
		|	TableDocumentRegistry.RefType,
		|	TableDocumentRegistry.Organization,
		|	TableDocumentRegistry.BusinessOperation,
		|	TableDocumentRegistry.Partner,
		|	TableDocumentRegistry.Counterparty,
		|	TableDocumentRegistry.Department,
		|	TableDocumentRegistry.StorageLocation,
		|	TableDocumentRegistry.IBDocumentDate,
		|	TableDocumentRegistry.Ref,
		|	CASE
		|		WHEN TableDocumentRegistry.NumberOfActivities = 1
		|			THEN TableDocumentRegistry.LineOfBusiness
		|		ELSE UNDEFINED
		|	END";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	HeaderData_.Date AS Period,
		|	&Organization AS Organization,
		|	Inventories.Currency AS Currency,
		|	Inventories.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.CCDNumber AS CCDNumber,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	0 AS Count,
		|	Inventories.Count AS QuantityConsumed,
		|	0 AS RevenueAmount,
		|	0 AS RevenueAmountExclVATLocal,
		|	0 AS RevenueAmountMan,
		|	0 AS QuantityToRegister,
		|	Inventories.Count AS QuantityConsumedForIncoiceRegistration,
		|	0 AS RevenueAmountToRegister,
		|	UNDEFINED AS CorInventoryOwnerAttribute,
		|	Inventories.CommitteeAccountingAnalytics AS ItemsLocationAttributes,
		|	Inventories.RowID AS FinRecordID,
		|	HeaderData_.BusinessTransactionSetting AS BusinessTransactionSetting,
		|	Inventories.RowID AS RowID
		|FROM
		|	TTTypesOfStocks AS Inventories
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON Inventories.Ref = HeaderData_.Ref
		|WHERE
		|	Inventories.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
		|	AND Inventories.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.InventoryTransfer";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",                 """""");
	RedefiningParameterCalculation.Insert("WarehouseInformationRecipient",  """""");
	RedefiningParameterCalculation.Insert("WarehouseInformationToSender", """""");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnShipment",
		"CASE
		|		WHEN GoodsTable.Ref.SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnGoodsReceipt", 
		"CASE
		|		WHEN GoodsTable.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	RedefiningParameterCalculation.Insert("ByTransferOrder", "GoodsTable.Ref.TransferAgainstOrders");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	
	If RegisterName = "TransferOrders" Then
	
		QueryText = QueryTextTableTransferOrders(Query, QueryTexts, RegisterName);
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", FullDocumentName + ".Goods");
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName%kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	HeaderData_.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	HeaderData_.SourceWarehouse AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	TabPart.ControlledLotOfTheSender AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	DocumentDataTableItems AS TabPart
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON HeaderData_.Ref = TabPart.Ref
		|WHERE
		|	TabPart.RowCode = 0";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);

	If DocumentObject = Undefined
		Or DocumentObject.Status = Enums.GoodsTransferStatuses.Accepted Then

		// Arrival at an irregular warehouse or for old purposes.
		QueryTextTabPart =
			"SELECT
			|	TabPart.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	HeaderData_.DestinationWarehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	TabPart.ControlledLotReference AS ControlledLotReference,
			|	TabPart.ToControlQuality AS ToControlQuality,
			|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
			|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
			|	TabPart.Count AS Count,
			|	HeaderData_.TransferAgainstOrders
			|		AND TabPart.RowCode <> 0 AS OnSchedule,
			|	CASE
			|		WHEN TabPart.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef)
			|			THEN TabPart.ControlledLotOfTheSender
			|		ELSE TabPart.TransferOrder
			|	END AS OrderInSchedule
			|FROM
			|	DocumentDataTableItems AS TabPart
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TabPart.Ref)
			|WHERE
			|	(NOT HeaderData_.AdvancedWarehousingOnGoodsReceipt
			|			OR NOT TabPart.AssigningTrafficToWarehouseRegisters)
			|	AND HeaderData_.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)";
		
		StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
		// The reverse of the receipt order for the old appointments.
		QueryTextTabPart =
			"SELECT
			|	TabPart.Ref AS Ref,
			|	HeaderData_.Date AS Period,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	HeaderData_.DestinationWarehouse AS Warehouse,
			|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
			|	FALSE AS ToControlQuality,
			|	FALSE AS SubjectToUnlocking,
			|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
			|	-TabPart.Count AS Count,
			|	FALSE AS OnSchedule,
			|	UNDEFINED AS OrderInSchedule
			|FROM
			|	DocumentDataTableItems AS TabPart
			|		LEFT JOIN DocumentDataHeader AS HeaderData_
			|		ON (HeaderData_.Ref = TabPart.Ref)
			|WHERE
			|	TabPart.AssigningTrafficToWarehouseRegisters = FALSE
			|	AND HeaderData_.AdvancedWarehousingOnGoodsReceipt
			|	AND HeaderData_.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)";
		
		StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);

	EndIf;
	
	QueryTextTabPart =
		"SELECT
		|	HeaderData_.Ref AS Ref,
		|	HeaderData_.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	HeaderData_.DestinationWarehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.AssigningTrafficToWarehouseRegisters = FALSE
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE TabPart.Purpose
		|	END AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	CASE
		|		WHEN TabPart.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN TabPart.ControlledLotOfTheSender
		|		WHEN HeaderData_.TransferAgainstOrders
		|				AND HeaderData_.GoodsReceiptOption <> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			THEN TabPart.TransferOrder
		|		ELSE
		|			CASE
		|				WHEN HeaderData_.CorrectedDocument = VALUE(Document.InventoryTransfer.EmptyRef)
		|					THEN HeaderData_.Ref
		|				ELSE HeaderData_.CorrectedDocument
		|			END
		|	END AS OrderDocument,
		|	CASE
		|		WHEN HeaderData_.DateOfReceipt <> DATETIME(1, 1, 1)
		|			THEN HeaderData_.DateOfReceipt
		|		ELSE HeaderData_.Date
		|	END AS DateOfReceipt,
		|	TRUE AS AvailableForConsumption,
		|	HeaderData_.TransferAgainstOrders
		|		AND TabPart.RowCode <> 0 AS OnSchedule,
		|	CASE
		|		WHEN TabPart.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN TabPart.ControlledLotOfTheSender
		|		ELSE
		|			TabPart.TransferOrder
		|	END AS OrderInSchedule,
		|	TabPart.Count AS QuantityInGraph
		|FROM
		|	DocumentDataTableItems AS TabPart
		|		LEFT JOIN DocumentDataHeader AS HeaderData_
		|		ON HeaderData_.Ref = TabPart.Ref
		|WHERE
		|	(HeaderData_.AdvancedWarehousingOnGoodsReceipt
		|				AND (HeaderData_.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|					OR NOT HeaderData_.TransferAgainstOrders
		|					OR TabPart.RowCode = 0)
		|			OR HeaderData_.Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
		|				AND (NOT HeaderData_.TransferAgainstOrders
		|					OR TabPart.RowCode = 0))";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
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
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.SenderProductAnalysis	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	DocumentTable.TransferForActivity			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	DocumentTable.CompanyRecipient			    AS CorCompany,
	|	UNDEFINED 									    AS CorLot,
	|	TableTypesOfStocks_.RecipientProductAnalysis  AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt		    AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.EmployeeResponsible	AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.InventoryTransfer AS DocumentTable
	|	LEFT JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Status = VALUE(Enum.GoodsTransferStatuses.Accepted)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
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
	
	// Invoice on the move
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "TransferNote";
	PrintCommand.Presentation = NStr("vi = 'Phiếu điều chuyển hàng hóa';
									|ru = 'Накладная на перемещение';
									|en = 'Goods transfer'; fa = 'انتقال کالا';
									|it = 'Bolla per trasferimento';
									|pl = 'Faktura na przemieszczenie';
									|tr = 'Taşıma için irsaliye'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 3;

	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob",
																							8);
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														Enums.GoodsTransferStatuses.Accepted,
														ComparisonType.Equal);
	
	// Task for the selection of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask", 9);

	If AccessRight("Read", Metadata.Catalogs.QualityCertificates)
		And GetFunctionalOption("UseQualityCertificates") Then
		// Register of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesOfProductsRegister";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (đăng ký)';
										|ru = 'Сертификаты (реестр)';
										|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
										|it = 'Certificati (registro)';
										|pl = 'Certyfikaty (rejestr)';
										|tr = 'Sertifikalar (kayıt)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 10;
		
		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocuments";
		PrintCommand.Presentation = NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
										|ru = 'Сертификаты (по каждой позиции документа)';
										|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
										|it = 'Certificati (per ogni voce del documento)';
										|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
										|tr = 'Sertifikalar (belgedeki her kalem için)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 11;

		// Images of Nomenclature certificates
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "CertificatesProductImagesFromDocumentsWithoutDuplicates";
		PrintCommand.Presentation = NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
										|ru = 'Сертификаты (по одному на сертификат)';
										|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
										|it = 'Certificati (uno per certificato)';
										|pl = 'Certyfikaty (po jednym na certyfikat)';
										|tr = 'Sertifikalar (sertifika başına bir tane)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 12;

	EndIf;

	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "PriceTags";
		PrintCommand.Presentation = NStr("vi = 'Nhãn giá';
										|ru = 'Ценники';
										|en = 'Price tags'; fa = 'برچسب‌های قیمت';
										|it = 'Cartellini del prezzo';
										|pl = 'Price tags';
										|tr = 'Fiyat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 15;

		// Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "";
		PrintCommand.Id = "Labels";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 16;
	EndIf;

	If GoodsDeliveryClientServer.UsedDelivery20() Then
		// Shipping Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintingShippingLabels";
		PrintCommand.PrintManager = "DataProcessor.PrintPriceTagsAndLabels.Print";
		PrintCommand.Id = "ShippingLabel";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem giao hàng';
										|ru = 'Этикетки доставки';
										|en = 'Delivery labels'; fa = 'Delivery labels';
										|it = 'Etichette di consegna';
										|pl = 'Etykiety dostawy';
										|tr = 'Teslimat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 17;
	EndIf;
	
	InventoryTransferLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Procedure for printing a document.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "TransferNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"TransferNote",
			NStr("vi = 'Phiếu điều chuyển hàng hóa';
				|ru = 'Накладная на перемещение';
				|en = 'Goods transfer'; fa = 'انتقال کالا';
				|it = 'Bolla per trasferimento';
				|pl = 'Faktura na przemieszczenie';
				|tr = 'Taşıma için irsaliye'"),
			CreatePrintedFormOfInvoiceForMovementOfGoods(ObjectsArray, PrintObjects));
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesOfProductsRegister") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateRegistry");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocuments") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificatesProductImagesFromDocumentsWithoutDuplicates") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(ObjectsArray, PrintObjects),
			,
			"Catalog.QualityCertificates.PF_MXL_CertificateImages");
	EndIf;
		
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	InventoryTransferLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.InventoryTransfer.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"TransferNote");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			CreatePrintedFormOfInvoiceForMovementOfGoods(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificatesOfProductsRegister");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.CreatePrintedFormRegisterOfProductCertificates(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificatesProductImagesFromDocuments");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocuments(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CertificatesProductImagesFromDocumentsWithoutDuplicates");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			Catalogs.QualityCertificates.GeneratePrintedFormImagesOfCertificatesFromDocumentsWithoutDuplicates(PrintKit.Objects, PrintObjects));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
																									PrintFormsSet,
																									ObjectsArray,
																									"GoodsPickingPlacementJob");
	
	PrintParameters.Insert("JobType", "SelectionTask");
	
	For Each PrintKit In SetsOfPrintingOnObjects Do
		
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.InventoryTransfer", PrintKit.Objects);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.CreateTaskForProductSelectionAndPlacement(StructureOfTypes,
																										PrintObjects,
																										PrintParameters));
		
	EndDo;
	
	InventoryTransferLocalization.CreateSetOfPrintedForms(ObjectsArray, 
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);
		
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.InventoryTransfer",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
	
EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "TransferNote", NStr("vi = 'Phiếu điều chuyển hàng hóa';
																									|ru = 'Накладная на перемещение';
																									|en = 'Goods transfer'; fa = 'انتقال کالا';
																									|it = 'Bolla per trasferimento';
																									|pl = 'Faktura na przemieszczenie';
																									|tr = 'Taşıma için irsaliye'"),                     0);

	If GetFunctionalOption("UseQualityCertificates") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
			"CertificatesOfProductsRegister",
			NStr("vi = 'Giấy chứng nhận (đăng ký)';
				|ru = 'Сертификаты (реестр)';
				|en = 'Certificates (registry)'; fa = 'Certificates (registry)';
				|it = 'Certificati (registro)';
				|pl = 'Certyfikaty (rejestr)';
				|tr = 'Sertifikalar (kayıt)'"),
			0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
			"CertificatesProductImagesFromDocuments",
			NStr("vi = 'Giấy chứng nhận (cho mỗi mục trong chứng từ)';
				|ru = 'Сертификаты (по каждой позиции документа)';
				|en = 'Certificates (by each document item)'; fa = 'Certificates (by each document item)';
				|it = 'Certificati (per ogni voce del documento)';
				|pl = 'Certyfikaty (dla każdej pozycji dokumentu)';
				|tr = 'Sertifikalar (belgedeki her kalem için)'"),
			0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
			"CertificatesProductImagesFromDocumentsWithoutDuplicates",
			NStr("vi = 'Chứng chỉ (một cho mỗi chứng chỉ)';
				|ru = 'Сертификаты (по одному на сертификат)';
				|en = 'Certificates (one per certificate)'; fa = 'Certificates (one per certificate)';
				|it = 'Certificati (uno per certificato)';
				|pl = 'Certyfikaty (po jednym na certyfikat)';
				|tr = 'Sertifikalar (sertifika başına bir tane)'"),
			0);	
	EndIf;
	
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
																			"GoodsPickingPlacementJob",
																			NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
																				|ru = 'Задание на отбор товаров';
																				|en = 'Picking job'; fa = 'کار برداشت';
																				|it = 'Task per selezione prodotti';
																				|pl = 'Zadanie na selekcję towarów';
																				|tr = 'Ürün filtre görevi'"),
																			0);
	
	InventoryTransferLocalization.PrintFormsSet(PrintFormsSet);
	
	Return PrintFormsSet;
	
EndFunction

// Returns the address in the temporary storage for the generated data collection used for printing labels.
//
// Parameters:
//	DocumentsArray - Array of DocumentRef.InventoryTransfer - a collection of document references used
//																	to prepare label printing data.
//
// Returns:
//	String - the address in the temporary storage for the generated collection of data used for printing labels.
//
Function LabelPrintingData(DocumentsArray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED DISTINCT
	|	HeaderData_.Organization							AS Organization,
	|	HeaderData_.DestinationWarehouse						AS Warehouse,
	|	HeaderData_.DestinationWarehouse.RetailPriceType	AS PriceKind
	|FROM
	|	Document.InventoryTransfer AS HeaderData_
	|WHERE
	|	HeaderData_.Ref IN (&DocumentsArray)
	|	AND NOT HeaderData_.DestinationWarehouse.RetailPriceType IS NULL";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		MessageText = NStr("vi = 'Người sử dụng không thể truy cập đến kho nhận. Không thể in nhãn tem.';
							|ru = 'У пользователя нет доступа к складу-получателю. Печать этикеток невозможна.';
							|en = 'The user does not have access to the destination warehouse. Labels cannot be printed.'; fa = 'The user does not have access to the destination warehouse. Labels cannot be printed.';
							|it = 'У пользователя нет доступа к складу-получателю. Печать этикеток невозможна.';
							|pl = 'The user does not have access to the destination warehouse. Labels cannot be printed.';
							|tr = 'Kullanıcının hedef ambara erişimi yoktur. Etiketler yazdırılamaz.'");
		
		Raise MessageText;
	EndIf;
	
	DetailsOfDocuments = QueryResult.Unload();
	
	Query.Text = 
	"SELECT ALLOWED
	|	TableOfGoods.Ref						AS Ref,
	|	MIN(TableOfGoods.LineNumber)			AS Order,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.Package						AS Package,
	|	SUM(TableOfGoods.NumberOfPackages)	AS Count
	|INTO TableOfProductsToRequest
	|FROM
	|	Document.InventoryTransfer.Goods AS TableOfGoods
	|		LEFT JOIN Document.InventoryTransfer AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	TableOfGoods.Ref IN (&DocumentsArray)
	|	AND NOT HeaderData_.DestinationWarehouse.RetailPriceType IS NULL
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	COUNT(TableOfGoods.Package)	AS NumberOfPackages
	|INTO TableOfProductsGrouped
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfSeries.Ref				AS Ref,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	TableOfSeries.Series				AS Series,
	|	SUM(TableOfSeries.Count)	AS Count
	|INTO DocumentSeriesTable
	|FROM
	|	Document.InventoryTransfer.SetOfSeries AS TableOfSeries
	|		LEFT JOIN Document.InventoryTransfer AS HeaderData_
	|		ON TableOfSeries.Ref = HeaderData_.Ref
	|
	|WHERE
	|	TableOfSeries.Ref IN (&DocumentsArray)
	|	AND NOT HeaderData_.DestinationWarehouse.RetailPriceType IS NULL
	|
	|GROUP BY
	|	TableOfSeries.Ref,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Series
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Ref				AS Ref,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	COUNT(TableOfSeries.Series)	AS SeriesCount
	|INTO SeriesTableGrouped
	|FROM
	|	DocumentSeriesTable AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Ref,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic,
	|	TableOfSeries.Series			AS Series,
	|	TableOfGoods.Package		AS Package,
	|	TableOfSeries.Count / ISNULL(&QueryTextPackagingFactor, 1) AS Count
	|INTO SeriesTableForQuery
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		INNER JOIN DocumentSeriesTable AS TableOfSeries
	|		ON TableOfGoods.Ref = TableOfSeries.Ref
	|			AND TableOfGoods.Products = TableOfSeries.Products
	|			AND TableOfGoods.Characteristic = TableOfSeries.Characteristic
	|
	|WHERE
	|	(TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			TableOfProductsGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.NumberOfPackages = 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic,
	|	TableOfSeries.Series			AS Series,
	|	TableOfGoods.Package		AS Package,
	|	TableOfGoods.Count	AS Count
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		INNER JOIN DocumentSeriesTable AS TableOfSeries
	|		ON TableOfGoods.Ref = TableOfSeries.Ref
	|			AND TableOfGoods.Products = TableOfSeries.Products
	|			AND TableOfGoods.Characteristic = TableOfSeries.Characteristic
	|
	|WHERE
	|	(TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			TableOfProductsGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.NumberOfPackages > 1)
	|	AND (TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			SeriesTableGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.SeriesCount = 1)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic,
	|	TableOfSeries.Series			AS Series,
	|	TableOfSeries.Package		AS Package,
	|	TableOfSeries.Count		AS Count
	|INTO TableOfSeries
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		INNER JOIN SeriesTableForQuery AS TableOfSeries
	|		ON ItemsBarcodes.Products = TableOfSeries.Products
	|			AND ItemsBarcodes.Characteristic = TableOfSeries.Characteristic
	|			AND ItemsBarcodes.Series = TableOfSeries.Series
	|			AND ItemsBarcodes.Package = TableOfSeries.Package
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.Ref				AS Ref,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	TableOfSeries.Package			AS Package,
	|	SUM(TableOfSeries.Count)	AS Count
	|FROM
	|	SeriesTableForQuery AS TableOfSeries
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON TableOfSeries.Products = ItemsBarcodes.Products
	|			AND TableOfSeries.Characteristic = ItemsBarcodes.Characteristic
	|			AND TableOfSeries.Series = ItemsBarcodes.Series
	|			AND TableOfSeries.Package = ItemsBarcodes.Package
	|
	|WHERE
	|	ItemsBarcodes.Barcode IS NULL
	|
	|GROUP BY
	|	TableOfSeries.Ref,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Package
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TableOfGoods.Order)		AS Order,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Series				AS Series,
	|	TableOfGoods.Package				AS Package,
	|	SUM(TableOfGoods.Count)	AS Count
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|
	|WHERE
	|	(TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic, TableOfGoods.Package) NOT IN
	|		(SELECT
	|			TableOfSeries.Ref			AS Ref,
	|			TableOfSeries.Products	AS Products,
	|			TableOfSeries.Characteristic	AS Characteristic,
	|			TableOfSeries.Package		AS Package
	|		FROM
	|			TableOfSeries AS TableOfSeries)
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Package
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableOfGoods.Order)	AS Order,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	TableOfSeries.Series				AS Series,
	|	TableOfSeries.Package			AS Package,
	|	SUM(TableOfSeries.Count)	AS Count
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		INNER JOIN TableOfSeries AS TableOfSeries
	|		ON TableOfGoods.Ref = TableOfSeries.Ref
	|			AND TableOfGoods.Products = TableOfSeries.Products
	|			AND TableOfGoods.Characteristic = TableOfSeries.Characteristic
	|			AND TableOfGoods.Package = TableOfSeries.Package
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Series,
	|	TableOfSeries.Package
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic
	|FROM
	|	DocumentSeriesTable AS TableOfSeries
	|
	|WHERE
	|	(TableOfSeries.Ref, TableOfSeries.Products, TableOfSeries.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			TableOfProductsGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.NumberOfPackages > 1)
	|	AND (TableOfSeries.Ref, TableOfSeries.Products, TableOfSeries.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			SeriesTableGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.SeriesCount > 1)";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
	
	QueryResult = Query.ExecuteBatch();
	
	Companies	= TMCommonUse.UniqueValuesFromTableColumn(DetailsOfDocuments, "Organization");
	Warehouses		= TMCommonUse.UniqueValuesFromTableColumn(DetailsOfDocuments, "Warehouse");
	TypesOfPrices		= TMCommonUse.UniqueValuesFromTableColumn(DetailsOfDocuments, "PriceKind");
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", ?(Companies.Count() = 1, Companies[0], Undefined));
	StructureOfActions.Insert("FillInTheWarehouse", ?(Warehouses.Count() = 1, Warehouses[0], Warehouses));
	StructureOfActions.Insert("FillInPriceView", ?(TypesOfPrices.Count() = 1, TypesOfPrices[0], Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of processing the printing of price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Date",						TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray));
	ResultingStructure.Insert("Goods",					QueryResult[QueryResult.UBound() - 1].Unload());
	ResultingStructure.Insert("ErrorTableBySeries",	QueryResult[QueryResult.UBound()].Unload());
	ResultingStructure.Insert("StructureOfActions",		StructureOfActions);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

// The function puts the necessary data in the structure. The structure is placed in temporary storage.
//
// Returns:
//   String - the address of the data structure in the temporary storage.
//
Function DataForPrintingPriceTags(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	MovementOfGoodsGoods.Products      AS Products,
	|	MovementOfGoodsGoods.Characteristic    AS Characteristic,
	|	MovementOfGoodsGoods.Package          AS Package,
	|	MovementOfGoodsGoods.Series             AS Series,
	|	MIN(MovementOfGoodsGoods.LineNumber) AS Order,
	|	SUM(MovementOfGoodsGoods.Count)    AS Count
	|FROM
	|	Document.InventoryTransfer.Goods AS MovementOfGoodsGoods
	|WHERE
	|	MovementOfGoodsGoods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	MovementOfGoodsGoods.Products,
	|	MovementOfGoodsGoods.Characteristic,
	|	MovementOfGoodsGoods.Package,
	|	MovementOfGoodsGoods.Series
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	InventoryTransfer.Organization                      AS Organization,
	|	InventoryTransfer.DestinationWarehouse                  AS Warehouse,
	|	InventoryTransfer.DestinationWarehouse.RetailPriceType AS PriceKind,
	|	CASE
	|		WHEN NOT InventoryTransfer.DestinationWarehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|				AND InventoryTransfer.DestinationWarehouse.RetailPriceType IS NULL
	|			THEN 0
	|		ELSE 1
	|	END AS ReceivingWarehouseIsAccessibleToUser
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	TableDocumentDetails = ResultsArray[1].Unload();
	CompanyArray = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Organization");
	WarehouseArray     = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Warehouse");
	
	TableOfPriceTypes = TableDocumentDetails.Copy(, "PriceKind,ReceivingWarehouseIsAccessibleToUser");
	TableOfPriceTypes.GroupBy("PriceKind", "ReceivingWarehouseIsAccessibleToUser");
	FillInPriceView = Undefined;
	If TableOfPriceTypes.Count() = 1 Then
		If TableOfPriceTypes[0].ReceivingWarehouseIsAccessibleToUser Then
			FillInPriceView = TableDocumentDetails[0].PriceKind;
		Else
			MessageText = NStr("vi = 'Người sử dụng không thể truy cập đến kho nhận. Không thể in nhãn giá.';
								|ru = 'У пользователя нет доступа к складу-получателю. Печать ценников невозможна.';
								|en = 'The user does not have access to the destination warehouse. Price tags cannot be printed.'; fa = 'The user does not have access to the destination warehouse. Price tags cannot be printed.';
								|it = 'У пользователя нет доступа к складу-получателю. Печать ценников невозможна.';
								|pl = 'The user does not have access to the destination warehouse. Price tags cannot be printed.';
								|tr = 'Kullanıcının hedef ambara erişimi yoktur. Etiket yazdırılamaz.'");
			Raise MessageText;
		EndIf;
	EndIf;
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", ?(CompanyArray.Count() = 1, CompanyArray[0], Undefined));
	StructureOfActions.Insert("FillInTheWarehouse",       ?(WarehouseArray.Count() = 1,     WarehouseArray[0],     WarehouseArray));
	StructureOfActions.Insert("FillInPriceView",     FillInPriceView);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintingPriceTags");
	StructureOfActions.Insert("FillInTheNumberOfPriceTagsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", ResultsArray[0].Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

// The function generates a tabular document with a printed invoice form
// developed by methodologists.
//
// Returns:
//  SpreadsheetDocument - the printed form of the invoice.
//
Function CreatePrintedFormOfInvoiceForMovementOfGoods(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_InventoryTransfer_Invoice";
	Template = PrintManagement.PrintFormTemplate("Document.InventoryTransfer.PF_MXL_TransferNote");
	
	HeaderAreaMove         = Template.GetArea("TitleMove");
	HeaderAreaInternalTransfer  = Template.GetArea("TitleInternalTransfer");
	
	If OutputCodes Then
		AreaCodesHeader  = Template.GetArea("TableHeader|ColumnOfCodes");
		AreaCodesHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		
		AreaCodesString = Template.GetArea("String|ColumnOfCodes");
		AreaCodesBasement = Template.GetArea("Footer|ColumnOfCodes");
	Else
		ScopeOfApplication_10 = Template.Area("OwnGoods");
		ScopeOfApplication_10.ColumnWidth = ScopeOfApplication_10.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
	EndIf;
	
	If UseItemPackages Then
		PackagingAreaHeader  =  Template.GetArea("TableHeader|ColumnOfPackages");
		PackagingAreaString =  Template.GetArea("String|ColumnOfPackages");
		PackingAreaBasement =  Template.GetArea("Footer|ColumnOfPackages");
	Else
		ScopeOfApplication_10 = Template.Area("OwnGoods");
		ScopeOfApplication_10.ColumnWidth = ScopeOfApplication_10.ColumnWidth 
									  + Template.Area("ColumnOfPackagesQuantity").ColumnWidth
									  + Template.Area("ColumnOfPackagesPresentation").ColumnWidth;
	EndIf;
	
	AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
	HeaderDataArea = Template.GetArea("TableHeader|OwnGoods");
	AreaEndOfLineHeader = Template.GetArea("TableHeader|EndOfRow");
	
	NumberAreaLine = Template.GetArea("String|LineNumber");
	DataAreaRow = Template.GetArea("String|OwnGoods");
	AreaEndOfLineString = Template.GetArea("String|EndOfRow");
	
	RoomAreaBasement = Template.GetArea("Footer|LineNumber");
	DataAreaBasement = Template.GetArea("Footer|OwnGoods");
	AreaEndOfLineBasement = Template.GetArea("Footer|EndOfRow");
	
	SignatureArea = Template.GetArea("Signatures");
	
	RequestByHeader = New Query;
	RequestByHeader.Text = 
	"SELECT
	|	InventoryTransfer.Ref                              AS Ref,
	|	InventoryTransfer.Number                               AS Number,
	|	InventoryTransfer.Date                                AS Date,
	|	InventoryTransfer.CorrectedDocument.Number          AS NumberOfDocumentBeingCorrected,
	|	InventoryTransfer.CorrectedDocument.Date           AS DateOfDocumentBeingCorrected,
	|	InventoryTransfer.Organization.Prefix                 AS Prefix,
	|	InventoryTransfer.BusinessOperation               AS BusinessOperation,
	|	InventoryTransfer.SourceWarehouse.Presentation      AS SenderPresentation,
	|	InventoryTransfer.DestinationWarehouse.Presentation       AS RecipientPresentation,
	|	InventoryTransfer.Organization						   AS Organization,
	|	InventoryTransfer.CompanyRecipient			   AS CompanyRecipient,
	|	CASE WHEN InventoryTransfer.SourceWarehouse.UseItemsBatch
	|	 OR InventoryTransfer.DestinationWarehouse.UseItemsBatch THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS UseItemsBatch
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref IN(&DocumentsArray)
	|
	|ORDER BY
	|	Ref,
	|	Date
	|TOTALS BY
	|	UseItemsBatch
	|";
	
	RequestByHeader.SetParameter("DocumentsArray", ObjectsArray);
	
	ObjectsTree = RequestByHeader.Execute().Unload(QueryResultIteration.ByGroups);
	
	FirstLineOfObjects = True;  // There can be a maximum of 2 lines in the object tree, this variable is used to 
									// determine that the second line has started to output the border separator
	
	For Each UsingSeries In ObjectsTree.Rows Do
		
		RequestForProducts = New Query;
		RequestForProducts.SetParameter("ObjectsArray", UsingSeries.Rows.UnloadColumn("Ref"));
		
		If UsingSeries.UseItemsBatch Then
			
			QueryTextByGoods = 
			"SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.LineNumber AS LineNumber,
			|	GoodsTable.Products AS Products,
			|	GoodsTable.Characteristic AS Characteristic,
			|	CASE
			|		WHEN GoodsTable.BatchesIndicationStatus IN(10, 14)
			|			THEN GoodsTable.Series
			|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
			|	END AS Series,
			|	GoodsTable.Package AS Package,
			|	GoodsTable.NumberOfPackages AS NumberOfPackages,
			|	GoodsTable.Count AS Count
			|INTO TableOfGoods
			|FROM
			|	Document.InventoryTransfer.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&ObjectsArray)
			|	AND NOT GoodsTable.BatchesIndicationStatus IN (2, 4, 6, 8)
			|
			|UNION ALL
			|
			|SELECT
			|	SeriesTable.Ref,
			|	MIN(GoodsTable.LineNumber),
			|	SeriesTable.Products,
			|	SeriesTable.Characteristic,
			|	SeriesTable.Series,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
			|	SeriesTable.Count,
			|	SeriesTable.Count
			|FROM
			|	Document.InventoryTransfer.SetOfSeries AS SeriesTable
			|		INNER JOIN Document.InventoryTransfer.Goods AS GoodsTable
			|		ON SeriesTable.Ref = GoodsTable.Ref
			|			AND SeriesTable.Products = GoodsTable.Products
			|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
			|WHERE
			|	SeriesTable.Ref IN(&ObjectsArray)
			|
			|GROUP BY
			|	SeriesTable.Ref,
			|	SeriesTable.Products,
			|	SeriesTable.Characteristic,
			|	SeriesTable.Series,
			|	SeriesTable.Count,
			|	SeriesTable.Count
			|
			|HAVING
			|	MAX(GoodsTable.BatchesIndicationStatus) IN (2, 4, 6, 8)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref,
			|	MIN(TableOfGoods.LineNumber) AS LineNumber,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN TableOfGoods.Products.UnitOfMeasure
			|		ELSE TableOfGoods.Package
			|	END AS Package,
			|	SUM(TableOfGoods.NumberOfPackages) AS NumberOfPackages,
			|	SUM(TableOfGoods.Count) AS Count,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END AS Series
			|INTO SummaryTableOfProducts
			|FROM
			|	TableOfGoods AS TableOfGoods
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN TableOfGoods.Products.UnitOfMeasure
			|		ELSE TableOfGoods.Package
			|	END,
			|	CASE
			|		WHEN TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|			THEN NULL
			|		ELSE TableOfGoods.Series
			|	END
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.LineNumber AS LineNumber,
			|	GoodsTable.Products AS OwnGoods,
			|	GoodsTable.Products.DescriptionFull AS ProductItemName,
			|	GoodsTable.Products.Code AS Code,
			|	GoodsTable.Products.SKU AS SKU,
			|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicName,
			|	GoodsTable.Characteristic AS Characteristic,
			|	GoodsTable.Series AS Series,
			|	CASE
			|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
			|		ELSE REFPRESENTATION(GoodsTable.Package)
			|	END AS PresentationOfPackingUnit,
			|	REFPRESENTATION(GoodsTable.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	GoodsTable.NumberOfPackages AS NumberOfPackages,
			|	GoodsTable.Count AS Count,
			|	GoodsTable.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings
			|FROM
			|	SummaryTableOfProducts AS GoodsTable
			|
			|ORDER BY
			|	Ref,
			|	LineNumber,
			|	OwnGoods,
			|	Characteristic
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TableOfGoods.Ref AS Ref,
			|	MIN(TableOfGoods.LineNumber) AS LineNumber,
			|	TableOfGoods.Products AS Products,
			|	TableOfGoods.Characteristic AS Characteristic,
			|	TableOfGoods.Series.Description AS BatchPresentation
			|FROM
			|	TableOfGoods AS TableOfGoods
			|WHERE
			|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
			|	AND NOT TableOfGoods.Series IS NULL 
			|
			|GROUP BY
			|	TableOfGoods.Ref,
			|	TableOfGoods.Products,
			|	TableOfGoods.Characteristic,
			|	TableOfGoods.Series.Description
			|
			|ORDER BY
			|	Ref,
			|	LineNumber,
			|	Products,
			|	Characteristic,
			|	BatchPresentation";
			
			RequestForProducts.Text = QueryTextByGoods;
			QueryResult		 = RequestForProducts.ExecuteBatch();
			ProductSelection_1		 = QueryResult[2].Select(QueryResultIteration.ByGroups);
			SelectionBySeries 		 = QueryResult[3].Select();
			
		Else
			
			QueryTextByGoods = 
			"SELECT
			|	GoodsTable.Ref AS Ref,
			|	GoodsTable.Products AS OwnGoods,
			|	GoodsTable.Products.DescriptionFull AS ProductItemName,
			|	GoodsTable.Products.Code AS Code,
			|	GoodsTable.Products.SKU AS SKU,
			|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicName,
			|	GoodsTable.Characteristic AS Characteristic,
			|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
			|	CASE
			|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
			|			THEN REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
			|		ELSE REFPRESENTATION(GoodsTable.Package)
			|	END AS PresentationOfPackingUnit,
			|	REFPRESENTATION(GoodsTable.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
			|	GoodsTable.NumberOfPackages AS NumberOfPackages,
			|	GoodsTable.Count AS Count,
			|	FALSE AS BatchUsageSettings,
			|	GoodsTable.LineNumber
			|FROM
			|	Document.InventoryTransfer.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN(&ObjectsArray)
			|
			|ORDER BY
			|	Ref,
			|	GoodsTable.LineNumber,
			|	OwnGoods,
			|	Characteristic";
			
			RequestForProducts.Text = QueryTextByGoods;
			ProductSelection_1 = RequestForProducts.Execute().Select();
			
		EndIf;
				
		FirstDocument = True;

		For Each Header In UsingSeries.Rows Do
			
			RowNumberStart = SpreadsheetDocument.TableHeight + 1;
			If Not FirstDocument Or (FirstDocument And Not FirstLineOfObjects) Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			FirstDocument = False;
			
			// We display the header of the invoice
			If Header.BusinessOperation = Enums.BusinessTransactions.InventoryTransfer Then

				TitleArea  = HeaderAreaMove;

			Else //The hat.Business Operation = Transfers.Economic operations.Movementetovaroves betweenfilials

				TitleArea = HeaderAreaInternalTransfer;

			EndIf;

			DocumentName_1 = NStr("vi = 'Phiếu điều chuyển hàng hóa';
									|ru = 'Накладная на перемещение';
									|en = 'Goods transfer'; fa = 'انتقال کالا';
									|it = 'Bolla per trasferimento';
									|pl = 'Faktura na przemieszczenie';
									|tr = 'Taşıma için irsaliye'", Common.DefaultLanguageCode());
			TitleArea.Parameters.Fill(Header);
			AreaParameters_ = New Structure;
			AreaParameters_.Insert("TitleText", 
									TMCommonUseClientServer.GenerateDocumentTitle(Header,
									DocumentName_1));
			NamesAsOfDate = CompaniesCached.NamesAsOfDate(Header.Organization, Header.Date);
			AreaParameters_.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
			NamesAsOfDate = CompaniesCached.NamesAsOfDate(Header.CompanyRecipient, Header.Date);
			AreaParameters_.Insert("CompanyRecipientPresentation", NamesAsOfDate.AbbreviatedDescription);
			TitleArea.Parameters.Fill(AreaParameters_);
			
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TitleArea, Header.Ref);
			SpreadsheetDocument.Put(TitleArea);
			
			SpreadsheetDocument.Put(AreaOfHeaderNumber);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodesHeader);
			EndIf;
			
			SpreadsheetDocument.Join(HeaderDataArea);
			
			If UseItemPackages Then
				SpreadsheetDocument.Join(PackagingAreaHeader);
			EndIf;
			
			SpreadsheetDocument.Join(AreaEndOfLineHeader);
			
			// The sample of goods
			
			LineNumber = 1;
			
			While ProductSelection_1.FindNext(New Structure("Ref",Header.Ref)) Do
				
				NumberAreaLine.Parameters.LineNumber = LineNumber;
				SpreadsheetDocument.Put(NumberAreaLine);
				
				If OutputCodes Then
					AreaCodesString.Parameters.SKU = ProductSelection_1[NameOfCodeColumn];
					SpreadsheetDocument.Join(AreaCodesString);
				EndIf;
				
				If ProductSelection_1.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
					
					TheStructureOfTheSearch = New Structure;
					TheStructureOfTheSearch.Insert("Ref", ProductSelection_1.Ref);
					TheStructureOfTheSearch.Insert("LineNumber", ProductSelection_1.LineNumber);
					TheStructureOfTheSearch.Insert("Products", ProductSelection_1.OwnGoods);
					TheStructureOfTheSearch.Insert("Characteristic", ProductSelection_1.Characteristic);
					
					SeriesString = "";
					While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
						SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
					EndDo;
					
					If StrLen(SeriesString) <> 0 Then
						SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
					EndIf;
					
				Else
					
					SeriesString = ProductSelection_1.Series;
					
				EndIf;
				
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				DataAreaRow.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					TrimAll(ProductSelection_1.ProductItemName),
					TrimAll(ProductSelection_1.CharacteristicName),
					, // Package
					TrimAll(SeriesString),
					AdditionalParametersProductPresentation);
				
				SpreadsheetDocument.Join(DataAreaRow);
				
				If UseItemPackages Then
					PackagingAreaString.Parameters.Fill(ProductSelection_1);
					SpreadsheetDocument.Join(PackagingAreaString);
				EndIf;
				
				AreaEndOfLineString.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Join(AreaEndOfLineString);
				
				LineNumber = LineNumber + 1;
								
			EndDo;
			
			
			SpreadsheetDocument.Put(RoomAreaBasement);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodesBasement);
			EndIf;
			
			SpreadsheetDocument.Join(DataAreaBasement);
			
			If UseItemPackages Then
				SpreadsheetDocument.Join(PackingAreaBasement);
			EndIf;
			
			SpreadsheetDocument.Join(AreaEndOfLineBasement);
			
			// Print signatures.
			SpreadsheetDocument.Put(SignatureArea);
			
			PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, Header.Ref);
			
		EndDo;
		
		FirstLineOfObjects = False;
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;

EndFunction

Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25() Then
		
		Return;
		
	EndIf;
	
	PrintObjectDataStructure.PrimaryRecipient = "CarrierPartner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("CarrierPartner");
	
EndProcedure

#EndRegion

#Region Private

#Region Companies

Procedure CheckAndClearOrganization(Object, Organization) Export
	
	If ValueIsFilled(Organization)
			And Object.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
		
		If Not Catalogs.Companies.OrganizationIsInterconnectedWithOtherOrganizations(Organization) Then
			Organization = Undefined;
		ElsIf ValueIsFilled(Object.Organization)
					And ValueIsFilled(Object.CompanyRecipient)
					And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Object.Organization, Object.CompanyRecipient) Then
			Organization = Undefined;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region FillingInDocument_

Procedure RequestParametersToCreateBasedOn(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", True);
	
	If SelectionData_.FillByWarehouseDocument Then
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TableShipped");
		
		QueryNames.Add("TableOfContents_");
		SubqueryNames.Add("BlockRegisterOrders");
		
	Else
		
		QueryNames.Add("TTOrdersSelection");
		
		QueryNames.Add("TableOfContents_");
		SubqueryNames.Add("BlockRegisterOrders");
		
	EndIf;
	
EndProcedure

Procedure QueryParametersForMatching(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", SelectionData_.AnArrayOfOrders.Count() = 1);
	QueryParameters.Insert("Recorder",      SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("Organization",      SelectionData_.HeaderAttributes.Organization);
	QueryParameters.Insert("SourceWarehouse", SelectionData_.HeaderAttributes.SourceWarehouse);
	QueryParameters.Insert("DestinationWarehouse",  SelectionData_.HeaderAttributes.DestinationWarehouse);
	QueryParameters.Insert("InvoiceGoods",  SelectionData_.InvoiceGoods);
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", True);
	
	QueryNames.Add("TTOrdersSelection");
	QueryNames.Add("TTInvoice");
	QueryNames.Add("TableShipped");
	
	QueryNames.Add("TableOfContents_");
	SubqueryNames.Add("BlockRegisterOrders");
	SubqueryNames.Add("StornoInvoiceBlock");
	SubqueryNames.Add("BlockNewRegisteredRecordsInvoice");
	
EndProcedure

Procedure RequestParametersForOrderReplenishment(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", True);
	QueryParameters.Insert("Recorder",      SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("InvoiceGoods",  SelectionData_.InvoiceGoods);
	QueryParameters.Insert("ItIsGoingToTakeIntoAccount", True);
	QueryParameters.Insert("FillInAsNeeded", True);
	
	QueryNames.Add("TTOrdersSelection");
	QueryNames.Add("TTInvoice");
	QueryNames.Add("TableShipped");
	
	QueryNames.Add("TableOfContents_");
	SubqueryNames.Add("BlockRegisterOrders");
	SubqueryNames.Add("StornoInvoiceBlock");
	SubqueryNames.Add("BlockNewRegisteredRecordsInvoice");
	
EndProcedure

Procedure RequestParametersToFillInForOrders(QueryParameters, QueryNames, SubqueryNames, SelectionData_)
	
	QueryParameters.Insert("AnArrayOfOrders",    SelectionData_.AnArrayOfOrders);
	QueryParameters.Insert("SelectByOrder_", SelectionData_.AnArrayOfOrders.Count() = 1);
	QueryParameters.Insert("Recorder",      SelectionData_.HeaderAttributes.Ref);
	QueryParameters.Insert("Organization",      SelectionData_.HeaderAttributes.Organization);
	QueryParameters.Insert("SourceWarehouse", SelectionData_.HeaderAttributes.SourceWarehouse);
	QueryParameters.Insert("DestinationWarehouse",  SelectionData_.HeaderAttributes.DestinationWarehouse);
	
	If SelectionData_.FillByWarehouseDocument Then
		
		QueryNames.Add("TTOrdersSelection");
		QueryNames.Add("TableShipped");
		
		QueryNames.Add("TableOfContents_");
		SubqueryNames.Add("BlockRegisterOrders");
		SubqueryNames.Add("StornoInvoiceBlock");
		
	Else
		
		QueryNames.Add("TTOrdersSelection");
		
		QueryNames.Add("TableOfContents_");
		SubqueryNames.Add("BlockRegisterOrders");
		SubqueryNames.Add("StornoInvoiceBlock");
		
	EndIf;
	
EndProcedure

Function RequestTextForTemporaryInvoiceTable()
	
	QueryText =
		"SELECT
		|	Table.Count            AS Count,
		|
		|	Table.LineNumber           AS LineNumber,
		|	Table.Products          AS Products,
		|	Table.Characteristic        AS Characteristic,
		|	Table.ProductsInSet    AS ProductsInSet,
		|	Table.ItemVariantOfSet  AS ItemVariantOfSet,
		|	Table.AssignmentSender AS AssignmentSender,
		|	Table.Purpose            AS Purpose,
		|	Table.Series                 AS Series,
		|	Table.SalesOpportunity                AS SalesOpportunity,
		|
		|	Table.RowCode             AS RowCode,
		|	Table.Package              AS Package,
		|
		|	CASE WHEN Table.RowCode = 0 THEN
		|				&Recorder
		|			ELSE
		|				Table.TransferOrder
		|		END                     AS OrderDocument
		|
		|INTO TTInvoice
		|FROM
		|	&InvoiceGoods AS Table
		|;
		|
		|//////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function QueryTextOfTemporaryOrderTable()
	
	QueryText =
		"SELECT
		|	TransferOrder.Ref AS OrderDocument
		|INTO TTOrdersSelection
		|FROM
		|	Document.TransferOrder AS TransferOrder
		|WHERE
		|	CASE
		|		WHEN &SelectByOrder_ THEN
		|			TransferOrder.Ref IN (&AnArrayOfOrders)
		|		ELSE TransferOrder.Organization      = &Organization
		|			AND TransferOrder.SourceWarehouse = &SourceWarehouse
		|			AND TransferOrder.DestinationWarehouse  = &DestinationWarehouse
		|	END
		|	AND TransferOrder.Posted
		|
		|UNION ALL
		|
		|SELECT
		|	&Recorder AS OrderDocument
		|;
		|
		|//////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function MergeRequestText(Names, Texts)
	
	MergeText = "";
	ThisIsFirstBlock = True;
	
	For Each Name In Names Do
		
		If ThisIsFirstBlock Then
			ThisIsFirstBlock = False;
		Else
			
			MergeText = MergeText + "
			                                      |
			                                      |	UNION ALL
			                                      |
			                                      |";
			
		EndIf;
		
		MergeText = MergeText + Texts[Name];
		
	EndDo;
	
	QueryText =
		"SELECT
		|	Set.OrderDocument             AS TransferOrder,
		|	Set.RowCode         AS RowCode,
		|
		|	Set.Products          AS Products,
		|	Set.Characteristic        AS Characteristic,
		|	MAX(Set.AssignmentSender) AS AssignmentSender,
		|	MAX(Set.Purpose)            AS Purpose,
		|	Set.Series                 AS Series,
		|	MAX(Set.Date)                  AS Date,
		|	MAX(Set.LineNumber)           AS LineNumber,
		|	MAX(Set.DateOfShipment)          AS DateOfShipment,
		|	MAX(Set.SalesOpportunity)                AS SalesOpportunity,
		|	MAX(Set.ExistsInTheDocument) AS ExistsInTheDocument,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				Set.Package
		|			ELSE
		|				UNDEFINED
		|		END)                             AS PackingOfConsignmentNote,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				UNDEFINED
		|			ELSE
		|				Set.Package
		|		END)                             AS OrderPackage,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				Set.PackageFactor
		|			ELSE
		|				UNDEFINED
		|		END)                             AS PackingOfConsignmentNote_,
		|
		|	MAX(CASE WHEN Set.ExistsInTheDocument THEN
		|				UNDEFINED
		|			ELSE
		|				Set.PackageFactor
		|		END)                             AS OrderPackingRatio,
		|
		|
		|	SUM(Set.QuantityInOrder)        AS QuantityInOrder,
		|	SUM(Set.QuantityInInvoice)     AS QuantityInInvoice
		|
		|FROM MergeText AS Set
		|
		|GROUP BY
		|	Set.OrderDocument, Set.RowCode,
		|	Set.Products, Set.Characteristic, Set.Series,
		|	CASE WHEN Set.RowCode <> 0 THEN
		|				0
		|			ELSE
		|				Set.LineNumber
		|		END
		|
		|HAVING
		|	SUM(Set.QuantityInOrder) > 0 OR SUM(Set.QuantityInInvoice) > 0
		|
		|ORDER BY
		|	Date, OrderDocument, LineNumber
		|;
		|
		|/////////////////////////////////////////////////////////////////////
		|";
	
	QueryText = StrReplace(QueryText, "MergeText", "(" + MergeText + ")");
	Return QueryText;
	
EndFunction

Function RequestTextUpperCaseOrders()
	
	QueryText =
		"	SELECT
		|		TableBalance.TransferOrder AS OrderDocument,
		|		TableBalance.RowCode          AS RowCode,
		|
		|		TableBalance.ToRegisterBalance AS QuantityInOrder,
		|		0                                 AS QuantityInInvoice,
		|
		|		// Background information.
		|		Table.Products         AS Products,
		|		Table.Characteristic       AS Characteristic,
		|		Table.ProductsInSet   AS ProductsInSet,
		|		Table.ItemVariantOfSet AS ItemVariantOfSet,
		|
		|		CASE WHEN Table.WithAssignment THEN
		|			
		|				CASE WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|								OR DocumentData.AssignByOrderAssignment AND Table.Purpose.AssignmentType
		|									= VALUE(Enum.AssignmentTypes.Own) THEN
		|							DocumentData.Purpose
		|						ELSE
		|							Table.Purpose
		|					END
		|			
		|				ELSE
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			
		|			END                   AS AssignmentSender,
		|
		|		Table.Purpose          AS Purpose,
		|		Table.Series               AS Series,
		|		DocumentData.Date        AS Date,
		|		Table.LineNumber         AS LineNumber,
		|		Table.ShipmentStart      AS DateOfShipment,
		|		DocumentData.SalesOpportunity      AS SalesOpportunity,
		|		FALSE                        AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		AccumulationRegister.TransferOrders.Balance(,
		|				TransferOrder IN(
		|					SELECT
		|						Table.OrderDocument AS OrderDocument
		|					FROM
		|						TTOrdersSelection AS Table)) AS TableBalance
		|
		|			INNER JOIN Document.TransferOrder.Goods AS Table
		|			ON TableBalance.TransferOrder = Table.Ref
		|			 AND TableBalance.RowCode = Table.RowCode
		|	
		|			INNER JOIN Document.TransferOrder AS DocumentData
		|			ON TableBalance.TransferOrder = DocumentData.Ref";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Return QueryText;
	
EndFunction

Function RequestTextShippedByOrders()
	
	QueryText =
		"SELECT
		|	TableBalance.DocumentShipments       AS TransferOrder,
		|	TableBalance.Products           AS Products,
		|	TableBalance.Characteristic         AS Characteristic,
		|	TableBalance.Series                  AS Series,
		|	TableBalance.Purpose             AS AssignmentSender,
		|	1                                     AS PackageFactor,
		|	
		|	SUM(CASE WHEN TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|		END)                            AS AssemblyInProgress,
		|	
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &FillInAsNeeded AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled)         AS Count
		|FROM
		|	TTOrdersSelection AS Table
		|		INNER JOIN AccumulationRegister.GoodsForIssue AS TableBalance
		|		ON Table.OrderDocument = TableBalance.DocumentShipments
		|		 AND TableBalance.Active
		|
		|GROUP BY
		|	TableBalance.DocumentShipments,
		|	TableBalance.Products, TableBalance.Characteristic, TableBalance.Series, TableBalance.Purpose
		|
		|HAVING
		|	SUM(CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) THEN
		|					TableBalance.ToShip
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN TableBalance.RecordType = VALUE(AccumulationRecordType.Expense) AND TableBalance.Recorder <> &Recorder THEN
		|					- TableBalance.ToRegister
		|				ELSE
		|					0
		|			END
		|		+ CASE WHEN &ItIsGoingToTakeIntoAccount AND TableBalance.DocumentShipments = &Recorder THEN
		|					TableBalance.AssemblyInProgress
		|				ELSE
		|					0
		|			END
		|		+ TableBalance.Assembled) > 0
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextInvoice()
	
	QueryText =
		"	SELECT
		|		TableStorno.TransferOrder AS OrderDocument,
		|		TableStorno.RowCode          AS RowCode,
		|
		|		TableStorno.ToRegister        AS QuantityInOrder,
		|		0                                AS QuantityInInvoice,
		|
		|		// Background information.
		|		TableStorno.Products       AS Products,
		|		TableStorno.Characteristic     AS Characteristic,
		|		Table.ProductsInSet       AS ProductsInSet,
		|		Table.ItemVariantOfSet     AS ItemVariantOfSet,
		|
		|		CASE WHEN Table.WithAssignment THEN
		|			
		|					CASE WHEN Table.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
		|								Table.Ref.Purpose
		|							ELSE
		|								Table.Purpose
		|						END
		|			
		|				ELSE
		|					VALUE(Catalog.Assignments.EmptyRef)
		|			
		|			END                        AS AssignmentSender,
		|
		|		Table.Purpose               AS Purpose,
		|		Table.Series                    AS Series,
		|		DocumentData.Date             AS Date,
		|		Table.LineNumber              AS LineNumber,
		|		Table.ShipmentStart           AS DateOfShipment,
		|		DocumentData.SalesOpportunity           AS SalesOpportunity,
		|		FALSE                             AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		AccumulationRegister.TransferOrders AS TableStorno
		|
		|			INNER JOIN Document.TransferOrder.Goods AS Table
		|			ON Table.Ref = TableStorno.TransferOrder
		|			 AND Table.RowCode = TableStorno.RowCode
		|
		|			INNER JOIN Document.TransferOrder AS DocumentData
		|			ON TableStorno.TransferOrder = DocumentData.Ref
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|		AND TableStorno.TransferOrder IN(
		|			SELECT
		|				Table.OrderDocument AS OrderDocument
		|			FROM
		|				TTOrdersSelection AS Table)
		|		AND TableStorno.Active";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	Return QueryText;
	
EndFunction

Function RequestTextNewTrafficInvoice()
	
	QueryText =
		"	SELECT
		|		Table.OrderDocument       AS OrderDocument,
		|		Table.RowCode   AS RowCode,
		|		0                   AS QuantityInOrder,
		|		Table.Count  AS QuantityInInvoice,
		|
		|		// Background information.
		|		Table.Products          AS Products,
		|		Table.Characteristic        AS Characteristic,
		|		Table.ProductsInSet    AS ProductsInSet,
		|		Table.ItemVariantOfSet  AS ItemVariantOfSet,
		|		Table.AssignmentSender AS AssignmentSender,
		|		Table.Purpose            AS Purpose,
		|		Table.Series                 AS Series,
		|		UNDEFINED                  AS Date,
		|		Table.LineNumber           AS LineNumber,
		|		UNDEFINED                  AS DateOfShipment,
		|		Table.SalesOpportunity                AS SalesOpportunity,
		|		TRUE                        AS ExistsInTheDocument,
		|
		|		Table.Package                          AS Package,
		|		ISNULL(&QueryTextPackagingFactor, 1) AS PackageFactor
		|	FROM
		|		TTInvoice AS Table";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure)",
			"CAST(Table.Products AS Catalog.Products)"));
	Return QueryText;
	
EndFunction

Function ParametersForCreatingWarehousesByGroup(CommandParameter) Export
	
	Query = New Query();
	
	If TypeOf(CommandParameter) = Type("DocumentRef.VendorInvoice") Then
		
		Query.Text =
		"SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Warehouse.Description AS Description
		|FROM
		|	Document.VendorInvoice.Goods AS Goods
		|WHERE
		|	Goods.Ref = &OrderDocument
		|	AND Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))
		|	AND NOT Goods.ToExpenseAs
		|ORDER BY
		|	Description";
		
	ElsIf TypeOf(CommandParameter) = Type("DocumentRef.GoodsReceiptForStorage") Then
		
		Query.Text =
		"SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse
		|FROM
		|	Document.GoodsReceiptForStorage.Goods AS Goods
		|WHERE
		|	Goods.Ref = &OrderDocument
		|	AND Goods.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage))";
		
	ElsIf TypeOf(CommandParameter) = Type("DocumentRef.GoodsQualityControlCertificate") Then
		
		Query.Text =
		"SELECT ALLOWED DISTINCT
		|	Goods.Warehouse.Ref AS Warehouse
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &OrderDocument
		|	AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer)";
		
	EndIf;
	
	Query.SetParameter("OrderDocument", CommandParameter);
	Warehouses = Query.Execute().Unload().UnloadColumn("Warehouse");
	
	MultipleWarehouses = False;
	If Warehouses.Count() > 1 Then
		MultipleWarehouses = True;
	ElsIf Warehouses.Count() = 0 Then
		If TypeOf(CommandParameter) = Type("DocumentRef.GoodsQualityControlCertificate") Then
			Warehouses.Add(Catalogs.Warehouses.EmptyRef()); // goods will not be filled in during the processing of filling in the document, a message will be issued about the absence of lines with the necessary action
		Else
			Warehouses.Add(Undefined); // during the processing of filling out the document, goods will not be filled in.
		EndIf;
	EndIf;
	
	ParametersForCreatingWarehousesByGroup = New Structure();
	ParametersForCreatingWarehousesByGroup.Insert("WarehousesList",    Warehouses);
	ParametersForCreatingWarehousesByGroup.Insert("MultipleWarehouses", MultipleWarehouses);
	
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

// This function defines the details of the selected product movement.
//
// Parameters:
//  DocumentRef - DocumentRef.InventoryTransfer - link to the document.
//
// Returns:
//	Structure - details of the movement of goods.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.InventoryTransfer AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
	Else
		Date = Date(1,1,1);
		Organization = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure("Date, Organization",
		Date,
		Organization,);
	
	Return AttributesStructure1;

EndFunction

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.InventoryTransfer))
		And (AccessRight("Insert", Metadata.Documents.InventoryTransfer)
			Or AccessRight("Update", Metadata.Documents.InventoryTransfer))
		And AccessRight("View",   Metadata.Documents.TransferOrder)
		And AccessRight("Read",     Metadata.AccumulationRegisters.TransferOrders)
		And GetFunctionalOption("UseTransferOrders");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	BsnsTransactions = New Array(2);
	BsnsTransactions[0] = Enums.BusinessTransactions.InventoryTransfer;
	BsnsTransactions[1] = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices;
	
	MovementOfGoodsGoodsForRegistration = DataProcessors.LogOfInternalDocuments.NumberOfLinesForLayout(
		BsnsTransactions);
	
	// Filling out cases.
	// Internal Movement
	UserTaskParent = ToDoList.Find("InternalInventoryTransfers", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id  = "InternalInventoryTransfers";
		UserTaskParent.Presentation  = NStr("vi = 'Điều chuyển hàng hóa nội bộ';
											|ru = 'Внутреннее товародвижение';
											|en = 'Internal inventory transfers'; fa = 'انتقالات داخلی موجودی';
											|it = 'Flusso di prodotti interno';
											|pl = 'Wewnętrzny ruch towarów';
											|tr = 'Dahili stok transferleri'");
		UserTaskParent.Owner       = Metadata.Subsystems.Warehouse;
	EndIf;
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or MovementOfGoodsGoodsForRegistration > 0;
	
	OpeningParameters = ParametersForOpeningWorkplaceForm();
	OpeningParameters.FormParameters.Insert("FormAssignmentKey", "ToDoList");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "TransfersOfGoodsToRegister";
	ToDoItem.HasToDoItems       = MovementOfGoodsGoodsForRegistration > 0;
	ToDoItem.Presentation  = NStr("vi = 'Chuẩn bị điều chuyển hàng hóa';
									|ru = 'Перемещения товаров к оформлению';
									|en = 'Transfers of goods to register'; fa = 'Transfers of goods to register';
									|it = 'Trasferimenti delle merci da formalizzare';
									|pl = 'Przenoszenie towarów do rejestracji';
									|tr = 'Düzenlenecek mal transferi'");
	ToDoItem.Count     = MovementOfGoodsGoodsForRegistration;
	ToDoItem.Important         = False;
	ToDoItem.Form          = OpeningParameters.FormName;
	ToDoItem.FormParameters = OpeningParameters.FormParameters;
	ToDoItem.Owner       = "InternalInventoryTransfers";
	
EndProcedure

#EndRegion

#Region ImportDataFromFile

// Overrides the parameters for loading data from a file.
//
// Parameters:
//  Parameters - Structure:
//   * DataStructureTemplateName - String - the name of the layout. For example, "Uploading a file".
//   * TabularSectionName - String - The full name of the table part. For example, "Document._account to the payer.The table is missing.Products"
//   * RequiredColumns2 - Array of String - names of required columns.
//   * ColumnDataType - Map of KeyAndValue:
//      * Key - String - column name;
//      * Value - TypeDescription - the type of the column of uploaded data.
//   * AdditionalParameters - Structure
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
    
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
//
// Parameters:
//   AddressOfUploadedData - String - the address of the temporary storage with the table of values in which the downloaded data from the file is located. 
//   							Composition of columns: 
//     								ID - Number - sequence number of the line;
//     								The remaining columns correspond to the columns of the File Upload Template.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values, which is a copy of the tabular part of the document, 
//                                        which must be filled in from the Addressable data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//   							Composition of columns: 
//       							* Column - String - name of the column where the ambiguity was detected;
//       							* Id - Number - ID of the string where the ambiguity was detected.
//   FullTabularSectionName - String - full name of the table part where data is loaded.
//   AdditionalParameters - Arbitrary - Any additional information.
//
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export

	QueryText =
	"SELECT
	|	DataToImport.Id AS Id,
	|	DataToImport.ProductsAndServicesCode AS ProductsAndServicesCode,
	|	DataToImport.SKU AS ProductIDOfItems,
	|	DataToImport.Products AS Products,
	|	DataToImport.Characteristic AS Characteristic,
	|	DataToImport.Purpose AS Purpose,
	|	DataToImport.Series AS Series,
	|	DataToImport.PackageCode AS PackageCode,
	|	DataToImport.Package AS Package,
	|	DataToImport.NumberOfPackages AS NumberOfPackages
	|
	|INTO TTDownloadableData
	|
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatProducts.Ref) AS Ref,
	|	COUNT(CatProducts.Ref) AS Count
	|
	|INTO TTProductsByArticle
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.SKU = DataToImport.ProductIDOfItems
	|			AND NOT CatProducts.DeletionMark
	|			AND NOT CatProducts.IsFolder
	|
	|WHERE
	|	DataToImport.ProductIDOfItems <> """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatProducts.Ref) AS Ref,
	|	COUNT(CatProducts.Ref) AS Count
	|
	|INTO TTProductListByCode
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
	|			AND NOT CatProducts.DeletionMark
	|			AND NOT CatProducts.IsFolder
	|
	|WHERE
	|	DataToImport.ProductsAndServicesCode <> """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	MAX(CatProducts.Ref) AS Ref,
	|	COUNT(CatProducts.Ref) AS Count
	|
	|INTO TTProductListByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Description = DataToImport.Products
	|			AND NOT CatProducts.DeletionMark
	|			AND NOT CatProducts.IsFolder
	|
	|WHERE
	|	DataToImport.Products <> """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	CatCharacteristics.Owner AS Owner,
	|	MAX(CatCharacteristics.Ref) AS Ref,
	|	COUNT(CatCharacteristics.Ref) AS Count
	|
	|INTO TTSpecificationsByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ItemsCharacteristics AS CatCharacteristics
	|		ON CatCharacteristics.Description = DataToImport.Characteristic
	|			AND NOT CatCharacteristics.DeletionMark
	|
	|WHERE
	|	DataToImport.Characteristic <> """"
	|
	|GROUP BY
	|	DataToImport.Id,
	|	CatCharacteristics.Owner
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	CatSetOfSeries.ProductKind AS ProductKind,
	|	MAX(CatSetOfSeries.Ref) AS Ref,
	|	COUNT(CatSetOfSeries.Ref) AS Count
	|
	|INTO TTSeriesByName
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ItemsBatches AS CatSetOfSeries
	|		ON CatSetOfSeries.Description = DataToImport.Series
	|			AND NOT CatSetOfSeries.DeletionMark
	|
	|WHERE
	|	DataToImport.Series <> """"
	|
	|GROUP BY
	|	DataToImport.Id,
	|	CatSetOfSeries.ProductKind
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|
	|	CASE
	|		WHEN NOT TTProductListByName.Id IS NULL
	|
	|			THEN TTProductListByName.Ref
	|
	|		WHEN NOT TTProductsByArticle.Id IS NULL
	|
	|			THEN TTProductsByArticle.Ref
	|
	|		WHEN NOT TTProductListByCode.Id IS NULL
	|
	|			THEN TTProductListByCode.Ref
	|
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|
	|	END AS Ref
	|
	|INTO TTFoundProduct
	| 
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		LEFT JOIN TTProductsByArticle AS TTProductsByArticle
	|		ON TTProductsByArticle.Id = DataToImport.Id
	|
	|		LEFT JOIN TTProductListByCode AS TTProductListByCode
	|		ON TTProductListByCode.Id = DataToImport.Id
	|
	|		LEFT JOIN TTProductListByName AS TTProductListByName
	|		ON TTProductListByName.Id = DataToImport.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	TTSpecificationsByName.Ref AS Ref
	|
	|INTO TTFoundCharacteristic
	| 
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		INNER JOIN TTFoundProduct AS TTFoundProduct
	|		ON TTFoundProduct.Id = DataToImport.Id
	|
	|		INNER JOIN TTSpecificationsByName AS TTSpecificationsByName
	|		ON TTSpecificationsByName.Id = DataToImport.Id
	|			AND (TTSpecificationsByName.Owner = TTFoundProduct.Ref
	|				OR TTSpecificationsByName.Owner = TTFoundProduct.Ref.ProductKind)
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataToImport.Id AS Id,
	|	TTSeriesByName.Ref AS Ref
	|
	|INTO TTFoundSeries
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		INNER JOIN TTFoundProduct AS TTFoundProduct
	|		ON TTFoundProduct.Id = DataToImport.Id
	|
	|		INNER JOIN TTSeriesByName AS TTSeriesByName
	|		ON TTSeriesByName.Id = DataToImport.Id
	|			AND (TTSeriesByName.ProductKind = CASE
	|				WHEN TTFoundProduct.Ref.ProductKind.BatchSettingsAreTakenFromOtherItemsKind
	|					THEN TTFoundProduct.Ref.ProductKind.BatchOwner
	|				ELSE TTFoundProduct.Ref.ProductKind
	|				END)
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Assignments.Id                    AS Id,
	|	MAX(Assignments.Purpose)             AS Purpose,
	|	COUNT(DISTINCT Assignments.Purpose) AS NumberOfAppointments
	|INTO TTFoundDestination
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Assignments.Ref               AS Purpose
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON Assignments.Description = DataToImport.Purpose
	|
	|	WHERE
	|		NOT DataToImport.Purpose = """"
	|	) AS Assignments
	|
	|GROUP BY
	|	Assignments.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Packages.Id                  AS Id,
	|	MAX(Packages.Package)             AS Package,
	|	COUNT(DISTINCT Packages.Package) AS PackingQuantity
	|INTO TTPackagesFound
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTFoundProduct AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Ref
	|		AND Packages.Description = DataToImport.Package
	|
	|	WHERE
	|		NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTFoundProduct AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Ref.PackagingGroup
	|		AND Packages.Description = DataToImport.Package
	|
	|	WHERE
	|		NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTFoundProduct AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Ref
	|		AND Packages.Code = DataToImport.PackageCode
	|
	|	WHERE
	|		NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTFoundProduct AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Ref.PackagingGroup
	|		AND Packages.Code = DataToImport.PackageCode
	|
	|	WHERE
	|		NOT DataToImport.PackageCode = """"
	|	) AS Packages
	|
	|GROUP BY
	|	Packages.Id
	|
	|INDEX BY
	|	Id
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|
	|	ISNULL(TTFoundProduct.Ref, VALUE(Catalog.Products.EmptyRef)) AS Products,
	|	ISNULL(TTFoundCharacteristic.Ref, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS Characteristic,
	|	ISNULL(TTFoundSeries.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	CASE
	|		WHEN ISNULL(TTFoundDestination.NumberOfAppointments, 0) = 1
	|			THEN TTFoundDestination.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	ISNULL(TTFoundDestination.NumberOfAppointments, 0) AS NumberOfAppointments,
	|	CASE
	|		WHEN ISNULL(TTPackagesFound.PackingQuantity, 0) = 1
	|			THEN TTPackagesFound.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	ISNULL(TTPackagesFound.PackingQuantity, 0) AS PackingQuantity,
	|	DataToImport.NumberOfPackages AS NumberOfPackages
	|
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|		LEFT JOIN TTFoundProduct AS TTFoundProduct
	|		ON TTFoundProduct.Id = DataToImport.Id
	|
	|		LEFT JOIN TTFoundCharacteristic AS TTFoundCharacteristic
	|		ON TTFoundCharacteristic.Id = DataToImport.Id
	|
	|		LEFT JOIN TTFoundSeries AS TTFoundSeries
	|		ON TTFoundSeries.Id = DataToImport.Id
	|
	|		LEFT JOIN TTFoundDestination AS TTFoundDestination
	|		ON TTFoundDestination.Id = DataToImport.Id
	|
	|		LEFT JOIN TTPackagesFound AS TTPackagesFound
	|		ON TTPackagesFound.Id = DataToImport.Id
	|";
	
	GoodsTable = GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData); // ValueTable
	
	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("DataToImport", DataToImport);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = GoodsTable.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.NumberOfAppointments > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Purpose";
		EndIf;
		
		If Selection.PackingQuantity > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Package";
		EndIf;

	EndDo;
	
	PutToTempStorage(GoodsTable, AddressOfMappingTable);

EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
// 	FullTabularSectionName- String - full name of the table part where data is loaded.
// 	ConflictsList - Array - list of ambiguities.
// 	ColumnName - String - name of the column where the ambiguity occurs.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	Query = New Query;
	
	If ColumnName = "Purpose" Then
		
		Query.Text =
		"SELECT
		|	Assignments.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS Assignments
		|
		|WHERE
		|	NOT &Purpose = """"
		|	AND Assignments.Description = &Purpose
		|";
		
		Query.SetParameter("Purpose", LoadedValuesString.Purpose);
		
	EndIf;
	
	If ColumnName = "Package" Then
		
		Query.Text =
		"SELECT
		|	Packages.Ref AS Ref
		|FROM
		|	(SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &PackageCode = """"
		|		AND Packages.Code = &PackageCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &Package = """"
		|		AND Packages.Description = &Package
		|	) AS Packages
		|
		|GROUP BY
		|	Packages.Ref
		|";
		
		Query.SetParameter("PackageCode", LoadedValuesString.PackageCode);
		Query.SetParameter("Package",    LoadedValuesString.Package);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region DocumentExecutionStateReport

Function TemporaryGoodsReceiptTableForProgressStateReport()
	
	QueryText = "
		|SELECT ALLOWED
		|	Set.DocumentInflow AS DocumentInflow,
		|	Set.Products        AS Products,
		|	Set.Characteristic      AS Characteristic,
		|	Set.Warehouse               AS Warehouse,
		|
		|	FALSE                      AS SeparatePurchase,
		|
		|	SUM(Set.Accepts)  AS Accepts,
		|	SUM(Set.Accepted)      AS Accepted,
		|	SUM(Set.Accept)      AS Accept,
		|	SUM(Set.Received)    AS Received,
		|
		|	SUM(Set.ToReceive) AS ToReceive,
		|	SUM(Set.ApplyAppearance)     AS ApplyAppearance,
		|	SUM(Set.Issued_1)    AS Issued_1,
		|
		|	MAX(Set.AdvancedWarehousingOnGoodsReceipt) AS AdvancedWarehousingOnGoodsReceipt
		|
		|INTO TTGoodsArrival
		|FROM(
		|	SELECT
		|		GoodsToReceive.DocumentInflow AS DocumentInflow,
		|		GoodsToReceive.Products        AS Products,
		|		GoodsToReceive.Characteristic      AS Characteristic,
		|		GoodsToReceive.Warehouse               AS Warehouse,
		|
		|		GoodsToReceive.AcceptsClosingBalance  AS Accepts,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense          AS Accepted,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterClosingBalance AS Accept,
		|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense          AS Received,
		|
		|		0                                              AS ToReceive,
		|		0                                              AS ApplyAppearance,
		|		0                                              AS Issued_1,
		|
		|		CASE WHEN GoodsToReceive.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsToReceive.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|	FROM
		|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers( , , , ,
		|				DocumentInflow IN(
		|					SELECT
		|						TTDocuments.DocumentRef
		|					FROM
		|						TTDocuments AS TTDocuments)) AS GoodsToReceive
		|
		|	UNION ALL
		|
		|	SELECT
		|		GoodsForRegistration.Ref             AS DocumentInflow,
		|		GoodsForRegistration.Products       AS Products,
		|		GoodsForRegistration.Characteristic     AS Characteristic,
		|		GoodsForRegistration.Ref.DestinationWarehouse AS Warehouse,
		|
		|		0                                    AS Accepts,
		|		0                                    AS Accepted,
		|		CASE WHEN GoodsForRegistration.Ref.Status = VALUE(Enum.GoodsTransferStatuses.Shipped)
		|			AND NOT ( GoodsForRegistration.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsForRegistration.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt) THEN
		|					GoodsForRegistration.Count
		|				ELSE
		|					0
		|			END                            AS Accept,
		|		0                                    AS Received,
		|
		|		GoodsForRegistration.Count         AS ToReceive,
		|		0                                    AS ApplyAppearance,
		|		GoodsForRegistration.Count         AS Issued_1,
		|
		|		CASE WHEN GoodsForRegistration.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsForRegistration.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|FROM
		|	Document.InventoryTransfer.Goods AS GoodsForRegistration
		|WHERE
		|	NOT GoodsForRegistration.Ref.TransferAgainstOrders
		|	AND GoodsForRegistration.Ref IN(
		|		SELECT
		|			TTDocuments.DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)) AS Set
		|GROUP BY
		|	Set.DocumentInflow,
		|	Set.Products, Set.Characteristic, Set.Warehouse
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
#EndIf
