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
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DamageNote") Then
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
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
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
	
	DataProcessors.WarehouseGoodsIssueReceiptWizard.AddCreateCommandBasedOnWarehouseActRegistrationForm(GenerationCommands);
	
	Documents.GoodsDamage.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "Order to reflect damage to goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.DamageNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DamageNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DamageNote);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsQuality";
		
		
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
	
	
	
	Reports.UnregisteredSurplusesAndShortagesOfGoods.AddDesignCommand(ReportsCommands);
	
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
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.DamageNote";
	SeriesSpecificationParameters.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.DamageRecord);
	
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	
	SeriesSpecificationParameters.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(
		                                                  	Object.Warehouse,Object.Premise, Object.Date);
	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		SeriesSpecificationParameters.LinkFields.Add("Cell");
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";	
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ItSWarrant = True;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	SeriesSpecificationParameters.Date = Object.Date;
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusShortages");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
//	Parameters:
//		SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods." + SeriesSpecificationParameters.FieldNameQuantity + " AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusShortages AS BatchesIndicationStatusShortages
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
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusShortages AS BatchesIndicationStatusShortages
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusShortages AS OldStatusOfIndicatingShortageSeries,
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
	|				WHEN NOT &SeriesOnlyForCostPrice
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|								THEN CASE
	|										WHEN Goods.Count > 0
	|											THEN 10
	|										ELSE 9
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|											THEN CASE
	|													WHEN Goods.Count > 0
	|														THEN 6
	|													ELSE 5
	|												END
	|										ELSE CASE
	|												WHEN Goods.Count > 0
	|													THEN 8
	|												ELSE 7
	|											END
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenRecordingSurpluses
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|											THEN CASE
	|													WHEN Goods.Count > 0
	|														THEN 4
	|													ELSE 3
	|												END
	|										ELSE CASE
	|												WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenRecordingSurpluses
	|													OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenRecordingShortages
	|													THEN CASE
	|															WHEN Goods.Count > 0
	|																THEN 2
	|															ELSE 1
	|														END
	|												ELSE 0
	|											END
	|									END
	|							ELSE 0
	|						END
	|			END
	|	END AS BatchesIndicationStatus,
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
	|				WHEN NOT &SeriesOnlyForCostPrice
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|								THEN CASE
	|										WHEN Goods.Count > 0
	|											THEN 10
	|										ELSE 9
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|											THEN CASE
	|													WHEN Goods.Count > 0
	|														THEN 6
	|													ELSE 5
	|												END
	|										ELSE CASE
	|												WHEN Goods.Count > 0
	|													THEN 8
	|												ELSE 7
	|											END
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenRecordingShortages
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|											THEN CASE
	|													WHEN Goods.Count > 0
	|														THEN 4
	|													ELSE 3
	|												END
	|										ELSE CASE
	|												WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenRecordingShortages
	|													THEN CASE
	|															WHEN Goods.Count > 0
	|																THEN 2
	|															ELSE 1
	|														END
	|												ELSE 0
	|											END
	|									END
	|							ELSE 0
	|						END
	|			END
	|	END AS BatchesIndicationStatusShortages
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
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Statuses.BatchesIndicationStatusShortages AS BatchesIndicationStatusShortages
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatusShortages <> Statuses.OldStatusOfIndicatingShortageSeries
	|
	|ORDER BY
	|	Statuses.LineNumber";
	
	Return QueryText;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
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
	|	HeaderData_.Date AS Period,
	|	HeaderData_.Warehouse AS Warehouse,
	|	HeaderData_.Premise AS Premise,
	|	HeaderData_.Ref AS Ref,
	|	CASE
	|		WHEN HeaderData_.Warehouse.UseWarerooms
	|				AND HeaderData_.Date >= HeaderData_.Warehouse.StartDateOfWareroomUse
	|			THEN CASE
	|					WHEN HeaderData_.Premise.UseBinLocationWarehousing
	|							AND HeaderData_.Date >= HeaderData_.Premise.StartDateOfUsingWarehouseBinSystem
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|		ELSE CASE
	|				WHEN HeaderData_.Warehouse.UseBinLocationWarehousing
	|						AND HeaderData_.Date >= HeaderData_.Warehouse.StartDateOfUsingWarehouseBinSystem
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS UseBinLocationWarehousing
	|FROM
	|	Document.DamageNote AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                       Attributes.Period);
	Query.SetParameter("Warehouse",                        Attributes.Warehouse);
	Query.SetParameter("Premise",                    Attributes.Premise);
	Query.SetParameter("UseBinLocationWarehousing", Attributes.UseBinLocationWarehousing);
	
EndProcedure

Procedure RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref                       AS Ref,
	|	GoodsTable.Ref.Date                  AS Date,
	|	GoodsTable.Ref.Warehouse                 AS Warehouse,
	|	GoodsTable.Ref.Premise             AS Premise,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.Purpose                   AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series                        AS Series,
	|	GoodsTable.Package                     AS Package,
	|	-GoodsTable.Count                  AS Count,
	|	-GoodsTable.NumberOfPackages          AS NumberOfPackages,
	|	GoodsTable.Cell                       AS Cell,
	|	GoodsTable.BatchesIndicationStatusShortages AS BatchesIndicationStatus,
	|	TRUE                                     AS RemainderChanges
	|FROM
	|	Document.DamageNote.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref                      AS Ref,
	|	GoodsTable.Ref.Date                 AS Date,
	|	GoodsTable.Ref.Warehouse                AS Warehouse,
	|	GoodsTable.Ref.Premise            AS Premise,
	|	GoodsTable.ProductsRecordingAsReceived   AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.ForAssignment 
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series                       AS Series,
	|	GoodsTable.PackagingReceipt       AS Package,
	|	GoodsTable.CountRecordingAsReceived     AS Count,
	|	GoodsTable.NumberOfPackages          AS NumberOfPackages,
	|	GoodsTable.Cell                      AS Cell,
	|	GoodsTable.BatchesIndicationStatus         AS BatchesIndicationStatus,
	|	TRUE                                    AS RemainderChanges
	|FROM
	|	Document.DamageNote.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|";
	
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
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Sender,
	|	&Premise AS WareroomOfSender,
	|	UNDEFINED AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.DamageRecord) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	TTTableProducts AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND SeriesTable.BatchesIndicationStatusShortages <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.ProductsRecordingAsReceived,
	|	SeriesTable.CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN SeriesTable.ForAssignment
	|			THEN CASE
	|					WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|						THEN SeriesTable.Purpose
	|					ELSE VALUE(Catalog.Assignments.EmptyRef)
	|				END
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END										AS Purpose,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	UNDEFINED,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	&Warehouse,
	|	&Premise,
	|	VALUE(Enum.WarehouseTransactions.DamageRecord),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	TRUE
	|FROM
	|	TTTableProducts AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
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
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue,
		|	FALSE AS IgnoreReservesInStockControl
		|FROM
		|	Document.DamageNote.Goods AS TabPart
		|WHERE
		|	ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	AND ISNULL(TabPart.PackagingReceipt.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.ProductsRecordingAsReceived AS Products,
		|	TabPart.CharacteristicRecordingAsReceived AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.ForAssignment
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.DamageNote.Goods AS TabPart
		|WHERE
		|	ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	AND ISNULL(TabPart.PackagingReceipt.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	TextProductLocations =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.Series AS Series,
		|	MAX(TabPart.Package) AS Package,
		|	TabPart.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	TabPart.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	CASE WHEN TabPart.ForAssignment THEN
		|				TabPart.Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END AS AssignmentGoodsReceipt,
		|	MAX(TabPart.PackagingReceipt) AS PackagingReceipt
		|INTO ProductLocations
		|FROM
		|	Document.DamageNote.Goods AS TabPart
		|WHERE
		|	TabPart.Ref IN(&Ref)
		|		AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|GROUP BY
		|	TabPart.Ref,
		|	TabPart.Products,
		|	TabPart.Characteristic,
		|	TabPart.Purpose,
		|	TabPart.Series,
		|	TabPart.ProductsRecordingAsReceived,
		|	TabPart.CharacteristicRecordingAsReceived,
		|	CASE WHEN TabPart.ForAssignment THEN
		|				TabPart.Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END
		|INDEX BY
		|	Ref, Products, Characteristic, Purpose, Series, Package,
		|	ProductsRecordingAsReceived, CharacteristicRecordingAsReceived, AssignmentGoodsReceipt, PackagingReceipt";
		
	TemporaryTableTemplateTexts = New Structure();
	TemporaryTableTemplateTexts.Insert("ProductLocations", TextProductLocations);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref               AS Ref,
		|	TabPart.Ref.Date          AS Period,
		|	TabPart.Products         AS Products,
		|	TabPart.Characteristic       AS Characteristic,
		|	TabPart.Ref.Warehouse         AS Warehouse,
		|	TabPart.Purpose           AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count           AS Count,
		|	UNDEFINED                  AS PlannedConsumptionOfDistributedStock,
		|	FALSE                          AS ControlOfFreeResidue
		|FROM
		|	Document.DamageNote.Goods AS TabPart
		|		
		|		INNER JOIN ProductLocations AS ProductLocations
		|		ON TabPart.Ref = ProductLocations.Ref
		|		 AND TabPart.Products = ProductLocations.Products
		|		 AND TabPart.Characteristic = ProductLocations.Characteristic
		|		 AND TabPart.Purpose = ProductLocations.Purpose
		|		 AND TabPart.Series = ProductLocations.Series
		|		 AND TabPart.Package = ProductLocations.Package
		|		 AND TabPart.ProductsRecordingAsReceived = ProductLocations.ProductsRecordingAsReceived
		|		 AND TabPart.CharacteristicRecordingAsReceived = ProductLocations.CharacteristicRecordingAsReceived
		|		 AND CASE WHEN TabPart.ForAssignment THEN
		|				TabPart.Purpose
		|			ELSE
		|				VALUE(Catalog.Assignments.EmptyRef)
		|		END = ProductLocations.AssignmentGoodsReceipt
		|		 AND TabPart.PackagingReceipt = ProductLocations.PackagingReceipt
		|WHERE
		|	TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False,
		TemporaryTableTemplateTexts);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.ProductsRecordingAsReceived AS Products,
		|	TabPart.CharacteristicRecordingAsReceived AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	CASE
		|		WHEN TabPart.ForAssignment
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.DamageNote.Goods AS TabPart
		|		INNER JOIN ProductLocations AS ProductLocations
		|		ON TabPart.Ref = ProductLocations.Ref
		|		AND TabPart.Products = ProductLocations.Products
		|		AND TabPart.Characteristic = ProductLocations.Characteristic
		|		AND TabPart.Purpose = ProductLocations.Purpose
		|		AND TabPart.Series = ProductLocations.Series
		|		AND TabPart.Package = ProductLocations.Package
		|		AND TabPart.ProductsRecordingAsReceived = ProductLocations.ProductsRecordingAsReceived
		|		AND TabPart.CharacteristicRecordingAsReceived = ProductLocations.CharacteristicRecordingAsReceived
		|		AND CASE
		|			WHEN TabPart.ForAssignment
		|				THEN TabPart.Purpose
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END = ProductLocations.AssignmentGoodsReceipt
		|		AND TabPart.PackagingReceipt = ProductLocations.PackagingReceipt
		|WHERE
		|	TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False,
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
	
	// Reflection of damage to goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "DamageNote";
	PrintCommand.Presentation = NStr("vi = 'Phản ánh hàng hỏng';
									|ru = 'Отражение порчи товаров';
									|en = 'Inventory quality change recognition'; fa = 'Inventory quality change recognition';
									|it = 'Visualizzazione dei deterioramenti delle merci';
									|pl = 'Odzwierciedlenie uszkodzeń towarów';
									|tr = 'Ürün stok kalite değişikliği yansıtma'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "Document.DamageNote";
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
		PrintCommand.PrintManager = "Document.DamageNote";
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "DamageNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"DamageNote",
			NStr("vi = 'Phản ánh hàng hỏng';
				|ru = 'Отражение порчи товаров';
				|en = 'Inventory quality change recognition'; fa = 'Inventory quality change recognition';
				|it = 'Visualizzazione dei deterioramenti delle merci';
				|pl = 'Odzwierciedlenie uszkodzeń towarów';
				|tr = 'Ürün stok kalite değişikliği yansıtma'"),
			PrintingReflectionOfSpoilageOfGoodsInStock(ObjectsArray, PrintObjects));
		
	EndIf;
	
EndProcedure

Function PrintingReflectionOfSpoilageOfGoodsInStock(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTING_OrderForReflectionOfDamageToGoods_ReflectionOfDamageToGoods";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DamageNote.Ref,
	|	PRESENTATION(DamageNote.Warehouse) AS WarehousePresentation,
	|	DamageNote.Date,
	|	DamageNote.Number,
	|	CASE
	|		WHEN DamageNote.Warehouse.UseWarerooms
	|				AND DamageNote.Date >= DamageNote.Warehouse.StartDateOfWareroomUse
	|			THEN DamageNote.Premise.CurrentEmployeeInChargeTypes
	|		ELSE DamageNote.Warehouse.CurrentEmployeeInChargeTypes
	|	END AS Warehouseman,
	|	CASE
	|		WHEN DamageNote.Warehouse.UseWarerooms
	|				AND DamageNote.Date >= DamageNote.Warehouse.StartDateOfWareroomUse
	|			THEN DamageNote.Premise.CurrentPositionOfTheResponsiblePerson
	|		ELSE DamageNote.Warehouse.CurrentPositionOfTheResponsiblePerson
	|	END AS StorekeeperPosition_,
	|	DamageNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	DamageNote.Warehouse AS Warehouse,
	|	CASE
	|		WHEN DamageNote.Warehouse.UseWarerooms
	|				AND DamageNote.Date >= DamageNote.Warehouse.StartDateOfWareroomUse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarerooms,
	|	PRESENTATION(DamageNote.Premise) AS PremisePresentation,
	|	DamageNote.Premise AS Premise
	|FROM
	|	Document.DamageNote AS DamageNote
	|WHERE
	|	DamageNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	DamageNote.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DamageNote.Ref AS Ref,
	|	DamageNote.LineNumber AS LineNumber,
	|	PRESENTATION(DamageNote.Cell) AS CellPresentation,
	|	DamageNote.Products.DescriptionFull AS ProductPresentation,
	|	&ColumnOfCodes AS AdditionalColumn,
	|	DamageNote.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	DamageNote.Series.Description AS BatchPresentation,
	|	DamageNote.ProductsRecordingAsReceived.DescriptionFull AS PresentationOfSpoiledProducts,
	|	PRESENTATION(DamageNote.CharacteristicRecordingAsReceived) AS PresentationOfCharacteristicsOfSpoiledProduct,
	|	DamageNote.Series.Description AS PresentationOfSeriesOfSpoiledProducts,
	|	DamageNote.NumberOfPackages AS NumberOfPackages,
	|	DamageNote.Count AS Count,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE DamageNote.Package.Description
	|	END AS PackagingPresentation,
	|	PRESENTATION(DamageNote.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	&QueryTextUnitOfMeasureDescription AS PresentationOfPackingUnit
	|FROM
	|	Document.DamageNote.Goods AS DamageNote
	|WHERE
	|	DamageNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	Query.Text = StrReplace(Query.Text,"&ColumnOfCodes",
		?(OutputCodes,"DamageNote.Products." + NameOfCodeColumn, """"""));
		
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"DamageNote.Package",
			"DamageNote.Products"));
			
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"DamageNote.Package",
			"DamageNote.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Results = Query.ExecuteBatch(); 
	
	SelectionByDocuments = Results[0].Select();
	SelectionByTableParts = Results[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	DocumentAttributes = New Structure("Number, Date, Prefix");
	
	DocumentSynonym = "";
	
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		OutputCellsAndPackages = WarehousesServer.UseBinLocationWarehousing(SelectionByDocuments.Warehouse, SelectionByDocuments.Premise, SelectionByDocuments.Date);
		
		// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
		Template = PrintManagement.PrintFormTemplate("Document.DamageNote.PF_MXL_DamageNote");
		
		HeaderArea_ 		= Template.GetArea("Title");
		SectionHeader 			= Template.GetArea("Header");
		
		TableHeaderAreaStart 	= Template.GetArea("TableHeader|BeginningOfTheLine");
		AreaTableRowStart 	= Template.GetArea("TableRow|BeginningOfTheLine");
		AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");
		
		If OutputCellsAndPackages Then
			AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeader|ColumnOfCodes");
			AreaTableRowCodeColumn 	= Template.GetArea("TableRow|ColumnOfCodes");
			AreaBasementTableColumnCodes 	= Template.GetArea("TableFooter|ColumnOfCodes");
			
			AreaTableHeaderCell	= Template.GetArea("TableHeader|Cell");
			AreaTableRowCell	= Template.GetArea("TableRow|Cell");
			AreaBasementTableCell	= Template.GetArea("TableFooter|Cell");
			
			AreaTableHeaderPackingColumn 		= Template.GetArea("TableHeader|ColumnOfPackages");
			AreaTableRowPackingColumn 	= Template.GetArea("TableRow|ColumnOfPackages");
			AreaBasementTablePackingColumn		= Template.GetArea("TableFooter|ColumnOfPackages");
			
			AreaTableHeaderProductColumn 	= Template.GetArea("TableHeader|ProductColumn_");
			AreaTableRowProductColumn 	= Template.GetArea("TableRow|ProductColumn_");
			AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|ProductColumn_");
		Else
			AreaTableHeaderCodeColumn 	= Template.GetArea("TableHeaderWithoutBarley|ColumnOfCodesWithoutCell");
			AreaTableRowCodeColumn 	= Template.GetArea("TableRowWithoutBarley|ColumnOfCodesWithoutCell");
			AreaBasementTableColumnCodes 	= Template.GetArea("TableFooter|ColumnOfCodesWithoutCell");
			
			AreaTableHeaderProductColumn 	= Template.GetArea("TableHeaderWithoutBarley|GoodsWithoutPackaging");
			AreaTableRowProductColumn 	= Template.GetArea("TableRowWithoutBarley|GoodsWithoutPackaging");
			AreaBasementTableGoodsColumn 	= Template.GetArea("TableFooter|GoodsWithoutPackaging");
		EndIf;
		
		AreaTableHeaderCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
		SignatureArea = Template.GetArea("Signatures");
		
		ProductColumnArea_ = ?(OutputCellsAndPackages, Template.Area("ProductColumn_"), Template.Area("GoodsWithoutPackaging"));
		
		If Not OutputCodes Then
			ProductColumnArea_.ColumnWidth = ProductColumnArea_.ColumnWidth 
					+ ?(OutputCellsAndPackages, Template.Area("ColumnOfCodes").ColumnWidth, Template.Area("ColumnOfCodesWithoutCell").ColumnWidth); 
		EndIf;
		
		TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
		AreaTableRowEnd 	= Template.GetArea("TableRow|EndOfRow");
		AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");
		
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes,SelectionByDocuments);
		
		If Not ValueIsFilled(DocumentSynonym) Then
			MetadataOfDocument = SelectionByDocuments.Ref.Metadata();
			If Not ValueIsFilled(MetadataOfDocument.ObjectPresentation) Then
				DocumentSynonym = MetadataOfDocument.Synonym;
			Else
				DocumentSynonym = MetadataOfDocument.ObjectPresentation;
			EndIf;
		EndIf;
		
		Title = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym);
		
		HeaderArea_.Parameters.TitleText = Title;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		SectionHeader.Parameters.Fill(SelectionByDocuments);
		
		SectionHeader.Parameters.WarehousePresentation = WarehousesServer.GetWarehousePresentation(
			SelectionByDocuments.WarehousePresentation,
			SelectionByDocuments.PremisePresentation);
		
		SpreadsheetDocument.Put(SectionHeader);
		
		SpreadsheetDocument.Put(TableHeaderAreaStart);
		
		If OutputCellsAndPackages Then
			SpreadsheetDocument.Join(AreaTableHeaderCell);
		EndIf;
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderCodeColumn);
		EndIf;
		
		SpreadsheetDocument.Join(AreaTableHeaderProductColumn);
		
		If OutputCellsAndPackages Then
			SpreadsheetDocument.Join(AreaTableHeaderPackingColumn);
		EndIf;
		
		SpreadsheetDocument.Join(TableHeaderAreaEnd);
		
		While SamplingByTSLines.Next() Do
			
			AreaTableRowStart.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Put(AreaTableRowStart);
			
			If OutputCellsAndPackages Then
				AreaTableRowCell.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowCell);
			EndIf;
			
			If OutputCodes Then
				AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines.AdditionalColumn;
				SpreadsheetDocument.Join(AreaTableRowCodeColumn);
			EndIf;
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				,
				SamplingByTSLines.BatchPresentation,
				AdditionalParametersProductPresentation);
			
			AreaTableRowProductColumn.Parameters.DamagedGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.PresentationOfSpoiledProducts,
				SamplingByTSLines.PresentationOfCharacteristicsOfSpoiledProduct,
				,
				SamplingByTSLines.PresentationOfSeriesOfSpoiledProducts,
				AdditionalParametersProductPresentation);
			SpreadsheetDocument.Join(AreaTableRowProductColumn);
			
			If OutputCellsAndPackages Then
				AreaTableRowPackingColumn.Parameters.Fill(SamplingByTSLines);
				SpreadsheetDocument.Join(AreaTableRowPackingColumn);
			EndIf;
			
			AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Join(AreaTableRowEnd);
			
		EndDo;
		
		SpreadsheetDocument.Put(AreaBasementTableTop);
		
		If OutputCellsAndPackages Then
			AreaBasementTableCell.Parameters.Fill(SamplingByTSLines);
			SpreadsheetDocument.Join(AreaBasementTableCell);
		EndIf;
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableGoodsColumn);
		If OutputCellsAndPackages Then
			SpreadsheetDocument.Join(AreaBasementTablePackingColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		// Output of signatures.
		SignatureArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
		SignatureArea.Parameters.Warehouseman = PersonsTM.IndividualShortName(SelectionByDocuments.Warehouseman, SelectionByDocuments.Date);
		SignatureArea.Parameters.StorekeeperPosition_ = WarehousesServer.PositionOfResponsiblePersonOfWarehouse(SelectionByDocuments.StorekeeperPosition_);
		SpreadsheetDocument.Put(SignatureArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function LabelPrintingData(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.ProductsRecordingAsReceived   AS Products,
	|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
	|	Goods.PackagingReceipt       AS Package,
	|	Goods.Series                       AS Series,
	|	MIN(Goods.LineNumber)        AS Order,
	|	SUM(Goods.NumberOfPackages)   AS Count
	|FROM
	|	Document.DamageNote.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND CASE
	|		WHEN Goods.ProductsRecordingAsReceived.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			AND Goods.CharacteristicRecordingAsReceived = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|GROUP BY
	|	Goods.ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived,
	|	Goods.PackagingReceipt,
	|	Goods.Series
	|
	|ORDER BY
	|	Order";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.Execute();
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", Undefined);
	StructureOfActions.Insert("FillInTheWarehouse",       Undefined);
	StructureOfActions.Insert("FillInPriceView",     Undefined);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", QueryResult.Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

Function DataForPrintingPriceTags(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.ProductsRecordingAsReceived   AS Products,
	|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
	|	Goods.PackagingReceipt       AS Package,
	|	Goods.Series                       AS Series,
	|	MIN(Goods.LineNumber)        AS Order,
	|	SUM(Goods.NumberOfPackages)   AS Count
	|FROM
	|	Document.DamageNote.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND CASE
	|		WHEN Goods.ProductsRecordingAsReceived.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			AND Goods.CharacteristicRecordingAsReceived = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|GROUP BY
	|	Goods.ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived,
	|	Goods.PackagingReceipt,
	|	Goods.Series
	|
	|ORDER BY
	|	Order";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.Execute();
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", Undefined);
	StructureOfActions.Insert("FillInTheWarehouse",       Undefined);
	StructureOfActions.Insert("FillInPriceView",     Undefined);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintingPriceTags");
	StructureOfActions.Insert("FillInTheNumberOfPriceTagsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", QueryResult.Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
		
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived,
	|	Goods.ForAssignment,
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusShortages AS BatchesIndicationStatusShortages,
	|	Goods.Count
	|INTO TTTableProducts
	|FROM
	|	Document.DamageNote.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND ISNULL(Goods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND ISNULL(Goods.PackagingReceipt.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived,
	|	Table.ForAssignment,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.BatchesIndicationStatusShortages,
	|	SUM(GoodsCount.Count)
	|FROM
	|	(SELECT
	|		GoodsPackage.Ref AS Ref,
	|		GoodsPackage.Products AS Products,
	|		GoodsPackage.Characteristic AS Characteristic,
	|		GoodsPackage.Purpose AS Purpose,
	|		GoodsPackage.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|		GoodsPackage.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|		GoodsPackage.ForAssignment AS ForAssignment,
	|		GoodsPackage.Series AS Series,
	|		MAX(GoodsPackage.Package) AS Package,
	|		MAX(GoodsPackage.PackagingReceipt) AS PackagingReceipt,
	|		GoodsPackage.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		GoodsPackage.BatchesIndicationStatusShortages AS BatchesIndicationStatusShortages
	|	FROM
	|		Document.DamageNote.Goods AS GoodsPackage
	|	WHERE
	|		GoodsPackage.Ref = &Ref
	|		AND ISNULL(GoodsPackage.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	
	|	GROUP BY
	|		GoodsPackage.Ref,
	|		GoodsPackage.Products,
	|		GoodsPackage.Characteristic,
	|		GoodsPackage.Purpose,
	|		GoodsPackage.ProductsRecordingAsReceived,
	|		GoodsPackage.CharacteristicRecordingAsReceived,
	|		GoodsPackage.ForAssignment,
	|		GoodsPackage.Series,
	|		GoodsPackage.BatchesIndicationStatus,
	|		GoodsPackage.BatchesIndicationStatusShortages) AS Table
	|		INNER JOIN Document.DamageNote.Goods AS GoodsCount
	|		ON Table.Ref = GoodsCount.Ref
	|			AND Table.Products = GoodsCount.Products
	|			AND Table.Characteristic = GoodsCount.Characteristic
	|			AND Table.Series = GoodsCount.Series
	|			AND Table.Purpose = GoodsCount.Purpose
	|			AND Table.Package = GoodsCount.Package
	|			AND Table.ProductsRecordingAsReceived = GoodsCount.ProductsRecordingAsReceived
	|			AND Table.CharacteristicRecordingAsReceived = GoodsCount.CharacteristicRecordingAsReceived
	|			AND Table.ForAssignment = GoodsCount.ForAssignment
	|			AND Table.PackagingReceipt = GoodsCount.PackagingReceipt
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived,
	|	Table.ForAssignment,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.BatchesIndicationStatusShortages";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
