
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
	
	DocumentMechanisms.Add("Production");
	DocumentMechanisms.Add("OrderStructure");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * Table - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ProductionOrder2_2") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	Else
		DocumentObject = Document.GetObject();
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
		
		QueryTextTableProductionProcessSupply(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableProductionOrders(Query, QueryTexts, Registers, DocumentObject);  
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.InventoryAssignmentAdjustment.AddCreateCommandBasedOnCustomerOrder(GenerationCommands);
	
	Documents.StandardCosting2_2.AddGenerateCommand(GenerationCommands);
	
	Documents.EngineeringChangeOrder.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the "production Order" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
// See ProductionManagement.AddCreateSecuringOrderCommand
Function AddCreateSecuringOrderCommand(GenerationCommands) Export
	Return ProductionManagement.AddCreateSecuringOrderCommand(GenerationCommands);
EndFunction

// Adds a command to create a document "Custom PRODUCTION2_2".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ProductionOrder2_2)
		Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager =  Metadata.Documents.ProductionOrder2_2.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ProductionOrder2_2);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseProduction";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command to create a document "Production order" for Reverse kitting.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow, Undefined - added command
//
Function AddCommandToCreateProductionOrderOfReverseKitType(GenerationCommands) Export
	
	MetadataObject = Metadata.Documents.ProductionOrder2_2;
	
	If AccessRight("Insert", MetadataObject) Then
	
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager =  MetadataObject.FullName();
		CreateBasedOnCommand.Presentation = StrTemplate("%1 (%2)",
				MetadataObject.Synonym, Lower(Enums.ProductionProcessTypes.Disassembly));
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateProductionOrderOfReverseKittingType";
		
		Return CreateBasedOnCommand;
	
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command to create a document "Production order" for repair work.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow, Undefined - added command
//
Function AddCommandToCreateProductionOrderOfRepairWorkType(GenerationCommands) Export
	
	MetadataObject = Metadata.Documents.ProductionOrder2_2;
	
	If AccessRight("Insert", MetadataObject) Then
	
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager =  MetadataObject.FullName();
		CreateBasedOnCommand.Presentation = StrTemplate("%1 (%2)",
				MetadataObject.Synonym, Lower(Enums.ProductionProcessTypes.PerformRM));
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateProductionOrderOfRepairWorkType";
		
		Return CreateBasedOnCommand;
	
	EndIf;
	
	Return Undefined;
	
EndFunction

// Creation parameters based on the providing order.
// Returns:
// See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
Function CreationParametersBasedOnProvidingOrder() Export
	
	ProductTableParameters = ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder();
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	Return ProductTableParameters;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand_ = Undefined;
	
	If GetFunctionalOption("UsePlanningByMaterialResources")
		Or GetFunctionalOption("UsePlanningByProductionResources") Then
		ReportCommand_ = Reports.ProductionSchedule2_2.AddReportCommand(ReportsCommands);
	ElsIf GetFunctionalOption("StandardOrderStructureScheduleIsUsed") Then
		ReportCommand_ = Reports.StandardProductionScheduleByOrders.AddReportCommand(ReportsCommands);
	EndIf;
	
	If Not ReportCommand_ = Undefined Then
		ReportCommand_.Order = 1;
	EndIf;
	
	Reports.ScheduleOfProductionOrderMaterialConsumption.AddReportCommand(ReportsCommands);
	
	Reports.ScheduleOfHumanResourceOccupancyByProductionOrders.AddReportCommand(ReportsCommands);
	
	Reports.ProductStandardCostComparison.AddReportCommand(ReportsCommands);
	
	Reports.ProductsCostTree.AddReportCommand(ReportsCommands);

	Reports.MonitorProductionOrder.AddReportCommand(ReportsCommands);
	
	Reports.MonitorOrder.AddReportCommand(ReportsCommands);
	
	Reports.LaborInputOfProductionOrder.AddReportCommand(ReportsCommands, "LaborInputByOrder");
	
	Reports.OrderCompleteness.AddStaffingCommandByOrder(ReportsCommands);
	
	Reports.ControlOfProductionByOrder.AddReportCommand(ReportsCommands);
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ProductionOrder";
	PrintCommand.Presentation = NStr("vi = 'Đơn hàng sản xuất';
									|ru = 'Заказ на производство';
									|en = 'Production order'; fa = 'سفارش تولید';
									|it = 'Ordine di produzione';
									|pl = 'Zlecenie produkcyjne';
									|tr = 'Üretim emri'");
	PrintCommand.CheckPostingBeforePrint = True;
	
EndProcedure

#EndRegion

#Region ObjectsVersioning

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Status";
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - Contains keys:
//    * FinishedProductBeingRepaired - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//
Function SeriesSpecificationParameters(Object) Export
	
	ProductionSettings = ProductionServer.UseOfSeriesInProduction22();
	
	SeriesSpecificationParameters = New Structure;

	#Region FinishedProductBeingRepaired
	ParametersForSpecifyingRIBatches = ProductsClientServer.SeriesSpecificationParameters();
	ParametersForSpecifyingRIBatches.FullObjectName = "Document.ProductionOrder2_2";
	ParametersForSpecifyingRIBatches.ProductInHeader = True;
	
	ParametersForSpecifyingRIBatches.UseItemsBatch = ProductionSettings.UseItemsBatch;
	
	ParametersForSpecifyingRIBatches.WarehouseFieldName = Undefined;
	ParametersForSpecifyingRIBatches.NameTSGoods = Undefined;
	ParametersForSpecifyingRIBatches.TSSeriesName = Undefined;
	
	ParametersForSpecifyingRIBatches.FieldNamesWithSuffix.Insert("Products",   "UnderRepairProduct");
	ParametersForSpecifyingRIBatches.FieldNamesWithSuffix.Insert("Characteristic", "UnderRepairVariant");
	ParametersForSpecifyingRIBatches.FieldNamesWithSuffix.Insert("Series",          "UnderRepairBatch");

	ParametersForSpecifyingRIBatches.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductRM);

	ParametersForSpecifyingRIBatches.RegisterSeries = True;
	
	ParametersForSpecifyingRIBatches.FactOfSelection = (Object.Status = Enums.ProductionOrderStatuses2_2.ToProduce
												Or Object.Status = Enums.ProductionOrderStatuses2_2.Closed);
	
	SeriesSpecificationParameters.Insert("FinishedProductBeingRepaired", ParametersForSpecifyingRIBatches);
	#EndRegion
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = QueryTextForFillingInStatusesIndicatingBatchesOfFinishedProductBeingRepaired();
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Queue

// Returns a new number in the production order queue.
//
// Returns:
//   - Number - a new number in the queue.
//
Function NewQueueNumber() Export
	
	Query = New Query(
		"SELECT TOP 1
		|	(T.Queue + 1) AS NewQueueNumber
		|FROM
		|	Document.ProductionOrder2_2 AS T
		|
		|ORDER BY
		|	T.Queue DESC");
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		
		NewQueueNumber = 1;
		
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		NewQueueNumber = Selection.NewQueueNumber;
		
	EndIf;
	
	Return NewQueueNumber;
	
EndFunction

// Determines whether a document can be moved to a single position in the queue
//
// Parameters:
//  CurrentOrder - DocumentRef.ProductionOrder2_2 - current order
//  Direction	 - Number - -1, moves the order up the queue
//                         +1, moves the order down the queue.
// 
// Returns:
//   - Boolean - True if the document can be moved to one position in the queue.
//
Function YouCanMoveDocumentToQueue(CurrentOrder, Direction) Export
	
	If Direction = 0 Then
		Return False;
	EndIf;
	
	QueryText =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	Document.ProductionOrder2_2 AS CurProductionOrder
		|		INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
		|		ON ProductionOrder.Priority        = CurProductionOrder.Priority
		|			AND ProductionOrder.Department = CurProductionOrder.Department
		|			AND ProductionOrder.Queue       < CurProductionOrder.Queue
		|WHERE
		|	CurProductionOrder.Ref = &CurrentOrder
		|	AND ProductionOrder.Status = &StatusForProduction
		|	AND ProductionOrder.Posted";
	
	If Direction > 0 Then
		QueryText = StrReplace(QueryText, "<", ">");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("CurrentOrder", CurrentOrder);
	Query.SetParameter("StatusForProduction", StatusOfProductionOrder());
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Moves a document in the order queue by one position
//
// Parameters:
//  CurrentOrder - DocumentRef.ProductionOrder2_2 - current order
//  Direction	 - Number - -1, moves the order up the queue
//                         +1, moves the order down the queue.
// 
Procedure MoveDocumentToQueue(CurrentOrder, Direction) Export
	
	Try
		LockDataForEdit(CurrentOrder);
	Except
		ErrorTemplate = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
							|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
							|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
							|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
							|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
							|tr = '%Document% bloke edilemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorTemplate, "%Document%", CurrentOrder);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		Common.MessageToUser(ErrorText, CurrentOrder);
		Return;
	EndTry;
		
	Query = New Query;
	
	If Direction > 0 Then
		
		Query.Text = 
			"SELECT
			|	T.Priority AS Priority,
			|	CASE
			|		WHEN T.QueueAverage = T.QueueMaximum
			|			THEN T.QueueMaximum + 1
			|		ELSE T.QueueAverage
			|	END       AS Queue
			|
			|FROM
			|	(SELECT TOP 1
			|		T.Priority         AS Priority,
			|		T.PriorityOrder  AS PriorityOrder,
			|		AVG(T.Queue)  AS QueueAverage,
			|		MAX(T.Queue) AS QueueMaximum
			|	FROM
			|		(
			|			SELECT
			|				T.Priority        AS Priority,
			|				T.PriorityOrder AS PriorityOrder,
			|				T.Queue          AS Queue
			|			FROM (
			|				SELECT TOP 2
			|					ProductionOrder.Priority                           AS Priority,
			|					ProductionOrder.Priority.AddlOrderingAttribute AS PriorityOrder,
			|					ProductionOrder.Queue                             AS Queue
			|				FROM
			|					Document.ProductionOrder2_2 AS CurProductionOrder
			|						INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
			|						ON ProductionOrder.Priority        = CurProductionOrder.Priority
			|							AND ProductionOrder.Department = CurProductionOrder.Department
			|							AND ProductionOrder.Queue       > CurProductionOrder.Queue
			|				WHERE
			|					CurProductionOrder.Ref = &CurrentOrder
			|					AND ProductionOrder.Status = &StatusForProduction
			|					AND ProductionOrder.Posted
			|
			|				ORDER BY
			|					Queue
			|				) AS T
			|			
			|			UNION ALL
			|
			|			SELECT
			|				T.Priority        AS Priority,
			|				T.PriorityOrder AS PriorityOrder,
			|				T.Queue          AS Queue
			|			FROM (
			|				SELECT TOP 2
			|					ProductionOrder.Priority                           AS Priority,
			|					ProductionOrder.Priority.AddlOrderingAttribute AS PriorityOrder,
			|					ProductionOrder.Queue                             AS Queue
			|				FROM
			|					Document.ProductionOrder2_2 AS CurProductionOrder
			|						INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
			|						ON ProductionOrder.Priority.AddlOrderingAttribute > CurProductionOrder.Priority.AddlOrderingAttribute
			|							AND ProductionOrder.Department                    = CurProductionOrder.Department
			|				WHERE
			|					CurProductionOrder.Ref = &CurrentOrder
			|					AND ProductionOrder.Status = &StatusForProduction
			|					AND ProductionOrder.Posted
			|					AND NOT TRUE IN (
			|									SELECT TOP 1
			|										TRUE
			|									FROM
			|										Document.ProductionOrder2_2 AS ProductionOrderQueue
			|									WHERE
			|										ProductionOrderQueue.Priority       = CurProductionOrder.Priority
			|										AND ProductionOrderQueue.Department = CurProductionOrder.Department
			|										AND ProductionOrderQueue.Queue       > CurProductionOrder.Queue
			|										AND ProductionOrderQueue.Status = &StatusForProduction
			|					                    AND ProductionOrderQueue.Posted)
			|				ORDER BY
			|					PriorityOrder,
			|					Queue
			|				) AS T
			|		) AS T
			|
			|	GROUP BY
			|		T.Priority,
			|		T.PriorityOrder
			|
			|	ORDER BY
			|		PriorityOrder
			|	) AS T
			|
			|WHERE
			|	NOT T.QueueAverage IS NULL";
		
	Else
		
		Query.Text = 
			"SELECT
			|	T.Priority AS Priority,
			|	CASE
			|		WHEN T.QueueAverage = T.QueueMinimum
			|			THEN T.QueueMinimum / 2
			|		ELSE T.QueueAverage
			|	END       AS Queue
			|
			|FROM
			|	(SELECT TOP 1
			|		T.Priority         AS Priority,
			|		T.PriorityOrder  AS PriorityOrder,
			|		MIN(T.Queue)  AS QueueMinimum,
			|		AVG(T.Queue)  AS QueueAverage
			|	FROM
			|		(
			|			SELECT
			|				T.Priority        AS Priority,
			|				T.PriorityOrder AS PriorityOrder,
			|				T.Queue          AS Queue
			|			FROM (
			|				SELECT TOP 2
			|					ProductionOrder.Priority                           AS Priority,
			|					ProductionOrder.Priority.AddlOrderingAttribute AS PriorityOrder,
			|					ProductionOrder.Queue                             AS Queue
			|				FROM
			|					Document.ProductionOrder2_2 AS CurProductionOrder
			|						INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
			|						ON ProductionOrder.Priority        = CurProductionOrder.Priority
			|							AND ProductionOrder.Department = CurProductionOrder.Department
			|							AND ProductionOrder.Queue       < CurProductionOrder.Queue
			|				WHERE
			|					CurProductionOrder.Ref = &CurrentOrder
			|					AND ProductionOrder.Status = &StatusForProduction
			|					AND ProductionOrder.Posted
			|
			|				ORDER BY
			|					Queue DESC
			|				) AS T
			|			
			|			UNION ALL
			|
			|			SELECT
			|				T.Priority        AS Priority,
			|				T.PriorityOrder AS PriorityOrder,
			|				T.Queue          AS Queue
			|			FROM (
			|				SELECT TOP 2
			|					ProductionOrder.Priority                           AS Priority,
			|					ProductionOrder.Priority.AddlOrderingAttribute AS PriorityOrder,
			|					ProductionOrder.Queue                             AS Queue
			|				FROM
			|					Document.ProductionOrder2_2 AS CurProductionOrder
			|						INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
			|						ON ProductionOrder.Priority.AddlOrderingAttribute < CurProductionOrder.Priority.AddlOrderingAttribute
			|							AND ProductionOrder.Department                    = CurProductionOrder.Department
			|				WHERE
			|					CurProductionOrder.Ref = &CurrentOrder
			|					AND ProductionOrder.Status = &StatusForProduction
			|					AND ProductionOrder.Posted
			|					AND NOT TRUE IN (
			|									SELECT TOP 1
			|										TRUE
			|									FROM
			|										Document.ProductionOrder2_2 AS ProductionOrderQueue
			|									WHERE
			|										ProductionOrderQueue.Priority       = CurProductionOrder.Priority
			|										AND ProductionOrderQueue.Department = CurProductionOrder.Department
			|										AND ProductionOrderQueue.Queue       < CurProductionOrder.Queue
			|										AND ProductionOrderQueue.Status = &StatusForProduction
			|					                    AND ProductionOrderQueue.Posted)
			|
			|				ORDER BY
			|					PriorityOrder DESC,
			|					Queue DESC
			|				) AS T
			|		) AS T
			|
			|	GROUP BY
			|		T.Priority,
			|		T.PriorityOrder
			|
			|	ORDER BY
			|		PriorityOrder DESC
			|	) AS T
			|
			|WHERE
			|	NOT T.QueueAverage IS NULL";
		
	EndIf;
	
	Query.SetParameter("CurrentOrder",        CurrentOrder);
	Query.SetParameter("StatusForProduction", StatusOfProductionOrder());
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		
		BeginTransaction();
		
		Try
			
			OrderObject = CurrentOrder.GetObject();
			PriorityChanged = OrderObject.Priority <> Selection.Priority;
			FillPropertyValues(OrderObject, Selection, "Priority, Queue");
			OrderObject.DataExchange.Load = True;
			OrderObject.Write(DocumentWriteMode.Write);
		
			If PriorityChanged Then
				UniversalQueueOfRealTimeJobs.ProcessTask_(CurrentOrder, Enums.UniversalQueueTasks.UpdatePriorityInProductionStages);
			EndIf;
	
			If OrderObject.DynamicStructure Then
				UniversalQueueOfRealTimeJobs.ProcessTask_(CurrentOrder, Enums.UniversalQueueTasks.UpdateOrderStructureWhenQueuePlaceIsChanged);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = StrTemplate(NStr("vi = 'Không thể ghi lại %1. %2';
										|ru = 'Не удалось записать %1. %2';
										|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
										|it = 'Impossibile registrare %1. %2';
										|pl = 'Nie udało się zapisać %1. %2';
										|tr = '%1 kaydedilemedi. %2'"),
				CurrentOrder,
				BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(ErrorText, CurrentOrder);
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Determines whether a document can be inserted into the queue
//
// Parameters:
//  CurrentOrder - DocumentRef.ProductionOrder2_2 - current order
//  NewPosition - DocumentRef.ProductionOrder2_2 - new position in the queue.
// 
// Returns:
//   - Boolean - True if the document can be inserted into the specified queue position.
//
Function YouCanInsertDocumentIntoQueue(CurrentOrder, NewPosition) Export
	
	Query = New Query("
		|SELECT
		|	TRUE 
		|FROM
		|	Document.ProductionOrder2_2 AS NewPosition
		|		INNER JOIN Document.ProductionOrder2_2 AS CurrentOrder
		|		ON  CurrentOrder.Ref          = &CurrentOrder
		|			AND NewPosition.Ref        = &NewPosition
		|			AND NewPosition.Department = CurrentOrder.Department
		|			AND NewPosition.Priority     = CurrentOrder.Priority
		|			AND NewPosition.Status        = &StatusForProduction
		|			AND CurrentOrder.Status        = &StatusForProduction
		|			AND NewPosition.Posted
		|			AND CurrentOrder.Posted");
	
	Query.SetParameter("CurrentOrder", CurrentOrder);
	Query.SetParameter("NewPosition", NewPosition);
	Query.SetParameter("StatusForProduction", StatusOfProductionOrder());
	
	QueryResult = Query.Execute();
	
	Return Not QueryResult.IsEmpty();
	
EndFunction

// Inserts a document into the order queue
//
// Parameters:
//  CurrentOrder - DocumentRef.ProductionOrder2_2 - current order
//  NewPosition - DocumentRef.ProductionOrder2_2 - new position in the queue.
//
Procedure InsertDocumentIntoQueue(CurrentOrder, NewPosition) Export
	
	Try
		LockDataForEdit(CurrentOrder);
	Except
		ErrorTemplate = NStr("vi = 'Không thể khóa %Document%. %ErrorDescription%';
							|ru = 'Не удалось заблокировать %Document%. %ErrorDescription%';
							|en = 'Failed to lock %Document%. %ErrorDescription%'; fa = 'Failed to lock %Document%. %ErrorDescription%';
							|it = 'Non è stato possibile bloccare %Document%. %ErrorDescription%';
							|pl = 'Nie udało się zablokować %Document%, %ErrorDescription%';
							|tr = '%Document% bloke edilemedi. %ErrorDescription%'");
		ErrorText = StrReplace(ErrorTemplate, "%Document%", CurrentOrder);
		ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
		Common.MessageToUser(ErrorText, CurrentOrder);
		Return;
	EndTry;
	
	Query = New Query(
		"SELECT
			|	T.Priority AS Priority,
			|	CASE
			|		WHEN T.QueueAverage = T.QueueMinimum
			|			THEN T.QueueMinimum / 2
			|		ELSE T.QueueAverage
			|	END       AS Queue
			|
			|FROM
			|	(SELECT
			|		T.Priority         AS Priority,
			|		MIN(T.Queue)  AS QueueMinimum,
			|		AVG(T.Queue)  AS QueueAverage
			|	FROM
			|		(
			|			SELECT TOP 2
			|				ProductionOrder.Priority AS Priority,
			|				ProductionOrder.Queue   AS Queue
			|			FROM
			|				Document.ProductionOrder2_2 AS ProductionOrderNewPosition
			|					INNER JOIN Document.ProductionOrder2_2 AS ProductionOrder
			|					ON ProductionOrder.Priority        = ProductionOrderNewPosition.Priority
			|						AND ProductionOrder.Department = ProductionOrderNewPosition.Department
			|						AND ProductionOrder.Queue      <= ProductionOrderNewPosition.Queue
			|			WHERE
			|				ProductionOrderNewPosition.Ref = &NewPosition
			|				AND ProductionOrder.Status = &StatusForProduction
			|				AND ProductionOrder.Posted
			|
			|			ORDER BY
			|				Queue DESC
			|		) AS T
			|
			|	GROUP BY
			|		T.Priority
			|	) AS T
			|
			|WHERE
			|	NOT T.QueueAverage IS NULL");
	
	Query.SetParameter("NewPosition", NewPosition);
	Query.SetParameter("StatusForProduction", StatusOfProductionOrder());
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		
		BeginTransaction();
		Try
			
			OrderObject = CurrentOrder.GetObject();
			PriorityChanged = OrderObject.Priority <> Selection.Priority;
			FillPropertyValues(OrderObject, Selection, "Priority, Queue");
			OrderObject.DataExchange.Load = True;
			OrderObject.Write(DocumentWriteMode.Write);
			
			If PriorityChanged Then
				UniversalQueueOfRealTimeJobs.ProcessTask_(CurrentOrder, Enums.UniversalQueueTasks.UpdatePriorityInProductionStages);
			EndIf;
			
			If OrderObject.DynamicStructure Then
				UniversalQueueOfRealTimeJobs.ProcessTask_(CurrentOrder, Enums.UniversalQueueTasks.UpdateOrderStructureWhenQueuePlaceIsChanged);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorTemplate = NStr("vi = 'Không thể ghi %Document%. %ErrorDescription%';
								|ru = 'Не удалось записать %Document%. %ErrorDescription%';
								|en = 'Failed to save %Document%. %ErrorDescription%'; fa = 'Failed to save %Document%. %ErrorDescription%';
								|it = 'Non è stato possibile registrare %Document%. %ErrorDescription%';
								|pl = 'Nie udało się zapisać %Document%. %ErrorDescription%';
								|tr = '%Document% kaydedilemedi. %ErrorDescription%'");
			
			ErrorText = StrReplace(ErrorTemplate, "%Document%", CurrentOrder);
			ErrorText = StrReplace(ErrorText, "%ErrorDescription%", BriefErrorDescription(ErrorInfo()));
			
			Common.MessageToUser(ErrorText, CurrentOrder);
			Return;
			
		EndTry
		
	EndIf;
	
EndProcedure

// Calculates the queue number to insert before documents
//
// Parameters:
//  Orders - Array - Production order.
//
// Returns:
//   - Number - the number of the queue to insert before the documents.
//
Function QueueNumberToInsertBeforeDocuments(Orders) Export
	
	Query = New Query(
		"SELECT
		|	Boundary.Priority     AS Priority,
		|	Boundary.Department AS Department,
		|	Boundary.Status        AS Status,
		|	Boundary.Queue       AS Queue
		|INTO TTBorder
		|FROM
		|	Document.ProductionOrder2_2 AS Boundary
		|WHERE
		|	Boundary.Ref IN
		|			(SELECT TOP 1
		|				T.Ref AS Ref
		|			FROM
		|				Document.ProductionOrder2_2 AS T
		|			WHERE
		|				T.Ref IN (&Orders)
		|				AND T.Status = &StatusForProduction
		|				AND T.Posted
		|			ORDER BY
		|				-T.Priority.AddlOrderingAttribute DESC,
		|				T.Department.AddlOrderingAttribute,
		|				T.Queue)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE WHEN T.QueueAverage = T.QueueMinimum THEN
		|		T.QueueMinimum / 2
		|	ELSE
		|		T.QueueAverage
		|	END AS QueueNumber
		|
		|FROM
		|	(SELECT
		|		MIN(T.Queue)  AS QueueMinimum,
		|		AVG(T.Queue)  AS QueueAverage,
		|		MAX(T.Queue) AS QueueMaximum
		|	FROM
		|		(SELECT TOP 2
		|			ProductionOrder.Queue AS Queue
		|
		|		FROM
		|			Document.ProductionOrder2_2 AS ProductionOrder
		|
		|				INNER JOIN TTBorder AS Boundary
		|
		|				ON ProductionOrder.Priority        = Boundary.Priority
		|					AND ProductionOrder.Department = Boundary.Department
		|					AND ProductionOrder.Status        = Boundary.Status
		|					AND ProductionOrder.Queue      <= Boundary.Queue
		|					AND ProductionOrder.Posted
		|	
		|		ORDER BY
		|			Queue DESC
		|		) AS T
		|	) AS T
		|
		|WHERE
		|	NOT CASE WHEN T.QueueAverage = T.QueueMaximum THEN
		|		T.QueueAverage + 1
		|	ELSE
		|		T.QueueAverage
		|	END IS NULL");
	
	Query.SetParameter("Orders",              Orders);
	Query.SetParameter("StatusForProduction", StatusOfProductionOrder());
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	QueueNumber = 0;
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		QueueNumber = Selection.QueueNumber;
		
	EndIf;
	
	Return QueueNumber;

EndFunction

// Returns the order queue for scheduling for the specified order
//
// Parameters:
//  CurrentOrder			 - DocumentRef.ProductionOrder2_2 - current order
//  ProductionDispatcherBusinessUnit	 - CatalogRef.BusinessStructure - for which Department-dispatcher you need to get the order queue.
//
// Returns:
//   - Array - planning queue.
//
Function PlanningQueue(CurrentOrder, ProductionDispatcherBusinessUnit = Undefined) Export
	
	Query = New Query( 
		"SELECT ALLOWED
		|	ProductionOrder.Ref AS Ref
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrder
		|		INNER JOIN Document.ProductionOrder2_2 AS CurProductionOrder
		|		ON (CurProductionOrder.Ref = &CurrentOrder)
		|			AND (ProductionOrder.Posted)
		|			AND (ProductionOrder.Status = &StatusForProduction)
		|			AND (NOT &ThereIsSelectionByDivision
		|				OR &ThereIsSelectionByDivision
		|					AND ProductionOrder.Department = CurProductionOrder.Department)
		|			AND (ProductionOrder.Priority.AddlOrderingAttribute < CurProductionOrder.Priority.AddlOrderingAttribute
		|				OR NOT &ThereIsSelectionByDivision
		|					AND ProductionOrder.Priority.AddlOrderingAttribute = CurProductionOrder.Priority.AddlOrderingAttribute
		|					AND ProductionOrder.Department.AddlOrderingAttribute < CurProductionOrder.Department.AddlOrderingAttribute
		|				OR ProductionOrder.Priority.AddlOrderingAttribute = CurProductionOrder.Priority.AddlOrderingAttribute
		|					AND (&ThereIsSelectionByDivision
		|						OR NOT &ThereIsSelectionByDivision
		|							AND ProductionOrder.Department.AddlOrderingAttribute = CurProductionOrder.Department.AddlOrderingAttribute)
		|					AND ProductionOrder.Queue <= CurProductionOrder.Queue)
		|
		|ORDER BY
		|	ProductionOrder.Priority.AddlOrderingAttribute,
		|	ProductionOrder.Department.AddlOrderingAttribute,
		|	ProductionOrder.Queue");
	
	Query.SetParameter("CurrentOrder", CurrentOrder);
	Query.SetParameter("StatusForProduction", StatusOfProductionOrder());
	
	Query.SetParameter("ProductionDispatcherBusinessUnit", ProductionDispatcherBusinessUnit);
	Query.SetParameter("ThereIsSelectionByDivision", ValueIsFilled(ProductionDispatcherBusinessUnit));
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Creates a temporary table with orders that have a higher priority than the specified order.
// Selected completed documents in all statuses except Completed/Closed.
//
// Parameters:
//  TempTablesManager - TempTablesManager - the Manager where
//		the generated temporary table will be placed.
//  TempTableName	- String - name of the generated temporary table.
//  OrderDocument - DocumentRef.ProductionOrder2_2 - an order that you want to get
//		higher priority orders for.
//
Procedure CreateTTOrdersWithHighPriority(TempTablesManager, TempTableName, OrderDocument) Export
	
	QueryText =
	"SELECT
	|	ProductionOrder2_2.Priority.AddlOrderingAttribute AS PriorityNumber,
	|	ProductionOrder2_2.Department.AddlOrderingAttribute AS DivisionNumber,
	|	ProductionOrder2_2.Queue AS Queue
	|INTO TTOrderData_
	|FROM
	|	Document.ProductionOrder2_2 AS ProductionOrder2_2
	|WHERE
	|	ProductionOrder2_2.Ref = &OrderDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductionOrder2_2.Ref AS Ref
	|INTO TTOrdersWithHighPriority
	|FROM
	|	Document.ProductionOrder2_2 AS ProductionOrder2_2
	|		LEFT JOIN TTOrderData_ AS TTOrderData_
	|		ON (TRUE)
	|WHERE
	|	ProductionOrder2_2.Posted
	|	AND ProductionOrder2_2.Status <> VALUE(Enum.StatusesOfProductionStages2_2.Completed)
	|	AND (ProductionOrder2_2.Priority.AddlOrderingAttribute < TTOrderData_.PriorityNumber
	|			OR ProductionOrder2_2.Priority.AddlOrderingAttribute = TTOrderData_.PriorityNumber
	|				AND ProductionOrder2_2.Department.AddlOrderingAttribute < TTOrderData_.DivisionNumber
	|			OR ProductionOrder2_2.Priority.AddlOrderingAttribute = TTOrderData_.PriorityNumber
	|				AND ProductionOrder2_2.Department.AddlOrderingAttribute = TTOrderData_.DivisionNumber
	|				AND ProductionOrder2_2.Queue < TTOrderData_.Queue)
	|";
	
	QueryText = StrReplace(QueryText, "TTOrdersWithHighPriority", TempTableName);
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("OrderDocument", OrderDocument);
	
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
EndProcedure

// Checks for conflicts in the order queue when the order is provided with the expected receipts 
// of a lower priority order.
//
// Returns:
//  Boolean - True if there are conflicts, False if there are no conflicts.
//
Function ThereAreConflictsInQueue() Export
	
	SetPrivilegedMode(True);
	Query = New Query(
		"SELECT TOP 1
		|	TRUE AS ThereAreRecords
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	InventoryAllocation.InventoryState IN(
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock))
		|	AND InventoryAllocation.ShipmentOrder REFS Document.ProductionStage2_2
		|	AND InventoryAllocation.ReceiptOrder REFS Document.ProductionStage2_2
		|	AND TRUE IN (
		|			SELECT TOP 1 TRUE
		|			FROM
		|				Document.ProductionStage2_2 AS ReceiptOrder
		|					LEFT JOIN Document.ProductionStage2_2 AS ShipmentOrder
		|					ON TRUE
		|			WHERE
		|				ReceiptOrder.Ref = InventoryAllocation.ReceiptOrder
		|				AND ReceiptOrder.ReferenceOrder.Posted
		|				AND ReceiptOrder.ReferenceOrder.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|				AND ShipmentOrder.Ref = InventoryAllocation.ShipmentOrder
		|				AND ShipmentOrder.ReferenceOrder.Posted
		|				AND ShipmentOrder.ReferenceOrder.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|				AND (
		|					ReceiptOrder.ReferenceOrder.Priority.AddlOrderingAttribute > ShipmentOrder.ReferenceOrder.Priority.AddlOrderingAttribute
		|					OR ReceiptOrder.ReferenceOrder.Priority.AddlOrderingAttribute = ShipmentOrder.ReferenceOrder.Priority.AddlOrderingAttribute
		|						AND ReceiptOrder.ReferenceOrder.Department.AddlOrderingAttribute > ShipmentOrder.ReferenceOrder.Department.AddlOrderingAttribute
		|					OR ReceiptOrder.ReferenceOrder.Priority.AddlOrderingAttribute = ShipmentOrder.ReferenceOrder.Priority.AddlOrderingAttribute
		|						AND ReceiptOrder.ReferenceOrder.Department.AddlOrderingAttribute = ShipmentOrder.ReferenceOrder.Department.AddlOrderingAttribute
		|						AND ReceiptOrder.ReferenceOrder.Queue > ShipmentOrder.ReferenceOrder.Queue))");
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region SeparationSchemes

// Creates a temporary table of product separation schemes in production
//
// Parameters:
//  TempTablesManager	 - TempTablesManager	 - temporary table Manager
//  References			 - Array					 - list of production orders.
//
Procedure CreateTTIsolationSchemesInProduction(TempTablesManager, References) Export
	
	QueryText = TextOfRequestForSeparationSchemeByOrder(True);
	QueryText = QueryText + " INDEX BY ReferenceOrder, Purpose ";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	Query.Execute();
	
EndProcedure

// Gets product separation schemes for a production order
//
// Parameters:
//  References - Array	 - list of production orders.
//
// Returns:
//   Map of KeyAndValue:
//    * ReferenceOrder - DocumentRef.ProductionOrder2_2 - production order
//    * Purpose   - CatalogRef.Assignments - the purpose of the production of the manufacturing order.
//
//    * WithAssignment - Boolean - It is true if the production process should be divided by purpose.
//
//    * AssignmentProducts - CatalogRef.Assignments - accounting separator (intended use of products)
//    * AssignmentMaterials - CatalogRef.Assignments - the purpose of separate provision of stages with materials and works.
//
Function OrderSeparationSchemes(References) Export
	
	QueryText = TextOfRequestForSeparationSchemeByOrder();
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	SeparationSchemes = New Map;
	
	While Selection.Next() Do
		
		If SeparationSchemes[Selection.ReferenceOrder] = Undefined Then
			SeparationSchemes.Insert(Selection.ReferenceOrder, New Map);
		EndIf;
		
		SeparationSchemes[Selection.ReferenceOrder].Insert(Selection.Purpose, CreateSeparationScheme(Selection));
		
	EndDo;
	
	Return SeparationSchemes;
	
EndFunction

// Gets the scheme for separating the products of the production order
//
// Parameters:
//  ReferenceOrder		 - DocumentRef.ProductionOrder2_2 - production order
//  AssignmentProducts	 - CatalogRef.Assignments			 - the purpose of the production of the manufacturing order.
//
// Returns:
//  See CreateSeparationScheme
//
Function IsolationScheme(ReferenceOrder, AssignmentProducts) Export
	
	QueryText = RequestTextForIntendedSeparationScheme();
	Query = New Query(QueryText);
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("Purpose",   AssignmentProducts);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Selection.Next();
	
	IsolationScheme = CreateSeparationScheme(Selection);
	Return IsolationScheme;
	
EndFunction

#EndRegion

#Region ReplacingSpecifications

// Performs replacement of specifications in production orders.
//  - replacement of specifications for semi-finished products produced in the process is not supported.
//
// Parameters:
//  ReplacementData - See SpecificationReplacementData
//
// Returns:
//   Structure - replacement result:
//    * HasErrors     - Boolean -
//    * TotalReplacements     - Number -
//    * ReplacementsPerformed - Number -
//
Function ReplaceSpecificationsWithoutControl(ReplacementData) Export
	
	ReplacementsPerformed = 0;
	TotalReplacements = ReplacementData.Count();
	
	Query = New Query("
	|SELECT
	|
	|	Substitutions_3.Products        AS Products,
	|	Substitutions_3.Characteristic      AS Characteristic,
	|	Substitutions_3.Warehouse               AS Warehouse,
	|	Substitutions_3.Purpose          AS Purpose,
	|	Substitutions_3.ProductionOrder AS ProductionOrder,
	|	Substitutions_3.BillOfMaterials        AS BillOfMaterials
	|
	|INTO ReplacementData
	|FROM 
	|	&ReplacementData AS Substitutions_3
	|
	|INDEX BY
	|
	|	ProductionOrder,
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose
	|;
	|
	|SELECT
	|
	|	Substitutions_3.ProductionOrder AS ProductionOrder,
	|
	|	Substitutions_3.Products        AS Products,
	|	Substitutions_3.Characteristic      AS Characteristic,
	|	Substitutions_3.Warehouse               AS Warehouse,
	|	Substitutions_3.Purpose          AS Purpose,
	|
	|	CASE
	|		WHEN TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Document.ProductionOrder2_2.ManufacturedProduct AS DD
	|			WHERE
	|				DD.Ref           = Substitutions_3.ProductionOrder
	|				AND DD.Products   = Substitutions_3.Products
	|				AND DD.Characteristic = Substitutions_3.Characteristic
	|				AND DD.Warehouse          = Substitutions_3.Warehouse
	|				AND DD.Purpose     = Substitutions_3.Purpose
	|				AND NOT DD.Canceled)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsOutput_,
	|
	|	Substitutions_3.BillOfMaterials        AS BillOfMaterials
	|
	|FROM
	|	ReplacementData AS Substitutions_3
	|
	|ORDER BY
	|	ProductionOrder
	|");
	Query.SetParameter("ReplacementData", ReplacementData);
	
	Selection = Query.Execute().Select();
	
	RowsGroups = New Structure("ManufacturedProduct, SemiFinishedProducts", SpecificationReplacementData(), SpecificationReplacementData());
	
	ThereAreRecordsInSelection = Selection.Next();
	While ThereAreRecordsInSelection Do
		
		ProductionOrder = Selection.ProductionOrder;
		
		While ThereAreRecordsInSelection And ProductionOrder = Selection.ProductionOrder Do
			
			FillPropertyValues(?(Selection.ThisIsOutput_, RowsGroups.ManufacturedProduct, RowsGroups.SemiFinishedProducts).Add(), Selection);
			ThereAreRecordsInSelection = Selection.Next();
			
		EndDo;
		
		If RowsGroups.SemiFinishedProducts.Count() > 0 Then
			
			ReplacementsPerformed = ReplacementsPerformed + OrderStructureInternal.ReplaceSpecifications(RowsGroups.SemiFinishedProducts);
			RowsGroups.SemiFinishedProducts.Clear();
			
		EndIf;
		
		If RowsGroups.ManufacturedProduct.Count() > 0 Then
			
			ReplacementsPerformed = ReplacementsPerformed + ReplaceProductSpecifications(ProductionOrder, RowsGroups.ManufacturedProduct);
			RowsGroups.ManufacturedProduct.Clear();
			
		EndIf;
		
	EndDo;
	
	If ReplacementsPerformed > 0
		And GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		OrderStructure.StartCalculation();
	EndIf;
	
	Result = New Structure("HasErrors, TotalReplacements, ReplacementsPerformed", ReplacementsPerformed <> TotalReplacements, TotalReplacements, ReplacementsPerformed);
	
	Return Result;
	
EndFunction

// Performs replacement of specifications for products in the production order.
//
// Parameters:
// 
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - production order
//  ReplacementData - 	Array, ValueTable - LongDesc:
//    * Products - CatalogRef.Products - Nomenclature.
//    * Characteristic - CatalogRef.ItemsCharacteristics - characteristic.
//    * Warehouse - CatalogRef.Warehouses - warehouse.
//    * Purpose - CatalogRef.Assignments - purpose.
//    * BillOfMaterials - CatalogRef.BillsOfMaterials - new specification.
//
// Returns:
//   Number - the number of substitutions performed.
Function ReplaceProductSpecifications(ProductionOrder, ReplacementData) Export
	
	ReplacementStructure = New Structure("Products,Characteristic,Warehouse,Purpose");
	
	SubstitutionsCompleted = 0;
	
	BeginTransaction();
	Try
		
		LockDataForEdit(ProductionOrder);
		
		OrderObject = ProductionOrder.GetObject();
		
		If OrderObject = Undefined Then
			MessageText = StrTemplate(NStr("vi = 'Không tìm thấy %1 đơn hàng.';
											|ru = 'Заказ %1 не найден.';
											|en = 'The %1 order is not found.'; fa = 'The %1 order is not found.';
											|it = 'Ordine %1 non trovato.';
											|pl = 'Zamówienie %1 nie zostało znalezione.';
											|tr = '%1 siparişi bulunamadı.'"), ProductionOrder);
			Raise MessageText;
		EndIf;
		
		OrderChanged = False;
		
		For Each Replacement In ReplacementData Do
			
			FillPropertyValues(ReplacementStructure, Replacement);
			
			FoundRows = OrderObject.ManufacturedProduct.FindRows(ReplacementStructure);
			
			For Each FoundRow In FoundRows Do
				
				If FoundRow.BillOfMaterials = Replacement.BillOfMaterials Then
					Continue;
				EndIf;
				
				FoundRow.BillOfMaterials = Replacement.BillOfMaterials;
				
				OrderChanged = True;
				
			EndDo;
			
			SubstitutionsCompleted = SubstitutionsCompleted + 1;
			
		EndDo;
		
		ReplacementCompleted = False;
		
		If Not OrderChanged Then
			
			ReplacementCompleted = True;
			
		Else
			
			If OrderObject.CheckFilling() Then
				
				If OrderObject.Posted Then
					OrderObject.Write(DocumentWriteMode.Posting);
				Else
					OrderObject.Write(DocumentWriteMode.Write);
				EndIf;
				
				ReplacementCompleted = True;
				
			EndIf;
			
		EndIf;
		
		If Not ReplacementCompleted Then
			MessageText = NStr("vi = 'Khi kiểm tra điền đã tìm thấy lỗi.';
								|ru = 'При проверке заполнения были найдены ошибки.';
								|en = 'Errors were found while checking the filling.'; fa = 'Errors were found while checking the filling.';
								|it = 'Durante la verifica della compilazione sono stati rilevati degli errori.';
								|pl = 'Podczas sprawdzenia wypełnienia zostały znalezione błędy.';
								|tr = 'Doldurma kontrol edilirken hatalar bulundu.'");
			Raise MessageText;
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		EventLogEvent = ProductionServer.EventReplacementOfSpecifications();
		
		MessageText = StrTemplate(NStr("vi = 'Không thể thay thế bảng kê chi tiết trong đơn hàng sản xuất: %1 do nguyên nhân: %2';
										|ru = 'Не удалось заменить спецификации в заказе на производство: %1 по причине: %2';
										|en = 'Cannot replace the bills of materials in the production order: %1 due to: %2'; fa = 'Cannot replace the bills of materials in the production order: %1 due to: %2';
										|it = 'Non è stato possibile sostituire le specifiche nell''ordine di produzione: %1 a causa di: %2';
										|pl = 'Nie udało się zmienić specyfikacji w zleceniu produkcyjnym: %1 z powodu: %2';
										|tr = 'Üretim emrindeki ürün reçetesi değiştirilemedi: %1 çünkü: %2'"),
							ProductionOrder,
							DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(EventLogEvent, EventLogLevel.Error, ProductionOrder.Metadata(), ProductionOrder, MessageText);
		
		SubstitutionsCompleted = 0;
		
	EndTry;
	
	Return SubstitutionsCompleted;
	
EndFunction

// Data Structure Constructor for performing specification replacement
// 
// Returns:
// 	ValueTable - LongDesc:
// * ProductionOrder - DocumentRef.ProductionOrder2_2 - production order.
// * Products - CatalogRef.Products - Nomenclature.
// * Characteristic - CatalogRef.ItemsCharacteristics - characteristic.
// * Warehouse - CatalogRef.Warehouses - warehouse.
// * Purpose - CatalogRef.Assignments - purpose.
// * BillOfMaterials - CatalogRef.BillsOfMaterials - new specification.
Function SpecificationReplacementData() Export
	
	Result = New ValueTable();
	
	Result.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	
	// nomenclature analytics
	
	Result.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Result.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Result.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	Result.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	// new specification
	
	Result.Columns.Add("BillOfMaterials", New TypeDescription("CatalogRef.BillsOfMaterials"));
	
	Return Result;
	
EndFunction

#EndRegion

#Region StageManagement

// This function checks whether you need to specify stages for orders
//
// Parameters:
//  Orders - DocumentRef.ProductionOrder2_2, Array - Production order.
//
// Returns:
//  Boolean - True - it is necessary to clarify the stages.
//
Function NeedToClarifySteps(Orders) Export
	
	Return Documents.ProductionStage2_2.NeedToClarifySteps(Orders);
	
EndFunction

// This function checks whether you need to create stages based on the specification for production orders
//
// Parameters:
//  References - Array	 - Production order.
//
// Returns:
//  Boolean - Truth - it is required to form stages.
//
Function ItIsRequiredToFormStagesAccordingToSpecification(References) Export
	
	TempTablesManager = New TempTablesManager;
	CreateTTDataToGenerateStages(TempTablesManager, References);
	
	Query = New Query(
	"SELECT TOP 1
	|	Orders.Ref AS Ref
	|FROM
	|	Document.ProductionOrder2_2 AS Orders
	|WHERE
	|	Orders.Ref IN
	|			(SELECT TOP 1
	|				Table.ReferenceOrder
	|			FROM
	|				TTDataForGeneratingStages AS Table
	|			WHERE
	|				Table.ReferenceOrder = Orders.Ref
	|				AND Table.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|				AND Table.Count > 0)
	|	AND Orders.Status IN (VALUE(Enum.ProductionOrderStatuses2_2.ToProduce))
	|");
	Query.TempTablesManager = TempTablesManager;
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region DocumentStatus

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
	
	If TypeOf(NewStatus) = Type("String") Then
		MeaningOfNewStatus = Enums.ProductionOrderStatuses2_2[NewStatus];
	Else
		MeaningOfNewStatus = NewStatus;
	EndIf;
	
	If AdditionalParameters <> Undefined
		And AdditionalParameters.Property("OrderFulfillmentControl") Then
		MonitorOrderFulfillment = GetFunctionalOption("DoNotCloseProductionOrdersWithoutFullProcessing");
	Else
		MonitorOrderFulfillment = False;
	EndIf;
	
	OrdersByStructureType = SplitArrayOfOrdersDependingOnStructure(DocumentsArray);
	
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
	|	TRUE AS Recording,
	|	&OrderClosingControl AS ThereAreLeftoversOnOrder,
	|	&ControlOfCostAllocation AS ThereAreCostsAfterRelease
	|FROM
	|	Document.ProductionOrder2_2 AS DocumentsTable,
	|	&ConnectionOrderClosingControl,
	|	&EffectiveControlOfCostAllocation
	|WHERE
	|	DocumentsTable.Ref IN(&ReferencesArrray)
	|";
	If MeaningOfNewStatus = Enums.ProductionOrderStatuses2_2.ToProduce Then
		QueryText = QueryText + "
		|
		|ORDER BY
		|	DocumentsTable.DemandDate
		|";
	EndIf;
	
	QueryText = StrReplace(QueryText, "AS DocumentsTable,", "AS DocumentsTable");
	
	PerformSubstitutionRequestTextOrderClosingControl(QueryText, MonitorOrderFulfillment, OrdersByStructureType);
	PerformQueryTextSubstitutionCostAllocationControl(QueryText);
	
	Query = New Query(QueryText);
	
	AllowableVariance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving", AllowableVariance);
	
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("ReferencesArrray", DocumentsArray);
	Query.SetParameter("ArrayOfLinksStaticOrders", OrdersByStructureType.StaticOrders);
	Query.SetParameter("ArrayOfLinksDynamicOrders", OrdersByStructureType.DynamicOrders);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef.ProductionOrderStatuses2_2 - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If Not AdditionalParameters = Undefined
		And AdditionalParameters.Property("OrderFulfillmentControl")
		And ValidationSample.ThereAreLeftoversOnOrder Then
		
		ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"" chưa được đặt, bởi vì đơn hàng chưa hoàn thành';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ отработан не полностью';
						|en = 'The ""%Status%"" status of the %Document% document is not set as the order is not fully processed'; fa = 'The ""%Status%"" status of the %Document% document is not set as the order is not fully processed';
						|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché l''ordine non è elaborato completamente';
						|pl = 'W dokumencie %Document% nie ustawiono statusu ""%Status%"", ponieważ zamówienie zrealizowano nie w całości';
						|tr = 'Sipariş tümüyle işlenmediğinden dolayı %Document% belgesinde ""%Status%"" durumu ayarlanmadı'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	If ValidationSample.ThereAreCostsAfterRelease Then
		
		ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"" chưa được đặt, bởi vì có những chi phí không có đầu ra muộn hơn so với phân bổ của chúng.';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. есть затраты, для которых нет выпуска продукции позже их отнесения.';
						|en = '%Document% status is not set in the %Status% document, as there are costs for which there is no product release after their allocation.'; fa = '%Document% status is not set in the %Status% document, as there are costs for which there is no product release after their allocation.';
						|it = 'Per il documento %Document% lo stato ""%Status%"" non è impostato in quanto esistono spese per le quali non ci sono prodotti emessi successivamente alla loro attribuzione.';
						|pl = 'Dla dokumentu %Document% nie ustawiono statusu ""%Status%"", ponieważ są rozchody, dla których nie wypuszczono produkcji po ich przypisaniu.';
						|tr = 'Tahsis edildikten sonra ürün çıkışı olmayan giderler olduğundan dolayı %Document% belgesinde ""%Status%"" durumu ayarlanmadı.'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		Common.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

#EndRegion

#Region Presentation

// Generates a view of the production order.
// Format: "Order no. %1 from %2".
//
// Parameters:
//  Ref	 - DocumentRef.ProductionOrder2_2 - production order
//  Prefix	 - String								 - prefix.
//  OrderData	 - Structure					 - order number and date.
//
// Returns:
//  String - submission of a production order.
//
Function OrderPresentation(Ref, Val Prefix = Undefined, Val OrderData = Undefined) Export
	
	If OrderData = Undefined Then
		OrderData = Common.ObjectAttributesValues(Ref, "Number,Date");
	EndIf;

	OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(OrderData.Number, False, True);
	OrderNumber = TrimAll(OrderNumber);
	
	PrefixPattern = ?(Prefix <> Undefined, Prefix, NStr("vi = 'Đơn hàng';
														|ru = 'Заказ';
														|en = 'Order'; fa = 'سفارش';
														|it = 'Ordine';
														|pl = 'Zamówienie';
														|tr = 'Sipariş'"));
	Template = PrefixPattern + ?(IsBlankString(PrefixPattern),""," ") + NStr("vi = 'Số %1 ngày %2';
																			|ru = '№ %1 от %2';
																			|en = 'No. %1 from %2'; fa = 'No. %1 from %2';
																			|it = '№ %1 da %2';
																			|pl = 'Nr %1 z dnia %2';
																			|tr = '%2 tarihli %1 numaralı'");
	
	OrderDate  = Format(OrderData.Date, "DLF=D");
	
	Return StrTemplate(Template, OrderNumber, OrderDate);
	
EndFunction

// Generates a complete view of the production order.
// Format: "Order no. %1 from %2, need date %3".
//
// Parameters:
//  Ref	 - DocumentRef.ProductionOrder2_2 - production order
//
// Returns:
//  String - full presentation of the production order.
//
Function FullOrderPresentation(Ref) Export
	
	OrderData = Common.ObjectAttributesValues(Ref,"Number,Date,DemandDate,DemandDateIsSpecifiedInLines");
	
	OrderNumber = ObjectsPrefixesClientServer.NumberForPrinting(OrderData.Number, False, True);
	OrderNumber = TrimAll(OrderNumber);
	
	If OrderData.DemandDateIsSpecifiedInLines Then
		OrderPresentation = StrTemplate(NStr("vi = 'Đơn hàng số %1 ngày %2, ngày nhu cầu %3';
											|ru = 'Заказ № %1 от %2, дата потребности %3';
											|en = 'Order No. %1 from %2, demand date %3'; fa = 'Order No. %1 from %2, demand date %3';
											|it = 'Заказ № %1 от %2, дата потребности %3';
											|pl = 'Order No. %1 from %2, demand date %3';
											|tr = '%2 tarihli %1 numaralı, gereksinim tarihi %3'"), OrderNumber, Format(OrderData.Date, "DLF=D"), Format(OrderData.DemandDate, "DLF=D"));
	Else
		OrderPresentation = StrTemplate(NStr("vi = 'Đơn hàng số %1 ngày %2';
											|ru = 'Заказ № %1 от %2';
											|en = 'Order No. %1 from %2'; fa = 'Order No. %1 from %2';
											|it = 'Заказ № %1 от %2';
											|pl = 'Order No. %1 from %2';
											|tr = '%2 itibarıyla %1 numaralı sipariş'"), OrderNumber, Format(OrderData.Date, "DLF=D"));
	EndIf; 
	
	Return OrderPresentation;
	
EndFunction

#EndRegion

#Region Other

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department,Organization", Parameters);
	
EndProcedure

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn hàng sản xuất';
		|ru = 'Заказ на производство';
		|en = 'Production order'; fa = 'سفارش تولید';
		|it = 'Ordine di produzione';
		|pl = 'Zlecenie produkcyjne';
		|tr = 'Üretim emri'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("Number");
	Result.Add("Department");
	Result.Add("ProductionProcessType");
	
	Result.Add("Organization");
	Result.Add("OrderForActivity");
	Result.Add("LineOfBusiness");
	
	Result.Add("AssignmentProducts");
	
	Result.Add("BusinessOperation");
	Result.Add("Partner");
	Result.Add("Contract");
	
	Result.Add("MethodOfAllocatingFinishedProductCosts");
	
	Result.Add("ConsolidatedOrderByProductAssignments");
	
	Return Result;
	
EndFunction

// Determines whether you have access rights to add a document
//
// Returns:
//   - Boolean - True if there is an access right to add.
//
Function AccessRightInsert() Export
	
	Return AccessRight("Insert", Metadata.Documents.ProductionOrder2_2);
	
EndFunction

// Determines whether you have access rights to change the document
//
// Returns:
//   - Boolean - True if there is an access right to change.
//
Function AccessRightUpdate() Export
	
	Return AccessRight("Update", Metadata.Documents.ProductionOrder2_2);
	
EndFunction

// Determines whether the "manage queue order Production" access right is available for the current user.
//
// Returns:
//   - Boolean - True if queue management is available.
//
Function QueueManagementIsAvailable() Export
	
	Return AccessRight("View", Metadata.CommonCommands.ManagementOfProductionOrderQueue);
	
EndFunction

// This function checks whether the production order stages are scheduled
//
// Parameters:
//  Ref - DocumentRef.ProductionOrder2_2 - production order.
//
// Returns:
//  Boolean - True if the order is scheduled.
//
Function OrderScheduled(Ref) Export
	
	ReferencesArrray = CommonClientServer.ValueInArray(Ref);
	Return OrdersAreScheduled(ReferencesArrray)[Ref];
	
EndFunction

// The function checks whether the stages of production orders are scheduled
//
// Parameters:
//  ReferencesArrray - Array - Production order.
//
// Returns:
//  Map - matching the status of orders.
//
Function OrdersAreScheduled(ReferencesArrray) Export
	
	Query = New Query(
	"SELECT
	|	ProductionOrders.Ref AS Ref,
	|	CASE
	|		WHEN TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Document.ProductionStage2_2 AS Stages
	|				WHERE
	|					Stages.ReferenceOrder = ProductionOrders.Ref
	|					AND Stages.Posted)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Planned_
	|FROM
	|	Document.ProductionOrder2_2 AS ProductionOrders
	|WHERE
	|	ProductionOrders.Ref IN (&ReferencesArrray)");
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Result = New Map;

	While Selection.Next() Do
		Result.Insert(Selection.Ref, Selection.Planned_);
	EndDo;
	
	Return Result;
	
EndFunction

// The function calculates the number of production orders based on the selection structure
//
// Parameters:
//  FiltersStructure - Structure - Selection structure
//   *Status
//   *Division
//   *Priority
//   *Responsible.
//
// Returns:
//   - Number - The number of orders in a certain status.
//
Function OrdersCount(FiltersStructure = Undefined) Export
	
	OrdersCount = 0;
	
	Query = New Query;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText("
		|SELECT
		|	COUNT(Orders.Ref) AS Count
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	Orders.Posted");
		
	OrderSelectionOperator = QuerySchema.QueryBatch[0].Operators[0];
	
	If FiltersStructure.Property("Status") Then
		
		Query.SetParameter("Status", FiltersStructure.Status);
		OrderSelectionOperator.Filter.Add("Status = &Status");
		
	EndIf;
	
	If FiltersStructure.Property("Department") Then
		
		Query.SetParameter("Department", FiltersStructure.Department);
		OrderSelectionOperator.Filter.Add("Department = &Department");
		
	EndIf;
	
	If FiltersStructure.Property("Priority") Then
		
		Query.SetParameter("Priority", FiltersStructure.Priority);
		OrderSelectionOperator.Filter.Add("Priority = &Priority");
		
	EndIf;
	
	If FiltersStructure.Property("EmployeeResponsible") Then
		
		Query.SetParameter("EmployeeResponsible", FiltersStructure.EmployeeResponsible);
		OrderSelectionOperator.Filter.Add("EmployeeResponsible = &EmployeeResponsible");
		
	EndIf;
	
	Query.Text = QuerySchema.GetQueryText();
	
	SetPrivilegedMode(True);
	
	QueryResult = Query.Execute();
	
	SetPrivilegedMode(False);
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		OrdersCount = Selection.Count;
		
	EndIf;
	
	Return OrdersCount;
	
EndFunction

// Generates an array of production orders that match the search parameters
//
// Parameters:
//  Text	 - String	 - the text of the search.
//  FilterStructure1 - Structure
//
// Returns:
//  Array - an array containing production orders.
//
Function AutoSelectionOfProductionOrders(Text, FilterStructure1 = Undefined) Export
	
	Query = New Query(
	"SELECT TOP 7
	|	Table.Ref AS Ref
	|FROM
	|	Document.ProductionOrder2_2 AS Table
	|WHERE
	|	NOT Table.DeletionMark
	|	AND Table.Number LIKE &Text
	|	AND &Filter
	|
	|ORDER BY
	|	Table.Date DESC, Table.Ref");
	Query.SetParameter("Text", "%" + Text + "%");
	
	FilterText1 = "";
	If ValueIsFilled(FilterStructure1) Then
		For Each KeyAndValue In FilterStructure1 Do
			FilterText1 = FilterText1
						  + ?(ValueIsFilled(FilterText1), "And ", "")
						  + "Table."+KeyAndValue.Key + " IN (&"+KeyAndValue.Key + ") ";
			Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&Filter", ?(ValueIsFilled(FilterText1), FilterText1, "TRUE"));
	
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.ManufacturedProduct.Purpose");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.AssignmentProducts");
	DestinationPattern.TermsOfUse_     = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
	
	// Needs for products in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.ManufacturedProduct.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProduct.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProduct.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProduct.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.ManufacturedProduct.Warehouse";
	
	// The needs for the work performed in the recipient unit.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.ManufacturedProduct.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProduct.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProduct.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProduct.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.ManufacturedProduct.Department";
	
	// Product needs in all warehouses.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "SecuringOrdersAllWarehouses", True, "Object.ManufacturedProduct.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.ManufacturedProduct.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.ManufacturedProduct.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.ManufacturedProduct.Characteristic";
	
	// All assignments for the Assignationproduction field in the document header.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.AssignmentProducts");
	
	Return FormTemplate;
	
EndFunction

// Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	BOMSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	BOMSelectionParameters.SideOutputSpecificationsAreAvailable = True;
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	
	ChoiceParameterLinks.Products            = "Object.ManufacturedProduct.Products";
	ChoiceParameterLinks.Characteristic          = "Object.ManufacturedProduct.Characteristic";
	ChoiceParameterLinks.ProductionStart      = "Object.EarliestStartDate";
	ChoiceParameterLinks.ProductionDispatcherBusinessUnit  = "Object.Department";
	ChoiceParameterLinks.LineOfBusiness = "Object.LineOfBusiness";
	ChoiceParameterLinks.UnderRepairProduct   = "Object.UnderRepairProduct";
	ChoiceParameterLinks.UnderRepairVariant = "Object.UnderRepairVariant";
	
	BOMSelectionParameters.ChoiceParameterLinks.Insert("Object.ManufacturedProduct.BillOfMaterials", ChoiceParameterLinks);
	
	Return BOMSelectionParameters;
	
EndFunction

// The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "ProductionProcessType";
	Return AttributesNames;
	
EndFunction

// Initializes the parameters for filling in the VAT activity type.
//
// Parameters:
//  Object	 - DocumentObject.ProductionOrder2_2, FormDataStructure	 - the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization             = Object.Organization;
	FillParameters.Date                    = Object.Date;
	FillParameters.Warehouse                   = Undefined;
	FillParameters.Contract                 = Undefined;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	
	FillParameters.OutputOfProductsAndWorks = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of cost allocation.
//
// Returns:
//  Structure - parameters specifying the specifics of the distribution of costs for output products.
//
Function CostAllocationParameters(Object) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts("ManufacturedProduct", Object.MethodOfAllocatingFinishedProductCosts);
	
	CostAllocationParameters.ThereIsFieldCanceled = True;
	
	CostAllocationParameters.CalculateShareCostPercentageField = True;
	CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
	CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
	CostAllocationParameters.ParametersForFillingInCostShares.Date = 
								?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Date"), 
								Object.Date, 
								Date("00010101"));
	CostAllocationParameters.ParametersForFillingInCostShares.Currency = 
								?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Currency"), 
								Object.Currency, 
								Catalogs.Currencies.EmptyRef());
	
	Return CostAllocationParameters;
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
//  Array, Structure - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(Object) Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ChoiceParameters.DataPath         = "Object.ManufacturedProduct";
	ChoiceParameters.AssetRef              = "ExpenseItem";
	ChoiceParameters.ArticleType           = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	
	ChoiceParameters.AvailabilityByOperation = Not
		(Object.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			Or Object.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair);
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	ProductionManagement.CompleteSelectionOfExpenditureItems(ChoiceParameters.SelectionOfExpenditureItems);
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ManufacturedProductExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ManufacturedProductDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ManufacturedProductAssetsLiabilitiesDimension");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("Canceled", False);
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

// Returns the Query Text that forms the temporary table you need to form these steps.
//
// Parameters:
//   SelectionOrderTypes - QueryResultSelection
//
// Returns:
//  String - QueryText
//
Function QueryTextTTStageGenerationIsRequired(SelectionOrderTypes) Export
	
	If Not SelectionOrderTypes.ThereAreOrdersStaticStructure Then
		
		QueryText = 
		"SELECT TOP 0
		|	VALUE(Document.ProductionOrder2_2.EmptyRef) AS Ref
		|INTO TTIsRequiredToFormStages";
		
	Else
		
		QueriesTexts = New Array;
		
		VerificationIndicator = BalanceIndicatorForFormationOfStages();
		
		RequestTextsProductsForProduction =
			RequestTextsProductsForProduction(True, VerificationIndicator,, False, "ReferenceOrder IN (&ReferencesArrray)");
			
		QueriesTexts.Add(RequestTextsProductsForProduction.QueryTextSource);
		QueriesTexts.Add(RequestTextsProductsForProduction.QueryTextAdditional);
		QueriesTexts.Add(RequestTextsProductsForProduction.QueryTextMain);
		
		QueryText =
		"SELECT
		|	Table.ReferenceOrder AS Ref
		|INTO TTIsRequiredToFormStages
		|FROM
		|	TTProductsForProduction AS Table
		|GROUP BY
		|	Table.ReferenceOrder
		|HAVING
		|	(TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.ProductionOrder2_2 AS T
		|			WHERE
		|				T.Ref = Table.ReferenceOrder
		|				AND NOT T.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials))
		|		OR TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				AccumulationRegister.ProductionProcessSupply AS T
		|			WHERE
		|				T.ReferenceOrder = Table.ReferenceOrder
		|				AND T.Scheduled + T.TransferredToProduction + T.Produced + T.Manufactured > 0)
		|)";
		
		QueriesTexts.Add(QueryText);
		
		QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
		
	EndIf;
	
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

#Region GroupCosts

// Returns a list of fields that identify the cost group.
//	Returns:
//		ValueList of String - a list of fields identifying the cost group.
//
Function ListOfCostGroupFields() Export
	
	FieldList = New ValueList;
	LanguageCode = Common.DefaultLanguageCode();
	FieldList.Add("BillOfMaterials",	NStr("vi = 'Bảng kê chi tiết';
											|ru = 'Спецификация';
											|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
											|it = 'Specifica';
											|pl = 'Specafikacja';
											|tr = 'Ürün reçetesi'", LanguageCode));
	FieldList.Add("Purpose",		NStr("vi = 'Mục đích';
										|ru = 'Назначение';
										|en = 'Assignment'; fa = 'تخصیص';
										|it = 'Assegnazione';
										|pl = 'Przeznaczenie';
										|tr = 'Atama'", LanguageCode));
	
	Return FieldList;
	
EndFunction

#EndRegion

#Region ProductionSchedule

// Updates the Registered Records schedule of goods after calculating the production schedule.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Universal queue of operational tasks", there are also service columns:
//             * Object                 - DocumentRef          - Link To Order
//             * RecordID    - UUID -
//             * RecordDate             - Date                    -
//             * JobID   - UUID - Service_
//             * TaskDate_            - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure UpdateScheduleOfRegisteredRecordsOfGoods(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	SetPrivilegedMode(True);

	DocumentsArray = TMCommonUse.UnloadColumnValues(Jobs, "Object");
	MetaOfRegister = Undefined;
	
	For Each DocumentRef In DocumentsArray Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Document.ProductionOrder2_2");
			LockItem.Mode = DataLockMode.Shared;
			LockItem.SetValue("Ref", DocumentRef);
			Block.Lock();
		
			DocumentObject = DocumentRef.GetObject();
			
			If DocumentObject.Status = Enums.ProductionOrderStatuses2_2.ToProduce
				And DocumentObject.Posted Then
			
				DocumentsPosting.BeforeWritingDocument(DocumentObject, DocumentWriteMode.Posting, Undefined);
				TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(DocumentObject.Ref, "InventoryAndDemands");
				TempTablesManager = New TempTablesManager();
				
				RegisterRegisteredRecords_ = DocumentObject.RegisterRecords["InventoryAndDemands"];
				RegisterRegisteredRecords_.Write = True;
				RegisterRegisteredRecords_.Load(TablesForRegisteredRecords["Table" + "InventoryAndDemands"]);
				
				DocumentsPosting.SetAdditionalRegisterProperties(
					RegisterRegisteredRecords_, 
					DocumentObject, 
					TempTablesManager,
					True,
					True,
					False,
					False);
					
				DocumentObject.RegisterRecords.Write(); 

				DocumentsPosting.CreateTasksForDeferredRegisteredRecords(DocumentObject, TempTablesManager);
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			If MetaOfRegister = Undefined Then
				
				MetaOfRegister = Metadata.InformationRegisters.UniversalQueueOfRealTimeJobs;
				
				EventName   = DeferredJobs.EventName();
				
				ErrorFields   = New Structure("Object");
				DataOfError = New Structure("Object");
				
				Jobs.Indexes.Add("Object");
				
			EndIf;
			
			ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName, EventLogLevel.Error, MetaOfRegister,, ExceptionText);
			
			DataOfError.Object = DocumentRef;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, DataOfError, ExceptionText);
			
			FoundRows = Jobs.FindRows(DataOfError);
			For Each FoundRow In FoundRows Do
				IdsOfUnprocessedRecords.Insert(FoundRow.RecordID, ErrorText);
			EndDo;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region LinesOfBusiness

// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
//  Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "ManufacturedProduct";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("ManufacturedProduct", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region Posting

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources; 
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	Table.Date                               AS Period,
	|	Table.Number                              AS Number, 
	|	Table.Partner                            AS Partner,
	|	Table.BusinessOperation              AS BusinessOperation,
	|	Table.EmployeeResponsible                      AS EmployeeResponsible,
	|	Table.Comment                        AS Comment, 
	|	Table.DeletionMark                    AS DeletionMark,  
	|	Table.Priority                          AS Priority,
	|	Table.LineOfBusiness            AS LineOfBusiness,
	|	Table.Organization                        AS Organization,
	|	Table.Status                             AS Status,
	|	Table.Posted                           AS Posted,
	|	Table.Department                      AS Department,
	|	Table.EarliestStartDate                      AS EarliestStartDate,
	|	Table.DemandDate                    AS DemandDate,
	|	Table.ProductionScheduling                  AS ProductionScheduling,
	|	Table.ProductionProcessType       AS ProductionProcessType,
	|	Table.AssignmentProducts                AS AssignmentProducts,
	|	Table.DynamicStructure              AS DynamicStructure,
	|	Table.DemandDateIsSpecifiedInLines AS DemandDateIsSpecifiedInLines
	|FROM
	|	Document.ProductionOrder2_2 AS Table
	|WHERE
	|	Table.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();    
	
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	SetPredefinedInitializationParameters(Query);
	
EndProcedure

Procedure SetPredefinedInitializationParameters(Query)
	
	Query.SetParameter("EmptyDestinationLink",    Catalogs.Assignments.EmptyRef());
	Query.SetParameter("EmptyWarehouseLink",         Catalogs.Warehouses.EmptyRef());
	Query.SetParameter("EmptyUnitReference", Catalogs.BusinessStructure.EmptyRef());
	
	Query.SetParameter("StatusIsGenerated",   Enums.ProductionOrderStatuses2_2.BeingGenerated);
	Query.SetParameter("StatusForProduction", Enums.ProductionOrderStatuses2_2.ToProduce);
	Query.SetParameter("TheClosedStatus",        Enums.ProductionOrderStatuses2_2.Closed);
	
EndProcedure

#EndRegion

#Region TextsOfRequestsForHolding

Function QueryTextTableProductionProcessSupply(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ProductionProcessSupply";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If DocumentObject <> Undefined
	   And Not ((DocumentObject.Status = Enums.ProductionOrderStatuses2_2.ToProduce
				Or DocumentObject.Status = Enums.ProductionOrderStatuses2_2.Closed)
			 And Not DocumentObject.DynamicStructure) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("DocumentDataTableManufacturingProducts", QueryTexts) Then
		QueryTextDocumentDataTableManufacturingProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                              AS Period,
	|	TabularSection.LineNumber           AS LineNumber,
	|
	|	&Ref                              AS ReferenceOrder,
	|
	|	TabularSection.Products          AS Products,
	|	TabularSection.Characteristic        AS Characteristic,
	|	TabularSection.BillOfMaterials          AS BillOfMaterials,
	|
	|	CASE
	|		WHEN NOT TabularSection.ToExpenseAs
	|			AND &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|			THEN &AssignmentProducts
	|		ELSE TabularSection.Purpose
	|	END                                AS Purpose,
	|
	|	CASE 
	|		WHEN TabularSection.ProductsTypeOfProducts IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage)) 
	|			AND NOT TabularSection.ToExpenseAs THEN
	|		TabularSection.Warehouse
	|	ELSE
	|		VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|
	|	CASE 
	|		WHEN TabularSection.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5) 
	|		  OR TabularSection.ToExpenseAs THEN
	|		TabularSection.Department
	|	ELSE
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|
	|	TabularSection.ToExpenseAs         AS ToExpenseAs,
	|
	|	CASE
	|		WHEN TabularSection.ToExpenseAs 
	|			THEN TabularSection.ExpenseItem
	|		ELSE UNDEFINED
	|	END  									AS ExpenseItem,
	|
	|	CASE
	|		WHEN TabularSection.ToExpenseAs 
	|			THEN TabularSection.DimensionOfExpenses
	|		ELSE UNDEFINED
	|	END  									AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN TabularSection.ToExpenseAs 
	|			THEN TabularSection.AssetsLiabilitiesDimension
	|		ELSE UNDEFINED
	|	END  									AS AssetsLiabilitiesDimension,
	|
	|	CASE WHEN &ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly) THEN
	|		TabularSection.Count
	|	ELSE
	|		0
	|	END                                AS Required2,
	|
	|	CASE WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly) THEN
	|		TabularSection.Count
	|	ELSE
	|		0
	|	END                                AS DisassemblyIsRequired
	|
	|FROM
	|	DocumentDataTableManufacturingProducts AS TabularSection
	|WHERE
	|	&Status IN (
	|		&StatusForProduction,
	|		&TheClosedStatus)
	|	AND NOT TabularSection.Canceled
	|	AND NOT &DynamicStructure
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableProductionOrders(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ProductionOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject <> Undefined
	   And Not (DocumentObject.Posted
			 And DocumentObject.DynamicStructure
			 And (DocumentObject.Status = Enums.ProductionOrderStatuses2_2.ToProduce
				Or DocumentObject.Status = Enums.ProductionOrderStatuses2_2.Closed)) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("DocumentDataTableManufacturingProducts", QueryTexts) Then
		QueryTextDocumentDataTableManufacturingProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText =
	"SELECT
	|
	|	TabularSection.LineNumber                                                AS LineNumber,
	|	TabularSection.Products                                               AS Products,
	|	TabularSection.Characteristic                                             AS Characteristic,
	|	CASE
	|		WHEN TabularSection.ProductsTypeOfProducts IN (
	|				VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage))
	|			AND NOT TabularSection.ToExpenseAs THEN
	|		TabularSection.Warehouse
	|	WHEN TabularSection.ToExpenseAs
	|		OR TabularSection.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5) THEN
	|		TabularSection.Department
	|	ELSE
	|		UNDEFINED
	|	END                                                                     AS Warehouse,
	|	CASE
	|		WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly) THEN
	|			&AssignmentProducts
	|		ELSE
	|			TabularSection.Purpose
	|	END                                                                     AS Purpose,
	|	TabularSection.Ref                                                     AS ProductionOrder,
	|	TabularSection.KeyProducts                                           AS KeyProducts,
	|	TabularSection.DemandDate                                            AS DemandDate,
	|	TabularSection.BillOfMaterials                                               AS BillOfMaterials,
	|	CASE
	|		WHEN &DemandDateIsSpecifiedInLines
	|				AND NOT TabularSection.DemandDate = DATETIME(1, 1, 1)
	|			THEN DATEDIFF(TabularSection.DemandDate, BEGINOFPERIOD(&Period, DAY), SECOND)
	|		WHEN &DemandDateIsSpecifiedInLines
	|				AND NOT &DemandDate = DATETIME(1, 1, 1)
	|			THEN DATEDIFF(&DemandDate, BEGINOFPERIOD(&Period, DAY), SECOND)
	|		ELSE 0
	|	END                                                                     AS DurationBeforeProductionIssue,
	|	TabularSection.Count                                                 AS ToProduce
	|
	|FROM
	|	DocumentDataTableManufacturingProducts AS TabularSection
	|	
	|WHERE
	|	&Posted
	|	AND &DynamicStructure
	|	AND &Status IN (
	|			VALUE(Enum.ProductionOrderStatuses2_2.ToProduce),
	|			VALUE(Enum.ProductionOrderStatuses2_2.Closed))
	|	AND NOT TabularSection.Canceled
	|	AND NOT TabularSection.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ProductionOrder2_2";
	SynonymForDocumentTable = "TabularSection";  

	RequestHasSource = True;
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
		
	RedefiningParameterCalculation = RedefiningParameterCalculation(
										StrTemplate("%1.Ref", SynonymForDocumentTable),
										RegisterName);
	
	If RegisterName = "ProductionOrders" Then
		
		QueryText = QueryTextTableProductionOrders(Query, QueryTexts, RegisterName, Undefined);
		
		QueryText = StrReplace(QueryText,
									"DocumentDataTableManufacturingProducts",
									"Document.ProductionOrder2_2.ManufacturedProduct");
		
		QueryText = StrReplace(QueryText,
									"ProductsTypeOfProducts",
									"Products.ItemsType");
		
		QueryText = StrReplace(QueryText,
									"SeparatePurchasingAndSaleItems",
									"Products.AssignedPurchaseSale");
		
	ElsIf RegisterName = "ProductionProcessSupply" Then
		
		QueryText = QueryTextTableProductionProcessSupply(
						Query,
						QueryTexts,
						RegisterName,
						Undefined);
		
		QueryText = StrReplace(QueryText,
									"DocumentDataTableManufacturingProducts",
									"Document.ProductionOrder2_2.ManufacturedProduct");
		
		QueryText = StrReplace(QueryText,
									"ProductsTypeOfProducts",
									"Products.ItemsType");
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName, Undefined);
		RequestHasSource = False;
		
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
			RequestHasSource);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation);
		
		EndIf;
		
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = QueryText;
	Result.ParameterValues = ParameterValues;

	Return Result;
	
EndFunction

Function RedefiningParameterCalculation(MainTable, RegisterName)
	
	Result = New Structure;
	
	If RegisterName = "ProductionProcessSupply" Then
		
		Result.Insert(
			"StatusForProduction",
			"VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)");
		
		Result.Insert(
			"TheClosedStatus",
			"VALUE(Enum.ProductionOrderStatuses2_2.Closed)");
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject = Undefined
	 Or (DocumentObject.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		   Or DocumentObject.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		   Or DocumentObject.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials) Then
		
		If Not DocumentsPosting.ThereIsQueryTable("DocumentDataTableManufacturingProducts", QueryTexts) Then
			QueryTextDocumentDataTableManufacturingProducts(Query, QueryTexts, DocumentObject);
		EndIf;
		
		QueryTextTabPart =
			"SELECT
			|	TabPart.Ref                 AS Ref,
			|	&Period                         AS Period,
			|	TabPart.Products           AS Products,
			|	TabPart.Characteristic         AS Characteristic,
			|	
			|	CASE WHEN TabPart.ToExpenseAs THEN
			|					TabPart.Department
			|			WHEN TabPart.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5) THEN
			|					TabPart.Department
			|				ELSE
			|					TabPart.Warehouse
			|		END AS Warehouse,
			|	
			|	CASE WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials) THEN
			|			&AssignmentProducts
			|		ELSE
			|			TabPart.Purpose
			|		END AS Purpose,
			|	FALSE AS ToControlQuality,
			|	FALSE AS SubjectToUnlocking,
			|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
			|	
			|	TabPart.Ref AS OrderDocument,
			|	
			|	CASE WHEN NOT ScheduleOfManufacturingProducts.ProductionOrder IS NULL THEN
			|											
			|			BEGINOFPERIOD(ScheduleOfManufacturingProducts.ScheduleDate, DAY)
			|												
			|		ELSE
			|									
			|			TabPart.DemandDate
			|										
			|	END AS DateOfReceipt,
			|	
			|	CASE WHEN &Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
			|			AND &DynamicStructure THEN
			|											
			|			ISNULL(ScheduleOfManufacturingProducts.ScheduleDate, TabPart.DemandDate) <> DATETIME(1, 1, 1)
			|												
			|		ELSE
			|									
			|			FALSE
			|										
			|	END AS AvailableForConsumption,
			|	
			|	ISNULL(ScheduleOfManufacturingProducts.Count, TabPart.Count) AS Count,
			|	
			|	FALSE                            AS OnSchedule,
			|	UNDEFINED                    AS OrderInSchedule,
			|	0                               AS QuantityInGraph
			|FROM
			|	DocumentDataTableManufacturingProducts AS TabPart
			|		
			|		LEFT JOIN InformationRegister.OrderProductReleaseSchedule AS ScheduleOfManufacturingProducts
			|		ON TabPart.Products        = ScheduleOfManufacturingProducts.Products
			|		 AND TabPart.Characteristic      = ScheduleOfManufacturingProducts.Characteristic
			|		 AND TabPart.Warehouse               = ScheduleOfManufacturingProducts.Warehouse
			|		 AND TabPart.Purpose          = ScheduleOfManufacturingProducts.Purpose
			|		 AND TabPart.Ref              = ScheduleOfManufacturingProducts.ProductionOrder
			|		 AND TabPart.KeyProducts    = ScheduleOfManufacturingProducts.KeyProducts
			|		
			|WHERE
			|	NOT TabPart.Canceled
			|		AND NOT &Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
			|		AND &ProductionProcessType IN(
			|			VALUE(Enum.ProductionProcessTypes.Assembly),
			|			VALUE(Enum.ProductionProcessTypes.PerformRM),
			|			VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials))";
		
		StockAllocationRecords.ScheduleStockArrival(
			Query,
			QueryTexts,
			Registers,
			QueryTextTabPart,
			False,
			True);
		
	EndIf;
	
	//
	
	If DocumentObject = Undefined
	 Or (DocumentObject.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		   Or DocumentObject.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
		   Or DocumentObject.ProductionProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials)
		 And DocumentObject.ManufacturedProduct.FindRows(New Structure("ToExpenseAs", True)).Count() > 0 Then
		
		If Not DocumentsPosting.ThereIsQueryTable("DocumentDataTableManufacturingProducts", QueryTexts) Then
			QueryTextDocumentDataTableManufacturingProducts(Query, QueryTexts, DocumentObject);
		EndIf;
		
		QueryTextTabPart =
			"SELECT
			|	TabPart.Ref                                           AS Ref,
			|	&Period                                                   AS Period,
			|	TabPart.Products                                     AS Products,
			|	TabPart.Characteristic                                   AS Characteristic,
			|	TabPart.Department                                    AS Warehouse,
			|	
			|	CASE WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials) THEN
			|			&AssignmentProducts
			|		ELSE
			|			TabPart.Purpose
			|		END AS Purpose,
			|	VALUE(Catalog.ControlledLots.EmptyRef)    AS ControlledLotReference,
			|	TabPart.Count                                       AS Count,
			|	VALUE(Enum.SupplyOptions.NotRequired)    AS SupplyOption,
			|	TabPart.Ref                                           AS OrderDocument,
			|	DATETIME(1, 1, 1)                                        AS RequestShipmentOn,
			|	FALSE                                                      AS OnSchedule,
			|	UNDEFINED                                              AS OrderInSchedule,
			|	0                                                         AS QuantityInGraph
			|FROM
			|	DocumentDataTableManufacturingProducts AS TabPart
			|WHERE
			|	NOT TabPart.Canceled
			|		AND TabPart.ToExpenseAs
			|		AND NOT &Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
			|		AND &ProductionProcessType IN(
			|			VALUE(Enum.ProductionProcessTypes.Assembly),
			|			VALUE(Enum.ProductionProcessTypes.PerformRM),
			|			VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials))";
			
		StockAllocationRecords.PlanStockConsumption(
			Query,
			QueryTexts,
			Registers,
			QueryTextTabPart,
			False);
		
	EndIf;
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	&Partner AS Partner,
	|	UNDEFINED AS Counterparty,
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS StorageLocation,
	|	&Department AS Department,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Comment AS Comment,
	|	UNDEFINED AS Currency,
	|	0 AS Sum,
	|	&Status AS Status,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period    AS RecordingInAccountingDate,
	|	&Priority AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextDocumentDataTableManufacturingProducts(Query, QueryTexts, DocumentObject)
	
	TableName = "DocumentDataTableManufacturingProducts";
	
	QueryText =
	"SELECT
	|	TabularSection.Ref                       AS Ref,
	|	TabularSection.LineNumber                  AS LineNumber,
	|	TabularSection.Products                 AS Products,
	|	TabularSection.Products.ItemsType AS ProductsTypeOfProducts,
	|	TabularSection.Products.AssignedPurchaseSale AS SeparatePurchasingAndSaleItems,
	|	TabularSection.Characteristic               AS Characteristic,
	|	TabularSection.BillOfMaterials                 AS BillOfMaterials,
	|	TabularSection.Warehouse                        AS Warehouse,
	|	TabularSection.Department                AS Department,
	|	TabularSection.Purpose                   AS Purpose,
	|	TabularSection.DemandDate              AS DemandDate,
	|	TabularSection.ToExpenseAs             AS ToExpenseAs,
	|	TabularSection.ExpenseItem               AS ExpenseItem,
	|	TabularSection.DimensionOfExpenses            AS DimensionOfExpenses,
	|	TabularSection.AssetsLiabilitiesDimension     AS AssetsLiabilitiesDimension,
	|	TabularSection.Count                   AS Count,
	|	TabularSection.Canceled                     AS Canceled,
	|	TabularSection.KeyProducts             AS KeyProducts
	|INTO DocumentDataTableManufacturingProducts
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
	|WHERE
	|	TabularSection.Ref IN (&Ref)
	|";
	
	QueryTexts.Add(QueryText, TableName);
			
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region SetOfSeries

Function QueryTextForFillingInStatusesIndicatingBatchesOfFinishedProductBeingRepaired()
	
	QueryText = 
	"SELECT
	|	Goods.Series AS Series,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Count AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.LineNumber AS LineNumber
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
	|		WHEN ItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ItemKinds.BatchAccountingPolicy.SpecifyWhenRepairingProducts
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 2
	|					WHEN NOT &FactOfSelection
	|						THEN 21
	|					ELSE 1
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON Goods.Products = CatProducts.Ref
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (CatProducts.ProductKind = ItemKinds.Ref)
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

#Region ProductionLot

// Defines data for the production batch fields.
//
// Parameters:
//  Object - DocumentObject.ProductionOrder2_2 -
//
// Returns:
//  See Catalogs.ProductionLots.ProductionBatchDescription
//
Function BatchFields(Object) Export
	
	BatchFields = Catalogs.ProductionLots.ProductionBatchDescription();
	
	BatchFields.Document = Object.Ref;
	BatchFields.GroupCosts = Enums.GroupingsOfCostsInBackflushProduction.ByDocument;
	
	BatchFields.ProcessType = Enums.ProductionProcessTypes.WithoutBillsOfMaterials;
	BatchFields.BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
	
	BatchFields.Organization = Object.Organization;
	BatchFields.VATActivityType = Object.OrderForActivity;
	
	BatchFields.Purpose = Object.AssignmentProducts;
	BatchFields.LineOfBusiness = Object.LineOfBusiness;
	
	If ValueIsFilled(Object.AssignmentProducts) Then
		LineOfBusiness = ProductionManagementCached.DirectionOfActivityPurposeOfProduction(Object.AssignmentProducts);
		BatchFields.LineOfBusiness = LineOfBusiness;
	EndIf;
	
	Rows = Object.ManufacturedProduct.FindRows(New Structure("Canceled", False));
	If Rows.Count() > 0 Then
		BatchFields.MainProductProducts = Rows[0].Products;
		BatchFields.MainProductCharacteristic = Rows[0].Characteristic;
	EndIf;
	
	If ValueIsFilled(BatchFields.MainProductProducts) Then
		BatchFields.ProductsGroup =
			Common.ObjectAttributeValue(Rows[0].Products, "AnalyticalGroup");
	EndIf;
	
	// Organization of stages
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Stages.Organization AS Organization
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|WHERE
	|	Stages.ProductionLot = &ProductionLot
	|	AND Stages.Organization <> &Organization
	|	AND Stages.Posted
	|";
	
	Query.SetParameter("Organization",        Object.Organization);
	Query.SetParameter("ProductionLot", Object.ProductionLot);
	
	Companies = Query.Execute().Unload();
	If Companies.Count() > 0 Then
		
		BatchFields.InternalSubcontracting = True;
		
		NewRow = Companies.Add();
		NewRow.Organization = BatchFields.Organization;
		
		BatchFields.Companies = Companies;
		
	EndIf;
	
	Return BatchFields;
	
EndFunction

#EndRegion

#Region SeparationSchemes

Function TextOfRequestForSeparationSchemeByOrder(CreateTemporaryTable = False)
	
	// The request text is modified programmatically
	//  - creation of a temporary table in the scheme of the special production
	//  - substitution of parameters.
	QueryText =
	"SELECT DISTINCT
	|
	|	SeparationSchemes.ReferenceOrder              AS ReferenceOrder,
	|	SeparationSchemes.Purpose                AS Purpose,
	|
	|	SeparationSchemes.WithAssignment               AS WithAssignment,
	|
	|	SeparationSchemes.AssignmentProducts       AS AssignmentProducts,
	|	SeparationSchemes.AssigningSideOutput AS AssigningSideOutput,
	|	SeparationSchemes.AssignmentMaterials       AS AssignmentMaterials,
	|
	|	SeparationSchemes.ReferenceOrder.DisabledAssignmentByProductionStageForIntermediateProducts AS DisabledAssignmentByProductionStageForIntermediateProducts
	|
	|INTO TTIsolationSchemesInProduction
	|
	|FROM
	|	(SELECT
	// settings for separate rows (by tabular part)
	|	
	|		Goods.Ref                   AS ReferenceOrder,
	|		Goods.Purpose               AS Purpose,
	|	
	|		CASE
	|			WHEN &TextApart
	|				THEN TRUE
	|			ELSE FALSE
	|		END                           AS WithAssignment,
	|	
	|		CASE
	|			WHEN &TextApart
	|				THEN Goods.Purpose
	|			ELSE
	|				VALUE(Catalog.Assignments.EmptyRef)
	|		END                           AS AssignmentProducts,
	|	
	|		&TextAssignmentOfSideOutput AS AssigningSideOutput,
	|	
	|		CASE
	|			WHEN &TextApart
	|				THEN Goods.Purpose
	|			ELSE
	|				CASE
	|					WHEN Orders.OptionOfAssignment IN (VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|														VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|														VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|														VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|						THEN Orders.Purpose
	|					ELSE VALUE(Catalog.Assignments.EmptyRef)
	|				END
	|		END                           AS AssignmentMaterials
	|
	|	FROM
	|		Document.ProductionOrder2_2.ManufacturedProduct AS Goods
	|		
	|		LEFT JOIN Document.ProductionOrder2_2 AS Orders
	|		ON Goods.Ref = Orders.Ref
	|	
	|	WHERE
	|		Goods.Ref IN(&References) 
	|		AND Goods.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|		AND Orders.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly),
	|												VALUE(Enum.ProductionProcessTypes.PerformRM),
	|												VALUE(Enum.ProductionProcessTypes.Repair))
	|	
	// settings for separate lines (by document header)
	|	UNION ALL
	|	
	|	SELECT
	|		Orders.Ref                   AS ReferenceOrder,
	|		Orders.AssignmentProducts      AS Purpose,
	|
	|		CASE
	|			WHEN &TextApart
	|				THEN TRUE
	|			ELSE FALSE
	|		END                           AS WithAssignment,
	|
	|		CASE
	|			WHEN &TextApart
	|				THEN Orders.AssignmentProducts
	|			ELSE
	|				VALUE(Catalog.Assignments.EmptyRef)
	|		END                           AS AssignmentProducts,
	|
	|		&TextAssignmentOfSideOutput AS AssigningSideOutput,
	|
	|		CASE
	|			WHEN &TextApart
	|				THEN Orders.AssignmentProducts
	|			ELSE
	|				CASE
	|					WHEN Orders.OptionOfAssignment IN (VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|														VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|														VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|														VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|						THEN Orders.Purpose
	|					ELSE VALUE(Catalog.Assignments.EmptyRef)
	|				END
	|		END                           AS AssignmentMaterials
	|
	|	FROM
	|		Document.ProductionOrder2_2 AS Orders
	|
	|	WHERE
	|		Orders.Ref IN(&References)
	|		AND Orders.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials),
	|													VALUE(Enum.ProductionProcessTypes.Disassembly))
	|		AND Orders.AssignmentProducts <> VALUE(Catalog.Assignments.EmptyRef)
	|	
	// settings for non-isolated rows
	|	UNION ALL
	|	
	|	SELECT
	|		Orders.Ref                                AS ReferenceOrder,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|
	|		CASE
	|			WHEN &TextApart
	|				THEN TRUE
	|			ELSE FALSE
	|		END                                        AS WithAssignment,
	|
	|		VALUE(Catalog.Assignments.EmptyRef) AS AssignmentProducts,
	|		&TextAssignmentOfSideOutput              AS AssigningSideOutput,
	|		CASE
	|			WHEN Orders.OptionOfAssignment IN (VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|												VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|												VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|												VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|				THEN Orders.Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END                                        AS AssignmentMaterials
	|
	|	FROM
	|		Document.ProductionOrder2_2 AS Orders
	|
	|	WHERE
	|		Orders.Ref IN(&References)
	|
	|) AS SeparationSchemes";
	
	QueryText = StrReplace(QueryText, "&TextApart", RequestTextFieldIsSeparate());
	QueryText = StrReplace(QueryText, "&TextAssignmentOfSideOutput", QueryTextAssigningSideOutput());
	
	If Not CreateTemporaryTable Then
		QueryText = StrReplace(QueryText, "INTO TTIsolationSchemesInProduction", "");
	EndIf;

	Return QueryText;
	
EndFunction

Function RequestTextForIntendedSeparationScheme()
	
	QueryText =
	// settings for separate rows
	"SELECT
	|
	|	Orders.Ref                   AS ReferenceOrder,
	|	&Purpose                     AS Purpose,
	|	
	|	CASE
	|		WHEN &TextApart
	|			THEN TRUE
	|		ELSE FALSE
	|	END                           AS WithAssignment,
	|	
	|	CASE
	|		WHEN &TextApart
	|			THEN &Purpose
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END                           AS AssignmentProducts,
	|	
	|	&TextAssignmentOfSideOutput AS AssigningSideOutput,
	|	
	|	CASE
	|		WHEN &TextApart
	|			THEN &Purpose
	|		ELSE
	|			CASE
	|				WHEN Orders.OptionOfAssignment IN (VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|													VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|													VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|													VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|					THEN Orders.Purpose
	|				ELSE VALUE(Catalog.Assignments.EmptyRef)
	|			END
	|	END                           AS AssignmentMaterials,
	|
	|	Orders.DisabledAssignmentByProductionStageForIntermediateProducts AS DisabledAssignmentByProductionStageForIntermediateProducts
	|
	|FROM
	|	Document.ProductionOrder2_2 AS Orders
	|
	|WHERE
	|	Orders.Ref = &ReferenceOrder 
	|	AND &Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|	
	// settings for non-isolated rows
	|UNION
	|	
	|SELECT
	|
	|	Orders.Ref                                AS ReferenceOrder,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|
	|	CASE
	|		WHEN &TextApart
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                        AS WithAssignment,
	|
	|	VALUE(Catalog.Assignments.EmptyRef) AS AssignmentProducts,
	|	
	|	&TextAssignmentOfSideOutput              AS AssigningSideOutput,
	|	
	|	CASE
	|		WHEN Orders.OptionOfAssignment IN (VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|			THEN Orders.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                        AS AssignmentMaterials,
	|
	|	Orders.DisabledAssignmentByProductionStageForIntermediateProducts AS DisabledAssignmentByProductionStageForIntermediateProducts
	|
	|FROM
	|	Document.ProductionOrder2_2 AS Orders
	|
	|WHERE
	|	Orders.Ref = &ReferenceOrder
	|	AND &Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|";
	QueryText = StrReplace(QueryText, "&TextApart",               RequestTextFieldIsSeparate());
	QueryText = StrReplace(QueryText, "&TextAssignmentOfSideOutput", QueryTextAssigningSideOutput());
	
	Return QueryText;
	
EndFunction

Function RequestTextFieldIsSeparate(PathToDataFieldOrder = Undefined) Export
	
	QueryText = "Orders.OptionOfAssignment = VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts)
				|";
	
	If PathToDataFieldOrder <> Undefined Then
		QueryText = StrReplace(QueryText, "Orders", PathToDataFieldOrder);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextAssigningSideOutput()
	
	QueryText =
	"CASE
	|	
	|	WHEN Orders.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Disassembly))
	|			AND Orders.AssignmentProducts <> VALUE(Catalog.Assignments.EmptyRef)
	|	
	|		THEN
	|			Orders.AssignmentProducts
	|	
	|	WHEN Orders.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.TollManufacturing2_5))
	|			AND Orders.OptionOfAssignment IN ( VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|											VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|	
	|		THEN
	|			Orders.Purpose
	|	
	|	ELSE
	|		VALUE(Catalog.Assignments.EmptyRef)
	|	
	|END";
	Return QueryText;
	
EndFunction

Function CreateSeparationScheme(FillingValues)
	
	IsolationScheme = New Structure;
	IsolationScheme.Insert("ReferenceOrder", Documents.ProductionOrder2_2.EmptyRef());
	IsolationScheme.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	IsolationScheme.Insert("AssignmentProducts", Catalogs.Assignments.EmptyRef());
	IsolationScheme.Insert("AssigningSideOutput", Catalogs.Assignments.EmptyRef());
	IsolationScheme.Insert("AssignmentMaterials", Catalogs.Assignments.EmptyRef());
	IsolationScheme.Insert("WithAssignment", False);
	IsolationScheme.Insert("DisabledAssignmentByProductionStageForIntermediateProducts", False);
	
	FillPropertyValues(IsolationScheme, FillingValues);
	
	Return IsolationScheme;
	
EndFunction

#EndRegion

#Region DynamicStructure

// Returns the protocol for calculating the structure of the production order.
//
// Parameters:
//  ProductionOrder - DocumentRef.ProductionOrder2_2 - production order.
// 
// Returns:
//  Structure - calculation protocol
//
Function OrderStructureCalculationProtocol(ProductionOrder) Export
	
	CalculationIsRunning = OrderStructureInternal.CalculationIsRunning()
		Or Not ProductionManagementCached.TheProductionScheduleIsUsed()
			And InformationRegisters.TargetOrderStructureSchedule.CalculationIsRunning();
	
	Query = New Query;
	Query.SetParameter("CalculationIsRunning", CalculationIsRunning);
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("NormativeProductionScheduleIsUsed",
		Not ProductionManagementCached.TheProductionScheduleIsUsed());
	Query.Text = 
	"SELECT
	|	1 AS Code
	|INTO Errors
	|WHERE
	|	TRUE IN
	|	 (SELECT TOP 1 TRUE
	|		FROM InformationRegister.OrderStructureCalculationProtocol AS DD
	|		WHERE DD.ProductionOrder = &ProductionOrder AND DD.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs))
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS Code
	|WHERE
	|	TRUE IN
	|	 (SELECT TOP 1 TRUE
	|		FROM InformationRegister.OrderStructureCalculationProtocol AS DD
	|		WHERE DD.ProductionOrder = &ProductionOrder AND DD.ErrorType IN (VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError),
	|																			VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenFillingTheBOMData)))
	|
	|UNION ALL
	|
	|SELECT
	|	3 AS Code
	|WHERE
	|	TRUE IN
	|	 (SELECT TOP 1 TRUE
	|		FROM InformationRegister.OrderStructureCalculationProtocol AS DD
	|		WHERE DD.ProductionOrder = &ProductionOrder AND DD.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError))
	|;
	|SELECT
	|	CASE
	|		WHEN 
	|			(TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.TasksOfBOMOrderStructureCalculation AS T
	|				WHERE
	|					T.ProductionOrder = Table.Ref)
	|				OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS T
	|				WHERE
	|					T.ProductionOrder = Table.Ref)
	|				OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS T
	|				WHERE
	|					T.ProductionOrder = Table.Ref)
	|				OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS T
	|				WHERE
	|					T.ProductionOrder = Table.Ref)
	|				OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructureCleanupTasks AS T
	|				WHERE
	|					T.ProductionOrder = Table.Ref)
	|				OR TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.OrderStructureCalculationJobsProductionSchedule AS T
	|				WHERE
	|					T.ProductionOrder = Table.Ref)
	|					AND &NormativeProductionScheduleIsUsed
	|					AND NOT TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructureCalculationProtocol AS T
	|						WHERE
	|							T.ProductionOrder = Table.Ref
	|							AND T.ErrorType = VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.TargetScheduleCalculationError)))
	|			THEN CASE
	|					WHEN &CalculationIsRunning AND &Running    THEN 3
	|					WHEN &CalculationIsRunning AND NOT &Running THEN 4
	|					ELSE 2
	|				END
	|		WHEN
	|			&Running
	|				AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Errors
	|				WHERE
	|					Errors.Code > 0)
	|			THEN 5
	|		ELSE CASE
	|				WHEN &Running THEN 1 ELSE 0 END
	|	END AS Code
	|FROM
	|	Document.ProductionOrder2_2 AS Table
	|WHERE
	|	Table.Ref = &ProductionOrder
	|";
	Query.Text = StrReplace(Query.Text,
		"&Running",
		"Table.Posted AND Table.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)");
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	SetPrivilegedMode(False);
	
	StateCodes = New Structure();
	
	StateCodes.Insert("NotCalculated",           0);
	StateCodes.Insert("Calculated",             1);
	StateCodes.Insert("AwaitingCalculation",        2);
	StateCodes.Insert("Calculating",        3);
	StateCodes.Insert("IsCancelled",            4);
	StateCodes.Insert("CalculatedHasErrors",   5);
	StateCodes.Insert("NotCalculatedHasErrors", 6);
	
	ErrorCodes = New Structure();
	
	ErrorCodes.Insert("NoErrors_ ",                       0);
	ErrorCodes.Insert("SpecificationSelectionErrors",        1);
	ErrorCodes.Insert("ErrorsInFillingInProductData", 2);
	ErrorCodes.Insert("ErrorsInCalculationOfRegulatorySchedule", 3);
	
	Result = New Structure();
	
	Result.Insert("StateCodes",StateCodes);
	Result.Insert("ErrorCodes",ErrorCodes);
	Result.Insert("Errors",QueryResult[0].Unload().UnloadColumn(0));
	Result.Insert("State",QueryResult[1].Unload().UnloadColumn(0)[0]);
	
	Return Result;
	
EndFunction

#EndRegion

#Region FormationOfStages

Function RequestTextsProductsForProduction(
	CreateTemporaryTable, Factor, TempTableName = "TTProductsForProduction", ThereIsSelectionByPeriod = False, TextOfSelectionByMeasurements = "")
	
	QueryTexts = New Structure;
	
	QueryText = 
	"SELECT
	|	Table.ReferenceOrder	 AS ReferenceOrder,
	|
	|	Table.Products	 AS Products,
	|	Table.Characteristic	 AS Characteristic,
	|
	|	Table.Purpose		 AS Purpose,
	|	Table.Stage			 AS Stage,
	|
	|	Table.ToExpenseAs AS ToExpenseAs,
	|
	|	Table.Warehouse			 AS Warehouse,
	|
	|	Table.Required2Turnover 			AS Required2Turnover,
	|	Table.ScheduledTurnover 		AS ScheduledTurnover,
	|	Table.TransferredToProductionTurnover AS TransferredToProductionTurnover,
	|	Table.ProducedTurnover 			AS ProducedTurnover,
	|	Table.ManufacturedTurnover 			AS ManufacturedTurnover,
	|
	|	Table.DisassemblyIsRequiredTurnover		AS DisassemblyIsRequiredTurnover,
	|	Table.DisassemblyIsPlannedTurnover AS DisassemblyIsPlannedTurnover,
	|	Table.ReadyForDisassemblyTurnover		AS ReadyForDisassemblyTurnover,
	|
	|	&TextResourceAccounting
	|		- CASE
	|			WHEN Table.Products.UnitOfMeasure.MeasuredValueType IN (
	|													VALUE(Enum.TypesOfMeasuredValues.Weight),
	|													VALUE(Enum.TypesOfMeasuredValues.Length),
	|													VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
	|													VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
	|				THEN Table.Required2Turnover * (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
	|			ELSE 0
	|		END                           AS ProductionIsRequiredTakingIntoAccountPermissibleDeviation,
	|
	|	VALUETYPE(Table.Purpose.OrderDocument)                                            AS TypeOrderFromDestination,
	|	CAST(Table.Purpose.OrderDocument AS Document.ProductionStage2_2).ReferenceOrder AS OrderFromAppointment
	|
	|INTO EnsuringProductionProcessesInContextOfWarehouses
	|FROM
	|	AccumulationRegister.ProductionProcessSupply.Turnovers(
	|		&BeginOfPeriod,
	|		&EndOfPeriod,
	|		,
	|		&FilterByDimensions) AS Table
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Products,
	|	Characteristic,
	|	Stage,
	|	ToExpenseAs,
	|	Purpose
	|";
	
	If Not ThereIsSelectionByPeriod Then
		QueryText = StrReplace(QueryText, "&BeginOfPeriod", "");
		QueryText = StrReplace(QueryText, "&EndOfPeriod", "");
	EndIf;
	
	If Factor = BalanceIndicatorForFormationOfStages() Then
		QueryText = StrReplace(QueryText, "&TextResourceAccounting", 
		"Table.Required2Turnover
		|		- Table.ScheduledTurnover
		|		- Table.TransferredToProductionTurnover
		|		- Table.ProducedTurnover
		|		- Table.ManufacturedTurnover");
	Else
		QueryText = StrReplace(QueryText, "&TextResourceAccounting", 
		"Table.Required2Turnover
		|		- Table.ManufacturedTurnover");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterByDimensions", TextOfSelectionByMeasurements);
	
	QueryTexts.Insert("QueryTextSource", QueryText);
	
	QueryText =
	"SELECT
	|	Table.ReferenceOrder     AS ReferenceOrder,
	|	Table.Products     AS Products,
	|	Table.Characteristic   AS Characteristic,
	|	Table.Purpose       AS Purpose,
	|	Table.Stage             AS Stage,
	|	Table.ToExpenseAs AS ToExpenseAs
	|INTO TTRequiredAssignmentsToProduction
	|FROM
	|	EnsuringProductionProcessesInContextOfWarehouses AS Table
	|WHERE
	|	Table.TypeOrderFromDestination = TYPE(Document.ProductionStage2_2)
	|	AND Table.OrderFromAppointment = Table.ReferenceOrder
	|
	|GROUP BY
	|	Table.ReferenceOrder,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.Stage,
	|	Table.ToExpenseAs
	|HAVING
	|	SUM(Table.ProductionIsRequiredTakingIntoAccountPermissibleDeviation) > 0
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Products,
	|	Characteristic,
	|	Stage,
	|	ToExpenseAs
	|";
	
	QueryTexts.Insert("QueryTextAdditional", QueryText);
	
	QueryText =
	"SELECT
	|
	|	Table.ReferenceOrder     AS ReferenceOrder,
	|
	|	Table.Products     AS Products,
	|	Table.Characteristic   AS Characteristic,
	|
	|	Table.Purpose       AS Purpose,
	|	Table.Stage             AS Stage,
	|
	|	Table.ToExpenseAs AS ToExpenseAs,
	|
	|	SUM(&TextResourceAccounting) AS ProductionRequired,
	|
	|	SUM(Table.DisassemblyIsRequiredTurnover)
	|			- CASE
	|				WHEN SUM(Table.DisassemblyIsPlannedTurnover) - SUM(Table.ReadyForDisassemblyTurnover) > 0
	|					THEN SUM(Table.DisassemblyIsPlannedTurnover) - SUM(Table.ReadyForDisassemblyTurnover)
	|				ELSE 0
	|			END                        AS DisassemblyIsRequired
	|
	|INTO TTProductsForProduction
	|FROM
	|	(SELECT
	|
	|		Table.ReferenceOrder     AS ReferenceOrder,
	|
	|		Table.Products     AS Products,
	|		Table.Characteristic   AS Characteristic,
	|
	|		Table.Purpose       AS Purpose,
	|		Table.Stage             AS Stage,
	|
	|		Table.ToExpenseAs AS ToExpenseAs,
	|
	|		Table.Required2Turnover             AS Required2Turnover,
	|		Table.ScheduledTurnover         AS ScheduledTurnover,
	|		Table.TransferredToProductionTurnover AS TransferredToProductionTurnover,
	|		Table.ProducedTurnover          AS ProducedTurnover,
	|		Table.ManufacturedTurnover           AS ManufacturedTurnover,
	|
	|		Table.DisassemblyIsRequiredTurnover     AS DisassemblyIsRequiredTurnover,
	|		Table.DisassemblyIsPlannedTurnover AS DisassemblyIsPlannedTurnover,
	|		Table.ReadyForDisassemblyTurnover        AS ReadyForDisassemblyTurnover
	|
	|	FROM
	|		EnsuringProductionProcessesInContextOfWarehouses AS Table
	|
	|	WHERE
	|		TRUE IN 
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				EnsuringProductionProcessesInContextOfWarehouses AS DD
	|			WHERE
	|				DD.ReferenceOrder		= Table.ReferenceOrder
	|				AND DD.Products		= Table.Products
	|				AND DD.Characteristic	= Table.Characteristic
	|				AND DD.Purpose		= Table.Purpose
	|				AND DD.Stage				= Table.Stage
	|				AND DD.ToExpenseAs = Table.ToExpenseAs
	|				AND DD.ProductionIsRequiredTakingIntoAccountPermissibleDeviation > 0)
	|		OR
	|		TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				EnsuringProductionProcessesInContextOfWarehouses AS DD
	|			WHERE
	|				DD.ReferenceOrder		= Table.ReferenceOrder
	|				AND DD.Products		= Table.Products
	|				AND DD.Characteristic	= Table.Characteristic
	|				AND DD.Purpose		= Table.Purpose
	|				AND DD.Stage				= Table.Stage
	|				AND DD.ToExpenseAs = Table.ToExpenseAs
	|				AND DD.ProductionIsRequiredTakingIntoAccountPermissibleDeviation <= 0
	|
	|			GROUP BY
	|				DD.ReferenceOrder,
	|				DD.Products,
	|				DD.Characteristic,
	|				DD.Purpose,
	|				DD.Stage,
	|				DD.ToExpenseAs
	|
	|			HAVING
	|				SUM(DD.DisassemblyIsRequiredTurnover)
	|					- CASE
	|						WHEN SUM(DD.DisassemblyIsPlannedTurnover) - SUM(DD.ReadyForDisassemblyTurnover) > 0
	|							THEN SUM(DD.DisassemblyIsPlannedTurnover) - SUM(DD.ReadyForDisassemblyTurnover)
	|					ELSE 0
	|				END > 0)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|
	|		Table.ReferenceOrder     AS ReferenceOrder,
	|
	|		Table.Products     AS Products,
	|		Table.Characteristic   AS Characteristic,
	|
	|		ProductionAssignments.Purpose AS Purpose,
	|		Table.Stage                       AS Stage,
	|
	|		Table.ToExpenseAs AS ToExpenseAs,
	|
	|		Table.Required2Turnover             AS Required2Turnover,
	|		Table.ScheduledTurnover         AS ScheduledTurnover,
	|		Table.TransferredToProductionTurnover AS TransferredToProductionTurnover,
	|		Table.ProducedTurnover          AS ProducedTurnover,
	|		Table.ManufacturedTurnover           AS ManufacturedTurnover,
	|
	|		Table.DisassemblyIsRequiredTurnover     AS DisassemblyIsRequiredTurnover,
	|		Table.DisassemblyIsPlannedTurnover AS DisassemblyIsPlannedTurnover,
	|		Table.ReadyForDisassemblyTurnover        AS ReadyForDisassemblyTurnover
	|
	|	FROM
	|		EnsuringProductionProcessesInContextOfWarehouses AS Table
	|			LEFT JOIN TTRequiredAssignmentsToProduction AS ProductionAssignments
	|			ON Table.ReferenceOrder     = ProductionAssignments.ReferenceOrder
	|			 AND Table.Products     = ProductionAssignments.Products
	|			 AND Table.Characteristic   = ProductionAssignments.Characteristic
	|			 AND Table.Stage             = ProductionAssignments.Stage
	|			 AND Table.ToExpenseAs = ProductionAssignments.ToExpenseAs
	|
	|	WHERE
	|		Table.ProductionIsRequiredTakingIntoAccountPermissibleDeviation < 0
	|		AND NOT ProductionAssignments.Purpose IS NULL
	|		AND NOT TRUE IN 
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					EnsuringProductionProcessesInContextOfWarehouses AS DD
	|				WHERE
	|					DD.ReferenceOrder		  = Table.ReferenceOrder
	|					AND DD.Products	  = Table.Products
	|					AND DD.Characteristic	  = Table.Characteristic
	|					AND DD.Purpose		  = Table.Purpose
	|					AND DD.Stage			  = Table.Stage
	|					AND DD.ToExpenseAs = Table.ToExpenseAs
	|					AND DD.ProductionIsRequiredTakingIntoAccountPermissibleDeviation > 0)) AS Table
	|
	|GROUP BY
	|	Table.ReferenceOrder,
	|
	|	Table.Products,
	|	Table.Characteristic,
	|
	|	Table.Purpose,
	|	Table.Stage,
	|
	|	Table.ToExpenseAs
	|
	|HAVING	
	|	SUM(&TextResourceAccounting) > 0
	|	OR
	|	SUM(Table.DisassemblyIsRequiredTurnover)
	|			- CASE
	|				WHEN SUM(Table.DisassemblyIsPlannedTurnover) - SUM(Table.ReadyForDisassemblyTurnover) > 0
	|					THEN SUM(Table.DisassemblyIsPlannedTurnover) - SUM(Table.ReadyForDisassemblyTurnover)
	|				ELSE 0
	|			END > 0
	|";
	
	If Factor = BalanceIndicatorForFormationOfStages() Then
		QueryText = StrReplace(QueryText, "&TextResourceAccounting", 
		"Table.Required2Turnover
		|		- Table.ScheduledTurnover
		|		- Table.TransferredToProductionTurnover
		|		- Table.ProducedTurnover
		|		- Table.ManufacturedTurnover");
	Else
		QueryText = StrReplace(QueryText, "&TextResourceAccounting", 
		"Table.Required2Turnover
		|		- Table.ManufacturedTurnover");
	EndIf;
	
	If CreateTemporaryTable Then
		
		QueryText = QueryText + "
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Stage,
		|	ToExpenseAs";
		
		If TempTableName <> "TTProductsForProduction" Then
			QueryText = StrReplace(QueryText, "TTProductsForProduction", TempTableName);
		EndIf;
		
	Else
		
		QueryText = StrReplace(QueryText, "INTO TTProductsForProduction", "");
		
	EndIf;
	
	QueryTexts.Insert("QueryTextMain", QueryText);
	
	Return QueryTexts;
	
EndFunction

Procedure CreateTTDataToGenerateStages(TempTablesManager, References) Export
	
	ListOfRequests = New ValueList();
	
	VerificationIndicator = BalanceIndicatorForFormationOfStages();
	
	RequestTextsProductsForProduction =
		RequestTextsProductsForProduction(True, VerificationIndicator,, True, "ReferenceOrder IN (&References)");
		
	ListOfRequests.Add(RequestTextsProductsForProduction.QueryTextSource,       "");
	ListOfRequests.Add(RequestTextsProductsForProduction.QueryTextAdditional, "");
	ListOfRequests.Add(RequestTextsProductsForProduction.QueryTextMain,       "");
	
	QueryText = 
		"SELECT
		|	Table.ReferenceOrder             AS ReferenceOrder,
		|
		|	Table.Products             AS Products,
		|	Table.Characteristic           AS Characteristic,
		|
		|	Table.Purpose               AS Purpose,
		|	Table.Stage                     AS Stage,
		|
		|	Table.Warehouse                    AS Warehouse,
		|	Table.Department            AS Department,
		|
		|	Table.BillOfMaterials             AS BillOfMaterials,
		|
		|	Table.ToExpenseAs         AS ToExpenseAs,
		|	Table.ExpenseItem           AS ExpenseItem,
		|	Table.DimensionOfExpenses        AS DimensionOfExpenses,
		|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	(Table.Required2Turnover
		|		- Table.ScheduledTurnover
		|		- Table.TransferredToProductionTurnover
		|		- Table.ProducedTurnover
		|		- Table.ManufacturedTurnover) AS Count
		|
		|INTO TTProductionProductsDetailedRecords
		|FROM
		|	AccumulationRegister.ProductionProcessSupply.Turnovers(
		|			&BeginOfPeriod,
		|			&EndOfPeriod,
		|			,
		|			(ReferenceOrder, Products, Characteristic, Purpose, Stage, ToExpenseAs) IN
		|					(SELECT
		|						Table.ReferenceOrder,
		|						Table.Products,
		|						Table.Characteristic,
		|						Table.Purpose,
		|						Table.Stage,
		|						Table.ToExpenseAs
		|					FROM
		|						TTProductsForProduction AS Table
		|					WHERE 
		|						Table.ProductionRequired > 0)) AS Table
		|WHERE
		|	(Table.Required2Turnover
		|		- Table.ScheduledTurnover
		|		- Table.TransferredToProductionTurnover
		|		- Table.ProducedTurnover
		|		- Table.ManufacturedTurnover) <> 0
		|";
	ListOfRequests.Add(QueryText, "");
	
	QueryText = StrReplace(
		"SELECT
		|	&TextSource_                   AS Source,
		|
		|	Table.ReferenceOrder             AS ReferenceOrder,
		|
		|	Table.Products             AS Products,
		|	Table.Characteristic           AS Characteristic,
		|
		|	Table.Purpose               AS Purpose,
		|	Table.Stage                     AS Stage,
		|
		|	Table.Warehouse                    AS Warehouse,
		|	Table.Department            AS Department,
		|
		|	Table.BillOfMaterials             AS BillOfMaterials,
		|
		|	Table.ToExpenseAs         AS ToExpenseAs,
		|	Table.ExpenseItem           AS ExpenseItem,
		|	Table.DimensionOfExpenses        AS DimensionOfExpenses,
		|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	Table.Count               AS Count
		|FROM
		|	TTProductionProductsDetailedRecords AS Table
		|WHERE
		|	Table.Count > 0
		|",
		"&TextSource_",
		Documents.ProductionStage2_2.RequestTextSourceStageField(
			"Table.ReferenceOrder",
			"Table.Stage",
			"Table.Purpose"));
	ListOfRequests.Add(QueryText, "ProductionRequired");
	
	QueryText = 
		"SELECT
		|	Table.ReferenceOrder             AS ReferenceOrder,
		|
		|	Table.Products             AS Products,
		|	Table.Characteristic           AS Characteristic,
		|
		|	Table.Purpose               AS Purpose,
		|	Table.Stage                     AS Stage,
		|
		|	Table.Warehouse                    AS Warehouse,
		|	Table.Department            AS Department,
		|
		|	Table.BillOfMaterials             AS BillOfMaterials,
		|
		|	Table.ToExpenseAs         AS ToExpenseAs,
		|	Table.ExpenseItem           AS ExpenseItem,
		|	Table.DimensionOfExpenses        AS DimensionOfExpenses,
		|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	-Table.Count              AS Count
		|FROM
		|	TTProductionProductsDetailedRecords AS Table
		|WHERE
		|	Table.Count < 0
		|";
	ListOfRequests.Add(QueryText, "PlannedProduction");
	
	QueryText = 
		"SELECT
		|
		|	CASE
		|		WHEN RegisterRecords.Recorder REFS Document.ProductionStage2_2 THEN
		|			RegisterRecords.Recorder
		|		ELSE
		|			VALUE(Document.ProductionStage2_2.EmptyRef)
		|	END                             AS Source,
		|
		|	RegisterRecords.ReferenceOrder             AS ReferenceOrder,
		|
		|	RegisterRecords.Products             AS Products,
		|	RegisterRecords.Characteristic           AS Characteristic,
		|
		|	RegisterRecords.Purpose               AS Purpose,
		|	RegisterRecords.Stage                     AS Stage,
		|
		|	RegisterRecords.Warehouse                    AS Warehouse,
		|
		|	RegisterRecords.BillOfMaterials             AS BillOfMaterials,
		|
		|	RegisterRecords.ToExpenseAs         AS ToExpenseAs,
		|	RegisterRecords.ExpenseItem           AS ExpenseItem,
		|	RegisterRecords.DimensionOfExpenses        AS DimensionOfExpenses,
		|	RegisterRecords.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	SUM(RegisterRecords.DisassemblyIsRequired) AS Count
		|FROM
		|	AccumulationRegister.ProductionProcessSupply AS RegisterRecords
		|WHERE
		|	(RegisterRecords.ReferenceOrder, RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Purpose, RegisterRecords.Stage, RegisterRecords.ToExpenseAs) IN
		|					(SELECT
		|						Table.ReferenceOrder,
		|						Table.Products,
		|						Table.Characteristic,
		|						Table.Purpose,
		|						Table.Stage,
		|						Table.ToExpenseAs
		|					FROM
		|						TTProductsForProduction AS Table
		|					WHERE 
		|						Table.DisassemblyIsRequired > 0)
		|
		|GROUP BY
		|	RegisterRecords.Recorder,
		|	RegisterRecords.ReferenceOrder,
		|	RegisterRecords.Products,
		|	RegisterRecords.Characteristic,
		|	RegisterRecords.Purpose,
		|	RegisterRecords.Stage,
		|	RegisterRecords.Warehouse,
		|	RegisterRecords.BillOfMaterials,
		|	RegisterRecords.ToExpenseAs,
		|	RegisterRecords.ExpenseItem,
		|	RegisterRecords.DimensionOfExpenses,
		|	RegisterRecords.AssetsLiabilitiesDimension
		|
		|HAVING
		|	SUM(RegisterRecords.DisassemblyIsRequired) > 0
		|";
	ListOfRequests.Add(QueryText, "DisassemblyIsRequired");
	
	QueryText = 
		"SELECT
		|
		|	RegisterRecords.ReferenceOrder             AS ReferenceOrder,
		|
		|	RegisterRecords.Products             AS Products,
		|	RegisterRecords.Characteristic           AS Characteristic,
		|
		|	RegisterRecords.Warehouse                    AS Warehouse,
		|
		|	RegisterRecords.Stage                     AS Stage,
		|	RegisterRecords.Purpose               AS Purpose,
		|
		|	RegisterRecords.BillOfMaterials             AS BillOfMaterials,
		|
		|	RegisterRecords.ToExpenseAs         AS ToExpenseAs,
		|	RegisterRecords.ExpenseItem           AS ExpenseItem,
		|	RegisterRecords.DimensionOfExpenses        AS DimensionOfExpenses,
		|	RegisterRecords.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
		|
		|	SUM(CASE
		|		WHEN RegisterRecords.DisassemblyIsPlanned - RegisterRecords.ReadyForDisassembly > 0
		|			THEN
		|				RegisterRecords.DisassemblyIsPlanned - RegisterRecords.ReadyForDisassembly
		|		ELSE
		|			0
		|		END)                        AS Count
		|FROM
		|	AccumulationRegister.ProductionProcessSupply AS RegisterRecords
		|WHERE
		|	(RegisterRecords.ReferenceOrder, RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Purpose, RegisterRecords.Stage, RegisterRecords.ToExpenseAs) IN
		|					(SELECT
		|						Table.ReferenceOrder,
		|						Table.Products,
		|						Table.Characteristic,
		|						Table.Purpose,
		|						Table.Stage,
		|						Table.ToExpenseAs
		|					FROM
		|						TTProductsForProduction AS Table
		|					WHERE 
		|						Table.DisassemblyIsRequired > 0)
		|
		|GROUP BY
		|	RegisterRecords.ReferenceOrder,
		|	RegisterRecords.Products,
		|	RegisterRecords.Characteristic,
		|	RegisterRecords.Purpose,
		|	RegisterRecords.Stage,
		|	RegisterRecords.Warehouse,
		|	RegisterRecords.BillOfMaterials,
		|	RegisterRecords.ToExpenseAs,
		|	RegisterRecords.ExpenseItem,
		|	RegisterRecords.DimensionOfExpenses,
		|	RegisterRecords.AssetsLiabilitiesDimension
		|
		|HAVING
		|	SUM(CASE
		|		WHEN RegisterRecords.DisassemblyIsPlanned - RegisterRecords.ReadyForDisassembly > 0
		|			THEN
		|				RegisterRecords.DisassemblyIsPlanned - RegisterRecords.ReadyForDisassembly
		|		ELSE
		|			0
		|		END) > 0
		|";
	ListOfRequests.Add(QueryText, "DisassemblyIsPlanned");
	
	DataToGenerate_ = DataStructureForGeneratingStagesConstructor();
	Query = New Query();
	
	Query.SetParameter("References", References);
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("ProductionProcessSupply", "ReferenceOrder IN (&References)", New Structure("References", References));
	Query.Parameters.Insert("BeginOfPeriod", SpeedLimits.MinDate);
	Query.Parameters.Insert("EndOfPeriod", SpeedLimits.MaxDate);
	AllowableVariance = Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving", AllowableVariance);
	
	QueryResult = TMCommonUse.UploadResultsOfQuery(Query, ListOfRequests,, True);
	
	If QueryResult["ProductionRequired"].Count() > 0 Then
		
		Dimension = "ReferenceOrder,Products,Characteristic,Purpose,Stage,ToExpenseAs";
		CalculationProcedure = New Array();
		CalculationProcedure.Add(Dimension);
		
		Required2     = QueryResult["ProductionRequired"];
		Scheduled = QueryResult["PlannedProduction"];//ValueTable - 
		Scheduled.Indexes.Add(CalculationProcedure[0]);
		
		RequirementsForProvision = New Array();
		AllocateQuantity(Required2, Scheduled, CalculationProcedure[0], RequirementsForProvision);
		
		AddRowsToDataToFormStages(RequirementsForProvision, DataToGenerate_, 1);
		
	EndIf;
	
	If QueryResult["DisassemblyIsRequired"].Count() > 0 Then
		
		Dimension = "ReferenceOrder,Products,Characteristic,Purpose,Stage";
		CalculationProcedure = New Array();
		CalculationProcedure.Add(Dimension + ",BillOfMaterials,Warehouse");
		CalculationProcedure.Add(Dimension);
		
		Required2     = QueryResult["DisassemblyIsRequired"];
		Scheduled = QueryResult["DisassemblyIsPlanned"];//ValueTable - 
		Scheduled.Indexes.Add(CalculationProcedure[0]);
		
		RequirementsForProvision = New Array();
		AllocateQuantity(Required2, Scheduled, CalculationProcedure[0]);
		AllocateQuantity(Required2, Scheduled, CalculationProcedure[1], RequirementsForProvision);
		
		AddRowsToDataToFormStages(RequirementsForProvision, DataToGenerate_, -1);
		
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.ReferenceOrder AS ReferenceOrder,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose     AS Purpose,
	|
	|	Table.BillOfMaterials AS BillOfMaterials,
	|
	|	Table.Sender  AS Sender,
	|	Table.Recipient   AS Recipient,
	|
	|	Table.StageSource AS StageSource,
	|
	|	Table.ToExpenseAs         AS ToExpenseAs,
	|	Table.ExpenseItem           AS ExpenseItem,
	|	Table.DimensionOfExpenses        AS DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	Table.Count AS Count
	|
	|INTO DataToGenerate_
	|FROM
	|	&DataToGenerate_ AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Ref         AS ReferenceOrder,
	|	TabularSection.Products   AS Products,
	|	TabularSection.Characteristic AS Characteristic,
	|	TabularSection.Purpose     AS Purpose,
	|	TabularSection.BillOfMaterials   AS BillOfMaterials,
	|	CASE
	|		WHEN TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN TabularSection.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Sender,
	|	CASE
	|		WHEN TabularSection.Ref.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			AND TabularSection.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage)) 
	|			AND NOT TabularSection.ToExpenseAs
	|			THEN TabularSection.Warehouse
	|		WHEN TabularSection.Ref.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			AND (TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				OR TabularSection.ToExpenseAs)
	|			THEN TabularSection.Department
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END Recipient,
	|	MIN(TabularSection.LineNumber) AS LineNumber
	|INTO LineNumbers
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
	|WHERE
	|	(TabularSection.Ref, TabularSection.Products, TabularSection.Characteristic, TabularSection.Purpose, TabularSection.BillOfMaterials) IN
	|		(SELECT
	|			Table.ReferenceOrder AS Ref,
	|			Table.Products AS Products,
	|			Table.Characteristic AS Characteristic,
	|			Table.Purpose AS Purpose,
	|			Table.BillOfMaterials AS BillOfMaterials
	|		FROM
	|			DataToGenerate_ AS Table)
	|	AND NOT TabularSection.Canceled
	|
	|GROUP BY
	|	TabularSection.Ref,
	|	TabularSection.Products,
	|	TabularSection.Characteristic,
	|	TabularSection.Purpose,
	|	TabularSection.BillOfMaterials,
	|	CASE
	|		WHEN TabularSection.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN TabularSection.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	CASE
	|		WHEN TabularSection.Ref.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			AND TabularSection.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage)) 
	|			AND NOT TabularSection.ToExpenseAs
	|			THEN TabularSection.Warehouse
	|		WHEN TabularSection.Ref.ProductionProcessType <> VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			AND (TabularSection.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|				OR TabularSection.ToExpenseAs)
	|			THEN TabularSection.Department
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END
	|
	|INDEX BY
	|	ReferenceOrder, Products, Characteristic, Purpose, BillOfMaterials, Sender, Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ReferenceOrder AS ReferenceOrder,
	|
	|	CASE
	|		WHEN &TextApart
	|			THEN CASE
	|					WHEN Table.StageSource = VALUE(Document.ProductionStage2_2.EmptyRef)
	|						THEN CASE
	|								WHEN CAST(Table.ReferenceOrder AS Document.ProductionOrder2_2).ProductionProcessType IN (
	|												VALUE(Enum.ProductionProcessTypes.Assembly),
	|												VALUE(Enum.ProductionProcessTypes.PerformRM),
	|												VALUE(Enum.ProductionProcessTypes.Repair))
	|									THEN Table.Purpose
	|								ELSE CAST(Table.ReferenceOrder AS Document.ProductionOrder2_2).AssignmentProducts
	|							END
	|					ELSE CAST(Table.StageSource AS Document.ProductionStage2_2).AssignmentProducts
	|				END
	|		ELSE
	|			VALUE(Catalog.Assignments.EmptyRef)
	|	END AS AssignmentProducts,
	|
	|	CASE
	|		WHEN &TextApart
	|			THEN CASE
	|					WHEN Table.StageSource = VALUE(Document.ProductionStage2_2.EmptyRef)
	|						THEN CASE
	|								WHEN CAST(Table.ReferenceOrder AS Document.ProductionOrder2_2).ProductionProcessType IN (
	|												VALUE(Enum.ProductionProcessTypes.Assembly),
	|												VALUE(Enum.ProductionProcessTypes.PerformRM),
	|												VALUE(Enum.ProductionProcessTypes.Repair))
	|									THEN Table.Purpose
	|								ELSE CAST(Table.ReferenceOrder AS Document.ProductionOrder2_2).AssignmentProducts
	|							END
	|					ELSE CAST(Table.StageSource AS Document.ProductionStage2_2).AssignmentProducts
	|				END
	|		ELSE
	|			CASE
	|				WHEN CAST(Table.ReferenceOrder AS Document.ProductionOrder2_2).OptionOfAssignment IN (
	|															VALUE(Enum.OptionsOfMaterialAssignmentInProduction.LineOfBusiness),
	|															VALUE(Enum.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts),
	|															VALUE(Enum.OptionsOfMaterialAssignmentInProduction.ProductionOrder),
	|															VALUE(Enum.OptionsOfMaterialAssignmentInProduction.MaterialProviderContract))
	|					THEN CAST(Table.ReferenceOrder AS Document.ProductionOrder2_2).Purpose
	|				ELSE VALUE(Catalog.Assignments.EmptyRef)
	|			END
	|	END AS AssignmentMaterials,
	|
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose     AS Purpose,
	|
	|	Table.BillOfMaterials AS BillOfMaterials,
	|
	|	Table.Sender  AS Sender,
	|	Table.Recipient   AS Recipient,
	|
	|	Table.StageSource AS StageSource,
	|
	|	Table.ToExpenseAs         AS ToExpenseAs,
	|	Table.ExpenseItem           AS ExpenseItem,
	|	Table.DimensionOfExpenses        AS DimensionOfExpenses,
	|	Table.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	ISNULL(LineNumbers.LineNumber, 100000) AS LineNumber,
	|
	|	Table.Count AS Count
	|
	|INTO TTDataForGeneratingStages
	|FROM
	|	DataToGenerate_ AS Table
	|
	|	LEFT JOIN LineNumbers AS LineNumbers
	|	ON Table.ReferenceOrder = LineNumbers.ReferenceOrder
	|		AND Table.Products = LineNumbers.Products
	|		AND Table.Characteristic = LineNumbers.Characteristic
	|		AND Table.Purpose = LineNumbers.Purpose
	|		AND Table.BillOfMaterials = LineNumbers.BillOfMaterials
	|		AND Table.Sender = LineNumbers.Sender
	|		AND Table.Recipient = LineNumbers.Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DataToGenerate_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP LineNumbers
	|";
	QueryText = StrReplace(QueryText, "&TextApart", RequestTextFieldIsSeparate("Table.ReferenceOrder"));
	
	Query = New Query(QueryText);
	Query.SetParameter("DataToGenerate_", DataToGenerate_);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure AllocateQuantity(Required2, Scheduled, Dimension, Balance = Undefined)
	
	Filter = New Structure(Dimension);
	
	For Each LineIsRequired In Required2 Do
		
		FillPropertyValues(Filter, LineIsRequired);
		Var_204_Balance = Scheduled.FindRows(Filter);
		
		For Each StringBalance In Var_204_Balance Do
			If StringBalance.Count > 0 Then
				ReversingEntry = Min(LineIsRequired.Count, StringBalance.Count);
				StringBalance.Count = StringBalance.Count - ReversingEntry;
				LineIsRequired.Count = LineIsRequired.Count - ReversingEntry;
			EndIf;
		EndDo;
		
		If LineIsRequired.Count > 0 And Balance <> Undefined Then
			Balance.Add(LineIsRequired);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//  ValueTable - Data Structure For Generating Stages Constructor:
// * ReferenceOrder - DocumentRef.ProductionOrder2_2
// * Products - CatalogRef.Products
// * Characteristic - CatalogRef.ItemsCharacteristics
// * BillOfMaterials - CatalogRef.BillsOfMaterials
// * Recipient - CatalogRef.BusinessStructure,CatalogRef.Warehouses
// * Sender - CatalogRef.Warehouses
// * Purpose - CatalogRef.Assignments
// * StageSource - DocumentRef.ProductionStage2_2
// * ToExpenseAs - Boolean
// * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems,ChartOfCharacteristicTypesRef.AssetLiabilityItems
// * DimensionOfExpenses - ChartOfCharacteristicTypesRef.ExpenseItems
// * AssetsLiabilitiesDimension - ChartOfCharacteristicTypesRef.AssetLiabilityItems
// * Count - Number
Function DataStructureForGeneratingStagesConstructor()
	
	Result = New ValueTable;
	
	TypeDescription = New TypeDescription("DocumentRef.ProductionOrder2_2");
	Result.Columns.Add("ReferenceOrder", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.Products");
	Result.Columns.Add("Products", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.ItemsCharacteristics");
	Result.Columns.Add("Characteristic", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.BillsOfMaterials");
	Result.Columns.Add("BillOfMaterials", TypeDescription);
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef.BusinessStructure"));
	TypesArray.Add(Type("CatalogRef.Warehouses"));

	TypeDescription = New TypeDescription(TypesArray);
	Result.Columns.Add("Recipient", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.Warehouses");
	Result.Columns.Add("Sender", TypeDescription);
	
	TypeDescription = New TypeDescription("CatalogRef.Assignments");
	Result.Columns.Add("Purpose", TypeDescription);
	
	TypeDescription = New TypeDescription("DocumentRef.ProductionStage2_2");
	Result.Columns.Add("StageSource", TypeDescription);
	
	TypeDescription = New TypeDescription("Boolean");
	Result.Columns.Add("ToExpenseAs", TypeDescription);
	
	TypesArray = New Array;
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.ExpenseItems"));
	TypesArray.Add(Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	
	TypeDescription = New TypeDescription(TypesArray);
	Result.Columns.Add("ExpenseItem", TypeDescription);
	                                    
	Result.Columns.Add("DimensionOfExpenses", Metadata.ChartsOfCharacteristicTypes.ExpenseItems.Type);
	
	Result.Columns.Add("AssetsLiabilitiesDimension", Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems.Type);
	
	TypeDescription = Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative);
	Result.Columns.Add("Count", TypeDescription);
	
	Return Result;
	
EndFunction

// Adds rows to the data for forming stages.
//
// Parameters:
//  Rows - Array of ValueTableRow - Contains:
//                      * Source - DocumentRef.ProductionStage2_2 -
//                      * ReferenceOrder - DocumentRef.ProductionOrder2_2 -
//                      * Products - CatalogRef.Products -
//                      * Characteristic - CatalogRef.ItemsCharacteristics -
//                      * Purpose - CatalogRef.Assignments -
//                      * Stage - DocumentRef.ProductionStage2_2 -
//                      * Warehouse - CatalogRef.Warehouses -
//                      * Department - CatalogRef.BusinessStructure -
//                      * BillOfMaterials - CatalogRef.BillsOfMaterials -
//                      * ToExpenseAs - Boolean -
//                      * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems, ChartOfCharacteristicTypesRef.AssetLiabilityItems -
//                      * DimensionOfExpenses - ChartOfCharacteristicTypesRef.ExpenseItems -
//                      * AssetsLiabilitiesDimension - ChartOfCharacteristicTypesRef.AssetLiabilityItems -
//                      * Count - Number -
//  Table     - See DataStructureForGeneratingStagesConstructor
//  Direction - Number -
//
Procedure AddRowsToDataToFormStages(Rows, Table, Direction)
	
	For Each String In Rows Do
		
		NewRow = Table.Add();
		FillPropertyValues(
			NewRow,
			String,
			"ReferenceOrder,
			|Products,
			|Characteristic,
			|BillOfMaterials,
			|ToExpenseAs,
			|ExpenseItem,
			|DimensionOfExpenses,
			|AssetsLiabilitiesDimension,
			|Count");

		If Direction > 0 Then

			NewRow.Purpose   = String.Purpose;
			NewRow.StageSource = String.Source;

			NewRow.Sender = Catalogs.Warehouses.EmptyRef();
			NewRow.Recipient = ?(ValueIsFilled(String.Warehouse), String.Warehouse, String.Department);

		ElsIf Direction < 0 Then
			
			NewRow.Purpose   = Catalogs.Assignments.EmptyRef();
			NewRow.StageSource = String.Source;
			
			NewRow.Sender = String.Warehouse;
			NewRow.Recipient  = Catalogs.Warehouses.EmptyRef();
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CreateTTStagesProvidingOrders(TempTablesManager, References) Export
	
	QueryText =
		"SELECT
		|	TabularSection.Ref AS OrderDocument,
		|	TabularSection.Products AS Products,
		|	TabularSection.Characteristic AS Characteristic,
		|	TabularSection.Purpose AS Purpose,
		|	TabularSection.Warehouse AS Warehouse,
		|	TabularSection.BillOfMaterials AS BillOfMaterials,
		|	SUM(TabularSection.Count) AS Count,
		|	CASE
		|		WHEN Document.ProductionProcessType = &Disassembly
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END AS ProcessType,
		|	MIN(TabularSection.LineNumber) AS LineNumber
		|INTO TTProductsOrdered
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS TabularSection
		|		LEFT JOIN Document.ProductionOrder2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	TabularSection.Ref IN(&Orders)
		|	AND Document.Posted
		|	AND NOT TabularSection.Canceled
		|
		|GROUP BY
		|	TabularSection.Products,
		|	TabularSection.Purpose,
		|	TabularSection.Warehouse,
		|	TabularSection.Ref,
		|	TabularSection.Characteristic,
		|	TabularSection.BillOfMaterials,
		|	CASE
		|		WHEN Document.ProductionProcessType = &Disassembly
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Document.ReferenceOrder AS OrderDocument,
		|	Document.Ref AS Stage,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END AS ProcessType,
		|	TabularSection.Products AS Products,
		|	TabularSection.Characteristic AS Characteristic,
		|	TabularSection.Purpose AS Purpose,
		|	TabularSection.Recipient AS Warehouse,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN TabularSection.BillOfMaterials
		|		ELSE Document.BillOfMaterials
		|	END AS BillOfMaterials,
		|	SUM(TabularSection.Count) AS Count,
		|	TabularSection.Manufactured AS Manufactured
		|INTO TTIssue
		|FROM
		|	Document.ProductionStage2_2.ManufacturedProducts AS TabularSection
		|		LEFT JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	Document.ReferenceOrder IN(&Orders)
		|	AND Document.Posted
		|	AND NOT TabularSection.Canceled
		|
		|GROUP BY
		|	TabularSection.Recipient,
		|	TabularSection.Purpose,
		|	TabularSection.Characteristic,
		|	TabularSection.Products,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN TabularSection.BillOfMaterials
		|		ELSE Document.BillOfMaterials
		|	END,
		|	Document.Ref,
		|	Document.ReferenceOrder,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END,
		|	TabularSection.Manufactured
		|
		|UNION
		|
		|SELECT
		|	Document.ReferenceOrder,
		|	Document.Ref,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END,
		|	TabularSection.Products,
		|	TabularSection.Characteristic,
		|	TabularSection.Purpose,
		|	TabularSection.Recipient,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN TabularSection.BillOfMaterials
		|		ELSE Document.BillOfMaterials
		|	END,
		|	SUM(TabularSection.Count),
		|	TabularSection.Manufactured
		|FROM
		|	Document.ProductionStage2_2.SideAndIntermediateRelease AS TabularSection
		|		LEFT JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	Document.ReferenceOrder IN(&Orders)
		|	AND Document.Posted
		|	AND NOT TabularSection.Canceled
		|
		|GROUP BY
		|	TabularSection.Recipient,
		|	TabularSection.Purpose,
		|	TabularSection.Characteristic,
		|	TabularSection.Products,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN TabularSection.BillOfMaterials
		|		ELSE Document.BillOfMaterials
		|	END,
		|	Document.Ref,
		|	Document.ReferenceOrder,
		|	CASE
		|		WHEN TabularSection.ProcessByBOM
		|			THEN &Disassembly
		|		ELSE &Assembly
		|	END,
		|	TabularSection.Manufactured
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Document.ReferenceOrder AS OrderDocument,
		|	Document.Ref AS Stage,
		|	&Assembly AS ProcessType,
		|	TabularSection.Products AS Products,
		|	TabularSection.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabularSection.WithAssignment
		|			THEN TabularSection.Purpose
		|		ELSE &EmptyAssignment
		|	END AS Purpose,
		|	TabularSection.Warehouse AS Warehouse,
		|	TabularSection.BillOfMaterials AS BillOfMaterials,
		|	SUM(TabularSection.Count) AS Count
		|INTO TTSoftware
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TabularSection
		|		LEFT JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	Document.ReferenceOrder IN(&Orders)
		|	AND Document.Posted
		|	AND TabularSection.Produced
		|	AND TabularSection.BillOfMaterials <> &EmptySpecification
		|	AND NOT TabularSection.Canceled
		|
		|GROUP BY
		|	TabularSection.Characteristic,
		|	TabularSection.Warehouse,
		|	TabularSection.Products,
		|	Document.Ref,
		|	TabularSection.BillOfMaterials,
		|	Document.ReferenceOrder,
		|	CASE
		|		WHEN TabularSection.WithAssignment
		|			THEN TabularSection.Purpose
		|		ELSE &EmptyAssignment
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	Document.ReferenceOrder,
		|	Document.Ref,
		|	&Disassembly,
		|	TabularSection.Products,
		|	TabularSection.Characteristic,
		|	CASE
		|		WHEN TabularSection.WithAssignment
		|			THEN TabularSection.Purpose
		|		ELSE &EmptyAssignment
		|	END,
		|	TabularSection.Warehouse,
		|	Document.BillOfMaterials,
		|	SUM(TabularSection.Count)
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS TabularSection
		|		LEFT JOIN Document.ProductionStage2_2 AS Document
		|		ON TabularSection.Ref = Document.Ref
		|WHERE
		|	Document.ReferenceOrder IN(&Orders)
		|	AND Document.Posted
		|	AND Document.ProductionProcessType = &Disassembly
		|	AND NOT TabularSection.Produced
		|	AND NOT TabularSection.Canceled
		|
		|GROUP BY
		|	Document.Ref,
		|	TabularSection.Products,
		|	TabularSection.Warehouse,
		|	TabularSection.Characteristic,
		|	Document.ReferenceOrder,
		|	Document.BillOfMaterials,
		|	CASE
		|		WHEN TabularSection.WithAssignment
		|			THEN TabularSection.Purpose
		|		ELSE &EmptyAssignment
		|	END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TTOrdered.Products AS Products,
		|	TTOrdered.Characteristic AS Characteristic,
		|	TTOrdered.Purpose AS Purpose,
		|	TTOrdered.Warehouse AS Warehouse,
		|	TTOrdered.BillOfMaterials AS BillOfMaterials,
		|	TTOrdered.OrderDocument AS OrderDocument,
		|	TTIssue.Stage AS Stage
		|INTO TTStagesProvidingOrders
		|	
		|FROM
		|	TTProductsOrdered AS TTOrdered
		|		INNER JOIN TTIssue AS TTIssue
		|		ON TTOrdered.OrderDocument = TTIssue.OrderDocument
		|			AND TTOrdered.Products = TTIssue.Products
		|			AND TTOrdered.Characteristic = TTIssue.Characteristic
		|			AND TTOrdered.Purpose = TTIssue.Purpose
		|			AND TTOrdered.Warehouse = TTIssue.Warehouse
		|			AND TTOrdered.BillOfMaterials = TTIssue.BillOfMaterials
		|			AND TTOrdered.ProcessType = TTIssue.ProcessType
		|WHERE
		|	TTOrdered.ProcessType = &Assembly
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	TTOrdered.Products,
		|	TTOrdered.Characteristic,
		|	TTOrdered.Purpose,
		|	TTOrdered.Warehouse,
		|	TTOrdered.BillOfMaterials,
		|	TTOrdered.OrderDocument,
		|	TTSoftware.Stage
		|FROM
		|	TTProductsOrdered AS TTOrdered
		|		INNER JOIN TTSoftware AS TTSoftware
		|		ON TTOrdered.OrderDocument = TTSoftware.OrderDocument
		|			AND TTOrdered.Products = TTSoftware.Products
		|			AND TTOrdered.Characteristic = TTSoftware.Characteristic
		|			AND TTOrdered.Purpose = TTSoftware.Purpose
		|			AND TTOrdered.Warehouse = TTSoftware.Warehouse
		|			AND TTOrdered.BillOfMaterials = TTSoftware.BillOfMaterials
		|			AND TTOrdered.ProcessType = TTSoftware.ProcessType
		|WHERE
		|	TTOrdered.ProcessType = &Disassembly";
	
	Query = New Query(QueryText);
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Orders", References);
	Query.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	Query.SetParameter("EmptySpecification", Catalogs.BillsOfMaterials.EmptyRef());
	Query.SetParameter("Assembly", Enums.ProductionProcessTypes.Assembly);
	Query.SetParameter("Disassembly", Enums.ProductionProcessTypes.Disassembly);
	
	Query.Execute();
	
EndProcedure

Procedure CreateTTWaysToGetMaterials2_2(TempTablesManager, References) Export
	
	// The procedure initializes the redefinition of the NSI for a specific order (Warehouse, Separate attribute).
	// The procedure creates temporary tables that can be reused during the formation of stages. For example, when replacing with analogs, in the procedure to create an exception to the changesanalogs.
	Query = New Query();
	Query.Text =
		QueryTextEnsuringOrderOfGiveawayMaterials(True)
		+ TMCommonUse.RequestSeparatorInPacket_() 
		+ QueryTextEnsuringOrderOfDisassembledProducts(True)
		+ TMCommonUse.RequestSeparatorInPacket_()
		+ QueryTextTTMethodsOfObtainingMaterials2_2(True); 
	Query.SetParameter("References", References);
	Query.TempTablesManager = TempTablesManager;
	SetPrivilegedMode(True);
	Query.Execute();
	
EndProcedure

Function QueryTextTTMethodsOfObtainingMaterials2_2(DataSourcesAreGeneratedSeparately = False) Export
	
	QueryText =
		"SELECT
		|	UsedMaterials.ReferenceOrder      AS ReferenceOrder,
		|	UsedMaterials.Products      AS Products,
		|	UsedMaterials.Characteristic    AS Characteristic,
		|	UsedMaterials.Warehouse             AS Warehouse,
		|	TRUE                      AS WithAssignment
		|
		|INTO TTMethodsOfObtainingMaterials
		|FROM
		|	TTProvisionOfOrderGiveawayMaterials AS UsedMaterials
		|
		|WHERE
		|	NOT UsedMaterials.DynamicStructure
		|
		|UNION
		|
		|SELECT
		|	ProductsBeingDisassembled.ReferenceOrder      AS ReferenceOrder,
		|	ProductsBeingDisassembled.Products      AS Products,
		|	ProductsBeingDisassembled.Characteristic    AS Characteristic,
		|	ProductsBeingDisassembled.Warehouse             AS Warehouse,
		|	UNDEFINED                         AS WithAssignment
		|FROM
		|	TTOrderAssuranceDisassembledProducts AS ProductsBeingDisassembled
		|
		|WHERE
		|	NOT ProductsBeingDisassembled.DynamicStructure
		|
		|UNION ALL
		|
		|SELECT
		|	ProductionOrders.Ref AS ReferenceOrder,
		|	UNDEFINED                AS Products,
		|	UNDEFINED                AS Characteristic,
		|	UNDEFINED                AS Warehouse,
		|	TRUE                      AS WithAssignment
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrders
		|WHERE
		|	ProductionOrders.Ref IN(&References)
		|		AND ProductionOrders.SupplyOfAssignedMaterialsAndWorks
		|		AND NOT ProductionOrders.DynamicStructure
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Products,
		|	Characteristic,
		|	Warehouse";
		
	If Not DataSourcesAreGeneratedSeparately Then
		QueryText = StrReplace(QueryText, "TTProvisionOfOrderGiveawayMaterials", "(" + QueryTextEnsuringOrderOfGiveawayMaterials() + ")");
		QueryText = StrReplace(QueryText, "TTOrderAssuranceDisassembledProducts", "(" + QueryTextEnsuringOrderOfDisassembledProducts() + ")");
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure CreateTTExceptionsReplacingWithAnalogs(TempTablesManager, References) Export
	
	QueryText =
		"SELECT
		|	UsedMaterials.ReferenceOrder      AS ReferenceOrder,
		|	UsedMaterials.Products      AS Products,
		|	UsedMaterials.Characteristic    AS Characteristic,
		|	UsedMaterials.Warehouse             AS Warehouse
		|
		|INTO TTExceptionsReplacementWithAnalogs
		|FROM
		|	TTProvisionOfOrderGiveawayMaterials AS UsedMaterials
		|
		|UNION
		|
		|SELECT
		|	ProductsBeingDisassembled.ReferenceOrder      AS ReferenceOrder,
		|	ProductsBeingDisassembled.Products      AS Products,
		|	ProductsBeingDisassembled.Characteristic    AS Characteristic,
		|	ProductsBeingDisassembled.Warehouse             AS Warehouse
		|FROM
		|	TTOrderAssuranceDisassembledProducts AS ProductsBeingDisassembled
		|
		|INDEX BY
		|	ReferenceOrder,
		|	Products,
		|	Characteristic,
		|	Warehouse";
	
	If TempTablesManager.Tables.Find("TTProvisionOfOrderGiveawayMaterials") = Undefined Then
		QueryText = StrReplace(QueryText, "TTProvisionOfOrderGiveawayMaterials", "(" + QueryTextEnsuringOrderOfGiveawayMaterials() + ")");
	EndIf;
	
	If TempTablesManager.Tables.Find("TTOrderAssuranceDisassembledProducts") = Undefined Then
		QueryText = StrReplace(QueryText, "TTOrderAssuranceDisassembledProducts", "(" + QueryTextEnsuringOrderOfDisassembledProducts() + ")");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	Query.TempTablesManager = TempTablesManager;
	SetPrivilegedMode(True);
	Query.Execute();
	
EndProcedure

Function QueryTextEnsuringOrderOfGiveawayMaterials(PutInTemporaryTable = False)
	
	QueryText =
		"SELECT
		|	ProductionOrders.Ref                AS ReferenceOrder,
		|	ProductionOrders.DynamicStructure AS DynamicStructure,
		|	TableMaterials.Products              AS Products,
		|	TableMaterials.Characteristic            AS Characteristic,
		|	MAX(TableMaterials.Warehouse)           AS Warehouse
		|
		|INTO TTProvisionOfOrderGiveawayMaterials
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrders
		|		
		|		LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS ProductsProductionOrder
		|		ON ProductsProductionOrder.Ref = ProductionOrders.Ref
		|		AND NOT ProductsProductionOrder.Canceled
		|		
		|		LEFT JOIN Document.MaterialProviderOrder2_5 AS GiverSOrders
		|		ON GiverSOrders.Purpose = ProductsProductionOrder.Purpose
		|		AND GiverSOrders.Posted
		|		
		|		LEFT JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS TableMaterials
		|		ON TableMaterials.Ref = GiverSOrders.Ref
		|WHERE
		|	ProductionOrders.Ref IN(&References)
		|	AND ProductionOrders.ProductionProcessType IN (
		|		VALUE(Enum.ProductionProcessTypes.Assembly),
		|		VALUE(Enum.ProductionProcessTypes.PerformRM),
		|		VALUE(Enum.ProductionProcessTypes.Repair))
		|	AND ProductionOrders.BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
		|	AND NOT TableMaterials.Ref IS NULL
		|	AND NOT TableMaterials.Canceled
		|
		|GROUP BY
		|	ProductionOrders.Ref,
		|	ProductionOrders.DynamicStructure,
		|	TableMaterials.Products,
		|	TableMaterials.Characteristic
		|";
	If Not PutInTemporaryTable Then
		QueryText = StrReplace(QueryText, "INTO TTProvisionOfOrderGiveawayMaterials", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextEnsuringOrderOfDisassembledProducts(PutInTemporaryTable = False)
	
	QueryText =
		"SELECT
		|	ProductionOrders.Ref                   AS ReferenceOrder,
		|	ProductionOrders.DynamicStructure    AS DynamicStructure,
		|	ProductsProductionOrder.Products    AS Products,
		|	ProductsProductionOrder.Characteristic  AS Characteristic,
		|	MAX(ProductsProductionOrder.Warehouse) AS Warehouse
		|
		|INTO TTOrderAssuranceDisassembledProducts
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrders
		|		INNER JOIN Document.ProductionOrder2_2.ManufacturedProduct AS ProductsProductionOrder
		|		ON ProductsProductionOrder.Ref = ProductionOrders.Ref
		|		AND NOT ProductsProductionOrder.Canceled
		|WHERE
		|	ProductionOrders.Ref IN (&References)
		|	AND ProductionOrders.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|
		|GROUP BY
		|	ProductionOrders.Ref,
		|	ProductionOrders.DynamicStructure,
		|	ProductsProductionOrder.Products,
		|	ProductsProductionOrder.Characteristic
		|";
	If Not PutInTemporaryTable Then
		QueryText = StrReplace(QueryText, "INTO TTOrderAssuranceDisassembledProducts", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region OrderState



Function RequestTextForCalculatingOrderStates(SelectionOrderTypes) Export
	
	QueryTexts = New Array();
	
	QueryTexts.Add(QueryTextTTPendingOrders(SelectionOrderTypes));
	QueryTexts.Add(QueryTextTTStageGenerationIsRequired(SelectionOrderTypes));
	QueryTexts.Add(QueryTextTTStatesOfStages());
	
	QueryText =
		"SELECT
		|	DocumentAttributes.Ref             AS OrderDocument,
		|
		|	CASE
		|		WHEN NOT TTStateStages.Ref IS NULL AND TTStateStages.StateAtIntershopLevel = VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification)
		|			THEN VALUE(Enum.StatesOfQueuedProductionOrders.ItIsRequiredToCheckStages)
		|	
		|		WHEN NOT TTIsRequiredToFormStages.Ref IS NULL
		|			THEN VALUE(Enum.StatesOfQueuedProductionOrders.StageGenerationIsRequired)
		|	
		|		WHEN NOT TTStateStages.Ref IS NULL AND TTStateStages.StateAtIntershopLevel = VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment)
		|			THEN VALUE(Enum.StatesOfQueuedProductionOrders.ItIsRequiredToReleaseStages)
		|	
		|		ELSE
		|			VALUE(Enum.StatesOfQueuedProductionOrders.EmptyRef)
		|
		|	END                                 AS StageStatus,
		|
		|	CASE
		|		WHEN NOT TTStateStages.Ref IS NULL AND TTStateStages.RequiresSupply
		|			THEN VALUE(Enum.StatesOfQueuedProductionOrders.SupplyIsRequired)
		|		
		|		ELSE
		|			VALUE(Enum.StatesOfQueuedProductionOrders.EmptyRef)
		|
		|	END                                 AS SupplyState,
		|
		|	CASE
		|		WHEN DocumentAttributes.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|					AND NOT DocumentAttributes.DynamicStructure THEN
		|
		|			VALUE(Enum.StatesOfQueuedProductionOrders.EmptyRef)
		|
		|		ELSE
		|			CASE
		|				WHEN TTPendingOrders.Ref IS NULL
		|					THEN VALUE(Enum.StatesOfQueuedProductionOrders.Completed)
		|
		|				WHEN &TheProductionScheduleIsUsed
		|						AND ISNULL(TTPendingOrders.DemandDate, DATETIME(1,1,1)) <> DATETIME(1,1,1)
		|						AND TRUE IN
		|							(SELECT TOP 1
		|								TRUE
		|							FROM
		|								InformationRegister.ScheduleOfProductionStages2_2 AS Schedule
		|							WHERE
		|								Schedule.Ending > TTPendingOrders.DemandDate
		|								AND Schedule.ProductionOrder = TTPendingOrders.Ref
		|								AND Schedule.ScheduleStatus = &StatusWorkingSchedule)
		|					THEN VALUE(Enum.StatesOfQueuedProductionOrders.DemandDateIsViolated)
		|
		|				ELSE
		|					VALUE(Enum.StatesOfQueuedProductionOrders.EmptyRef)
		|				END
		|
		|	END                                 AS StatusOfProductionIssue,
		|
		|	CASE
		|		WHEN TTPendingOrders.Ref IS NOT NULL THEN 
		|			TTPendingOrders.DemandDate
		|		ELSE
		|			DATETIME(1,1,1)
		|	END                                 AS EventDate,
		|
		|	CASE
		|		WHEN DocumentAttributes.Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
		|				AND DocumentAttributes.Posted THEN 
		|			TRUE
		|		ELSE
		|			FALSE
		|	END                                 AS ActiveStatus
		|
		|FROM
		|	Document.ProductionOrder2_2 AS DocumentAttributes
		|
		|		LEFT JOIN TTStateStages AS TTStateStages
		|		ON TTStateStages.Ref = DocumentAttributes.Ref
		|
		|		LEFT JOIN TTPendingOrders AS TTPendingOrders
		|		ON TTPendingOrders.Ref = DocumentAttributes.Ref
		|
		|		LEFT JOIN TTIsRequiredToFormStages AS TTIsRequiredToFormStages
		|		ON TTIsRequiredToFormStages.Ref = DocumentAttributes.Ref
		|
		|WHERE 
		|	DocumentAttributes.Ref IN (&ReferencesArrray)";
	
	QueryTexts.Add(QueryText);
	
	Return ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	
EndFunction

Function QueryTextTTStatesOfStages()
	
	QueryText = 
		"SELECT
		|	Table.Ref             AS Ref,
		|	CASE
		|		WHEN Table.StatusCode = 1
		|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification)
		|		WHEN Table.StatusCode = 2
		|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment)
		|	END                      AS StateAtIntershopLevel,
		|	Table.RequiresSupply AS RequiresSupply
		|INTO TTStateStages
		|FROM
		|	(SELECT
		|		Table.ReferenceOrder AS Ref,
		|		MIN(CASE
		|				WHEN Table.StateAtIntershopLevel = VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification)
		|					THEN 1
		|				WHEN Table.StateAtIntershopLevel = VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment)
		|					THEN 2
		|				ELSE 3
		|			END) AS StatusCode,
		|		MAX(Table.RequiresSupply) AS RequiresSupply
		|	FROM
		|		InformationRegister.ProductionStageStates AS Table
		|	WHERE
		|		Table.ReferenceOrder IN(&ReferencesArrray)
		|		AND (Table.StateAtIntershopLevel IN (VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification),
		|													VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment))
		|				OR Table.RequiresSupply)
		|	
		|	GROUP BY
		|		Table.ReferenceOrder) AS Table";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPendingOrders(SelectionOrderTypes)
	
	TextsSelection = New Array;
	TextsTemporaryTables = New Array;
	
	If SelectionOrderTypes.ThereAreOrdersStaticStructure Then
	
		QueryText =
			"SELECT DISTINCT
			|
			|	Table.ReferenceOrder        AS ReferenceOrder,
			|	Table.Products        AS Products,
			|	Table.Characteristic      AS Characteristic,
			|	Table.Purpose          AS Purpose
			|
			|INTO TTSelectionOfSsProducts
			|FROM
			|	AccumulationRegister.ProductionProcessSupply AS Table
			|WHERE
			|	Table.Recorder IN (&ReferencesArrray) AND Table.Required2 > 0
			|
			|INDEX BY
			|	ReferenceOrder,
			|	Products,
			|	Characteristic,
			|	Purpose
			|";
		TextsTemporaryTables.Add(QueryText);
		
		QueryText =
			"SELECT
			|	Table.ReferenceOrder AS Ref,
			|   Table.ReferenceOrder.DemandDate AS DemandDate
			|FROM
			|	(SELECT
			|		Table.ReferenceOrder   AS ReferenceOrder,
			|		Table.Products   AS Products,
			|		Table.Characteristic AS Characteristic,
			|		Table.Purpose     AS Purpose
			|	FROM
			|		AccumulationRegister.ProductionProcessSupply AS Table
			|
			|	WHERE
			|		(Table.ReferenceOrder, Table.Products, Table.Characteristic, Table.Purpose) IN
			|				(SELECT
			|					Filter.ReferenceOrder,
			|					Filter.Products,
			|					Filter.Characteristic,
			|					Filter.Purpose
			|				FROM
			|					TTSelectionOfSsProducts AS Filter)
			|
			|GROUP BY
			|		Table.ReferenceOrder,
			|		Table.Products,
			|		Table.Characteristic,
			|		Table.Purpose
			|
			|	HAVING
			|		SUM(Table.Required2)
			|			* CASE
			|				WHEN Table.Products.UnitOfMeasure.MeasuredValueType IN (
			|														VALUE(Enum.TypesOfMeasuredValues.Weight),
			|														VALUE(Enum.TypesOfMeasuredValues.Length),
			|														VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
			|														VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
			|					THEN 1 - &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|				ELSE 1
			|			END > SUM(Table.Manufactured)
			|	
			|	) AS Table
			|GROUP BY
			|		Table.ReferenceOrder
			|";
		TextsSelection.Add(QueryText);
		
	EndIf;
	
	If SelectionOrderTypes.ThereAreOrdersDynamicStructure Then
		
		QueryText =
			"SELECT
			|	Table.ProductionOrder AS Ref,
			|   MIN(Table.DemandDate) AS DemandDate
			|FROM
			|	(SELECT
			|		Table.Products        AS Products,
			|		Table.Characteristic      AS Characteristic,
			|		Table.Warehouse               AS Warehouse,
			|		Table.Purpose          AS Purpose,
			|		Table.ProductionOrder AS ProductionOrder,
			|		Table.KeyProducts    AS KeyProducts,
			|		MIN(OrderProducts_.DemandDate) AS DemandDate
			|	FROM
			|		InformationRegister.OrderStructure AS Table
			|
			|			LEFT JOIN Document.ProductionOrder2_2.ManufacturedProduct AS OrderProducts_
			|			ON OrderProducts_.Ref = Table.ProductionOrder
			|				AND OrderProducts_.KeyProducts = Table.KeyProducts
			|
			|	WHERE
			|		Table.ProductionOrder IN (&ReferencesArrray)
			|			AND Table.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.ManufacturedProduct)
			|
			|GROUP BY
			|		Table.Products,
			|		Table.Characteristic,
			|		Table.Warehouse,
			|		Table.Purpose,
			|		Table.ProductionOrder,
			|		Table.KeyProducts
			|
			|	HAVING
			|		SUM(Table.Ordered)
			|			* CASE
			|				WHEN Table.Products.UnitOfMeasure.MeasuredValueType IN (
			|													VALUE(Enum.TypesOfMeasuredValues.Weight),
			|													VALUE(Enum.TypesOfMeasuredValues.Length),
			|													VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
			|													VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
			|					THEN 1 - &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|				ELSE 1
			|			END > 0
			|	) AS Table
			|
			|GROUP BY
			|		Table.ProductionOrder
			|";
		TextsSelection.Add(QueryText);
		
	EndIf;
	
	QueryText = ?(TextsTemporaryTables.Count() = 0, 
		"", StrConcat(TextsTemporaryTables, Common.QueryBatchSeparator()) + Common.QueryBatchSeparator())
		+ StrReplace(
			"SELECT
			|	Table.Ref AS Ref,
			|	Table.DemandDate AS DemandDate
			|INTO TTPendingOrders
			|FROM
			|	MergingDataSamplingTables AS Table
			|
			|INDEX BY
			|	Ref,
			|	DemandDate",
			"MergingDataSamplingTables",
			"(" + StrConcat(TextsSelection, TMCommonUse.QuerySeparatorInJoin()) + ")");

	Return QueryText;
	
EndFunction

#EndRegion

#Region ClosingControl

Function QueryTextOrderClosingControl(OrdersByStructureType)
	
	TextsSelection = New Array;
	TextsTemporaryTables = New Array;
	
#Region ItemsForProduction
	
	// Static Structure
	
	If OrdersByStructureType.StaticOrders.Count() > 0 Then
		
		VerificationIndicator = IndicatorIsNotManufacturedProducts();
		
		RequestTextsProductsForProduction =
		RequestTextsProductsForProduction(True, VerificationIndicator,, False, "ReferenceOrder IN (&ArrayOfLinksStaticOrders)");
	
		TextsTemporaryTables.Add(RequestTextsProductsForProduction.QueryTextSource);
		TextsTemporaryTables.Add(RequestTextsProductsForProduction.QueryTextAdditional);
		TextsTemporaryTables.Add(RequestTextsProductsForProduction.QueryTextMain);
		
		QueryText =
			"SELECT DISTINCT
			|	Table.ReferenceOrder AS Ref
			|FROM
			|	TTProductsForProduction AS Table
			|";
		TextsSelection.Add(QueryText);
	
	EndIf;
	
	// Dynamic Structure
	If OrdersByStructureType.DynamicOrders.Count() > 0 Then
				
		QueryText = 
			"SELECT DISTINCT
			|
			|	Table.ProductionOrder AS ProductionOrder,
			|	Table.Products        AS Products,
			|	Table.Characteristic      AS Characteristic,
			|	Table.Purpose          AS Purpose
			|
			|INTO TTSelectionOfCashProducts
			|FROM
			|	InformationRegister.ProductionOrders AS Table
			|WHERE
			|	Table.Recorder IN (&ArrayOfLinksDynamicOrders) AND Table.ToProduce > 0
			|
			|INDEX BY
			|	ProductionOrder,
			|	Products,
			|	Characteristic,
			|	Purpose
			|";
		TextsTemporaryTables.Add(QueryText);
		
		QueryText =
			"SELECT DISTINCT
			|	Table.ProductionOrder AS Ref
			|
			|FROM
			|	(SELECT
			|		Table.ProductionOrder AS ProductionOrder,
			|		Table.Products        AS Products,
			|		Table.Characteristic      AS Characteristic,
			|		Table.Purpose          AS Purpose
			|	FROM
			|		InformationRegister.ProductionOrders AS Table
			|
			|		INNER JOIN TTSelectionOfCashProducts AS Filter
			|		ON Filter.ProductionOrder = Table.ProductionOrder
			|		AND Filter.Products = Table.Products
			|		AND Filter.Characteristic = Table.Characteristic
			|		AND Filter.Purpose = Table.Purpose
			|
			|GROUP BY
			|		Table.ProductionOrder,
			|		Table.Products,
			|		Table.Characteristic,
			|		Table.Purpose
			|
			|	HAVING
			|		SUM(Table.ToProduce)
			|			* CASE
			|				WHEN Table.Products.UnitOfMeasure.MeasuredValueType IN (
			|													VALUE(Enum.TypesOfMeasuredValues.Weight),
			|													VALUE(Enum.TypesOfMeasuredValues.Length),
			|													VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
			|													VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement))
			|					THEN 1 - &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100
			|				ELSE 1
			|			END > SUM(Table.Done + Table.ReverseKittingCompleted)
			|	) AS Table
			|";
		TextsSelection.Add(QueryText);
		
	EndIf;

#EndRegion
	
	QueryText = StrConcat(TextsTemporaryTables, Common.QueryBatchSeparator())
		+ Common.QueryBatchSeparator()
		+ StrReplace(
			"SELECT DISTINCT
			|	Table.Ref AS Ref
			|INTO TTOrderClosingControl
			|FROM
			|	MergingDataSamplingTables AS Table",
			"MergingDataSamplingTables",
			"(" + StrConcat(TextsSelection, TMCommonUse.QuerySeparatorInJoin()) + ")");
	
	Return QueryText;
	
EndFunction

Procedure PerformSubstitutionRequestTextOrderClosingControl(QueryText, MonitorOrderFulfillment, OrdersByStructureType)
	
	If Not MonitorOrderFulfillment Then
		
		QueryText = StrReplace(QueryText, "&OrderClosingControl", "FALSE");
		QueryText = StrReplace(QueryText, "&ConnectionOrderClosingControl,", "");
		
		Return;
	EndIf;
	
	Package = New Array;
	Package.Add(QueryTextOrderClosingControl(OrdersByStructureType));
	
	SubstitutionField = "
	|	CASE
	|		WHEN TTOrderClosingControl.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END";
	QueryText = StrReplace(QueryText, "&OrderClosingControl", SubstitutionField);
	
	SubstitutionField = "
	|LEFT JOIN
	|	TTOrderClosingControl
	|ON
	|	TTOrderClosingControl.Ref = DocumentsTable.Ref";
	QueryText = StrReplace(QueryText, "&ConnectionOrderClosingControl,", SubstitutionField);
	
	Package.Add(QueryText);
	
	QueryText = StrConcat(Package, Common.QueryBatchSeparator());
	
EndProcedure

Function QueryTextControlOfCostAllocation()
	
	QueryText =
	"SELECT
	|	Costs.ReferenceOrder				AS ReferenceOrder,
	|	MAX(Costs.Month)	AS Month
	|INTO TTCosts
	|FROM
	|	(SELECT
	|		GoodsTable.Ref.ReferenceOrder								AS ReferenceOrder,
	|		ENDOFPERIOD(GoodsTable.DateOfMaterialWorkConsumption, MONTH)	AS Month
	|	FROM
	|		Document.ProductionStage2_2.MaterialsAndWorksConsumption AS GoodsTable
	|	WHERE
	|		&Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|		AND GoodsTable.Ref.ReferenceOrder IN (&ReferencesArrray)
	|		AND GoodsTable.Ref.Posted
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.Ref.ReferenceOrder											AS ReferenceOrder,
	|		ENDOFPERIOD(GoodsTable.ExecutionDate, MONTH)	AS Month
	|	FROM
	|		Document.ProductionStage2_2.LaborCosts AS GoodsTable
	|	WHERE
	|		&Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|		AND GoodsTable.Ref.ReferenceOrder IN (&ReferencesArrray)
	|		AND GoodsTable.Ref.Posted
	|		AND GoodsTable.Completed2
	|		AND NOT GoodsTable.Canceled
	|	) AS Costs
	|
	|GROUP BY
	|	Costs.ReferenceOrder
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ManufacturedProduct.ReferenceOrder				AS ReferenceOrder,
	|	MAX(ManufacturedProduct.Month)	AS Month
	|INTO TTManufacturedProduct
	|FROM
	|	(SELECT 
	|		GoodsTable.Ref.ReferenceOrder											AS ReferenceOrder,
	|		ENDOFPERIOD(GoodsTable.ProductionDate, MONTH)	AS Month
	|	FROM
	|		Document.ProductionStage2_2.ManufacturedProducts AS GoodsTable
	|	WHERE
	|		&Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|		AND GoodsTable.Ref.ReferenceOrder IN (&ReferencesArrray)
	|		AND GoodsTable.Ref.Posted
	|		AND NOT GoodsTable.Ref.ProductionByThirdParty
	|		AND GoodsTable.Manufactured
	|		AND NOT GoodsTable.Canceled
	|
	|	UNION ALL
	|
	|	SELECT 
	|		GoodsTable.ProductionStage.ReferenceOrder    AS ReferenceOrder,
	|		ENDOFPERIOD(GoodsTable.Ref.Date, MONTH) AS Month
	|	FROM
	|		Document.SubcontractorReport2_5.ManufacturedProducts AS GoodsTable
	|	WHERE
	|		&Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|		AND GoodsTable.ProductionStage.ReferenceOrder IN (&ReferencesArrray)
	|		AND GoodsTable.Ref.Posted
	|	) AS ManufacturedProduct
	|
	|GROUP BY
	|	ManufacturedProduct.ReferenceOrder
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTCosts.ReferenceOrder AS Ref
	|INTO TTCostAllocationControl
	|FROM
	|	TTCosts AS TTCosts
	|
	|	INNER JOIN TTManufacturedProduct AS TTManufacturedProduct
	|	ON TTManufacturedProduct.ReferenceOrder = TTCosts.ReferenceOrder
	|	AND TTManufacturedProduct.Month < TTCosts.Month
	|
	|INDEX BY
	|	Ref
	|";
	
	Return QueryText;
	
EndFunction

Procedure PerformQueryTextSubstitutionCostAllocationControl(QueryText)
	
	Package = New Array;
	Package.Add(QueryTextControlOfCostAllocation());
	
	SubstitutionField = "
	|	CASE
	|		WHEN TTCostAllocationControl.Ref IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END";
	QueryText = StrReplace(QueryText, "&ControlOfCostAllocation", SubstitutionField);
	
	SubstitutionField = "
	|
	|	LEFT JOIN TTCostAllocationControl AS TTCostAllocationControl
	|	ON TTCostAllocationControl.Ref = DocumentsTable.Ref
	|";
	
	QueryText = StrReplace(QueryText, "&EffectiveControlOfCostAllocation", SubstitutionField);
	
	Package.Add(QueryText);
	
	QueryText = StrConcat(Package, Common.QueryBatchSeparator());
	
EndProcedure

#EndRegion

#Region MaterialProvider

// Generates the query result for the undelivered part of orders
//
// Parameters:
//	AnArrayOfOrders - Array of DocumentRef.MaterialProviderOrder2_5 - The order of the giver, for which it is necessary to create / re-fill an order for the production of products on the order of the giver.
//	ProductionProcessType - EnumRef.ProductionProcessTypes - selection of lines by type of production process.
//  CurrentObjectData - Structure, ClientApplicationForm - Cur current data of the document being edited. If the call comes from a form,
//                                                           then the Client's formapplications or structure with keys:
//                                                             * Object - DocumentObject.ProductionOrder2_2 - the item being edited.
//                                                             * Modified - Boolean - the modification attribute
// Returns:
//	ValueTable - a table for filling in the tabular part of the production order for production by order of the giver.
//
Function ProductionResiduesToProvideGiver(AnArrayOfOrders, ProductionProcessType = Undefined, CurrentObjectData = Undefined) Export

	QueryTexts = New Array();
	
	// Goods from the giver's order
	QueryText =
		"SELECT
		|	Table.LineNumber            AS LineNumber,
		|	Table.Products           AS Products,
		|	Table.Characteristic         AS Characteristic,
		|	Table.Ref.Purpose      AS Purpose,
		|	CASE
		|		WHEN Table.Products.ItemsType IN (
		|							VALUE(Enum.ItemsTypes.OwnGoods),
		|							VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN Table.Warehouse
		|		ELSE Table.Department
		|	END                          AS Warehouse,
		|	Table.DateOfShipment           AS DemandDate,
		|	Table.BillOfMaterials           AS BillOfMaterials,
		|	Table.Package               AS Package,
		|	Table.Count             AS Count
		|INTO TTOrderGiver
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|	AND Table.WithAssignment
		|	AND (&ProductionProcessType <> UNDEFINED
		|			AND Table.Ref.ProductionProcessType = &ProductionProcessType
		|		OR &ProductionProcessType = UNDEFINED)
		|	AND NOT Table.Canceled
		|";
	QueryTexts.Add(QueryText);
	
	// Goods delivered earlier (with amended collateral)
	ThereIsAdjustment = CurrentObjectData <> Undefined And CurrentObjectData.Modified;
	If ThereIsAdjustment Then
		
		QueryText = 
			// Based on the text of the function request to reflect the distribution of the movement reserves.
			"SELECT
			|	TabPart.Purpose AS Purpose,
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	CASE
			|		WHEN VALUETYPE(TabPart.Warehouse) = TYPE(Catalog.Warehouses)
			|			THEN TabPart.Warehouse
			|		ELSE TabPart.Department
			|	END AS Warehouse,
			|	TabPart.Count AS Ordered,
			|	CASE
			|		WHEN
			|			&Status = VALUE(Enum.ProductionOrderStatuses2_2.ToProduce)
			|				AND NOT TabPart.ToExpenseAs
			|				AND TabPart.DemandDate <> DATETIME(1, 1, 1)
			|			THEN TabPart.Count
			|		ELSE 0
			|	END AS Received_1
			|INTO TabPart
			|FROM
			|	&TS AS TabPart";
		QueryTexts.Add(QueryText);
		
		QueryText = 
			"SELECT
			|	RegisterRecords.Products AS Products,
			|	RegisterRecords.Characteristic AS Characteristic,
			|	RegisterRecords.Warehouse AS Warehouse,
			|	RegisterRecords.Purpose AS Purpose,
			|	RegisterRecords.InStock AS InStock,
			|	RegisterRecords.LockedInStock AS LockedInStock,
			|	RegisterRecords.OrderDocument AS OrderDocument,
			|	RegisterRecords.Ordered AS Ordered,
			|	RegisterRecords.Received_1 AS Received_1,
			|	RegisterRecords.LockedReceipt AS LockedReceipt,
			|	RegisterRecords.ToUnlock AS ToUnlock,
			|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	RegisterRecords.ReserveAsReceived AS ReserveAsReceived,
			|	RegisterRecords.SnoozeReservation AS SnoozeReservation,
			|	RegisterRecords.ToSupply AS ToSupply,
			|	RegisterRecords.NotProvide AS NotProvide,
			|	RegisterRecords.ReserveAtWarehouse AS ReserveAtWarehouseFromLocked,
			|	RegisterRecords.ReserveAsReceived AS ReserveUponReceiptFromLocked
			|INTO InventoryAndNeedsStorno
			|FROM
			|	AccumulationRegister.InventoryAndDemands AS RegisterRecords
			|WHERE
			|	RegisterRecords.Active
			|	AND RegisterRecords.Recorder = &CurrentDocument
			|	AND RegisterRecords.EntryType = VALUE(Enum.RecordTypesInventoryAndDemands.PrimaryRegisterRecord)
			|	AND (RegisterRecords.Products, RegisterRecords.Characteristic, RegisterRecords.Warehouse, RegisterRecords.Purpose) IN(
			|		SELECT
			|			FilterOfProducts_.Products AS Products,
			|			FilterOfProducts_.Characteristic AS Characteristic,
			|			FilterOfProducts_.Warehouse AS Warehouse,
			|			FilterOfProducts_.Purpose AS Purpose
			|		FROM
			|			TTOrderGiver AS FilterOfProducts_)
			|
			|UNION ALL
			|
			// Based on the text of the function request to reflect the distribution of the movement reserves.
			|SELECT
			|	TabPart.Products AS Products,
			|	TabPart.Characteristic AS Characteristic,
			|	TabPart.Warehouse AS Warehouse,
			|	TabPart.Purpose AS Purpose,
			|	0 AS InStock,
			|	0 AS LockedInStock,
			|	&CurrentDocument AS OrderDocument,
			|	- TabPart.Ordered AS Ordered,
			|	- TabPart.Received_1 AS Received_1,
			|	0 AS LockedReceipt,
			|	0 AS ToUnlock,
			|	0 AS ReserveAtWarehouseBalance,
			|	0 AS ReserveAsReceivedBalance,
			|	0 AS SnoozeReservationBalance,
			|	0 AS ToSupplyBalance,
			|	0 AS NotProvideBalance,
			|	0 AS ReserveAtWarehouseFromLocked,
			|	0 AS ReserveUponReceiptFromLocked
			|FROM
			|	TabPart AS TabPart
			|WHERE
			|	(TabPart.Products, TabPart.Characteristic, TabPart.Warehouse, TabPart.Purpose) IN(
			|		SELECT
			|			FilterOfProducts_.Products AS Products,
			|			FilterOfProducts_.Characteristic AS Characteristic,
			|			FilterOfProducts_.Warehouse AS Warehouse,
			|			FilterOfProducts_.Purpose AS Purpose
			|		FROM
			|			TTOrderGiver AS FilterOfProducts_)";
		
		QueryTexts.Add(QueryText);
		
	EndIf;
	QueryText =
		"SELECT
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
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT DISTINCT
		|				FilterOfProducts_.Products AS Products,
		|				FilterOfProducts_.Characteristic AS Characteristic,
		|				FilterOfProducts_.Warehouse AS Warehouse,
		|				FilterOfProducts_.Purpose AS Purpose
		|			FROM
		|				TTOrderGiver AS FilterOfProducts_)) AS Inventories
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
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT DISTINCT
		|				FilterOfProducts_.Products AS Products,
		|				FilterOfProducts_.Characteristic AS Characteristic,
		|				FilterOfProducts_.Warehouse AS Warehouse,
		|				FilterOfProducts_.Purpose AS Purpose
		|			FROM
		|				TTOrderGiver AS FilterOfProducts_)) AS Inventories";
	
	QueryTexts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	Set.Purpose AS Purpose,
		|	Set.Products AS Products,
		|	Set.Characteristic AS Characteristic,
		|	Set.Warehouse AS Warehouse,
		|	SUM(Set.Count) AS Count
		|FROM(
		|	SELECT
		|		OrderingProducts.Purpose AS Purpose,
		|		OrderingProducts.Products AS Products,
		|		OrderingProducts.Characteristic AS Characteristic,
		|		OrderingProducts.Warehouse AS Warehouse,
		|		OrderingProducts.Count AS Count
		|	FROM
		|		TTOrderGiver AS OrderingProducts
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		Calculation.Purpose AS Purpose,
		|		Calculation.Products AS Products,
		|		Calculation.Characteristic AS Characteristic,
		|		Calculation.Warehouse AS Warehouse,
		|		- Calculation.NotProvided_ReserveAsNeeded
		|			- Calculation.NotProvided_Postpone
		|			- Calculation.Supply_CIsNotProvided AS Count
		|FROM
		|	SubstitutionInventoryAllocation AS Calculation
		|WHERE
		|	Calculation.NotProvided_ReserveAsNeeded
		|		+ Calculation.NotProvided_Postpone
		|		+ Calculation.Supply_CIsNotProvided > 0) AS Set
		|		
		|GROUP BY
		|	Set.Purpose,
		|	Set.Products,
		|	Set.Characteristic,
		|	Set.Warehouse
		|HAVING
		|	SUM(Set.Count) > 0";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	If ThereIsAdjustment Then
		TablesNames.ReversingEntry = "InventoryAndNeedsStorno"; // @query-part-1
	EndIf;
	TablesNames.Result = "SubstitutionInventoryAllocation"; // @query-part-1
	ProvisionInDocumentsServer.InventoryAllocation(QueryText, TablesNames, False);
	
 	QueryTexts.Add(QueryText);  

	QueryText =
		"SELECT
		|		
		|	OrderingProducts.Products           AS Products,
		|	OrderingProducts.Characteristic         AS Characteristic,
		|	CASE
		|		WHEN VALUETYPE(OrderingProducts.Warehouse) = TYPE(Catalog.Warehouses)
		|			THEN OrderingProducts.Warehouse
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END                              AS Warehouse,
		|	CASE
		|		WHEN VALUETYPE(OrderingProducts.Warehouse) = TYPE(Catalog.BusinessStructure)
		|			THEN OrderingProducts.Warehouse
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END                              AS Department,
		|	OrderingProducts.Purpose             AS Purpose,
		|	OrderingProducts.BillOfMaterials           AS BillOfMaterials,
		|	OrderingProducts.DemandDate        AS DemandDate,
		|	OrderingProducts.Package               AS Package,
		|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
		|	OrderingProducts.Count             AS Count
		|		
		|FROM
		|	TTOrderGiver AS OrderingProducts
		|
		|ORDER BY
		|	OrderingProducts.DemandDate, OrderingProducts.LineNumber
		|"; 
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("OrderingProducts.Package", "OrderingProducts.Products"));  
	QueryTexts.Add(QueryText);
	
	FillingValues = New Structure();
	FillingValues.Insert("EarliestStartDate",     BegOfDay(CurrentSessionDate()));
	FillingValues.Insert("ProductionScheduling", Enums.WayOfLinkingProductionOperations.Backward);
	
	TableOfGoods = New ValueTable();  
	TableOfGoods.Columns.Add("Products", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Products.Type);
	TableOfGoods.Columns.Add("Characteristic", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Characteristic.Type);
	TableOfGoods.Columns.Add("Warehouse", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Warehouse.Type);
	TableOfGoods.Columns.Add("Department", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Department.Type);
	TableOfGoods.Columns.Add("Purpose", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Purpose.Type);
	TableOfGoods.Columns.Add("BillOfMaterials", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.BillOfMaterials.Type);
	TableOfGoods.Columns.Add("DemandDate", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.DemandDate.Type);
	TableOfGoods.Columns.Add("Package", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Package.Type);
	TableOfGoods.Columns.Add("NumberOfPackages", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.NumberOfPackages.Type);
	TableOfGoods.Columns.Add("Count", Metadata.Documents.ProductionOrder2_2.TabularSections.ManufacturedProduct.Attributes.Count.Type);
	// Additional Fields
	TableOfGoods.Columns.Add("EarliestStartDate", Metadata.Documents.ProductionOrder2_2.Attributes.EarliestStartDate.Type);
	TableOfGoods.Columns.Add("ProductionScheduling", Metadata.Documents.ProductionOrder2_2.Attributes.ProductionScheduling.Type);

	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Query = New Query(QueryText);
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	Query.SetParameter("ProductionProcessType", ProductionProcessType);
 	
	If ThereIsAdjustment Then 
		Object = CurrentObjectData.Object;
		Query.SetParameter("CurrentDocument", Object.Ref);
		Query.SetParameter("TS", Object.ManufacturedProduct.Unload(New Structure("Canceled", False)));
		Query.SetParameter("Status", Object.Status);
	EndIf;

	SetPrivilegedMode(True);  
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);

	NumberOfPackages_ = QueryResult.Count();

	IssuedForDistribution = QueryResult[NumberOfPackages_-2].Unload(); 
	IssuedForDistribution.Indexes.Add("Products,Characteristic,Warehouse,Purpose");
	SelectionStructureFormalized = New Structure("Products,Characteristic,Warehouse,Purpose");
		
	SampleProducts = QueryResult[NumberOfPackages_-1].Select();
	While SampleProducts.Next() Do
		
		FillPropertyValues(SelectionStructureFormalized, SampleProducts); 
		SelectionStructureFormalized.Warehouse = ?(ValueIsFilled(SampleProducts.Warehouse), SampleProducts.Warehouse, 
			SampleProducts.Department);
		
		FoundRows = IssuedForDistribution.FindRows(SelectionStructureFormalized);   
		If FoundRows.Count() = 0 Then  
			QuantityToRegister = SampleProducts.Count;
		Else 
			Allocated = Min(SampleProducts.Count, FoundRows[0].Count); 
			QuantityToRegister = SampleProducts.Count - Allocated ; 
			FoundRows[0].Count = FoundRows[0].Count - Allocated;
		EndIf;
		
		If QuantityToRegister > 0 Then
			NewRow = TableOfGoods.Add();
			FillPropertyValues(NewRow, SampleProducts);
			FillPropertyValues(NewRow, FillingValues);
			NewRow.Count = QuantityToRegister;
			NewRow.NumberOfPackages = NewRow.Count / SampleProducts.PackagingFactor;
		EndIf;
		
	EndDo;
	
	Return TableOfGoods;
	
EndFunction

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProductionOrder") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProductionOrder",
			NStr("vi = 'Đơn hàng sản xuất';
				|ru = 'Заказ на производство';
				|en = 'Production order'; fa = 'سفارش تولید';
				|it = 'Ordine di produzione';
				|pl = 'Zlecenie produkcyjne';
				|tr = 'Üretim emri'"),
			FormPrintedFormOfProductionOrder(ObjectsArray, PrintObjects));
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions,
		ObjectsArray,
		PrintFormsCollection);
	
EndProcedure

Function FormPrintedFormOfProductionOrder(ObjectsArray, PrintObjects)
	
	ScheduleDateFormat = ProductionManagement.FormatStringForProductionScheduleDate();

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName = "Parameters_Seals_ProductionOrder2_2_ProductionOrder";
	
	Template = PrintManagement.PrintFormTemplate("Document.ProductionOrder2_2.PF_MXL_ProductionOrder");
	FirstDocument = True;
	
	DataForPrint = PrintDataProductionOrder(ObjectsArray);
	HeaderSelection = DataForPrint.HeaderSelection;
	SampleProducts = DataForPrint.SampleProducts;
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	While HeaderSelection.Next() Do
	
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		FirstDocument = False;
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// Header - Header
		
		Area = Template.GetArea("Title"); // See ProductionServer.ServiceStructureTabularDocument
		
		Area.Parameters.TitleText = TMCommonUseClientServer.GenerateDocumentTitle(
			HeaderSelection,
			NStr("vi = 'Đơn hàng sản xuất';
				|ru = 'Заказ на производство';
				|en = 'Production order'; fa = 'سفارش تولید';
				|it = 'Ordine di produzione';
				|pl = 'Zlecenie produkcyjne';
				|tr = 'Üretim emri'", Common.DefaultLanguageCode()));
		Area.Parameters.Ref = HeaderSelection.Ref;
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
			SpreadsheetDocument,
			Template,
			Area,
			HeaderSelection.Ref);
	
		SpreadsheetDocument.Put(Area);
		
		// Organization Header
		
		Area = Template.GetArea("Organization");
		Area.Parameters.Fill(HeaderSelection);
		SpreadsheetDocument.Put(Area);
		
		// Dispatcher Header
		
		Area = Template.GetArea("Dispatcher");
		Area.Parameters.Fill(HeaderSelection);
		SpreadsheetDocument.Put(Area);
		
		// Hat - Giver
		
		If HeaderSelection.TollManufacturing Then
			
			Area = Template.GetArea("MaterialProvider");
			Area.Parameters.Fill(HeaderSelection);
			SpreadsheetDocument.Put(Area);
			
		EndIf;
		
		// Table
		
		If SampleProducts.FindNext(New Structure("Ref", HeaderSelection.Ref)) Then
			
			ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
			NameOfCodeColumn = ColumnOfCodes.ColumnName;
			PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
			OutputCodes = ValueIsFilled(ColumnOfCodes);
	
			If OutputCodes Then
		    	
				SectionHeader = Template.GetArea("HeaderOf_codeTable");
				SectionHeader.Parameters.NameOfCodeColumn = PresentationOfCodesColumn;
				AreaRow = Template.GetArea("TableRow_WithCode"); // See ProductionServer.ServiceStructureTabularDocument
				AreaRow.Areas.TableRow_WITHCode_DateOfNeed.Format = ScheduleDateFormat;
				
			Else
				
				SectionHeader = Template.GetArea("TableHeader_WithoutCode");
				AreaRow = Template.GetArea("TableRow_WithoutCode"); // See ProductionServer.ServiceStructureTabularDocument
				AreaRow.Areas.TableRow_WithoutCode_NeedDate.Format = ScheduleDateFormat;
			EndIf;
			
			SectionHeader.Parameters.ColumnNameProducts = ProductionClientServer.TitleOfTablePartByProcessType(
				HeaderSelection.ProductionProcessType,
				Common.DefaultLanguageCode());
			
			SpreadsheetDocument.Put(SectionHeader);
			
			LineNumber = 0;
			Selection = SampleProducts.Select();
			While Selection.Next() Do
		
				AreaRow.Parameters.Fill(Selection);
				
				LineNumber = LineNumber + 1;
				AreaRow.Parameters.LineNumber = LineNumber;
		
				If OutputCodes Then
					AreaRow.Parameters.SKU = Selection[NameOfCodeColumn];
				EndIf;
						
				AreaRow.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
					Selection.ProductFullName,
					Selection.CharacteristicFullName,
					,
					,
					AdditionalParametersProductPresentation);
		
				SpreadsheetDocument.Put(AreaRow);
		
			EndDo;
			
			SpreadsheetDocument.Put(Template.GetArea("TableFooter"));
			
		EndIf;
		
		PrintManagement.SetDocumentPrintArea(
			SpreadsheetDocument,
			RowNumberStart,
			PrintObjects,
			HeaderSelection.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function PrintDataProductionOrder(References)
	
	QueryText =
		"SELECT
		|	Orders.Ref                       AS Ref,
		|	Orders.Number                        AS Number,
		|	Orders.Date                         AS Date,
		|	Orders.Organization                  AS Organization,
		|	Orders.Organization.Presentation    AS OrganizationPresentation,
		|	Orders.Department                AS Dispatcher,
		|	Orders.Department.Presentation  AS DispatcherPresentation,
		|	Orders.Partner                      AS MaterialProvider,
		|	Orders.Partner.Presentation        AS MaterialProviderPresentation,
		|	Orders.ProductionProcessType AS ProductionProcessType,
		|	Orders.BusinessOperation IN (
		|				VALUE(Enum.BusinessTransactions.TollManufacturing2_5)) AS TollManufacturing
		|FROM
		|	Document.ProductionOrder2_2 AS Orders
		|WHERE
		|	Orders.Ref IN(&References)
		|
		|ORDER BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ManufacturedProduct.Ref                            AS Ref,
		|	ManufacturedProduct.Products                      AS Products,
		|	ManufacturedProduct.Products.Code                  AS Code,
		|	ManufacturedProduct.Products.SKU              AS SKU,
		|	ManufacturedProduct.Products.DescriptionFull   AS ProductFullName,
		|	ManufacturedProduct.Characteristic.DescriptionFull AS CharacteristicFullName,
		|	ManufacturedProduct.BillOfMaterials                      AS BillOfMaterials,
		|	ManufacturedProduct.BillOfMaterials.Presentation        AS BillOfMaterialsPresentation,
		|	ManufacturedProduct.DemandDate                   AS DemandDate,
		|	&QueryTextUnitOfMeasure               AS UnitOfMeasure,
		|	ManufacturedProduct.NumberOfPackages                AS Count
		|FROM
		|	Document.ProductionOrder2_2.ManufacturedProduct AS ManufacturedProduct
		|WHERE
		|	ManufacturedProduct.Ref IN(&References)
		|	AND NOT ManufacturedProduct.Canceled
		|
		|ORDER BY
		|	Ref,
		|	ManufacturedProduct.LineNumber
		|TOTALS BY
		|	Ref";
	
	TextEd = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"Description",
		"ManufacturedProduct.Package",
		"ManufacturedProduct.Products");
			
	QueryText = StrReplace(
		QueryText,
		"&QueryTextUnitOfMeasure",
		TextEd);
	
	Query = New Query(QueryText);
	Query.SetParameter("References", References);
	
	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch(); 
	SetPrivilegedMode(False);
	
	DataForPrint = New Structure;
	DataForPrint.Insert("HeaderSelection", ResultsArray[0].Select());
	DataForPrint.Insert("SampleProducts", ResultsArray[1].Select(QueryResultIteration.ByGroups));
	
	Return DataForPrint;
	
EndFunction

#EndRegion

#Region Other

#Region CreatingHyperlinkInProductionLog

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not AccessRight("Update", Metadata.Documents.ProductionOrder2_2) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED TOP 1
		|	ProductionOrder2_2.Ref AS Ref
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrder2_2
		|WHERE
		|	NOT ProductionOrder2_2.Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
		|	AND (ProductionOrder2_2.Organization = &Organization
		|		OR &AllCompanies)
		|	AND (ProductionOrder2_2.Department = &Department
		|		OR &AllDepartments)";
	
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Parameters.Organization));
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("AllDepartments", Not ValueIsFilled(Parameters.Department));
	Query.SetParameter("Department", Parameters.Department);
	
	If GetFunctionalOption("UseProductionManagement") Then
		HyperlinkText = NStr("vi = 'Đơn hàng sản xuất 2.2';
							|ru = 'Заказы на производство 2.2';
							|en = 'Production orders 2.2'; fa = 'Production orders 2.2';
							|it = 'Ordini di produzione 2.2';
							|pl = 'Zlecenie produkcyjne 2.2';
							|tr = 'Üretim emirleri 2.2'");
	Else
		HyperlinkText = NStr("vi = 'Đơn hàng sản xuất';
							|ru = 'Заказы на производство';
							|en = 'Production orders'; fa = 'سفارش‌های تولید';
							|it = 'Ordini di produzione';
							|pl = 'Zamówienia na produkcję';
							|tr = 'Üretim emirleri'");
	EndIf;
	
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			"Document.ProductionOrder2_2.Form.ListForm");
	Else
		Return New FormattedString(HyperlinkText,,,,
			"Document.ProductionOrder2_2.Form.ListForm");
	EndIf;
	
EndFunction

#EndRegion

// Returns a template for generating a document destination
//
// Parameters:
//  Object	 - DocumentObject.ProductionOrder2_2 - order.
//
// Returns:
//  See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	OptionOfAssignment = Object.OptionOfAssignment;
	
	If OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage Then
		
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		If Object.BusinessOperation =
				Enums.BusinessTransactions.TollManufacturing2_5
			And ValueIsFilled(Object.Partner)
			And ValueIsFilled(Object.Contract) Then
			
			DestinationPattern.Partner       = Object.Partner;
			DestinationPattern.Contract       = Object.Contract;
			DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
			
		Else
			
			If OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentInProduction.LineOfBusiness
				Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
				
				DestinationPattern.OrderDocument = Object.Ref;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

Function StatusOfProductionOrder()
	
	Return Enums.ProductionOrderStatuses2_2.ToProduce;
	
EndFunction

// Returns the text of the request, the result of which is a list of orders (by product)
// for which part of the product was produced, but the production of the remaining part is not planned.
//
// Returns:
//  String - query text.
//
Function RequestTextTTUnscheduledOrderProduction() Export
	
	QueryTexts = New Array;
	QueryText =
	"SELECT ALLOWED
	|	CAST(ProductsRelease.ReferenceOrder AS Document.ProductionStage2_2) AS ReferenceOrder
	|INTO StagesWithTurns
	|FROM
	|	AccumulationRegister.ProductsRelease.Turnovers(
	|		&BeginOfPeriod,
	|		&EndOfPeriod,,
	|		Organization IN (&CompanyArray)
	|		AND VALUETYPE(ReferenceOrder) = TYPE(Document.ProductionStage2_2)) AS ProductsRelease
	|
	|GROUP BY
	|	CAST(ProductsRelease.ReferenceOrder AS Document.ProductionStage2_2)
	|
	|INDEX BY
	|	ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OrderDetails.Ref AS Ref
	|INTO OrdersRequiringVerification
	|FROM
	|	StagesWithTurns AS StagesWithTurns
	|
	|	INNER JOIN Document.ProductionStage2_2 AS StageDetails
	|	ON StageDetails.Ref = StagesWithTurns.ReferenceOrder
	|	
	|	INNER JOIN Document.ProductionOrder2_2 AS OrderDetails
	|	ON OrderDetails.Ref = StageDetails.ReferenceOrder
	|	
	|WHERE
	|	NOT OrderDetails.Status = VALUE(Enum.ProductionOrderStatuses2_2.Closed)
	|	AND OrderDetails.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.WithoutBillsOfMaterials)
	|
	|GROUP BY
	|	OrderDetails.Ref
	|
	|INDEX BY
	|	Ref
	|";
	QueryTexts.Add(QueryText);
	
	VerificationIndicator = BalanceIndicatorForFormationOfStages();
	
	RequestTextsProductsForProduction = RequestTextsProductsForProduction(True, VerificationIndicator,, False,
		"ReferenceOrder IN (
		|	SELECT
		|		OrdersRequiringVerification.Ref
		|	FROM
		|		OrdersRequiringVerification AS OrdersRequiringVerification
		|)");
	QueryTexts.Add(RequestTextsProductsForProduction.QueryTextSource);
	QueryTexts.Add(RequestTextsProductsForProduction.QueryTextAdditional);
	QueryTexts.Add(RequestTextsProductsForProduction.QueryTextMain);
	
	QueryText =
	"SELECT
	|	OrderDetails.Organization					AS Organization,
	|	TTProductsForProduction.ReferenceOrder	AS ProductionOrder,
	|	TTProductsForProduction.Products	AS Products,
	|	TTProductsForProduction.Characteristic	AS Characteristic,
	|	TTProductsForProduction.Purpose		AS Purpose
	|INTO UnplannedProductsWithoutSpecifications
	|FROM
	|	TTProductsForProduction AS TTProductsForProduction
	|	
	|	INNER JOIN Document.ProductionOrder2_2 AS OrderDetails
	|	ON OrderDetails.Ref = TTProductsForProduction.ReferenceOrder
	|
	|GROUP BY
	|	OrderDetails.Organization,
	|	TTProductsForProduction.ReferenceOrder,
	|	TTProductsForProduction.Products,
	|	TTProductsForProduction.Characteristic,
	|	TTProductsForProduction.Purpose
	|";
	QueryTexts.Add(QueryText);
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndFunction

Function SplitArrayOfOrdersDependingOnStructure(DocumentsArray)

	Query = New Query;
	Query.Text = 
		"SELECT
		|	ProductionOrder2_2.Ref AS Ref,
		|	ProductionOrder2_2.DynamicStructure AS DynamicStructure
		|INTO DocumentsData
		|FROM
		|	Document.ProductionOrder2_2 AS ProductionOrder2_2
		|WHERE
		|	ProductionOrder2_2.Ref IN(&DocumentsArray)
		|
		|INDEX BY
		|	DynamicStructure
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsData.Ref AS Ref
		|FROM
		|	DocumentsData AS DocumentsData
		|WHERE
		|	DocumentsData.DynamicStructure
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsData.Ref AS Ref
		|FROM
		|	DocumentsData AS DocumentsData
		|WHERE
		|	NOT DocumentsData.DynamicStructure";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ResultsArray = Query.ExecuteBatch();
	Boundary = ResultsArray.UBound();
	ArrayOfStaticOrders = ResultsArray[Boundary].Unload().UnloadColumn("Ref");
	ArrayOfDynamicOrders = ResultsArray[Boundary - 1].Unload().UnloadColumn("Ref");
	Return New Structure("StaticOrders, DynamicOrders", ArrayOfStaticOrders, ArrayOfDynamicOrders);	
	
EndFunction

Function BalanceIndicatorForFormationOfStages()

	Return 1;

EndFunction

Function IndicatorIsNotManufacturedProducts()

	Return 2;

EndFunction

#EndRegion

#Region ImportDataFromFile

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	Goods = GetFromTempStorage(AddressOfMappingTable);
	DataToImport = GetFromTempStorage(AddressOfUploadedData);
	
	QueryTexts = New Array;
	QueryTexts.Add(UploadedDataQueryTextExternalData());
	QueryTexts.Add(UploadedDataQueryTextTTBarcodeData());
	QueryTexts.Add(UploadedDataQueryTextTTItemData());
	QueryTexts.Add(UploadedDataQueryTextTTDataCharacteristics());
	QueryTexts.Add(LoadingDataQueryTextTTDataOfPackages());
	QueryTexts.Add(UploadedDataQueryTextTTWarehouseData());
	QueryTexts.Add(UploadedDataQueryTextTTDataOfDivisions());
	If AdditionalParameters.AssignmentsAreUsed Then
		QueryTexts.Add(UploadedDataQueryTextTTDestinationData());
	EndIf;
	If AdditionalParameters.SpecificationsAreUsed Then
		QueryTexts.Add(UploadedDataQueryTextTTDataBillOfMaterials());
	EndIf;
	QueryTexts.Add(DataToLoadQueryTextFinalSelection());
	
	Query = UploadDataCreateRequest(QueryTexts, DataToImport, AdditionalParameters);
	Result = Query.Execute().Unload();
	
	For Each String In Result Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, String);
		If String.ThisIsWork Then
			NewRow.Department = String.ReceivingBusinessUnit;
		Else
			NewRow.Warehouse = String.DestinationWarehouse;
		EndIf;
		UploadedDataCreateAmbiguityRecords(ConflictsList, String, AdditionalParameters);
	EndDo;
	
	PutToTempStorage(Goods, AddressOfMappingTable);
	
EndProcedure

Procedure UploadedDataCreateAmbiguityRecords(ConflictsList, String, AdditionalParameters)
	
		If String.QuantityOfProducts > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Products";
		EndIf;
		
		If String.NumberOfCharacteristics > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Characteristic";
		EndIf;
		
		If AdditionalParameters.AssignmentsAreUsed And String.NumberOfAppointments > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Purpose";
		EndIf;
		
		If String.PackingQuantity > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Package";
		EndIf;
		
		If AdditionalParameters.SpecificationsAreUsed And String.NumberOfSpecifications > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "BillOfMaterials";
		EndIf;
		
		If String.NumberOfWarehouses > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Warehouse";
		EndIf;
		
		If String.NumberOfDivisions_ > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = String.Id;
			WritingAboutAmbiguity.Column       = "Department";
		EndIf;
		
EndProcedure

// Fill in the list of ambiguities.
// 
// Parameters:
//  TabularSectionName - String -
//  ConflictsList - Array of ValueTableRow
//  ColumnName - String -
//  LoadedValuesString - ValueTableRow
//  AdditionalParameters - See PlanningClient.AdditionalParametersForDownloadingFromFile
Procedure FillInListOfAmbiguities(TabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export
	
	Query = New Query;
	
	If ColumnName = "Products" Then
		
		Query.Text =
		"SELECT
		|	Barcodes.Products   AS Products,
		|	Barcodes.Characteristic AS Characteristic,
		|	Barcodes.Package       AS Package
		|INTO TTBarcodeData
		|FROM
		|	InformationRegister.ItemsBarcodes AS Barcodes
		|
		|WHERE
		|	NOT &Barcode = """"
		|	AND Barcodes.Barcode = &Barcode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatProducts.Ref AS Ref
		|FROM
		|	(SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &SKU = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.SKU = &SKU
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &ProductsAndServicesCode = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Code = &ProductsAndServicesCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &Products = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Description = &Products
		|
		|	UNION ALL
		|
		|	SELECT
		|		BarcodeData_5.Products AS Ref
		|	FROM
		|		TTBarcodeData AS BarcodeData_5
		|	) AS CatProducts
		|
		|GROUP BY
		|	CatProducts.Ref
		|";
		
		Query.SetParameter("Barcode",        LoadedValuesString.Barcode);
		Query.SetParameter("SKU",         LoadedValuesString.SKU);
		Query.SetParameter("ProductsAndServicesCode", LoadedValuesString.ProductsAndServicesCode);
		Query.SetParameter("Products",    LoadedValuesString.Products);
		
	EndIf;
	
	If ColumnName = "Characteristic" Then
		
		Query.Text =
		"SELECT
		|	Characteristics.Ref AS Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS Characteristics
		|
		|WHERE
		|	NOT &Characteristic = """"
		|	AND Characteristics.Description = &Characteristic
		|";
		
		Query.SetParameter("Characteristic", LoadedValuesString.Characteristic);
		
	EndIf;
	
	If ColumnName = "Purpose" Then
		
		Query.Text =
		"SELECT
		|	Assignments.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS Assignments
		|
		|WHERE
		|	NOT &Purpose = """"
		|	AND Assignments.Description = &Purpose
		|";
		
		Query.SetParameter("Purpose", LoadedValuesString.Purpose);
		
	EndIf;
	
	If ColumnName = "Package" Then
		
		Query.Text =
		"SELECT
		|	Packages.Ref AS Ref
		|FROM
		|	(SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &PackageCode = """"
		|		AND Packages.Code = &PackageCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &Package = """"
		|		AND Packages.Description = &Package
		|	) AS Packages
		|
		|GROUP BY
		|	Packages.Ref
		|";
		
		Query.SetParameter("PackageCode", LoadedValuesString.PackageCode);
		Query.SetParameter("Package",    LoadedValuesString.Package);
		
	EndIf;
	
	If ColumnName = "BillOfMaterials" Then
		
		Query.Text =
		"SELECT
		|	Specifications.Ref AS Ref
		|FROM
		|	Catalog.BillsOfMaterials AS Specifications
		|
		|WHERE
		|	NOT &BillOfMaterials = """"
		|	AND Specifications.Description = &BillOfMaterials
		|";
		
		Query.SetParameter("BillOfMaterials", LoadedValuesString.BillOfMaterials);
		
	EndIf;
	
	If ColumnName = "Warehouse" Then
		
		Query.Text =
		"SELECT
		|	Warehouses.Ref AS Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|
		|WHERE
		|	NOT &Warehouse = """"
		|	AND Warehouses.Description = &Warehouse
		|";
		
		Query.SetParameter("Warehouse", LoadedValuesString.Warehouse);
		
	EndIf;
	
	If ColumnName = "Department" Then
		
		Query.Text =
		"SELECT
		|	BusinessStructure.Ref AS Ref
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|
		|WHERE
		|	NOT &Partner = """"
		|	AND BusinessStructure.Description = &Department
		|";
		
		Query.SetParameter("Department", LoadedValuesString.Department);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#Region RequestTextsForDownloadingDataFromFile

// Parameters:
//  QueryTexts - Array of String - Request texts
//  DataToImport - ValueTable - Uploaded data
//  AdditionalParameters - Structure - advanced setting:
// * AssignmentsAreUsed - Boolean -
// * SpecificationsAreUsed - Boolean -
// * NeedDateIsUsed - Boolean -
// * AvailableProductTypes - Array of EnumRef.ItemsTypes -
// 
// Returns:
//  Query
Function UploadDataCreateRequest(QueryTexts, DataToImport, AdditionalParameters)
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	QuantityField = "DataToImport.Count AS Count,
					 |DataToImport.Count AS NumberOfPackages,";
	
	QueryText = StrReplace(QueryText, "&DownloadableDataNumberOfPackages,", QuantityField);

	If AdditionalParameters.AssignmentsAreUsed Then
		
		QueryText = StrReplace(QueryText, "&DownloadableDataDestination,", "DataToImport.Purpose AS Purpose,");
		
		QueryText = StrReplace(QueryText, "&Purpose,", "
			|	CASE
			|		WHEN ISNULL(DestinationData.NumberOfAppointments, 0) = 1
			|			THEN DestinationData.Purpose
			|		ELSE VALUE(Catalog.Assignments.EmptyRef)
			|	END AS Purpose,");
	
		QueryText = StrReplace(QueryText, "&NumberOfAppointments,", "ISNULL(DestinationData.NumberOfAppointments, 0) AS NumberOfAppointments,");
	
		QueryText = QueryText + "
			|	LEFT JOIN TTDestinationData AS DestinationData
			|	ON DestinationData.Id = DataToImport.Id";
		
	Else
		
		QueryText = StrReplace(QueryText, "&DownloadableDataDestination,", "");
		QueryText = StrReplace(QueryText, "&Purpose,", "");
		QueryText = StrReplace(QueryText, "&NumberOfAppointments,", "");
		
	EndIf;
	
	If AdditionalParameters.SpecificationsAreUsed Then
		
		QueryText = StrReplace(QueryText, "&DownloadableDataSpecification,", "DataToImport.BillOfMaterials AS BillOfMaterials,");
		
		QueryText = StrReplace(QueryText, "&BillOfMaterials,", "
			|	CASE
			|		WHEN ISNULL(SpecificationsData.NumberOfSpecifications, 0) = 1
			|			THEN SpecificationsData.BillOfMaterials
			|		ELSE VALUE(Catalog.BillsOfMaterials.EmptyRef)
			|	END AS BillOfMaterials,");
		
		QueryText = StrReplace(QueryText, "&NumberOfSpecifications,", "ISNULL(SpecificationsData.NumberOfSpecifications, 0) AS NumberOfSpecifications,");
		
		QueryText = QueryText + "
			|	LEFT JOIN TTSpecificationsData AS SpecificationsData
			|	ON SpecificationsData.Id = DataToImport.Id";
		
	Else
		
		QueryText = StrReplace(QueryText, "&DownloadableDataSpecification,", "");
		QueryText = StrReplace(QueryText, "&BillOfMaterials,", "");
		QueryText = StrReplace(QueryText, "&NumberOfSpecifications,", "");
		
	EndIf;

	If AdditionalParameters.DateOfNeedIsUsed Then
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", "DataToImport.DemandDate AS DemandDate,");
	Else
		QueryText = StrReplace(QueryText, "&DownloadableDateData,", "");
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",         DataToImport);
	Query.SetParameter("AvailableProductTypes", AdditionalParameters.AvailableProductTypes);
	
	Return Query;
	
EndFunction

// Returns:
//  String
Function UploadedDataQueryTextExternalData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id       AS Id,
	|	DataToImport.Barcode            AS Barcode,
	|	DataToImport.SKU             AS SKU,
	|	DataToImport.ProductsAndServicesCode     AS ProductsAndServicesCode,
	|	DataToImport.Products        AS Products,
	|	DataToImport.Characteristic      AS Characteristic,
	|	&DownloadableDataDestination,
	|	DataToImport.PackageCode         AS PackageCode,
	|	DataToImport.Package            AS Package,
	|	DataToImport.Recipient          AS Recipient,
	|	&DownloadableDataNumberOfPackages,
	|	&DownloadableDataSpecification,
	|	&DownloadableDateData,
	|	DataToImport.Comment         AS Comment
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Barcode Data
Function UploadedDataQueryTextTTBarcodeData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id AS Id,
	|	Barcodes.Products          AS Products,
	|	Barcodes.Characteristic        AS Characteristic,
	|	Barcodes.Package              AS Package
	|INTO TTBarcodeData
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
	|	ON Barcodes.Barcode = DataToImport.Barcode
	|
	|WHERE
	|	NOT DataToImport.Barcode = """"
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Product Data
Function UploadedDataQueryTextTTItemData()
	
	QueryText =
	"SELECT
	|	CatProducts.Id                      AS Id,
	|	MAX(CatProducts.Products)             AS Products,
	|	COUNT(DISTINCT CatProducts.Products) AS QuantityOfProducts
	|INTO TTProductData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.SKU = DataToImport.SKU
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.SKU = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ProductsAndServicesCode = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Description = DataToImport.Products
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Products = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Products  AS Products
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS CatProducts
	|
	|GROUP BY
	|	CatProducts.Id
	|
	|INDEX BY
	|	Id,
	|	Products
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Characteristics Data
Function UploadedDataQueryTextTTDataCharacteristics()
	
	QueryText =
	"SELECT
	|	Characteristics.Id                        AS Id,
	|	MAX(Characteristics.Characteristic)             AS Characteristic,
	|	COUNT(DISTINCT Characteristics.Characteristic) AS NumberOfCharacteristics
	|INTO TTCharacteristicsData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Characteristics.Ref           AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = ProductData_1.Products
	|		
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = CASE
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|				THEN CatProducts.ProductKind
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|				THEN CatProducts.Ref
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|				THEN CatProducts.ItemVariantsOwner
	|			ELSE UNDEFINED
	|		END
	|		AND Characteristics.Description = DataToImport.Characteristic
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Characteristic = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Characteristics.Ref           AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = ProductData_1.Products
	|
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = CASE
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind)
	|				THEN CatProducts.ProductKind
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
	|				THEN CatProducts.Ref
	|			WHEN CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind)
	|				THEN CatProducts.ItemVariantsOwner
	|			ELSE UNDEFINED
	|		END
	|		AND Characteristics.Description = DataToImport.Characteristic
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Characteristic = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Characteristic AS Characteristic
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Characteristics
	|
	|GROUP BY
	|	Characteristics.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Destination Data
Function UploadedDataQueryTextTTDestinationData()
	QueryText = "
	|SELECT
	|	Assignments.Id                    AS Id,
	|	MAX(Assignments.Purpose)             AS Purpose,
	|	COUNT(DISTINCT Assignments.Purpose) AS NumberOfAppointments
	|INTO TTDestinationData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Assignments.Ref               AS Purpose
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Assignments AS Assignments
	|		ON Assignments.Description = DataToImport.Purpose
	|
	|	WHERE
	|		NOT DataToImport.Purpose = """"
	|	) AS Assignments
	|
	|GROUP BY
	|	Assignments.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Package Data
Function LoadingDataQueryTextTTDataOfPackages()
	
	QueryText =
	"SELECT
	|	Packages.Id                  AS Id,
	|	MAX(Packages.Package)             AS Package,
	|	COUNT(DISTINCT Packages.Package) AS PackingQuantity
	|INTO TTPackingData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Description = DataToImport.Package
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Description = DataToImport.Package
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Package      AS Package
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Packages
	|
	|GROUP BY
	|	Packages.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Specification Data
Function UploadedDataQueryTextTTDataBillOfMaterials()
	QueryText = "
	|SELECT
	|	Specifications.Id                      AS Id,
	|	MAX(Specifications.BillOfMaterials)             AS BillOfMaterials,
	|	COUNT(DISTINCT Specifications.BillOfMaterials) AS NumberOfSpecifications
	|INTO TTSpecificationsData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Specifications.Ref             AS BillOfMaterials
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.BillsOfMaterials AS Specifications
	|		ON Specifications.Description = DataToImport.BillOfMaterials
	|
	|	WHERE
	|		NOT DataToImport.BillOfMaterials = """"
	|	) AS Specifications
	|
	|GROUP BY
	|	Specifications.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text TT Warehouse Data
Function UploadedDataQueryTextTTWarehouseData()
	QueryText = "
	|SELECT
	|	Warehouses.Id               AS Id,
	|	MAX(Warehouses.Warehouse)             AS Warehouse,
	|	COUNT(DISTINCT Warehouses.Warehouse) AS NumberOfWarehouses
	|INTO TTWarehouseData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Warehouses.Ref                   AS Warehouse
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON Warehouses.Description = DataToImport.Recipient
	|
	|	WHERE
	|		NOT DataToImport.Recipient = """"
	|	) AS Warehouses
	|
	|GROUP BY
	|	Warehouses.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Query Text TT division data
Function UploadedDataQueryTextTTDataOfDivisions()
	QueryText = "
	|SELECT
	|	Departments.Id                       AS Id,
	|	MAX(Departments.Department)             AS Department,
	|	COUNT(DISTINCT Departments.Department) AS NumberOfDivisions_
	|INTO TTDataOfDivisions
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		BusinessStructure.Ref     AS Department
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Description = DataToImport.Recipient
	|
	|	WHERE
	|		NOT DataToImport.Recipient = """"
	|	) AS Departments
	|
	|GROUP BY
	|	Departments.Id
	|
	|INDEX BY
	|	Id";
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - Request Text Uploaded Product Data
Function DataToLoadQueryTextFinalSelection()
	
	QueryText =
	"SELECT
	|	DataToImport.Id                          AS Id,
	|	CASE
	|		WHEN ISNULL(ProductData_1.QuantityOfProducts, 0) = 1
	|			THEN ProductData_1.Products
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END                                                    AS Products,
	|	CASE
	|		WHEN ISNULL(ProductData_1.QuantityOfProducts, 0) = 1
	|			THEN ProductData_1.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		ELSE FALSE
	|	END                                                    AS ThisIsWork,
	|	CASE
	|		WHEN ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) = 1
	|			THEN CharacteristicsData.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END                                                    AS Characteristic,
	|	&Purpose,
	|	CASE
	|		WHEN ISNULL(PackageData_.PackingQuantity, 0) = 1
	|			THEN PackageData_.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                                                    AS Package,
	|	&BillOfMaterials,
	|	CASE
	|		WHEN ISNULL(WarehouseData_2.NumberOfWarehouses, 0) = 1
	|			THEN WarehouseData_2.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS DestinationWarehouse,
	|	CASE
	|		WHEN ISNULL(DivisionData.NumberOfDivisions_, 0) = 1
	|			THEN DivisionData.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS ReceivingBusinessUnit,
	|	ISNULL(ProductData_1.QuantityOfProducts, 0)   AS QuantityOfProducts,
	|	ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) AS NumberOfCharacteristics,
	|	&NumberOfAppointments,
	|	&NumberOfSpecifications,
	|	ISNULL(WarehouseData_2.NumberOfWarehouses, 0)             AS NumberOfWarehouses,
	|	ISNULL(DivisionData.NumberOfDivisions_, 0)       AS NumberOfDivisions_,
	|	ISNULL(PackageData_.PackingQuantity, 0)           AS PackingQuantity,
	|	&DownloadableDataNumberOfPackages,
	|	&DownloadableDateData,
	|	DataToImport.Comment                            AS Comment
	|FROM
	|	TTDownloadableData AS DataToImport
	|	LEFT JOIN TTProductData AS ProductData_1
	|	ON ProductData_1.Id = DataToImport.Id
	|	LEFT JOIN TTCharacteristicsData AS CharacteristicsData
	|	ON CharacteristicsData.Id = DataToImport.Id
	|	LEFT JOIN TTPackingData AS PackageData_
	|	ON PackageData_.Id = DataToImport.Id
	|	LEFT JOIN TTDataOfDivisions AS DivisionData
	|	ON DivisionData.Id = DataToImport.Id
	|	LEFT JOIN TTWarehouseData AS WarehouseData_2
	|	ON WarehouseData_2.Id = DataToImport.Id";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
