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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("RequestStatesForQualityControl");
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.RequestForGoodsQualityControl, DocumentRef.RequestForGoodsQualityControl - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RequestForGoodsQualityControl") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList();
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		
	EndIf;
	QueryTextTableOfQualityControlRequests(Query, QueryTexts, Registers);
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ReflectByWarehouseSubsystem(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region CalculationOfStates

// Calculates the current State of the quality control application
//
// Parameters:
//	RequestForGoodsQualityControl - DocumentRef.RequestForGoodsQualityControl - Document whose state needs to be calculated
//	StateOfApplication - ClientApplicationForm - The form in which the calculated state will be placed.
//
Procedure CalculateStatus(Val RequestForGoodsQualityControl, StateOfApplication) Export
	
	StructureOfStateOfApplication = New Structure;
	StructureOfStateOfApplication.Insert("State", Enums.StatesOfResearchRequests.EmptyRef());
	
	FillPropertyValues(StateOfApplication, StructureOfStateOfApplication);
	
	If ValueIsFilled(RequestForGoodsQualityControl) Then
	
		SetPrivilegedMode(True);
		
		QueryText = "
			|SELECT
			|	CASE
			|		WHEN NOT DocumentRequestForGoodsQualityControl.Posted 
			|			THEN VALUE(Enum.StatesOfResearchRequests.EmptyRef)
			|		ELSE
			|			ISNULL(RequestStatesForQualityControl.State, VALUE(Enum.StatesOfResearchRequests.Completed_))
			|	END AS State
			|FROM
			|	Document.RequestForGoodsQualityControl AS DocumentRequestForGoodsQualityControl
			|LEFT JOIN
			|	InformationRegister.RequestStatesForQualityControl AS RequestStatesForQualityControl
			|ON
			|	RequestStatesForQualityControl.Request = DocumentRequestForGoodsQualityControl.Ref
			|WHERE
			|	DocumentRequestForGoodsQualityControl.Ref = &RequestForGoodsQualityControl
			|";
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("RequestForGoodsQualityControl", RequestForGoodsQualityControl);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(StateOfApplication, Selection);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// Returns the Organization based on the controlled Lot reference document.
// Parameters:
//  Object - DocumentObject.RequestForGoodsQualityControl - Document
// Returns:
//  CatalogRef.Companies - Organization.
Function CompanyFromControlledLotReference(Object) Export
	
	Organization = Catalogs.Companies.EmptyRef();
	SetPrivilegedMode(True);
	Query = New Query();
	Query.Text =
		"SELECT
		|	MIN(AllControlledLotReferences.Organization) AS Organization
		|FROM
		|	Catalog.ControlledLots AS AllControlledLotReferences
		|WHERE
		|	AllControlledLotReferences.Ref IN(&References)
		|HAVING
		|	MIN(AllControlledLotReferences.Organization) = MAX(AllControlledLotReferences.Organization)";
	Query.SetParameter("References",
		Object.Goods.Unload(, "ControlledLotReference").UnloadColumn("ControlledLotReference"));
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Organization = Selection.Organization;
	EndIf;
	Return Organization;
	
EndFunction

// Adds a command to create a document "Application for quality control of goods".
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//  Undefined -
//  String of Value tables -
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.RequestForGoodsQualityControl) Then
		CreateBasedOnCommand = GenerateFrom.AddGenerationCommand(
			GenerationCommands, Metadata.Documents.RequestForGoodsQualityControl);
			CreateBasedOnCommand.FunctionalOptions = "UseGoodsQualityControl";
		Return CreateBasedOnCommand;
	EndIf;
	Return Undefined;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.RequestForGoodsQualityControl, DocumentRef.RequestForGoodsQualityControl - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Query = New Query();
	Ref = Undefined;
	
	NamesOfDocumentDetails = "ReasonForGoodsLock,Date,Number,ToScheduleGoodsUnlock,QualityConfirmationDate,Organization";
	If Common.IsReference(TypeOf(ObjectOrRef)) Then
		
		Ref = ObjectOrRef;
		Query.SetParameter("Ref", ObjectOrRef);
		Query.Text =
			"SELECT
			|	MAX(AllBatches.Partner) AS Partner,
			|	MAX(AllBatches.Contract) AS Contract,
			|	MAX(AllBatches.Counterparty) AS Counterparty,
			|	MAX(AllBatches.LineOfBusiness) AS LineOfBusiness,
			|	MAX(AllBatches.BusinessOperation) AS BusinessOperation,
			|	MAX(AllBatches.Department) AS Department,
			|	MAX(AllBatches.Sender) AS Sender,
			|	MAX(AllBatches.Partner) = MIN(AllBatches.Partner) AS OnePartner,
			|	MAX(AllBatches.Contract) = MIN(AllBatches.Contract) AS OneContract,
			|	MAX(AllBatches.Counterparty) = MIN(AllBatches.Counterparty) AS OneCounterparty,
			|	MAX(AllBatches.LineOfBusiness) = MIN(AllBatches.LineOfBusiness) AS OneLineOfBusiness,
			|	MAX(AllBatches.BusinessOperation) = MIN(AllBatches.BusinessOperation) AS OneBusinessTransaction,
			|	MAX(AllBatches.Sender) = MIN(AllBatches.Sender) AS OneSender,
			|	MAX(AllBatches.Department) = MIN(AllBatches.Department) AS OneUnit
			|FROM
			|	Document.RequestForGoodsQualityControl.Goods AS Goods
			|		
			|		LEFT JOIN Catalog.ControlledLots AS AllBatches
			|		ON AllBatches.Ref = Goods.ControlledLotReference
			|WHERE
			|	Goods.Ref = &Ref";
		
		DocumentAttributes = Common.ObjectAttributesValues(Ref, NamesOfDocumentDetails);
			
	Else
		
		Ref = ObjectOrRef.Ref;
		Goods = ObjectOrRef.Goods;
		References = Goods.Unload(, "ControlledLotReference").UnloadColumn("ControlledLotReference");
		Query.SetParameter("References", References);
		Query.Text =
			"SELECT
			|	MAX(AllBatches.Partner) AS Partner,
			|	MAX(AllBatches.Contract) AS Contract,
			|	MAX(AllBatches.Counterparty) AS Counterparty,
			|	MAX(AllBatches.LineOfBusiness) AS LineOfBusiness,
			|	MAX(AllBatches.BusinessOperation) AS BusinessOperation,
			|	MAX(AllBatches.Department) AS Department,
			|	MAX(AllBatches.Sender) AS Sender,
			|	MAX(AllBatches.Partner) = MIN(AllBatches.Partner) AS OnePartner,
			|	MAX(AllBatches.Contract) = MIN(AllBatches.Contract) AS OneContract,
			|	MAX(AllBatches.Counterparty) = MIN(AllBatches.Counterparty) AS OneCounterparty,
			|	MAX(AllBatches.LineOfBusiness) = MIN(AllBatches.LineOfBusiness) AS OneLineOfBusiness,
			|	MAX(AllBatches.BusinessOperation) = MIN(AllBatches.BusinessOperation) AS OneBusinessTransaction,
			|	MAX(AllBatches.Sender) = MIN(AllBatches.Sender) AS OneSender,
			|	MAX(AllBatches.Department) = MIN(AllBatches.Department) AS OneUnit
			|FROM
			|	Catalog.ControlledLots AS AllBatches
			|WHERE
			|	AllBatches.Ref IN(&References)";
			
		DocumentAttributes = New Structure(NamesOfDocumentDetails);
		FillPropertyValues(DocumentAttributes, ObjectOrRef);
			
	EndIf;
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	Attributes.Lot = Ref;
	Attributes.ReasonForGoodsLock = DocumentAttributes.ReasonForGoodsLock;
	Attributes.ScheduleGoodsUnlock = DocumentAttributes.ToScheduleGoodsUnlock;
	Attributes.ReceiptDocumentNumber = DocumentAttributes.Number;
	Attributes.DateOfReceiptDocument = DocumentAttributes.Date;
	Attributes.QualityConfirmationDate = DocumentAttributes.QualityConfirmationDate;
	Attributes.Organization = DocumentAttributes.Organization;
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.OnePartner <> Null Then
		If Selection.OnePartner Then
			Attributes.Partner = Selection.Partner;
		EndIf;
		If Selection.OneContract Then
			Attributes.Contract = Selection.Contract;
		EndIf;
		If Selection.OneCounterparty Then
			Attributes.Counterparty = Selection.Counterparty;
		EndIf;
		If Selection.OneLineOfBusiness Then
			Attributes.LineOfBusiness = Selection.LineOfBusiness;
		EndIf;
		If Selection.OneBusinessTransaction Then
			Attributes.BusinessOperation = Selection.BusinessOperation;
		EndIf;
		If Selection.OneSender Then
			Attributes.Sender = Selection.Sender;
		EndIf;
		If Selection.OneUnit Then
			Attributes.Department = Selection.Department;
		EndIf;
	EndIf;
	
	Return Attributes;
	
EndFunction

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		GoodsResearchIncluded = GoodsResearchIsIncluded();
		If GoodsResearchIncluded Then
			SelectedForm = "FulfillmentOfResearchRequests";
		Else
			SelectedForm = "ListForm";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

#Region StandardSubsystems

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

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
	Return;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction
// Parameters:
//  Restriction - See AccessManagementOverridable.OnFillListsWithAccessRestriction.Lists
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Warehouse, EmptyRef AS TRUE)";

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// A set of documents for the printer
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "RequestForGoodsQualityControl";
	PrintCommand.Presentation = NStr("vi = 'Giấy đề nghị kiểm soát chất lượng hàng hóa';
									|ru = 'Заявка на контроль качества товаров';
									|en = 'Request for goods quality control'; fa = 'درخواست کنترل کیفیت کالا';
									|it = 'Request for goods quality control';
									|pl = 'Request for goods quality control';
									|tr = 'Ürün kalite kontrol talebi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Order = 1;
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "RequestForGoodsQualityControl") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"RequestForGoodsQualityControl",
			NStr("vi = 'Giấy đề nghị kiểm soát chất lượng hàng hóa';
				|ru = 'Заявка на контроль качества товаров';
				|en = 'Request for goods quality control'; fa = 'درخواست کنترل کیفیت کالا';
				|it = 'Request for goods quality control';
				|pl = 'Request for goods quality control';
				|tr = 'Ürün kalite kontrol talebi'"),
			ToFormPrintedApplicationFormForQualityControlOfGoods(ObjectsArray, PrintObjects, PrintParameters),
			,
			"Document.RequestForGoodsQualityControl.PF_MXL_RequestForGoodsQualityControl");
	EndIf;
	
EndProcedure

// Defines a list of creation commands based on.
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	GoodsResearchIncluded = GoodsResearchIsIncluded();
	If Not GoodsResearchIncluded Then
		Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	EndIf;
	
EndProcedure

#EndRegion

#Region EmbeddedMechanisms

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date";
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
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.RequestForGoodsQualityControl";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse");
	SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Premise");
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Purpose");
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
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	Goods.Series AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|INDEX BY
	|	Warehouse, ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|								THEN CASE
	|										WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 13
	|										ELSE 14
	|									END
	|							ELSE CASE
	|									WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|										THEN 9
	|									ELSE 10
	|								END
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|					THEN CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 7
	|							ELSE 8
	|						END
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|						AND BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|					THEN CASE
	|							WHEN Goods.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 3
	|							ELSE 4
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO StatusTable
	|FROM
	|	ProductsToRequest AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON Goods.ProductKind = BatchAccountingPolicies.Ref
	|			AND BatchAccountingPolicies.Warehouse = Goods.Warehouse
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

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(
		FormTemplate,
		"OrderFulfillment",
		True, "Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
	Return FormTemplate;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Posting

Function FullObjectName()
	
	Return "Document.RequestForGoodsQualityControl";
	
EndFunction

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array();
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.Text =
		"SELECT
		|	DocumentData.Number AS Number
		|FROM
		|	DocumentDataHeader AS DocumentData";
	
	Attributes = Query.Execute().Select();
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Return;
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
		"SELECT
		|	HeaderData_.DataVersion AS DataVersion,
		|	HeaderData_.Date AS Date,
		|	HeaderData_.PointInTime AS PointInTime,
		|	HeaderData_.Number AS Number,
		|	HeaderData_.DeletionMark AS DeletionMark,
		|	HeaderData_.Posted AS Posted,
		|	HeaderData_.Ref AS Ref,
		|	HeaderData_.ReasonForGoodsLock AS ReasonForGoodsLock,
		|	HeaderData_.ToScheduleGoodsUnlock AS ToScheduleGoodsUnlock,
		|	HeaderData_.QualityConfirmationDate AS QualityConfirmationDate,
		|	HeaderData_.Department AS Department,
		|	HeaderData_.EmployeeResponsible AS EmployeeResponsible,
		|	HeaderData_.Author AS Author,
		|	HeaderData_.Warehouse AS Warehouse,
		|	HeaderData_.Organization AS Organization,
		|	HeaderData_.Comment AS Comment,
		|	HeaderData_.ControlledLotReference AS ControlledLotReference
		|INTO DocumentDataHeader
		|FROM
		|	Document.RequestForGoodsQualityControl AS HeaderData_
		|WHERE
		|	HeaderData_.Ref = &Ref
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryText =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Ref AS Ref,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.Package AS Package,
		|	Goods.Cell AS Cell,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.QualityIsConfirmed AS QualityIsConfirmed,
		|	Goods.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|	Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected
		|INTO DocumentDataTableItems
		|FROM
		|	Document.RequestForGoodsQualityControl.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|INDEX BY
		|	Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Function QueryTextDocumentDataTableGoodsSummary(Query, QueryTexts, BatchMode = False)
	
	TableName = "DocumentDataTableGoodsSummary";
	
	QueryText =
		"SELECT
		|	GoodsTable.Ref AS Ref,
		|	CASE
		|		WHEN COUNT(DISTINCT
		|				ISNULL(
		|					CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).LineOfBusiness,
		|					VALUE(Catalog.LinesOfBusiness.EmptyRef))) = 1
		|			THEN
		|				MAX(ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).LineOfBusiness,
		|					VALUE(Catalog.LinesOfBusiness.EmptyRef)))
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusiness,
		|	CASE
		|		WHEN COUNT(DISTINCT
		|				ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).Partner,
		|					VALUE(Catalog.Partners.EmptyRef))) = 1
		|			THEN
		|				MAX(ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).Partner,
		|					VALUE(Catalog.Partners.EmptyRef)))
		|		ELSE VALUE(Catalog.Partners.EmptyRef)
		|	END AS Partner,
		|	CASE
		|		WHEN COUNT(DISTINCT
		|				ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).Contract,
		|					VALUE(Catalog.CounterpartyContracts.EmptyRef))) = 1
		|			THEN
		|				MAX(ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).Contract,
		|					VALUE(Catalog.CounterpartyContracts.EmptyRef)))
		|		ELSE VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|	END AS Contract,
		|	CASE
		|		WHEN COUNT(DISTINCT
		|				ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).Counterparty,
		|					VALUE(Catalog.Counterparties.EmptyRef))) = 1
		|			THEN
		|				MAX(ISNULL(CAST(GoodsTable.ControlledLotReference AS Catalog.ControlledLots).Counterparty,
		|					VALUE(Catalog.Counterparties.EmptyRef)))
		|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
		|	END AS Counterparty
		|INTO DocumentDataTableGoodsSummary
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|GROUP BY
		|	GoodsTable.Ref
		|INDEX BY
		|	Ref";
	
	If BatchMode Then
		QueryText = StrReplace(QueryText,
			"INTO DocumentDataTableGoodsSummary",
			"");
		QueryText = StrReplace(QueryText,
			"INDEX BY
			|	Ref",
			"");
		QueryText = StrReplace(QueryText,
			"DocumentDataTableItems",
			"Document.RequestForGoodsQualityControl.Goods");
		Return QueryText;
	EndIf;
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextDocumentDataGoodsTableCollapseProductLocations(Query, QueryTexts)
	
	TableName = "DocumentDataGoodsTableCollapseProductLocations";
	
	QueryText =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Series AS Series,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Premise AS Premise,
		|	Goods.QualityIsConfirmed AS QualityIsConfirmed,
		|	Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|	Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|	Goods.Count AS Count
		|INTO DocumentDataGoodsTableCollapseProductLocations
		|FROM
		|	DocumentDataTableItems AS Goods
		|WHERE
		|	ISNULL(CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType,
		|		UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|
		|UNION ALL
		|
		|SELECT
		|	Components.Ref AS Ref,
		|	Components.Products AS Products,
		|	Components.Characteristic AS Characteristic,
		|	Components.Purpose AS Purpose,
		|	Components.ControlledLotReference AS ControlledLotReference,
		|	Components.Series AS Series,
		|	Components.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Components.Warehouse AS Warehouse,
		|	Components.Premise AS Premise,
		|	Components.QualityIsConfirmed AS QualityIsConfirmed,
		|	Components.WarehouseUseOrderSchemeWhenReflectingSurplusShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|	Components.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|	MIN(Components.Count) AS Count
		|FROM(
		|	SELECT
		|		Goods.Ref AS Ref,
		|		Goods.Products AS Products,
		|		Goods.Characteristic AS Characteristic,
		|		Goods.Purpose AS Purpose,
		|		Goods.ControlledLotReference AS ControlledLotReference,
		|		Goods.Series AS Series,
		|		Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|		Goods.Warehouse AS Warehouse,
		|		Goods.Premise AS Premise,
		|		Goods.Package AS Package,
		|		Goods.QualityIsConfirmed AS QualityIsConfirmed,
		|		Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages AS WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|		Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected AS WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected,
		|		SUM(Goods.Count) AS Count
		|FROM
		|	DocumentDataTableItems AS Goods
		|WHERE
		|	CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).PackageType
		|		= VALUE(Enum.TypesOfItemsPackages.CargoItem)
		|	GROUP BY
		|		Goods.Ref,
		|		Goods.Products,
		|		Goods.Characteristic,
		|		Goods.Purpose,
		|		Goods.ControlledLotReference,
		|		Goods.Series,
		|		Goods.BatchesIndicationStatus,
		|		Goods.Warehouse,
		|		Goods.Premise,
		|		Goods.Package,
		|		Goods.QualityIsConfirmed,
		|		Goods.WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|		Goods.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected) AS Components
		|	GROUP BY
		|		Components.Ref,
		|		Components.Products,
		|		Components.Characteristic,
		|		Components.Purpose,
		|		Components.ControlledLotReference,
		|		Components.Series,
		|		Components.BatchesIndicationStatus,
		|		Components.Warehouse,
		|		Components.Premise,
		|		Components.QualityIsConfirmed,
		|		Components.WarehouseUseOrderSchemeWhenReflectingSurplusShortages,
		|		Components.WarehouseStartDateOfOrderSchemeWhenSurplusShortagesAreReflected
		|INDEX BY
		|	Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, BatchMode = False)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Date AS IBDocumentDate,
		|	DocumentData.Number AS IBDocumentNumber,
		|	&MetadataIdentifier AS RefType,
		|	DocumentData.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.GoodsQualityControl) AS BusinessOperation,
		|	GoodsSummaryTable.Partner AS Partner,
		|	GoodsSummaryTable.Counterparty AS Counterparty,
		|	GoodsSummaryTable.Contract AS Contract,
		|	GoodsSummaryTable.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.Warehouse AS StorageLocation,
		|	DocumentData.Department AS Department,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Author AS Author,
		|	DocumentData.Comment AS Comment,
		|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
		|	0 AS Sum,
		|	UNDEFINED AS Status,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	FALSE AS AdditionalRecord,
		|	"""" AS More,
		|	DocumentData.Date AS SourceDocumentDate,
		|	"""" AS SourceDocumentName,
		|	&NumberForPrinting AS SourceDocumentNumber,
		|	DocumentData.Date AS RecordingInAccountingDate,
		|	UNDEFINED AS Priority
		|FROM
		|	DocumentDataHeader AS DocumentData
		|		
		|		LEFT JOIN DocumentDataTableGoodsSummary AS GoodsSummaryTable
		|		ON GoodsSummaryTable.Ref = DocumentData.Ref";
	
	If BatchMode Then
		
		TextSummary = QueryTextDocumentDataTableGoodsSummary(Undefined, Undefined, True);
		QueryText = StrReplace(QueryText, "&NumberForPrinting", "DocumentData.Number");
		QueryText = StrReplace(QueryText, "DocumentData.Comment", "CAST(DocumentData.Comment AS STRING (100))");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.RequestForGoodsQualityControl");
		QueryText = StrReplace(QueryText, "DocumentDataTableGoodsSummary", StrTemplate("(%1)", TextSummary));
		Return QueryText;
		
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("DocumentDataTableGoodsSummary", QueryTexts) Then
		QueryTextDocumentDataTableGoodsSummary(Query, QueryTexts);
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.Count AS Count,
		|	Goods.Warehouse AS Sender,
		|	Goods.Premise AS WareroomOfSender,
		|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
		|	Goods.Ref AS Document,
		|	Attributes.Date AS Period
		|FROM
		|	DocumentDataTableItems AS Goods
		|		
		|		LEFT JOIN DocumentDataHeader AS Attributes
		|		ON Attributes.Ref = Goods.Ref
		|WHERE
		|	Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	If Not DocumentsPosting.ThereIsQueryTable("DocumentDataGoodsTableCollapseProductLocations", QueryTexts) Then
		QueryTextDocumentDataGoodsTableCollapseProductLocations(Query, QueryTexts);
	EndIf;
	
	QueryTextTabPart =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Attributes.Date AS Period,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	Goods.ControlledLotReference AS ControlledLotReference,
		|	Goods.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		
		|		LEFT JOIN DocumentDataHeader AS Attributes
		|		ON Attributes.Ref = Goods.Ref";
		
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Attributes.Date AS Period,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Purpose AS Purpose,
		|	CASE
		|		WHEN Goods.QualityIsConfirmed
		|			THEN VALUE(Catalog.ControlledLots.EmptyRef)
		|		ELSE Attributes.ControlledLotReference
		|	END AS ControlledLotReference,
		|	NOT Goods.QualityIsConfirmed AS ToControlQuality,
		|	Attributes.ToScheduleGoodsUnlock AS SubjectToUnlocking,
		|	Attributes.QualityConfirmationDate AS QualityConfirmationDate,
		|	Goods.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	DocumentDataGoodsTableCollapseProductLocations AS Goods
		|		
		|		LEFT JOIN DocumentDataHeader AS Attributes
		|		ON Attributes.Ref = Goods.Ref";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

Procedure ReflectByWarehouseSubsystem(Query, QueryTexts, Registers)
	
	RegisterName = "ProductStock";
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		QueryTextDocument_ =
			"SELECT
			|	Goods.Ref AS Ref,
			|	Header.Date AS Period,
			|	UNDEFINED AS OrderDocument,
			|	UNDEFINED AS TransportationJob,
			|	UNDEFINED AS Recipient,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Cell AS Cell,
			|	Goods.Premise AS Premise,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Purpose AS Purpose,
			|	Goods.ControlledLotReference AS ControlledLotReference,
			|	Goods.Package AS Package,
			|	Goods.Series AS Series,
			|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	Goods.Count AS Count,
			|	Goods.NumberOfPackages AS NumberOfPackages,
			|	VALUE(Enum.ActionsWithGoodsIssueNoteRows.Ship) AS Action,
			|	FALSE AS ForAssembly,
			|	FALSE AS AssemblyInProgress,
			|	FALSE AS Assembled,
			|	TRUE AS ToShip
			|FROM
			|	DocumentDataHeader AS Header
			|		INNER JOIN DocumentDataTableItems AS Goods
			|		ON Header.Ref = Goods.Ref";
			
		WarehousesServer.ShipGoodsFromWarehouse_(Query, QueryTexts, RegisterName, QueryTextDocument_, True);
		
	EndIf;
	
	RegisterName = "GoodsInStorageBins";
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		
		QueryTextDocument_ =
			"SELECT
			|	Goods.Ref AS Ref,
			|	Header.Date AS Date,
			|	Goods.Warehouse AS Warehouse,
			|	Goods.Cell AS Cell,
			|	Goods.Premise AS Premise,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Purpose AS Purpose,
			|	Goods.ControlledLotReference AS ControlledLotReference,
			|	Goods.Package AS Package,
			|	Goods.Series AS Series,
			|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
			|	-Goods.Count AS Count,
			|	-Goods.NumberOfPackages AS NumberOfPackages,
			|	TRUE AS RemainderChanges
			|FROM
			|	DocumentDataHeader AS Header
			|		INNER JOIN DocumentDataTableItems AS Goods
			|		ON Header.Ref = Goods.Ref";
		WarehousesServer.RegisterSurplusShortagesInWarehouse(Query, QueryTexts, RegisterName, QueryTextDocument_);
		
	EndIf;
	
	// Registration of goods with a new Lot reference.
	QueryTextDocument_ =
		"SELECT
		|	Goods.Ref AS Ref,
		|	Header.Date AS Date,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Cell AS Cell,
		|	Goods.Premise AS Premise,
		|	UNDEFINED AS Sender,
		|	UNDEFINED AS ReferenceOrder,
		|	UNDEFINED AS BusinessOperation,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Package AS Package,
		|	FALSE AS ThisIsAPackingList,
		|	Goods.Series AS Series,
		|	TRUE AS ToControlQuality,
		// It doesn't matter, since there are no Registered Records for items to be received.
		|	FALSE AS RecordOfAPreviouslyReceivedLot,
		|	CASE
		|		WHEN Goods.QualityIsConfirmed
		|			THEN VALUE(Catalog.ControlledLots.EmptyRef)
		|		ELSE Header.ControlledLotReference
		|	END AS ControlledLotReference,
		|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	Goods.Count AS Count,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	FALSE AS Accepts,
		|	TRUE AS Accepted,
		|	TRUE AS ThisIsAcceptanceWithoutOrder
		|FROM
		|	DocumentDataHeader AS Header
		|		INNER JOIN DocumentDataTableItems AS Goods
		|		ON Header.Ref = Goods.Ref";
		
	WarehousesServer.TakeGoodsToWarehouse(Query, QueryTexts, Registers, QueryTextDocument_, "Goods");
	
EndProcedure
Function QueryTextTableOfQualityControlRequests(Query, QueryTexts, Registers)
	
	RegisterName = "RequestStatesForQualityControl";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Ref AS Lot,
		|	DocumentData.ControlledLotReference AS ControlledLotReference
		|FROM
		|	DocumentDataHeader AS DocumentData";
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	FullDocumentName = "Document.RequestForGoodsQualityControl";
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName <> "DocumentsRegistry" Then
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
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, Undefined, "DocumentsRegistry", True);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

Function GoodsResearchIsIncluded()
	
	UseResearch = False;
	UseResearch = GetFunctionalOption("UseGoodsQualityResearch");
	Return UseResearch;
	
EndFunction

Function ToFormPrintedApplicationFormForQualityControlOfGoods(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	MetadataOfDocument = Documents.RequestForGoodsQualityControl.EmptyRef().Metadata();
	If Not ValueIsFilled(MetadataOfDocument.ObjectPresentation) Then
		DocumentSynonym = MetadataOfDocument.Synonym;
	Else
		DocumentSynonym = MetadataOfDocument.ObjectPresentation;
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_RequestForGoodsQualityControl_DocumentPrintForm";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	OutputBatches = GetFunctionalOption("UseItemsBatch");
	
	Query = New Query();
	Text =
		"SELECT
		|	Goods.Ref AS Ref,
		|	CASE
		|		WHEN MIN(Goods.Warehouse) = MAX(Goods.Warehouse)
		|			THEN MIN(Goods.Warehouse)
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	CASE
		|		WHEN MIN(Goods.Premise) = MAX(Goods.Premise)
		|			THEN MIN(Goods.Premise)
		|		ELSE VALUE(Catalog.Warerooms.EmptyRef)
		|	END AS Premise,
		|	CASE
		|		WHEN MIN(Goods.ControlledLotReference.Lot) = MAX(Goods.ControlledLotReference.Lot)
		|			THEN MIN(Goods.ControlledLotReference.Lot) 
		|		ELSE UNDEFINED
		|	END AS Lot
		|INTO GoodsInSummary
		|FROM
		|	Document.RequestForGoodsQualityControl.Goods AS Goods
		|WHERE
		|	Goods.Ref IN(&ObjectsArray)
		|GROUP BY
		|	Goods.Ref
		|INDEX BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Header.Ref AS Ref,
		|	Header.Date AS Date,
		|	Header.Number AS Number,
		|	PRESENTATION(Header.Organization) AS OrganizationPresentation,
		|	Header.EmployeeResponsible.Individual AS EmployeeResponsible,
		|	GoodsInSummary.Warehouse AS Warehouse,
		|	GoodsInSummary.Premise AS Premise,
		|	GoodsInSummary.Lot AS Lot,
		|	PRESENTATION(GoodsInSummary.Warehouse) AS WarehousePresentation,
		|	PRESENTATION(GoodsInSummary.Premise) AS PremisePresentation,
		|	PRESENTATION(GoodsInSummary.Lot) AS LotPresentation
		|FROM
		|	Document.RequestForGoodsQualityControl AS Header
		|		
		|		INNER JOIN GoodsInSummary AS GoodsInSummary
		|		ON GoodsInSummary.Ref = Header.Ref
		|WHERE
		|	Header.Ref IN(&ObjectsArray)
		|ORDER BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref AS Ref,
		|	MIN(Goods.LineNumber) AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Series AS Series,
		|	Goods.QualityIsConfirmed AS QualityIsConfirmed,
		|	Goods.Package AS Package,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|INTO ProductsGrouped
		|FROM
		|	Document.RequestForGoodsQualityControl.Goods AS Goods
		|WHERE
		|	Goods.Ref IN(&ObjectsArray)
		|GROUP BY
		|	Goods.Ref,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Package,
		|	Goods.QualityIsConfirmed
		|INDEX BY
		|	Products
		|;
		|
		|//////////////////////////////////////////////////////
		|SELECT
		|	Goods.Ref AS Ref,
		|	Goods.LineNumber AS LineNumber,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	&OutputCodes AS SKU,
		|	Goods.Products.DescriptionFull AS ProductPresentation,
		|	Goods.Characteristic.DescriptionFull AS CharacteristicPresentation,
		|	Goods.Series.Description AS BatchPresentation,
		|	PRESENTATION(Goods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
		|	CASE
		|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN REFPRESENTATION(Goods.Products.UnitOfMeasure)
		|		ELSE REFPRESENTATION(Goods.Package)
		|	END AS PresentationOfPackingUnit,
		|	Goods.QualityIsConfirmed AS QualityIsConfirmed
		|FROM
		|	ProductsGrouped AS Goods
		|WHERE
		|	Goods.Ref IN(&ObjectsArray)
		|ORDER BY
		|	Ref, LineNumber
		|TOTALS BY
		|	Ref";
	
	SubstitutionOutputCodes = ?(OutputCodes, "Goods.Products." + NameOfCodeColumn, """""");
	Text = StrReplace(Text, "&OutputCodes", SubstitutionOutputCodes);
	Query.Text = Text;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Results = Query.ExecuteBatch(); 
	
	SelectionByDocuments = Results[1].Select();
	SelectionByTableParts = Results[3].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	DocumentAttributes = New Structure("Number,Date,Prefix");
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While SelectionByDocuments.Next() Do
		
		If Not SelectionByTableParts.FindNext(New Structure("Ref", SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		ThereIs_Warehouse = ValueIsFilled(SelectionByDocuments.Warehouse);
		ThereIsLotReference = ValueIsFilled(SelectionByDocuments.Lot);
		
		// We get the layout in a loop, because the width of the columns depends on the warehouse and the room in the document.
		Template = PrintManagement.PrintFormTemplate("Document.RequestForGoodsQualityControl.PF_MXL_RequestForGoodsQualityControl");
		
		HeaderArea_ = Template.GetArea("Title");
		SignatureArea = Template.GetArea("Signatures");
		
		If ThereIs_Warehouse And ThereIsLotReference Then
			AreaNameHeader = "HeaderAndWarehouseAndLotReference";
		ElsIf ThereIs_Warehouse And Not ThereIsLotReference Then
			AreaNameHeader = "HatAndWarehouse";
		ElsIf ThereIsLotReference Then
			AreaNameHeader = "CapWithoutWarehouseAndLotReference";
		Else
			AreaNameHeader = "HatWithoutWarehouse";
		EndIf;
		SectionHeader = Template.GetArea(AreaNameHeader);
		
		TableArea = New Array();
		
		Header = Template.GetArea("TableHeader|BeginningOfTheLine");
		String = Template.GetArea("TableRow|BeginningOfTheLine");
		Footer = Template.GetArea("TableFooter|BeginningOfTheLine");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		HiddenWidth = 0;
		
		If OutputCodes Then
			
			Header = Template.GetArea("TableHeader|ColumnOfCodes");
			String = Template.GetArea("TableRow|ColumnOfCodes");
			Footer = Template.GetArea("TableFooter|ColumnOfCodes");
			
			TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
			Header.Parameters.NameOfCodeColumn = PresentationOfCodesColumn; 
			
		Else
			HiddenWidth = Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf;
		
		Header = Template.GetArea("TableHeader|OwnGoods");
		String = Template.GetArea("TableRow|OwnGoods");
		Footer = Template.GetArea("TableFooter|OwnGoods");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		Header = Template.GetArea("TableHeader|Count");
		String = Template.GetArea("TableRow|Count");
		Footer = Template.GetArea("TableFooter|Count");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		Template.Area("OwnGoods").ColumnWidth = Template.Area("OwnGoods").ColumnWidth + HiddenWidth;
		HiddenWidth = 0;
		
		Header = Template.GetArea("TableHeader|QualityIsConfirmed");
		String = Template.GetArea("TableRow|QualityIsConfirmed");
		Footer = Template.GetArea("TableFooter|QualityIsConfirmed");
		
		TableArea.Add(New Structure("Header,String,Footer", Header, String, Footer));
		
		TotalTableAreas = TableArea.Count() - 1;
		
		SamplingByTSLines = SelectionByTableParts.Select(QueryResultIteration.ByGroups);
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes,SelectionByDocuments);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym);
		HeaderDataStructure = New Structure();
		HeaderDataStructure.Insert("TitleText", TitleText);
		
		HeaderArea_.Parameters.Fill(HeaderDataStructure);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		SpreadsheetDocument.Put(HeaderArea_);
		
		SectionHeader.Parameters.Fill(SelectionByDocuments);
		
		If ThereIs_Warehouse Then
			
			SectionHeader.Parameters.WarehousePresentation = WarehousesServer.GetWarehousePresentation(
				SelectionByDocuments.WarehousePresentation,
				SelectionByDocuments.PremisePresentation);
				
		EndIf;
		
		SpreadsheetDocument.Put(SectionHeader);
		
		For AreaIndex = 0 To TotalTableAreas Do
			AreaDetails = TableArea[AreaIndex]; // Structure
			CurrentArea = AreaDetails.Header; // SpreadsheetDocument
			If AreaIndex = 0 Then
				SpreadsheetDocument.Put(CurrentArea);
			Else
				SpreadsheetDocument.Join(CurrentArea);
			EndIf;
		EndDo;
		
		While SamplingByTSLines.Next() Do
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				SamplingByTSLines.ProductPresentation,
				SamplingByTSLines.CharacteristicPresentation,
				, // Package
				SamplingByTSLines.BatchPresentation,
				AdditionalParametersProductPresentation);
			ParametersStructure = New Structure("OwnGoods", OwnGoods);
			
			For AreaIndex = 0 To TotalTableAreas Do
				AreaDetails = TableArea[AreaIndex]; // Structure
				CurrentArea = AreaDetails.String; // SpreadsheetDocument
				CurrentArea.Parameters.Fill(SamplingByTSLines);
				CurrentArea.Parameters.Fill(ParametersStructure);
				If AreaIndex = 0 Then
					SpreadsheetDocument.Put(CurrentArea);
				Else
					SpreadsheetDocument.Join(CurrentArea);
				EndIf;
			EndDo;
			
		EndDo;
		
		For AreaIndex = 0 To TotalTableAreas Do
			AreaDetails = TableArea[AreaIndex]; // Structure
			CurrentArea = AreaDetails.Footer; // SpreadsheetDocument
			If AreaIndex = 0 Then
				SpreadsheetDocument.Put(CurrentArea);
			Else
				SpreadsheetDocument.Join(CurrentArea);
			EndIf;
		EndDo;
		
		SignatureArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(
			SelectionByDocuments.EmployeeResponsible, SelectionByDocuments.Date);
		SpreadsheetDocument.Put(SignatureArea);
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndIf
