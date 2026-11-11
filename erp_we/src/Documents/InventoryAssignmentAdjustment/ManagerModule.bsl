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
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	InventoryAssignmentAdjustmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryAssignmentAdjustment") Then
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
		
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableProductStock(Query, QueryTexts, Registers);
		QueryTextTableGoodsInStorageBins(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		InventoryAssignmentAdjustmentLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
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
	
	InventoryAssignmentAdjustmentLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document called "product assignment Adjustment".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryAssignmentAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryAssignmentAdjustment);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseOrderSupplyWithAssignment";
		
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
	
	InventoryAssignmentAdjustmentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Date";
	
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
	
	SeriesSpecificationParameters.FullObjectName = "Document.InventoryAssignmentAdjustment";
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse");
	SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse");
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("InitialAssignment");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("NewAssignment");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	
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
	|	CAST(Goods.InitialAssignment AS Catalog.Assignments) AS InitialAssignment,
	|	CAST(Goods.NewAssignment AS Catalog.Assignments) AS NewAssignment,
	|	Goods.Warehouse,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO ProductsToRequest
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	CASE
	|		WHEN ISNULL(Goods.InitialAssignment.RecordsInWarehouseRegisters, FALSE)
	|				OR ISNULL(Goods.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|			THEN TRUE
	// Calling from filling out the correct assignment for the order to the processor by stages
	|		WHEN Goods.InitialAssignment = VALUE(Catalog.Assignments.EmptyRef)
	|				AND Goods.NewAssignment = VALUE(Catalog.Assignments.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreWarehouseRegisteredRecords,
	|	Goods.Warehouse,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	ProductsToRequest AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN Goods.ThereAreWarehouseRegisteredRecords
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|											THEN CASE
	|													WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|														THEN 13
	|													ELSE 14
	|												END
	|										ELSE CASE
	|												WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|													THEN 9
	|												ELSE 10
	|											END
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|								THEN CASE
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 7
	|										ELSE 8
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|									AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|								THEN CASE
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 3
	|										ELSE 4
	|									END
	|							ELSE 0
	|						END
	|				ELSE CASE
	|						WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|							THEN CASE
	|									WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 13
	|									ELSE 14
	|								END
	|						ELSE 0
	|					END
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|			AND (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	StatusTable AS StatusTable
	|WHERE
	|	StatusTable.OldStatusOfSpecifyingSeries <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

// Returns the query text that determines whether warehouse moves are used in the transferred warehouse,
// and whether address storage is used in the transferred move.
//
// Parameters:
//  TempTableName - String - Name of the temporary table to put the result in. If you do not specify this parameter,
//                                 the temporary table will not be created.
//
// Returns:
//  String - Query text
//
Function RequestTextUseOfPremisesAndAddressStorage(TempTableName = "") Export
	
	QueryText = 
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	CASE
	|		WHEN CAST(TableOfGoods.Warehouse AS Catalog.Warehouses).UseWarerooms
	|				AND &Period >= CAST(TableOfGoods.Warehouse AS Catalog.Warehouses).StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN CAST(TableOfGoods.Premise AS Catalog.Warerooms).UseBinLocationWarehousing
	|							AND &Period >= CAST(TableOfGoods.Premise AS Catalog.Warerooms).StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN CAST(TableOfGoods.Warehouse AS Catalog.Warehouses).UseBinLocationWarehousing
	|						AND &Period >= CAST(TableOfGoods.Warehouse AS Catalog.Warehouses).StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS UseBinLocationWarehousing,
	|	CASE
	|		WHEN CAST(TableOfGoods.Warehouse AS Catalog.Warehouses).UseWarerooms
	|				AND &Period >= CAST(TableOfGoods.Warehouse AS Catalog.Warehouses).StartDateOfWareroomUse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarerooms
	|INTO TempTableNameOverridable
	|FROM
	|	TableOfGoods AS TableOfGoods";
	
	If Not IsBlankString(TempTableName) Then
		QueryText = StrReplace(QueryText, "TempTableNameOverridable", TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO TempTableNameOverridable", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns an array of available actions with the document correctionsadjustments of Goods
//
// Parameters:
//  Purpose		 - CatalogRef.Assignments	 - the assignment chosen in the correction 
//                      only makes sense for the algorithm as a giveaway.
// Returns:
//  Array of EnumRef.KindsOfAssignmentAdjustmentOperations - array of available of operations.
//
Function AvailableAction(Purpose = Undefined) Export
	
	PartialRights = False;
	
	If Not Users.RolesAvailable("AdditionalOperationsOfInventoryAssignmentAdjustment") Then
		PartialRights = True;
	EndIf;
	
	ThisIsGiverMaterial = False;
	If ValueIsFilled(Purpose) Then
		
		AssignmentType = Common.ObjectAttributeValue(Purpose, "AssignmentType");
		
		If AssignmentType = Enums.AssignmentTypes.ProvidedMaterialsForStage22
			Or False Then
			ThisIsGiverMaterial = True;
		EndIf;
		
	EndIf;
	
	Array = New Array();
	If Not ThisIsGiverMaterial Then
		Array.Add(Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_);
	EndIf;
	
	If Not PartialRights Then
		Array.Add(Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment);
	EndIf;
	
	Array.Add(Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve);
	
	If Not PartialRights Then
		Array.Add(Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments);
	EndIf;
	
	If Not PartialRights Then
		Array.Add(Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment);
	EndIf;
	
	Return Array;
	
EndFunction

// Searches for a destination that matches the order
//
// Parameters:
//  OrderDocument - AnyRef - Link to the order to determine the purpose of.
//
// Returns:
//  CatalogRef.Assignments - the destination associated with the order.
//
Function OrderAssignment(OrderDocument) Export
	
	If Not ValueIsFilled(OrderDocument) Then
		Return Catalogs.Assignments.EmptyRef();
	EndIf;
	
	PathToTheDestinationField = "Purpose";
	
	Purpose = Common.ObjectAttributeValue(OrderDocument, PathToTheDestinationField);
	
	If TypeOf(OrderDocument) = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
		// Exceptions.
		Purpose = Documents.ByAssemblyDisassemblyOrder.OrderAssignment(OrderDocument);
	Else
		Purpose = Common.ObjectAttributeValue(OrderDocument, PathToTheDestinationField);
	EndIf;
	
	If ValueIsFilled(Purpose) Then
		DestinationOrder = Common.ObjectAttributeValue(Purpose, "OrderDocument");
		If ValueIsFilled(DestinationOrder) And DestinationOrder = OrderDocument Then
			Return Purpose;
		Else
			Return Catalogs.Assignments.EmptyRef();
		EndIf;
	Else
		Return Catalogs.Assignments.EmptyRef();
	EndIf;
	
EndFunction

// Checks whether the current user has access to change the document
//
// Parameters:
//  Ref - DocumentRef.InventoryAssignmentAdjustment -
//
// Returns:
//  Boolean -
//
Function ChangeOptionAvailable(Ref) Export
	
	ThereIsAccess = True;
	DocumentOperationKind = Common.ObjectAttributeValue(Ref, "OperationKind");
	
	If Not AccessRight("Update", Metadata.Documents.InventoryAssignmentAdjustment) Then
		ThereIsAccess = False;
	ElsIf Not Users.RolesAvailable("AdditionalOperationsOfInventoryAssignmentAdjustment") Then
		// Partial rights
		DocumentOperationKind = Common.ObjectAttributeValue(Ref, "OperationKind");
		If DocumentOperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments
			Or DocumentOperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment Then
			ThereIsAccess = False;
		EndIf;
	EndIf;
	
	Return ThereIsAccess;
	
EndFunction
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return InventoryAssignmentAdjustmentLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return InventoryAssignmentAdjustmentLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.Contract = "&Contract";
	DestinationPattern.TermsOfUse_ = "Object.OperationKind = VALUE(Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve)";
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.Contract = "&Contract";
	DestinationPattern.TermsOfUse_ = "Object.OperationKind = VALUE(Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment)";
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.TermsOfUse_ = "Object.OperationKind IN(
		|VALUE(Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments),
		|VALUE(Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_),
		|VALUE(Enum.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment),
		|VALUE(Enum.KindsOfAssignmentAdjustmentOperations.MutualAdjustment),
		|VALUE(Enum.KindsOfAssignmentAdjustmentOperations.EmptyRef))";
	
	// The remnants of the goods being written off in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.InitialAssignment", "InStock");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ExcludedAssignments = "Object.Purpose";
	
	// The needs for registered goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.NewAssignment", "Demand");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ExcludedAssignments = "Object.Purpose";
	
	Return FormTemplate;
	
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
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
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

// Adds a command to create a document "Adjusting the destination of goods "based on the"customer Order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   Undefined
//   GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddCreateCommandBasedOnCustomerOrder(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventoryAssignmentAdjustment) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryAssignmentAdjustment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryAssignmentAdjustment);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseOrderSupplyWithAssignment";
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateAdjustmentForPurposeOfGoodsBasedOnCustomerSOrder";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
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

#Region Internal

Procedure FillInAssignmentByTypeOfOperation(Purpose, OrderDocument, OperationKind, TableRow, ThisIsPurposeOfCap) Export
	
	If ThisIsPurposeOfCap Then
		
		If OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_") Then
			TableRow.NewAssignment = Purpose;
			TableRow.NewOrder = OrderDocument;
		ElsIf OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment") Then
			TableRow.NewAssignment = Purpose;
			TableRow.NewOrder = OrderDocument;
		ElsIf OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve") Then
			TableRow.InitialAssignment = Purpose;
			TableRow.SourceOrder = OrderDocument;
		EndIf;
		
	Else
		
		If OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment") Then
			TableRow.InitialAssignment = Purpose;
		ElsIf OperationKind = PredefinedValue("Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments") Then
			TableRow.InitialAssignment = Purpose;
		EndIf;
		TableRow.SourceOrder = Common.ObjectAttributeValue(Purpose, "OrderDocument");
		
	EndIf;
	
EndProcedure

#Region FillingByBalances

// Returns a table to fill in the assignment adjustment.
// Parameters:
//  Purpose - CatalogRef.Assignments -
//  Goods - ValueTable
//  Recorder - DocumentRef.InventoryAssignmentAdjustment, Undefined -
// Returns:
//  Structure:
//   *TableOfGoods - ValueTable -
//   *TableOfResults - ValueTable -
Function ReserveWithdrawalTable(Purpose, Goods, Recorder) Export
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Purpose",      Purpose);
	Query.SetParameter("Goods",          Goods);
	Query.SetParameter("AllGoods",       Goods.Count() = 0);
	Query.SetParameter("Recorder",     Recorder);
	Query.SetParameter("CollapseAssignments", False);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|INTO PermittedWarehouses
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|INDEX BY
		|	Warehouse";
	Query.Execute();
	
	SetPrivilegedMode(True);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	&FieldDestinationSelectionOfProducts AS Purpose
		|INTO FilterOfProducts_
		|FROM
		|	&Goods AS Table
		|INDEX BY
		|	Products, Characteristic
		|;
		|///////////////////////////////////
		|
		|SELECT
		|	&Purpose AS Purpose
		|INTO SelectionOfAppointments_";
	FieldDestinationSelectionOfProducts = "VALUE(Catalog.Assignments.EmptyRef)";
	If Goods.Columns.Find("Purpose") <> Undefined Then
		FieldDestinationSelectionOfProducts = "Table.Purpose";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FieldDestinationSelectionOfProducts", FieldDestinationSelectionOfProducts);
	
	Query.Execute();
	Query.Text = QueryTextDataSource(False);
	Query.Execute();
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO SelectingDataSourceProducts
		|FROM
		|	DataSource AS Table
		|INDEX BY
		|	Products, Characteristic";
	Query.Execute();
	
	PurposeText = "VALUE(Catalog.Assignments.EmptyRef)"; // @query-part-1
	Query.Text = QueryTextAvailableStock(True, PurposeText, "AvailableStock"); 
	Query.Execute();
	
	AddTemporaryTableSortingWarehouses(Query, "DataSource", "DataSource");
	
	Query.Text =
		"SELECT
		|	VALUE(Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve) AS OperationKind,
		|	&Purpose                                                            AS AssignmentForTotals,
		|	Table.Products                                                   AS Products,
		|	Table.Products.UnitOfMeasure                                  AS UnitOfMeasure,
		|	Table.Characteristic                                                 AS Characteristic,
		|	Table.Warehouse                                                          AS Warehouse,
		|	Table.Purpose                                                     AS InitialAssignment,
		|	Table.Purpose.OrderDocument                                               AS SourceOrder,
		|	VALUE(Catalog.Assignments.EmptyRef)                           AS NewAssignment,
		|	UNDEFINED                                                           AS NewOrder,
		|	Table.Demand                                                    AS Demand,
		|	Table.Inventory                                                          AS Inventory,
		|	Table.Reserve                                                         AS Reserve,
		|	Table.UnderControl                                                     AS UnderControl,
		|	ISNULL(AvailableStock.AvailableForInventoryAllocation, 0)                                 AS AvailableForInventoryAllocation,
		|	ISNULL(WarehouseSortingTable.WarehousePriority, 0)                  AS SortingWarehouse,
		|	NOT ShippingWarehousesTable.Warehouse IS NULL                              AS ThisIsShippingWarehouse
		|FROM
		|	DataSource AS Table
		|		
		|		LEFT JOIN AvailableStock AS AvailableStock
		|		ON AvailableStock.Warehouse          = Table.Warehouse
		|		 AND AvailableStock.Products   = Table.Products
		|		 AND AvailableStock.Characteristic = Table.Characteristic
		|		 AND AvailableStock.AvailableForInventoryAllocation > 0
		|		
		|		LEFT JOIN SortingWarehouses AS WarehouseSortingTable
		|		ON WarehouseSortingTable.Warehouse          = Table.Warehouse
		|		 AND WarehouseSortingTable.Purpose     = Table.Purpose
		|		 AND WarehouseSortingTable.Products   = Table.Products
		|		 AND WarehouseSortingTable.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN ShippingWarehouses AS ShippingWarehousesTable
		|		ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|		 AND ShippingWarehousesTable.Products   = Table.Products
		|		 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		 AND ShippingWarehousesTable.Purpose     = Table.Purpose
		|		
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = Table.Warehouse
		|WHERE
		|	Table.Inventory > 0
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	ThisIsShippingWarehouse,
		|	SortingWarehouse,
		|	Inventory DESC";
	
	TableOfGoods = Query.Execute().Unload();
	
	Var_Key = "InitialAssignment,Products,Characteristic,Warehouse";
	TableAdjusted = TableOfGoods.Copy(New Array(), Var_Key);
	TableAdjusted.Columns.Add("Count",
		Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative));
	
	Rows = TableOfGoods.Copy(, Var_Key);
	CompanyGoods = GiveawayProductsOfSelectionOrganizations(Rows, Recorder);
	CompanyGoods.Indexes.Add(Var_Key);
	AdjustAssignmentOfGivingMaterialsToAppointmentOfGiverAsWhole(
		TableOfGoods,
		CompanyGoods,
		TableAdjusted);
	
	Query.SetParameter("TableAdjusted", TableAdjusted);
	
	Texts = New Array();
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Count AS Count
		|INTO TableAdjusted
		|FROM
		|	&TableAdjusted AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|
		|//////////////////////////////////////////////////////////
		|SELECT
		|	&Purpose AS AssignmentForTotals,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	CASE
		|		WHEN Table.Inventory - ISNULL(TableAdjusted.Count, 0) > 0
		|			THEN Table.Inventory - ISNULL(TableAdjusted.Count, 0)
		|		ELSE 0
		|	END AS InStock,
		|	CASE
		|		WHEN Table.Supplied - ISNULL(TableAdjusted.Count, 0) > 0
		|			THEN Table.Supplied - ISNULL(TableAdjusted.Count, 0)
		|		ELSE 0
		|	END AS Supplied,
		|	CASE
		|		WHEN Table.Demand - ISNULL(TableAdjusted.Count, 0) > 0
		|			THEN Table.Demand - ISNULL(TableAdjusted.Count, 0)
		|		ELSE 0
		|	END AS Demand,
		|	NOT ShippingWarehousesTable.Warehouse IS NULL AS ThisIsShippingWarehouse
		|INTO TableOfResults
		|FROM
		|	DataSource AS Table
		|		
		|		LEFT JOIN TableAdjusted AS TableAdjusted
		|		ON TableAdjusted.Products = Table.Products
		|		 AND TableAdjusted.Characteristic = Table.Characteristic
		|		 AND TableAdjusted.Warehouse = Table.Warehouse
		|		
		|		LEFT JOIN ShippingWarehouses AS ShippingWarehousesTable
		|		ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|		 AND ShippingWarehousesTable.Products   = Table.Products
		|		 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		 AND ShippingWarehousesTable.Purpose     = Table.Purpose
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	Texts.Add(Text);
	
	Text = TemporaryTableMoveOrders(False);
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	&Purpose AS AssignmentForTotals,
		|	TableOfResults.Products AS Products,
		|	TableOfResults.Characteristic AS Characteristic,
		|	SUM(TableOfResults.InStock) AS InStock,
		|	SUM(TableOfResults.Supplied) - MAX(ISNULL(TransferOrders.Count, 0)) AS Supplied,
		|	SUM(TableOfResults.Demand) - MAX(ISNULL(TransferOrders.Count, 0)) AS Demand
		|FROM
		|	TableOfResults AS TableOfResults
		|		
		|		LEFT JOIN TransferOrders AS TransferOrders
		|		ON TransferOrders.Products = TableOfResults.Products
		|		 AND TransferOrders.Characteristic = TableOfResults.Characteristic
		|GROUP BY
		|	TableOfResults.Products,
		|	TableOfResults.Characteristic";
		
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	ReturnStructure = New Structure();
	ReturnStructure.Insert("TableOfGoods", TableOfGoods);
	ReturnStructure.Insert("SummaryTotalsTable", Query.Execute().Unload());
	ReturnStructure.Insert("TableOfResults", Query.TempTablesManager.Tables["TableOfResults"].GetData().Unload());
	
	Return ReturnStructure;
	
EndFunction

// Returns a table to fill in the assignment adjustment.
// Parameters:
//  Organization - Reference link.StructureEnterprises -
//  Products - Assignment Tables
//  The registrar is a document link.Adjustments to the assignment of goods, Indefinite -
// Returns:
//  Structure -
//   *Tables of Goods - Tables of values -
//   *Tables of Totals - Tables of values -

Function TableOfWithdrawalOfReserveForManyPurposes(Organization, Goods, Recorder, Assignments) Export

	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Organization",     Organization);
	Query.SetParameter("AllCompanies",  Organization = Undefined);
	Query.SetParameter("Goods",          Goods);
	Query.SetParameter("AllGoods",       Goods.Count() = 0);
	Query.SetParameter("Recorder",     Recorder);
	Query.SetParameter("Assignments",      Assignments);
	Query.SetParameter("ThereIsSelectionOfAppointments", Assignments.Count() > 0);
	Query.SetParameter("CollapseAssignments", False);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|INTO PermittedWarehouses
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|INDEX BY
		|	Warehouse";
	Query.Execute();
	
	SetPrivilegedMode(True);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	&FieldDestinationSelectionOfProducts AS Purpose
		|INTO FilterOfProducts_
		|FROM
		|	&Goods AS Table
		|INDEX BY
		|	Products, Characteristic";
	DestinationsAreInProducts = Goods.Columns.Find("Purpose") <> Undefined;
	FieldDestinationSelectionOfProducts = "VALUE(Catalog.Assignments.EmptyRef)";
	If DestinationsAreInProducts Then
		FieldDestinationSelectionOfProducts = "Table.Purpose";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FieldDestinationSelectionOfProducts", FieldDestinationSelectionOfProducts);
	Query.Execute();
	
	Query.Text =
		"SELECT ALLOWED
		|	Table.Purpose AS Purpose
		|INTO AssignmentsFromBalances
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND (NOT &ThereIsSelectionOfAppointments OR Purpose IN(&Assignments))) AS Table
		|INDEX BY
		|	Purpose
		|;
		|SELECT ALLOWED
		|	Table.Purpose AS Purpose
		|INTO SelectionOfAppointments_
		|FROM
		|	AssignmentsFromBalances AS Table
		|WHERE
		|	(&AllCompanies OR Table.Purpose.OrderDocument.Organization = &Organization)
		|		AND NOT Table.Purpose.AssignmentType IN(
		|			VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
		|INDEX BY
		|	Purpose
		|;
		|DROP AssignmentsFromBalances";
	Query.Execute();
	
	Query.Text = QueryTextDataSource(DestinationsAreInProducts);
	Query.Execute();
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO SelectingDataSourceProducts
		|FROM
		|	DataSource AS Table
		|INDEX BY
		|	Products, Characteristic";
	Query.Execute();
	
	PurposeText = "VALUE(Catalog.Assignments.EmptyRef)"; // @query-part-1
	Query.Text = QueryTextAvailableStock(True, PurposeText, "AvailableStock"); 
	Query.Execute();
	
	AddTemporaryTableSortingWarehouses(Query, "DataSource", "DataSource");
	
	Query.Text =
		"SELECT
		|	VALUE(Enum.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve) AS OperationKind,
		|	Table.Purpose                                                     AS AssignmentForTotals,
		|	Table.Products                                                   AS Products,
		|	Table.Products.UnitOfMeasure                                  AS UnitOfMeasure,
		|	Table.Characteristic                                                 AS Characteristic,
		|	Table.Warehouse                                                          AS Warehouse,
		|	Table.Purpose                                                     AS InitialAssignment,
		|	Table.Purpose.OrderDocument                                               AS SourceOrder,
		|	VALUE(Catalog.Assignments.EmptyRef)                           AS NewAssignment,
		|	UNDEFINED                                                           AS NewOrder,
		|	ISNULL(AvailableStock.AvailableForInventoryAllocation, 0)                                 AS AvailableForInventoryAllocation,
		|	Table.Demand                                                    AS Demand,
		|	Table.Inventory                                                          AS Inventory,
		|	Table.Reserve                                                         AS Reserve,
		|	Table.UnderControl                                                     AS UnderControl,
		|	ISNULL(WarehouseSortingTable.WarehousePriority, 0)                  AS SortingWarehouse,
		|	NOT ShippingWarehousesTable.Warehouse IS NULL                              AS ThisIsShippingWarehouse
		|FROM
		|	DataSource AS Table
		|		
		|		LEFT JOIN AvailableStock AS AvailableStock
		|		ON AvailableStock.Warehouse          = Table.Warehouse
		|		 AND AvailableStock.Products   = Table.Products
		|		 AND AvailableStock.Characteristic = Table.Characteristic
		|		 AND AvailableStock.AvailableForInventoryAllocation > 0
		|		
		|		LEFT JOIN SortingWarehouses AS WarehouseSortingTable
		|		ON WarehouseSortingTable.Warehouse          = Table.Warehouse
		|		 AND WarehouseSortingTable.Purpose     = Table.Purpose
		|		 AND WarehouseSortingTable.Products   = Table.Products
		|		 AND WarehouseSortingTable.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN ShippingWarehouses AS ShippingWarehousesTable
		|		ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|		 AND ShippingWarehousesTable.Products   = Table.Products
		|		 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		 AND ShippingWarehousesTable.Purpose     = Table.Purpose
		|		
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = Table.Warehouse
		|WHERE
		|	Table.Inventory > 0
		|ORDER BY
		|	InitialAssignment,
		|	Products,
		|	Characteristic,
		|	ThisIsShippingWarehouse,
		|	SortingWarehouse,
		|	Inventory DESC";
	
	TableOfGoods = Query.Execute().Unload();
	
	Var_Key = "InitialAssignment,Products,Characteristic,Warehouse";
	Rows = TableOfGoods.Copy(, Var_Key);
	CompanyGoods = GiveawayProductsOfSelectionOrganizations(Rows, Recorder);
	CompanyGoods.Indexes.Add(Var_Key);
	ReduceAppointmentOfTollingMaterialsWhenWithdrawingReserve(TableOfGoods, CompanyGoods);
	
	Texts = New Array();
	Text =
		"SELECT
		|	Table.Purpose                        AS AssignmentForTotals,
		|	Table.Products                      AS Products,
		|	Table.Characteristic                    AS Characteristic,
		|	Table.Warehouse                             AS Warehouse,
		|	Table.Inventory                             AS InStock,
		|	Table.Supplied                        AS Supplied,
		|	Table.Demand                       AS Demand,
		|	NOT ShippingWarehousesTable.Warehouse IS NULL AS ThisIsShippingWarehouse
		|INTO TableOfResults
		|FROM
		|	DataSource AS Table
		|		
		|		LEFT JOIN ShippingWarehouses AS ShippingWarehousesTable
		|		ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|		 AND ShippingWarehousesTable.Products   = Table.Products
		|		 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		 AND ShippingWarehousesTable.Purpose     = Table.Purpose
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	Texts.Add(Text);
	
	Text = TemporaryTableMoveOrders(True);
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	TableOfResults.AssignmentForTotals AS AssignmentForTotals,
		|	TableOfResults.Products AS Products,
		|	TableOfResults.Characteristic AS Characteristic,
		|	SUM(TableOfResults.InStock) AS InStock,
		|	SUM(TableOfResults.Supplied) - MAX(ISNULL(TransferOrders.Count, 0)) AS Supplied,
		|	SUM(TableOfResults.Demand) - MAX(ISNULL(TransferOrders.Count, 0)) AS Demand
		|FROM
		|	TableOfResults AS TableOfResults
		|		
		|		LEFT JOIN TransferOrders AS TransferOrders
		|		ON TransferOrders.Products = TableOfResults.Products
		|		 AND TransferOrders.Characteristic = TableOfResults.Characteristic
		|		 AND TransferOrders.Purpose = TableOfResults.AssignmentForTotals
		|GROUP BY
		|	TableOfResults.Products,
		|	TableOfResults.Characteristic,
		|	TableOfResults.AssignmentForTotals";
		
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	ReturnStructure = New Structure();
	ReturnStructure.Insert("TableOfGoods", TableOfGoods);
	ReturnStructure.Insert("SummaryTotalsTable", Query.Execute().Unload());
	ReturnStructure.Insert("TableOfResults", Query.TempTablesManager.Tables["TableOfResults"].GetData().Unload());
	
	Return ReturnStructure;
	
EndFunction

// Returns a table to fill in the assignment adjustment.
// Parameters:
//  The purpose is a reference link.Destinations -
//  Sources - Structure -
//  Only Load - 
//  Organization - Reference link.StructureEnterprises - 
//  Products - Assignment Tables
//  The registrar is a document link.Adjustments to the assignment of goods, Indefinite -
// Returns:
//  Structure -
//   *Tables of Goods - Tables of values -
//   *Tables of Totals - Tables of values -

Function ReservationTable(Purpose, Sources, ShippingWarehouseOnly, Organization, Goods, Recorder) Export
	
	MultipleAppointments = TypeOf(Purpose) = Type("Array");
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Purpose",           Purpose);
	Query.SetParameter("Organization",          Organization);
	Query.SetParameter("AllCompanies",       Organization = Undefined);
	Query.SetParameter("Goods",               Goods);
	Query.SetParameter("AllGoods",            Goods.Count() = 0);
	Query.SetParameter("Recorder",          Recorder);
	Query.SetParameter("ProvisionsForAppointments", Sources.ProvisionsForAppointments);
	Query.SetParameter("ShippingWarehouseOnly",  ShippingWarehouseOnly);
	Query.SetParameter("CollapseAssignments",   MultipleAppointments);
	Query.SetParameter("EmptyLinkKey",      New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|INTO PermittedWarehouses
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|INDEX BY
		|	Warehouse";
	Query.Execute();
	
	SetPrivilegedMode(True);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	&FieldDestinationSelectionOfProducts AS Purpose
		|INTO FilterOfProducts_
		|FROM
		|	&Goods AS Table
		|INDEX BY
		|	Products, Characteristic
		|;
		|///////////////////////////////////
		|
		|SELECT
		|	Assignments.Ref AS Purpose
		|INTO SelectionOfAppointments_
		|FROM
		|	Catalog.Assignments AS Assignments
		|WHERE
		|	Assignments.Ref IN (&Purpose)
		|;
		|///////////////////////////////////
		|
		|SELECT TOP 1
		|	Assignments.Purpose.AssignmentType AS AssignmentType,
		|	CASE
		|		WHEN TRUE
		|			THEN Assignments.Purpose.Partner
		|	END AS Partner,
		|	CASE
		|		WHEN TRUE
		|			THEN Assignments.Purpose.Contract
		|	END AS Contract
		|FROM
		|	SelectionOfAppointments_ AS Assignments";
	FieldDestinationSelectionOfProducts = "VALUE(Catalog.Assignments.EmptyRef)";
	If Goods.Columns.Find("Purpose") <> Undefined Then
		FieldDestinationSelectionOfProducts = "Table.Purpose";
	EndIf;
	Query.Text = StrReplace(Query.Text, "&FieldDestinationSelectionOfProducts", FieldDestinationSelectionOfProducts);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	Query.SetParameter("AssignmentType", Selection.AssignmentType);
	Query.SetParameter("Partner", Selection.Partner);
	Query.SetParameter("Contract", Selection.Contract);
	
	Query.Text = QueryTextDataSource(False);
	Query.Execute();
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO SelectingDataSourceProducts
		|FROM
		|	DataSource AS Table
		|INDEX BY
		|	Products, Characteristic";
	Query.Execute();
	
	PurposeText = "VALUE(Catalog.Assignments.EmptyRef)"; // @query-part-1
	Query.Text = QueryTextAvailableStock(Sources.WarehouseStockBalance, PurposeText, "AvailableStock"); 
	Query.Execute();
	
	Query.Text =
		"SELECT
		|	Table.Purpose AS Purpose
		|INTO AppointmentsFromRegister
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		&ProvisionsForAppointments
		|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND Purpose NOT IN(&Purpose)) AS Table
		|INDEX BY
		|	Purpose
		|;
		|SELECT
		|	Table.Purpose AS Purpose
		|INTO SelectingSourceAssignments
		|FROM
		|	AppointmentsFromRegister AS Table
		|WHERE
		|	CASE
		|		WHEN
		|			&AssignmentType IN(
		|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22))
		|			THEN
		|				Table.Purpose.AssignmentType IN(
		|							VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22))
		|						AND &Partner = Table.Purpose.Partner
		|						AND &Contract = Table.Purpose.Contract
		|					OR Table.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
		|		ELSE
		|			NOT Table.Purpose.AssignmentType IN(
		|				VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
		|	END
		|		AND (&AllCompanies OR Table.Purpose.OrderDocument.Organization = &Organization)
		|INDEX BY
		|	Purpose";
	Query.Execute();
	
	PurposeText =
		"SELECT
		| Filter.Purpose AS Purpose
		|FROM
		|SelectingSourceAssignments AS Filter";
	
	Query.Text = QueryTextAvailableStock(True, PurposeText, "OrderFulfillment"); // @query-part-1
	Query.Execute();
	If MultipleAppointments Then // the destination recipient is used only on the second page, it is not on the first one.
		Query.SetParameter("Purpose", Catalogs.Assignments.EmptyRef());
	EndIf;
	
	Query.Text =
		"SELECT
		|	&Purpose                                  AS Purpose,
		|	VALUE(Catalog.Assignments.EmptyRef) AS DestinationSource,
		|	Table.Products                         AS Products,
		|	Table.Characteristic                       AS Characteristic,
		|	Table.Warehouse                                AS Warehouse,
		|	Table.Demand                          AS Demand,
		|	Table.Inventory                                AS Inventory,
		|	Table.Reserve                               AS Reserve,
		|	Table.UnderControl                           AS UnderControl
		|INTO CorrectionFillingTable
		|FROM
		|	AvailableStock AS Table
		|WHERE
		|	Table.Inventory > 0
		|
		|UNION ALL
		|	
		|SELECT
		|	&Purpose                                 AS Purpose,
		|	TableOfSourceAssignments.Purpose      AS DestinationSource,
		|	TableOfSourceAssignments.Products    AS Products,
		|	TableOfSourceAssignments.Characteristic  AS Characteristic,
		|	TableOfSourceAssignments.Warehouse           AS Warehouse,
		|	TableOfSourceAssignments.Demand     AS Demand,
		|	TableOfSourceAssignments.Inventory           AS Inventory,
		|	TableOfSourceAssignments.Reserve          AS Reserve,
		|	TableOfSourceAssignments.UnderControl      AS UnderControl
		|FROM
		|	OrderFulfillment AS TableOfSourceAssignments
		|WHERE
		|	TableOfSourceAssignments.Inventory > 0";
	Query.Execute();
	
	TableNameDataSource = "DataSource";
	If MultipleAppointments Then
		
		TableNameDataSource = "DataSource1";
		Text = QueryTextDataSource(False);
		Query.Text = StrReplace(Text, "DataSource", TableNameDataSource);
		Query.SetParameter("CollapseAssignments", False);
		Query.Execute();
		
	EndIf;
	AddTemporaryTableSortingWarehouses(Query, TableNameDataSource, "CorrectionFillingTable");
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse
		|INTO ShippingWarehousesRolledUp
		|FROM
		|	ShippingWarehouses AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|SELECT
		|	Table.Products             AS Products,
		|	Table.Characteristic           AS Characteristic,
		|	Table.Warehouse                    AS Warehouse,
		|	MIN(Table.WarehousePriority) AS WarehousePriority
		|INTO WarehouseSortingCollapsed
		|FROM
		|	SortingWarehouses AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	Query.Execute();
	
	Query.Text =
		"SELECT
		|	VALUE(Enum.KindsOfAssignmentAdjustmentOperations.ToReserve_) AS OperationKind,
		|	Table.Purpose                                                       AS AssignmentForTotals,
		|	Table.Products                                                     AS Products,
		|	Table.Products.UnitOfMeasure                                    AS UnitOfMeasure,
		|	Table.Characteristic                                                   AS Characteristic,
		|	Table.Warehouse                                                            AS Warehouse,
		|	Table.DestinationSource                                               AS InitialAssignment,
		|	Table.DestinationSource.OrderDocument                                         AS SourceOrder,
		|	Table.Purpose                                                       AS NewAssignment,
		|	Table.Purpose.OrderDocument                                                 AS NewOrder,
		|	Table.Demand                                                      AS Demand,
		|	Table.Inventory                                                            AS Inventory,
		|	Table.Reserve                                                           AS Reserve,
		|	Table.UnderControl                                                       AS UnderControl,
		|	NOT ShippingWarehousesTable.Warehouse IS NULL                                AS ThisIsShippingWarehouse,
		|	ISNULL(WarehouseSortingTable.WarehousePriority, 0)                    AS SortingWarehouse
		|FROM
		|	CorrectionFillingTable AS Table
		|		
		|		LEFT JOIN WarehouseSortingCollapsed AS WarehouseSortingTable
		|		ON WarehouseSortingTable.Warehouse          = Table.Warehouse
		|		 AND WarehouseSortingTable.Products   = Table.Products
		|		 AND WarehouseSortingTable.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN ShippingWarehousesRolledUp AS ShippingWarehousesTable
		|		ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|		 AND ShippingWarehousesTable.Products   = Table.Products
		|		 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = Table.Warehouse
		|WHERE
		|	NOT &ShippingWarehouseOnly OR NOT ShippingWarehousesTable.Warehouse IS NULL
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	ThisIsShippingWarehouse DESC,
		|	SortingWarehouse DESC,
		|	DestinationSource";
	
	TableOfGoods = Query.Execute().Unload();
	
	Texts = New Array();
	Text =
		"SELECT
		|	&Purpose                             AS AssignmentForTotals,
		|	Set.Products                      AS Products,
		|	Set.Characteristic                    AS Characteristic,
		|	Set.Warehouse                             AS Warehouse,
		|	SUM(Set.InStock)                   AS InStock,
		|	SUM(Set.Supplied)                 AS Supplied,
		|	SUM(Set.Demand)                AS Demand,
		|	MAX(Set.ThisIsShippingWarehouse)        AS ThisIsShippingWarehouse
		|INTO TableOfResults
		|FROM(
		|	SELECT
		|		Table.Products                      AS Products,
		|		Table.Characteristic                    AS Characteristic,
		|		Table.Warehouse                             AS Warehouse,
		|		Table.Inventory                             AS InStock,
		|		Table.Supplied                        AS Supplied,
		|		Table.Demand                       AS Demand,
		|		NOT ShippingWarehousesTable.Warehouse IS NULL AS ThisIsShippingWarehouse
		|	FROM
		|		DataSource AS Table
		|			
		|			LEFT JOIN ShippingWarehousesRolledUp AS ShippingWarehousesTable
		|			ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|			 AND ShippingWarehousesTable.Products   = Table.Products
		|			 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = Table.Warehouse
		|	
		|	UNION ALL
		|	
		// The block is added because the filling table may contain warehouses of other purposes that are not present in the data source.
		|	SELECT
		|		Table.Products                      AS Products,
		|		Table.Characteristic                    AS Characteristic,
		|		Table.Warehouse                             AS Warehouse,
		|		0                                         AS InStock,
		|		0                                         AS Supplied,
		|		0                                         AS Demand,
		|		NOT ShippingWarehousesTable.Warehouse IS NULL AS ThisIsShippingWarehouse
		|	FROM
		|		CorrectionFillingTable AS Table
		|			
		|			LEFT JOIN ShippingWarehousesRolledUp AS ShippingWarehousesTable
		|			ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|			 AND ShippingWarehousesTable.Products   = Table.Products
		|			 AND ShippingWarehousesTable.Characteristic = Table.Characteristic) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	Texts.Add(Text);
	
	Text = TemporaryTableMoveOrders(False);
	Texts.Add(Text);
	
	Text =
		"SELECT
		|	&Purpose AS AssignmentForTotals,
		|	TableOfResults.Products AS Products,
		|	TableOfResults.Characteristic AS Characteristic,
		|	SUM(TableOfResults.InStock) AS InStock,
		|	SUM(TableOfResults.Supplied) - MAX(ISNULL(TransferOrders.Count, 0)) AS Supplied,
		|	SUM(TableOfResults.Demand) - MAX(ISNULL(TransferOrders.Count, 0)) AS Demand
		|FROM
		|	TableOfResults AS TableOfResults
		|		
		|		LEFT JOIN TransferOrders AS TransferOrders
		|		ON TransferOrders.Products = TableOfResults.Products
		|		 AND TransferOrders.Characteristic = TableOfResults.Characteristic
		|GROUP BY
		|	TableOfResults.Products,
		|	TableOfResults.Characteristic";
	
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	If Selection.AssignmentType = Enums.AssignmentTypes.Own Then
		
		Var_Key = "InitialAssignment,Products,Characteristic,Warehouse";
		Rows = TableOfGoods.Copy(, Var_Key);
		CompanyGoods = GiveawayProductsOfSelectionOrganizations(Rows, Recorder);
		CompanyGoods.Indexes.Add(Var_Key);
		ReduceAppointmentOfTollingMaterialsWhenReserving(TableOfGoods, CompanyGoods);
		
	EndIf;
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("TableOfGoods", TableOfGoods);
	ReturnStructure.Insert("SummaryTotalsTable", Query.Execute().Unload());
	ReturnStructure.Insert("TableOfResults", Query.TempTablesManager.Tables["TableOfResults"].GetData().Unload());
	
	Texts = New Array();
	Text =
		"DROP TableOfResults;
		|DROP TransferOrders;
		|
		|////////////////////////////////////////////
		|SELECT
		|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentForTotals,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Demand AS Demand,
		|	Table.Inventory AS Inventory
		|INTO TableOfResults
		|	
		|FROM
		|	AvailableStock AS Table
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = Table.Warehouse
		|
		|UNION ALL
		|	
		|SELECT
		|	TableOfSourceAssignments.Purpose AS AssignmentForTotals,
		|	TableOfSourceAssignments.Products AS Products,
		|	TableOfSourceAssignments.Characteristic AS Characteristic,
		|	TableOfSourceAssignments.Warehouse AS Warehouse,
		|	TableOfSourceAssignments.Demand AS Demand,
		|	TableOfSourceAssignments.Inventory AS Inventory
		|FROM
		|	OrderFulfillment AS TableOfSourceAssignments
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = TableOfSourceAssignments.Warehouse
		|INDEX BY
		|	Products, Characteristic, AssignmentForTotals";
	Texts.Add(Text);
	Text = TemporaryTableMoveOrders(True);
	Texts.Add(Text);
	Text =
		"SELECT
		|	&Purpose AS Purpose,
		|	TableOfResults.AssignmentForTotals AS InitialAssignment,
		|	TableOfResults.Products AS Products,
		|	TableOfResults.Characteristic AS Characteristic,
		|	SUM(TableOfResults.Demand) - MAX(ISNULL(TransferOrders.Count, 0)) AS Demand,
		|	SUM(TableOfResults.Inventory) AS Inventory
		|FROM
		|	TableOfResults AS TableOfResults
		|		
		|		LEFT JOIN TransferOrders AS TransferOrders
		|		ON TransferOrders.Products = TableOfResults.Products
		|		 AND TransferOrders.Characteristic = TableOfResults.Characteristic
		|		 AND TransferOrders.Purpose = TableOfResults.AssignmentForTotals
		|GROUP BY
		|	TableOfResults.Products,
		|	TableOfResults.Characteristic,
		|	TableOfResults.AssignmentForTotals";
	
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	ReturnStructure.Insert("TableOfTotalsOfSourcesOfProvision", Query.Execute().Unload());
	
	Return ReturnStructure;
	
EndFunction

// Returns a table to fill in the assignment adjustment.
// Parameters:
//  Destinations - An Array From The Reference Link.Destinations -
//  Only Shipments - Boolean -
//  Goods - Assignment Tables
//  The registrar is a document link.Adjustments to the assignment of goods, Indefinite -
// Returns:
//  Structure -
//   *Tables of Goods - Tables of values -
//   *Tables of Totals - Tables of values -

Function MultiPurposeTable(Assignments, ShippingWarehouseOnly, Goods, Recorder) Export
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Purpose",          Assignments);
	Query.SetParameter("Goods",              Goods);
	Query.SetParameter("AllGoods",           Goods.Count() = 0);
	Query.SetParameter("ShippingWarehouseOnly", ShippingWarehouseOnly);
	Query.SetParameter("Recorder",         Recorder);
	Query.SetParameter("CollapseAssignments",  False);
	Query.SetParameter("EmptyLinkKey",     New UUID("00000000-0000-0000-0000-000000000000"));
	
	Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|INTO PermittedWarehouses
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|INDEX BY
		|	Warehouse";
	Query.Execute();
	
	SetPrivilegedMode(True);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose
		|INTO FilterOfProducts_
		|FROM
		|	&Goods AS Table
		|INDEX BY
		|	Products, Characteristic
		|;
		|///////////////////////////////////
		|
		|SELECT
		|	Assignments.Ref AS Purpose
		|INTO SelectionOfAppointments_
		|FROM
		|	Catalog.Assignments AS Assignments
		|WHERE
		|	Assignments.Ref IN (&Purpose)";
	
	Query.Execute();
	
	Query.Text = QueryTextDataSource(True);
	Query.Execute();
	
	Query.Text =
		"SELECT
		|	Table.Purpose                           AS Purpose,
		|	Table.Products                         AS Products,
		|	Table.Characteristic                       AS Characteristic,
		|	Table.Warehouse                                AS Warehouse,
		|	Table.Inventory                                AS InStock,
		|	Table.Supplied                           AS Supplied,
		|	Table.Demand                          AS Demand
		|INTO CorrectionFillingTable
		|FROM
		|	DataSource AS Table";
	Query.Execute();
	
	AddTemporaryTableSortingWarehouses(Query, "DataSource", "DataSource");
	
	Query.Text =
		"SELECT
		|	VALUE(Enum.KindsOfAssignmentAdjustmentOperations.EmptyRef)  AS OperationKind,
		|	VALUE(Catalog.Assignments.EmptyRef)                             AS AssignmentForTotals,
		|	Table.Products                                                     AS Products,
		|	MAX(Table.Products.UnitOfMeasure)                          AS UnitOfMeasure,
		|	Table.Characteristic                                                   AS Characteristic,
		|	VALUE(Catalog.Warehouses.EmptyRef)                                 AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef)                             AS InitialAssignment,
		|	UNDEFINED                                                             AS SourceOrder,
		|	Table.Purpose                                                       AS NewAssignment,
		|	MAX(Table.Purpose.OrderDocument)                                       AS NewOrder,
		|	SUM(Table.InStock)                                                  AS InStock,
		|	SUM(Table.Supplied)                                                AS Supplied,
		|	SUM(Table.Demand)                                               AS Demand
		|FROM
		|	CorrectionFillingTable AS Table
		|		
		|		LEFT JOIN ShippingWarehouses AS ShippingWarehousesTable
		|		ON ShippingWarehousesTable.Warehouse          = Table.Warehouse
		|		 AND ShippingWarehousesTable.Products   = Table.Products
		|		 AND ShippingWarehousesTable.Characteristic = Table.Characteristic
		|		 AND ShippingWarehousesTable.Purpose     = Table.Purpose
		|		
		|		INNER JOIN PermittedWarehouses AS PermittedWarehouses
		|		ON PermittedWarehouses.Warehouse = Table.Warehouse
		|WHERE
		|	NOT &ShippingWarehouseOnly OR NOT ShippingWarehousesTable.Warehouse IS NULL
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	NewAssignment";
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Returns the composition of the set by product locations.
// Parameters:
//  ListOfItems - Array of CatalogRef.Products - Goods
// Returns:
//  Map of CatalogRef.Products - kit packaging
Function ProductLocationsAccordingToItemList(ListOfItems) Export
	
	QueryTextPackages = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Packages.Ref", "ItemList.Ref");
	
	QueryText =
		"SELECT
		|	ItemList.Ref AS Ref,
		|	Packages.Ref AS Package,
		|	ISNULL(&RequestTextForPackingCoefficient, 1) AS ZoomRatio
		|FROM
		|	Catalog.Products AS ItemList
		|		
		|		LEFT JOIN Catalog.PackagingGroups AS Sets
		|		ON Sets.Ref = ItemList.PackagingGroup
		|		 AND Sets.Ref <> VALUE(Catalog.PackagingGroups.SpecialForItem)
		|		
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
		|		ON Packages.Owner = ISNULL(Sets.Ref, ItemList.Ref)
		|WHERE
		|	ItemList.Ref IN(&ListOfItems)
		|		AND ItemList.PackagingGroup <> VALUE(Catalog.PackagingGroups.EmptyRef)
		|		AND Packages.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|		AND NOT Packages.DeletionMark";
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", QueryTextPackages);
	Query = New Query(QueryText);
	Query.SetParameter("ListOfItems", ListOfItems);
	Selection = Query.Execute().Select();
	
	Result = New Map();
	CurrentProducts = Undefined;
	Packages = Undefined;
	While Selection.Next() Do
		If Selection.Ref <> CurrentProducts Then
			CurrentProducts = Selection.Ref;
			Packages = New Map();
			Result.Insert(CurrentProducts, Packages);
		EndIf;
		Packages.Insert(Selection.Package, Selection.ZoomRatio);
	EndDo;
	Return Result;
	
EndFunction

Procedure AddControlledLotReferencesToTable(Table, Recorder) Export
	
	Table.Columns.Add("ControlledLotReference", New TypeDescription("CatalogRef.ControlledLots"));
	
	If Not GetFunctionalOption("UseGoodsQualityControl") Then
		Return;
	EndIf;
	SetPrivilegedMode(True);
	
	Goods = Table.Copy(, "Products,Characteristic,Warehouse,InitialAssignment,Premise,Series,Count");
	
	Query = New Query();
	Query.SetParameter("Goods", Goods);
	Query.SetParameter("Recorder", Recorder);
	
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	Texts = New Array();
	
	Texts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
	Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.InitialAssignment AS Purpose,
		|	Table.Premise AS Premise,
		|	Table.Series AS Series,
		|	Table.Count AS Count
		|INTO ProductsAll
		|FROM
		|	&Goods AS Table
		|;
		|
		|/////////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.Premise AS Premise,
		|	Table.Series AS Series,
		|	SUM(Table.Count) AS Count
		|INTO Goods
		|FROM
		|	ProductsAll AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose,
		|	Table.Premise,
		|	Table.Series
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, Premise, Series
		|;
		|
		|/////////////////////////////////////////////
		// Balance limit based on series
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS InitialAssignment,
		|	Set.Premise AS Premise,
		|	Set.Series AS Series,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	SUM(Set.Count) AS Count
		|INTO ProductStockBalance
		|FROM(
		|	SELECT
		|		ProductStock.Products AS Products,
		|		ProductStock.Characteristic AS Characteristic,
		|		ProductStock.Warehouse AS Warehouse,
		|		ProductStock.Purpose AS Purpose,
		|		ProductStock.Premise AS Premise,
		|		ProductStock.Series AS Series,
		|		ProductStock.ControlledLotReference AS ControlledLotReference,
		|		ProductStock.InStockBalance - ProductStock.ToShipBalance AS Count
		|	FROM
		|		AccumulationRegister.ProductStock.Balance(,
		|			(Products, Characteristic, Warehouse, Purpose, Premise, Series)
		|				IN(
		|					SELECT
		|						Filter.Products AS Products,
		|						Filter.Characteristic AS Characteristic,
		|						Filter.Warehouse AS Warehouse,
		|						Filter.Purpose AS Purpose,
		|						Filter.Premise AS Premise,
		|						Filter.Series AS Series
		|					FROM
		|						Goods AS Filter)) AS ProductStock
		|		
		|	UNION ALL
		|	
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.Premise AS Premise,
		|		RegisterRecords.Series AS Series,
		|		RegisterRecords.ControlledLotReference AS ControlledLotReference,
		|		- CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.InStock
		|			ELSE - RegisterRecords.InStock
		|		END
		|		+ CASE
		|			WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN RegisterRecords.ToShip
		|			ELSE - RegisterRecords.ToShip
		|		END AS Count
		|FROM
		|	AccumulationRegister.ProductStock AS RegisterRecords
		|WHERE
		|	RegisterRecords.Active
		|		AND RegisterRecords.Recorder = &Recorder
		|		AND (RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Warehouse, RegisterRecords.Purpose, RegisterRecords.Premise, RegisterRecords.Series)
		|			IN(
		|				SELECT
		|					Filter.Products AS Products,
		|					Filter.Characteristic AS Characteristic,
		|					Filter.Warehouse AS Warehouse,
		|					Filter.Purpose AS Purpose,
		|					Filter.Premise AS Premise,
		|					Filter.Series AS Series
		|				FROM
		|					Goods AS Filter)) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.Premise,
		|	Set.Series,
		|	Set.ControlledLotReference
		|HAVING
		|	SUM(Set.Count) > 0
		|INDEX BY
		|	ControlledLotReference
		|;
		|
		|///////////////////////////////////////////////
		// Restriction on free Balances.
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	SUM(Table.Count) AS Count
		|INTO ProductsWithoutSeries
		|FROM
		|	Goods AS Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse,
		|	Table.Purpose
		|INDEX BY
		|	Products,Characteristic,Warehouse,Purpose
		|;
		|
		|/////////////////////////////////////////////
		|SELECT
		|	RegisterRecords.Products AS Products,
		|	RegisterRecords.Characteristic AS Characteristic,
		|	RegisterRecords.Warehouse AS Warehouse,
		|	RegisterRecords.Purpose AS Purpose,
		|	RegisterRecords.OrderDocument AS OrderDocument,
		|	CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN RegisterRecords.InStock
		|		ELSE - RegisterRecords.InStock
		|	END AS InStock,
		|	CASE
		|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN RegisterRecords.LockedInStock
		|		ELSE - RegisterRecords.LockedInStock
		|	END AS LockedInStock
		|INTO InventoryAndNeedsStorno
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
		|WHERE
		|	RegisterRecords.Active
		|		AND RegisterRecords.Recorder = &Recorder
		|		AND (RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Warehouse, RegisterRecords.Purpose)
		|			IN(
		|				SELECT
		|					Filter.Products AS Products,
		|					Filter.Characteristic AS Characteristic,
		|					Filter.Warehouse AS Warehouse,
		|					Filter.Purpose AS Purpose
		|				FROM
		|					ProductsWithoutSeries AS Filter)
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.ControlledLotReference AS ControlledLotReference,
		|	Set.Purpose AS InitialAssignment,
		|	CASE
		|		WHEN Set.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN SUM(Set.AvailableForInventoryAllocation)
		|		WHEN SUM(Set.AvailableForInventoryAllocation) < SUM(Set.ToUnlock)
		|			THEN SUM(Set.AvailableForInventoryAllocation)
		|		ELSE SUM(Set.ToUnlock)
		|	END AS Count
		|INTO InventoryAndDemandsBalance
		|FROM(
		|	SELECT
		|		Inventories.Products AS Products,
		|		Inventories.Characteristic AS Characteristic,
		|		Inventories.Warehouse AS Warehouse,
		|		Inventories.Purpose AS Purpose,
		|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|		0 AS ToUnlock,
		|		Inventories.InStockBalance
		|		- Inventories.LockedInStockBalance
		|		- Inventories.ReserveAtWarehouseBalance
		|		- Inventories.ReserveAsReceivedBalance AS AvailableForInventoryAllocation
		|	FROM
		|		AccumulationRegister.InventoryAndDemands.Balance(,
		|			(Products, Characteristic, Warehouse, Purpose)
		|				IN(
		|					SELECT
		|						Filter.Products AS Products,
		|						Filter.Characteristic AS Characteristic,
		|						Filter.Warehouse AS Warehouse,
		|						Filter.Purpose AS Purpose
		|					FROM
		|						ProductsWithoutSeries AS Filter)) AS Inventories
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|		0 AS ToUnlock,
		|		- (RegisterRecords.InStock
		|			- RegisterRecords.LockedInStock) AS AvailableForInventoryAllocation
		|		FROM
		|			InventoryAndNeedsStorno AS RegisterRecords
		|	WHERE
		|		RegisterRecords.InStock - RegisterRecords.LockedInStock <> 0
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Inventories.Products AS Products,
		|		Inventories.Characteristic AS Characteristic,
		|		Inventories.Warehouse AS Warehouse,
		|		Inventories.Purpose AS Purpose,
		|		Inventories.OrderDocument AS ControlledLotReference,
		|		Inventories.ToUnlockBalance AS ToUnlock,
		|		Inventories.LockedInStockBalance
		|			- Inventories.ReserveAtWarehouseFromLockedBalance
		|			- Inventories.ReserveUponReceiptFromLockedBalance AS AvailableForInventoryAllocation
		|	FROM
		|		AccumulationRegister.InventoryAndDemands.Balance(,
		|			(Products, Characteristic, Warehouse, Purpose)
		|				IN(
		|					SELECT
		|						Filter.Products AS Products,
		|						Filter.Characteristic AS Characteristic,
		|						Filter.Warehouse AS Warehouse,
		|						Filter.Purpose AS Purpose
		|					FROM
		|						ProductsWithoutSeries AS Filter)) AS Inventories
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		RegisterRecords.Products AS Products,
		|		RegisterRecords.Characteristic AS Characteristic,
		|		RegisterRecords.Warehouse AS Warehouse,
		|		RegisterRecords.Purpose AS Purpose,
		|		RegisterRecords.OrderDocument AS ControlledLotReference,
		|		0 AS ToUnlock,
		|		- RegisterRecords.LockedInStock AS AvailableForInventoryAllocation
		|	FROM
		|		InventoryAndNeedsStorno AS RegisterRecords
		|	WHERE
		|		RegisterRecords.LockedInStock <> 0
		|) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose,
		|	Set.ControlledLotReference
		|HAVING
		|	CASE
		|		WHEN Set.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
		|			THEN SUM(Set.AvailableForInventoryAllocation)
		|		WHEN SUM(Set.AvailableForInventoryAllocation) < SUM(Set.ToUnlock)
		|			THEN SUM(Set.AvailableForInventoryAllocation)
		|		ELSE SUM(Set.ToUnlock)
		|	END > 0
		|INDEX BY
		|	ControlledLotReference
		|;
		|
		|///////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Premise AS Premise,
		|	Table.Series AS Series,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.Count AS Count,
		|	ISNULL(Table.ControlledLotReference.QualityConfirmationDate, DATETIME(1, 1, 1)) AS QualityConfirmationDate,
		|	ISNULL(Table.ControlledLotReference.DateOfReceipt, DATETIME(1, 1, 1)) AS DateOfReceipt,
		|	Table.Products.TermOfQualityControl AS TermOfQualityControl
		|INTO GoodsInWarehousesOrderingCalculation
		|FROM
		|	ProductStockBalance AS Table
		|;
		|
		|///////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Count AS Count,
		|	ISNULL(Table.ControlledLotReference.QualityConfirmationDate, DATETIME(1, 1, 1)) AS QualityConfirmationDate,
		|	ISNULL(Table.ControlledLotReference.DateOfReceipt, DATETIME(1, 1, 1)) AS DateOfReceipt,
		|	Table.Products.TermOfQualityControl AS TermOfQualityControl
		|INTO InventoriesAndNeedsBalancesOrderingCalculation
		|FROM
		|	InventoryAndDemandsBalance AS Table
		|;
		|
		|///////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Premise AS Premise,
		|	Table.Series AS Series,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.Count AS Count,
		|	CASE
		|		WHEN Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.QualityConfirmationDate = DATETIME(1, 1, 1)
		|			THEN 0
		|		ELSE 1
		|	END AS PartyPriority,
		|	CASE
		|		WHEN Table.DateOfReceipt = DATETIME(1, 1, 1)
		|				AND Table.QualityConfirmationDate = DATETIME(1, 1, 1)
		|			THEN DATETIME(1, 1, 1)
		|		WHEN Table.QualityConfirmationDate <> DATETIME(1, 1, 1)
		|			THEN Table.QualityConfirmationDate
		|		WHEN CalculationOfQualityControlPeriodOverridable.DateFound > DATETIME(1, 1, 1)
		|			THEN CalculationOfQualityControlPeriodOverridable.DateFound
		|		ELSE DATEADD(Table.DateOfReceipt, DAY, Table.TermOfQualityControl)
		|	END AS QualityConfirmationDate
		|FROM
		|	GoodsInWarehousesOrderingCalculation AS Table
		|		LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE
		|ORDER BY
		|	Products,Characteristic,Warehouse,InitialAssignment,Premise,Series,PartyPriority,QualityConfirmationDate DESC,ControlledLotReference
		|;
		|
		|///////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.ControlledLotReference AS ControlledLotReference,
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Count AS Count,
		|	CASE
		|		WHEN Table.DateOfReceipt = DATETIME(1, 1, 1)
		|			AND Table.QualityConfirmationDate = DATETIME(1, 1, 1)
		|			THEN 0
		|		ELSE 1
		|	END AS PartyPriority,
		|	CASE
		|		WHEN Table.DateOfReceipt = DATETIME(1, 1, 1)
		|				AND Table.QualityConfirmationDate = DATETIME(1, 1, 1)
		|			THEN DATETIME(1, 1, 1)
		|		WHEN Table.QualityConfirmationDate <> DATETIME(1, 1, 1)
		|			THEN Table.QualityConfirmationDate
		|		WHEN CalculationOfQualityControlPeriodOverridable.DateFound > DATETIME(1, 1, 1)
		|			THEN CalculationOfQualityControlPeriodOverridable.DateFound
		|		ELSE DATEADD(Table.DateOfReceipt, DAY, Table.TermOfQualityControl)
		|	END AS QualityConfirmationDate
		|FROM
		|	InventoriesAndNeedsBalancesOrderingCalculation AS Table
		|		LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE
		|ORDER BY
		|	Products,Characteristic,Warehouse,InitialAssignment,PartyPriority,QualityConfirmationDate DESC,ControlledLotReference";
		
	Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
		"Table.DateOfReceipt",
		"Table.TermOfQualityControl");
	
	Text = StrReplace(Text, "CalculationOfQualityControlPeriodOverridable.DateFound", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfQualityControlPeriodOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	QueryBatch = Query.ExecuteBatch();
	ProductStock = QueryBatch[QueryBatch.UBound() - 1].Unload();
	InventoryAndDemands = QueryBatch[QueryBatch.UBound()].Unload();
	KeyFieldsForGoodsInWarehouses = "Products,Characteristic,Warehouse,InitialAssignment,Premise,Series";
	KeyFieldsInventoryAndNeeds = "Products,Characteristic,Warehouse,InitialAssignment,ControlledLotReference";
	ProductStock.Indexes.Add(KeyFieldsForGoodsInWarehouses);
	InventoryAndDemands.Indexes.Add(KeyFieldsInventoryAndNeeds);
	KeyItemsInWarehouses = New Structure(KeyFieldsForGoodsInWarehouses);
	KeyInventoryAndNeeds = New Structure(KeyFieldsInventoryAndNeeds);
	TotalRows = Table.Count();
	InsertedLines = 0;
	For IndexOf = 0 To TotalRows - 1 Do
		
		NewLineWithEmptyLotReference = Undefined;
		
		TableRow = Table[IndexOf + InsertedLines];
		Count = TableRow.Count;
		
		FillPropertyValues(KeyItemsInWarehouses, TableRow);
		FoundGoods = ProductStock.FindRows(KeyItemsInWarehouses);
		
		For GoodsIndex = 0 To FoundGoods.Count() - 1 Do
			
			FoundProduct = FoundGoods[GoodsIndex];
			
			Allocate = Min(FoundProduct.Count, Count);
			FillPropertyValues(KeyInventoryAndNeeds, FoundProduct);
			FoundStocks = InventoryAndDemands.FindRows(KeyInventoryAndNeeds);
			
			AvailableForInventoryAllocation = 0;
			If FoundStocks.Count() > 0 Then
				InventoryFound = FoundStocks[0];
				AvailableForInventoryAllocation = Min(InventoryFound.Count, Allocate);
			EndIf;
			Allocate = AvailableForInventoryAllocation;
			If Allocate > 0 Then
				NewRow = Table.Insert(IndexOf + InsertedLines);
				InsertedLines = InsertedLines + 1;
				FillPropertyValues(NewRow, TableRow);
				NewRow.ControlledLotReference = FoundProduct.ControlledLotReference;
				NewRow.Count = Allocate;
				InventoryFound.Count = InventoryFound.Count - Allocate;
				FoundProduct.Count = FoundProduct.Count - Allocate;
				Count = Count - Allocate;
				If Not ValueIsFilled(NewRow.ControlledLotReference) Then
					NewLineWithEmptyLotReference = NewRow;
				EndIf;
			EndIf;
			
		EndDo;
		
		// If there are not enough Balances according to the query data, then add the rest with an empty batch.
		If Count > 0 Then
			If NewLineWithEmptyLotReference = Undefined Then
				NewRow = Table.Insert(IndexOf + InsertedLines);
				InsertedLines = InsertedLines + 1;
				FillPropertyValues(NewRow, TableRow);
				NewRow.Count = 0;
				NewLineWithEmptyLotReference = NewRow;
			EndIf;
			NewLineWithEmptyLotReference.Count = NewLineWithEmptyLotReference.Count + Count;
		EndIf;
		
		Table.Delete(TableRow);
		InsertedLines = InsertedLines - 1;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region MaintenanceOfProcessingOfFillingOfAdjustmentOfAppointment

Function CreateFillAndNavigateDocument(HeaderAttributes, Table) Export
	
	Result = New Structure("Document,Posted,Errors");

	Document = Documents.InventoryAssignmentAdjustment.CreateDocument();
	
	FillingData = New Structure("HeaderAttributes,Goods", HeaderAttributes, Table);
	Document.Fill(FillingData);
	Error = Not Document.CheckFilling();
	If Not Error Then
		
		Try
			Document.Write(DocumentWriteMode.Posting);
			Result.Posted = True;
		Except
			
			Result.Errors = GetUserMessages(True);
			Document.Write(DocumentWriteMode.Write);
			Result.Posted = False;
			
		EndTry;
		
	Else
		
		Result.Errors = GetUserMessages(True);
		Document.Write(DocumentWriteMode.Write);
		Result.Posted = False;
		
	EndIf;
	
	Result.Document = Document.Ref;
	Return Result;
	
EndFunction

// Parameters:
//  Table - ValueTable - the table corresponding to the tabular part "Goods" of the document.
//
// Returns:
//  QueryResultSelection - A selection containing signs of specifying cell spaces and series for a row.
//
Function SpecifyingNumberOfSeriesCellsForRow(Table) Export
	
	Table.Columns.Add("LineNumber", New TypeDescription("Number"));
	Table.Columns.Add("BatchesIndicationStatus", New TypeDescription("Number"));
	Table.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	
	// Filling in the line number for calculations, and subsequent communication with the table of goods
	For LineNumber = 1 To Table.Count() Do
		Table[LineNumber - 1].LineNumber = LineNumber;
	EndDo;
	
	Query = New Query;
	QueryTextTableOfProducts_ =
	"SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Warehouse AS Warehouse
	|INTO TableRows
	|FROM
	|	&Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Warehouse,
	|	ISNULL(Warerooms.Ref, VALUE(Catalog.Warerooms.EmptyRef)) AS Premise
	|INTO TableOfGoods
	|FROM
	|	TableRows AS TableOfGoods
	|		LEFT JOIN Catalog.Warerooms AS Warerooms
	|		ON TableOfGoods.Warehouse = Warerooms.Owner
	|		AND Warerooms.DeletionMark = FALSE";
	
	// Determination of the use of premises by warehouses and address storage
	// + Determination of the use of series by warehouse.
	RequestEndText = 
	"SELECT
	|	Table.LineNumber,
	|	MAX(Table.UseBinLocationWarehousing) AS UseBinLocationWarehousing,
	|	MAX(Table.UseWarerooms) AS UseWarerooms,
	|	MAX(CASE WHEN ISNULL(StatusTable.BatchesIndicationStatus, 0) > 0 THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END) AS KeepAccountingByBatch
	|FROM
	|	TTUseOfPremisesAndAddressableStorage AS Table
	|		LEFT JOIN StatusTable AS StatusTable
	|		ON Table.LineNumber = StatusTable.LineNumber
	|
	|GROUP BY
	|	Table.LineNumber";
	
	TextAddressableStorage = Documents.InventoryAssignmentAdjustment.RequestTextUseOfPremisesAndAddressStorage(
		"TTUseOfPremisesAndAddressableStorage");
	TextSeriesStatus = Documents.InventoryAssignmentAdjustment.TextOfRequestToFillInStatusesForSpecifyingSeries(Undefined);

	QueriesTexts = New Array();
	QueriesTexts.Add(QueryTextTableOfProducts_);
	QueriesTexts.Add(TextAddressableStorage);
	QueriesTexts.Add(TextSeriesStatus);
	QueriesTexts.Add(RequestEndText);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Period", CurrentSessionDate());
	Query.SetParameter("Goods", Table);
	
	Selection = Query.Execute().Select();
	Table.Columns.Delete("LineNumber");
	Table.Columns.Delete("BatchesIndicationStatus");
	Table.Columns.Delete("Series");
	Return Selection;

EndFunction

// Parameters:
//  TableOfSemiFinishedProducts - ValueTable - Table of semi-finished products.
//  TableOfMaterials - ValueTable - Table of materials.
//
// Returns:
//  ValueTable - The table of distribution of materials, taking into account the coefficients for semi-finished products.
//
Function DistributeCounterAdjustmentGoods(TableOfSemiFinishedProducts, TableOfMaterials) Export

	TableOfSemiFinishedProducts.Columns.Add("DistributionCoefficient", Common.TypeDescriptionNumber(15, 3));
	TableOfSemiFinishedProducts.Columns.Add("DistributionKey", Common.TypeDescriptionNumber(10));
	
	Total_Quantity = TableOfSemiFinishedProducts.Total("Count");
	
	RowIndex = TableOfSemiFinishedProducts.Count() - 1;
	While RowIndex > -1 Do
	
		TableRow = TableOfSemiFinishedProducts[RowIndex];
		
		TableRow.DistributionKey        = RowIndex;
		TableRow.DistributionCoefficient = Int(TableRow.Count / Total_Quantity * 1000) / 1000;
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
	TableOfSemiFinishedProducts.Sort("Count Desc");
	
	TotalDistributionCoefficient = TableOfSemiFinishedProducts.Total("DistributionCoefficient");
	If TotalDistributionCoefficient <> 1 Then
		TableRow = TableOfSemiFinishedProducts[0];
		TableRow.DistributionCoefficient =
			TableRow.DistributionCoefficient + 1 - TotalDistributionCoefficient;
	EndIf;
		
	TableOfMaterials.Columns.Add("DistributionKey", Common.TypeDescriptionNumber(10));
	
	RowIndex = TableOfMaterials.Count() - 1;
	While RowIndex > -1 Do
		
		TableRow = TableOfMaterials[RowIndex];
		
		If ValueIsFilled(TableRow.Package) Then
			MeasuredValueType = Common.ObjectAttributeValue(
										TableRow.Package, "MeasuredValueType");
		Else
			MeasuredValueType = Common.ObjectAttributeValue(
										TableRow.Products, "UnitOfMeasure.MeasuredValueType");
		EndIf;
		
		DistributePieceByPiece = MeasuredValueType = Enums.TypesOfMeasuredValues.NumberOfPieces;
		
		TotalNumberOfDistributions = TableRow.Count;
		
		IndexOfRowWithHighestNumber = -1;
		For Each RowOfOriginalTable In TableOfSemiFinishedProducts Do
			
			DistributionQuantity =
				Int(TableRow.Count * RowOfOriginalTable.DistributionCoefficient * 1000) / 1000;
			
			If DistributePieceByPiece Then
				QuantityOfOCDDistribution = Round(DistributionQuantity);
				If DistributionQuantity <> QuantityOfOCDDistribution Then
					DistributionQuantity = ?(QuantityOfOCDDistribution = 0, 1, QuantityOfOCDDistribution);
				EndIf;
				DistributionQuantity = Min(DistributionQuantity, TotalNumberOfDistributions);
			ElsIf DistributionQuantity = 0 Then
				DistributionQuantity = TotalNumberOfDistributions;
			EndIf;
			
			NewTableRow = TableOfMaterials.Add();
			NewTableRow.NewAssignment   = RowOfOriginalTable.InitialAssignment;
			NewTableRow.DistributionKey = RowOfOriginalTable.DistributionKey;
			NewTableRow.Count        = DistributionQuantity;
			
			FillPropertyValues(
				NewTableRow, TableRow,, "NewAssignment, DistributionKey, Count");
			
			If IndexOfRowWithHighestNumber = -1 Then
				IndexOfRowWithHighestNumber = TableOfMaterials.Count() - 1;
			EndIf;
			
			TotalNumberOfDistributions = TotalNumberOfDistributions - NewTableRow.Count;
			If TotalNumberOfDistributions = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
		If TotalNumberOfDistributions <> 0 Then
			NewTableRow = TableOfMaterials[IndexOfRowWithHighestNumber];
			NewTableRow.Count = NewTableRow.Count + TotalNumberOfDistributions;
		EndIf;
		
		TableOfMaterials.Delete(RowIndex);
		
		RowIndex = RowIndex - 1;
		
	EndDo;
	
	Result = TableOfMaterials.CopyColumns();
	TableOfMaterials.Indexes.Add("DistributionKey");
	For Each TableRow In TableOfSemiFinishedProducts Do
		
		NewTableRow = Result.Add();
		FillPropertyValues(NewTableRow, TableRow);
		
		CommonClientServer.SupplementTable(
			TableOfMaterials.Copy(New Structure("DistributionKey", TableRow.DistributionKey)),
			Result);
		
	EndDo;
	
	Return Result;

EndFunction

Procedure WithdrawReserves(GoodsTable, RemoveExcessReserves, ProductResults) Export
	
	If RemoveExcessReserves Then
		
		If TypeOf(GoodsTable) = Type("FormDataCollection") Then
			Table = GoodsTable.Unload();
		Else
			Table = GoodsTable.Copy();
		EndIf;
		Totals = ProductResults;
		If TypeOf(Totals) = Type("FormDataCollection") Then
			Totals = Totals.Unload();
		EndIf;
		LineGroupings = "AssignmentForTotals,Products,Characteristic";
		Totals.GroupBy(LineGroupings, "Demand");
		Totals.Indexes.Add(LineGroupings);
		
		Table.Columns.Add("ProvisionForNeeds");
		
		StructureOfKeyFields = New Structure(LineGroupings);
		
		For Counter = 1 To Table.Count() Do
			
			String = Table[Counter - 1];
			If StructureOfKeyFields.AssignmentForTotals <> String.AssignmentForTotals
					Or StructureOfKeyFields.Products <> String.Products
					Or StructureOfKeyFields.Characteristic <> String.Characteristic Then
					
					FillPropertyValues(StructureOfKeyFields, String);
					FoundRows = Totals.FindRows(StructureOfKeyFields);
					
			EndIf;
			String.ProvisionForNeeds = Max(0, Min(String.Inventory - String.Reserve, String.Demand - String.Reserve));
			FoundRows[0].Demand = FoundRows[0].Demand - String.ProvisionForNeeds - String.Reserve;
			
		EndDo;
		For Counter = 1 To Table.Count() Do
			
			String = Table[Counter - 1];
			If StructureOfKeyFields.AssignmentForTotals <> String.AssignmentForTotals
					Or StructureOfKeyFields.Products <> String.Products
					Or StructureOfKeyFields.Characteristic <> String.Characteristic Then
					
					FillPropertyValues(StructureOfKeyFields, String);
					FoundRows = Totals.FindRows(StructureOfKeyFields);
					
			EndIf;
			CurNeed = Max(0, Min(String.Inventory - String.Reserve - String.ProvisionForNeeds, FoundRows[0].Demand));
			String.ProvisionForNeeds = String.ProvisionForNeeds + CurNeed;
			FoundRows[0].Demand = FoundRows[0].Demand - CurNeed;
			
			GoodsTable[Counter - 1].Count = Max(0, String.Inventory - String.Reserve - String.ProvisionForNeeds);
			GoodsTable[Counter - 1].Mark = GoodsTable[Counter - 1].Count > 0;
		EndDo;
		
	Else
		
		For Each String In GoodsTable Do
			
			// To remove all reserves
			String.Count = Max(0, String.Inventory - String.Reserve);
			String.Mark = String.Count > 0;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure EstablishReserves(Table, TableResults_, CalculateDemandForAllWarehouses) Export
	
	If CalculateDemandForAllWarehouses Then
		LineGroupings = "AssignmentForTotals,Products,Characteristic";
	Else
		LineGroupings = "AssignmentForTotals,Products,Characteristic,Warehouse";
	EndIf;
	
	RowsWithWarehouse = New Array();
	For Each String In TableResults_ Do
		If Not String.Warehouse.IsEmpty() Then
			RowsWithWarehouse.Add(String);
		EndIf;
	EndDo;
	If TypeOf(TableResults_) = Type("FormDataCollection") Then
		Totals = TableResults_.Unload(RowsWithWarehouse, LineGroupings + ",Demand,Supplied");
	ElsIf TypeOf(TableResults_) = Type("ValueTable") Then
		Totals = TableResults_.Copy(RowsWithWarehouse, LineGroupings + ",Demand,Supplied");
	EndIf;
	Totals.GroupBy(LineGroupings, "Demand,Supplied");
	Totals.Columns.AssignmentForTotals.Name = "NewAssignment";
	If CalculateDemandForAllWarehouses Then
		LineGroupings = "NewAssignment,Products,Characteristic";
	Else
		LineGroupings = "NewAssignment,Products,Characteristic,Warehouse";
	EndIf;
	Totals.Indexes.Add(LineGroupings);
	
	StructureOfKeyFields = New Structure(LineGroupings);
	Demand = 0;
	
	For Each String In Table Do
		
		If String.OperationKind <> Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
			Continue;
		EndIf;
		
		If StructureOfKeyFields.NewAssignment <> String.NewAssignment
				Or StructureOfKeyFields.Products <> String.Products
				Or StructureOfKeyFields.Characteristic <> String.Characteristic
				Or Not CalculateDemandForAllWarehouses And StructureOfKeyFields.Warehouse <> String.Warehouse Then
				
				FillPropertyValues(StructureOfKeyFields, String);
				FoundRows = Totals.FindRows(StructureOfKeyFields);
				Demand = Max(FoundRows[0].Demand - FoundRows[0].Supplied, 0);
				
		EndIf;
		
		If Not ValueIsFilled(String.InitialAssignment) Then
			
			String.Count = Max(Min(Demand, String.Inventory - String.Reserve - String.UnderControl), 0);
			Demand = Demand - String.Count;
			String.Mark = String.Count > 0;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DiscussingFormOfDocument

// Parameters:
//  Object - FormDataStructure:
//   * Goods - FormDataCollection - collection on the form.
//  RowsArray - Array - processed collection rows.
Procedure FillInOrderInProductsTabularSection(Object, RowsArray = Undefined) Export
	
	Table = New ValueTable();
	Table.Columns.Add("InitialAssignment", New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("NewAssignment", New TypeDescription("CatalogRef.Assignments"));
	Table.Columns.Add("RowIndex", New TypeDescription("Number"));
	Rows = ?(RowsArray = Undefined, Object.Goods, RowsArray);
	
	For Each String In Rows Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, String);
		NewRow.RowIndex = Object.Goods.IndexOf(String);
	EndDo;
	Query = New Query();
	Query.Text =
		"SELECT
		|	String.RowIndex AS RowIndex,
		|	String.InitialAssignment AS InitialAssignment,
		|	String.NewAssignment AS NewAssignment
		|INTO Rows
		|FROM
		|	&Rows AS String
		|;
		|SELECT
		|	String.RowIndex AS RowIndex,
		|	ISNULL(TableInitialAssignment.OrderDocument, UNDEFINED) AS SourceOrder,
		|	ISNULL(TableNewAssignment.OrderDocument, UNDEFINED) AS NewOrder
		|FROM
		|	Rows AS String
		|		LEFT JOIN Catalog.Assignments AS TableInitialAssignment
		|		ON TableInitialAssignment.Ref = String.InitialAssignment
		|		LEFT JOIN Catalog.Assignments AS TableNewAssignment
		|		ON TableNewAssignment.Ref = String.NewAssignment";
	Query.SetParameter("Rows", Table);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		String = Object.Goods[Selection.RowIndex];
		FillPropertyValues(String, Selection, "SourceOrder,NewOrder");
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function AppointmentsWithoutOrderAreAllowed() Export
	
	AppointmentsWithoutOrderAreAllowed = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	AppointmentsWithoutOrderAreAllowed = AppointmentsWithoutOrderAreAllowed
		Or GetFunctionalOption("UseProductionByThirdParty2_5");
	AppointmentsWithoutOrderAreAllowed = AppointmentsWithoutOrderAreAllowed
		Or GetFunctionalOption("UseTollManufacturing2_5");
	Return AppointmentsWithoutOrderAreAllowed;
	
EndFunction

Function CreateAdjustmentToDestinationOfGoodsBasedOnCustomerSOrderCheckingDestinationType(BasisObject) Export
	
	CheckResult = New Structure("ErrorText", Undefined);
	
	If TypeOf(BasisObject) = Type("DocumentRef.SalesOrder") Then
		
		Purpose = Documents.InventoryAssignmentAdjustment.OrderAssignment(BasisObject);
		
		If ValueIsFilled(Purpose) Then
			
			AssignmentTypeOfAssignment = Common.ObjectAttributeValue(Purpose, "AssignmentType");
			
			If AssignmentTypeOfAssignment = Enums.AssignmentTypes.DeliveryForPrincipal Then
			
				CheckResult.ErrorText = NStr("vi = 'Không có điều chỉnh có sẵn cho loại điểm đến này. Cần làm lại các chứng từ gốc.';
											|ru = 'Для данного типа назначения корректировка недоступна. Необходимо переделать исходные документы.';
											|en = 'No adjustment is available for this type of assignment. It is necessary to rework the source documents.'; fa = 'No adjustment is available for this type of assignment. It is necessary to rework the source documents.';
											|it = 'Per questo tipo di destinazione la modifica non è disponibile. Devono essere modificati i documenti di riferimento.';
											|pl = 'Dla danego typu przeznaczenia poprawa jest niedostępna. Należy przerobić źródłowe dokumenty.';
											|tr = 'Bu atama türü için herhangi bir düzenleme mevcut değil. Orijinal belgeleri yeniden yapmak gerekir.'");
			
			EndIf;
			
		EndIf;
				
	EndIf;
	
	Return CheckResult;

EndFunction

#EndRegion

#Region StandardSubsystems
// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

#EndRegion

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.InventoryAssignmentAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Ref", 			   Attributes.Ref); // It is intended for use in the procedure of initializing the types of reserves
	Query.SetParameter("Period", 			   Attributes.Period);
	Query.SetParameter("DeletionMark", 	   Attributes.DeletionMark);
	Query.SetParameter("Number", 				   Attributes.Number);
	Query.SetParameter("Posted", 			   Attributes.Posted);
	Query.SetParameter("Comment", 		   Attributes.Comment);
	Query.SetParameter("Organization", 		   Attributes.Organization);
	Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.GoodsAssignmentAdjustments);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting",         ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.GoodsAssignmentAdjustments);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	Keys.Purpose           AS Purpose,
	|	Keys.Series                AS Series,
	|	Keys.StorageLocation        AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		Goods.ItemsLocationAttributes.Products         AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		&EmptyAssignment          AS Purpose,
	|		Goods.ItemsLocationAttributes.Series                AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation        AS StorageLocation
	|	FROM
	|		Document.InventoryAssignmentAdjustment.InventoryKinds AS Goods
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	) AS Keys
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Keys.Products      = Dimension.Products
	|		AND Keys.Characteristic = Dimension.Characteristic
	|		AND Keys.Series          = Dimension.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		AND Keys.StorageLocation = Dimension.StorageLocation
	|		AND Keys.Purpose = Dimension.Purpose
	|WHERE
	|	Dimension.Products IS NULL
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = 
	"SELECT
	|	CASE WHEN ISNULL(TypesOfOwnerStocks.Organization, ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Organization, VALUE(Catalog.Companies.EmptyRef))) <> VALUE(Catalog.Companies.EmptyRef) THEN
	|				ISNULL(TypesOfOwnerStocks.Organization, TableTypesOfStocks_.InventoryOwnerAttribute.Organization)
	|			ELSE
	|				&Organization
	|		END                                                   AS Organization,
	|	TableTypesOfStocks_.LineNumber								AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products										AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic									AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series												AS Series,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom	AS ShopFloorStockroom,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose										AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Purpose AS NewAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributes				AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey						AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt	AS ItemsLocationAttributesReceipt,
	|	AnalyticsWithoutAssignment.DimensionKey						AS ProductAccountingAnalyticsUnassignedRegistration,
	|	ISNULL(TypesOfOwnerStocks.Ref, TableTypesOfStocks_.InventoryOwnerAttribute)	AS InventoryOwnerAttribute,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN ISNULL(TypesOfOwnerStocks.Ref, TableTypesOfStocks_.InventoryOwnerAttribute.Ref)
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt
	|	END														AS InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.CCDNumber									AS CCDNumber,
	|	TableTypesOfStocks_.Count								AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN							AS QuantityByGBRN,
	|	TableTypesOfStocks_.RowID                      AS RowID
	|INTO TTTypesOfStocks
	|FROM
	|	Document.InventoryAssignmentAdjustment.InventoryKinds AS TableTypesOfStocks_
	|
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|	ON TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	1												AS Order,
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	&Period											AS Period,
	|	VALUE(AccumulationRecordType.Expense)			AS RecordType,
	|	TableTypesOfStocks_.Organization					AS Organization,
	|	TableTypesOfStocks_.Organization					AS ShipmentCompany,
	|	TableTypesOfStocks_.Products					AS Products,
	|	TableTypesOfStocks_.Characteristic				AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	&BusinessOperation							AS BusinessOperation,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt		AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS CorItemsLocationAttributes
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	2												AS Order,
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	&Period											AS Period,
	|	VALUE(AccumulationRecordType.Receipt)			AS RecordType,
	|	TableTypesOfStocks_.Organization					AS Organization,
	|	UNDEFINED									AS ShipmentCompany,
	|	TableTypesOfStocks_.Products					AS Products,
	|	TableTypesOfStocks_.Characteristic				AS Characteristic,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributes,
	|	&BusinessOperation							AS BusinessOperation,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS CorItemsLocationAttributes
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|ORDER BY
	|	LineNumber,
	|	Order";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	&Period										AS DateOfReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products				AS Products,
	|	TableTypesOfStocks_.Characteristic			AS Characteristic,
	|	TableTypesOfStocks_.Series					AS Series,
	|	TableTypesOfStocks_.NewAssignment			AS Purpose,
	|	TableTypesOfStocks_.CCDNumber					AS CCDNumber
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND TableTypesOfStocks_.Products = UninvoicedReceipts.Products
	|			AND TableTypesOfStocks_.Characteristic = UninvoicedReceipts.Characteristic
	|			AND TableTypesOfStocks_.Series = UninvoicedReceipts.Series
	|			AND TableTypesOfStocks_.NewAssignment = UninvoicedReceipts.Purpose
	|			AND TableTypesOfStocks_.CCDNumber = UninvoicedReceipts.CCDNumber
	|
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period)
	|
	|ORDER BY
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.Products,
	|	TableTypesOfStocks_.Characteristic,
	|	TableTypesOfStocks_.Series,
	|	TableTypesOfStocks_.NewAssignment,
	|	TableTypesOfStocks_.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableProductStock(Query, QueryTexts, Registers)
	
	RegisterName = "ProductStock";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Premise AS Premise,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.Count AS InStock,
	|	GoodsTable.InitialAssignment AS InitialAssignment,
	|	GoodsTable.NewAssignment AS NewAssignment
	|INTO GoodsTable
	|FROM
	|	Document.InventoryAssignmentAdjustment.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|	OR ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	GoodsTable.Period AS Period,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Premise AS Premise,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.InStock AS InStock,
	|	CASE
	|		WHEN ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.NewAssignment
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	FALSE AS ToControlBalance
	|FROM
	|	GoodsTable AS GoodsTable
	|WHERE
	|	ISNULL(GoodsTable.Package.PackageType,
	|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	GoodsTable.Period,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.InStock,
	|	CASE
	|		WHEN ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.InitialAssignment
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	TRUE
	|FROM
	|	GoodsTable AS GoodsTable
	|WHERE
	|	ISNULL(GoodsTable.Package.PackageType,
	|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	Subquery.Period,
	|	Subquery.Warehouse,
	|	Subquery.Premise,
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Series,
	|	Subquery.ControlledLotReference,
	|	MIN(Subquery.InStock),
	|	Subquery.Purpose,
	|	FALSE
	|FROM
	|	(SELECT
	|		GoodsTable.Period AS Period,
	|		GoodsTable.Warehouse AS Warehouse,
	|		GoodsTable.Premise AS Premise,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		GoodsTable.Series AS Series,
	|		GoodsTable.ControlledLotReference AS ControlledLotReference,
	|		SUM(GoodsTable.InStock) AS InStock,
	|		CASE
	|			WHEN ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|				THEN GoodsTable.NewAssignment
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END AS Purpose
	|	FROM
	|		GoodsTable AS GoodsTable
	|	WHERE
	|		GoodsTable.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	GROUP BY
	|		GoodsTable.Period,
	|		GoodsTable.Warehouse,
	|		GoodsTable.Premise,
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Package,
	|		GoodsTable.Series,
	|		GoodsTable.ControlledLotReference,
	|		CASE
	|			WHEN ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|				THEN GoodsTable.NewAssignment
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END) AS Subquery
	|GROUP BY
	|	Subquery.Period,
	|	Subquery.Warehouse,
	|	Subquery.Premise,
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Series,
	|	Subquery.ControlledLotReference,
	|	Subquery.Purpose,
	|	VALUE(AccumulationRecordType.Receipt)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	Subquery.Period,
	|	Subquery.Warehouse,
	|	Subquery.Premise,
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Series,
	|	Subquery.ControlledLotReference,
	|	MIN(Subquery.InStock),
	|	Subquery.Purpose,
	|	TRUE
	|FROM
	|	(SELECT
	|		GoodsTable.Period AS Period,
	|		GoodsTable.Warehouse AS Warehouse,
	|		GoodsTable.Premise AS Premise,
	|		GoodsTable.Products AS Products,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		GoodsTable.Series AS Series,
	|		GoodsTable.ControlledLotReference AS ControlledLotReference,
	|		SUM(GoodsTable.InStock) AS InStock,
	|		CASE
	|			WHEN ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE)
	|				THEN GoodsTable.InitialAssignment
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END AS Purpose
	|	FROM
	|		GoodsTable AS GoodsTable
	|	WHERE
	|		GoodsTable.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	GROUP BY
	|		GoodsTable.Period,
	|		GoodsTable.Warehouse,
	|		GoodsTable.Premise,
	|		GoodsTable.Products,
	|		GoodsTable.Characteristic,
	|		GoodsTable.Package,
	|		GoodsTable.Series,
	|		GoodsTable.ControlledLotReference,
	|		CASE
	|			WHEN ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE)
	|				THEN GoodsTable.InitialAssignment
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END) AS Subquery
	|GROUP BY
	|	Subquery.Period,
	|	Subquery.Warehouse,
	|	Subquery.Premise,
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Series,
	|	Subquery.ControlledLotReference,
	|	Subquery.Purpose,
	|	VALUE(AccumulationRecordType.Expense)";
	
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
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Cell AS Cell,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.NumberOfPackages
	|		ELSE GoodsTable.Count
	|	END AS InStock,
	|	CASE
	|		WHEN ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.NewAssignment
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose
	|FROM
	|	Document.InventoryAssignmentAdjustment.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|			OR ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE))
	|	AND CASE
	|			WHEN GoodsTable.Warehouse.UseWarerooms
	|					AND &Period >= GoodsTable.Warehouse.StartDateOfWareroomUse
	|				THEN CASE
	|						WHEN GoodsTable.Premise.UseBinLocationWarehousing
	|								AND &Period >= GoodsTable.Premise.StartDateOfUsingWarehouseBinSystem
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|			WHEN GoodsTable.Warehouse.UseBinLocationWarehousing
	|					AND &Period >= GoodsTable.Warehouse.StartDateOfUsingWarehouseBinSystem
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	GoodsTable.LineNumber,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Cell,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN GoodsTable.NumberOfPackages
	|		ELSE GoodsTable.Count
	|	END,
	|	CASE
	|		WHEN ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.InitialAssignment
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END 
	|FROM
	|	Document.InventoryAssignmentAdjustment.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (ISNULL(GoodsTable.NewAssignment.RecordsInWarehouseRegisters, FALSE)
	|			OR ISNULL(GoodsTable.InitialAssignment.RecordsInWarehouseRegisters, FALSE))
	|	AND CASE
	|			WHEN GoodsTable.Warehouse.UseWarerooms
	|					AND &Period >= GoodsTable.Warehouse.StartDateOfWareroomUse
	|				THEN CASE
	|						WHEN GoodsTable.Premise.UseBinLocationWarehousing
	|								AND &Period >= GoodsTable.Premise.StartDateOfUsingWarehouseBinSystem
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|			WHEN GoodsTable.Warehouse.UseBinLocationWarehousing
	|					AND &Period >= GoodsTable.Warehouse.StartDateOfUsingWarehouseBinSystem
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	
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
	
	QueryText =
	"SELECT
	|	&Period											AS Period,
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	ISNULL(TableTypesOfStocks_.Organization, &Organization)	AS Organization,
	|	&BusinessOperation							AS BusinessOperation,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.Department					AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END											AS ItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END											AS LineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation	AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType					AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributesReceipt
	|		ELSE TableTypesOfStocks_.ProductAccountingAnalyticsUnassignedRegistration
	|	END											AS CorItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.ItemsLocationAttributesReceipt.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END											AS CorLineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation									AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt.InventoryType		AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt		AS CorInventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.Count					AS CorQuantity,
	|
	|	0												AS Cost,
	|	0												AS CostExcludingVAT,
	|	0												AS LocalCost,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS SourceOfProductFinancialAccountingGroup,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt		AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)";
	
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
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS BusinessOperation,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS Counterparty,
	|	UNDEFINED                            AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	UNDEFINED                            AS StorageLocation,
	|	UNDEFINED                            AS Department,
	|	UNDEFINED                            AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	UNDEFINED                            AS Currency,
	|	UNDEFINED                            AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTemporaryTableOfGoods_ =
	"SELECT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.Ref.Date AS Period,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.InitialAssignment AS InitialAssignment,
	|	TableOfGoods.ControlledLotReference AS ControlledLotReference,
	|	TableOfGoods.SubjectToUnlocking AS SubjectToUnlocking,
	|	TableOfGoods.QualityConfirmationDate AS QualityConfirmationDate,
	|	TableOfGoods.NewAssignment AS NewAssignment,
	|	TableOfGoods.Count AS Count
	|INTO TableOfGoods
	|FROM
	|	Document.InventoryAssignmentAdjustment.Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Ref
	|	AND ISNULL(TableOfGoods.Package.PackageType,
	|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Subquery.Ref,
	|	Subquery.Ref.Date,
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Warehouse,
	|	Subquery.InitialAssignment,
	|	Subquery.ControlledLotReference AS ControlledLotReference,
	|	Subquery.SubjectToUnlocking AS SubjectToUnlocking,
	|	Subquery.QualityConfirmationDate AS QualityConfirmationDate,
	|	Subquery.NewAssignment,
	|	MIN(Subquery.Count)
	|FROM
	|	(SELECT
	|		TableOfProductLocations.Ref AS Ref,
	|		TableOfProductLocations.Products AS Products,
	|		TableOfProductLocations.Characteristic AS Characteristic,
	|		TableOfProductLocations.Package AS Package,
	|		TableOfProductLocations.Warehouse AS Warehouse,
	|		TableOfProductLocations.InitialAssignment AS InitialAssignment,
	|		TableOfProductLocations.ControlledLotReference AS ControlledLotReference,
	|		TableOfProductLocations.SubjectToUnlocking AS SubjectToUnlocking,
	|		TableOfProductLocations.QualityConfirmationDate AS QualityConfirmationDate,
	|		TableOfProductLocations.NewAssignment AS NewAssignment,
	|		SUM(TableOfProductLocations.Count) AS Count
	|	FROM
	|		Document.InventoryAssignmentAdjustment.Goods AS TableOfProductLocations
	|	WHERE
	|		TableOfProductLocations.Ref = &Ref
	|		AND TableOfProductLocations.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	GROUP BY
	|		TableOfProductLocations.Ref,
	|		TableOfProductLocations.Products,
	|		TableOfProductLocations.Characteristic,
	|		TableOfProductLocations.Package,
	|		TableOfProductLocations.Warehouse,
	|		TableOfProductLocations.InitialAssignment,
	|		TableOfProductLocations.ControlledLotReference,
	|		TableOfProductLocations.SubjectToUnlocking,
	|		TableOfProductLocations.QualityConfirmationDate,
	|		TableOfProductLocations.NewAssignment) AS Subquery
	|GROUP BY
	|	Subquery.Ref,
	|	Subquery.Ref.Date,
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Warehouse,
	|	Subquery.InitialAssignment,
	|	Subquery.ControlledLotReference,
	|	Subquery.SubjectToUnlocking,
	|	Subquery.QualityConfirmationDate,
	|	Subquery.NewAssignment";
	
	QueryTexts.Add(QueryTextTemporaryTableOfGoods_);

	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Period AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Warehouse AS Warehouse,
	|	TabPart.InitialAssignment AS Purpose,
	|	TabPart.ControlledLotReference AS ControlledLotReference,
	|	TabPart.Count AS Count,
	|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
	|	TRUE AS ControlOfFreeResidue
	|FROM
	|	TableOfGoods AS TabPart";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Period AS Period,
	|	TabPart.Products AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Warehouse AS Warehouse,
	|	TabPart.NewAssignment AS Purpose,
	|	TabPart.ControlledLotReference AS ControlledLotReference,
	|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
	|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule
	|FROM
	|	TableOfGoods AS TabPart";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
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
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	ISNULL(TableTypesOfStocks_.Organization,
	|		DocumentTable.Organization) 								AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	 				AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					 				AS InventoryOwnerAttribute,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN ISNULL(TableTypesOfStocks_.NewAssignment.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef))
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END 															AS VATActivityType,
	|	ISNULL(TableTypesOfStocks_.NewAssignment.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)) AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                            		AS CorCompany,
	|	UNDEFINED 									   				AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt 		AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt             			AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.Department	AS Department,
	|	UNDEFINED						AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsAssignmentAdjustments) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										 AS FinRecordID,
	|	&BusinessTransactionSetting												 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.InventoryAssignmentAdjustment AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (&KeepRecordsOfInventoryCostByAssignments
	|		OR TableTypesOfStocks_.InventoryOwnerAttribute <> TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt)
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

#Region FillingInTablePart

#Region FillingByBalances

Function QueryTextDataSource(ThereIsAppointmentInSelectionMatrix)
	
	QueryText =
		"SELECT
		|	*
		|INTO InventoryAndNeedsStorno
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS BalanceTable
		|WHERE
		|	BalanceTable.Active
		|		AND BalanceTable.Warehouse REFS Catalog.Warehouses
		|		AND BalanceTable.Recorder = &Recorder
		|		AND BalanceTable.Purpose IN(
		|			SELECT
		|				Filter.Purpose AS Purpose
		|			FROM
		|				SelectionOfAppointments_ AS Filter)
		|		AND (&AllGoods
		|				OR (BalanceTable.Products, BalanceTable.Characteristic, &ResidualTableAssignmentField)
		|						IN(
		|							SELECT
		|								Filter.Products AS Products,
		|								Filter.Characteristic AS Characteristic,
		|								&SelectionAssignmentField
		|							FROM
		|								FilterOfProducts_ AS Filter))
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT
		|	BalanceTable.Products AS Products,
		|	BalanceTable.Characteristic AS Characteristic,
		|	BalanceTable.Warehouse AS Warehouse,
		|	BalanceTable.Purpose AS Purpose,
		|	BalanceTable.OrderDocument AS OrderDocument,
		|	BalanceTable.LockedInStockBalance AS LockedInStockBalance,
		|	BalanceTable.LockedReceiptBalance AS LockedReceiptBalance,
		|	BalanceTable.ToUnlockBalance AS ToUnlockBalance,
		|	BalanceTable.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	BalanceTable.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Warehouse REFS Catalog.Warehouses
		|			AND Purpose IN(
		|				SELECT
		|					Filter.Purpose AS Purpose
		|				FROM
		|					SelectionOfAppointments_ AS Filter)
		|			AND (&AllGoods
		|					OR (Products, Characteristic, &VirtualTableParameterAssignmentField)
		|							IN(
		|								SELECT
		|									Filter.Products AS Products,
		|									Filter.Characteristic AS Characteristic,
		|									&SelectionAssignmentField
		|								FROM
		|									FilterOfProducts_ AS Filter))) AS BalanceTable
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT
		|	BalanceTable.Products AS Products,
		|	BalanceTable.Characteristic AS Characteristic,
		|	BalanceTable.Warehouse AS Warehouse,
		|	BalanceTable.Purpose AS Purpose,
		|	BalanceTable.InStockBalance AS InStockBalance,
		|	BalanceTable.LockedInStockBalance AS LockedInStockBalance,
		|	BalanceTable.OrderedBalance AS OrderedBalance,
		|	BalanceTable.Received_1Balance AS Received_1Balance,
		|	BalanceTable.LockedReceiptBalance AS LockedReceiptBalance,
		|	BalanceTable.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	BalanceTable.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	BalanceTable.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	BalanceTable.ToSupplyBalance AS ToSupplyBalance,
		|	BalanceTable.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		Warehouse REFS Catalog.Warehouses
		|			AND Purpose IN(
		|				SELECT
		|					Filter.Purpose AS Purpose
		|				FROM
		|					SelectionOfAppointments_ AS Filter)
		|			AND (&AllGoods
		|					OR (Products, Characteristic, &VirtualTableParameterAssignmentField)
		|							IN(
		|								SELECT
		|									Filter.Products AS Products,
		|									Filter.Characteristic AS Characteristic,
		|									&SelectionAssignmentField
		|								FROM
		|									FilterOfProducts_ AS Filter))) AS BalanceTable
		|;
		|
		|/////////////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	SUM(Set.Inventory) AS Inventory,
		|	SUM(Set.Reserve) AS Reserve,
		|	SUM(Set.Supplied) AS Supplied,
		|	SUM(Set.Demand) AS Demand,
		|	SUM(Set.UnderControl) AS UnderControl
		|INTO DataSource
		|FROM(
		|	SELECT
		|		CASE
		|			WHEN &CollapseAssignments
		|				THEN UNDEFINED
		|			ELSE Calculation.Purpose
		|		END AS Purpose,
		|		Calculation.Products AS Products,
		|		Calculation.Characteristic AS Characteristic,
		|		Calculation.Warehouse AS Warehouse,
		|		Calculation.InStock
		|			+ Calculation.AvailableWithLock AS Inventory,
		|		Calculation.Available_Reserve
		|			+ Calculation.Available_ReserveAsNeeded
		|			+ Calculation.AvailableWithLock_ReserveAsNeeded
		|			+ Calculation.AvailableWithLock_Reserve_FromBlocked
		|			+ Calculation.AvailableWithLock_ReserveAsNeeded_FromBlocked AS Reserve,
		|		Calculation.InStock
		|			+ Calculation.AvailableWithLock
		|			+ Calculation.Expected_
		|			+ Calculation.ExpectedWithBlocking
		|			+ Calculation.AwaitingApproval AS Supplied,
		|		Calculation.ToReserve_
		|			+ Calculation.ToReserveAsNeeded
		|			+ Calculation.Snooze
		|			+ Calculation.ToSupply
		|			+ Calculation.AvailableWithLock_Reserve_FromBlocked
		|			+ Calculation.AvailableWithLock_ReserveAsNeeded_FromBlocked AS Demand,
		|		Calculation.AvailableWithLock_Surplus
		|			+ Calculation.AvailableWithLock_Postpone
		|			+ Calculation.AvailableWithLock_CSupply AS UnderControl
		|	FROM
		|		SubstitutionCalculationOfReserves AS Calculation
		
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CASE
		|			WHEN &CollapseAssignments
		|				THEN UNDEFINED
		|			ELSE BalanceTable.Purpose
		|		END AS Purpose,
		|		BalanceTable.Products AS Products,
		|		BalanceTable.Characteristic AS Characteristic,
		|		BalanceTable.Warehouse AS Warehouse,
		|		0 AS Inventory,
		|		0 AS Reserve,
		|		0 AS Supplied,
		|		BalanceTable.ToSupply - BalanceTable.Replaced AS Demand,
		|		0 AS UnderControl
		|	FROM
		|		InformationRegister.OrderStructure AS BalanceTable
		|	WHERE
		|		BalanceTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|			AND BalanceTable.Purpose IN(
		|				SELECT
		|					Filter.Purpose AS Purpose
		|				FROM
		|					SelectionOfAppointments_ AS Filter)
		|			AND (&AllGoods
		|					OR (BalanceTable.Products, BalanceTable.Characteristic, &ResidualTableAssignmentField)
		|						IN(
		|							SELECT
		|								Filter.Products AS Products,
		|								Filter.Characteristic AS Characteristic,
		|								&SelectionAssignmentField
		|							FROM
		|								FilterOfProducts_ AS Filter))
		|									AND BalanceTable.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|									AND BalanceTable.ConnectionKeyTransfer = &EmptyLinkKey
		
		|) AS Set
		|GROUP BY
		|	Set.Purpose,
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse
		|;
		|DROP InventoryAndNeedsStorno;
		|DROP InventoryAndNeedsBalanceOfControlledLotsReference;
		|DROP InventoryAndDemandsBalance";
		
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.ReversingEntry = "InventoryAndNeedsStorno"; // @query-part-1
	TablesNames.Result = "SubstitutionCalculationOfReserves"; // @query-part-1
	ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames);
	
	VirtualTableParameterAssignmentField = "VALUE(Catalog.Assignments.EmptyRef)";
	ResidualTableAssignmentField = "VALUE(Catalog.Assignments.EmptyRef)";
	SelectionAssignmentField = "VALUE(Catalog.Assignments.EmptyRef)";
	If ThereIsAppointmentInSelectionMatrix Then
		ResidualTableAssignmentField = "BalanceTable.Purpose";
		VirtualTableParameterAssignmentField = "Purpose";
		SelectionAssignmentField = "Filter.Purpose";
	EndIf;
	QueryText = StrReplace(QueryText, "&VirtualTableParameterAssignmentField", VirtualTableParameterAssignmentField);
	QueryText = StrReplace(QueryText, "&ResidualTableAssignmentField", ResidualTableAssignmentField);
	QueryText = StrReplace(QueryText, "&SelectionAssignmentField", SelectionAssignmentField);
	Return QueryText;
	
EndFunction

Function QueryTextAvailableStock(ToGet, Assignments, TableNameResult)
	
	If Not ToGet Then
		
		QueryText =
			"SELECT
			|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
			|	VALUE(Catalog.Products.EmptyRef) AS Products,
			|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
			|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
			|	0 AS Demand,
			|	0 AS Inventory,
			|	0 AS Reserve,
			|	0 AS AvailableForInventoryAllocation,
			|	0 AS UnderControl
			|INTO TableNameOverridable
			|WHERE
			|	FALSE";
		QueryText = StrReplace(QueryText, "TableNameOverridable", TableNameResult); // @query-part-1
		Return QueryText;
		
	EndIf;
	
	QueryText =
		"SELECT ALLOWED
		|	*
		|INTO InventoryAndNeedsStorno
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS DocumentRegisterRecords
		|WHERE
		|	(DocumentRegisterRecords.Products, DocumentRegisterRecords.Characteristic) IN(
		|		SELECT
		|			FilterOfProducts_.Products AS Products,
		|			FilterOfProducts_.Characteristic AS Characteristic
		|		FROM
		|			SelectingDataSourceProducts AS FilterOfProducts_)
		|	AND DocumentRegisterRecords.Active
		|	AND DocumentRegisterRecords.Purpose IN (&AssignmentsOverridable)
		|	AND DocumentRegisterRecords.Recorder = &Recorder
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.OrderDocument AS OrderDocument,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ToUnlockBalance AS ToUnlockBalance,
		|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
		|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
		|INTO InventoryAndNeedsBalanceOfControlledLotsReference
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic) IN(
		|			SELECT
		|				FilterOfProducts_.Products AS Products,
		|				FilterOfProducts_.Characteristic AS Characteristic
		|			FROM
		|				SelectingDataSourceProducts AS FilterOfProducts_)
		|		AND Purpose IN (&AssignmentsOverridable)) AS Inventories
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic) IN(
		|			SELECT
		|				FilterOfProducts_.Products AS Products,
		|				FilterOfProducts_.Characteristic AS Characteristic
		|			FROM
		|				SelectingDataSourceProducts AS FilterOfProducts_)
		|		AND Purpose IN (&AssignmentsOverridable)) AS Inventories
		|;
		|
		|/////////////////////////////////////////////////////////
		|SELECT
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	Set.Purpose AS Purpose,
		|	SUM(Set.Demand) AS Demand,
		|	SUM(Set.Inventory) AS Inventory,
		|	SUM(Set.Reserve) AS Reserve,
		|	SUM(Set.AvailableForInventoryAllocation) AS AvailableForInventoryAllocation,
		|	SUM(Set.UnderControl) AS UnderControl
		|INTO TableNameOverridable
		|FROM(
		|	SELECT
		|		Calculation.Products AS Products,
		|		Calculation.Characteristic AS Characteristic,
		|		Calculation.Warehouse AS Warehouse,
		|		Calculation.Purpose AS Purpose,
		|		Calculation.ToReserve_
		|			+ Calculation.ToReserveAsNeeded
		|			+ Calculation.Snooze
		|			+ Calculation.ToSupply
		|			+ Calculation.AvailableWithLock_Reserve_FromBlocked
		|			+ Calculation.AvailableWithLock_ReserveAsNeeded_FromBlocked AS Demand,
		|		Calculation.InStock
		|			+ Calculation.AvailableWithLock AS Inventory,
		|		Calculation.Available_Reserve
		|			+ Calculation.Available_ReserveAsNeeded
		|			+ Calculation.AvailableWithLock_ReserveAsNeeded
		|			+ Calculation.AvailableWithLock_Reserve_FromBlocked
		|			+ Calculation.AvailableWithLock_ReserveAsNeeded_FromBlocked AS Reserve,
		|		Calculation.Available_Surplus
		|			+ Calculation.Available_Postpone
		|			+ Calculation.InStock_K
		|			+ Calculation.AvailableWithLock_Surplus
		|			+ Calculation.AvailableWithLock_Postpone
		|			+ Calculation.AvailableWithLock_CSupply AS AvailableForInventoryAllocation,
		|		Calculation.AvailableWithLock_Surplus
		|			+ Calculation.AvailableWithLock_Postpone
		|			+ Calculation.AvailableWithLock_CSupply AS UnderControl
		|	FROM
		|		SubstitutionCalculationOfReserves AS Calculation
		
		|
		|	UNION ALL
		|	
		|	SELECT
		|		TrafficOrderStructure.Products AS Products,
		|		TrafficOrderStructure.Characteristic AS Characteristic,
		|		TrafficOrderStructure.Warehouse AS Warehouse,
		|		TrafficOrderStructure.Purpose AS Purpose,
		|		TrafficOrderStructure.ToSupply - TrafficOrderStructure.Replaced AS Demand,
		|		0 AS Inventory,
		|		0 AS Reserve,
		|		0 AS AvailableForInventoryAllocation,
		|		0 AS UnderControl
		|	FROM
		|		InformationRegister.OrderStructure AS TrafficOrderStructure
		|	WHERE
		|		(TrafficOrderStructure.Products, TrafficOrderStructure.Characteristic) IN(
		|			SELECT
		|				FilterOfProducts_.Products   AS Products,
		|				FilterOfProducts_.Characteristic AS Characteristic
		|			FROM
		|				SelectingDataSourceProducts AS FilterOfProducts_)
		|		AND TrafficOrderStructure.Purpose IN (&AssignmentsOverridable)
		|		AND TrafficOrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|		AND TrafficOrderStructure.ConnectionKeyTransfer = &EmptyLinkKey
		|	
		|) AS Set
		|GROUP BY
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse,
		|	Set.Purpose
		|;
		|DROP InventoryAndNeedsStorno;
		|DROP InventoryAndNeedsBalanceOfControlledLotsReference;
		|DROP InventoryAndDemandsBalance";
		
		TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
		TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
		TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
		TablesNames.ReversingEntry = "InventoryAndNeedsStorno"; // @query-part-1
		TablesNames.Result = "SubstitutionCalculationOfReserves"; // @query-part-1
		ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames);
		
		QueryText = StrReplace(QueryText, "TableNameOverridable", TableNameResult); // @query-part-1
		QueryText = StrReplace(QueryText, "&AssignmentsOverridable", Assignments); // @query-part-1
		
	Return QueryText;
	
EndFunction

Function TemporaryTableMoveOrders(ThereIsAssignmentInTotalsTable)
	
	Text =
		"SELECT
		|	Table.Purpose AS Purpose,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	SUM(CASE WHEN Table.ToSupply > Table.Inventory THEN
		|				Table.Inventory
		|			ELSE
		|				Table.ToSupply
		|		END) AS Count
		|INTO TransferOrders
		|FROM(
		|	SELECT
		|		TableOfResults.OrderDocument AS OrderDocument,
		|		&StocksAndNeedsAssignmentSamplingOverridable AS Purpose,
		|		TableOfResults.Products AS Products,
		|		TableOfResults.Characteristic AS Characteristic,
		|		TableOfResults.ToSupplyBalance AS ToSupply,
		|		TableOfResults.OrderedBalance AS Inventory
		|	FROM
		|		AccumulationRegister.InventoryAndDemands.Balance(,
		|			(Products, Characteristic, &StocksAndNeedsPurposeOverridable) IN(
		|				SELECT
		|					TableOfResults.Products AS Products,
		|					TableOfResults.Characteristic AS Characteristic,
		|					&SummaryTableAssignmentOverridable AS Purpose
		|				FROM
		|					TableOfResults AS TableOfResults)
		|			AND (&ThereIsAssignmentInTotalsTableOverridable
		|				OR Purpose IN(
		|					SELECT
		|						SelectionOfAppointments_.Purpose AS Purpose
		|					FROM
		|						SelectionOfAppointments_ AS SelectionOfAppointments_))) AS TableOfResults
		|	WHERE
		|		TableOfResults.ToSupplyBalance <> 0 AND TableOfResults.OrderedBalance <> 0
		|) Table
		|GROUP BY
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Purpose
		|INDEX BY
		|	Products, Characteristic, Purpose";
	StocksAndNeedsPurpose = "VALUE(Catalog.Assignments.EmptyRef)";
	StocksAndNeedsAssignmentSampling = "VALUE(Catalog.Assignments.EmptyRef)";
	SummaryTableAssignment = "VALUE(Catalog.Assignments.EmptyRef)";
	ThereIsAssignmentInTotalsTableOverridable = "FALSE";
	If ThereIsAssignmentInTotalsTable Then
		SummaryTableAssignment = "TableOfResults.AssignmentForTotals";
		ThereIsAssignmentInTotalsTableOverridable = "TRUE";
		StocksAndNeedsPurpose = "Purpose";
		StocksAndNeedsAssignmentSampling = "TableOfResults.Purpose";
	EndIf;
	
	Text = StrReplace(Text, "&StocksAndNeedsPurposeOverridable", StocksAndNeedsPurpose);
	Text = StrReplace(Text, "&SummaryTableAssignmentOverridable", SummaryTableAssignment);
	Text = StrReplace(Text, "&ThereIsAssignmentInTotalsTableOverridable", ThereIsAssignmentInTotalsTableOverridable);
	Text = StrReplace(Text, "&StocksAndNeedsAssignmentSamplingOverridable", StocksAndNeedsAssignmentSampling);
	
	Return Text;
	
EndFunction

#EndRegion

// Returns a table of products with balances detailed to the series, room, or cell.
//
// Parameters:
//
//  GoodsTable - ValueTable - table of values with columns:
//		* InitialAssignment		 - CatalogRef.Assignments - assignment corresponding to the Order column
//		* Products				 - CatalogRef.Products -
//		* Characteristic			 - CatalogRef.ItemsCharacteristics -
//		* Warehouse						 - CatalogRef.Warehouses - the warehouse where the product is currently located
//		* UsingSeries		 - Boolean - indication of the use of series,
//		* UseOfCellPremises- Boolean - indicates whether rooms or cells are being used,
//		* Inventory						 - Number - the Balance of the item in stock
//		* Reserve					 - Number - quantity of reserved goods
//		* UnderControl				 - Number - quantity of item that is not reserved but blocked
//		* Count				 - Number - The quantity of the goods whose purpose needs to be adjusted.
//  Ref - DocumentRef.InventoryAssignmentAdjustment - Will the balances for warehouses not specified in the order be placed in the resulting table
//  OnlyChecked - Boolean - whether the remaining balances for cells and rooms will be received for rows in the transmitted table
//                              that do not have the Mark flag set.
//
// Returns:
//   - ValueTable - table of values with columns:
//		* Purpose - CatalogRef.Assignments -
//		* Products - CatalogRef.Products -
//		* ProductsUnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
//		* Characteristic - CatalogRef.ItemsCharacteristics -
//		* Warehouse - CatalogRef.Warehouses - the warehouse where the product is currently located
//		* Premise - CatalogRef.Warerooms - Premise
//		* Cell - CatalogRef.StorageBins -
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure -
//		* Series - CatalogRef.ItemsBatches -
//		* Supplied - Number -
//		* AssigningTrafficToWarehouseRegisters - Boolean -
//		* SecuredUnits - Number -
//		* SeriesReadyForShipment - Number -
//		* ThereAreCells - Boolean -
//		* ThereAreSeries - Boolean -
//		* AvailableStock - Number -
//		* FreeBalanceUnderControl - Number -
//		* Count - Number -
//
Function TableOfCellPlacementByProduct(GoodsTable, Ref, OnlyChecked = True) Export
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	CAST(Tab.InitialAssignment AS Catalog.Assignments) AS Purpose,
	|	Tab.Products AS Products,
	|	Tab.Characteristic AS Characteristic,
	|	Tab.Warehouse AS Warehouse,
	|	Tab.UsingSeries AS UsingSeries,
	|	Tab.UseOfCellPremises AS UseOfCellPremises,
	|	Tab.Inventory - Tab.Reserve AS AvailableStock,
	|	Tab.UnderControl AS FreeBalanceUnderControl,
	|	Tab.Count AS Count
	|INTO TTOrderItems
	|FROM
	|	&GoodsTable AS Tab
	|INDEX BY
	|	Purpose, Products, Characteristic, Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 1) For warehouses and all the premises of these warehouses, a sign of address storage is determined
	// in order to understand where to get the leftovers from - either from goods in warehouses or from goods in cells.
	|SELECT
	|	Warehouses.Ref AS Warehouse,
	|	ISNULL(WarehousesAndPremises.Ref, VALUE(Catalog.Warerooms.EmptyRef)) AS Premise,
	|	CASE
	|		WHEN Warehouses.Ref.UseWarerooms
	|				AND &Date >= Warehouses.Ref.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN WarehousesAndPremises.Ref.UseBinLocationWarehousing
	|							AND &Date >= WarehousesAndPremises.Ref.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN Warehouses.Ref.UseBinLocationWarehousing
	|						AND &Date >= Warehouses.Ref.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS UseBinLocationWarehousing
	|INTO WarehousesAndPremises
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|		LEFT JOIN Catalog.Warerooms AS WarehousesAndPremises
	|		ON WarehousesAndPremises.Owner = Warehouses.Ref
	|		INNER JOIN TTOrderItems AS OrderWarehouses
	|		ON OrderWarehouses.Warehouse = Warehouses.Ref
	|INDEX BY
	|	Warehouse, Premise, UseBinLocationWarehousing
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 2) Selection tables for accessing data sources on balances.
	|SELECT DISTINCT
	|	AllAnalysts.DimensionKey AS ItemsLocationAttributes
	|INTO ProductsOfOrganizationsSelection
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS AllAnalysts
	|		INNER JOIN TTOrderItems AS Filter
	|		ON Filter.Purpose = AllAnalysts.Purpose
	|			AND Filter.Products = AllAnalysts.Products
	|			AND Filter.Characteristic = AllAnalysts.Characteristic
	|			AND Filter.Warehouse = AllAnalysts.StorageLocation
	|WHERE
	|	NOT Filter.Purpose.RecordsInWarehouseRegisters
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Purpose AS Purpose,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Cells.Ref AS Cell
	|INTO ProductsInSelectionCells
	|FROM
	|	TTOrderItems AS Table
	|		INNER JOIN Catalog.StorageBins AS Cells
	|		ON Cells.Owner = Table.Warehouse
	|		INNER JOIN WarehousesAndPremises AS WarehousesAndPremises
	|		ON WarehousesAndPremises.Premise = Cells.Premise
	|			AND WarehousesAndPremises.Warehouse = Cells.Owner
	|WHERE
	|	ISNULL(Table.Purpose.RecordsInWarehouseRegisters, TRUE)
	|		AND WarehousesAndPremises.UseBinLocationWarehousing
	|INDEX BY
	|	Purpose, Products, Characteristic, Cell
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Purpose AS Purpose,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Warehouse AS Warehouse,
	|	WarehousesAndPremises.Premise AS Premise
	|INTO GoodsInWarehousesSelection
	|FROM
	|	TTOrderItems AS Table
	|		INNER JOIN WarehousesAndPremises AS WarehousesAndPremises
	|		ON WarehousesAndPremises.Warehouse = Table.Warehouse
	|WHERE
	|	ISNULL(Table.Purpose.RecordsInWarehouseRegisters, TRUE)
	|		AND NOT WarehousesAndPremises.UseBinLocationWarehousing
	|INDEX BY
	|	Purpose, Products, Characteristic, Warehouse, Premise
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 3) Balances from sources, according to the selection tables.
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Balance.CountBalance AS InStock
	|INTO CompanyGoods
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(,
	|		ItemsLocationAttributes IN(
	|			SELECT
	|				Filter.ItemsLocationAttributes AS ItemsLocationAttributes
	|			FROM
	|				ProductsOfOrganizationsSelection AS Filter)) AS Balance
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterRecords.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -RegisterRecords.Count
	|		ELSE RegisterRecords.Count
	|	END AS InStock
	|FROM
	|	AccumulationRegister.CompanyGoods AS RegisterRecords
	|		INNER JOIN ProductsOfOrganizationsSelection AS Filter
	|		ON Filter.ItemsLocationAttributes = RegisterRecords.ItemsLocationAttributes
	|WHERE
	|	RegisterRecords.Recorder = &Recorder
	|		AND RegisterRecords.Active
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Purpose AS Purpose,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Cell AS Cell,
	|	Balance.Package AS Package,
	|	Balance.Series AS Series,
	|	Balance.InStockBalance - Balance.ForPickingBalance AS InStock
	|INTO GoodsInStorageBins
	|FROM
	|	AccumulationRegister.GoodsInStorageBins.Balance(,
	|			(Purpose, Products, Characteristic, Cell) IN(
	|				SELECT
	|					Filter.Purpose AS Purpose,
	|					Filter.Products AS Products,
	|					Filter.Characteristic AS Characteristic,
	|					Filter.Cell AS Cell
	|				FROM
	|					ProductsInSelectionCells AS Filter)) AS Balance
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterRecords.Purpose AS Purpose,
	|	RegisterRecords.Products AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.Cell AS Cell,
	|	RegisterRecords.Package AS Package,
	|	RegisterRecords.Series AS Series,
	|	CASE
	|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -RegisterRecords.InStock
	|		ELSE RegisterRecords.InStock
	|	END AS InStock
	|FROM
	|	AccumulationRegister.GoodsInStorageBins AS RegisterRecords
	|		INNER JOIN ProductsInSelectionCells AS Filter
	|		ON Filter.Purpose = RegisterRecords.Purpose
	|			AND Filter.Products = RegisterRecords.Products
	|			AND Filter.Characteristic = RegisterRecords.Characteristic
	|			AND Filter.Cell = RegisterRecords.Cell
	|WHERE
	|	RegisterRecords.Recorder = &Recorder
	|		AND RegisterRecords.Active
	|INDEX BY
	|	Cell
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Purpose AS Purpose,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Warehouse AS Warehouse,
	|	Balance.Premise AS Premise,
	|	Balance.Series AS Series,
	|	Balance.InStockBalance - Balance.ToShipBalance AS InStock,
	|	CASE
	|		WHEN Balance.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
	|			THEN 0
	|		ELSE Balance.InStockBalance - Balance.ToShipBalance
	|	END AS AvailableUnderControl
	|INTO ProductStock
	|FROM
	|	AccumulationRegister.ProductStock.Balance(,
	|			(Purpose, Products, Characteristic, Warehouse, Premise) IN(
	|				SELECT
	|					Filter.Purpose AS Purpose,
	|					Filter.Products AS Products,
	|					Filter.Characteristic AS Characteristic,
	|					Filter.Warehouse AS Warehouse,
	|					Filter.Premise AS Premise
	|				FROM
	|					GoodsInWarehousesSelection AS Filter)) AS Balance
	|
	|UNION ALL
	|
	|SELECT
	|	RegisterRecords.Purpose AS Purpose,
	|	RegisterRecords.Products AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.Warehouse AS Warehouse,
	|	RegisterRecords.Premise AS Premise,
	|	RegisterRecords.Series AS Series,
	|	CASE
	|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -RegisterRecords.InStock
	|		ELSE RegisterRecords.InStock
	|	END AS InStock,
	|	CASE
	|		WHEN RegisterRecords.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
	|			THEN 0
	|		WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -RegisterRecords.InStock
	|		ELSE RegisterRecords.InStock
	|	END AS AvailableUnderControl
	|FROM
	|	AccumulationRegister.ProductStock AS RegisterRecords
	|		INNER JOIN GoodsInWarehousesSelection AS Filter
	|		ON Filter.Purpose = RegisterRecords.Purpose
	|			AND Filter.Products = RegisterRecords.Products
	|			AND Filter.Characteristic = RegisterRecords.Characteristic
	|			AND Filter.Warehouse = RegisterRecords.Warehouse
	|			AND Filter.Premise = RegisterRecords.Premise
	|WHERE
	|	RegisterRecords.Recorder = &Recorder
	|		AND RegisterRecords.Active
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 3.1) Goods for shipment, to determine the series that are not available for shipment.
	|SELECT
	|	Balance.Purpose AS Purpose,
	|	Balance.Products AS Products,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Warehouse AS Warehouse,
	|	Balance.Series AS Series,
	|	SUM(Balance.InReserveBalance) AS InReserve,
	|	SUM(Balance.ToShipBalance) AS ToShip,
	|	SUM(CASE
	|		WHEN Balance.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
	|			THEN 0
	|		ELSE Balance.InReserveBalance
	|	END) AS InReserveUnderControl,
	|	SUM(CASE
	|		WHEN Balance.ControlledLotReference = VALUE(Catalog.ControlledLots.EmptyRef)
	|			THEN 0
	|		ELSE Balance.ToShipBalance
	|	END) AS ToBeShippedUnderControl 
	|INTO GoodsForIssue
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(,
	|			(Purpose, Products, Characteristic, Warehouse) IN(
	|				SELECT
	|					Filter.Purpose AS Purpose,
	|					Filter.Products AS Products,
	|					Filter.Characteristic AS Characteristic,
	|					Filter.Warehouse AS Warehouse
	|				FROM
	|					TTOrderItems AS Filter)
	|			AND Series <> VALUE(Catalog.ItemsBatches.EmptyRef)) AS Balance
	|GROUP BY
	|	Balance.Purpose,
	|	Balance.Products,
	|	Balance.Characteristic,
	|	Balance.Warehouse,
	|	Balance.Series
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 4) Combining tables of balances from different sources.
	|SELECT
	|	CompanyGoods.ItemsLocationAttributes.Purpose AS Purpose,
	|	CompanyGoods.ItemsLocationAttributes.Products AS Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
	|	VALUE(Catalog.StorageBins.EmptyRef) AS Cell,
	|	CompanyGoods.ItemsLocationAttributes.Products.UnitOfMeasure AS Package,
	|	CompanyGoods.ItemsLocationAttributes.Series AS Series,
	|	SUM(CompanyGoods.InStock) AS InStock,
	|	0 AS AvailableUnderControl,
	|	MAX(ISNULL(GoodsForIssue.InReserve, 0)) AS SeriesReadyForShipment,
	|	0 AS SeriesToBeShippedUnderControl
	|INTO Balance
	|FROM
	|	CompanyGoods AS CompanyGoods
	|		LEFT JOIN GoodsForIssue AS GoodsForIssue
	|		ON GoodsForIssue.Products = CompanyGoods.ItemsLocationAttributes.Products
	|		 AND GoodsForIssue.Characteristic = CompanyGoods.ItemsLocationAttributes.Characteristic
	|		 AND GoodsForIssue.Warehouse = CompanyGoods.ItemsLocationAttributes.StorageLocation
	|		 AND GoodsForIssue.Purpose = CompanyGoods.ItemsLocationAttributes.Purpose
	|		 AND GoodsForIssue.Series = CompanyGoods.ItemsLocationAttributes.Series
	|GROUP BY
	|	CompanyGoods.ItemsLocationAttributes.Purpose,
	|	CompanyGoods.ItemsLocationAttributes.Products,
	|	CompanyGoods.ItemsLocationAttributes.Characteristic,
	|	CompanyGoods.ItemsLocationAttributes.StorageLocation,
	|	CompanyGoods.ItemsLocationAttributes.Series
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsInStorageBins.Purpose AS Purpose,
	|	GoodsInStorageBins.Products AS Products,
	|	GoodsInStorageBins.Characteristic AS Characteristic,
	|	MAX(GoodsInStorageBins.Cell.Owner) AS Warehouse,
	|	MAX(GoodsInStorageBins.Cell.Premise) AS Premise,
	|	GoodsInStorageBins.Cell AS Cell,
	|	GoodsInStorageBins.Package AS Package,
	|	GoodsInStorageBins.Series AS Series,
	|	SUM(GoodsInStorageBins.InStock) AS InStock,
	|	0 AS AvailableUnderControl,
	|	MAX(ISNULL(GoodsForIssue.InReserve + GoodsForIssue.ToShip, 0)) AS SeriesReadyForShipment,
	|	0 AS SeriesToBeShippedUnderControl
	|FROM
	|	GoodsInStorageBins AS GoodsInStorageBins
	|		LEFT JOIN GoodsForIssue AS GoodsForIssue
	|		ON GoodsForIssue.Products = GoodsInStorageBins.Products
	|		 AND GoodsForIssue.Characteristic = GoodsInStorageBins.Characteristic
	|		 AND GoodsForIssue.Warehouse = GoodsInStorageBins.Cell.Owner
	|		 AND GoodsForIssue.Purpose = GoodsInStorageBins.Purpose
	|		 AND GoodsForIssue.Series = GoodsInStorageBins.Series
	|GROUP BY
	|	GoodsInStorageBins.Purpose,
	|	GoodsInStorageBins.Products,
	|	GoodsInStorageBins.Characteristic,
	|	GoodsInStorageBins.Cell,
	|	GoodsInStorageBins.Package,
	|	GoodsInStorageBins.Series
	|
	|UNION ALL
	|
	|SELECT
	|	ProductStock.Purpose AS Purpose,
	|	ProductStock.Products AS Products,
	|	ProductStock.Characteristic AS Characteristic,
	|	ProductStock.Warehouse AS Warehouse,
	|	ProductStock.Premise AS Premise,
	|	VALUE(Catalog.StorageBins.EmptyRef) AS Cell,
	|	ProductStock.Products.UnitOfMeasure AS Package,
	|	ProductStock.Series AS Series,
	|	SUM(ProductStock.InStock) AS InStock,
	|	SUM(ProductStock.AvailableUnderControl) AS AvailableUnderControl,
	|	MAX(ISNULL(GoodsForIssue.InReserve + GoodsForIssue.ToShip, 0)) AS SeriesReadyForShipment,
	|	MAX(ISNULL(GoodsForIssue.InReserveUnderControl + GoodsForIssue.ToBeShippedUnderControl, 0)) AS SeriesToBeShippedUnderControl
	|FROM
	|	ProductStock AS ProductStock
	|		LEFT JOIN GoodsForIssue AS GoodsForIssue
	|		ON GoodsForIssue.Products = ProductStock.Products
	|		 AND GoodsForIssue.Characteristic = ProductStock.Characteristic
	|		 AND GoodsForIssue.Warehouse = ProductStock.Warehouse
	|		 AND GoodsForIssue.Purpose = ProductStock.Purpose
	|		 AND GoodsForIssue.Series = ProductStock.Series
	|GROUP BY
	|	ProductStock.Purpose,
	|	ProductStock.Products,
	|	ProductStock.Characteristic,
	|	ProductStock.Warehouse,
	|	ProductStock.Premise,
	|	ProductStock.Series
	|INDEX BY
	|	Purpose, Products, Characteristic, Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 5) Addition of the result table with the necessary fields.
	|SELECT
	|	Balance.Purpose AS Purpose,
	|	Balance.Products AS Products,
	|	Balance.Products.UnitOfMeasure AS ProductsUnitOfMeasure,
	|	Balance.Characteristic AS Characteristic,
	|	Balance.Warehouse AS Warehouse,
	|	Balance.Premise AS Premise,
	|	Balance.Cell AS Cell,
	|	CASE
	|		WHEN Balance.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			THEN Balance.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END AS Package,
	|	Balance.Series AS Series,
	|	Balance.InStock AS Supplied,
	|	Balance.AvailableUnderControl AS ProvidedOnControl,
	|	ISNULL(Balance.Purpose.RecordsInWarehouseRegisters, FALSE) AS AssigningTrafficToWarehouseRegisters,
	|	Balance.InStock * ISNULL(&RequestTextForPackingCoefficient, 1) AS SecuredUnits,
	|	Balance.AvailableUnderControl * ISNULL(&RequestTextForPackingCoefficient, 1) AS SecuredUnitsUnderControl,
	|	Balance.SeriesReadyForShipment AS SeriesReadyForShipment,
	|	Balance.SeriesToBeShippedUnderControl AS SeriesToBeShippedUnderControl,
	|	Goods.UseOfCellPremises AS ThereAreCells,
	|	Goods.UsingSeries AS ThereAreSeries,
	|	Goods.AvailableStock AS AvailableStock,
	|	Goods.FreeBalanceUnderControl AS FreeBalanceUnderControl,
	|	Goods.Count AS Count
	|FROM
	|	Balance AS Balance
	|		INNER JOIN TTOrderItems AS Goods
	|		ON Goods.Purpose = Balance.Purpose
	|		 AND Goods.Products = Balance.Products
	|		 AND Goods.Characteristic = Balance.Characteristic
	|		 AND Goods.Warehouse = Balance.Warehouse
	|WHERE
	|	Balance.InStock > 0
	|		AND (Balance.Premise <> VALUE(Catalog.Warerooms.EmptyRef)
	|				OR Balance.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|				OR Balance.Cell <> VALUE(Catalog.StorageBins.EmptyRef))
	|ORDER BY
	|	Purpose,
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Series,
	|	Premise,
	|	Cell,
	|	Package";
	
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager();
	EndIf;
	
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("Date", CurrentSessionDate());
	If OnlyChecked Then
		Query.SetParameter("GoodsTable", GoodsTable.Copy(New Structure("Mark", True)));
	Else
		Query.SetParameter("GoodsTable", GoodsTable);
	EndIf;
	
	RequestTextForPackingCoefficient = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Balance.Package","Balance.Products");
	Query.Text = StrReplace(Query.Text, "&RequestTextForPackingCoefficient", RequestTextForPackingCoefficient);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	Return Result;
	
EndFunction

Procedure MergeTablesByWarehouseAndPremises(TableOfWarehousesInGeneral, CellRoomTable)
	
	CellRoomTable.Columns.Add("KeyProductLocations", New TypeDescription("UUID"));
	CargoPackagingTable = CellRoomTable.CopyColumns();
	ListOfItems = CellRoomTable.UnloadColumn("Products");
	ProductLocations = ProductLocationsAccordingToItemList(ListOfItems);
	CellRoomTable.Columns.Add("Ignore", New TypeDescription("Boolean"));
	
	If ProductLocations.Count() > 0 Then
		
		GroupingKey = New Structure("Purpose,Products,Characteristic,Warehouse,Series,Premise");
		KeyProductLocations = Undefined;
		
		// Transfer of items to a separate table.
		For IndexOf = 0 To CellRoomTable.Count() - 1 Do
			
			TableRow = CellRoomTable[IndexOf];
			TableRow.Ignore = False;
			
			Packages = ProductLocations[TableRow.Products];
			If Packages <> Undefined And Packages[TableRow.Package] <> Undefined Then
				
				If GroupingKey.Purpose <> TableRow.Purpose
						Or GroupingKey.Products <> TableRow.Products
						Or GroupingKey.Characteristic <> TableRow.Characteristic
						Or GroupingKey.Warehouse <> TableRow.Warehouse
						Or GroupingKey.Series <> TableRow.Series
						Or GroupingKey.Premise <> TableRow.Premise Then
						
						FillPropertyValues(GroupingKey, TableRow);
						KeyProductLocations = New UUID();
						
				Else
					
					TableRow.Ignore = True;
					
				EndIf;
				
				TableRow.KeyProductLocations = KeyProductLocations;
				NewRow = CargoPackagingTable.Add();
				FillPropertyValues(NewRow, TableRow);
				
			EndIf;
			
		EndDo;
		
		TableWithoutProductLocations = CellRoomTable.Copy(New Structure("Ignore", False));
		CargoPackagingTable.Indexes.Add("KeyProductLocations,Package");
		
		// Determination of the number of sets for product locations.
		For IndexOf = 0 To TableWithoutProductLocations.Count() - 1 Do
			
			TableRow = TableWithoutProductLocations[IndexOf];
			Packages = ProductLocations[TableRow.Products];
			If Packages <> Undefined And Packages[TableRow.Package] <> Undefined Then
				
				KitCount = TableRow.SecuredUnits;
				For Each Package In Packages Do
					FoundRows = CargoPackagingTable.FindRows(
						New Structure("KeyProductLocations,Package", TableRow.KeyProductLocations, Package.Key));
					If FoundRows.Count() > 0 Then
						KitCount = Min(KitCount, FoundRows[0].SecuredUnits);
					Else
						KitCount = 0;
					EndIf;
				EndDo;
				TableRow.SecuredUnits = KitCount;
				
			EndIf;
			
		EndDo;
		
	Else
		
		TableWithoutProductLocations = CellRoomTable;
		
	EndIf;
	
	KeyAssignment = Undefined;
	KeyProducts = Undefined;
	KeyCharacteristic = Undefined;
	KeyWarehouse = Undefined;
	Key_Series = Undefined;
	SeriesReadyForShipment = 0;
	TotalRows = TableWithoutProductLocations.Count();
	For Counter = 1 To TotalRows Do
		TableRow = TableWithoutProductLocations[TotalRows - Counter];
		If KeyAssignment <> TableRow.Purpose
				Or KeyProducts <> TableRow.Purpose
				Or KeyCharacteristic <> TableRow.Characteristic
				Or KeyWarehouse <> TableRow.Warehouse
				Or Key_Series <> TableRow.Series Then
					SeriesReadyForShipment = TableRow.SeriesReadyForShipment;
		EndIf;
		Allocate = Min(SeriesReadyForShipment, TableRow.SecuredUnits);
		TableRow.SecuredUnits = TableRow.SecuredUnits - Allocate;
		SeriesReadyForShipment = SeriesReadyForShipment - Allocate;
		
	EndDo;
	
	TheStructureOfTheSearch = New Structure("Purpose,Products,Characteristic,Warehouse");
	
	LinesToDelete = New Array();
	
	For RowIndex = 0 To TableOfWarehousesInGeneral.Count() - 1 Do
		
		String = TableOfWarehousesInGeneral[RowIndex];
		
		FillPropertyValues(TheStructureOfTheSearch, String);
		TheStructureOfTheSearch.Purpose = String.InitialAssignment;
		
		FoundRows = TableWithoutProductLocations.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() > 0 Then
			
			CountBalance = String.Count;
			
			For Each FoundRow In FoundRows Do
				
				If FoundRow.SecuredUnits = 0 Then
					Continue; // One of the components of the goods place is missing.
				EndIf;
				
				Count = 0;
				If FoundRow.SecuredUnits > CountBalance Then
					Count = CountBalance;
					CountBalance = 0;
				Else
					Count = FoundRow.SecuredUnits;
					CountBalance = CountBalance - FoundRow.SecuredUnits;
				EndIf;
				
				Packages = ProductLocations[FoundRow.Products];
				If Packages <> Undefined And Packages[FoundRow.Package] <> Undefined Then
					
					// Adding all components of product locations.
					FoundRowsOfProductLocations = CargoPackagingTable.FindRows(
						New Structure("KeyProductLocations", FoundRow.KeyProductLocations));
					For Each ProductLocationsLine In FoundRowsOfProductLocations Do
						NewRow = TableOfWarehousesInGeneral.Add();
						FillPropertyValues(NewRow, String);
						FillPropertyValues(NewRow, ProductLocationsLine, "Premise,Cell,Series,Package");
						NewRow.Count = Count;
					EndDo;
					
				Else
					NewRow = TableOfWarehousesInGeneral.Add();
					FillPropertyValues(NewRow, String);
					FillPropertyValues(NewRow, FoundRow, "Premise,Cell,Series,Package");
					NewRow.Count = Count;
				EndIf;
				
			EndDo;
			
			LinesToDelete.Add(String); // The current row has been replaced with rows from the table by room
			
		EndIf;
		
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		TableOfWarehousesInGeneral.Delete(RowToDelete);
	EndDo;
	CellRoomTable.Columns.Delete("KeyProductLocations");
	
EndProcedure

Procedure AdjustAssignmentOfGivingMaterialsToAppointmentOfGiverAsWhole(GoodsTable, CompanyGoods, TableAdjusted)
	
	FilterParameters = New Structure("InitialAssignment,Products,Characteristic,Warehouse");
	TotalRows = GoodsTable.Count();
	For Counter = 1 To TotalRows Do
		
		IndexOf = TotalRows - Counter;
		CurRow = GoodsTable[IndexOf];
		FillPropertyValues(FilterParameters, CurRow);
		FoundRows = CompanyGoods.FindRows(FilterParameters);
		
		If FoundRows.Count() > 0 Then
			
			Count = Max(0, FoundRows[0].Count);
			AppointmentOfGiver = FoundRows[0].AppointmentOfGiver;
			Reserve = CurRow.Reserve;
			Demand = CurRow.Demand;
			NumberOfGiveaways = CurRow.Inventory - Count;
			If NumberOfGiveaways > 0 Then
				
				If AppointmentOfGiver <> CurRow.InitialAssignment Then // tolling type of stocks
					NewRow = GoodsTable.Insert(0);
					TotalRows = TotalRows + 1;
					FillPropertyValues(NewRow, CurRow);
					NewRow.Inventory = NumberOfGiveaways;
					NewRow.Reserve = Min(NumberOfGiveaways, NewRow.Reserve);
					Reserve = Reserve - NewRow.Reserve;
					NewRow.Demand = Min(NumberOfGiveaways, NewRow.Demand);
					Demand = Demand - NewRow.Demand;
					NewRow.NewAssignment = AppointmentOfGiver;
					CurRow.Inventory = Count; // own type of inventory
					CurRow.Reserve = Reserve;
					CurRow.Demand = Demand;
				Else
					// The need and the reserve are first provided by the supply.
					NewRow = TableAdjusted.Add();
					FillPropertyValues(NewRow, FoundRows[0]);
					NewRow.Count = NumberOfGiveaways;
					Demand = Max(0, Demand - NumberOfGiveaways);
					Reserve = Max(0, Reserve - NumberOfGiveaways);
					CurRow.Inventory = Max(0, CurRow.Inventory - NumberOfGiveaways); // own type of inventory
					CurRow.Reserve = Reserve;
					CurRow.Demand = Demand;
					If CurRow.Inventory = 0 Then
						GoodsTable.Delete(CurRow);
					EndIf;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReduceAppointmentOfTollingMaterialsWhenWithdrawingReserve(GoodsTable, CompanyGoods)
	
	FilterParameters = New Structure("InitialAssignment,Products,Characteristic,Warehouse");
	TotalRows = GoodsTable.Count();
	For Counter = 1 To TotalRows Do
		
		IndexOf = TotalRows - Counter;
		CurRow = GoodsTable[IndexOf];
		FillPropertyValues(FilterParameters, CurRow);
		FoundRows = CompanyGoods.FindRows(FilterParameters);
		
		If FoundRows.Count() > 0 Then
			
			AppointmentOfGiver = FoundRows[0].AppointmentOfGiver;
			
			If AppointmentOfGiver = CurRow.InitialAssignment Then
				GoodsTable.Delete(CurRow); // the withdrawal of the reserve from the tolling appointment must be performed through the operation "Withdrawal of the reserve"
			Else
				// We remove the assignment to the assignment of the giver for return to the giver or reuse.
				CurRow.NewAssignment = AppointmentOfGiver;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReduceAppointmentOfTollingMaterialsWhenReserving(GoodsTable, CompanyGoods)
	
	FilterParameters = New Structure("InitialAssignment,Products,Characteristic,Warehouse");
	TotalRows = GoodsTable.Count();
	For Counter = 1 To TotalRows Do
		
		IndexOf = TotalRows - Counter;
		CurRow = GoodsTable[IndexOf];
		FillPropertyValues(FilterParameters, CurRow);
		FoundRows = CompanyGoods.FindRows(FilterParameters);
		
		If FoundRows.Count() > 0 Then
			
			Count         = Max(0, FoundRows[0].Count);
			
			If Count < CurRow.Inventory Then
				
				If Count = 0 Then
					GoodsTable.Delete(CurRow);
				Else
					CurRow.Reserve = Max(0, CurRow.Reserve - (CurRow.Inventory - Min(Count, CurRow.Inventory)));
					CurRow.Inventory = Min(Count, CurRow.Inventory);
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function GiveawayProductsOfSelectionOrganizations(FilterTable, AssignmentAdjustment)
	
	Query = New Query();
	Query.Text = 
		"SELECT
		|	CAST(FilterTable.InitialAssignment AS Catalog.Assignments) AS InitialAssignment,
		|	FilterTable.Products       AS Products,
		|	FilterTable.Characteristic     AS Characteristic,
		|	FilterTable.Warehouse              AS Warehouse
		|INTO FilterTable
		|FROM
		|	&FilterTable AS FilterTable
		|INDEX BY
		|	InitialAssignment
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.InitialAssignment.Partner AS Partner,
		|	Table.InitialAssignment.Contract AS Contract,
		|	Table.InitialAssignment.LineOfBusiness AS LineOfBusiness,
		|	Table.InitialAssignment.OrderDocument AS OrderDocument,
		|	Table.InitialAssignment.AssignmentType AS AssignmentType
		|INTO RequitesForSearch
		|FROM
		|	FilterTable AS Table
		|INDEX BY
		|	Partner, Contract, LineOfBusiness, OrderDocument
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	ISNULL(GivingAppointment.Ref, GiveawayAppointmentWithEmptyLB.Ref) AS AppointmentOfGiver
		|INTO GiverAssignmentTable
		|FROM
		|	RequitesForSearch AS Table
		|		
		|		LEFT JOIN Catalog.Assignments AS GivingAppointment
		|		ON GivingAppointment.Partner = Table.Partner
		|		AND GivingAppointment.Contract = Table.Contract
		|		AND GivingAppointment.LineOfBusiness = Table.LineOfBusiness
		|		AND GivingAppointment.OrderDocument = UNDEFINED
		|		AND GivingAppointment.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
		|		
		|		LEFT JOIN Catalog.Assignments AS GiveawayAppointmentWithEmptyLB
		|		ON GiveawayAppointmentWithEmptyLB.Partner = Table.Partner
		|		AND GiveawayAppointmentWithEmptyLB.Contract = Table.Contract
		|		AND GiveawayAppointmentWithEmptyLB.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		AND GiveawayAppointmentWithEmptyLB.OrderDocument = UNDEFINED
		|		AND GiveawayAppointmentWithEmptyLB.AssignmentType = VALUE(Enum.AssignmentTypes.Giveaway2_5)
		|WHERE
		|	Table.AssignmentType IN(
		|		VALUE(Enum.AssignmentTypes.Giveaway2_5),
		|		VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22))
		|	AND ISNULL(GivingAppointment.Ref, GiveawayAppointmentWithEmptyLB.Ref) IS NOT NULL
		|INDEX BY
		|	InitialAssignment, Products, Characteristic, Warehouse
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	Table.InitialAssignment AS InitialAssignment,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.AppointmentOfGiver AS AppointmentOfGiver,
		|	RegisterAnalyst.DimensionKey AS DimensionKey
		|INTO TableOfGivingRows
		|FROM
		|	GiverAssignmentTable AS Table
		|		
		|		INNER JOIN InformationRegister.ItemsLocationAttributes AS RegisterAnalyst
		|		ON RegisterAnalyst.Purpose = Table.InitialAssignment
		|		AND RegisterAnalyst.Products = Table.Products
		|		AND RegisterAnalyst.Characteristic = Table.Characteristic
		|		AND RegisterAnalyst.StorageLocation = Table.Warehouse
		|INDEX BY
		|	DimensionKey, InitialAssignment, Products, Characteristic, Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.DimensionKey AS Ref
		|INTO Keys
		|FROM
		|	TableOfGivingRows AS Table
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Set.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	Set.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	SUM(Set.Count) AS Count
		|INTO CompanyStockBalance
		|FROM (
		|	SELECT
		|		CompanyGoodsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		CompanyGoodsBalance.Organization AS Organization,
		|		CompanyGoodsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		CompanyGoodsBalance.CountBalance AS Count
		|	FROM
		|		AccumulationRegister.CompanyGoods.Balance(,
		|				ItemsLocationAttributes IN(
		|					SELECT
		|						Table.Ref AS ItemsLocationAttributes
		|					FROM
		|						Keys AS Table)) AS CompanyGoodsBalance
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TableStorno.ItemsLocationAttributes AS ItemsLocationAttributes,
		|		TableStorno.Organization AS Organization,
		|		TableStorno.InventoryOwnerAttribute AS InventoryOwnerAttribute,
		|		TableStorno.Count AS Count
		|	FROM
		|		AccumulationRegister.CompanyGoods AS TableStorno
		|			INNER JOIN Keys AS Keys
		|			ON Keys.Ref = TableStorno.ItemsLocationAttributes
		|	WHERE
		|		TableStorno.Recorder = &Recorder
		|			AND TableStorno.Active) AS Set
		|GROUP BY
		|	Set.ItemsLocationAttributes,
		|	Set.InventoryOwnerAttribute
		|HAVING
		|	SUM(Set.Count) > 0
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|SELECT
		|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	SUM(Balance.Count) AS Count
		|INTO ResiduesCanBeRemovedByIsolation
		|FROM
		|	CompanyStockBalance AS Balance
		|WHERE
		|	NOT Balance.InventoryOwnerAttribute.InventoryType IN(
		|		VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
		|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|GROUP BY
		|	Balance.ItemsLocationAttributes
		|;
		|
		|///////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.InitialAssignment             AS InitialAssignment,
		|	Table.Products                   AS Products,
		|	Table.Characteristic                 AS Characteristic,
		|	Table.Warehouse                          AS Warehouse,
		|	MAX(Table.AppointmentOfGiver)   AS AppointmentOfGiver,
		|	SUM(ISNULL(Balance.Count, 0)) AS Count
		|FROM
		|	TableOfGivingRows AS Table
		|		
		|		LEFT JOIN ResiduesCanBeRemovedByIsolation AS Balance
		|		ON Balance.ItemsLocationAttributes = Table.DimensionKey
		|GROUP BY
		|	Table.InitialAssignment,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse";
	
	Query.SetParameter("FilterTable", FilterTable);
	Query.SetParameter("Recorder",   AssignmentAdjustment);
	
	SetPrivilegedMode(True);
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

Procedure AddTemporaryTableSortingWarehouses(Query, NameDataSource, NameAdjustmentFillTable)
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO TTProducts_1
		|FROM
		|	SubstitutionDataSource AS Table
		|INDEX BY
		|	Products, Characteristic";
	Query.Text = StrReplace(Query.Text, "SubstitutionDataSource", NameDataSource);
	Query.Execute();
	
	Query.Text = InformationRegisters.SupplySchemes.TemporaryTableWaysToSecureAllWarehouses(
		Enums.SupplyTypes.Move);
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS DestinationWarehouse,
		|	Table.ProcurementStrategy.SourceOfDemandSupply AS SourceWarehouse,
		|	1 AS Level
		|FROM
		|	TTWaysToEnsure AS Table
		|WHERE
		|	Table.Warehouse <> Table.ProcurementStrategy.SourceOfDemandSupply
		|		AND (Table.Products, Table.Characteristic) IN(
		|			SELECT
		|				Filter.Products   AS Products,
		|				Filter.Characteristic AS Characteristic
		|			FROM
		|				&SubstitutingProductSelection AS Filter)
		|ORDER BY
		|	Products, Characteristic, SourceWarehouse, DestinationWarehouse";
	
	Query.Text = StrReplace(Query.Text, "&SubstitutingProductSelection", NameAdjustmentFillTable);
	SourceTable_ = Query.Execute().Unload();

	ProductDimensions = SupplyServer.SplitTableByKeyValue(SourceTable_, "Products, Characteristic", "");
	For Each Group In ProductDimensions Do
		
		Table = Group.Table;
		Table.Indexes.Add("DestinationWarehouse");
		
		ProcessingCompleted = False;
		While Not ProcessingCompleted Do
			
			ProcessingCompleted = True;
			For Each TableRow In Table Do
				
				FoundRow = Table.Find(TableRow.SourceWarehouse, "DestinationWarehouse");
				If FoundRow <> Undefined
						And TableRow.DestinationWarehouse <> FoundRow.SourceWarehouse Then // protection against looping
					
					ProcessingCompleted = False;
					TableRow.Level = TableRow.Level + FoundRow.Level;
					TableRow.SourceWarehouse = FoundRow.SourceWarehouse;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	SourceTable_.Clear();
	For Each Group In ProductDimensions Do
		TMCommonUse.AddRowsToTable(SourceTable_, Group.Table);
	EndDo;

	Query.SetParameter("WarehouseHierarchyTable", SourceTable_);
	Query.Text =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.DestinationWarehouse AS DestinationWarehouse,
		|	Table.SourceWarehouse AS SourceWarehouse,
		|	Table.Level AS Level
		|INTO HierarchyOfWarehousesIsTemporary
		|FROM
		|	&WarehouseHierarchyTable AS Table
		|;
		|
		|/////////////////////////////////////////
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.DestinationWarehouse AS Warehouse,
		|	Table.SourceWarehouse AS RootSource,
		|	Table.Level + 1 AS Level
		|INTO WarehouseHierarchy_
		|FROM
		|	HierarchyOfWarehousesIsTemporary AS Table
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.SourceWarehouse AS Warehouse,
		|	Table.SourceWarehouse AS RootSource,
		|	1 AS Level
		|FROM
		|	HierarchyOfWarehousesIsTemporary AS Table
		|INDEX BY
		|	Products, Characteristic, Warehouse";
	
	Query.Execute();

	QueryText =
		"SELECT
		|	Table.Purpose     AS Purpose,
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse          AS Warehouse,
		|	
		|	MAX(ISNULL(WarehouseHierarchy_.Level, 0)
		|		+ CASE WHEN WarehouseHierarchy_.RootSource = HierarchyOfWarehousesWarehouses.RootSource
		|			AND WarehouseHierarchy_.Level <= HierarchyOfWarehousesWarehouses.Level THEN
		|					1000
		|				ELSE
		|					0
		|			END) AS WarehousePriority
		|INTO SortingWarehouses
		|FROM
		|	SubstitutionTableFillAdjustments AS Table
		|		
		|		LEFT JOIN SubstitutionDataSource AS DocumentTable
		|		ON DocumentTable.Purpose     = Table.Purpose
		|		 AND DocumentTable.Products   = Table.Products
		|		 AND DocumentTable.Characteristic = Table.Characteristic
		|		
		|		LEFT JOIN WarehouseHierarchy_ AS HierarchyOfWarehousesWarehouses
		|		ON HierarchyOfWarehousesWarehouses.Products   = Table.Products
		|		 AND HierarchyOfWarehousesWarehouses.Characteristic = Table.Characteristic
		|		 AND HierarchyOfWarehousesWarehouses.Warehouse          = DocumentTable.Warehouse
		|		
		|		LEFT JOIN WarehouseHierarchy_ AS WarehouseHierarchy_
		|		ON WarehouseHierarchy_.Products   = Table.Products
		|		 AND WarehouseHierarchy_.Characteristic = Table.Characteristic
		|		 AND WarehouseHierarchy_.Warehouse          = Table.Warehouse
		|GROUP BY
		|	Table.Purpose,
		|	Table.Products,
		|	Table.Characteristic,
		|	Table.Warehouse
		|INDEX BY
		|	Purpose, Products, Characteristic, Warehouse";
	QueryText = StrReplace(QueryText, "SubstitutionTableFillAdjustments", NameAdjustmentFillTable);
	QueryText = StrReplace(QueryText, "SubstitutionDataSource", NameDataSource);
	Query.Text = QueryText;
	Query.Execute();
	Text =
		"SELECT
		|	Table.Warehouse          AS Warehouse,
		|	Table.Products   AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose     AS Purpose
		|INTO ShippingWarehouses
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Purpose, Warehouse, Products, Characteristic) IN(
		|			SELECT 
		|				Filter.Purpose AS Purpose, 
		|				Filter.Warehouse AS Warehouse, 
		|				Filter.Products AS Products, 
		|				Filter.Characteristic AS Characteristic
		|			FROM
		|				DataSource AS Filter)) AS Table
		|WHERE
		|	Table.ReserveAtWarehouseBalance > 0
		|		OR Table.ReserveAsReceivedBalance > 0
		|		OR Table.SnoozeReservationBalance > 0
		|		OR Table.ToSupplyBalance > 0
		|		OR Table.NotProvideBalance > 0
		|
		|UNION
		|
		|SELECT DISTINCT
		|	Table.Warehouse AS Warehouse,
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Purpose AS Purpose
		|FROM
		|	InformationRegister.OrderStructure AS Table
		|WHERE
		|	(Table.Purpose, Table.Warehouse, Table.Products, Table.Characteristic) IN(
		|			SELECT
		|				Filter.Purpose AS Purpose,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic
		|			FROM
		|				DataSource AS Filter)
		|		AND Table.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption) 
		|		AND Table.ConnectionKeyTransfer = &EmptyLinkKey
		|	
		|INDEX BY
		|	Warehouse, Products, Characteristic, Purpose";
	Query.Text = StrReplace(Text, "DataSource", NameDataSource);
	Query.Execute();

EndProcedure

// The function checks that there are products for the intended purpose with the Provide separately action.
//
// Parameters:
//  Purpose - CatalogRef.Assignments - Purpose
//  AddressOfGoods - String - the address in the temporary storage with the selection of goods, to search for movements of a specific nomenclature
//
// Returns:
//   Boolean - The truth is if the goods are there.
//
Function ThereAreGoodsToSeparateProvision(Purpose, AddressOfGoods = Undefined) Export
	
	If Not ValueIsFilled(Purpose) Then
		Return False;
	EndIf;
	Query = New Query();
	
	If Not IsTempStorageURL(AddressOfGoods) Then
		
		Query.Text = 
			"SELECT ALLOWED TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		Purpose IN(&Purpose)
			|			AND Warehouse REFS Catalog.Warehouses) AS Balance
			|WHERE
			|	Balance.InStockBalance <> 0
			|		OR Balance.OrderedBalance <> 0
			|		OR Balance.ReserveAtWarehouseBalance <> 0
			|		OR Balance.ReserveAsReceivedBalance <> 0
			|		OR Balance.SnoozeReservationBalance <> 0
			|		OR Balance.ToSupplyBalance <> 0
			|		OR Balance.NotProvideBalance <> 0";
		If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
			Query.Text = Query.Text
			+ TMCommonUse.QuerySeparatorInJoin() + "
			|SELECT TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	InformationRegister.OrderStructure AS OrderStructure
			|WHERE
			|	OrderStructure.Purpose IN(&Purpose)
			|		AND OrderStructure.Warehouse REFS Catalog.Warehouses
			|		AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)";
		EndIf;
	Else
		
		Query.Text =
			"SELECT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic
			|INTO Goods
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products, Characteristic
			|;
			|
			|SELECT ALLOWED TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		Purpose IN(&Purpose)
			|			AND Warehouse REFS Catalog.Warehouses
			|			AND (Products, Characteristic) IN(
			|			SELECT
			|				Goods.Products AS Products,
			|				Goods.Characteristic AS Characteristic
			|			FROM
			|				Goods AS Goods)) AS Balance
			|WHERE
			|	Balance.InStockBalance <> 0
			|		OR Balance.OrderedBalance <> 0
			|		OR Balance.ReserveAtWarehouseBalance <> 0
			|		OR Balance.ReserveAsReceivedBalance <> 0
			|		OR Balance.SnoozeReservationBalance <> 0
			|		OR Balance.ToSupplyBalance <> 0
			|		OR Balance.NotProvideBalance <> 0";
		If GetFunctionalOption("DynamicStructureOfProductionOrders") Then
			Query.Text = Query.Text
			+ TMCommonUse.QuerySeparatorInJoin() + "
			|SELECT TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	InformationRegister.OrderStructure AS OrderStructure
			|WHERE
			|	OrderStructure.Purpose IN(&Purpose)
			|		AND OrderStructure.Warehouse REFS Catalog.Warehouses
			|		AND (OrderStructure.Products, OrderStructure.Characteristic) IN (
			|			SELECT
			|				Goods.Products AS Products,
			|				Goods.Characteristic AS Characteristic
			|			FROM
			|				Goods AS Goods)
			|		AND OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)";
		EndIf;
		Query.SetParameter("Goods", GetFromTempStorage(AddressOfGoods));
	
	EndIf;
	Query.SetParameter("Purpose", Purpose);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// The function checks that there are isolated remnants of goods for their intended purpose.
//
// Parameters:
//  Purpose - CatalogRef.Assignments - Purpose
//  AddressOfGoods - String - the address in the temporary storage with the selection of goods, to search for movements of a specific nomenclature
//
// Returns:
//   Boolean - The truth is if the goods are there.
//
Function ThereAreGoodsToWithdrawReserve(Purpose, AddressOfGoods = Undefined) Export
	
	If Not ValueIsFilled(Purpose) Then
		Return False;
	EndIf;
	
	Query = New Query();
	If Not IsTempStorageURL(AddressOfGoods) Then
		
		Query.Text = 
			"SELECT ALLOWED TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		Purpose IN(&Purpose)
			|			AND Warehouse REFS Catalog.Warehouses) AS Balance
			|WHERE
			|	Balance.InStockBalance <> 0";
		
	Else
	
		Query.Text =
			"SELECT
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic
			|INTO Goods
			|FROM
			|	&Goods AS Goods
			|INDEX BY
			|	Products, Characteristic
			|;
			|
			|SELECT ALLOWED TOP 1
			|	TRUE AS ThereAreRecords
			|FROM
			|	AccumulationRegister.InventoryAndDemands.Balance(,
			|		Purpose IN(&Purpose)
			|			AND Warehouse REFS Catalog.Warehouses
			|			AND (Products, Characteristic) IN(
			|			SELECT
			|				Goods.Products AS Products,
			|				Goods.Characteristic AS Characteristic
			|			FROM
			|				Goods AS Goods)) AS Balance
			|WHERE
			|	Balance.InStockBalance <> 0";
		Query.SetParameter("Goods", GetFromTempStorage(AddressOfGoods));
		
	EndIf;
	Query.SetParameter("Purpose", Purpose);
	Return Not Query.Execute().IsEmpty();
	
EndFunction


// Directly filling in the table part of the Goods document corrects the assignment of Goods with
// separate reserves for the assigned purpose.
//
// Parameters:
//  Purpose					 - CatalogRef.Assignments, Array - The purpose or array of assignments for which it is necessary to obtain the data of the separate provision
//  Organization					 - CatalogRef.Companies -
//  AssignmentAdjustment		 - DocumentRef.InventoryAssignmentAdjustment - the current adjustment for the reversal of her movements
//  OperationKind					 - EnumRef.KindsOfAssignmentAdjustmentOperations - the type of operation of the current/created document is the adjustment of the destination of goods.
//  Goods - FormDataCollection - Tabular part of the document to be filled in
//  GoodsFilter - ValueTable - Table containing selection by nomenclature and characteristics
Procedure FillInUsingBaseDocument(Purpose, Organization, AssignmentAdjustment, OperationKind, Goods, GoodsFilter = Undefined) Export
	
	If Not ValueIsFilled(Purpose) Then
		Return;
	EndIf;
	
	If GoodsFilter = Undefined Then
		GoodsFilter = New ValueTable();
		GoodsFilter.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
		GoodsFilter.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		
		ResultOfWithdrawalOfReserves = TableOfWithdrawalOfReserveForManyPurposes(Organization, GoodsFilter, AssignmentAdjustment, Purpose);
		Table = ResultOfWithdrawalOfReserves.TableOfGoods;
		
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
		
		ResultOfWithdrawalOfReserves = ReserveWithdrawalTable(Purpose, GoodsFilter, AssignmentAdjustment);
		Table = ResultOfWithdrawalOfReserves.TableOfGoods;
	
	ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment
				Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ToReserve_ Then
		
		ReservationResult = ReservationTable(
			Purpose,
			New Structure("WarehouseStockBalance,ProvisionsForAppointments", True, False),
			True,
			Organization,
			GoodsFilter,
			AssignmentAdjustment);
		Table = ReservationResult.TableOfGoods;
		
	Else
		Return;
	EndIf;
	
	Table.Columns.Add("Count", New TypeDescription("Number"));
	Table.Columns.Add("Mark", New TypeDescription("Boolean"));
	Table.Columns.Add("UsingSeries", New TypeDescription("Boolean"));
	Table.Columns.Add("UseOfCellPremises", New TypeDescription("Boolean"));
	Table.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	Table.Columns.Add("Premise", New TypeDescription("CatalogRef.Warerooms"));
	Table.Columns.Add("Cell", New TypeDescription("CatalogRef.StorageBins"));
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments
			Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve Then
			
			WithdrawReserves(Table, True, ResultOfWithdrawalOfReserves.TableOfResults);
			Goods_Copy = Table.Copy(, "Products,InitialAssignment,NewAssignment,Warehouse");
			Selection = SpecifyingNumberOfSeriesCellsForRow(Goods_Copy);
			While Selection.Next() Do
				
				String = Table[Selection.LineNumber - 1];
				String.UsingSeries = Selection.KeepAccountingByBatch;
				String.UseOfCellPremises = Selection.UseWarerooms
					Or Selection.UseBinLocationWarehousing;
				
			EndDo;
			CellRoomTable = TableOfCellPlacementByProduct(Table, AssignmentAdjustment, False);
			Table.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			MergeTablesByWarehouseAndPremises(Table, CellRoomTable);
			
	Else
		
		EstablishReserves(Table, ReservationResult.TableOfResults, True);
		
	EndIf;
	
	TotalRows = Table.Count();
	For Counter = 1 To TotalRows Do
		CurRow = Table[TotalRows - Counter];
		If CurRow.Count <= 0 Then
			Table.Delete(CurRow);
		EndIf;
	EndDo;
	
	AddControlledLotReferencesToTable(
		Table,
		AssignmentAdjustment);
	Goods.Load(Table);
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"RecalculateNumberOfPackages",
		BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	
EndProcedure

// The function checks that the document (order) has movements for other purposes for which reservations are available.
//
// Parameters:
//  Recorder - DefinedType.ExpectedShipment - The order whose movements need to be analyzed.
//
// Returns:
//  Boolean - True, if there is not an empty purpose in the movements, false, otherwise.
//
Function ThereAreGoodsToThirdPartyStandAloneCollateral(Recorder) Export
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	InventoryAndDemands.Products AS Products,
		|	InventoryAndDemands.Characteristic AS Characteristic,
		|	InventoryAndDemands.Warehouse AS Warehouse,
		|	InventoryAndDemands.Purpose AS Purpose
		|INTO Analysts
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		OrderDocument = &Recorder
		|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND Warehouse REFS Catalog.Warehouses) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.ReserveAtWarehouseBalance <> 0
		|		OR InventoryAndDemands.ReserveAsReceivedBalance <> 0
		|		OR InventoryAndDemands.SnoozeReservationBalance <> 0
		|		OR InventoryAndDemands.ToSupplyBalance <> 0
		|		OR InventoryAndDemands.NotProvideBalance <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS ThereAreRecords
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|				SELECT
		|					Filter.Products AS Products,
		|					Filter.Characteristic AS Characteristic,
		|					Filter.Warehouse AS Warehouse,
		|					Filter.Purpose AS Purpose
		|				FROM
		|					Analysts AS Filter)) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.InStockBalance <> 0
		|		OR InventoryAndDemands.OrderedBalance <> 0
		|		OR InventoryAndDemands.ReserveAtWarehouseBalance <> 0
		|		OR InventoryAndDemands.ReserveAsReceivedBalance <> 0
		|		OR InventoryAndDemands.SnoozeReservationBalance <> 0
		|		OR InventoryAndDemands.ToSupplyBalance <> 0
		|		OR InventoryAndDemands.NotProvideBalance <> 0";
	Query.SetParameter("Recorder", Recorder);
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// The function checks that the document (order) has movements for other purposes for which the withdrawal of the reserve is available.
//
// Parameters:
//  Recorder - DefinedType.ExpectedShipment - The order whose movements need to be analyzed.
//
// Returns:
//  Boolean - True, if there is not an empty purpose in the movements, false, otherwise.
//
Function HaveAccessToThirdPartyReserveWithdrawals(Recorder) Export
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	InventoryAndDemands.Products AS Products,
		|	InventoryAndDemands.Characteristic AS Characteristic,
		|	InventoryAndDemands.Warehouse AS Warehouse,
		|	InventoryAndDemands.Purpose AS Purpose
		|INTO Analysts
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		OrderDocument = &Recorder
		|			AND Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND Warehouse REFS Catalog.Warehouses) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.ReserveAtWarehouseBalance <> 0
		|		OR InventoryAndDemands.ReserveAsReceivedBalance <> 0
		|		OR InventoryAndDemands.SnoozeReservationBalance <> 0
		|		OR InventoryAndDemands.ToSupplyBalance <> 0
		|		OR InventoryAndDemands.NotProvideBalance <> 0
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|//////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS ThereAreRecords
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|				SELECT
		|					Filter.Products AS Products,
		|					Filter.Characteristic AS Characteristic,
		|					Filter.Warehouse AS Warehouse,
		|					Filter.Purpose AS Purpose
		|				FROM
		|					Analysts AS Filter)) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.InStockBalance <> 0";
	Query.SetParameter("Recorder", Recorder);
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion


#Region InfobaseUpdate

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	SynonymForDocumentTable = "";
	FullDocumentName = "Document.InventoryAssignmentAdjustment";
	RedefiningParameterCalculation = New Structure;
	
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
		
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
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
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
