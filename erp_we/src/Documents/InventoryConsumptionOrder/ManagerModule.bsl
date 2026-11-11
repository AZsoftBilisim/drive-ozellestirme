#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = CommonClientServer.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn hàng tiêu dùng nội bộ';
		|ru = 'Заказ на внутреннее потребление';
		|en = 'Inventory consumption order'; fa = 'سفارش مصرف موجودی';
		|it = 'Ordine per il consumo interno';
		|pl = 'Zamówienie na konsumpcję wewnętrzną';
		|tr = 'Stok tüketimi emri'",
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
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible, DocumentBasis";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible,BusinessOperation";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "ExpenseLineOfBusinessIsSpecifiedInList", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("InternalInventoryTransfers");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AddressWarehouse");
	
	InventoryConsumptionOrderLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Parameters:
//  Orders - Array of AnyRef -
//  ActionCode - String -
//  UserMessages - Array of Structure
Procedure BeforePerformingActionsInOrderList(Orders, ActionCode, UserMessages) Export
	
	If ActionCode <> "ACTION_LOAD" Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("Orders", Orders);
	Query.Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.InventoryConsumptionOrder AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|	AND NOT Table.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.InventoryConsumptionOrder AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|	AND Table.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval)";
	QueryBatch = Query.ExecuteBatch();
	OrdersPendingApproval = QueryBatch[1].Unload().UnloadColumn("Ref");
	Text = NStr("vi = 'Không thể thực hiện thao tác giao hàng đối với %1: đơn hàng trong trạng thái ""Chờ thống nhất"".';
				|ru = 'Невозможно выполнить действие отгрузить для %1: заказ находится в статусе ""На согласованиии"".';
				|en = 'Cannot ship %1: the order has the ""Pending approval"" status.'; fa = 'Cannot ship %1: the order has the ""Pending approval"" status.';
				|it = 'Невозможно выполнить действие отгрузить для %1: заказ находится в статусе ""На согласованиии"".';
				|pl = 'Cannot ship %1: the order has the ""Pending approval"" status.';
				|tr = '%1 için gönderim işlemi gerçekleştirilemiyor: sipariş ""Onay bekliyor"" durumunda.'");
	For Each Ref In OrdersPendingApproval Do 
		UserMessages.Add(New Structure("Text,Ref", StrTemplate(Text, Ref), Ref));
	EndDo;
	If OrdersPendingApproval.Count() > 0 Then
		Orders = QueryBatch[0].Unload().UnloadColumn("Ref");
	EndIf;
	
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
	
	If TypeOf(Document) = Type("DocumentObject.InventoryConsumptionOrder") Then
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
		
		QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		InventoryConsumptionOrderLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
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
	AcceptableStatuses.Add(Enums.InternalOrderStatuses.ForCompletion);
	AcceptableStatuses.Add(Enums.InternalOrderStatuses.Closed);
	
	Return AcceptableStatuses;
	
EndFunction

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.InventoryConsumption.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.TransferOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.InventoryAssignmentAdjustment.AddGenerateCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands); 
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	InventoryConsumptionOrderLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "internal consumption Order".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.InventoryConsumptionOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventoryConsumptionOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventoryConsumptionOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseInventoryConsumptionOrders";
	
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
	
	ReportCommand = Reports.ResultsOfApprovalOfInventoryConsumptionOrder.AddInternalConsumptionOrderApprovalResultsCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ListForm";
	EndIf;

	ReportCommand = Reports.DocumentFulfillmentStatus.AddCommandStateOfExecutionOfInternalOrders(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
	EndIf;
	
	InventoryConsumptionOrderLocalization.AddReportCommands(ReportsCommands, Parameters);
EndProcedure

#Region CalculationOfStates

// Returns the structure of parameters for calculating the order completion status in the list of orders.
//
// Returns:
//  Structure - contains the following keys:
//    * OrderBalancesModule         - AccumulationRegisterManager.InventoryConsumptionOrders -
//    * MonitorOrderClosing - Boolean -
//    * StatusInProcessOfAdmission   - EnumRef.StatusesOfInternalOrders -
//    * ShippingStatus      - EnumRef.StatusesOfInternalOrders -
//    * ReadyForShipmentStatus         - EnumRef.StatusesOfInternalOrders -
//
Function ParametersForCalculatingStates() Export
	
	Structure = New Structure();
	Structure.Insert("OrderBalancesModule", AccumulationRegisters.InventoryConsumptionOrders);
	Structure.Insert("MonitorOrderClosing",
		GetFunctionalOption("DoNotCloseInventoryConsumptionOrdersWithoutCompleteShipment"));
	Structure.Insert("StatusInProcessOfAdmission", Enums.StatusesOfInternalOrders.DuringShipment);
	Structure.Insert("ShippingStatus", Enums.StatusesOfInternalOrders.DuringShipment);
	Structure.Insert("ReadyForShipmentStatus", Enums.StatusesOfInternalOrders.ReadyToShip);
	
	Return Structure;
	
EndFunction

// Returns a structure containing the query texts of temporary tables for calculating the order completion status in the order list.
// 
// Returns:
//  String - Query text
//
Function TemporaryDocumentTablesForCalculatingStates() Export
	
	QueryTextGoods =
		"SELECT DISTINCT
		|	Table.Ref AS Ref,
		|	Table.SupplyOption AS SupplyOption,
		|	Table.Products.ItemsType IN(
		|		VALUE(Enum.ItemsTypes.OwnGoods),
		|		VALUE(Enum.ItemsTypes.ReusablePackage)) AS ThisIsAProduct,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference
		|INTO TTDocumentProducts_
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|		AND NOT Table.Canceled
		|		AND Table.Ref.Posted";
	
	QueryTextAttributes =
		"SELECT
		|	Table.Ref            AS Ref,
		|	Table.Posted          AS Posted,
		|	
		|	CASE WHEN Table.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval) THEN
		|				FALSE
		|			ELSE
		|				TRUE
		|		END                 AS ShippingStatus_,
		|	
		|	CASE WHEN Table.Status = VALUE(Enum.InternalOrderStatuses.Closed) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END                 AS TheClosedStatus,
		|	
		|	CASE WHEN Table.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END                 AS StatusUnderApproval
		|	
		|INTO TTDocumentDetails
		|FROM
		|	Document.InventoryConsumptionOrder AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)";
	
	Result = New Structure("DocumentGoods, DocumentAttributes", QueryTextGoods, QueryTextAttributes);
	Return Result;
	
EndFunction

// Calculates the current status of the customer's order
//
// Parameters:
//	InventoryConsumptionOrder - DocumentRef.InventoryConsumptionOrder - Document whose state needs to be calculated
//	OrderState - ClientApplicationForm - The form in which the calculated state will be placed.
//  CheckTasksToReflectStateOfOrders - Boolean - indicates whether the task has been checked
//                                                        in the taskreference register for the status of orders.
//
Procedure CalculateStatus(
			Val InventoryConsumptionOrder,
			OrderState,
			CheckTasksToReflectStateOfOrders = False) Export
	
	StructureOfStateOfOrder = New Structure;
	StructureOfStateOfOrder.Insert("State", Enums.StatusesOfInternalOrders.EmptyRef());
	
	FillPropertyValues(OrderState, StructureOfStateOfOrder);
	
	If ValueIsFilled(InventoryConsumptionOrder) Then
	
		SetPrivilegedMode(True);
		
		QueryText = "
			|SELECT
			|	CASE
			|		WHEN NOT DocumentInventoryConsumptionOrder.Posted 
			|			THEN VALUE(Enum.StatusesOfInternalOrders.EmptyRef)
			|		ELSE
			|			ISNULL(StatusesOfInternalOrders.State, VALUE(Enum.StatusesOfInternalOrders.Closed))
			|	END AS State
			|,&FieldHasTasksToReflectStateOfOrders
			|FROM
			|	Document.InventoryConsumptionOrder AS DocumentInventoryConsumptionOrder
			|LEFT JOIN
			|	InformationRegister.StatusesOfInternalOrders AS StatusesOfInternalOrders
			|ON
			|	StatusesOfInternalOrders.OrderDocument = DocumentInventoryConsumptionOrder.Ref
			|WHERE
			|	DocumentInventoryConsumptionOrder.Ref = &InventoryConsumptionOrder
			|	AND &CheckTasksToReflectStateOfOrders
			|
			|";
		
		If CheckTasksToReflectStateOfOrders Then
			
			QueryText = StrReplace(QueryText,
										",&FieldHasTasksToReflectStateOfOrders",
										",	FALSE AS ThereAreTasksToReflectStateOfOrders");
			
			QueryTextThereAreTasksToReflectStateOfOrders =
				DocumentsStates.QueryTextThereAreTasksToReflectStateOfOrders("&InventoryConsumptionOrder");
			
			QueryText = StrReplace(QueryText,
										"&CheckTasksToReflectStateOfOrders",
										StrTemplate("NOT TRUE IN 
												  |		(%1)", QueryTextThereAreTasksToReflectStateOfOrders));
			
			QueryTexts = New Array;
			QueryTexts.Add(QueryTextThereAreTasksToReflectStateOfOrders);
			QueryTexts.Add(QueryText);
			
			QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
			
		Else
			
			QueryText = StrReplace(QueryText, ",&FieldHasTasksToReflectStateOfOrders", "");
			QueryText = StrReplace(QueryText, "&CheckTasksToReflectStateOfOrders", "TRUE");
			
		EndIf;
		
		Query = New Query;
		Query.Text = QueryText;
		
		Query.SetParameter("InventoryConsumptionOrder", InventoryConsumptionOrder);
		
		Results = Query.ExecuteBatch();
		UBound   = Results.UBound();
		
		Selection = Results[UBound].Select();
		If Selection.Next() Then
			
			FillPropertyValues(OrderState, Selection);
			
		ElsIf CheckTasksToReflectStateOfOrders Then
			
			SelectionThereAreTasks = Results[UBound - 1].Select();
			If SelectionThereAreTasks.Next() Then
				
				FillPropertyValues(OrderState, SelectionThereAreTasks);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

// Returns whether the current user has the right to add a document
//
// Parameters:
//
// Returns:
//  Boolean - true if the current user has the right to add a document, false if there is no such right.
//
Function AccessRightInsert() Export
	
	Return AccessRight("Insert", Metadata.Documents.InventoryConsumptionOrder);
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	InventoryConsumptionOrderLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Generates arrays of names of details that depend on the business operation of the document.
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//	AllAttributes - Array - returns all banking details
//  TransactionDetails - Array - returns the details of the operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, AllAttributes, TransactionDetails) Export
	
	AllAttributes = New Array;
	TransactionDetails = New Array;
	
	AllAttributes.Add("Goods.Individual");
	AllAttributes.Add("Goods.OperationCategory");
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		
		TransactionDetails.Add("Goods.Individual");
		TransactionDetails.Add("Goods.OperationCategory");
		
	EndIf;

EndProcedure

// Fills in arrays of form elements that depend on the business operation of the document.
//
// Parameters:
// 		BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
// 		ArrayOfAllElements - Array - Array of all form elements that depend on the business operation
// 		ArrayOfOperationElements - Array - Array of names of form elements used in the selected business operation.
//
Procedure FillInNamesOfElementsForBusinessOperation(BusinessOperation, ArrayOfAllElements, ArrayOfOperationElements) Export
	
	ArrayOfAllElements = New Array;
	ArrayOfOperationElements = New Array;
	
	ArrayOfAllElements.Add("GoodsFillInInventory");
	ArrayOfAllElements.Add("GoodsFillInCategoryOfOperation");
	ArrayOfAllElements.Add("GoodsFillInIndividual");

	If BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		ArrayOfOperationElements.Add("GoodsFillInInventory");
		ArrayOfOperationElements.Add("GoodsFillInCategoryOfOperation");
		ArrayOfOperationElements.Add("GoodsFillInIndividual");
	EndIf;
		
EndProcedure

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
	
	MeaningOfNewStatus = Enums.InternalOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl")  Then
		
		QueryText =
		"SELECT
		|	Balance.InventoryConsumptionOrder AS InventoryConsumptionOrder
		|INTO TTOrderBalances_
		|FROM
		|	AccumulationRegister.InventoryConsumptionOrders.Balance(, InventoryConsumptionOrder IN (&DocumentsArray)) AS Balance
		|
		|GROUP BY
		|	Balance.InventoryConsumptionOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssueBalance.DocumentShipments
		|INTO TTShipmentBalances
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments IN (&DocumentsArray)) AS GoodsForIssueBalance
		|WHERE
		|	GoodsForIssueBalance.ToShipBalance + GoodsForIssueBalance.AssembledBalance <> 0
		|
		|GROUP BY
		|	GoodsForIssueBalance.DocumentShipments
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
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
		//  If at least one register has residues, the work on the document is not completed
		|	CASE
		|			WHEN TTOrderBalances_.InventoryConsumptionOrder IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END
		|		OR CASE
		|			WHEN TTShipmentBalances.DocumentShipments IS NULL 
		|				THEN FALSE
		|			ELSE TRUE
		|		END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.InventoryConsumptionOrder AS DocumentsTable
		|		LEFT JOIN TTOrderBalances_ AS TTOrderBalances_
		|		ON DocumentsTable.Ref = TTOrderBalances_.InventoryConsumptionOrder
		|		LEFT JOIN TTShipmentBalances AS TTShipmentBalances
		|		ON DocumentsTable.Ref = TTShipmentBalances.DocumentShipments
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)";
	
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
		|	Document.InventoryConsumptionOrder AS DocumentsTable
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
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.InternalOrderStatuses - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If AdditionalParameters = Undefined Then
		
		Return Not Cancel;
		
	EndIf;
	
	If AdditionalParameters.Property("OrderFulfillmentControl") And ValidationSample.ThereAreLeftoversOnOrder Then
		
		ErrorText = NStr("vi = 'Chưa đặt trạng thái ""%Status%"" cho chứng từ %Document%, bởi vì đơn hàng chưa được thực hiện đầy đủ';
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

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse, Date";
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
	SeriesSpecificationParameters.FullObjectName = "Document.InventoryConsumptionOrder";
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentForInternalNeeds);
	
	SeriesSpecificationParameters.ThisIsOrder = True;
	SeriesSpecificationParameters.ShipmentPlanning = True;
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.Date = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the value of the receipt or shipment order.
//
// Parameters:
//	FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//		of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - order for receipt or shipment.
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

// Initializes the status structure of the document
//
// Returns:
//  Structure - contains the following keys:
//     * OutputTablesSupply         - Number -
//     * DisplayShipmentTables            - Number -
//     * DisplayTablesCanceledShipment    - Number -
//     * ThisIsOrder                           - Boolean -
//     * WarehouseInHeader                        - Boolean -
//     * TextProductServiceShipment           - String -
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	StructureState.Insert("OutputTablesSupply",      1);
	StructureState.Insert("DisplayShipmentTables",         2);
	StructureState.Insert("DisplayTablesCanceledShipment", 3);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("WarehouseInHeader", True);
	StructureState.Insert("RegisterNameShipmentOfServices", "InventoryConsumptionOrders");
	
	Return StructureState;
	
EndFunction

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object - DocumentObject.InventoryConsumptionOrder, FormDataStructure - the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	
	FillParameters.Organization             = Object.Organization;
	FillParameters.Date                    = Object.Date;
	FillParameters.Warehouse                   = Object.Warehouse;
	FillParameters.Contract                 = Undefined;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
		FillParameters.WriteOffOfGoodsAndWorksForItems = True;
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToProduction Then
		FillParameters.MovementOfGoodsAndWorksInProduction = True;
	EndIf;
	If Object.BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		FillParameters.TransferToOperation = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
//
// Parameters:
//  DocumentObject - DocumentObject.InventoryConsumptionOrder - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	EmbeddingParameters.UseEventSubscriptions.BeforePerformingActionsInOrderList = True;
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "Goods";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "GoodsSupplyOption";
	FormItems.Available           = "GoodsAvailable";
	FormItems.Series              = "GoodsSeries";
	FormItems.WithAssignment        = "GoodsWithAssignment";
	FormItems.Warehouse              = "GoodsWarehouse";
	
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
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "InventoryConsumptionOrders";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.InventoryConsumptionOrder";
	EmbeddingParameters.TableName = "Document.InventoryConsumptionOrder.Goods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	Attributes.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed)
		|		) AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				TabPart.DateOfShipment
		|		END AS RequestShipmentOn,
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
		|	Document.InventoryConsumptionOrder.Goods AS TabPart
		|		
		|		LEFT JOIN Document.InventoryConsumptionOrder AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	Goods = New Structure();
	Goods.Insert("LineNumber",        New TypeDescription("Number"));
	Goods.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	Goods.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	Goods.Insert("WithAssignment",        New TypeDescription("Boolean"));
	Goods.Insert("Count",         New TypeDescription("Number"));
	Goods.Insert("NumberOfPackages", New TypeDescription("Number"));
	Goods.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Insert("DateOfShipment",       New TypeDescription("Date"));
	Goods.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Insert("Canceled",           New TypeDescription("Boolean"));
	Goods.Insert("RowCode",          New TypeDescription("Number"));
	
	Object = New Structure();
	Object.Insert("Department",      New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Purpose",         New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",             New TypeDescription("DocumentRef.InventoryConsumptionOrder"));
	Object.Insert("Status",             New TypeDescription("EnumRef.InternalOrderStatuses"));
	Object.Insert("NotShipInInstallments", New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",       New TypeDescription("Date"));
	Object.Insert("Date",               New TypeDescription("Date"));
	Object.Insert("Priority",          New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("Goods",             Goods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	Return EmbeddingParameters;
	
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

Function QueryTextDocumentGoods() Export

	QueryText = 
	"SELECT
	|	Table.Ref                       AS InventoryConsumptionOrder,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	CASE WHEN Table.WithAssignment THEN
	|				Table.Ref.Purpose
	|			ELSE
	|				VALUE(Catalog.Assignments.EmptyRef)
	|		END                            AS Purpose,
	|	CASE 
	|		WHEN &ExpenseLineOfBusinessIsSpecifiedInList THEN
	|			CASE 
	|				WHEN Table.Ref.ExpenseLineOfBusinessIsSpecifiedInList THEN			
	|					Table.LineOfBusiness
	|				ELSE
	|					Table.Ref.LineOfBusiness
	|				END
	|		ELSE
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                            	 AS LineOfBusiness,
	|	Table.RowCode                    AS RowCode,
	|	Table.Series                        AS Series,
	|	Table.Count                   AS Count,
	|	Table.Package                     AS Package,
	|	Table.DateOfShipment                 AS DateOfShipment,
	|	Table.ExpenseItem               AS ExpenseItem,
	|	Table.DimensionOfExpenses            AS DimensionOfExpenses,
	|	Table.ProductsGroup              AS ProductsGroup,
	|	Table.Ref.Warehouse                 AS Warehouse,
	|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
	|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered,
	|	Table.Individual               AS Individual,
	|	Table.OperationCategory        AS OperationCategory
	|FROM
	|	Document.InventoryConsumptionOrder.Goods AS Table
	|	LEFT JOIN TTAccountingData AS DataOfAccounting
	|	ON Table.Ref = DataOfAccounting.InventoryConsumptionOrder
	|	AND Table.RowCode = DataOfAccounting.RowCode
	|WHERE
	|	NOT DataOfAccounting.InventoryConsumptionOrder IS NULL
	|		AND Table.Ref IN(&References)";
	
	Return QueryText;

EndFunction

#Region Supply

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.InventoryConsumptionOrder - the document for which you need to get the goods
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
		|			THEN Goods.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.DateOfShipment AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	
	Query.Execute();
	
EndProcedure

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.InventoryConsumptionOrder - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters) Export
	
	ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.Goods,
		"DateOfShipment");
		
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			Changes.UnloadColumn("String"),
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
			
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.Goods);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// Parameters for embedding business lines in a document.
// Parameters:
//  Form - ClientApplicationForm - the form of the document.
//	Returns:
//   See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

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
	
	If TypeOf(ListOfOrders_) = Type("DocumentRef.InventoryConsumptionOrder") Then
		ReferenceArray = New Array();
		ReferenceArray.Add(ListOfOrders_);
	Else
		ReferenceArray = ListOfOrders_;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	GoodsToReceive.InventoryConsumptionOrder AS OrderDocument,
		|	GoodsToReceive.Products                 AS Products,
		|	GoodsToReceive.Characteristic               AS Characteristic,
		|	GoodsToReceive.Series                        AS Series,
		|	SUM(GoodsToReceive.ToRegisterReceipt
		|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
		|FROM
		|	AccumulationRegister.InventoryConsumptionOrders.Turnovers(&StartPeriod_,&ConPeriod,, 
		|		InventoryConsumptionOrder IN (&ReferenceArray)) AS GoodsToReceive
		|WHERE
		|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|GROUP BY
		|	GoodsToReceive.InventoryConsumptionOrder,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Series");
	
	Query.SetParameter("ReferenceArray", ReferenceArray);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("InventoryConsumptionOrders",
		"InventoryConsumptionOrder IN (&ReferenceArray)", Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("GoodsAssetsLiabilitiesDimension");
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToOperation Then
		
		ChoiceParameters.SelectingItemOfAssetsLiabilities = False;
		
		ListOfConditions = New Structure;
		ListOfConditions.Insert("DimensionOfExpensesRequired_", True);
		ListOfConditions.Insert("AccountAsGroupFA", False);
		ChoiceParameters.ConditionsForMandatoryAnalyticsInRows = ListOfConditions;
		
	EndIf;
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	HeaderData_.Date AS Period,
		|	HeaderData_.Organization AS Organization,
		|	HeaderData_.BusinessOperation AS BusinessOperation,
		|	HeaderData_.Warehouse AS Warehouse,
		|	HeaderData_.Department AS Department,
		|	HeaderData_.Status AS Status,
		|	HeaderData_.Purpose AS Purpose,
		|	HeaderData_.Priority AS Priority,
		|	ISNULL(HeaderData_.Purpose.RecordsInWarehouseRegisters, FALSE) AS RecordsInWarehouseRegisters,
		|	HeaderData_.LineOfBusiness AS LineOfBusiness,
		|	HeaderData_.EmployeeResponsible AS EmployeeResponsible,
		|	HeaderData_.Author AS Author,
		|	HeaderData_.SalesOpportunity AS SalesOpportunity,
		|	HeaderData_.Comment AS Comment,
		|	HeaderData_.Posted AS Posted,
		|	HeaderData_.DeletionMark AS DeletionMark,
		|	HeaderData_.Number AS Number,
		|	PRESENTATION(HeaderData_.SalesOpportunity) AS SalesOpportunityPresentation
		|FROM
		|	Document.InventoryConsumptionOrder AS HeaderData_
		|WHERE
		|	HeaderData_.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                       Attributes.Period);
	Query.SetParameter("Organization",                  Attributes.Organization);
	Query.SetParameter("Warehouse",      			      Attributes.Warehouse);
	Query.SetParameter("Status",                       Attributes.Status);
	Query.SetParameter("Purpose", 			      Attributes.Purpose);
	Query.SetParameter("BusinessOperation",        Attributes.BusinessOperation);
	Query.SetParameter("RecordsInWarehouseRegisters", Attributes.RecordsInWarehouseRegisters);
	Query.SetParameter("Department",                Attributes.Department);
	Query.SetParameter("Organization",                  Attributes.Organization);
	Query.SetParameter("LineOfBusiness",      Attributes.LineOfBusiness);
	Query.SetParameter("EmployeeResponsible",                Attributes.EmployeeResponsible);
	Query.SetParameter("SalesOpportunity",                       Attributes.SalesOpportunity);
	Query.SetParameter("Comment",                  Attributes.Comment);
	Query.SetParameter("Posted",                     Attributes.Posted);
	Query.SetParameter("DeletionMark",              Attributes.DeletionMark);
	Query.SetParameter("Priority",                    Attributes.Priority);
	Query.SetParameter("Number",                        Attributes.Number);
	Query.SetParameter("Author",                        Attributes.Author);
	Query.SetParameter("MetadataIdentifier",      Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	
	TransactionInformation = "";
	If ValueIsFilled(Attributes.SalesOpportunity) Then
		StringPattern = "vi = 'Theo vụ việc ""%1""';
						|ru = 'По сделке ""%1""';
						|en = 'By the ""%1"" sales opportunity';
						|it = 'Per la transazione ""%1""';
						|pl = 'Wg umowy ""%1""';
						|tr = 'Anlaşma kapsamında ""%1""'"; // @NStr
		TransactionInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.SalesOpportunityPresentation);
	EndIf;
	
	Query.SetParameter("TransactionInformation", TransactionInformation);
	
EndProcedure

Function QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, Registers)
	RegisterName = "InventoryConsumptionOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	QueryText =
		"SELECT
		|	BEGINOFPERIOD(&Period, DAY)           AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	GoodsTable.Ref                   AS InventoryConsumptionOrder,
		|	GoodsTable.Products             AS Products,
		|	GoodsTable.Characteristic           AS Characteristic,
		|	GoodsTable.Series                    AS Series,
		|	GoodsTable.RowCode                AS RowCode,
		|	CASE
		|		WHEN GoodsTable.Products.ItemsType IN (
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN &Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END                                  AS Warehouse,
		|	0                                      AS ToRegister,
		|	GoodsTable.Count               AS Ordered
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	
		|UNION ALL
		|	
		|SELECT
		|	GoodsTable.DateOfShipment             AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	GoodsTable.Ref                   AS InventoryConsumptionOrder,
		|	GoodsTable.Products             AS Products,
		|	GoodsTable.Characteristic           AS Characteristic,
		|	GoodsTable.Series                    AS Series,
		|	GoodsTable.RowCode                AS RowCode,
		|	CASE
		|		WHEN GoodsTable.Products.ItemsType IN (
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN &Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END                                  AS Warehouse,
		|	GoodsTable.Count               AS ToRegister,
		|	0                                      AS Ordered
		|
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND (NOT GoodsTable.Canceled)
		|	AND &Status IN (VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|		VALUE(Enum.InternalOrderStatuses.Closed))
		|
		|UNION ALL
		|
		|SELECT
		|	&Period                                AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	GoodsTable.Ref                   AS InventoryConsumptionOrder,
		|	GoodsTable.Products             AS Products,
		|	GoodsTable.Characteristic           AS Characteristic,
		|	GoodsTable.Series                    AS Series,
		|	GoodsTable.RowCode                AS RowCode,
		|	CASE
		|		WHEN GoodsTable.Products.ItemsType IN (
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN &Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END                                  AS Warehouse,
		|	0                                      AS ToRegister,
		|	- GoodsTable.Count             AS Ordered
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND GoodsTable.Canceled
		|
		|";
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.InventoryConsumptionOrder";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",      """""");
	RedefiningParameterCalculation.Insert("TransactionInformation", """""");
	RedefiningParameterCalculation.Insert("RecordsInWarehouseRegisters",
		"ISNULL(GoodsTable.Ref.Purpose.RecordsInWarehouseRegisters, FALSE)");
	
	If RegisterName = "InventoryConsumptionOrders" Then
		
		QueryText = QueryTextTableInventoryConsumptionOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
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
	|	&BusinessOperation                  AS BusinessOperation,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	VALUE(Catalog.Currencies.EmptyRef)AS Currency,
	|	0                            			AS Sum,
	|	&Status                                 AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&TransactionInformation                     AS More,
	|	&Period                            		AS SourceDocumentDate,
	|	&NumberForPrinting                     		AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	&Priority                              AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	CASE WHEN DocumentGoods.DateOfShipment <> DATETIME(1, 1, 1) THEN
	|				DocumentGoods.DateOfShipment
	|			ELSE
	|				HeaderData_.Date
	|		END                           AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Department			AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.InventoryConsumptionOrder.Goods AS DocumentGoods
	|		LEFT JOIN Document.InventoryConsumptionOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|	AND DocumentGoods.Count <> 0";
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.DateOfShipment		AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Department			AS Recipient,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	Document.InventoryConsumptionOrder.Goods AS DocumentGoods
	|		LEFT JOIN Document.InventoryConsumptionOrder AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.Status IN(VALUE(Enum.InternalOrderStatuses.ForCompletion),
	|							VALUE(Enum.InternalOrderStatuses.Closed))
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.InternalOrderStatuses.ForCompletion),
		|			VALUE(Enum.InternalOrderStatuses.Closed))
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
		
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	CASE
		|		WHEN TabPart.Ref.NotShipInInstallments
		|			THEN TabPart.Ref.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|	AND TabPart.Ref.Status <> VALUE(Enum.InternalOrderStatuses.AwaitingApproval)";
		
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref                                     AS Ref,
		|	TabPart.Ref.Date                                AS Period,
		|	TabPart.Products                               AS Products,
		|	TabPart.Characteristic                             AS Characteristic,
		|	
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Ref.Department
		|		ELSE TabPart.Ref.Warehouse
		|	END                                               AS Warehouse,
		|	
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END                                               AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count                                 AS Count,
		|	VALUE(Enum.SupplyOptions.FromWarehouse) AS SupplyOption,
		|	TabPart.Ref                                     AS OrderDocument,
		|	
		|	CASE
		|		WHEN TabPart.Ref.NotShipInInstallments
		|			THEN TabPart.Ref.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END                                               AS RequestShipmentOn,
		|	FALSE                                                AS OnSchedule,
		|	UNDEFINED                                        AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.InventoryConsumptionOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval)
		|		AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)";
		
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
		
EndProcedure

#EndRegion

#Region FormationOfHyperlinkInJournalOfDocumentsOfInternalCommodityMovement

Function ThereAreOrdersInProgress(Parameters)
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	OrderStates.OrderDocument AS OrderDocument,
		|	OrderStates.State AS State
		|FROM
		|	InformationRegister.StatusesOfInternalOrders AS OrderStates
		|WHERE
		|	OrderStates.OrderDocument REFS Document.InventoryConsumptionOrder
		|	AND OrderStates.State <> VALUE(Enum.StatusesOfInternalOrders.Closed)");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.StatusesOfInternalOrders)
			And AccessRight("Update", Metadata.Documents.InventoryConsumptionOrder)
			And GetFunctionalOption("UseInventoryConsumptionOrders")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Đơn hàng tiêu dùng nội bộ';
						|ru = 'Заказы на внутреннее потребление';
						|en = 'Inventory consumption orders'; fa = 'سفارش‌های مصرف موجودی';
						|it = 'Ordini per il consumo interno';
						|pl = 'Zamówienia na konsumpcję wewnętrzną';
						|tr = 'Stok tüketimi emri'");
	HyperlinkAnchorText = "Document.InventoryConsumptionOrder.Form.ListForm";
	
	If ThereAreOrdersInProgress(Parameters) Then
		Return New FormattedString(HyperlinkText,,,, HyperlinkAnchorText);
	Else
		Return New FormattedString(HyperlinkText,, StyleColors.EmptyTableField,, HyperlinkAnchorText);
	EndIf;
	
EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.InventoryConsumptionOrder, FormDataStructure - an internal consumption order for which you need to get a destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfGoodsAssignmentInInventoryConsumption.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfGoodsAssignmentInInventoryConsumption.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
