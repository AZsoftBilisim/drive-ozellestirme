
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#If Not MobileStandaloneServer Then

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	
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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsReceiptNote") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	ElsIf TypeOf(Document) = Type("DocumentRef.GoodsReceiptNote") Then
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	Else
		DocumentObject = Undefined;
		DocumentRef = Undefined;
	EndIf;

	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject);
	TakeGoodsToWarehouse(Query, QueryTexts, Registers);
	RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.GoodsPickingPlacement.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.GoodsToReceive.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order    = 1;
		ReportCommand.VisibilityInForms = "DocumentForm";
	EndIf;
	
	
EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Premise,Status,WarehouseOperation,RecordOfAPreviouslyReceivedLot,Date";
	
	Return AttributesNames;
EndFunction

#EndIf

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//		Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//		Structure - the composition of the structure fields is set in the Nomenclature Clientserver function.Parameters of the Series specification.
//
Function SeriesSpecificationParameters(Object) Export
	
	#If Not MobileStandaloneServer Then
		SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
		
		SeriesSpecificationParameters.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	#Else
		SeriesSpecificationParameters = MobileWarehouseKeeperWorkspace.ItemClientServerSerialSpecificationParameters();
		
		SeriesSpecificationParameters.UseBinLocationWarehousing = MobileWarehouseKeeperWorkspace.UseBinLocationWarehousing(Object.Warehouse, Object.Premise, Object.Date);
	#EndIf
	
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsReceiptNote";
	
	SeriesSpecificationParameters.UseItemsBatch = 
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse",Object.Warehouse));
	
	SeriesSpecificationParameters.ProductLocationsAreUsed = True;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Object.WarehouseOperation);
	
	SeriesSpecificationParameters.NameTSGoods = "Goods";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	SeriesSpecificationParameters.LinkFields.Add("PackingListParent");
	
	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";	
	EndIf;
	
	If Object.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient Then
		SeriesSpecificationParameters.LinkFields.Add("DocumentShipments");
	EndIf;
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.ItSWarrant = True;
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	If Object.RecordOfAPreviouslyReceivedLot Then
		SeriesSpecificationParameters.FieldNameControlledLotReference = "ControlledLotReference";
	EndIf;
	
	If Object.Status = Enums.GoodsReceiptNoteStatuses.ToReceive
		Or Object.Status = Enums.GoodsReceiptNoteStatuses.DataProcessorIsRequired 
		Or Object.Status = Enums.GoodsReceiptNoteStatuses.InProgress Then
		SeriesSpecificationParameters.OrderPreparation = True;
	EndIf;
	
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("ReferenceOrder");
	SeriesSpecificationParameters.RegisterSeries = True;
	
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
	|	Table.Package AS Package,
	|	Table.PackingListParent,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.NumberOfPackages AS Count,
	|	Table.BatchesIndicationStatus,
	|	Table.DocumentShipments AS DocumentShipments,
	|	Table.Purpose,
	|	Table.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
		
	If SeriesSpecificationParameters.LinkFields.Find("Package") = Undefined 
		Or SeriesSpecificationParameters.FieldNameQuantity = "Count" Then
	
		QueryText = StrReplace(QueryText, "Table.Package", "TRUE");
		QueryText = StrReplace(QueryText,"Table.PackingListParent","TRUE AS PackingListParent");
		QueryText = StrReplace(QueryText,
								"Table.NumberOfPackages AS Count,",
								"Table.Count AS Count,")
	EndIf;
	
	If SeriesSpecificationParameters.LinkFields.Find("DocumentShipments") = Undefined 
		Or SeriesSpecificationParameters.NameTSGoods = "SelectedLabeledProducts" Then
		QueryText = StrReplace(QueryText, "Table.DocumentShipments", "TRUE");
	EndIf;
	
	QueryText = QueryText + 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|							WHEN Goods.Count > 0
	|									AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|											THEN 14
	|										ELSE 10
	|									END
	|							WHEN &OrderPreparation
	|								THEN 11
	|							ELSE CASE
	|									WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|										THEN 13
	|									ELSE 9
	|								END
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|								THEN CASE
	|										WHEN Goods.Count > 0
	|												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 6
	|										WHEN &OrderPreparation
	|											THEN 25
	|										ELSE 5
	|									END
	|							ELSE CASE
	|									WHEN Goods.Count > 0
	|											AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 8
	|									WHEN &OrderPreparation
	|										THEN 27
	|									ELSE 7
	|								END
	|						END
	|				WHEN &ConditionForSeriesAccountingPolicyParameter
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN CASE
	|										WHEN Goods.Count > 0
	|												AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 4
	|										WHEN &OrderPreparation
	|											THEN 23
	|										ELSE 3
	|									END
	|							ELSE CASE
	|									WHEN Goods.Count > 0
	|											AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 2
	|									WHEN &OrderPreparation
	|										THEN 21
	|									ELSE 1
	|								END
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND Goods.Products.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.BatchesIndicationStatus <> StatusTable.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	ThisIsReturnOfRejectedGoods = SeriesSpecificationParameters.WarehouseTransactions
		.Find(Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient) <> Undefined;
	ThisReturnOfUnrecognizedGoodsIsOutdated = SeriesSpecificationParameters.WarehouseTransactions
		.Find(Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed) <> Undefined;
		
	If ThisIsReturnOfRejectedGoods
		Or ThisReturnOfUnrecognizedGoodsIsOutdated Then
		
		QueryText = StrReplace(QueryText,"&ConditionForSeriesAccountingPolicyParameter",
			"BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReturnOfGoodsNotAcceptedByRecipient");
			
	Else
		QueryText = StrReplace(QueryText,"&ConditionForSeriesAccountingPolicyParameter",
			"BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
			|						AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingFromVendor
			|								AND &ReceiptFromVendor
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByReturnFromCustomer
			|								AND &ReceivingByReturnFromACustomer
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingProductsFromManufacturing
			|								AND &ProductReceivingFromManufacturing
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByTransfer
			|								AND &ReceivingByTransfer
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByOtherRecordingAsReceived
			|								AND &GoodsReceiptByOtherTransactions
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingComponentsAfterDisassembly
			|								AND &ReceivingOfComponentsAfterDisassembly
			|							OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenReceivingAssembledKits
			|								AND &ReceivingOfAssembledSets)");
	EndIf;
	
	Return QueryText;
	
EndFunction

#If Not MobileStandaloneServer Then

// Returns the value of the receipt or shipment order
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	Return FieldValuesToIdentifyReferences.ReferenceOrder;	
EndFunction

// Returns the request body for the get the available appointments
//	Parameters:
//		RequestFormationParameters - Structure - the parameters for the generation of text queries
//	Returns:
//		String - query text.
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	If RequestFormationParameters.OperationKind = PredefinedValue("Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient") Then
		Return Catalogs.Assignments.RequestTextForAllAppointments(RequestFormationParameters);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	Assignments.Ref AS Purpose,
	|	SUM(GoodsToReceive.Demand) AS Demand,
	|	SUM(GoodsToReceive.Demand) - MAX(ISNULL(DocumentData.Count, 0)) AS Balance
	|FROM
	|	(SELECT
	|		GoodsToReceiveBalance.Products AS Products,
	|		GoodsToReceiveBalance.Characteristic AS Characteristic,
	|		GoodsToReceiveBalance.Purpose AS Purpose,
	|		GoodsToReceiveBalance.GoodsReceiptNotesToRegisterBalance AS Demand
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				DocumentInflow = &ReferenceOrder
	|					AND (Products, Characteristic) IN (&FilterByGoods)
	|					AND Warehouse = &Warehouse
	|					AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS GoodsToReceiveBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToBeReceivedAtRegistrar.Products,
	|		GoodsToBeReceivedAtRegistrar.Characteristic,
	|		GoodsToBeReceivedAtRegistrar.Purpose,
	|		CASE
	|			WHEN GoodsToBeReceivedAtRegistrar.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN 0
	|			ELSE GoodsToBeReceivedAtRegistrar.GoodsReceiptNotesToRegister
	|		END
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS GoodsToBeReceivedAtRegistrar
	|	WHERE
	|		GoodsToBeReceivedAtRegistrar.DocumentInflow = &ReferenceOrder
	|		AND GoodsToBeReceivedAtRegistrar.Warehouse = &Warehouse
	|		AND GoodsToBeReceivedAtRegistrar.Recorder = &Recorder
	|		AND (GoodsToBeReceivedAtRegistrar.Products, GoodsToBeReceivedAtRegistrar.Characteristic) IN (&FilterByGoods)
	|		AND GoodsToBeReceivedAtRegistrar.Purpose <> VALUE(Catalog.Assignments.EmptyRef)) AS GoodsToReceive
	|		LEFT JOIN GoodsOfDocumentAreGrouped AS DocumentData
	|		ON GoodsToReceive.Products = DocumentData.Products
	|			AND GoodsToReceive.Characteristic = DocumentData.Characteristic
	|			AND GoodsToReceive.Purpose = DocumentData.Purpose
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON GoodsToReceive.Purpose = Assignments.Ref
	|WHERE
	|	GoodsToReceive.Purpose.RecordsInWarehouseRegisters
	|
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	Assignments.Ref";
	
	If RequestFormationParameters.TakeIntoAccountAlreadySelected Then
		// The request is not for dynamic lists
		QueryText =
		"SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Purpose,
		|	DocumentGoods.Count
		|INTO TableOfDocumentProducts
		|FROM
		|	&DocumentGoods AS DocumentGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfDocumentProducts.Products AS Products,
		|	TableOfDocumentProducts.Characteristic AS Characteristic,
		|	TableOfDocumentProducts.Purpose AS Purpose,
		|	SUM(TableOfDocumentProducts.Count) AS Count
		|INTO GoodsOfDocumentAreGrouped
		|FROM
		|	TableOfDocumentProducts AS TableOfDocumentProducts
		|WHERE
		|	(TableOfDocumentProducts.Products, TableOfDocumentProducts.Characteristic) IN (&FilterByGoods)
		|
		|GROUP BY
		|	TableOfDocumentProducts.Products,
		|	TableOfDocumentProducts.Characteristic,
		|	TableOfDocumentProducts.Purpose
		|;" + QueryText;
	Else
		QueryText = StrReplace(QueryText, "GoodsOfDocumentAreGrouped", "(" +
			"SELECT
			|	TRUE AS Products,
			|	TRUE AS Characteristic,
			|	TRUE AS Purpose,
			|	0 AS Count" + ")");
	EndIf;
	
	If RequestFormationParameters.ForSeveralProducts Then
		// The request is not for dynamic lists
		QueryText =
		"SELECT
		|	TableOfGoods.Products,
		|	TableOfGoods.Characteristic
		|INTO ProductSelectionTable
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductSelectionTable.Products,
		|	ProductSelectionTable.Characteristic
		|INTO GoodsGrouped
		|FROM
		|	ProductSelectionTable AS ProductSelectionTable
		|
		|GROUP BY
		|	ProductSelectionTable.Products,
		|	ProductSelectionTable.Characteristic
		|;" + QueryText;
		QueryText = StrReplace(QueryText, "&FilterByGoods",
			"SELECT
			|	GoodsGrouped.Products,
			|	GoodsGrouped.Characteristic
			|FROM
			|	GoodsGrouped AS GoodsGrouped");
	Else
		QueryText = StrReplace(QueryText, "&FilterByGoods",
			"SELECT
			|	&Products,
			|	&Characteristic");
	EndIf;
	
	If RequestFormationParameters.SortByDateOfAppointmentOrder Then
		QueryText = QueryText + "
		|ORDER BY
		|	Assignments.OrderDocument.Date";
	EndIf;
	
	Return QueryText;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.GoodsReceiptNote - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ControlIsSupported = QualityControl.QualityControlIsSupported(Object.ReferenceOrder);
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	Contract = Undefined;
	If Not Object.RecordOfAPreviouslyReceivedLot And ControlIsSupported And ContractRequired Then
		
		If ValueIsFilled(Object.ControlledLotReference) Then
			
			Query = New Query();
			Query.SetParameter("ControlledLotReference", Object.ControlledLotReference);
			Query.Text =
				"SELECT
				|	ControlledLotReference.Contract AS Contract
				|FROM
				|Catalog.ControlledLots AS ControlledLotReference
				|WHERE
				|	ControlledLotReference.Ref = &ControlledLotReference";
			SetPrivilegedMode(True);
			Selection = Query.Execute().Select();
			SetPrivilegedMode(False);
			If Selection.Next() Then
				Contract = Selection.Contract;
			EndIf;
			
		Else
			
			ObjectManager = Common.ObjectManagerByRef(Object.ReferenceOrder);
			PartyDetails = ObjectManager.AttributesOfControlledLotReference(Object.ReferenceOrder, "ControlledLotReference");
			Contract = PartyDetails.Contract;
			
		EndIf;
		
	EndIf;
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,ThisIsAPackingList";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.Warehouse);
	ActionParameters.QueryOptions.Insert("QualityControlIsMaintainedAtDisposalOf", ControlIsSupported);
	ActionParameters.QueryOptions.Insert("QualityControlOfRegisteredRecordsOfPreviouslyReceivedLotReferences",
		Object.RecordOfAPreviouslyReceivedLot);
	ActionParameters.QueryOptions.QualityControlContract = Contract;
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	
	ActionParameters.QueryOptions.QualityControlContract = Contract;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&WarehouseQualityControl AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	&QualityControlOfRegisteredRecordsOfPreviouslyReceivedLotReferences AS Set,
		|	Table.ThisIsAPackingList OR NOT &QualityControlIsMaintainedAtDisposalOf AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.GoodsReceiptNote";
	ActionParameters.ReadableFields = "Products,ThisIsAPackingList";
	ActionParameters.EditableFields = "QualityConfirmationDate";
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlControlledLotReference", Object.ControlledLotReference);
	ActionParameters.KeyDetailsOfHeader.Insert("QualityControlOfRegisteredRecordsOfPreviouslyReceivedLotReferences",
		Object.RecordOfAPreviouslyReceivedLot);
	ActionParameters.OverridableProcessingInObjectManager = True;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	&QualityControlControlledLotReference AS ControlledLotReference,
		|	&QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.ThisIsAPackingList AS Reset
		|INTO DataOfDocumentToBeFilledInMustBeUnblockedDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// The procedure for redefining the processing of the table part for the action "Fill in the required blockingthe Quality confirmation data".
// Parameters:
//  CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString
//  DataForProcessing - See BatchProcessingOfTablePartServer.DataForStringProcessing
//  ActionParameters - See QualityControl.New_ActionParameters
//  FillInRegular - Boolean - if the Truth is set inside the procedure, then the regular logic will be executed.
Procedure FillInUnblockableDateOfQualityConfirmation(CurrentRow, DataForProcessing, ActionParameters, FillInRegular) Export
	
	FillInRegular = False; // since there is no Controlled Party field in the table part.
	If ActionParameters.KeyDetailsOfHeader.QualityControlOfRegisteredRecordsOfPreviouslyReceivedLotReferences Then
		
		CurrentRow.QualityConfirmationDate = DataForProcessing.QualityConfirmationDate;
		// To be unblocked - not in the tabular part.
		// The controlled party is not in the tabular part.
		
	Else
		
		// Filled in with the action to fill in the Quality control dataconfirmation of quality.
		
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
	|	ValueAllowed(Warehouse)";

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
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.ThisIsAnInvoice			= False;
	JobPrintingRules.FieldNameRoom		= "Premise";
	JobPrintingRules.ThereArePackingLists	= True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#EndIf

#EndRegion

#If Not MobileStandaloneServer Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.Text = 
		"SELECT
		|	DocumentDataHeader.Date AS Period,
		|	DocumentDataHeader.Warehouse AS Warehouse,
		|	DocumentDataHeader.Status AS Status,
		|	DocumentDataHeader.ReferenceOrder AS ReferenceOrder,
		|	DocumentDataHeader.ControlledLotReference AS ControlledLotReference,
		|	DocumentDataHeader.WarehouseOperation AS WarehouseOperation,
		|	CASE
		|		WHEN DocumentDataHeader.UseWarerooms
		|				AND DocumentDataHeader.Date >= DocumentDataHeader.StartDateOfWareroomUse
		|			THEN DocumentDataHeader.UseBinLocationWarehousing
		|					AND DocumentDataHeader.Date >= DocumentDataHeader.StartDateOfUsingWarehouseBinSystem
		|		ELSE DocumentDataHeader.UseBinLocationWarehousing
		|				AND DocumentDataHeader.Date >= DocumentDataHeader.StartDateOfUsingWarehouseBinSystem
		|	END AS UseBinLocationWarehousing,
		|	DocumentDataHeader.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|		AND DocumentDataHeader.Date >= DocumentDataHeader.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	DocumentDataHeader.ReceivingArea AS ReceivingArea,
		|	DocumentDataHeader.Premise AS Premise,
		|	DocumentDataHeader.ReturnOfGoodsNotReceivedByRecipient AS ReturnOfGoodsNotReceivedByRecipient,
		|	DocumentDataHeader.Sender AS Sender,
		|	DocumentDataHeader.BusinessOperation AS BusinessOperation
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader";
	Result = Query.Execute();

	ParametersStructure = TMCommonUse.FirstLineOfQueryResultInStructure(Result);
	TMCommonUse.SetRequestParameters(Query, ParametersStructure);

	TypesOfExpectedAdmission = Metadata.DefinedTypes.ExpectedReceipt.Type.Types();
	Query.SetParameter("TypesOfExpectedAdmission", TypesOfExpectedAdmission);

EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager();

	If DocumentRef = Undefined Then
		Return;
	EndIf;

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();

EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = 
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Warehouse AS Warehouse,
		|	DocumentData.Status AS Status,
		|	DocumentData.ReferenceOrder AS ReferenceOrder,
		|	DocumentData.ControlledLotReference AS ControlledLotReference,
		|	DocumentData.RecordOfAPreviouslyReceivedLot AS RecordOfAPreviouslyReceivedLot,
		|	DocumentData.SubjectToUnlocking AS SubjectToUnlocking,
		|	DocumentData.WarehouseOperation AS WarehouseOperation,
		|	DocumentData.WarehouseOperation IN (VALUE(Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient), VALUE(Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed)) AS ReturnOfGoodsNotReceivedByRecipient,
		|	Warehouses.UseWarerooms AS UseWarerooms,
		|	Warehouses.StartDateOfWareroomUse AS StartDateOfWareroomUse,
		|	Warerooms.UseBinLocationWarehousing AS PremisesToUseBinLocationSystem,
		|	Warerooms.StartDateOfUsingWarehouseBinSystem AS PremisesStartDateOfBinLocationSystemOfLeftovers,
		|	Warehouses.UseBinLocationWarehousing AS UseBinLocationWarehousing,
		|	Warehouses.StartDateOfUsingWarehouseBinSystem AS StartDateOfUsingWarehouseBinSystem,
		|	Warehouses.UseWarehouseManagemantSystemForGoodsSurplusesShortages AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	Warehouses.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages,
		|	DocumentData.ReceivingArea AS ReceivingArea,
		|	DocumentData.Premise AS Premise,
		|	DocumentData.Sender AS Sender,
		|	DocumentData.BusinessOperation AS BusinessOperation
		|INTO DocumentDataHeader
		|FROM
		|	Document.GoodsReceiptNote AS DocumentData
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON (Warehouses.Ref = DocumentData.Warehouse)
		|		LEFT JOIN Catalog.Warerooms AS Warerooms
		|		ON (Warerooms.Ref = DocumentData.Premise)
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods =
	"SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.ToControlQuality AS ToControlQuality,
	|	GoodsTable.QualityConfirmationDate AS QualityConfirmationDate,
	|	GoodsTable.ThisIsAPackingList AS ThisIsAPackingList,
	|	GoodsTable.Count AS Count,
	|	Packages.PackageType AS PackagingTypeOfPackaging,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages
	|INTO DocumentDataTableItems
	|FROM
	|	Document.GoodsReceiptNote.Goods AS GoodsTable
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON (Packages.Ref = GoodsTable.Package)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";

	ListOfRequests.Add(QueryTextTableGoods);

EndProcedure

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure TakeGoodsToWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|	DocumentDataHeader.Date AS Date,
		|	DocumentDataHeader.Warehouse AS Warehouse,
		|	DocumentDataHeader.ReceivingArea AS Cell,
		|	DocumentDataHeader.Premise AS Premise,
		|	DocumentDataHeader.Sender AS Sender,
		|	DocumentDataHeader.ReferenceOrder AS ReferenceOrder,
		|	GoodsTable.ToControlQuality AS ToControlQuality,
		|	DocumentDataHeader.RecordOfAPreviouslyReceivedLot AS RecordOfAPreviouslyReceivedLot,
		|	DocumentDataHeader.ControlledLotReference AS ControlledLotReference,
		|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.ThisIsAPackingList AS ThisIsAPackingList,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	DocumentDataHeader.Status IN (VALUE(Enum.GoodsReceiptNoteStatuses.ToReceive), VALUE(Enum.GoodsReceiptNoteStatuses.InProgress), VALUE(Enum.GoodsReceiptNoteStatuses.DataProcessorIsRequired)) AS Accepts,
		|	DocumentDataHeader.Status = VALUE(Enum.GoodsReceiptNoteStatuses.Accepted) AS Accepted,
		|	DocumentDataHeader.ReturnOfGoodsNotReceivedByRecipient AS ThisIsAcceptanceWithoutOrder
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = GoodsTable.Ref)
		|WHERE
		|	NOT GoodsTable.ThisIsAPackingList
		|	AND GoodsTable.Count <> 0";
	
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "GoodsTable");
	
EndProcedure

Procedure RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|	DocumentDataHeader.Date AS Date,
		|	DocumentDataHeader.Warehouse AS Warehouse,
		|	DocumentDataHeader.Premise AS Premise,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	DocumentDataHeader.ReceivingArea AS Cell,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	FALSE AS RemainderChanges
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = GoodsTable.Ref)
		|WHERE
		|	GoodsTable.Count <> 0
		|	AND DocumentDataHeader.Status = VALUE(Enum.GoodsReceiptNoteStatuses.Accepted)
		|	AND DocumentDataHeader.ReturnOfGoodsNotReceivedByRecipient";
	
	WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Count AS Count,
	|	DocumentDataHeader.Warehouse AS Recipient,
	|	DocumentDataHeader.Premise AS WareroomOfRecipient,
	|	DocumentDataHeader.Sender AS Sender,
	|	DocumentDataHeader.WarehouseOperation AS WarehouseOperation,
	|	GoodsTable.Ref AS Document,
	|	DocumentDataHeader.Date AS Period,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	TTTableProducts AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|		ON (DocumentDataHeader.Ref = GoodsTable.Ref)
	|WHERE
	|	GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
		
	QueryText = 
	"SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.Count AS Count
	|INTO TTTableProducts
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|	AND NOT GoodsTable.ThisIsAPackingList
	|	AND ISNULL(GoodsTable.PackagingTypeOfPackaging, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	SUM(ReceiptOrderForGoodsGoodsQuantity.Count)
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Purpose AS Purpose,
	|		GoodsTable.Series AS Series,
	|		MAX(GoodsTable.Package) AS Package,
	|		GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|	FROM
	|		DocumentDataTableItems AS GoodsTable
	|	WHERE
	|		NOT GoodsTable.ThisIsAPackingList
	|		AND ISNULL(GoodsTable.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	
	|	GROUP BY
	|		GoodsTable.Ref,
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Purpose,
	|		GoodsTable.Series,
	|		GoodsTable.BatchesIndicationStatus) AS Table
	|		INNER JOIN DocumentDataTableItems AS ReceiptOrderForGoodsGoodsQuantity
	|		ON Table.Products = ReceiptOrderForGoodsGoodsQuantity.Products
	|			AND Table.Characteristic = ReceiptOrderForGoodsGoodsQuantity.Characteristic
	|			AND Table.Series = ReceiptOrderForGoodsGoodsQuantity.Series
	|			AND Table.Purpose = ReceiptOrderForGoodsGoodsQuantity.Purpose
	|			AND Table.Package = ReceiptOrderForGoodsGoodsQuantity.Package
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject)

	If DocumentObject <> Undefined
		And DocumentObject.Status <> Enums.GoodsReceiptNoteStatuses.Accepted Then
		Return;
	EndIf;

	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	DocumentDataHeader.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	DocumentDataHeader.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	DocumentDataHeader.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	DocumentDataHeader.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	VALUETYPE(DocumentDataHeader.ReferenceOrder) IN (&TypesOfExpectedAdmission) AS OnSchedule,
		|	CASE
		|		WHEN DocumentDataHeader.RecordOfAPreviouslyReceivedLot
		|			THEN DocumentDataHeader.ControlledLotReference
		|		ELSE DocumentDataHeader.ReferenceOrder
		|	END AS OrderInSchedule
		|FROM
		|	DocumentDataTableItems AS TabPart
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = TabPart.Ref)
		|WHERE
		|	NOT TabPart.ThisIsAPackingList
		|	AND TabPart.Count <> 0
		|	AND ISNULL(TabPart.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	AND DocumentDataHeader.Status = VALUE(Enum.GoodsReceiptNoteStatuses.Accepted)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
	TextProductLocations =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.Series AS Series,
		|	MAX(TabPart.Package) AS Package
		|INTO ProductLocations
		|FROM
		|	DocumentDataTableItems AS TabPart
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = TabPart.Ref)
		|WHERE
		|	NOT TabPart.ThisIsAPackingList
		|	AND TabPart.Count <> 0
		|	AND TabPart.PackagingTypeOfPackaging = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	AND DocumentDataHeader.Status = VALUE(Enum.GoodsReceiptNoteStatuses.Accepted)
		|
		|GROUP BY
		|	TabPart.Ref,
		|	TabPart.Products,
		|	TabPart.Characteristic,
		|	TabPart.Purpose,
		|	TabPart.Series
		|
		|INDEX BY
		|	Ref,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	Package";
		
	TemporaryTableTemplateTexts = New Structure();
	TemporaryTableTemplateTexts.Insert("ProductLocations", TextProductLocations);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	DocumentDataHeader.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	DocumentDataHeader.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	DocumentDataHeader.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	DocumentDataHeader.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	VALUETYPE(DocumentDataHeader.ReferenceOrder) IN (&TypesOfExpectedAdmission) AS OnSchedule,
		|	CASE
		|		WHEN DocumentDataHeader.RecordOfAPreviouslyReceivedLot
		|			THEN DocumentDataHeader.ControlledLotReference
		|		ELSE DocumentDataHeader.ReferenceOrder
		|	END AS OrderInSchedule
		|FROM
		|	DocumentDataTableItems AS TabPart
		|		INNER JOIN ProductLocations AS ProductLocations
		|		ON TabPart.Ref = ProductLocations.Ref
		|			AND TabPart.Products = ProductLocations.Products
		|			AND TabPart.Characteristic = ProductLocations.Characteristic
		|			AND TabPart.Purpose = ProductLocations.Purpose
		|			AND TabPart.Series = ProductLocations.Series
		|			AND TabPart.Package = ProductLocations.Package
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|		ON (DocumentDataHeader.Ref = TabPart.Ref)
		|WHERE
		|	NOT TabPart.ThisIsAPackingList
		|	AND TabPart.Count <> 0
		|	AND TabPart.PackagingTypeOfPackaging = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	AND DocumentDataHeader.Status = VALUE(Enum.GoodsReceiptNoteStatuses.Accepted)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True,
		TemporaryTableTemplateTexts);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("Update", Metadata.Documents.GoodsReceiptNote) Then
		// Receipt order for goods
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "GoodsReceiptNote";
		PrintCommand.Presentation = NStr("vi = 'Phiếu nhập kho';
										|ru = 'Приходный ордер на товары';
										|en = 'Goods receipt'; fa = 'رسید انبار';
										|it = 'Reversale d''incasso per le merci';
										|pl = 'Asygnata przychodowa na wiersze pozycji';
										|tr = 'Ambar giriş fişi'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	// The form of acceptance of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "GoodsReceivingForm";
	PrintCommand.Presentation = NStr("vi = 'Mẫu tiếp nhận hàng hóa';
									|ru = 'Бланк приемки товаров';
									|en = 'Goods receipt form'; fa = 'فرم دریافت کالا';
									|it = 'Modulo di accettazione merci';
									|pl = 'Formularz przyjęcia towarów';
									|tr = 'Mal girişi formu'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
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
	EndIf;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsReceiptNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsReceiptNote",
			NStr("vi = 'Phiếu nhập kho';
				|ru = 'Приходный ордер на товары';
				|en = 'Goods receipt'; fa = 'رسید انبار';
				|it = 'Reversale d''incasso per le merci';
				|pl = 'Asygnata przychodowa na wiersze pozycji';
				|tr = 'Ambar giriş fişi'"),
			PrintingReceiptOrderForGoods(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsReceivingForm") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsReceivingForm",
			NStr("vi = 'Mẫu tiếp nhận hàng hóa';
				|ru = 'Бланк приемки товаров';
				|en = 'Goods receipt form'; fa = 'فرم دریافت کالا';
				|it = 'Modulo di accettazione merci';
				|pl = 'Formularz przyjęcia towarów';
				|tr = 'Mal girişi formu'"),
			PrintingOfGoodsAcceptanceForm(ObjectsArray, PrintObjects));
	EndIf;
EndProcedure

Function PrintingReceiptOrderForGoods(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsReceiptNote_GoodsReceiptNote";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	DocumentAttributes = New Structure("Number, Date, Prefix,Presentation");
	DocumentSynonym = NStr("vi = 'Phiếu nhập kho';
							|ru = 'Приходный ордер на товары';
							|en = 'Goods receipt'; fa = 'رسید انبار';
							|it = 'Reversale d''incasso per le merci';
							|pl = 'Asygnata przychodowa na wiersze pozycji';
							|tr = 'Ambar giriş fişi'", Common.DefaultLanguageCode());
	
	UseItemPackages = GetFunctionalOption("UseItemPackages");
	MarkedProductsAreUsed = GoodsReceiptNoteLocalization.MarkedProductsAreUsed();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsReceiptNote.Ref AS Ref,
	|	PRESENTATION(GoodsReceiptNote.Warehouse) AS WarehousePresentation_,
	|	PRESENTATION(GoodsReceiptNote.Premise) AS PresentationOfPremises,
	|	PRESENTATION(GoodsReceiptNote.ReceivingArea) AS PresentationOfAcceptanceArea,
	|	PRESENTATION(GoodsReceiptNote.Sender) AS PartnerPresentation_,
	|	PRESENTATION(GoodsReceiptNote.ReferenceOrder) AS ReferenceOrderPresentation,
	|	CASE
	|		WHEN GoodsReceiptNote.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(GoodsReceiptNote.ReferenceOrder AS Catalog.TermsOfPurchaseFromVendors).Number
	|		ELSE ISNULL(DetailsOfOrder.IBDocumentNumber, """""""")
	|	END AS OrderNumber__,
	|	CASE
	|		WHEN GoodsReceiptNote.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(GoodsReceiptNote.ReferenceOrder AS Catalog.TermsOfPurchaseFromVendors).Date
	|		ELSE ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1, 1, 1))
	|	END AS Order_Date,
	|	CASE
	|		WHEN GoodsReceiptNote.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(GoodsReceiptNote.ReferenceOrder AS Catalog.TermsOfPurchaseFromVendors).Organization.Prefix
	|		ELSE ISNULL(DetailsOfOrder.Organization.Prefix, """""""")
	|	END AS OrderPrefix_,
	|	GoodsReceiptNote.Date,
	|	GoodsReceiptNote.Number,
	|	GoodsReceiptNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	GoodsReceiptNote.Performer.Individual AS Performer,
	|	GoodsReceiptNote.Warehouse AS Warehouse,
	|	GoodsReceiptNote.Premise AS Premise,
	|	GoodsReceiptNote.Warehouse.UseItemsBatch AS UseItemsBatch,
	|	GoodsReceiptNote.IncomingDocumentDate AS IncomingDocumentDate,
	|	GoodsReceiptNote.IncomingDocumentNumber AS IncomingDocumentNumber
	|FROM
	|	Document.GoodsReceiptNote AS GoodsReceiptNote
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON (NOT DetailsOfOrder.AdditionalRecord)
	|			AND GoodsReceiptNote.ReferenceOrder = DetailsOfOrder.Ref
	|WHERE
	|	GoodsReceiptNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	GoodsReceiptNote.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReceiptOrderForGoodsGoods.Ref AS Ref,
	|	ReceiptOrderForGoodsGoods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN &ColumnOfCodes = ""SKU""
	|			THEN ReceiptOrderForGoodsGoods.Products.SKU
	|		WHEN &ColumnOfCodes = ""Code""
	|			THEN ReceiptOrderForGoodsGoods.Products.Code
	|		ELSE """"
	|	END AS SKU,
	|	ReceiptOrderForGoodsGoods.ThisIsAPackingList AS ThisIsAPackingList,
	|	PRESENTATION(ReceiptOrderForGoodsGoods.PackingList) AS PackingList,
	|	ReceiptOrderForGoodsGoods.Products.DescriptionFull AS ProductPresentation,
	|	ReceiptOrderForGoodsGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	ReceiptOrderForGoodsGoods.Products AS Products,
	|	ReceiptOrderForGoodsGoods.Characteristic AS Characteristic,
	|	ReceiptOrderForGoodsGoods.Series AS Series,
	|	PRESENTATION(ReceiptOrderForGoodsGoods.Series) AS BatchPresentation,
	|	ReceiptOrderForGoodsGoods.NumberOfPackages AS NumberOfPackages,
	|	ReceiptOrderForGoodsGoods.Count AS Count,
	|	PRESENTATION(ReceiptOrderForGoodsGoods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	CASE
	|		WHEN ReceiptOrderForGoodsGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(ReceiptOrderForGoodsGoods.Package)
	|		ELSE PRESENTATION(ReceiptOrderForGoodsGoods.Products.UnitOfMeasure)
	|	END AS PresentationOfPackingUnit,
	|	FALSE AS MarkedProducts,
	|	NULL AS BatchUsageSettings
	|INTO TableOfGoods
	|FROM
	|	Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsGoods
	|, ConnectionTable
	|WHERE
	|	ReceiptOrderForGoodsGoods.Ref IN (&ObjectsArray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref,
	|	TableOfGoods.SKU,
	|	TableOfGoods.ThisIsAPackingList,
	|	TableOfGoods.PackingList,
	|	TableOfGoods.ProductPresentation,
	|	TableOfGoods.CharacteristicPresentation,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.BatchPresentation,
	|	TableOfGoods.NumberOfPackages,
	|	TableOfGoods.Count,
	|	TableOfGoods.PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.PresentationOfPackingUnit,
	|	TableOfGoods.BatchUsageSettings,
	|	TableOfGoods.MarkedProducts,
	|	LineNumber
	|FROM
	|	TableOfGoods
	|ORDER BY
	|	Ref,
	|	TableOfGoods.LineNumber
	|TOTALS
	|BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref,
	|	MAX(TableOfGoods.MarkedProducts) AS ThereAreLabeledProducts
	|FROM
	|	TableOfGoods AS TableOfGoods
	|GROUP BY
	|	TableOfGoods.Ref";

	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("ColumnOfCodes", NameOfCodeColumn);
	
	QueriesTexts = ProductsLocalization.QueryTextsForItemDetails();
	ProductsLocalization.FillInQueryTextDetailsOfItem("ReceiptOrderForGoodsGoods.Products", QueriesTexts);
	If MarkedProductsAreUsed Then
		Query.Text = StrReplace(Query.Text, "FALSE AS MarkedProducts", QueriesTexts.DetailsOfItemSelection);
	EndIf; 
	Query.Text = StrReplace(Query.Text, ", ConnectionTable", QueriesTexts.DetailsOfConnectionNomenclature);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[0]; // QueryResult
	SelectionByDocuments = QueryResult.Select();
	
	QueryResult = ResultsArray[2]; // QueryResult
	SelectionByTableParts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	QueryResult   = ResultsArray[3]; // QueryResult
	SelectionByBrand    = QueryResult.Select();

	FirstDocument = True;
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		If SelectionByBrand.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			DisplayStamps = SelectionByBrand.ThereAreLabeledProducts;
		Else
			DisplayStamps = False;
		EndIf;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		BinLocationWarehousingIsUsed = WarehousesServer.UseBinLocationWarehousing(
		SelectionByDocuments.Warehouse, SelectionByDocuments.Premise, SelectionByDocuments.Date);
		
		DisplayingPackages = UseItemPackages Or BinLocationWarehousingIsUsed;
		
		// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
		Template = PrintManagement.PrintFormTemplate("Document.GoodsReceiptNote.PF_MXL_GoodsReceiptNote");
		
		HeaderArea_ 		= Template.GetArea("Title");
		SectionHeader 			= Template.GetArea("Header");
		ScopeOfApplication_6	 	= Template.GetArea("Vendor");
		
		TableHeaderAreaStart 	= Template.GetArea("TableHeader|BeginningOfTheLine");
		AreaTableRowStart 	= Template.GetArea("TableRow|BeginningOfTheLine");
		AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");
		
		AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeader|ColumnOfCodes");
		AreaTableRowCodeColumn 	= Template.GetArea("TableRow|ColumnOfCodes");
		AreaBasementTableColumnCodes 	= Template.GetArea("TableFooter|ColumnOfCodes");
		
		AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		
		AreaTableHeaderPackingColumn 		= Template.GetArea("TableHeader|ColumnOfPackages");
		AreaTableRowPackingColumn 	= Template.GetArea("TableRow|ColumnOfPackages");
		AreaBasementTablePackingColumn		= Template.GetArea("TableFooter|ColumnOfPackages");
		
		AreaTableHeaderMarkingColumn 	= Template.GetArea("TableHeader|MarkingColumn");
		AreaTableRowMarkingColumn 	= Template.GetArea("TableRow|MarkingColumn");
		AreaBasementTableMarkingColumn	= Template.GetArea("TableFooter|MarkingColumn");
		
		SignatureArea = Template.GetArea("Signatures");
		
		ProductColumnArea_ = Template.Area("ProductColumn_");
		
		If Not OutputCodes Then
			ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf;
		
		If Not DisplayingPackages Then
			ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("ColumnOfPackagesQuantity").ColumnWidth
			+ Template.Area("ColumnOfPackagesPresentation").ColumnWidth; 		
		EndIf;
		
		If Not MarkedProductsAreUsed Then
			ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + Template.Area("MarkingColumn").ColumnWidth; 		
		EndIf;
		
		AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
		AreaTableRowProductColumn 	= Template.GetArea("TableRow|ProductColumn_");
		AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
		
		TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
		AreaTableRowEnd 	= Template.GetArea("TableRow|EndOfRow");
		AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		If BinLocationWarehousingIsUsed Then
			
			ZoneText = NStr("vi = 'Khu vực tiếp nhận:';
							|ru = 'Зона приемки:';
							|en = 'Inbound area:'; fa = 'ناحیه ورودی:';
							|it = 'Area di accettazione:';
							|pl = 'Stefa przyjęcia:';
							|tr = 'Boşaltma alanı:'", Common.DefaultLanguageCode());
			ZonePresentation = SelectionByDocuments.PresentationOfAcceptanceArea;
			
		Else
			
			ZoneText = "";
			ZonePresentation = "";
			
		EndIf;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		
		HeaderDataStructure = New Structure;
		HeaderDataStructure.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		HeaderArea_.Parameters.Fill(HeaderDataStructure);
		
		If DisplayStamps Then
			HeaderArea_.Parameters.MarkingAttribute = "[M]";
		EndIf; 
		
		SpreadsheetDocument.Put(HeaderArea_);
		
		If ValueIsFilled(SelectionByDocuments.PartnerPresentation_) Then
			// if not moving or posting
			ScopeOfApplication_6.Parameters.Fill(SelectionByDocuments);
			SpreadsheetDocument.Put(ScopeOfApplication_6);
		EndIf;
		
		HeaderParameters_ = New Structure;
		HeaderParameters_.Insert("WarehousePresentation_",
		WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation_,SelectionByDocuments.PresentationOfPremises));
		HeaderParameters_.Insert("ZoneText", ZoneText);
		HeaderParameters_.Insert("PresentationOfAcceptanceArea", ZonePresentation);
		PresentationOfIncomingDocument = ?(IsBlankString(SelectionByDocuments.IncomingDocumentNumber),"","№ " + TrimAll(SelectionByDocuments.IncomingDocumentNumber))
		+ ?(Not ValueIsFilled(SelectionByDocuments.IncomingDocumentDate),""," dated " + Format(SelectionByDocuments.IncomingDocumentDate,"DLF=D"));
		HeaderParameters_.Insert("PresentationOfIncomingDocument", PresentationOfIncomingDocument);
		
		SectionHeader.Parameters.Fill(HeaderParameters_);
		
		If Not ValueIsFilled(SelectionByDocuments.Order_Date)
			Or Not ValueIsFilled(SelectionByDocuments.OrderNumber__) Then
			SectionHeader.Parameters.PresentationOfOrder	= SelectionByDocuments.ReferenceOrderPresentation;
		Else
			DocumentAttributes.Date          = SelectionByDocuments.Order_Date;
			DocumentAttributes.Number         = SelectionByDocuments.OrderNumber__;
			DocumentAttributes.Prefix       = SelectionByDocuments.OrderPrefix_;
			DocumentAttributes.Presentation = SelectionByDocuments.ReferenceOrderPresentation;
			
			SectionHeader.Parameters.PresentationOfOrder	= TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
		EndIf;
		
		SpreadsheetDocument.Put(SectionHeader);
		
		SpreadsheetDocument.Put(TableHeaderAreaStart);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
		EndIf;
		
		SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
		
		If MarkedProductsAreUsed Then
			SpreadsheetDocument.Join(AreaTableHeaderMarkingColumn);
		EndIf;
		
		If DisplayingPackages Then
			SpreadsheetDocument.Join(AreaTableHeaderPackingColumn);
		EndIf;
		
		SpreadsheetDocument.Join(TableHeaderAreaEnd);
		
		TotalItems_1 = 0;
		
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		FirstRow = True;
		StringOfPackages = "";
		StringQuantityOfPackages = "";
		UnitString = "";
		CountRow = "";
		
		While SamplingByTSLines.Next() Do
			
			AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
			AreaTableRowStart.Parameters.Fill(New Structure("LineNumber", TotalItems_1 + 1));
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
			
			If SamplingByTSLines.ThisIsAPackingList Then
				AreaTableRowProductColumn.Parameters.OwnGoods = SamplingByTSLines.PackingList;
			Else
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				, // Package
				SamplingByTSLines.BatchPresentation,
				AdditionalParametersProductPresentation);
			EndIf;
			
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			TotalItems_1 = TotalItems_1 + 1;
			
			If MarkedProductsAreUsed Then
				If DisplayStamps And SamplingByTSLines.MarkedProducts Then
					AreaTableRowMarkingColumn.Parameters.MarkingAttribute = "[M]";
				Else	
					AreaTableRowMarkingColumn.Parameters.MarkingAttribute = "";
				EndIf; 
				SpreadsheetDocument.Join(AreaTableRowMarkingColumn);
			EndIf;
			
			If DisplayingPackages Then
				AreaTableRowPackingColumn.Parameters.Fill(SamplingByTSLines);
				If SamplingByTSLines.ThisIsAPackingList Then
					AreaTableRowPackingColumn.Parameters.PresentationOfPackingUnit = NStr("vi = 'vị trí';
																							|ru = 'место';
																							|en = 'place'; fa = 'place';
																							|it = 'luogo';
																							|pl = 'place';
																							|tr = 'yer'", Common.DefaultLanguageCode());
				EndIf;
				SpreadsheetDocument.Join(AreaTableRowPackingColumn);
			EndIf;
			
			AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
			If SamplingByTSLines.ThisIsAPackingList Then
				AreaTableRowEnd.Parameters.PresentationOfBasicUnitOfMeasure = NStr("vi = 'vị trí';
																					|ru = 'место';
																					|en = 'place'; fa = 'place';
																					|it = 'luogo';
																					|pl = 'place';
																					|tr = 'yer'", Common.DefaultLanguageCode());
			EndIf;
			SpreadsheetDocument.Join(AreaTableRowEnd);
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		
		If MarkedProductsAreUsed Then
			SpreadsheetDocument.Join(AreaBasementTableMarkingColumn);
		EndIf;
		
		If DisplayingPackages Then
			SpreadsheetDocument.Join(AreaBasementTablePackingColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng: %TotalItems_1%';
									|ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
									|it = 'Totale articoli %TotalItems_1%';
									|pl = 'Razem pozycji %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		SignatureArea.Parameters.TotalString = TextOfResultingLine;
		
		SignatureArea.Parameters.EmployeeResponsiblePresentation = PersonsTM.IndividualShortName(SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
		SignatureArea.Parameters.ArtistPresentation = PersonsTM.IndividualShortName(SelectionByDocuments.Performer, SelectionByDocuments.Date);
		
		SpreadsheetDocument.Put(SignatureArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;	
	
EndFunction

Function PrintingOfGoodsAcceptanceForm(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsReceiptNote_GoodsReceivingForm";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	DocumentAttributes = New Structure("Number, Date, Prefix,Presentation");
	DocumentSynonym = NStr("vi = 'Mẫu tiếp nhận hàng hóa';
							|ru = 'Бланк приемки товаров';
							|en = 'Goods receipt form'; fa = 'فرم دریافت کالا';
							|it = 'Modulo di accettazione merci';
							|pl = 'Formularz przyjęcia towarów';
							|tr = 'Mal girişi formu'", Common.DefaultLanguageCode());
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsReceiptNote.Ref AS Ref,
	|	PRESENTATION(GoodsReceiptNote.Warehouse) AS WarehousePresentation_,
	|	PRESENTATION(GoodsReceiptNote.Premise) AS PresentationOfPremises,
	|	PRESENTATION(GoodsReceiptNote.ReceivingArea) AS PresentationOfAcceptanceArea,
	|	PRESENTATION(GoodsReceiptNote.Sender) AS PartnerPresentation_,
	|	PRESENTATION(GoodsReceiptNote.ReferenceOrder) AS ReferenceOrderPresentation,
	|	CASE
	|		WHEN GoodsReceiptNote.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(GoodsReceiptNote.ReferenceOrder AS Catalog.TermsOfPurchaseFromVendors).Number
	|		ELSE ISNULL(DetailsOfOrder.IBDocumentNumber, """""""")
	|	END AS OrderNumber__,
	|	CASE
	|		WHEN GoodsReceiptNote.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(GoodsReceiptNote.ReferenceOrder AS Catalog.TermsOfPurchaseFromVendors).Date
	|		ELSE ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1, 1, 1))
	|	END AS Order_Date,
	|	CASE
	|		WHEN GoodsReceiptNote.ReferenceOrder REFS Catalog.TermsOfPurchaseFromVendors
	|			THEN CAST(GoodsReceiptNote.ReferenceOrder AS Catalog.TermsOfPurchaseFromVendors).Organization.Prefix
	|		ELSE ISNULL(DetailsOfOrder.Organization.Prefix, """""""")
	|	END AS OrderPrefix_,
	|	GoodsReceiptNote.Date,
	|	GoodsReceiptNote.Number,
	|	GoodsReceiptNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	GoodsReceiptNote.Performer.Individual AS Performer,
	|	GoodsReceiptNote.Warehouse AS Warehouse,
	|	GoodsReceiptNote.Premise AS Premise,
	|	GoodsReceiptNote.Warehouse.UseItemsBatch AS UseItemsBatch,
	|	GoodsReceiptNote.IncomingDocumentDate AS IncomingDocumentDate,
	|	GoodsReceiptNote.IncomingDocumentNumber AS IncomingDocumentNumber
	|FROM
	|	Document.GoodsReceiptNote AS GoodsReceiptNote
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
	|		ON (NOT DetailsOfOrder.AdditionalRecord)
	|			AND GoodsReceiptNote.ReferenceOrder = DetailsOfOrder.Ref
	|WHERE
	|	GoodsReceiptNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	GoodsReceiptNote.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReceiptOrderForGoodsGoods.Ref AS Ref,
	|	ReceiptOrderForGoodsGoods.ThisIsAPackingList AS ThisIsAPackingList,
	|	PRESENTATION(ReceiptOrderForGoodsGoods.PackingList) AS PackingList,
	|	CASE
	|		WHEN &ColumnOfCodes = ""SKU""
	|			THEN ReceiptOrderForGoodsGoods.Products.SKU
	|		WHEN &ColumnOfCodes = ""Code""
	|			THEN ReceiptOrderForGoodsGoods.Products.Code
	|		ELSE """"
	|	END AS SKU,
	|	CASE
	|		WHEN ReceiptOrderForGoodsGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN ReceiptOrderForGoodsGoods.Products.UnitOfMeasure.Presentation
	|		ELSE ReceiptOrderForGoodsGoods.Package.Presentation
	|	END AS UnitOfMeasurePresentation,
	|	ReceiptOrderForGoodsGoods.NumberOfPackages AS Count,
	|	ReceiptOrderForGoodsGoods.Products.DescriptionFull AS ProductPresentation,
	|	ReceiptOrderForGoodsGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	ReceiptOrderForGoodsGoods.Series AS Series,
	|	ReceiptOrderForGoodsGoods.Series.Description AS BatchPresentation,
	|	ReceiptOrderForGoodsGoods.BatchesIndicationStatus,
	|	ReceiptOrderForGoodsGoods.LineNumber,
	|	ReceiptOrderForGoodsGoods.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings,
	|	ReceiptOrderForGoodsGoods.Products.ProductKind.SpecifyNumberWhenRegisteringBatch AS SpecifyNumberWhenRegisteringBatch,
	|	ReceiptOrderForGoodsGoods.Products.ProductKind.UseShelfLifeOnBatchRegistration AS UseShelfLifeOnBatchRegistration
	|FROM
	|	Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsGoods
	|WHERE
	|	ReceiptOrderForGoodsGoods.Ref IN(&ObjectsArray)
	|	AND ReceiptOrderForGoodsGoods.PackingListParent = VALUE(Document.PackingList.EmptyRef)
	|
	|ORDER BY
	|	Ref,
	|	ReceiptOrderForGoodsGoods.LineNumber
	|
	|TOTALS BY
	|	Ref";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("ColumnOfCodes", NameOfCodeColumn);
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[0]; // QueryResult
	SelectionByDocuments = QueryResult.Select();
		
	QueryResult = ResultsArray[1]; // QueryResult
	SelectionByTableParts = QueryResult.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	Template = PrintManagement.PrintFormTemplate("Document.GoodsReceiptNote.PF_MXL_GoodsReceivingForm");
	HeaderArea_ 		= Template.GetArea("Title");
	SectionHeader 			= Template.GetArea("Header");
	ScopeOfApplication_6	 	= Template.GetArea("Vendor");
	
	TableHeaderAreaStart 	= Template.GetArea("TableHeader|BeginningOfTheLine");
	AreaTableRowStart 	= Template.GetArea("TableRow|BeginningOfTheLine");
	AreaLineSeriesStart    = Template.GetArea("SeriesString|StartOfSeriesLine");
	AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");
	
	AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeader|ColumnOfCodes");
	AreaTableRowCodeColumn 	= Template.GetArea("TableRow|ColumnOfCodes");
	AreaBasementTableColumnCodes 	= Template.GetArea("TableFooter|ColumnOfCodes");
	
	AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
	
	SignatureArea = Template.GetArea("Signatures");
	
	ProductColumnArea_ = Template.Area("ProductColumn_");
	
	WidthOfCodesColumn = Template.Area("ColumnOfCodes").ColumnWidth;
	
	If Not OutputCodes Then
		ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth + WidthOfCodesColumn;
	EndIf;
	
	AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
	AreaTableRowProductColumn 	= Template.GetArea("TableRow|ProductColumn_");
	AreaSeriesRowSeriesColumn 		= Template.GetArea("SeriesString|SeriesColumn");
	AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
	
	TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
	AreaTableRowEnd 	= Template.GetArea("TableRow|EndOfRow");
	AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");
	
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		BinLocationWarehousingIsUsed = WarehousesServer.UseBinLocationWarehousing(
			SelectionByDocuments.Warehouse, SelectionByDocuments.Premise, SelectionByDocuments.Date);
		
		If BinLocationWarehousingIsUsed Then
			
			ZoneText = NStr("vi = 'Khu vực tiếp nhận:';
							|ru = 'Зона приемки:';
							|en = 'Inbound area:'; fa = 'ناحیه ورودی:';
							|it = 'Area di accettazione:';
							|pl = 'Stefa przyjęcia:';
							|tr = 'Boşaltma alanı:'", Common.DefaultLanguageCode());
			ZonePresentation = SelectionByDocuments.PresentationOfAcceptanceArea;
			
		Else
			
			ZoneText = "";
			ZonePresentation = "";
			
		EndIf;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		
		HeaderDataStructure = New Structure;
		HeaderDataStructure.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		HeaderArea_.Parameters.Fill(HeaderDataStructure);
		
		SpreadsheetDocument.Put(HeaderArea_);
		
		If ValueIsFilled(SelectionByDocuments.PartnerPresentation_) Then
			// if not moving or posting
			ScopeOfApplication_6.Parameters.Fill(SelectionByDocuments);
			SpreadsheetDocument.Put(ScopeOfApplication_6);
		EndIf;
		
		HeaderParameters_ = New Structure;
		HeaderParameters_.Insert("WarehousePresentation_", WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation_,
																								SelectionByDocuments.PresentationOfPremises));
		
		HeaderParameters_.Insert("ZoneText", ZoneText);
		HeaderParameters_.Insert("PresentationOfAcceptanceArea", ZonePresentation);
		HeaderParameters_.Insert("IncomingDocumentNumber",TrimAll(SelectionByDocuments.IncomingDocumentNumber));
		HeaderParameters_.Insert("IncomingDocumentDate", Format(SelectionByDocuments.IncomingDocumentDate,"DLF=D"));
		
		SectionHeader.Parameters.Fill(HeaderParameters_);
		
		If Not ValueIsFilled(SelectionByDocuments.Order_Date)
			Or Not ValueIsFilled(SelectionByDocuments.OrderNumber__) Then
			SectionHeader.Parameters.PresentationOfOrder	= SelectionByDocuments.ReferenceOrderPresentation;
		Else
			DocumentAttributes.Date          = SelectionByDocuments.Order_Date;
			DocumentAttributes.Number         = SelectionByDocuments.OrderNumber__;
			DocumentAttributes.Prefix       = SelectionByDocuments.OrderPrefix_;
			DocumentAttributes.Presentation = SelectionByDocuments.ReferenceOrderPresentation;
			
			SectionHeader.Parameters.PresentationOfOrder	= TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
		EndIf;
		
		SpreadsheetDocument.Put(SectionHeader);
		
		SpreadsheetDocument.Put(TableHeaderAreaStart);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
		EndIf;
		
		SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
		SpreadsheetDocument.Join(TableHeaderAreaEnd);
		
		TotalItems_1 = 0;
		
		While SamplingByTSLines.Next() Do
			
			AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
			AreaTableRowStart.Parameters.Fill(New Structure("LineNumber", TotalItems_1 + 1));
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
			
			AreaTableRowProductColumn.Parameters.Fill(SamplingByTSLines);
			
			If SamplingByTSLines.ThisIsAPackingList Then
				AreaTableRowProductColumn.Parameters.OwnGoods = SamplingByTSLines.PackingList;
			Else
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
				AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				,
				,
				AdditionalParametersProductPresentation);
			EndIf;
			
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
			If SamplingByTSLines.ThisIsAPackingList Then
				AreaTableRowEnd.Parameters.UnitOfMeasurePresentation = NStr("vi = 'vị trí';
																			|ru = 'место';
																			|en = 'place'; fa = 'place';
																			|it = 'luogo';
																			|pl = 'place';
																			|tr = 'yer'", Common.DefaultLanguageCode());
			EndIf;
			SpreadsheetDocument.Join(AreaTableRowEnd);
			
			If SamplingByTSLines.BatchesIndicationStatus <> 0 Then
				
				SeriesInscription = "";
				
				If SamplingByTSLines.BatchUsageSettings = Enums.ItemsBatchUsageSettings.GoodsLot Then
					If SamplingByTSLines.SpecifyNumberWhenRegisteringBatch
						And SamplingByTSLines.UseShelfLifeOnBatchRegistration Then
						SeriesInscription = NStr("vi = 'Sê-ri (số, thời hạn sử dụng đến, số lượng):';
												|ru = 'Серии (номер, годен до, количество):';
												|en = 'Batch (number, expiration date, quantity):'; fa = 'Batch (number, expiration date, quantity):';
												|it = 'Serie (numero, valido entro, quantità):';
												|pl = 'Serie (numer, ważny do, ilość)';
												|tr = 'Partiler (numara, son kullanma tarihi, miktar):'", Common.DefaultLanguageCode());
					ElsIf SamplingByTSLines.SpecifyNumberWhenRegisteringBatch Then
						SeriesInscription = NStr("vi = 'Sê-ri (số, số lượng):';
												|ru = 'Серии (номер, количество):';
												|en = 'Batch (number, quantity):'; fa = 'Batch (number, quantity):';
												|it = 'Serie (numero, quantità):';
												|pl = 'Serie (numer, ilość)';
												|tr = 'Partiler (numara, miktar):'", Common.DefaultLanguageCode());
					Else
						SeriesInscription = NStr("vi = 'Sê-ri (thời hạn sử dụng đến, số lượng):';
												|ru = 'Серии (годен до, количество):';
												|en = 'Batch (expiration date, quantity):'; fa = 'Batch (expiration date, quantity):';
												|it = 'Serie (valido entro, quantità):';
												|pl = 'Serie (ważny do, ilość)';
												|tr = 'Partiler (son kullanma tarihi, miktar):'", Common.DefaultLanguageCode());
					EndIf;
				ElsIf SamplingByTSLines.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
					SeriesInscription = NStr("vi = 'Số sê-ri:';
											|ru = 'Серийные номера:';
											|en = 'Serial numbers:'; fa = 'Serial numbers:';
											|it = 'Numeri di serie:';
											|pl = 'Numery seryjne:';
											|tr = 'Seri numarası:'", Common.DefaultLanguageCode());	
				EndIf;
				
				AreaLineSeriesStart.Parameters.SeriesInscription = SeriesInscription;
				
				SpreadsheetDocument.Put(AreaLineSeriesStart);
				
				BatchPresentation = "";
				
				If ValueIsFilled(SamplingByTSLines.Series) Then
					BatchPresentation = NStr("vi = '%1, %2 %3';
											|ru = '%1, %2 %3';
											|en = '%1, %2 %3'; fa = '%1, %2 %3';
											|it = '%1, %2 %3';
											|pl = '%1, %2 %3';
											|tr = '%1, %2 %3'", Common.DefaultLanguageCode());
					BatchPresentation = StrTemplate(BatchPresentation,
													SamplingByTSLines.BatchPresentation,
													SamplingByTSLines.Count,
													SamplingByTSLines.UnitOfMeasurePresentation);
				EndIf;
				
				SeriesParameters = New Structure("Series", BatchPresentation);
				
				AreaSeriesRowSeriesColumn.Parameters.Fill(SeriesParameters);
				
				SpreadsheetDocument.Join(AreaSeriesRowSeriesColumn);
				
			EndIf;
			
			TotalItems_1 = TotalItems_1 + 1;
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng: %TotalItems_1%';
									|ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
									|it = 'Totale articoli %TotalItems_1%';
									|pl = 'Razem pozycji %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		SignatureArea.Parameters.TotalString = TextOfResultingLine;
		
		SignatureArea.Parameters.EmployeeResponsiblePresentation = PersonsTM.IndividualShortName(SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
		SignatureArea.Parameters.ArtistPresentation = PersonsTM.IndividualShortName(SelectionByDocuments.Performer, SelectionByDocuments.Date);
		
		SpreadsheetDocument.Put(SignatureArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;	
	
EndFunction

// Returns the document data structure used for printing the printed form of the product selection (placement) Task.
//
// Parameters:
//	PrintParameters	- Structure	- additional print options.
//	ObjectsArray	- Array	- links to objects that need to be printed.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- Undefined		- errors in document data that make it impossible
//															to print the document.
//		*ResultOnOrders	- Undefined		- information about orders for document shipment.
//		*HeaderResults			- QueryResult	- the data of the header of the document used for the print Job
//															on product placement.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Tasks for placing products.
//		*ResultForPackages		- Undefined		- data about product packages in the tabular part of the document
//															used for printing the product placement Task.
//		*ResultBySeries			- QueryResult	- data about product series in the table part of the document
//															that is used for printing the product placement Task.
//		*ResultByBrand			- QueryResult	- data on the marking of goods in the tabular part of the document
//															used to print the Assignment for the placement of goods.
//
Function GetDataForPrintedFormForProductPlacement(PrintParameters, ObjectsArray) Export
	
	MarkedProductsAreUsed = GoodsReceiptNoteLocalization.MarkedProductsAreUsed();
	PackingList_ = Not PrintParameters.Property("NoExtraCharge");
	
	QueryText = RequestTextProductsTasksSelectionProductPlacement(PackingList_)
					+ Common.QueryBatchSeparator() +
	"SELECT
	|	GoodsTable.Ref					AS Ref,
	|	GoodsTable.Warehouse						AS Warehouse,
	|	GoodsTable.Premise					AS Premise,
	|	MIN(GoodsTable.LineNumber)		AS LineNumber,
	|	GoodsTable.Products				AS Products,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END									AS Series,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				OR GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END									AS Package,
	|	SUM(GoodsTable.Count)			AS Count,
	|	SUM(CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN GoodsTable.Count
	|		ELSE GoodsTable.NumberOfPackages
	|	END)									AS NumberOfPackages,
	|	GoodsTable.MarkedProducts		AS MarkedProducts
	|INTO TableOfGoodsSummarized
	|FROM
	|	TaskItems_ AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END,
	|	CASE
	|		WHEN GoodsTable.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|				OR GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END,
	|	GoodsTable.MarkedProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskData_.Ref						AS Ref,
	|	PRESENTATION(TaskData_.Ref)			AS RefPresentation,
	|	TaskData_.Number							AS Number,
	|	TaskData_.Date							AS Date,
	|	TaskData_.Warehouse							AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)			AS WarehousePresentation,
	|	PRESENTATION(TaskData_.Premise)		AS PremisePresentation,
	|	FALSE										AS ThisIsAnInvoice,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.Date >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.Premise.UseBinLocationWarehousing
	|							AND TaskData_.Date >= TaskData_.Premise.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousing
	|						AND TaskData_.Date >= TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END										AS BinLocationWarehousingIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.Date >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN TaskData_.Premise.UseBinLocationWarehousingForInformation
	|							AND (NOT TaskData_.Premise.UseBinLocationWarehousing
	|								OR TaskData_.Date < TaskData_.Premise.StartDateOfUsingWarehouseBinSystem)
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN TaskData_.Warehouse.UseBinLocationWarehousingForInformation
	|						AND (NOT TaskData_.Warehouse.UseBinLocationWarehousing
	|							OR TaskData_.Date < TaskData_.Warehouse.StartDateOfUsingWarehouseBinSystem)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END										AS ReferenceStorageIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.Date >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN TaskData_.Premise.WarehouseZoneUsage
	|		ELSE TaskData_.Warehouse.WarehouseZoneUsage
	|	END										AS WarehouseZoneUsage,
	|	FALSE										AS AdvancedWarehousingIsUsed
	|FROM
	|	Document.GoodsReceiptNote AS TaskData_
	|
	|WHERE
	|	TaskData_.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref								AS Ref,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	PRESENTATION(MainStorageBins.Cell.WarehouseZone)	AS PresentationOfWorkArea,
	|	ISNULL(MainStorageBins.Cell.TabIndex, 0)	AS TabIndex,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS MainStorageBin,
	|	ISNULL(MainStorageBins.Cell.Code, """")			AS MainStorageBinPresentation,
	|	ISNULL(OtherCells.Cell.TabIndex, 0)	AS TraversalOrderAdditionalCell,
	|	ISNULL(OtherCells.Cell.Code, """")			AS CellPresentation,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.Products.Code						AS Code,
	|	TableOfGoods.Products.SKU					AS SKU,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Products.DescriptionFull		AS ProductPresentation,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull	AS CharacteristicPresentation,
	|	Goods.ProductKind.BatchUsageSettings	AS BatchUsageSettings,
	|	TableOfGoods.Series								AS Series,
	|	TableOfGoods.Series.Description					AS BatchPresentation,
	|	TableOfGoods.Package								AS Package,
	|	PRESENTATION(TableOfGoods.Package)				AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.UnitOfMeasure)				AS PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages,
	|	TableOfGoods.MarkedProducts					AS MarkedProducts
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
	|		
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON TableOfGoods.Package = Packages.Ref
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DATE >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS OtherCells
	|		ON TableOfGoods.Products = OtherCells.Products
	|			AND NOT OtherCells.MainStorageBin
	|			AND TableOfGoods.Warehouse = OtherCells.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DATE >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = OtherCells.Premise
	|				ELSE OtherCells.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series
	|
	|TOTALS BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Warehouse				AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	TableOfGoods.LineNumber			AS LineNumber,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Series.Description	AS BatchPresentation,
	|	TableOfGoods.MarkedProducts AS MarkedProducts
	|FROM
	|	TaskItems_ AS TableOfGoods
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|			AND CASE
	|				WHEN TableOfGoods.Warehouse.UseWarerooms
	|						AND TableOfGoods.Ref.DATE >= TableOfGoods.Warehouse.StartDateOfWareroomUse
	|					THEN TableOfGoods.Premise = MainStorageBins.Premise
	|				ELSE MainStorageBins.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|			END
	|
	|WHERE
	|	TableOfGoods.Products.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|	AND TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaskItems_.Ref,
	|	MAX(TaskItems_.MarkedProducts) AS ThereAreLabeledProducts
	|FROM
	|	TaskItems_ AS TaskItems_
	|GROUP BY
	|	TaskItems_.Ref";
	
	QueriesTexts = ProductsLocalization.QueryTextsForItemDetails();
	ProductsLocalization.FillInQueryTextDetailsOfItem("DocumentGoods.Products", QueriesTexts);
	If MarkedProductsAreUsed Then
		QueryText = StrReplace(QueryText, "FALSE AS MarkedProducts", QueriesTexts.DetailsOfItemSelection);
	EndIf; 
	QueryText = StrReplace(QueryText, "&DetailsOfItemGrouping", QueriesTexts.DetailsOfItemGrouping);
	QueryText = StrReplace(QueryText, ", ConnectionTable", QueriesTexts.DetailsOfConnectionNomenclature);
	
	QueryText = StrReplace(QueryText,
								"&BatchUsageSettings",
								"VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)");
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultCell",
								"VALUE(Catalog.StorageBins.EmptyRef)");
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Undefined);
	TaskData_.Insert("ResultOnOrders",	Undefined);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 3]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForPackages",		Undefined);
	TaskData_.Insert("ResultBySeries",			Result[MaxIndex - 1]);
	TaskData_.Insert("ResultByBrand",			Result[MaxIndex]);
	
	Return TaskData_;
	
EndFunction

Function RequestTextProductsTasksSelectionProductPlacement(PackingList_)
	
	If PackingList_ Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref						AS Ref,
		|	DocumentData.Warehouse						AS Warehouse,
		|	DocumentData.Premise					AS Premise,
		|	MIN(DocumentGoods.LineNumber)		AS LineNumber,
		|	DocumentGoods.Products				AS Products,
		|	DocumentGoods.Characteristic				AS Characteristic,
		|	DocumentGoods.Series						AS Series,
		|	DocumentGoods.Package					AS Package,
		|	FALSE AS MarkedProducts,
		|	SUM(DocumentGoods.Count)			AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
		|INTO TaskItems_
		|FROM
		|	Document.GoodsReceiptNote.Goods AS DocumentGoods
		|		LEFT JOIN Document.GoodsReceiptNote AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|	, ConnectionTable
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND NOT DocumentGoods.ThisIsAPackingList
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.Premise,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
		|	&DetailsOfItemGrouping,
		|	DocumentGoods.Package";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentData.Ref						AS Ref,
		|	DocumentData.Warehouse						AS Warehouse,
		|	DocumentData.Premise					AS Premise,
		|	MIN(DocumentGoods.LineNumber)		AS LineNumber,
		|	DocumentGoods.Products				AS Products,
		|	DocumentGoods.Characteristic				AS Characteristic,
		|	DocumentGoods.Series						AS Series,
		|	&DefaultPackaging						AS Package,
		|	FALSE AS MarkedProducts,
		|	SUM(DocumentGoods.Count)			AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
		|INTO TaskItems_
		|FROM
		|	Document.GoodsReceiptNote.Goods AS DocumentGoods
		|		LEFT JOIN Document.GoodsReceiptNote AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|	, ConnectionTable
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND NOT DocumentGoods.ThisIsAPackingList
		|	AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.Premise,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
		|	&DetailsOfItemGrouping,
		|	&DefaultPackaging
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref					AS Ref,
		|	DocumentData.Warehouse					AS Warehouse,
		|	DocumentData.Premise				AS Premise,
		|	MIN(DocumentGoods.LineNumber)	AS LineNumber,
		|	GoodsWithoutPackaging_.Products			AS Products,
		|	GoodsWithoutPackaging_.Characteristic		AS Characteristic,
		|	GoodsWithoutPackaging_.Series					AS Series,
		|	&DefaultPackaging					AS Package,
		|	FALSE AS MarkedProducts,
		|	SUM(DocumentGoods.Count)		AS Count,
		|	SUM(DocumentGoods.Count)		AS NumberOfPackages
		|FROM
		|	(SELECT
		|		DocumentGoods.Ref				AS Ref,
		|		DocumentGoods.Products		AS Products,
		|		DocumentGoods.Characteristic		AS Characteristic,
		|		DocumentGoods.Purpose			AS Purpose,
		|		DocumentGoods.Series				AS Series,
		|		MAX(DocumentGoods.Package)	AS Package
		|	FROM
		|		Document.GoodsReceiptNote.Goods AS DocumentGoods
		|	
		|	WHERE
		|		DocumentGoods.Ref IN(&ObjectsArray)
		|		AND NOT DocumentGoods.ThisIsAPackingList
		|		AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	
		|	GROUP BY
		|		DocumentGoods.Ref,
		|		DocumentGoods.Products,
		|		DocumentGoods.Characteristic,
		|		DocumentGoods.Purpose,
		|		DocumentGoods.Series
		|	
		|	) AS GoodsWithoutPackaging_
		|		INNER JOIN Document.GoodsReceiptNote.Goods AS DocumentGoods
		|		ON GoodsWithoutPackaging_.Ref = DocumentGoods.Ref
		|			AND GoodsWithoutPackaging_.Products = DocumentGoods.Products
		|			AND GoodsWithoutPackaging_.Characteristic = DocumentGoods.Characteristic
		|			AND GoodsWithoutPackaging_.Purpose = DocumentGoods.Purpose
		|			AND GoodsWithoutPackaging_.Series = DocumentGoods.Series
		|			AND GoodsWithoutPackaging_.Package = DocumentGoods.Package
		|		
		|		LEFT JOIN Document.GoodsReceiptNote AS DocumentData
		|		ON GoodsWithoutPackaging_.Ref = DocumentData.Ref
		|	, ConnectionTable
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.Premise,
		|	GoodsWithoutPackaging_.Products,
		|	GoodsWithoutPackaging_.Characteristic,
		|	GoodsWithoutPackaging_.Series,
		|	&DetailsOfItemGrouping,
		|	&DefaultPackaging";
		
		QueryText = StrReplace(QueryText,
									"&DefaultPackaging",
									"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function LabelPrintingData(DocumentsArray) Export
	
	SetPrivilegedMode(True);
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReceiptOrderForGoodsGoods.Products AS Products,
	|	ReceiptOrderForGoodsGoods.Characteristic AS Characteristic,
	|	ReceiptOrderForGoodsGoods.Series AS Series,
	|	CASE
	|		WHEN ReceiptOrderForGoodsGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|			THEN ItemsPrices.PricingPackage
	|		ELSE ReceiptOrderForGoodsGoods.Package
	|	END AS Package,
	|	MIN(ReceiptOrderForGoodsGoods.LineNumber) AS Order,
	|	SUM(CASE
	|			WHEN ReceiptOrderForGoodsGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|				THEN ReceiptOrderForGoodsGoods.NumberOfPackages * (ISNULL(&ZoomRatio1, 1) / ISNULL(&ZoomRatio2, 1))
	|			ELSE ReceiptOrderForGoodsGoods.NumberOfPackages
	|		END) AS Count
	|FROM
	|	Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsGoods
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast AS ItemsPrices
	|		ON (ItemsPrices.Products = ReceiptOrderForGoodsGoods.Products)
	|			AND (ItemsPrices.PricingVariant = ReceiptOrderForGoodsGoods.Characteristic.ItemsCharacteristicForPricing)
	|			AND (ItemsPrices.PriceKind = ReceiptOrderForGoodsGoods.Ref.Warehouse.RetailPriceType)
	|WHERE
	|	ReceiptOrderForGoodsGoods.Ref IN(&DocumentsArray)
	|	AND NOT ReceiptOrderForGoodsGoods.ThisIsAPackingList
	|
	|GROUP BY
	|	ReceiptOrderForGoodsGoods.Products,
	|	ReceiptOrderForGoodsGoods.Characteristic,
	|	ReceiptOrderForGoodsGoods.Series,
	|	CASE
	|		WHEN ReceiptOrderForGoodsGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|			THEN ItemsPrices.PricingPackage
	|		ELSE ReceiptOrderForGoodsGoods.Package
	|	END
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DetailsOfDecoupling.Organization AS Organization,
	|	GoodsReceiptNote.Warehouse AS Warehouse,
	|	GoodsReceiptNote.Warehouse.RetailPriceType AS PriceKind
	|FROM
	|	Document.GoodsReceiptNote AS GoodsReceiptNote
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DetailsOfDecoupling
	|		ON (NOT DetailsOfDecoupling.AdditionalRecord
	|				AND GoodsReceiptNote.ReferenceOrder = DetailsOfDecoupling.Ref)
	|WHERE
	|	GoodsReceiptNote.Ref IN(&DocumentsArray)";
	
	Query.Text = StrReplace(Query.Text, "&ZoomRatio1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ReceiptOrderForGoodsGoods.Package",
			"ReceiptOrderForGoodsGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&ZoomRatio2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package",
			"ItemsPrices.Products"));
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	TableDocumentDetails = ResultsArray[1].Unload();
	CompanyArray = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Organization");
	WarehouseArray     = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Warehouse");
	ArrayOfPriceTypes    = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "PriceKind");
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", ?(CompanyArray.Count() = 1, CompanyArray[0], Undefined));
	StructureOfActions.Insert("FillInTheWarehouse",       ?(WarehouseArray.Count() = 1,     WarehouseArray[0],     WarehouseArray));
	StructureOfActions.Insert("FillInPriceView",     ?(ArrayOfPriceTypes.Count() = 1,    ArrayOfPriceTypes[0],    Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", ResultsArray[0].Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction // Prepare the data()

Function DataForPrintingPriceTags(DocumentsArray) Export

	SetPrivilegedMode(True);
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReceiptOrderForGoodsGoods.Products    AS Products,
	|	ReceiptOrderForGoodsGoods.Characteristic  AS Characteristic,
	|	ReceiptOrderForGoodsGoods.Series           AS Series,
	|
	|	CASE WHEN ReceiptOrderForGoodsGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		ItemsPrices.PricingPackage
	|	ELSE
	|		ReceiptOrderForGoodsGoods.Package
	|	END AS Package,
	|
	|	MIN(ReceiptOrderForGoodsGoods.LineNumber) AS Order,
	|	SUM(
	|		CASE WHEN ReceiptOrderForGoodsGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|			ReceiptOrderForGoodsGoods.NumberOfPackages * (ISNULL(&ZoomRatio1, 1) / ISNULL(&ZoomRatio2, 1))
	|		ELSE
	|			ReceiptOrderForGoodsGoods.NumberOfPackages
	|		END) AS Count
	|FROM
	|	Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsGoods
	|	
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast AS ItemsPrices
	|		ON ItemsPrices.Products     = ReceiptOrderForGoodsGoods.Products
	|		 AND ItemsPrices.PricingVariant = ReceiptOrderForGoodsGoods.Characteristic
	|		 AND ItemsPrices.PriceKind          = ReceiptOrderForGoodsGoods.Ref.Warehouse.RetailPriceType
	|	
	|WHERE
	|	ReceiptOrderForGoodsGoods.Ref IN(&DocumentsArray)
	|	AND (NOT ReceiptOrderForGoodsGoods.ThisIsAPackingList)
	|
	|GROUP BY
	|	ReceiptOrderForGoodsGoods.Products,
	|	ReceiptOrderForGoodsGoods.Characteristic,
	|	ReceiptOrderForGoodsGoods.Series,
	|	CASE WHEN ReceiptOrderForGoodsGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		ItemsPrices.PricingPackage
	|	ELSE
	|		ReceiptOrderForGoodsGoods.Package
	|	END
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DetailsOfDecoupling.Organization AS Organization,
	|	GoodsReceiptNote.Warehouse AS Warehouse,
	|	GoodsReceiptNote.Warehouse.RetailPriceType AS PriceKind
	|FROM
	|	Document.GoodsReceiptNote AS GoodsReceiptNote
	|		INNER JOIN InformationRegister.DocumentsRegistry AS DetailsOfDecoupling
	|		ON (NOT DetailsOfDecoupling.AdditionalRecord
	|				AND GoodsReceiptNote.ReferenceOrder = DetailsOfDecoupling.Ref)
	|WHERE
	|	GoodsReceiptNote.Ref IN(&DocumentsArray)";
	
	Query.Text = StrReplace(Query.Text, "&ZoomRatio1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ReceiptOrderForGoodsGoods.Package",
			"ReceiptOrderForGoodsGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&ZoomRatio2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package",
			"ItemsPrices.Products"));
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	TableDocumentDetails = ResultsArray[1].Unload();
	CompanyArray = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Organization");
	WarehouseArray     = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Warehouse");
	ArrayOfPriceTypes    = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "PriceKind");
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", ?(CompanyArray.Count() = 1, CompanyArray[0], Undefined));
	StructureOfActions.Insert("FillInTheWarehouse",       ?(WarehouseArray.Count() = 1,     WarehouseArray[0],     WarehouseArray));
	StructureOfActions.Insert("FillInPriceView",     ?(ArrayOfPriceTypes.Count() = 1,    ArrayOfPriceTypes[0],    Undefined));
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
	
EndFunction // Prepare the data()

#EndRegion

#Region Other

Function AdvancedWarehouses(Object) Export
	
	DateFromOrder = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	Query = New Query;
	Query.SetParameter("DateFromOrder", DateFromOrder);
	WarehouseArray = New Array;
	MetadataResolution = Object.ReferenceOrder.Metadata(); // MetadataObjectAttribute
	TypeOfOrder_ = MetadataResolution.Name;
	
	If TypeOfOrder_ = "TermsOfPurchaseFromVendors" Then
		
		AttributesStructure1 = New Structure;
		AttributesStructure1.Insert("Warehouse", "Warehouse");
		AttributesStructure1.Insert("IsFolder", "Warehouse.IsFolder");
		AttributesStructure1.Insert("UseWarehouseManagemantSystemForGoodsReceipt",
			"Warehouse.UseWarehouseManagemantSystemForGoodsReceipt");
		AttributesStructure1.Insert("StartDateOfWarehouseManagemantSystemForGoodsReceipt",
			"Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt");
		
		WarehouseDetails = Common.ObjectAttributesValues(Object.ReferenceOrder, AttributesStructure1);
		
		If ValueIsFilled(WarehouseDetails.Warehouse) Then
			If WarehouseDetails.IsFolder Then
				Query.Text =
				"SELECT ALLOWED
				|	Warehouses.Ref AS Warehouse
				|FROM
				|	Catalog.Warehouses AS Warehouses
				|WHERE
				|	Warehouses.Ref IN HIERARCHY(&GroupOfWarehouses)
				|	AND Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
				|	AND &DateFromOrder >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
				|	AND (NOT Warehouses.DeletionMark)
				|	AND (NOT Warehouses.IsFolder)";
				
				Query.SetParameter("GroupOfWarehouses", WarehouseDetails.Warehouse);
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					WarehouseArray.Add(Selection.Warehouse);
				EndDo;
			ElsIf WarehouseDetails.UseWarehouseManagemantSystemForGoodsReceipt
				And DateFromOrder >= WarehouseDetails.StartDateOfWarehouseManagemantSystemForGoodsReceipt Then
				WarehouseArray.Add(WarehouseDetails.Warehouse);
			EndIf;
		Else
			Query.Text =
			"SELECT ALLOWED
			|	Warehouses.Ref AS Warehouse
			|FROM
			|	Catalog.Warehouses AS Warehouses
			|WHERE
			|	Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
			|	AND &DateFromOrder >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
			|	AND (NOT Warehouses.DeletionMark)
			|	AND (NOT Warehouses.IsFolder)";
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				WarehouseArray.Add(Selection.Warehouse);
			EndDo;
		EndIf;
		
	Else
		Query.SetParameter("Ref", Object.ReferenceOrder);
		Query.Text =
		"SELECT ALLOWED DISTINCT
		|	GoodsToReceive.Warehouse
		|FROM
		|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.DocumentInflow = &Ref";
		
		SetPrivilegedMode(True);
		Selection = Query.Execute().Select();
		SetPrivilegedMode(False);
		While Selection.Next() Do
			WarehouseArray.Add(Selection.Warehouse);
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(Object.Warehouse) 
	 And WarehouseArray.Find(Object.Warehouse) = Undefined Then
		WarehouseArray.Add(Object.Warehouse);
	EndIf;
	
	Return WarehouseArray;
	
EndFunction

Function FillInSeriesByReference(Object, GiveErrors) Export
	
	If Not YouCanSpecifySeriesByReference(Object, GiveErrors) Then
		Return False;
	EndIf;
	
	If Object.WarehouseOperation = Enums.WarehouseTransactions.ReceivingByTransfer Then
		SetOfSeries = SeriesTableByShipmentWhenMoving(Object);
	ElsIf Object.WarehouseOperation = Enums.WarehouseTransactions.ProductReceivingFromManufacturing Then
		SetOfSeries = TableOfSeriesOfProducts(Object);
	ElsIf Object.WarehouseOperation = Enums.WarehouseTransactions.GoodsReceiptByOtherTransactions Then
		SetOfSeries = TableOfSeriesAtAcceptanceOnOtherRegistration(Object);
	Else
		SetOfSeries = TableOfFinancialSeriesFromOrder(Object);
	EndIf;
	
	If SetOfSeries.Count() = 0 Then
		If GiveErrors Then
			MessageText = NStr("vi = 'Theo lệnh không có sê-ri mà có thể chuyển chứng sang phiếu nhập.';
								|ru = 'По распоряжению нет серий, которые можно перенести в ордер.';
								|en = 'There are no batch for the reference which can be transferred to the note.'; fa = 'There are no batch for the reference which can be transferred to the note.';
								|it = 'Per la disposizione non ci sono serie che possono essere trasferite nel mandato.';
								|pl = 'Dla zamówienia nie ma serii, które można przenieść do zlecenia.';
								|tr = 'Emre göre siparişe aktarılabilecek serisi bulunmamaktadır.'");
			Common.MessageToUser(MessageText);
		EndIf;
		Return False;
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(Object, Documents.GoodsReceiptNote);
	
	ProductsServer.CompleteTableWithColumnsForFieldsOfParametersForSpecifyingSeries(SeriesSpecificationParameters, SetOfSeries,, True);
	
	Actions = New Structure;
	Actions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	If SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined Then 
		Actions.Insert("RecalculateNumberOfUnits");
	Else
		Actions.Insert("RecalculateNumberOfPackages");
	EndIf;
	ProductsServer.FillInWHSeriesAccordingToSeriesTable(Object,
														SeriesSpecificationParameters,
														SetOfSeries,
														Actions);
	Return True;
EndFunction

Function YouCanSpecifySeriesByReference(Object, GiveErrors) Export
	
	SetPrivilegedMode(True);
	If Not GetFunctionalOption("UseItemsBatchWarehouse",New Structure("Warehouse",Object.Warehouse)) Then
		If GiveErrors Then
			MessageText = NStr("vi = 'Trong kho không tiến hành sê-ri.';
								|ru = 'На складе не ведется учет серий.';
								|en = 'Batches are not accounted in the warehouse.'; fa = 'Batches are not accounted in the warehouse.';
								|it = 'Nel magazzino non viene tenuta la contabilità delle serie.';
								|pl = 'W magazynie nie prowadzi się ewidencji serii';
								|tr = 'Ambarda parti muhasebesi yapılmıyor.'");
			Common.MessageToUser(MessageText);
		EndIf;
		Return False;	
	EndIf;
	
	If WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date)
		And Not ValueIsFilled(Object.Premise) Then
		If GiveErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Địa điểm""';
								|ru = 'Не заполнено поле ""Помещение""';
								|en = '""Wareroom"" is required'; fa = '""Wareroom"" is required';
								|it = 'Non è compilato il campo ""Locale""';
								|pl = 'Nie jest wypełnione pole ""Pomieszczenie""';
								|tr = '""Depolama alanı"" alanı doldurulmadı'");
			Common.MessageToUser(MessageText,,"Premise","Object");
		EndIf;
		Return False;
	EndIf;
	
	If Object.WarehouseOperation = Enums.WarehouseTransactions.ReceivingByTransfer Then
		
		SourceWarehouse = Common.ObjectAttributeValue(Object.ReferenceOrder,"SourceWarehouse");
		
		If Not GetFunctionalOption("UseItemsBatchWarehouse",New Structure("Warehouse",SourceWarehouse)) Then
			If GiveErrors Then
				MessageText = NStr("vi = 'Trong kho-nơi gửi không tiến hành sê-ri';
									|ru = 'На складе-отправителе не ведется учет по сериям';
									|en = 'Accounting by batch is not kept in the origin warehouse'; fa = 'Accounting by batch is not kept in the origin warehouse';
									|it = 'Nel magazzino-mittente non viene tenuta la contabilità per serie';
									|pl = 'W magazynie nadawcy nie prowadzi się ewidencji serii';
									|tr = 'Çıkış ambarında parti muhasebesi yapılmıyor'");
				
				Common.MessageToUser(MessageText);
			EndIf;
			Return False;	
		EndIf;
		
		If WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(SourceWarehouse,Object.Date) Then
			
			If WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date)
				And Not WarehousesServer.UseBinLocationWarehousing(SourceWarehouse, Catalogs.Warerooms.EmptyRef(),Object.Date)
				And Not WarehousesServer.UseWarerooms(SourceWarehouse,Object.Date) Then
				
				If GiveErrors Then
					MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" tiến hành ghi nhận số dư theo từng ô kho, vì vậy, cần chỉ ra sê-ri theo từng đóng gói. Tại kho-nơi gửi không tiến hành ghi nhận theo từng ô khô, vì vậy ghi nhận sê-ri mà không theo đóng gói. Không thể điền sê-ri theo dữ liệu giao hàng.';
										|ru = 'На складе ""%Warehouse%"" ведется учет остатков в разрезе складских ячеек, поэтому серии нужно указывать в разрезе упаковок. На складе-отправителе учет в разрезе складских ячеек не ведется, поэтому серии учитываются без разреза упаковок. Заполнить серии по данным отгрузки нельзя.';
										|en = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. Accounting by storage bins in the origin warehouse is not kept, that is why batches are not recorded by packaging units. You cannot fill in the batch by shipment data.'; fa = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. Accounting by storage bins in the origin warehouse is not kept, that is why batches are not recorded by packaging units. You cannot fill in the batch by shipment data.';
										|it = 'Nel magazzino ""%Warehouse%"" viene tenuta la contabilità delle rimanenze nello specifico delle celle di magazzino, pertanto le serie devono essere specificate nei termini di imballaggi. Nel magazzino-mittente non viene tenuta la contabilità nello specifico delle celle di magazzino, quindi le serie vengono registrate senza tenere conto di imballaggi. Impossibile compilare le serie in base ai dati di spedizione.';
										|pl = 'W magazynie ""%Warehouse%"" prowadzi się ewidencja pozostałości w kontekście komórek magazynowych, więc seria musi być określona w kontekście opakowań. W magazynie nadawcy nie prowadzi się ewidencji w kontekście komórek magazynowych, dlatego serie są brane pod uwagę bez kontekstu opakowań. Nie można wypełnić serii według danych wysyłki.';
										|tr = '""%Warehouse%"" ambarında, ambar hücreleri bağlamında bakiye kayıtlarının muhasebesi yapılıyor, bu nedenle partiler paketler bağlamında belirtilmelidir. Çıkış ambarında, ambar hücreleri tarafından muhasebe tutulmaz, bu nedenle seriler, paketler bozulmadan dikkate alınır. Sevkiyat verilerine göre seri doldurmak mümkün değildir.'");
					
					MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(Object.Warehouse, Object.Premise)); 
					
					Common.MessageToUser(MessageText);
				EndIf;
				Return False;	
				
			EndIf;
				
			If WarehousesServer.UseWarerooms(SourceWarehouse,Object.Date)
				And WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date) Then
				
				Query = New Query;
				Query.Text =
				"SELECT TOP 1
				|	GoodsByReferences.Ref
				|FROM
				|	Document.GoodsIssueNote.GoodsByReferences AS GoodsByReferences
				|WHERE
				|	GoodsByReferences.ReferenceOrder = &ReferenceOrder 
				|	AND GoodsByReferences.Ref.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
				|	AND GoodsByReferences.Ref.Posted
				|	AND (NOT (GoodsByReferences.Ref.Premise.UseBinLocationWarehousing)
				|		OR GoodsByReferences.Ref.Date < GoodsByReferences.Ref.Premise.StartDateOfUsingWarehouseBinSystem)";
				
				Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
				
				If Not Query.Execute().IsEmpty() Then
					If GiveErrors Then
						MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" ghi nhận số dư theo từng ô kho, vì vậy cần chỉ ra sê-ri theo từng đóng gói. Đã giao hàng từ vị trí của kho-nơi gửi mà tại đó không ghi nhận theo từng ô kho. vì vậy ghi nhận sê-ri không theo đóng gói. Không nên điền sê-ri theo dữ liệu giao hàng.';
											|ru = 'На складе ""%Warehouse%"" ведется учет остатков в разрезе складских ячеек, поэтому серии нужно указывать в разрезе упаковок. Отгрузка производилась из помещений склада-отправителя, на которых учет в разрезе складския ячеек не ведется, поэтому серии учитываются без разреза упаковок. Заполнить серии по данным отгрузки нельзя.';
											|en = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. Shipment was performed from the origin warehouse warerooms where accounting by storage bins is not kept, that is why batches are not recorded by packaging units. You cannot fill in the batch by shipment data.'; fa = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. Shipment was performed from the origin warehouse warerooms where accounting by storage bins is not kept, that is why batches are not recorded by packaging units. You cannot fill in the batch by shipment data.';
											|it = 'Nel magazzino ""%Warehouse%"" viene tenuta la contabilità delle rimanenze nello specifico delle celle di magazzino, pertanto le serie devono essere specificate nei termini di imballaggi. La spedizione è stata effettuata dal magazzino-mittente, dove non viene tenuta la contabilità nello specifico delle celle di magazzino, quindi le serie vengono registrate senza tenere conto di imballaggi. Impossibile compilare le serie in base ai dati di spedizione.';
											|pl = 'W magazynie ""%Warehouse%"" prowadzi się ewidencja pozostałości w kontekście komórek magazynowych, więc seria musi być określona w kontekście opakowań. Wysylkę dokonano z pomieszczeń magazynu nadawcy, w których nie prowadzi się ewidencji w kontekście komórek magazynowych, dlatego serie są brane pod uwagę bez kontekstu opakowań. Nie można wypełnić serii według danych wysyłki.';
											|tr = '""%Warehouse%"" ambarında depo yerine göre stok bakiyesi takibinin kullanıldığı için, partileri paketleme ünitelerine göre belirtmeniz şarttır. Sevkiyatın, depo yerine göre stok bakiyesi takibi kullanmayan bir ambar deposundan gerçekleştirildiği için, partiler paketleme ünitelerine göre kaydedilemedi. Parti verilerini sevkiyat verilerine göre dolduramazsınız.'");
						MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(Object.Warehouse, Object.Premise)); 
						Common.MessageToUser(MessageText);
					EndIf;
					Return False;	
				EndIf;
				
			EndIf;
			
		Else
			If WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date) Then
				If GiveErrors Then
					MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" tiến hành ghi nhận số dư theo từng ô kho, vì vậy, cần chỉ ra sê-ri theo từng đóng gói. Tại kho-nơi gửi không tiến hành ghi nhận theo từng ô khô, vì vậy ghi nhận sê-ri mà không theo đóng gói. Không thể điền sê-ri theo dữ liệu giao hàng.';
										|ru = 'На складе ""%Warehouse%"" ведется учет остатков в разрезе складских ячеек, поэтому серии нужно указывать в разрезе упаковок. На складе-отправителе учет в разрезе складских ячеек не ведется, поэтому серии учитываются без разреза упаковок. Заполнить серии по данным отгрузки нельзя.';
										|en = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. Accounting by storage bins in the origin warehouse is not kept, that is why batches are not recorded by packaging units. You cannot fill in the batch by shipment data.'; fa = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. Accounting by storage bins in the origin warehouse is not kept, that is why batches are not recorded by packaging units. You cannot fill in the batch by shipment data.';
										|it = 'Nel magazzino ""%Warehouse%"" viene tenuta la contabilità delle rimanenze nello specifico delle celle di magazzino, pertanto le serie devono essere specificate nei termini di imballaggi. Nel magazzino-mittente non viene tenuta la contabilità nello specifico delle celle di magazzino, quindi le serie vengono registrate senza tenere conto di imballaggi. Impossibile compilare le serie in base ai dati di spedizione.';
										|pl = 'W magazynie ""%Warehouse%"" prowadzi się ewidencja pozostałości w kontekście komórek magazynowych, więc seria musi być określona w kontekście opakowań. W magazynie nadawcy nie prowadzi się ewidencji w kontekście komórek magazynowych, dlatego serie są brane pod uwagę bez kontekstu opakowań. Nie można wypełnić serii według danych wysyłki.';
										|tr = '""%Warehouse%"" ambarında, ambar hücreleri bağlamında bakiye kayıtlarının muhasebesi yapılıyor, bu nedenle partiler paketler bağlamında belirtilmelidir. Çıkış ambarında, ambar hücreleri tarafından muhasebe tutulmaz, bu nedenle seriler, paketler bozulmadan dikkate alınır. Sevkiyat verilerine göre seri doldurmak mümkün değildir.'");
					
					MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(Object.Warehouse, Object.Premise)); 
					
					Common.MessageToUser(MessageText);
				EndIf;
				Return False;
			EndIf;
			
		EndIf;
	ElsIf Object.WarehouseOperation = Enums.WarehouseTransactions.ProductReceivingFromManufacturing Then
		
		If Not GetFunctionalOption("UseItemsBatchProduction") 
 			And Not GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure("Warehouse", Object.Warehouse)) 
			And Not GetFunctionalOption("UseItemsBatchProduction22")
			Then
			If GiveErrors Then
				MessageText = NStr("vi = 'Để thiết lập chỉ ra sê-ri trong các chứng từ sản xuất.';
									|ru = 'На настроено указание серий в производственных документах.';
									|en = 'Batch specification is not set for manufacturing documents.'; fa = 'Batch specification is not set for manufacturing documents.';
									|it = 'Non è impostata l''indicazione delle serie nei documenti di produzione.';
									|pl = 'Nie ustawiono podanie serii w dokumentach produkcyjnych.';
									|tr = 'Serilerin üretim belgelerinde belirtilmesi ayarlanmamıştır.'");
				Common.MessageToUser(MessageText);
			EndIf;
			Return False;	
		EndIf;
		
		If WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date)
			And Object.BusinessOperation <> Enums.BusinessTransactions.TransferOfProductsFromProduction Then
			If GiveErrors Then
				MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" tiến hành ghi nhận số dư theo từng ô kho, vì vậy cần chỉ ra sê-ri theo từng đóng gói. Trong sản xuất, điền sê-ri mà không ghi nhận đóng gói. Không thể điền sê-ri theo dữ liệu xuất xưởng sản phẩm.';
									|ru = 'На складе ""%Warehouse%"" ведется учет остатков в разрезе складских ячеек, поэтому серии нужно указывать в разрезе упаковок. В производстве серии заполняются без учета упаковок. Заполнить серии по данным выпуска продукции нельзя.';
									|en = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. During manufacturing batches are filled in without recording packaging units. You cannot fill in the batch by product release data.'; fa = 'Remaining quantity is accounted by storage bins in warehouse ""%Warehouse%"", that is why batch should be specified by packaging units. During manufacturing batches are filled in without recording packaging units. You cannot fill in the batch by product release data.';
									|it = 'Nel magazzino ""%Warehouse%"" viene tenuta la contabilità delle rimanenze nello specifico delle celle di magazzino, pertanto le serie devono essere specificate nei termini di imballaggi. In produzione le serie vengono compilati senza tenere conto di imballaggi. Impossibile compilare le serie in base ai dati di emissione prodotti.';
									|pl = 'W magazynie ""%Warehouse%"" prowadzi się ewidencja pozostałości w kontekście komórek magazynowych, więc seria musi być określona w kontekście opakowań. Podczas produkcji serie wypełnia się bez uwzgłędnienia opakowań. Nie można wypełnić serii według danych produkcji towarów.';
									|tr = '""%Warehouse%"" ambarında, ambar hücreleri bağlamında bakiye kayıtlarının muhasebesi yapılıyor, bu nedenle partiler paketler bağlamında belirtilmelidir. Üretimde, partiler paketler dikkate alınmadan doldurulur. Üretim verilerine göre parti doldurmak mümkün değildir.'");
				
				MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(Object.Warehouse, Object.Premise)); 
				
				Common.MessageToUser(MessageText);
			EndIf;
			Return False;
		EndIf;
	ElsIf Object.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient
		Or Object.WarehouseOperation = Enums.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed Then
		If GiveErrors Then
			MessageText = NStr("vi = 'Trong các giao dịch, khi nhận hàng trả lại do người nhận không nhận thì không hỗ trợ điền sê-ri theo lệnh.';
								|ru = 'В операциях при приемке по возврату непринятых получателем товаров заполнение серий по распоряжению не поддерживается.';
								|en = 'Specifying batch under the reference is not supported in operations of receiving when a recipient returns unaccepted goods.'; fa = 'Specifying batch under the reference is not supported in operations of receiving when a recipient returns unaccepted goods.';
								|it = 'Nelle operazioni di accettazione della merce resa non accettata dal destinatario, la compilazione delle serie per disposizione non è supportata.';
								|pl = 'W operacjach przyjmowania zwrotu towarów nie przyjętych przez odbiorcę, wypełnianie serii na podstawie zamówienia nie jest obsługiwane.';
								|tr = 'Alıcı tarafından kabul edilmeyen ürün iadesine yönelik işlemlerde, siparişe göre parti dolum desteklenmemektedir.'");
			Common.MessageToUser(MessageText);
		EndIf;
		Return False;
	Else
		
		If Not GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure("Warehouse",Object.Warehouse)) Then
			If GiveErrors Then
				MessageText = NStr("vi = 'Trong lệnh chỉ có thể chỉ ra sê-ri dùng để tính giá vốn, nhưng chưa thiết lập sử dụng các sê-ri như vậy trong kho.';
									|ru = 'В распоряжении могут быть указаны только серии, по которым учитывается себестоимость, но складе не настроено использование таких серий.';
									|en = 'Only batch according to which cost is recorded can be specified in the reference. Using such batch is not set for the warehouse.'; fa = 'Only batch according to which cost is recorded can be specified in the reference. Using such batch is not set for the warehouse.';
									|it = 'Nella disposizione possono essere indicate solo le serie in base alle quali viene contabilizzato il costo di produzione, ma l''utilizzo di tali serie non è configurato nel magazzino.';
									|pl = 'W zamówieniu mogą być podane tylko serie, według których określa się koszty własne, ale w magazynie nie jest ustawione używanie takich serii.';
									|tr = 'Siparişte sadece maliyet fiyatının dikkate alındığı partiler belirtilebilir, ancak ambar bu partileri kullanacak şekilde ayarlanmamıştır.'");
				Common.MessageToUser(MessageText);
			EndIf;
			Return False;	
		EndIf;
		
		If WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date) Then
			If GiveErrors Then
				MessageText = NStr("vi = 'Trong kho ""%Warehouse%"" ghi nhận số dư theo từng ô kho. Có thể điền sê-ri theo lệnh chỉ khi điều chuyển hàng hóa từ địa chỉ kho. Không hỗ trợ điền sê-ri tại kho này theo các kiểu khác của lệnh.';
									|ru = 'На складе ""%Warehouse%"" ведется учет остатков в разрезе складских ячеек. Серии могут быть заполнены по распоряжению только при перемещении товаров с адресного склада. По другим типам распоряжений заполнение серий на этом складе не поддерживается.';
									|en = 'Stock balance is accounted by storage bins in warehouse ""%Warehouse%"". Batch can be filled in against the reference only while moving goods from the bin location warehouse. Batch population against other reference types is not supported in this warehouse.'; fa = 'Stock balance is accounted by storage bins in warehouse ""%Warehouse%"". Batch can be filled in against the reference only while moving goods from the bin location warehouse. Batch population against other reference types is not supported in this warehouse.';
									|it = 'Nel magazzino ""%Warehouse%"" viene tenuta la contabilità delle rimanenze nello specifico delle celle di magazzino. La serie possono essere compilate solo per disposizione durante il trasferimento delle merci dal magazzino di stoccaggio codificato. Per altri tipi delle disposizioni, la compilazione delle serie in questo magazzino non è supportata.';
									|pl = 'W magazynie ""%Warehouse%"" prowadzi się ewidencja pozostałości w kontekście komórek magazynowych. Serie moga być wypełnione na podstawie zamówienia tylko przy przemieszczeniu towarów z magazynu adresowego. W przypadku innych typów zamówień wypełnianie serii w tym magazynie nie jest obsługiwane.';
									|tr = '""%Warehouse%"" ambarında ambar hücreleri bağlamında bakiyelerin muhasebesi tutulur. Parti, yalnızca ürünleri adres ambarından taşırken emre göre doldurulabilir. Diğer emir türleri için bu ambardaki dolum partisi desteklenmez.'");
				
				MessageText = StrReplace(MessageText,"%Warehouse%", WarehousesServer.GetWarehousePresentation(Object.Warehouse, Object.Premise)); 
				
				Common.MessageToUser(MessageText);
			EndIf;
			Return False;
		EndIf;
	EndIf;
		
	Return True;
EndFunction

// Returns a table containing information about the series of goods according to the data of shipped goods and invoices-orders.
//
// Parameters:
//	Object - DocumentObject.GoodsReceiptNote - the object of the goods acceptance document.
//
// Returnable value:
//	Assignment table - a table with information about the series to be filled in the acceptance document, containing the following columns:
//		* Products - CatalogRef.Products - the receipt number.
//		* Characteristic - CatalogRef.ItemsCharacteristics -characteristics of the Product of the receipt.
//		* Purpose - CatalogRef.Assignments - the purpose of the receipt product.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - packing.
//		* Series - CatalogRef.ItemsBatches - product series.
//		* Count - Number - the quantity of the accepted product in the storage unit.
//		* NumberOfPackages - Number - the number of packages of accepted goods.
//
Function SeriesTableByShipmentWhenMoving(Object)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsToReceive.Products						AS Products,
	|	GoodsToReceive.Characteristic					AS Characteristic,
	|	COUNT(DISTINCT GoodsToReceive.Purpose)	AS Purpose
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.DocumentInflow = &ReferenceOrder
	|	AND GoodsToReceive.GoodsReceiptNotesToRegister > 0
	|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
	|
	|GROUP BY
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Products
	|
	|HAVING
	|	COUNT(DISTINCT GoodsToReceive.Purpose) > 1";
	
	Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
	
	OneProductAssignment	= Query.Execute().IsEmpty();
	SourceWarehouse		= Common.ObjectAttributeValue(Object.ReferenceOrder, "SourceWarehouse");
	UnloadedColumns		= "Products, Characteristic, Products, Purpose, Package, Count,
								|NumberOfPackages, ThisIsAPackingList";
	
	SetPrivilegedMode(True);
	
	If OneProductAssignment
		And WarehousesServer.UseWarehouseManagemantSystemForGoodsIssue(SourceWarehouse, Object.Date) Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	DocumentGoods.Products	AS Products,
		|	DocumentGoods.Characteristic	AS Characteristic,
		|	CASE
		|		WHEN &UseBinLocationWarehousing
		|			THEN CAST(DocumentGoods.Package AS Catalog.PackagesAndUnitsOfMeasure)
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END							AS Package,
		|	DocumentGoods.Count		AS Count,
		|	CASE
		|		WHEN &UseBinLocationWarehousing
		|			THEN DocumentGoods.NumberOfPackages
		|		ELSE DocumentGoods.Count
		|	END							AS NumberOfPackages
		|INTO ProductsOrdersToRequest
		|FROM
		|	&GoodsTable AS DocumentGoods
		|WHERE
		|	NOT DocumentGoods.ThisIsAPackingList
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	GoodsTable.Ref			AS Ref,
		|	GoodsTable.ReferenceOrder		AS ReferenceOrder,
		|	GoodsTable.Products		AS Products,
		|	GoodsTable.Characteristic	AS Characteristic,
		|	GoodsTable.Series				AS Series,
		|	SUM(GoodsTable.Count)	AS Count
		|INTO GoodsToShipByOrder
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS GoodsTable
		|		INNER JOIN Document.GoodsIssueNote AS HeaderData_
		|		ON GoodsTable.Ref = HeaderData_.Ref
		|WHERE
		|	HeaderData_.Posted
		|	AND GoodsTable.ReferenceOrder IN(&ReferenceOrder)
		|	AND HeaderData_.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_)
		|
		|GROUP BY
		|	GoodsTable.Ref,
		|	GoodsTable.ReferenceOrder,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series
		|
		|INDEX BY
		|	Ref,
		|	Products,
		|	Characteristic,
		|	Series
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	GoodsTable.Ref				AS Ref,
		|	HeaderData_.DateOfShipment			AS DateOfShipment,
		|	MIN(GoodsTable.LineNumber)	AS LineNumber,
		|	GoodsTable.Products			AS Products,
		|	GoodsTable.Characteristic		AS Characteristic,
		|	GoodsTable.Series					AS Series,
		|	SUM(GoodsTable.Count)		AS Count
		|INTO TTShippedGoods
		|FROM
		|	Document.GoodsIssueNote.ShippedGoods AS GoodsTable
		|		INNER JOIN Document.GoodsIssueNote AS HeaderData_
		|		ON GoodsTable.Ref = HeaderData_.Ref
		|WHERE
		|	GoodsTable.Ref IN
		|			(SELECT DISTINCT
		|				GoodsByReferences.Ref AS Ref
		|			FROM
		|				GoodsToShipByOrder AS GoodsByReferences)
		|	AND NOT GoodsTable.ThisIsAPackingList
		|	AND GoodsTable.Action = VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship)
		|
		|GROUP BY
		|	GoodsTable.Ref,
		|	HeaderData_.DateOfShipment,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series
		|
		|INDEX BY
		|	Ref,
		|	Products,
		|	Characteristic,
		|	Series
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	GoodsTable.Ref			AS Ref,
		|	GoodsTable.DateOfShipment		AS DateOfShipment,
		|	GoodsTable.LineNumber		AS LineNumber,
		|	GoodsTable.Products		AS Products,
		|	GoodsTable.Characteristic	AS Characteristic,
		|	GoodsTable.Series				AS Series,
		|	GoodsTable.Count		AS Count
		|INTO ShippedGoods
		|FROM
		|	TTShippedGoods AS GoodsTable
		|WHERE
		|	(GoodsTable.Ref, GoodsTable.Products, GoodsTable.Characteristic) IN
		|			(SELECT DISTINCT
		|				ShippedGoods.Ref			AS Ref,
		|				ShippedGoods.Products		AS Products,
		|				ShippedGoods.Characteristic	AS Characteristic
		|			FROM
		|				TTShippedGoods AS ShippedGoods
		|					LEFT JOIN GoodsToShipByOrder AS GoodsByReferences
		|					ON ShippedGoods.Ref = GoodsByReferences.Ref
		|						AND ShippedGoods.Products = GoodsByReferences.Products
		|						AND ShippedGoods.Characteristic = GoodsByReferences.Characteristic
		|			WHERE
		|				ISNULL(GoodsByReferences.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) = VALUE(Catalog.ItemsBatches.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.Ref			AS Ref,
		|	GoodsTable.DateOfShipment		AS DateOfShipment,
		|	GoodsTable.LineNumber		AS LineNumber,
		|	GoodsTable.Products		AS Products,
		|	GoodsTable.Characteristic	AS Characteristic,
		|	GoodsTable.Series				AS Series,
		|	CASE
		|		WHEN GoodsTable.Count > GoodsByReferences.Count
		|			THEN GoodsByReferences.Count
		|		ELSE GoodsTable.Count
		|	END							AS Count
		|FROM
		|	TTShippedGoods AS GoodsTable
		|		INNER JOIN GoodsToShipByOrder AS GoodsByReferences
		|		ON GoodsTable.Ref = GoodsByReferences.Ref
		|			AND GoodsTable.Products = GoodsByReferences.Products
		|			AND GoodsTable.Characteristic = GoodsByReferences.Characteristic
		|			AND GoodsTable.Series = GoodsByReferences.Series
		|			AND GoodsByReferences.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|
		|INDEX BY
		|	Ref,
		|	Products,
		|	Characteristic,
		|	Series
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 4
		|SELECT DISTINCT
		|	GoodsTable.ReferenceOrder AS ReferenceOrder
		|INTO ShipmentReferences
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS GoodsTable
		|WHERE
		|	(GoodsTable.Ref, GoodsTable.Products, GoodsTable.Characteristic) IN
		|			(SELECT DISTINCT
		|				ShippedGoods.Ref			AS Ref,
		|				ShippedGoods.Products		AS Products,
		|				ShippedGoods.Characteristic	AS Characteristic
		|			FROM
		|				ShippedGoods AS ShippedGoods)
		|	AND (GoodsTable.ReferenceOrder REFS Document.InventoryTransfer
		|		OR GoodsTable.ReferenceOrder REFS Document.TransferOrder)
		|
		|INDEX BY
		|	ReferenceOrder
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 5
		|SELECT
		|	GoodsOfOrder.Products		AS Products,
		|	GoodsOfOrder.Characteristic		AS Characteristic,
		|	GoodsOfOrder.Series				AS Series,
		|	SUM(GoodsOfOrder.Count)	AS Count
		|INTO RegisteredProducts
		|FROM
		|	Document.GoodsReceiptNote.Goods AS GoodsOfOrder
		|		INNER JOIN Document.GoodsReceiptNote AS HeaderData_
		|		ON GoodsOfOrder.Ref = HeaderData_.Ref
		|WHERE
		|	HeaderData_.Posted
		|	AND HeaderData_.Ref <> &CurIncomingOrder
		|	AND HeaderData_.ReferenceOrder IN
		|			(SELECT DISTINCT
		|				ShipmentReferences.ReferenceOrder AS ReferenceOrder
		|			FROM
		|				ShipmentReferences AS ShipmentReferences)
		|	AND GoodsOfOrder.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND (GoodsOfOrder.Products, GoodsOfOrder.Characteristic) IN
		|			(SELECT DISTINCT
		|				ShippedGoods.Products AS Products,
		|				ShippedGoods.Characteristic AS Characteristic
		|			FROM
		|				ShippedGoods AS ShippedGoods)
		|
		|GROUP BY
		|	GoodsOfOrder.Products,
		|	GoodsOfOrder.Characteristic,
		|	GoodsOfOrder.Series
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Series
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 6
		|SELECT
		|	NestedQuery.Products				AS Products,
		|	NestedQuery.Characteristic				AS Characteristic,
		|	NestedQuery.Series						AS Series,
		|	SUM(NestedQuery.Count)			AS Count
		|INTO ShippedGoodsWithSeries
		|FROM
		|	(SELECT
		|		ShippedGoods.Products			AS Products,
		|		ShippedGoods.Characteristic		AS Characteristic,
		|		ShippedGoods.Series					AS Series,
		|		ShippedGoods.Count			AS Count
		|	FROM
		|		ShippedGoods AS ShippedGoods
		|	WHERE
		|		ShippedGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsOfOrder.Products			AS Products,
		|		GoodsOfOrder.Characteristic			AS Characteristic,
		|		GoodsOfOrder.Series					AS Series,
		|		-GoodsOfOrder.Count			AS Count
		|	FROM
		|		RegisteredProducts AS GoodsOfOrder
		|			INNER JOIN ShippedGoods AS ShippedGoods
		|			ON GoodsOfOrder.Products = ShippedGoods.Products
		|				AND GoodsOfOrder.Characteristic = ShippedGoods.Characteristic
		|				AND GoodsOfOrder.Series = ShippedGoods.Series
		|	
		|	) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Series
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 7
		|SELECT DISTINCT
		|	GoodsToReceive.Products		AS Products,
		|	GoodsToReceive.Characteristic	AS Characteristic,
		|	GoodsToReceive.Purpose		AS Purpose
		|INTO DestinationsOfGoods
		|FROM
		|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.GoodsReceiptNotesToRegister > 0
		|	AND GoodsToReceive.DocumentInflow IN(&ReferenceOrder)
		|	AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 8
		|SELECT
		|	GoodsToReceive.Products			AS Products,
		|	GoodsToReceive.Characteristic		AS Characteristic,
		|	GoodsToReceive.Series				AS Series,
		|	SUM(GoodsToReceive.Count)	AS Count
		|INTO ProductsToBeReceivedWithSeries
		|FROM
		|	(SELECT
		|		GoodsToReceive.Products		AS Products,
		|		GoodsToReceive.Characteristic	AS Characteristic,
		|		GoodsToReceive.Series			AS Series,
		|		-GoodsToReceive.ToRegisterGoodsReceiptsBalance AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive.Balance(
		|				&DateOfRemainingGoods,
		|				Warehouse = &Warehouse
		|				AND Sender = &Sender
		|				AND DocumentInflow IN(&ReferenceOrder)
		|				AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|				AND (Products, Characteristic) IN
		|						(SELECT DISTINCT
		|							ShippedGoods.Products		AS Products,
		|							ShippedGoods.Characteristic	AS Characteristic
		|						FROM
		|							ShippedGoods AS ShippedGoods
		|						WHERE
		|							ShippedGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|		) AS GoodsToReceive
		|	WHERE
		|		GoodsToReceive.ToRegisterGoodsReceiptsBalance < 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsToReceive.Products		AS Products,
		|		GoodsToReceive.Characteristic	AS Characteristic,
		|		GoodsToReceive.Series			AS Series,
		|		GoodsToReceive.ToRegisterGoodsReceipts AS Count
		|	FROM
		|		AccumulationRegister.GoodsToReceive AS GoodsToReceive
		|	WHERE
		|		GoodsToReceive.Active
		|		AND GoodsToReceive.Warehouse = &Warehouse
		|		AND GoodsToReceive.Recorder = &CurIncomingOrder
		|		AND GoodsToReceive.DocumentInflow IN(&ReferenceOrder)
		|		AND GoodsToReceive.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND GoodsToReceive.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND (Products, Characteristic) IN
		|				(SELECT DISTINCT
		|					ShippedGoods.Products		AS Products,
		|					ShippedGoods.Characteristic	AS Characteristic
		|				FROM
		|					ShippedGoods AS ShippedGoods
		|				WHERE
		|					ShippedGoods.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|	
		|	) AS GoodsToReceive
		|
		|GROUP BY
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Series
		|
		|HAVING
		|	SUM(GoodsToReceive.Count) > 0
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 9
		|SELECT
		|	DocumentGoods.Products					AS Products,
		|	DocumentGoods.Characteristic					AS Characteristic,
		|	CASE
		|		WHEN DestinationsOfGoods.Purpose IS NULL
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DestinationsOfGoods.Purpose
		|	END											AS Purpose,
		|	DocumentGoods.Package						AS Package,
		|	ISNULL(&QueryTextPackagingFactor, 1)	AS PackagingFactor,
		|	SUM(DocumentGoods.Count)				AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)		AS NumberOfPackages
		|FROM
		|	ProductsOrdersToRequest AS DocumentGoods
		|		LEFT JOIN DestinationsOfGoods AS DestinationsOfGoods
		|		ON DocumentGoods.Products = DestinationsOfGoods.Products
		|			AND DocumentGoods.Characteristic = DestinationsOfGoods.Characteristic
		|
		|WHERE
		|	ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	CASE
		|		WHEN DestinationsOfGoods.Purpose IS NULL
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DestinationsOfGoods.Purpose
		|	END,
		|	DocumentGoods.Package,
		|	ISNULL(&QueryTextPackagingFactor, 1)
		|
		|ORDER BY
		|	PackagingFactor
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 10
		|SELECT
		|	GoodsToReceive.Products		AS Products,
		|	GoodsToReceive.Characteristic	AS Characteristic,
		|	CASE
		|		WHEN DestinationsOfGoods.Purpose IS NULL
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DestinationsOfGoods.Purpose
		|	END								AS Purpose,
		|	GoodsToReceive.Series			AS Series,
		|	GoodsToReceive.Count		AS Count,
		|	GoodsToReceive.Count		AS NumberOfPackages
		|FROM
		|	ProductsToBeReceivedWithSeries AS GoodsToReceive
		|		LEFT JOIN DestinationsOfGoods AS DestinationsOfGoods
		|		ON GoodsToReceive.Products = DestinationsOfGoods.Products
		|			AND GoodsToReceive.Characteristic = DestinationsOfGoods.Characteristic
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 11
		|SELECT
		|	SeriesTable.DateOfShipment	AS DateOfShipment,
		|	SeriesTable.Products	AS Products,
		|	SeriesTable.Characteristic	AS Characteristic,
		|	CASE
		|		WHEN DestinationsOfGoods.Purpose IS NULL
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DestinationsOfGoods.Purpose
		|	END						AS Purpose,
		|	SeriesTable.Series			AS Series,
		|	SeriesTable.Count		AS Count,
		|	SeriesTable.Count		AS NumberOfPackages
		|FROM
		|	ShippedGoods AS SeriesTable
		|		LEFT JOIN DestinationsOfGoods AS DestinationsOfGoods
		|		ON SeriesTable.Products = DestinationsOfGoods.Products
		|			AND SeriesTable.Characteristic = DestinationsOfGoods.Characteristic
		|WHERE
		|	(SeriesTable.Products, SeriesTable.Characteristic, SeriesTable.Series) IN
		|			(SELECT DISTINCT
		|				ShippedGoods.Products AS Products,
		|				ShippedGoods.Characteristic AS Characteristic,
		|				ShippedGoods.Series AS Series
		|			FROM
		|				ShippedGoodsWithSeries AS ShippedGoods)
		|
		|ORDER BY
		|	DateOfShipment,
		|	SeriesTable.LineNumber
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 12
		|SELECT
		|	SeriesTable.Products	AS Products,
		|	SeriesTable.Characteristic	AS Characteristic,
		|	CASE
		|		WHEN DestinationsOfGoods.Purpose IS NULL
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE DestinationsOfGoods.Purpose
		|	END						AS Purpose,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	SeriesTable.Series			AS Series,
		|	SeriesTable.Count		AS Count,
		|	SeriesTable.Count		AS NumberOfPackages
		|FROM
		|	ShippedGoodsWithSeries AS SeriesTable
		|		LEFT JOIN DestinationsOfGoods AS DestinationsOfGoods
		|		ON SeriesTable.Products = DestinationsOfGoods.Products
		|			AND SeriesTable.Characteristic = DestinationsOfGoods.Characteristic";
		
		Query.Text = StrReplace(Query.Text,
									"&QueryTextPackagingFactor",
									Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
										"DocumentGoods.Package",
										"DocumentGoods.Products"));
		
		If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.InventoryTransfer")
			And Common.ObjectAttributeValue(Object.ReferenceOrder, "TransferAgainstOrders") Then
			
			OrderToTransfer = Common.ObjectAttributeValue(Object.ReferenceOrder, "TransferOrder");
			If Not ValueIsFilled(OrderToTransfer) Then
				OrderToTransfer = Common.UnloadColumn(
												Common.ObjectAttributeValue(Object.ReferenceOrder, "Goods").Unload(),
												"TransferOrder",
												True);
			EndIf;
		Else
			OrderToTransfer = Object.ReferenceOrder;
		EndIf;
		
		UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date);
		
		Query.SetParameter("CurIncomingOrder",			Object.Ref);
		Query.SetParameter("ReferenceOrder",					OrderToTransfer);
		Query.SetParameter("DateOfRemainingGoods",					CurrentSessionDate());
		Query.SetParameter("Sender",					Object.Sender);
		Query.SetParameter("Warehouse",							Object.Warehouse);
		Query.SetParameter("UseBinLocationWarehousing",	UseBinLocationWarehousing);
		Query.SetParameter("GoodsTable",					Object.Goods.Unload(, UnloadedColumns));
		
		QueryResult = Query.ExecuteBatch();
		ResultBoundary = QueryResult.UBound();
		
		DocumentGoods = QueryResult[ResultBoundary - 3].Unload();
		SeriesByOrders = QueryResult[ResultBoundary - 2].Unload();
		
		ShippedSeriesToDistribution	= QueryResult[ResultBoundary - 1].Unload();
		ShippedSeriesToSubtract		= QueryResult[QueryResult.UBound()].Unload();
		
		DocumentGoods.Indexes.Add("Products, Characteristic, Purpose");
		ShippedSeriesToSubtract.Indexes.Add("Products, Characteristic, Purpose, Series");
		
		SetOfSeries = ShippedSeriesToSubtract.CopyColumns();
		ShippedSeries = TableOfDistributedShippedSeries(ShippedSeriesToDistribution, ShippedSeriesToSubtract);
		
		FillInTransferSeriesTable(SetOfSeries, ShippedSeries, DocumentGoods);
		FillInTransferSeriesTable(SetOfSeries, SeriesByOrders, DocumentGoods);
		
	Else
		
		If TypeOf(Object.ReferenceOrder) = Type("DocumentRef.TransferOrder") Then
			QueryTextByReferences =
			"SELECT DISTINCT
			|	InventoryTransfer.Ref AS ReferenceOrder
			|FROM
			|	Document.InventoryTransfer AS InventoryTransfer
			|WHERE
			|	InventoryTransfer.Posted
			|	AND InventoryTransfer.Goods.TransferOrder = &ReferenceOrder";
		Else
			QueryTextByReferences = "&ReferenceOrder";
		EndIf;
		
		QueryText =
		"SELECT
		|	DocumentGoods.Products	AS Products,
		|	DocumentGoods.Characteristic	AS Characteristic,
		|	DocumentGoods.Purpose		AS Purpose,
		|	CASE
		|		WHEN &UseBinLocationWarehousing
		|			THEN CAST(DocumentGoods.Package AS Catalog.PackagesAndUnitsOfMeasure)
		|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|	END							AS Package,
		|	DocumentGoods.Count		AS Count,
		|	CASE
		|		WHEN &UseBinLocationWarehousing
		|			THEN DocumentGoods.NumberOfPackages
		|		ELSE DocumentGoods.Count
		|	END							AS NumberOfPackages
		|INTO ProductsOrdersToRequest
		|FROM
		|	&GoodsTable AS DocumentGoods
		|WHERE
		|	NOT DocumentGoods.ThisIsAPackingList
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Purpose
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	DocumentGoods.Products					AS Products,
		|	DocumentGoods.Characteristic					AS Characteristic,
		|	DocumentGoods.Purpose						AS Purpose,
		|	DocumentGoods.Package						AS Package,
		|	ISNULL(&QueryTextPackagingFactor, 1)	AS PackagingFactor,
		|	SUM(DocumentGoods.Count)				AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)		AS NumberOfPackages
		|FROM
		|	ProductsOrdersToRequest AS DocumentGoods
		|
		|WHERE
		|	ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Purpose,
		|	DocumentGoods.Package,
		|	ISNULL(&QueryTextPackagingFactor, 1)
		|
		|ORDER BY
		|	PackagingFactor
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	NestedQuery.Series,
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages
		|FROM
		|	(SELECT
		|		InventoryTransferSetOfSeries.Products AS Products,
		|		InventoryTransferSetOfSeries.Characteristic AS Characteristic,
		|		CASE
		|			WHEN ISNULL(InventoryTransferSetOfSeries.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN InventoryTransferSetOfSeries.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose,
		|		InventoryTransferSetOfSeries.Series AS Series,
		|		InventoryTransferSetOfSeries.Count AS Count,
		|		InventoryTransferSetOfSeries.Count AS NumberOfPackages
		|	FROM
		|		Document.InventoryTransfer.SetOfSeries AS InventoryTransferSetOfSeries
		|	WHERE
		|		InventoryTransferSetOfSeries.Ref IN(&QueryTextByReferences)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MovementOfGoodsGoods.Products,
		|		MovementOfGoodsGoods.Characteristic,
		|		CASE
		|			WHEN ISNULL(MovementOfGoodsGoods.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN MovementOfGoodsGoods.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		MovementOfGoodsGoods.Series,
		|		MovementOfGoodsGoods.Count,
		|		MovementOfGoodsGoods.NumberOfPackages
		|	FROM
		|		Document.InventoryTransfer.Goods AS MovementOfGoodsGoods
		|	WHERE
		|		MovementOfGoodsGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND MovementOfGoodsGoods.Ref IN(&QueryTextByReferences)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ReceiptOrderForGoodsOfSeries.Products,
		|		ReceiptOrderForGoodsOfSeries.Characteristic,
		|		ReceiptOrderForGoodsOfSeries.Purpose,
		|		ReceiptOrderForGoodsOfSeries.Series,
		|		-ReceiptOrderForGoodsOfSeries.Count,
		|		-ReceiptOrderForGoodsOfSeries.NumberOfPackages
		|	FROM
		|		Document.GoodsReceiptNote.Goods AS ReceiptOrderForGoodsOfSeries
		|	WHERE
		|		ReceiptOrderForGoodsOfSeries.Ref.ReferenceOrder = &ReferenceOrder
		|		AND ReceiptOrderForGoodsOfSeries.Ref <> &CurIncomingOrder
		|		AND ReceiptOrderForGoodsOfSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND ReceiptOrderForGoodsOfSeries.Ref.Posted) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose,
		|	NestedQuery.Series
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0";
		
		QueryText = StrReplace(QueryText, "&QueryTextByReferences", QueryTextByReferences);
		QueryText = StrReplace(QueryText,
									"&QueryTextPackagingFactor",
									Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
										"DocumentGoods.Package",
										"DocumentGoods.Products"));
		
		UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,Object.Premise,Object.Date);
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("GoodsTable",					Object.Goods.Unload(, UnloadedColumns));
		Query.SetParameter("UseBinLocationWarehousing",	UseBinLocationWarehousing);
		Query.SetParameter("ReferenceOrder", 					Object.ReferenceOrder);
		Query.SetParameter("CurIncomingOrder", 			Object.Ref);

		QueryResult	= Query.ExecuteBatch();
		ResultBoundary	= QueryResult.UBound();
		
		DocumentGoods		= QueryResult[ResultBoundary - 1].Unload();
		SeriesByOrder	= QueryResult[ResultBoundary].Unload();
		
		DocumentGoods.Indexes.Add("Products, Characteristic, Purpose");		
		
		SetOfSeries = SeriesByOrder.CopyColumns();
		
		FillInTransferSeriesTable(SetOfSeries, SeriesByOrder, DocumentGoods);
	
	EndIf;
	
	Return SetOfSeries;
	
EndFunction

// Parameters:
// 	Object - FormDataStructure - contains including:
// 		* Ref - DocumentRef.GoodsReceiptNote - 
Function TableOfSeriesOfProducts(Object)
	If False Then

	ElsIf TypeOf(Object.ReferenceOrder) = Type("DocumentRef.ProductionStage2_2") Then
		QueryText =
		"SELECT
		|	NestedQuery.Series AS Series,
		|	SUM(NestedQuery.Count) AS Count,
		|	NestedQuery.Products AS Products,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Purpose AS Purpose,
		|	NestedQuery.Package AS Package
		|FROM
		|	(SELECT
		|		CASE
		|			WHEN ISNULL(OutputProductSeriesTable.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|				THEN OutputProductSeriesTable.Series
		|			ELSE ManufacturedProducts.Series
		|		END AS Series,
		|		MAX(CASE
		|				WHEN ISNULL(OutputProductSeriesTable.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|					THEN OutputProductSeriesTable.Count
		|				ELSE ManufacturedProducts.Count
		|			END) AS Count,
		|		ManufacturedProducts.Products AS Products,
		|		ManufacturedProducts.Characteristic AS Characteristic,
		|		CASE
		|			WHEN ISNULL(ManufacturedProducts.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN ManufacturedProducts.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose,
		|		ManufacturedProducts.Package AS Package
		|	FROM
		|		Document.ProductionStage2_2.ManufacturedProducts AS ManufacturedProducts
		|			LEFT JOIN Document.ProductionStage2_2.BatchFinishedProducts AS OutputProductSeriesTable
		|			ON ManufacturedProducts.Ref = OutputProductSeriesTable.Ref
		|				AND ManufacturedProducts.Recipient = OutputProductSeriesTable.Recipient
		|				AND ManufacturedProducts.Products = OutputProductSeriesTable.Products
		|				AND ManufacturedProducts.Characteristic = OutputProductSeriesTable.Characteristic
		|				AND ManufacturedProducts.Purpose = OutputProductSeriesTable.Purpose
		|				AND ManufacturedProducts.Manufactured = OutputProductSeriesTable.Manufactured
		|				AND ManufacturedProducts.ProductionDate = OutputProductSeriesTable.ProductionDate
		|	WHERE
		|		ManufacturedProducts.Ref = &ReferenceOrder
		|		AND ManufacturedProducts.Recipient = &Warehouse
		|		AND ManufacturedProducts.Ref.Posted
		|		AND NOT ManufacturedProducts.Canceled
		|		AND ManufacturedProducts.Manufactured
		|		AND CASE
		|				WHEN ISNULL(OutputProductSeriesTable.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|					THEN OutputProductSeriesTable.Series
		|				ELSE ManufacturedProducts.Series
		|			END <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	GROUP BY
		|		ManufacturedProducts.Package,
		|		CASE
		|			WHEN ISNULL(OutputProductSeriesTable.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|				THEN OutputProductSeriesTable.Series
		|			ELSE ManufacturedProducts.Series
		|		END,
		|		CASE
		|			WHEN ISNULL(ManufacturedProducts.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN ManufacturedProducts.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		ManufacturedProducts.Characteristic,
		|		ManufacturedProducts.Products
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		-SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		SeriesTable.Purpose,
		|		SeriesTable.Package
		|	FROM
		|		Document.GoodsReceiptNote.Goods AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref.ReferenceOrder = &ReferenceOrder
		|		AND SeriesTable.Ref <> &CurIncomingOrder
		|		AND SeriesTable.Ref.Warehouse = &Warehouse
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND SeriesTable.Ref.Posted
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CASE
		|			WHEN ISNULL(BatchTableByProducts.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|				THEN BatchTableByProducts.Series
		|			ELSE SideAndIntermediateRelease.Series
		|		END,
		|		MAX(CASE
		|				WHEN ISNULL(BatchTableByProducts.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|					THEN BatchTableByProducts.Count
		|				ELSE SideAndIntermediateRelease.Count
		|			END),
		|		SideAndIntermediateRelease.Products,
		|		SideAndIntermediateRelease.Characteristic,
		|		CASE
		|			WHEN ISNULL(SideAndIntermediateRelease.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN SideAndIntermediateRelease.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		SideAndIntermediateRelease.Package
		|	FROM
		|		Document.ProductionStage2_2.SideAndIntermediateRelease AS SideAndIntermediateRelease
		|			LEFT JOIN Document.ProductionStage2_2.BatchSideAndIntermediateRelease AS BatchTableByProducts
		|			ON SideAndIntermediateRelease.Ref = BatchTableByProducts.Ref
		|				AND SideAndIntermediateRelease.Recipient = BatchTableByProducts.Recipient
		|				AND SideAndIntermediateRelease.Products = BatchTableByProducts.Products
		|				AND SideAndIntermediateRelease.Characteristic = BatchTableByProducts.Characteristic
		|				AND SideAndIntermediateRelease.Purpose = BatchTableByProducts.Purpose
		|				AND SideAndIntermediateRelease.Manufactured = BatchTableByProducts.Manufactured
		|				AND SideAndIntermediateRelease.ProductionDate = BatchTableByProducts.ProductionDate
		|				AND SideAndIntermediateRelease.ProductOwner = BatchTableByProducts.ProductOwner
		|	WHERE
		|		SideAndIntermediateRelease.Ref = &ReferenceOrder
		|		AND SideAndIntermediateRelease.Recipient = &Warehouse
		|		AND SideAndIntermediateRelease.Ref.Posted
		|		AND NOT SideAndIntermediateRelease.Canceled
		|		AND SideAndIntermediateRelease.Manufactured
		|		AND CASE
		|				WHEN ISNULL(BatchTableByProducts.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|					THEN BatchTableByProducts.Series
		|				ELSE SideAndIntermediateRelease.Series
		|			END <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	GROUP BY
		|		SideAndIntermediateRelease.Package,
		|		CASE
		|			WHEN ISNULL(BatchTableByProducts.Series, VALUE(Catalog.ItemsBatches.EmptyRef)) <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|				THEN BatchTableByProducts.Series
		|			ELSE SideAndIntermediateRelease.Series
		|		END,
		|		SideAndIntermediateRelease.Characteristic,
		|		CASE
		|			WHEN ISNULL(SideAndIntermediateRelease.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN SideAndIntermediateRelease.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END,
		|		SideAndIntermediateRelease.Products) AS NestedQuery
		|	
		|		GROUP BY
		|		NestedQuery.Series,
		|		NestedQuery.Products,
		|		NestedQuery.Characteristic,
		|		NestedQuery.Purpose,
		|		NestedQuery.Package
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0";
	ElsIf TypeOf(Object.ReferenceOrder) = Type("DocumentRef.MovementOfProductsAndMaterials") Then
		QueryText =
		"SELECT
		|	NestedQuery.Series AS Series,
		|	SUM(NestedQuery.Count) AS Count,
		|	NestedQuery.Products AS Products,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Purpose AS Purpose
		|FROM
		|	(SELECT
		|		ManufacturedProducts.Series AS Series,
		|		ManufacturedProducts.Count AS Count,
		|		ManufacturedProducts.Products AS Products,
		|		ManufacturedProducts.Characteristic AS Characteristic,
		|		CASE
		|			WHEN ISNULL(ManufacturedProducts.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN ManufacturedProducts.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose
		|	FROM
		|		Document.MovementOfProductsAndMaterials.Goods AS ManufacturedProducts
		|	WHERE
		|		ManufacturedProducts.Ref = &ReferenceOrder
		|		AND ManufacturedProducts.Ref.Recipient = &Warehouse
		|		AND ManufacturedProducts.Ref.Posted
		|		AND ManufacturedProducts.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		CASE
		|			WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN SeriesTable.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END
		|	FROM
		|		Document.MovementOfProductsAndMaterials.SetOfSeries AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref = &ReferenceOrder
		|		AND SeriesTable.Ref.Recipient = &Warehouse
		|		AND SeriesTable.Ref.Posted
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		-SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		SeriesTable.Purpose
		|	FROM
		|		Document.GoodsReceiptNote.Goods AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref.ReferenceOrder = &ReferenceOrder
		|		AND SeriesTable.Ref <> &CurIncomingOrder
		|		AND SeriesTable.Ref.Warehouse = &Warehouse
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND SeriesTable.Ref.Posted) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Series,
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0";
	ElsIf TypeOf(Object.ReferenceOrder) = Type("DocumentRef.BackflushProduction") Then
		QueryText =
		"SELECT
		|	NestedQuery.Series AS Series,
		|	SUM(NestedQuery.Count) AS Count,
		|	NestedQuery.Products AS Products,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Purpose AS Purpose
		|FROM
		|	(SELECT
		|		ManufacturedProducts.Series AS Series,
		|		ManufacturedProducts.Count AS Count,
		|		ManufacturedProducts.Products AS Products,
		|		ManufacturedProducts.Characteristic AS Characteristic,
		|		CASE
		|			WHEN ISNULL(ManufacturedProducts.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN ManufacturedProducts.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose
		|	FROM
		|		Document.BackflushProduction.ManufacturedProducts AS ManufacturedProducts
		|	WHERE
		|		ManufacturedProducts.Ref = &ReferenceOrder
		|		AND ManufacturedProducts.Recipient = &Warehouse
		|		AND ManufacturedProducts.Ref.Posted
		|		AND ManufacturedProducts.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		CASE
		|			WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN SeriesTable.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END
		|	FROM
		|		Document.BackflushProduction.BatchFinishedProducts AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref = &ReferenceOrder
		|		AND SeriesTable.Recipient = &Warehouse
		|		AND SeriesTable.Ref.Posted
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ManufacturedProducts.Series AS Series,
		|		ManufacturedProducts.Count AS Count,
		|		ManufacturedProducts.Products AS Products,
		|		ManufacturedProducts.Characteristic AS Characteristic,
		|		CASE
		|			WHEN ISNULL(ManufacturedProducts.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN ManufacturedProducts.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose
		|	FROM
		|		Document.BackflushProduction.SideAndIntermediateRelease AS ManufacturedProducts
		|	WHERE
		|		ManufacturedProducts.Ref = &ReferenceOrder
		|		AND ManufacturedProducts.Recipient = &Warehouse
		|		AND ManufacturedProducts.Ref.Posted
		|		AND ManufacturedProducts.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		CASE
		|			WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN SeriesTable.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END
		|	FROM
		|		Document.BackflushProduction.BatchSideAndIntermediateRelease AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref = &ReferenceOrder
		|		AND SeriesTable.Recipient = &Warehouse
		|		AND SeriesTable.Ref.Posted
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		-SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		SeriesTable.Purpose
		|	FROM
		|		Document.GoodsReceiptNote.Goods AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref.ReferenceOrder = &ReferenceOrder
		|		AND SeriesTable.Ref <> &CurIncomingOrder
		|		AND SeriesTable.Ref.Warehouse = &Warehouse
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND SeriesTable.Ref.Posted) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Series,
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0";
	ElsIf TypeOf(Object.ReferenceOrder) = Type("DocumentRef.RecyclableWasteAllocation") Then
		QueryText =
		"SELECT
		|	NestedQuery.Series AS Series,
		|	SUM(NestedQuery.Count) AS Count,
		|	NestedQuery.Products AS Products,
		|	NestedQuery.Characteristic AS Characteristic,
		|	NestedQuery.Purpose AS Purpose
		|FROM
		|	(SELECT
		|		ManufacturedProducts.Series AS Series,
		|		ManufacturedProducts.Count AS Count,
		|		ManufacturedProducts.Products AS Products,
		|		ManufacturedProducts.Characteristic AS Characteristic,
		|		CASE
		|			WHEN ISNULL(ManufacturedProducts.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN ManufacturedProducts.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose
		|	FROM
		|		Document.RecyclableWasteAllocation AS ManufacturedProducts
		|	WHERE
		|		ManufacturedProducts.Ref = &ReferenceOrder
		|		AND ManufacturedProducts.Recipient = &Warehouse
		|		AND ManufacturedProducts.Ref.Posted
		|		AND ManufacturedProducts.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		CASE
		|			WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
		|				THEN SeriesTable.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END
		|	FROM
		|		Document.RecyclableWasteAllocation.SetOfSeries AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref = &ReferenceOrder
		|		AND SeriesTable.Ref.Recipient = &Warehouse
		|		AND SeriesTable.Ref.Posted
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesTable.Series,
		|		-SeriesTable.Count,
		|		SeriesTable.Products,
		|		SeriesTable.Characteristic,
		|		SeriesTable.Purpose
		|	FROM
		|		Document.GoodsReceiptNote.Goods AS SeriesTable
		|	WHERE
		|		SeriesTable.Ref.ReferenceOrder = &ReferenceOrder
		|		AND SeriesTable.Ref <> &CurIncomingOrder
		|		AND SeriesTable.Ref.Warehouse = &Warehouse
		|		AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|		AND SeriesTable.Ref.Posted) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Series,
		|	NestedQuery.Products,
		|	NestedQuery.Characteristic,
		|	NestedQuery.Purpose
		|
		|HAVING
		|	SUM(NestedQuery.Count) > 0";
	Else
		ExceptionText = NStr("vi = 'Loại lệnh không được hỗ trợ.';
							|ru = 'Тип распоряжения не поддерживается.';
							|en = 'Reference type is not supported.'; fa = 'Reference type is not supported.';
							|it = 'Tipo di disposizione non supportata.';
							|pl = 'Typ zamówienia nie jest obsługiwany.';
							|tr = 'Emir türü desteklenmiyor.'");
		Raise ExceptionText;
	EndIf;

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.SetParameter("CurIncomingOrder", Object.Ref);
	
	SetOfSeries = Query.Execute().Unload();
	
	Return SetOfSeries;
	
	Return New ValueTable;
	
EndFunction

Function TableOfSeriesAtAcceptanceOnOtherRegistration(Object)
	
	If Object.BusinessOperation <> Enums.BusinessTransactions.PutOutOfOperation Then
		Return TableOfFinancialSeriesFromOrder(Object);
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	NestedQuery.Series				AS Series,
	|	SUM(NestedQuery.Count)	AS Count,
	|	NestedQuery.Products		AS Products,
	|	NestedQuery.Characteristic		AS Characteristic,
	|	NestedQuery.Purpose			AS Purpose
	|FROM
	|	(SELECT
	|		Goods.Series AS		Series,
	|		Goods.Count		AS Count,
	|		Goods.Products		AS Products,
	|		Goods.Characteristic	AS Characteristic,
	|		CASE
	|			WHEN ISNULL(Goods.Purpose.RecordsInWarehouseRegisters, FALSE)
	|				THEN Goods.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END					AS Purpose
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.SetOfSeries AS Goods
	|	
	|	WHERE
	|		Goods.Ref = &ReferenceOrder
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.Series AS		Series,
	|		Goods.Count		AS Count,
	|		Goods.Products		AS Products,
	|		Goods.Characteristic	AS Characteristic,
	|		CASE
	|			WHEN ISNULL(Goods.Purpose.RecordsInWarehouseRegisters, FALSE)
	|				THEN Goods.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END					AS Purpose
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.Goods AS Goods
	|	
	|	WHERE
	|		Goods.Ref = &ReferenceOrder
	|		AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SetOfSeries.Series AS		Series,
	|		-SetOfSeries.Count		AS Count,
	|		SetOfSeries.Products		AS Products,
	|		SetOfSeries.Characteristic	AS Characteristic,
	|		SetOfSeries.Purpose		AS Purpose
	|	FROM
	|		Document.GoodsReceiptNote.Goods AS SetOfSeries
	|			INNER JOIN Document.GoodsReceiptNote AS ReceiptGoodsOrder
	|			ON SetOfSeries.Ref = ReceiptGoodsOrder.Ref
	|	
	|	WHERE
	|		ReceiptGoodsOrder.Posted
	|		AND ReceiptGoodsOrder.ReferenceOrder = &ReferenceOrder
	|		AND ReceiptGoodsOrder.Ref <> &CurIncomingOrder
	|		AND SetOfSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Series,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose
	|
	|HAVING
	|	SUM(NestedQuery.Count) > 0";
	
	Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
	Query.SetParameter("CurIncomingOrder", Object.Ref);
	
	SetOfSeries = Query.Execute().Unload();
	
	Return SetOfSeries;
	
EndFunction

// Parameters:
// 	Object - FormDataStructure - contains including:
// 		* Ref - DocumentRef.GoodsReceiptNote - 
Function TableOfFinancialSeriesFromOrder(Object)
	
	QueryText =
	"SELECT
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Series AS Series,
	|	-SUM(NestedQuery.Count) AS Count
	|FROM
	|	(SELECT
	|		GoodsReadyForReceiptBalance.Products AS Products,
	|		GoodsReadyForReceiptBalance.Characteristic AS Characteristic,
	|		GoodsReadyForReceiptBalance.Purpose AS Purpose,
	|		GoodsReadyForReceiptBalance.Series AS Series,
	|		GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS Count
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				DocumentInflow = &ReferenceOrder
	|					AND NOT &TheseAreGoodsInTransit
	|					AND Warehouse = &Warehouse
	|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS GoodsReadyForReceiptBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsReadyForReceiptBalance.Products AS Products,
	|		GoodsReadyForReceiptBalance.Characteristic AS Characteristic,
	|		GoodsReadyForReceiptBalance.Purpose AS Purpose,
	|		GoodsReadyForReceiptBalance.Series AS Series,
	|		-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance AS Count
	|	FROM
	|		AccumulationRegister.GoodsToReceive.Balance(
	|				,
	|				DocumentInflow = &ReferenceOrder
	|					AND &TheseAreGoodsInTransit
	|					AND Warehouse = &Warehouse
	|					AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS GoodsReadyForReceiptBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsReadyForReceipt.Products,
	|		GoodsReadyForReceipt.Characteristic,
	|		GoodsReadyForReceipt.Purpose,
	|		GoodsReadyForReceipt.Series,
	|		CASE
	|			WHEN GoodsReadyForReceipt.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN GoodsReadyForReceipt.ToRegisterGoodsReceipts
	|			ELSE -GoodsReadyForReceipt.ToRegisterGoodsReceipts
	|		END
	|	FROM
	|		AccumulationRegister.GoodsToReceive AS GoodsReadyForReceipt
	|	WHERE
	|		GoodsReadyForReceipt.Recorder = &CurIncomingOrder) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series
	|
	|HAVING
	|	-SUM(NestedQuery.Count) > 0";
	
	OperationsGoodsInTransit = New Array();
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	TheseAreGoodsInTransit = OperationsGoodsInTransit.Find(Object.BusinessOperation) <> Undefined;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ReferenceOrder", Object.ReferenceOrder);
	Query.SetParameter("Warehouse", Object.Warehouse);
	Query.SetParameter("CurIncomingOrder", Object.Ref);
	Query.SetParameter("TheseAreGoodsInTransit", TheseAreGoodsInTransit);
	SetOfSeries = Query.Execute().Unload();
	
	Return SetOfSeries;
	
EndFunction

Function TableOfDistributedShippedSeries(TableToDistribution, SubtractionTable)
	
	TableOfSeries	= SubtractionTable.CopyColumns();
	LinesToDelete	= New Array;
	FilterAttributes	= "Products, Characteristic, Purpose, Series";
	RowFilter		= New Structure(FilterAttributes);
	
	For Each DistributableString In TableToDistribution Do
		LinesToDelete.Clear();
		FillPropertyValues(RowFilter, DistributableString);
		
		LinesToSubtract = SubtractionTable.FindRows(RowFilter);
		
		For Each SubtractedString In LinesToSubtract Do
			Count = Min(DistributableString.Count, SubtractedString.Count);
			
			NewRow = TableOfSeries.Add();
			FillPropertyValues(NewRow, SubtractedString);
			NewRow.Count			= Count;
			NewRow.NumberOfPackages	= Count;
			
			SubtractedString.Count = SubtractedString.Count - NewRow.Count;
			
			If SubtractedString.Count = 0 Then
				LinesToDelete.Add(SubtractedString);
				
				Break;
			EndIf;
		EndDo;
		
		For Each RowToDelete In LinesToDelete Do
			SubtractionTable.Delete(RowToDelete);
		EndDo;
	EndDo;
	
	TableOfSeries.GroupBy("Products, Characteristic, Purpose, Series", "Count, NumberOfPackages");
	
	Return TableOfSeries;
	
EndFunction

Procedure FillInTransferSeriesTable(SetOfSeries, SeriesByOrders, DocumentGoods)
	
	RowFilter = New Structure("Products, Characteristic, Purpose");
	
	For Each RowSeries In SeriesByOrders Do
		
		QuantityToDistribution	= RowSeries.Count;
		ProductLinesThatAreBeingDeleted		= New Array;
		
		FillPropertyValues(RowFilter, RowSeries);
		
		ProductLines_3 = DocumentGoods.FindRows(RowFilter);
		
		For Each LineProducts_ In ProductLines_3 Do
			
			If QuantityToDistribution <= 0 Then
				Break;
			EndIf;
			
			NewRow = SetOfSeries.Add();
			FillPropertyValues(NewRow, LineProducts_);
			NewRow.Series = RowSeries.Series;
			
			If QuantityToDistribution > LineProducts_.Count Then
				NewRow.Count	= LineProducts_.Count;
				NumberOfPackages		= LineProducts_.NumberOfPackages;
			Else
				NewRow.Count	= RowSeries.Count;
				NumberOfPackages		= QuantityToDistribution / LineProducts_.PackagingFactor;
			EndIf;
			
			NewRow.NumberOfPackages = ?(ValueIsFilled(NewRow.Package),
												Int(NumberOfPackages),
												NumberOfPackages);
			
			QuantityToDistribution = QuantityToDistribution - NewRow.Count;
			
			LineProducts_.Count			= LineProducts_.Count - NewRow.Count;
			LineProducts_.NumberOfPackages	= LineProducts_.NumberOfPackages - NewRow.NumberOfPackages;
			
			If LineProducts_.Count <= 0 Then
				ProductLinesThatAreBeingDeleted.Add(LineProducts_);
			EndIf;
			
		EndDo;
		
		For Each RowToDelete In ProductLinesThatAreBeingDeleted Do
			DocumentGoods.Delete(RowToDelete);
		EndDo;
		
		ProductLinesThatAreBeingDeleted.Clear();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.GoodsReceiptNote"; 
	
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ReturnOfGoodsNotReceivedByRecipient",
	" CASE
	|		WHEN GoodsTable.Ref.WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipient)
	|			OR GoodsTable.Ref.WarehouseOperation = VALUE(Enum.WarehouseTransactions.ReturnOfGoodsNotReceivedByRecipientNotUsed)
	|			THEN TRUE
	|		ELSE FALSE
	|	END ");
	RedefiningParameterCalculation.Insert("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
	" CASE
	|		WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|			AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
	|				THEN TRUE
	|			ELSE FALSE
	|	END ");
	
	RedefiningParameterCalculation.Insert("DocumentInflow", "GoodsTable.Ref.ReferenceOrder");
	
	If RegisterName = "GoodsBatchMovement" Then
	
		QueryText = QueryTextTableGoodsBatchMovement(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTTableProducts", QueryTextTTTableProducts(Query, QueryTexts));
		SynonymForDocumentTable = "GoodsTable";
		
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
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(QueryText,
																								FullDocumentName,
																								SynonymForDocumentTable,
																								RedefiningParameterCalculation,
																								TemporaryTableQueryTexts);
	
	Result.ParameterValues.Insert("TypesOfExpectedAdmission", Metadata.DefinedTypes.ExpectedReceipt.Type.Types());
	
	Return Result;

EndFunction

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.GoodsReceiptNote.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.25.7";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a07d2ef3-6091-4ea1-9e4e-8a145862fc1f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.GoodsReceiptNote.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhập các chứng từ ""Phiếu nhập kho"":';
								|ru = 'Обновление документов ""Приходный ордер на товары"":';
								|en = 'Update the ""Goods receipt"" documents:'; fa = 'Update the ""Goods receipt"" documents:';
								|it = 'Update the ""Goods receipt"" documents:';
								|pl = 'Update the ""Goods receipt"" documents:';
								|tr = '""Ambar giriş fişi"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền lại mục tin ""Người gửi"" trong các chứng từ có kiểu lệnh là ""Sản xuất không theo đơn hàng"".';
								|ru = '- перезаполняет реквизит ""Отправитель"" в документах, распоряжениями для которых выступает ""Производство без заказа"".';
								|en = '- Refills the ""Sender"" attribute in the documents generated based on ""Backflush production"".'; fa = '- Refills the ""Sender"" attribute in the documents generated based on ""Backflush production"".';
								|it = '- Refills the ""Sender"" attribute in the documents generated based on ""Backflush production"".';
								|pl = '- Refills the ""Sender"" attribute in the documents generated based on ""Backflush production"".';
								|tr = '- talimatı ""Geriye dönük üretim"" olan belgelerde  ""Gönderen"" özniteliğini yeniden doldurur.'"));
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.GoodsReceiptNote.FullName());
	ItemsToRead.Add(Metadata.Documents.BackflushProduction.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.GoodsReceiptNote.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.GoodsReceiptNote";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.GoodsReceiptNote AS DocumentAttributes
	|WHERE
	|	FALSE
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.GoodsReceiptNote AS DocumentAttributes
	|	
	|	INNER JOIN Document.BackflushProduction AS AttributesBP
	|	ON AttributesBP.Ref = DocumentAttributes.ReferenceOrder
	|
	|WHERE
	|	NOT DocumentAttributes.Sender = AttributesBP.Department
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.GoodsReceiptNote";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref        AS Ref,
	|	AttributesBP.Department      AS Sender,
	|	DocumentAttributes.DataVersion AS DataVersion
	|FROM
	|	UpdatedData AS UpdatedData
	|
	|	LEFT JOIN Document.GoodsReceiptNote AS DocumentAttributes
	|	ON UpdatedData.Ref = DocumentAttributes.Ref
	|	
	|	LEFT JOIN Document.BackflushProduction AS AttributesBP
	|	ON AttributesBP.Ref = DocumentAttributes.ReferenceOrder
	|";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = 0;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				If Not DocumentObject.Sender = Selection.Sender Then
					DocumentObject.Sender = Selection.Sender;
					ObjectModified = True;
				EndIf;
			EndIf;
			
			ExceptionReason = 2; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = 2 Then
				Raise NStr("vi = 'Không thể xử lý việc cập nhật các chứng từ ""Phiếu nhập kho"".';
							|ru = 'Не удалось обработать обновление документов ""Приходный ордер на товары"".';
							|en = 'Cannot process the update of the ""Goods receipt"" documents.'; fa = 'Cannot process the update of the ""Goods receipt"" documents.';
							|it = 'Cannot process the update of the ""Goods receipt"" documents.';
							|pl = 'Cannot process the update of the ""Goods receipt"" documents.';
							|tr = '""Ambar giriş fişi"" belgelerinin güncellenme işlemi gerçekleştirilemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
