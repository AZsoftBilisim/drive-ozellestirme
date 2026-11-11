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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsShortageNote") Then
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
	
	Documents.WriteOffOfGoodsShortages.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create a document "Order to reflect the shortage of goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsShortageNote) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsShortageNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsShortageNote);
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
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsShortageNote";
	SeriesSpecificationParameters.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShortageRecord);
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
	
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
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
	|	Document.GoodsShortageNote AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",            Attributes.Period);
	Query.SetParameter("Warehouse",             Attributes.Warehouse);
	Query.SetParameter("Premise",         Attributes.Premise);
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
	|	-GoodsTable.Count         AS Count,
	|	-GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Cell              AS Cell,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TRUE                            AS RemainderChanges
	|FROM
	|	Document.GoodsShortageNote.Goods AS GoodsTable
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
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period
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
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.GoodsShortageNote.Goods AS TabPart
		|WHERE
		|	ISNULL(TabPart.Package.PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
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
		|	Document.GoodsShortageNote.Goods AS TabPart
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
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.GoodsShortageNote.Goods AS TabPart
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

	// Reflection of shortages of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "GoodsShortageNote";
	PrintCommand.Presentation = NStr("vi = 'Phản ánh hàng thiếu';
									|ru = 'Отражение недостач товаров';
									|en = 'Inventory shortage recognition'; fa = 'Inventory shortage recognition';
									|it = 'Visualizzazione degli ammanchi delle merci';
									|pl = 'Odzwierciedlenie niedostatków towarów';
									|tr = 'Ürün eksikliğini yansıtma'");
	PrintCommand.CheckPostingBeforePrint = True;

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsShortageNote") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsShortageNote",
			NStr("vi = 'Phản ánh hàng thiếu';
				|ru = 'Отражение недостач товаров';
				|en = 'Inventory shortage recognition'; fa = 'Inventory shortage recognition';
				|it = 'Visualizzazione degli ammanchi delle merci';
				|pl = 'Odzwierciedlenie niedostatków towarów';
				|tr = 'Ürün eksikliğini yansıtma'"),
			PrintingReflectionOfShortagesOfGoodsInWarehouse(ObjectsArray, PrintObjects));
	EndIf;
EndProcedure

Function PrintingReflectionOfShortagesOfGoodsInWarehouse(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTING_OrderForReflectionOfShortageOfGoods_ReflectionOfShortageOfGoods";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsShortageNote.Ref,
	|	PRESENTATION(GoodsShortageNote.Warehouse) AS WarehousePresentation,
	|	GoodsShortageNote.Date,
	|	GoodsShortageNote.Number,
	|	CASE
	|		WHEN GoodsShortageNote.Warehouse.UseWarerooms
	|			THEN GoodsShortageNote.Premise.CurrentEmployeeInChargeTypes
	|		ELSE GoodsShortageNote.Warehouse.CurrentEmployeeInChargeTypes
	|	END AS Warehouseman,
	|	CASE
	|		WHEN GoodsShortageNote.Warehouse.UseWarerooms
	|			THEN GoodsShortageNote.Premise.CurrentPositionOfTheResponsiblePerson
	|		ELSE GoodsShortageNote.Warehouse.CurrentPositionOfTheResponsiblePerson
	|	END AS StorekeeperPosition_,
	|	GoodsShortageNote.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	GoodsShortageNote.Warehouse AS Warehouse,
	|	CASE
	|		WHEN GoodsShortageNote.Warehouse.UseWarerooms
	|				AND GoodsShortageNote.Date >= GoodsShortageNote.Warehouse.StartDateOfWareroomUse
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarerooms,
	|	PRESENTATION(GoodsShortageNote.Premise) AS PremisePresentation,
	|	GoodsShortageNote.Premise AS Premise
	|FROM
	|	Document.GoodsShortageNote AS GoodsShortageNote
	|WHERE
	|	GoodsShortageNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	GoodsShortageNote.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsShortageNote.Ref AS Ref,
	|	GoodsShortageNote.LineNumber AS LineNumber,
	|   PRESENTATION(GoodsShortageNote.Cell) AS CellPresentation,
	|	GoodsShortageNote.Products.DescriptionFull AS ProductPresentation,
	|	&OutputCodes AS AdditionalColumn,
	|	GoodsShortageNote.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	GoodsShortageNote.Series.Description AS BatchPresentation,
	|	GoodsShortageNote.NumberOfPackages AS NumberOfPackages,
	|	GoodsShortageNote.Count AS Count,
	|	PRESENTATION(GoodsShortageNote.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	CASE
	|		WHEN GoodsShortageNote.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN PRESENTATION(GoodsShortageNote.Package)
	|		ELSE PRESENTATION(GoodsShortageNote.Products.UnitOfMeasure)
	|	END AS PresentationOfPackingUnit
	|FROM
	|	Document.GoodsShortageNote.Goods AS GoodsShortageNote
	|WHERE
	|	GoodsShortageNote.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	If OutputCodes Then
		Query.Text = StrReplace(Query.Text, "&OutputCodes", "GoodsShortageNote.Products." + NameOfCodeColumn);
	Else
		Query.Text = StrReplace(Query.Text, "&OutputCodes AS AdditionalColumn,", "");
	EndIf;
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Results = Query.ExecuteBatch(); 
	
	SelectionByDocuments = Results[0].Select();
	SelectionByTableParts = Results[1].Select(QueryResultIteration.ByGroups);
	
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
		Template = PrintManagement.PrintFormTemplate("Document.GoodsShortageNote.PF_MXL_GoodsShortageNote");
		
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
	|	Document.GoodsShortageNote.Goods AS Goods
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
	|		Document.GoodsShortageNote.Goods AS GoodsPackage
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
	|		INNER JOIN Document.GoodsShortageNote.Goods AS GoodsCount
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
