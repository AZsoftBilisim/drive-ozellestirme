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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsSurplusesNote") Then
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
	
	Documents.InventorySurplusRecognition.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "Order to reflect excess goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsSurplusesNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsSurplusesNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsSurplusesNote);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseWarehouseManagemantSystemForGoodsSurplusesShortages";
		
		
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

// Names of the details that the parameters for specifying the series depend on.
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
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsSurplusesNote";
	SeriesSpecificationParameters.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.SurplusesRecord);
	SeriesSpecificationParameters.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(
		                                                  	Object.Warehouse,Object.Premise, Object.Date);
	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		SeriesSpecificationParameters.LinkFields.Add("Cell");
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";	
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	
	SeriesSpecificationParameters.ItSWarrant = True;
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.FieldNameRoom = "Premise";
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	SeriesSpecificationParameters.Date = Object.Date;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = False;
		
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
	|	Goods.Count AS Count,
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

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
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
	JobPrintingRules.SurplusesRecord		= True;
	JobPrintingRules.ThisIsAnInvoice			= False;
	JobPrintingRules.FieldNameRoom		= "Premise";
	
	Return JobPrintingRules;
	
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
	|	Document.GoodsSurplusesNote AS HeaderData_
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
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Ref.Premise    AS Premise,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Package            AS Package,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.NumberOfPackages  AS NumberOfPackages,
	|	GoodsTable.Cell              AS Cell,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TRUE                            AS RemainderChanges
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS GoodsTable
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
	|	&Warehouse AS Recipient,
	|	&Premise AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	TRUE AS ThisIsWarehouseRecord
	|FROM
	|	TTTableProducts AS SeriesTable
	|
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
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.GoodsSurplusesNote.Goods AS TabPart
		|WHERE
		|	ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	TextProductLocations =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.Series AS Series,
		|	MAX(TabPart.Package) AS Package
		|INTO ProductLocations
		|FROM
		|	Document.GoodsSurplusesNote.Goods AS TabPart
		|WHERE
		|	TabPart.Ref IN(&Ref)
		|		AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|GROUP BY
		|	TabPart.Ref,
		|	TabPart.Products,
		|	TabPart.Characteristic,
		|	TabPart.Purpose,
		|	TabPart.ControlledLotReference,
		|	TabPart.Series
		|INDEX BY
		|	Ref, Products, Characteristic, Purpose, Series, Package";
		
	TemporaryTableTemplateTexts = New Structure();
	TemporaryTableTemplateTexts.Insert("ProductLocations", TextProductLocations);
	
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
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.GoodsSurplusesNote.Goods AS TabPart
		|		INNER JOIN ProductLocations AS ProductLocations
		|		ON TabPart.Ref = ProductLocations.Ref
		|		AND TabPart.Products = ProductLocations.Products
		|		AND TabPart.Characteristic = ProductLocations.Characteristic
		|		AND TabPart.Purpose = ProductLocations.Purpose
		|		AND TabPart.ControlledLotReference = ProductLocations.ControlledLotReference
		|		AND TabPart.Series = ProductLocations.Series
		|		AND TabPart.Package = ProductLocations.Package
		|WHERE
		|	TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True,
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

	// Reflection of surplus goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "GoodsSurplusesNote";
	PrintCommand.Presentation = NStr("vi = 'Phản ánh hàng thừa';
									|ru = 'Отражение излишков товаров';
									|en = 'Stock surplus recognition'; fa = 'شناسایی مازاد موجودی';
									|it = 'Visualizzazione delle eccedenze delle merci';
									|pl = 'Odzwierciedlenie nadmiarów towarów';
									|tr = 'Ürün fazlalıklarının yansıtılması'");
	PrintCommand.CheckPostingBeforePrint = True;

	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");

	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "Document.GoodsSurplusesNote";
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
		PrintCommand.PrintManager = "Document.GoodsSurplusesNote";
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsSurplusesNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsSurplusesNote",
			NStr("vi = 'Phản ánh hàng thừa';
				|ru = 'Отражение излишков товаров';
				|en = 'Stock surplus recognition'; fa = 'شناسایی مازاد موجودی';
				|it = 'Visualizzazione delle eccedenze delle merci';
				|pl = 'Odzwierciedlenie nadmiarów towarów';
				|tr = 'Ürün fazlalıklarının yansıtılması'"),
			PrintReflectionOfSurplusGoodsInStock(ObjectsArray, PrintObjects));
		
	EndIf;
	
EndProcedure

Function PrintReflectionOfSurplusGoodsInStock(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTING_OrderForReflectionOfSurplusGoods_ReflectionOfSurplusGoods";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	                      
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsSurplusesNote.Ref,
	|	PRESENTATION(GoodsSurplusesNote.Warehouse) AS WarehousePresentation,
	|	GoodsSurplusesNote.Date,
	|	GoodsSurplusesNote.Number,
	|	CASE
	|		WHEN GoodsSurplusesNote.Warehouse.UseWarerooms
	|				AND GoodsSurplusesNote.Date >= GoodsSurplusesNote.Warehouse.StartDateOfWareroomUse
	|			THEN GoodsSurplusesNote.Premise.CurrentEmployeeInChargeTypes
	|		ELSE GoodsSurplusesNote.Warehouse.CurrentEmployeeInChargeTypes
	|	END AS Warehouseman,
	|	CASE
	|		WHEN GoodsSurplusesNote.Warehouse.UseWarerooms
	|				AND GoodsSurplusesNote.Date >= GoodsSurplusesNote.Warehouse.StartDateOfWareroomUse
	|			THEN GoodsSurplusesNote.Premise.CurrentPositionOfTheResponsiblePerson
	|		ELSE GoodsSurplusesNote.Warehouse.CurrentPositionOfTheResponsiblePerson
	|	END AS StorekeeperPosition_,
	|	GoodsSurplusesNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	GoodsSurplusesNote.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsSurplusesNote.Warehouse.UseWarerooms
	|				AND GoodsSurplusesNote.Date >= GoodsSurplusesNote.Warehouse.StartDateOfWareroomUse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarerooms,
	|	PRESENTATION(GoodsSurplusesNote.Premise) AS PremisePresentation,
	|	GoodsSurplusesNote.Premise AS Premise
	|FROM
	|	Document.GoodsSurplusesNote AS GoodsSurplusesNote
	|WHERE
	|	GoodsSurplusesNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	GoodsSurplusesNote.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsSurplusesNote.Ref AS Ref,
	|	&OutputCodes AS AdditionalColumn,
	|	CASE
	|		WHEN GoodsSurplusesNote.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
	|			THEN NULL
	|		ELSE PRESENTATION(GoodsSurplusesNote.Cell)
	|	END AS CellPresentation,
	|	GoodsSurplusesNote.Products.DescriptionFull AS ProductPresentation,
	|	GoodsSurplusesNote.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	CASE
	|		WHEN GoodsSurplusesNote.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
	|			THEN NULL
	|		ELSE GoodsSurplusesNote.Series.Description
	|	END AS BatchPresentation,
	|	GoodsSurplusesNote.Products AS Products,
	|	GoodsSurplusesNote.Characteristic AS Characteristic,
	|	GoodsSurplusesNote.Package.Description AS PackagingPresentation,
	|	SUM(GoodsSurplusesNote.NumberOfPackages) AS NumberOfPackages,
	|	SUM(GoodsSurplusesNote.NumberOfPackages) AS Count,
	|	PRESENTATION(GoodsSurplusesNote.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	CASE
	|		WHEN GoodsSurplusesNote.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(GoodsSurplusesNote.Package)
	|		ELSE PRESENTATION(GoodsSurplusesNote.Products.UnitOfMeasure)
	|	END AS PresentationOfPackingUnit,
	|	GoodsSurplusesNote.Products.ProductKind.BatchUsageSettings AS BatchUsageSettings
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS GoodsSurplusesNote
	|WHERE
	|	GoodsSurplusesNote.Ref IN(&ObjectsArray)
	|
	|GROUP BY
	|	GoodsSurplusesNote.Ref,
	|	&OutputCodes,
	|	GoodsSurplusesNote.Products.DescriptionFull,
	|	GoodsSurplusesNote.Characteristic.DescriptionFull,
	|	CASE
	|		WHEN GoodsSurplusesNote.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
	|			THEN NULL
	|		ELSE GoodsSurplusesNote.Series.Description
	|	END,
	|	GoodsSurplusesNote.Products,
	|	GoodsSurplusesNote.Characteristic,
	|	GoodsSurplusesNote.Package.Description,
	|	GoodsSurplusesNote.Products.ProductKind.BatchUsageSettings,
	|	CASE
	|		WHEN GoodsSurplusesNote.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
	|			THEN NULL
	|		ELSE PRESENTATION(GoodsSurplusesNote.Cell)
	|	END,
	|	PRESENTATION(GoodsSurplusesNote.Products.UnitOfMeasure),
	|	CASE
	|		WHEN GoodsSurplusesNote.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(GoodsSurplusesNote.Package)
	|		ELSE PRESENTATION(GoodsSurplusesNote.Products.UnitOfMeasure)
	|	END
	|
	|ORDER BY
	|	Ref,
	|	Products,
	|	Characteristic
	|TOTALS BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series.Description AS BatchPresentation
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
	|	AND NOT TableOfGoods.Series IS NULL 
	|
	|ORDER BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	BatchPresentation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	PRESENTATION(TableOfGoods.Cell) AS CellPresentation
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Products.ProductKind.BatchUsageSettings = VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)
	|	AND NOT TableOfGoods.Cell IS NULL 
	|
	|ORDER BY
	|	Ref,
	|	Products,
	|	Characteristic";
	
	If OutputCodes Then
		Query.Text = StrReplace(Query.Text, "&OutputCodes", "GoodsSurplusesNote.Products." + NameOfCodeColumn);
	Else	
		Query.Text = StrReplace(Query.Text, "&OutputCodes AS AdditionalColumn,", "");
		Query.Text = StrReplace(Query.Text, "&OutputCodes,", "");
	EndIf;
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Results = Query.ExecuteBatch(); 
	
	SelectionByDocuments 	 = Results[0].Select();
	SelectionByTableParts = Results[1].Select(QueryResultIteration.ByGroups);
	SelectionBySeries 		 = Results[2].Select();
	CellSelection		 = Results[3].Select();
	
	FirstDocument = True;
	
	DocumentAttributes = New Structure("Number, Date, Prefix");
	
	DocumentSynonym = "";
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		OutputCellsAndPackages = WarehousesServer.UseBinLocationWarehousing(SelectionByDocuments.Warehouse, SelectionByDocuments.Premise, SelectionByDocuments.Date);
		
		// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
		Template = PrintManagement.PrintFormTemplate("Document.GoodsSurplusesNote.PF_MXL_GoodsSurplusesNote");
		
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
		
		HeaderDataStructure = New Structure;
		HeaderDataStructure.Insert("TitleText", 
				TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		HeaderArea_.Parameters.Fill(HeaderDataStructure);

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
		
		LineNumber = 1;
		
		SamplingByTSLinks = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		While SamplingByTSLinks.Next() Do
			
			SamplingByTSProduct = SamplingByTSLinks.Select(QueryResultIteration.ByGroups);
			
			While SamplingByTSProduct.Next() Do
				
				SamplingByTSLines = SamplingByTSProduct.Select(QueryResultIteration.ByGroups);
				
				If SamplingByTSProduct.BatchUsageSettings = Enums.ItemsBatchUsageSettings.InventoryItem Then
					
					StringOfPackages = "";
					StringQuantityOfPackages = "";
					UnitString = "";
					CountRow = "";
					RowOfCells = "";
					
					While SamplingByTSLines.Next() Do
						
						If OutputCellsAndPackages Then
							StringOfPackages = StringOfPackages + SamplingByTSLines.PresentationOfPackingUnit + Chars.LF;
							StringQuantityOfPackages = StringQuantityOfPackages + SamplingByTSLines.NumberOfPackages + Chars.LF;
						EndIf;
						
						UnitString = UnitString + SamplingByTSLines.PresentationOfBasicUnitOfMeasure + Chars.LF;
						CountRow = CountRow + SamplingByTSLines.Count + Chars.LF;
						
					EndDo;
					
					SamplingByTSLines.Reset();
					
					If SamplingByTSLines.Next() Then
						
						AreaTableRowStart.Parameters.Fill(New Structure("LineNumber", LineNumber));
						SpreadsheetDocument.Put(AreaTableRowStart);
						
						TheStructureOfTheSearch = New Structure;
						TheStructureOfTheSearch.Insert("Ref", SamplingByTSLines.Ref);
						TheStructureOfTheSearch.Insert("Products", SamplingByTSLines.Products);
						TheStructureOfTheSearch.Insert("Characteristic", SamplingByTSLines.Characteristic);
						
						If OutputCellsAndPackages Then
							While CellSelection.FindNext(TheStructureOfTheSearch) Do
								RowOfCells = RowOfCells + CellSelection.CellPresentation + Chars.LF;
							EndDo;
							
							AreaTableRowCell.Parameters.CellPresentation = RowOfCells;
							SpreadsheetDocument.Join(AreaTableRowCell);
						EndIf;
						
						If OutputCodes Then
							AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines.AdditionalColumn;
							SpreadsheetDocument.Join(AreaTableRowCodeColumn);
						EndIf;
						
						SeriesString = "";
						While SelectionBySeries.FindNext(TheStructureOfTheSearch) Do
							SeriesString = SeriesString + SelectionBySeries.BatchPresentation + ", ";
						EndDo;
						
						If StrLen(SeriesString) <> 0 Then
							SeriesString = Left(SeriesString, StrLen(SeriesString) - 2);
						EndIf;
						
						AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
							SamplingByTSLines.ProductPresentation,
							SamplingByTSLines.CharacteristicPresentation,
							, // Package
							SeriesString,
							AdditionalParametersProductPresentation);
						
						SpreadsheetDocument.Join(AreaTableRowProductColumn);
						
						If OutputCellsAndPackages Then
							AreaTableRowPackingColumn.Parameters.NumberOfPackages = StringQuantityOfPackages;
							AreaTableRowPackingColumn.Parameters.PresentationOfPackingUnit = StringOfPackages;
							SpreadsheetDocument.Join(AreaTableRowPackingColumn);
						EndIf;
						
						AreaTableRowEnd.Parameters.Count = CountRow;
						AreaTableRowEnd.Parameters.PresentationOfBasicUnitOfMeasure = UnitString;
						SpreadsheetDocument.Join(AreaTableRowEnd);
						
						LineNumber = LineNumber + 1;
						
					EndIf;
					
				Else
					
					While SamplingByTSLines.Next() Do
						
						AreaTableRowStart.Parameters.Fill(New Structure("LineNumber", LineNumber));
						SpreadsheetDocument.Put(AreaTableRowStart);
						
						If OutputCellsAndPackages Then
							AreaTableRowCell.Parameters.Fill(SamplingByTSLines);
							SpreadsheetDocument.Join(AreaTableRowCell);
						EndIf;
						
						If OutputCodes Then
							AreaTableRowCodeColumn.Parameters.SKU = SamplingByTSLines.AdditionalColumn;
							SpreadsheetDocument.Join(AreaTableRowCodeColumn);
						EndIf;
						
						AreaTableRowProductColumn.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
							SamplingByTSLines.ProductPresentation,
							SamplingByTSLines.CharacteristicPresentation,
							, // Package
							SamplingByTSLines.BatchPresentation,
							AdditionalParametersProductPresentation);
						
						SpreadsheetDocument.Join(AreaTableRowProductColumn);
						
						If OutputCellsAndPackages Then
							AreaTableRowPackingColumn.Parameters.Fill(SamplingByTSLines);
							SpreadsheetDocument.Join(AreaTableRowPackingColumn);
						EndIf;
						
						AreaTableRowEnd.Parameters.Fill(SamplingByTSLines);
						SpreadsheetDocument.Join(AreaTableRowEnd);
						
						LineNumber = LineNumber + 1;
						
					EndDo;
					
				EndIf;
				
			EndDo;
			
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
	|	TaskData_.Ref					AS Ref,
	|	PRESENTATION(TaskData_.Ref)		AS RefPresentation,
	|	TaskData_.Number						AS Number,
	|	TaskData_.Date						AS Date,
	|	TaskData_.Warehouse						AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)		AS WarehousePresentation,
	|	PRESENTATION(TaskData_.Premise)	AS PremisePresentation,
	|	FALSE									AS ThisIsAnInvoice,
	|	FALSE									AS BinLocationWarehousingIsUsed,
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
	|	END									AS ReferenceStorageIsUsed,
	|	CASE
	|		WHEN TaskData_.Warehouse.UseWarerooms
	|				AND TaskData_.Date >= TaskData_.Warehouse.StartDateOfWareroomUse
	|			THEN TaskData_.Premise.WarehouseZoneUsage
	|		ELSE TaskData_.Warehouse.WarehouseZoneUsage
	|	END									AS WarehouseZoneUsage,
	|	FALSE									AS AdvancedWarehousingIsUsed
	|FROM
	|	Document.GoodsSurplusesNote AS TaskData_
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
	|	TableOfGoods.NumberOfPackages					AS NumberOfPackages
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
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
	|	AND TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic";
	
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
		|	Document.GoodsSurplusesNote.Goods AS DocumentGoods
		|		LEFT JOIN Document.GoodsSurplusesNote AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
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
		|	Document.GoodsSurplusesNote.Goods AS DocumentGoods
		|		LEFT JOIN Document.GoodsSurplusesNote AS DocumentData
		|		ON DocumentGoods.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentGoods.Ref IN(&ObjectsArray)
		|	AND ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
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
		|		Document.GoodsSurplusesNote.Goods AS DocumentGoods
		|	
		|	WHERE
		|		DocumentGoods.Ref IN(&ObjectsArray)
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
		|		INNER JOIN Document.GoodsSurplusesNote.Goods AS DocumentGoods
		|		ON GoodsWithoutPackaging_.Ref = DocumentGoods.Ref
		|			AND GoodsWithoutPackaging_.Products = DocumentGoods.Products
		|			AND GoodsWithoutPackaging_.Characteristic = DocumentGoods.Characteristic
		|			AND GoodsWithoutPackaging_.Purpose = DocumentGoods.Purpose
		|			AND GoodsWithoutPackaging_.Series = DocumentGoods.Series
		|			AND GoodsWithoutPackaging_.Package = DocumentGoods.Package
		|		
		|		LEFT JOIN Document.GoodsSurplusesNote AS DocumentData
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

Function LabelPrintingData(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package       AS Package,
	|	Goods.Series          AS Series,
	|	MIN(Goods.LineNumber)        AS Order,
	|	SUM(Goods.NumberOfPackages)   AS Count
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND CASE
	|		WHEN Goods.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			AND Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
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
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package       AS Package,
	|	Goods.Series          AS Series,
	|	MIN(Goods.LineNumber)      AS Order,
	|	SUM(Goods.NumberOfPackages) AS Count
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND CASE
	|		WHEN Goods.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems), VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			AND Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Package,
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
	|	Goods.Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count
	|INTO TTTableProducts
	|FROM
	|	Document.GoodsSurplusesNote.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND ISNULL(Goods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	SUM(GoodsCount.Count)
	|FROM
	|	(SELECT
	|		GoodsPackage.Ref AS Ref,
	|		GoodsPackage.Products AS Products,
	|		GoodsPackage.Characteristic AS Characteristic,
	|		GoodsPackage.Purpose AS Purpose,
	|		GoodsPackage.Series AS Series,
	|		MAX(GoodsPackage.Package) AS Package,
	|		GoodsPackage.BatchesIndicationStatus AS BatchesIndicationStatus
	|	FROM
	|		Document.GoodsSurplusesNote.Goods AS GoodsPackage
	|	WHERE
	|		GoodsPackage.Ref = &Ref
	|		AND ISNULL(GoodsPackage.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	
	|	GROUP BY
	|		GoodsPackage.Ref,
	|		GoodsPackage.Products,
	|		GoodsPackage.Characteristic,
	|		GoodsPackage.Purpose,
	|		GoodsPackage.Series,
	|		GoodsPackage.BatchesIndicationStatus) AS Table
	|		INNER JOIN Document.GoodsSurplusesNote.Goods AS GoodsCount
	|		ON Table.Ref = GoodsCount.Ref
	|			AND Table.Products = GoodsCount.Products
	|			AND Table.Characteristic = GoodsCount.Characteristic
	|			AND Table.Series = GoodsCount.Series
	|			AND Table.Purpose = GoodsCount.Purpose
	|			AND Table.Package = GoodsCount.Package
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
