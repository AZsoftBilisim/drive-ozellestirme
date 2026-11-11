#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn đề nghị xuất nguyên vật liệu vào sản xuất';
		|ru = 'Заказ материалов в производство';
		|en = 'Material order for shop floor stockroom'; fa = 'سفارش مواد برای انبار کارگاه';
		|it = 'Ordine dei materiali nella produzione';
		|pl = 'Zamówienie materiałów do produkcji';
		|tr = 'Üretim için malzeme siparişi'",
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
		"Organization, Warehouse");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization, Warehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ProductionManagement2_2";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ProductionManagement2_2";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department, ShopFloorStockroom", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("DocumentsRegistry");
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
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.OrderOfMaterialsForProduction") Then
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
		
		QueryTextTableOrdersOfMaterialsForProduction(Query, QueryTexts, Registers);
		QueryTextTableOrdersOfMaterialsSubjectToAdjustments(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
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
	AcceptableStatuses.Add(Enums.StatusesOfOrdersForMaterialsForProduction.ForCompletion);
	AcceptableStatuses.Add(Enums.StatusesOfOrdersForMaterialsForProduction.Closed);
	
	Return AcceptableStatuses;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
// Parameters:
//  DocumentObject - DocumentObject.OrderOfMaterialsForProduction - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
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
	Links.Warehouse                 = "Object.Warehouse";
	Links.MultipleWarehouses      = Undefined;
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "OrdersOfMaterialsForProduction";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.OrderOfMaterialsForProduction";
	EmbeddingParameters.TableName = "Document.OrderOfMaterialsForProduction.Goods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	Attributes.Warehouse AS Warehouse,
		|	CASE WHEN TabPart.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|					OR Attributes.AssignByOrderAssignment
		|						AND TabPart.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own) THEN
		|				Attributes.Purpose
		|			ELSE
		|				TabPart.Purpose
		|		END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	TRUE AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion),
		|			VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed)
		|		) AS ReadyToShip,
		|	TabPart.ShipmentStart AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				UNDEFINED
		|		END AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.OrderOfMaterialsForProduction.Goods AS TabPart
		|		
		|		LEFT JOIN Document.OrderOfMaterialsForProduction AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
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
	Object.Insert("Department",                  New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("Warehouse",                          New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Purpose",                     New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("AssignByOrderAssignment", New TypeDescription("Boolean"));
	Object.Insert("Ref",                         New TypeDescription("DocumentRef.OrderOfMaterialsForProduction"));
	Object.Insert("Status",                         New TypeDescription("EnumRef.StatusesOfOrdersForMaterialsForProduction"));
	Object.Insert("Date",                           New TypeDescription("Date"));
	Object.Insert("Priority",                      New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("NotShipInInstallments",             New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",                   New TypeDescription("Date"));
	Object.Insert("Goods",                         Goods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	EmbeddingParameters.ExpressionForQuestionWhenPerformingActionInOrderList =
		"CASE WHEN NOT Table.ProductionManagement2_2 AND Table.NotShipInInstallments THEN
		|			Table.DateOfShipment
		|		ELSE
		|			UNDEFINED
		|	END";
	
	Return EmbeddingParameters;
	
EndFunction

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//  String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse, Date";
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.OrderOfMaterialsForProduction";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.TransferToProductionShipment);
	
	SeriesSpecificationParameters.ThisIsOrder = True;
	SeriesSpecificationParameters.ShipmentPlanning = True;
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.Date = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
// 
// Parameters:
// 	FieldValuesToIdentifyReferences - Structure - structure with keys:
//  *Ref - DocumentRef.OrderOfMaterialsForProduction - order.
// Returns:
// 	DocumentRef.OrderOfMaterialsForProduction - Link to the order.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	Return FieldValuesToIdentifyReferences.Ref;
	
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
	|	Goods.Products AS Products,
	|	Goods.Series,
	|	Goods.Canceled,
	|	Goods.SupplyOption,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|				OR NOT Goods.SupplyOption IN (
	|						VALUE(Enum.SupplyOptions.FromWarehouse),
	|						VALUE(Enum.SupplyOptions.Ship))
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
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
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
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
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.TransferOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	DataProcessors.GenerationOfTransferToProductionOrdersByReference.AddGenerateCommand(GenerationCommands);
	
	
	CommandToPantry = Documents.MovementOfProductsAndMaterials.AddCommandCreateTransferToPantryBasedOnOrder(GenerationCommands);
	
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds a command to create an object based on.
// 
// Parameters:
// 	GenerationCommands - ValueTable - list of commands
// Returns:
// 	Undefined, ValueTableRow - added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.OrderOfMaterialsForProduction) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.OrderOfMaterialsForProduction.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.OrderOfMaterialsForProduction);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction";

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
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
EndProcedure

// Determines whether the user has rights to add a document.
//
// Returns:
//  Boolean - True if there is a right to add.
//
Function AccessRightInsert() Export
	
	Return AccessRight("Insert", Metadata.Documents.OrderOfMaterialsForProduction);
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

// Creates a structure for creating internal consumption for one or more internal consumption orders.
//
// Parameters:
//  ReferencesArrray		 - Array	 - internal consumption orders for which you need to enter the internal consumption of goods.
//  WarningText	 - String	 - the line where the message explaining why the document can't be processed will be placed.
//
// Returns:
//  Structure - the structure where the header details from the order array will be placed.
//
Function DesignParametersForTransferOfMaterialsToProduction(ReferencesArrray, WarningText) Export
	
	Query = New Query(
	"SELECT
	|	MIN(OrderDocument.Organization)                        AS Organization,
	|	MIN(OrderDocument.Warehouse)                              AS Warehouse,
	|	MIN(OrderDocument.Department)                      AS Department,
	|	COUNT(DISTINCT OrderDocument.Organization)           AS VariousOrganizations_,
	|	COUNT(DISTINCT OrderDocument.Warehouse)                 AS VariousWarehouses,
	|	COUNT(DISTINCT OrderDocument.Department)         AS VariousDivisions
	|FROM
	|	Document.OrderOfMaterialsForProduction AS OrderDocument
	|WHERE
	|	OrderDocument.Ref IN(&ReferencesArrray)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderDocument.Ref AS OrderDocument,
	|	OrderDocument.Status AS Status,
	|	(NOT OrderDocument.Posted) AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN OrderDocument.Status = VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed)
	|				OR OrderDocument.Status = VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus
	|FROM
	|	Document.OrderOfMaterialsForProduction AS OrderDocument
	|WHERE
	|	OrderDocument.Ref IN(&ReferencesArrray)
	|	AND ((NOT OrderDocument.Posted)
	|			OR OrderDocument.Status <> VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion)
	|				AND OrderDocument.Status <> VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed))");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	QueryResult = Query.ExecuteBatch();
	SelectionHeaderDetails = QueryResult[0].Select();
	SelectionHeaderDetails.Next();
	
	Cancel = False;
	
	MessageTemplate = NStr("vi = 'Các đơn hàng được chọn có một trường khác: ""%FieldPresentation%""';
							|ru = 'У выделенных заказов отличается поле ""%FieldPresentation%""';
							|en = 'The ""%FieldPresentation%"" field differs in the selected orders'; fa = 'The ""%FieldPresentation%"" field differs in the selected orders';
							|it = 'Gli ordini selezionati hanno il campo diverso ""%FieldPresentation%""';
							|pl = 'U wybranych zamówień różni się pole ""%FieldPresentation%""';
							|tr = 'Belirtilen siparişlerin ""%FieldPresentation%"" alanı farklı'");
	MessageText = "";
	
	If SelectionHeaderDetails.VariousOrganizations_ > 1 Then
		MessageText = MessageText
							+ ?(MessageText = "", "", Chars.LF)
							+ StrReplace(MessageTemplate, "%FieldPresentation%", NStr("vi = '""Doanh nghiệp""';
																						|ru = '""Организация""';
																						|en = '""Company""'; fa = '""Company""';
																						|it = '""Организация""';
																						|pl = '""Company""';
																						|tr = '""İş yeri""'"));
		
		Cancel = True;
	EndIf;
	
	If SelectionHeaderDetails.VariousWarehouses > 1 Then
		MessageText = MessageText
							+ ?(MessageText = "", "", Chars.LF)
							+ StrReplace(MessageTemplate, "%FieldPresentation%", NStr("vi = '""Kho bãi""';
																						|ru = '""Склад""';
																						|en = '""Warehouse""'; fa = '""Warehouse""';
																						|it = '""Склад""';
																						|pl = '""Warehouse""';
																						|tr = '""Ambar""'"));
		
		Cancel = True;
	EndIf;
	
	If SelectionHeaderDetails.VariousDivisions > 1 Then
		MessageText = MessageText
							+ ?(MessageText = "", "", Chars.LF)
							+ StrReplace(MessageTemplate, "%FieldPresentation%", NStr("vi = '""Bộ phận""';
																						|ru = '""Подразделение""';
																						|en = '""Business unit""'; fa = '""Business unit""';
																						|it = '""Подразделение""';
																						|pl = '""Business unit""';
																						|tr = '""Departman""'"));
		
		Cancel = True;
	EndIf;
	
	If Not QueryResult[1].IsEmpty() Then
		
		SampleOrders = QueryResult[1].Select();
		
		While SampleOrders.Next() Do
			
			If SampleOrders.ThereAreErrorsPosted Then
				
				ErrorText = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Lập trên cơ sở bị cấm.';
								|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
								|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
								|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
								|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
								|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belge temelinde giriş yasaktır.'");
				ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.OrderDocument);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					,
					,
					Cancel);
				
			ElsIf SampleOrders.ThereAreErrorsStatus Then
				
				ErrorText = NStr("vi = 'Chứng từ %Document% đang ở trạng thái ""%Status%"". Chỉ cho phép nhập trên cơ sở chứng từ ở các trạng thái ""Chờ thực hiện"", ""Đã đóng"".';
								|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен только в статусах ""К выполнению"", ""Закрыт"".';
								|en = 'Document %Document% is in the ""%Status%"" status.  Generation is only allowed from base documents in ""Released"" or ""Closed"" statuses.'; fa = 'Document %Document% is in the ""%Status%"" status.  Generation is only allowed from base documents in ""Released"" or ""Closed"" statuses.';
								|it = 'Il documento %Document% è nello stato ""%Status%"". Immissione in base alla causale è consentita solo negli stati ""Da eseguire"", ""Chiuso"".';
								|pl = 'Dokument %Document% znajduje się w statusie ""%Status%"". Wprowadzenie na podstawie jest dozwolone tylko w statusach ""К выполнению"", ""Закрыт"".';
								|tr = '%Document% belgesi ""%Status%"" durumunda bulunmaktadır. Temel alınan girişe sadece ""Gerçekleştirmeye hazır"", ""Kapalı"" durumlarında izin verilmektedir.'");
				ErrorText = StrReplace(ErrorText, "%Document%", SampleOrders.OrderDocument);
				ErrorText = StrReplace(ErrorText, "%Status%",   SampleOrders.Status);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					,
					,
					,
					Cancel);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Cancel Then
		
		WarningText = NStr("vi = 'Không thể hoàn tBiên bảnệc chuyển giao vật liệu dựa trên các đơn đặt hàng đã chọn.';
							|ru = 'Невозможно оформить передачу материалов на основании выбранных заказов.';
							|en = 'Cannot register material transfer based on the selected orders.'; fa = 'Cannot register material transfer based on the selected orders.';
							|it = 'Impossibile formalizzare la consegna dei materiali in base agli ordini selezionati.';
							|pl = 'Niemożliwe jest zarejestrowanie przekazania materiałów na podstawie wybranych zamówień.';
							|tr = 'Seçili siparişler temelinde malzeme transferini düzenlemeniz mümkün değildir.'")
								+ Chars.LF + MessageText;
		
		Return Undefined;
		
	EndIf;
	
	DesignParameters = New Structure;
	DesignParameters.Insert("Organization",           SelectionHeaderDetails.Organization);
	DesignParameters.Insert("Warehouse",                 SelectionHeaderDetails.Warehouse);
	DesignParameters.Insert("Department",         SelectionHeaderDetails.Department);
	
	Return DesignParameters;
	
EndFunction

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
	
	MeaningOfNewStatus = Enums.StatusesOfOrdersForMaterialsForProduction[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl")  Then
		
		QueryText =
		"SELECT
		|	Balance.ReferenceOrder AS ReferenceOrder
		|INTO
		|	TTOrderBalances_
		|FROM
		|	AccumulationRegister.OrdersOfMaterialsForProduction.Balance(, ReferenceOrder IN (&DocumentsArray)) AS Balance
		|GROUP BY
		|	Balance.ReferenceOrder
		|;
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
		|	CASE
		|		WHEN TTOrderBalances_.ReferenceOrder IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.OrderOfMaterialsForProduction AS DocumentsTable
		|LEFT JOIN
		|	TTOrderBalances_
		|ON
		|	DocumentsTable.Ref = TTOrderBalances_.ReferenceOrder
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
	
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
		|	Document.OrderOfMaterialsForProduction AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN (&DocumentsArray)
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
// 	ValidationSample - QueryResultSelection - Current selection string
// 	NewStatus - EnumRef.StatusesOfOrdersForMaterialsForProduction - New status
// 	AdditionalParameters - Structure - Structure of additional parameters.
// Returns:
// 	Boolean - flag.
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
						|tr = 'Sipariş tümüyle gerçekleştirilmediğinden dolayı %Document% belgenin ""%Status%"" durumu ayarlanmadı'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//	Structure - The structure of the report parameters.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("OutputTablesSupply", 1);
	StructureState.Insert("DisplayShipmentTables", 2);
	StructureState.Insert("DisplayTablesCanceledShipment", 3);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("WarehouseInHeader", True);
	StructureState.Insert("TextProductServiceShipment", NStr("vi = 'Nguyên vật liệu';
															|ru = 'Материал';
															|en = 'Material'; fa = 'ماده';
															|it = 'Materiale';
															|pl = 'Material';
															|tr = 'Malzeme'"));
	
	StructureState.Insert("FieldNameShipmentDate", "ShipmentStart");
	
	Return StructureState
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

Function VerificationOfGroundsForTransferOfMaterials(AnArrayOfOrders, ProductionManagement2_2) Export
	
	CheckResult = New Structure("HasErrors, ErrorText", False);
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	OrderOfMaterialsForProduction.Ref AS Ref
	|FROM
	|	Document.OrderOfMaterialsForProduction AS OrderOfMaterialsForProduction
	|WHERE
	|	OrderOfMaterialsForProduction.Ref IN(&ReferencesArrray)
	|	AND OrderOfMaterialsForProduction.ProductionManagement2_2 = &ProductionManagement2_2";
	
	Query.SetParameter("ReferencesArrray", AnArrayOfOrders);
	Query.SetParameter("ProductionManagement2_2", ProductionManagement2_2);
	
	ObjectsOfBases = Query.Execute().Unload().UnloadColumn("Ref");
	
	If ObjectsOfBases.Count() = 0 Then
		
		CheckResult.HasErrors = True;
		
		If AnArrayOfOrders.Count() = 1 Then
			CheckResult.ErrorText = NStr("vi = 'Lệnh không thể được thực thi cho chứng từ này.';
										|ru = 'Команда не может быть выполнена для данного документа';
										|en = 'Unable to execute the command for this document'; fa = 'Unable to execute the command for this document';
										|it = 'Il comando non può essere eseguito per questo documento';
										|pl = 'Nie można wykonać polecenia dla danego dokumentu.';
										|tr = 'Mevcut belge için komut gerçekleştirilemez'");
		Else
			CheckResult.ErrorText = NStr("vi = 'Lệnh không thể được thực thi cho các chứng từ được chọn';
										|ru = 'Команда не может быть выполнена для выбранных документов';
										|en = 'Command cannot be executed for the selected documents'; fa = 'Command cannot be executed for the selected documents';
										|it = 'Il comando non può essere eseguito per documenti selezionati';
										|pl = 'Nie można wykonać polecenia dla wybranych dokumentów.';
										|tr = 'Seçili belgeler için komut gerçekleştirilemez'");
		EndIf;
		
	EndIf;

	Return New Structure("ObjectsOfBases, CheckResult", ObjectsOfBases, CheckResult);
	
EndFunction

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.OrderOfMaterialsForProduction, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Date								= Object.Date;
	FillParameters.Organization							= Object.Organization;
	FillParameters.Warehouse								= Object.ShopFloorStockroom;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.MovementOfGoodsInWarehouses			= True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region QualityControl

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.OrderOfMaterialsForProduction, DocumentRef.OrderOfMaterialsForProduction - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
//
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Ref,
		|Date,
		|Number,
		|Sender,
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
	If Attributes.BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
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
//  Object - DocumentObject.OrderOfMaterialsForProduction - Object.
// 
// Returns:
//  Structure - structure with fields:
// * Key - String - An identifier used when there are two or more data sources to fill in in the same object.
// * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.FullObjectName = "Document.OrderOfMaterialsForProduction";
	ActionParameters.ReadableFields = "Products,ShipmentStart,ReceiptEnd,Canceled";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	
	ActionParameters.QueryOptions.Insert("WarehouseQualityControl", Object.ShopFloorStockroom);
	ActionParameters.QueryOptions.Insert("QualityControlUseDurationOfMove", Object.UseTransferDuration);
	
	ActionParameters.KeyDetailsOfHeader.Insert("TransferDurationDays",    Object.TransferDurationDays);
	ActionParameters.KeyDetailsOfHeader.Insert("ProductionManagement2_2", Object.ProductionManagement2_2);
	
	ActionParameters.QueryTextDocumentData =
	"SELECT
	|	Table.IdOfTTRow AS IdOfTTRow,
	|	Table.Products AS Products,
	|	&WarehouseQualityControl AS Warehouse,
	|	UNDEFINED AS Contract,
	|	CASE
	|		WHEN &QualityControlUseDurationOfMove THEN
	|			Table.ReceiptEnd
	|		ELSE Table.ShipmentStart
	|	END AS DateOfReceipt,
	|	FALSE AS Set,
	|	Table.Canceled AS Reset
	|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
	|FROM
	|	#DataSource AS Table
	|INDEX BY
	|	Products,
	|	Warehouse,
	|	Contract
	|";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(Warehouse)";

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

Function QueryTextDocumentGoods(Filter) Export
	
	QueryText =
	"SELECT
	|	Table.Ref                           AS ReferenceOrder,
	|	Table.Products                     AS Products,
	|	Table.Characteristic                   AS Characteristic,
	|	DataOfAccounting.Purpose                   AS Purpose,
	|	DataOfAccounting.AssignmentSender        AS AssignmentSender,
	|	Table.RowCode                        AS RowCode,
	|	Table.Series                            AS Series,
	|	Table.Count                       AS Count,
	|	Table.Package                         AS Package,
	|	Table.ShipmentStart                   AS DateOfShipment,
	|	Table.Canceled                         AS Canceled,
	|	Table.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	Table.SupplyOption               AS SupplyOption,
	|	Table.WithAssignment                      AS WithAssignment,
	|	Table.ProductsGroup                  AS ProductsGroup,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	ISNULL(DataOfAccounting.ToRegister, 0)     AS ToRegister,
	|	ISNULL(DataOfAccounting.Ordered, 0)        AS Ordered
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS Table
	|	
	|	LEFT JOIN TTAccountingData AS DataOfAccounting
	|	ON Table.Ref = DataOfAccounting.ReferenceOrder
	|		AND Table.RowCode = DataOfAccounting.RowCode
	|	
	|WHERE
	|	NOT DataOfAccounting.ReferenceOrder IS NULL
	|	AND &Filter";
	
	TextSourceTable = "Document.OrderOfMaterialsForProduction.Goods AS Table";
	TextIsCompoundPieceOfGoodsInMeasuringUnit = TextSourceTable + "
	|	//&CompoundUnitGoodsInUnitOfMeasure";
	
	QueryText = StrReplace(QueryText, TextSourceTable, TextIsCompoundPieceOfGoodsInMeasuringUnit);
	
	ApplyingParameters = ProductionServer.ParametersOfApplicationOfPieceProductInDimensionalUnit();
	ApplyingParameters.NumberOfPackages = False;
	ApplyingParameters.UnitGoodsInUnitsOfMeasure = False;
	
	ProductionServer.ApplyUnitItemSettingsInUnitOfMeasure(QueryText, "Table", ApplyingParameters);
	
	FilterText1 = "TRUE";
	
	If ValueIsFilled(Filter) Then
		For Each KeyValue In Filter Do
			
			Var_Key = KeyValue.Key;
			
			If Var_Key = "Ref" Then
				Var_Key = "Table.Ref";
			EndIf;
			
			FilterText1 = FilterText1 + " And " + Var_Key + " IN(&" + KeyValue.Value + ")";
			
		EndDo;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&Filter", FilterText1);
	
	Return QueryText;
	
EndFunction

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.OrderOfMaterialsForProduction - the document for which you need to get the goods
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
		|	Goods.Ref.Warehouse AS Warehouse,
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
		|	Document.OrderOfMaterialsForProduction.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	
	Query.Execute();
	
EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterials22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterialsForStage22));
	DestinationPattern.TermsOfUse_ = "Object.ProductionManagement2_2 = FALSE";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.TermsOfUse_ = "Object.ProductionManagement2_2";
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	DestinationPattern.VisibleSelectionsOnForm.Insert("LineOfBusiness", NStr("vi = 'Chỉ đến ""%1""';
																			|ru = 'Только назначения направления деятельности ""%1""';
																			|en = 'The ""%1"" line of business assignments only'; fa = 'The ""%1"" line of business assignments only';
																			|it = 'Solo assegnazioni del settore di attività ""%1""';
																			|pl = 'Tylko przeznaczenia rodzaju działalności ""%1""';
																			|tr = 'Sadece ""%1"" iş kolunun atamaları'"));
	
	// Remnants of goods in the sender warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Sender");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.Columns.FindByValue("AvailableForReservation").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	
	// The needs for goods in the workshop pantry.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose", "Recipient");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ProductionManagement2_2";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.ShopFloorStockroom";
	
	// Needs for goods in the receiving warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.Goods.Purpose", "AllWarehouses");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ProductionManagement2_2";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
EndFunction

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.OrderOfMaterialsForProduction - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	If Object.ProductionManagement2_2 Then
	
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
					String.ShipmentStart = DateOfReceiptCalculated - 86400 * Object.TransferDurationDays;
					String.ReceiptEnd = DateOfReceiptCalculated;
					RowsToProcess.Add(String);
				EndIf;
				
			EndDo;
			
			CacheQualityControl = QualityControl.DataCacheOfMechanism(Object);
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.ProcessTSStrings(RowsToProcess, StructureOfActions, Object.Goods, Undefined);
			
		EndIf;
		
	Else
		
		ProvisionInDocumentsServer.UpdateShipmentDate(
			FillParameters,
			Object.NotShipInInstallments,
			Object.DateOfShipment,
			Object.Goods,
			"ShipmentStart");
		
		If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
			
			ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
				Changes.UnloadColumn("String"),
				"ShipmentStart",
				Object.NotShipInInstallments,
				Object.DateOfShipment);
				
		EndIf;
		
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.Goods);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// Returns:
// 	Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#EndRegion

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts                = New ValueList;
	FullDocumentName           = "Document.OrderOfMaterialsForProduction";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",             """""");
	RedefiningParameterCalculation.Insert("WarehouseInformation",        """""");
	RedefiningParameterCalculation.Insert("DivisionInformation", """""");
	RedefiningParameterCalculation.Insert("Recipient",
		"	CASE
		|		WHEN GoodsTable.Ref.ProductionManagement2_2
		|			THEN GoodsTable.Ref.ShopFloorStockroom
		|		ELSE GoodsTable.Ref.Department
		|	END");
	
	If RegisterName = "OrdersOfMaterialsSubjectToAdjustments" Then
		
		QueryText = QueryTextTableOrdersOfMaterialsSubjectToAdjustments(Undefined, QueryTexts, Undefined);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "OrdersOfMaterialsForProduction" Then
		
		QueryText = QueryTextTableOrdersOfMaterialsForProduction(Undefined, QueryTexts, Undefined);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, QueryTexts, Undefined);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Undefined, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
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

Function QueryTextTableOrdersOfMaterialsForProduction(Query, QueryTexts, Registers)

	RegisterName = "OrdersOfMaterialsForProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&Period                                  AS Period,
	|	&Ref                                  AS ReferenceOrder,
	|	&Warehouse                                   AS Warehouse,
	|	&Department                           AS Department,
	|	&Recipient                              AS Recipient,
	|	GoodsTable.Products               AS Products,
	|	GoodsTable.Characteristic             AS Characteristic,
	|	GoodsTable.Series                      AS Series,
	|
	|	GoodsTable.Purpose                 AS Purpose,
	|
	|	CASE
	|		WHEN NOT GoodsTable.WithAssignment
	|				THEN VALUE(Catalog.Assignments.EmptyRef)
	|		WHEN GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|					OR &AssignByOrderAssignment
	|						AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own)
	|			THEN &Purpose
	|		ELSE
	|			GoodsTable.Purpose
	|	END AS AssignmentSender,
	|
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Count AS Ordered,
	|	CASE
	|		WHEN GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			AND &Status IN (VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion),
	|							VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed))
	|			THEN GoodsTable.Count
	|	END AS ToRegister
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND (NOT GoodsTable.Canceled)";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableOrdersOfMaterialsSubjectToAdjustments(Query, QueryTexts, Registers)

	RegisterName = "OrdersOfMaterialsSubjectToAdjustments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber                   AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY)                AS Period,
	|	&Organization                                AS Organization,
	|	&Department                              AS Department,
	|	&Ref                                     AS ReferenceOrder,
	|	GoodsTable.RowCode                     AS ReferenceRowCode,
	|	GoodsTable.SupplyOption            AS SupplyOption,
	|	GoodsTable.WithAssignment                   AS WithAssignment,
	|	GoodsTable.ShipmentStart                AS DemandDate,
	|	GoodsTable.RowCode                     AS RowCode,
	|	GoodsTable.Canceled                      AS Canceled,
	|	GoodsTable.Series                         AS Series,
	|	&Warehouse                                      AS Warehouse,
	|	GoodsTable.Package                      AS Package,
	|	GoodsTable.Products                  AS Products,
	|	GoodsTable.Characteristic                AS Characteristic,
	|	CASE WHEN GoodsTable.WithAssignment
	|				AND (GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|					OR (&AssignByOrderAssignment
	|						AND GoodsTable.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))) THEN
	|			&Purpose
	|		ELSE
	|			GoodsTable.Purpose
	|	END                                       AS Purpose,
	|	GoodsTable.Count                    AS Count,
	|	GoodsTable.NumberOfPackages            AS NumberOfPackages
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT &ProductionManagement2_2
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	HeaderData_.Date AS Period,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Warehouse AS Warehouse,
	|	HeaderData_.ShopFloorStockroom AS ShopFloorStockroom,
	|	HeaderData_.Department AS Department,
	|	HeaderData_.Priority AS Priority,
	|	PRESENTATION(HeaderData_.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(HeaderData_.Department) AS DepartmentPresentation,
	|	CASE
	|		WHEN HeaderData_.ProductionManagement2_2
	|			THEN HeaderData_.ShopFloorStockroom
	|		ELSE HeaderData_.Department
	|	END AS Recipient,
	|	HeaderData_.Status AS Status,
	|	HeaderData_.Purpose AS Purpose,
	|	HeaderData_.ProductionManagement2_2 AS ProductionManagement2_2,
	|	ISNULL(HeaderData_.Purpose.RecordsInWarehouseRegisters, FALSE) AS RecordsInWarehouseRegisters,
	|	HeaderData_.AssignByOrderAssignment AS AssignByOrderAssignment,
	|	HeaderData_.EmployeeResponsible AS EmployeeResponsible,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.Number AS Number
	|FROM
	|	Document.OrderOfMaterialsForProduction AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	DivisionInformation = "";
	If ValueIsFilled(Attributes.Department) Then
		StringPattern = "vi = 'Chuyển giao vào ""%1""';
						|ru = 'Передача в ""%1""';
						|en = 'Transfer to ""%1""';
						|it = 'Trasferimento a ""%1""';
						|pl = 'Przeniesienie do ""%1""';
						|tr = '""%1"" içine transfer'"; // @NStr
		DivisionInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.DepartmentPresentation);
	EndIf;
	Query.SetParameter("DivisionInformation", DivisionInformation);
	
	WarehouseInformation = "";
	If ValueIsFilled(Attributes.Warehouse) Then
		StringPattern = "vi = 'Chuyển giao từ ""%1""';
						|ru = 'Передача с ""%1""';
						|en = 'Transfer from ""%1""';
						|it = 'Trasferimento da ""%1""';
						|pl = 'Przeniesienie z ""%1""';
						|tr = '""%1"" üzerinden transfer'"; // @NStr
		WarehouseInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.WarehousePresentation);
	EndIf;
	Query.SetParameter("WarehouseInformation", WarehouseInformation);
		
EndProcedure

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref				AS Ref,
	|	CASE WHEN SourceData.ShipmentStart <> DATETIME(1, 1, 1) THEN
	|				SourceData.ShipmentStart
	|			ELSE
	|				SourceData.Ref.Date
	|		END                           AS Period,
	|	SourceData.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	CASE
	|		WHEN SourceData.Ref.ProductionManagement2_2
	|			THEN SourceData.Ref.ShopFloorStockroom
	|		ELSE SourceData.Ref.Department
	|	END								AS Recipient,
	|	SourceData.Ref.Warehouse		AS Warehouse,
	|	SourceData.Products		AS Products,
	|	SourceData.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN SourceData.WithAssignment
	|			THEN CASE
	|					WHEN SourceData.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|							OR (SourceData.Ref.AssignByOrderAssignment
	|								AND SourceData.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))
	|						THEN SourceData.Ref.Purpose
	|					ELSE SourceData.Purpose
	|				END
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series				AS Series,
	|	SourceData.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	SourceData.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	SourceData.RowCode			AS RowCode,
	|	SourceData.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS SourceData
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND SourceData.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|														VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT SourceData.Canceled
	|	AND SourceData.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
		
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	SourceData.Ref				AS Ref,
	|	SourceData.ShipmentStart		AS Period,
	|	SourceData.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	CASE
	|		WHEN SourceData.Ref.ProductionManagement2_2
	|			THEN SourceData.Ref.ShopFloorStockroom
	|		ELSE SourceData.Ref.Department
	|	END								AS Recipient,
	|	SourceData.Ref.Warehouse		AS Warehouse,
	|	SourceData.Products		AS Products,
	|	SourceData.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN SourceData.WithAssignment
	|			THEN CASE
	|					WHEN SourceData.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|							OR (SourceData.Ref.AssignByOrderAssignment
	|								AND SourceData.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.Own))
	|						THEN SourceData.Ref.Purpose
	|					ELSE SourceData.Purpose
	|				END
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	SourceData.Series				AS Series,
	|	SourceData.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	SourceData.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	SourceData.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS SourceData
	|
	|WHERE
	|	SourceData.Ref IN(&Ref)
	|	AND SourceData.Ref.Status IN (VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion),
	|										VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed))
	|	AND SourceData.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

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

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref						AS Ref,
	|	UNDEFINED								AS Invoice,
	|	FALSE										AS Patch,
	|	UNDEFINED								AS CorrectedDocument,
	|	DataSource.Ref						AS OrderDocument,
	|	UNDEFINED								AS Contract,
	|	UNDEFINED								AS Terms,
	|	UNDEFINED								AS GoodsReceiptOption,
	|	DataSource.ReceiptEnd			AS Date,
	|	DataSource.Products					AS Products,
	|	DataSource.Characteristic				AS Characteristic,
	|	DataSource.Purpose					AS Purpose,
	|	DataSource.ToControlQuality    AS ToControlQuality,
	|	FALSE                                        AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                AS ControlledLotReference,
	|	DataSource.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	DataSource.Series						AS Series,
	|	FALSE										AS ExceedingOrder,
	|	DataSource.Ref.ShopFloorStockroom		AS Warehouse,
	|	DataSource.Ref.Warehouse					AS Sender,
	|	DataSource.Ref.BusinessOperation	AS BusinessOperation,
	|	DataSource.Count					AS Count,
	|	FALSE										AS ThisIsAnInvoice,
	|	FALSE										AS ReceiptUnderOrders
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)
	|	AND DataSource.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		 VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT DataSource.Canceled
	|	AND DataSource.Ref.Status IN (
	|		VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion),
	|		VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed))
	|	AND DataSource.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DataSource.Ref.ProductionManagement2_2";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
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
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.OrderOfMaterialsForProduction.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion),
		|			VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
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
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.ShipmentStart AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.OrderOfMaterialsForProduction.Goods AS TabPart
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
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.ShopFloorStockroom AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.ReceiptEnd AS DateOfReceipt,
		|	TabPart.ReceiptEnd
		|		<> DATETIME(1, 1, 1) AS AvailableForConsumption,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.OrderOfMaterialsForProduction.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.ProductionManagement2_2
		|		AND NOT TabPart.Canceled";
	
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
	|		&Warehouse                                        AS StorageLocation,
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
	|		CAST(&DivisionInformation AS STRING (100)) AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&LineOfBusiness                      AS LineOfBusiness
	|	FROM
	|		Document.OrderOfMaterialsForProduction AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	GROUP BY
	|		DocumentData.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref                        AS Ref,
	|		&Period                                       AS IBDocumentDate,
	|		&Number                                        AS IBDocumentNumber,
	|		&MetadataIdentifier                      AS RefType,
	|		&Priority                                    AS Priority,
	|		&Organization                                  AS Organization,
	|		&BusinessOperation                        AS BusinessOperation,
	|		VALUE(Catalog.Partners.EmptyRef)    AS Partner,
	|		VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|		&ShopFloorStockroom                              AS StorageLocation,
	|		ISNULL(
	|			CAST(&ShopFloorStockroom AS Catalog.Warehouses).Department,
	|			VALUE(Catalog.BusinessStructure.EmptyRef)) AS Department,
	|		&EmployeeResponsible                                AS EmployeeResponsible,
	|		&Author                                        AS Author,
	|		CAST(&Comment AS STRING (100))       AS Comment,
	|		VALUE(Catalog.Currencies.EmptyRef)      AS Currency,
	|		0                                             AS Sum,
	|		&Status                                       AS Status,
	|		&Posted                                     AS Posted,
	|		&DeletionMark                              AS DeletionMark,
	|		TRUE                                        AS AdditionalRecord,
	|		CAST(&WarehouseInformation AS STRING (100)) AS More,
	|		&Period                                       AS SourceDocumentDate,
	|		&NumberForPrinting                                AS SourceDocumentNumber,
	|		&LineOfBusiness                      AS LineOfBusiness
	|	FROM
	|		Document.OrderOfMaterialsForProduction AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
	|	
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

#Region Other

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
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.OrderOfMaterialsForProduction") Then
		ReferenceArray = New Array();
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	GoodsToReceive.ReferenceOrder   AS OrderDocument,
		|	GoodsToReceive.Products   AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Series          AS Series,
		|	SUM(GoodsToReceive.ToRegisterReceipt
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	AccumulationRegister.OrdersOfMaterialsForProduction.Turnovers(&StartPeriod_,&ConPeriod,,
		|		ReferenceOrder IN (&ReferenceArray)) AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	GoodsToReceive.ReferenceOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Series");
	
	Query.SetParameter("ReferenceArray", ReferenceArray);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("OrdersOfMaterialsForProduction",
		"ReferenceOrder IN (&ReferenceArray)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInProductionLog

Function ThereAreOrdersInProgress(Parameters)
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	OrderOfMaterials.Ref AS Ref
		|FROM
		|	Document.OrderOfMaterialsForProduction AS OrderOfMaterials
		|WHERE
		|	OrderOfMaterials.Status <> VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.Closed)
		|	AND &FilterCriterion");
	
	If Parameters.Property("Department") And ValueIsFilled(Parameters.Department) Then
		Query.Text = StrReplace(Query.Text, "&FilterCriterion", "OrderOfMaterials.Department = &Department");
		Query.SetParameter("Department", Parameters.Department);
	Else
		Query.Text = StrReplace(Query.Text, "&FilterCriterion", "TRUE");
	EndIf;
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.OrderOfMaterialsForProduction) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Đơn đề nghị xuất nguyên vật liệu';
						|ru = 'Заказы материалов';
						|en = 'Orders for materials'; fa = 'Orders for materials';
						|it = 'Ordini dei materiali';
						|pl = 'Zamówienia materiałów';
						|tr = 'Malzeme siparişleri'");
	HyperlinkAnchorText = "Document.OrderOfMaterialsForProduction.Form.ListForm";
	
	If ThereAreOrdersInProgress(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, HyperlinkAnchorText);
	Else
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,, HyperlinkAnchorText);
	EndIf;
	
EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.OrderOfMaterialsForProduction, FormDataStructure - the order of materials for which you need to get the destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.OrderOfMaterialsForProduction.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.8";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("585b47aa-3f0e-4e83-8e9d-ebc62dd2e19c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.OrderOfMaterialsForProduction.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Điền mục tin ""Lĩnh vực hoạt động"" trong chứng từ ""Đơn đặt nguyên vật liệu vào sản xuất"". ';
							|ru = 'Заполняет реквизит ""Направление деятельности"" в документе ""Заказ материалов в производство"".';
							|en = 'Fills in the ""Line of business"" attribute in the ""Material order for shop floor stockroom"" document.'; fa = 'Fills in the ""Line of business"" attribute in the ""Material order for shop floor stockroom"" document.';
							|it = 'Fills in the ""Line of business"" attribute in the ""Material order for shop floor stockroom"" document.';
							|pl = 'Fills in the ""Line of business"" attribute in the ""Material order for shop floor stockroom"" document.';
							|tr = '""Üretim için malzeme siparişi"" belgesindeki ""İş kolu"" özniteliğini doldurur.'");
	
	ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = ExecutionPriorities.Add();
	Priority.Order = "Before";
	Priority.Procedure = "InformationRegisters.DocumentsRegistry.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionPriorities = ExecutionPriorities;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.OrderOfMaterialsForProduction.FullName());
	ItemsToRead.Add(Metadata.Catalogs.Assignments.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.OrderOfMaterialsForProduction.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Registers data for processing when switching to a new version.
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.OrderOfMaterialsForProduction";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText = "SELECT DISTINCT
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
	|		Document.OrderOfMaterialsForProduction AS DocumentData
	|			LEFT JOIN Document.OrderOfMaterialsForProduction.Goods AS GoodsTable
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
	|		Document.OrderOfMaterialsForProduction AS DocumentData
	|			LEFT JOIN Document.OrderOfMaterialsForProduction.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
	|		AND DocumentData.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
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
	
	FullObjectName = "Document.OrderOfMaterialsForProduction";
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
	|		Document.OrderOfMaterialsForProduction AS DocumentData
	|			LEFT JOIN Document.OrderOfMaterialsForProduction.Goods AS GoodsTable
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
	|		Document.OrderOfMaterialsForProduction AS DocumentData
	|			LEFT JOIN Document.OrderOfMaterialsForProduction.Goods AS GoodsTable
	|			ON DocumentData.Ref = GoodsTable.Ref
	|	WHERE
	|		DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom)
	|		AND TRUE IN
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
	|		INNER JOIN Document.OrderOfMaterialsForProduction AS DocumentAttributes
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
			
			DocumentObject = Selection.Ref.GetObject(); // DocumentObject.OrderOfMaterialsForProduction
			
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
