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
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, Terms";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);

EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//	Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	GoodsReceiptFromCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "Receipt of goods from the client".
// 
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// 	ValueTableRow, Undefined -
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsReceiptFromCustomer) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Id = "GoodsReceiptFromCustomer";
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsReceiptFromCustomer.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Tiếp nhận hàng hóa từ khách';
												|ru = 'Поступление товаров от клиента';
												|en = 'Goods receipt from customer'; fa = 'دریافت کالا از مشتری';
												|it = 'Goods receipt from customer';
												|pl = 'Goods receipt from customer';
												|tr = 'Müşteriden ürün alımı'");
		CreateBasedOnCommand.FunctionalOptions = "UseShipmentWithDeferredTransferOfTitle2_5";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
	
	EndIf;
	
	Return Undefined;
EndFunction

#EndRegion

#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return GoodsReceiptFromCustomerLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
//  String - The text of the request for the temporary reflection table in the regl accounting
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return GoodsReceiptFromCustomerLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"OrderFulfillment",
			True,
			"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	
	// Needs for goods in all warehouses
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"SecuringOrdersAllWarehouses",
			True,
			"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
//
// Parameters:
// 	Form - ClientApplicationForm
//
// Returns:
// 	See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,BusinessOperation,Date,ReduceShipmentByReference";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	UseItemsBatch  =
		GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	UseCostAccountingByBatches =
		GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsReceiptFromCustomer";
	
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceivingByReturnFromACustomer);
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	SeriesSpecificationParameters.QueryOptions.Insert("ReduceShipmentByReference",
													Object.ReduceShipmentByReference);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Products        AS Products,
	|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Warehouse             AS Warehouse,
	|	Goods.Products      AS Products,
	|	Goods.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.ProductsRecordingAsReceived,
	|	Goods.Characteristic,
	|	Goods.CharacteristicRecordingAsReceived,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Count     AS Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	SetOfSeries.Warehouse             AS Warehouse,
	|	SetOfSeries.Products      AS Products,
	|	SetOfSeries.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	SetOfSeries.Characteristic    AS Characteristic,
	|	SetOfSeries.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	SetOfSeries.Purpose        AS Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.ProductsRecordingAsReceived,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.CharacteristicRecordingAsReceived,
	|	SetOfSeries.Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN &ReduceShipmentByReference
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 10
	|								ELSE 9
	|							END
	|					WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|							OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|						THEN CASE
	|								WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|									THEN 10
	|								ELSE 9
	|							END
	|					ELSE 0
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN
	|				CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 8
	|					ELSE 7
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|				AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|					OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingByReturnFromCustomer
	|			THEN
	|				CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN
	|							CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE
	|						CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END                      AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|						AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
	|					THEN
	|						CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 18
	|							ELSE 17
	|						END
	|				ELSE 0
	|			END
	|	END                      AS BatchesIndicationStatusOfGoodsTransferred
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.ProductsRecordingAsReceived = ProductsToRequest.ProductsRecordingAsReceived
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.CharacteristicRecordingAsReceived = ProductsToRequest.CharacteristicRecordingAsReceived
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|		LEFT JOIN SeriesToRequest AS SeriesToRequest
	|		ON ProductsToRequest.Products = SeriesToRequest.Products
	|			AND ProductsToRequest.ProductsRecordingAsReceived = SeriesToRequest.ProductsRecordingAsReceived
	|			AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|			AND ProductsToRequest.CharacteristicRecordingAsReceived = SeriesToRequest.CharacteristicRecordingAsReceived
	|			AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|			AND ProductsToRequest.Warehouse = BatchAccountingPolicies.Warehouse
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON ProductsToRequest.Warehouse = Warehouses.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Statuses.LineNumber                          AS LineNumber,
	|	Statuses.BatchesIndicationStatus                  AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                        AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
	|	OR Statuses.BatchesIndicationStatusOfGoodsTransferred <> Statuses.OldStatusOfSpecifyingSeriesOfTransferredGoods
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Allows you to specify metadata objects for which the logic of restricting access to data is set.
//
// Parameters:
//	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(BusinessOperation)";
	
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

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.GoodsReceiptFromCustomer, DocumentRef.GoodsReceiptFromCustomer - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Contract,
		|Partner,
		|Ref,
		|Date,
		|DateOfReceipt,
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
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
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
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Attributes.Sender = ObjectAttributes.Partner;
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.GoodsReceiptFromCustomer - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,ProductsRecordingAsReceived,Damage,Warehouse";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.KeyDetailsOfHeader.Insert("Warehouse", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	CASE
		|		WHEN Table.Damage
		|			THEN Table.ProductsRecordingAsReceived
		|		ELSE Table.Products
		|	END AS Products,
		|	Table.Warehouse AS Warehouse,
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

// Returns a collection of valid incoming document names.
//
// Returns:
//	Array of String - collection of titles.
//
Function NamesOfIncomingDocuments() Export
	
	ArrayOfNames = New Array;
	ArrayOfNames.Add(NStr("vi = 'Trả hàng';
							|ru = 'Возврат товаров';
							|en = 'Return of goods'; fa = 'برگشت کالا';
							|it = 'Restituzione della merce';
							|pl = 'Zwrot towarów';
							|tr = 'Ürün iadesi'"));
	
	GoodsReceiptFromCustomerLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	
	Return ArrayOfNames;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods", Undefined);
	
	Return DocumentTables;
	
EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//	DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//											registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("ARAPAccounting");

	GoodsReceiptFromCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//	Document - DocumentRef, DocumentObject - a link to the document or object for which you want to get data.
//	Registers - Structure - list of register names for which tables should be retrieved.
//	AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	See DocumentsPosting.InitializeDocumentDataForPosting.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GoodsReceiptFromCustomer") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
		
	EndIf;
	
	Query         = New Query;
	QueryTexts  = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
			
		GoodsReceiptFromCustomerLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// The procedure recalculates the quantity of Packages field and other dependent fields
//
// Parameters:
//  Goods				 - FormDataCollection - Table part " Products"
//  FillParameters	 - Structure -
//
Procedure UpdateDependentDetailsOfTablePart(Goods, FillParameters) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateAmount");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(
		Goods,
		StructureOfActions,
		CachedValues);
	
EndProcedure

// Returns the Products table
//
// Parameters:
//  Invoice - DocumentRef.GoodsReceiptFromCustomer - link to the invoice for PM Products that need to be returned
//
// Returns:
//  ValueTable - The tabular part of the goods receipt document.
//
Function TableDataAndDocument(Invoice) Export
	
	QueryText = 
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.Ref AS Ref,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
		|	GoodsTable.Price AS Price,
		|	GoodsTable.Sum AS Sum,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.Warehouse AS Warehouse,
		|	GoodsTable.CCDNumber AS CCDNumber,
		|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	GoodsTable.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
		|	GoodsTable.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
		|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	GoodsTable.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
		|	GoodsTable.RowID AS RowID,
		|	GoodsTable.ProductsInSet AS ProductsInSet,
		|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsTable.SetAccountingDimension AS SetAccountingDimension,
		|	GoodsTable.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
		|	GoodsTable.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
		|	GoodsTable.Damage AS Damage,
		|	GoodsTable.ReferenceOrder AS ReferenceOrder
		|FROM
		|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Invoice";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Checks the completeness of the verified details.
//
// Parameters:
//	 ShipmentOfItems    - DocumentRef.GoodsReceiptFromCustomer - The document on the basis of which the input is made
//	 Status             - EnumRef - Status of the document that is used for entering data
//	 ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
//
Procedure CheckPossibilityOfEnteringBasedOn(ShipmentOfItems, Status = Undefined,
	ThereAreErrorsPosted = False) Export
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = False;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(ShipmentOfItems, CheckParameters);
	
EndProcedure

#Region Filling_By_Order

// Constructor function for the structure of the folder props.
//
// Returns:
//  Structure:
//  	* Organization - CatalogRef.Companies
//  	* Warehouse - CatalogRef.Warehouses
//  	* Department - CatalogRef.BusinessStructure
//  	* BusinessOperation - EnumRef.BusinessTransactions
//  	* GoodsReceiptOption - EnumRef.GoodsReceiptOptions
//  	* Ref - DocumentRef.GoodsReceiptFromCustomer
//  	* Partner - CatalogRef.Partners
//  	* Counterparty - CatalogRef.Counterparties
//  	* Terms - CatalogRef.TermsOfSale
//  	* Contract - CatalogRef.CounterpartyContracts
//  	* Currency - CatalogRef.Currencies
//  	* SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer
//  	* LineOfBusiness - CatalogRef.LinesOfBusiness
//
Function HeaderAttributes() Export

	HeaderAttributes = New Structure;
	
	HeaderAttributes.Insert("Organization",             Catalogs.Companies.EmptyRef());
	HeaderAttributes.Insert("Warehouse",                   Catalogs.Warehouses.EmptyRef());
	HeaderAttributes.Insert("Department",           Catalogs.BusinessStructure.EmptyRef());
	HeaderAttributes.Insert("BusinessOperation",   Enums.BusinessTransactions.EmptyRef());
	HeaderAttributes.Insert("GoodsReceiptOption",   Enums.GoodsReceiptOptions.EmptyRef());
	HeaderAttributes.Insert("Ref",                  Documents.GoodsReceiptFromCustomer.EmptyRef());
	HeaderAttributes.Insert("Partner",                 Catalogs.Partners.EmptyRef());
	HeaderAttributes.Insert("Counterparty",              Catalogs.Counterparties.EmptyRef());
	HeaderAttributes.Insert("Terms",              Catalogs.TermsOfSale.EmptyRef());
	HeaderAttributes.Insert("Contract",                 Catalogs.CounterpartyContracts.EmptyRef());
	HeaderAttributes.Insert("Currency",                  Catalogs.Currencies.EmptyRef());
	HeaderAttributes.Insert("SalesOpportunity",                  Catalogs.SalesOpportunitiesToCustomer.EmptyRef());
	HeaderAttributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	
	Return HeaderAttributes;
	
EndFunction

// Returns an array containing the transmitted invoice, as well as all orders that fit
// the selection by the header Attributes.
//
// Parameters:
// 	Invoice - DocumentRef.GoodsReceiptFromCustomer - invoice.
// 	HeaderAttributes - Structure - Details of the caps:
// 		* Organization - CatalogRef.Companies
// 		* Warehouse - CatalogRef.Warehouses
// 		* SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer
// 		* BusinessOperation - EnumRef.BusinessTransactions
// 		* LineOfBusiness - CatalogRef.LinesOfBusiness
//
// Returns:
// 	Array of DocumentRef
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	QueryText = 
	"SELECT ALLOWED
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.SalesOrder.Goods AS DocumentData
	|WHERE
	|	DocumentData.Ref.Posted
	|	AND DocumentData.Ref.Organization = &Organization
	|	AND DocumentData.Ref.Partner = &Partner
	|	AND DocumentData.Ref.Counterparty = &Counterparty
	|	AND DocumentData.Ref.Terms = &Terms
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Ref.Terms = &Terms)
	|	AND DocumentData.Ref.Contract = &Contract
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND DocumentData.Ref.Currency = &Currency
	|	AND DocumentData.Ref.SalesOpportunity = &SalesOpportunity
	|	AND CASE
	|		WHEN NOT &UseLinesOfBusiness
	|			THEN TRUE
	|		ELSE DocumentData.Ref.LineOfBusiness = &LineOfBusiness
	|	END
	|	AND NOT DocumentData.Ref.ThisIsOrderAsInvoice
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.LineOfBusiness = &LineOfBusiness)
	|	AND NOT DocumentData.Ref.ThisIsOrderAsInvoice
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN DocumentData.Ref.Patch
	|			THEN DocumentData.Ref.CorrectedDocument
	|		ELSE
	|			DocumentData.Ref
	|	END AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentData
	|WHERE
	|	DocumentData.Ref.Posted
	|	AND DocumentData.Ref.Organization = &Organization
	|	AND DocumentData.Ref.Partner = &Partner
	|	AND DocumentData.Ref.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Ref.Terms = &Terms)
	|	AND DocumentData.Ref.Contract = &Contract
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND DocumentData.Ref.Currency = &Currency
	|	AND DocumentData.Ref.SalesOpportunity = &SalesOpportunity
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.Ref.LineOfBusiness = &LineOfBusiness)
	|	AND (NOT DocumentData.Ref.ShipmentByOrders
	|		AND DocumentData.SalesOrder IN (
	|	                      VALUE(Document.SalesOrder.EmptyRef),
	|	                      VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                      VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                      UNDEFINED
	|	                      )
	|		OR DocumentData.Ref.ShipmentByOrders
	|			AND CASE
	|				WHEN DocumentData.SalesOrder REFS Document.SalesOrder
	|					THEN CAST(DocumentData.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|				WHEN DocumentData.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|					THEN CAST(DocumentData.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|				ELSE
	|					FALSE
	|			END)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentData.Lot AS ReferenceOrder
	|FROM
	|	Document.OBEntryGoods AS DocumentData
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.Lot <> VALUE(Document.SourceDocument.EmptyRef)
	|	AND DocumentsRegistry.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.SaleAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.LineOfBusiness = &LineOfBusiness)
	|
	|UNION ALL
	|
	|SELECT
	|	&Invoice AS ReferenceOrder
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice",               Invoice);
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("Partner",                 HeaderAttributes.Partner);
	Query.SetParameter("Counterparty",              HeaderAttributes.Counterparty);
	Query.SetParameter("Terms",              HeaderAttributes.Terms);
	Query.SetParameter("Contract",                 HeaderAttributes.Contract);
	Query.SetParameter("Warehouse",                   HeaderAttributes.Warehouse);
	Query.SetParameter("Currency",                  HeaderAttributes.Currency);
	Query.SetParameter("SalesOpportunity",                  HeaderAttributes.SalesOpportunity);
	Query.SetParameter("LineOfBusiness", HeaderAttributes.LineOfBusiness);
	Query.SetParameter("ToUseTermsOfSales",
		GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseLinesOfBusiness",
		GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));

	References = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Return CommonClientServer.CollapseArray(References);
	
EndFunction

// Returns parameters for filling in the document for refund requests and receipt orders.
//
// Returns:
//  Structure:
//  	* AnArrayOfOrders - Undefined
//  	* FormIsOpen - Boolean
//  	* FillByWarehouseDocument - Boolean
//  	* AddSeriesOnRequest - Boolean
//  	* RegistrationViaRM - Boolean
//  	* DiscrepancyCertificate - DocumentRef.DiscrepancyReportFollowingShipment
//  	* BasisOfAct - DocumentRef.GoodsReceiptFromCustomer
//  	* HeaderAttributes - Undefined
//  	* Organization - CatalogRef.Companies
//  	* BusinessOperation - EnumRef.BusinessTransactions
//  	* Warehouse - CatalogRef.Warehouses
//  	* Department - CatalogRef.BusinessStructure
//  	* FieldNameOrder - String
//  	* KeyFields - String
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure();
	
	FillParameters.Insert("AnArrayOfOrders",     Undefined);
	FillParameters.Insert("FormIsOpen",      False);
	FillParameters.Insert("FillByWarehouseDocument", False);
	
	FillParameters.Insert("AddSeriesOnRequest", False);
	FillParameters.Insert("RegistrationViaRM",        False);
	
	FillParameters.Insert("DiscrepancyCertificate",        Documents.DiscrepancyReportFollowingShipment.EmptyRef());
	FillParameters.Insert("BasisOfAct",           Documents.GoodsReceiptFromCustomer.EmptyRef());
	
	FillParameters.Insert("HeaderAttributes",          Undefined);
	FillParameters.Insert("Organization",             Catalogs.Companies.EmptyRef());
	FillParameters.Insert("BusinessOperation",   Enums.BusinessTransactions.EmptyRef());
	FillParameters.Insert("Warehouse",                   Catalogs.Warehouses.EmptyRef());
	FillParameters.Insert("Department",           Catalogs.BusinessStructure.EmptyRef());
	
	FillParameters.Insert("FieldNameOrder", "ReferenceOrder");
	FillParameters.Insert("KeyFields", "");
	
	Return FillParameters;
	
EndFunction

// Initializes parameters populate the document according to the document.
//
// Parameters:
//  FillParameters - Structure - the fill settings of the default document.
//  HeaderAttributes - Structure - document data that will be used for filling in parameters.
//  AnArrayOfOrders - Array of DocumentRef.GoodsShipmentToCustomer, DocumentRef.SaleAdjustment -
//  	array for applications to be filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders         = AnArrayOfOrders;
	FillParameters.HeaderAttributes        = HeaderAttributes;
	FillParameters.Organization           = HeaderAttributes.Organization;
	FillParameters.Warehouse                 = HeaderAttributes.Warehouse;
	FillParameters.Department         = HeaderAttributes.Department;
	FillParameters.BusinessOperation = HeaderAttributes.BusinessOperation;
	FillParameters.FillByWarehouseDocument     = False; // orders can be entered only on the basis of receipt
	
	FillParameters.KeyFields          = KeyFieldsOfGoodsTable();
	
EndProcedure

// Returns a list of details by which tables are compared when filling in orders/orders
// 
// Returns:
//  String
//
Function KeyFieldsOfGoodsTable() Export
	
	Return "Products, Characteristic, ProductsRecordingAsReceived, CharacteristicRecordingAsReceived, Purpose, Series";
	
EndFunction

// Fills in the passed parameter table for orders and warehouse orders
//
// Parameters:
//  Goods				 	- ValueTable - Table products to fill In
//  Recorder			- DocumentRef.GoodsReceiptFromCustomer - Link to the current invoice
//  FillParameters	- Structure - The default settings defined in the method of Parametrization()
//  PackageBarcodes	- ValueTable, Undefined - Table of barcodes of packages for returning stamp data
//
Procedure FillInByOrdersOrders(Goods,
                                    Recorder,
                                    FillParameters,
                                    PackageBarcodes = Undefined) Export

	ToFillInCCD = Goods.Columns.Find("CCDNumber") <> Undefined;

	QueryTexts = New Array();
	
	// 1. We get the Query Text for the Balances to be shipped: [shipped] + [logged in to PPP] - [debited to PPP] -
	// [processed] - [accepted]
	If ToFillInCCD Then
		QueryTexts.Add(QueryTextBalancesToBeProcessedByOrders("TTForRegistrationByOrder"));
		QueryTexts.Add(QueryTextBalancesToBeProcessedUnderCCD("TTForRegistrationByOrder"));
	Else
		QueryTexts.Add(QueryTextBalancesToBeProcessedByOrders());
	EndIf;
	
	// 2. We connect the Balances to be shipped from item 1. with the data from the tables of the order documents.
	// The Number, Date, Document summation, etc. fields are required to be displayed in the order selection form.
		
	QueryText =
	"SELECT
	|	TTAccountingData.ReferenceOrder                  AS ReferenceOrder,
	|	MAX(DataOfCorrectedDocuments.Date) AS DateOfLastCorrection
	|INTO RecentFixes
	|FROM
	|	Document.GoodsShipmentToCustomer AS DataOfCorrectedDocuments
	|	INNER JOIN TTAccountingData AS TTAccountingData
	|		ON DataOfCorrectedDocuments.CorrectedDocument = TTAccountingData.ReferenceOrder
	|WHERE
	|	DataOfCorrectedDocuments.Posted
	|	AND DataOfCorrectedDocuments.Patch
	|
	|GROUP BY
	|	TTAccountingData.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTAccountingData.ReferenceOrder AS ReferenceOrder,
	|	DocumentsData.Ref    AS CorrectedShipmentOfItems
	|INTO CorrectionsOfItemShipments
	|FROM
	|	TTAccountingData AS TTAccountingData
	|	LEFT JOIN RecentFixes AS RecentFixes
	|		ON TTAccountingData.ReferenceOrder = RecentFixes.ReferenceOrder
	|	LEFT JOIN Document.GoodsShipmentToCustomer AS DocumentsData
	|		ON TTAccountingData.ReferenceOrder = DocumentsData.CorrectedDocument
	|			AND RecentFixes.DateOfLastCorrection = DocumentsData.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber                   AS LineNumber,
	|	DataOfAccounting.ReferenceOrder              AS ReferenceOrder,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	CASE
	|		WHEN Table.WithAssignment
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                 AS Purpose,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                                 AS Series,
	|	Table.RowCode                     AS RowCode,
	|	Table.Count                    AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ToRegister,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Warehouse                         AS Warehouse,
	|	Table.ProductsInSet            AS ProductsInSet,
	|	Table.ItemVariantOfSet          AS ItemVariantOfSet,
	|	DataOfAccounting.CCDNumber                  AS CCDNumber
	|INTO VTKRegistration
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber                   AS LineNumber,
	|	DataOfAccounting.ReferenceOrder              AS ReferenceOrder,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	CASE
	|		WHEN Table.WithAssignment
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                 AS Purpose,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                                 AS Series,
	|	Table.RowCode                     AS RowCode,
	|	Table.Count                    AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ToRegister,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Ref.Warehouse                  AS Warehouse,
	|	Table.ProductsInSet            AS ProductsInSet,
	|	Table.ItemVariantOfSet          AS ItemVariantOfSet,
	|	DataOfAccounting.CCDNumber                  AS CCDNumber
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber                   AS LineNumber,
	|	DataOfAccounting.ReferenceOrder              AS ReferenceOrder,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	Table.Purpose                    AS Purpose,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                                 AS Series,
	|	Table.RowCode                     AS RowCode,
	|	Table.Count                    AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ToRegister,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Warehouse                         AS Warehouse,
	|	Table.ProductsInSet            AS ProductsInSet,
	|	Table.ItemVariantOfSet          AS ItemVariantOfSet,
	|	DataOfAccounting.CCDNumber                  AS CCDNumber
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN CorrectionsOfItemShipments AS CorrectionsOfItemShipments
	|		ON ISNULL(CorrectionsOfItemShipments.CorrectedShipmentOfItems, CorrectionsOfItemShipments.ReferenceOrder) = Table.Ref
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON CorrectionsOfItemShipments.ReferenceOrder = DataOfAccounting.ReferenceOrder
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	Table.Ref.Posted
	|
	|UNION ALL
	|
	// For lines over the order
	|SELECT
	|	MAX(ISNULL(Table.LineNumber, 0)) AS LineNumber,
	|	DataOfAccounting.ReferenceOrder                   AS ReferenceOrder,
	|	DataOfAccounting.Products                   AS Products,
	|	DataOfAccounting.Characteristic                 AS Characteristic,
	|	MAX(ISNULL(Table.Purpose, VALUE(Catalog.Assignments.EmptyRef))) AS Purpose,
	|	MAX(CASE
	|		WHEN Table.Series IS NOT NULL AND Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		WHEN RegistrationOfItems.Series IS NOT NULL AND RegistrationOfItems.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN RegistrationOfItems.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END)                                      AS Series,
	|	DataOfAccounting.RowCode                       AS RowCode,
	|	SUM(ISNULL(Table.Count, 0) + ISNULL(RegistrationOfItems.Count, 0)) AS Count,
	|	MAX(DataOfAccounting.ForRegistrationQuantity) AS ToRegister,
	|	DataOfAccounting.Products.UnitOfMeasure   AS Package,
	|	MAX(CASE
	|		WHEN DataOfAccounting.ForRegistrationQuantity = 0
	|			THEN 0
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|	END)                                      AS Price,
	|	SUM(DataOfAccounting.AmountToBeProcessed)         AS Sum,
	|	MAX(ISNULL(Table.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))) AS Warehouse,
	|	MAX(ISNULL(Table.ProductsInSet, VALUE(Catalog.Products.EmptyRef))) AS ProductsInSet,
	|	MAX(ISNULL(Table.ItemVariantOfSet, VALUE(Catalog.ItemsCharacteristics.EmptyRef))) AS ItemVariantOfSet,
	|	DataOfAccounting.CCDNumber                        AS CCDNumber
	|FROM
	|	TTAccountingData AS DataOfAccounting
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS Table
	|		ON DataOfAccounting.ReferenceOrder = Table.SalesOrder
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|			AND Table.RowCode = 0
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND Table.Ref.Posted
	|	LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS RegistrationOfItems
	|		ON DataOfAccounting.ReferenceOrder = RegistrationOfItems.ReferenceOrder
	|			AND DataOfAccounting.Products = RegistrationOfItems.Products
	|			AND DataOfAccounting.Characteristic = RegistrationOfItems.Characteristic
	|			AND RegistrationOfItems.Ref.Posted
	|	
	|WHERE
	|	DataOfAccounting.RowCode = 0
	|
	|GROUP BY
	|	DataOfAccounting.ReferenceOrder,
	|	DataOfAccounting.Products,
	|	DataOfAccounting.Characteristic,
	|	DataOfAccounting.RowCode,
	|	DataOfAccounting.CCDNumber
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber                   AS LineNumber,
	|	DataOfAccounting.ReferenceOrder              AS ReferenceOrder,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	Table.Purpose                    AS Purpose,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                                 AS Series,
	|	Table.RowCode                     AS RowCode,
	|	Table.Count                    AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ToRegister,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Ref.Warehouse                  AS Warehouse,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	Table.CCDNumber                      AS CCDNumber
	|FROM
	|	Document.OBEntryGoods.Goods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref.Lot
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|			AND Table.Ref.Posted
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentsRegistry.Ref IS NULL
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber                   AS LineNumber,
	|	DataOfAccounting.ReferenceOrder              AS ReferenceOrder,
	|	Table.Products                  AS Products,
	|	Table.Characteristic                AS Characteristic,
	|	Table.Purpose                    AS Purpose,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                                 AS Series,
	|	Table.RowCode                     AS RowCode,
	|	-Table.Count                   AS Count,
	|	DataOfAccounting.ForRegistrationQuantity     AS ToRegister,
	|	Table.Package                      AS Package,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                                 AS Price,
	|	DataOfAccounting.AmountToBeProcessed          AS Sum,
	|	Table.Warehouse                         AS Warehouse,
	|	Table.ProductsInSet            AS ProductsInSet,
	|	Table.ItemVariantOfSet          AS ItemVariantOfSet,
	|	DataOfAccounting.CCDNumber                  AS CCDNumber
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	Table.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ReturnToTransit)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(VTKRegistration.LineNumber) AS LineNumber,
	|	VTKRegistration.ReferenceOrder         AS ReferenceOrder,
	|	VTKRegistration.Products         AS Products,
	|	VTKRegistration.Characteristic       AS Characteristic,
	|	VTKRegistration.Purpose           AS Purpose,
	|	VTKRegistration.Warehouse                AS Warehouse,
	|	VTKRegistration.Series                AS Series,
	|	VTKRegistration.RowCode            AS RowCode,
	|	VTKRegistration.Package             AS Package,
	|	SUM(VTKRegistration.Count)    AS Count,
	|	SUM(VTKRegistration.ToRegister)   AS ToRegister,
	|	MAX(VTKRegistration.Price)       AS Price,
	|	SUM(VTKRegistration.Sum)         AS Sum,
	|	VTKRegistration.CCDNumber             AS CCDNumber,
	|	VTKRegistration.ProductsInSet   AS ProductsInSet,
	|	VTKRegistration.ItemVariantOfSet AS ItemVariantOfSet
	|FROM
	|	VTKRegistration AS VTKRegistration
	|
	|GROUP BY
	|	VTKRegistration.ReferenceOrder,
	|	VTKRegistration.Products,
	|	VTKRegistration.Characteristic,
	|	VTKRegistration.Purpose,
	|	VTKRegistration.Warehouse,
	|	VTKRegistration.Series,
	|	VTKRegistration.RowCode,
	|	VTKRegistration.Package,
	|	VTKRegistration.CCDNumber,
	|	VTKRegistration.ProductsInSet,
	|	VTKRegistration.ItemVariantOfSet
	|
	|ORDER BY
	|	VTKRegistration.ReferenceOrder,
	|	MIN(VTKRegistration.LineNumber)
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, InvoicesServer.QuerySeparatorText());
	
	Query = New Query(QueryText);
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Warehouse", FillParameters.Warehouse);
	Query.SetParameter("Recorder", Recorder);
	OrdersTable = Query.Execute().Unload();

	Var_Key = "RowCode, " + FillParameters.KeyFields;
	If ToFillInCCD Then
		Var_Key = Var_Key + ", CCDNumber";
	EndIf;
	
	OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";

	Condition = "On [Count]"; // @query-part
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("BusinessOperation");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	ObjectPresentation = NStr("vi = 'Tiếp nhận hàng hóa từ khách';
								|ru = 'Поступление товаров от клиента';
								|en = 'Goods receipt from customer'; fa = 'دریافت کالا از مشتری';
								|it = 'Goods receipt from customer';
								|pl = 'Goods receipt from customer';
								|tr = 'Müşteriden ürün alımı'");
	
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Data.Number, Data.Date);
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "GoodsReceiptFromCustomer");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

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
	
	If AccessRight("Update", Metadata.Documents.GoodsReceiptFromCustomer) Then
		// Receipt of goods from the customer.
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "GoodsReceiptFromCustomer";
		PrintCommand.Presentation = NStr("vi = 'Tiếp nhận hàng hóa từ khách';
										|ru = 'Поступление товаров от клиента';
										|en = 'Goods receipt from customer'; fa = 'دریافت کالا از مشتری';
										|it = 'Goods receipt from customer';
										|pl = 'Goods receipt from customer';
										|tr = 'Müşteriden ürün alımı'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	
	GoodsReceiptFromCustomerLocalization.AddPrintCommands(PrintCommands);
	
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "GoodsReceiptFromCustomer") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"GoodsReceiptFromCustomer",
			NStr("vi = 'Tiếp nhận hàng hóa từ khách';
				|ru = 'Поступление товаров от клиента';
				|en = 'Goods receipt from customer'; fa = 'دریافت کالا از مشتری';
				|it = 'Goods receipt from customer';
				|pl = 'Goods receipt from customer';
				|tr = 'Müşteriden ürün alımı'"),
			ToFormPrintedFormReceiptOfGoodsFromClient(ObjectsArray, PrintObjects));
	EndIf;
	
	GoodsReceiptFromCustomerLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects,
		OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// The function generates a printed Form of goods receipt documents from the client.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - printed Form of documents of receipt of goods from the client.
//
Function ToFormPrintedFormReceiptOfGoodsFromClient(ObjectsArray, PrintObjects)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text =
	"SELECT
	|	UninvoicedReceipt.Ref AS Ref,
	|	UninvoicedReceipt.Number AS Number,
	|	UninvoicedReceipt.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	UninvoicedReceipt.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	UninvoicedReceipt.Date AS Date,
	|	UninvoicedReceipt.Partner AS Partner,
	|	UninvoicedReceipt.Counterparty AS Recipient,
	|	UninvoicedReceipt.Organization AS Organization,
	|	UninvoicedReceipt.Organization.Prefix AS Prefix,
	|	UninvoicedReceipt.Currency AS Currency,
	|	UninvoicedReceipt.Warehouse.CurrentEmployeeInChargeTypes AS GettingProduced
	|FROM
	|	Document.GoodsReceiptFromCustomer AS UninvoicedReceipt
	|WHERE
	|	UninvoicedReceipt.Ref IN(&DocumentsArray)
	|	AND UninvoicedReceipt.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsTable.Ref               AS Ref,
	|	GoodsTable.LineNumber          AS LineNumber,
	|	KitConfigurations.Ref        AS ItemKitConfiguration,
	|	KitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.SetPricingOption AS SetPricingOption,
	|	GoodsTable.ProductsInSet   AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.Products         AS Products,
	|	GoodsTable.Characteristic       AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN GoodsTable.Products.UnitOfMeasure
	|		ELSE GoodsTable.Package
	|	END                              AS UnitOfMeasure,
	|	GoodsTable.Package             AS Package,
	|	GoodsTable.Count           AS Count,
	|	GoodsTable.NumberOfPackages   AS NumberOfPackages,
	|	GoodsTable.Price                 AS Price,
	|	GoodsTable.Sum                AS Sum,
	|	FALSE                               AS ThisIsReusablePackage
	|INTO Goods
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
	|		LEFT JOIN Catalog.ProductKitConfigurations AS KitConfigurations
	|		ON KitConfigurations.Owner = GoodsTable.ProductsInSet
	|			AND KitConfigurations.Characteristic = GoodsTable.ItemVariantOfSet
	|			AND KitConfigurations.Main
	|WHERE
	|	GoodsTable.Ref IN(&DocumentsArray)
	|	AND GoodsTable.Ref.Posted
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 2
	|SELECT DISTINCT
	|	Goods.Ref AS Ref
	|INTO PrintDocuments_1
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration
	|INTO DocumentConfigurations
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsTable.Ref               AS Ref,
	|	MIN(GoodsTable.LineNumber) AS LineNumber,
	|	GoodsTable.ProductsInSet   AS ProductsInSet,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	SUM(GoodsTable.Sum)         AS Sum
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS GoodsTable
	|WHERE
	|	GoodsTable.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.ProductsInSet,
	|	GoodsTable.ItemVariantOfSet
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	Goods.Ref               AS Ref,
	|	Goods.ItemKitConfiguration AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption AS SetPricingOption,
	|	Goods.ProductsInSet   AS ProductsInSet,
	|	Goods.ItemVariantOfSet AS ItemVariantOfSet,
	|	Goods.Products         AS Products,
	|	Goods.Characteristic       AS Characteristic,
	|	Goods.Count           AS Count,
	|	0                           AS DefaultQuantity,
	|	CASE
	|		WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|				AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END                       AS MainComponent
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	PrintDocuments_1.Ref                     AS Ref,
	|	KitConfigurations.Ref                AS ItemKitConfiguration,
	|	KitConfigurations.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	KitConfigurations.Ref.SetPricingOption AS SetPricingOption,
	|	KitConfigurations.Ref.Owner       AS ProductsInSet,
	|	KitConfigurations.Ref.Characteristic AS ItemVariantOfSet,
	|	KitConfigurations.Products          AS Products,
	|	KitConfigurations.Characteristic        AS Characteristic,
	|	0                                          AS Count,
	|	SUM(KitConfigurations.Count)     AS DefaultQuantity,
	|	FALSE                                       AS MainComponent
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS KitConfigurations
	|		LEFT JOIN PrintDocuments_1 AS PrintDocuments_1
	|		ON TRUE
	|WHERE
	|	KitConfigurations.Ref IN
	|		(SELECT DISTINCT
	|			Configuration_.ItemKitConfiguration
	|		FROM DocumentConfigurations AS Configuration_)
	|
	|GROUP BY
	|	PrintDocuments_1.Ref,
	|	KitConfigurations.Ref,
	|	KitConfigurations.Ref.Owner,
	|	KitConfigurations.Ref.Characteristic,
	|	KitConfigurations.Products,
	|	KitConfigurations.Characteristic
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	Table.Ref                          AS Ref,
	|	Table.ItemKitConfiguration AS ItemKitConfiguration,
	|	Table.SetPricingOption        AS SetPricingOption,
	|	Table.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet              AS ProductsInSet,
	|	Table.ItemVariantOfSet            AS ItemVariantOfSet,
	|	Table.Products                    AS Products,
	|	Table.Characteristic                  AS Characteristic,
	|	SUM(Table.Count)               AS Count,
	|	SUM(Table.DefaultQuantity)    AS DefaultQuantity,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT)   AS VATRate,
	|	MAX(Table.MainComponent) AS MainComponent
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
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	Result.Ref               AS Ref,
	|	Result.ItemKitConfiguration AS ItemKitConfiguration,
	|	Result.SetPricingOption AS SetPricingOption,
	|	Result.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Result.ProductsInSet   AS ProductsInSet,
	|	Result.ItemVariantOfSet AS ItemVariantOfSet,
	|	CAST(MIN(CASE
	|		WHEN Result.DefaultQuantity <> 0
	|				AND Result.MainComponent
	|			THEN Result.Count / Result.DefaultQuantity
	|		ELSE NULL
	|	END) + 0.5 AS NUMBER(10,0)) - 1 AS Count,
	|	MAX(CASE
	|		WHEN Result.MainComponent
	|			THEN Result.VATRate
	|		ELSE NULL
	|	END)                         AS VATRate
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	Table.Ref               AS Ref,
	|	Table.LineNumber          AS LineNumber,
	|	TemporaryTableSetsOptional.ItemKitConfiguration AS ItemKitConfiguration,
	|	CASE
	|		WHEN CASE
	|				WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|					THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|				ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|				END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|				AND TemporaryTableSetsOptional.SetPricingOption IN(
	|					VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|					VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|			THEN VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE TemporaryTableSetsOptional.SetPricingOption
	|	END                        AS SetPricingOption,
	|	CASE
	|		WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet)
	|			THEN VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END                        AS PresentationOptionInPrintForms,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	Table.Sum                AS Sum,
	|	TemporaryTableSetsOptional.VATRate AS VATRate,
	|	0                            AS VATAmount
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.Ref = TemporaryTableSetsOptional.Ref
	|			AND Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|			AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|
	|INDEX BY
	|	Ref,
	|	ProductsInSet,
	|	ItemVariantOfSet
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 9
	|SELECT
	|	NestedQuery.Ref               AS Ref,
	|	NestedQuery.LineNumber          AS LineNumber,
	|	NestedQuery.SetPricingOption AS SetPricingOption,
	|	NestedQuery.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	NestedQuery.ProductsInSet   AS ProductsInSet,
	|	NestedQuery.ItemVariantOfSet AS ItemVariantOfSet,
	|	NestedQuery.Products         AS Products,
	|	NestedQuery.Products.Code     AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.Products.DescriptionFull AS ProductNameFull_,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	NestedQuery.UnitOfMeasure     AS UnitOfMeasure,
	|	NestedQuery.UnitOfMeasure.Description AS UnitPrice,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END                                AS Package,
	|	NestedQuery.NumberOfPackages   AS Count,
	|	NestedQuery.Price                 AS Price,
	|	NestedQuery.Sum                AS Sum,
	|	NestedQuery.VATRate            AS VATRate,
	|	NestedQuery.VATAmount             AS VATAmount,
	|	NestedQuery.TheseAreComponents     AS TheseAreComponents,
	|	NestedQuery.IsRecordsSet             AS IsRecordsSet,
	|	NestedQuery.ThisIsReusablePackage    AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		Table.Ref               AS Ref,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.LineNumber
	|			ELSE Table.LineNumber
	|		END                        AS LineNumber,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.SetPricingOption
	|			ELSE VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END                        AS SetPricingOption,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TemporaryTableSets.PresentationOptionInPrintForms
	|			ELSE VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END                        AS PresentationOptionInPrintForms,
	|		Table.ProductsInSet   AS ProductsInSet,
	|		Table.ItemVariantOfSet AS ItemVariantOfSet,
	|		Table.Products         AS Products,
	|		Table.Characteristic       AS Characteristic,
	|		Table.UnitOfMeasure     AS UnitOfMeasure,
	|		Table.Package             AS Package,
	|		Table.Count           AS Count,
	|		Table.NumberOfPackages   AS NumberOfPackages,
	|		Table.Price                 AS Price,
	|		Table.Sum                AS Sum,
	|		VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|		0                            AS VATAmount,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END                        AS TheseAreComponents,
	|		FALSE                         AS IsRecordsSet,
	|		Table.ThisIsReusablePackage    AS ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.Ref = Table.Ref
	|				AND TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|				AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|			AND TemporaryTableSets.PresentationOptionInPrintForms IN(
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TemporaryTableSets.Ref               AS Ref,
	|		TemporaryTableSets.LineNumber          AS LineNumber,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|		TemporaryTableSets.ProductsInSet   AS ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet AS ItemVariantOfSet,
	|		TemporaryTableSets.ProductsInSet   AS Products,
	|		TemporaryTableSets.ItemVariantOfSet AS Characteristic,
	|		TemporaryTableSets.ProductsInSet.UnitOfMeasure AS UnitOfMeasure,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.Count           AS Count,
	|		TemporaryTableSets.NumberOfPackages   AS NumberOfPackages,
	|		CASE
	|			WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0
	|				THEN (TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|			ELSE 0
	|		END                                       AS Price,
	|		TemporaryTableSets.Sum                AS Sum,
	|		TemporaryTableSets.VATRate            AS VATRate,
	|		TemporaryTableSets.VATAmount             AS VATAmount,
	|		FALSE                                        AS TheseAreComponents,
	|		TRUE                                      AS IsRecordsSet,
	|		FALSE                                        AS ThisIsReusablePackage
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN(
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber,
	|	IsRecordsSet DESC";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	FirstDocument = True;
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes   = ValueIsFilled(NameOfCodeColumn);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsReceiptFromCustomer_Invoice";
	
	PrintData        = ResultsArray[0].Select();
	Goods = ResultsArray[ResultsArray.Count() - 1].Unload();
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		GoodsTable   = Goods.FindRows(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically
		Template = PrintManagement.PrintFormTemplate("Document.GoodsReceiptFromCustomer.PF_MXL_GoodsReceiptFromCustomer");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		TemplateArea = Template.GetArea("Title");
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
			Template, TemplateArea, PrintData.Ref);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData,
			NStr("vi = 'Tiếp nhận hàng hóa từ khách';
				|ru = 'Поступление товаров от клиента';
				|en = 'Goods receipt from customer'; fa = 'دریافت کالا از مشتری';
				|it = 'Goods receipt from customer';
				|pl = 'Goods receipt from customer';
				|tr = 'Müşteriden ürün alımı'", Common.DefaultLanguageCode()));
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TitleText);
		
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Vendor");
		
		SupplierPresentation = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		
		DataStructureProvider = New Structure;
		DataStructureProvider.Insert("Vendor",               PrintData.Organization);
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea = Template.GetArea("Customer");
		
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		
		CustomerDataStructure = New Structure;
		CustomerDataStructure.Insert("Recipient",              PrintData.Recipient);
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		RoomArea = Template.GetArea("TableHeader|LineNumber");
		AreaCodes  = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductArea  = Template.GetArea("TableHeader|OwnGoods");
		DataArea = Template.GetArea("TableHeader|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		LineNumberAreaStandard = Template.GetArea("TableRow|LineNumber");
		ScopeOfStringCodesStandard  = Template.GetArea("TableRow|ColumnOfCodes");
		ProductAreaRowsStandard  = Template.GetArea("TableRow|OwnGoods");
		DataAreaOfStringIsStandard = Template.GetArea("TableRow|Data");
		
		UseSets = False;
		
		If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
			UseSets = True;
			
			LineNumberAreaSet = Template.GetArea("TableRowSet" + "|LineNumber");
			StringCodeAreaSet  = Template.GetArea("TableRowSet" + "|ColumnOfCodes");
			ProductAreaRowsSet  = Template.GetArea("TableRowSet" + "|OwnGoods");
			RowDataAreaSet = Template.GetArea("TableRowSet" + "|Data");
			
			LineNumberAreaComponents = Template.GetArea("TableRowComponents" + "|LineNumber");
			StringCodeAreaComponents  = Template.GetArea("TableRowComponents" + "|ColumnOfCodes");
			ProductAreaRowsComponents  = Template.GetArea("TableRowComponents" + "|OwnGoods");
			RowDataAreaComponents = Template.GetArea("TableRowComponents" + "|Data");
		EndIf;
		
		Sum       = 0;
		LineNumber = 0;
		
		BlankData = SetsServer.BlankData();
		
		// Output the rows of the Goods table
		For Each ProductSelection_1 In GoodsTable Do
			
			If SetsServer.UseSetArea(ProductSelection_1, UseSets) Then
				StringCodeArea  = StringCodeAreaSet;
				LineNumberArea = LineNumberAreaSet;
				RowDataArea = RowDataAreaSet;
				ProductAreaRows  = ProductAreaRowsSet;
			ElsIf SetsServer.UseScope(ProductSelection_1, UseSets) Then
				StringCodeArea  = StringCodeAreaComponents;
				LineNumberArea = LineNumberAreaComponents;
				RowDataArea = RowDataAreaComponents;
				ProductAreaRows  = ProductAreaRowsComponents;
			Else
				StringCodeArea  = ScopeOfStringCodesStandard;
				LineNumberArea = LineNumberAreaStandard;
				RowDataArea = DataAreaOfStringIsStandard;
				ProductAreaRows  = ProductAreaRowsStandard;
			EndIf;
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				SetParameter(LineNumberArea, "LineNumber", Undefined);
			Else
				LineNumber = LineNumber + 1;
				
				SetParameter(LineNumberArea, "LineNumber", LineNumber);
			EndIf;
			
			SpreadsheetDocument.Put(LineNumberArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				
				StringCodeArea.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(StringCodeArea);
			EndIf;
			
			PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(ProductSelection_1, UseSets);
			
			ProductAreaRows.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = PrefixAndPostfix.Prefix + ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint) + PrefixAndPostfix.Postfix;
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductAreaRows.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductAreaRows);
			
			If SetsServer.DisplayOnlyTitle(ProductSelection_1, UseSets) Then
				RowDataArea.Parameters.Fill(BlankData);
			Else
				RowDataArea.Parameters.Fill(ProductSelection_1);
			EndIf;
			
			SpreadsheetDocument.Join(RowDataArea);
			
			If Not SetsServer.UseScope(ProductSelection_1, UseSets) Then
				Sum    = Sum    + ProductSelection_1.Sum;
			EndIf;
			
		EndDo;
		
		// We output the basement
		RoomArea = Template.GetArea("TableFooter|LineNumber");
		AreaCodes  = Template.GetArea("TableFooter|ColumnOfCodes");
		ProductArea  = Template.GetArea("TableFooter|OwnGoods");
		DataArea = Template.GetArea("TableFooter|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		TotalDataStructure = New Structure;
		TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		
		DataArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the total of the ADS
		RoomArea = Template.GetArea("VATTableBasement|LineNumber");
		AreaCodes  = Template.GetArea("VATTableBasement|ColumnOfCodes");
		ProductArea  = Template.GetArea("VATTableBasement|OwnGoods");
		DataArea = Template.GetArea("VATTableBasement|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		// We output the Amount in words
		TemplateArea = Template.GetArea("AmountInWords");
		
		AmountToBeRegistered = Sum;
		AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency);
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số %1, thành tiền %2';
				|ru = 'Всего наименований %1, на сумму %2';
				|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
				|it = 'Totale articoli %1, per importo di %2';
				|pl = 'Razem pozycji %1, na kwotę %2';
				|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
			LineNumber,
			PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		DataStructureSumInWords = New Structure;
		DataStructureSumInWords.Insert("AmountInWords",  AmountInWords);
		DataStructureSumInWords.Insert("TotalString", TotalString);
		
		TemplateArea.Parameters.Fill(DataStructureSumInWords);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.GettingProduced) Then
			GettingProduced = PersonsTM.IndividualShortName(PrintData.GettingProduced, PrintData.Date);
			
			DataStructureGettingProduced = New Structure;
			DataStructureGettingProduced.Insert("GettingProduced", GettingProduced);
			
			TemplateArea.Parameters.Fill(DataStructureGettingProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	Return SpreadsheetDocument;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	
EndProcedure

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	
	FillParameters = New Structure(ParameterName, ParameterValue);
	
	TemplateArea.Parameters.Fill(FillParameters);
	
EndProcedure

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

#Region GeneralMethodsForBusinessOperations

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
			
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo khách hàng';
																		|ru = 'По клиенту';
																		|en = 'By customer'; fa = 'بر اساس مشتری';
																		|it = 'Per cliente';
																		|pl = 'Przez klienta';
																		|tr = 'Müşteriye göre'")));
			
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray = New Array;
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));

	ArrayOfSelectParameterRelationships = New Array;
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));
		
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
		
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	If Not Items.Find("LineOfBusiness") = Undefined Then
		
		ChoiceParametersArray = New Array;
		ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
		
		Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
		
	EndIf;
	
EndProcedure

// Returns the business of operations of the Contract.
//
// Returns:
//  Array of EnumRef.BusinessTransactions
// 
Function ContractBusinessTransaction() Export
	
	BusinessTransactions = New Array;
	BusinessTransactions.Add(Enums.BusinessTransactions.SaleToCustomer);
	BusinessTransactions.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
	
	Return BusinessTransactions;
	
EndFunction

#EndRegion

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - Contains:
//           * Items - FormAllItems - Contains:
//              ** Partner - TextBox - Contains:
//                  *** Title - String -
//              ** GoodsSelectTransferredGoods - FormCommand - Contains:
//                  *** Title - String -
//              ** CloseRequest - FormCommand - Contains:
//                  *** Title - String -
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	Object    = Form.Object;
	
	UsePartnersAndCounterparties = 
		GetFunctionalOption("UsePartnersAndCounterparties");
	
	ToUseTermsOfSales = 
		GetFunctionalOption("ToUseTermsOfSales");
	
	Items.Terms.Visible = ToUseTermsOfSales;
	Items.CounterpartyCheckIssueCounterpartyPages.Visible
		= UsePartnersAndCounterparties;
	
EndProcedure

// Gets the default contract.
//
// Parameters:
//    Object                         - FormDataStructure, DocumentObject.GoodsReceiptFromCustomer - The object from which the main parameters for the search will be taken.
//    CurrencySelection_2                  - Boolean - Search by the specified settlement currency of the Contract you are looking for (True) or
//												without taking into account the settlement currency (False).
//    FilterByLineOfBusiness - Boolean - Conduct a search in the specified area of activity of the desired Contract (True) or
//												in all directions (False).
//
// Returns:
//    CatalogRef.CounterpartyContracts - the default counterparty agreement.
//
Function GetDefaultContract(Object, CurrencySelection_2 = True, FilterByLineOfBusiness = True) Export
	
	Currency = Undefined;
	If CurrencySelection_2 Then
		Currency = Object.Currency;
	EndIf;
	
	LineOfBusiness = Undefined;
	If FilterByLineOfBusiness
	   And GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		LineOfBusiness = Object.LineOfBusiness;
	EndIf;

	BusinessTransactions = ContractBusinessTransaction();
	
	Contract = SalesServer.GetDefaultContract(
		Object,
		BusinessTransactions,
		Currency,
		LineOfBusiness);
	
	Return Contract;
	
EndFunction

// Adds the action "Recalculate the number of units"
//
// Parameters:
//  StructureOfActions - Structure - 
//
Procedure AddActionRecalculateNumberOfUnits(StructureOfActions) Export
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ParametersForRecalculatingNumberOfUnits());
	
EndProcedure

// Returns the parameters for recalculating the client units
//
// Returns:
//  Undefined - 
//
Function ParametersForRecalculatingNumberOfUnits() Export
	
	Return Undefined;
	
EndFunction

// Returns the parameters for rounding
// 
// Parameters:
//  Warehouse - CatalogRef.Warehouses - 
// 
// Returns:
// 	Structure - the elements contain a structure of rounding parameters 
// 				See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding(Warehouse) Export
	
	Return New Structure("Goods");
	
EndFunction

Function QueryTextBalancesToBeProcessedByOrders(TempTableName = "TTAccountingData")
	
	QueryText =
	"SELECT ALLOWED
	|	TableRevolutions.ReferenceOrder AS ReferenceOrder,
	|	TableRevolutions.Products AS Products,
	|	TableRevolutions.Characteristic AS Characteristic,
	|	TableRevolutions.RowCode AS RowCode,
	|	TableRevolutions.Series AS Series,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS ShippedQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS ShippedAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS RegisteredUpToPPPQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS RegisteredUpToPPPAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS DeductedToPPPQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS DebitedToPPPAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS QuantityReadyForAcceptance,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS AmountToBeAccepted,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS QuantityAccepted_,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS AcceptedAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS IssuedQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS IssuedAmount
	|INTO OrdersForShipmentWithoutGrouping
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(
	|			,
	|			,
	|			,
	|			ReferenceOrder IN (&References)
	|				AND Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|				AND Factor IN (
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|						)
	|	) AS TableRevolutions
	|
	|UNION ALL
	|
	|SELECT
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.RowCode AS RowCode,
	|	Table.Series AS Series,
	|	0 AS ShippedQuantity,
	|	0 AS ShippedAmount,
	|	0 AS RegisteredUpToPPPQuantity,
	|	0 AS RegisteredUpToPPPAmount,
	|	0 AS DeductedToPPPQuantity,
	|	0 AS DebitedToPPPAmount,
	|	0 AS QuantityReadyForAcceptance,
	|	0 AS AmountToBeAccepted,
	|	-Table.Count AS QuantityAccepted_,
	|	-Table.Sum AS AcceptedAmount,
	|	0 AS IssuedQuantity,
	|	0 AS IssuedAmount
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|WHERE
	|	Table.Active
	|	AND Table.Recorder = &Recorder
	|	AND Table.ReferenceOrder IN (&References)
	|	AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND Table.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersForShipmentWithoutGrouping.ReferenceOrder AS ReferenceOrder,
	|	OrdersForShipmentWithoutGrouping.Products AS Products,
	|	OrdersForShipmentWithoutGrouping.Characteristic AS Characteristic,
	|	OrdersForShipmentWithoutGrouping.RowCode AS RowCode,
	|	OrdersForShipmentWithoutGrouping.Series AS Series,
	|	SUM(OrdersForShipmentWithoutGrouping.ShippedQuantity) AS ShippedQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.ShippedAmount) AS ShippedAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPQuantity) AS RegisteredUpToPPPQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPAmount) AS RegisteredUpToPPPAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.DeductedToPPPQuantity) AS DeductedToPPPQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.DebitedToPPPAmount) AS DebitedToPPPAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.QuantityReadyForAcceptance) AS QuantityReadyForAcceptance,
	|	SUM(OrdersForShipmentWithoutGrouping.AmountToBeAccepted) AS AmountToBeAccepted,
	|	SUM(OrdersForShipmentWithoutGrouping.QuantityAccepted_) AS QuantityAccepted_,
	|	SUM(OrdersForShipmentWithoutGrouping.AcceptedAmount) AS AcceptedAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.IssuedQuantity) AS IssuedQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.IssuedAmount) AS IssuedAmount
	|INTO ShipmentOrdersAreGrouped
	|FROM
	|	OrdersForShipmentWithoutGrouping AS OrdersForShipmentWithoutGrouping
	|
	|GROUP BY
	|	OrdersForShipmentWithoutGrouping.ReferenceOrder,
	|	OrdersForShipmentWithoutGrouping.Products,
	|	OrdersForShipmentWithoutGrouping.Characteristic,
	|	OrdersForShipmentWithoutGrouping.RowCode,
	|	OrdersForShipmentWithoutGrouping.Series
	|
	|HAVING
	|	SUM(OrdersForShipmentWithoutGrouping.ShippedQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.ShippedAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.DeductedToPPPQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.DebitedToPPPAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.QuantityReadyForAcceptance) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.AmountToBeAccepted) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.QuantityAccepted_) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.AcceptedAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.IssuedQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.IssuedAmount) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShipmentOrdersAreGrouped.ReferenceOrder AS ReferenceOrder,
	|	ShipmentOrdersAreGrouped.Products AS Products,
	|	ShipmentOrdersAreGrouped.Characteristic AS Characteristic,
	|	ShipmentOrdersAreGrouped.RowCode AS RowCode,
	|	MAX(ShipmentOrdersAreGrouped.Series) AS Series,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	SUM(CASE
	|		WHEN ShipmentOrdersAreGrouped.ReferenceOrder REFS Document.SaleAdjustment
	|			THEN ShipmentOrdersAreGrouped.QuantityReadyForAcceptance - ShipmentOrdersAreGrouped.QuantityAccepted_
	|		ELSE 
	|			ShipmentOrdersAreGrouped.ShippedQuantity
	|				+ ShipmentOrdersAreGrouped.RegisteredUpToPPPQuantity
	|				- ShipmentOrdersAreGrouped.DeductedToPPPQuantity
	|				- ShipmentOrdersAreGrouped.QuantityAccepted_
	|				- ShipmentOrdersAreGrouped.IssuedQuantity
	|	END) AS ForRegistrationQuantity,
	|	SUM(CASE
	|		WHEN ShipmentOrdersAreGrouped.ReferenceOrder REFS Document.SaleAdjustment
	|			THEN ShipmentOrdersAreGrouped.AmountToBeAccepted - ShipmentOrdersAreGrouped.AcceptedAmount
	|		ELSE 
	|			ShipmentOrdersAreGrouped.ShippedAmount
	|				+ ShipmentOrdersAreGrouped.RegisteredUpToPPPAmount
	|				- ShipmentOrdersAreGrouped.DebitedToPPPAmount
	|				- ShipmentOrdersAreGrouped.AcceptedAmount
	|				- ShipmentOrdersAreGrouped.IssuedAmount
	|	END) AS AmountToBeProcessed
	|INTO TTForRegistrationByOrder
	|FROM
	|	ShipmentOrdersAreGrouped AS ShipmentOrdersAreGrouped
	|
	|GROUP BY
	|	ShipmentOrdersAreGrouped.ReferenceOrder,
	|	ShipmentOrdersAreGrouped.Products,
	|	ShipmentOrdersAreGrouped.Characteristic,
	|	ShipmentOrdersAreGrouped.RowCode
	|
	|HAVING
	|	SUM(CASE
	|		WHEN ShipmentOrdersAreGrouped.ReferenceOrder REFS Document.SaleAdjustment
	|			THEN ShipmentOrdersAreGrouped.QuantityReadyForAcceptance - ShipmentOrdersAreGrouped.QuantityAccepted_
	|		ELSE
	|			ShipmentOrdersAreGrouped.ShippedQuantity
	|				+ ShipmentOrdersAreGrouped.RegisteredUpToPPPQuantity
	|				- ShipmentOrdersAreGrouped.DeductedToPPPQuantity
	|				- ShipmentOrdersAreGrouped.QuantityAccepted_
	|				- ShipmentOrdersAreGrouped.IssuedQuantity
	|	END) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OrdersForShipmentWithoutGrouping
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ShipmentOrdersAreGrouped
	|";
	
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBalancesToBeProcessedUnderCCD(NameOfTemporaryTableToBeProcessedByOrders,
	TempTableName = "TTAccountingData")

	QueryText =
	"SELECT ALLOWED DISTINCT
	|	Table.Ref AS Document
	|INTO SalesDocumentsAll
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	Table.SalesOrder IN (&References)
	|	AND Table.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Document
	|FROM
	|	Document.GoodsShipmentToCustomer AS Table
	|WHERE
	|	Table.Ref IN (&References)
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Document
	|FROM
	|	Document.GoodsShipmentToCustomer AS Table
	|WHERE
	|	Table.CorrectedDocument IN (&References)
	|	AND Table.Ref.Patch
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS Document
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS Table
	|WHERE
	|	Table.ReferenceOrder IN (&References)
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS Document
	|FROM
	|	Document.OBEntryGoods.Goods AS Table
	|WHERE
	|	Table.Ref.Lot IN (&References)
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS Document
	|FROM
	|	Document.SaleAdjustment.Discrepancies AS Table
	|WHERE
	|	Table.Ref IN (&References)
	|	AND Table.Ref.Posted
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	InventoryKinds.ItemsLocationAttributesShipment AS ItemsLocationAttributes,
	|	InventoryKinds.CCDNumber                           AS CCDNumber,
	|	InventoryKinds.Count                         AS QuantityFromDocument,
	|	CASE
	|		WHEN Goods.SalesOrder IN (
	|	                   VALUE(Document.SalesOrder.EmptyRef),
	|	                   VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                   VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                   UNDEFINED
	|	                   )
	|				AND Goods.Ref.Patch
	|			THEN Goods.Ref.CorrectedDocument
	|		WHEN Goods.SalesOrder IN (
	|	                   VALUE(Document.SalesOrder.EmptyRef),
	|	                   VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                   VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                   UNDEFINED
	|	                   )
	|			THEN Goods.Ref
	|		WHEN Goods.SalesOrder REFS Document.SalesOrder
	|				AND CAST(Goods.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			THEN Goods.Ref
	|		WHEN Goods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(Goods.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			THEN Goods.Ref
	|		ELSE
	|			Goods.SalesOrder
	|	END                                          AS ReferenceOrder,
	|	Goods.RowCode                               AS RowCode
	|INTO InventoryLocationAttributesWithCCDNumbersAndNoGrouping
	|FROM
	|	Document.GoodsShipmentToCustomer.InventoryKinds AS InventoryKinds
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON InventoryKinds.Ref = SalesDocumentsAll.Document
	|	INNER JOIN Document.GoodsShipmentToCustomer.Goods AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes = Goods.ItemsLocationAttributes
	|		AND InventoryKinds.SalesOrder = Goods.SalesOrder
	|		AND InventoryKinds.RowCode = Goods.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.CCDNumber                   AS CCDNumber,
	|	Goods.Count                 AS QuantityFromDocument,
	|	Goods.ReferenceOrder               AS ReferenceOrder,
	|	0                                 AS RowCode
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS Goods
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON Goods.Ref = SalesDocumentsAll.Document
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.CCDNumber                   AS CCDNumber,
	|	Goods.Count                 AS QuantityFromDocument,
	|	Goods.Ref.Lot              AS ReferenceOrder,
	|	Goods.RowCode                  AS RowCode
	|FROM
	|	Document.OBEntryGoods.Goods AS Goods
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON Goods.Ref = SalesDocumentsAll.Document
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	CASE
	|		WHEN Discrepancies.Count < 0
	|			THEN -Discrepancies.Count
	|		ELSE
	|			Discrepancies.Count
	|	END                                  AS QuantityFromDocument,
	|	Discrepancies.Ref                     AS ReferenceOrder,
	|	Discrepancies.RowCode                  AS RowCode
	|FROM
	|	Document.SaleAdjustment.InventoryOwnerAttributesGoodsReceipt AS InventoryKinds
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON InventoryKinds.Ref = SalesDocumentsAll.Document
	|	INNER JOIN Document.SaleAdjustment.Discrepancies AS Discrepancies
	|		ON InventoryKinds.Ref = Discrepancies.Ref
	|		AND InventoryKinds.ItemsLocationAttributes = Discrepancies.ItemsLocationAttributes
	|		AND InventoryKinds.SalesOrder = Discrepancies.SalesOrder
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	Table.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	Table.CCDNumber                     AS CCDNumber,
	|	SUM(Table.QuantityFromDocument) AS QuantityFromDocument,
	|	Table.ReferenceOrder                 AS ReferenceOrder,
	|	Table.RowCode                    AS RowCode
	|INTO InventoryLocationAttributesWithCCDNumbers
	|FROM
	|	InventoryLocationAttributesWithCCDNumbersAndNoGrouping AS Table
	|
	|GROUP BY
	|	Table.ItemsLocationAttributes,
	|	Table.CCDNumber,
	|	Table.ReferenceOrder,
	|	Table.RowCode
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	Set.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Set.CCDNumber                   AS CCDNumber,
	|	SUM(Set.Count)          AS BalanceOfCCD
	|INTO TTBalancesOnCCD
	|FROM
	|	(SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CCDNumber                   AS CCDNumber,
	|		Table.CountBalance          AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(, (ItemsLocationAttributes, CCDNumber) IN (
	|			                                           SELECT
	|			                                               ItemsLocationAttributes,
	|			                                               CCDNumber
	|			                                           FROM
	|			                                               InventoryLocationAttributesWithCCDNumbers
	|			                                           )
	|		) AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CCDNumber                   AS CCDNumber,
	|		Table.Count                 AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS Table
	|	WHERE
	|		Table.Active
	|		AND Table.Recorder IN(&Recorder)
	|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ItemsLocationAttributes,
	|	Set.CCDNumber
	|
	|HAVING
	|	SUM(Set.Count) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Products AS Products,
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryLocationAttributesWithCCDNumbers.CCDNumber                   AS CCDNumber,
	|	InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument      AS QuantityFromDocument,
	|	InventoryLocationAttributesWithCCDNumbers.ReferenceOrder               AS ReferenceOrder,
	|	InventoryLocationAttributesWithCCDNumbers.RowCode                  AS RowCode,
	|	SUM(CASE
	|		WHEN InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument < TTBalancesOnCCD.BalanceOfCCD
	|			THEN InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument
	|		ELSE
	|			TTBalancesOnCCD.BalanceOfCCD
	|	END) AS BalanceOfCCD
	|INTO TTBalancesOnGTDSByOrders
	|FROM
	|	InventoryLocationAttributesWithCCDNumbers AS InventoryLocationAttributesWithCCDNumbers
	|	INNER JOIN TTBalancesOnCCD AS TTBalancesOnCCD
	|		ON InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes = TTBalancesOnCCD.ItemsLocationAttributes
	|		AND InventoryLocationAttributesWithCCDNumbers.CCDNumber = TTBalancesOnCCD.CCDNumber
	|
	|GROUP BY
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Products,
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Characteristic,
	|	InventoryLocationAttributesWithCCDNumbers.CCDNumber,
	|	InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument,
	|	InventoryLocationAttributesWithCCDNumbers.ReferenceOrder,
	|	InventoryLocationAttributesWithCCDNumbers.RowCode
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	TTForRegistrationByOrder.ReferenceOrder               AS ReferenceOrder,
	|	TTForRegistrationByOrder.Products               AS Products,
	|	TTForRegistrationByOrder.Characteristic             AS Characteristic,
	|	TTForRegistrationByOrder.RowCode                  AS RowCode,
	|	TTForRegistrationByOrder.Series                      AS Series,
	|	ISNULL(TTBalancesOnGTDSByOrders.CCDNumber, VALUE(Catalog.CCDNumbers.EmptyRef)) AS CCDNumber,
	|	ISNULL(TTBalancesOnGTDSByOrders.BalanceOfCCD, 0) AS BalanceOfCCD,
	|	TTForRegistrationByOrder.ForRegistrationQuantity      AS ForRegistrationQuantity,
	|	TTForRegistrationByOrder.AmountToBeProcessed           AS AmountToBeProcessed
	|INTO Result
	|FROM
	|	#NameOfTemporaryTableToBeProcessedByOrders AS TTForRegistrationByOrder
	|	LEFT JOIN TTBalancesOnGTDSByOrders AS TTBalancesOnGTDSByOrders
	|		ON TTForRegistrationByOrder.Products = TTBalancesOnGTDSByOrders.Products
	|		AND TTForRegistrationByOrder.Characteristic = TTBalancesOnGTDSByOrders.Characteristic
	|		AND TTForRegistrationByOrder.ReferenceOrder = TTBalancesOnGTDSByOrders.ReferenceOrder
	|		AND TTForRegistrationByOrder.RowCode = TTBalancesOnGTDSByOrders.RowCode
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	RECORDAUTONUMBER()               AS LineNumber,
	|	Result.ReferenceOrder          AS ReferenceOrder,
	|	Result.Products          AS Products,
	|	Result.Characteristic        AS Characteristic,
	|	Result.RowCode             AS RowCode,
	|	Result.Series                 AS Series,
	|	Result.CCDNumber              AS CCDNumber,
	|	Result.BalanceOfCCD          AS BalanceOfCCD,
	|	Result.ForRegistrationQuantity AS ForRegistrationQuantity,
	|	Result.AmountToBeProcessed      AS AmountToBeProcessed
	|INTO ResultIsNumbered
	|FROM
	|	Result
	|
	|INDEX BY
	|	LineNumber,
	|	ReferenceOrder,
	|	Products,
	|	Characteristic,
	|	RowCode,
	|	Series,
	|	CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	TableBase.ReferenceOrder     AS ReferenceOrder,
	|	TableBase.Products     AS Products,
	|	TableBase.Characteristic   AS Characteristic,
	|	TableBase.RowCode        AS RowCode,
	|	TableBase.Series            AS Series,
	|	TableBase.CCDNumber         AS CCDNumber,
	|	CASE
	|		WHEN TableBase.BalanceOfCCD = 0
	|			THEN TableBase.ForRegistrationQuantity
	|		WHEN TableBase.ForRegistrationQuantity >= SUM(Distribution_Table.BalanceOfCCD)
	|			THEN TableBase.BalanceOfCCD
	|		WHEN TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity) < 0
	|			THEN 0
	|		ELSE
	|			  TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity)
	|	END AS ForRegistrationQuantity,
	|	CASE
	|		WHEN TableBase.BalanceOfCCD = 0
	|			THEN TableBase.ForRegistrationQuantity
	|		WHEN TableBase.ForRegistrationQuantity >= SUM(Distribution_Table.BalanceOfCCD)
	|			THEN TableBase.BalanceOfCCD
	|		WHEN TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity) < 0
	|			THEN 0
	|		ELSE
	|			  TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity)
	|	END * TableBase.AmountToBeProcessed / TableBase.ForRegistrationQuantity AS AmountToBeProcessed
	|INTO #TempTableName
	|FROM
	|	ResultIsNumbered AS TableBase
	|		LEFT JOIN ResultIsNumbered AS Distribution_Table
	|		ON TableBase.LineNumber >= Distribution_Table.LineNumber
	|		AND TableBase.ReferenceOrder = Distribution_Table.ReferenceOrder
	|		AND TableBase.Products = Distribution_Table.Products
	|		AND TableBase.Characteristic = Distribution_Table.Characteristic
	|		AND TableBase.Series = Distribution_Table.Series
	|		AND TableBase.RowCode = Distribution_Table.RowCode
	|		AND TableBase.CCDNumber = Distribution_Table.CCDNumber
	|
	|GROUP BY
	|	TableBase.LineNumber,
	|	TableBase.ReferenceOrder,
	|	TableBase.Products,
	|	TableBase.Characteristic,
	|	TableBase.RowCode,
	|	TableBase.Series,
	|	TableBase.CCDNumber,
	|	TableBase.BalanceOfCCD,
	|	TableBase.ForRegistrationQuantity,
	|	TableBase.AmountToBeProcessed
	|
	|HAVING
	|	CASE
	|		WHEN TableBase.BalanceOfCCD = 0
	|			THEN TableBase.ForRegistrationQuantity
	|		WHEN TableBase.ForRegistrationQuantity >= SUM(Distribution_Table.BalanceOfCCD)
	|			THEN TableBase.BalanceOfCCD
	|		WHEN TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity) < 0
	|			THEN 0
	|		ELSE
	|			  TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity)
	|	END <> 0
	|";
	
	QueryText = StrReplace(
		QueryText,
		"#NameOfTemporaryTableToBeProcessedByOrders",
		NameOfTemporaryTableToBeProcessedByOrders);
	
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Return QueryText;
	
EndFunction

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Date                    AS Period,
	|	TRUE                                  AS ByReferences,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.Warehouse                   AS Warehouse,
	|	DocumentData.ControlledLotReference    AS ControlledLotReference,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.SalesOpportunity                  AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.Department           AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.IncomingDocumentDate  AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.GoodsReceiptOption   AS GoodsReceiptOption,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                   AS UseWarehouseManagemantSystemForGoodsReceipt,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.Author                   AS Author,
	|	DocumentData.Patch             AS Patch,
	|	DocumentData.ReversedDocument    AS ReversedDocument,
	|	DocumentData.CorrectedDocument    AS CorrectedDocument,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting
	|FROM
	|	Document.GoodsReceiptFromCustomer AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	For Each Column In QueryResult.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ContractInformation    = "";
	NumberForPrinting           = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	MetadataIdentifier = Common.MetadataObjectID("Document.GoodsReceiptFromCustomer");
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier", MetadataIdentifier);
	Query.SetParameter("NumberForPrinting",           NumberForPrinting);
	Query.SetParameter("ContractInformation",    ContractInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                        AS Period,
	|	&BusinessOperation         AS BusinessOperation,
	|	&Organization                   AS Organization,
	|	&Department                 AS Department,
	|	TableTypesOfStocks_.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.InventoryLocationAttributeOfItemsFromPartnersWithNoDestination AS ItemsLocationAttributes,
	|	&Contract                       AS Warehouse,
	|	TableTypesOfStocks_.InventoryType  AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  AS InventoryOwnerAttribute,
	|	&LineOfBusiness       AS CorLineOfBusiness,
	|	TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.Warehouse       AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.InventoryType AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END                          AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END                          AS CorSourceOfItemsFinancialAccountingGroup,
	|	TableTypesOfStocks_.Count  AS Count,
	|	TableTypesOfStocks_.Count  AS CorQuantity,
	|	0                              AS Cost,
	|	0                              AS CostExcludingVAT,
	|	0                              AS LocalCost
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber                AS LineNumber,
	|	InventoryKinds.Ref                     AS Ref,
	|	&Organization                           AS Organization,
	|	Dimension.StorageLocation                AS Warehouse,
	|	InventoryKinds.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType      AS InventoryType,
	|	InventoryKinds.SetAccountingDimension      AS SetAccountingDimension,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey   AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	AnalyticsForPartnersWithoutAppointment.DimensionKey AS InventoryLocationAttributeOfItemsFromPartnersWithNoDestination,
	|	Dimension.Products                 AS Products,
	|	Dimension.Characteristic               AS Characteristic,
	|	LogInAnalytics.DimensionKey   AS AnalysisOfAccountingForProductList,
	|	AnalyticsOfRegistrationWithoutAssignment.DimensionKey AS InventoryLocationAttributeAccountingWithoutAssignment,
	|	InventoryKinds.ProductsRecordingAsReceived  AS ProductsRecordingAsReceived,
	|	InventoryKinds.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	InventoryKinds.Count                 AS Count,
	|	InventoryKinds.QuantityByGBRN           AS QuantityByGBRN,
	|	InventoryKinds.CCDNumber                   AS CCDNumber,
	|	InventoryKinds.CCDNumber.CCDNumberType      AS CCDNumberCCDNumberType,
	|	CASE
	|		WHEN Dimension.Purpose.LineOfBusiness IS NULL
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE Dimension.Purpose.LineOfBusiness
	|	END AS LineOfBusiness,
	|	ISNULL(Dimension.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityType,
	|	InventoryKinds.RowID        AS RowID
	|INTO TTTableTypesOfStocks
	|FROM
	|	Document.GoodsReceiptFromCustomer.InventoryKinds AS InventoryKinds
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryKinds.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsForPartnersWithoutAppointment
	|		ON InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Products = AnalyticsForPartnersWithoutAppointment.Products
	|			AND InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Characteristic = AnalyticsForPartnersWithoutAppointment.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributesGoodsAtPartners.Series = AnalyticsForPartnersWithoutAppointment.Series
	|			AND InventoryKinds.ItemsLocationAttributesGoodsAtPartners.StorageLocation = AnalyticsForPartnersWithoutAppointment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsForPartnersWithoutAppointment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsForPartnersWithoutAppointment.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS LogInAnalytics
	|		ON InventoryKinds.ProductsRecordingAsReceived = LogInAnalytics.Products
	|			AND InventoryKinds.CharacteristicRecordingAsReceived = LogInAnalytics.Characteristic
	|			AND Dimension.Series = LogInAnalytics.Series
	|			AND Dimension.StorageLocation = LogInAnalytics.StorageLocation
	|			AND Dimension.Purpose = LogInAnalytics.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsForPartnersWithoutAppointment.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfRegistrationWithoutAssignment
	|		ON InventoryKinds.ProductsRecordingAsReceived = AnalyticsOfRegistrationWithoutAssignment.Products
	|			AND InventoryKinds.CharacteristicRecordingAsReceived = AnalyticsOfRegistrationWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsOfRegistrationWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsOfRegistrationWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsOfRegistrationWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsForPartnersWithoutAppointment.ProductCostElement
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Returns the Query Text of the temporary table of Registered Records of the Accumulation register of organizations' products.
//
// Parameters:
//	Query - Query - request for a document.
//	QueryTexts - ValueList of String - collection of Query Texts for the event.
//
// Returns:
//	String - The Query Text of the temporary table of Registered Records of the Accumulation register of organizations' goods.
//
Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	&Period								AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Organization		AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType	AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count		AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	&BusinessOperation				AS BusinessOperation,
	|	UNDEFINED						AS VATTaxation,
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Organization		AS ShipmentCompany,
	|	TableTypesOfStocks_.Products		AS Products,
	|	TableTypesOfStocks_.Characteristic	AS Characteristic
	|INTO TTProductsOfOrganizations
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	&Period								AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Organization		AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType	AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count		AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	&BusinessOperation				AS BusinessOperation,
	|	UNDEFINED						AS VATTaxation,
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Organization		AS ShipmentCompany,
	|	TableTypesOfStocks_.Products		AS Products,
	|	TableTypesOfStocks_.Characteristic	AS Characteristic
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber		AS LineNumber,
	|	&Period								AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableTypesOfStocks_.AnalysisOfAccountingForProductList AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Organization		AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberCCDNumberType	AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count		AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	&BusinessOperation				AS BusinessOperation,
	|	UNDEFINED						AS VATTaxation,
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Organization		AS ShipmentCompany,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived AS Products,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS Characteristic
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|
	|INDEX BY
	|	CCDNumberCCDNumberType
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	AnalystTable.Products   AS Products,
	|	AnalystTable.Characteristic AS Characteristic,
	|	AnalystTable.Purpose     AS Purpose,
	|	AnalystTable.Series          AS Series,
	|	AnalystTable.Warehouse          AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		Goods.ItemsLocationAttributes.Products   AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment                                AS Purpose,
	|		Goods.ItemsLocationAttributes.Series          AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|	FROM
	|		Document.GoodsReceiptFromCustomer.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributes.Products = Dimension.Products
	|				AND Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|				AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Products   AS Products,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Characteristic AS Characteristic,
	|		&EmptyAssignment                                                AS Purpose,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.Series          AS Series,
	|		Goods.ItemsLocationAttributesGoodsAtPartners.StorageLocation  AS Warehouse
	|	FROM
	|		Document.GoodsReceiptFromCustomer.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributesGoodsAtPartners.Products = Dimension.Products
	|				AND Goods.ItemsLocationAttributesGoodsAtPartners.Characteristic = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributesGoodsAtPartners.Series = Dimension.Series
	|				AND Goods.ItemsLocationAttributesGoodsAtPartners.StorageLocation = Dimension.StorageLocation
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		Goods.ProductsRecordingAsReceived                AS Products,
	|		Goods.CharacteristicRecordingAsReceived              AS Characteristic,
	|		Goods.ItemsLocationAttributes.Purpose    AS Purpose,
	|		Goods.ItemsLocationAttributes.Series         AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation AS Warehouse
	|	FROM
	|		Document.GoodsReceiptFromCustomer.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ProductsRecordingAsReceived = Dimension.Products
	|				AND Goods.CharacteristicRecordingAsReceived = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|				AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|				AND Goods.ItemsLocationAttributes.Purpose = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND Goods.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		Goods.ProductsRecordingAsReceived                AS Products,
	|		Goods.CharacteristicRecordingAsReceived              AS Characteristic,
	|		&EmptyAssignment                               AS Purpose,
	|		Goods.ItemsLocationAttributes.Series         AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation AS Warehouse
	|	FROM
	|		Document.GoodsReceiptFromCustomer.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ProductsRecordingAsReceived = Dimension.Products
	|				AND Goods.CharacteristicRecordingAsReceived = Dimension.Characteristic
	|				AND Goods.ItemsLocationAttributes.Series = Dimension.Series
	|				AND Goods.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|				AND &EmptyAssignment = Dimension.Purpose
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Goods.ProductsRecordingAsReceived <> VALUE(Catalog.Products.EmptyRef)
	|	
	|	) AS AnalystTable";
	
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Ref",                 Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",       Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
		Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	QueryAnalyst.SetParameter("Ref",           Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.GoodsReceiptFromCustomer";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	TextOfRequestToRedefineBusinessTransaction = "
		|	CASE
		|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.EmptyRef)
		|			THEN VALUE(Enum.BusinessTransactions.GoodsReceiptFromCustomer)
		|		ELSE GoodsTable.Ref.BusinessOperation
		|	END";
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
								Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("UseAdvancedFeaturesOfSalesOrder",
								GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",         """""");
	RedefiningParameterCalculation.Insert("ContractInformation",  """""");
	RedefiningParameterCalculation.Insert("BusinessOperation", TextOfRequestToRedefineBusinessTransaction);
	
	If RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
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
	
	If SynonymForDocumentTable <> "GoodsTable" Then
		For Each CalculationParameter In RedefiningParameterCalculation Do
			RedefiningParameterCalculation[CalculationParameter.Key] = StrReplace(
				CalculationParameter.Value, "GoodsTable", SynonymForDocumentTable);
		EndDo;
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
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness =
	"SELECT
	|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
	|	DirectionsOfDocuments.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))
	|		OR (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfAnalytics
	|INTO TTLinesOfBusiness
	|FROM
	|	Document.GoodsShipmentToCustomer AS DirectionsOfDocuments
	|WHERE
	|	DirectionsOfDocuments.Ref IN
	|		(SELECT
	|			ReferenceOrder
	|		FROM
	|			Document.GoodsReceiptFromCustomer.Goods
	|		WHERE
	|			Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
	|	DirectionsOfDocuments.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))
	|		OR (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfAnalytics
	|FROM
	|	Document.SalesOrder AS DirectionsOfDocuments
	|WHERE
	|	DirectionsOfDocuments.Ref IN
	|		(SELECT
	|			ReferenceOrder
	|		FROM
	|			Document.GoodsReceiptFromCustomer.Goods
	|		WHERE
	|			Ref = &Ref)
	|	AND NOT DirectionsOfDocuments.ThisIsOrderAsInvoice";
	
	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	#Region CancellationOfPlans
	
	TextPaymentPlans =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).PaymentMethod AS PaymentMethod,
	|	DocumentDataHeader.Date AS PaymentDate,
	|	ScheduleStages.PaymentOption AS PaymentOption,
	|	-Table.Sum * ScheduleStages.PaymentPercentage / 100 AS AmountDue,
	|	0 AS MeasuringGoodsVarianceAmount,
	|	TRUE AS ExcludeDuringControl
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS Table
	|		INNER JOIN Document.GoodsReceiptFromCustomer AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		INNER JOIN Document.SalesOrder.PaymentScheduleSteps AS ScheduleStages
	|		ON Table.ReferenceOrder = ScheduleStages.Ref
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND VALUETYPE(DocumentDataHeader.ReferenceOrder) IN (TYPE(Document.SalesOrder), TYPE(Document.GoodsShipmentToCustomer))
	|	AND Table.RowCode <> 0
	|	AND NOT DocumentDataHeader.ReduceShipmentByReference
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptFromCustomer)
	|	AND VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND NOT CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
	
	TextShipmentPlans =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObject AS ARAPObject,
	|	ENDOFPERIOD(DocumentDataHeader.Date, DAY) AS DateOfShipment,
	|	-Table.Sum AS IncreaseToBeSHIPPED,
	|	-Table.Sum AS IncreaseShipping,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).PaymentMethod AS PaymentMethod
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS Table
	|		INNER JOIN Document.GoodsReceiptFromCustomer AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND VALUETYPE(DocumentDataHeader.ReferenceOrder) IN (TYPE(Document.SalesOrder), TYPE(Document.GoodsShipmentToCustomer))
	|	AND Table.RowCode <> 0
	|	AND NOT DocumentDataHeader.ReduceShipmentByReference
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsReceiptFromCustomer)
	|	AND VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND NOT CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans);
	
	#EndRegion
	
	#Region ReduceShipping
	
	TextProducts_1 =
	"SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	DocumentDataHeader.Contract AS Contract,
	|	DocumentDataHeader.LineOfBusiness AS LineOfBusiness,
	|	CAST(Table.ReferenceOrder AS Document.GoodsShipmentToCustomer).ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Date AS DateOfShipment,
	|	0 AS IncreaseShipping,
	|	Table.Sum AS ReduceShipping,
	|	0 AS IncreaseToBeSHIPPED,
	|	0 AS ReduceToBESHIPPED,
	|	Table.Sum AS AmountARAP,
	|	Table.ReferenceOrder AS SalesOrder_,
	|	0 AS DepositForPackage,
	|	FALSE AS ExceedingOrder,
	|	TRUE AS InvoiceForOrders,
	|	TRUE AS ThisIsTransferOfOwnershipBasedOnShipment,
	|	CAST(Table.ReferenceOrder AS Document.GoodsShipmentToCustomer).ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
	|	DocumentDataHeader.Currency AS DocumentCurrency
	|FROM
	|	Document.GoodsReceiptFromCustomer AS DocumentDataHeader
	|		INNER JOIN Document.GoodsReceiptFromCustomer.Goods AS Table
	|		ON DocumentDataHeader.Ref = Table.Ref
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND VALUETYPE(Table.ReferenceOrder) = TYPE(Document.GoodsShipmentToCustomer)";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, "", "", "", TextProducts_1);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	QueryText = "
	|SELECT
	|	CASE
	|		WHEN SeriesTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN SeriesTable.Products
	|		ELSE SeriesTable.ProductsRecordingAsReceived
	|	END					AS Products,
	|	CASE
	|		WHEN SeriesTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN SeriesTable.Characteristic
	|		ELSE SeriesTable.CharacteristicRecordingAsReceived
	|	END					AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END					AS Purpose,
	|	SeriesTable.Series		AS Series,
	|	SeriesTable.Count	AS Count,
	|	&Partner				AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfSender,
	|	SeriesTable.Warehouse		AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Ref					AS Document,
	|	&Period					AS Period,
	|	&Ref					AS Recorder,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsReceiptFromCustomer.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN GoodsTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN GoodsTable.Products
	|		ELSE GoodsTable.ProductsRecordingAsReceived
	|	END						AS Products,
	|	CASE
	|		WHEN GoodsTable.ProductsRecordingAsReceived = VALUE(Catalog.Products.EmptyRef)
	|			THEN GoodsTable.Characteristic
	|		ELSE GoodsTable.CharacteristicRecordingAsReceived
	|	END						AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END						AS Purpose,
	|	GoodsTable.Series			AS Series,
	|	GoodsTable.Count	AS Count,
	|	&Partner					AS Sender,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfSender,
	|	GoodsTable.Warehouse			AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.ReceivingByReturnFromACustomer) AS WarehouseOperation,
	|	&Ref						AS Document,
	|	&Period						AS Period,
	|	&Ref						AS Recorder,
	|	NOT &UseWarehouseManagemantSystemForGoodsReceipt AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
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
	|	&Ref                         AS Ref,
	|	&Period                         AS IBDocumentDate,
	|	&Number                          AS IBDocumentNumber,
	|	&MetadataIdentifier        AS RefType,
	|	&Organization                    AS Organization,
	|	&BusinessOperation          AS BusinessOperation,
	|	&Partner                        AS Partner,
	|	&Counterparty                     AS Counterparty,
	|	&Contract                        AS Contract,
	|	&LineOfBusiness        AS LineOfBusiness,
	|	&Warehouse                          AS StorageLocation,
	|	&Department                  AS Department,
	|	&Manager                       AS EmployeeResponsible,
	|	&Author                          AS Author,
	|	&Comment                    AS Comment,
	|	&Currency                         AS Currency,
	|	&DocumentAmount                 AS Sum,
	|	UNDEFINED                    AS Status,
	|	&Posted                       AS Posted,
	|	&DeletionMark                AS DeletionMark,
	|	FALSE                            AS AdditionalRecord,
	|	&ContractInformation           AS More,
	|	&IncomingDocumentDate         AS SourceDocumentDate,
	|	&IncomingDocumentNumber        AS SourceDocumentNumber,
	|	&Patch                    AS ReverseTransactionCorrection,
	|	&ReversedDocument           AS ReversedDocument,
	|	&CorrectedDocument           AS CorrectedDocument,
	|	&ExternalDocumentName AS SourceDocumentName,
	|	&Period                         AS RecordingInAccountingDate,
	|	UNDEFINED                    AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TTProductsOfOrganizations.LineNumber				AS LineNumber,
	|	TTProductsOfOrganizations.RecordType				AS RecordType,
	|	TTProductsOfOrganizations.Period					AS Period,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Organization				AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.CCDNumber				AS CCDNumber,
	|	TTProductsOfOrganizations.Count				AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN		AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation	AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation		AS VATTaxation,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute			AS CorInventoryOwnerAttribute,
	|	TTProductsOfOrganizations.ShipmentCompany	AS ShipmentCompany,
	|	TTProductsOfOrganizations.Products			AS Products,
	|	TTProductsOfOrganizations.Characteristic			AS Characteristic
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	// 1. For PM lines, where the order is not an credit note of the implementation
	"SELECT
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN (NOT GoodsTable.Ref.ReduceShipmentByReference
	|				OR GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|				OR GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|				OR GoodsTable.RowCode = 0)
	|				AND TableOfIndicators.Ref IN (
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|						)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE
	|			GoodsTable.Warehouse
	|	END AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|					)
	|				AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.Sum) AS Sum
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
	|	INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN (
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RequestedForReturn),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegisterForReturns),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.RegisteredOnReturns),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|				)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.ReferenceOrder IN (
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|				VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|				VALUE(Document.SourceDocument.EmptyRef),
	|				VALUE(Document.SaleAdjustment.EmptyRef),
	|				UNDEFINED
	|				)
	|	AND NOT (GoodsTable.ReferenceOrder REFS Document.SaleAdjustment
	|		AND GoodsTable.ReferenceOrder <> VALUE(Document.SaleAdjustment.EmptyRef))
	|
	|GROUP BY
	|	GoodsTable.Ref.Date,
	|	GoodsTable.ReferenceOrder,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.RowCode,
	|	CASE
	|		WHEN (NOT GoodsTable.Ref.ReduceShipmentByReference
	|				OR GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|				OR GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|				OR GoodsTable.RowCode = 0)
	|				AND TableOfIndicators.Ref IN (
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|						)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE
	|			GoodsTable.Warehouse
	|	END,
	|	CASE
	|		WHEN TableOfIndicators.Ref IN (
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|					VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|					)
	|				AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	TableOfIndicators.Ref
	|
	|UNION ALL
	|
	// 2. For PM lines, where the order is a credit note of the implementation
	|SELECT
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted) AS Factor,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.Sum) AS Sum
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ReferenceOrder REFS Document.SaleAdjustment
	|	AND GoodsTable.ReferenceOrder <> VALUE(Document.SaleAdjustment.EmptyRef)
	|
	|GROUP BY
	|	GoodsTable.Ref.Date,
	|	GoodsTable.ReferenceOrder,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.RowCode,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|
	|UNION ALL
	|
	// 3. For the case when the Received goods field = "Ship again" and in the line with the line code > 0 we write
	// the indicator "To be shipped", and the quantity and amount with a + sign.
	// For the case when the Received goods field = "Not shipped", we write the indicator "For registration",
	// and the quantity and amount with the sign -.
	|SELECT
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|		ELSE
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|	END AS Factor,
	|	SUM(CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Count
	|		ELSE
	|			-GoodsTable.Count
	|	END) AS Count,
	|	SUM(CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Sum
	|		ELSE
	|			-GoodsTable.Sum
	|	END) AS Sum
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.ReferenceOrder IN (
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|				VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|				VALUE(Document.SourceDocument.EmptyRef),
	|				VALUE(Document.SaleAdjustment.EmptyRef),
	|				UNDEFINED
	|				)
	|	AND NOT (GoodsTable.ReferenceOrder REFS Document.SaleAdjustment
	|		AND GoodsTable.ReferenceOrder <> VALUE(Document.SaleAdjustment.EmptyRef))
	|
	|GROUP BY
	|	GoodsTable.Ref.Date,
	|	GoodsTable.ReferenceOrder,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.RowCode,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|		ELSE
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|	END
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
	// Arrival at an irregular warehouse or for old purposes.
	"SELECT
	|	TabPart.Ref      AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.ProductsRecordingAsReceived
	|		ELSE
	|			TabPart.Products
	|	END                AS Products,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.CharacteristicRecordingAsReceived
	|		ELSE
	|			TabPart.Characteristic
	|	END                AS Characteristic,
	|	TabPart.Warehouse       AS Warehouse,
	|	TabPart.Purpose  AS Purpose,
	|	&ControlledLotReference AS ControlledLotReference,
	|	TabPart.ToControlQuality AS ToControlQuality,
	|	TabPart.ToControlQuality AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count  AS Count,
	|	FALSE                 AS OnSchedule,
	|	UNDEFINED         AS OrderInSchedule
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS TabPart
	|WHERE
	|	NOT TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|		OR TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
	|		OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	// The reverse of the receipt order for the old appointments.
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref      AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.ProductsRecordingAsReceived
	|		ELSE
	|			TabPart.Products
	|	END                AS Products,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.CharacteristicRecordingAsReceived
	|		ELSE
	|			TabPart.Characteristic
	|	END                AS Characteristic,
	|	TabPart.Warehouse       AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	-TabPart.Count AS Count,
	|	FALSE                 AS OnSchedule,
	|	UNDEFINED         AS OrderInSchedule
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS TabPart
	|WHERE
	|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
	|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref      AS Ref,
	|	TabPart.Ref.Date AS Period,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.ProductsRecordingAsReceived
	|		ELSE
	|			TabPart.Products
	|	END                AS Products,
	|	CASE
	|		WHEN TabPart.Damage
	|			THEN TabPart.CharacteristicRecordingAsReceived
	|		ELSE
	|			TabPart.Characteristic
	|	END                AS Characteristic,
	|	TabPart.Warehouse       AS Warehouse,
	|	CASE
	|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE THEN
	|			VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE
	|			TabPart.Purpose
	|	END                AS Purpose,
	|	TabPart.ToControlQuality AS ToControlQuality,
	|	TabPart.ToControlQuality AS SubjectToUnlocking,
	|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
	|	TabPart.Count  AS Count,
	|	CASE
	|		WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.GoodsReceiptFromCustomer.EmptyRef)
	|			THEN TabPart.Ref
	|		ELSE
	|			TabPart.Ref.CorrectedDocument
	|	END                AS OrderDocument,
	|	CASE
	|		WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1)
	|			THEN TabPart.Ref.DateOfReceipt
	|		ELSE
	|			TabPart.Ref.Date
	|	END                AS DateOfReceipt,
	|	TRUE               AS AvailableForConsumption,
	|	FALSE                 AS OnSchedule,
	|	UNDEFINED         AS OrderInSchedule,
	|	TabPart.Count  AS QuantityInGraph
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS TabPart
	|WHERE
	|	TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref         AS Ref,
	|	TabPart.Ref.Date    AS Period,
	|	TabPart.Products   AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Warehouse          AS Warehouse,
	|	TabPart.Purpose     AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count     AS Count,
	|	TRUE                  AS ControlOfFreeResidue,
	|	UNDEFINED            AS PlannedConsumptionOfDistributedStock
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS TabPart
	|WHERE
	|	TabPart.Ref.ReduceShipmentByReference
	|	AND NOT TabPart.ReferenceOrder REFS Document.SourceDocument
	|	AND NOT TabPart.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|	AND TabPart.RowCode <> 0";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)

	QueryTextDocument_ =
	"SELECT
	|	DataSource.Ref				AS Ref,
	|	HeaderData_.Patch				AS Patch,
	|	HeaderData_.CorrectedDocument	AS CorrectedDocument,
	|	UNDEFINED						AS OrderDocument,
	|	DataSource.Ref				AS Invoice,
	|	HeaderData_.Contract					AS Contract,
	|	HeaderData_.Terms				AS Terms,
	|	HeaderData_.GoodsReceiptOption	AS GoodsReceiptOption,
	|	HeaderData_.Date					AS Date,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE
	|			DataSource.Products
	|	END								AS Products,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE
	|			DataSource.Characteristic
	|	END								AS Characteristic,
	|	DataSource.Purpose			AS Purpose,
	|	DataSource.ToControlQuality AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	HeaderData_.ControlledLotReference AS ControlledLotReference,
	|	DataSource.Series				AS Series,
	|	DataSource.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	FALSE								AS ExceedingOrder,
	|	DataSource.Warehouse				AS Warehouse,
	|	HeaderData_.Partner					AS Sender,
	|	HeaderData_.BusinessOperation	AS BusinessOperation,
	|	DataSource.Count			AS Count,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ReceiptUnderOrders
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS DataSource
	|		LEFT JOIN Document.GoodsReceiptFromCustomer AS HeaderData_
	|		ON DataSource.Ref = HeaderData_.Ref
	|WHERE
	|	DataSource.Ref IN(&Ref)";

	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref              AS Ref,
	|	UNDEFINED                       AS OrderDocument,
	|	DataSource.Ref              AS Invoice,
	|	HeaderData_.Patch            AS Patch,
	|	HeaderData_.CorrectedDocument   AS CorrectedDocument,
	|	HeaderData_.Contract                AS Contract,
	|	HeaderData_.Terms             AS Terms,
	|	HeaderData_.GoodsReceiptOption  AS GoodsReceiptOption,
	|	HeaderData_.Date                   AS Date,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.ProductsRecordingAsReceived
	|		ELSE DataSource.Products
	|	END                              AS Products,
	|	CASE
	|		WHEN DataSource.Damage
	|			THEN DataSource.CharacteristicRecordingAsReceived
	|		ELSE DataSource.Characteristic
	|	END                              AS Characteristic,
	|	DataSource.Purpose          AS Purpose,
	|	DataSource.ToControlQuality AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	HeaderData_.ControlledLotReference   AS ControlledLotReference,
	|	DataSource.Series               AS Series,
	|	DataSource.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	FALSE                               AS ExceedingOrder,
	|	DataSource.Warehouse               AS Warehouse,
	|	HeaderData_.Partner                AS Sender,
	|	HeaderData_.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count          AS Count,
	|	TRUE                             AS ThisIsAnInvoice,
	|	FALSE                               AS ReceiptUnderOrders,
	|	FALSE                               AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS DataSource
	|		LEFT JOIN Document.GoodsReceiptFromCustomer AS HeaderData_
	|		ON DataSource.Ref = HeaderData_.Ref
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|";
	
	AdditionalSeriesConnectionFields = New Array();
	AdditionalSeriesConnectionFields.Add("ProductsRecordingAsReceived");
	AdditionalSeriesConnectionFields.Add("CharacteristicRecordingAsReceived");
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.TSSeriesName = "SetOfSeries";
	MethodParameters.AdditionalSeriesConnectionFields = AdditionalSeriesConnectionFields;
	
	WarehousesServer.IssueReceiptOfGoodsOnOneWayBasisWithConnectionSettings(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		Metadata.Documents.GoodsReceiptFromCustomer,
		MethodParameters);

EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref              AS Ref,
	|	HeaderData_.Date                    AS Period,
	|	DocumentGoods.ReferenceOrder        AS OrderDocument,
	|	HeaderData_.Ref                  AS Invoice,
	|	FALSE                                AS Patch,
	|	UNDEFINED                        AS CorrectedDocument,
	|	HeaderData_.Partner                 AS Recipient,
	|	DocumentGoods.Warehouse               AS Warehouse,
	|	DocumentGoods.Products        AS Products,
	|	DocumentGoods.Characteristic      AS Characteristic,
	|	DocumentGoods.Purpose          AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series               AS Series,
	|	DocumentGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	DocumentGoods.Count          AS Count,
	|	FALSE                                AS ExceedingOrder,
	|	FALSE                                AS Canceled,
	|	TRUE                              AS ThisIsAnInvoice,
	|	FALSE                                AS ShipmentByOrder
	|FROM
	|	Document.GoodsReceiptFromCustomer.Goods AS DocumentGoods
	|		LEFT JOIN Document.GoodsReceiptFromCustomer AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.RowCode <> 0
	|	AND DocumentGoods.Count <> 0
	|	AND HeaderData_.ReduceShipmentByReference
	|	AND NOT DocumentGoods.ReferenceOrder REFS Document.SaleAdjustment
	|	AND NOT DocumentGoods.ReferenceOrder REFS Document.SourceDocument
	|	AND NOT DocumentGoods.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|	AND NOT DocumentGoods.ReferenceOrder IN (
	|	                     UNDEFINED,
	|	                     VALUE(Document.SalesOrder.EmptyRef),
	|	                     VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                     VALUE(Document.SaleAdjustment.EmptyRef),
	|	                     VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                     VALUE(Document.SourceDocument.EmptyRef)
	|	                     )
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

// Adds an additional property for monitoring when conducting
// 
// Parameters:
//  Object - DocumentObject.GoodsReceiptFromCustomer - 
//
Procedure AddAdditionalPropertyToControlWhenConducting(Object) Export
	
	Object.RegisterRecords.CompanyGoods.AdditionalProperties.Insert("CreateSummaryTableProductsOfOrganizations");
	
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
	AdditionalTables.Add("TTTableTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
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
	|	&Period AS Period,
	|	&Ref AS Ref,
	|	UNDEFINED AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	&SalesOpportunity AS SalesOpportunity,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|	UNDEFINED AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.RowID AS RowID,
	|
	// Other fields
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
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

#EndRegion

#EndIf
#EndIf
