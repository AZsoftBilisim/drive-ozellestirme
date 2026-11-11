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

	If TypeOf(Document) = Type("DocumentObject.GoodsMisgradingNote") Then
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

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	DataProcessors.WarehouseGoodsIssueReceiptWizard.AddCreateCommandBasedOnWarehouseActRegistrationForm(
		GenerationCommands);

	Documents.GoodsMisgrading.AddGenerateCommand(GenerationCommands);

	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);

EndProcedure

// Adds the command to create the document "Order to reflect the re-sorting of goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsMisgradingNote) Then

		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsMisgradingNote.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
												Metadata.Documents.GoodsMisgradingNote);
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;

	EndIf;

	Return Undefined;
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

	Reports.UnregisteredSurplusesAndShortagesOfGoods.AddDesignCommand(ReportsCommands);
EndProcedure

#EndRegion

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export

	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();

	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	
	// The Balance of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True,
		"Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");

	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True,
		"Object.Goods.AssignmentGoodsReceipt");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;

	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.ProductsRecordingAsReceived";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.CharacteristicRecordingAsReceived";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
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
	
	Action_Parameters = New Structure;
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
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
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export

	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsMisgradingNote";

	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;

	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.SurplusesRecord);
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShortageRecord);

	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentGoodsReceipt");

	SeriesSpecificationParameters.UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Object.Warehouse,
		Object.Premise, Object.Date);

	If SeriesSpecificationParameters.UseBinLocationWarehousing Then
		SeriesSpecificationParameters.LinkFields.Add("Cell");
		SeriesSpecificationParameters.LinkFields.Add("Package");
		SeriesSpecificationParameters.LinkFields.Add("PackagingReceipt");

		SeriesSpecificationParameters.FieldNameQuantity = "NumberOfPackages";
	EndIf;

	SeriesSpecificationParameters.ItSWarrant                               = True;
	SeriesSpecificationParameters.TSSeriesName                             = "Goods";
	SeriesSpecificationParameters.FieldNameRoom                       = "Premise";
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	SeriesSpecificationParameters.Date                                   = Object.Date;
	SeriesSpecificationParameters.SpecialCheckingOfSeriesIndicationStatuses = True;

	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Series", "BatchReceipt");

	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusReceipt");

	SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("BatchesIndicationStatus", "Series");
	SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("BatchesIndicationStatusReceipt",
		"BatchReceipt");

	Return SeriesSpecificationParameters;

EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - the composition of fields is set in the function
//		Nomenclaturales.Parametrizatsii.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export

	QueryText = "SELECT
				   |	Goods.LineNumber                                      AS LineNumber,
				   |	Goods.Products                                     AS Products,
				   |	Goods.Characteristic                                   AS Characteristic,
				   |	Goods.Series                                            AS Series,
				   |	Goods.BatchesIndicationStatus                              AS BatchesIndicationStatus,
				   |	Goods.ProductsRecordingAsReceived                        AS ProductsRecordingAsReceived,
				   |	Goods.CharacteristicRecordingAsReceived                      AS CharacteristicRecordingAsReceived,
				   |	Goods.BatchReceipt                               AS BatchReceipt,
				   |	Goods.BatchesIndicationStatusReceipt                 AS BatchesIndicationStatusReceipt,
				   |	Goods." + SeriesSpecificationParameters.FieldNameQuantity + " AS Count
																			  |INTO Goods
																			  |FROM
																			  |	&Goods AS Goods
																			  |;
																			  |
																			  |////////////////////////////////////////////////////////////////////////////////
																			  |SELECT
																			  |	Goods.LineNumber                                                                     AS LineNumber,
																			  |	Goods.Products                                                                    AS Products,
																			  |	CAST(Goods.Products AS Catalog.Products).ProductKind              AS ProductKind,
																			  |	Goods.Characteristic                                                                  AS Characteristic,
																			  |	Goods.Series                                                                           AS Series,
																			  |	Goods.BatchesIndicationStatus                                                             AS BatchesIndicationStatus,
																			  |	Goods.ProductsRecordingAsReceived                                                       AS ProductsRecordingAsReceived,
																			  |	CAST(Goods.ProductsRecordingAsReceived AS Catalog.Products).ProductKind AS TypeOfProductEntry,
																			  |	Goods.CharacteristicRecordingAsReceived                                                     AS CharacteristicRecordingAsReceived,
																			  |	Goods.BatchReceipt                                                              AS BatchReceipt,
																			  |	Goods.BatchesIndicationStatusReceipt                                                AS BatchesIndicationStatusReceipt,
																			  |	Goods.Count                                                                      AS Count
																			  |INTO ProductsToRequest
																			  |FROM
																			  |	Goods AS Goods
																			  |;
																			  |
																			  |////////////////////////////////////////////////////////////////////////////////
																			  |SELECT
																			  |	Goods.LineNumber         AS LineNumber,
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
																			  |	END                      AS BatchesIndicationStatus,
																			  |	Goods.BatchesIndicationStatusReceipt AS OldStatusOfSeriesReference,
																			  |	CASE
																			  |		WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy IS NULL
																			  |			THEN 0
																			  |		ELSE CASE
																			  |				WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.UseCostAccountingByBatches
																			  |					THEN CASE
																			  |							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
																			  |								THEN 14
																			  |							ELSE 13
																			  |						END
																			  |				WHEN NOT &SeriesOnlyForCostPrice
																			  |					THEN CASE
																			  |							WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.SpecifyWhenPlanningShipment
																			  |								THEN CASE
																			  |										WHEN Goods.Count > 0
																			  |											THEN 10
																			  |										ELSE 9
																			  |									END
																			  |							WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.SpecifyWhenPlanningPicking
																			  |								THEN CASE
																			  |										WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.BatchesAccountingByFEFO
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
																			  |							WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.SpecifyWhenRecordingSurpluses
																			  |								THEN CASE
																			  |										WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.AccountForRemainingSeries
																			  |											THEN CASE
																			  |													WHEN Goods.Count > 0
																			  |														THEN 4
																			  |													ELSE 3
																			  |												END
																			  |										ELSE CASE
																			  |												WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.SpecifyWhenRecordingSurpluses
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
																			  |	END                      AS BatchesIndicationStatusReceipt
																			  |INTO Statuses
																			  |FROM
																			  |	ProductsToRequest AS Goods
																			  |		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
																			  |			INNER JOIN Catalog.Warehouses AS Warehouses
																			  |			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
																			  |		ON &Warehouse = BatchAccountingPolicies.Warehouse
																			  |			AND Goods.ProductKind = BatchAccountingPolicies.Ref
																			  |		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS AccountingPoliciesAndLogging
																			  |			INNER JOIN Catalog.Warehouses AS WarehousesRegistration
																			  |			ON AccountingPoliciesAndLogging.Warehouse = WarehousesRegistration.Ref
																			  |		ON &Warehouse = AccountingPoliciesAndLogging.Warehouse
																			  |			AND Goods.TypeOfProductEntry = AccountingPoliciesAndLogging.Ref
																			  |;
																			  |
																			  |////////////////////////////////////////////////////////////////////////////////
																			  |SELECT
																			  |	Statuses.LineNumber                      AS LineNumber,
																			  |	Statuses.BatchesIndicationStatus              AS BatchesIndicationStatus,
																			  |	Statuses.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt
																			  |FROM
																			  |	Statuses AS Statuses
																			  |WHERE
																			  |	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
																			  |		OR Statuses.BatchesIndicationStatusReceipt <> Statuses.OldStatusOfSeriesReference
																			  |
																			  |ORDER BY
																			  |	Statuses.LineNumber";

	Return QueryText;

EndFunction

// Returns the request text to check whether the series is filled in.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToCheckSeriesFilling(SeriesSpecificationParameters) Export

	QueryText =
	"SELECT
	|	TableOfSeries.LineNumber AS LineNumber,
	|	TableOfSeries.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfSeries.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfSeries.Products AS Products,
	|	TableOfSeries.Characteristic AS Characteristic,
	|	TableOfSeries.Series AS Series,
	|	TableOfSeries.Package AS Package,
	|	TableOfSeries.NumberOfPackages AS NumberOfPackages,
	|	TableOfSeries.BatchReceipt AS BatchReceipt,
	|	TableOfSeries.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt,
	|	TableOfSeries.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO SeriesPreparatoryTable
	|FROM
	|	&TableOfSeries_QueryNumber AS TableOfSeries
	|WHERE
	|	(TableOfSeries.BatchesIndicationStatus > 0
	|				AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|			OR TableOfSeries.BatchesIndicationStatusReceipt > 0
	|				AND NOT TableOfSeries.BatchesIndicationStatusReceipt IN (&SeriesStatusesYouCanSpecifySeries))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.LineNumber AS LineNumber,
	|	TableOfSeries.Products AS Products,
	|	TableOfSeries.Characteristic AS Characteristic,
	|	TableOfSeries.Series AS Series,
	|	""Series"" AS FieldNameSeries,
	|	TableOfSeries.Package AS Package,
	|	TableOfSeries.NumberOfPackages AS NumberOfPackages
	|INTO SeriesTableForQuery
	|FROM
	|	SeriesPreparatoryTable AS TableOfSeries
	|WHERE
	|	TableOfSeries.BatchesIndicationStatus > 0
	|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.LineNumber,
	|	TableOfSeries.ProductsRecordingAsReceived,
	|	TableOfSeries.CharacteristicRecordingAsReceived,
	|	TableOfSeries.BatchReceipt,
	|	""BatchReceipt"",
	|	TableOfSeries.Package,
	|	TableOfSeries.NumberOfPackages
	|FROM
	|	SeriesPreparatoryTable AS TableOfSeries
	|WHERE
	|	TableOfSeries.BatchesIndicationStatusReceipt > 0
	|	AND NOT TableOfSeries.BatchesIndicationStatusReceipt IN (&SeriesStatusesYouCanSpecifySeries)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SeriesPreparatoryTable";

	Return QueryText;

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

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// Reflection of damage to goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id                  = "GoodsMisgradingNote";
	PrintCommand.Presentation                  = NStr("vi = 'Phản ánh của việc tái tổ hợp hàng hóa';
														|ru = 'Отражение пересортицы товаров';
														|en = 'Stock reclass record'; fa = 'Stock reclass record';
														|it = 'Visualizzazione della riclassificazione merci';
														|pl = 'Odzwierciedlenie przeklasyfikowania towarów';
														|tr = 'Stok yeniden sınıflandırmasının yansıması'");
	PrintCommand.CheckPostingBeforePrint = True;

	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler                     = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager                 = "Document.GoodsMisgradingNote";
		PrintCommand.Id                  = "PriceTags";
		PrintCommand.Presentation                  = NStr("vi = 'Nhãn giá';
															|ru = 'Ценники';
															|en = 'Price tags'; fa = 'برچسب‌های قیمت';
															|it = 'Cartellini del prezzo';
															|pl = 'Price tags';
															|tr = 'Fiyat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler                     = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager                 = "Document.GoodsMisgradingNote";
		PrintCommand.Id                  = "Labels";
		PrintCommand.Presentation                  = NStr("vi = 'Nhãn tem';
															|ru = 'Этикетки';
															|en = 'Labels'; fa = 'برچسب‌ها';
															|it = 'Etichette';
															|pl = 'Labels';
															|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;

EndProcedure

// Forms printed forms of the object.
//
// Parameters:
//	ObjectsArray        - Array           - an array of references to objects which need to print,
//	PrintParameters       - Structure        - structure of additional print parameters,
//	PrintFormsCollection - ValueTable  - generated table documents,
//	PrintObjects         - ValueList   - list of print objects,
//	OutputParameters       - Structure        - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	TemplateName = "GoodsMisgradingNote";

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, TemplateName) Then
		TemplateSynonym = NStr("vi = 'Phản ánh hàng hỏng';
								|ru = 'Отражение порчи товаров';
								|en = 'Inventory quality change recognition'; fa = 'Inventory quality change recognition';
								|it = 'Visualizzazione dei deterioramenti delle merci';
								|pl = 'Odzwierciedlenie uszkodzeń towarów';
								|tr = 'Ürün stok kalite değişikliği yansıtma'");

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, TemplateName, TemplateSynonym,
			PrintingReflectionOfReSortingOfGoodsInWarehouse(ObjectsArray, PrintObjects));
	EndIf;

EndProcedure

// The function generates a printed form of documents for orders to reflect the re-sorting of goods.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - the printed form of the documents of the orders for the reflection of the re-sorting of goods.
//
Function PrintingReflectionOfReSortingOfGoodsInWarehouse(ObjectsArray, PrintObjects)

	SetPrivilegedMode(True);

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PARAMETERS_PRINTING_OrderToReflectDamageToGoods_ReflectionOfReSortingOfGoods";

	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);

	Query = New Query;
	Query.Text =
	"SELECT
	|	OrderToRepelReSorting.Ref                       AS Ref,
	|	PRESENTATION(OrderToRepelReSorting.Warehouse)         AS WarehousePresentation,
	|	OrderToRepelReSorting.Date                         AS Date,
	|	OrderToRepelReSorting.Number                        AS Number,
	|	CASE
	|		WHEN OrderToRepelReSorting.Warehouse.UseWarerooms
	|				AND OrderToRepelReSorting.Date >= OrderToRepelReSorting.Warehouse.StartDateOfWareroomUse
	|			THEN OrderToRepelReSorting.Premise.CurrentEmployeeInChargeTypes
	|		ELSE OrderToRepelReSorting.Warehouse.CurrentEmployeeInChargeTypes
	|	END                                                    AS Warehouseman,
	|	CASE
	|		WHEN OrderToRepelReSorting.Warehouse.UseWarerooms
	|				AND OrderToRepelReSorting.Date >= OrderToRepelReSorting.Warehouse.StartDateOfWareroomUse
	|			THEN OrderToRepelReSorting.Premise.CurrentPositionOfTheResponsiblePerson
	|		ELSE OrderToRepelReSorting.Warehouse.CurrentPositionOfTheResponsiblePerson
	|	END                                                    AS StorekeeperPosition_,
	|	OrderToRepelReSorting.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	OrderToRepelReSorting.Warehouse                        AS Warehouse,
	|	CASE
	|		WHEN OrderToRepelReSorting.Warehouse.UseWarerooms
	|				AND OrderToRepelReSorting.Date >= OrderToRepelReSorting.Warehouse.StartDateOfWareroomUse
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                    AS UseWarerooms,
	|	PRESENTATION(OrderToRepelReSorting.Premise)     AS PremisePresentation,
	|	OrderToRepelReSorting.Premise                    AS Premise
	|FROM
	|	Document.GoodsMisgradingNote AS OrderToRepelReSorting
	|WHERE
	|	OrderToRepelReSorting.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	OrderToRepelReSorting.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsOfOrder.Ref                                       AS Ref,
	|	GoodsOfOrder.LineNumber                                  AS LineNumber,
	|	PRESENTATION(GoodsOfOrder.Cell)                        AS CellPresentation,
	|	&ColumnOfCodes1                                            AS AdditionalColumn,
	|	GoodsOfOrder.Products.DescriptionFull              AS ProductPresentation,
	|	GoodsOfOrder.Characteristic.DescriptionFull            AS CharacteristicPresentation,
	|	GoodsOfOrder.Series.Description                           AS BatchPresentation,
	|	&ColumnOfCodes2                                            AS AdditionalColumnRegistration,
	|	GoodsOfOrder.ProductsRecordingAsReceived.DescriptionFull AS PresentationOfSpoiledProducts,
	|	PRESENTATION(GoodsOfOrder.CharacteristicRecordingAsReceived)   AS PresentationOfCharacteristicsOfSpoiledProduct,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|			THEN UNDEFINED
	|		ELSE GoodsOfOrder.Package.Description
	|	END                                                     AS PackagingPresentation,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor2, 1) = 1
	|			THEN UNDEFINED
	|		ELSE GoodsOfOrder.PackagingReceipt.Description
	|	END                                                     AS PresentationOfPackagingOfSpoiledProducts,
	|	GoodsOfOrder.BatchReceipt.Description              AS PresentationOfSeriesOfSpoiledProducts,
	|	GoodsOfOrder.Count                                   AS Count,
	|	GoodsOfOrder.NumberOfPackages                           AS NumberOfPackages,
	|	PRESENTATION(GoodsOfOrder.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	&QueryTextUnitOfMeasureDescription                 AS PresentationOfPackingUnit
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS GoodsOfOrder
	|WHERE
	|	GoodsOfOrder.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS BY
	|	Ref";

	Query.Text = StrReplace(Query.Text, "&ColumnOfCodes1", ?(OutputCodes, "GoodsOfOrder.Products."
		+ NameOfCodeColumn, """"""));

	Query.Text = StrReplace(Query.Text, "&ColumnOfCodes2", ?(OutputCodes,
		"GoodsOfOrder.ProductsRecordingAsReceived." + NameOfCodeColumn, """"""));

	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1", Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsOfOrder.Package", "GoodsOfOrder.Products"));

	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2", Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsOfOrder.PackagingReceipt", "GoodsOfOrder.ProductsRecordingAsReceived"));

	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description", "GoodsOfOrder.Package", "GoodsOfOrder.Products"));

	Query.SetParameter("ObjectsArray", ObjectsArray);

	Results = Query.ExecuteBatch();

	SelectionByDocuments      = Results[0].Select();
	SelectionByTableParts = Results[1].Select(QueryResultIteration.ByGroups);

	DocumentSynonym   = "";
	FirstDocument     = True;
	DocumentAttributes = New Structure("Number, Date, Prefix");

	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();

	While SelectionByDocuments.Next() Do

		If Not SelectionByTableParts.FindNext(New Structure("Ref", SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;

		OutputCellsAndPackages = WarehousesServer.UseBinLocationWarehousing(SelectionByDocuments.Warehouse,
			SelectionByDocuments.Premise, SelectionByDocuments.Date);
		
		// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
		Template = PrintManagement.PrintFormTemplate(
			"Document.GoodsMisgradingNote.PF_MXL_GoodsMisgradingNote");

		HeaderArea_ = Template.GetArea("Title");
		SectionHeader     = Template.GetArea("Header");

		If OutputCellsAndPackages Then

			TableHeaderAreaStart 	= Template.GetArea("TableHeader|BeginningOfTheLine");
			AreaTableRowStart 	= Template.GetArea("TableRow|BeginningOfTheLine");
			AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");

			AreaTableHeaderCell	= Template.GetArea("TableHeader|Cell");
			AreaTableRowCell	= Template.GetArea("TableRow|Cell");
			AreaBasementTableCell	= Template.GetArea("TableFooter|Cell");

			AreaTableHeaderColumnOfWriteOffCodes  = Template.GetArea(
				"TableHeader|ColumnOfCodesOfWrittenOffGoods");
			AreaTableRowColumnOfWriteOffCodes = Template.GetArea(
				"TableRow|ColumnOfCodesOfWrittenOffGoods");
			AreaBasementTablesColumnOfWriteOffCodes = Template.GetArea(
				"TableFooter|ColumnOfCodesOfWrittenOffGoods");

			AreaHeaderOfTableColumnOfItemsDebited 	= Template.GetArea("TableHeader|DebitedProduct");
			AreaTableRowColumnOfItemsDebited 	= Template.GetArea("TableRow|DebitedProduct");
			AreaBasementOfTableColumnOfGoodsWriteOff 	= Template.GetArea("TableFooter|DebitedProduct");

			If OutputCodes Then
				AreaTableHeaderEntryCodeColumn 	= Template.GetArea(
					"TableHeader|ColumnOfIncomingProductCodes");
				AreaTableRowColumnOfArrivalCodes 	= Template.GetArea(
					"TableRow|ColumnOfIncomingProductCodes");
				AreaBasementTableColumnOfParishCodes 	= Template.GetArea(
					"TableFooter|ColumnOfIncomingProductCodes");
			EndIf;

			AreaHeaderOfTableColumnOfGoodsArrival 	= Template.GetArea("TableHeader|IncomingGoods");
			AreaTableRowGoodsColumnArrival 	= Template.GetArea("TableRow|IncomingGoods");
			AreaTableBasementGoodsColumnParishes 	= Template.GetArea("TableFooter|IncomingGoods");

			AreaTableHeaderPackingColumn 	= Template.GetArea("TableHeader|ColumnOfPackages");
			AreaTableRowPackingColumn = Template.GetArea("TableRow|ColumnOfPackages");
			AreaBasementTablePackingColumn	= Template.GetArea("TableFooter|ColumnOfPackages");

			TableHeaderAreaEnd 	= Template.GetArea("TableHeader|EndOfRow");
			AreaTableRowEnd 	= Template.GetArea("TableRow|EndOfRow");
			AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");

		Else

			TableHeaderAreaStart 	= Template.GetArea("TableHeaderWithoutBarley|BeginningOfTheLine");
			AreaTableRowStart 	= Template.GetArea("TableRowWithoutBarley|BeginningOfTheLine");
			AreaBasementTableTop 	= Template.GetArea("TableFooter|BeginningOfTheLine");

			AreaTableHeaderColumnOfWriteOffCodes 	= Template.GetArea(
				"TableHeaderWithoutBarley|ColumnOfCodesWithoutCellOfWrittenOffGoods");
			AreaTableRowColumnOfWriteOffCodes 	= Template.GetArea(
				"TableRowWithoutBarley|ColumnOfCodesWithoutCellOfWrittenOffGoods");
			AreaBasementTablesColumnOfWriteOffCodes 	= Template.GetArea(
				"TableFooter|ColumnOfCodesWithoutCellOfWrittenOffGoods");

			AreaHeaderOfTableColumnOfItemsDebited 	= Template.GetArea(
				"TableHeaderWithoutBarley|DebitedProductWithoutCells");
			AreaTableRowColumnOfItemsDebited 	= Template.GetArea(
				"TableRowWithoutBarley|DebitedProductWithoutCells");
			AreaBasementOfTableColumnOfGoodsWriteOff 	= Template.GetArea(
				"TableFooter|DebitedProductWithoutCells");

			If OutputCodes Then
				AreaTableHeaderEntryCodeColumn 	= Template.GetArea(
					"TableHeaderWithoutBarley|ColumnOfIncomingProductCodes");
				AreaTableRowColumnOfArrivalCodes 	= Template.GetArea(
					"TableRowWithoutBarley|ColumnOfIncomingProductCodes");
				AreaBasementTableColumnOfParishCodes 	= Template.GetArea(
					"TableFooter|ColumnOfIncomingProductCodes");
			EndIf;

			AreaHeaderOfTableColumnOfGoodsArrival 	= Template.GetArea(
				"TableHeaderWithoutBarley|IncomingGoodsWithoutPackaging");
			AreaTableRowGoodsColumnArrival 	= Template.GetArea(
				"TableRowWithoutBarley|IncomingGoodsWithoutPackaging");
			AreaTableBasementGoodsColumnParishes 	= Template.GetArea(
				"TableFooter|IncomingGoodsWithoutPackaging");

			TableHeaderAreaEnd 	= Template.GetArea("TableHeaderWithoutBarley|EndOfRow");
			AreaTableRowEnd 	= Template.GetArea("TableRowWithoutBarley|EndOfRow");
			AreaBasementTableEnd 	= Template.GetArea("TableFooter|EndOfRow");

		EndIf;

		AreaTableHeaderColumnOfWriteOffCodes.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		If OutputCodes Then
			AreaTableHeaderEntryCodeColumn.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
		EndIf;

		SignatureArea = Template.GetArea("Signatures");

		AreaColumnOfItemsDebited = ?(OutputCellsAndPackages, Template.Area("DebitedProduct"), Template.Area(
			"DebitedProductWithoutCells"));

		AreaGoodsColumnName = ?(OutputCellsAndPackages, Template.Area("IncomingGoods"), Template.Area(
			"IncomingGoodsWithoutPackaging"));

		If Not OutputCodes Then
			AreaColumnOfItemsDebited.ColumnWidth = AreaColumnOfItemsDebited.ColumnWidth + ?(
				OutputCellsAndPackages, Template.Area("ColumnOfCodesOfWrittenOffGoods").ColumnWidth, Template.Area(
				"ColumnOfCodesWithoutCellOfWrittenOffGoods").ColumnWidth);

			AreaGoodsColumnName.ColumnWidth = AreaGoodsColumnName.ColumnWidth
				+ Template.Area("ColumnOfIncomingProductCodes").ColumnWidth;
		EndIf;

		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);

		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;

		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;

		FillPropertyValues(DocumentAttributes, SelectionByDocuments);

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

		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, HeaderArea_,
			SelectionByDocuments.Ref);

		SpreadsheetDocument.Put(HeaderArea_);

		SectionHeader.Parameters.Fill(SelectionByDocuments);

		SectionHeader.Parameters.WarehousePresentation = WarehousesServer.GetWarehousePresentation(
			SelectionByDocuments.WarehousePresentation, SelectionByDocuments.PremisePresentation);

		SpreadsheetDocument.Put(SectionHeader);

		SpreadsheetDocument.Put(TableHeaderAreaStart);

		If OutputCellsAndPackages Then
			SpreadsheetDocument.Join(AreaTableHeaderCell);
		EndIf;

		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderColumnOfWriteOffCodes);
		EndIf;

		SpreadsheetDocument.Join(AreaHeaderOfTableColumnOfItemsDebited);

		If OutputCodes Then
			SpreadsheetDocument.Join(AreaTableHeaderEntryCodeColumn);
		EndIf;

		SpreadsheetDocument.Join(AreaHeaderOfTableColumnOfGoodsArrival);

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
				AreaTableRowColumnOfWriteOffCodes.Parameters.SKU = SamplingByTSLines.AdditionalColumn;
				SpreadsheetDocument.Join(AreaTableRowColumnOfWriteOffCodes);
			EndIf;

			AreaTableRowColumnOfItemsDebited.Parameters.OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductPresentation, SamplingByTSLines.CharacteristicPresentation, ,
				SamplingByTSLines.BatchPresentation, AdditionalParametersProductPresentation);
			SpreadsheetDocument.Join(AreaTableRowColumnOfItemsDebited);

			If OutputCodes Then
				AreaTableRowColumnOfArrivalCodes.Parameters.SKU = SamplingByTSLines.AdditionalColumnRegistration;
				SpreadsheetDocument.Join(AreaTableRowColumnOfArrivalCodes);
			EndIf;

			AreaTableRowGoodsColumnArrival.Parameters.DamagedGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.PresentationOfSpoiledProducts,
				SamplingByTSLines.PresentationOfCharacteristicsOfSpoiledProduct,
				SamplingByTSLines.PresentationOfPackagingOfSpoiledProducts,
				SamplingByTSLines.PresentationOfSeriesOfSpoiledProducts, AdditionalParametersProductPresentation);
			SpreadsheetDocument.Join(AreaTableRowGoodsColumnArrival);

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
			SpreadsheetDocument.Join(AreaBasementTablesColumnOfWriteOffCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementOfTableColumnOfGoodsWriteOff);
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaBasementTableColumnOfParishCodes);
		EndIf;
		SpreadsheetDocument.Join(AreaTableBasementGoodsColumnParishes);
		If OutputCellsAndPackages Then
			SpreadsheetDocument.Join(AreaBasementTablePackingColumn);
		EndIf;
		SpreadsheetDocument.Join(AreaBasementTableEnd);
		
		// Output of signatures.
		SignatureArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(
			SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
		SignatureArea.Parameters.Warehouseman = PersonsTM.IndividualShortName(SelectionByDocuments.Warehouseman,
			SelectionByDocuments.Date);
		SignatureArea.Parameters.StorekeeperPosition_ = WarehousesServer.PositionOfResponsiblePersonOfWarehouse(
			SelectionByDocuments.StorekeeperPosition_);
		SpreadsheetDocument.Put(SignatureArea);

		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
			SelectionByDocuments.Ref);

	EndDo;

	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;

	Return SpreadsheetDocument;

EndFunction

// The function generates data for printing labels based on the data in the 'Products' tabular part of the documents
// of orders to reflect the re-sorting of goods.
//
// Parameters:
//	DocumentsArray - Array - array of links to documents of orders to reflect the re-sorting of goods.
//
// Returns:
//	Structure - Label Printing Data:
//		* Goods            - ValueTable - table of products of the document of the order to reflect the re-sorting of goods,
//		* StructureOfActions - Structure - the structure of the actions that you must perform before printing the labels.
//
Function LabelPrintingData(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MIN(Goods.LineNumber)        AS Order,
	|	Goods.ProductsRecordingAsReceived   AS Products,
	|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
	|	Goods.PackagingReceipt       AS Package,
	|	Goods.Series                       AS Series,
	|	SUM(Goods.NumberOfPackages)   AS Count
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND CASE
	|		WHEN Goods.ProductsRecordingAsReceived.UseVariants IN (&OptionsForUsingCharacteristics)
	|				AND Goods.CharacteristicRecordingAsReceived = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
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

	OptionsForUsingCharacteristics = New Array;
	OptionsForUsingCharacteristics.Add(
		Enums.ItemVariantsUsageOptions.CommonForItemKind);
	OptionsForUsingCharacteristics.Add(
		Enums.ItemVariantsUsageOptions.SpecialForItems);
	OptionsForUsingCharacteristics.Add(
		Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind);

	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("OptionsForUsingCharacteristics", OptionsForUsingCharacteristics);

	QueryResult = Query.Execute();
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", Undefined);
	StructureOfActions.Insert("FillInTheWarehouse", Undefined);
	StructureOfActions.Insert("FillInPriceView", Undefined);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("FillInTheGoodsTable");
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", QueryResult.Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date", PricingDate);

	Return PutToTempStorage(ResultingStructure);

EndFunction

// The function generates data for printing price tags based on the data in the table part 'Products' of documents
// of orders to reflect the re-sorting of goods.
//
// Parameters:
//	DocumentsArray - Array - array of links to documents of orders to reflect the re-sorting of goods.
//
// Returns:
//	Structure - Label Printing Data:
//		* Goods            - ValueTable - table of products of the document of the order to reflect the re-sorting of goods,
//		* StructureOfActions - Structure - the structure of the actions that you must perform before printing the labels.
//
Function DataForPrintingPriceTags(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MIN(Goods.LineNumber)        AS Order,
	|	Goods.ProductsRecordingAsReceived   AS Products,
	|	Goods.CharacteristicRecordingAsReceived AS Characteristic,
	|	Goods.PackagingReceipt       AS Package,
	|	Goods.Series                       AS Series,
	|	SUM(Goods.NumberOfPackages)   AS Count
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&DocumentsArray)
	|	AND CASE
	|		WHEN Goods.ProductsRecordingAsReceived.UseVariants IN (&OptionsForUsingCharacteristics)
	|				AND Goods.CharacteristicRecordingAsReceived = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
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
	
	OptionsForUsingCharacteristics = New Array;
	OptionsForUsingCharacteristics.Add(
		Enums.ItemVariantsUsageOptions.CommonForItemKind);
	OptionsForUsingCharacteristics.Add(
		Enums.ItemVariantsUsageOptions.SpecialForItems);
	OptionsForUsingCharacteristics.Add(
		Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind);
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("OptionsForUsingCharacteristics", OptionsForUsingCharacteristics);
	
	QueryResult = Query.Execute();
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization",                  Undefined);
	StructureOfActions.Insert("FillInTheWarehouse",                        Undefined);
	StructureOfActions.Insert("FillInPriceView",                      Undefined);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("FillInTheGoodsTable");
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintingPriceTags");
	StructureOfActions.Insert("FillInTheNumberOfPriceTagsForTheDocument");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods",            QueryResult.Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

#EndRegion

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources;

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)

	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	HeaderData_.Ref    AS Ref,
	|	HeaderData_.Date      AS Period,
	|	HeaderData_.Warehouse     AS Warehouse,
	|	HeaderData_.Premise AS Premise,
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
	|	END                 AS UseBinLocationWarehousing
	|FROM
	|	Document.GoodsMisgradingNote AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";

	Attributes = Query.Execute().Select();

	Attributes.Next();

	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("Warehouse", Attributes.Warehouse);
	Query.SetParameter("Premise", Attributes.Premise);
	Query.SetParameter("UseBinLocationWarehousing", Attributes.UseBinLocationWarehousing);

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
	|	&Ref                                                    AS Recorder,
	|	&Ref                                                    AS Document,
	|	&Period                                                    AS Period,
	|	&Warehouse                                                     AS Sender,
	|	&Premise                                                 AS WareroomOfSender,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	SeriesTable.Products                                  AS Products,
	|	SeriesTable.Characteristic                                AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                      AS Purpose,
	|	SeriesTable.Series                                         AS Series,
	|	SeriesTable.Count                                    AS Count,
	|	UNDEFINED                                               AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)       AS WareroomOfRecipient,
	|	TRUE                                                     AS ThisIsWarehouseRecord
	|FROM
	|	TTTableProducts AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref,
	|	&Ref,
	|	&Period,
	|	UNDEFINED,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord),
	|	SeriesTable.ProductsRecordingAsReceived,
	|	SeriesTable.CharacteristicRecordingAsReceived,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssignmentGoodsReceipt.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.AssignmentGoodsReceipt
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	SeriesTable.BatchReceipt,
	|	SeriesTable.Count,
	|	&Warehouse,
	|	&Premise,
	|	TRUE
	|FROM
	|	TTTableProducts AS SeriesTable
	|WHERE
	|	SeriesTable.BatchReceipt <> VALUE(Catalog.ItemsBatches.EmptyRef)";

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

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
	|	Document.GoodsMisgradingNote.Goods AS GoodsTable
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
	|	GoodsTable.AssignmentGoodsReceipt     AS Purpose,
	|	GoodsTable.ControlledLotReference        AS ControlledLotReference,
	|	GoodsTable.BatchReceipt          AS Series,
	|	GoodsTable.PackagingReceipt       AS Package,
	|	GoodsTable.CountRecordingAsReceived     AS Count,
	|	GoodsTable.NumberOfPackages          AS NumberOfPackages,
	|	GoodsTable.Cell                      AS Cell,
	|	GoodsTable.BatchesIndicationStatusReceipt AS BatchesIndicationStatus,
	|	TRUE                                    AS RemainderChanges
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|";

	WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);

EndProcedure

Function QueryTextTTTableProducts(Query, QueryTexts)

	RegisterName = "TTTableProducts";

	QueryText =
	"SELECT
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	Goods.Purpose                       AS Purpose,
	|	Goods.Series                            AS Series,
	|	Goods.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	Goods.ProductsRecordingAsReceived        AS ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived      AS CharacteristicRecordingAsReceived,
	|	Goods.AssignmentGoodsReceipt          AS AssignmentGoodsReceipt,
	|	Goods.BatchReceipt               AS BatchReceipt,
	|	Goods.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt,
	|	Goods.Count
	|INTO TTTableProducts
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS Goods
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
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived,
	|	Table.AssignmentGoodsReceipt,
	|	Table.BatchReceipt,
	|	Table.BatchesIndicationStatusReceipt,
	|	SUM(GoodsCount.Count)
	|FROM
	|	(SELECT
	|		GoodsPackage.Ref                           AS Ref,
	|		GoodsPackage.Products                     AS Products,
	|		GoodsPackage.Characteristic                   AS Characteristic,
	|		GoodsPackage.Purpose                       AS Purpose,
	|		MAX(GoodsPackage.Package)               AS Package,
	|		GoodsPackage.Series                            AS Series,
	|		GoodsPackage.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|		GoodsPackage.ProductsRecordingAsReceived        AS ProductsRecordingAsReceived,
	|		GoodsPackage.CharacteristicRecordingAsReceived      AS CharacteristicRecordingAsReceived,
	|		GoodsPackage.AssignmentGoodsReceipt          AS AssignmentGoodsReceipt,
	|		MAX(GoodsPackage.PackagingReceipt)  AS PackagingReceipt,
	|		GoodsPackage.BatchReceipt               AS BatchReceipt,
	|		GoodsPackage.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt
	|	FROM
	|		Document.GoodsMisgradingNote.Goods AS GoodsPackage
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
	|		GoodsPackage.BatchesIndicationStatus,
	|		GoodsPackage.ProductsRecordingAsReceived,
	|		GoodsPackage.CharacteristicRecordingAsReceived,
	|		GoodsPackage.AssignmentGoodsReceipt,
	|		GoodsPackage.BatchReceipt,
	|		GoodsPackage.BatchesIndicationStatusReceipt) AS Table
	|		INNER JOIN Document.GoodsMisgradingNote.Goods AS GoodsCount
	|		ON Table.Ref = GoodsCount.Ref
	|			AND Table.Products = GoodsCount.Products
	|			AND Table.Characteristic = GoodsCount.Characteristic
	|			AND Table.Purpose = GoodsCount.Purpose
	|			AND Table.Package = GoodsCount.Package
	|			AND Table.Series = GoodsCount.Series
	|			AND Table.ProductsRecordingAsReceived = GoodsCount.ProductsRecordingAsReceived
	|			AND Table.CharacteristicRecordingAsReceived = GoodsCount.CharacteristicRecordingAsReceived
	|			AND Table.AssignmentGoodsReceipt = GoodsCount.AssignmentGoodsReceipt
	|			AND Table.PackagingReceipt = GoodsCount.PackagingReceipt
	|			AND Table.BatchReceipt = GoodsCount.BatchReceipt
	|
	|GROUP BY
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Series,
	|	Table.BatchesIndicationStatus,
	|	Table.ProductsRecordingAsReceived,
	|	Table.CharacteristicRecordingAsReceived,
	|	Table.AssignmentGoodsReceipt,
	|	Table.BatchReceipt,
	|	Table.BatchesIndicationStatusReceipt";

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
	|	Document.GoodsMisgradingNote.Goods AS TabPart
	|WHERE
	|	ISNULL(TabPart.Package.PackageType,
	|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND ISNULL(TabPart.PackagingReceipt.PackageType,
	|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)";

	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);

	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.ProductsRecordingAsReceived AS Products,
	|	TabPart.CharacteristicRecordingAsReceived AS Characteristic,
	|	TabPart.Ref.Warehouse AS Warehouse,
	|	TabPart.AssignmentGoodsReceipt AS Purpose,
	|	TabPart.ControlledLotReference AS ControlledLotReference,
	|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
	|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS TabPart
	|WHERE
	|	ISNULL(TabPart.Package.PackageType,
	|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND ISNULL(TabPart.PackagingReceipt.PackageType,
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
	|	MAX(TabPart.Package) AS Package,
	|	TabPart.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TabPart.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TabPart.AssignmentGoodsReceipt AS AssignmentGoodsReceipt,
	|	TabPart.BatchReceipt AS BatchReceipt,
	|	MAX(TabPart.PackagingReceipt) AS PackagingReceipt
	|INTO ProductLocations
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS TabPart
	|WHERE
	|	TabPart.Ref IN(&Ref)
	|		AND TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|GROUP BY
	|	TabPart.Ref,
	|	TabPart.Products,
	|	TabPart.Characteristic,
	|	TabPart.Purpose,
	|	TabPart.ControlledLotReference,
	|	TabPart.Series,
	|	TabPart.ProductsRecordingAsReceived,
	|	TabPart.CharacteristicRecordingAsReceived,
	|	TabPart.AssignmentGoodsReceipt,
	|	TabPart.BatchReceipt
	|INDEX BY
	|	Ref, Products, Characteristic, Purpose, Series, Package,
	|	ProductsRecordingAsReceived, CharacteristicRecordingAsReceived, AssignmentGoodsReceipt, BatchReceipt, PackagingReceipt";

	TemporaryTableTemplateTexts = New Structure;
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
	|	Document.GoodsMisgradingNote.Goods AS TabPart
	|		INNER JOIN ProductLocations AS ProductLocations
	|		ON TabPart.Ref = ProductLocations.Ref
	|		AND TabPart.Products = ProductLocations.Products
	|		AND TabPart.Characteristic = ProductLocations.Characteristic
	|		AND TabPart.Purpose = ProductLocations.Purpose
	|		AND TabPart.ControlledLotReference = ProductLocations.ControlledLotReference
	|		AND TabPart.Series = ProductLocations.Series
	|		AND TabPart.Package = ProductLocations.Package
	|		AND TabPart.ProductsRecordingAsReceived = ProductLocations.ProductsRecordingAsReceived
	|		AND TabPart.CharacteristicRecordingAsReceived = ProductLocations.CharacteristicRecordingAsReceived
	|		AND TabPart.AssignmentGoodsReceipt = ProductLocations.AssignmentGoodsReceipt
	|		AND TabPart.BatchReceipt = ProductLocations.BatchReceipt
	|		AND TabPart.PackagingReceipt = ProductLocations.PackagingReceipt
	|WHERE
	|	TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";

	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True,
		TemporaryTableTemplateTexts);

	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	TabPart.ProductsRecordingAsReceived AS Products,
	|	TabPart.CharacteristicRecordingAsReceived AS Characteristic,
	|	TabPart.Ref.Warehouse AS Warehouse,
	|	TabPart.AssignmentGoodsReceipt AS Purpose,
	|	TabPart.ControlledLotReference AS ControlledLotReference,
	|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
	|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count AS Count,
	|	FALSE AS OnSchedule,
	|	UNDEFINED AS OrderInSchedule
	|FROM
	|	Document.GoodsMisgradingNote.Goods AS TabPart
	|		INNER JOIN ProductLocations AS ProductLocations
	|		ON TabPart.Ref = ProductLocations.Ref
	|		AND TabPart.Products = ProductLocations.Products
	|		AND TabPart.Characteristic = ProductLocations.Characteristic
	|		AND TabPart.Purpose = ProductLocations.Purpose
	|		AND TabPart.ControlledLotReference = ProductLocations.ControlledLotReference
	|		AND TabPart.Series = ProductLocations.Series
	|		AND TabPart.Package = ProductLocations.Package
	|		AND TabPart.ProductsRecordingAsReceived = ProductLocations.ProductsRecordingAsReceived
	|		AND TabPart.CharacteristicRecordingAsReceived = ProductLocations.CharacteristicRecordingAsReceived
	|		AND TabPart.AssignmentGoodsReceipt = ProductLocations.AssignmentGoodsReceipt
	|		AND TabPart.BatchReceipt = ProductLocations.BatchReceipt
	|		AND TabPart.PackagingReceipt = ProductLocations.PackagingReceipt
	|WHERE
	|	TabPart.Package.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem)";

	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True,
		TemporaryTableTemplateTexts);

EndProcedure

#EndRegion

#EndRegion

#EndIf