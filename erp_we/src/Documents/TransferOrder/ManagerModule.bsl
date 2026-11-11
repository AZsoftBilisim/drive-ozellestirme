#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn hàng điều chuyển nội bộ';
		|ru = 'Заказ на перемещение';
		|en = 'Transfer order'; fa = 'سفارش انتقال';
		|it = 'Ordine di trasferimento';
		|pl = 'Zamówienie przemieszczenia';
		|tr = 'Transfer emri'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, SourceWarehouse, DestinationWarehouse");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "BusinessOperation,Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyRecipient", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "DocumentBasis";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("InternalInventoryTransfers");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AddressWarehouse");
	
	TransferOrderLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.TransferOrder") Then
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
		
		QueryTextTableTransferOrders(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		TransferOrderLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	ReflectReserve(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//	DocumentName - String - Name of the document to enter.
//
// Returns:
//	Array - array of valid statuses.
//
Function ValidInputStatusesBasedOn(DocumentName) Export
	
	AcceptableStatuses = New Array;
	AcceptableStatuses.Add(Enums.InternalOrderStatuses.ForCompletion);
	AcceptableStatuses.Add(Enums.InternalOrderStatuses.Closed);
	
	Return AcceptableStatuses;
	
EndFunction

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
	|	CASE WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|		THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE Header.DeliveryMethod
	|	END                   AS DeliveryMethod,
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
	|	T.DeliverFully    AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		MIN(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|				ELSE FALSE
	|			END) AS DeliverFully
	|	FROM
	|		Document.TransferOrder.Goods AS T
	|	WHERE
	|		T.Ref IN (&References)
	|	
	|	GROUP BY
	|		T.Ref
	|	
	|	HAVING
	|		MAX(CASE
	|				WHEN T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|					THEN TRUE
	|			END) = TRUE
	|	) AS T
	|		INNER JOIN Document.TransferOrder AS Header
	|		ON (Header.Ref = T.Ref)";
	
	Return QueryText;
	
EndFunction

// Returns a table of acceptable deviations of measured items from the list of orders.
//
//	Parameters:
//		ListOfOrders_ - ValueList, DocumentRef.InventoryConsumptionOrder - the list of orders to determine the allowable deviations
//		InventoryMovementType - EnumRef.InventoryMovementTypes -
//	Returns:
//		ValueTable - table of permissible deviations:
//		* OrderDocument                - DocumentRef.InventoryConsumptionOrder
//		* Products         - CatalogRef.Products
//		* Characteristic       - CatalogRef.ItemsCharacteristics
//		* Series                - CatalogRef.ItemsBatches
//		* AllowableVariance - Number
//
Function PermissibleDeviationsOfMeasuredGoods(ListOfOrders_, InventoryMovementType) Export
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If Not ValueIsFilled(ListOfOrders_) Or AllowableDeviationOfMeasuringGoodsShipmentAndReceiving = 0 Then
		Table = New ValueTable;
		Table.Columns.Add("OrderDocument");
		Table.Columns.Add("Products");
		Table.Columns.Add("Characteristic");
		Table.Columns.Add("Series");
		Table.Columns.Add("AllowableVariance");
		Return Table;
	EndIf;
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.TransferOrder") Then
		ReferenceArray = New Array();
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	GoodsToReceive.TransferOrder AS OrderDocument,
		|	GoodsToReceive.Products       AS Products,
		|	GoodsToReceive.Characteristic     AS Characteristic,
		|	GoodsToReceive.Series              AS Series,
		|	SUM(GoodsToReceive.ToRegisterReceipt * (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	AccumulationRegister.TransferOrders.Turnovers(&StartPeriod_, &ConPeriod,, 
		|		TransferOrder IN (&ReferenceArray)) AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	GoodsToReceive.TransferOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Series");
	
	Query.SetParameter("ReferenceArray", ReferenceArray);
	Query.SetParameter("DimensionalTypesOfUnits", Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving", AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("TransferOrders",
		"TransferOrder IN (&ReferenceArray)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

#Region CalculationOfStates

// Returns the structure of parameters for calculating the order completion status in the list of orders.
//
// Returns:
//  Structure - contains the following keys:
//    * OrderBalancesModule         - AccumulationRegisterManager.TransferOrders -
//    * MonitorOrderClosing - Boolean -
//    * StatusInProcessOfAdmission   - EnumRef.StatusesOfInternalOrders -
//    * ShippingStatus      - EnumRef.StatusesOfInternalOrders -
//    * ReadyForShipmentStatus         - EnumRef.StatusesOfInternalOrders -
//
Function ParametersForCalculatingStates() Export
	
	Structure = New Structure();
	Structure.Insert("OrderBalancesModule", AccumulationRegisters.TransferOrders);
	Structure.Insert("MonitorOrderClosing", GetFunctionalOption("DoNotCloseTransferOrdersWithoutCompleteShipment"));
	Structure.Insert("StatusInProcessOfAdmission", Enums.StatusesOfInternalOrders.DuringGoodsReceipt);
	Structure.Insert("ShippingStatus", Enums.StatusesOfInternalOrders.DuringShipment);
	Structure.Insert("ReadyForShipmentStatus", Enums.StatusesOfInternalOrders.ReadyToShip);
	
	Return Structure;
	
EndFunction

// Returns a structure containing the query texts of temporary tables for calculating the order completion status in the order list.
// 
// Returns:
//  String - Query text
//
Function TemporaryDocumentTablesForCalculatingStates() Export
	
	QueryTextGoods =
		"SELECT
		|	Table.Ref AS Ref,
		|	Table.SupplyOption AS SupplyOption,
		|	TRUE AS ThisIsAProduct,
		|	Table.Ref.ControlledLotOfTheSender AS ControlledLotReference
		|INTO TTDocumentProducts_
		|FROM
		|	Document.TransferOrder.Goods AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|		AND NOT Table.Canceled
		|		AND Table.Ref.Posted";
	
	QueryTextAttributes =
		"SELECT
		|	Table.Ref            AS Ref,
		|	Table.Posted          AS Posted,
		|	
		|	TRUE                    AS ShippingStatus_,
		|	
		|	CASE WHEN Table.Status = VALUE(Enum.InternalOrderStatuses.Closed) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END                 AS TheClosedStatus,
		|	FALSE                      AS StatusUnderApproval
		|	
		|INTO TTDocumentDetails
		|FROM
		|	Document.TransferOrder AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)";
	
	Result = New Structure("DocumentGoods, DocumentAttributes", QueryTextGoods, QueryTextAttributes);
	Return Result;
	
EndFunction

#EndRegion

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

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.InternalOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl") Then
		
		QueryText =
		"SELECT
		|	Balance.TransferOrder AS TransferOrder
		|INTO TTOrderBalances_
		|FROM
		|	AccumulationRegister.TransferOrders.Balance(, TransferOrder IN (&DocumentsArray)) AS Balance
		|
		|GROUP BY
		|	Balance.TransferOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssueBalance.DocumentShipments
		|INTO TTShipmentBalances
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&DocumentsArray)) AS GoodsForIssueBalance
		|WHERE
		|	GoodsForIssueBalance.ToShipBalance + GoodsForIssueBalance.AssembledBalance > 0
		|
		|GROUP BY
		|	GoodsForIssueBalance.DocumentShipments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow
		|INTO TTBalancesOnReceipt
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow IN (&DocumentsArray)) AS GoodsToReceiveBalance
		|
		|GROUP BY
		|	GoodsToReceiveBalance.DocumentInflow
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording,
		//  If at least one register has residues, the work on the document is not completed
		|	CASE
		|			WHEN TTOrderBalances_.TransferOrder IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|		OR CASE
		|			WHEN TTShipmentBalances.DocumentShipments IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|		OR CASE
		|			WHEN TTBalancesOnReceipt.DocumentInflow IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.TransferOrder AS DocumentsTable
		|		LEFT JOIN TTOrderBalances_ AS TTOrderBalances_
		|		ON DocumentsTable.Ref = TTOrderBalances_.TransferOrder
		|		LEFT JOIN TTShipmentBalances AS TTShipmentBalances
		|		ON DocumentsTable.Ref = TTShipmentBalances.DocumentShipments
		|		LEFT JOIN TTBalancesOnReceipt AS TTBalancesOnReceipt
		|		ON DocumentsTable.Ref = TTBalancesOnReceipt.DocumentInflow
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording
		|FROM
		|	Document.TransferOrder AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	EndIf;
		
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.InternalOrderStatuses - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If AdditionalParameters = Undefined Then
		
		Return Not Cancel;
		
	EndIf;
	
	If AdditionalParameters.Property("OrderFulfillmentControl") And ValidationSample.ThereAreLeftoversOnOrder Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" vì đơn hàng cung ứng không đầy đủ';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ выполнен не полностью';
						|en = 'Status ""%Status%"" is not set for document %Document% as the order is not fulfilled completely'; fa = 'Status ""%Status%"" is not set for document %Document% as the order is not fulfilled completely';
						|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché l''ordine non è eseguito completamente';
						|pl = 'Dla dokumentu %Document% status ""%Status%"" nie jest ustawiony, ponieważ zamówienie jest wykonanie nie w całości';
						|tr = '%Document% belgenin ""%Status%"" durumu ayarlanmadı, çünkü sipariş tam olarak tamamlanmadı'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "SourceWarehouse,DestinationWarehouse,LockedGoodsTransfer,Date";
	
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
	
	SeriesSpecificationParameters.FullObjectName = "Document.TransferOrder";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	SerialSenderParameters = WarehousesServer.UseOfSeriesInStock(Object.SourceWarehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = SerialSenderParameters.UseItemsBatch; 
	SeriesSpecificationParameters.UseCostAccountingByBatches = SerialSenderParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentByTransfer);
	
	SeriesSpecificationParameters.WarehouseFieldName = "SourceWarehouse";
	If Object.LockedGoodsTransfer Then
		SeriesSpecificationParameters.FieldNameControlledLotReference = "ControlledLotOfTheSender";
	EndIf;
	SeriesSpecificationParameters.NameOfSenderWarehouseField = "SourceWarehouse";
	SeriesSpecificationParameters.NameOfRecipientWarehouseField  = "DestinationWarehouse";
	SeriesSpecificationParameters.ShipmentPlanning = True;
	SeriesSpecificationParameters.ThisIsOrder = True;
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.Date = Object.Date;
	
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
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber,
	|	Goods.Canceled,
	|	Goods.SupplyOption
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR SeriesAccountingPoliciesSender.BatchAccountingPolicy IS NULL 
	|				OR NOT Goods.SupplyOption IN (
	|						VALUE(Enum.SupplyOptions.FromWarehouse),
	|						VALUE(Enum.SupplyOptions.Ship))
	|			THEN 0
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN SeriesAccountingPoliciesSender.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 11
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS SeriesAccountingPoliciesSender
	|		ON (SeriesAccountingPoliciesSender.Warehouse = &SourceWarehouse)
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = SeriesAccountingPoliciesSender.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.StatusOfSpecifyingSeriesIsOld
	|
	|ORDER BY
	|	Statuses.LineNumber";
	
	Return QueryText;
	
EndFunction

// Checks whether the current user has the "Add" access right to the metadata object.
//
// Returns:
//	Boolean - True - the right of access to the object is established; False - otherwise.
//
Function AccessRightInsert() Export
	
	Return AccessRight("Insert", Metadata.Documents.TransferOrder);
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//  Structure - contains the following keys:
//     * OutputTablesSupply      - Number -
//     * DisplayShipmentTables         - Number -
//     * DisplayReceiptTables      - Number -
//     * DisplayTablesCanceledShipment - Number -
//     * ThisIsOrder                        - Boolean -
//     * WarehouseInHeader                     - Boolean -
//     * FieldNameShipmentDate             - String -
//     * WarehouseFieldName                    - String -
//     * NameOfRecipientWarehouseField          - String -
//     * TextProductServiceShipment        - String -
//     * TextProductServiceReceipt     - String -
//     * NameOfServiceReceiptRegister     - String -
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("OutputTablesSupply", 1);
	StructureState.Insert("DisplayShipmentTables", 2);
	StructureState.Insert("DisplayReceiptTables", 3);
	StructureState.Insert("DisplayTablesCanceledShipment", 4);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("WarehouseInHeader", True);
	StructureState.Insert("FieldNameShipmentDate",    "ShipmentStart");
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
	StructureState.Insert("NameOfServiceReceiptRegister", "TransferOrders");
	
	StructureOfAdditionalRequests = New Structure();
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsArrival",
		TemporaryGoodsReceiptTableForProgressStateReport());
	StructureOfAdditionalRequests.Insert("QueryTextTTGoodsOrdersArrivalOrder",
		TemporaryTableGoodsOrdersReceiptForStateOfExecutionReport());
	StructureState.Insert("StructureOfAdditionalRequests", StructureOfAdditionalRequests);
	
	Return StructureState;
	
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
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ chỉ định lĩnh vực hoạt động ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Yalnızca ""%1"" iş kolu atamaları'"));
	
	// Remnants of goods in the sender warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Sender");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.Columns.FindByValue("AvailableForReservation").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.SourceWarehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotOfTheSender";
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

// Forms the structure of the document parameters for embedding the document in the software algorithms.
// Parameters:
//  DocumentObject - DocumentObject.TransferOrder - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	EmbeddingParameters.UseEventSubscriptions.BeforePerformingActionsInOrderList = True;
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "Goods";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "GoodsSupplyOption";
	FormItems.Available           = "GoodsAvailable";
	FormItems.Series              = "GoodsSeries";
	FormItems.WithAssignment        = "GoodsWithAssignment";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.Goods.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.Goods.Canceled";
		DataPaths.ItemsType = "Object.Goods.ItemsType";

	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.Goods.CurrentData.Available";
	Links.NumberOfPackages    = "Items.Goods.CurrentData.NumberOfPackages";
	Links.Count            = "Items.Goods.CurrentData.Count";
	Links.ShipIfAvailable = "Items.Goods.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.Goods.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.Goods.CurrentData.ItemsType";
	Links.Package              = "Items.Goods.CurrentData.Package";
	Links.Products          = "Items.Goods.CurrentData.Products";
	Links.SupplyOption    = "Items.Goods.CurrentData.SupplyOption";
	Links.Warehouse                 = "Object.SourceWarehouse";
	Links.MultipleWarehouses      = Undefined;
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "TransferOrders";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.TransferOrder";
	EmbeddingParameters.TableName = "Document.TransferOrder.Goods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
	
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	Attributes.SourceWarehouse AS Warehouse,
		|	
		|	CASE WHEN TabPart.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					OR Attributes.AssignByOrderAssignment
		|						AND TabPart.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own) THEN
		|				Attributes.Purpose
		|			ELSE
		|				TabPart.Purpose
		|		END AS Purpose,
		|	CASE
		|		WHEN Attributes.LockedGoodsTransfer
		|			THEN Attributes.ControlledLotOfTheSender
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	CASE
		|		WHEN Attributes.LockedGoodsTransfer
		|			THEN Attributes.ControlledLotOfTheSender
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	TRUE AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	TabPart.ShipmentStart AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.SourceWarehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	UNDEFINED AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.TransferOrder.Goods AS TabPart
		|		
		|		LEFT JOIN Document.TransferOrder AS Attributes
		|		ON TRUE";
	
	Goods = New Structure();
	Goods.Insert("LineNumber",        New TypeDescription("Number"));
	Goods.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	Goods.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Insert("Purpose",         New TypeDescription("CatalogRef.Assignments"));
	Goods.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	Goods.Insert("WithAssignment",        New TypeDescription("Boolean"));
	Goods.Insert("Count",         New TypeDescription("Number"));
	Goods.Insert("NumberOfPackages", New TypeDescription("Number"));
	Goods.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Insert("ShipmentStart",     New TypeDescription("Date"));
	Goods.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Insert("Canceled",           New TypeDescription("Boolean"));
	Goods.Insert("RowCode",          New TypeDescription("Number"));
	
	Object = New Structure();
	Object.Insert("Department",                     New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("SourceWarehouse",                  New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Purpose",                        New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("AssignByOrderAssignment",    New TypeDescription("Boolean"));
	Object.Insert("Ref",                            New TypeDescription("DocumentRef.TransferOrder"));
	Object.Insert("Status",                            New TypeDescription("EnumRef.InternalOrderStatuses"));
	Object.Insert("Date",                              New TypeDescription("Date"));
	Object.Insert("Priority",                         New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("ControlledLotOfTheSender",   New TypeDescription("CatalogRef.ControlledLots"));
	Object.Insert("LockedGoodsTransfer", New TypeDescription("Boolean"));
	Object.Insert("Goods",                            Goods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList = "UNDEFINED";
	
	Return EmbeddingParameters;
	
EndFunction

// Designed to override the order list to set the collateral actions.
// Parameters:
//  Orders - Array of AnyRef -
//  ActionCode - String -
//  UserMessages - Array of Structure
Procedure BeforePerformingActionsInOrderList(Orders, ActionCode, UserMessages) Export
	
	If ActionCode = "ACTION_COOPERATION" Or ActionCode = "ACTION_NOTABLE" Then
		
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Orders", Orders);
	Query.Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.TransferOrder AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|	AND NOT Table.LockedGoodsTransfer
		|;
		|SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.TransferOrder AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|	AND Table.LockedGoodsTransfer";
	QueryBatch = Query.ExecuteBatch();
	OrdersToMoveBlockedGoods = QueryBatch[1].Unload().UnloadColumn("Ref");
	Text = NStr("vi = 'Đối với %1, lệnh không thể thực hiện vì chứng từ đang lên kế hoạch di chuyển hàng hóa đã được yêu cầu kiểm soát chất lượng.';
				|ru = 'Для %1 команда не может быть выполнена, так как документ планирует перемещение товаров, предъявленных на контроль качества.';
				|en = 'Cannot run the command for %1 as the document plans to transfer the goods submitted for quality control.'; fa = 'Cannot run the command for %1 as the document plans to transfer the goods submitted for quality control.';
				|it = 'Cannot run the command for %1 as the document plans to transfer the goods submitted for quality control.';
				|pl = 'Cannot run the command for %1 as the document plans to transfer the goods submitted for quality control.';
				|tr = '%1 için komut gerçekleştirilemez, çünkü belge kalite kontrole sunulan ürünlerin transferini planlıyor.'");
	For Each Ref In OrdersToMoveBlockedGoods Do 
		UserMessages.Add(New Structure("Text,Ref", StrTemplate(Text, Ref), Ref));
	EndDo;
	If OrdersToMoveBlockedGoods.Count() > 0 Then
		Orders = QueryBatch[0].Unload().UnloadColumn("Ref");
	EndIf;
	
EndProcedure

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.TransferOrder, DocumentRef.TransferOrder - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Date,
		|Number,
		|SourceWarehouse,
		|BusinessOperation,
		|LineOfBusiness,
		|Organization,
		|CompanyRecipient,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
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
//  Object - DocumentObject.TransferOrder - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.TransferOrder";
	ActionParameters.ReadableFields = "Products,ShipmentStart,ReceiptEnd,Canceled";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.DestinationWarehouse);
	ActionParameters.QueryOptions.Insert("QualityControlUseDurationOfMove1",
		Object.UseTransferDuration);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlMovementOfBlockedItems",
		Object.LockedGoodsTransfer);
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	UNDEFINED AS Contract,
		|	CASE
		|		WHEN &QualityControlUseDurationOfMove1 THEN
		|			Table.ReceiptEnd
		|		ELSE Table.ShipmentStart
		|	END AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.Canceled AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	ActionParameters.OverridableProcessingInObjectManager = True;
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.TransferOrder";
	ActionParameters.ReadableFields = "Products,ReceiptEnd,Canceled";
	ActionParameters.EditableFields = "SubjectToUnlocking,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("QualityControlControlledLotReference", Object.ControlledLotOfTheSender);
	ActionParameters.QueryOptions.Insert("QualityControlUseDurationOfMove2",
		Object.UseTransferDuration);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlMovementOfBlockedItems",
		Object.LockedGoodsTransfer);
	ActionParameters.OverridableProcessingInObjectManager = True;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&QualityControlControlledLotReference AS ControlledLotReference,
		|	CASE
		|		WHEN &QualityControlUseDurationOfMove2 THEN
		|			Table.ReceiptEnd
		|		ELSE Table.ShipmentStart
		|	END AS DateOfReceipt,
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
	
	If ActionParameters.KeyDetailsOfHeader.QualityControlMovementOfBlockedItems Then
		
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
	
	FillInRegular = False; // since there is no Controlled Party field in the table part.
	If ActionParameters.KeyDetailsOfHeader.QualityControlMovementOfBlockedItems Then
		
		CurrentRow.SubjectToUnlocking = DataForProcessing.SubjectToUnlocking;
		CurrentRow.QualityConfirmationDate = DataForProcessing.QualityConfirmationDate;
		// The controlled party is not in the tabular part.
		
	Else
		
		CurrentRow.SubjectToUnlocking = True;
		// The Quality confirmation DataPackage is filled in by the action to fill in the Quality control DataPackage confirmation.
		// The controlled party is not in the tabular part.
		
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
	|	AND( ValueAllowed(SourceWarehouse)
	|	OR ValueAllowed(DestinationWarehouse)
	|	) ";

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

#EndRegion

#Region Private

#Region Internal

#Region Supply

// Returns the provision option and the flag separately for filling in the default in the document.
// Parameters:
// Object - DocumentObject.TransferOrder
// Returns:
// Undefined
// See ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault
Function SecurityOptionAndFlagSeparately(Object) Export
	
	Result = Undefined;
	If Object.LockedGoodsTransfer Then
		Result = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(False);
		SupplyOption = Enums.SupplyOptions.ReserveAsReceived;
		Result.OwnGoods.SupplyOption = SupplyOption;
		Result.Tara.SupplyOption = SupplyOption;
		// the flag is filled in normally.
		Result.OwnGoods.WithAssignment = Undefined;
		Result.Tara.WithAssignment = Undefined;
	EndIf;
	Return Result;
	
EndFunction

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.TransferOrder - the document for which you need to get the goods
//  CreationParameters - See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
//  TempTablesManager - TempTablesManager - temporary table manager where a table with columns will be created:
//   * LineNumber - Number - Line number
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Department - CatalogRef.BusinessStructure - Department
//   * Purpose - CatalogRef.Assignments - Purpose
//   * SupplyOption - EnumRef.SupplyOptions - security option
//   * WithAssignment - Boolean - WithAssignment
//   * QuantityOfUnits - Number - number of units
//   * CountByDocument - Number - Number of packages
Procedure GoodsOfDocumentForCreatingSecuringOrder(Ref, CreationParameters, TempTablesManager) Export
	
	Attributes = Common.ObjectAttributesValues(Ref, "Status,Posted");
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Ref, Attributes.Status, Not Attributes.Posted);
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	Query.Text =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Ref.SourceWarehouse AS Warehouse,
		|	Goods.Ref.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN
		|				CASE
		|					WHEN Goods.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|							OR Goods.Ref.AssignByOrderAssignment
		|									AND Goods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
		|						THEN Goods.Ref.Purpose
		|					ELSE Goods.Purpose
		|				END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.ShipmentStart AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.TransferOrder.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	
	Query.Execute();
	
EndProcedure

Function DocumentParametersForSoftwareActions(Object) Export
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("EmbeddingParameters", AvailableRemainingEmbeddingOptions());
	DocumentParameters.Insert("Object", Object);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately", SecurityOptionAndFlagSeparately(Object));
	
	ProvisionInDocumentsServer.FillInEmbeddingServiceParameters(DocumentParameters);
	Return DocumentParameters;
	
EndFunction

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.TransferOrder - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		RowsArray = Changes.UnloadColumn("String");
		
		ShipOption = Enums.SupplyOptions.Ship;
		
		RowsToProcess = New Array();
		For Each String In RowsArray Do
			
			DateOfReceiptCalculated = Max(
				BegOfDay(CurrentSessionDate()) + 86400 * Object.TransferDurationDays,
				Object.RequestedDeliveryDate);
			
			YouNeedToFillInShippingDate = String.SupplyOption = ShipOption;
			
			If YouNeedToFillInShippingDate Then
				RowsToProcess.Add(String);
				String.ShipmentStart = DateOfReceiptCalculated - 86400 * Object.TransferDurationDays;
				String.ReceiptEnd = DateOfReceiptCalculated;
			EndIf;
			
		EndDo;
		
		CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
		StructureOfActions = New Structure();
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			Object.Goods,
			Undefined);
		
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.Goods);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//	Returns:
//   See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.TransferOrder, FormDataStructure - the transfer order to get the destination template for.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfGoodslAssignmentInTransfer.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfGoodslAssignmentInTransfer.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

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
	|	HeaderData_.Date                    AS Period,
	|	HeaderData_.SourceWarehouse        AS SourceWarehouse,
	|	HeaderData_.DestinationWarehouse         AS DestinationWarehouse,
	|	PRESENTATION(HeaderData_.SourceWarehouse)    AS SourceWarehousePresentation,
	|	PRESENTATION(HeaderData_.DestinationWarehouse)     AS DestinationWarehousePresentation,
	|	HeaderData_.Purpose              AS Purpose,
	|	ISNULL(HeaderData_.Purpose.RecordsInWarehouseRegisters,FALSE) AS RecordsInWarehouseRegisters,
	|	HeaderData_.Status                  AS Status,
	|	HeaderData_.Priority               AS Priority,
	|	HeaderData_.Organization             AS Organization,
	|	HeaderData_.BusinessOperation   AS BusinessOperation,
	|	HeaderData_.Department           AS Department,
	|	HeaderData_.ControlledLotOfTheSender AS ControlledLotReference,
	|	HeaderData_.LockedGoodsTransfer AS LockedGoodsTransfer,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.Number                   AS Number,
	|	HeaderData_.EmployeeResponsible           AS EmployeeResponsible,
	|	HeaderData_.Author                   AS Author,
	|	HeaderData_.Comment             AS Comment,
	|	HeaderData_.Posted                AS Posted,
	|	HeaderData_.DeletionMark         AS DeletionMark,
	|	HeaderData_.AssignByOrderAssignment AS AssignByOrderAssignment,
	|	CASE
	|		WHEN HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
	|			THEN HeaderData_.CompanyRecipient
	|		ELSE HeaderData_.Organization
	|	END AS CompanyRecipient,
	|	CASE
	|		WHEN HeaderData_.SourceWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND HeaderData_.Date >= HeaderData_.SourceWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END                               AS AdvancedWarehousingOnShipment,
	|	CASE
	|		WHEN HeaderData_.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND HeaderData_.Date >= HeaderData_.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                               AS AdvancedWarehousingOnGoodsReceipt,
	|	HeaderData_.GoodsReceiptOption   AS GoodsReceiptOption
	|FROM
	|	Document.TransferOrder AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(Attributes.GoodsReceiptOption);
	
	Query.SetParameter("InvoiceIsOrder", InvoiceIsOrder);
	Query.SetParameter("NumberForPrinting",                  ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("MetadataIdentifier",        Common.MetadataObjectID(TypeOf(DocumentRef)));
	
	WarehouseInformationToSender = "";
	If ValueIsFilled(Attributes.SourceWarehouse) Then
		StringPattern = "vi = 'Điều chuyển từ ""%1""';
						|ru = 'Перемещение с ""%1""';
						|en = 'Transfer from ""%1""';
						|it = 'Trasferimento da ""%1""';
						|pl = 'Przenoszenie z ""%1""';
						|tr = '""%1''dan"" transfer'"; // @NStr
		WarehouseInformationToSender = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.SourceWarehousePresentation);
	EndIf;
	Query.SetParameter("WarehouseInformationToSender", WarehouseInformationToSender);
	WarehouseInformationRecipient = "";
	If ValueIsFilled(Attributes.DestinationWarehouse) Then
		StringPattern = "vi = 'Điều chuyển đến ""%1""';
						|ru = 'Перемещение на ""%1""';
						|en = 'Transfer to ""%1""';
						|it = 'Trasferimento a ""%1""';
						|pl = 'Przenoszenie do ""%1""';
						|tr = '""%1''na"" transfer'"; // @NStr
		WarehouseInformationRecipient = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.DestinationWarehousePresentation);
	EndIf;
	Query.SetParameter("WarehouseInformationRecipient", WarehouseInformationRecipient);
	
EndProcedure

Function QueryTextTableTransferOrders(Query, QueryTexts, Registers)
	RegisterName = "TransferOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) 	AS RecordType,
	|	BEGINOFPERIOD(&Period, DAY) 			AS Period,
	|	GoodsTable.Ref         			AS TransferOrder,
	|	GoodsTable.Products   			AS Products,
	|	GoodsTable.Characteristic 			AS Characteristic,
	|	GoodsTable.Series          			AS Series,
	|	GoodsTable.RowCode      			AS RowCode,
	|	0                            			AS ToRegister,
	|	GoodsTable.Count     			AS Ordered
	|FROM
	|	Document.TransferOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	
	|UNION ALL
	|	
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) 	AS RecordType,
	|	GoodsTable.ShipmentStart 			AS Period,
	|	GoodsTable.Ref        			AS TransferOrder,
	|	GoodsTable.Products   			AS Products,
	|	GoodsTable.Characteristic 			AS Characteristic,
	|	GoodsTable.Series          			AS Series,
	|	GoodsTable.RowCode      			AS RowCode,
	|	GoodsTable.Count     			AS ToRegister,
	|	0                            			AS Ordered
	|FROM
	|	Document.TransferOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (NOT GoodsTable.Canceled)
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND &Status IN (VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|				VALUE(Enum.InternalOrderStatuses.Closed))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Ref                   AS TransferOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.RowCode                AS RowCode,
	|	0                                      AS ToRegister,
	|	-GoodsTable.Count              AS Ordered
	|FROM
	|	Document.TransferOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                                AS Ref,
	|	UNDEFINED                                        AS Invoice,
	|	FALSE                                                AS Patch,
	|	UNDEFINED                                        AS CorrectedDocument,
	|	GoodsTable.Ref                                AS OrderDocument,
	|	GoodsTable.ReceiptEnd                  AS Date,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	UNDEFINED                                        AS Terms,
	|	GoodsTable.Ref.GoodsReceiptOption          AS GoodsReceiptOption,
	|	GoodsTable.Ref.DestinationWarehouse                AS Warehouse,
	|	GoodsTable.Ref.SourceWarehouse               AS Sender,
	|	GoodsTable.Ref.BusinessOperation          AS BusinessOperation,
	|	GoodsTable.Products                          AS Products,
	|	GoodsTable.Characteristic                        AS Characteristic,
	|	GoodsTable.Purpose                            AS Purpose,
	|	GoodsTable.ToControlQuality             AS ToControlQuality,
	|	GoodsTable.Ref.LockedGoodsTransfer AS RecordOfAPreviouslyReceivedLot,
	|	GoodsTable.Ref.ControlledLotOfTheSender AS ControlledLotReference,
	|	0                                                   AS BatchesIndicationStatus,
	|	FALSE                                                AS ExceedingOrder,
	|	UNDEFINED                                        AS Series,
	|	GoodsTable.Count                            AS Count,
	|	FALSE                                                AS ReceiptUnderOrders,
	|	FALSE                                                AS ThisIsAnInvoice
	|FROM
	|	Document.TransferOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|		AND NOT GoodsTable.Canceled
	|		AND GoodsTable.Ref.Status IN(
	|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|			VALUE(Enum.InternalOrderStatuses.Closed))
	|		AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
		
	WarehousesServer.ScheduleGoodsReceipt(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		"GoodsTable");
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.TransferOrder";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",                 """""");
	RedefiningParameterCalculation.Insert("WarehouseInformationRecipient",  """""");
	RedefiningParameterCalculation.Insert("WarehouseInformationToSender", """""");
	RedefiningParameterCalculation.Insert("AdvancedWarehousingOnGoodsReceipt",
		"CASE
		|	WHEN GoodsTable.Ref.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|			AND GoodsTable.Ref.Date >= GoodsTable.Ref.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|		THEN TRUE
		|	ELSE FALSE
		|END");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "TransferOrders" Then
		
		QueryText = QueryTextTableTransferOrders(Query, QueryTexts, Undefined);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		RedefiningParameterCalculation.Insert("CompanyRecipient",
			"	CASE
			|		WHEN DocumentData.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices)
			|			THEN DocumentData.Ref.CompanyRecipient
			|		ELSE DocumentData.Ref.Organization
			|	END");
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, Undefined);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
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
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.Department            AS Department,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	FALSE                                     AS ReverseTransactionCorrection,
	|	UNDEFINED                             AS ReversedDocument,
	|	UNDEFINED                             AS CorrectedDocument,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	DocumentData.Priority                AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	CASE WHEN DocumentGoods.ShipmentStart <> DATETIME(1, 1, 1) THEN
	|				DocumentGoods.ShipmentStart
	|			ELSE
	|				HeaderData_.Date
	|		END                           AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.DestinationWarehouse			AS Recipient,
	|	HeaderData_.SourceWarehouse		AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|				AND DocumentGoods.Purpose <> &DefaultAssignment
	|				AND NOT (HeaderData_.AssignByOrderAssignment
	|					AND DocumentGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))
	|			THEN DocumentGoods.Purpose
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	CASE
	|		WHEN HeaderData_.LockedGoodsTransfer
	|			THEN HeaderData_.ControlledLotOfTheSender
	|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
	|	END                               AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.TransferOrder.Goods AS DocumentGoods
	|		LEFT JOIN Document.TransferOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|	AND DocumentGoods.Count <> 0";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.ShipmentStart		AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.DestinationWarehouse			AS Recipient,
	|	HeaderData_.SourceWarehouse		AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|				AND DocumentGoods.Purpose <> &DefaultAssignment
	|				AND NOT (HeaderData_.AssignByOrderAssignment
	|					AND DocumentGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))
	|			THEN DocumentGoods.Purpose
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	CASE
	|		WHEN HeaderData_.LockedGoodsTransfer
	|			THEN HeaderData_.ControlledLotOfTheSender
	|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
	|	END                               AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.TransferOrder.Goods AS DocumentGoods
	|		LEFT JOIN Document.TransferOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.Status IN(VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|							VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.SourceWarehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN CASE
		|				WHEN TabPart.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				OR TabPart.Ref.AssignByOrderAssignment
		|				AND TabPart.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
		|					THEN TabPart.Ref.Purpose
		|				ELSE TabPart.Purpose
		|			END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	CASE
		|		WHEN &LockedGoodsTransfer
		|			THEN &ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	CASE
		|		WHEN &LockedGoodsTransfer
		|			THEN &ControlledLotReference
		|		ELSE TabPart.Ref
		|	END AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.TransferOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
		
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.SourceWarehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN CASE
		|				WHEN TabPart.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|				OR TabPart.Ref.AssignByOrderAssignment
		|				AND TabPart.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
		|					THEN TabPart.Ref.Purpose
		|				ELSE TabPart.Purpose
		|			END
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	CASE
		|		WHEN &LockedGoodsTransfer
		|			THEN &ControlledLotReference
		|		ELSE VALUE(Catalog.ControlledLots.EmptyRef)
		|	END AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.ShipmentStart AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.TransferOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
		
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref                 AS Ref,
		|	TabPart.Ref.Date            AS Period,
		|	TabPart.Products           AS Products,
		|	TabPart.Characteristic         AS Characteristic,
		|	TabPart.Ref.DestinationWarehouse AS Warehouse,
		|	TabPart.Purpose             AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count             AS Count,
		|	CASE
		|		WHEN &LockedGoodsTransfer AND TabPart.ReceiptEnd
		|				<> DATETIME(1, 1, 1)
		|			THEN &ControlledLotReference
		|		ELSE TabPart.Ref
		|	END                           AS OrderDocument,
		|	TabPart.ReceiptEnd   AS DateOfReceipt,
		|	TabPart.ReceiptEnd
		|		<> DATETIME(1, 1, 1)       AS AvailableForConsumption,
		|	FALSE                            AS OnSchedule,
		|	UNDEFINED                    AS OrderInSchedule,
		|	0                               AS QuantityInGraph
		|FROM
		|	Document.TransferOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	TableDocumentRegistry.LineOfBusiness            AS LineOfBusiness,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	TableDocumentRegistry.Department                      AS Department,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber,
	|	MAX(TableDocumentRegistry.Priority)                AS Priority
	|INTO TTBases
	|	FROM
	|	(SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&Priority                                    AS Priority,
	|		&Organization                                  AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|		&SourceWarehouse                             AS StorageLocation,
	|		&Department                                AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING (100))       AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		FALSE                                          AS AdditionalRecord,
	|		CAST(&WarehouseInformationRecipient AS STRING (100)) AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&LineOfBusiness                      AS LineOfBusiness
	|	FROM
	|		Document.TransferOrder AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	GROUP BY
	|		DocumentData.Ref
	|
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&Priority                                    AS Priority,
	|		&CompanyRecipient                        AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|		&DestinationWarehouse                              AS StorageLocation,
	|		&Department                                AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING (100))       AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		TRUE                                        AS AdditionalRecord,
	|		CAST(&WarehouseInformationToSender AS STRING (100)) AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&LineOfBusiness                      AS LineOfBusiness
	|	FROM
	|		Document.TransferOrder AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
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
	|	TableDocumentRegistry.LineOfBusiness";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region GenerateFrom

// Adds a command creation of the document "transfer Order".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.TransferOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.TransferOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.TransferOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferOrders";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	DataProcessors.GenerationOfTransferToProductionOrdersByReference.AddGenerateCommand(GenerationCommands);
	Documents.SubcontractOrder2_5.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.InventoryTransfer.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.PackingList.AddGenerateCommand(GenerationCommands);
	
	TransferOrderLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	
EndProcedure

// Adds a command creation of the document "transfer Order".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateSecuringOrderCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.TransferOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.TransferOrder.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSecuringOrder";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
			Metadata.Documents.TransferOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferOrders";
		CreationParameters = ProvisionInDocumentsServer.ParametersForCreatingSecuringOrder(
			CreateBasedOnCommand.AdditionalParameters);
		CreationParameters.NameOfDocumentManager = "TransferOrder";
		CreationParameters.FormName = "Document.TransferOrder.ObjectForm";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command creation of the document "transfer Order".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateCommandBasedOnPurchaseOfGoodsAndServicesForGroupOfWarehouses(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.TransferOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.TransferOrder.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateMovingOrderBasedOnPurchaseOfGoodsServicesForGroupOfWarehouses";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.TransferOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferOrders";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command creation of the document "transfer Order".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateCommandBasedOnAcceptanceOfGoodsForStorageByWarehouseGroup(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.TransferOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.TransferOrder.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateMovingOrderBasedOnAcceptanceOfGoodsForStorageByWarehouseGroup";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.TransferOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferOrders";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

Function ParametersForCreatingWarehousesForGroupBasedOnReceiptOfGoodsAndServices(CommandParameter) Export
	
	Query = New Query();
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
	
	Query.SetParameter("OrderDocument", CommandParameter);
	Warehouses = Query.Execute().Unload().UnloadColumn("Warehouse");
	
	MultipleWarehouses = False;
	If Warehouses.Count() > 1 Then
		MultipleWarehouses = True;
	ElsIf Warehouses.Count() = 0 Then
		Warehouses.Add(Undefined); // during the processing of filling out the document, goods will not be filled in.
	EndIf;
	
	ParametersForCreatingWarehousesByGroup = New Structure();
	ParametersForCreatingWarehousesByGroup.Insert("WarehousesList",    Warehouses);
	ParametersForCreatingWarehousesByGroup.Insert("MultipleWarehouses", MultipleWarehouses);
	
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

Function ParametersForCreatingGroupOfWarehousesForAcceptingGoodsForStorage(CommandParameter) Export
	
	Query = New Query();
	Query.Text =
	"SELECT DISTINCT
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Warehouse.Description AS Description
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS Goods
	|WHERE
	|	Goods.Ref = &OrderDocument
	|	AND Goods.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|ORDER BY
	|	Description";
	
	Query.SetParameter("OrderDocument", CommandParameter);
	Warehouses = Query.Execute().Unload().UnloadColumn("Warehouse");
	
	MultipleWarehouses = False;
	If Warehouses.Count() > 1 Then
		MultipleWarehouses = True;
	ElsIf Warehouses.Count() = 0 Then
		Warehouses.Add(Catalogs.Warehouses.EmptyRef());
	EndIf;
	
	ParametersForCreatingWarehousesByGroup = New Structure();
	ParametersForCreatingWarehousesByGroup.Insert("WarehousesList",    Warehouses);
	ParametersForCreatingWarehousesByGroup.Insert("MultipleWarehouses", MultipleWarehouses);
	
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

// Creation parameters based on the providing order.
// Returns:
// See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
Function CreationParametersBasedOnProvidingOrder() Export
	
	ProductTableParameters = ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder();
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ProductTableParameters.OneWarehouse = True;
	Return ProductTableParameters;
	
EndFunction

#EndRegion

#Region Print

// Procedure for printing a document.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "TransferOrder") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"TransferOrder",
			NStr("vi = 'Đơn hàng điều chuyển nội bộ';
				|ru = 'Заказ на перемещение';
				|en = 'Transfer order'; fa = 'سفارش انتقال';
				|it = 'Ordine di trasferimento';
				|pl = 'Zamówienie na przesunięcie';
				|tr = 'Transfer emri'"),
			CreatePrintedOrderForMovingForm(ObjectsArray, PrintObjects));
		
	EndIf;
	
EndProcedure

// The function generates a tabular document with a printed order form
// developed by methodologists.
//
// Returns:
//  SpreadsheetDocument - the printed form of the invoice.
//
Function CreatePrintedOrderForMovingForm(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	Column = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(Column);
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_TransferOrder";
	Template = PrintManagement.PrintFormTemplate("Document.TransferOrder.PF_MXL_TransferOrder");
	
	HeaderAreaMove         = Template.GetArea("TitleMove");
	HeaderAreaInternalTransfer  = Template.GetArea("TitleInternalTransfer");
	
	If OutputCodes Then
		
		AreaCodesHeader  = Template.GetArea("TableHeader|ColumnOfCodes");
		AreaCodesHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		
		AreaCodesStringComponents = Template.GetArea("StringComponents|ColumnOfCodes");
		AreaCodesStringSet = Template.GetArea("StringSet|ColumnOfCodes");
		AreaCodesString = Template.GetArea("String|ColumnOfCodes");
		AreaCodesString = Template.GetArea("String|ColumnOfCodes");
		AreaCodesBasement = Template.GetArea("Footer|ColumnOfCodes");
		
	Else
		
		ScopeOfApplication_10 = Template.Area("OwnGoods");
		ScopeOfApplication_10.ColumnWidth = ScopeOfApplication_10.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
		
	EndIf;
	
	If UseItemPackages Then
		
		PackagingAreaHeader  =  Template.GetArea("TableHeader|ColumnOfPackages");
		PackagingAreaStringComponents =  Template.GetArea("StringComponents|ColumnOfPackages");
		PackagingAreaStringSet =  Template.GetArea("StringSet|ColumnOfPackages");
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
	
	NumberAreaLineComponents = Template.GetArea("StringComponents|LineNumber");
	DataAreaRowComponents = Template.GetArea("StringComponents|OwnGoods");
	AreaEndOfLineStringComponents = Template.GetArea("StringComponents|EndOfRow");
	
	NumberAreaLineSet = Template.GetArea("StringSet|LineNumber");
	DataAreaRowSet = Template.GetArea("StringSet|OwnGoods");
	AreaEndOfLineStringSet = Template.GetArea("StringSet|EndOfRow");
	
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
		|	TransferOrder.Ref AS Ref,
		|	TransferOrder.Number AS Number,
		|	TransferOrder.Date AS Date,
		|	TransferOrder.Organization.Prefix AS Prefix,
		|	TransferOrder.BusinessOperation AS BusinessOperation,
		|	REFPRESENTATION(TransferOrder.SourceWarehouse) AS SenderPresentation,
		|	REFPRESENTATION(TransferOrder.DestinationWarehouse) AS RecipientPresentation,
		|	TransferOrder.Organization AS Organization,
		|	TransferOrder.CompanyRecipient AS CompanyRecipient,
		|	TransferOrder.EmployeeResponsible.Individual AS Manager
		|FROM
		|	Document.TransferOrder AS TransferOrder
		|WHERE
		|	TransferOrder.Ref IN(&DocumentsArray)
		|
		|ORDER BY
		|	Ref";
	
	RequestByHeader.SetParameter("DocumentsArray", ObjectsArray);
	SetPrivilegedMode(True);
	SelectionByHeader = RequestByHeader.Execute().Select();
	SetPrivilegedMode(False);
	
	QueryTextByGoods =
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|
		|	ProductKitConfigurations.Ref                                    AS ItemKitConfiguration,
		|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
		|	ProductKitConfigurations.SetPricingOption                  AS SetPricingOption,
		|
		|	GoodsTable.ProductsInSet   AS ProductsInSet,
		|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
		|
		|	GoodsTable.Products   AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Series          AS Series,
		|	GoodsTable.LineNumber    AS LineNumber,
		|
		|	CASE
		|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN REFPRESENTATION(GoodsTable.Products.UnitOfMeasure)
		|		ELSE REFPRESENTATION(GoodsTable.Package)
		|	END                                                            AS PresentationOfPackingUnit,
		|
		|	REFPRESENTATION(GoodsTable.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
		|
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Count         AS Count
		|INTO Goods
		|FROM
		|	Document.TransferOrder.Goods AS GoodsTable
		|		
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|			ON ProductKitConfigurations.Owner = GoodsTable.ProductsInSet
		|			AND ProductKitConfigurations.Characteristic = GoodsTable.ItemVariantOfSet
		|			AND ProductKitConfigurations.Main
		|WHERE
		|	GoodsTable.Ref IN(&ObjectsArray)
		|	AND NOT GoodsTable.Canceled
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.Ref                AS Ref,
		|	TableOfGoods.ProductsInSet    AS ProductsInSet,
		|	TableOfGoods.ItemVariantOfSet  AS ItemVariantOfSet,
		|	MIN(TableOfGoods.LineNumber)  AS LineNumber
		|INTO TemporaryTableSetsPreparation
		|FROM
		|	Goods AS TableOfGoods
		|
		|WHERE
		|	TableOfGoods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
		|
		|GROUP BY
		|	TableOfGoods.Ref,
		|	TableOfGoods.ProductsInSet,
		|	TableOfGoods.ItemVariantOfSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TableOfGoods.Ref AS Ref
		|INTO VariousGoods_
		|FROM
		|	Goods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref                                    AS Ref,
		|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
		|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
		|	Goods.SetPricingOption                  AS SetPricingOption,
		|	Goods.ProductsInSet                        AS ProductsInSet,
		|	Goods.ItemVariantOfSet                      AS ItemVariantOfSet,
		|	Goods.Products                              AS Products,
		|	Goods.Characteristic                            AS Characteristic,
		|
		|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
		|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END AS MainComponent,
		|	0 AS DefaultQuantity,
		|	Goods.Count AS Count
		|INTO TemporaryTableSetsOptionalPartOne
		|FROM
		|	Goods AS Goods
		|
		|WHERE
		|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT
		|	VariousGoods_.Ref                                                                  AS Ref,
		|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
		|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
		|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
		|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
		|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
		|	ConfigurationOptionsForProductRange.Products                                     AS Products,
		|	ConfigurationOptionsForProductRange.Characteristic                                   AS Characteristic,
		|
		|	FALSE AS MainComponent,
		|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
		|	0 AS Count
		|FROM
		|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
		|		LEFT JOIN VariousGoods_ AS VariousGoods_
		|		ON TRUE
		|WHERE
		|	ConfigurationOptionsForProductRange.Ref IN (SELECT T.ItemKitConfiguration FROM Goods AS T)
		|
		|GROUP BY
		|	VariousGoods_.Ref,
		|	ConfigurationOptionsForProductRange.Ref,
		|	ConfigurationOptionsForProductRange.Ref.Owner,
		|	ConfigurationOptionsForProductRange.Ref.Characteristic,
		|	ConfigurationOptionsForProductRange.Products,
		|	ConfigurationOptionsForProductRange.Characteristic,
		|	ConfigurationOptionsForProductRange.Package
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Ref,
		|	Table.ItemKitConfiguration,
		|	Table.SetPricingOption,
		|	Table.PresentationOptionInPrintForms,
		|	Table.ProductsInSet,
		|	Table.ItemVariantOfSet,
		|	Table.Products,
		|	Table.Characteristic,
		|	MAX(Table.MainComponent) AS MainComponent,
		|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
		|	SUM(Table.Count) AS Count
		|INTO TemporaryTableSetsOptionalPartTwo
		|FROM
		|	TemporaryTableSetsOptionalPartOne AS Table
		|
		|GROUP BY
		|	Table.Ref,
		|	Table.ItemKitConfiguration,
		|	Table.SetPricingOption,
		|	Table.PresentationOptionInPrintForms,
		|	Table.ProductsInSet,
		|	Table.ItemVariantOfSet,
		|	Table.Products,
		|	Table.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Result.Ref,
		|	Result.ItemKitConfiguration,
		|	Result.SetPricingOption,
		|	Result.PresentationOptionInPrintForms,
		|	Result.ProductsInSet,
		|	Result.ItemVariantOfSet,
		|	CAST(MIN(CASE
		|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
		|				THEN Result.Count / Result.DefaultQuantity
		|			ELSE NULL
		|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count,
		|	MAX(CASE
		|			WHEN Result.DefaultQuantity <> 0
		|				THEN Result.Count / Result.DefaultQuantity
		|			ELSE NULL
		|		END) AS CoefficientMaximum,
		|	CAST(MIN(CASE
		|			WHEN Result.DefaultQuantity <> 0
		|				THEN Result.Count / Result.DefaultQuantity
		|			ELSE NULL
		|		END) + 0.5 AS NUMBER(10,0)) - 1 AS MinimumRatio
		|INTO TemporaryTableSetsOptional
		|FROM
		|	TemporaryTableSetsOptionalPartTwo AS Result
		|GROUP BY
		|	Result.Ref,
		|	Result.ItemKitConfiguration,
		|	Result.SetPricingOption,
		|	Result.PresentationOptionInPrintForms,
		|	Result.ProductsInSet,
		|	Result.ItemVariantOfSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TemporaryTableSetsOptional.ItemKitConfiguration,
		|
		|	CASE WHEN CAST(Table.Ref AS Document.TransferOrder).BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
		|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
		|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
		|		ELSE
		|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
		|		END
		|	ELSE
		|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
		|	END AS PresentationOptionInPrintForms,
		|
		|	CASE WHEN CAST(Table.Ref AS Document.TransferOrder).BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) THEN
		|		CASE WHEN
		|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
		|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
		|			ELSE
		|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
		|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
		|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
		|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
		|		ELSE
		|			TemporaryTableSetsOptional.SetPricingOption
		|		END
		|	ELSE
		|		TemporaryTableSetsOptional.SetPricingOption
		|	END AS SetPricingOption,
		|
		|	Table.Ref                            AS Ref,
		|	Table.ProductsInSet                AS ProductsInSet,
		|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
		|	Table.LineNumber                       AS LineNumber,
		|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
		|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
		|	CASE WHEN TemporaryTableSetsOptional.MinimumRatio = TemporaryTableSetsOptional.CoefficientMaximum THEN TRUE ELSE FALSE END AS FullSet
		|INTO TemporaryTableSets
		|FROM
		|	TemporaryTableSetsPreparation AS Table
		|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
		|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
		|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
		|		AND Table.Ref = TemporaryTableSetsOptional.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NestedQuery.Ref AS Ref,
		|	NestedQuery.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
		|	NestedQuery.SetPricingOption AS SetPricingOption,
		|
		|	NestedQuery.ProductsInSet   AS ProductsInSet,
		|	NestedQuery.ItemVariantOfSet AS ItemVariantOfSet,
		|	NestedQuery.IsRecordsSet             AS IsRecordsSet,
		|	NestedQuery.TheseAreComponents     AS TheseAreComponents,
		|	NestedQuery.FullSet          AS FullSet,
		|
		|	NestedQuery.Products                      AS OwnGoods,
		|	NestedQuery.Products.DescriptionFull   AS ProductItemName,
		|	NestedQuery.Products.Code                  AS Code,
		|	NestedQuery.Products.SKU              AS SKU,
		|	NestedQuery.Characteristic.DescriptionFull AS CharacteristicName,
		|	NestedQuery.Characteristic                    AS Characteristic,
		|	NestedQuery.Series                             AS Series,
		|
		|	NestedQuery.PresentationOfPackingUnit   AS PresentationOfPackingUnit,
		|	NestedQuery.PresentationOfBasicUnitOfMeasure    AS PresentationOfBasicUnitOfMeasure,
		|	NestedQuery.PresentationOfBasicUnitOfMeasure    AS UnitOfMeasure,
		|	NestedQuery.Count                              AS Count,
		|	NestedQuery.NumberOfPackages                      AS NumberOfPackages,
		|	NestedQuery.LineNumber                             AS LineNumber,
		|	FALSE                                                    AS BatchUsageSettings
		|FROM
		|(
		|	SELECT
		|		Table.Ref,
		|
		|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
		|			TemporaryTableSets.PresentationOptionInPrintForms
		|		ELSE
		|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
		|		END AS PresentationOptionInPrintForms,
		|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
		|			TemporaryTableSets.SetPricingOption
		|		ELSE
		|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
		|		END AS SetPricingOption,
		|
		|		Table.ProductsInSet   AS ProductsInSet,
		|		Table.ItemVariantOfSet AS ItemVariantOfSet,
		|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|		END AS TheseAreComponents,
		|		FALSE AS IsRecordsSet,
		|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
		|			TemporaryTableSets.LineNumber
		|		ELSE
		|			Table.LineNumber
		|		END AS LineNumber,
		|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
		|			TemporaryTableSets.FullSet
		|		ELSE
		|			FALSE
		|		END AS FullSet,
		|		Table.Products       AS Products,
		|		Table.Count         AS Count,
		|		Table.NumberOfPackages AS NumberOfPackages,
		|		Table.Characteristic     AS Characteristic,
		|		Table.Series              AS Series,
		|
		|		Table.PresentationOfPackingUnit AS PresentationOfPackingUnit,
		|		Table.PresentationOfBasicUnitOfMeasure    AS PresentationOfBasicUnitOfMeasure
		|	FROM
		|		Goods AS Table
		|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
		|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
		|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
		|			 AND TemporaryTableSets.Ref = Table.Ref
		|
		|	WHERE
		|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
		|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
		|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
		|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
		|
		|	UNION ALL
		|
		|	SELECT
		|		TemporaryTableSets.Ref,
		|		TemporaryTableSets.PresentationOptionInPrintForms,
		|		TemporaryTableSets.SetPricingOption,
		|		TemporaryTableSets.ProductsInSet,
		|		TemporaryTableSets.ItemVariantOfSet,
		|		FALSE,
		|		TRUE,
		|		TemporaryTableSets.LineNumber,
		|		TemporaryTableSets.FullSet,
		|		TemporaryTableSets.ProductsInSet,
		|		TemporaryTableSets.Count,
		|		TemporaryTableSets.NumberOfPackages,
		|		TemporaryTableSets.ItemVariantOfSet,
		|		VALUE(Catalog.ItemsBatches.EmptyRef),
		|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
		|		TemporaryTableSets.ProductsInSet.UnitOfMeasure
		|	FROM
		|		TemporaryTableSets AS TemporaryTableSets
		|	WHERE
		|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
		|	                                                           VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
		|) AS NestedQuery
		|
		|ORDER BY
		|	NestedQuery.Ref,
		|	LineNumber,
		|	IsRecordsSet DESC
		|
		|TOTALS BY
		|	Ref";
	
	RequestForProducts = New Query;
	RequestForProducts.Text = QueryTextByGoods;
	RequestForProducts.SetParameter("ObjectsArray", ObjectsArray);
	SelectionByTableParts = RequestForProducts.Execute().Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	ErrorPatternProducts = NStr("vi = 'Không có hàng hóa nào trong chứng từ %1. Không cần in lệnh chuyển';
								|ru = 'В документе %1 отсутствуют товары. Печать заказа на перемещение не требуется';
								|en = 'No goods in the document %1. It is not required to print the transfer order'; fa = 'No goods in the document %1. It is not required to print the transfer order';
								|it = 'Il documento %1 non contiene merci. La stampa dell''ordine di trasferimento non è richiesta.';
								|pl = 'W dokumencie %1 nie ma towarów. Wydruk zlecenia na przemieszczenie nie jest wymagany';
								|tr = '%1 belgesinde ürün mevcut değil. Transfer siparişini yazdırma gerekli değildir'");
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While SelectionByHeader.Next() Do
		
		Header = SelectionByHeader;
		If Not SelectionByTableParts.FindNext(New Structure("Ref", Header.Ref)) Then
			
			ErrorText = StrTemplate(ErrorPatternProducts, Header.Ref);
			CommonClientServer.MessageToUser(ErrorText, Header.Ref);
			Continue;
			
		EndIf;
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		If Not FirstDocument Then
			
			TabDocument.PutHorizontalPageBreak();
			
		EndIf;
		
		FirstDocument = False;
		
		// Order header output
		If Header.BusinessOperation = Enums.BusinessTransactions.InventoryTransfer Then
		
			TitleArea = HeaderAreaMove;
		
		Else // Economic operation - Internal transfer of goods
		
			TitleArea = HeaderAreaInternalTransfer;
		
		EndIf;
			
		DocumentName_1 = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
								|ru = 'Заказ на перемещение';
								|en = 'Transfer order'; fa = 'سفارش انتقال';
								|it = 'Ordine di trasferimento';
								|pl = 'Zamówienie przemieszczenia';
								|tr = 'Transfer emri'", Common.DefaultLanguageCode());
		TitleArea.Parameters.Fill(Header);
        AreaParameters_ = New Structure;
		AreaParameters_.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(Header,
									DocumentName_1));
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(Header.Organization, Header.Date);
		AreaParameters_.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(Header.CompanyRecipient, Header.Date);
		AreaParameters_.Insert("CompanyRecipientPresentation ", NamesAsOfDate.AbbreviatedDescription);
		TitleArea.Parameters.Fill(AreaParameters_);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, TitleArea, Header.Ref);
		TabDocument.Put(TitleArea);
		
		TabDocument.Put(AreaOfHeaderNumber);
		
		If OutputCodes Then
			
			TabDocument.Join(AreaCodesHeader);
			
		EndIf;
		
		TabDocument.Join(HeaderDataArea);
		
		If UseItemPackages Then
			
			TabDocument.Join(PackagingAreaHeader);
			
		EndIf;
		
		TabDocument.Join(AreaEndOfLineHeader);
		
		SelectingProductLines = SelectionByTableParts.Select();
		
		LineNumber = 0;
		BlankData = New Structure();
		
		BlankData.Insert("NumberOfPackages", "");
		BlankData.Insert("PresentationOfPackingUnit", "");
		BlankData.Insert("Count", "");
		BlankData.Insert("PresentationOfBasicUnitOfMeasure", "");
		
		While SelectingProductLines.Next() Do
		
			UseSets = TMCommonUseClientServer.HasObjectAttribute(SelectingProductLines, "IsRecordsSet");
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(SelectingProductLines, UseSets);
			
			If SetsServer.UseSetArea(SelectingProductLines, UseSets) Then
				RoomArea = NumberAreaLineSet;
				AreaCodes = ?(OutputCodes, AreaCodesStringSet, Undefined);
				DataArea = DataAreaRowSet;
				PackagingArea= ?(UseItemPackages, PackagingAreaStringSet, Undefined);
				EndOfLineArea= AreaEndOfLineStringSet;
			ElsIf SetsServer.UseScope(SelectingProductLines, UseSets) Then
				RoomArea = NumberAreaLineComponents;
				AreaCodes = ?(OutputCodes, AreaCodesStringComponents, Undefined);
				DataArea = DataAreaRowComponents;
				PackagingArea= ?(UseItemPackages, PackagingAreaStringComponents, Undefined);
				EndOfLineArea= AreaEndOfLineStringComponents;
			Else
				RoomArea = NumberAreaLine;
				AreaCodes = ?(OutputCodes, AreaCodesString, Undefined);
				DataArea = DataAreaRow;
				PackagingArea= ?(UseItemPackages, PackagingAreaString, Undefined);
				EndOfLineArea= AreaEndOfLineString;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(SelectingProductLines, UseSets) Then
				RoomArea.Parameters.LineNumber = Undefined;
			Else
				LineNumber = LineNumber + 1;
				RoomArea.Parameters.LineNumber = LineNumber;
			EndIf;
			
			TabDocument.Put(RoomArea);
			
			If OutputCodes Then
				
				AreaCodes.Parameters.SKU = SelectingProductLines[Column];
				TabDocument.Join(AreaCodes);
				
			EndIf;
			
			DataArea.Parameters.Fill(SelectingProductLines);
			DataArea.Parameters.OwnGoods = PrefixAndPostfix.Prefix
				+ ProductsClientServer.PresentationOfProductsForPrinting(
				TrimAll(SelectingProductLines.ProductItemName),
				TrimAll(SelectingProductLines.Characteristic),
				, // Package
				TrimAll(SelectingProductLines.Series),
				AdditionalParametersProductPresentation)
				+ PrefixAndPostfix.Postfix;
			
			TabDocument.Join(DataArea);
			
			If UseItemPackages Then
				
				PackagingArea.Parameters.Fill(SelectingProductLines);
				
			EndIf;
			
			EndOfLineArea.Parameters.Fill(SelectingProductLines);
			
			If UseSets
				And SelectingProductLines.TheseAreComponents
				And SelectingProductLines.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents
				And (SelectingProductLines.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares
				   Or SelectingProductLines.SetPricingOption = Enums.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices) Then
				// The area should remain blank
				If UseItemPackages Then
					PackagingArea.Parameters.Fill(BlankData);
				EndIf;
				EndOfLineArea.Parameters.Fill(BlankData);
			ElsIf UseSets
				And SelectingProductLines.IsRecordsSet
				And SelectingProductLines.PresentationOptionInPrintForms = Enums.OptionsOfSetPresentationInPrintForms.KitAndComponents
				And (SelectingProductLines.SetPricingOption = Enums.SetPriceCalculationOptions.CaclulatesFromComponentPrices) Then
				// The area should remain blank
				If UseItemPackages Then
					PackagingArea.Parameters.Fill(BlankData);
				EndIf;
				EndOfLineArea.Parameters.Fill(BlankData);
			EndIf;
			
			If UseItemPackages Then
				TabDocument.Join(PackagingArea);
			EndIf;
			
			TabDocument.Join(EndOfLineArea);
			
		EndDo;
		
		TabDocument.Put(RoomAreaBasement);
		
		If OutputCodes Then
			
			TabDocument.Join(AreaCodesBasement);
			
		EndIf;
		
		TabDocument.Join(DataAreaBasement);
		
		If UseItemPackages Then
			
			TabDocument.Join(PackingAreaBasement);
			
		EndIf;
		
		TabDocument.Join(AreaEndOfLineBasement);
		
		// Signature output.
		LabelArea = Template.GetArea("Signatures");
		LabelArea.Parameters.ManagerSFullName = PersonsTM.IndividualShortName(Header.Manager, Header.Date);
		TabDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, Header.Ref);
		
	EndDo;
	
	TabDocument.FitToPage = True;
	
	Return TabDocument;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If AccessRight("Update", Metadata.Documents.TransferOrder) Then
		// Transfer order
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "TransferOrder";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
										|ru = 'Заказ на перемещение';
										|en = 'Transfer order'; fa = 'سفارش انتقال';
										|it = 'Ordine di trasferimento';
										|pl = 'Zamówienie na przesunięcie';
										|tr = 'Transfer emri'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	TransferOrderLocalization.AddPrintCommands(PrintCommands);

EndProcedure

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
		|		GoodsForRegistration.TransferOrder AS DocumentInflow,
		|		GoodsForRegistration.Products       AS Products,
		|		GoodsForRegistration.Characteristic     AS Characteristic,
		|		GoodsForRegistration.TransferOrder.DestinationWarehouse AS Warehouse,
		|
		|		0                                    AS Accepts,
		|		0                                    AS Accepted,
		|		0                                    AS Accept,
		|		0                                    AS Received,
		|
		|		GoodsForRegistration.ToRegisterReceipt          AS ToReceive,
		|		GoodsForRegistration.ToRegisterClosingBalance AS ApplyAppearance,
		|		GoodsForRegistration.ToRegisterExpense          AS Issued_1,
		|
		|		CASE WHEN GoodsForRegistration.TransferOrder.DestinationWarehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND &CurrentDate >= GoodsForRegistration.TransferOrder.DestinationWarehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt THEN
		|					TRUE
		|				ELSE
		|					FALSE
		|			END                                      AS AdvancedWarehousingOnGoodsReceipt
		|FROM
		|	AccumulationRegister.TransferOrders.BalanceAndTurnovers(, , , ,
		|			TransferOrder IN(
		|				SELECT
		|					TTDocuments.DocumentRef
		|				FROM
		|					TTDocuments AS TTDocuments)) AS GoodsForRegistration) AS Set
		|GROUP BY
		|	Set.DocumentInflow,
		|	Set.Products, Set.Characteristic, Set.Warehouse
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////";
	
	Return QueryText;
	
EndFunction

Function TemporaryTableGoodsOrdersReceiptForStateOfExecutionReport()
	
	QueryText = "
		|SELECT ALLOWED
		|	DocumentGoods.Products           AS Products,
		|	DocumentGoods.Characteristic         AS Characteristic,
		|	SUM(DocumentGoods.Count)      AS Count,
		|	SUM(0)                              AS AmountIncludingVAT,
		|	DocumentGoods.Ref.DestinationWarehouse AS Warehouse,
		|	TTDocuments.DocumentRef            AS Ref
		|INTO TTGoodsNewArrival
		|FROM
		|	Document.TransferOrder.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
		|WHERE
		|	NOT DocumentGoods.Canceled
		|	AND TTDocuments.Posted
		|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND DocumentGoods.Ref.Status IN(
		|		VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|		VALUE(Enum.InternalOrderStatuses.Closed))
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Ref.DestinationWarehouse,
		|	TTDocuments.DocumentRef
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	SUM(DocumentGoods.Count),
		|	SUM(0),
		|	DocumentGoods.Ref.DestinationWarehouse,
		|	TTDocuments.DocumentRef
		|FROM
		|	Document.InventoryTransfer.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.TransferOrder)
		|WHERE
		|	DocumentGoods.Ref.Posted
		|	AND DocumentGoods.RowCode = 0
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Package,
		|	DocumentGoods.Ref.DestinationWarehouse,
		|	TTDocuments.DocumentRef
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	TransferOrderLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Other

Function QueryTextDocumentGoods() Export

	QueryText = 
	"SELECT
	|	Table.Ref                       AS TransferOrder,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	Table.ProductsInSet           AS ProductsInSet,
	|	Table.ItemVariantOfSet         AS ItemVariantOfSet,
	|	Table.Purpose,
	|	CASE
	|		WHEN Table.WithAssignment
	|				AND Table.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|				AND NOT (Table.Ref.AssignByOrderAssignment
	|					AND Table.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))
	|			THEN Table.Purpose
	|		WHEN Table.WithAssignment
	|				AND (Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|					OR (Table.Ref.AssignByOrderAssignment)
	|						AND Table.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS AssignmentSender,
	|	Table.RowCode                    AS RowCode,
	|	Table.Series                        AS Series,
	|	Table.Count                   AS Count,
	|	Table.Package                     AS Package,
	|	Table.ShipmentStart               AS DateOfShipment,
	|	Table.Ref.SourceWarehouse      AS Warehouse,
	|	Table.Ref.SalesOpportunity                AS SalesOpportunity,
	|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
	|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered
	|FROM
	|	Document.TransferOrder.Goods AS Table
	|	LEFT JOIN TTAccountingData AS DataOfAccounting
	|	ON Table.Ref = DataOfAccounting.TransferOrder
	|	AND Table.RowCode = DataOfAccounting.RowCode
	|WHERE
	|	NOT DataOfAccounting.TransferOrder IS NULL
	|		AND Table.Ref IN(&References)";
	
	Return QueryText;

EndFunction

#EndRegion

#Region FormationOfHyperlinkInJournalOfDocumentsOfInternalCommodityMovement

Function ThereAreOrdersInProgress(Parameters)
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	OrderStates.OrderDocument AS OrderDocument,
		|	OrderStates.State AS State
		|FROM
		|	InformationRegister.StatusesOfInternalOrders AS OrderStates
		|WHERE
		|	OrderStates.OrderDocument REFS Document.TransferOrder
		|	AND OrderStates.State <> VALUE(Enum.StatusesOfInternalOrders.Closed)");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders)
			And AccessRight("Update", Metadata.Documents.TransferOrder)
			And GetFunctionalOption("UseTransferOrders")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Đơn hàng điều chuyển nội bộ';
						|ru = 'Заказы на перемещение';
						|en = 'Transfer orders'; fa = 'سفارش‌های انتقال';
						|it = 'Ordini di trasferimento';
						|pl = 'Zamówienia na przesunięcie';
						|tr = 'Transfer siparişleri'");
	HyperlinkAnchorText = "Document.TransferOrder.Form.ListForm";
	
	If ThereAreOrdersInProgress(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, HyperlinkAnchorText);
	Else
		Return New FormattedString(HyperlinkText,, StyleColors.EmptyTableField,, HyperlinkAnchorText);
	EndIf;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.TransferOrder.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.8";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("174b0cda-50f8-479f-a083-88db17d1ba04");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.TransferOrder.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền mục tin ""Lĩnh vực hoạt động"" trong chứng từ ""Đơn hàng điều chuyển nội bộ"".';
							|ru = 'Заполняет реквизит ""Направление деятельности"" в документе ""Заказ на перемещение"".';
							|en = 'Fills in the ""Line of business"" attribute in the ""Transfer order"" document.'; fa = 'Fills in the ""Line of business"" attribute in the ""Transfer order"" document.';
							|it = 'Fills in the ""Line of business"" attribute in the ""Transfer order"" document.';
							|pl = 'Fills in the ""Line of business"" attribute in the ""Transfer order"" document.';
							|tr = '""Transfer emri"" belgesindeki ""İş kolu"" özniteliğini doldurur.'");
	
	ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = ExecutionPriorities.Add();
	Priority.Order = "Before";
	Priority.Procedure = "InformationRegisters.DocumentsRegistry.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionPriorities = ExecutionPriorities;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.TransferOrder.FullName());
	ItemsToRead.Add(Metadata.Catalogs.Assignments.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.TransferOrder.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Registers data for processing when switching to a new version.
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.TransferOrder";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText = 
	"SELECT DISTINCT
	|	DocumentsTable.Ref AS Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		MAX(ISNULL(CASE
	|					WHEN NOT GoodsTable.WithAssignment
	|						THEN NULL
	|					WHEN GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|							OR DocumentData.AssignByOrderAssignment
	|								AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
	|						THEN DocumentData.Purpose.LineOfBusiness
	|					ELSE GoodsTable.Purpose.LineOfBusiness
	|				END, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|		COUNT(DISTINCT ISNULL(CASE
	|					WHEN NOT GoodsTable.WithAssignment
	|						THEN NULL
	|					WHEN GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|							OR DocumentData.AssignByOrderAssignment
	|								AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
	|						THEN DocumentData.Purpose.LineOfBusiness
	|					ELSE GoodsTable.Purpose.LineOfBusiness
	|				END, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities
	|	FROM
	|		Document.TransferOrder AS DocumentData
	|			LEFT JOIN Document.TransferOrder.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	GROUP BY
	|		DocumentData.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref,
	|		MAX(ISNULL(GoodsTable.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))),
	|		COUNT(DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|	FROM
	|		Document.TransferOrder AS DocumentData
	|			LEFT JOIN Document.TransferOrder.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	GROUP BY
	|		DocumentData.Ref) AS DocumentsTable
	|WHERE
	|	DocumentsTable.NumberOfActivities = 1
	|	AND DocumentsTable.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)";
	
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.TransferOrder";
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	QueryText = 
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO DocumentsTable
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(CASE
	|			WHEN TableDocumentRegistry.NumberOfActivities = 1
	|				THEN TableDocumentRegistry.LineOfBusiness
	|			ELSE UNDEFINED
	|		END) AS LineOfBusiness,
	|	TableDocumentRegistry.Ref AS Ref
	|INTO DataByFilling
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref,
	|		MAX(ISNULL(CASE
	|					WHEN NOT GoodsTable.WithAssignment
	|						THEN NULL
	|					WHEN GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|							OR DocumentData.AssignByOrderAssignment
	|								AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
	|						THEN DocumentData.Purpose.LineOfBusiness
	|					ELSE GoodsTable.Purpose.LineOfBusiness
	|				END, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|		COUNT(DISTINCT ISNULL(CASE
	|					WHEN NOT GoodsTable.WithAssignment
	|						THEN NULL
	|					WHEN GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|							OR DocumentData.AssignByOrderAssignment
	|								AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
	|						THEN DocumentData.Purpose.LineOfBusiness
	|					ELSE GoodsTable.Purpose.LineOfBusiness
	|				END, VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities,
	|		DocumentData.Date AS Date
	|	FROM
	|		Document.TransferOrder AS DocumentData
	|			LEFT JOIN Document.TransferOrder.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		TRUE IN
	|				(SELECT
	|					TRUE AS Flag
	|				FROM
	|					DocumentsTable AS DocumentsTable
	|				WHERE
	|					DocumentsTable.Ref = DocumentData.Ref)
	|	
	|	GROUP BY
	|		DocumentData.Ref,
	|		DocumentData.Date
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref,
	|		MAX(ISNULL(GoodsTable.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))),
	|		COUNT(DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))),
	|		DocumentData.Date
	|	FROM
	|		Document.TransferOrder AS DocumentData
	|			LEFT JOIN Document.TransferOrder.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		TRUE IN
	|				(SELECT
	|					TRUE AS Flag
	|				FROM
	|					DocumentsTable AS DocumentsTable
	|				WHERE
	|					DocumentsTable.Ref = DocumentData.Ref)
	|	
	|	GROUP BY
	|		DocumentData.Ref,
	|		DocumentData.Date) AS TableDocumentRegistry
	|WHERE
	|	TableDocumentRegistry.NumberOfActivities = 1
	|
	|GROUP BY
	|	TableDocumentRegistry.Ref
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Ref AS Ref,
	|	ISNULL(DataByFilling.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	DocumentAttributes.Date AS Date
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.TransferOrder AS DocumentAttributes
	|		ON DocumentsTable.Ref = DocumentAttributes.Ref
	|		LEFT JOIN DataByFilling AS DataByFilling
	|		ON DocumentsTable.Ref = DataByFilling.Ref
	|
	|ORDER BY
	|	Date DESC";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
	
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			DocumentObject = Selection.Ref.GetObject(); // DocumentObject.TransferOrder
			
			If DocumentObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
				CommitTransaction();
				Continue;
			EndIf;
			
			ObjectModified = False;
			
			If Not ValueIsFilled(DocumentObject.LineOfBusiness)
			   And ValueIsFilled(Selection.LineOfBusiness) Then
				
				DocumentObject.LineOfBusiness = Selection.LineOfBusiness;
				ObjectModified = True;
				
			EndIf;
			
			If ObjectModified Then
				InfobaseUpdate.WriteObject(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
		EndTry;
	
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
