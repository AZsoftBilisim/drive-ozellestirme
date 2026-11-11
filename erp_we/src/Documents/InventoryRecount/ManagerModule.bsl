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
	
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("SerialAccounting");
	
	InventoryRecountLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryRecount") Then
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
		
		QueryTextTableGoodsForRegistrationOfSurplusesAndShortages(Query, QueryTexts, Registers);
		QueryTextTableGoodsInStorageBins(Query, QueryTexts, Registers);
		QueryTextTableStorageBinsLocks(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableProductStock(Query, QueryTexts, Registers);
		QueryTextTableCargoItemsForRecordingSurplusesAndShortages(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
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
	
	Documents.WriteOffOfGoodsShortages.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsDamage.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsMisgrading.AddGenerateCommand(GenerationCommands);
	
	Documents.InventorySurplusRecognition.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.WarehouseGoodsIssueReceiptWizard.AddCreateCommandBasedOnWarehouseActRegistrationForm(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	CreationBasedOnCommand = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(
									GenerationCommands);
	
	If CreationBasedOnCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreationBasedOnCommand,
															"Status",
															Enums.InventoryRecountStatuses.Prepared2,
															DataCompositionComparisonType.NotEqual);
	EndIf;
	
	InventoryRecountLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the "product Recalculation" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryRecount) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryRecount.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryRecount);
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
	
	Reports.WarehouseStock.AddCommandToRecalculateProducts(ReportsCommands);
		
	Reports.UnregisteredSurplusesAndShortagesOfGoods.AddMakeRecalculationCommand(ReportsCommands);
	
	InventoryRecountLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Premise,Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	Structure
//		See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.UseItemsBatch = GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", Object.Warehouse));
	SeriesSpecificationParameters.FullObjectName = "Document.InventoryRecount";
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.Recalculate);
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(
		                                                  	Object.Warehouse,Object.Premise, Object.Date);
	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		SeriesSpecificationParameters.LinkFields.Add("Cell");
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";	
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.Date = Object.Date;
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences	 - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	Return FieldValuesToIdentifyReferences.Ref;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//
// Parameters:
//  SeriesSpecificationParameters	 - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//  String - Query text
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 13
	|					ELSE 14
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 9
	|					ELSE 10
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 5
	|								ELSE 6
	|							END
	|					ELSE CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 7
	|							ELSE 8
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|			THEN CASE
	|					WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 3
	|					ELSE 4
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	ProductsToRequest AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON (&Warehouse = Warehouses.Ref)
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND Goods.ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	Statuses.LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the default value of the "Print quantity by accounting" attribute
//
// Parameters:
//  Ref			 - DocumentRef.InventoryRecount	 - recalculation of products in which the attribute will be filled in
//  EmployeeResponsible	 - CatalogRef.Users	 - responsible for the recalculation.
//
// Returns:
//  Boolean - the value of the "Print quantity by accounting" attribute.
//
Function GetValueForPrintQuantityByAccountingDefaultAttribute(Ref,EmployeeResponsible) Export
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED TOP 1
	|	InventoryRecount.PrintQuantityByRecords
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Posted
	|	AND InventoryRecount.EmployeeResponsible = &EmployeeResponsible
	|	AND InventoryRecount.Ref <> &Ref
	|
	|ORDER BY
	|	InventoryRecount.Date DESC";
	
	Query.SetParameter("EmployeeResponsible",EmployeeResponsible);
	Query.SetParameter("Ref",Ref);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		PrintQuantityByRecords = Selection.PrintQuantityByRecords;
	EndIf;
	
	Return PrintQuantityByRecords;
	
EndFunction

// Returns a structure with cells for excess and reject by default
//
// Parameters:
//  Ref		 - DocumentRef.InventoryRecount	 - the document, which will be filled with the received values
//  Warehouse		 - CatalogRef.Warehouses			 - warehouse of the conversion document
//  Premise	 - CatalogRef.Warerooms	 - the premise of the recalculation.
//
// Returns:
//  Structure - structure with keys:
//  *StorageBinForSurplusesConsolidation - CatalogRef.StorageBins - surplus consolidation cell,
//  *StorageBinForSpoiledGoodsConsolidation - CatalogRef.StorageBins - damage consolidation cell,
//  *MoveGoodsSurplusesIntoBin - Boolean - use a separate surplus cell,
//  *MoveSpoiledGoodsIntoBin - Boolean - use a separate damage cell.
//
Function GetDefaultSurplusAndRejectCells(Ref,Warehouse,Premise) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	InventoryRecount.StorageBinForSurplusesConsolidation,
	|	InventoryRecount.StorageBinForSpoiledGoodsConsolidation,
	|	InventoryRecount.MoveGoodsSurplusesIntoBin,
	|	InventoryRecount.MoveSpoiledGoodsIntoBin
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Posted
	|	AND InventoryRecount.Warehouse = &Warehouse
	|	AND InventoryRecount.Premise = &Premise
	|	AND InventoryRecount.Ref <> &Ref
	|
	|ORDER BY
	|	InventoryRecount.Date DESC";
	
	Query.SetParameter("Warehouse",Warehouse);
	Query.SetParameter("Premise",Premise);
	Query.SetParameter("Ref",Ref);
	
	Selection = Query.Execute().Select();
	
	ReturnStructure = New Structure("StorageBinForSurplusesConsolidation,StorageBinForSpoiledGoodsConsolidation,MoveGoodsSurplusesIntoBin,MoveSpoiledGoodsIntoBin");
	
	If Selection.Next() Then
		FillPropertyValues(ReturnStructure,Selection);
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Returns the text of the query
//
// Parameters:
//  RequestFormationParameters - Structure	 - the "selection Mode" key must be present.
//
// Returns:
//  String - Query text
//
Function RequestTextForAvailableAssignments(RequestFormationParameters) Export
	
	If RequestFormationParameters.ChoiceMode = "ByBalancesInCell" Then
		Return Catalogs.Assignments.RequestTextForAvailableAssignmentsBasedOnBalancesInCell(RequestFormationParameters);
	Else
		Return Catalogs.Assignments.RequestTextOfUnsecuredAppointmentsSecured(RequestFormationParameters);
	EndIf;
	
EndFunction

// Returns a table of cell States and dates for recalculating cells after the product recalculation.
//
// Parameters:
//  DocumentRef	 - DocumentRef.InventoryRecount - the reference to the conversion of goods
//  Status			 - EnumRef.InventoryRecountStatuses - the status of the conversion.
//
// Returns:
//  ValueTable - a table of values with cell states and dates.
//
Function TableOfCellRecalculationStates(DocumentRef, Status) Export
	
	TableOfCellRecalculationStates = New ValueTable;
	
	If Status = Enums.InventoryRecountStatuses.Completed2 Then

		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	RecalculationOfGoods.Cell,
		|	VALUE(Enum.BinRecountStates.RecalculationIsCompleted) AS State,
		|	RecalculationOfGoods.Ref.Date AS DocumentDate
		|FROM
		|	Document.InventoryRecount.Goods AS RecalculationOfGoods
		|WHERE
		|	RecalculationOfGoods.Ref = &DocumentRef";
		
		Query.SetParameter("DocumentRef", DocumentRef);
		TableOfCellRecalculationStates = Query.Execute().Unload();
		
		
	EndIf;
	
	Return TableOfCellRecalculationStates;
	
EndFunction

// Returns a list of unformed product recalculations
//	Parameters:
//		Warehouse - CatalogRef.Warehouses - the warehouse where you need to search for unformed recalculations of goods.
//	Returns:
//		Array - an array of unformulated recalculations of goods for a given warehouse or all warehouses, if the warehouse is not specified.
//
Function UnformattedRecalculationsByWarehouse(Warehouse = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	InventoryRecount.Ref AS Document
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Posted
	|	AND NOT InventoryRecount.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)";
	If ValueIsFilled(Warehouse) Then
		Query.SetParameter("Warehouse", Warehouse);
		Query.Text = Query.Text + Chars.LF + "AND InventoryRecount.Warehouse = &Warehouse";
	EndIf;
	
	Return Query.Execute().Unload().UnloadColumn("Document");
			
EndFunction

// Document parameters for the Attribute filling mechanism are subject to unblocking and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.PurchaseOrder - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.FullObjectName = "Document.InventoryRecount";
	ActionParameters.ReadableFields = "Products,ControlledLotReference,CountReal,Count";
	ActionParameters.EditableFields = "ControlledLotReference,SubjectToUnlocking,QualityConfirmationDate";
	ActionParameters.OverridableProcessingInObjectManager = True;
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	
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
	
	// Regular filling.
	If CurrentRow.CountReal <= CurrentRow.Count Then
		FillInRegular = False;
		CurrentRow.SubjectToUnlocking = False;
		CurrentRow.QualityConfirmationDate = '00010101';
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
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

// Used in information security update mechanisms
//
// Parameters:
//  RegisterName	 - String	 - register name.
//
// Returns:
//  Map -
//
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	InventoryRecount.Date AS Period,
	|	InventoryRecount.Status AS Status,
	|	InventoryRecount.Warehouse AS Warehouse,
	|	CASE
	|		WHEN InventoryRecount.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND InventoryRecount.Date >= InventoryRecount.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	CASE
	|		WHEN InventoryRecount.Warehouse.UseWarerooms
	|				AND InventoryRecount.Date >= InventoryRecount.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN InventoryRecount.Premise.UseBinLocationWarehousing
	|							AND InventoryRecount.Date >= InventoryRecount.Premise.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN InventoryRecount.Warehouse.UseBinLocationWarehousing
	|						AND InventoryRecount.Date >= InventoryRecount.Warehouse.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS UseBinLocationWarehousing,
	|	InventoryRecount.Premise AS Premise,
	|	InventoryRecount.LockStorageBins AS LockStorageBins
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Status",      Attributes.Status);
	Query.SetParameter("Period",      Attributes.Period);
	Query.SetParameter("UseBinLocationWarehousing", Attributes.UseBinLocationWarehousing);
	Query.SetParameter("UseWarehouseManagemantSystemForGoodsSurplusesShortages",Attributes.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	Query.SetParameter("Warehouse", Attributes.Warehouse);
	Query.SetParameter("Premise", Attributes.Premise);
	Query.SetParameter("LockStorageBins", Attributes.LockStorageBins);
	
EndProcedure

Function QueryTextTableGoodsForRegistrationOfSurplusesAndShortages(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfSurplusesAndShortages";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProducts_1.Products AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	TTProducts_1.Count AS ToCertificateRegistration,
	|	TTProducts_1.Purpose,
	|	CASE
	|		WHEN TTProducts_1.ThisIsSeriesAtCostPrice
	|			THEN TTProducts_1.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	CASE
	|		WHEN TTProducts_1.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|WHERE
	|	&Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
	|	AND &UseWarehouseManagemantSystemForGoodsSurplusesShortages";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsInStorageBins(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsInStorageBins";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	GoodsTable.Products AS Products,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	GoodsTable.Series AS Series,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.NumberOfPackagesReal - GoodsTable.NumberOfPackages
	|		ELSE GoodsTable.CountReal - GoodsTable.Count
	|	END AS InStock,
	|	GoodsTable.Cell AS Cell,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType
	|FROM
	|	Document.InventoryRecount.Goods AS GoodsTable
	|WHERE
	|	&UseBinLocationWarehousing
	|	AND &Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
	|	AND GoodsTable.Ref = &Ref
	|	AND GoodsTable.NumberOfPackagesReal - GoodsTable.NumberOfPackages > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	GoodsTable.Series,
	|	-(CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.NumberOfPackagesReal - GoodsTable.NumberOfPackages
	|		ELSE GoodsTable.CountReal - GoodsTable.Count
	|	END),
	|	GoodsTable.Cell,
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense)
	|FROM
	|	Document.InventoryRecount.Goods AS GoodsTable
	|WHERE
	|	&UseBinLocationWarehousing
	|	AND &Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
	|	AND GoodsTable.Ref = &Ref
	|	AND GoodsTable.NumberOfPackagesReal - GoodsTable.NumberOfPackages < 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableStorageBinsLocks(Query, QueryTexts, Registers)
	
	RegisterName = "StorageBinsLocks";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	RecalculationOfGoods.Cell AS Cell,
	|	VALUE(Enum.TypesOfWarehouseBinLocks.Full) AS LockType
	|FROM
	|	Document.InventoryRecount.Goods AS RecalculationOfGoods
	|WHERE
	|	&UseBinLocationWarehousing
	|	AND &LockStorageBins
	|	AND RecalculationOfGoods.Ref = &Ref
	|
	|GROUP BY
	|	RecalculationOfGoods.Cell";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Purpose AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	&Warehouse AS Sender,
	|	&Premise AS WareroomOfSender,
	|	UNDEFINED AS Recipient,
	|	UNDEFINED AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.Recalculate) AS WarehouseOperation,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages AS ThisIsWarehouseRecord
	|FROM
	|	TTProducts_1 AS SeriesTable
	|WHERE
	|	&Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableProductStock(Query, QueryTexts, Registers)
	
	RegisterName = "ProductStock";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProducts_1", QueryTexts) Then
		QueryTextTTProducts_1(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	RecalculationOfGoods.Products                  AS Products,
	|	RecalculationOfGoods.Characteristic                AS Characteristic,
	|	CASE
	|		WHEN ISNULL(RecalculationOfGoods.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN RecalculationOfGoods.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	RecalculationOfGoods.ControlledLotReference,
	|	RecalculationOfGoods.Series,
	|	RecalculationOfGoods.Count AS InStock,
	|	CASE
	|		WHEN RecalculationOfGoods.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&Period                                     AS Period,
	|	&Warehouse                                      AS Warehouse,
	|	&Premise                                  AS Premise
	|FROM
	|	TTProducts_1 AS RecalculationOfGoods
	|WHERE
	|	&Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
	| 	AND &UseWarehouseManagemantSystemForGoodsSurplusesShortages";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.CountReal - TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.InventoryRecount.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
		|	AND TabPart.CountReal - TabPart.Count > 0
		|	AND TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date
		|	AND ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	-(TabPart.CountReal - TabPart.Count) AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.InventoryRecount.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
		|	AND TabPart.CountReal - TabPart.Count < 0
		|	AND TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date
		|	AND ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	TextProductLocationsInDocument =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	MAX(TabPart.Ref.Date) AS Date,
		|	MAX(TabPart.Ref.Warehouse) AS Warehouse,
		|	TabPart.Products AS Products,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	MAX(TabPart.QualityConfirmationDate) AS QualityConfirmationDate,
		|	MAX(TabPart.SubjectToUnlocking) AS SubjectToUnlocking,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.Package AS CargoItem,
		|	CASE
		|		WHEN TabPart.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
		|			THEN TabPart.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	SUM(TabPart.NumberOfPackagesReal - TabPart.NumberOfPackages) AS CountBalance
		|INTO ProductLocationsInDocument
		|FROM
		|	Document.InventoryRecount.Goods AS TabPart
		|WHERE
		|	TabPart.Ref IN(&Ref)
		|		AND TabPart.Ref.Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
		|		AND TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|		AND TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date
		|		AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|GROUP BY
		|	TabPart.Ref,
		|	TabPart.Package,
		|	TabPart.Products,
		|	TabPart.Characteristic,
		|	TabPart.Purpose,
		|	TabPart.ControlledLotReference,
		|	CASE
		|		WHEN TabPart.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
		|			THEN TabPart.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END
		|HAVING
		|	SUM(TabPart.NumberOfPackagesReal - TabPart.NumberOfPackages) <> 0
		|INDEX BY
		|	Ref, Products, CargoItem";
		
	TextProductLocationsInProductRange =
		"SELECT DISTINCT
		|	ProductLocationsBalance.Ref AS Ref,
		|	ProductLocationsBalance.Products AS Products,
		|	ProductLocationsBalance.Characteristic AS Characteristic,
		|	ProductLocationsBalance.Purpose AS Purpose,
		|	ProductLocationsBalance.Series AS Series,
		|	ProductLocationsBalance.ControlledLotReference AS ControlledLotReference,
		|	PackagesAndUnitsOfMeasure.Ref AS CargoItem,
		|	PackagesAndUnitsOfMeasure.NumberOfPackages AS NumberOfSeats
		|INTO ItemsInProductRange
		|FROM
		|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
		|		INNER JOIN ProductLocationsInDocument AS ProductLocationsBalance
		|		ON (PackagesAndUnitsOfMeasure.Owner = CASE
		|				WHEN ProductLocationsBalance.Products.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
		|					THEN ProductLocationsBalance.Products.Ref
		|				ELSE ProductLocationsBalance.Products.PackagingGroup
		|			END)
		|WHERE
		|	PackagesAndUnitsOfMeasure.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|INDEX BY
		|	Ref, Products, CargoItem";
	
	TextWholeSets =
		"SELECT
		|	ItemsInProductRange.Ref AS Ref,
		|	ItemsInProductRange.Products AS Products,
		|	ItemsInProductRange.Characteristic AS Characteristic,
		|	ItemsInProductRange.Purpose AS Purpose,
		|	ItemsInProductRange.ControlledLotReference AS ControlledLotReference,
		|	MAX(TabPart.Warehouse) AS Warehouse,
		|	MAX(TabPart.Date) AS Date,
		|	MAX(TabPart.QualityConfirmationDate) AS QualityConfirmationDate,
		|	MAX(TabPart.SubjectToUnlocking) AS SubjectToUnlocking,
		|	ItemsInProductRange.Series AS Series,
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats <= 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) - 1
		|		END) AS KitCount
		|INTO WholeSets
		|FROM
		|	ItemsInProductRange AS ItemsInProductRange
		|		
		|		LEFT JOIN ProductLocationsInDocument AS TabPart
		|		ON TabPart.Ref = ItemsInProductRange.Ref
		|			AND TabPart.Products = ItemsInProductRange.Products
		|			AND TabPart.Characteristic = ItemsInProductRange.Characteristic
		|			AND TabPart.Purpose = ItemsInProductRange.Purpose
		|			AND TabPart.ControlledLotReference = ItemsInProductRange.ControlledLotReference
		|			AND TabPart.Series = ItemsInProductRange.Series
		|			AND TabPart.CargoItem = ItemsInProductRange.CargoItem
		|			AND TabPart.CountBalance > 0
		|		
		|GROUP BY
		|	ItemsInProductRange.Ref,
		|	ItemsInProductRange.Products,
		|	ItemsInProductRange.Characteristic,
		|	ItemsInProductRange.Purpose,
		|	ItemsInProductRange.ControlledLotReference,
		|	ItemsInProductRange.Series
		|HAVING
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats <= 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) - 1
		|		END) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	ItemsInProductRange.Ref AS Ref,
		|	ItemsInProductRange.Products AS Products,
		|	ItemsInProductRange.Characteristic AS Characteristic,
		|	ItemsInProductRange.Purpose AS Purpose,
		|	ItemsInProductRange.ControlledLotReference AS ControlledLotReference,
		|	MAX(TabPart.Warehouse) AS Warehouse,
		|	MAX(TabPart.Date) AS Date,
		|	MAX(TabPart.QualityConfirmationDate) AS QualityConfirmationDate,
		|	MAX(TabPart.SubjectToUnlocking) AS SubjectToUnlocking,
		|	ItemsInProductRange.Series AS Series,
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats > 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))- 1
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) 
		|		END) AS KitCount
		|FROM
		|	ItemsInProductRange AS ItemsInProductRange
		|		
		|		LEFT JOIN ProductLocationsInDocument AS TabPart
		|		ON TabPart.Ref = ItemsInProductRange.Ref
		|			AND TabPart.Products = ItemsInProductRange.Products
		|			AND TabPart.Characteristic = ItemsInProductRange.Characteristic
		|			AND TabPart.Purpose = ItemsInProductRange.Purpose
		|			AND TabPart.ControlledLotReference = ItemsInProductRange.ControlledLotReference
		|			AND TabPart.Series = ItemsInProductRange.Series
		|			AND TabPart.CargoItem = ItemsInProductRange.CargoItem
		|			AND TabPart.CountBalance < 0
		|		
		|GROUP BY
		|	ItemsInProductRange.Ref,
		|	ItemsInProductRange.Products,
		|	ItemsInProductRange.Characteristic,
		|	ItemsInProductRange.Purpose,
		|	ItemsInProductRange.ControlledLotReference,
		|	ItemsInProductRange.Series
		|HAVING
		|	MIN(CASE
		|			WHEN (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0)))
		|					- ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats > 0
		|				THEN CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))- 1
		|			ELSE (CAST(ISNULL(TabPart.CountBalance, 0) / ItemsInProductRange.NumberOfSeats AS NUMBER(12, 0))) 
		|		END) < 0";
	
	TemporaryTableTemplateTexts = New Structure();
	TemporaryTableTemplateTexts.Insert("ProductLocationsInDocument", TextProductLocationsInDocument);
	TemporaryTableTemplateTexts.Insert("ItemsInProductRange", TextProductLocationsInProductRange);
	TemporaryTableTemplateTexts.Insert("WholeSets", TextWholeSets);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.KitCount AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	WholeSets AS TabPart
		|WHERE
		|	TabPart.KitCount > 0
		|		AND VALUETYPE(TabPart.Ref) = TYPE(Document.InventoryRecount)"; // it is necessary that it is not doubled in the IB update.
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True,
		TemporaryTableTemplateTexts);
		
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	-TabPart.KitCount AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	WholeSets AS TabPart
		|WHERE
		|	TabPart.KitCount < 0
		|		AND VALUETYPE(TabPart.Ref) = TYPE(Document.InventoryRecount)"; // it is necessary that it is not doubled in the IB update.
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True,
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

	// The form of the task for the recalculation of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "RecalculationTask";
	PrintCommand.Presentation = NStr("vi = 'Mẫu nhiệm vụ để kiểm đếm hàng hóa';
									|ru = 'Бланк задания на пересчет товаров';
									|en = 'Inventory count task template'; fa = 'Inventory count task template';
									|it = 'Modulo del task di ricalcolo delle merci';
									|pl = 'Formularz do ponownego przeliczania towarów';
									|tr = 'Stok sayımı görev formu'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.AdditionalParameters.Insert("DisplayGradationsOfQuality",    False);
	PrintCommand.AdditionalParameters.Insert("DisplayRecalculationResults", False);
	
	If GetFunctionalOption("UseGoodsQuality") Then
		// Task form for recalculation of goods (with gradations of quality)
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "RecalculationTask";
		PrintCommand.Presentation = NStr("vi = 'Mẫu nhiệm vụ để kiểm đếm hàng hóa (có phân cấp chất lượng)';
										|ru = 'Бланк задания на пересчет товаров (с градациями качества)';
										|en = 'Inventory count task template (with quality levels)'; fa = 'Inventory count task template (with quality levels)';
										|it = 'Modulo del task di ricalcolo delle merci (con gradazioni di qualità)';
										|pl = 'Formularz do ponownego przeliczania towarów (z wskaźnikami jakości)';
										|tr = 'Stok sayımı görev formu (kalite notları ile)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayGradationsOfQuality",    True);
		PrintCommand.AdditionalParameters.Insert("DisplayRecalculationResults", False);
	EndIf;
	
	// The results of the recalculation of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "RecalculationTask";
	PrintCommand.Presentation = NStr("vi = 'Kết quả kiểm đếm hàng hóa';
									|ru = 'Результаты пересчета товаров';
									|en = 'Inventory count results'; fa = 'نتایج شمارش موجودی';
									|it = 'I risultati di ricalcolo delle merci';
									|pl = 'Wyniki ponownego przeliczenia towarów';
									|tr = 'Stok sayımı sonuçları'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.AdditionalParameters.Insert("DisplayGradationsOfQuality",    False);
	PrintCommand.AdditionalParameters.Insert("DisplayRecalculationResults", True);
	
	// The task form for the recalculation of goods (with reference cells)
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "RecalculationTask");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
	InventoryRecountLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "RecalculationTask") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"RecalculationTask",
			NStr("vi = 'Nhiệm vụ kiểm đếm hàng hóa';
				|ru = 'Задание на пересчет товаров';
				|en = 'Inventory count task'; fa = 'وظیفه شمارش موجودی';
				|it = 'Task di ricalcolo delle merci';
				|pl = 'Zadanie na inwentaryzacje';
				|tr = 'Stok sayımı görevi'"),
			PrintJob(ObjectsArray, PrintObjects, PrintParameters));
		
	EndIf;
	
	InventoryRecountLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

Function PrintJob(ObjectsArray, PrintObjects, PrintParameters)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	
	OutputCodes                = ValueIsFilled(NameOfCodeColumn);
	DisplayGradationsOfQuality    = PrintParameters.DisplayGradationsOfQuality;
	DisplayRecalculationResults = PrintParameters.DisplayRecalculationResults;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	
	SpreadsheetDocument.PrintParametersKey = "PrintPARAMETERS_COUNTOfGoods_countOfGoodsTask";
	
	QueryText = 
	"SELECT
	|	InventoryRecount.Ref AS Ref,
	|	InventoryRecount.Presentation AS PresentationOfDocument,
	|	InventoryRecount.Date AS Date,
	|	InventoryRecount.Number AS Number,
	|	InventoryRecount.Warehouse AS Warehouse,
	|	InventoryRecount.Premise AS Premise,
	|	InventoryRecount.StorageBinForSurplusesConsolidation AS SurplusCell,
	|	InventoryRecount.StorageBinForSpoiledGoodsConsolidation AS CellOfSpoiled,
	|	PRESENTATION(InventoryRecount.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(InventoryRecount.Premise) AS PremisePresentation,
	|	InventoryRecount.Performer.Individual AS Performer,
	|	InventoryRecount.PrintQuantityByRecords AS PrintQuantityByRecords,
	|	InventoryRecount.Status AS Status
	|FROM
	|	Document.InventoryRecount AS InventoryRecount
	|WHERE
	|	InventoryRecount.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	InventoryRecount.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RecalculationOfGoods.LineNumber 									AS LineNumber,
	|	RecalculationOfGoods.Count 									AS Count,
	|	RecalculationOfGoods.NumberOfPackages 							AS NumberOfPackages,
	|	&ReplacementText,
	|	RecalculationOfGoods.Products.DescriptionFull 				AS ProductsPresentation,
	|	RecalculationOfGoods.Characteristic.DescriptionFull 			AS CharacteristicPresentation,
	|	RecalculationOfGoods.Products 									AS Products,
	|	RecalculationOfGoods.Characteristic 								AS Characteristic,
	|	RecalculationOfGoods.Series 										AS Series,
	|	CASE WHEN RecalculationOfGoods.Package.Description IS NULL
	|		THEN PRESENTATION(RecalculationOfGoods.Products.UnitOfMeasure)
	|		ELSE RecalculationOfGoods.Package.Description
	|	END 																AS UnitOfMeasurementPresentationPackaging,
	|	RecalculationOfGoods.Series.Description AS SeriesPresentation,
	|	PRESENTATION(RecalculationOfGoods.Products.UnitOfMeasure) AS UnitOfMeasurementPresentationProduct,
	|	PRESENTATION(RecalculationOfGoods.Cell) AS CellPresentation,
	|	RecalculationOfGoods.Products.Code AS Code,
	|	RecalculationOfGoods.Products.SKU AS SKU,
	|	RecalculationOfGoods.Ref AS Ref
	|FROM
	|	Document.InventoryRecount.Goods AS RecalculationOfGoods
	|WHERE
	|	RecalculationOfGoods.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	RecalculationOfGoods.LineNumber
	|TOTALS BY
	|	Ref";
	
	If DisplayRecalculationResults Then
		ReplacementText = "	RecalculationOfGoods.CountReal								AS CountReal,
		|	RecalculationOfGoods.NumberOfPackagesReal						AS NumberOfPackagesReal,
		|	RecalculationOfGoods.NumberOfPackagesReal - RecalculationOfGoods.NumberOfPackages AS NumberOfPackagesDiscrepancy,";
	Else
		ReplacementText = "	0								                                   AS CountReal,
		|	0						                                           AS NumberOfPackagesReal,
		|	0						                                           AS NumberOfPackagesDiscrepancy,";
	EndIf;
	QueryText = StrReplace(QueryText, "&ReplacementText,", ReplacementText);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Results = Query.ExecuteBatch(); 
	
	SelectionByDocuments = Results[0].Select();
	SelectionByTableParts = Results[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	If DisplayRecalculationResults Then
		DocumentSynonym = NStr("vi = 'Kết quả kiểm đếm hàng hóa';
								|ru = 'Результаты пересчета товаров';
								|en = 'Inventory count results'; fa = 'نتایج شمارش موجودی';
								|it = 'I risultati di ricalcolo delle merci';
								|pl = 'Wyniki ponownego przeliczenia towarów';
								|tr = 'Stok sayımı sonuçları'", Common.DefaultLanguageCode());
	Else
		DocumentSynonym = NStr("vi = 'Nhiệm vụ kiểm đếm hàng hóa';
								|ru = 'Задание на пересчет товаров';
								|en = 'Inventory count task'; fa = 'وظیفه شمارش موجودی';
								|it = 'Task di ricalcolo delle merci';
								|pl = 'Zadanie na inwentaryzacje';
								|tr = 'Stok sayımı görevi'", Common.DefaultLanguageCode());
	EndIf;
	
	While SelectionByDocuments.Next() Do
		DocumentAttributes = New Structure("Number, Date, Prefix");
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		Title = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym);
		
		If DisplayRecalculationResults
			And Not SelectionByDocuments.Status = Enums.InventoryRecountStatuses.Completed2 Then
			
			MessageText = NStr("vi = 'Chứng từ ""%PresentationOfDocument%"" đang ở trạng thái ""%Status%"". Chỉ có thể in kết quả kiểm đếm ở trạng thái ""Đã thực hiện""';
								|ru = 'Документ ""%PresentationOfDocument%"" находится в статусе ""%Status%"". Печать результатов пересчета возможна только в статусе ""Выполнено""';
								|en = 'Document ""%PresentationOfDocument%"" is in status ""%Status%"". You can print recalculation results only in status ""Completed""'; fa = 'Document ""%PresentationOfDocument%"" is in status ""%Status%"". You can print recalculation results only in status ""Completed""';
								|it = 'Il documento ""%PresentationOfDocument%"" è nello stato ""%Status%"". La stampa dei risultati di ricalcolo è possibile solo nello stato ""Completato""';
								|pl = 'Dokument ""%PresentationOfDocument%"" ma status ""%Status%"". Drukowanie wyników przeliczania jest możliwe tylko w stanie ""Zakończone""';
								|tr = '""%PresentationOfDocument%"" belgesi ""%Status%"" durumundadır. Yeniden hesaplama sonuçlarının yazdırılması yalnızca ""Tamamlandı"" durumunda mümkündür'");
			
			DocumentAttributes.Insert("Presentation",SelectionByDocuments.PresentationOfDocument);
			PresentationOfDocument = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
			
			MessageText = StrReplace(MessageText,"%PresentationOfDocument%",PresentationOfDocument);
			MessageText = StrReplace(MessageText,"%Status%",SelectionByDocuments.Status);
			
			Common.MessageToUser(MessageText);
			Continue;
		ElsIf SelectionByDocuments.Status = Enums.InventoryRecountStatuses.Prepared2 Then 
			MessageText = NStr("vi = 'Chứng từ ""%PresentationOfDocument%"" đang có trạng thái ""%Status%"". Có thể in nhiệm vụ kiểm đến với trạng thái ""%InProgress%"", ""%EnteringResults%"" và ""%Completed2%"".';
								|ru = 'Документ ""%PresentationOfDocument%"" находится в статусе ""%Status%"". Печать заданий на пересчет возможна в статусах ""%InProgress%"", ""%EnteringResults%"" и ""%Completed2%"".';
								|en = 'Document ""%PresentationOfDocument%"" is in status ""%Status%"". You can print recount jobs only in statuses ""%InProgress%"", ""%EnteringResults%"" and ""%Completed2%"".'; fa = 'Document ""%PresentationOfDocument%"" is in status ""%Status%"". You can print recount jobs only in statuses ""%InProgress%"", ""%EnteringResults%"" and ""%Completed2%"".';
								|it = 'Il documento ""%PresentationOfDocument%"" è nello stato ""%Status%"". La stampa dei risultati di ricalcolo è possibile solo negli stati ""%InProgress%"", ""%EnteringResults%"" e ""%Completed2%"".';
								|pl = 'Dokument ""%PresentationOfDocument%"" ma status ""%Status%"". Drukowanie zadań do ponownego obliczania jest możliwe w statusach ""%InProgress%"", ""%EnteringResults%"" i ""%Completed2%"".';
								|tr = '""%PresentationOfDocument%"" belgesi ""%Status%"" durumundadır. Yeniden hesaplama için yazdırma görevleri ""%InProgress%"", ""%EnteringResults%"" ve ""%Completed2%"" durumlarında mümkündür.'");
			
			DocumentAttributes.Insert("Presentation",SelectionByDocuments.PresentationOfDocument);
			PresentationOfDocument = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes);
			
			MessageText = StrReplace(MessageText,"%PresentationOfDocument%",PresentationOfDocument);
			MessageText = StrReplace(MessageText,"%Status%",SelectionByDocuments.Status);
			MessageText = StrReplace(MessageText,"%InProgress%", Enums.InventoryRecountStatuses.InProgress);
			MessageText = StrReplace(MessageText,"%EnteringResults%", Enums.InventoryRecountStatuses.EnteringResults);
			MessageText = StrReplace(MessageText,"%Completed2%", Enums.InventoryRecountStatuses.Completed2);
			
			Common.MessageToUser(MessageText);
			Continue;
		EndIf;
		
		WithdrawByAccounting = SelectionByDocuments.PrintQuantityByRecords Or DisplayRecalculationResults;
		ByAddressWarehouse = WarehousesServer.UseBinLocationWarehousing(
			SelectionByDocuments.Warehouse, SelectionByDocuments.Premise, SelectionByDocuments.Date);
		Template = PrintManagement.PrintFormTemplate("Document.InventoryRecount.PF_MXL_JobToRecountInventoryAtWarehouse");
			
		HeaderArea_ 		= Template.GetArea("Title");
		StorageArea_ = Template.GetArea("WarehouseExecutor");
		AreaSurplusCell	= Template.GetArea("AreaSurplusCell");
		AreaCellCorrupted	= Template.GetArea("AreaCellCorrupted");
		
		If ByAddressWarehouse Then
			
			If OutputCodes Then
				TableHeaderAreaStart 			= Template.GetArea("TableHeaderCellCodeAccounting|BeginningOfTheLine");
				AreaTableRowStart 			= Template.GetArea("TableRowCellCodeAccounting|BeginningOfTheLine");
				AreaBasementTableTop 			= Template.GetArea("BasementTableCellCodeAccounting|BeginningOfTheLine");
				AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeaderCellCodeAccounting|ColumnOfCodes");
				AreaTableRowCodeColumn 	= Template.GetArea("TableRowCellCodeAccounting|ColumnOfCodes");
				AreaBasementTableColumnCodes 	= Template.GetArea("BasementTableCellCodeAccounting|ColumnOfCodes");
				AreaTableHeaderProductColumn 	= Template.GetArea("TableHeaderCellCodeAccounting|ProductColumnCodeCell");
				AreaTableRowProductColumn 	= Template.GetArea("TableRowCellCodeAccounting|ProductColumnCodeCell");
				AreaBasementTableGoodsColumn 	= Template.GetArea("BasementTableCellCodeAccounting|ProductColumnCodeCell");
			Else
				TableHeaderAreaStart 			= Template.GetArea("TableHeaderCell|BeginningOfTheLine");
				AreaTableRowStart 			= Template.GetArea("TableRowCell|BeginningOfTheLine");
				AreaBasementTableTop 			= Template.GetArea("BasementTableCell|BeginningOfTheLine");
				AreaTableHeaderProductColumn 	= Template.GetArea("TableHeaderCell|ColumnOfProductsWithoutCellCodes");
				AreaTableRowProductColumn 	= Template.GetArea("TableRowCell|ColumnOfProductsWithoutCellCodes");
				AreaBasementTableGoodsColumn 	= Template.GetArea("BasementTableCell|ColumnOfProductsWithoutCellCodes");
			EndIf;
		Else 
			TableHeaderAreaStart 			= Template.GetArea("TableHeader|Number");
			AreaTableRowStart 			= Template.GetArea("TableRow|Number");
			AreaBasementTableTop 			= Template.GetArea("TableFooter|Number");
			
			If OutputCodes Then
				
				AreaTableHeaderCodeColumn 	= Template.GetArea("HeaderOfCodeAccountingTable|ColumnCellCode");
				AreaTableRowCodeColumn 	= Template.GetArea("RowOfCodeAccountingTable|ColumnCellCode");
				AreaBasementTableColumnCodes 	= Template.GetArea("BasementTableCoding|ColumnCellCode");
				AreaTableHeaderProductColumn 	= Template.GetArea("HeaderOfCodeAccountingTable|ColumnOfProductsWithoutCellCodes");
				AreaTableRowProductColumn 	= Template.GetArea("RowOfCodeAccountingTable|ColumnOfProductsWithoutCellCodes");
				AreaBasementTableGoodsColumn 	= Template.GetArea("BasementTableCoding|ColumnOfProductsWithoutCellCodes");
			Else 
				AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
				AreaTableRowProductColumn 	= Template.GetArea("TableRow|ProductColumn_");
				AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
			EndIf; 
		EndIf;
		
		PackingTableHeaderArea 	= Template.GetArea(?(ByAddressWarehouse, "TableHeaderCell|ColumnOfPackages", "TableHeader|ColumnOfPackages"));
		AreaRowOfPackingTable 	= Template.GetArea(?(ByAddressWarehouse, "TableRowCell|ColumnOfPackages", "TableRow|ColumnOfPackages"));
		PackingTableBasementArea 	= Template.GetArea("TableFooter|ColumnOfPackages");
				
		If OutputCodes Then
			
			AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
			
		EndIf;	
		
		If Not WithdrawByAccounting Then
			If DisplayGradationsOfQuality Then
				FactTableHeaderArea 	= Template.GetArea("HeaderOfQualityGradingTable|QualityLevels");
				AreaRowOfFactTable 	= Template.GetArea("RowOfQualityGradationTable|QualityLevels");
				AreaBasementTableFact 	= Template.GetArea("BasementQualityGradingTable|QualityLevels");
			Else 	
				FactTableHeaderArea 	= Template.GetArea("TableHeader|FactWithoutAccountingQuantity");
				AreaRowOfFactTable 	= Template.GetArea("TableRow|FactWithoutAccountingQuantity");
				AreaBasementTableFact 	= Template.GetArea("TableFooter|FactWithoutAccountingQuantity");
			EndIf;	
		Else
			
			AreaHeaderOfAccountingTable 		= Template.GetArea("HeaderOfCodeAccountingTable|AccountingColumn");
			AreaRowOfAccountingTable 	= Template.GetArea("RowOfCodeAccountingTable|AccountingColumn");
			AreaBasementAccountingTables 	= Template.GetArea("BasementTableCoding|AccountingColumn");
			AreaHeaderOfDeviationTable	= Template.GetArea("HeaderOfCodeAccountingTable|ColumnDeviation");
			AreaTableRowDeviation 	= Template.GetArea("RowOfCodeAccountingTable|ColumnDeviation");
			AreaBasementTableDeviation 	= Template.GetArea("BasementTableCoding|ColumnDeviation");
			If DisplayGradationsOfQuality Then
				FactTableHeaderArea 	= Template.GetArea("HeaderOfQualityGradingTable|QualityLevels");
				AreaRowOfFactTable 	= Template.GetArea("RowOfQualityGradationTable|QualityLevels");
				AreaBasementTableFact 	= Template.GetArea("BasementQualityGradingTable|QualityLevels");
			Else 
				FactTableHeaderArea 	= Template.GetArea("HeaderOfCodeAccountingTable|FactColumn");
				AreaRowOfFactTable 	= Template.GetArea("RowOfCodeAccountingTable|FactColumn");
				AreaBasementTableFact 	= Template.GetArea("BasementTableCoding|FactColumn");
			EndIf;	
		EndIf;		
			
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
			
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		HeaderDataStructure = New Structure;
		HeaderDataStructure.Insert("TitleText", Title);
		HeaderArea_.Parameters.Fill(HeaderDataStructure);

		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		StorageArea_.Parameters.PerformerPresentation	= PersonsTM.IndividualShortName(SelectionByDocuments.Performer, SelectionByDocuments.Date);
		StorageArea_.Parameters.WarehousePresentation		= WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation,
																											SelectionByDocuments.PremisePresentation);
		
		SpreadsheetDocument.Put(StorageArea_);
		
		If ValueIsFilled(SelectionByDocuments.SurplusCell) Then
			FillPropertyValues(AreaSurplusCell.Parameters, SelectionByDocuments);
			SpreadsheetDocument.Put(AreaSurplusCell);
		EndIf;
		
		If ValueIsFilled(SelectionByDocuments.CellOfSpoiled) Then
			FillPropertyValues(AreaCellCorrupted.Parameters, SelectionByDocuments);
			SpreadsheetDocument.Put(AreaCellCorrupted);
		EndIf;
		
		SpreadsheetDocument.Put(TableHeaderAreaStart);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
		SpreadsheetDocument.Join(PackingTableHeaderArea);
		
		If WithdrawByAccounting Then
			SpreadsheetDocument.Join(AreaHeaderOfAccountingTable);
		EndIf;
		
		SpreadsheetDocument.Join(FactTableHeaderArea);
		If WithdrawByAccounting Then
			SpreadsheetDocument.Join(AreaHeaderOfDeviationTable);
		EndIf;
		
		While SamplingByTSLines.Next() Do
			
			AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines[NameOfCodeColumn];
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				?(ValueIsFilled(SamplingByTSLines.Products), 
						SamplingByTSLines.ProductsPresentation, 
						NStr("vi = '<ô trống>';
							|ru = '<пустая ячейка>';
							|en = '<empty bin>'; fa = '<empty bin>';
							|it = '<cella vuota>';
							|pl = '<pusta komórka>';
							|tr = '<boş hücre>'", Common.DefaultLanguageCode())),
				SamplingByTSLines.CharacteristicPresentation,
				,
				SamplingByTSLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			AreaRowOfPackingTable.Parameters.Fill(SamplingByTSLines);
			
			SpreadsheetDocument.Join(AreaRowOfPackingTable);	
			
			If WithdrawByAccounting Then
				AreaRowOfAccountingTable.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaRowOfAccountingTable);
			EndIf;
			
			AreaRowOfFactTable.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Join(AreaRowOfFactTable);
			
			If WithdrawByAccounting Then
				AreaTableRowDeviation.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowDeviation);
			EndIf;
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		SpreadsheetDocument.Join(PackingTableBasementArea);
		If WithdrawByAccounting Then
			SpreadsheetDocument.Join(AreaBasementAccountingTables);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableFact);
		If WithdrawByAccounting Then
			SpreadsheetDocument.Join(AreaBasementTableDeviation);
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
	EndDo;
	
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
//		*HeaderResults			- QueryResult	- data for the document header used for printing
//															the item recalculation Task.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Job of the conversion products.
//		*ResultForPackages		- Undefined		- data about product packages in the tabular part of the document
//															that is used for printing a task for recalculating products.
//		*ResultBySeries			- QueryResult	- data about product series in the tabular part of the document
//															that is used for printing the product recalculation Task.
//
Function GetDataForPrintedFormForProductPlacement(PrintParameters, ObjectsArray) Export
	
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
	|	END)									AS NumberOfPackages
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
	|	END
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
	|	FALSE										AS BinLocationWarehousingIsUsed,
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
	|	FALSE										AS AdvancedWarehousingIsUsed,
	|	TaskData_.Performer.Individual	AS PerformerPresentation,
	|	TaskData_.PrintQuantityByRecords		AS WithdrawByAccounting
	|FROM
	|	Document.InventoryRecount AS TaskData_
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
	|	CASE
	|		WHEN ISNULL(Packages.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|			THEN TRUE
	|		ELSE FALSE
	|	END												AS CargoItem,
	|	CASE
	|		WHEN &SettingRecalculation
	|			THEN 0
	|		ELSE TableOfGoods.Count
	|	END												AS Count,
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages
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
	|	TableOfGoods.Series.Description	AS BatchPresentation
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
	|	AND NOT TableOfGoods.Series IS NULL
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic";
	
	SettingRecalculation = (PrintParameters.JobType = "RecalculationTask");
	
	If SettingRecalculation Then
		TextOfTermsAndConditionsForCompletingTask = 
		"	AND (DocumentGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|													VALUE(Enum.ItemsTypes.ReusablePackage))
		|		OR DocumentGoods.Products.ItemsType IS NULL)";
	Else
		TextOfTermsAndConditionsForCompletingTask = "";
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &TextOfTermsAndConditionsForCompletingTask", TextOfTermsAndConditionsForCompletingTask);
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
	Query.SetParameter("ObjectsArray",		ObjectsArray);
	Query.SetParameter("SettingRecalculation",	SettingRecalculation);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Undefined);
	TaskData_.Insert("ResultOnOrders",	Undefined);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 1]);
	TaskData_.Insert("ResultForPackages",		Undefined);
	TaskData_.Insert("ResultBySeries",			Result[MaxIndex]);
	
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
		|	SUM(DocumentGoods.Count)			AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
		|INTO TaskItems_
		|FROM
		|	Document.InventoryRecount.Goods AS DocumentGoods
		|		LEFT JOIN Document.InventoryRecount AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND &TextOfTermsAndConditionsForCompletingTask
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.Premise,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
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
		|	SUM(DocumentGoods.Count)			AS Count,
		|	SUM(DocumentGoods.NumberOfPackages)	AS NumberOfPackages
		|INTO TaskItems_
		|FROM
		|	Document.InventoryRecount.Goods AS DocumentGoods
		|		LEFT JOIN Document.InventoryRecount AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	AND &TextOfTermsAndConditionsForCompletingTask
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.Premise,
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Series,
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
		|		Document.InventoryRecount.Goods AS DocumentGoods
		|	
		|	WHERE
		|		DocumentGoods.Ref IN(&ObjectsArray)
		|		AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND &TextOfTermsAndConditionsForCompletingTask
		|	
		|	GROUP BY
		|		DocumentGoods.Ref,
		|		DocumentGoods.Products,
		|		DocumentGoods.Characteristic,
		|		DocumentGoods.Purpose,
		|		DocumentGoods.Series
		|	
		|	) AS GoodsWithoutPackaging_
		|		INNER JOIN Document.InventoryRecount.Goods AS DocumentGoods
		|		ON GoodsWithoutPackaging_.Ref = DocumentGoods.Ref
		|			AND GoodsWithoutPackaging_.Products = DocumentGoods.Products
		|			AND GoodsWithoutPackaging_.Characteristic = DocumentGoods.Characteristic
		|			AND GoodsWithoutPackaging_.Purpose = DocumentGoods.Purpose
		|			AND GoodsWithoutPackaging_.Series = DocumentGoods.Series
		|			AND GoodsWithoutPackaging_.Package = DocumentGoods.Package
		|		
		|		LEFT JOIN Document.InventoryRecount AS DocumentData
		|		ON GoodsWithoutPackaging_.Ref = DocumentData.Ref
		|
		|GROUP BY
		|	DocumentData.Ref,
		|	DocumentData.Warehouse,
		|	DocumentData.Premise,
		|	GoodsWithoutPackaging_.Products,
		|	GoodsWithoutPackaging_.Characteristic,
		|	GoodsWithoutPackaging_.Series,
		|	&DefaultPackaging";
		
		QueryText = StrReplace(QueryText,
									"&DefaultPackaging",
									"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region GeneratingRecalculationTasks

// Creates tasks for the conversion
//
// Parameters:
//  GenerationParameters_	 - Structure	 -
//
// Returns:
//  Number - the number of tasks created.
//
Function CreateJobs(GenerationParameters_) Export
	
	NumberOfTasksCreated = 0;
	
	If GenerationParameters_.SplitByNumberOfCells And GenerationParameters_.NumberOfCellsInTheTask = 0 Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Số lượng ô hàng trong một nhiệm vụ"".';
				|ru = 'Поле ""Количество ячеек в одном задании"" не заполнено.';
				|en = '""Storage bins per job"" is required.'; fa = '""Storage bins per job"" is required.';
				|it = 'Il campo ""Numero di celle nello stesso task"" non è compilato.';
				|pl = 'Pole ""Liczba komórek w jednym zadaniu"" nie jest wypełnione.';
				|tr = '""Bir görevdeki hücre sayısı"" alanı doldurulmadı.'"),
			,
			"NumberOfCellsInTheTask");
		Return 0;
	EndIf;
	
	RecountFilter = New DataCompositionSettingsComposer;
	DataCompositionSchema = Documents.InventoryRecount.GetTemplate("RecountFilterGroupCreation");
	URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
	RecountFilter.Initialize(SettingsSource);
	RecountFilter.LoadSettings(GenerationParameters_.Filter_Settings);
	
	SetValueOfSettingsParameter(RecountFilter.Settings, "RecountDate", CurrentSessionDate());
	
	ProductSelectionIsUsed_ = GetUseOfSelectionElement(RecountFilter.Settings.Filter.Items, 
																			"NomenclatureSelection");
	EnableSelections(RecountFilter, "FilterByRemainingProducts",   False, 	 ProductSelectionIsUsed_);
	EnableSelections(RecountFilter, "FilterByStorageBinsWithRemainingGoods", 	 False,	 GenerationParameters_.RecountByFilling = "OnlyCellsWithLeftovers");
	EnableSelections(RecountFilter, "FilterByEmptyStorageBins", 		 False,	 GenerationParameters_.RecountByFilling = "OnlyEmptyStorageBins");
	EnableSelections(RecountFilter, "FilterByDoubtfulStorageBins", 	 True, GenerationParameters_.DoubtfulBinRecount);
	EnableSelections(RecountFilter, "FilterByRecountFrequency", True, GenerationParameters_.RecountByFrequencySettings);
	EnableSelections(RecountFilter, "FilterByNegativeInventory",	 True, GenerationParameters_.RecalculationByCellsWithNegativeResiduals);
	EnableSelections(RecountFilter, "ThereIsFilterByAdditionalConditions",	 	 False,	 GenerationParameters_.DoubtfulBinRecount
																				Or GenerationParameters_.RecountByFrequencySettings
																				Or GenerationParameters_.RecalculationByCellsWithNegativeResiduals);
																				
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, 
		RecountFilter.GetSettings()
		,
		,
		,
		Type("DataCompositionValueCollectionTemplateGenerator"));
	
	SetPrivilegedMode(True);	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	CellTable = OutputProcessor.Output(DataCompositionProcessor);
	
	If CellTable.Count() = 0 Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Không có ô hàng phù hợp với điều kiện đã chọn.';
				|ru = 'Отсутствуют ячейки, подходящие по выбранным условиям.';
				|en = 'No bins which satisfy the selected conditions.'; fa = 'No bins which satisfy the selected conditions.';
				|it = 'Non ci sono celle adatte per le condizioni selezionate.';
				|pl = 'Nie ma komórek odpowiednich dla wybranych warunków.';
				|tr = 'Seçilen koşullarla eşleşen hücreler mevcut değil.'"));
		Return 0;
	EndIf;
	
	CellsByWorkingArea = New Array;	
	CurWorkSite = Undefined;
	
	If GenerationParameters_.SplitByWorkArea Then 
		For Each TableRow In CellTable Do
			If CurWorkSite <> Undefined 
				And CurWorkSite <> TableRow.CellSelectionWorkArea Then
				SplitByNumberOfCellsInTask(GenerationParameters_, CellsByWorkingArea, NumberOfTasksCreated);
				CellsByWorkingArea.Clear();
			EndIf;
			CurWorkSite = TableRow.CellSelectionWorkArea;
			CellsByWorkingArea.Add(TableRow.SelectionCell);
		EndDo;
	Else 
		CellsByWorkingArea = CellTable.UnloadColumn("SelectionCell");
	EndIf;
	
	SplitByNumberOfCellsInTask(GenerationParameters_, CellsByWorkingArea, NumberOfTasksCreated);
	
	Return NumberOfTasksCreated;
	
EndFunction

Procedure SplitByNumberOfCellsInTask(GenerationParameters_, ArrayOfCells, NumberOfTasksCreated )
	
	CellsByNumber = New Array;	

	If GenerationParameters_.SplitByNumberOfCells Then 
		For Each Cell In ArrayOfCells Do
			If CellsByNumber.Count() = GenerationParameters_.NumberOfCellsInTheTask Then
				Success = CreateAndRecordRecalculationTask(GenerationParameters_.Warehouse, GenerationParameters_.Premise, CellsByNumber);
				If Success Then
					NumberOfTasksCreated = NumberOfTasksCreated + 1;
				EndIf;
				CellsByNumber.Clear();
			EndIf;
			CellsByNumber.Add(Cell);
		EndDo;
	Else 
		CellsByNumber = ArrayOfCells;
	EndIf;
	
	If CellsByNumber.Count() <> 0 Then
		Success = CreateAndRecordRecalculationTask(GenerationParameters_.Warehouse, GenerationParameters_.Premise, CellsByNumber); 
		If Success Then
			NumberOfTasksCreated = NumberOfTasksCreated + 1;
		EndIf;
	EndIf;
	
EndProcedure

Procedure SetValueOfSettingsParameter(Settings, ParameterName, Value)
	
	Parameter = Settings.DataParameters.Items.Find(ParameterName);
	
	If Parameter <> Undefined Then
		Parameter.Value = Value;
		Parameter.Use = True;
	EndIf;
	
EndProcedure

Function GetUseOfSelectionElement(CollectionOfSelectionElements, FilterElementName)
	
	For Each FilterElement In CollectionOfSelectionElements Do
		If FilterElement.LeftValue = New DataCompositionField(FilterElementName) And FilterElement.Use = True Then 
			Return True;	
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Procedure EnableSelections(SettingsComposer, ParameterName, RequiredParameter_, ParameterValue)
	
	FilterParameter_ = DataCompositionClientServer.GetParameter(
		SettingsComposer.Settings, 
		ParameterName);	
		
	If FilterParameter_ = Undefined Then
		Return;
	EndIf;
	
	FilterParameter_.Value = False;
	FilterParameter_.Use = False;
	
	If TypeOf(SettingsComposer) = Type("DataCompositionNestedObjectSettings") Then
	
		FixedSettings = SettingsComposer.Settings;
	
	Else
	
		FixedSettings = SettingsComposer.FixedSettings;
	
	EndIf;
	
	FilterParameter_  = DataCompositionClientServer.GetParameter(
		FixedSettings, 
		ParameterName);
		
	If RequiredParameter_ Then
		FilterParameter_.Value = ParameterValue;
		FilterParameter_.Use = True;
	Else
		FilterParameter_.Value = True;
		FilterParameter_.Use = ParameterValue;
	EndIf;
	
EndProcedure

Function CreateAndRecordRecalculationTask(Warehouse, Premise, ArrayOfCells)
	
	RecalculationCells = GetCellsIncludedInRecalculations(ArrayOfCells);
	DocumentCells = CommonClientServer.ArraysDifference(ArrayOfCells, RecalculationCells);
	
	For Each Cell In RecalculationCells Do
		MessageText = NStr("vi = 'Có các nhiệm vụ nổi bật để kể lại ô %Cell%';
							|ru = 'Есть невыполненные задания на пересчет ячейки %Cell%';
							|en = 'There are incomplete jobs for recalculating the %Cell% bin'; fa = 'There are incomplete jobs for recalculating the %Cell% bin';
							|it = 'Ci sono task in sospeso per il ricalcolo della cella %Cell%';
							|pl = 'Istnieją niewykonane zadania do ponownego obliczenia komórki %Cell%';
							|tr = '%Cell%hücresinin yeniden hesaplaması için yerine getirilmemiş görevler mevcut'");
		MessageText = StrReplace(MessageText, "%Cell%", Cell);
		
		CommonClientServer.MessageToUser(MessageText);
	EndDo;
	
	If DocumentCells.Count() = 0 Then
		Return False;
	EndIf;
	
	DocumentObject = Documents.InventoryRecount.CreateDocument();
	
	FillingData = New Structure;
	FillingData.Insert("Warehouse", Warehouse);
	FillingData.Insert("Premise", Premise);
	
	DocumentObject.Fill(FillingData);
	
	For Each Cell In DocumentCells Do
		LineProducts_ = DocumentObject.Goods.Add();
		LineProducts_.Cell = Cell;
	EndDo;
	
	Try
		DocumentObject.Write(DocumentWriteMode.Posting);
	Except
		CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function GetCellsIncludedInRecalculations(CheckedCells_)
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ConversionProducts_.Ref AS Ref,
	|	ConversionProducts_.Cell AS Cell
	|INTO ConversionProducts_
	|FROM
	|	Document.InventoryRecount.Goods AS ConversionProducts_
	|WHERE
	|	ConversionProducts_.Cell IN(&CheckedCells_)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ConversionProducts_.Cell AS Cell
	|FROM
	|	ConversionProducts_ AS ConversionProducts_
	|		INNER JOIN Document.InventoryRecount AS InventoryRecounts
	|		ON ConversionProducts_.Ref = InventoryRecounts.Ref
	|WHERE
	|	InventoryRecounts.Posted
	|	AND NOT (InventoryRecounts.Status = VALUE(Enum.InventoryRecountStatuses.Completed2))
	|
	|ORDER BY
	|	Cell";
	
	Query.SetParameter("CheckedCells_", CheckedCells_);
	CellsIncludedInRecalculations = Query.Execute().Unload().UnloadColumn("Cell");
	
	Return CellsIncludedInRecalculations;
	
EndFunction

Function QueryTextTableCargoItemsForRecordingSurplusesAndShortages(Query, QueryTexts, Registers)
	
	RegisterName = "CargoItemsForRecordingSurplusesAndShortages";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsPlacesBalances", QueryTexts) Then
		QueryTextTTProductLocationsBalance(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCommodityPlacesToReflectSurplusShortages", QueryTexts) Then
		WarehousesServer.QueryTextTTCargoItemsForRecordingSurplusesAndShortages(QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	NestedQuery.Series AS Series,
	|	NestedQuery.Package AS CargoItem,
	|	SUM(NestedQuery.Count) AS Count
	|FROM
	|	(SELECT
	|		DiscrepanciesInProductLocations.Products AS Products,
	|		DiscrepanciesInProductLocations.Characteristic AS Characteristic,
	|		DiscrepanciesInProductLocations.Purpose AS Purpose,
	|		DiscrepanciesInProductLocations.Series AS Series,
	|		DiscrepanciesInProductLocations.CargoItem AS Package,
	|		DiscrepanciesInProductLocations.CountBalance AS Count
	|	FROM
	|		TTGoodsPlacesBalances AS DiscrepanciesInProductLocations
	|	WHERE
	|		&Status = VALUE(Enum.InventoryRecountStatuses.Completed2)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTCommodityPlacesToReflectSurplusShortages.Products,
	|		TTCommodityPlacesToReflectSurplusShortages.Characteristic,
	|		TTCommodityPlacesToReflectSurplusShortages.Purpose,
	|		TTCommodityPlacesToReflectSurplusShortages.Series,
	|		TTCommodityPlacesToReflectSurplusShortages.Package,
	|		CASE
	|			WHEN TTCommodityPlacesToReflectSurplusShortages.OperationKind = VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|				THEN -TTCommodityPlacesToReflectSurplusShortages.NumberOfPackages
	|			ELSE TTCommodityPlacesToReflectSurplusShortages.NumberOfPackages
	|		END
	|	FROM
	|		TTCommodityPlacesToReflectSurplusShortages AS TTCommodityPlacesToReflectSurplusShortages
	|	WHERE
	|		&Status = VALUE(Enum.InventoryRecountStatuses.Completed2)) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series,
	|	NestedQuery.Package
	|
	|HAVING
	|	SUM(NestedQuery.Count) <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTProductLocationsBalance(Query, QueryTexts)
	
	RegisterName = "TTGoodsPlacesBalances";
	QueryText = 
	"SELECT
	|	&Warehouse AS Warehouse,
	|	&Premise AS Premise,
	|	RecalculationOfGoods.Products AS Products,
	|	RecalculationOfGoods.Characteristic AS Characteristic,
	|	RecalculationOfGoods.Purpose AS Purpose,
	|	RecalculationOfGoods.ControlledLotReference AS ControlledLotReference,
	|	CASE
	|		WHEN RecalculationOfGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN RecalculationOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	RecalculationOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	RecalculationOfGoods.Package AS CargoItem,
	|	SUM(RecalculationOfGoods.NumberOfPackagesReal - RecalculationOfGoods.NumberOfPackages) AS CountBalance
	|INTO TTGoodsPlacesBalances
	|FROM
	|	Document.InventoryRecount.Goods AS RecalculationOfGoods
	|WHERE
	|	RecalculationOfGoods.Ref = &Ref
	|	AND RecalculationOfGoods.NumberOfPackagesReal - RecalculationOfGoods.NumberOfPackages <> 0
	|	AND ISNULL(RecalculationOfGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	RecalculationOfGoods.Package,
	|	RecalculationOfGoods.Products,
	|	RecalculationOfGoods.Characteristic,
	|	RecalculationOfGoods.Purpose,
	|	RecalculationOfGoods.ControlledLotReference,
	|	CASE
	|		WHEN RecalculationOfGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN RecalculationOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	RecalculationOfGoods.BatchesIndicationStatus
	|
	|HAVING
	|	SUM(RecalculationOfGoods.NumberOfPackagesReal - RecalculationOfGoods.NumberOfPackages) <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsPlacesBalances", QueryTexts) Then
		QueryTextTTProductLocationsBalance(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages", QueryTexts) Then
		WarehousesServer.QueryTextTTSetsOnCommodityRequirementsForReflectionOfSurplusShortages(QueryTexts);
	EndIf;
	
	RegisterName = "TTProducts_1";
			
	QueryText = 
	"SELECT DISTINCT
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Products AS Products,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Characteristic AS Characteristic,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Purpose AS Purpose,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.ControlledLotReference AS ControlledLotReference,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Series AS Series,
	|	RecalculationOfGoods.BatchesIndicationStatus = 14 AS ThisIsSeriesAtCostPrice,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.OperationKind AS OperationKind,
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.KitCount AS Count
	|INTO TTProducts_1
	|FROM
	|	TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages AS TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages
	|		INNER JOIN Document.InventoryRecount.Goods AS RecalculationOfGoods
	|		ON TTSetsOnCommodityRequirementsForReflectionOfSurplusShortages.Products = RecalculationOfGoods.Products
	|WHERE
	|	RecalculationOfGoods.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	RecalculationOfGoods.Products,
	|	RecalculationOfGoods.Characteristic,
	|	RecalculationOfGoods.Purpose,
	|	RecalculationOfGoods.ControlledLotReference,
	|	CASE
	|		WHEN RecalculationOfGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN RecalculationOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	RecalculationOfGoods.BatchesIndicationStatus = 14,
	|	CASE
	|		WHEN RecalculationOfGoods.CountReal - RecalculationOfGoods.Count > 0
	|			THEN VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|		ELSE VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|	END,
	|	SUM(CASE
	|			WHEN RecalculationOfGoods.CountReal - RecalculationOfGoods.Count > 0
	|				THEN RecalculationOfGoods.CountReal - RecalculationOfGoods.Count
	|			ELSE -(RecalculationOfGoods.CountReal - RecalculationOfGoods.Count)
	|		END)
	|FROM
	|	Document.InventoryRecount.Goods AS RecalculationOfGoods
	|WHERE
	|	RecalculationOfGoods.Ref = &Ref
	|	AND RecalculationOfGoods.CountReal - RecalculationOfGoods.Count <> 0
	|	AND ISNULL(RecalculationOfGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	RecalculationOfGoods.Characteristic,
	|	RecalculationOfGoods.Products,
	|	CASE
	|		WHEN RecalculationOfGoods.CountReal - RecalculationOfGoods.Count > 0
	|			THEN VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordSurplus)
	|		ELSE VALUE(Enum.OperationKindsOfStockBalanceAdjustingEntries.RecordShortage)
	|	END,
	|	CASE
	|		WHEN RecalculationOfGoods.BatchesIndicationStatus IN (4, 6, 8, 10, 14)
	|			THEN RecalculationOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	RecalculationOfGoods.BatchesIndicationStatus = 14,
	|	RecalculationOfGoods.Purpose,
	|	RecalculationOfGoods.ControlledLotReference
	|
	|HAVING
	|	SUM(CASE
	|			WHEN RecalculationOfGoods.CountReal - RecalculationOfGoods.Count > 0
	|				THEN RecalculationOfGoods.CountReal - RecalculationOfGoods.Count
	|			ELSE -(RecalculationOfGoods.CountReal - RecalculationOfGoods.Count)
	|		END) > 0";
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf